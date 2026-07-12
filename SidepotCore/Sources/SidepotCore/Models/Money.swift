import Foundation

/// A tracked monetary (or points/"Golf Bucks") amount. Sidepot never processes real payments —
/// `Money` exists purely to keep every stake, balance, and ledger entry using exact `Decimal`
/// arithmetic instead of `Double`.
public struct Money: Hashable, Codable, Comparable, Sendable {
    public let amount: Decimal
    public let currencyCode: String

    public init(amount: Decimal, currencyCode: String = "USD") {
        self.amount = amount
        self.currencyCode = currencyCode
    }

    public static let zero = Money(amount: 0)

    public var isZero: Bool { amount == 0 }
    public var isNegative: Bool { amount < 0 }
    public var isPositive: Bool { amount > 0 }

    public static func < (lhs: Money, rhs: Money) -> Bool {
        lhs.amount < rhs.amount
    }

    public static func + (lhs: Money, rhs: Money) -> Money {
        Money(amount: lhs.amount + rhs.amount, currencyCode: lhs.currencyCode)
    }

    public static func - (lhs: Money, rhs: Money) -> Money {
        Money(amount: lhs.amount - rhs.amount, currencyCode: lhs.currencyCode)
    }

    public static prefix func - (value: Money) -> Money {
        Money(amount: -value.amount, currencyCode: value.currencyCode)
    }

    /// Renders the amount per the display label the round is using. Real-currency labels use the
    /// locale currency formatter (2 decimal places unless the amount is whole); points/Golf Bucks
    /// labels use a plain number suffixed with the label name.
    public func formatted(label: MoneyDisplayLabel = .currency, signed: Bool = false) -> String {
        let magnitude = abs(amount)
        let sign = signed ? (amount < 0 ? "-" : (amount > 0 ? "+" : "")) : (amount < 0 ? "-" : "")

        switch label {
        case .currency:
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.currencyCode = currencyCode
            formatter.minimumFractionDigits = magnitude.isWholeNumber ? 0 : 2
            formatter.maximumFractionDigits = 2
            let formatted = formatter.string(from: NSDecimalNumber(decimal: magnitude)) ?? "\(magnitude)"
            return signed ? sign + formatted : (amount < 0 ? "-" + formatted : formatted)
        case .points, .golfBucks:
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.minimumFractionDigits = magnitude.isWholeNumber ? 0 : 2
            formatter.maximumFractionDigits = 2
            let number = formatter.string(from: NSDecimalNumber(decimal: magnitude)) ?? "\(magnitude)"
            let suffix = label == .points ? "pts" : "Golf Bucks"
            return "\(sign)\(number) \(suffix)"
        }
    }
}

public enum MoneyDisplayLabel: String, Codable, Sendable {
    case currency
    case points
    case golfBucks
}

extension Decimal {
    var isWholeNumber: Bool {
        self == (self as NSDecimalNumber).rounding(accordingToBehavior: NSDecimalNumberHandler(
            roundingMode: .plain,
            scale: 0,
            raiseOnExactness: false,
            raiseOnOverflow: false,
            raiseOnUnderflow: false,
            raiseOnDivideByZero: false
        )) as Decimal
    }
}
