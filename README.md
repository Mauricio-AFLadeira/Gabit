# MauIt

A calorie-and-weight tracking app: onboarding goal, a daily Today screen
(on-track and over-budget states), quick-add with a numeric keypad, and
weight progress with a trend line and adherence stats.

Originally built in Swift (SwiftUI + Vapor); this is a full port to
**React Native + TypeScript** on the client and **Node + Express +
TypeScript** on the server, sharing one domain package between them. It
implements the five screens from the `Gabit - Screens & Foundations`
design handoff (Claude Design) — onboarding, Today, quick-add, progress,
and the over-budget state of Today.

## Structure

This is an npm-workspaces monorepo:

```
packages/shared/   @mauit/shared — domain types (DayLog, GoalDirection,
                   MealType, FoodEntry, WeightReading...), the calorie-
                   target formula (EnergyMath's dailyTarget), macro-target
                   split, signed-number formatting, and mock data. Pure
                   TypeScript, no React/Express — both mobile/ and
                   backend/ depend on it, so the math lives in exactly one
                   place instead of being reimplemented twice.
mobile/            @mauit/mobile — the React Native app (Expo), TypeScript.
                   Five screens, a small design system (OKLCH-accurate
                   colors, typography, metrics) ported from the Swift
                   version's DesignSystem/.
backend/           @mauit/backend — the API (Express + Prisma +
                   PostgreSQL), TypeScript. JWT auth, one endpoint per
                   screen's data. See backend/README.md.
```

## Why this shape

The Swift version split into `MauItKit` (a platform-agnostic Swift package
with the domain models and math) and an `App/` SwiftUI layer, specifically
so the calorie-target formula lived in one place and both the client and a
future server could share it. `packages/shared` is the direct continuation
of that idea — and TypeScript makes it more literal here than Swift ever
could: `mobile/` and `backend/` import the *exact same* `dailyTarget()`
and `defaultMacroTargets()` functions, not two independent
reimplementations that happen to agree today.

## Setup

```
npm install
npm run build:shared
```

Every workspace depends on `@mauit/shared`'s **compiled** output
(`dist/`), not its TypeScript source directly — simpler and more robust
than teaching Metro or `tsx` to resolve a sibling package's `.ts` files,
at the cost of needing a rebuild step. Re-run `npm run build:shared`
(or `npm run dev --workspace=@mauit/shared` to watch) after changing
anything under `packages/shared/src`.

## Run the mobile app

```
npm run dev:mobile
```

Opens the Expo dev server — scan the QR code with Expo Go, or press `i`
for the iOS simulator / `a` for an Android emulator. The app runs entirely
on `@mauit/shared`'s mock data right now; it isn't wired to the API yet
(see "What's not done" below).

## Run the API

```
npm run build:shared   # if you haven't already
cd backend
docker compose up --build
```

Full details, endpoints, and `curl` examples in `backend/README.md`.

## What's not done

- **The mobile app doesn't call the API.** Both halves exist and share
  `@mauit/shared`'s types, but nothing in `mobile/src/screens` fetches
  from `backend/` yet — every screen still reads directly from
  `mockData`. Wiring that up means adding a small fetch/auth-token layer
  in `mobile/` and swapping each screen's `mockData.*` reference for a
  network call.
- **No tests.** Neither workspace has a test runner configured.
- **No ESLint.** `.editorconfig` covers formatting whitespace; nothing
  enforces TypeScript lint rules yet.
- Backend-specific gaps (migrations, token expiry, the over-budget
  insight text, the progress-screen projection sentence) are called out
  in `backend/README.md`.

## A note on how this was built

None of this has been run. This environment has no Node/npm, no Docker
daemon, and no way to launch a simulator — every file here was hand-
written and reviewed (import-by-import, brace-by-brace) rather than
compiled or tested. Treat `npm install` as the real first test; if
something doesn't resolve, it's almost certainly a small, fixable
mismatch (a package version, an import) rather than a structural problem
with the approach.
