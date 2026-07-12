import SwiftUI

public struct RoundProgressHeader: View {
    private let courseName: String
    private let holeNumber: Int
    private let par: Int
    private let holeCount: Int
    private let onPrevious: () -> Void
    private let onNext: () -> Void

    public init(
        courseName: String,
        holeNumber: Int,
        par: Int,
        holeCount: Int,
        onPrevious: @escaping () -> Void,
        onNext: @escaping () -> Void
    ) {
        self.courseName = courseName
        self.holeNumber = holeNumber
        self.par = par
        self.holeCount = holeCount
        self.onPrevious = onPrevious
        self.onNext = onNext
    }

    public var body: some View {
        VStack(spacing: SidepotTheme.Spacing.s) {
            Text(courseName)
                .font(SidepotTheme.Typography.caption)
                .foregroundStyle(SidepotTheme.Colors.textSecondary)

            HStack {
                navButton(systemImage: "chevron.left", label: "Previous hole", action: onPrevious)
                    .disabled(holeNumber <= 1)

                Spacer()
                VStack {
                    Text("Hole \(holeNumber)")
                        .font(SidepotTheme.Typography.title)
                    Text("Par \(par)")
                        .font(SidepotTheme.Typography.caption)
                        .foregroundStyle(SidepotTheme.Colors.textSecondary)
                }
                Spacer()

                navButton(systemImage: "chevron.right", label: "Next hole", action: onNext)
                    .disabled(holeNumber >= holeCount)
            }

            ProgressView(value: Double(holeNumber), total: Double(holeCount))
                .tint(SidepotTheme.Colors.accent)
                .accessibilityLabel("Round progress")
                .accessibilityValue("Hole \(holeNumber) of \(holeCount)")
        }
        .padding(SidepotTheme.Spacing.m)
        .background(SidepotTheme.Colors.surface)
    }

    private func navButton(systemImage: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .frame(width: SidepotTheme.minimumTapTarget, height: SidepotTheme.minimumTapTarget)
        }
        .accessibilityLabel(label)
    }
}

#Preview {
    RoundProgressHeader(courseName: "Toad Valley Golf Course", holeNumber: 7, par: 4, holeCount: 18, onPrevious: {}, onNext: {})
}
