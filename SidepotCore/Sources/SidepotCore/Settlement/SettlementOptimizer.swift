import Foundation

/// Reduces a zero-sum set of player balances into a minimal set of payments via greedy
/// largest-debtor/largest-creditor matching (§17).
public enum SettlementOptimizer {
    /// - Throws: `SidepotError.nonZeroSumLedger` if `balances` doesn't sum to exactly zero.
    /// - Returns: Payments in a deterministic order for identical input. Zero-amount balances are
    ///   dropped before matching, so an already-settled round returns an empty array. Ties in
    ///   balance magnitude are broken by `playerID` string ordering — see `DEVIATIONS.md`.
    public static func settle(balances: [PlayerBalance]) throws -> [SettlementPaymentValue] {
        guard LedgerValidator.isZeroSum(balances) else {
            throw SidepotError.nonZeroSumLedger("Balances must sum to zero before they can be settled.")
        }

        var creditors = balances
            .filter { $0.amount > 0 }
            .sorted(by: descendingThenByID)

        var debtors = balances
            .filter { $0.amount < 0 }
            .map { PlayerBalance(playerID: $0.playerID, amount: -$0.amount) }
            .sorted(by: descendingThenByID)

        var payments: [SettlementPaymentValue] = []
        var creditorIndex = 0
        var debtorIndex = 0

        while creditorIndex < creditors.count && debtorIndex < debtors.count {
            let credit = creditors[creditorIndex]
            let debt = debtors[debtorIndex]
            let amount = min(credit.amount, debt.amount)

            if amount > 0 {
                payments.append(
                    SettlementPaymentValue(fromPlayerID: debt.playerID, toPlayerID: credit.playerID, amount: amount)
                )
            }

            creditors[creditorIndex] = PlayerBalance(playerID: credit.playerID, amount: credit.amount - amount)
            debtors[debtorIndex] = PlayerBalance(playerID: debt.playerID, amount: debt.amount - amount)

            if creditors[creditorIndex].amount == 0 { creditorIndex += 1 }
            if debtors[debtorIndex].amount == 0 { debtorIndex += 1 }
        }

        return payments
    }

    private static func descendingThenByID(_ lhs: PlayerBalance, _ rhs: PlayerBalance) -> Bool {
        lhs.amount != rhs.amount ? lhs.amount > rhs.amount : lhs.playerID.uuidString < rhs.playerID.uuidString
    }
}
