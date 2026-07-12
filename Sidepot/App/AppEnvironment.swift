import Foundation
import Observation

/// The app's dependency-injection container. Views reach for services through this rather than
/// instantiating concrete types directly, so tests/previews can substitute fakes (§3).
@Observable
final class AppEnvironment {
    let gameEvaluationService: GameEvaluationServicing
    let settlementService: SettlementServicing

    init(
        gameEvaluationService: GameEvaluationServicing = GameEvaluationService(),
        settlementService: SettlementServicing = SettlementService()
    ) {
        self.gameEvaluationService = gameEvaluationService
        self.settlementService = settlementService
    }
}
