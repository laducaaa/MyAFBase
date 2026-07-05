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
    nonisolated static let stationed: [EssentialAFI] = [
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
}
