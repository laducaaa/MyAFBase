import Foundation

enum BaseCatalog {
    /// CONUS installations with enriched JSON content. All other index entries stay in the
    /// bundle for development and testing but are hidden from the base picker.
    static let pickerListedBaseIDs: Set<String> = [
        "andrews",
        "barksdale",
        "beale",
        "charleston",
        "dover",
        "eglin",
        "fe-warren",
        "hill",
        "hurlburt",
        "jbab",
        "jbmdl",
        "keesler",
        "lackland",
        "langley",
        "luke",
        "macdill",
        "mountain-home",
        "nellis",
        "patrick",
        "randolph",
        "scott",
        "shaw",
        "sheppard",
        "tinker",
        "travis",
        "vandenberg",
        "whiteman",
        "wright-patterson",
    ]

    static func isListedInPicker(_ entry: BaseIndexEntry) -> Bool {
        entry.region == .conus && pickerListedBaseIDs.contains(entry.id)
    }

    static func pickerEntries(from index: [BaseIndexEntry]) -> [BaseIndexEntry] {
        index
            .filter(isListedInPicker)
            .sorted {
                $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
    }
}
