# MyAFBase Android — Data Safety (Play Console)

Use this when completing the **Data safety** section in Google Play Console.

## Overview

| Question | Answer |
|----------|--------|
| Does your app collect or share user data? | Yes (limited, optional) |
| Is all data encrypted in transit? | Yes (HTTPS for feedback and remote base sync) |
| Can users request data deletion? | N/A — no account; local data cleared by uninstalling |

## Data types collected

### Device or other IDs (optional feedback only)

| Field | Detail |
|-------|--------|
| Collected | Yes, when user submits feedback |
| Shared | No |
| Purpose | App functionality (debugging feedback) |
| Data | Device model, Android version, app version |
| Required | No — user chooses to send feedback |
| Ephemeral | No — stored server-side with feedback ticket |

### App activity (optional feedback only)

| Field | Detail |
|-------|--------|
| Collected | Yes, when user submits feedback |
| Shared | No |
| Purpose | App functionality |
| Data | Selected base name, feedback category, message text |
| Required | No |

### Personal info (optional feedback only)

| Field | Detail |
|-------|--------|
| Collected | Optional email if user consents on feedback form |
| Shared | No |
| Purpose | Support follow-up |
| Required | No |

## Data stored on device (not transmitted)

Declare under **Data collected** only if Play Console requires local storage disclosure:

- Bookmarks (gates, resources, events)
- Assignment dates and phase
- Readiness tracker dates
- PFRA scores and records
- WAR Tracker entries and award deadlines
- User preferences (weather toggle, notification settings)

All of the above stay in local Room/DataStore storage. Not shared with third parties.

## Data NOT collected

- Location (app uses base coordinates from bundled JSON, not device GPS)
- Contacts, photos, files
- Financial info
- Health info
- Account credentials (no login)

## Security practices

- Feedback sent over HTTPS to Cloudflare Worker
- No ads, no analytics SDKs, no sale of data
- Optional biometric lock for WAR Tracker (local only)
- AFI semantic search runs fully on-device (SQLite index + local embedding model); search queries are not sent to a server

## On-device machine learning

- Essential AFI Search builds a local SQLite FTS index and computes text embeddings on-device to improve related-result ranking
- Embedding computation happens locally during background backfill; no AFI search queries or corpus text leave the device

## Government app declaration

**Not a government app.** Unofficial community tool; not affiliated with DoD or U.S. Air Force.
