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
                    .foregroundStyle(.red)
                    .frame(width: 40, height: 40)
                    .background(Color.red.opacity(0.14), in: Circle())

                Text("Emergency Numbers")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white)

                Spacer(minLength: 8)

                Image(systemName: "chevron.up")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 30, height: 30)
                    .background(Color.red.opacity(0.85), in: Circle())
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background(HomeMetrics.heroBackground)
            .clipShape(RoundedRectangle(cornerRadius: HomeMetrics.heroCornerRadius, style: .continuous))
            .shadow(color: .black.opacity(HomeMetrics.heroShadowOpacity), radius: 10, y: 5)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Emergency numbers, \(numbers.count) contacts, tap to view and call")
        .sheet(isPresented: $showSheet) {
            EmergencyNumbersSheet(numbers: numbers)
        }
    }
}
