import Foundation

struct NewcomersInfo: Codable, Equatable {
    let primaryAction: NewcomerPrimaryAction?
    let moreInfoURL: String?
    let sections: [NewcomerSection]

    init(
        primaryAction: NewcomerPrimaryAction? = nil,
        moreInfoURL: String? = nil,
        sections: [NewcomerSection]
    ) {
        self.primaryAction = primaryAction
        self.moreInfoURL = moreInfoURL
        self.sections = sections
    }

    func resolvedPrimaryAction(resources: [Resource]) -> NewcomerPrimaryAction? {
        if let primaryAction { return primaryAction }

        let keywords = ["Visitor Center", "Visitor Control", "Pass & Registration", "Personnel Section"]
        guard let resource = resources.first(where: { resource in
            keywords.contains { resource.name.localizedCaseInsensitiveContains($0) }
        }) else {
            return nil
        }

        let title = resource.name.localizedCaseInsensitiveContains("Visitor") ? "Visitor Center" : "Reporting"
        return NewcomerPrimaryAction(
            title: title,
            url: resource.displayURL,
            phone: resource.displayPhone,
            address: resource.displayAddress
        )
    }

    func resolvedMoreInfoURL() -> String? {
        if let moreInfoURL { return moreInfoURL }
        return sections.compactMap(\.links).flatMap { $0 }.first?.url
    }
}

struct NewcomerPrimaryAction: Codable, Equatable, Identifiable {
    let title: String
    let url: String?
    let phone: String?
    let address: String?

    var id: String { title }
}

struct NewcomerSection: Codable, Identifiable, Equatable, Hashable {
    let id: String
    let title: String
    let body: String
    let links: [NewcomerLink]?
    let icon: String?

    var displayIcon: String {
        if let icon { return icon }
        let lower = title.lowercased()
        if lower.contains("document") { return "doc.text.fill" }
        if lower.contains("schedule") || lower.contains("in-processing") { return "calendar" }
        if lower.contains("housing") { return "house.fill" }
        if lower.contains("sponsor") { return "person.2.fill" }
        if lower.contains("permanent") { return "briefcase.fill" }
        return "link"
    }
}

struct NewcomerLink: Codable, Identifiable, Equatable, Hashable {
    let id: String
    let title: String
    let url: String
}
