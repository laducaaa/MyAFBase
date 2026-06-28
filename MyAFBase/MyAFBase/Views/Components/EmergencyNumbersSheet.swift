import SwiftUI

struct EmergencyNumbersSheet: View {
    let numbers: [EmergencyNumber]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    sheetHeader

                    VStack(spacing: 12) {
                        ForEach(numbers) { emergency in
                            EmergencyCallRow(emergency: emergency)
                        }
                    }

                    sheetFooter
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .tint(.primary)
            .navigationTitle("Emergency Numbers")
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

    private var sheetHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Need help now?")
                .font(.headline.weight(.semibold))
                .foregroundStyle(.primary)

            Text("Tap a contact below to call.")
                .font(.subheadline)
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 4)
        .accessibilityElement(children: .combine)
    }

    private var sheetFooter: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Life-threatening emergency")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)

            footerEmergencyLine

            Text("Other numbers connect directly to on-installation security, fire, and medical services.")
                .font(.subheadline)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)

            Text(LegalCopy.emergencyVerify)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 8)
    }

    private var footerEmergencyLine: some View {
        HStack(spacing: 0) {
            Text("Call ")
                .foregroundStyle(.primary)
            Text("911")
                .foregroundStyle(.red)
                .fontWeight(.semibold)
            Text(" immediately.")
                .foregroundStyle(.primary)
        }
        .font(.subheadline)
    }
}
