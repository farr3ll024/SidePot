import Foundation

public enum GameType: String, Codable, CaseIterable, Sendable {
    case skins
    case nassau
    case matchPlay
    case strokePlay
    case greenies
    case sandies
    case birdies
    case custom

    public var displayName: String {
        switch self {
        case .skins: return "Skins"
        case .nassau: return "Nassau"
        case .matchPlay: return "Match Play"
        case .strokePlay: return "Stroke Play"
        case .greenies: return "Greenies"
        case .sandies: return "Sandies"
        case .birdies: return "Birdies"
        case .custom: return "Custom Bet"
        }
    }
}
