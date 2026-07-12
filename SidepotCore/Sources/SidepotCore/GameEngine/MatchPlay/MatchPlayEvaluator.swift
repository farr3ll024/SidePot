import Foundation

/// Straight match play over the whole round: two individuals or two teams (best ball for teams),
/// a single fixed stake, no presses (§13). Reuses `MatchPlayCalculator`, the same shared utility
/// Nassau uses, rather than duplicating match-state logic.
public struct MatchPlayEvaluator: GolfGameEvaluating {
    public init() {}

    public func evaluate(
        gameID: UUID,
        context: RoundEvaluationContext,
        configuration: MatchPlayConfiguration
    ) throws -> GameEvaluationResult {
        guard !configuration.sideAPlayerIDs.isEmpty, !configuration.sideBPlayerIDs.isEmpty else {
            throw SidepotError.invalidRound("Match play needs players on both sides.")
        }
        if configuration.format == .individual {
            guard configuration.sideAPlayerIDs.count == 1, configuration.sideBPlayerIDs.count == 1 else {
                throw SidepotError.invalidRound("Individual match play needs exactly one player per side.")
            }
        }

        let range = 1...context.holeCount
        var results: [HoleResult] = []
        var unresolvedItems: [UnresolvedGameItem] = []

        for holeNumber in range where holeNumber <= context.throughHole {
            let aScores = configuration.sideAPlayerIDs.compactMap {
                context.score(for: $0, hole: holeNumber)?.effectiveScore(mode: configuration.scoringMode)
            }
            let bScores = configuration.sideBPlayerIDs.compactMap {
                context.score(for: $0, hole: holeNumber)?.effectiveScore(mode: configuration.scoringMode)
            }
            guard !aScores.isEmpty, !bScores.isEmpty else {
                unresolvedItems.append(UnresolvedGameItem(description: "Match play — hole \(holeNumber) missing a score", holeNumber: holeNumber))
                continue
            }
            results.append(HoleResult(holeNumber: holeNumber, winner: MatchPlayCalculator.holeWinner(sideAScores: aScores, sideBScores: bScores)))
        }

        let state = MatchPlayCalculator.evaluate(holeResults: results, totalHolesInSegment: context.holeCount)
        var statusLines: [GameStatusLine] = []
        var ledgerEntries: [LedgerEntryValue] = []

        let played = state.holesWonBySideA + state.holesWonBySideB + state.holesHalved
        let detail: String
        if state.isClosed {
            let leaderLabel = state.leader == .a ? "Side A" : "Side B"
            detail = "\(leaderLabel) wins, \(abs(state.differential)) up with \(state.holesRemaining) to play"
        } else if state.holesRemaining == 0 {
            detail = state.differential == 0 ? "Halved" : "\(state.differential > 0 ? "Side A" : "Side B") wins, \(abs(state.differential)) up"
        } else if state.differential == 0 {
            detail = "All square through \(played) of \(context.holeCount)"
        } else {
            detail = "\(state.differential > 0 ? "Side A" : "Side B") \(abs(state.differential)) up through \(played) of \(context.holeCount)"
        }
        statusLines.append(GameStatusLine(title: "Match Play", detail: detail, holeNumber: nil))

        let isResolved = unresolvedItems.isEmpty && (state.isClosed || context.throughHole >= context.holeCount)
        if isResolved, let leader = state.leader {
            let winners = leader == .a ? configuration.sideAPlayerIDs : configuration.sideBPlayerIDs
            let losers = leader == .a ? configuration.sideBPlayerIDs : configuration.sideAPlayerIDs
            let perWinnerShare = MoneySplit.evenSplit(configuration.stakeAmount, into: winners.count)
            for loser in losers {
                for (index, winner) in winners.enumerated() {
                    ledgerEntries.append(
                        LedgerEntryValue(
                            gameID: gameID,
                            holeNumber: nil,
                            segmentName: nil,
                            fromPlayerID: loser,
                            toPlayerID: winner,
                            amount: perWinnerShare[index],
                            reason: "Match play"
                        )
                    )
                }
            }
        } else if !isResolved {
            unresolvedItems.append(UnresolvedGameItem(description: "Match play still in progress", holeNumber: nil))
        }

        return GameEvaluationResult(
            gameID: gameID,
            statusLines: statusLines,
            ledgerEntries: ledgerEntries,
            unresolvedItems: unresolvedItems
        )
    }
}
