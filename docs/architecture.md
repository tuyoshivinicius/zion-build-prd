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

## 2. Decisões consolidadas (D-xx)

Decisões estruturantes já tomadas, com o design doc de origem. Decisão não se reabre aqui: uma
decisão nova (ou reversão) nasce como ADR em `docs/adr/` e entra no índice da §3.

| # | Decisão | Origem (docs/superpowers/specs/) |
|---|---------|----------------------------------|
| D-01 | `assets/` é fonte única; `skills/*/references/` são derivados regenerados por sync (hook + guard de drift). | 2026-07-12-auto-sync-assets-design.md |
| D-02 | Distribuição dual — skills.sh e plugin do Claude Code — com autocontenção por cópia real. | 2026-07-12-distribuicao-dual-plugin-deps-design.md · 2026-07-12-zion-build-prd-npx-skills-design.md |
| D-03 | Prefixo `zion-` em todas as skills (namespace estável nos dois canais). | 2026-07-12-zion-prefixo-skills-design.md |
| D-04 | Regras decidíveis verificadas por script que **aconselha** no projeto-alvo (exit lido pela Fase 4), nunca bloqueia o autor. | 2026-07-17-check-prd-verificacao-mecanica-design.md |
| D-05 | Pontes para o Spec Kit montam prompts em **prosa** (conteúdo, não formato) e param — nunca disparam `/speckit.*`. | 2026-07-13-pontes-spec-kit-prosa-design.md |
| D-06 | Evidência de ADR proporcional ao risco: execução → spike; conhecimento → pesquisa com fonte; decisão dada → racional. | 2026-07-17-spike-evidencia-por-risco-design.md · 2026-07-18-adr-decisao-dada-design.md |
| D-07 | Contrato de capacidades C1–C3 com o superpowers (pin de versão + check de marcadores). | 2026-07-17-r9-contrato-superpowers-design.md |
| D-08 | Avaliação em duas camadas (mecânica no CI; julgamento sob demanda) com fixtures pareadas defeito/limpa. | 2026-07-17-r7-fixtures-avaliacao-harness-design.md |
| D-09 | A unidade de trabalho chama-se **spec** (rename fatia → spec) em toda a superfície. | 2026-07-18-rename-fatia-spec-design.md |
| D-10 | O repo governa a si mesmo: `docs/prd.md` + `docs/architecture.md` como fontes da verdade, com guard de canonização bloqueante. | 2026-07-18-governanca-canon-design.md |

## 3. Índice de ADRs

Decisões estruturantes futuras nascem via `/zion-adr-new` em `docs/adr/` (dogfood do próprio
harness) e são listadas aqui — `check-canon.sh` acusa ADR fora do índice.

*(nenhum ADR ainda — o histórico pré-governança vive nos design docs da §2)*

## 4. Scripts

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

## 5. Fonte única e derivados

Fontes mapeadas no `ASSET_MAP` (`check-canon.sh` acusa fonte `assets/` fora desta lista):

- assets/quality-rules.md — regras de qualidade e denylist de stack.
- assets/process-context.md — bloco invariante de contexto da jornada.
- assets/superpowers-contract.md — capacidades C1–C3 exigidas do executor externo.
- assets/templates/prd-skeleton.md — esqueleto da PRD (dogfoodado por `docs/prd.md`).
- assets/templates/traceability-table.md — template da tabela §12.
- assets/templates/backlog.md — template do backlog de specs.

Também distribuídos como references executáveis: `scripts/check-prd.sh`, `scripts/check-adr.sh`,
`scripts/trace-prd.sh`, `scripts/trace-backlog.sh` (cobertos pela tabela da §4).

## 6. Canonização — o que muda ⇒ onde reflete

| Mudança | Reflete em |
|---|---|
| Skill nova/removida/renomeada | RF na §6 + linha na §12 de `docs/prd.md` |
| Script novo/removido | Tabela de scripts (§4) deste doc |
| Fonte nova no `ASSET_MAP` | §5 deste doc |
| Decisão estruturante nova/revertida | ADR em `docs/adr/` + índice (§3) |
| Comportamento de estágio muda | RF correspondente em `docs/prd.md` |

`scripts/check-canon.sh` verifica o decidível disto no pre-commit (**bloqueia**) e no CI
(backstop). O indecidível (o texto do RF ainda descreve o comportamento?) é dever de quem edita —
regra em `CLAUDE.md`.
