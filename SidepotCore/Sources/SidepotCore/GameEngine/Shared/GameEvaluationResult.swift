import Foundation

/// A single human-readable line describing current game state (e.g. "Hole 7 — Blaise wins skin",
/// "Front nine: 2 up through 6"), for display in `GameStatusCard` / `LiveLedgerView`.
public struct GameStatusLine: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public let title: String
    public let detail: String
    public let holeNumber: Int?

    public init(id: UUID = UUID(), title: String, detail: String, holeNumber: Int?) {
        self.id = id
        self.title = title
        self.detail = detail
        self.holeNumber = holeNumber
    }
}

/// A pending money movement produced by a game evaluator. Maps directly onto a persisted
/// `LedgerEntry` once the service layer writes evaluation results back to SwiftData.
public struct LedgerEntryValue: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public let gameID: UUID
    public let holeNumber: Int?
    public let segmentName: String?
    /// Round-scoped player ID (`RoundPlayerSnapshot.id`) of who owes.
    public let fromPlayerID: UUID
    /// Round-scoped player ID of who is owed.
    public let toPlayerID: UUID
    public let amount: Decimal
    public let reason: String

    public init(
        id: UUID = UUID(),
        gameID: UUID,
        holeNumber: Int?,
        segmentName: String?,
        fromPlayerID: UUID,
        toPlayerID: UUID,
        amount: Decimal,
        reason: String
    ) {
        self.id = id
        self.gameID = gameID
        self.holeNumber = holeNumber
        self.segmentName = segmentName
        self.fromPlayerID = fromPlayerID
        self.toPlayerID = toPlayerID
        self.amount = amount
        self.reason = reason
    }
}

/// Something a game can't resolve yet — a hole missing a score, a bet still pending, a segment
/// still in progress. Surfaced in `LiveLedgerView` as "pending unresolved bets."
public struct UnresolvedGameItem: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public let description: String
    public let holeNumber: Int?

    public init(id: UUID = UUID(), description: String, holeNumber: Int?) {
        self.id = id
        self.description = description
        self.holeNumber = holeNumber
    }
}

/// The full output of evaluating one configured game against a round's current state.
public struct GameEvaluationResult: Equatable, Sendable {
    public let gameID: UUID
    public let statusLines: [GameStatusLine]
    public let ledgerEntries: [LedgerEntryValue]
    public let unresolvedItems: [UnresolvedGameItem]
    public let metadata: [String: String]

    public init(
        gameID: UUID,
        statusLines: [GameStatusLine],
        ledgerEntries: [LedgerEntryValue],
        unresolvedItems: [UnresolvedGameItem],
        metadata: [String: String] = [:]
    ) {
        self.gameID = gameID
        self.statusLines = statusLines
        self.ledgerEntries = ledgerEntries
        self.unresolvedItems = unresolvedItems
        self.metadata = metadata
    }
}
