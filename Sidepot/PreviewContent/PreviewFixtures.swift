import Foundation
import SwiftData
import SidepotCore

/// Seed data for SwiftUI previews and the simulator (§27). Not used in the shipping app's normal
/// startup path — only `#Preview` blocks and `PersistenceController.makePreviewContainer` calls
/// reach for this.
enum PreviewFixtures {
    @MainActor
    static func populate(_ container: ModelContainer) {
        let context = container.mainContext

        let blaise = Player(firstName: "Blaise", lastName: "Reints", defaultHandicapIndex: 7)
        let mike = Player(firstName: "Mike", defaultHandicapIndex: 12)
        let john = Player(firstName: "John", defaultHandicapIndex: 18)
        let ryan = Player(firstName: "Ryan", defaultHandicapIndex: 22)
        [blaise, mike, john, ryan].forEach(context.insert)

        let group = GolfGroup(name: "Saturday Degenerates", players: [blaise, mike, john, ryan])
        context.insert(group)

        let par = [4, 4, 3, 5, 4, 4, 3, 5, 4, 4, 4, 3, 5, 4, 4, 3, 5, 4]
        let holes = (1...18).map { number in
            HoleSnapshot(number: number, par: par[number - 1], strokeIndex: number, yardage: nil)
        }
        let course = CourseSnapshot(name: "Toad Valley Golf Course", teeName: "White", holeCount: 18, holes: holes)
        context.insert(course)
        holes.forEach { $0.course = course }

        let round = GolfRound(status: .active, startedAt: .now, scheduledDate: .now, activeHoleNumber: 13)
        round.course = course
        course.round = round
        context.insert(round)

        let roundPlayers = [blaise, mike, john, ryan].enumerated().map { index, player -> RoundPlayer in
            let handicap = Int(player.defaultHandicapIndex ?? 0)
            let rp = RoundPlayer(
                player: player,
                displayNameSnapshot: player.displayName,
                handicapIndexSnapshot: player.defaultHandicapIndex,
                courseHandicap: handicap,
                playingHandicap: handicap,
                startingOrder: index
            )
            rp.round = round
            context.insert(rp)
            return rp
        }

        for hole in holes where hole.number <= 12 {
            for (index, roundPlayer) in roundPlayers.enumerated() {
                let gross = hole.par + (index % 3) - 1
                let score = HoleScore(holeNumber: hole.number, roundPlayer: roundPlayer, grossScore: gross, strokesReceived: 0)
                score.round = round
                context.insert(score)
            }
        }

        let skinsConfig = SkinsConfiguration(scoringMode: .gross, baseAmount: 2, participantIDs: roundPlayers.map(\.id))
        if let skins = try? GameConfiguration(gameType: .skins, name: "Skins", stakeAmount: 2, configuration: skinsConfig) {
            skins.owningRound = round
            context.insert(skins)
        }

        let nassauConfig = NassauConfiguration(
            frontStake: 5,
            backStake: 5,
            overallStake: 5,
            teamMode: .individual,
            sideAPlayerIDs: [roundPlayers[0].id],
            sideBPlayerIDs: [roundPlayers[1].id]
        )
        if let nassau = try? GameConfiguration(gameType: .nassau, name: "Nassau", stakeAmount: 5, configuration: nassauConfig) {
            nassau.owningRound = round
            context.insert(nassau)
        }

        try? context.save()
    }
}
