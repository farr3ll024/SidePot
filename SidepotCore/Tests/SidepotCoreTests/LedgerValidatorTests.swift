import Foundation
import Testing
@testable import SidepotCore

@Suite("LedgerValidator")
struct LedgerValidatorTests {
    private let gameID = UUID()

    @Test("Balances derived from entries sum to zero")
    func balancesSumToZero() {
        let a = UUID(), b = UUID(), c = UUID()
        let entries = [
            LedgerEntryValue(gameID: gameID, holeNumber: nil, segmentName: nil, fromPlayerID: a, toPlayerID: b, amount: 5, reason: "x"),
            LedgerEntryValue(gameID: gameID, holeNumber: nil, segmentName: nil, fromPlayerID: c, toPlayerID: b, amount: 3, reason: "x")
        ]
        let balances = LedgerValidator.balances(from: entries)
        #expect(LedgerValidator.isZeroSum(balances))
        #expect(TestSupport.balance(balances, for: b) == 8)
        #expect(TestSupport.balance(balances, for: a) == -5)
        #expect(TestSupport.balance(balances, for: c) == -3)
    }

    @Test("A negative amount is rejected")
    func rejectsNegativeAmount() {
        let a = UUID(), b = UUID()
        let entries = [LedgerEntryValue(gameID: gameID, holeNumber: nil, segmentName: nil, fromPlayerID: a, toPlayerID: b, amount: -5, reason: "x")]
        #expect(throws: SidepotError.self) {
            try LedgerValidator.validate(entries: entries)
        }
    }

    @Test("A zero amount is rejected")
    func rejectsZeroAmount() {
        let a = UUID(), b = UUID()
        let entries = [LedgerEntryValue(gameID: gameID, holeNumber: nil, segmentName: nil, fromPlayerID: a, toPlayerID: b, amount: 0, reason: "x")]
        #expect(throws: SidepotError.self) {
            try LedgerValidator.validate(entries: entries)
        }
    }

    @Test("A self-payment is rejected")
    func rejectsSelfPayment() {
        let a = UUID()
        let entries = [LedgerEntryValue(gameID: gameID, holeNumber: nil, segmentName: nil, fromPlayerID: a, toPlayerID: a, amount: 5, reason: "x")]
        #expect(throws: SidepotError.self) {
            try LedgerValidator.validate(entries: entries)
        }
    }

    @Test("Recalculating from the same entries is idempotent")
    func recalculationIsIdempotent() {
        let a = UUID(), b = UUID()
        let entries = [LedgerEntryValue(gameID: gameID, holeNumber: nil, segmentName: nil, fromPlayerID: a, toPlayerID: b, amount: 5, reason: "x")]
        #expect(LedgerValidator.balances(from: entries) == LedgerValidator.balances(from: entries))
    }
}
