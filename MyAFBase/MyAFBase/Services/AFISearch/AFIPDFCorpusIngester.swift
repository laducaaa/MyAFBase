import Foundation
import PDFKit

nonisolated enum AFIPDFCorpusIngester {
    private static let chunkSize = 900
    private static let chunkOverlap = 120
    private static let minimumChunkLength = 60

    static func ingestFromBundle(
        progress: @Sendable (Double, String) -> Void
    ) throws -> AFICorpus {
        var allChunks: [AFICorpusChunk] = []
        let publications = EssentialAFIs.stationed
        let total = Double(max(publications.count, 1))

        for (index, publication) in publications.enumerated() {
            progress(Double(index) / total, "Reading \(publication.publication)…")

            guard let pdfURL = AFICorpusBundledResources.bundledPDFURL(for: publication.id) else {
                continue
            }

            let pdfData = try Data(contentsOf: pdfURL)
            let chunks = extractChunks(from: pdfData, publication: publication)
            allChunks.append(contentsOf: chunks)

            progress((Double(index) + 1) / total, "Parsed \(publication.publication)")
        }

        guard !allChunks.isEmpty else {
            throw AFIPDFCorpusIngesterError.noChunksExtracted
        }

        return makeCorpus(chunks: allChunks, source: "bundle")
    }

    private static func makeCorpus(chunks: [AFICorpusChunk], source: String) -> AFICorpus {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        let timestamp = formatter.string(from: Date())

        return AFICorpus(
            version: "\(source)-\(timestamp.prefix(10))",
            dataUpdatedAt: timestamp,
            chunks: chunks
        )
    }

    static func extractChunks(from pdfData: Data, publication: EssentialAFI) -> [AFICorpusChunk] {
        guard let document = PDFDocument(data: pdfData) else { return [] }

        var chunks: [AFICorpusChunk] = []
        var currentChapter: String?
        let pageCount = document.pageCount

        for pageIndex in 0 ..< pageCount {
            guard let page = document.page(at: pageIndex) else { continue }
            let pageNumber = pageIndex + 1
            let (pageText, chapter) = cleanPage(page.string ?? "")
            if let chapter {
                currentChapter = chapter
            }
            chunks.append(contentsOf: chunkPageText(
                pageText,
                publication: publication,
                pageNumber: pageNumber,
                chapter: currentChapter
            ))
        }

        return chunks
    }

    // MARK: - Private

    private static func chunkPageText(
        _ pageText: String,
        publication: EssentialAFI,
        pageNumber: Int,
        chapter: String?
    ) -> [AFICorpusChunk] {
        let text = cleanText(pageText)
        guard text.count >= minimumChunkLength else { return [] }

        var chunks: [AFICorpusChunk] = []
        var start = text.startIndex
        var localIndex = 0

        while start < text.endIndex {
            let end = chunkEndIndex(in: text, startingAt: start)
            let piece = cleanText(String(text[start ..< end]))
            if piece.count >= minimumChunkLength, alphaRatio(piece) >= 0.6 {
                chunks.append(
                    AFICorpusChunk(
                        id: "\(publication.id)-p\(String(format: "%04d", pageNumber))-\(String(format: "%03d", localIndex))",
                        publicationID: publication.id,
                        publication: publication.publication,
                        title: publication.title,
                        section: sectionLabel(chapter: chapter, piece: piece),
                        page: pageNumber,
                        text: piece
                    )
                )
                localIndex += 1
            }

            if end >= text.endIndex { break }
            let overlapStart = text.index(end, offsetBy: -chunkOverlap, limitedBy: start) ?? start
            start = text.index(after: overlapStart > start ? overlapStart : start)
        }

        return chunks
    }

    private static func chunkEndIndex(in text: String, startingAt start: String.Index) -> String.Index {
        let maxEnd = text.index(start, offsetBy: chunkSize, limitedBy: text.endIndex) ?? text.endIndex
        guard maxEnd < text.endIndex else { return maxEnd }

        let searchStart = text.index(start, offsetBy: chunkSize / 2, limitedBy: maxEnd) ?? start
        if let space = text[searchStart ..< maxEnd].lastIndex(of: " ") {
            return text.index(after: space)
        }

        return maxEnd
    }

    private static func cleanText(_ text: String) -> String {
        text
            .replacingOccurrences(of: "\u{0000}", with: " ")
            .replacingOccurrences(of: #"[ \t]+"#, with: " ", options: .regularExpression)
            .replacingOccurrences(of: #"\n{3,}"#, with: "\n\n", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // Mirrors scripts/ingest_afi_corpus.py so device-parsed chunks match the
    // quality of the pre-built corpus.

    private static let dotLeaderRegex = try? NSRegularExpression(pattern: #"\.{4,}"#)
    private static let headerFooterRegex = try? NSRegularExpression(
        pattern: #"^\s*\d{0,4}\s*(?:DAFI|DAFMAN|DAFH|AFMAN|AFI|AFH|AFPD)\s*\d[\d\-. ]*.{0,40}?(?:JANUARY|FEBRUARY|MARCH|APRIL|MAY|JUNE|JULY|AUGUST|SEPTEMBER|OCTOBER|NOVEMBER|DECEMBER)\s+\d{4}\s*\d{0,4}\s*$"#,
        options: [.caseInsensitive]
    )
    private static let pageNumberLineRegex = try? NSRegularExpression(pattern: #"^\s*\d{1,4}\s*$"#)
    private static let chapterRegex = try? NSRegularExpression(
        pattern: #"^\s*Chapter\s+(\d{1,2})\s*[—–\-]?\s*(.*)$"#,
        options: [.caseInsensitive]
    )
    private static let paragraphRefRegex = try? NSRegularExpression(
        pattern: #"(?<!Figure )(?<!Table )\b(\d{1,2}(?:\.\d{1,3}){1,4})\.\s"#
    )

    /// Removes TOC dot leaders, running headers/footers, and bare page numbers.
    /// Returns the cleaned text and the last chapter heading found on the page.
    private static func cleanPage(_ pageText: String) -> (text: String, chapter: String?) {
        var keptLines: [String] = []
        var chapter: String?

        for rawLine in pageText.components(separatedBy: .newlines) {
            let line = rawLine
                .replacingOccurrences(of: "\u{0000}", with: " ")
                .replacingOccurrences(of: #"[ \t]+"#, with: " ", options: .regularExpression)
                .trimmingCharacters(in: .whitespaces)

            if line.isEmpty {
                keptLines.append("")
                continue
            }

            let fullRange = NSRange(line.startIndex ..< line.endIndex, in: line)
            if dotLeaderRegex?.firstMatch(in: line, range: fullRange) != nil { continue }
            if headerFooterRegex?.firstMatch(in: line, range: fullRange) != nil { continue }
            if pageNumberLineRegex?.firstMatch(in: line, range: fullRange) != nil { continue }

            if let match = chapterRegex?.firstMatch(in: line, range: fullRange),
               let numberRange = Range(match.range(at: 1), in: line) {
                let number = String(line[numberRange])
                var rest = ""
                if let restRange = Range(match.range(at: 2), in: line) {
                    rest = String(line[restRange])
                    if let urlRange = rest.range(of: #"https?://"#, options: .regularExpression) {
                        rest = String(rest[..<urlRange.lowerBound])
                    }
                    rest = rest.trimmingCharacters(in: CharacterSet(charactersIn: " .,—–-"))
                    // Cut glued-on table headers like rank abbreviations ("SSgt TSgt…").
                    if let abbrevRange = rest.range(of: #"\b[A-Z]{2,}[a-z]+\b"#, options: .regularExpression) {
                        rest = String(rest[..<abbrevRange.lowerBound])
                            .trimmingCharacters(in: CharacterSet(charactersIn: " .,—–-"))
                    }
                    if rest == rest.uppercased() {
                        rest = rest.capitalized
                    }
                    rest = String(rest.prefix(48)).trimmingCharacters(in: .whitespaces)
                }
                chapter = "Chapter \(number)" + (rest.isEmpty ? "" : " — \(rest)")
            }

            keptLines.append(line)
        }

        return (cleanText(keptLines.joined(separator: "\n")), chapter)
    }

    private static func alphaRatio(_ text: String) -> Double {
        guard !text.isEmpty else { return 0 }
        let letters = text.unicodeScalars.filter {
            CharacterSet.letters.contains($0) || CharacterSet.whitespaces.contains($0)
        }
        return Double(letters.count) / Double(text.unicodeScalars.count)
    }

    private static func sectionLabel(chapter: String?, piece: String) -> String? {
        var paragraph: String?
        let head = String(piece.prefix(250))
        if let match = paragraphRefRegex?.firstMatch(
            in: head,
            range: NSRange(head.startIndex ..< head.endIndex, in: head)
        ), let range = Range(match.range(at: 1), in: head) {
            paragraph = String(head[range])
        }

        switch (chapter, paragraph) {
        case let (chapter?, paragraph?):
            return "\(chapter) · Para \(paragraph)"
        case let (chapter?, nil):
            return chapter
        case let (nil, paragraph?):
            return "Para \(paragraph)"
        default:
            return nil
        }
    }
}

enum AFIPDFCorpusIngesterError: LocalizedError {
    case noChunksExtracted
    case missingBundledPDFs

    var errorDescription: String? {
        switch self {
        case .noChunksExtracted:
            "No searchable text could be extracted from the AFI PDFs."
        case .missingBundledPDFs:
            "No bundled AFI PDFs were found in the app."
        }
    }
}
