# syntax=docker/dockerfile:1

# Swift toolchain for the parts of Gabit that are platform-agnostic.
#
# SwiftUI, UIKit and the iOS SDK are closed-source Apple frameworks and do not
# exist for Linux, so this image deliberately does NOT try to build the app.
# It builds and tests `Sources/GabitKit` (pure Swift + Foundation) and formats
# and lints every .swift file in the repository, App/ included — swift-format
# works on syntax, so it does not need the Apple SDKs to check the SwiftUI layer.
# The app itself is built with Xcode on macOS; see README.md.

ARG SWIFT_VERSION=6.3.3

# ---------------------------------------------------------------- base ------
FROM swift:${SWIFT_VERSION}-noble AS base

ARG HOST_UID=1000
ARG HOST_GID=1000
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        git \
    && rm -rf /var/lib/apt/lists/*

# ubuntu:24.04 already ships a user at uid 1000; drop it so the container user
# can own the bind-mounted workspace and stop writing root-owned files onto the host.
RUN if getent passwd "${HOST_UID}" >/dev/null; then \
        userdel -r "$(getent passwd "${HOST_UID}" | cut -d: -f1)" >/dev/null 2>&1 || true; \
    fi \
    && if ! getent group "${HOST_GID}" >/dev/null; then groupadd --gid "${HOST_GID}" gabit; fi \
    && useradd --uid "${HOST_UID}" --gid "${HOST_GID}" --create-home --shell /bin/bash gabit \
    && mkdir -p /workspace \
    && chown "${HOST_UID}:${HOST_GID}" /workspace

WORKDIR /workspace
USER gabit

# ---------------------------------------------------------------- deps ------
# Resolve the package graph from the manifest alone, before any source is
# copied, so editing a .swift file does not re-resolve dependencies.
FROM base AS deps

COPY --chown=gabit:gabit Package.swift Package.resolve[d] ./

RUN mkdir -p Sources/GabitKit \
    && : > Sources/GabitKit/Placeholder.swift \
    && swift package resolve \
    && rm -rf Sources \
    && mkdir -p /home/gabit/.cache/org.swift.swiftpm

# ----------------------------------------------------------------- dev ------
# The stage compose runs. Long-lived toolchain container: it holds no server,
# it exists so `make lint`, `make fmt`, `make build` and `make test` have a
# pinned Swift to run inside.
FROM base AS dev

ARG SWIFTLINT_VERSION=0.65.1
# SwiftLint has no Linux binary release, so enabling it compiles it from source
# and adds several minutes to the first build. Off by default; flip
# WITH_SWIFTLINT=1 in .env when you want it.
ARG WITH_SWIFTLINT=0

USER root
RUN if [ "${WITH_SWIFTLINT}" = "1" ]; then \
        git clone --depth 1 --branch "${SWIFTLINT_VERSION}" https://github.com/realm/SwiftLint.git /tmp/swiftlint \
        && swift build -c release --package-path /tmp/swiftlint --product swiftlint \
        && install -m 0755 /tmp/swiftlint/.build/release/swiftlint /usr/local/bin/swiftlint \
        && rm -rf /tmp/swiftlint; \
    fi
USER gabit

COPY --from=deps --chown=gabit:gabit /home/gabit/.cache /home/gabit/.cache
COPY --from=deps --chown=gabit:gabit /workspace /workspace

HEALTHCHECK --interval=30s --timeout=15s --start-period=10s --retries=3 \
    CMD swift --version > /dev/null 2>&1 || exit 1

CMD ["sleep", "infinity"]

# ------------------------------------------------------------- release ------
# Release build of the platform-agnostic core, with no dev tooling in the image.
# This is what a Linux CI job or a server-side reuse of GabitKit targets — it is
# not the shippable app, which is an .ipa produced by Xcode on macOS.
FROM base AS build

COPY --chown=gabit:gabit Package.swift Package.resolve[d] ./
COPY --chown=gabit:gabit Sources ./Sources

RUN swift build -c release

FROM swift:${SWIFT_VERSION}-noble-slim AS release

WORKDIR /app
COPY --from=build /workspace/.build/release/ ./
