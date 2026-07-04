import SwiftUI

struct NextPayPeriodCard: View {
    let event: PayCalendarEvent

    var body: some View {
        let days = PayCalendar.daysUntil(event.date)

        VStack(alignment: .leading, spacing: 12) {
            Text("Next pay")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            HStack(alignment: .center, spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(
                            (event.isSpecial ? AppTheme.highlight : AppTheme.accent)
                                .opacity(0.12)
                        )
                        .frame(width: 48, height: 48)

                    Image(systemName: event.systemImage)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(event.isSpecial ? AppTheme.highlight : AppTheme.accent)
                }
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 4) {
                    Text(event.title)
                        .font(.headline)

                    Text(event.date.formatted(date: .complete, time: .omitted))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 8)

                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(days)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.accent)
                        .contentTransition(.numericText())

                    Text(days == 1 ? "day" : "days")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .appCardStyle()
        .accessibilityElement(children: .combine)
    }
}
