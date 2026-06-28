import Foundation

enum BaseCatalog: Sendable {
    /// CONUS installations with enriched JSON content. OCONUS entries stay in the
    /// bundle for development and testing but are hidden from the base picker.
    nonisolated static let pickerListedBaseIDs: Set<String> = [
        "air-force-academy",
        "altus",
        "andrews",
        "barksdale",
        "beale",
        "buckley",
        "cannon",
        "charleston",
        "columbus",
        "creech",
        "davis-monthan",
        "dover",
        "dyess",
        "edwards",
        "eglin",
        "ellsworth",
        "fairchild",
        "fe-warren",
        "goodfellow",
        "grand-forks",
        "grissom",
        "hanscom",
        "hill",
        "holloman",
        "hurlburt",
        "jbab",
        "jblm",
        "jbmdl",
        "keesler",
        "kirtland",
        "lackland",
        "langley",
        "laughlin",
        "little-rock",
        "los-angeles",
        "luke",
        "macdill",
        "malmstrom",
        "march",
        "maxwell",
        "mcconnell",
        "minot",
        "moody",
        "mountain-home",
        "nellis",
        "offutt",
        "patrick",
        "peterson",
        "pope",
        "randolph",
        "robins",
        "schriever",
        "scott",
        "seymour-johnson",
        "shaw",
        "sheppard",
        "tinker",
        "travis",
        "tyndall",
        "vance",
        "vandenberg",
        "whiteman",
        "wright-patterson",
    ]

    nonisolated static func isListedInPicker(_ entry: BaseIndexEntry) -> Bool {
        entry.region == .conus && pickerListedBaseIDs.contains(entry.id)
    }

    nonisolated static func pickerEntries(from index: [BaseIndexEntry]) -> [BaseIndexEntry] {
        index
            .filter(isListedInPicker)
            .sorted {
                $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
    }
}
