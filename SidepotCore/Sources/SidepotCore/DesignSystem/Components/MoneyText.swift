import SwiftUI

/// Renders a `Money` amount with monospaced digits and, when `signed`, a `+`/`-` prefix. Color
/// alone never carries the positive/negative meaning — the sign glyph always does (§20).
public struct MoneyText: View {
    private let money: Money
    private let label: MoneyDisplayLabel
    private let signed: Bool
    private let style: Font.TextStyle

    public init(_ money: Money, label: MoneyDisplayLabel = .currency, signed: Bool = false, style: Font.TextStyle = .body) {
        self.money = money
        self.label = label
        self.signed = signed
        self.style = style
    }

    public var body: some View {
        Text(money.formatted(label: label, signed: signed))
            .font(SidepotTheme.Typography.money(style))
            .foregroundStyle(colorForAmount)
            .accessibilityLabel(accessibilityText)
    }

    private var colorForAmount: Color {
        guard signed else { return SidepotTheme.Colors.textPrimary }
        if money.isPositive { return SidepotTheme.Colors.positive }
        if money.isNegative { return SidepotTheme.Colors.negative }
        return SidepotTheme.Colors.textPrimary
    }

    private var accessibilityText: String {
        guard signed else { return money.formatted(label: label) }
        if money.isPositive { return "up \(money.formatted(label: label))" }
        if money.isNegative { return "down \(Money(amount: -money.amount, currencyCode: money.currencyCode).formatted(label: label))" }
        return "even"
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 12) {
        MoneyText(Money(amount: 22), signed: true, style: .largeTitle)
        MoneyText(Money(amount: -16), signed: true)
        MoneyText(Money(amount: 0), signed: true)
        MoneyText(Money(amount: 12.5), label: .points)
    }
    .padding()
}
