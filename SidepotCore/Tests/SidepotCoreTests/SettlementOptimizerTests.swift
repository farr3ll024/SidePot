import Foundation
import Testing
@testable import SidepotCore

@Suite("SettlementOptimizer")
struct SettlementOptimizerTests {
    @Test("Simple two-player settlement")
    func simpleTwoPlayer() throws {
        let a = UUID(), b = UUID()
        let balances = [PlayerBalance(playerID: a, amount: 10), PlayerBalance(playerID: b, amount: -10)]
        let payments = try SettlementOptimizer.settle(balances: balances)
        #expect(payments.count == 1)
        #expect(payments.first?.fromPlayerID == b)
        #expect(payments.first?.toPlayerID == a)
        #expect(payments.first?.amount == 10)
    }

    @Test("The spec's four-player example resolves to exactly three payments")
    func fourPlayerSpecExample() throws {
        let a = UUID(), b = UUID(), c = UUID(), d = UUID()
        let balances = [
            PlayerBalance(playerID: a, amount: 20),
            PlayerBalance(playerID: b, amount: 5),
            PlayerBalance(playerID: c, amount: -10),
            PlayerBalance(playerID: d, amount: -15)
        ]
        let payments = try SettlementOptimizer.settle(balances: balances)
        #expect(payments.count == 3)
        #expect(payments.contains { $0.fromPlayerID == d && $0.toPlayerID == a && $0.amount == 15 })
        #expect(payments.contains { $0.fromPlayerID == c && $0.toPlayerID == a && $0.amount == 5 })
        #expect(payments.contains { $0.fromPlayerID == c && $0.toPlayerID == b && $0.amount == 5 })
    }

    @Test("Multiple creditors, one debtor")
    func multipleCreditors() throws {
        let a = UUID(), b = UUID(), c = UUID()
        let balances = [
            PlayerBalance(playerID: a, amount: 6),
            PlayerBalance(playerID: b, amount: 4),
            PlayerBalance(playerID: c, amount: -10)
        ]
        let payments = try SettlementOptimizer.settle(balances: balances)
        let totalFromC = payments.filter { $0.fromPlayerID == c }.reduce(Decimal(0)) { $0 + $1.amount }
        #expect(totalFromC == 10)
    }

    @Test("Multiple debtors, one creditor")
    func multipleDebtors() throws {
        let a = UUID(), b = UUID(), c = UUID()
        let balances = [
            PlayerBalance(playerID: a, amount: -6),
            PlayerBalance(playerID: b, amount: -4),
            PlayerBalance(playerID: c, amount: 10)
        ]
        let payments = try SettlementOptimizer.settle(balances: balances)
        let totalToC = payments.filter { $0.toPlayerID == c }.reduce(Decimal(0)) { $0 + $1.amount }
        #expect(totalToC == 10)
    }

    @Test("An already-settled round produces no payments")
    func alreadySettled() throws {
        let a = UUID(), b = UUID()
        let balances = [PlayerBalance(playerID: a, amount: 0), PlayerBalance(playerID: b, amount: 0)]
        let payments = try SettlementOptimizer.settle(balances: balances)
        #expect(payments.isEmpty)
    }

    @Test("A non-zero-sum input is rejected")
    func invalidNonZeroSum() {
        let a = UUID(), b = UUID()
        let balances = [PlayerBalance(playerID: a, amount: 10), PlayerBalance(playerID: b, amount: -5)]
        #expect(throws: SidepotError.self) {
            try SettlementOptimizer.settle(balances: balances)
        }
    }

    @Test("Settlement preserves exact Decimal totals")
    func exactDecimalArithmetic() throws {
        let a = UUID(), b = UUID(), c = UUID()
        let balances = [
            PlayerBalance(playerID: a, amount: Decimal(string: "6.66")!),
            PlayerBalance(playerID: b, amount: Decimal(string: "6.67")!),
            PlayerBalance(playerID: c, amount: Decimal(string: "-13.33")!)
        ]
        let payments = try SettlementOptimizer.settle(balances: balances)
        let total = payments.reduce(Decimal(0)) { $0 + $1.amount }
        #expect(total == Decimal(string: "13.33")!)
    }

    @Test("Settlement is deterministic for identical input")
    func deterministicOrdering() throws {
        let a = UUID(), b = UUID(), c = UUID(), d = UUID()
        let balances = [
            PlayerBalance(playerID: a, amount: 20),
            PlayerBalance(playerID: b, amount: 5),
            PlayerBalance(playerID: c, amount: -10),
            PlayerBalance(playerID: d, amount: -15)
        ]
        let first = try SettlementOptimizer.settle(balances: balances)
        let second = try SettlementOptimizer.settle(balances: balances)
        // Compare payment content, not `id` -- each SettlementPaymentValue gets a fresh random
        // UUID per call, so the ids themselves are expected to differ between calls even though
        // the underlying from/to/amount payments are identical.
        let firstContent = first.map { "\($0.fromPlayerID)-\($0.toPlayerID)-\($0.amount)" }
        let secondContent = second.map { "\($0.fromPlayerID)-\($0.toPlayerID)-\($0.amount)" }
        #expect(firstContent == secondContent)
    }
}
