# Sidepot

Keep score in 18Birdies. Track the money in Sidepot.

A native iOS companion app for golf groups who play for small stakes — Nassau, skins, presses,
junk, and custom bets — and want automatic settlement instead of a napkin. Sidepot never
processes payments, holds money, or connects to a bank account; it only tracks who owes whom.

Full product/engineering spec: [`IMPLEMENTATION_SPEC.md`](./IMPLEMENTATION_SPEC.md). Every place
this implementation fills a gap or deviates from that spec is logged in
[`DEVIATIONS.md`](./DEVIATIONS.md) — read it before assuming a behavior is a bug rather than a
documented decision.

## Status

**This build has never been compiled.** It was authored in a Linux environment with no Swift
toolchain reachable (see `DEVIATIONS.md`'s "Environment constraint" section) — everything here is
an unverified first draft. Treat the extensive test suite as *written*, not *passing*, until
someone runs it on macOS.

What's implemented:

- **`SidepotCore`** (local Swift package) — the full domain layer, per spec Phases 1–2:
  - SwiftData models: `Player`, `GolfGroup`, `CourseSnapshot`, `HoleSnapshot`, `GolfRound`,
    `RoundPlayer`, `HoleScore`, `GameConfiguration`, `LedgerEntry`, `SettlementPayment`.
  - `Money` (exact `Decimal` arithmetic) and `MoneySplit` (exact multi-way splitting).
  - `HandicapEngine` — course/playing handicap and stroke allocation.
  - Game evaluators: Skins, Nassau (with manual + automatic two-down presses), Match Play, Stroke
    Play, Greenies, Sandies, Birdies, Custom Bets — all pure, `SwiftUI`/`SwiftData`-independent,
    conforming to `GolfGameEvaluating`.
  - `LedgerValidator` and `SettlementOptimizer` (greedy debtor/creditor settlement).
  - The full `DesignSystem` component set from spec §19.
  - An extensive Swift Testing suite in `SidepotCore/Tests/SidepotCoreTests` covering every
    scenario listed in spec §26 for handicap, skins, Nassau, match play, stroke play, junk,
    custom bets, ledger, and settlement.
- **`Sidepot`** (the app target) — root navigation (`RootView`, four tabs), onboarding, and a
  scaffold for every other screen in the nav map. Several screens (`HomeView`, `GroupsView`,
  `PlayersView`) are functionally real against the SwiftData store; others (`NewRoundView`,
  `DefaultRulesView`, `StandingsView`) are intentionally light placeholders — see "Known
  Limitations" below.

## Known Limitations

Per the scope agreed for this build, Phases 3–6 of the implementation order were **not** fully
built out. Specifically still TODO:

- The five-step create-round flow (Basics → Players → Course → Games → Review).
- Full active-round UX: press controls, live per-game status cards wired to `GameStatusCard`,
  the live ledger panel, jump-to-hole, autosave-on-every-change, and restoring an in-progress
  round after relaunch.
- Round completion flow: final validation, "Reopen Round," the plain-text and SwiftUI share
  receipt, and marking settlement payments paid.
- Season standings computation (rounds played, win rate, streaks, etc.) — `StandingsView` is
  currently just an empty state.
- History filters (group/player/course/date range).
- Default rules per group (`DefaultRulesView`) — the group model supports it
  (`GolfGroup.defaultGameConfigurations`), but there's no UI yet.
- Most of the UI test checklist in spec §26 — only the onboarding smoke test exists.
- Accessibility, dark mode, and empty/error-state *polish* passes (the design system itself is
  dark-mode-aware and accessible by construction — Dynamic Type, 44×44 targets, monospaced
  digits, no color-only balance signaling — but a dedicated review pass hasn't happened).

None of this affects the domain engine, which is complete per spec.

## Repository Layout

```text
IMPLEMENTATION_SPEC.md   Source-of-truth product/engineering spec
DEVIATIONS.md            Every place this implementation fills a gap or differs from the spec
project.yml              XcodeGen project definition (see "Setup" below)
SidepotCore/             Local Swift package: models, game engine, settlement, design system
  Sources/SidepotCore/
  Tests/SidepotCoreTests/
Sidepot/                 App target sources (SwiftUI + SwiftData)
  App/                   SidepotApp, AppState, AppEnvironment, RootView
  Features/              One folder per screen area, matching the spec's nav map
  Services/              GameEvaluationService, SettlementService (DI via protocols)
  PreviewContent/         Seed/preview fixtures (§27)
  Resources/              Info.plist, Assets.xcassets
SidepotTests/             App-level XCTest (SwiftData/service integration smoke tests)
SidepotUITests/           XCUITest target (onboarding smoke test; rest TODO)
```

## Setup

This project's `.xcodeproj` is generated, not committed (see `DEVIATIONS.md` for why) — a
hand-authored `.pbxproj` couldn't be validated in the environment this was written in.

1. Install [XcodeGen](https://github.com/yonaskolb/XcodeGen): `brew install xcodegen`.
2. From the repo root: `xcodegen generate`.
3. Open `Sidepot.xcodeproj` in Xcode 16+ on macOS, targeting iOS 18.
4. Build and run the `Sidepot` scheme in the simulator. `SidepotApp` boots with an empty store —
   use the onboarding flow to create your first player, or point a `#Preview` at
   `PersistenceController.makePreviewContainer(populate: PreviewFixtures.populate)` to explore the
   UI with the seeded "Saturday Degenerates" fixture data from spec §27.

### Running just the domain engine

`SidepotCore` is a standalone Swift package with no UIKit/AppKit dependency in its game-engine
code (SwiftData and SwiftUI are still used for models/design-system, so it's `.iOS(.v18)`-only —
it won't build with `swift build` on Linux). On macOS:

```sh
cd SidepotCore
swift test
```

This is the fastest way to iterate on game-engine changes without opening Xcode.

## Bundle Identifier

The placeholder bundle ID is `com.example.sidepot` (`project.yml`, `options.bundleIdPrefix` +
target `PRODUCT_BUNDLE_IDENTIFIER`). Change both before shipping to a device or TestFlight.

## Non-Goals

Sidepot deliberately does not do any of the following (spec §30): real payment processing, cloud
sync, subscriptions, ads, push notifications, GPS/course maps/shot tracking, Apple Watch,
Android, or 18Birdies API integration. All monetary values are tracking-only.
