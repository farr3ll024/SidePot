import Foundation
import SidepotCore

/// Runs every configured game for a round through the appropriate evaluator and turns the results
/// into persisted `LedgerEntry` rows. Injected as a protocol per §3 ("Dependency injection through
/// protocols") so views/view models can be tested against a fake implementation.
protocol GameEvaluationServicing {
    func evaluateAllGames(for round: GolfRound) throws -> [GameEvaluationResult]
    func recalculateLedger(for round: GolfRound) throws
}

struct GameEvaluationService: GameEvaluationServicing {
    func evaluateAllGames(for round: GolfRound) throws -> [GameEvaluationResult] {
        let context = round.evaluationContext()
        var results: [GameEvaluationResult] = []

        for game in (round.games ?? []).filter(\.isEnabled) {
            switch game.gameType {
            case .skins:
                let configuration: SkinsConfiguration = try game.decodedConfiguration()
                results.append(try SkinsEvaluator().evaluate(gameID: game.id, context: context, configuration: configuration))
            case .nassau:
                let configuration: NassauConfiguration = try game.decodedConfiguration()
                results.append(try NassauEvaluator().evaluate(gameID: game.id, context: context, configuration: configuration))
            case .matchPlay:
                let configuration: MatchPlayConfiguration = try game.decodedConfiguration()
                results.append(try MatchPlayEvaluator().evaluate(gameID: game.id, context: context, configuration: configuration))
            case .strokePlay:
                let configuration: StrokePlayConfiguration = try game.decodedConfiguration()
                results.append(try StrokePlayEvaluator().evaluate(gameID: game.id, context: context, configuration: configuration))
            case .greenies:
                let configuration: GreeniesConfiguration = try game.decodedConfiguration()
                results.append(try GreeniesEvaluator().evaluate(gameID: game.id, context: context, configuration: configuration))
            case .sandies:
                let configuration: SandiesConfiguration = try game.decodedConfiguration()
                results.append(try SandiesEvaluator().evaluate(gameID: game.id, context: context, configuration: configuration))
            case .birdies:
                let configuration: BirdiesConfiguration = try game.decodedConfiguration()
                results.append(try BirdiesEvaluator().evaluate(gameID: game.id, context: context, configuration: configuration))
            case .custom:
                let configuration: CustomBetConfiguration = try game.decodedConfiguration()
                results.append(try CustomBetEvaluator().evaluate(gameID: game.id, context: context, configuration: configuration))
            }
        }

        return results
    }

    /// Deletes every ledger entry currently attached to `round` and replaces it with a fresh
    /// evaluation. Recalculation is always wholesale, never incremental — see
    /// IMPLEMENTATION_SPEC.md §10 and DEVIATIONS.md.
    func recalculateLedger(for round: GolfRound) throws {
        let results = try evaluateAllGames(for: round)
        let allEntries = results.flatMap(\.ledgerEntries)
        try LedgerValidator.validate(entries: allEntries)

        guard let modelContext = round.modelContext else {
            throw SidepotError.persistenceFailure("This round hasn't been saved yet.")
        }

        for entry in round.ledgerEntries ?? [] {
            modelContext.delete(entry)
        }

        for value in allEntries {
            let entry = LedgerEntry(value: value)
            entry.round = round
            modelContext.insert(entry)
        }
    }
}
