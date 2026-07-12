import Foundation

/// Domain errors surfaced to the user. Every case carries a human-readable `context` string so
/// call sites can explain *what* went wrong without the UI layer needing to know evaluator
/// internals.
public enum SidepotError: LocalizedError, Equatable, Sendable {
    case invalidRound(String)
    case incompleteScores(String)
    case invalidHandicap(String)
    case nonZeroSumLedger(String)
    case unresolvedGame(String)
    case invalidPress(String)
    case persistenceFailure(String)

    public var errorDescription: String? {
        switch self {
        case .invalidRound(let context):
            return "This round can't be used right now. \(context)"
        case .incompleteScores(let context):
            return "Some scores are missing. \(context)"
        case .invalidHandicap(let context):
            return "That handicap value isn't valid. \(context)"
        case .nonZeroSumLedger(let context):
            return "The money doesn't add up. \(context)"
        case .unresolvedGame(let context):
            return "A game hasn't been fully resolved yet. \(context)"
        case .invalidPress(let context):
            return "That press can't be created. \(context)"
        case .persistenceFailure(let context):
            return "Sidepot couldn't save your changes. \(context)"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .invalidRound:
            return "Check the round setup and try again."
        case .incompleteScores:
            return "Enter every player's score for this hole before continuing."
        case .invalidHandicap:
            return "Handicap index must be between -10 and 54."
        case .nonZeroSumLedger:
            return "This usually means a bet was configured inconsistently. Review the game settings for this round."
        case .unresolvedGame:
            return "Resolve the pending bet before finishing the round."
        case .invalidPress:
            return "Presses need at least one hole remaining in the segment and can't exceed the configured limit."
        case .persistenceFailure:
            return "Try again. If this keeps happening, your device may be low on storage."
        }
    }
}
