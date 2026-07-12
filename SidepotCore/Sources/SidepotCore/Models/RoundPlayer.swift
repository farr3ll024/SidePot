import Foundation
import SwiftData

/// A per-round snapshot of a `Player`. Handicaps and display name are copied in at round creation
/// so a completed round's history never changes if the underlying `Player` record is later edited
/// or archived (§7: "Never rely only on the current Player record after a round is completed").
@Model
public final class RoundPlayer {
    public var id: UUID = UUID()
    public var player: Player?
    public var displayNameSnapshot: String = ""
    public var handicapIndexSnapshot: Double?
    public var courseHandicap: Int = 0
    public var playingHandicap: Int = 0
    public var teamID: UUID?
    public var startingOrder: Int = 0

    public var round: GolfRound?

    public init(
        id: UUID = UUID(),
        player: Player?,
        displayNameSnapshot: String,
        handicapIndexSnapshot: Double?,
        courseHandicap: Int,
        playingHandicap: Int,
        teamID: UUID? = nil,
        startingOrder: Int = 0
    ) {
        self.id = id
        self.player = player
        self.displayNameSnapshot = displayNameSnapshot
        self.handicapIndexSnapshot = handicapIndexSnapshot
        self.courseHandicap = courseHandicap
        self.playingHandicap = playingHandicap
        self.teamID = teamID
        self.startingOrder = startingOrder
    }

    public var asSnapshot: RoundPlayerSnapshot {
        RoundPlayerSnapshot(
            id: id,
            playerID: player?.id ?? id,
            displayName: displayNameSnapshot,
            handicapIndex: handicapIndexSnapshot,
            courseHandicap: courseHandicap,
            playingHandicap: playingHandicap,
            teamID: teamID,
            startingOrder: startingOrder
        )
    }
}
