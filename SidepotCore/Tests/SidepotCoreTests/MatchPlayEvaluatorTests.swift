import Foundation
import Testing
@testable import SidepotCore

@Suite("MatchPlayEvaluator")
struct MatchPlayEvaluatorTests {
    private let gameID = UUID()

    @Test("An individual match pays the stake to the winner")
    func individualWinner() throws {
        let a = UUID(), b = UUID()
        let scores = [
            TestSupport.score(hole: 1, player: a, gross: 3),
            TestSupport.score(hole: 1, player: b, gross: 5),
            TestSupport.score(hole: 2, player: a, gross: 4),
            TestSupport.score(hole: 2, player: b, gross: 4)
        ]
        let context = TestSupport.context(holeCount: 2, scores: scores, throughHole: 2)
        let config = MatchPlayConfiguration(format: .individual, scoringMode: .gross, stakeAmount: 20, sideAPlayerIDs: [a], sideBPlayerIDs: [b])

        let result = try MatchPlayEvaluator().evaluate(gameID: gameID, context: context, configuration: config)
        let balances = LedgerValidator.balances(from: result.ledgerEntries)
        #expect(TestSupport.balance(balances, for: a) == 20)
        #expect(TestSupport.balance(balances, for: b) == -20)
    }

    @Test("A halved match produces no payment")
    func halvedMatch() throws {
        let a = UUID(), b = UUID()
        let scores = [
            TestSupport.score(hole: 1, player: a, gross: 4),
            TestSupport.score(hole: 1, player: b, gross: 4)
        ]
        let context = TestSupport.context(holeCount: 1, scores: scores, throughHole: 1)
        let config = MatchPlayConfiguration(format: .individual, scoringMode: .gross, stakeAmount: 20, sideAPlayerIDs: [a], sideBPlayerIDs: [b])

        let result = try MatchPlayEvaluator().evaluate(gameID: gameID, context: context, configuration: config)
        #expect(result.ledgerEntries.isEmpty)
    }

    @Test("Team best ball decides each hole")
    func teamBestBall() throws {
        let p1 = UUID(), p2 = UUID(), p3 = UUID(), p4 = UUID()
        let scores = [
            TestSupport.score(hole: 1, player: p1, gross: 5),
            TestSupport.score(hole: 1, player: p2, gross: 3),
            TestSupport.score(hole: 1, player: p3, gross: 4),
            TestSupport.score(hole: 1, player: p4, gross: 6)
        ]
        let context = TestSupport.context(holeCount: 1, scores: scores, throughHole: 1)
        let config = MatchPlayConfiguration(format: .twoTeams, scoringMode: .gross, stakeAmount: 10, sideAPlayerIDs: [p1, p2], sideBPlayerIDs: [p3, p4])

        let result = try MatchPlayEvaluator().evaluate(gameID: gameID, context: context, configuration: config)
        let balances = LedgerValidator.balances(from: result.ledgerEntries)
        // Equal-share allocation: each of the 2 losers pays each of the 2 winners stake/2 (5),
        // so each winner collects 5 from each loser = 10 total (matches the Nassau team example).
        #expect(TestSupport.balance(balances, for: p1) == 10)
        #expect(TestSupport.balance(balances, for: p2) == 10)
    }

    @Test("A match still short of closing stays unresolved")
    func stillInProgress() throws {
        let a = UUID(), b = UUID()
        let scores = (1...3).flatMap { hole in
            [TestSupport.score(hole: hole, player: a, gross: 3), TestSupport.score(hole: hole, player: b, gross: 5)]
        }
        let context = TestSupport.context(holeCount: 9, scores: scores, throughHole: 3)
        let config = MatchPlayConfiguration(format: .individual, scoringMode: .gross, stakeAmount: 5, sideAPlayerIDs: [a], sideBPlayerIDs: [b])

        let result = try MatchPlayEvaluator().evaluate(gameID: gameID, context: context, configuration: config)
        // 3 up with 6 to play does not close (3 < 6); the match should still be in progress.
        #expect(result.ledgerEntries.isEmpty)
        #expect(result.unresolvedItems.contains { $0.description.contains("in progress") })
    }

    @Test("The match closes as soon as the lead exceeds the holes remaining")
    func closesEarly() throws {
        let a = UUID(), b = UUID()
        let scores = (1...6).flatMap { hole in
            [TestSupport.score(hole: hole, player: a, gross: 3), TestSupport.score(hole: hole, player: b, gross: 5)]
        }
        let context = TestSupport.context(holeCount: 9, scores: scores, throughHole: 6)
        let config = MatchPlayConfiguration(format: .individual, scoringMode: .gross, stakeAmount: 5, sideAPlayerIDs: [a], sideBPlayerIDs: [b])

        let result = try MatchPlayEvaluator().evaluate(gameID: gameID, context: context, configuration: config)
        // 6 up with 3 to play closes the match even though holes 7-9 were never played.
        let balances = LedgerValidator.balances(from: result.ledgerEntries)
        #expect(TestSupport.balance(balances, for: a) == 5)
        #expect(TestSupport.balance(balances, for: b) == -5)
    }
}
