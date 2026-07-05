import SwiftUI

struct EmergencyContactsButton: View {
    let numbers: [EmergencyNumber]
    @State private var showSheet = false

    var body: some View {
        Button {
            showSheet = true
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "phone.fill")
                    .font(.title3)
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(AppTheme.danger.gradient, in: Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text("Emergency Numbers")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text("\(numbers.count) contacts · tap to view and call")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 8)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .elevatedCardStyle(background: Color(.secondarySystemGroupedBackground))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Emergency numbers, \(numbers.count) contacts, tap to view and call")
        .sheet(isPresented: $showSheet) {
            EmergencyNumbersSheet(numbers: numbers)
        }
    }
}
