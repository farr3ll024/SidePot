import Foundation
import SwiftData

/// A person who can be added to groups and rounds. `Player` is never hard-deleted once it's been
/// used in a historical round — see `isArchived` (§18 PlayersView: "Prevent deletion if historical
/// rounds reference the player. Archive instead").
@Model
public final class Player {
    public var id: UUID = UUID()
    public var firstName: String = ""
    public var lastName: String = ""
    public var nickname: String?
    public var defaultHandicapIndex: Double?
    public var venmoHandle: String?
    public var cashAppHandle: String?
    public var createdAt: Date = Date.now
    public var updatedAt: Date = Date.now
    public var isArchived: Bool = false

    @Relationship(inverse: \GolfGroup.players)
    public var groups: [GolfGroup]? = []

    public init(
        id: UUID = UUID(),
        firstName: String,
        lastName: String = "",
        nickname: String? = nil,
        defaultHandicapIndex: Double? = nil,
        venmoHandle: String? = nil,
        cashAppHandle: String? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        isArchived: Bool = false
    ) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.nickname = nickname
        self.defaultHandicapIndex = defaultHandicapIndex
        self.venmoHandle = venmoHandle
        self.cashAppHandle = cashAppHandle
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isArchived = isArchived
    }

    public var displayName: String {
        if let nickname, !nickname.trimmingCharacters(in: .whitespaces).isEmpty {
            return nickname
        }
        let full = "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
        return full.isEmpty ? "Unnamed Player" : full
    }

    public var initials: String {
        let firstInitial = firstName.first.map(String.init) ?? ""
        let lastInitial = lastName.first.map(String.init) ?? ""
        let combined = (firstInitial + lastInitial).uppercased()
        return combined.isEmpty ? "?" : combined
    }

    /// Validates the fields a UI form should check before saving. Throws `SidepotError
    /// .invalidRound` for a missing name or `.invalidHandicap` for an out-of-range index.
    public func validate() throws {
        if firstName.trimmingCharacters(in: .whitespaces).isEmpty {
            throw SidepotError.invalidRound("A player needs a first name.")
        }
        if let handicap = defaultHandicapIndex, !(-10...54).contains(handicap) {
            throw SidepotError.invalidHandicap("Handicap index must be between -10 and 54.")
        }
    }
}
