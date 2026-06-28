import Foundation

struct AppReleaseNote: Identifiable, Equatable {
    let version: String
    let title: String
    let highlights: [AppReleaseHighlight]

    var id: String { version }
}

struct AppReleaseHighlight: Identifiable, Equatable {
    let systemImage: String
    let text: String

    var id: String { text }
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
            version: "1.2",
            title: "In development",
            highlights: []
        ),
        AppReleaseNote(
            version: "1.1",
            title: "Reminders, maps & assignment flow",
            highlights: [
                AppReleaseHighlight(
                    systemImage: "calendar.badge.clock",
                    text: "Reminders tab replaces base alerts with your personal readiness due dates from Assignment."
                ),
                AppReleaseHighlight(
                    systemImage: "map.fill",
                    text: "Explore map mode uses native Apple Maps POIs, base-scoped search, and a bounded map area."
                ),
                AppReleaseHighlight(
                    systemImage: "dollarsign.circle.fill",
                    text: "Pay Calendar widget and next-pay card on Reminders keep pay dates visible at a glance."
                ),
                AppReleaseHighlight(
                    systemImage: "suitcase.fill",
                    text: "Set In Processing, Stationed, or Out Processing in Menu — My Assignment shows only what's relevant."
                ),
                AppReleaseHighlight(
                    systemImage: "line.3.horizontal",
                    text: "Refreshed Menu layout with card-based sections matching Home and Assignment."
                )
            ]
        ),
        AppReleaseNote(
            version: "1.0",
            title: "Welcome to MyAFBase",
            highlights: [
                AppReleaseHighlight(
                    systemImage: "building.2.fill",
                    text: "Browse gates, dining, fitness, medical, events, and resources for your installation."
                ),
                AppReleaseHighlight(
                    systemImage: "house.fill",
                    text: "Home dashboard with weather, emergency contacts, tools, open-now picks, and saved items."
                ),
                AppReleaseHighlight(
                    systemImage: "figure.run",
                    text: "PFRA Score Calculator, Goal Planner, and Leave Planner built in."
                ),
                AppReleaseHighlight(
                    systemImage: "checklist",
                    text: "PCS checklists, readiness tracker, and assignment phase support."
                ),
                AppReleaseHighlight(
                    systemImage: "square.grid.2x2.fill",
                    text: "Readiness, weather, open-now, emergency, and pay Home Screen widgets."
                )
            ]
        )
    ]
}
