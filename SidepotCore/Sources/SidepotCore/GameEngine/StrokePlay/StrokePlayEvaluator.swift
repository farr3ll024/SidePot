import Foundation

/// Total-score stroke play: lowest total (gross or net) across every hole wins the stake from
/// every other participant (§14). Incomplete scores prevent resolution entirely, since a partial
/// total isn't meaningful for "lowest total wins."
public struct StrokePlayEvaluator: GolfGameEvaluating {
    public init() {}

    public func evaluate(
        gameID: UUID,
        context: RoundEvaluationContext,
        configuration: StrokePlayConfiguration
    ) throws -> GameEvaluationResult {
        let participants = configuration.participantIDs.sorted { $0.uuidString < $1.uuidString }
        guard participants.count >= 2 else {
            return GameEvaluationResult(gameID: gameID, statusLines: [], ledgerEntries: [], unresolvedItems: [])
        }

        guard context.throughHole >= context.holeCount else {
            return GameEvaluationResult(
                gameID: gameID,
                statusLines: [GameStatusLine(title: "Stroke Play", detail: "In progress — through hole \(context.throughHole)", holeNumber: nil)],
                ledgerEntries: [],
                unresolvedItems: [UnresolvedGameItem(description: "Stroke play totals aren't final until every hole is played", holeNumber: nil)]
            )
        }

        var totals: [UUID: Int] = [:]
        var unresolvedItems: [UnresolvedGameItem] = []

        for playerID in participants {
            var total = 0
            var complete = true
            for holeNumber in 1...context.holeCount {
                guard let value = context.score(for: playerID, hole: holeNumber)?.effectiveScore(mode: configuration.scoringMode) else {
                    complete = false
                    unresolvedItems.append(UnresolvedGameItem(description: "Missing hole \(holeNumber) score for stroke play", holeNumber: holeNumber))
                    continue
                }
                total += value
            }
            if complete {
                totals[playerID] = total
            }
        }

        guard totals.count == participants.count, let lowest = totals.values.min() else {
            return GameEvaluationResult(
                gameID: gameID,
                statusLines: [GameStatusLine(title: "Stroke Play", detail: "Waiting on final scores", holeNumber: nil)],
                ledgerEntries: [],
                unresolvedItems: unresolvedItems
            )
        }

        let winners = participants.filter { totals[$0] == lowest }
        let losers = participants.filter { totals[$0] != lowest }

        var statusLines = [GameStatusLine(title: "Stroke Play", detail: "Final — low total \(lowest)", holeNumber: nil)]
        var ledgerEntries: [LedgerEntryValue] = []

        if winners.count > 1 {
            statusLines.append(GameStatusLine(title: "Stroke Play", detail: "Tied at \(lowest) between \(winners.count) players", holeNumber: nil))
            if configuration.tieHandling == .push {
                // No payment on a push.
            } else {
                ledgerEntries.append(contentsOf: payout(winners: winners, losers: losers, stakeAmount: configuration.stakeAmount, gameID: gameID))
            }
        } else {
            ledgerEntries.append(contentsOf: payout(winners: winners, losers: losers, stakeAmount: configuration.stakeAmount, gameID: gameID))
        }

        return GameEvaluationResult(gameID: gameID, statusLines: statusLines, ledgerEntries: ledgerEntries, unresolvedItems: [])
    }

    private func payout(winners: [UUID], losers: [UUID], stakeAmount: Decimal, gameID: UUID) -> [LedgerEntryValue] {
        guard !winners.isEmpty, !losers.isEmpty, stakeAmount > 0 else { return [] }
        let perWinnerShare = MoneySplit.evenSplit(stakeAmount, into: winners.count)
        var entries: [LedgerEntryValue] = []
        for loser in losers {
            for (index, winner) in winners.enumerated() {
                entries.append(
                    LedgerEntryValue(
                        gameID: gameID,
                        holeNumber: nil,
                        segmentName: nil,
                        fromPlayerID: loser,
                        toPlayerID: winner,
                        amount: perWinnerShare[index],
                        reason: "Stroke play"
                    )
                )
            }
        }
        return entries
    }
}
