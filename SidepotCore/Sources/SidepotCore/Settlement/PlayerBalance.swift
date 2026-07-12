import Foundation

/// A player's net position from ledger entries: positive means they're owed money, negative
/// means they owe it.
public struct PlayerBalance: Equatable, Sendable {
    public let playerID: UUID
    public let amount: Decimal

    public init(playerID: UUID, amount: Decimal) {
        self.playerID = playerID
        self.amount = amount
    }
}

/// One optimized payment produced by `SettlementOptimizer`. Maps onto a persisted
/// `SettlementPayment`.
public struct SettlementPaymentValue: Equatable, Identifiable, Sendable {
    public let id: UUID
    public let fromPlayerID: UUID
    public let toPlayerID: UUID
    public let amount: Decimal

    public init(id: UUID = UUID(), fromPlayerID: UUID, toPlayerID: UUID, amount: Decimal) {
        self.id = id
        self.fromPlayerID = fromPlayerID
        self.toPlayerID = toPlayerID
        self.amount = amount
    }
}
