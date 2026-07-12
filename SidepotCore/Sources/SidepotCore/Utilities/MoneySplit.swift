import Foundation

/// Splits a `Decimal` total into evenly-sized shares at a given currency scale, guaranteeing the
/// shares sum back to exactly the original total.
///
/// Plain `Decimal` division does not guarantee this on its own: `10 / 3` rounded to two decimal
/// places three times sums to `9.99`, not `10.00`. Every evaluator that divides a stake among
/// more than one party (skins pot splits, Nassau team payouts, custom-bet multi-winner splits)
/// uses this instead of raw division, because the app's core invariant — a completed round's
/// balances sum to exactly zero — depends on it.
public enum MoneySplit {
    /// - Parameters:
    ///   - total: The amount to divide.
    ///   - count: Number of shares. Must be greater than zero.
    ///   - scale: Number of fractional digits to round each share to (2 for cents).
    /// - Returns: `count` shares, in the same order requested, summing to exactly `total`. Any
    ///   leftover minor unit (e.g. a stray penny) from rounding is deterministically assigned to
    ///   the earliest shares in the returned array, so callers should pass participants in a
    ///   stable order (e.g. sorted by player ID) if they want the remainder assignment to be
    ///   reproducible and fair-looking across recalculations.
    public static func evenSplit(_ total: Decimal, into count: Int, scale: Int = 2) -> [Decimal] {
        guard count > 0 else { return [] }
        guard count > 1 else { return [total] }

        let handler = NSDecimalNumberHandler(
            roundingMode: .plain,
            scale: Int16(scale),
            raiseOnExactness: false,
            raiseOnOverflow: false,
            raiseOnUnderflow: false,
            raiseOnDivideByZero: false
        )

        let totalNumber = NSDecimalNumber(decimal: total)
        let baseNumber = totalNumber.dividing(by: NSDecimalNumber(value: count), withBehavior: handler)
        let base = baseNumber as Decimal

        var shares = Array(repeating: base, count: count)
        let allocated = base * Decimal(count)
        var remainder = total - allocated

        guard remainder != 0 else { return shares }

        let unitExponent = -scale
        let unit = Decimal(sign: remainder < 0 ? .minus : .plus, exponent: unitExponent, significand: 1)

        var index = 0
        while remainder != 0 && index < shares.count {
            shares[index] += unit
            remainder -= unit
            index += 1
        }

        return shares
    }
}
