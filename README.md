# Gabit

A calorie and energy-balance tracker for iPhone, built as one honest vertical
slice: domain, UI, tests and pipeline, end to end.

The interesting part is not the CRUD. It is arithmetic that must be correct —
basal rate, expenditure, deficit targets, projected timelines — and correctness
that must be provable is what a test-first workflow is for.

---

## Running it

**The domain, the store, lint and format need only Docker:**

```
make setup
make up
make test
```

**The app needs macOS with Xcode 16+.** SwiftUI, UIKit and the iOS SDK have no
Linux implementation, so no container builds an iOS app and this one does not
pretend to:

```
brew install xcodegen
make xcode
open Gabit.xcworkspace
```

| Command | What it does | Where |
|---|---|---|
| `make setup` | Creates `.env`, installs the pre-commit hook, builds the image | host |
| `make up` / `make down` | Starts / stops the toolchain container | host |
| `make test` | `swift test` for GabitDomain and GabitData | container |
| `make build` | Builds both platform-agnostic packages | container |
| `make lint` / `make fmt` | swift-format over every Swift file, GabitUI included | container |
| `make shell` | A shell inside the container | container |
| `make xcode` | Regenerates `Gabit.xcodeproj` from `project.yml` | host (macOS) |
| `make reset` | Drops the containers and their volumes | host |

`fastlane unit`, `fastlane ui` and `fastlane beta` are the same three things CI
runs. A pipeline you cannot reproduce on your own machine is a pipeline you
debug by pushing.

---

## Architecture

Three Swift packages and a thin app target. The dependency arrow only ever
points inward: the app knows the features, the features know the domain, the
domain knows nothing.

```
Gabit.xcworkspace
├── Gabit/                     app target: composition root only
│   ├── GabitApp.swift         builds live dependencies, injects
│   └── UITests/               the one smoke test
├── Packages/
│   ├── GabitDomain/           pure Swift · no UIKit, no SwiftUI, no SwiftData
│   │   ├── Sources/           models, energy math, projections
│   │   └── Tests/             60 tests — the bulk of the suite
│   ├── GabitData/             stores behind protocols
│   │   ├── Sources/           protocols, in-memory store, SwiftData store, mappers
│   │   └── Tests/             one contract, run against both implementations
│   └── GabitUI/               SwiftUI views, view models, design tokens
│       ├── Sources/           Today, QuickAdd, Onboarding, Progress
│       │   └── Interop/       KeypadInputView (UIViewRepresentable)
│       └── Tests/             view-model tests + snapshots
├── fastlane/                  Fastfile, Appfile, Matchfile
└── .github/workflows/ci.yml
```

**The boundary is compiler-enforced, not a folder convention.** `GabitDomain`
is built on Linux in CI, where SwiftUI does not exist. An `import SwiftUI` that
sneaks into the domain fails the build rather than waiting for a reviewer to
notice it.

**View models own state and depend on protocols** — `DayLogStoring`,
`GabitClock` — passed through their initialiser. There is no singleton, no
service locator, and `Date()` is called in exactly one place: the composition
root. That is what makes "the day rolls over at midnight" a testable behaviour
rather than a hope.

**Views stay dumb.** No arithmetic, no formatting decisions, no conditionals
beyond rendering the state the view model already resolved — the resolved
state holds strings, not numbers. The over-budget screen is not a sixth view;
it is Today with one boolean set.

---

## The two decisions worth arguing about

**A deficit is a rate, not a number.** The user picks 0.5 kg per week and the
app derives ≈550 kcal/day from 7,700 kcal per kg of fat. The target recomputes
as weight changes instead of silently going stale. `WeightRate` carries the
rate; nothing stores a hand-typed calorie goal.

**Burn credits the budget; it never reduces intake.** `DayLog` keeps two
ledgers and `EnergyBalance` never nets one against the other. Conflating them
is the bug most of these apps ship: it corrupts the intake total that macro
targets are measured against. `test_balance_creditsBurnWithoutAlteringIntakeTotal`
is the test that pins it.

Guardrails live in the domain, not the view. A target is clamped so it can
never fall below basal rate, and an aggressive rate surfaces as a domain-level
warning the UI merely renders.

---

## Tests

142 across four targets. The gate is not coverage — it is that every domain
rule maps to a named test, which a reviewer can audit by reading test names
alone.

| Level | Count | Runs on |
|---|---|---|
| Domain units | 60 | Linux, milliseconds, no host app |
| Store contract | 23 | Linux for the fake, simulator for SwiftData |
| View models | 58 | Simulator |
| Snapshots | 6 baselines | Simulator — **not recorded yet, see below** |
| Smoke UI | 1 | Simulator |

Two things worth knowing about how they are written:

**Time is always injected.** Every fixture date is explicit and every calendar
is pinned, so a run in São Paulo and a run on a UTC CI runner assert the same
thing. `test_dayLog_rollsOverAtLocalMidnight_notUTC` is the one that would have
caught the classic version of this bug.

**The fake is held to the real store's contract.** `StoreContractTests` is a
base class; `SwiftDataStoreTests` inherits it and swaps the implementation. A
fake that quietly drifts from the thing it stands in for is worse than no fake,
and inheritance is what stops it.

Three domain tests assert against the worked examples printed on the design
screens — 2,565 maintenance, a 2,180 target, 795 remaining, 310 over. The
design's arithmetic and the domain's agree.

---

## Pipeline

Four stages, fast feedback first, per the plan.

| Stage | Runs | Where |
|---|---|---|
| Lint & format | swift-format `--strict` | Linux container |
| Fast tests | domain + data, no simulator | Linux container |
| Simulator tests | view models, snapshots, smoke test | macOS runner |
| Beta | archive, build number from the run number, TestFlight | macOS runner |

The two cheap stages run on Linux in the same image developers use, which is
what keeps them cheap — no simulator, no Xcode, no queue for a macOS runner.
Only the stages that genuinely need the Apple SDKs pay for one.

Signing goes through `match` so the pipeline is reproducible on a clean runner.
Release notes are generated from commit subjects. Without an App Store account
the beta lane still archives and uploads the `.ipa` as an artifact — the point
is that shipping is automated, not that a store listing exists.

---

## Adding a feature, test-first

The habit this repository is meant to demonstrate. Say you are adding a fibre
target.

1. **Write the failing domain test first**, named after the rule:
   `test_fibreTarget_scalesWithEnergyTarget()` in `Packages/GabitDomain/Tests`.
   Run `make test`. Watch it fail for the right reason — a missing symbol is a
   compile error, not a red test; get to a red test before writing anything.
2. **Add the smallest thing in `GabitDomain`** that makes it green. Pure
   function, pure value types, no imports beyond Foundation.
3. **Extend the store contract** in `StoreContractTests` if it needs
   persisting. Both implementations inherit the new case, so the SwiftData
   store fails until its mapper learns the field.
4. **Resolve it in the view model** — a string, not a number — and assert that
   string against the in-memory store and a fixed clock.
5. **Render it.** If you find yourself writing `if` or arithmetic in the view,
   the value belongs in the view model.
6. **Re-record the snapshots** if the layout moved. Delete the affected file
   under `Packages/GabitUI/Tests/GabitUITests/__Snapshots__/`, run
   `GabitPackageTests` once — the run records it and fails, by design — then
   look at the new PNG before committing it. `recording` in `SnapshotTests`
   forces every baseline to re-record at once.

Small commits, trunk-based on `main`, every push green or reverted.

---

## Decisions

**Swift 6.3.3 pinned** in `.swift-version` and `SWIFT_VERSION`. Swift 6
language mode and `SWIFT_STRICT_CONCURRENCY=complete` are on from the first
commit; turning them on later, over a finished app, is the expensive order.

**swift-format is the linter, SwiftLint is opt-in.** swift-format ships with
the toolchain: no install, always the pinned Swift. SwiftLint publishes no
Linux binary, so enabling it means compiling it during the image build —
minutes on the first `make setup`. It sits behind `WITH_SWIFTLINT=1` in `.env`
with `.swiftlint.yml` ready. This replaces the plan's SwiftFormat + SwiftLint
pairing, for the same reason.

**`swift format` lints GabitUI even though the container cannot build it.**
It works on syntax, not on compilation, so the SwiftUI layer is still checked.

**Two names differ from the plan and the design**, both to avoid ambiguity
against the standard library, which a file importing both could not resolve:
the clock protocol is `GabitClock`, and the Progress screen is
`ProgressScreen`. Noted at both declarations.

**Records are separate types from domain values.** A `@Model` class is a
reference type with change tracking attached; letting one reach the domain
would put SwiftData behind every pure function. Enums persist as raw strings
and the goal as a kind plus a rate, so the store stays inspectable and
migratable. Unknown raw values fall back rather than refusing to launch — a
tracker that will not open is worse than one showing a stale activity level.

**No migration plan yet.** There is one schema version, and a
`SchemaMigrationPlan` over a single version tests nothing. `GabitSchema` is
where V2 goes, and the round-trip tests become the fixture it is checked
against.

**`.build` is a named volume, not the host directory.** Xcode writes Mach-O
objects there and the container writes ELF; sharing it makes the two toolchains
fight, and the failure looks like a corrupt module cache.

**The `.xcodeproj` is generated and not committed**, from `project.yml`.
`Gabit.xcworkspace` is committed — it ties the generated project to the three
local packages and does not churn.

**No `prod` runtime image.** The production artifact of an iOS app is a signed
`.ipa` from Xcode. The Dockerfile's `release` stage exists for Linux CI and for
reusing `GabitDomain` server-side, not for shipping the app.

**The snapshot baselines are not in the repository yet.** They can only be
produced by running the tests on a Mac, and the first run is meant to fail:
swift-snapshot-testing records a missing baseline and then tells you it did.
To seed them, once:

```
make xcode
open Gabit.xcworkspace     # run the GabitPackageTests target — 3 tests fail, 6 PNGs appear
git add Packages/GabitUI/Tests/GabitUITests/__Snapshots__
```

Look at the six images before committing them. A baseline nobody has ever
looked at asserts that the screen still renders the way it rendered — which is
worth something, but not what these tests are for.

**Light only.** The foundations sheet specifies `iPhone · light only · v0.1`,
which narrows the plan's "light and dark" snapshots to one scheme for this
version. Dark comes back with a dark palette, and doubles `SnapshotTests`.

---

## Design system

Taken from the foundations sheet and encoded in `Packages/GabitUI/Sources/GabitUI/DesignSystem`.

The sheet specifies colour in OKLCH, which SwiftUI cannot express, so each
value is converted to sRGB once and recorded with the OKLCH it came from. The
three semantic colours sit deliberately at one lightness and one chroma so they
carry identical weight on screen — a property that is invisible once you only
have hex, which is why the source values stay in the comments.

Red is reserved. It appears only when the day's budget is genuinely exceeded —
never for a validation message, never for an aggressive-rate warning.

Type is bound to Dynamic Type text styles rather than fixed point sizes. The
sheet's numbers are the sizes at the default setting; `relativeTo:` is the
difference between a design that survives the largest accessibility size and
one that clips.

---

## What is not here

Cut deliberately, each with the reason: barcode scanning, a nutrition database
or any network layer, HealthKit, iPad and Watch, accounts and sync, widgets,
notifications, body-fat estimation. Being able to defend a cut line is part of
the exercise; the plan's §9 orders them by what each would demonstrate.
