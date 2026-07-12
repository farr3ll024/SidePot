import Foundation
import SwiftData

/// A single persisted money movement produced by recalculating a round's games. `LedgerEntry`
/// rows are never edited in place — a recalculation deletes and replaces every entry for the
/// affected games, keeping recalculation idempotent (§10, §22).
@Model
public final class LedgerEntry {
    public var id: UUID = UUID()
    public var gameID: UUID = UUID()
    public var holeNumber: Int?
    public var segmentName: String?
    public var fromPlayerID: UUID = UUID()
    public var toPlayerID: UUID = UUID()
    public var amount: Decimal = 0
    public var reason: String = ""
    public var createdAt: Date = Date.now

    public var round: GolfRound?

    public init(
        id: UUID = UUID(),
        gameID: UUID,
        holeNumber: Int?,
        segmentName: String?,
        fromPlayerID: UUID,
        toPlayerID: UUID,
        amount: Decimal,
        reason: String,
        createdAt: Date = .now
    ) {
        self.id = id
        self.gameID = gameID
        self.holeNumber = holeNumber
        self.segmentName = segmentName
        self.fromPlayerID = fromPlayerID
        self.toPlayerID = toPlayerID
        self.amount = amount
        self.reason = reason
        self.createdAt = createdAt
    }

    public convenience init(value: LedgerEntryValue) {
        self.init(
            id: value.id,
            gameID: value.gameID,
            holeNumber: value.holeNumber,
            segmentName: value.segmentName,
            fromPlayerID: value.fromPlayerID,
            toPlayerID: value.toPlayerID,
            amount: value.amount,
            reason: value.reason
        )
    }

    public func validate() throws {
        guard amount > 0 else {
            throw SidepotError.nonZeroSumLedger("Ledger entries must be for a positive amount.")
        }
        guard fromPlayerID != toPlayerID else {
            throw SidepotError.nonZeroSumLedger("A player can't owe themselves money.")
        }
    }
}
