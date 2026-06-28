# Base data files

Each Air Force installation in the app is defined by one JSON file in this folder plus one entry in `bases_index.json`.

## Adding a new base

1. Copy `_base_template.json` → `{id}.json` (e.g. `nellis.json`).
2. Fill in all fields using official `.mil` / FSS / MWR sources.
3. Add a summary object to `bases_index.json`:

```json
{ "id": "nellis", "name": "Nellis AFB", "location": "Las Vegas, NV", "wing": "99 ABW" }
```

Rules:

- `id` must be a **lowercase slug** matching the filename (no spaces).
- `id` in the file, filename, and index entry must all match.
- Valid JSON only — **no trailing commas**.
- All `id` fields must be unique within a base file.
- Dates use ISO 8601 UTC with `Z` (e.g. `"2026-06-01T06:00:00Z"`).
- Use `null` for unknown optional values.

The app sorts bases alphabetically by `name` in the base picker.

## Reference files

| File | Purpose |
|------|---------|
| `_base_template.json` | Empty scaffold to copy |
| `keesler.json` | Most complete example |
| `eglin.json`, `travis.json`, `lackland.json` | Smaller examples |
| `bases_index.json` | Picker list (id, name, location, wing) |

## Schema overview

Decodes to the Swift `Base` model (`Models/Base.swift`).

### Top-level

| Field | Type | Notes |
|-------|------|-------|
| `id` | string | Slug matching filename |
| `name` | string | Short name (e.g. `Keesler AFB`) |
| `fullName` | string | Official full name |
| `location` | string | `City, ST` |
| `description` | string | 1–2 sentences; Home + Newcomers |
| `wing` | string | Host wing (e.g. `81 TRW`) |
| `latitude` / `longitude` | number | Base center; used for weather |

### `currentNotifications` → Alerts tab

| Field | Allowed values |
|-------|----------------|
| `type` | `alert`, `info`, `closure`, `event` |
| `postedAt` | ISO 8601 UTC |
| `expiresAt` | ISO 8601 UTC or `null` |

Use `[]` if none. Source from real base notices when possible.

### `emergencyNumbers` → Home emergency sheet

Objects: `{ id, label, number }`. Include a `911` row where applicable. Use official SF, hospital, and base operator numbers.

### `gates` → Explore (Gates)

| Field | Allowed values |
|-------|----------------|
| `status` | `open`, `closed`, `delayed`, `unknown` |
| `traffic` | `low`, `moderate`, `high`, `unknown` |
| `latitude` / `longitude` | number or `null` |

Parse from official gate hours / visitor access pages.

### `resources` → Explore (Resources)

| Field | Notes |
|-------|-------|
| `category` | See allowed values below |
| `description`, `hours`, `address`, `phone`, `url`, `building` | Optional; prefer direct fields over legacy `type`/`value` |

**`category` values (exact strings):**  
`dining`, `recreation`, `services`, `shopping`, `fitness`, `medical`, `finance`, `housing`, `safety`, `other`

Typical entries: DFAC(s), BX, commissary, medical, MPF, housing, visitor center, fitness, FSS, banks, major MWR.

### `events` → Explore (Events)

| Field | Notes |
|-------|-------|
| `date` / `endDate` | ISO 8601 UTC; `endDate` optional |
| `category` | `holiday`, `family`, `outdoor`, `community`, `fitness` (optional) |

Use `[]` if none.

### `newcomers` → Newcomers tab

```json
{
  "primaryAction": { "title": "...", "url": "...", "phone": "...", "address": "..." },
  "moreInfoURL": "https://www.example.af.mil/Newcomers/",
  "sections": [ ... ]
}
```

- `primaryAction` is optional; app falls back to Visitor Center / MPF resource if omitted.
- Recommended sections: **Required Documents**, **In-Processing Schedule**, **Housing**, **Sponsor Program**, **Quick Resources**.
- Each section: `{ id, title, body, links }` where `links` is an array of `{ id, title, url }` or `null`.

## Data quality

- Do not invent phone numbers, hours, or URLs.
- Prefer official `.mil`, FSS, and published visitor/gate pages.
- Invalid enum strings will fail JSON decoding at runtime.
- After adding a base, every index entry must have a matching `{id}.json` (covered by `LocalJSONDataServiceTests`).

## Remote updates (GitHub)

The same JSON in this folder is fetched at runtime from GitHub (`raw.githubusercontent.com`) so hours, gate status, and alerts can change without an App Store release.

1. Edit `{id}.json` and set `dataUpdatedAt` to the current UTC timestamp.
2. Merge to `main` on GitHub.
3. The app syncs on launch and when the user pull-to-refreshes Home.

Bundled copies in the app binary remain the offline fallback. Remote data is used when `dataUpdatedAt` is newer.

Repository URL is configured in `Services/BaseDataRemoteConfig.swift`.

## Swift source for enums

See `Utils/Constants.swift` for `ResourceCategory`, `NotificationType`, `GateStatus`, `TrafficLevel`, `EventCategory`.
