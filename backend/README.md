# MauIt API

The server side: Express + Prisma + PostgreSQL, TypeScript throughout. It
depends on the sibling `@mauit/shared` package (see `../packages/shared`),
so the calorie-target formula (`dailyTarget`) and the macro-target split
live in exactly one place — the mobile app and the API can't quietly drift
apart on the math.

## Run it

```
# from the repo root, once:
npm install
npm run build:shared

cd backend
cp .env.example .env   # optional outside Docker — compose sets these itself
docker compose up --build
```

That builds the image (build context is the **repo root**, not `backend/`
— see `Dockerfile` — because of the `@mauit/shared` workspace dependency),
starts Postgres, pushes the Prisma schema (`prisma db push`, not
`migrate deploy` — see "What this doesn't do yet"), and starts the API at
`http://localhost:8080`.

```
curl http://localhost:8080/health
# => 200, empty body
```

Without Docker: run a Postgres yourself, point `DATABASE_URL` at it, then
from the repo root:

```
npm run build:shared
npm run prisma:migrate --workspace=@mauit/backend   # or: npx prisma db push --workspace=@mauit/backend
npm run dev:backend
```

## Auth

JWT bearer tokens (`jsonwebtoken`), not a database-backed token table —
the more idiomatic choice for a Node API, and it means no `UserToken`
model. Sign up, then send the returned token as `Authorization: Bearer
<token>` on everything else.

```
curl -X POST http://localhost:8080/api/auth/signup \
  -H 'Content-Type: application/json' \
  -d '{"email":"you@example.com","password":"correct horse battery staple"}'
# => { "token": "...", "user": { "id": "...", "email": "..." } }

curl -X POST http://localhost:8080/api/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"email":"you@example.com","password":"correct horse battery staple"}'
# => same shape, a fresh token
```

## Endpoints

All of these except `/auth/*` require `Authorization: Bearer <token>`.

| Method | Path | Screen | What |
|---|---|---|---|
| POST | `/api/auth/signup` | — | Create an account |
| POST | `/api/auth/login` | — | Email + password in, get a token |
| GET | `/api/goal` | 01 Onboarding | Current goal + derived daily target |
| PUT | `/api/goal` | 01 Onboarding | Set direction / rate / maintenance |
| GET | `/api/days/:date` | 02/05 Today | Aggregated day — target, eaten, burn, macros, entries (`yyyy-MM-dd`) |
| GET | `/api/entries?date=` | 03 Quick add | Entries, optionally filtered to one day |
| POST | `/api/entries` | 03 Quick add | Log a meal or a manual burn |
| GET | `/api/entries/recent` | 03 Quick add | Recent meals, for the "tap to log as is" chips |
| DELETE | `/api/entries/:id` | — | Remove an entry |
| GET | `/api/weight-check-ins?weeks=` | 04 Progress | Weight readings |
| POST | `/api/weight-check-ins` | 04 Progress | Log a check-in |
| GET | `/api/progress/summary?weeks=` | 04 Progress | Trend + adherence stats |

`GET /api/days/:date` backs both Today states (02 on-track, 05
over-budget) — same aggregation either way; `isOverBudget` in the response
is what the client branches on, exactly like `DayLog` does on-device (see
`packages/shared/src/types.ts`).

## What this deliberately doesn't do yet

- **No real database migrations.** `prisma db push` syncs the schema
  straight to Postgres with no migration history, because generating a
  proper migration (`prisma migrate dev`) needs a live database to run
  against, which nothing in this environment had. Once you have Postgres
  up locally: `npx prisma migrate dev --name init --workspace=@mauit/backend`
  (or without the `--workspace` flag, from inside `backend/`) to generate
  a real initial migration, then switch `docker-compose.yml`'s command
  back to `prisma migrate deploy`.
- **No token expiry handling beyond the JWT's own `exp` claim** (30 days,
  hardcoded in `src/lib/jwt.ts`) — no refresh tokens, no revocation list.
  A leaked token is valid until it expires.
- **No projection sentence.** The design's "reach 75 kg around 14
  November" needs a target weight, which nothing here collects. Rather
  than fake a number, `/progress/summary` omits it — `currentWeightKg`,
  `deltaLabel`, `percentWithinTarget` and `averageDailyBalance` are all
  real aggregates, or `null` when there isn't enough data yet.
- **No over-budget insight text.** Same reasoning — "your 7-day average is
  still −390 kcal" needs a real rolling average, which `days.ts` doesn't
  compute yet (`insightNote` comes back `undefined`).
- **No rate limiting, no email verification, no password reset.**
- **The mobile app isn't wired to this yet.** It still runs entirely on
  `@mauit/shared`'s `mockData`. Swapping it over means adding a fetch
  layer in `mobile/` that calls these endpoints and replaces the mock-data
  imports in the four screens.
- **The Dockerfile is single-stage** (keeps `devDependencies`, including
  the whole TypeScript toolchain, in the final image) rather than a
  multi-stage build with a pruned `node_modules` — see the comment at the
  top of `Dockerfile` for why. Fine for a scaffold; worth revisiting
  before this is actually deployed anywhere.

## Structure

```
prisma/schema.prisma   User, Goal, Entry, WeightCheckIn — Entry/WeightCheckIn
                        are named to not collide with @mauit/shared's
                        FoodEntry/WeightReading types when both are in
                        scope in the same file.
src/
  index.ts              Boots the HTTP server.
  app.ts                Builds the Express app: middleware, route mounting.
  env.ts                Reads and validates process.env once, at startup.
  db.ts                 The one PrismaClient instance for the process.
  lib/
    jwt.ts               Sign/verify bearer tokens.
    password.ts          bcrypt hash/verify.
    dateOnly.ts           The one place "which day is this" is decided.
    asyncHandler.ts       Wraps async route handlers so a thrown/rejected
                          error reaches errorHandler instead of hanging.
  middleware/
    auth.ts               Verifies the bearer token, sets req.userId.
    errorHandler.ts        Converts HttpError / ZodError / anything else
                          into a JSON error response.
  routes/                One file per resource, mirrors the table above.
  types/express.d.ts      Augments Express's Request with `userId`.
```
