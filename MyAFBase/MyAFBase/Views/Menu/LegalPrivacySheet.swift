import SwiftUI

struct LegalPrivacySheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.sectionSpacing) {
                    headerCard

                    ForEach(LegalCopy.Section.allCases) { section in
                        sectionCard(section)
                    }

                    footerNote
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
                Image(systemName: "doc.text")
                    .font(.system(size: 44 * 0.4, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(AppTheme.brandIconGradient, in: RoundedRectangle(cornerRadius: 44 * 0.27, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text("Please read before use")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                    Text("Unofficial community tool")
                        .font(.title3.weight(.bold))
                }
            }

            Text("MyAFBase helps Airmen and families navigate installation life. It is built independently and is not an official government application.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .appCardStyle()
    }

    private func sectionCard(_ section: LegalCopy.Section) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label {
                Text(section.title)
                    .font(.subheadline.weight(.semibold))
            } icon: {
                Image(systemName: section.systemImage)
                    .foregroundStyle(AppTheme.accent)
            }

            Text(section.body)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .appCardStyle()
    }

    private var footerNote: some View {
        LegalDisclaimerCard(
            text: "By using MyAFBase, you acknowledge that information in the app is provided as-is for planning and reference only, and that you are responsible for verifying official guidance with your chain of command and installation offices.",
            style: .compact,
            systemImage: "checkmark.shield"
        )
        .padding(.horizontal, 4)
    }
}

#if DEBUG
#Preview {
    LegalPrivacySheet()
}
#endif
