# syntax=docker/dockerfile:1

# Swift toolchain for the parts of Gabit that are platform-agnostic.
#
# SwiftUI, UIKit and the iOS SDK are closed-source Apple frameworks with no
# Linux implementation, so this image deliberately does NOT try to build the
# app. It builds and tests GabitDomain and GabitData — the two packages that
# import nothing but Foundation and SwiftData — and it formats and lints every
# .swift file in the repository, GabitUI included: swift-format works on
# syntax, so it checks the SwiftUI layer without needing the Apple SDKs.
#
# The app itself is built with Xcode on macOS. See README.md.

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
# Resolve each package graph from its manifest alone, before any source is
# copied, so editing a .swift file does not re-resolve dependencies. Neither
# Linux-buildable package has an external dependency today; the layer is here
# so that adding the first one does not make every build slow.
FROM base AS deps

COPY --chown=gabit:gabit Packages/GabitDomain/Package.swift Packages/GabitDomain/Package.resolve[d] Packages/GabitDomain/
COPY --chown=gabit:gabit Packages/GabitData/Package.swift   Packages/GabitData/Package.resolve[d]   Packages/GabitData/

# SwiftPM validates that every declared target has a source directory before it
# will resolve, so stand in empty ones and throw them away afterwards.
RUN set -eu; \
    for pkg in GabitDomain GabitData; do \
        mkdir -p "Packages/${pkg}/Sources/${pkg}" "Packages/${pkg}/Tests/${pkg}Tests"; \
        : > "Packages/${pkg}/Sources/${pkg}/Placeholder.swift"; \
        : > "Packages/${pkg}/Tests/${pkg}Tests/Placeholder.swift"; \
        swift package resolve --package-path "Packages/${pkg}"; \
    done; \
    rm -rf Packages; \
    mkdir -p /home/gabit/.cache/org.swift.swiftpm

# ----------------------------------------------------------------- dev ------
# The stage compose runs. A long-lived toolchain container: it holds no server,
# it exists so `make lint`, `make fmt`, `make build` and `make test` have a
# pinned Swift to run inside.
FROM base AS dev

ARG SWIFTLINT_VERSION=0.65.1
# SwiftLint publishes no Linux binary, so enabling it compiles it from source
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

HEALTHCHECK --interval=30s --timeout=15s --start-period=10s --retries=3 \
    CMD swift --version > /dev/null 2>&1 || exit 1

CMD ["sleep", "infinity"]

# ------------------------------------------------------------- release ------
# Release build and test of the platform-agnostic packages, with no dev tooling
# in the image. This is what the Linux half of CI targets. It is not the
# shippable app — that is a signed .ipa produced by Xcode on macOS.
FROM base AS build

COPY --chown=gabit:gabit Packages/GabitDomain Packages/GabitDomain
COPY --chown=gabit:gabit Packages/GabitData   Packages/GabitData

RUN swift build -c release --package-path Packages/GabitDomain \
    && swift build -c release --package-path Packages/GabitData

FROM swift:${SWIFT_VERSION}-noble-slim AS release

WORKDIR /app
COPY --from=build /workspace/Packages/GabitDomain/.build/release/ ./GabitDomain/
COPY --from=build /workspace/Packages/GabitData/.build/release/ ./GabitData/
