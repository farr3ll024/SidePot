import Foundation
import SwiftData

/// A recurring group of players (e.g. "Saturday Degenerates") with default games/stakes that
/// pre-fill the create-round flow.
@Model
public final class GolfGroup {
    public var id: UUID = UUID()
    public var name: String = ""
    public var createdAt: Date = Date.now
    public var updatedAt: Date = Date.now
    public var isArchived: Bool = false

    public var players: [Player]? = []

    @Relationship(deleteRule: .cascade, inverse: \GameConfiguration.owningGroup)
    public var defaultGameConfigurations: [GameConfiguration]? = []

    public init(
        id: UUID = UUID(),
        name: String,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        isArchived: Bool = false,
        players: [Player] = []
    ) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isArchived = isArchived
        self.players = players
    }

    /// A group must have at least two players to be usable for a round, though it may be created
    /// with fewer while players are still being added (§7: "At least two players for an active
    /// group").
    public var isReadyForRound: Bool {
        (players?.filter { !$0.isArchived }.count ?? 0) >= 2
    }

    public func validate() throws {
        if name.trimmingCharacters(in: .whitespaces).isEmpty {
            throw SidepotError.invalidRound("A group needs a name.")
        }
    }
}
