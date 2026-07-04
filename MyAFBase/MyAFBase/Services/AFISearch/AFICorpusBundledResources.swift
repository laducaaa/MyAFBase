import Foundation

enum AFICorpusBundledResources {
    private static let pdfSubdirectories = ["Resources/AFI/PDFs", "AFI/PDFs", nil as String?]

    nonisolated static func bundledPDFURL(for publicationID: String) -> URL? {
        for subdirectory in pdfSubdirectories {
            if let subdirectory {
                if let url = Bundle.main.url(
                    forResource: publicationID,
                    withExtension: "pdf",
                    subdirectory: subdirectory
                ) {
                    return url
                }
            } else if let url = Bundle.main.url(forResource: publicationID, withExtension: "pdf") {
                return url
            }
        }
        return nil
    }

    nonisolated static var bundledPDFCount: Int {
        EssentialAFIs.stationed.filter { bundledPDFURL(for: $0.id) != nil }.count
    }

    nonisolated static var hasBundledPDFs: Bool {
        bundledPDFCount > 0
    }
}

enum AFICorpusQuality {
    nonisolated static let minimumChunks = 50

    nonisolated static func isSearchReady(_ corpus: AFICorpus) -> Bool {
        !corpus.version.hasPrefix("seed-") && corpus.chunks.count >= minimumChunks
    }

    nonisolated static func needsBundledPDFParse(_ corpus: AFICorpus) -> Bool {
        !isSearchReady(corpus) && AFICorpusBundledResources.hasBundledPDFs
    }
}
