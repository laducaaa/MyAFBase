# MyAFBase Android

Jetpack Compose port of MyAFBase. Shares the same bundled base JSON and remote GitHub raw URLs as iOS.

## Requirements

- Android Studio / JDK 17+
- minSdk 26, targetSdk 36

## Android Studio

Open the **`android/`** folder as the project root (not the monorepo root). If you open `MyAFBase/` at the top level, the **app** run configuration will fail with "Cannot obtain the application ID".

After opening `android/`, wait for Gradle sync, then run the **app** configuration.

## Run

```bash
cd android
./gradlew :app:assembleDebug
./gradlew :app:testDebugUnitTest
```

Install the debug APK from `app/build/outputs/apk/debug/`.

## Optional Maps key

Add to `android/gradle.properties`:

```
MAPS_API_KEY=your_google_maps_key
```

Without a key, Explore map may render blank tiles; directions intents still work from list rows.

## Material You (Android 12+)

On API 31+, the app uses wallpaper-driven dynamic colors. API 26–30 keeps the static brand palette. iOS remains brand-locked.

## Release build

1. Copy `keystore.properties.example` to `keystore.properties` and fill in your upload keystore.
2. Build: `./gradlew :app:bundleRelease`
3. Upload `app/build/outputs/bundle/release/app-release.aab` to Play Console.

See `PlayStore/play-store-listing.md` and `PlayStore/DATA_SAFETY.md` for store setup.

## Architecture

- `ui/` — Compose screens (5-tab shell + tools)
- `data/` — Room, DataStore, JSON assets/cache, remote sync, weather/AFI/feedback
- `domain/` — models + portable logic (hours, PCS, pay, leave, PFRA)

## iOS-only / later

- Siri / App Intents (Android uses widget/deep-link for WAR quick-log)
- iCloud sync
- NWS-primary weather (Android uses Open-Meteo)
- Apple Watch

## Feature parity (v1.5.1+)

- Six Glance widgets with shared snapshot sync (`WidgetDataStore`)
- Hybrid AFI search: SQLite FTS + on-device embeddings + WorkManager backfill
- Explore location/event detail sheets
- Global WAR quick-log from widget/deep link

See `PARITY.md` for the full shipped vs deferred list.
