import SwiftUI

struct BusinessHoursView: View {
    let hours: String
    @State private var isExpanded = true

    private var parsed: ParsedHours {
        HoursParser.parse(hours)
    }

    var body: some View {
        VStack(spacing: 0) {
            if let status = parsed.status {
                statusRow(status: status)
            } else if let todayHours = parsed.todayHoursText {
                fallbackStatusRow(todayHours)
            }

            if parsed.isStructured {
                if parsed.status != nil || parsed.todayHoursText != nil {
                    Divider()
                }

                if !parsed.mealEntries.isEmpty {
                    mealScheduleSection
                } else {
                    weekdayScheduleSection
                }
            } else if let fallback = parsed.fallbackText {
                Text(fallback)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 4)
            }
        }
    }

    private var weekdayScheduleSection: some View {
        Group {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Text("Normal Hours")
                        .font(.body)
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 12)
            }
            .buttonStyle(.plain)

            if isExpanded {
                Divider()

                ForEach(Array(parsed.groupedRows.enumerated()), id: \.element.id) { index, row in
                    if index > 0 {
                        Divider()
                    }
                    scheduleRow(row)
                }
            }
        }
    }

    private var mealScheduleSection: some View {
        VStack(spacing: 0) {
            ForEach(Array(parsed.mealEntries.enumerated()), id: \.element.id) { index, entry in
                if index > 0 {
                    Divider()
                }

                HStack(alignment: .top, spacing: 16) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(entry.name)
                            .font(.body.weight(.semibold))
                        Text(entry.dayLabel)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(minWidth: 96, alignment: .leading)

                    Spacer(minLength: 8)

                    Text(HoursParser.summaryHours(for: entry.hoursText) ?? entry.hoursText)
                        .font(.body)
                        .multilineTextAlignment(.trailing)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 10)
            }
        }
    }

    private func statusRow(status: OpenStatus) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(statusTitle(status))
                .font(.body)
                .foregroundStyle(statusColor(status))

            Spacer(minLength: 16)

            if let detail = statusDetailText(for: status) {
                Text(detail)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.trailing)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }

    private func statusDetailText(for status: OpenStatus) -> String? {
        if !parsed.mealEntries.isEmpty {
            return nil
        }

        guard let todayHours = parsed.todayHoursText else { return nil }
        if status == .closed && todayHours.caseInsensitiveCompare("Closed") == .orderedSame {
            return nil
        }
        return todayHours
    }

    private func fallbackStatusRow(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("Hours")
                .font(.body)
                .foregroundStyle(.secondary)
            Spacer(minLength: 16)
            Text(text)
                .font(.body)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 4)
    }

    private func scheduleRow(_ row: GroupedDayHoursRow) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Text(row.dayLabel)
                .font(.body)
                .foregroundStyle(.secondary)
                .frame(minWidth: 72, alignment: .leading)

            Spacer(minLength: 8)

            Text(row.hoursText)
                .font(.body)
                .foregroundStyle(row.includesToday ? .primary : .primary)
                .fontWeight(row.includesToday ? .semibold : .regular)
                .multilineTextAlignment(.trailing)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 10)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(row.dayLabel), \(row.hoursText)")
    }

    private func statusTitle(_ status: OpenStatus) -> String {
        switch status {
        case .open: "Open"
        case .closed: "Closed"
        case .alwaysOpen: "Open"
        }
    }

    private func statusColor(_ status: OpenStatus) -> Color {
        switch status {
        case .open, .alwaysOpen: .green
        case .closed: .secondary
        }
    }
}
