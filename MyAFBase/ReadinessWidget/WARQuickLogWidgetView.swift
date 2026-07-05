import AppIntents
import SwiftUI
import WidgetKit

struct WARQuickLogWidgetView: View {
    @Environment(\.colorScheme) private var colorScheme

    let entry: WARQuickLogEntry

    private var snapshot: WARWidgetSnapshot { entry.snapshot }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            WidgetHeader(systemImage: "text.badge.star", title: "WAR Tracker")

            Spacer(minLength: 6)

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("\(snapshot.entriesThisWeek)")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(WidgetPalette.primaryText(for: colorScheme))
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)

                Text(snapshot.entriesThisWeek == 1 ? "entry" : "entries")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(WidgetPalette.secondaryText(for: colorScheme))
            }

            Text("this week")
                .font(.caption)
                .foregroundStyle(WidgetPalette.secondaryText(for: colorScheme))

            Spacer(minLength: 8)

            Button(intent: LogAccomplishmentIntent()) {
                Label("Log", systemImage: "plus.circle.fill")
                    .font(.caption.weight(.semibold))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(WidgetPalette.warAccent(for: colorScheme))
        }
        .padding(EdgeInsets(top: 12, leading: 14, bottom: 12, trailing: 14))
        .containerBackground(for: .widget) {
            WidgetPalette.background(for: colorScheme)
        }
    }
}

#if DEBUG
#Preview(as: .systemSmall) {
    WARQuickLogWidget()
} timeline: {
    WARQuickLogEntry(date: .now, snapshot: WARWidgetSnapshot(baseID: "sample", entriesThisWeek: 3, weekRangeLabel: "Jun 2 – Jun 8", updatedAt: .now))
}
#endif
