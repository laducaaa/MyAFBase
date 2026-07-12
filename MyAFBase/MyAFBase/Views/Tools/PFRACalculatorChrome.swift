import SwiftUI

/// Records toolbar + shared save presentation for PFRA calculators.
struct PFRACalculatorChromeModifier: ViewModifier {
    @Binding var showSaveSheet: Bool
    let assessment: PFRAResult?
    let includeTargetTier: Bool
    let defaultKind: PFRARecordKind

    @State private var didSave = false

    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        PFRARecordsView()
                    } label: {
                        Image(systemName: "align.vertical.bottom.fill")
                    }
                    .accessibilityLabel("PFRA records")
                }
            }
            .sheet(isPresented: $showSaveSheet) {
                if let assessment {
                    PFRASaveScoreSheet(
                        assessment: assessment,
                        includeTargetTier: includeTargetTier,
                        defaultKind: defaultKind,
                        onSaved: {
                            showSaveSheet = false
                            didSave = true
                            Task {
                                try? await Task.sleep(nanoseconds: 1_600_000_000)
                                didSave = false
                            }
                        },
                        onCancel: { showSaveSheet = false }
                    )
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
                }
            }
            .overlay(alignment: .bottom) {
                if didSave {
                    Label("Score saved", systemImage: "checkmark.circle.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(.ultraThinMaterial, in: Capsule())
                        .padding(.bottom, 24)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: didSave)
    }
}

struct PFRASaveScoreButton: View {
    let enabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("Save Score")
                .font(.body.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .disabled(!enabled)
        .accessibilityHint("Opens the save score sheet")
    }
}

struct PFRASaveScoreSheet: View {
    @Environment(PFRARecordStore.self) private var recordStore
    @Environment(PFRAProfileStore.self) private var profile

    let assessment: PFRAResult
    let includeTargetTier: Bool
    let defaultKind: PFRARecordKind
    let onSaved: () -> Void
    let onCancel: () -> Void

    @State private var kind: PFRARecordKind
    @State private var testedAt = Date()
    @State private var note = ""

    init(
        assessment: PFRAResult,
        includeTargetTier: Bool,
        defaultKind: PFRARecordKind,
        onSaved: @escaping () -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.assessment = assessment
        self.includeTargetTier = includeTargetTier
        self.defaultKind = defaultKind
        self.onSaved = onSaved
        self.onCancel = onCancel
        _kind = State(initialValue: defaultKind)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.sectionSpacing) {
                    scorePreviewCard
                    kindPickerCard
                    detailsCard
                }
                .padding(AppTheme.screenPadding)
            }
            .appScreenBackground()
            .navigationTitle("Save Score")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button(action: save) {
                    Text("Save to Records")
                        .font(.body.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding(.horizontal, AppTheme.screenPadding)
                .padding(.top, 10)
                .padding(.bottom, 10)
                .background(.ultraThinMaterial)
            }
        }
    }

    private var scorePreviewCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Composite")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(String(format: "%.1f", assessment.compositeScore))
                        .font(.system(size: 44, weight: .bold, design: .rounded).monospacedDigit())
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 6) {
                    Text(assessment.rating)
                        .font(.subheadline.weight(.semibold))
                    Text(assessment.passed ? "Passing" : "Not passing")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(assessment.passed ? AppTheme.success : AppTheme.warning)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            (assessment.passed ? AppTheme.success : AppTheme.warning).opacity(0.14),
                            in: Capsule()
                        )
                }
            }

            if includeTargetTier {
                Text("Target: \(profile.targetTier.title)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .appCardStyle(padding: 18)
    }

    private var kindPickerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("What kind of score is this?")
                .font(.headline)

            VStack(spacing: 10) {
                ForEach(PFRARecordKind.allCases) { option in
                    Button {
                        kind = option
                    } label: {
                        HStack(spacing: 12) {
                            IconBadge(systemImage: option.systemImage, tint: option.tint, size: 40)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(option.title)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.primary)
                                Text(option.subtitle)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer(minLength: 0)

                            Image(systemName: kind == option ? "checkmark.circle.fill" : "circle")
                                .font(.title3)
                                .foregroundStyle(kind == option ? option.tint : Color.secondary.opacity(0.45))
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(kind == option ? option.tint.opacity(0.10) : Color(.secondarySystemGroupedBackground))
                        )
                        .overlay {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(kind == option ? option.tint.opacity(0.35) : Color.clear, lineWidth: 1)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .appCardStyle(padding: 16)
    }

    private var detailsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Details")
                .font(.headline)

            DatePicker(
                "Test date",
                selection: $testedAt,
                displayedComponents: [.date, .hourAndMinute]
            )
            .font(.subheadline)

            VStack(alignment: .leading, spacing: 8) {
                Text("Note")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                TextField("Optional context for this score", text: $note, axis: .vertical)
                    .lineLimit(3...5)
                    .padding(12)
                    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        .appCardStyle(padding: 16)
    }

    private func save() {
        _ = recordStore.saveRecord(
            from: profile,
            result: assessment,
            kind: kind,
            testedAt: testedAt,
            note: note,
            includeTargetTier: includeTargetTier
        )
        onSaved()
    }
}

extension View {
    func pfraCalculatorChrome(
        showSaveSheet: Binding<Bool>,
        assessment: PFRAResult?,
        includeTargetTier: Bool = false,
        defaultKind: PFRARecordKind = .diagnostic
    ) -> some View {
        modifier(
            PFRACalculatorChromeModifier(
                showSaveSheet: showSaveSheet,
                assessment: assessment,
                includeTargetTier: includeTargetTier,
                defaultKind: defaultKind
            )
        )
    }
}
