import Foundation

/// Automatic birdie (and optional eagle-or-better multiplier) bets, computed directly from score
/// relative to par — no manual entry required, unlike greenies/sandies (§15).
public struct BirdiesEvaluator: GolfGameEvaluating {
    public init() {}

    public func evaluate(
        gameID: UUID,
        context: RoundEvaluationContext,
        configuration: BirdiesConfiguration
    ) throws -> GameEvaluationResult {
        let participants = configuration.participantIDs.sorted { $0.uuidString < $1.uuidString }
        guard participants.count >= 2 else {
            return GameEvaluationResult(gameID: gameID, statusLines: [], ledgerEntries: [], unresolvedItems: [])
        }

        var statusLines: [GameStatusLine] = []
        var ledgerEntries: [LedgerEntryValue] = []

        for hole in context.orderedHoles where hole.number <= context.throughHole {
            for playerID in participants {
                guard let score = context.score(for: playerID, hole: hole.number),
                      score.isEntered,
                      let value = score.effectiveScore(mode: configuration.scoringMode) else { continue }

                let relativeToPar = value - hole.par
                guard relativeToPar <= -1 else { continue }

                let isEagleOrBetter = relativeToPar <= -2
                let amount = (isEagleOrBetter && configuration.eagleMultiplierEnabled)
                    ? configuration.amountPerBirdie * configuration.eagleMultiplier
                    : configuration.amountPerBirdie

                let opponents = participants.filter { $0 != playerID }
                for opponent in opponents {
                    ledgerEntries.append(
                        LedgerEntryValue(
                            gameID: gameID,
                            holeNumber: hole.number,
                            segmentName: nil,
                            fromPlayerID: opponent,
                            toPlayerID: playerID,
                            amount: amount,
                            reason: isEagleOrBetter ? "Eagle or better — hole \(hole.number)" : "Birdie — hole \(hole.number)"
                        )
                    )
                }
                statusLines.append(
                    GameStatusLine(
                        title: "Hole \(hole.number)",
                        detail: isEagleOrBetter ? "Eagle or better" : "Birdie",
                        holeNumber: hole.number
                    )
                )
            }
        }

        return GameEvaluationResult(gameID: gameID, statusLines: statusLines, ledgerEntries: ledgerEntries, unresolvedItems: [])
    }
}
