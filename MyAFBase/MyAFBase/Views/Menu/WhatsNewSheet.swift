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
                    currentReleaseSection

                    if !earlier.isEmpty {
                        earlierReleasesSection
                    }

                    aboutNotesSection
                }
                .padding()
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

    private var currentReleaseSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(AppTheme.brandIconGradient, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text("Version \(current.version)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                    Text(current.title)
                        .font(.title3.weight(.bold))
                }
            }

            VStack(spacing: 10) {
                ForEach(current.highlights) { highlight in
                    releaseHighlightRow(highlight)
                }
            }
        }
        .appCardStyle()
    }

    private var earlierReleasesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Earlier Versions")
                .font(.title3.weight(.semibold))

            VStack(spacing: AppTheme.cardSpacing) {
                ForEach(earlier) { release in
                    VStack(alignment: .leading, spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Version \(release.version)")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)

                            Text(release.title)
                                .font(.headline)
                        }

                        VStack(spacing: 8) {
                            ForEach(release.highlights) { highlight in
                                releaseHighlightRow(highlight, compact: true)
                            }
                        }
                    }
                    .appCardStyle()
                }
            }
        }
    }

    private var aboutNotesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("About MyAFBase")
                .font(.subheadline.weight(.semibold))

            aboutNote(
                systemImage: "icloud.fill",
                text: "Bookmarks, assignment dates, readiness tracker, and checklists sync through iCloud when signed in."
            )

            aboutNote(
                systemImage: "arrow.clockwise.circle.fill",
                text: "Base hours and resources refresh from GitHub when you open the app or pull to refresh on Home."
            )

            aboutNote(
                systemImage: "cloud.sun.fill",
                text: "CONUS weather from NOAA station observations. OCONUS forecasts use Open-Meteo."
            )

            Divider()

            aboutNote(
                systemImage: "building.columns",
                text: LegalCopy.nonAffiliationShort
            )

            aboutNote(
                systemImage: "lock.shield",
                text: LegalCopy.securityPractices
            )

            Button {
                showLegalPrivacySheet = true
            } label: {
                Label("Full legal & privacy notice", systemImage: "doc.text")
                    .font(.caption.weight(.medium))
            }
            .padding(.top, 4)
        }
        .appCardStyle()
    }

    private func releaseHighlightRow(_ highlight: AppReleaseHighlight, compact: Bool = false) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: highlight.systemImage)
                .font(compact ? .caption.weight(.semibold) : .subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.accent)
                .frame(width: compact ? 28 : 32, height: compact ? 28 : 32)
                .background(AppTheme.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

            Text(highlight.text)
                .font(compact ? .caption : .subheadline)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func aboutNote(systemImage: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: systemImage)
                .font(.caption)
                .foregroundStyle(AppTheme.accent)
                .frame(width: 16, alignment: .center)
                .padding(.top, 1)

            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
