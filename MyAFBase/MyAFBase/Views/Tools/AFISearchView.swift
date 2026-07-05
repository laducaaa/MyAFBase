import SwiftUI

struct AFISearchView: View {
    @Binding var query: String

    @Environment(AFISearchService.self) private var searchService
    @Environment(\.openURL) private var openURL

    @State private var results: [AFISearchResult] = []
    @State private var searchTask: Task<Void, Never>?
    @State private var didScheduleIndexPreparation = false
    @State private var pdfPreview: AFIPDFPreviewContext?
    @State private var detailResult: AFISearchResult?

    var body: some View {
        VStack(alignment: .leading, spacing: AssignmentMetrics.sectionSpacing) {
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
                iconColor: AppTheme.warning,
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
            AFISearchReadyHintCard(
                title: AFISearchCopy.readyHintTitle,
                message: AFISearchCopy.readyHintMessage
            )

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
            VStack(alignment: .leading, spacing: 10) {
                IconBadge(systemImage: afi.systemImage, tint: AppTheme.accent, size: 36)

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

// MARK: - Status Cards

private struct AFISearchReadyHintCard: View {
    let title: String
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            IconBadge(systemImage: "text.magnifyingglass", tint: AppTheme.accent, size: 36)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))

                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .appCardStyle(
            padding: AssignmentMetrics.cardPadding,
            background: Color(.secondarySystemGroupedBackground)
        )
    }
}

private struct AFISearchIndexingCard: View {
    let progress: Double
    let statusMessage: String
    var timeRemainingText: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                IconBadge(systemImage: "arrow.down.doc.fill", tint: AppTheme.accent, size: 36)

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
                IconBadge(systemImage: systemImage, tint: iconColor, size: 36)

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
                        Label(viewPDFTitle, systemImage: "doc.viewfinder")
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

    private var viewPDFTitle: String {
        if let page = result.chunk.page {
            return "View PDF · p. \(page)"
        }
        return "View PDF"
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
                    AFISearchViewPDFBar(
                        page: result.chunk.page,
                        action: openPDF
                    )
                }
            }
            .sheet(item: $pdfPreview) { context in
                AFIPDFViewerSheet(context: context)
            }
        }
    }

    private func openPDF() {
        if let context = AFIPDFPreviewContext(result: result) {
            pdfPreview = context
        } else if let url = result.pdfURL {
            openURL(url)
        }
    }
}

// MARK: - View PDF Bar

private struct AFISearchViewPDFBar: View {
    let page: Int?
    let action: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Divider()

            Button(action: action) {
                HStack(spacing: 12) {
                    IconBadge(systemImage: "doc.viewfinder", tint: AppTheme.accent, size: 36)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("View PDF")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)

                        if let page {
                            Text("Opens to page \(page)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer(minLength: 8)

                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(page.map { "View PDF, opens to page \($0)" } ?? "View PDF")
        }
        .background(.bar)
    }
}
