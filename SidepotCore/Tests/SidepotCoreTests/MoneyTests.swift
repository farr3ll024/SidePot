import Foundation
import Testing
@testable import SidepotCore

@Suite("Money")
struct MoneyTests {
    @Test("Arithmetic preserves exact Decimal values")
    func arithmetic() {
        let a = Money(amount: 12.50)
        let b = Money(amount: 7.25)
        #expect((a + b).amount == Decimal(string: "19.75"))
        #expect((a - b).amount == Decimal(string: "5.25"))
        #expect((-a).amount == Decimal(string: "-12.50"))
    }

    @Test("isZero / isPositive / isNegative")
    func signs() {
        #expect(Money(amount: 0).isZero)
        #expect(Money(amount: 1).isPositive)
        #expect(Money(amount: -1).isNegative)
    }

    @Test("Comparable orders by amount")
    func comparable() {
        #expect(Money(amount: 1) < Money(amount: 2))
        #expect(!(Money(amount: 2) < Money(amount: 2)))
    }
}

@Suite("MoneySplit")
struct MoneySplitTests {
    @Test("Splits that divide evenly")
    func evenDivision() {
        let shares = MoneySplit.evenSplit(10, into: 2)
        #expect(shares == [5, 5])
    }

    @Test("Splits that don't divide evenly still sum to the exact total")
    func unevenDivisionSumsExactly() {
        let shares = MoneySplit.evenSplit(10, into: 3)
        #expect(shares.reduce(0, +) == 10)
        #expect(shares.count == 3)
        // Every share should be within a penny of the others.
        let distinctValues = Set(shares)
        #expect(distinctValues.count <= 2)
    }

    @Test("Splitting a negative total still sums exactly")
    func negativeTotal() {
        let shares = MoneySplit.evenSplit(-10, into: 3)
        #expect(shares.reduce(0, +) == -10)
    }

    @Test("Single-way split returns the whole amount")
    func singleShare() {
        #expect(MoneySplit.evenSplit(7.77, into: 1) == [7.77])
    }

    @Test("Many-way split of a small odd amount still sums exactly")
    func manyWaySplit() {
        let shares = MoneySplit.evenSplit(1, into: 7)
        #expect(shares.reduce(0, +) == 1)
        #expect(shares.count == 7)
    }
}
