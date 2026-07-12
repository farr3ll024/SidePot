import Foundation
import SidepotCore

/// Turns a round's persisted ledger into optimized settlement payments (§17).
protocol SettlementServicing {
    func settle(round: GolfRound) throws -> [SettlementPaymentValue]
}

struct SettlementService: SettlementServicing {
    func settle(round: GolfRound) throws -> [SettlementPaymentValue] {
        let entries = (round.ledgerEntries ?? []).map { entry in
            LedgerEntryValue(
                id: entry.id,
                gameID: entry.gameID,
                holeNumber: entry.holeNumber,
                segmentName: entry.segmentName,
                fromPlayerID: entry.fromPlayerID,
                toPlayerID: entry.toPlayerID,
                amount: entry.amount,
                reason: entry.reason
            )
        }
        let balances = LedgerValidator.balances(from: entries)
        guard LedgerValidator.isZeroSum(balances) else {
            throw SidepotError.nonZeroSumLedger("This round's bets haven't all been resolved yet.")
        }
        return try SettlementOptimizer.settle(balances: balances)
    }
}
