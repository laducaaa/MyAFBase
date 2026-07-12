# Android MyAFBase — iOS parity notes

## Shipped on Android

- 5-tab shell with brand-tinted navigation, onboarding (monochrome flow), CONUS base picker
- Bundled + remote base JSON (GitHub raw)
- Explore list (category icon bar, open-now chip, inline Resources/Events segmented control) + map view with list/map toggle
- Explore detail sheets for gates, resources, and events
- Home weather hero (condition-aware gradients), bento tools grid, home reminder strip, emergency CTA
- Assignment phases with tinted headers, tip banner, PCS tool links (incl. PFRA Score)
- Reminders with next-pay hero card, sectioned readiness/WAR rows
- Menu with installation phase segmented control, quick links, preferences
- Pay Calendar with hero card, collapsible insights accordion, special pays
- PFRA score/goals/records with component score bars, circular steppers, save toast
- Leave Planner, WAR tracker (+ PDF export, biometric lock), hybrid AFI search (FTS + on-device embeddings)
- Full Glance widget suite: pay, weather, open-now, emergency, readiness, WAR quick-log
- Global WAR quick-log sheet from widget/deep link
- WorkManager semantic embedding backfill for AFI search
- Local notifications suite (readiness + WAR)
- Branded launcher icon, splash screen, release signing scaffold

## UI parity status (2026)

Android mirrors iOS brand tokens on API 26–30 with a complete Material 3 `ColorScheme` derived from the locked palette. On **Android 12+ (API 31+)**, the app uses **Material You** dynamic colors from the system wallpaper via `dynamicLightColorScheme` / `dynamicDarkColorScheme`, with static palette fallback on older devices. iOS keeps a fixed brand palette.

Widget snapshots are published through `WidgetDataStore` (DataStore JSON) and refreshed from `WidgetSync` on base/weather/bookmark/readiness/WAR changes.

## iOS-only or deferred

- Siri / App Intents (Android uses widget/deep-link equivalents for WAR quick-log)
- iCloud sync for bookmarks/checklists/assignment
- NWS primary weather path (Android uses Open-Meteo)
- Apple Watch

## Android launch additions (v1.5.1+)

- Six Glance widgets with shared snapshot sync
- Hybrid AFI search with SQLite FTS5 + on-device embeddings
- Explore location/event detail sheets
- `ContactConfig` centralized support/legal URLs
