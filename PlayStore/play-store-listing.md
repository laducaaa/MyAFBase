# MyAFBase — Google Play Store Listing (v1.5.1)

Use these values when creating the app in [Google Play Console](https://play.google.com/console).

## URLs

| Field | Value |
|-------|-------|
| Website | https://myafbase.com |
| Support URL | https://myafbase.com/support |
| Privacy Policy URL | https://myafbase.com/privacy |

## Contact

| Purpose | Email |
|---------|-------|
| Support & feedback | support@myafbase.com |
| Privacy & legal | legal@myafbase.com |

## App details

| Field | Value |
|-------|-------|
| App name | MyAFBase |
| Package name | com.ryanladuca.myafbase |
| Category | Tools |
| Short description (80 chars max) | Unofficial Air Force base companion with PCS tools, PFRA, pay & leave planners |

## Full description

MyAFBase is the unofficial installation companion for U.S. Air Force Airmen. Gates, resources, readiness tools, and career planning in one native Android app.

Whether you're in-processing, stationed, or preparing to PCS, MyAFBase helps you navigate your base and stay ahead of the deadlines that matter — without spreadsheets, group chats, or another login.

YOUR BASE, AT A GLANCE
• 85 Air Force installations — gates, dining, fitness, medical, events, and emergency contacts
• See what's open now with live hours and status
• Explore on Google Maps with base-scoped search
• Pull to refresh for updated hours, gate status, and alerts
• Bookmark gates and resources to your Home dashboard

STAY READY
• Personal readiness tracker for PFRA, dental, CAC, immunizations, and custom due dates
• Reminders tab surfaces upcoming deadlines and award package suspenses
• PCS checklists and assignment phases (In Processing, Stationed, Out Processing)
• Home Screen widget: base name and next pay date

BUILT-IN TOOLS
• PFRA Score Calculator, Goal Planner, and Records
• Leave Planner — multi-trip planning and balance projection
• Pay Calendar — mid-month, month-end, and special pays
• Essential AFI Search — dress, leave, fitness, and more offline with PDF citations

WAR TRACKER
• Quick weekly log with categories, tags, and performance factors
• Reports for any date range — plain text, bullets, or PDF export
• Award deadline tracking with reminders
• Optional biometric lock and PII warnings before export
• Stored only on your device

IMPORTANT
MyAFBase is not affiliated with, endorsed by, or an official product of the U.S. Department of Defense, Department of the Air Force, or any military installation. All information is for planning and reference only — verify critical details through official channels.

Support: https://myafbase.com/support

## Store assets checklist

- [ ] App icon 512×512 PNG (export from adaptive icon)
- [ ] Feature graphic 1024×500 PNG
- [ ] Phone screenshots (min 2): Home, Explore, Assignment, PFRA, WAR, Reminders
- [ ] 7-inch tablet screenshots (optional)
- [ ] 10-inch tablet screenshots (optional)

## Release checklist

See [DATA_SAFETY.md](DATA_SAFETY.md) for the Data safety form.

1. Register Play Console developer account ($25)
2. Create app with package `com.ryanladuca.myafbase`
3. Complete developer identity verification
4. Generate upload keystore: `keytool -genkey -v -keystore myafbase-upload.jks ...`
5. Copy `keystore.properties.example` → `keystore.properties`
6. Build release AAB: `cd android && ./gradlew :app:bundleRelease`
7. Upload to Internal testing track
8. Complete Data safety, Content rating (IARC), Target audience
9. Run pre-launch report; fix any crashes
10. Promote to Closed testing → Production staged rollout

## What's New (v1.5.1)

• Android launch with core parity to iOS 1.5.1
• PFRA Records — save scores and track trends
• Readiness notifications with per-date reminders
• WAR reports with date presets and export formats
• In-processing newcomer guides with tappable links
