import Foundation

public enum NassauSegment: String, Codable, Equatable, CaseIterable, Sendable {
    case front
    case back
    case overall

    public var displayName: String {
        switch self {
        case .front: return "Front"
        case .back: return "Back"
        case .overall: return "Overall"
        }
    }
}

public enum TeamMode: String, Codable, Equatable, Sendable {
    case individual
    case twoTeams
}

public enum AutoPressRule: String, Codable, Equatable, Sendable {
    case none
    case twoDown
}

/// A user-initiated press action, recorded so the evaluator can regenerate the resulting
/// `NassauPress` deterministically on every recalculation (§10, §12; see `DEVIATIONS.md` —
/// "Nassau manual presses must be recorded somewhere the evaluator can see").
public struct ManualPressRecord: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public let segment: NassauSegment
    public let createdAfterHole: Int
    public let initiatingSide: MatchSide

    public init(id: UUID = UUID(), segment: NassauSegment, createdAfterHole: Int, initiatingSide: MatchSide) {
        self.id = id
        self.segment = segment
        self.createdAfterHole = createdAfterHole
        self.initiatingSide = initiatingSide
    }
}

public struct NassauConfiguration: Codable, Equatable, Sendable {
    public var frontStake: Decimal
    public var backStake: Decimal
    public var overallStake: Decimal
    public var teamMode: TeamMode
    public var autoPressRule: AutoPressRule
    public var maxPressesPerSegment: Int?
    public var allowManualPresses: Bool
    public var pressStakeMultiplier: Decimal
    public var allowDormiePress: Bool

    /// Gross or net comparison for hole winners (needed by the evaluator; not itemized in the
    /// original spec field list — see `DEVIATIONS.md`).
    public var scoringMode: ScoringMode
    /// Round-scoped player IDs on side A. Exactly one player for `teamMode == .individual`.
    public var sideAPlayerIDs: [UUID]
    /// Round-scoped player IDs on side B. Exactly one player for `teamMode == .individual`.
    public var sideBPlayerIDs: [UUID]
    /// User-created presses, recorded as they happen so recalculation stays deterministic.
    public var manualPresses: [ManualPressRecord]

    public init(
        frontStake: Decimal,
        backStake: Decimal,
        overallStake: Decimal,
        teamMode: TeamMode = .individual,
        autoPressRule: AutoPressRule = .twoDown,
        maxPressesPerSegment: Int? = nil,
        allowManualPresses: Bool = true,
        pressStakeMultiplier: Decimal = 1,
        allowDormiePress: Bool = false,
        scoringMode: ScoringMode = .net,
        sideAPlayerIDs: [UUID],
        sideBPlayerIDs: [UUID],
        manualPresses: [ManualPressRecord] = []
    ) {
        self.frontStake = frontStake
        self.backStake = backStake
        self.overallStake = overallStake
        self.teamMode = teamMode
        self.autoPressRule = autoPressRule
        self.maxPressesPerSegment = maxPressesPerSegment
        self.allowManualPresses = allowManualPresses
        self.pressStakeMultiplier = pressStakeMultiplier
        self.allowDormiePress = allowDormiePress
        self.scoringMode = scoringMode
        self.sideAPlayerIDs = sideAPlayerIDs
        self.sideBPlayerIDs = sideBPlayerIDs
        self.manualPresses = manualPresses
    }

    func stake(for segment: NassauSegment) -> Decimal {
        switch segment {
        case .front: return frontStake
        case .back: return backStake
        case .overall: return overallStake
        }
    }

    /// The canonical identifier for a side, used as `NassauPress.initiatingSideID` — the spec
    /// models this as a bare `UUID` without a separately-modeled "side" entity, so the first
    /// player on each side stands in for it (see `DEVIATIONS.md`).
    func sideIdentifier(_ side: MatchSide) -> UUID? {
        switch side {
        case .a: return sideAPlayerIDs.first
        case .b: return sideBPlayerIDs.first
        }
    }

    func playerIDs(for side: MatchSide) -> [UUID] {
        switch side {
        case .a: return sideAPlayerIDs
        case .b: return sideBPlayerIDs
        }
    }
}
