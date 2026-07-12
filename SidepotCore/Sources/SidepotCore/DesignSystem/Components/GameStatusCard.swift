import SwiftUI

public struct GameStatusCard: View {
    private let title: String
    private let lines: [GameStatusLine]

    public init(title: String, lines: [GameStatusLine]) {
        self.title = title
        self.lines = lines
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: SidepotTheme.Spacing.s) {
            Text(title)
                .font(SidepotTheme.Typography.headline)
                .foregroundStyle(SidepotTheme.Colors.textPrimary)

            ForEach(lines) { line in
                VStack(alignment: .leading, spacing: 2) {
                    Text(line.title)
                        .font(SidepotTheme.Typography.caption)
                        .foregroundStyle(SidepotTheme.Colors.textSecondary)
                    Text(line.detail)
                        .font(SidepotTheme.Typography.body)
                        .foregroundStyle(SidepotTheme.Colors.textPrimary)
                }
            }
        }
        .padding(SidepotTheme.Spacing.m)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SidepotTheme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: SidepotTheme.Radius.card))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
    }
}

#Preview {
    GameStatusCard(
        title: "Nassau",
        lines: [
            GameStatusLine(title: "Front", detail: "Side A 2 up through 6 of 9", holeNumber: nil),
            GameStatusLine(title: "Back", detail: "All square through 3 of 9", holeNumber: nil)
        ]
    )
    .padding()
}
