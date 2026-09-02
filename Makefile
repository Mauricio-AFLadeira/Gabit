SHELL := /bin/bash
.DEFAULT_GOAL := help

COMPOSE := docker compose
EXEC    := $(COMPOSE) exec -T app

# Packages the Linux toolchain can build and test. GabitUI is absent on
# purpose: it imports SwiftUI, which has no Linux implementation.
LINUX_PACKAGES := GabitDomain GabitData

# swift-format works on syntax, so it covers GabitUI and the app target too.
SWIFT_DIRS := Packages Gabit

.PHONY: help setup up down logs shell lint fmt build test xcode reset

help:  ## Lista os comandos disponíveis
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-8s\033[0m %s\n", $$1, $$2}'

setup:  ## Prepara o projeto pela primeira vez (.env, hooks, build da imagem)
	@test -f .env || { cp .env.example .env; echo "Criado .env a partir de .env.example."; }
	@if [ "$$(uname)" = "Linux" ]; then \
		sed -i "s/^HOST_UID=.*/HOST_UID=$$(id -u)/; s/^HOST_GID=.*/HOST_GID=$$(id -g)/" .env; \
		echo "Ajustado HOST_UID/HOST_GID no .env para $$(id -u):$$(id -g)."; \
	fi
	git config core.hooksPath .githooks
	$(COMPOSE) build

up:  ## Sobe o container do toolchain
	$(COMPOSE) up -d
	@echo "Toolchain Swift no ar. Use 'make test', 'make lint' ou 'make shell'."

down:  ## Derruba o ambiente
	$(COMPOSE) down

logs:  ## Acompanha os logs do container
	$(COMPOSE) logs -f app

shell:  ## Abre um shell dentro do container
	$(COMPOSE) exec app bash

lint:  ## Verifica formatação e estilo de todo o Swift (inclusive GabitUI)
	$(EXEC) swift format lint --strict --recursive $(SWIFT_DIRS)
	@if $(EXEC) test -x /usr/local/bin/swiftlint; then $(EXEC) swiftlint lint --quiet; fi

fmt:  ## Formata todo o Swift no lugar
	$(EXEC) swift format --in-place --recursive $(SWIFT_DIRS)

build:  ## Compila os pacotes independentes de plataforma
	@for pkg in $(LINUX_PACKAGES); do \
		echo "==> build $$pkg"; \
		$(EXEC) swift build --package-path Packages/$$pkg || exit 1; \
	done

test:  ## Roda os testes de domínio e de persistência
	@for pkg in $(LINUX_PACKAGES); do \
		echo "==> test $$pkg"; \
		$(EXEC) swift test --package-path Packages/$$pkg || exit 1; \
	done

xcode:  ## Gera Gabit.xcodeproj a partir do project.yml (macOS, fora do container)
	@command -v xcodegen >/dev/null 2>&1 || { echo "xcodegen não encontrado. Instale com: brew install xcodegen"; exit 1; }
	xcodegen generate
	@echo "Gerado Gabit.xcodeproj. Abra o workspace com: open Gabit.xcworkspace"

reset:  ## Derruba tudo e apaga os volumes (destrói caches e artefatos locais)
	$(COMPOSE) down -v
