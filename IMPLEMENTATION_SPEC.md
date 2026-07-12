# Sidepot — Claude Code Implementation Specification

## 1. Mission

Build a production-quality native iOS application named **Sidepot**.

Sidepot is a companion app for golfers who already use an app such as 18Birdies for GPS, scorekeeping, and golf statistics but want a better way to manage friendly on-course betting.

The app must not replace 18Birdies. It must focus on:

- Round setup
- Group management
- Handicap-aware games
- Live side-bet tracking
- Nassau and skins
- Presses
- Custom bets
- Running balances
- End-of-round settlement
- Shareable round receipts
- Season standings

The first release must work completely offline and must not require an account or custom backend.

## 2. Product Positioning

Primary promise:

> Keep score in 18Birdies. Track the money in Sidepot.

Target users:

- Recurring golf groups
- Foursomes that play for small stakes
- Players who currently track games manually
- Players who want automatic settlement
- Players who want season-long standings

This app must not:

- Process payments
- Hold money
- Provide sportsbook odds
- Enable public wagering
- Facilitate wagers between strangers
- Advertise itself as a gambling platform
- Scrape or depend on undocumented 18Birdies APIs

All monetary values are tracking-only.

## 3. Platform and Technical Constraints

### Required

- Native iOS app
- Swift 6
- SwiftUI
- iOS 18 minimum deployment target
- SwiftData for persistence
- XCTest and Swift Testing where appropriate
- MVVM or feature-oriented architecture
- Dependency injection through protocols
- No third-party dependencies in v1
- Dark mode and light mode support
- Dynamic Type support
- VoiceOver support
- Offline-first behavior

### Deferred

- CloudKit sync
- Sign in with Apple
- StoreKit subscriptions
- Apple Watch
- Live Activities
- App Intents
- Course database APIs
- 18Birdies integration
- Push notifications
- Android
- Web app

The codebase should be designed so these can be added later without rewriting the core game engine.

## 4. Repository and Project Setup

Create an Xcode project named:

`Sidepot`

Bundle identifier placeholder:

`com.example.sidepot`

Project structure:

```text
Sidepot/
├── App/
│   ├── SidepotApp.swift
│   ├── AppState.swift
│   ├── AppEnvironment.swift
│   └── RootView.swift
├── Core/
│   ├── Models/
│   ├── Persistence/
│   ├── Extensions/
│   ├── Utilities/
│   └── DesignSystem/
├── GameEngine/
│   ├── Protocols/
│   ├── Handicap/
│   ├── Nassau/
│   ├── Skins/
│   ├── MatchPlay/
│   ├── StrokePlay/
│   ├── Junk/
│   ├── CustomBets/
│   └── Shared/
├── Settlement/
├── Features/
│   ├── Onboarding/
│   ├── Home/
│   ├── Groups/
│   ├── Players/
│   ├── CreateRound/
│   ├── ActiveRound/
│   ├── RoundSummary/
│   ├── History/
│   ├── Standings/
│   └── Settings/
├── Services/
├── PreviewContent/
├── Resources/
├── SidepotTests/
└── SidepotUITests/
```

## 5. Core User Flow

### First launch

1. Show a short onboarding sequence.
2. Explain that Sidepot tracks friendly golf games but does not move money.
3. Let the user create their first player profile.
4. Let the user create a group or skip.
5. Land on the Home screen.

### Starting a round

1. Tap **New Round**.
2. Choose an existing group or select players manually.
3. Enter:
   - Course name
   - Date
   - Number of holes
   - Tee name, optional
   - Player handicaps for this round
4. Select games.
5. Configure stakes and rules.
6. Review setup.
7. Start round.

### During a round

1. Show active hole.
2. Enter gross scores.
3. Record side-bet results.
4. Update live game status.
5. Show running player balances.
6. Move forward and backward between holes.
7. Allow editing prior holes.
8. Persist after every change.

### Finishing a round

1. Validate every required hole.
2. Calculate final ledger.
3. Validate zero-sum accounting.
4. Optimize settlement payments.
5. Show summary.
6. Save completed round.
7. Generate shareable text receipt.

## 6. Navigation

Use `NavigationStack`.

Root tabs:

1. Home
2. History
3. Standings
4. Settings

A currently active round must be accessible from a persistent banner or top-level card on Home.

Primary navigation map:

```text
RootView
├── HomeView
│   ├── NewRoundFlow
│   ├── ActiveRoundView
│   ├── GroupsView
│   └── RecentRoundDetailView
├── HistoryView
│   └── RoundDetailView
├── StandingsView
│   ├── GroupStandingsView
│   └── PlayerSeasonDetailView
└── SettingsView
    ├── PlayersView
    ├── DefaultRulesView
    └── AboutView
```

## 7. SwiftData Models

Use `@Model` classes. Relationships must use explicit delete rules where appropriate.

### Player

Fields:

- `id: UUID`
- `firstName: String`
- `lastName: String`
- `nickname: String?`
- `defaultHandicapIndex: Double?`
- `venmoHandle: String?`
- `cashAppHandle: String?`
- `createdAt: Date`
- `updatedAt: Date`
- `isArchived: Bool`

Computed:

- `displayName`
- `initials`

Validation:

- First name required
- Handicap index between -10 and 54 inclusive
- Payment handles optional and stored only for display/handoff

### GolfGroup

Fields:

- `id: UUID`
- `name: String`
- `createdAt: Date`
- `updatedAt: Date`
- `isArchived: Bool`
- Relationship to players
- Default game configurations

Validation:

- Name required
- At least two players for an active group

### CourseSnapshot

This is a snapshot stored per round. Do not create a global course database in v1.

Fields:

- `id: UUID`
- `name: String`
- `teeName: String?`
- `holeCount: Int`
- Relationship to hole snapshots

### HoleSnapshot

Fields:

- `id: UUID`
- `number: Int`
- `par: Int`
- `strokeIndex: Int?`
- `yardage: Int?`

Validation:

- Hole number 1...18
- Par 3...6
- Stroke index 1...18 if present

### GolfRound

Fields:

- `id: UUID`
- `status: RoundStatus`
- `startedAt: Date?`
- `completedAt: Date?`
- `scheduledDate: Date`
- `createdAt: Date`
- `updatedAt: Date`
- `currencyCode: String`
- `usesRealCurrencyLabels: Bool`
- `notes: String?`
- Relationship to `CourseSnapshot`
- Relationship to `RoundPlayer`
- Relationship to `HoleScore`
- Relationship to configured games
- Relationship to ledger entries
- Relationship to settlements

Statuses:

```swift
enum RoundStatus: String, Codable, CaseIterable {
    case draft
    case active
    case completed
    case abandoned
}
```

### RoundPlayer

Represents a player snapshot for a specific round.

Fields:

- `id: UUID`
- Relationship to Player
- `displayNameSnapshot: String`
- `handicapIndexSnapshot: Double?`
- `courseHandicap: Int`
- `playingHandicap: Int`
- `teamID: UUID?`
- `startingOrder: Int`

Never rely only on the current Player record after a round is completed.

### HoleScore

Fields:

- `id: UUID`
- `holeNumber: Int`
- Relationship to RoundPlayer
- `grossScore: Int?`
- `netScore: Int?`
- `strokesReceived: Int`
- `isConceded: Bool`
- `didNotFinish: Bool`
- `updatedAt: Date`

Validation:

- Gross score normally 1...20
- Nil means not entered
- A conceded score may still store an agreed gross score
- Did-not-finish scores must be excluded from games that require a numeric result unless rules specify otherwise

### GameConfiguration

Use an enum-backed model or separate models if persistence requires it.

Fields:

- `id: UUID`
- `gameType: GameType`
- `name: String`
- `stakeAmount: Decimal`
- `isEnabled: Bool`
- `configurationData: Data`

Game types:

```swift
enum GameType: String, Codable, CaseIterable {
    case skins
    case nassau
    case matchPlay
    case strokePlay
    case greenies
    case sandies
    case birdies
    case custom
}
```

Use Codable configuration structs serialized to Data.

### LedgerEntry

Fields:

- `id: UUID`
- Relationship to GolfRound
- `gameID: UUID`
- `holeNumber: Int?`
- `segmentName: String?`
- `fromPlayerID: UUID`
- `toPlayerID: UUID`
- `amount: Decimal`
- `reason: String`
- `createdAt: Date`

Rules:

- Amount must be positive
- From and to players must differ
- Every final balance must be derivable from ledger entries

### SettlementPayment

Fields:

- `id: UUID`
- `fromPlayerID: UUID`
- `toPlayerID: UUID`
- `amount: Decimal`
- `isMarkedPaid: Bool`
- `markedPaidAt: Date?`

## 8. Money and Decimal Rules

Never use `Double` for money.

Use `Decimal`.

Create:

```swift
struct Money: Hashable, Codable, Comparable {
    let amount: Decimal
    let currencyCode: String
}
```

Requirements:

- Use bankers rounding only when required
- Display two decimal places unless amount is a whole number
- Preserve exact arithmetic
- Currency defaults to USD
- App can label values as points or Golf Bucks instead of dollars

A round must not be marked complete unless:

```text
sum(all player balances) == 0
```

Allow a tolerance only if unavoidable during currency rounding, but exact equality is expected for normal integer or two-decimal stakes.

## 9. Handicap Engine

Create a pure, deterministic handicap module.

### Inputs

- Player handicap index
- Optional course rating
- Optional slope rating
- Optional par
- Round handicap override
- Allow manual course handicap entry

### V1 behavior

Because course data is manual in v1:

- Default to manually entered course handicap
- If slope, rating, and par are provided, calculate course handicap
- Allow the organizer to override any calculated value
- Persist the resulting course handicap snapshot

Formula:

```text
Course Handicap =
Handicap Index × (Slope Rating / 113)
+ (Course Rating - Par)
```

Round to nearest whole number according to accepted golf handicap rounding behavior.

### Playing handicap

Allow game configuration to define an allowance percentage.

Examples:

- 100%
- 90%
- 85%

### Stroke allocation

For an 18-hole round:

- Determine the lowest playing handicap in the match
- Each other player receives the difference
- Allocate one stroke to holes in ascending stroke-index order
- If difference exceeds 18, allocate second strokes beginning again at stroke index 1
- Support plus handicaps
- Support manual hole-by-hole stroke overrides

For a 9-hole round:

- Use stroke indexes 1...9 if provided
- Otherwise allocate across the selected nine holes using normalized ordering

Implement as pure functions with exhaustive tests.

## 10. Game Engine Architecture

Game calculations must not depend on SwiftUI.

Create protocols:

```swift
protocol GolfGameEvaluating {
    associatedtype Configuration: Codable & Equatable

    func evaluate(
        context: RoundEvaluationContext,
        configuration: Configuration
    ) throws -> GameEvaluationResult
}
```

Shared context:

```swift
struct RoundEvaluationContext {
    let roundID: UUID
    let players: [RoundPlayerSnapshot]
    let holes: [HoleSnapshotValue]
    let scores: [HoleScoreValue]
    let throughHole: Int
}
```

Output:

```swift
struct GameEvaluationResult {
    let gameID: UUID
    let statusLines: [GameStatusLine]
    let ledgerEntries: [LedgerEntryValue]
    let unresolvedItems: [UnresolvedGameItem]
    let metadata: [String: String]
}
```

All evaluators must be deterministic and idempotent.

Given identical inputs, they must produce identical outputs.

Do not incrementally mutate balances inside UI code. Recalculate from source data whenever a score or game input changes.

## 11. Skins Rules

Support:

- Gross skins
- Net skins
- Carryovers
- No carryovers
- Pot-per-hole
- Fixed-value-per-skin
- Individual play only in v1
- Optional validation that all players have scores before resolving a hole

Configuration:

```swift
struct SkinsConfiguration: Codable, Equatable {
    var scoringMode: ScoringMode
    var stakeMode: SkinsStakeMode
    var baseAmount: Decimal
    var carryoversEnabled: Bool
    var carryoverCap: Int?
    var tiesCarry: Bool
}
```

Evaluation:

1. Calculate eligible score per player for each hole.
2. Find unique low score.
3. If unique low exists, award the skin.
4. If tied:
   - Carry value forward when enabled.
   - Otherwise no award.
5. Generate ledger entries from each losing player to the winning player unless configuration specifies a shared pot.
6. Any unresolved current carry must be shown in status metadata.

Example:

- $2 skin
- Four players
- Hole winner receives $2 from each of three opponents
- Net impact: winner +$6, each loser -$2

Carryover example:

- Hole 1 ties
- Hole 2 has a unique winner
- Hole 2 is worth two skins
- Winner receives $4 from each opponent

## 12. Nassau Rules

Nassau is the highest-risk feature and must be implemented carefully.

Support:

- Individual or two-team play
- Front nine
- Back nine
- Overall
- Match-play scoring
- Separate stake for each segment
- Manual presses
- Automatic two-down presses
- Optional maximum number of presses per segment
- Presses start on the next hole after creation
- Presses are independent matches
- Presses end at the segment boundary
- No dormie press in v1 unless explicitly enabled
- Halved matches produce no payment by default
- Optional split-stake behavior for halves may be deferred

Configuration:

```swift
struct NassauConfiguration: Codable, Equatable {
    var frontStake: Decimal
    var backStake: Decimal
    var overallStake: Decimal
    var teamMode: TeamMode
    var autoPressRule: AutoPressRule
    var maxPressesPerSegment: Int?
    var allowManualPresses: Bool
    var pressStakeMultiplier: Decimal
    var allowDormiePress: Bool
}
```

Segments:

```swift
enum NassauSegment: String, Codable {
    case front
    case back
    case overall
}
```

Match state:

```swift
struct MatchState {
    let holesWonBySideA: Int
    let holesWonBySideB: Int
    let holesHalved: Int
    let holesRemaining: Int
    let differential: Int
    let isDormie: Bool
    let isClosed: Bool
}
```

Two-team scoring:

- Compare best net score from each team per hole.
- Lower best-ball net score wins hole.
- Ties halve the hole.

Individual scoring:

- V1 supports exactly two sides.
- For groups larger than two, the UI must require teams.

Press model:

```swift
struct NassauPress: Codable, Equatable, Identifiable {
    let id: UUID
    let segment: NassauSegment
    let createdAfterHole: Int
    let startsOnHole: Int
    let endsOnHole: Int
    let initiatingSideID: UUID
    let stakeAmount: Decimal
    let trigger: PressTrigger
}
```

Automatic two-down press:

- When a side becomes two down in an active match, create a press if:
  - No press has already been created at that exact trigger point
  - Press cap has not been reached
  - At least one hole remains after the trigger hole
- The press starts on the next hole
- A press can itself trigger another press only if explicitly supported
- For v1, automatic presses may be triggered from the base segment only
- Nested presses are deferred

Manual press:

- User selects segment and side
- Press starts on next hole
- Reject if no hole remains
- Reject if cap reached

Ledger generation:

- Each closed base segment creates payment entries.
- Each closed press creates separate payment entries.
- Team payment allocation:
  - Default: every losing team member pays every winning team member an equal share such that each side's total exposure equals the stake.
  - Alternative simplified rule: designate team captains.
- For v1 use equal share allocation and document it in UI.

Example for $10 team Nassau with two players per team:

- Losing team total loss = $20
- Each loser pays $5 to each winner
- Each loser total = -$10
- Each winner total = +$10

## 13. Match Play

Support:

- Two individuals
- Two teams
- Gross or net
- Best ball for teams
- Fixed match stake
- Closed when lead exceeds remaining holes
- Halved match results in no payment

Do not duplicate Nassau logic. Reuse common match-state utilities.

## 14. Stroke Play

Support:

- Gross or net total
- Lowest total wins
- Optional winner-take-all
- Optional per-player stake
- Ties:
  - Push by default
  - Optional split pot

Incomplete scores prevent resolution.

## 15. Junk Games

### Greenies

Available only on par-3 holes by default.

Manual result entry:

- Select winner
- Select no winner
- Optional validation requiring par or better
- Optional carryover

### Sandies

Manual entry per hole:

- Mark player as eligible after bunker
- Confirm whether player made par or better
- Award configured amount

For v1, do not infer bunker events from score data.

### Birdies

Automatic from gross or net score according to configuration.

Example:

- Each opponent pays configured amount to a player making birdie.
- Eagle can use a multiplier if enabled.

## 16. Custom Bets

Support simple one-off bets.

Fields:

- Name
- Amount
- Participants
- Winner or winning side
- Hole number optional
- Notes
- Status: pending, resolved, void

V1 settlement rule:

- Every loser pays the winner the configured amount
- For multiple winners, split evenly
- Allow voiding without ledger impact

Examples:

- Closest to pin
- Longest drive
- First birdie
- No three-putt
- Water ball
- Beer cart challenge

## 17. Settlement Engine

Input:

```swift
[PlayerBalance]
```

where balances sum to zero.

Output:

```swift
[SettlementPayment]
```

Algorithm:

1. Separate creditors and debtors.
2. Sort by absolute balance descending.
3. Match largest debtor with largest creditor.
4. Transfer the minimum of debt and credit.
5. Update balances.
6. Continue until all balances are zero.

Requirements:

- Deterministic ordering
- Minimize number of payments reasonably
- Preserve exact totals
- Reject non-zero-sum input
- Reject negative payment amounts
- Do not create self-payments

Example:

```text
A +20
B +5
C -10
D -15
```

Possible output:

```text
D pays A 15
C pays A 5
C pays B 5
```

Create extensive unit tests.

## 18. Screens

### OnboardingView

Pages:

1. Track the game, not the GPS
2. Settle every bet automatically
3. Friendly games only
4. Create your profile

Include Skip except on final profile step.

### HomeView

Sections:

- Active round card
- New Round primary button
- Groups
- Recent rounds
- Quick season snapshot

Empty state must guide user to create players and start a round.

### PlayersView

Capabilities:

- Create
- Edit
- Archive
- Search
- Show default handicap
- Show payment handles

Prevent deletion if historical rounds reference the player. Archive instead.

### GroupsView

Capabilities:

- Create
- Edit
- Archive
- Add/remove players
- Configure default games
- Configure default stakes

### CreateRoundFlow

Steps:

1. Basics
2. Players
3. Course
4. Games
5. Review

Use a single observable view model.

Do not persist a round until the user starts it, unless using explicit draft persistence.

### ActiveRoundView

Top area:

- Course
- Hole number
- Par
- Round progress
- Back/forward controls

Primary content:

- Compact score entry grid
- Net stroke indicator
- Game events
- Running balances
- Current carryovers
- Active Nassau matches
- Press button

Bottom actions:

- Previous
- Save hole / Next
- Round menu

Round menu:

- Edit round setup
- Jump to hole
- View ledger
- Abandon round
- Finish round

Autosave on every change.

### Score Entry

Optimize for one-handed use.

Requirements:

- Large tap targets
- Stepper or numeric keypad
- Default next score based on par
- Quick buttons: par, bogey, double
- Clear score
- Show strokes received
- Show calculated net score
- Haptic feedback

### LiveLedgerView

Show:

- Player name
- Current balance
- Breakdown by game
- Pending unresolved bets
- Total exposure

Balance must be derived, never manually edited.

### RoundSummaryView

Show:

- Winner
- Final balances
- Game-by-game breakdown
- Settlement payments
- Biggest skin
- Most expensive hole
- Unresolved or voided bets
- Share receipt
- Mark payments paid

### HistoryView

Filters:

- Group
- Player
- Course
- Date range

Show:

- Date
- Course
- Players
- Winner
- User's balance if known

### StandingsView

Metrics:

- Rounds played
- Total net winnings
- Average result
- Win rate
- Skins won
- Nassau record
- Biggest win
- Biggest loss
- Current streak

Support all-time and current calendar year.

## 19. Design System

Visual direction:

- Premium golf aesthetic
- Modern, dark-friendly
- Avoid casino styling
- Avoid neon sportsbook visuals
- Use restrained green accents
- Cards with subtle depth
- Clear hierarchy
- Large financial totals
- Friendly, not corporate

Create reusable components:

- `PrimaryButton`
- `SecondaryButton`
- `MoneyText`
- `PlayerAvatar`
- `PlayerBalanceRow`
- `GameStatusCard`
- `ScoreEntryCell`
- `EmptyStateView`
- `SectionHeader`
- `RoundProgressHeader`
- `InlineErrorView`
- `ConfirmationSheet`

Use semantic colors.

Do not hard-code colors directly in feature views.

## 20. Accessibility

Required:

- Dynamic Type
- VoiceOver labels for scores and balances
- Minimum 44x44 tap targets
- Sufficient color contrast
- Do not convey positive/negative balance using color alone
- Support Reduce Motion
- Use monospaced digits for financial values
- Add accessibility hints to score controls
- Logical focus order

## 21. Error Handling

Create domain errors:

```swift
enum SidepotError: LocalizedError {
    case invalidRound
    case incompleteScores
    case invalidHandicap
    case nonZeroSumLedger
    case unresolvedGame
    case invalidPress
    case persistenceFailure
}
```

User-facing errors must:

- Explain what happened
- State how to fix it
- Avoid technical jargon
- Never silently discard scores or bets

## 22. Autosave and Recovery

Requirements:

- Save after every score edit
- Save after every bet edit
- Save after every press creation
- Store current active hole
- Restore active round after app relaunch
- Never allow more than one active round in v1
- If a second round is started, require abandoning or completing the first
- Handle interrupted termination safely

## 23. Round Editing Rules

Draft:

- Everything editable

Active:

- Players cannot be removed after scores exist
- Handicaps may be edited with explicit confirmation
- Game rules may be edited only before affected holes are completed
- Stakes may not be changed retroactively without confirmation
- Course hole data may be corrected
- Previous scores may be edited

Completed:

- Read-only by default
- Provide explicit "Reopen Round" developer/admin-style action
- Reopening recalculates ledger and settlements
- Marked-paid state must be cleared if amounts change

## 24. Share Receipt

Generate plain text in v1.

Example:

```text
SIDEpot Round Receipt

Saturday Degenerates
Toad Valley Golf Course
July 18, 2026

Final standings
1. Blaise +$22
2. John +$4
3. Mike -$10
4. Ryan -$16

Settlement
Ryan pays Blaise $16
Mike pays Blaise $6
Mike pays John $4

Biggest skin
Hole 14 — Blaise — $12

Tracked by Sidepot
```

Also render a SwiftUI share card that can be exported as an image if practical without third-party libraries.

## 25. Privacy

V1 stores all data locally.

Privacy copy:

- Sidepot does not process payments.
- Sidepot does not connect to bank accounts.
- Sidepot does not sell user data.
- Sidepot stores round and player data on the device.
- Payment handles are optional and used only to help users settle outside the app.

Do not include analytics SDKs in v1.

## 26. Testing Requirements

### Unit tests

At minimum:

#### Handicap

- Zero handicap
- Plus handicap
- More than 18 strokes
- Team handicap differences
- 9-hole allocation
- Missing stroke indexes
- Manual override

#### Skins

- Unique winner
- Tie with carry
- Tie without carry
- Multiple carryovers
- Net skins
- Incomplete scores
- Four-player payment distribution

#### Nassau

- Front winner
- Back winner
- Overall winner
- Halved segment
- Two-down auto press
- Press cap
- No holes remaining
- Manual press
- Team best ball
- Editing a prior score removes or creates press deterministically
- Press begins on next hole
- Base match closes early
- Overall continues after front closes

#### Settlement

- Simple two-player
- Four-player
- Multiple creditors
- Multiple debtors
- Already settled
- Invalid non-zero-sum
- Exact Decimal arithmetic
- Deterministic result ordering

#### Ledger

- Sum equals zero
- No self-payment
- No negative entries
- Round recalculation is idempotent

### UI tests

- Complete onboarding
- Create four players
- Create a group
- Start a round
- Configure skins and Nassau
- Enter three holes
- Add a custom bet
- Navigate backward and edit a score
- Finish round
- View settlement
- Share receipt
- Relaunch and restore active round

## 27. Seed and Preview Data

Create preview fixtures:

Players:

- Blaise — 7
- Mike — 12
- John — 18
- Ryan — 22

Group:

- Saturday Degenerates

Course:

- Toad Valley Golf Course
- 18 holes
- Standard par/stroke-index sample data

Round:

- 12 completed holes
- Active skins carry
- Front Nassau completed
- Back Nassau active
- One press
- One greenie
- One custom bet

Every major view must have:

- Populated preview
- Empty preview
- Error or incomplete preview where relevant

## 28. Implementation Order

Claude Code must implement in this order:

### Phase 1 — Foundation

1. Create project and folder structure.
2. Add design tokens and reusable components.
3. Add SwiftData models.
4. Add preview fixtures.
5. Add persistence container.
6. Add root navigation.

### Phase 2 — Domain Engine

1. Money type
2. Player balances
3. Handicap engine
4. Match-state utilities
5. Skins evaluator
6. Match-play evaluator
7. Nassau evaluator
8. Junk evaluators
9. Custom bet evaluator
10. Ledger validator
11. Settlement optimizer
12. Unit tests

Do not start the primary UI until core engine tests pass.

### Phase 3 — CRUD and Setup

1. Players
2. Groups
3. Course snapshot builder
4. Create-round flow
5. Validation
6. Draft persistence

### Phase 4 — Active Round

1. Score entry
2. Hole navigation
3. Autosave
4. Live game status
5. Press controls
6. Live ledger
7. Recovery after relaunch

### Phase 5 — Completion

1. Round validation
2. Final recalculation
3. Settlement
4. Summary
5. Share receipt
6. History
7. Standings

### Phase 6 — Polish

1. Accessibility
2. Dark mode
3. Empty states
4. Error states
5. Haptics
6. UI tests
7. Performance review
8. README

## 29. Definition of Done

The implementation is complete when:

- Project builds with no warnings
- All unit tests pass
- Core flows work in the simulator
- App works offline
- User can create players and groups
- User can create and complete a round
- Skins calculate correctly
- Nassau calculates correctly
- Manual and automatic presses work
- Scores can be edited safely
- Ledger remains zero-sum
- Settlement is generated
- Completed rounds persist
- Season standings update
- Share receipt works
- Active round restores after relaunch
- Dark mode works
- Dynamic Type works
- No third-party packages are used
- README includes setup and known limitations

## 30. Explicit Non-Goals

Do not implement:

- Real payment processing
- Gambling compliance workflows
- Public betting markets
- Public user profiles
- Online multiplayer
- 18Birdies API integration
- GPS
- Course maps
- Shot tracking
- Apple Watch
- Cloud sync
- Subscriptions
- Ads
- Push notifications
- AI features
- Android
- Tournament brackets
- Live spectators

## 31. Claude Code Execution Instructions

Follow these rules:

1. Do not ask architectural questions unless blocked by a contradiction.
2. Use the specification as the source of truth.
3. Favor simple native Swift solutions.
4. Keep domain logic independent of SwiftUI and SwiftData.
5. Use immutable value types inside the game engine.
6. Persist snapshots for historical accuracy.
7. Recalculate ledgers from source data rather than mutating balances.
8. Add tests before or alongside each game evaluator.
9. Do not leave placeholder implementations for core calculations.
10. Do not use mocked results in production paths.
11. Do not add third-party dependencies.
12. Do not add features listed as non-goals.
13. Keep files focused and reasonably small.
14. Add documentation comments to public domain interfaces.
15. Use `Decimal` for every stake, balance, ledger entry, and settlement.
16. Ensure every completed round is exactly zero-sum.
17. Make the app usable in the iOS simulator with seeded preview data.
18. Commit implementation in logical phases if operating in a Git repository.

## 32. Recommended Initial Claude Code Prompt

Use this prompt after placing this specification at the repository root as `IMPLEMENTATION_SPEC.md`:

```text
Build the Sidepot iOS application described in IMPLEMENTATION_SPEC.md.

Treat that file as the source of truth.

Start by inspecting the repository. Then implement the project in the required implementation order. Do not add features marked as deferred or non-goals.

Prioritize a compiling, tested local-first application. Keep all game calculations outside SwiftUI and SwiftData models. Use Decimal for money and require zero-sum ledgers.

Run tests after each domain-engine milestone and fix failures before proceeding.

At the end:
1. Build the app.
2. Run all tests.
3. Summarize what was implemented.
4. List any incomplete items.
5. List any decisions that materially differ from the specification.
6. Provide simulator launch instructions.
```

## 33. Suggested Future Phases

After the local MVP is stable:

### Phase 2

- CloudKit private database
- Shared rounds
- Invite links
- Sign in with Apple
- Conflict resolution

### Phase 3

- Live Activities
- Apple Watch score entry
- App Intents
- Siri shortcut
- Lock-screen balances

### Phase 4

- StoreKit subscription
- Premium season analytics
- Additional games such as Wolf, Vegas, Banker, and Hammer
- Export and backup

### Phase 5

- Official partnerships
- Course-data provider
- Scorecard import
- Approved 18Birdies integration if available

---

End of specification.
