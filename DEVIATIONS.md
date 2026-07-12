# Deviations from IMPLEMENTATION_SPEC.md

This file tracks every place the implementation materially differs from, or fills a gap in,
`IMPLEMENTATION_SPEC.md`. Per execution rule #1 ("do not ask architectural questions unless
blocked by a contradiction"), these were resolved unilaterally where the spec was silent or
self-contradictory, favoring the simplest change consistent with the rest of the document.

## Environment constraint (not a spec deviation, but material)

This implementation was authored in a Linux container with no Swift toolchain reachable
(`download.swift.org` is blocked by the sandbox's network policy, and no Docker daemon is
available to run an official `swift` image). **No file in this repository has been compiled,
type-checked, or run.** Everything under `SidepotCore/` and `Sidepot/` needs to be opened in
Xcode on macOS (or run through `swift build` / `swift test` for the `SidepotCore` package alone)
before it can be trusted. Treat this as an unverified first draft of the domain layer, not a
tested one, despite the extensive test suite written alongside it — the tests have never
actually been executed.

## Project generation

The spec assumes a hand-created Xcode project. A `.pbxproj` is a fragile, mostly-binary-shaped
plist format that is extremely easy to corrupt when hand-authored without Xcode available to
validate it, and there was no way to verify one in this environment. Instead, the app target is
described declaratively in `project.yml` for [XcodeGen](https://github.com/yonaskolb/XcodeGen),
which deterministically produces a correct `Sidepot.xcodeproj`. XcodeGen is a project-generation
dev tool, not a runtime dependency shipped in the app, so this does not conflict with "no
third-party dependencies in v1." Run `xcodegen generate` once (`brew install xcodegen` if needed)
before opening the project. `Sidepot.xcodeproj` is gitignored since it's a generated artifact.

## GolfGameEvaluating protocol: added `gameID` parameter

The spec's `GameEvaluationResult` requires a `gameID: UUID`, but the protocol's `evaluate(context:
configuration:)` signature has no way to supply one. This is a direct contradiction. Resolved by
adding a `gameID: UUID` parameter to `evaluate`, supplied by the caller (the service layer, from
`GameConfiguration.id`):

```swift
func evaluate(gameID: UUID, context: RoundEvaluationContext, configuration: Configuration) throws -> GameEvaluationResult
```

## Evaluators need to know their own participants; context alone can't tell them

`RoundEvaluationContext` carries every player in the round, not the subset participating in a
given game (Nassau is explicitly two-sided; a custom bet may involve only some players). The spec
never threads a participant list into evaluators. Resolved by adding explicit participant/side
fields to each game's `Configuration` struct where needed:

- `NassauConfiguration` gained `sideAPlayerIDs: [UUID]`, `sideBPlayerIDs: [UUID]`, and
  `scoringMode: ScoringMode` (gross/net — needed to know how to compare scores; the spec's field
  list for `NassauConfiguration` omits it even though §12 discusses net best-ball).
- `MatchPlayConfiguration` gained `sideAPlayerIDs`/`sideBPlayerIDs` and `format` for the same
  reason.
- `StrokePlayConfiguration`, `BirdiesConfiguration` gained `participantIDs: [UUID]`.
- `GreeniesConfiguration`/`SandiesConfiguration` derive winners from manual per-hole entries that
  already name a player, so no separate participant list was needed there.

## Nassau manual presses must be recorded somewhere the evaluator can see

Evaluators must be pure functions of `(context, configuration)` — "recalculate from source data,"
"deterministic and idempotent" (execution rules #6–7). Automatic two-down presses satisfy this
because they're derivable purely from scores. Manual presses are a user *action* ("the organizer
taps Press"), and the spec never says where that action is persisted. If it isn't persisted
somewhere the evaluator reads, a manual press can't survive a recalculation — which contradicts
"presses are independent matches" persisting through the rest of the round. Resolved by adding
`manualPresses: [ManualPressRecord]` to `NassauConfiguration`; the app layer appends a record when
the user taps "Press," and the evaluator regenerates the full `NassauPress` (with computed
`startsOnHole`/`endsOnHole`/`stakeAmount`) from that record on every recalculation, exactly as it
does for automatic presses. This is also what makes "editing a prior score removes or creates a
press deterministically" (§26) possible: the auto-press *record* only exists if the score data
still produces that 2-down trigger when replayed.

## Nassau side identifiers

`NassauPress.initiatingSideID: UUID` per spec, but a "side" (A or B) isn't itself a modeled
entity with its own UUID anywhere else in the spec. Resolved by using the first player ID in
`sideAPlayerIDs`/`sideBPlayerIDs` as that side's canonical identifier — stable and deterministic
without inventing a new persisted model.

## Exact-cent splitting for divisions that don't come out even

Decimal division (e.g. a $10 pot split three ways, or a 3-winner custom bet) does not always
produce shares that re-sum to the original exactly once each share is rounded to the currency's
minor unit — a real risk given §8's hard requirement that a completed round sum to exactly zero.
Added `MoneySplit.evenSplit(_:into:scale:)` (`SidepotCore/Sources/SidepotCore/Utilities/`), which
computes even shares to the target scale and deterministically allocates any leftover minor units
(pennies) to the first entries in the input order, guaranteeing the shares sum to the original
total exactly. Every evaluator that splits an amount across more than one party uses this instead
of raw `Decimal` division.

## Settlement optimizer tie-break

The spec's greedy debtor/creditor matching algorithm doesn't specify a tie-break when two
balances are equal. `SettlementOptimizer` breaks ties by `UUID` string ordering, which is
arbitrary but stable and keeps the function deterministic for identical input, as required by
§17 ("Deterministic ordering"). A caller that wants ties broken by, say, player name can pre-sort
before calling — the function only has UUIDs to work with.

## Stroke play payout when `winnerTakeAll` is false

§14 lists `winnerTakeAll` as "optional" but never describes an alternative payout mechanic beyond
"lowest total wins... every loser pays the winner." No second mechanic is specified anywhere in
the document, so `StrokePlayEvaluator` implements only the one payout rule the spec actually
describes (each non-winner pays `stakeAmount`, split evenly across co-winners on a tie if
`tieHandling == .splitPot`); `winnerTakeAll` is accepted on the configuration for forward
compatibility but does not currently change behavior, since no alternative was specified to
switch to.

## Skins "pot-per-hole" stake mode

§11 names `potPerHole` as a stake mode alongside `fixedValuePerSkin` but doesn't define its
payout math. Implemented as: each participant's ante for the hole is `baseAmount /
participantCount`; on a win, every other participant's ante for that hole (scaled by the current
carry) is transferred to the winner via `MoneySplit`, so the winner nets `(N-1)/N × baseAmount ×
carry` and each loser nets `-baseAmount/N × carry` — a standard shared-pot mechanic that keeps the
hole zero-sum without needing a phantom "house" entry.

## Junk game payouts (greenies / sandies)

§15 only states the payout rule explicitly for birdies ("each opponent pays configured amount to
the player"). Greenies and sandies are implemented with the same rule for consistency: every other
active participant pays the configured `amount` directly to the winning player (not split), since
no alternative was described and this matches the one concrete example given in the document.

## Round-level vs. per-game stroke allocation

§9 says "determine the lowest playing handicap in the match" without defining "the match" — the
whole round's field, or just the two sides of a given game (e.g. a Nassau 1v1 within a 4-person
round). `HandicapEngine.strokesReceived` is written to take whatever set of playing handicaps the
caller passes in and computes strokes relative to the lowest handicap *in that set*, so callers
decide per game: pass the full round field for round-level net scoring displays, or just a Nassau
match's two sides for that match's strokes. This keeps the engine reusable rather than forcing a
single global interpretation.
