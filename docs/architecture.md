# Arquitetura — Zion Build PRD (o harness)

> Fonte da verdade do **como/com-quê** deste repo. O o-quê/por-quê vive em `docs/prd.md`. Toda
> mudança estrutural (skill, script, asset, decisão) reflete aqui no mesmo commit (canonização —
> veja `CLAUDE.md`); `scripts/check-canon.sh` cruza este documento com a implementação.

## 1. Visão geral

O harness é um conjunto de **skills do Claude Code** (`skills/zion-*`), sem runtime próprio: toda
a lógica é prosa de skill (`SKILL.md`) + verificadores em shell script.

- **Skills autocontidas.** Cada skill carrega em `references/` os assets de que precisa. Os
  `references/` são **artefatos derivados** — a fonte única é `assets/` (e alguns `scripts/*.sh`),
  mapeada em `scripts/asset-map.sh` e sincronizada por `scripts/sync-assets.sh`.
- **Verificadores em shell.** Regra decidível vira script (`check-*.sh`, `trace-*.sh`) com
  contrato comum: exit 0 limpo · 1 achados · 2 erro de uso. No projeto-alvo o veredito é
  **conselho** (a Fase 4 da skill ecoa e o autor decide); neste repo os guards de integridade
  **bloqueiam** (pre-commit + CI).
- **Enforcement em camadas.** Hook versionado (`.githooks/pre-commit`, ativado por
  `scripts/setup-hooks.sh`) regenera derivados e roda os guards; o CI
  (`.github/workflows/check-assets.yml`) repete tudo como backstop.
- **Avaliação em duas camadas.** Determinística: auto-testes `test-*.sh` contra
  `scripts/fixtures/`, agregados por `scripts/eval.sh` (CI a cada push). Julgamento (LLM):
  fixtures com defeito plantado, sob demanda — roteiro em `docs/guias/avaliacao-harness.md`.

## 2. Decisões estruturantes (ADRs)

Toda decisão estruturante deste repo é um **ADR aceito** em `docs/adr/` (dogfood do próprio
harness). Decisão não se reabre aqui: uma decisão nova (ou reversão) nasce como ADR novo. O
`check-canon.sh` acusa ADR fora deste índice; o `check-adr.sh docs/adr` (pre-commit + CI) cobra
evidência presente e supersessão simétrica. A proveniência histórica de cada decisão vive **dentro**
do próprio ADR (campo **Evidência**, que aponta o design doc de origem), não mais neste documento.

| ADR | Decisão (uma linha) |
|---|---|
| [ADR-001](adr/ADR-001-assets-fonte-unica.md) | `assets/` é fonte única; `skills/*/references/` são derivados regenerados por sync (hook + guard de drift). |
| [ADR-002](adr/ADR-002-distribuicao-dual.md) | Distribuição dual — skills.sh e plugin do Claude Code — com autocontenção por cópia real. |
| [ADR-003](adr/ADR-003-prefixo-zion-skills.md) | Prefixo `zion-` em todas as skills (namespace estável nos dois canais). |
| [ADR-004](adr/ADR-004-verificadores-aconselham.md) | Regras decidíveis verificadas por script que **aconselha** no projeto-alvo (exit lido pela Fase 4), nunca bloqueia o autor. |
| [ADR-005](adr/ADR-005-pontes-spec-kit-prosa.md) | Pontes para o Spec Kit montam prompts em **prosa** (conteúdo, não formato) e param — nunca disparam `/speckit.*`. |
| [ADR-006](adr/ADR-006-evidencia-por-risco.md) | Evidência de ADR proporcional ao risco: execução → spike; conhecimento → pesquisa com fonte; decisão dada → racional. |
| [ADR-007](adr/ADR-007-contrato-superpowers.md) | Contrato de capacidades C1–C3 com o superpowers (pin de versão + check de marcadores). |
| [ADR-008](adr/ADR-008-avaliacao-duas-camadas.md) | Avaliação em duas camadas (mecânica no CI; julgamento sob demanda) com fixtures pareadas defeito/limpa. |
| [ADR-009](adr/ADR-009-unidade-spec.md) | A unidade de trabalho chama-se **spec** (rename fatia → spec) em toda a superfície. |
| [ADR-010](adr/ADR-010-governanca-canon.md) | O repo governa a si mesmo: `docs/prd.md` + `docs/architecture.md` como fontes da verdade, com guard de canonização bloqueante. |
| [ADR-011](adr/ADR-011-adrs-canonicos.md) | Promover as decisões consolidadas D-xx a ADRs reais; o canon passa a citar ADRs, não specs. |

## 3. Scripts

Papel de uma linha por script (`check-canon.sh` acusa script fora desta tabela).

| Script | Papel |
|---|---|
| scripts/asset-map.sh | Mapa fonte única → skills consumidoras; sourced por sync/check. |
| scripts/sync-assets.sh | Regenera `skills/*/references/` a partir da fonte única. |
| scripts/check-assets.sh | Guard de drift dos derivados (pre-commit via sync + CI). |
| scripts/check-prd.sh | Verificador das regras decidíveis da PRD e do prompt do specify. |
| scripts/check-adr.sh | Verificador de presença de evidência e supersessão simétrica nos ADRs. |
| scripts/check-superpowers-contract.sh | Verificador do contrato C1–C3 no superpowers instalado. |
| scripts/check-canon.sh | Guard de canonização: cruza prd.md/architecture.md com skills/, scripts/, ASSET_MAP e docs/adr/. |
| scripts/trace-prd.sh | Semeia/reconcilia a §12 da PRD a partir das specs. |
| scripts/trace-backlog.sh | Semeia/reconcilia o backlog de specs. |
| scripts/eval.sh | Runner único da camada mecânica (auto-testes abaixo). |
| scripts/test-check-prd.sh | Auto-teste do check-prd.sh contra fixtures. |
| scripts/test-check-adr.sh | Auto-teste do check-adr.sh contra fixtures. |
| scripts/test-check-superpowers-contract.sh | Auto-teste do check de contrato contra fixtures. |
| scripts/test-check-canon.sh | Auto-teste do check-canon.sh contra fixtures. |
| scripts/test-trace-prd.sh | Auto-teste do trace-prd.sh contra fixtures. |
| scripts/test-trace-backlog.sh | Auto-teste do trace-backlog.sh contra fixtures. |
| scripts/setup-hooks.sh | Ativa os git hooks versionados (core.hooksPath). |

## 4. Fonte única e derivados

Fontes mapeadas no `ASSET_MAP` (`check-canon.sh` acusa fonte `assets/` fora desta lista):

- assets/quality-rules.md — regras de qualidade e denylist de stack.
- assets/process-context.md — bloco invariante de contexto da jornada.
- assets/superpowers-contract.md — capacidades C1–C3 exigidas do executor externo.
- assets/templates/prd-skeleton.md — esqueleto da PRD (dogfoodado por `docs/prd.md`).
- assets/templates/traceability-table.md — template da tabela §12.
- assets/templates/backlog.md — template do backlog de specs.

Também distribuídos como references executáveis: `scripts/check-prd.sh`, `scripts/check-adr.sh`,
`scripts/trace-prd.sh`, `scripts/trace-backlog.sh` (cobertos pela tabela da §3).

## 5. Canonização — o que muda ⇒ onde reflete

| Mudança | Reflete em |
|---|---|
| Skill nova/removida/renomeada | RF na §6 + linha na §12 de `docs/prd.md` |
| Script novo/removido | Tabela de scripts (§3) deste doc |
| Fonte nova no `ASSET_MAP` | §4 deste doc |
| Decisão estruturante nova/revertida | ADR em `docs/adr/` + índice (§2) |
| Comportamento de estágio muda | RF correspondente em `docs/prd.md` |

`scripts/check-canon.sh` verifica o decidível disto no pre-commit (**bloqueia**) e no CI
(backstop). O indecidível (o texto do RF ainda descreve o comportamento?) é dever de quem edita —
regra em `CLAUDE.md`.
