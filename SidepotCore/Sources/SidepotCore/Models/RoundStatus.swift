import Foundation

public enum RoundStatus: String, Codable, CaseIterable, Sendable {
    case draft
    case active
    case completed
    case abandoned
}
