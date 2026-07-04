import SwiftUI

struct AFISearchView: View {
    @Environment(AFISearchService.self) private var searchService
    @Environment(\.openURL) private var openURL

    @State private var query = ""
    @State private var results: [AFISearchResult] = []
    @State private var searchTask: Task<Void, Never>?
    @State private var didScheduleIndexPreparation = false
    @State private var pdfPreview: AFIPDFPreviewContext?
    @State private var detailResult: AFISearchResult?

    var body: some View {
        VStack(alignment: .leading, spacing: AssignmentMetrics.sectionSpacing) {
            AFISearchField(query: $query)

            contentArea

            LegalDisclaimerCard(
                text: LegalCopy.afiSearchDisclaimer,
                style: .compact,
                systemImage: "info.circle"
            )
        }
        .onAppear {
            scheduleIndexPreparationIfNeeded()
        }
        .onChange(of: query) { _, newValue in
            scheduleSearch(for: newValue)
        }
        .sheet(item: $pdfPreview) { context in
            AFIPDFViewerSheet(context: context)
        }
        .sheet(item: $detailResult) { result in
            AFISearchResultDetailSheet(result: result, query: query)
        }
    }

    private func openPDF(for result: AFISearchResult) {
        if let context = AFIPDFPreviewContext(result: result) {
            pdfPreview = context
        } else if let url = result.pdfURL {
            openURL(url)
        }
    }

    private func openQuickAccessPDF(for afi: EssentialAFI) {
        if let context = AFIPDFPreviewContext(afi: afi) {
            pdfPreview = context
        } else if let url = afi.url {
            openURL(url)
        }
    }

    @ViewBuilder
    private var contentArea: some View {
        if searchService.isIndexing {
            AFISearchIndexingCard(
                progress: searchService.indexProgress,
                statusMessage: searchService.statusMessage ?? "Preparing offline search…",
                timeRemainingText: searchService.estimatedTimeRemainingText
            )
        } else if let failure = searchService.preparationFailure, !searchService.isReady {
            AFISearchStatusCard(
                systemImage: "exclamationmark.triangle.fill",
                iconColor: .orange,
                title: failure.title,
                message: failure.message,
                actionTitle: "Try Again"
            ) {
                Task { await searchService.retryPreparation() }
            }
        } else if !trimmedQuery.isEmpty {
            if results.isEmpty {
                if searchService.isReady {
                    EmptyStateView(
                        systemImage: "doc.text.magnifyingglass",
                        title: AFISearchCopy.noResultsTitle,
                        message: AFISearchCopy.noResultsMessage,
                        style: .card
                    )
                } else {
                    AFISearchStatusCard(
                        systemImage: "hourglass",
                        iconColor: AppTheme.accent,
                        title: "Still Getting Ready",
                        message: "Offline search is still setting up. Give it a moment, or tap Try Again if this persists.",
                        actionTitle: "Try Again"
                    ) {
                        Task { await searchService.retryPreparation() }
                    }
                }
            } else {
                resultsList
            }
        } else if searchService.isReady {
            readyIdleContent
        } else {
            AFISearchStatusCard(
                systemImage: "arrow.down.doc",
                iconColor: AppTheme.accent,
                title: AFISearchCopy.indexingTitle,
                message: "Offline search will be ready shortly. You'll be able to search Essential AFIs with citations to the official PDFs.",
                actionTitle: nil,
                action: nil
            )
        }
    }

    private var readyIdleContent: some View {
        VStack(alignment: .leading, spacing: AssignmentMetrics.sectionSpacing) {
            AFISearchHintCard(
                title: AFISearchCopy.readyHintTitle,
                message: AFISearchCopy.readyHintMessage,
                exampleQueries: AFISearchCopy.exampleQueries
            ) { example in
                query = example
            }

            if let backfillProgress = searchService.semanticBackfillProgress {
                AFISemanticBackfillBanner(progress: backfillProgress)
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("Quick access")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(EssentialAFIs.stationed) { afi in
                        AFISearchQuickAccessCard(afi: afi) {
                            openQuickAccessPDF(for: afi)
                        }
                    }
                }
            }
        }
    }

    private var trimmedQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var resultsList: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("\(results.count) result\(results.count == 1 ? "" : "s")")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            ForEach(results) { result in
                AFISearchResultCard(
                    result: result,
                    query: query,
                    onOpenPDF: { openPDF(for: result) },
                    onShowDetail: { detailResult = result }
                )
            }
        }
    }

    private func scheduleIndexPreparationIfNeeded() {
        guard !didScheduleIndexPreparation else { return }
        didScheduleIndexPreparation = true

        guard !AppRuntime.isPreview else { return }

        Task {
            await searchService.prepareIndexIfNeeded()
        }
    }

    private func scheduleSearch(for value: String) {
        searchTask?.cancel()

        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else {
            results = []
            return
        }

        searchTask = Task {
            try? await Task.sleep(nanoseconds: 250_000_000)
            guard !Task.isCancelled else { return }

            let hits = await searchService.search(query: trimmed)
            guard !Task.isCancelled else { return }
            results = hits
        }
    }
}

// MARK: - Quick Access

private struct AFISearchQuickAccessCard: View {
    let afi: EssentialAFI
    let onOpen: () -> Void

    var body: some View {
        Button(action: onOpen) {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: afi.systemImage)
                    .font(.title3)
                    .foregroundStyle(AppTheme.buttonIcon)

                Text(afi.title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)

                Text(afi.publication)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, minHeight: 96, alignment: .topLeading)
            .appCardStyle(padding: AssignmentMetrics.cardPadding)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(afi.title), \(afi.publication)")
        .accessibilityHint("Opens the bundled PDF")
    }
}

// MARK: - Search Field

private struct AFISearchField: View {
    @Binding var query: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.body.weight(.semibold))
                .foregroundStyle(AppTheme.accent)
                .frame(width: 36, height: 36)
                .background(AppTheme.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

            TextField("Search AFIs and publications", text: $query)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .font(.subheadline)

            if !query.isEmpty {
                Button {
                    query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear search")
            }
        }
        .appCardStyle(padding: 14)
    }
}

// MARK: - Status Cards

private struct AFISearchIndexingCard: View {
    let progress: Double
    let statusMessage: String
    var timeRemainingText: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "arrow.down.doc.fill")
                    .font(.title3)
                    .foregroundStyle(AppTheme.buttonIcon)
                    .frame(width: 36, height: 36)
                    .background(AppTheme.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(AFISearchCopy.indexingTitle)
                        .font(.subheadline.weight(.semibold))

                    Text(statusMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                ProgressView(value: progress)
                    .tint(AppTheme.accent)

                HStack {
                    Text("\(Int((progress * 100).rounded()))%")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .monospacedDigit()

                    Spacer()

                    if let timeRemainingText {
                        Text(timeRemainingText)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Text(AFISearchCopy.indexingFooter)
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .appCardStyle(
            padding: AssignmentMetrics.cardPadding,
            background: Color(.secondarySystemGroupedBackground)
        )
    }
}

/// Subtle banner shown while semantic embeddings finish in the background.
/// Keyword search is fully usable during this pass.
private struct AFISemanticBackfillBanner: View {
    let progress: Double

    var body: some View {
        HStack(spacing: 10) {
            ProgressView()
                .controlSize(.small)

            VStack(alignment: .leading, spacing: 2) {
                Text("Improving smart matches — \(Int((progress * 100).rounded()))%")
                    .font(.caption.weight(.medium))
                    .monospacedDigit()

                Text("Search works now. \"Related\" results get better as this finishes.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .appCardStyle(padding: 12)
    }
}

private struct AFISearchStatusCard: View {
    let systemImage: String
    let iconColor: Color
    let title: String
    let message: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: systemImage)
                    .font(.title3)
                    .foregroundStyle(iconColor)
                    .frame(width: 36, height: 36)
                    .background(iconColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))

                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(.subheadline.weight(.semibold))
                    .buttonStyle(.bordered)
                    .tint(.primary)
                    .controlSize(.small)
            }
        }
        .appCardStyle(
            padding: AssignmentMetrics.cardPadding,
            background: Color(.secondarySystemGroupedBackground)
        )
    }
}

private struct AFISearchHintCard: View {
    let title: String
    let message: String
    let exampleQueries: [String]
    let onSelectExample: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "text.magnifyingglass")
                    .font(.title3)
                    .foregroundStyle(AppTheme.buttonIcon)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))

                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Try searching for")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                AFISearchExampleChipGrid(queries: exampleQueries, onSelect: onSelectExample)
            }
        }
        .appCardStyle(
            padding: AssignmentMetrics.cardPadding,
            background: Color(.secondarySystemGroupedBackground)
        )
    }
}

private struct AFISearchExampleChipGrid: View {
    let queries: [String]
    let onSelect: (String) -> Void

    var body: some View {
        FlowLayout(spacing: 8) {
            ForEach(queries, id: \.self) { example in
                Button {
                    onSelect(example)
                } label: {
                    Text(example)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(AppTheme.accent)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(AppTheme.accent.opacity(0.12), in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }
}

/// Simple wrapping layout for example-query chips.
private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0, x + size.width > width {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        return CGSize(width: width, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > bounds.minX, x + size.width > bounds.maxX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

// MARK: - Result Card

private struct AFISearchResultCard: View {
    let result: AFISearchResult
    let query: String
    let onOpenPDF: () -> Void
    let onShowDetail: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text(result.chunk.publication)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(AppTheme.accent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(AppTheme.accent.opacity(0.12), in: Capsule())

                Spacer(minLength: 8)

                if let page = result.chunk.page {
                    Text("Page \(page)")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(result.chunk.title)
                    .font(.subheadline.weight(.semibold))

                if let section = result.chunk.section, !section.isEmpty {
                    Text(section)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Text(AFISearchSnippet.highlightedExcerpt(
                from: result.chunk.text,
                query: query,
                highlightColor: AppTheme.accent
            ))
            .font(.subheadline)
            .foregroundStyle(.primary)
            .lineLimit(6)
            .fixedSize(horizontal: false, vertical: true)

            HStack {
                if result.pdfURL != nil {
                    Button(action: onOpenPDF) {
                        Label(openButtonTitle, systemImage: "doc.richtext")
                            .font(.caption.weight(.semibold))
                    }
                    .buttonStyle(.bordered)
                    .tint(AppTheme.accent)
                    .controlSize(.small)
                }

                Spacer()

                HStack(spacing: 3) {
                    Text("Read more")
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                }
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .appCardStyle(padding: AssignmentMetrics.cardPadding)
        .contentShape(Rectangle())
        .onTapGesture(perform: onShowDetail)
    }

    private var openButtonTitle: String {
        if let page = result.chunk.page {
            return "Open PDF · p. \(page)"
        }
        return "Open PDF"
    }
}

// MARK: - Result Detail Sheet

/// Full passage view: complete chunk text with highlights, citation, and a jump
/// straight into the official PDF at the cited page.
struct AFISearchResultDetailSheet: View {
    let result: AFISearchResult
    let query: String

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @State private var pdfPreview: AFIPDFPreviewContext?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 8) {
                        Text(result.chunk.publication)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(AppTheme.accent)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(AppTheme.accent.opacity(0.12), in: Capsule())

                        Spacer(minLength: 8)

                        if let page = result.chunk.page {
                            Text("Page \(page)")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(.secondary)
                        }
                    }

                    if let section = result.chunk.section, !section.isEmpty {
                        Text(section)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }

                    Text(AFISearchSnippet.highlight(
                        result.chunk.text,
                        query: query,
                        highlightColor: AppTheme.accent
                    ))
                    .font(.subheadline)
                    .lineSpacing(3)
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Text("Passages are extracted automatically. Always verify against the official publication before acting on guidance.")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                .padding()
            }
            .navigationTitle(result.chunk.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                if result.pdfURL != nil {
                    Button {
                        openPDF()
                    } label: {
                        Label(openButtonTitle, systemImage: "doc.richtext")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppTheme.accent)
                    .padding()
                    .background(.bar)
                }
            }
            .sheet(item: $pdfPreview) { context in
                AFIPDFViewerSheet(context: context)
            }
        }
    }

    private var openButtonTitle: String {
        if let page = result.chunk.page {
            return "Open Official PDF · Page \(page)"
        }
        return "Open Official PDF"
    }

    private func openPDF() {
        if let context = AFIPDFPreviewContext(result: result) {
            pdfPreview = context
        } else if let url = result.pdfURL {
            openURL(url)
        }
    }
}
