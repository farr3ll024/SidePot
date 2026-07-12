import SwiftUI

public struct PlayerBalanceRow: View {
    private let displayName: String
    private let initials: String
    private let balance: Money
    private let label: MoneyDisplayLabel
    private let subtitle: String?

    public init(
        displayName: String,
        initials: String,
        balance: Money,
        label: MoneyDisplayLabel = .currency,
        subtitle: String? = nil
    ) {
        self.displayName = displayName
        self.initials = initials
        self.balance = balance
        self.label = label
        self.subtitle = subtitle
    }

    public var body: some View {
        HStack(spacing: SidepotTheme.Spacing.m) {
            PlayerAvatar(initials: initials)
            VStack(alignment: .leading, spacing: 2) {
                Text(displayName)
                    .font(SidepotTheme.Typography.headline)
                    .foregroundStyle(SidepotTheme.Colors.textPrimary)
                if let subtitle {
                    Text(subtitle)
                        .font(SidepotTheme.Typography.caption)
                        .foregroundStyle(SidepotTheme.Colors.textSecondary)
                }
            }
            Spacer()
            MoneyText(balance, label: label, signed: true, style: .headline)
        }
        .frame(minHeight: SidepotTheme.minimumTapTarget)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    VStack(spacing: 0) {
        PlayerBalanceRow(displayName: "Blaise", initials: "B", balance: Money(amount: 22), subtitle: "Through 12 holes")
        PlayerBalanceRow(displayName: "Ryan", initials: "R", balance: Money(amount: -16), subtitle: "Through 12 holes")
    }
    .padding()
}
