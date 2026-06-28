import SwiftUI

struct LocationDetailRow: View {
    let label: String
    let value: String
    var isLink: Bool = false
    var action: (() -> Void)?

    var body: some View {
        Group {
            if let action {
                Button(action: action) {
                    rowContent
                }
                .buttonStyle(.plain)
            } else {
                rowContent
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label), \(value)")
    }

    private var rowContent: some View {
        HStack(alignment: .top, spacing: 16) {
            Text(label)
                .font(.body)
                .foregroundStyle(.secondary)
                .frame(width: 72, alignment: .leading)

            Spacer(minLength: 8)

            Text(value)
                .font(.body)
                .foregroundStyle(isLink ? AppTheme.buttonText : .primary)
                .multilineTextAlignment(.trailing)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 4)
    }
}

struct LocationDetailSheet: View {
    let title: String
    let hours: String?
    let address: String?
    let phone: String?
    let url: String?
    let description: String?
    let gateStatus: GateStatus?
    let traffic: TrafficLevel?
    let onOpenMaps: (() -> Void)?
    @Environment(\.dismiss) private var dismiss

    private var hasDetails: Bool {
        [phone, url, address, description].contains { value in
            guard let value else { return false }
            return !value.isEmpty
        }
    }

    var body: some View {
        NavigationStack {
            List {
                if let address, !address.isEmpty, let onOpenMaps {
                    Section {
                        AddressMapPreview(
                            title: title,
                            address: address,
                            onOpenMaps: onOpenMaps
                        )
                        .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                        .listRowBackground(Color.clear)
                    }
                }

                if let hours, !hours.isEmpty {
                    Section {
                        BusinessHoursView(hours: hours)
                    } header: {
                        Text("Hours")
                    }
                }

                if hasDetails {
                    Section {
                        if let phone, !phone.isEmpty {
                            LocationDetailRow(
                                label: "Phone",
                                value: formattedPhone(phone),
                                isLink: true
                            ) {
                                ResourceAction.call(number: phone)
                            }
                        }

                        if let url, !url.isEmpty {
                            if let linkURL = normalizedURL(url) {
                                Link(destination: linkURL) {
                                    LocationDetailRow(
                                        label: "Website",
                                        value: displayHost(for: url),
                                        isLink: true
                                    )
                                }
                            }
                        }

                        if let address, !address.isEmpty {
                            LocationDetailRow(
                                label: "Address",
                                value: address
                            )
                        }

                        if let description, !description.isEmpty {
                            LocationDetailRow(
                                label: "About",
                                value: description
                            )
                        }
                    } header: {
                        Text("Details")
                    }
                }

                if gateStatus != nil || traffic != nil {
                    Section("Status") {
                        if let gateStatus {
                            LabeledContent("Gate Status") {
                                StatusPill(gateStatus: gateStatus)
                            }
                        }
                        if let traffic {
                            LabeledContent("Traffic") {
                                StatusPill(trafficLevel: traffic)
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func formattedPhone(_ phone: String) -> String {
        let digits = phone.filter(\.isNumber)
        if digits.count == 10 {
            let area = digits.prefix(3)
            let prefix = digits.dropFirst(3).prefix(3)
            let line = digits.suffix(4)
            return "(\(area)) \(prefix)-\(line)"
        }
        return phone
    }

    private func displayHost(for urlString: String) -> String {
        let normalized = urlString.hasPrefix("http") ? urlString : "https://\(urlString)"
        guard let host = URL(string: normalized)?.host?.replacingOccurrences(of: "www.", with: "") else {
            return urlString
        }
        return host
    }

    private func normalizedURL(_ string: String) -> URL? {
        if string.hasPrefix("http") {
            return URL(string: string)
        }
        return URL(string: "https://\(string)")
    }
}
