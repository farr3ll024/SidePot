import Foundation
import Testing
@testable import SidepotCore

@Suite("StrokePlayEvaluator")
struct StrokePlayEvaluatorTests {
    private let gameID = UUID()

    @Test("Lowest total wins and every loser pays the stake")
    func lowestTotalWins() throws {
        let a = UUID(), b = UUID(), c = UUID()
        var scores: [HoleScoreValue] = []
        for hole in 1...3 {
            scores.append(TestSupport.score(hole: hole, player: a, gross: 3))
            scores.append(TestSupport.score(hole: hole, player: b, gross: 4))
            scores.append(TestSupport.score(hole: hole, player: c, gross: 5))
        }
        let context = TestSupport.context(holeCount: 3, scores: scores, throughHole: 3)
        let config = StrokePlayConfiguration(scoringMode: .gross, stakeAmount: 10, participantIDs: [a, b, c])

        let result = try StrokePlayEvaluator().evaluate(gameID: gameID, context: context, configuration: config)
        let balances = LedgerValidator.balances(from: result.ledgerEntries)
        #expect(LedgerValidator.isZeroSum(balances))
        #expect(TestSupport.balance(balances, for: a) == 20)
        #expect(TestSupport.balance(balances, for: b) == -10)
        #expect(TestSupport.balance(balances, for: c) == -10)
    }

    @Test("A tie pushes by default")
    func tiePushes() throws {
        let a = UUID(), b = UUID()
        let scores = [
            TestSupport.score(hole: 1, player: a, gross: 4),
            TestSupport.score(hole: 1, player: b, gross: 4)
        ]
        let context = TestSupport.context(holeCount: 1, scores: scores, throughHole: 1)
        let config = StrokePlayConfiguration(scoringMode: .gross, stakeAmount: 10, tieHandling: .push, participantIDs: [a, b])

        let result = try StrokePlayEvaluator().evaluate(gameID: gameID, context: context, configuration: config)
        #expect(result.ledgerEntries.isEmpty)
    }

    @Test("Incomplete scores prevent resolution")
    func incompleteScoresPreventResolution() throws {
        let a = UUID(), b = UUID()
        let scores = [
            TestSupport.score(hole: 1, player: a, gross: 4),
            TestSupport.score(hole: 1, player: b, gross: 4)
        ]
        let context = TestSupport.context(holeCount: 3, scores: scores, throughHole: 1)
        let config = StrokePlayConfiguration(scoringMode: .gross, stakeAmount: 10, participantIDs: [a, b])

        let result = try StrokePlayEvaluator().evaluate(gameID: gameID, context: context, configuration: config)
        #expect(result.ledgerEntries.isEmpty)
        #expect(!result.unresolvedItems.isEmpty)
    }
}
