# Gabit

App iOS em Swift + SwiftUI, com o núcleo de regras isolado num pacote SPM que
compila também em Linux.

## Requisitos

Para o núcleo (`GabitKit`), lint e formatação: **apenas Docker e Docker Compose.**

Para rodar o app de fato: **macOS com Xcode 16+**. SwiftUI, UIKit e o SDK do iOS
são frameworks fechados da Apple e não existem para Linux — nenhum container
constrói um app iOS, e este não finge que constrói.

## Como rodar

```
make setup
make up
```

A partir daí, tudo o que não precisa do SDK da Apple roda dentro do container:

```
make lint      # verifica Sources/ e App/
make build     # compila o núcleo
```

No macOS, para abrir o app:

```
brew install xcodegen
make xcode
open Gabit.xcodeproj
```

## Comandos

| Comando | O que faz | Onde roda |
|---|---|---|
| `make setup` | Cria o `.env`, ativa o hook de pre-commit e builda a imagem | host |
| `make up` | Sobe o container do toolchain | host |
| `make down` | Derruba o ambiente | host |
| `make logs` | Acompanha os logs do container | host |
| `make shell` | Abre um shell dentro do container | container |
| `make lint` | `swift format lint --strict` em `Sources/` e `App/` | container |
| `make fmt` | Formata todo o Swift no lugar | container |
| `make build` | `swift build` do núcleo | container |
| `make test` | `swift test` do núcleo | container |
| `make xcode` | Gera `Gabit.xcodeproj` a partir do `project.yml` | host (macOS) |
| `make reset` | Derruba tudo e apaga os volumes | host |

## Estrutura

```
Sources/GabitKit/    Núcleo: modelos, regras, persistência. Swift puro +
                     Foundation, sem framework da Apple. É o que o container
                     compila, testa e o que a CI em Linux consegue verificar.
App/Gabit/           Camada SwiftUI. Só compila no Xcode, mas é formatada e
                     lintada pelo container junto com o resto.
Package.swift        Manifesto do pacote (declara só GabitKit).
project.yml          Fonte de verdade do projeto Xcode. O .xcodeproj é gerado
                     e não é versionado — edite este arquivo, não o projeto.
Dockerfile           Estágios: base → deps → dev (o que o compose roda) e
                     build → release (para CI em Linux).
compose.yaml         O container do toolchain e seus volumes de cache.
```

## Decisões

**A divisão núcleo/app é o ponto do ambiente.** Sem ela o Docker não teria o que
fazer num projeto iOS. Com ela, regra de negócio ganha build e teste rápidos e
reprodutíveis em qualquer máquina, e só a camada de tela depende do macOS.
Vale manter `GabitKit` livre de `import SwiftUI` — no dia em que escapar um, o
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
no alvo do app. Ligar isso agora, com quatro arquivos, é barato; ligar depois de
um app inteiro pronto, não.

**`.build` é um volume nomeado, não o diretório do host.** O Xcode escreve
objetos Mach-O ali e o container escreve ELF; compartilhar o diretório faz os
dois toolchains brigarem pelos mesmos artefatos.

**O `.xcodeproj` não é versionado.** Ele é gerado do `project.yml` por
`make xcode`. É o que evita conflito de merge em XML gerado e mantém a
configuração do app legível no diff.

**Não há estágio `prod` de runtime.** O artefato de produção de um app iOS é um
`.ipa` assinado, produzido pelo Xcode. O estágio `release` do Dockerfile existe
para CI em Linux e para reaproveitar `GabitKit` fora do app.
