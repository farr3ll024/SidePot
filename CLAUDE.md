# CLAUDE.md

Guidance for Claude Code when working in this repository.

## Umbrella context

Sidepot is one product under the **Reints Labs LLC** portfolio. The
private ops dashboard correlating all Reints Labs repos, deploys, and
domains lives in the sibling `reints-labs-control-center` repo.

## What this is

Sidepot is a native iOS (SwiftUI + SwiftData, iOS 18+) companion app for
golf groups betting small stakes (Nassau, skins, presses, junk, custom
bets). It tracks who owes whom — **it never processes payments, holds
money, or connects to a bank account.**

Read before assuming anything is a bug rather than a decision:
- [`IMPLEMENTATION_SPEC.md`](./IMPLEMENTATION_SPEC.md) — source-of-truth product/engineering spec.
- [`DEVIATIONS.md`](./DEVIATIONS.md) — every place the implementation fills a gap or differs from the spec.

## Environment constraint — read before editing

This repo was authored in a **Linux environment with no local Swift/Xcode
toolchain**. `SidepotCore` (the domain package) has no UIKit/SwiftUI
dependency in its game-engine code, but the package still declares
`.iOS(.v18)` because SwiftData is used for models, so **`swift build`/`swift
test` do not run on Linux at all** — only on macOS, or via the CI workflow
below. Do not assume you can locally verify Swift changes in this session;
say so rather than claiming a change is tested.

CI (`.github/workflows/ci.yml`) on GitHub's macOS runners is what actually
compiles and runs this project: `swift test` for `SidepotCore`, and
`xcodebuild` for the `Sidepot` app target + `SidepotTests`/`SidepotUITests`.
Treat any change made without a subsequent green CI run as unverified.

## Setup (on macOS)

```bash
brew install xcodegen
xcodegen generate            # generates Sidepot.xcodeproj — not committed
# open Sidepot.xcodeproj in Xcode 16+, run the Sidepot scheme

cd SidepotCore && swift test # fastest way to iterate on the game engine alone
```

## Repository layout

```
IMPLEMENTATION_SPEC.md   Source-of-truth spec
DEVIATIONS.md            Gaps/deviations from the spec
project.yml              XcodeGen project definition
SidepotCore/             Domain package: models, game engine, settlement, design system
Sidepot/                 App target (SwiftUI + SwiftData)
SidepotTests/            App-level XCTest
SidepotUITests/          XCUITest (mostly TODO — see README "Known Limitations")
```

## Architecture notes

- `Money`/`MoneySplit` use exact `Decimal` arithmetic — never `Double` — for
  any money-tracking code.
- Game evaluators (Skins, Nassau, Match Play, Stroke Play, Greenies,
  Sandies, Birdies, Custom Bets) are pure and conform to
  `GolfGameEvaluating`, independent of SwiftUI/SwiftData. Keep new
  evaluators pure the same way so they stay testable via `swift test`
  without the simulator.
- `LedgerValidator` and `SettlementOptimizer` (greedy debtor/creditor
  settlement) are the only places balances get reconciled — don't
  reimplement settlement math elsewhere.

## Known incomplete areas (see README for the full list)

Phases 3–6 of the spec's build order are intentionally not fully built:
the 5-step create-round flow, full active-round UX (press controls, live
ledger panel, autosave/resume), round completion/share receipt, season
standings, history filters, per-group default rules UI, and most UI tests.
The domain engine itself is complete per spec — don't treat these gaps as
engine bugs.

## Non-goals

No real payment processing, cloud sync, subscriptions, ads, push
notifications, GPS/course maps/shot tracking, Apple Watch, Android, or
18Birdies API integration.
