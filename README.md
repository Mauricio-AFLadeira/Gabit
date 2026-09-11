# MauIt

App iOS em Swift + SwiftUI para registro de alimentos e acompanhamento de
calorias — meta, déficit/superávit, macros e peso. Núcleo de regras isolado
num pacote SPM que compila também em Linux.

Implementado a partir do handoff de design `Gabit - Screens & Foundations`
(Claude Design): cinco telas — onboarding de meta, Today, quick-add com
teclado numérico em UIKit, progresso de peso e o estado "acima do
orçamento" — mais o design system (paleta OKLCH, tipografia, espaçamento)
extraído da mesma doc.

## Telas

| # | Tela | Arquivo |
|---|---|---|
| — | Login / Sign up — email+senha, ou nome+email+senha+telefone opcional | `Screens/LoginView.swift`, `Screens/RegisterView.swift` |
| 01 | Onboarding — meta (direção, taxa, alvo derivado) | `Screens/OnboardingGoalView.swift` |
| 02 / 05 | Today — no orçamento e acima do orçamento | `Screens/TodayView.swift` |
| 03 | Quick add — teclado numérico custom (`UIViewRepresentable`) | `Screens/LogFoodView.swift`, `Components/NumericKeypad.swift` |
| 04 | Progress — tendência de peso, projeção, aderência | `Screens/ProgressScreenView.swift` |

Login e cadastro falam de verdade com `Sources/Server` (`App/MauIt/Auth/`:
`APIClient`, `AuthViewModel`, `TokenStore` no Keychain) — ver seção Backend.
Dali em diante (onboarding, Today, Progress, quick-add) as telas ainda rodam
sobre dados mock (`Sources/MauItKit/MockData.swift`). A única conta real
depois do login é a do alvo diário (`EnergyMath`), que é o que a tela 01
demonstra: o alvo é derivado da direção e da taxa, nunca digitado.

## Backend

`Sources/Server/` é uma API Vapor + Fluent/PostgreSQL, no mesmo pacote Swift
que `MauItKit` (e compilada pelo mesmo container Linux). Hoje cobre só
usuários e autenticação:

| Rota | O que faz |
|---|---|
| `POST /auth/register` | Cria a conta (`name`, `email`, `password` — mínimo 8 caracteres —, `phone` opcional), devolve `{ user, token }` |
| `POST /auth/login` | Autentica com `email` + `password`, devolve `{ user, token }` |
| `GET /auth/me` | Devolve o usuário do token (`Authorization: Bearer <token>`) |
| `GET /health` | Healthcheck |

`token` é um JWT HS256 (`JWT_SECRET` no `.env`) válido por 7 dias. Senhas são
guardadas com Bcrypt (`password_hash`), nunca em texto puro. O schema
(`users`) é criado por `make migrate`, que roda as migrations Fluent
`CreateUser` e `AddNameAndPhoneToUser` contra o Postgres do `docker compose`
(serviço `db`).

No app, `App/MauIt/Auth/APIClient.swift` aponta para
`http://localhost:8080` — funciona de graça no Simulator (que enxerga o
`localhost` do Mac host); num device físico, troque `APIConfig.baseURL`
para o IP da máquina na rede local.

## Design system

`App/MauIt/DesignSystem/` reproduz a doc à risca:

- **Cores** — `Color+OKLCH.swift` implementa a conversão OKLCH → sRGB (via
  OKLab) usada pelo `oklch()` do browser, então a paleta bate com a doc bit
  a bit em vez de aproximar por hex. `Palette.swift` nomeia cada token
  (neutros, semânticas, macros).
- **Tipografia** — face do sistema para tudo que o usuário lê (Dynamic Type
  de graça); mono para unidades, datas e labels. A doc especifica IBM Plex
  Mono; o app usa a fonte mono do sistema como substituta — zero setup de
  fonte, mesmo caráter tabular. Trocar para a IBM Plex Mono de verdade é
  uma questão de registrar os arquivos no `Info.plist` e apontar
  `Typography.swift` para eles.
- **Métricas** — `Metrics.swift` fixa as regras da doc: raio 14 para
  cards, 12 para controles, 999 para pills; escala de espaçamento de 4pt;
  alvo de toque mínimo 44×44.

## Requisitos

Para o núcleo (`MauItKit`), o backend (`Server`) e Postgres, lint e formatação:
**apenas Docker e Docker Compose.**

Para rodar o app de fato: **macOS com Xcode 16+**. SwiftUI, UIKit e o SDK do iOS
são frameworks fechados da Apple e não existem para Linux — nenhum container
constrói um app iOS, e este não finge que constrói.

## Como rodar

```
make setup
make up
```

`make up` também sobe o Postgres (serviço `db`). A partir daí, tudo o que não
precisa do SDK da Apple roda dentro do container:

```
make lint      # verifica Sources/, App/ e Tests/
make build     # compila núcleo + backend
make test      # MauItKitTests + ServerTests, contra o Postgres de teste
make migrate   # cria o schema no Postgres de dev
make serve     # sobe a API em localhost:8080
```

No macOS, para abrir o app:

```
brew install xcodegen
make xcode
open MauIt.xcodeproj
```

## Comandos

| Comando | O que faz | Onde roda |
|---|---|---|
| `make setup` | Cria o `.env`, ativa o hook de pre-commit e builda a imagem | host |
| `make up` | Sobe o container do toolchain e o Postgres | host |
| `make down` | Derruba o ambiente | host |
| `make logs` | Acompanha os logs do container | host |
| `make shell` | Abre um shell dentro do container | container |
| `make lint` | `swift format lint --strict` em `Sources/`, `App/` e `Tests/` | container |
| `make fmt` | Formata todo o Swift no lugar | container |
| `make build` | `swift build` (núcleo + backend) | container |
| `make test` | `swift test` — `MauItKitTests` + `ServerTests` | container |
| `make migrate` | Roda as migrations Fluent contra o Postgres de dev | container |
| `make serve` | Sobe a API (`Server`) em `0.0.0.0:8080` | container |
| `make xcode` | Gera `MauIt.xcodeproj` a partir do `project.yml` | host (macOS) |
| `make reset` | Derruba tudo e apaga os volumes (inclui os dados do Postgres) | host |

## Desenvolvimento — TDD

Regra de negócio nova (`MauItKit`) ou rota/validação nova (`Server`) entra por
teste primeiro: escreva o teste falhando em `Tests/`, veja-o falhar
(`make test`), implemente o mínimo pra ficar verde, refatore. `EnergyMath`,
`DayLog` e `AuthController` já seguem esse padrão — use-os de referência.

- **`MauItKitTests`** — lógica pura (`XCTAssertEqual` direto), sem rede nem
  banco. É onde a maior parte da regra de negócio do app deveria morrer:
  rápido de rodar, roda em qualquer máquina.
- **`ServerTests`** — sobe a `Application` de verdade (`configure(_:)`, o
  mesmo que `make serve` usa) contra o banco `mauit_test`
  (`docker/postgres-init/`). Uma única `Application` é migrada e
  compartilhada por toda a classe de teste — recriá-la a cada teste (migrar
  e reverter o schema por teste) tende a travar no shutdown da pool de
  conexões do Postgres em Linux. Isolamento vem de cada teste usar um email
  próprio, não de resetar o schema; leia o dado que você acabou de escrever,
  não assuma tabela vazia. Deliberadamente *não* mocka o Fluent: um mock não
  pega erro de migration, de query ou de serialização, que é justamente a
  classe de bug mais comum numa rota nova.
- Nenhum teste ainda cobre `App/` (SwiftUI) — o Simulator/XCTest de UI fica
  fora do escopo do container Linux. Verificação da camada de tela hoje é
  `make xcode` + rodar no Simulator; se isso crescer, um alvo de UI tests via
  Xcode (não `swift test`) é o próximo passo.

`make test` roda os dois pacotes de teste de uma vez. O CI (veja abaixo) roda
exatamente esse comando a cada PR — um teste vermelho bloqueia o merge.

## CI

`.github/workflows/ci.yml` roda em todo push/PR para `main`:

| Job | O que faz | Runner |
|---|---|---|
| `lint-and-test` | `swift format lint --strict`, `swift build --build-tests`, `swift test` (com um serviço Postgres dedicado) | `swift:6.3.3-noble` (mesma imagem do `Dockerfile`) |
| `ios-build` | `xcodegen generate` + `xcodebuild build` do app pro Simulator | `macos-14` |

`.github/dependabot.yml` abre PR semanal para atualizações de pacotes Swift
(`Package.swift`), imagens base (`swift:*`, `postgres:*` no `Dockerfile` e
`compose.yaml`) e as próprias GitHub Actions fixadas nos workflows.

## Estrutura

```
Sources/MauItKit/    Núcleo: modelos (DayLog, WeightReading, GoalDirection...),
                     EnergyMath, MockData. Swift puro + Foundation, sem
                     framework da Apple. É o que o container compila, testa
                     e o que a CI em Linux consegue verificar.
Sources/Server/      API Vapor + Fluent/PostgreSQL.
  Models/            Modelos Fluent (User).
  Migrations/         Migrations do schema (CreateUser, AddNameAndPhoneToUser).
  DTOs/              Payloads de request/response (Content).
  Auth/              JWTPayload e o authenticator do bearer token.
  Controllers/       Rotas agrupadas por recurso (AuthController).
  configure.swift    Conecta Postgres, registra migrations e o signer JWT.
  routes.swift       Registra os RouteCollection na Application.
Tests/
  MauItKitTests/     Testes de lógica pura (EnergyMath, DayLog, SignedFormatting).
  ServerTests/       Testes de rota contra o Postgres de teste (AuthController).
App/MauIt/           Camada SwiftUI.
  DesignSystem/      Cores (OKLCH), tipografia, métricas.
  Components/        Botões, anel de progresso, barra de macro, linha de
                     entrada, teclado numérico (UIKit), LabeledTextField.
  Screens/           Login, Sign up e as cinco telas do produto.
  Auth/              APIClient, AuthViewModel, TokenStore (Keychain).
  RootView.swift     Login/Sign up → onboarding → tabs (Today/Progress) → sheet.
Package.swift        Manifesto do pacote: MauItKit e Server (produtos) mais
                     MauItKitTests e ServerTests (alvos de teste).
project.yml          Fonte de verdade do projeto Xcode. O .xcodeproj é gerado
                     e não é versionado — edite este arquivo, não o projeto.
Dockerfile           Estágios: base → deps → dev (o que o compose roda) e
                     build → release (para CI em Linux).
compose.yaml         O container do toolchain, o Postgres (`db`) e os
                     volumes de cache.
docker/postgres-init/ Script que cria o banco `mauit_test` na primeira subida
                     do volume do Postgres.
.github/workflows/   CI (lint, build, test, build do app no Xcode).
.github/dependabot.yml Atualização semanal de pacotes Swift/Docker/Actions.
```

## Decisões

**A divisão núcleo/app é o ponto do ambiente.** Sem ela o Docker não teria o que
fazer num projeto iOS. Com ela, regra de negócio ganha build e teste rápidos e
reprodutíveis em qualquer máquina, e só a camada de tela depende do macOS.
Vale manter `MauItKit` livre de `import SwiftUI` — no dia em que escapar um, o
`make build` acusa.

**Lint cobre `App/` mesmo sem SDK da Apple.** `swift-format` trabalha em cima da
sintaxe, não da compilação, então o container consegue checar a camada SwiftUI
sem conseguir construí-la.

**`swift-format` como linter padrão, SwiftLint opcional.** O `swift-format` vem
junto do toolchain: zero instalação e sempre na versão do Swift fixada. O
SwiftLint não publica binário para Linux, então ligá-lo significa compilá-lo
durante o build da imagem — vários minutos no primeiro `make setup`. Fica atrás
de `WITH_SWIFTLINT=1` no `.env`, com o `.swiftlint.yml` já pronto.

**Versões fixadas:** Swift 6.3.3 (`.swift-version` e `SWIFT_VERSION`), SwiftLint
0.65.1, XcodeGen 2.46.0. Sem `latest` em imagem: `latest` quebra o build de quem
clonar o repositório daqui a três meses.

**Modo de linguagem Swift 6** ligado no pacote e `SWIFT_STRICT_CONCURRENCY=complete`
no alvo do app.

**`.build` é um volume nomeado, não o diretório do host.** O Xcode escreve
objetos Mach-O ali e o container escreve ELF; compartilhar o diretório faz os
dois toolchains brigarem pelos mesmos artefatos.

**O `.xcodeproj` não é versionado.** Ele é gerado do `project.yml` por
`make xcode`. É o que evita conflito de merge em XML gerado e mantém a
configuração do app legível no diff.

**Não há estágio `prod` de runtime.** O artefato de produção de um app iOS é um
`.ipa` assinado, produzido pelo Xcode. O estágio `release` do Dockerfile existe
para CI em Linux e para reaproveitar `MauItKit` fora do app.

**As cinco telas ainda rodam sobre `MockData`, não sobre a API.** `DayLog`,
`ProgressSummary` etc. são o formato que o backend vai preencher conforme as
próximas entidades (metas, dias, peso) ganharem tabela — hoje só usuários e
autenticação existem do lado do servidor.

**`Server` é um alvo à parte no mesmo pacote, não um serviço separado.**
Reaproveita o container Linux que já builda `MauItKit`, o mesmo toolchain
Swift e o mesmo `swift-format`/lint — sem duplicar Dockerfile ou versão de
Swift para o backend. `App/` (SwiftUI) não depende de `Server`; a única
ligação viria de o app de fato chamar a API pela rede, o que ainda não existe.

**`ServerTests` roda contra Postgres de verdade, não SQLite in-memory.**
Testar num banco diferente do de produção é o clássico jeito de um teste
verde esconder uma migration ou uma query que só quebra no Postgres real.
O banco `mauit_test` (criado uma vez pelo script de init do Postgres) paga o
custo de precisar do `db` no ar, em troca de os testes realmente provarem
que a rota funciona contra o banco que vai pra produção.

**JWT em vez de sessão com cookie.** O cliente é um app iOS, não um browser —
um bearer token guardado no Keychain encaixa melhor que gerenciar cookies.
`JWTPayload.verify` só confere expiração; revogação (logout do lado do
servidor, troca de senha invalidando tokens antigos) fica para quando isso
importar de verdade.
