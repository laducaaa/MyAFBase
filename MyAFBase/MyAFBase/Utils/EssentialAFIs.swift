import Foundation

struct EssentialAFI: Identifiable, Equatable {
    let id: String
    let title: String
    let publication: String
    let systemImage: String
    let urlString: String

    var url: URL? {
        URL(string: urlString)
    }
}

/// Commonly referenced Air Force publications for quick access on the Stationed tab.
/// PDF links point to official AF e-Publishing static hosting.
enum EssentialAFIs {
    static let searchSuggestions: [String] = [
        "convalescent leave",
        "PT test",
        "beard waiver",
        "air force",
        "ordinary leave"
    ]

    static let stationed: [EssentialAFI] = [
        EssentialAFI(
            id: "dress-appearance",
            title: "Dress & Appearance",
            publication: "DAFI 36-2903",
            systemImage: "tshirt.fill",
            urlString: "https://static.e-publishing.af.mil/production/1/af_a1/publication/dafi36-2903/dafi36-2903.pdf"
        ),
        EssentialAFI(
            id: "afh1",
            title: "The Air Force",
            publication: "AFH 1 · Blue Book",
            systemImage: "book.closed.fill",
            urlString: "https://static.e-publishing.af.mil/production/1/af_a1/publication/afh1/afh1.pdf"
        ),
        EssentialAFI(
            id: "enlisted-force",
            title: "Enlisted Force",
            publication: "DAFI 36-2618",
            systemImage: "person.3.fill",
            urlString: "https://static.e-publishing.af.mil/production/1/af_a1/publication/dafi36-2618/dafi36-2618.pdf"
        ),
        EssentialAFI(
            id: "officer-pd",
            title: "Officer Development",
            publication: "DAFI 36-2643",
            systemImage: "star.circle.fill",
            urlString: "https://static.e-publishing.af.mil/production/1/af_a1/publication/dafi36-2643/dafi36-2643.pdf"
        ),
        EssentialAFI(
            id: "fitness",
            title: "Fitness Program",
            publication: "DAFI 36-2905",
            systemImage: "figure.run",
            urlString: "https://static.e-publishing.af.mil/production/1/af_a1/publication/dafi36-2905/dafi36-2905.pdf"
        ),
        EssentialAFI(
            id: "decorations",
            title: "Decorations",
            publication: "DAFMAN 36-2806",
            systemImage: "medal.fill",
            urlString: "https://static.e-publishing.af.mil/production/1/af_a1/publication/dafman36-2806/dafman36-2806.pdf"
        ),
        EssentialAFI(
            id: "leave",
            title: "Military Leave",
            publication: "DAFI 36-3003",
            systemImage: "calendar",
            urlString: "https://static.e-publishing.af.mil/production/1/af_a1/publication/dafi36-3003/dafi36-3003.pdf"
        ),
        EssentialAFI(
            id: "justice",
            title: "Military Justice",
            publication: "DAFI 51-201",
            systemImage: "scale.3d",
            urlString: "https://static.e-publishing.af.mil/production/1/af_ja/publication/dafi51-201/dafi51-201.pdf"
        )
    ]

    static let ePublishingIndex = URL(string: "https://www.e-publishing.af.mil/")!

    static func filtered(query: String) -> [EssentialAFI] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return stationed }

        return stationed.filter { afi in
            afi.title.localizedCaseInsensitiveContains(trimmed)
                || afi.publication.localizedCaseInsensitiveContains(trimmed)
                || searchKeywords(for: afi).contains { $0.localizedCaseInsensitiveContains(trimmed) }
        }
    }

    private static func searchKeywords(for afi: EssentialAFI) -> [String] {
        switch afi.id {
        case "dress-appearance":
            ["appearance", "beard", "grooming", "uniform", "waiver"]
        case "afh1":
            ["air force", "blue book", "culture", "heritage"]
        case "enlisted-force":
            ["enlisted", "promotion", "development"]
        case "officer-pd":
            ["officer", "development", "promotion"]
        case "fitness":
            ["fitness", "pt", "test", "physical", "assessment"]
        case "decorations":
            ["decoration", "award", "medal"]
        case "leave":
            ["leave", "convalescent", "ordinary", "emergency", "pass"]
        case "justice":
            ["justice", "ucmj", "article 15"]
        default:
            []
        }
    }
}
