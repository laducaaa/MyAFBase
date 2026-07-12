/**
 * MyAFBase feedback relay (free Cloudflare Workers)
 *
 * One-time setup:
 * 1. Create a GitHub fine-grained PAT with Issues: Read and write on laducaaa/MyAFBase
 * 2. npm i -g wrangler && wrangler login
 * 3. cp wrangler.toml.example wrangler.toml — edit name if needed
 * 4. wrangler secret put GITHUB_TOKEN
 * 5. Optional: wrangler secret put FEEDBACK_SECRET (same string as FeedbackConfig.sharedSecret)
 * 6. wrangler kv namespace create RATE_LIMIT — paste ids into wrangler.toml
 * 7. wrangler deploy
 * 8. Paste the worker URL into FeedbackConfig.endpoint in the iOS app
 *
 * GitHub emails you when new issues are opened (enable in GitHub notification settings).
 *
 * Auth model (v1.5.1 hotfix):
 * - Live 1.5 clients ship with an empty shared secret and omit X-Feedback-Secret.
 * - Secret is optional. When FEEDBACK_SECRET is set AND the client sends a non-empty
 *   X-Feedback-Secret, it must match. Missing/empty client secrets are allowed so
 *   already-shipped builds keep working. Abuse is limited by IP rate limiting.
 */

const REPO = "laducaaa/MyAFBase";
const ALLOWED_CATEGORIES = new Set(["bug", "feature", "baseData", "general"]);
const RATE_LIMIT_MAX = 5;
const RATE_LIMIT_WINDOW_SECONDS = 3600;

export default {
  async fetch(request, env) {
    if (request.method === "OPTIONS") {
      return new Response(null, { status: 204, headers: corsHeaders() });
    }

    if (request.method !== "POST") {
      return json({ error: "method_not_allowed" }, 405);
    }

    if (!env.GITHUB_TOKEN) {
      return json({ error: "not_configured" }, 503);
    }

    const provided = (request.headers.get("X-Feedback-Secret") ?? "").trim();
    const expected = typeof env.FEEDBACK_SECRET === "string" ? env.FEEDBACK_SECRET.trim() : "";

    // Only enforce the shared secret when the client actually sends one.
    // Shipped 1.5 builds leave FEEDBACK_SHARED_SECRET empty and omit the header.
    if (provided && expected && !timingSafeEqual(provided, expected)) {
      return json({ error: "unauthorized" }, 401);
    }

    if (env.RATE_LIMIT) {
      const clientIP = request.headers.get("CF-Connecting-IP") ?? "unknown";
      const rateKey = `rate:${clientIP}`;
      const count = Number(await env.RATE_LIMIT.get(rateKey)) || 0;
      if (count >= RATE_LIMIT_MAX) {
        return json({ error: "rate_limited" }, 429);
      }
      await env.RATE_LIMIT.put(rateKey, String(count + 1), {
        expirationTtl: RATE_LIMIT_WINDOW_SECONDS,
      });
    }

    let body;
    try {
      body = await request.json();
    } catch {
      return json({ error: "invalid_json" }, 400);
    }

    const message = typeof body.message === "string" ? body.message.trim() : "";
    if (message.length < 12 || message.length > 4000) {
      return json({ error: "invalid_message" }, 400);
    }

    const category =
      typeof body.category === "string" && ALLOWED_CATEGORIES.has(body.category)
        ? body.category
        : "general";
    const title = `[App Feedback] ${labelFor(category)} — ${sanitizeInline(message.slice(0, 72))}${message.length > 72 ? "…" : ""}`;

    const issueBody = formatIssueBody(body, message, category);

    const ghResponse = await fetch(`https://api.github.com/repos/${REPO}/issues`, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${env.GITHUB_TOKEN}`,
        Accept: "application/vnd.github+json",
        "Content-Type": "application/json",
        "User-Agent": "MyAFBase-Feedback-Worker",
        "X-GitHub-Api-Version": "2022-11-28",
      },
      body: JSON.stringify({ title, body: issueBody }),
    });

    if (!ghResponse.ok) {
      const detail = await ghResponse.text().catch(() => "");
      console.error("GitHub API error", ghResponse.status, detail.slice(0, 500));
      return json({ error: "github_failed", status: ghResponse.status }, 502);
    }

    const issue = await ghResponse.json();
    return json({ ok: true, issueNumber: issue.number, issueURL: issue.html_url }, 201);
  },
};

function labelFor(category) {
  switch (category) {
    case "bug":
      return "Bug";
    case "feature":
      return "Feature";
    case "baseData":
      return "Base Data";
    default:
      return "General";
  }
}

function formatIssueBody(body, message, category) {
  const contactEmail = formatContactEmail(body);
  const lines = [
    "### Message",
    "",
    "```text",
    message.slice(0, 4000),
    "```",
    "",
    "---",
    "| Field | Value |",
    "| --- | --- |",
    `| **Category** | ${labelFor(category)} |`,
    `| **App version** | ${escapeCell(body.appVersion)} |`,
    `| **Base** | ${escapeCell(body.baseName || body.baseID || "—")} |`,
    `| **Device** | ${escapeCell(body.deviceModel)} |`,
    `| **OS** | ${escapeCell(body.osVersion)} |`,
    `| **Contact email** | ${contactEmail} |`,
    "",
    "_Submitted from the MyAFBase iOS app._",
  ];
  return lines.join("\n");
}

function formatContactEmail(body) {
  const consented = body.contactEmailConsent === true;
  const email = typeof body.contactEmail === "string" ? body.contactEmail.trim() : "";
  if (!consented || !email) {
    return "—";
  }
  return escapeCell(email);
}

function escapeCell(value) {
  if (value == null || value === "") return "—";
  return String(value)
    .replace(/[\|\[\]`_*#@<>\\]/g, "")
    .replace(/\n/g, " ")
    .slice(0, 200);
}

function sanitizeInline(value) {
  return String(value).replace(/[\n\r|]/g, " ").slice(0, 200);
}

function timingSafeEqual(a, b) {
  if (a.length !== b.length) return false;
  let mismatch = 0;
  for (let i = 0; i < a.length; i++) {
    mismatch |= a.charCodeAt(i) ^ b.charCodeAt(i);
  }
  return mismatch === 0;
}

function json(data, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      "Content-Type": "application/json",
      ...corsHeaders(),
    },
  });
}

function corsHeaders() {
  // Native iOS URLSession does not require CORS; omit Access-Control-Allow-Origin.
  return {
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type, X-Feedback-Secret, User-Agent",
  };
}
