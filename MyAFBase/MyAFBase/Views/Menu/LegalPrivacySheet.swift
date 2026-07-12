import SwiftUI

struct LegalPrivacySheet: View {
    @Environment(\.dismiss) private var dismiss

    private static let links: [LegalWebsiteLink] = [
        LegalWebsiteLink(
            id: "privacy",
            title: "Privacy Policy",
            subtitle: "How MyAFBase handles your data",
            systemImage: "hand.raised.fill",
            urlString: ContactConfig.privacyURL.absoluteString
        ),
        LegalWebsiteLink(
            id: "user-choices",
            title: "Your Privacy Choices",
            subtitle: "Manage consent and preferences",
            systemImage: "switch.2",
            urlString: ContactConfig.userChoicesURL.absoluteString
        ),
        LegalWebsiteLink(
            id: "terms",
            title: "Terms of Use",
            subtitle: "Rules for using MyAFBase",
            systemImage: "doc.text.fill",
            urlString: ContactConfig.termsURL.absoluteString
        ),
        LegalWebsiteLink(
            id: "support",
            title: "Support",
            subtitle: "Help, feedback, and contact options",
            systemImage: "lifepreserver.fill",
            urlString: ContactConfig.supportURL.absoluteString
        )
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.sectionSpacing) {
                    headerCard

                    VStack(spacing: 0) {
                        ForEach(Array(Self.links.enumerated()), id: \.element.id) { index, link in
                            if let url = link.url {
                                Link(destination: url) {
                                    LegalWebsiteLinkRow(link: link)
                                }
                                .buttonStyle(.plain)

                                if index < Self.links.count - 1 {
                                    Divider()
                                        .padding(.leading, 54)
                                }
                            }
                        }
                    }
                    .appCardStyle(padding: 0)

                    LegalDisclaimerCard(
                        text: LegalCopy.nonAffiliationShort,
                        style: .compact,
                        systemImage: "building.columns"
                    )
                    .padding(.horizontal, 4)
                }
                .padding()
            }
            .appScreenBackground()
            .navigationTitle("Legal & Privacy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDragIndicator(.visible)
        .presentationDetents([.medium, .large])
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                IconBadge(systemImage: "doc.text.fill", tint: AppTheme.accent, size: 44)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Official policies")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                    Text("Legal, privacy & terms")
                        .font(.title3.weight(.bold))
                }
            }

            Text("Full policy documents are hosted on myafbase.com. Open any link below in Safari to read the latest version.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Text("Privacy questions: \(ContactConfig.legalEmail) · Support: \(ContactConfig.supportEmail)")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .appCardStyle()
    }
}

private struct LegalWebsiteLink: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let systemImage: String
    let urlString: String

    var url: URL? {
        SafeURL.webURL(from: urlString)
    }
}

private struct LegalWebsiteLinkRow: View {
    let link: LegalWebsiteLink

    var body: some View {
        HStack(spacing: 12) {
            IconBadge(systemImage: link.systemImage, tint: AppTheme.accent, size: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(link.title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)

                Text(link.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            Image(systemName: "arrow.up.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }
}

#if DEBUG
#Preview {
    LegalPrivacySheet()
}
#endif
