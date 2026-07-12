import Foundation
import SwiftData

/// Builds the app's single `ModelContainer`. Centralized here so the schema (and the switch to an
/// in-memory store for previews/tests) lives in one place instead of being duplicated across
/// `SidepotApp` and preview code.
public enum PersistenceController {
    public static var schema: Schema {
        Schema([
            Player.self,
            GolfGroup.self,
            CourseSnapshot.self,
            HoleSnapshot.self,
            GolfRound.self,
            RoundPlayer.self,
            HoleScore.self,
            GameConfiguration.self,
            LedgerEntry.self,
            SettlementPayment.self
        ])
    }

    /// The on-device store used by the running app. Sidepot is offline-first and stores
    /// everything locally (§25) — no CloudKit configuration in v1.
    public static func makeContainer() -> ModelContainer {
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Failed to create Sidepot's persistent store: \(error)")
        }
    }

    /// An in-memory container for SwiftUI previews and tests, optionally pre-populated.
    ///
    /// `@MainActor` because populate closures (e.g. `PreviewFixtures.populate`) need to touch
    /// `ModelContainer.mainContext`, which is itself main-actor-isolated. `#Preview` bodies and
    /// `@MainActor`-marked test methods already run on the main actor, so this doesn't require
    /// callers to do anything differently.
    @MainActor
    public static func makePreviewContainer(populate: @MainActor (ModelContainer) -> Void = { _ in }) -> ModelContainer {
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        do {
            let container = try ModelContainer(for: schema, configurations: [configuration])
            populate(container)
            return container
        } catch {
            fatalError("Failed to create Sidepot's preview store: \(error)")
        }
    }
}
