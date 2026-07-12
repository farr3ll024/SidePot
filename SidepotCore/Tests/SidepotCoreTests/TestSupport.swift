import Foundation
@testable import SidepotCore

/// Shared fixture builders so individual test files can focus on the scenario being verified
/// instead of re-deriving `RoundEvaluationContext` boilerplate every time.
enum TestSupport {
    static func holes(count: Int, par: Int = 4, strokeIndexes: [Int]? = nil) -> [HoleSnapshotValue] {
        (1...count).map { number in
            HoleSnapshotValue(
                id: UUID(),
                number: number,
                par: par,
                strokeIndex: strokeIndexes.map { $0[number - 1] } ?? number,
                yardage: nil
            )
        }
    }

    static func score(
        hole: Int,
        player: UUID,
        gross: Int?,
        strokes: Int = 0,
        conceded: Bool = false,
        dnf: Bool = false
    ) -> HoleScoreValue {
        HoleScoreValue(
            holeNumber: hole,
            roundPlayerID: player,
            grossScore: gross,
            netScore: nil,
            strokesReceived: strokes,
            isConceded: conceded,
            didNotFinish: dnf
        )
    }

    static func context(
        holeCount: Int,
        scores: [HoleScoreValue],
        throughHole: Int,
        players: [RoundPlayerSnapshot] = [],
        strokeIndexes: [Int]? = nil,
        par: Int = 4
    ) -> RoundEvaluationContext {
        RoundEvaluationContext(
            roundID: UUID(),
            players: players,
            holes: holes(count: holeCount, par: par, strokeIndexes: strokeIndexes),
            scores: scores,
            throughHole: throughHole
        )
    }

    static func balance(_ balances: [PlayerBalance], for playerID: UUID) -> Decimal {
        balances.first { $0.playerID == playerID }?.amount ?? 0
    }
}
