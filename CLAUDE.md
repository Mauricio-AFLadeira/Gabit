# CLAUDE.md

Contexto rápido pra qualquer sessão do Claude Code neste repo. Detalhes
completos (comandos, decisões, estrutura de pastas) estão no
[README](README.md) — este arquivo só resume o que uma sessão nova
precisa saber antes de tocar em código.

## O que é este projeto

**MauIt** — app iOS (Swift + SwiftUI) de registro de alimentos e
acompanhamento de calorias. Núcleo de regras (`MauItKit`) em Swift puro,
testável em Linux; backend (`Server`) em Vapor + Fluent/PostgreSQL, no
mesmo pacote Swift. Ver [docs/TECH_STACK.md](docs/TECH_STACK.md) para a
lista completa de tecnologias e [CHANGELOG.md](CHANGELOG.md) para como o
projeto chegou até aqui (inclui uma reversão completa de um port pra
React Native — o projeto é Swift ponta a ponta, de propósito).

## Regra de trabalho: TDD

Regra de negócio nova ou rota/validação nova entra por teste primeiro:
escreva o teste falhando em `Tests/`, veja-o falhar (`make test`),
implemente o mínimo pra ficar verde, refatore. Todo PR passa pelo CI
(`.github/workflows/ci.yml`) antes do merge — lint + build + test em
Linux, e build real do app no Xcode. Ver a seção "Desenvolvimento — TDD"
do README para o padrão exato que `AuthControllerTests` já segue.

## Comandos essenciais

```
make up        # sobe o container do toolchain + Postgres
make lint      # swift-format --strict em Sources/, App/, Tests/
make test      # MauItKitTests + ServerTests
make build     # compila núcleo + backend
make xcode     # gera MauIt.xcodeproj (host macOS, precisa de xcodegen)
```

Tabela completa de comandos: README, seção "Comandos".

## Coisas que uma sessão nova precisa saber de cara

- **`App/` (SwiftUI) não compila no container Linux** — só lint de
  sintaxe. Pra validar de verdade, precisa rodar `make xcode` + abrir no
  Xcode/Simulator (macOS). Não assuma que `make build`/`make test`
  cobrem a camada de tela.
- **`MauIt.xcodeproj` não é versionado** — é gerado de `project.yml` via
  `make xcode`. Edite `project.yml`, nunca o `.xcodeproj` direto.
- **`ServerTests` roda contra Postgres real** (`mauit_test`, banco
  separado do de dev), não mock nem SQLite in-memory — decisão
  deliberada, ver README. Compartilham uma única `Application` por
  classe de teste (não uma por teste) porque recriar a `Application`
  repetidamente trava no shutdown da pool de conexões em Linux — já foi
  investigado e é comportamento conhecido, não reabra essa investigação
  do zero se aparecer de novo.
- **Branches remotas obsoletas**: `claude/gabit-weekend-project-uhajba`
  e `feature/backend-scaffold` são tentativas abandonadas de uma
  arquitetura anterior (pacotes `GabitDomain`/`GabitData`/`GabitUI` e um
  scaffold de backend descartado) — nunca foram mergeadas em `main` e não
  refletem o estado atual do projeto. Ignore-as ao explorar o histórico.
- **Nunca commite direto em `main`** — sempre branch + PR, mesmo que o
  histórico tenha alguns commits diretos de antes desse padrão existir.

## Onde procurar mais contexto

| Pergunta | Onde |
|---|---|
| Como rodar/testar localmente | [README](README.md) |
| O que mudou e quando | [CHANGELOG.md](CHANGELOG.md) |
| Qual tecnologia faz o quê | [docs/TECH_STACK.md](docs/TECH_STACK.md) |
| Por que uma decisão de arquitetura foi tomada | README, seção "Decisões" |
