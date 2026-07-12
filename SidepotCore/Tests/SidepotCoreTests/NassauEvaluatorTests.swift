import Foundation
import Testing
@testable import SidepotCore

@Suite("NassauEvaluator")
struct NassauEvaluatorTests {
    private let gameID = UUID()

    private enum Outcome { case a, b, halved }

    /// Builds gross scores (par 4, no strokes) for holes 1...holeCount, using `outcomes` to decide
    /// who wins each hole. Holes not present in `outcomes` get no scores at all (simulating "not
    /// yet played").
    private func scores(sideA: UUID, sideB: UUID, holeCount: Int, outcomes: [Int: Outcome]) -> [HoleScoreValue] {
        var result: [HoleScoreValue] = []
        for hole in 1...holeCount {
            guard let outcome = outcomes[hole] else { continue }
            switch outcome {
            case .a:
                result.append(TestSupport.score(hole: hole, player: sideA, gross: 3))
                result.append(TestSupport.score(hole: hole, player: sideB, gross: 5))
            case .b:
                result.append(TestSupport.score(hole: hole, player: sideA, gross: 5))
                result.append(TestSupport.score(hole: hole, player: sideB, gross: 3))
            case .halved:
                result.append(TestSupport.score(hole: hole, player: sideA, gross: 4))
                result.append(TestSupport.score(hole: hole, player: sideB, gross: 4))
            }
        }
        return result
    }

    private func baseConfig(sideA: UUID, sideB: UUID, frontStake: Decimal = 0, backStake: Decimal = 0, overallStake: Decimal = 0) -> NassauConfiguration {
        NassauConfiguration(
            frontStake: frontStake,
            backStake: backStake,
            overallStake: overallStake,
            teamMode: .individual,
            autoPressRule: .none,
            allowManualPresses: false,
            scoringMode: .gross,
            sideAPlayerIDs: [sideA],
            sideBPlayerIDs: [sideB]
        )
    }

    @Test("Front nine winner")
    func frontWinner() throws {
        let a = UUID(), b = UUID()
        let outcomes: [Int: Outcome] = [1: .a, 2: .halved, 3: .a, 4: .halved, 5: .a, 6: .halved, 7: .a, 8: .halved, 9: .a]
        let context = TestSupport.context(holeCount: 18, scores: scores(sideA: a, sideB: b, holeCount: 18, outcomes: outcomes), throughHole: 9)
        let config = baseConfig(sideA: a, sideB: b, frontStake: 10)

        let result = try NassauEvaluator().evaluate(gameID: gameID, context: context, configuration: config)
        let balances = LedgerValidator.balances(from: result.ledgerEntries)
        #expect(LedgerValidator.isZeroSum(balances))
        #expect(TestSupport.balance(balances, for: a) == 10)
        #expect(TestSupport.balance(balances, for: b) == -10)
    }

    @Test("Back nine winner")
    func backWinner() throws {
        let a = UUID(), b = UUID()
        let outcomes: [Int: Outcome] = [10: .b, 11: .halved, 12: .b, 13: .halved, 14: .b, 15: .halved, 16: .b, 17: .halved, 18: .b]
        let context = TestSupport.context(holeCount: 18, scores: scores(sideA: a, sideB: b, holeCount: 18, outcomes: outcomes), throughHole: 18)
        let config = baseConfig(sideA: a, sideB: b, backStake: 10)

        let result = try NassauEvaluator().evaluate(gameID: gameID, context: context, configuration: config)
        let balances = LedgerValidator.balances(from: result.ledgerEntries)
        #expect(TestSupport.balance(balances, for: b) == 10)
        #expect(TestSupport.balance(balances, for: a) == -10)
    }

    @Test("Overall winner is independent of front/back")
    func overallWinner() throws {
        let a = UUID(), b = UUID()
        var outcomes: [Int: Outcome] = [:]
        for hole in 1...18 { outcomes[hole] = hole % 3 == 0 ? .b : .a } // A wins 12, B wins 6 -> A wins overall
        let context = TestSupport.context(holeCount: 18, scores: scores(sideA: a, sideB: b, holeCount: 18, outcomes: outcomes), throughHole: 18)
        let config = baseConfig(sideA: a, sideB: b, overallStake: 20)

        let result = try NassauEvaluator().evaluate(gameID: gameID, context: context, configuration: config)
        let balances = LedgerValidator.balances(from: result.ledgerEntries)
        #expect(TestSupport.balance(balances, for: a) == 20)
        #expect(TestSupport.balance(balances, for: b) == -20)
    }

    @Test("A halved segment produces no payment")
    func halvedSegment() throws {
        let a = UUID(), b = UUID()
        var outcomes: [Int: Outcome] = [:]
        for hole in 1...9 { outcomes[hole] = .halved }
        let context = TestSupport.context(holeCount: 18, scores: scores(sideA: a, sideB: b, holeCount: 18, outcomes: outcomes), throughHole: 9)
        let config = baseConfig(sideA: a, sideB: b, frontStake: 10)

        let result = try NassauEvaluator().evaluate(gameID: gameID, context: context, configuration: config)
        #expect(result.ledgerEntries.isEmpty)
        #expect(result.statusLines.contains { $0.detail == "Halved" })
    }

    @Test("Two-down triggers an automatic press starting on the next hole")
    func twoDownAutoPress() throws {
        let a = UUID(), b = UUID()
        // A wins holes 1-2 (2 up, triggers a press after hole 2), then everything halves.
        var outcomes: [Int: Outcome] = [1: .a, 2: .a]
        for hole in 3...9 { outcomes[hole] = .halved }
        let context = TestSupport.context(holeCount: 18, scores: scores(sideA: a, sideB: b, holeCount: 18, outcomes: outcomes), throughHole: 9)
        var config = baseConfig(sideA: a, sideB: b, frontStake: 10)
        config.autoPressRule = .twoDown

        let result = try NassauEvaluator().evaluate(gameID: gameID, context: context, configuration: config)
        #expect(result.metadata["front.pressCount"] == "1")
        #expect(result.statusLines.contains { $0.title.contains("Press from hole 2") })
        // Press is halved (holes 3-9 all tied), so it produces no ledger entries of its own,
        // only the base match's front-nine payout.
        #expect(result.ledgerEntries.allSatisfy { $0.segmentName == "front" && $0.holeNumber == nil })
    }

    @Test("Press cap limits how many presses can be created in a segment")
    func pressCap() throws {
        let a = UUID(), b = UUID()
        // A goes 2 up after hole 2 (press #1). B claws back and goes 2 down at hole 6 (would be press #2, blocked by cap).
        let outcomes: [Int: Outcome] = [1: .a, 2: .a, 3: .b, 4: .b, 5: .b, 6: .b, 7: .halved, 8: .halved, 9: .halved]
        let context = TestSupport.context(holeCount: 18, scores: scores(sideA: a, sideB: b, holeCount: 18, outcomes: outcomes), throughHole: 9)
        var config = baseConfig(sideA: a, sideB: b, frontStake: 10)
        config.autoPressRule = .twoDown
        config.maxPressesPerSegment = 1

        let result = try NassauEvaluator().evaluate(gameID: gameID, context: context, configuration: config)
        #expect(result.metadata["front.pressCount"] == "1")
    }

    @Test("A press can't be created with no holes remaining in the segment")
    func noHolesRemaining() throws {
        let a = UUID(), b = UUID()
        var outcomes: [Int: Outcome] = [:]
        for hole in 1...9 { outcomes[hole] = .halved }
        let context = TestSupport.context(holeCount: 18, scores: scores(sideA: a, sideB: b, holeCount: 18, outcomes: outcomes), throughHole: 9)
        var config = baseConfig(sideA: a, sideB: b, frontStake: 10)
        config.allowManualPresses = true
        config.manualPresses = [ManualPressRecord(segment: .front, createdAfterHole: 9, initiatingSide: .a)]

        let result = try NassauEvaluator().evaluate(gameID: gameID, context: context, configuration: config)
        #expect(result.metadata["front.pressCount"] == "0")
        #expect(result.unresolvedItems.contains { $0.description.contains("no holes remain") })
    }

    @Test("A manual press is created and resolves independently")
    func manualPress() throws {
        let a = UUID(), b = UUID()
        var outcomes: [Int: Outcome] = [1: .halved, 2: .halved, 3: .halved]
        for hole in 4...9 { outcomes[hole] = .b }
        let context = TestSupport.context(holeCount: 18, scores: scores(sideA: a, sideB: b, holeCount: 18, outcomes: outcomes), throughHole: 9)
        // A non-zero front stake is required for the front segment (and its presses) to be
        // evaluated at all; the assertions below only look at the press's own ledger entries.
        var config = baseConfig(sideA: a, sideB: b, frontStake: 1)
        config.allowManualPresses = true
        config.manualPresses = [ManualPressRecord(segment: .front, createdAfterHole: 3, initiatingSide: .b)]

        let result = try NassauEvaluator().evaluate(gameID: gameID, context: context, configuration: config)
        #expect(result.metadata["front.pressCount"] == "1")
        let pressEntries = result.ledgerEntries.filter { $0.reason.contains("from hole 3") }
        #expect(pressEntries.count == 1)
        #expect(pressEntries.first?.toPlayerID == b)
        #expect(pressEntries.first?.fromPlayerID == a)
    }

    @Test("Two-team best ball: the lower of each team's scores decides the hole")
    func teamBestBall() throws {
        let p1 = UUID(), p2 = UUID(), p3 = UUID(), p4 = UUID()
        let scores = [
            TestSupport.score(hole: 1, player: p1, gross: 5),
            TestSupport.score(hole: 1, player: p2, gross: 3), // side A best = 3
            TestSupport.score(hole: 1, player: p3, gross: 4),
            TestSupport.score(hole: 1, player: p4, gross: 4)  // side B best = 4
        ]
        let context = TestSupport.context(holeCount: 1, scores: scores, throughHole: 1)
        let config = NassauConfiguration(
            frontStake: 0,
            backStake: 0,
            overallStake: 10,
            teamMode: .twoTeams,
            autoPressRule: .none,
            allowManualPresses: false,
            scoringMode: .gross,
            sideAPlayerIDs: [p1, p2],
            sideBPlayerIDs: [p3, p4]
        )

        let result = try NassauEvaluator().evaluate(gameID: gameID, context: context, configuration: config)
        let balances = LedgerValidator.balances(from: result.ledgerEntries)
        #expect(LedgerValidator.isZeroSum(balances))
        #expect(TestSupport.balance(balances, for: p1) == 10)
        #expect(TestSupport.balance(balances, for: p2) == 10)
        #expect(TestSupport.balance(balances, for: p3) == -10)
        #expect(TestSupport.balance(balances, for: p4) == -10)
    }

    @Test("Editing a prior score deterministically removes a press that would otherwise have been created")
    func editingPriorScoreChangesPresses() throws {
        let a = UUID(), b = UUID()
        var config = baseConfig(sideA: a, sideB: b, frontStake: 10)
        config.autoPressRule = .twoDown

        let beforeEdit: [Int: Outcome] = [1: .a, 2: .a, 3: .halved, 4: .halved, 5: .halved, 6: .halved, 7: .halved, 8: .halved, 9: .halved]
        let contextBefore = TestSupport.context(holeCount: 18, scores: scores(sideA: a, sideB: b, holeCount: 18, outcomes: beforeEdit), throughHole: 9)
        let resultBefore = try NassauEvaluator().evaluate(gameID: gameID, context: contextBefore, configuration: config)
        #expect(resultBefore.metadata["front.pressCount"] == "1")

        // Hole 1 is edited from an A win to a halve, so A never reaches 2-down and the auto press disappears.
        let afterEdit: [Int: Outcome] = [1: .halved, 2: .a, 3: .halved, 4: .halved, 5: .halved, 6: .halved, 7: .halved, 8: .halved, 9: .halved]
        let contextAfter = TestSupport.context(holeCount: 18, scores: scores(sideA: a, sideB: b, holeCount: 18, outcomes: afterEdit), throughHole: 9)
        let resultAfter = try NassauEvaluator().evaluate(gameID: gameID, context: contextAfter, configuration: config)
        #expect(resultAfter.metadata["front.pressCount"] == "0")
    }

    @Test("A base match can close before the segment's final hole")
    func baseMatchClosesEarly() throws {
        let a = UUID(), b = UUID()
        // A wins the first six holes outright: 6 up with 3 to play closes the match at hole 6.
        var outcomes: [Int: Outcome] = [:]
        for hole in 1...6 { outcomes[hole] = .a }
        let context = TestSupport.context(holeCount: 18, scores: scores(sideA: a, sideB: b, holeCount: 18, outcomes: outcomes), throughHole: 6)
        let config = baseConfig(sideA: a, sideB: b, frontStake: 10)

        let result = try NassauEvaluator().evaluate(gameID: gameID, context: context, configuration: config)
        let balances = LedgerValidator.balances(from: result.ledgerEntries)
        // Resolved (and paid out) even though only 6 of the front nine's holes were played.
        #expect(TestSupport.balance(balances, for: a) == 10)
    }

    @Test("Overall keeps evaluating after the front segment has already closed")
    func overallContinuesAfterFrontCloses() throws {
        let a = UUID(), b = UUID()
        var outcomes: [Int: Outcome] = [:]
        for hole in 1...6 { outcomes[hole] = .a } // front closes early, A way up
        for hole in 7...18 { outcomes[hole] = .b } // B wins every remaining hole, taking the overall
        let context = TestSupport.context(holeCount: 18, scores: scores(sideA: a, sideB: b, holeCount: 18, outcomes: outcomes), throughHole: 18)
        let config = baseConfig(sideA: a, sideB: b, frontStake: 10, overallStake: 10)

        let result = try NassauEvaluator().evaluate(gameID: gameID, context: context, configuration: config)
        let balances = LedgerValidator.balances(from: result.ledgerEntries)
        // Front: A collects 10. Overall: A won 6, B won 12 -> B collects 10. Net zero, but both
        // segments must have independently resolved and paid out for this to be true.
        #expect(TestSupport.balance(balances, for: a) == 0)
        #expect(TestSupport.balance(balances, for: b) == 0)
        #expect(result.ledgerEntries.contains { $0.segmentName == "front" && $0.toPlayerID == a })
        #expect(result.ledgerEntries.contains { $0.segmentName == "overall" && $0.toPlayerID == b })
    }
}
