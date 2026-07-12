import Foundation
import Testing
@testable import SidepotCore

@Suite("CustomBetEvaluator")
struct CustomBetEvaluatorTests {
    private let gameID = UUID()
    private let emptyContext = TestSupport.context(holeCount: 1, scores: [], throughHole: 1)

    @Test("A resolved bet with one winner pays the full amount from every loser")
    func singleWinnerResolved() throws {
        let winner = UUID(), a = UUID(), b = UUID()
        let config = CustomBetConfiguration(
            name: "Closest to Pin",
            amount: 10,
            participantIDs: [winner, a, b],
            winnerIDs: [winner],
            status: .resolved
        )

        let result = try CustomBetEvaluator().evaluate(gameID: gameID, context: emptyContext, configuration: config)
        let balances = LedgerValidator.balances(from: result.ledgerEntries)
        #expect(LedgerValidator.isZeroSum(balances))
        #expect(TestSupport.balance(balances, for: winner) == 20)
        #expect(TestSupport.balance(balances, for: a) == -10)
    }

    @Test("Multiple winners split the amount evenly")
    func multipleWinnersSplitEvenly() throws {
        let w1 = UUID(), w2 = UUID(), loser = UUID()
        let config = CustomBetConfiguration(
            name: "Longest Drive",
            amount: 10,
            participantIDs: [w1, w2, loser],
            winnerIDs: [w1, w2],
            status: .resolved
        )

        let result = try CustomBetEvaluator().evaluate(gameID: gameID, context: emptyContext, configuration: config)
        let balances = LedgerValidator.balances(from: result.ledgerEntries)
        #expect(LedgerValidator.isZeroSum(balances))
        #expect(TestSupport.balance(balances, for: loser) == -10)
        #expect(TestSupport.balance(balances, for: w1) == 5)
        #expect(TestSupport.balance(balances, for: w2) == 5)
    }

    @Test("A pending bet has no ledger impact and is reported unresolved")
    func pendingBet() throws {
        let a = UUID(), b = UUID()
        let config = CustomBetConfiguration(name: "First Birdie", amount: 5, participantIDs: [a, b], status: .pending)

        let result = try CustomBetEvaluator().evaluate(gameID: gameID, context: emptyContext, configuration: config)
        #expect(result.ledgerEntries.isEmpty)
        #expect(result.unresolvedItems.count == 1)
    }

    @Test("A void bet has no ledger impact and is not unresolved")
    func voidBet() throws {
        let a = UUID(), b = UUID()
        let config = CustomBetConfiguration(name: "Water Ball", amount: 5, participantIDs: [a, b], status: .void)

        let result = try CustomBetEvaluator().evaluate(gameID: gameID, context: emptyContext, configuration: config)
        #expect(result.ledgerEntries.isEmpty)
        #expect(result.unresolvedItems.isEmpty)
    }
}
