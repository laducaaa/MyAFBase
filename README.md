# MyAFBase

iOS app for Air Force installation guides — gates, resources, alerts, assignment tools, and home-screen widgets.

## Repository layout

| Path | Purpose |
|------|---------|
| `MyAFBase/` | Xcode project, app target, widget extension |
| `MyAFBase/MyAFBase/Resources/Bases/` | Base JSON (bundled in the app **and** served remotely) |
| `scripts/` | Data generation / enrichment helpers |

## Remote base data (no App Store release required)

Base hours, gate status, and alerts can be updated by editing JSON in:

`MyAFBase/MyAFBase/Resources/Bases/`

When changes are pushed to `main` on GitHub, the app fetches updates from:

`https://raw.githubusercontent.com/<owner>/MyAFBase/main/MyAFBase/MyAFBase/Resources/Bases/`

**How it works**

1. The app ships with a full copy of every base JSON (offline fallback).
2. On launch and on pull-to-refresh, it syncs `bases_index.json` and the selected base file.
3. Remote data wins when `dataUpdatedAt` is newer than the bundled copy.
4. Fetched files are cached in Application Support for offline use.

**To publish an update**

1. Edit the relevant `{base-id}.json` (and `bases_index.json` if adding a base).
2. Bump `dataUpdatedAt` to the current UTC time (ISO 8601 with `Z`).
3. Open a PR, merge to `main`.
4. Users get the update within about an hour automatically, or immediately after pull-to-refresh on Home.

See `MyAFBase/MyAFBase/Resources/Bases/README.md` for the JSON schema.

**App config:** `BaseDataRemoteConfig.swift` — update `repository` if your GitHub org/user differs from `ryanladuca/MyAFBase`.

## Development

**Requirements:** Xcode 26+, iOS 26.2 deployment target

```bash
open MyAFBase/MyAFBase.xcodeproj
```

Run tests: **Product → Test** (⌘U)

## GitHub workflow

### First-time setup

```bash
cd /path/to/MyAFBase
git init
git add .
git commit -m "Initial commit: MyAFBase iOS app"
```

Create the repo on GitHub (website or CLI), then:

```bash
git branch -M main
git remote add origin git@github.com:YOUR_USERNAME/MyAFBase.git
git push -u origin main
```

### Day-to-day

```bash
# Start a feature
git checkout -b feature/pay-calendar

# Commit and push
git add .
git commit -m "Describe the change"
git push -u origin feature/pay-calendar
```

Open a pull request on GitHub, review, merge to `main`. Base JSON changes merged to `main` are live for the app immediately via raw GitHub URLs.

### Updating base data only

For hours/alert hotfixes you can commit directly to `main` or use a short-lived branch:

```bash
git checkout -b data/keesler-gate-hours
# edit MyAFBase/MyAFBase/Resources/Bases/keesler.json
git add MyAFBase/MyAFBase/Resources/Bases/keesler.json
git commit -m "Update Keesler gate hours"
git push -u origin data/keesler-gate-hours
# merge PR → users refresh
```

## Widgets

The `ReadinessWidget` extension includes Readiness Countdown, Weather, Open Now, and Emergency Contacts widgets. Both the app and widget use the App Group `group.com.ryanladuca.MyAFBase`.

## License

Private / unpublished — add a license before open-sourcing.
