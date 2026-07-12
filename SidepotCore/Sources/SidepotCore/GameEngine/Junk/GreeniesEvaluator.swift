import Foundation

/// Par-3 closest-to-the-pin bets, manually recorded per hole (§15). Every other opponent pays the
/// configured amount to the winner (see `DEVIATIONS.md` for why greenies/sandies mirror the
/// birdies payout rule). Supports an optional carryover for holes with no winner.
public struct GreeniesEvaluator: GolfGameEvaluating {
    public init() {}

    public func evaluate(
        gameID: UUID,
        context: RoundEvaluationContext,
        configuration: GreeniesConfiguration
    ) throws -> GameEvaluationResult {
        let participants = configuration.participantIDs.sorted { $0.uuidString < $1.uuidString }
        guard participants.count >= 2 else {
            return GameEvaluationResult(gameID: gameID, statusLines: [], ledgerEntries: [], unresolvedItems: [])
        }

        let eligibleHoles: [HoleSnapshotValue]
        if let explicit = configuration.eligibleHoleNumbers {
            eligibleHoles = context.orderedHoles.filter { explicit.contains($0.number) }
        } else {
            eligibleHoles = context.orderedHoles.filter { $0.par == 3 }
        }

        var carry = 1
        var statusLines: [GameStatusLine] = []
        var ledgerEntries: [LedgerEntryValue] = []
        var unresolvedItems: [UnresolvedGameItem] = []

        for hole in eligibleHoles where hole.number <= context.throughHole {
            guard let entry = configuration.results.first(where: { $0.holeNumber == hole.number }) else {
                unresolvedItems.append(UnresolvedGameItem(description: "Greenie not recorded for hole \(hole.number)", holeNumber: hole.number))
                continue
            }

            guard let winner = entry.winnerRoundPlayerID, participants.contains(winner) else {
                statusLines.append(GameStatusLine(title: "Hole \(hole.number)", detail: "Greenie — no winner", holeNumber: hole.number))
                if configuration.carryoverEnabled { carry += 1 } else { carry = 1 }
                continue
            }

            if configuration.requireParOrBetter {
                let score = context.score(for: winner, hole: hole.number)?.effectiveScore(mode: .gross)
                let qualifies = score.map { $0 <= hole.par } ?? false
                guard qualifies else {
                    statusLines.append(GameStatusLine(title: "Hole \(hole.number)", detail: "Greenie recorded but didn't make par — no payout", holeNumber: hole.number))
                    if configuration.carryoverEnabled { carry += 1 } else { carry = 1 }
                    continue
                }
            }

            let amount = configuration.amount * Decimal(carry)
            let opponents = participants.filter { $0 != winner }
            for opponent in opponents {
                ledgerEntries.append(
                    LedgerEntryValue(
                        gameID: gameID,
                        holeNumber: hole.number,
                        segmentName: nil,
                        fromPlayerID: opponent,
                        toPlayerID: winner,
                        amount: amount,
                        reason: carry > 1 ? "Greenie (×\(carry) carry) — hole \(hole.number)" : "Greenie — hole \(hole.number)"
                    )
                )
            }
            statusLines.append(GameStatusLine(title: "Hole \(hole.number)", detail: "Greenie won", holeNumber: hole.number))
            carry = 1
        }

        return GameEvaluationResult(gameID: gameID, statusLines: statusLines, ledgerEntries: ledgerEntries, unresolvedItems: unresolvedItems)
    }
}
