import Foundation

/// Custom one-off bets (§16). `.pending` bets are surfaced as unresolved, `.void` bets produce no
/// ledger impact, and `.resolved` bets split the configured amount evenly across every loser-to-
/// winner pair so each loser's total exposure equals `amount`.
public struct CustomBetEvaluator: GolfGameEvaluating {
    public init() {}

    public func evaluate(
        gameID: UUID,
        context: RoundEvaluationContext,
        configuration: CustomBetConfiguration
    ) throws -> GameEvaluationResult {
        switch configuration.status {
        case .void:
            return GameEvaluationResult(
                gameID: gameID,
                statusLines: [GameStatusLine(title: configuration.name, detail: "Voided", holeNumber: configuration.holeNumber)],
                ledgerEntries: [],
                unresolvedItems: []
            )

        case .pending:
            return GameEvaluationResult(
                gameID: gameID,
                statusLines: [GameStatusLine(title: configuration.name, detail: "Pending", holeNumber: configuration.holeNumber)],
                ledgerEntries: [],
                unresolvedItems: [UnresolvedGameItem(description: "\"\(configuration.name)\" hasn't been resolved yet", holeNumber: configuration.holeNumber)]
            )

        case .resolved:
            let winners = configuration.winnerIDs.filter { configuration.participantIDs.contains($0) }
            let losers = configuration.participantIDs.filter { !winners.contains($0) }

            guard !winners.isEmpty, !losers.isEmpty, configuration.amount > 0 else {
                return GameEvaluationResult(
                    gameID: gameID,
                    statusLines: [GameStatusLine(title: configuration.name, detail: "Resolved — no payout", holeNumber: configuration.holeNumber)],
                    ledgerEntries: [],
                    unresolvedItems: []
                )
            }

            let perWinnerShare = MoneySplit.evenSplit(configuration.amount, into: winners.count)
            var ledgerEntries: [LedgerEntryValue] = []
            for loser in losers {
                for (index, winner) in winners.enumerated() {
                    ledgerEntries.append(
                        LedgerEntryValue(
                            gameID: gameID,
                            holeNumber: configuration.holeNumber,
                            segmentName: nil,
                            fromPlayerID: loser,
                            toPlayerID: winner,
                            amount: perWinnerShare[index],
                            reason: configuration.name
                        )
                    )
                }
            }

            return GameEvaluationResult(
                gameID: gameID,
                statusLines: [GameStatusLine(title: configuration.name, detail: "Resolved", holeNumber: configuration.holeNumber)],
                ledgerEntries: ledgerEntries,
                unresolvedItems: []
            )
        }
    }
}
