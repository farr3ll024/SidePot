import Foundation
import Testing
@testable import SidepotCore

@Suite("SkinsEvaluator")
struct SkinsEvaluatorTests {
    private let gameID = UUID()

    @Test("A unique low score wins the skin; four-player payment distribution matches the spec example")
    func uniqueWinnerFourPlayerDistribution() throws {
        let winner = UUID(), p2 = UUID(), p3 = UUID(), p4 = UUID()
        let participants = [winner, p2, p3, p4]
        let scores = [
            TestSupport.score(hole: 1, player: winner, gross: 3),
            TestSupport.score(hole: 1, player: p2, gross: 4),
            TestSupport.score(hole: 1, player: p3, gross: 5),
            TestSupport.score(hole: 1, player: p4, gross: 4)
        ]
        let context = TestSupport.context(holeCount: 1, scores: scores, throughHole: 1)
        let config = SkinsConfiguration(scoringMode: .gross, baseAmount: 2, participantIDs: participants)

        let result = try SkinsEvaluator().evaluate(gameID: gameID, context: context, configuration: config)
        #expect(result.ledgerEntries.count == 3)
        #expect(result.ledgerEntries.allSatisfy { $0.toPlayerID == winner && $0.amount == 2 })

        let balances = LedgerValidator.balances(from: result.ledgerEntries)
        #expect(LedgerValidator.isZeroSum(balances))
        #expect(TestSupport.balance(balances, for: winner) == 6)
        #expect(TestSupport.balance(balances, for: p2) == -2)
    }

    @Test("A tie carries the skin forward when carryovers are enabled")
    func tieWithCarry() throws {
        let a = UUID(), b = UUID()
        let scores = [
            TestSupport.score(hole: 1, player: a, gross: 4),
            TestSupport.score(hole: 1, player: b, gross: 4),
            TestSupport.score(hole: 2, player: a, gross: 3),
            TestSupport.score(hole: 2, player: b, gross: 5)
        ]
        let context = TestSupport.context(holeCount: 2, scores: scores, throughHole: 2)
        let config = SkinsConfiguration(scoringMode: .gross, baseAmount: 2, carryoversEnabled: true, tiesCarry: true, participantIDs: [a, b])

        let result = try SkinsEvaluator().evaluate(gameID: gameID, context: context, configuration: config)
        #expect(result.ledgerEntries.count == 1)
        #expect(result.ledgerEntries.first?.amount == 4) // 2 skins carried x $2
        #expect(result.ledgerEntries.first?.toPlayerID == a)
    }

    @Test("A tie awards nothing when carryovers are disabled")
    func tieWithoutCarry() throws {
        let a = UUID(), b = UUID()
        let scores = [
            TestSupport.score(hole: 1, player: a, gross: 4),
            TestSupport.score(hole: 1, player: b, gross: 4),
            TestSupport.score(hole: 2, player: a, gross: 3),
            TestSupport.score(hole: 2, player: b, gross: 5)
        ]
        let context = TestSupport.context(holeCount: 2, scores: scores, throughHole: 2)
        let config = SkinsConfiguration(scoringMode: .gross, baseAmount: 2, carryoversEnabled: false, tiesCarry: false, participantIDs: [a, b])

        let result = try SkinsEvaluator().evaluate(gameID: gameID, context: context, configuration: config)
        #expect(result.ledgerEntries.count == 1)
        #expect(result.ledgerEntries.first?.amount == 2) // no carry applied
    }

    @Test("Multiple consecutive ties compound the carry")
    func multipleCarryovers() throws {
        let a = UUID(), b = UUID()
        let scores = [
            TestSupport.score(hole: 1, player: a, gross: 4),
            TestSupport.score(hole: 1, player: b, gross: 4),
            TestSupport.score(hole: 2, player: a, gross: 4),
            TestSupport.score(hole: 2, player: b, gross: 4),
            TestSupport.score(hole: 3, player: a, gross: 3),
            TestSupport.score(hole: 3, player: b, gross: 5)
        ]
        let context = TestSupport.context(holeCount: 3, scores: scores, throughHole: 3)
        let config = SkinsConfiguration(scoringMode: .gross, baseAmount: 2, carryoversEnabled: true, tiesCarry: true, participantIDs: [a, b])

        let result = try SkinsEvaluator().evaluate(gameID: gameID, context: context, configuration: config)
        #expect(result.ledgerEntries.count == 1)
        #expect(result.ledgerEntries.first?.amount == 6) // 3 skins carried x $2
    }

    @Test("Net skins uses strokes received, not gross score")
    func netSkins() throws {
        let a = UUID(), b = UUID()
        // Gross: a=5, b=4 (b would win on gross), but a receives 2 strokes -> net a=3 wins.
        let scores = [
            TestSupport.score(hole: 1, player: a, gross: 5, strokes: 2),
            TestSupport.score(hole: 1, player: b, gross: 4, strokes: 0)
        ]
        let context = TestSupport.context(holeCount: 1, scores: scores, throughHole: 1)
        let config = SkinsConfiguration(scoringMode: .net, baseAmount: 2, participantIDs: [a, b])

        let result = try SkinsEvaluator().evaluate(gameID: gameID, context: context, configuration: config)
        #expect(result.ledgerEntries.first?.toPlayerID == a)
    }

    @Test("A hole with a missing score is unresolved when full-field validation is required")
    func incompleteScores() throws {
        let a = UUID(), b = UUID(), c = UUID()
        let scores = [
            TestSupport.score(hole: 1, player: a, gross: 3),
            TestSupport.score(hole: 1, player: b, gross: 4)
            // c has no score for hole 1.
        ]
        let context = TestSupport.context(holeCount: 1, scores: scores, throughHole: 1)
        let config = SkinsConfiguration(scoringMode: .gross, baseAmount: 2, requireAllScoresBeforeResolving: true, participantIDs: [a, b, c])

        let result = try SkinsEvaluator().evaluate(gameID: gameID, context: context, configuration: config)
        #expect(result.ledgerEntries.isEmpty)
        #expect(result.unresolvedItems.count == 1)
    }
}
