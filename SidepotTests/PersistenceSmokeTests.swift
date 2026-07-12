import XCTest
import SwiftData
@testable import Sidepot
import SidepotCore

/// A small integration check that the app target's model container actually stands up and
/// accepts inserts end to end. The exhaustive, fast-running domain-logic tests live in
/// `SidepotCore/Tests/SidepotCoreTests` and run via `swift test` without needing a simulator —
/// this target is for checks that specifically need the app bundle (SwiftData model container
/// wiring, app-level services). It intentionally stays small; most business logic is already
/// covered at the SidepotCore layer.
@MainActor
final class PersistenceSmokeTests: XCTestCase {
    func testPreviewContainerAcceptsInserts() throws {
        let container = PersistenceController.makePreviewContainer()
        let context = container.mainContext

        let player = Player(firstName: "Test", lastName: "Player")
        context.insert(player)
        try context.save()

        let descriptor = FetchDescriptor<Player>()
        let players = try context.fetch(descriptor)
        XCTAssertEqual(players.count, 1)
        XCTAssertEqual(players.first?.displayName, "Test Player")
    }

    func testGameEvaluationServiceRecalculatesAZeroSumLedger() throws {
        let container = PersistenceController.makePreviewContainer(populate: PreviewFixtures.populate)
        let context = container.mainContext
        let round = try XCTUnwrap(try context.fetch(FetchDescriptor<GolfRound>()).first)

        try GameEvaluationService().recalculateLedger(for: round)

        let entries = (round.ledgerEntries ?? []).map {
            LedgerEntryValue(
                id: $0.id, gameID: $0.gameID, holeNumber: $0.holeNumber, segmentName: $0.segmentName,
                fromPlayerID: $0.fromPlayerID, toPlayerID: $0.toPlayerID, amount: $0.amount, reason: $0.reason
            )
        }
        let balances = LedgerValidator.balances(from: entries)
        XCTAssertTrue(LedgerValidator.isZeroSum(balances))
    }
}
