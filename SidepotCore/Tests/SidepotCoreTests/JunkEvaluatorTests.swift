import Foundation
import Testing
@testable import SidepotCore

@Suite("GreeniesEvaluator")
struct GreeniesEvaluatorTests {
    private let gameID = UUID()

    @Test("A recorded winner is paid by every other participant")
    func winnerPaid() throws {
        let winner = UUID(), b = UUID(), c = UUID()
        let context = TestSupport.context(holeCount: 3, scores: [], throughHole: 3, par: 3)
        let config = GreeniesConfiguration(
            amount: 5,
            participantIDs: [winner, b, c],
            results: [GreenieResult(holeNumber: 1, winnerRoundPlayerID: winner)]
        )

        let result = try GreeniesEvaluator().evaluate(gameID: gameID, context: context, configuration: config)
        #expect(result.ledgerEntries.count == 2)
        #expect(result.ledgerEntries.allSatisfy { $0.toPlayerID == winner && $0.amount == 5 })
    }

    @Test("Carryover accumulates across holes with no winner")
    func carryoverAccumulates() throws {
        let winner = UUID(), b = UUID()
        let context = TestSupport.context(holeCount: 3, scores: [], throughHole: 3, par: 3)
        let config = GreeniesConfiguration(
            amount: 5,
            carryoverEnabled: true,
            participantIDs: [winner, b],
            results: [
                GreenieResult(holeNumber: 1, winnerRoundPlayerID: nil),
                GreenieResult(holeNumber: 2, winnerRoundPlayerID: winner)
            ]
        )

        let result = try GreeniesEvaluator().evaluate(gameID: gameID, context: context, configuration: config)
        #expect(result.ledgerEntries.count == 1)
        #expect(result.ledgerEntries.first?.amount == 10) // 2 x $5 carried
    }

    @Test("A hole with no recorded entry is unresolved")
    func unrecordedHoleIsUnresolved() throws {
        let winner = UUID(), b = UUID()
        let context = TestSupport.context(holeCount: 1, scores: [], throughHole: 1, par: 3)
        let config = GreeniesConfiguration(amount: 5, participantIDs: [winner, b], results: [])

        let result = try GreeniesEvaluator().evaluate(gameID: gameID, context: context, configuration: config)
        #expect(result.ledgerEntries.isEmpty)
        #expect(result.unresolvedItems.count == 1)
    }
}

@Suite("SandiesEvaluator")
struct SandiesEvaluatorTests {
    private let gameID = UUID()

    @Test("A qualifying sandie is paid by every other participant")
    func sandiePaid() throws {
        let winner = UUID(), b = UUID(), c = UUID()
        let context = TestSupport.context(holeCount: 1, scores: [], throughHole: 1)
        let config = SandiesConfiguration(
            amount: 5,
            participantIDs: [winner, b, c],
            entries: [SandieEntry(holeNumber: 1, roundPlayerID: winner, madeParOrBetter: true)]
        )

        let result = try SandiesEvaluator().evaluate(gameID: gameID, context: context, configuration: config)
        #expect(result.ledgerEntries.count == 2)
        #expect(result.ledgerEntries.allSatisfy { $0.toPlayerID == winner && $0.amount == 5 })
    }

    @Test("A non-qualifying entry produces no payout")
    func nonQualifyingEntryNoPayout() throws {
        let a = UUID(), b = UUID()
        let context = TestSupport.context(holeCount: 1, scores: [], throughHole: 1)
        let config = SandiesConfiguration(
            amount: 5,
            participantIDs: [a, b],
            entries: [SandieEntry(holeNumber: 1, roundPlayerID: a, madeParOrBetter: false)]
        )

        let result = try SandiesEvaluator().evaluate(gameID: gameID, context: context, configuration: config)
        #expect(result.ledgerEntries.isEmpty)
    }
}

@Suite("BirdiesEvaluator")
struct BirdiesEvaluatorTests {
    private let gameID = UUID()

    @Test("A birdie is paid automatically from the score")
    func birdiePaidAutomatically() throws {
        let a = UUID(), b = UUID()
        let scores = [
            TestSupport.score(hole: 1, player: a, gross: 3), // par 4, birdie
            TestSupport.score(hole: 1, player: b, gross: 4)
        ]
        let context = TestSupport.context(holeCount: 1, scores: scores, throughHole: 1, par: 4)
        let config = BirdiesConfiguration(scoringMode: .gross, amountPerBirdie: 3, participantIDs: [a, b])

        let result = try BirdiesEvaluator().evaluate(gameID: gameID, context: context, configuration: config)
        #expect(result.ledgerEntries.count == 1)
        #expect(result.ledgerEntries.first?.toPlayerID == a)
        #expect(result.ledgerEntries.first?.amount == 3)
    }

    @Test("An eagle uses the multiplier when enabled")
    func eagleUsesMultiplier() throws {
        let a = UUID(), b = UUID()
        let scores = [
            TestSupport.score(hole: 1, player: a, gross: 2), // par 4, eagle
            TestSupport.score(hole: 1, player: b, gross: 4)
        ]
        let context = TestSupport.context(holeCount: 1, scores: scores, throughHole: 1, par: 4)
        let config = BirdiesConfiguration(scoringMode: .gross, amountPerBirdie: 3, eagleMultiplierEnabled: true, eagleMultiplier: 2, participantIDs: [a, b])

        let result = try BirdiesEvaluator().evaluate(gameID: gameID, context: context, configuration: config)
        #expect(result.ledgerEntries.first?.amount == 6)
    }

    @Test("A bogey or par produces no payout")
    func noPayoutForParOrWorse() throws {
        let a = UUID(), b = UUID()
        let scores = [
            TestSupport.score(hole: 1, player: a, gross: 4),
            TestSupport.score(hole: 1, player: b, gross: 5)
        ]
        let context = TestSupport.context(holeCount: 1, scores: scores, throughHole: 1, par: 4)
        let config = BirdiesConfiguration(scoringMode: .gross, amountPerBirdie: 3, participantIDs: [a, b])

        let result = try BirdiesEvaluator().evaluate(gameID: gameID, context: context, configuration: config)
        #expect(result.ledgerEntries.isEmpty)
    }
}
