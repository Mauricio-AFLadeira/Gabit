# Tech stack

Referência rápida do que o repositório usa e por quê. Detalhes de setup e
comandos estão no [README](../README.md); isto aqui é só "o que é cada
peça e onde ela mora".

## Linguagem e runtime

- **Swift 6** (`.swift-version`, `SWIFT_VERSION=6.3.3`), modo de linguagem
  Swift 6 (`swiftLanguageMode(.v6)`) em todos os alvos do `Package.swift` —
  concorrência estrita desde o início, não uma migração futura.
- **SwiftPM** como único gerenciador de pacotes/build system — sem
  CocoaPods, sem Carthage.

## Núcleo (`Sources/MauItKit`)

Swift puro + `Foundation`, sem nenhum import de framework da Apple
(`SwiftUI`, `UIKit`). É o que garante que o núcleo compile e rode em
Linux — modelos (`DayLog`, `WeightReading`, `GoalDirection`...) e a
única conta real do app hoje, `EnergyMath`.

## App (`App/MauIt`)

- **SwiftUI** (iOS 17+) — todas as telas.
- **UIKit** via `UIViewRepresentable` só onde SwiftUI não cobre: o teclado
  numérico custom do quick-add (`Components/NumericKeypad.swift`).
- **Keychain** (`Security` framework) para persistir o JWT da sessão —
  `App/MauIt/Auth/TokenStore.swift`. Não usa `UserDefaults` para isso de
  propósito: é credencial, não preferência.
- **URLSession** puro para falar com o backend (`APIClient.swift`) — sem
  Alamofire nem geração de cliente a partir de OpenAPI.
- **XcodeGen** (2.46.0) gera o `.xcodeproj` a partir de `project.yml`, que
  é o arquivo versionado — o `.xcodeproj` em si não vai pro git.

## Backend (`Sources/Server`)

- **Vapor 4** — framework HTTP.
- **Fluent** + **FluentPostgresDriver** — ORM/query builder e driver
  Postgres.
- **JWT** (`vapor/jwt`) — assinatura/verificação dos bearer tokens (HS256).
- **Bcrypt** (embutido no Vapor) — hash de senha.

Versões mínimas ficam fixadas em `Package.swift` (`from: "4.106.0"` etc.);
o Dependabot (`.github/dependabot.yml`) abre PR semanal quando saem
versões novas.

## Banco de dados

- **PostgreSQL 16** (`postgres:16-alpine` no `compose.yaml`). Dois bancos:
  `mauit` (dev, usado por `make serve`/`make migrate`) e `mauit_test`
  (isolado, criado uma vez por `docker/postgres-init/` — é contra ele que
  `ServerTests` roda; ver a seção TDD do [README](../README.md)).
- Migrations em `Sources/Server/Migrations/`, versionadas e aplicadas via
  Fluent (`swift run Server migrate`).

## Testes

- **XCTest** — `Tests/MauItKitTests` (lógica pura, sem I/O).
- **XCTVapor** — `Tests/ServerTests`, contra o Postgres de teste de
  verdade (não mock, não SQLite in-memory — ver a razão no README).

## Infra local / dev

- **Docker + Docker Compose** — todo o toolchain que não precisa do SDK da
  Apple roda em container (`swift:6.3.3-noble`). `compose.yaml` define os
  serviços `app` (toolchain) e `db` (Postgres).
- **Make** — interface única pros comandos (`make lint`, `make test`,
  `make serve`, `make xcode`...); ver a tabela completa no README.
- **swift-format** — linter/formatter padrão (vem com o toolchain).
  **SwiftLint** (0.65.1) é opcional, atrás de `WITH_SWIFTLINT=1` — não tem
  binário pré-compilado pra Linux, então ligá-lo adiciona tempo de build.

## CI/CD

- **GitHub Actions** (`.github/workflows/ci.yml`) — dois jobs por
  push/PR: lint+build+test em Linux (`swift:6.3.3-noble` + serviço
  Postgres) e build real do app via `xcodebuild` num runner macOS
  (Xcode selecionado dinamicamente com `maxim-lobanov/setup-xcode`, pra
  não depender do Xcode default do runner).
- **Dependabot** (`.github/dependabot.yml`) — ecosystems `swift`,
  `docker` e `github-actions`, semanal.

## O que *não* está aqui (de propósito)

- Sem backend em outra linguagem — já existiu uma versão em
  React Native + Node (`5f82dc8`), revertida no mesmo dia (ver
  [CHANGELOG.md](../CHANGELOG.md)). O projeto é Swift ponta a ponta.
- Sem ORM/driver SQLite para teste — decisão deliberada, ver README.
- Sem ferramenta de mock de rede/HTTP nos testes de app — `APIClient`
  ainda não tem testes automatizados do lado do cliente (SwiftUI/App
  fica fora do alcance do container Linux; ver seção de testes do
  README para o estado disso).
