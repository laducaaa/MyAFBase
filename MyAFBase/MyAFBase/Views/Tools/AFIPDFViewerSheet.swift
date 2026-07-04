import PDFKit
import SwiftUI

/// What to show in the in-app PDF viewer: which document, and which page to jump to.
struct AFIPDFPreviewContext: Identifiable {
    let url: URL
    let page: Int?
    let title: String

    var id: String { "\(url.absoluteString)#\(page ?? 0)" }

    /// Returns a context for results backed by a bundled PDF; nil when the
    /// publication is only available as a web link.
    init?(result: AFISearchResult) {
        guard let url = result.pdfURL, url.isFileURL else { return nil }
        self.url = url
        self.page = result.chunk.page
        self.title = result.chunk.publication
    }

    /// Opens a bundled Essential AFI from the quick-access grid (page 1).
    init?(afi: EssentialAFI) {
        guard let url = AFICorpusBundledResources.bundledPDFURL(for: afi.id) else { return nil }
        self.url = url
        self.page = nil
        self.title = afi.publication
    }
}

/// In-app PDF reader that opens directly to the cited page.
struct AFIPDFViewerSheet: View {
    let context: AFIPDFPreviewContext

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            AFIPDFKitView(url: context.url, page: context.page)
                .ignoresSafeArea(edges: .bottom)
                .navigationTitle(context.title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Done") { dismiss() }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        ShareLink(item: context.url) {
                            Image(systemName: "square.and.arrow.up")
                        }
                        .accessibilityLabel("Share PDF")
                    }
                }
        }
    }
}

private struct AFIPDFKitView: UIViewRepresentable {
    let url: URL
    let page: Int?

    func makeUIView(context: Context) -> PDFView {
        let view = PDFView()
        view.autoScales = true
        view.displayMode = .singlePageContinuous
        view.displayDirection = .vertical
        view.backgroundColor = .systemGroupedBackground

        // Large publications (AFH 1 is ~60 MB) can take a moment to open;
        // load off the main thread so the sheet appears instantly.
        let targetPage = page
        DispatchQueue.global(qos: .userInitiated).async {
            let document = PDFDocument(url: url)
            DispatchQueue.main.async {
                view.document = document
                if let targetPage,
                   targetPage > 0,
                   let pdfPage = document?.page(at: targetPage - 1) {
                    view.go(to: pdfPage)
                }
            }
        }

        return view
    }

    func updateUIView(_ uiView: PDFView, context: Context) {}
}
