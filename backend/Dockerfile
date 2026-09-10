# syntax=docker/dockerfile:1

# Single-stage on purpose: this is an npm-workspaces monorepo (the backend
# depends on the sibling @mauit/shared package), and a multi-stage image
# that COPYs a pruned node_modules across stages is easy to get subtly
# wrong (Prisma's generated client in particular lives inside
# node_modules and has to survive the copy). Simpler and safer to just
# keep devDependencies in the final image — optimize later once this is
# actually running.
#
# Also deliberately skips the usual "copy manifests, install, then copy
# source" layer-caching trick: @mauit/backend's `postinstall` runs
# `prisma generate`, which needs prisma/schema.prisma to already be on
# disk — copying source before `npm install` is what makes that work.
#
# IMPORTANT: build context is the REPO ROOT, not backend/ — npm workspaces
# need the root package.json and packages/shared's source too. See
# docker-compose.yml's `context: .. / dockerfile: backend/Dockerfile`.
FROM node:20-slim

WORKDIR /repo

COPY package.json package-lock.json* ./
COPY packages/shared packages/shared
COPY backend backend

# `prisma generate` (run via postinstall, below) only reads the schema to
# emit the typed client — it doesn't connect to a database — but the
# schema still references env("DATABASE_URL"), so give it a placeholder
# rather than fail the build over an unset variable. The real one comes
# from docker-compose.yml at container run time.
ENV DATABASE_URL="postgresql://user:password@localhost:5432/db"
RUN npm install

RUN npm run build --workspace=@mauit/shared
RUN npm run build --workspace=@mauit/backend

WORKDIR /repo/backend
EXPOSE 8080

CMD ["node", "dist/index.js"]
