import Foundation
import SwiftData

/// A configured game, either a group's default template or an instance attached to a specific
/// round. The type-specific rules (`SkinsConfiguration`, `NassauConfiguration`, etc.) are
/// Codable structs serialized into `configurationData`, keeping this model generic across all
/// `GameType` cases (§7).
@Model
public final class GameConfiguration {
    public var id: UUID = UUID()
    public var gameType: GameType = GameType.skins
    public var name: String = ""
    public var stakeAmount: Decimal = 0
    public var isEnabled: Bool = true
    public var configurationData: Data = Data()

    public var owningRound: GolfRound?
    public var owningGroup: GolfGroup?

    public init(
        id: UUID = UUID(),
        gameType: GameType,
        name: String,
        stakeAmount: Decimal,
        isEnabled: Bool = true,
        configurationData: Data
    ) {
        self.id = id
        self.gameType = gameType
        self.name = name
        self.stakeAmount = stakeAmount
        self.isEnabled = isEnabled
        self.configurationData = configurationData
    }

    /// Convenience initializer that encodes `configuration` immediately.
    public convenience init<Configuration: Encodable>(
        id: UUID = UUID(),
        gameType: GameType,
        name: String,
        stakeAmount: Decimal,
        isEnabled: Bool = true,
        configuration: Configuration
    ) throws {
        let data = try JSONEncoder.sidepot.encode(configuration)
        self.init(
            id: id,
            gameType: gameType,
            name: name,
            stakeAmount: stakeAmount,
            isEnabled: isEnabled,
            configurationData: data
        )
    }

    public func decodedConfiguration<Configuration: Decodable>(as type: Configuration.Type = Configuration.self) throws -> Configuration {
        do {
            return try JSONDecoder.sidepot.decode(Configuration.self, from: configurationData)
        } catch {
            throw SidepotError.persistenceFailure("Couldn't read the settings for \"\(name)\".")
        }
    }

    public func updateConfiguration<Configuration: Encodable>(_ configuration: Configuration) throws {
        configurationData = try JSONEncoder.sidepot.encode(configuration)
    }
}

extension JSONEncoder {
    static let sidepot: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()
}

extension JSONDecoder {
    static let sidepot: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
}
