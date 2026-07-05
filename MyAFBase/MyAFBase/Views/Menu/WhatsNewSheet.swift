import SwiftUI

struct WhatsNewSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showLegalPrivacySheet = false

    private let current = AppReleaseNotes.current
    private let earlier = AppReleaseNotes.earlier

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.sectionSpacing) {
                    heroCard(release: current)

                    if !current.highlights.isEmpty {
                        highlightsSection(
                            title: "In this release",
                            highlights: current.highlights
                        )
                    }

                    if !earlier.isEmpty {
                        earlierReleasesSection
                    }

                    aboutSection
                }
                .padding(AppTheme.screenPadding)
            }
            .appScreenBackground()
            .navigationTitle("What's New")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDragIndicator(.visible)
        .presentationDetents([.medium, .large])
        .sheet(isPresented: $showLegalPrivacySheet) {
            LegalPrivacySheet()
        }
    }

    // MARK: - Sections

    private func heroCard(release: AppReleaseNote) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.system(size: 44 * 0.4, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(AppTheme.brandIconGradient, in: RoundedRectangle(cornerRadius: 44 * 0.27, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text("Version \(release.version)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                    Text(release.title)
                        .font(.title3.weight(.bold))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            if !release.highlights.isEmpty {
                Text("Here's what changed in the latest update.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .appCardStyle()
    }

    private func highlightsSection(title: String, highlights: [AppReleaseHighlight]) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.cardSpacing) {
            WhatsNewSectionHeader(title: title)

            VStack(spacing: 0) {
                ForEach(Array(highlights.enumerated()), id: \.element.id) { index, highlight in
                    WhatsNewHighlightRow(highlight: highlight)

                    if index < highlights.count - 1 {
                        Divider()
                            .padding(.leading, 52)
                    }
                }
            }
            .appCardStyle(padding: 0)
        }
    }

    private var earlierReleasesSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.cardSpacing) {
            WhatsNewSectionHeader(title: "Earlier versions")

            VStack(spacing: AppTheme.cardSpacing) {
                ForEach(earlier) { release in
                    earlierReleaseCard(release)
                }
            }
        }
    }

    private func earlierReleaseCard(_ release: AppReleaseNote) -> some View {
        DisclosureGroup {
            VStack(spacing: 0) {
                ForEach(Array(release.highlights.enumerated()), id: \.element.id) { index, highlight in
                    WhatsNewHighlightRow(highlight: highlight, compact: true)

                    if index < release.highlights.count - 1 {
                        Divider()
                            .padding(.leading, 44)
                    }
                }
            }
            .padding(.top, 8)
        } label: {
            VStack(alignment: .leading, spacing: 2) {
                Text("Version \(release.version)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                Text(release.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .appCardStyle()
    }

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.cardSpacing) {
            WhatsNewSectionHeader(title: "How MyAFBase works")

            VStack(spacing: 0) {
                WhatsNewInfoRow(
                    systemImage: "icloud.fill",
                    title: "iCloud sync",
                    detail: "Bookmarks, assignment dates, readiness tracker, and checklists sync when you're signed in."
                )

                Divider().padding(.leading, 52)

                WhatsNewInfoRow(
                    systemImage: "arrow.clockwise.circle.fill",
                    title: "Fresh base data",
                    detail: "Hours and resources refresh from GitHub when you open the app or pull to refresh on Home."
                )

                Divider().padding(.leading, 52)

                WhatsNewInfoRow(
                    systemImage: "cloud.sun.fill",
                    title: "Weather sources",
                    detail: "CONUS weather from NOAA station observations. OCONUS forecasts use Open-Meteo."
                )
            }
            .appCardStyle(padding: 0)

            Button {
                showLegalPrivacySheet = true
            } label: {
                HStack(spacing: 12) {
                    IconBadge(systemImage: "doc.text", tint: AppTheme.accent, size: 32)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Legal & privacy notice")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.primary)

                        Text("Affiliation, data use, and security practices")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer(minLength: 0)

                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .appCardStyle()

            LegalDisclaimerCard(
                text: LegalCopy.nonAffiliationShort,
                style: .compact,
                systemImage: "building.columns"
            )
        }
    }
}

// MARK: - Shared Components

private struct WhatsNewSectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 4)
    }
}

private struct WhatsNewHighlightRow: View {
    let highlight: AppReleaseHighlight
    var compact: Bool = false

    private var iconSize: CGFloat { compact ? 28 : 32 }
    private var horizontalPadding: CGFloat { compact ? 12 : 16 }
    private var verticalPadding: CGFloat { compact ? 10 : 12 }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            IconBadge(systemImage: highlight.systemImage, tint: AppTheme.accent, size: iconSize)

            VStack(alignment: .leading, spacing: 3) {
                Text(highlight.title)
                    .font(compact ? .subheadline.weight(.medium) : .subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)

                if let detail = highlight.detail {
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, verticalPadding)
        .accessibilityElement(children: .combine)
    }
}

private struct WhatsNewInfoRow: View {
    let systemImage: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            IconBadge(systemImage: systemImage, tint: AppTheme.accent, size: 32)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)

                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .accessibilityElement(children: .combine)
    }
}
