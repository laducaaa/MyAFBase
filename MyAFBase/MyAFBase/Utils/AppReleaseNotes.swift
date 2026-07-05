import Foundation

struct AppReleaseNote: Identifiable, Equatable {
    let version: String
    let title: String
    let highlights: [AppReleaseHighlight]

    var id: String { version }
}

struct AppReleaseHighlight: Identifiable, Equatable {
    let systemImage: String
    let title: String
    let detail: String?

    var id: String { title }

    init(systemImage: String, title: String, detail: String? = nil) {
        self.systemImage = systemImage
        self.title = title
        self.detail = detail
    }
}

enum AppReleaseNotes {
    static var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    static var current: AppReleaseNote {
        if let match = all.first(where: { $0.version == appVersion }) {
            return match
        }
        return all.first ?? AppReleaseNote(version: appVersion, title: "What's New", highlights: [])
    }

    static var earlier: [AppReleaseNote] {
        all.filter { $0.version != current.version }
    }

    static let all: [AppReleaseNote] = [
        AppReleaseNote(
            version: "1.5",
            title: "In development",
            highlights: []
        ),
        AppReleaseNote(
            version: "1.4",
            title: "WAR Tracker",
            highlights: [
                AppReleaseHighlight(
                    systemImage: "text.badge.star",
                    title: "WAR Tracker",
                    detail: "Log daily accomplishments by week with categories, tags, and performance factors — ready for EPB/OPB closeout."
                ),
                AppReleaseHighlight(
                    systemImage: "chart.bar.doc.horizontal",
                    title: "Reports & PDF export",
                    detail: "Generate plain-text or bullet summaries for any date range, then copy, share, or export a formatted PDF."
                ),
                AppReleaseHighlight(
                    systemImage: "flag.checkered",
                    title: "Award deadlines",
                    detail: "Track package suspenses with due dates, notes, and reminders surfaced on the Reminders tab."
                ),
                AppReleaseHighlight(
                    systemImage: "lock.fill",
                    title: "Privacy controls",
                    detail: "Optional Face ID lock, auto-retention for old entries, and PII warnings before you export."
                ),
                AppReleaseHighlight(
                    systemImage: "square.grid.2x2.fill",
                    title: "Quick log widget & Siri",
                    detail: "Log an accomplishment from the Home Screen widget or with a Siri shortcut — without opening the full tracker."
                )
            ]
        ),
        AppReleaseNote(
            version: "1.3",
            title: "Elevated design & stability",
            highlights: [
                AppReleaseHighlight(
                    systemImage: "square.stack.3d.up.fill",
                    title: "Unified card design",
                    detail: "Home, Explore, Assignment, Menu, and tools now share the same elevated cards and icon badges for a cleaner, more consistent look."
                ),
                AppReleaseHighlight(
                    systemImage: "house.fill",
                    title: "Refined Home screen",
                    detail: "Tools, saved items, emergency contacts, and the weather hero use the same visual language — less clutter, easier to scan."
                ),
                AppReleaseHighlight(
                    systemImage: "magnifyingglass",
                    title: "Explore polish",
                    detail: "Resource, gate, and event cards match Home's saved section, with improved spacing under the Open Now filter."
                ),
                AppReleaseHighlight(
                    systemImage: "bolt.fill",
                    title: "Faster & more reliable",
                    detail: "Fixed a widget bug that could clear saved bookmarks on launch, reduced redundant data fetches, and tightened Explore list filtering."
                ),
                AppReleaseHighlight(
                    systemImage: "checkmark.shield.fill",
                    title: "Swift 6 ready",
                    detail: "Resolved all compiler concurrency warnings and corrected a Little Rock base data issue caught by integrity tests."
                )
            ]
        ),
        AppReleaseNote(
            version: "1.2",
            title: "Smarter tools & Essential AFIs",
            highlights: [
                AppReleaseHighlight(
                    systemImage: "doc.text.magnifyingglass",
                    title: "Essential AFI Search",
                    detail: "Search key publications offline from Home → Tools, with citations that open the official PDFs."
                ),
                AppReleaseHighlight(
                    systemImage: "figure.strengthtraining.functional",
                    title: "PFRA tools redesigned",
                    detail: "Score Calculator and Goal Planner use clearer cards, inline progress, and compact stepper controls."
                ),
                AppReleaseHighlight(
                    systemImage: "calendar.badge.clock",
                    title: "Leave Planner expanded",
                    detail: "Plan multiple trips, project your balance by date, or model PCS leave caps — all from one planner."
                ),
                AppReleaseHighlight(
                    systemImage: "dollarsign.circle.fill",
                    title: "Pay Calendar insights",
                    detail: "Collapsible warnings when weekend pay shifts create gaps longer than two weeks between deposits."
                )
            ]
        ),
        AppReleaseNote(
            version: "1.1",
            title: "Reminders, maps & assignment flow",
            highlights: [
                AppReleaseHighlight(
                    systemImage: "calendar.badge.clock",
                    title: "Personal reminders",
                    detail: "Reminders tab replaces base alerts with readiness due dates from Assignment."
                ),
                AppReleaseHighlight(
                    systemImage: "map.fill",
                    title: "Explore map mode",
                    detail: "Native Apple Maps POIs, base-scoped search, and a bounded map area."
                ),
                AppReleaseHighlight(
                    systemImage: "dollarsign.circle.fill",
                    title: "Pay at a glance",
                    detail: "Pay Calendar widget and next-pay card on Reminders keep pay dates visible."
                ),
                AppReleaseHighlight(
                    systemImage: "suitcase.fill",
                    title: "Assignment phases",
                    detail: "Set In Processing, Stationed, or Out Processing in Menu — My Assignment shows only what's relevant."
                ),
                AppReleaseHighlight(
                    systemImage: "line.3.horizontal",
                    title: "Refreshed Menu",
                    detail: "Card-based sections matching Home and Assignment."
                )
            ]
        ),
        AppReleaseNote(
            version: "1.0",
            title: "Welcome to MyAFBase",
            highlights: [
                AppReleaseHighlight(
                    systemImage: "building.2.fill",
                    title: "Installation guide",
                    detail: "Browse gates, dining, fitness, medical, events, and resources for your base."
                ),
                AppReleaseHighlight(
                    systemImage: "house.fill",
                    title: "Home dashboard",
                    detail: "Weather, emergency contacts, tools, open-now picks, and saved items."
                ),
                AppReleaseHighlight(
                    systemImage: "figure.run",
                    title: "Built-in planners",
                    detail: "PFRA Score Calculator, Goal Planner, and Leave Planner."
                ),
                AppReleaseHighlight(
                    systemImage: "checklist",
                    title: "PCS readiness",
                    detail: "Checklists, readiness tracker, and assignment phase support."
                ),
                AppReleaseHighlight(
                    systemImage: "square.grid.2x2.fill",
                    title: "Home Screen widgets",
                    detail: "Readiness, weather, open-now, emergency, and pay widgets."
                )
            ]
        )
    ]
}
