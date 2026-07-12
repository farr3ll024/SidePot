import Foundation

/// Conformers compute a game's live or final state from a round snapshot. Implementations must be
/// pure, deterministic, and idempotent: calling `evaluate` twice with identical `context` and
/// `configuration` must produce byte-identical results, and results must be fully derivable from
/// `context` — never from mutable state held by the evaluator itself (§10, execution rule #7).
///
/// - Note: The spec's original signature (`evaluate(context:configuration:)`) has no way to
///   supply the `gameID` that `GameEvaluationResult` requires. `gameID` was added as an explicit
///   parameter to resolve that contradiction — see `DEVIATIONS.md`.
public protocol GolfGameEvaluating {
    associatedtype Configuration: Codable & Equatable

    func evaluate(
        gameID: UUID,
        context: RoundEvaluationContext,
        configuration: Configuration
    ) throws -> GameEvaluationResult
}
