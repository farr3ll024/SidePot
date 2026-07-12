import SwiftUI

/// A large, one-handed-friendly score entry control for a single player on a single hole (§18
/// "Score Entry": large tap targets, quick par/bogey/double buttons, strokes-received indicator).
public struct ScoreEntryCell: View {
    private let displayName: String
    private let par: Int
    private let strokesReceived: Int
    @Binding private var grossScore: Int?

    public init(displayName: String, par: Int, strokesReceived: Int, grossScore: Binding<Int?>) {
        self.displayName = displayName
        self.par = par
        self.strokesReceived = strokesReceived
        self._grossScore = grossScore
    }

    private var netScore: Int? {
        grossScore.map { $0 - strokesReceived }
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: SidepotTheme.Spacing.s) {
            HStack {
                Text(displayName)
                    .font(SidepotTheme.Typography.headline)
                if strokesReceived > 0 {
                    strokeDots
                }
                Spacer()
                if let grossScore {
                    Button {
                        self.grossScore = nil
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(SidepotTheme.Colors.textSecondary)
                    }
                    .accessibilityLabel("Clear score")
                    .frame(width: SidepotTheme.minimumTapTarget, height: SidepotTheme.minimumTapTarget)
                    Text("\(grossScore)")
                        .font(SidepotTheme.Typography.money(.title2))
                        .frame(minWidth: 32)
                }
            }

            HStack(spacing: SidepotTheme.Spacing.s) {
                quickButton(label: "Par", score: par)
                quickButton(label: "Bogey", score: par + 1)
                quickButton(label: "Double", score: par + 2)
                Stepper(value: Binding(get: { grossScore ?? par }, set: { grossScore = $0 }), in: 1...20) {
                    EmptyView()
                }
                .labelsHidden()
            }

            if let netScore {
                Text("Net \(netScore)")
                    .font(SidepotTheme.Typography.caption)
                    .foregroundStyle(SidepotTheme.Colors.textSecondary)
                    .accessibilityLabel("Net score \(netScore)")
            }
        }
        .padding(SidepotTheme.Spacing.m)
        .background(SidepotTheme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: SidepotTheme.Radius.card))
        .accessibilityElement(children: .combine)
        .accessibilityHint("Double tap Par, Bogey, or Double for a quick score, or use the stepper to enter a specific score.")
    }

    private var strokeDots: some View {
        HStack(spacing: 2) {
            ForEach(0..<min(strokesReceived, 2), id: \.self) { _ in
                Circle().fill(SidepotTheme.Colors.accent).frame(width: 6, height: 6)
            }
        }
        .accessibilityLabel("\(strokesReceived) stroke\(strokesReceived == 1 ? "" : "s") received")
    }

    private func quickButton(label: String, score: Int) -> some View {
        Button(label) { grossScore = score }
            .buttonStyle(.bordered)
            .tint(grossScore == score ? SidepotTheme.Colors.accent : SidepotTheme.Colors.textSecondary)
            .frame(minHeight: SidepotTheme.minimumTapTarget)
    }
}

#Preview {
    @Previewable @State var gross: Int? = 5
    return ScoreEntryCell(displayName: "Blaise", par: 4, strokesReceived: 1, grossScore: $gross)
        .padding()
}
