# Changelog

Formato baseado em [Keep a Changelog](https://keepachangelog.com/), adaptado
para um projeto sem versionamento semântico ainda — as entradas são
agrupadas por PR/dia, mais recentes primeiro. Sem `[Unreleased]`: cada
entrada abaixo já está em `main`.

## 2026-09-11 — Login, registro e padrão de TDD (#4)

- **Backend de autenticação**: `Sources/Server` — API Vapor + Fluent sobre
  PostgreSQL, alvo executável separado no mesmo pacote Swift de `MauItKit`.
  `POST /auth/register` (nome, email, senha ≥8 caracteres, telefone
  opcional), `POST /auth/login`, `GET /auth/me`. Senhas com Bcrypt, sessão
  via JWT HS256 (bearer token, 7 dias).
- **Telas de Login/Sign up**: `App/MauIt/Screens/LoginView.swift` e
  `RegisterView.swift`, no mesmo design system das outras cinco telas.
  `App/MauIt/Auth/` (`APIClient`, `AuthViewModel`, `TokenStore` via
  Keychain) conecta o app ao backend; `RootView` passa a gatear o
  onboarding atrás do login e restaura sessão do Keychain sem round-trip
  de rede.
- **TDD estabelecido como padrão**: `Tests/MauItKitTests` (lógica pura) e
  `Tests/ServerTests` (rotas contra Postgres real, não mockado — ver
  `docker/postgres-init/`). `make test` roda os dois.
- **CI**: `.github/workflows/ci.yml` — lint + build + test em Linux
  (mesma imagem `swift:6.3.3-noble` do container de dev) e build real do
  app no Xcode (macOS) a cada push/PR.
- **Dependabot**: `.github/dependabot.yml` — PR semanal para pacotes
  Swift, imagens base Docker e GitHub Actions.

## 2026-09-10 — Backend Vapor/Postgres, revert do port para React Native

- Reversão completa do port para React Native + Node (commit `5f82dc8`,
  PR #3): o app voltou a ser 100% Swift/SwiftUI. O código RN nunca chegou
  a ficar em produção — foi revertido no mesmo dia em que foi mergeado.
- **Primeiro backend real**: Vapor + Fluent + FluentPostgresDriver,
  usuários com email/senha (sem nome/telefone ainda — isso veio no PR #4).
  `docker compose` ganhou o serviço `db` (Postgres 16); `Makefile` ganhou
  `migrate` e `serve`.
- Correções de lint (`swift-format`): variáveis em `camelCase`, quebra de
  linhas longas.

## 2026-09-08 — Rename Gabit → MauIt, cinco telas do design handoff

- Renomeado de "Gabit" para "MauIt" (bundle id, nomes de arquivo, docs).
- Implementadas as cinco telas a partir do handoff de design `Gabit —
  Screens & Foundations`: onboarding de meta, Today (no orçamento e acima
  do orçamento), quick add (teclado numérico custom em UIKit) e Progress.
- Design system extraído do handoff: paleta OKLCH (`Color+OKLCH.swift`),
  tipografia, métricas (raio de canto, espaçamento em escala de 4pt).

## 2026-09-01 — Scaffolding inicial

- Commit inicial do repositório.
- Ambiente Docker do toolchain Swift (`Dockerfile`, `compose.yaml`,
  `Makefile`) e scaffolding do app SwiftUI — pensado desde o início para
  separar núcleo de regras (`MauItKit`, testável em Linux) da camada
  SwiftUI (só compila via Xcode/macOS).
