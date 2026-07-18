# Design — canonizar as decisões consolidadas em ADRs reais

**Data:** 2026-07-18 · **Status:** aprovado

## Problema

A governança do dia 1 (D-10 / `governanca-canon`) consolidou as decisões estruturantes já
tomadas como a tabela **D-01…D-10** na §2 do `docs/architecture.md`, cada linha apontando o
**design doc de origem** em `docs/superpowers/specs/`. O `docs/adr/` nasceu vazio, só com README,
reservado para decisões futuras via `/zion-adr-new`.

Consequência: a fonte da verdade de arquitetura **referencia as specs** para lastrear cada
decisão, e o padrão de ADR adotado pelo próprio harness não é dogfoodado nas suas próprias
decisões. Queremos promover D-01…D-10 a ADRs reais em `docs/adr/`, no padrão adotado, de modo que
o canon deixe de referenciar as specs — a proveniência desce uma camada, para dentro de cada ADR.

Isto **revisa a DECIDIR-3** do `governanca-canon` (que escolhera consolidar como D-xx apontando
specs, com `docs/adr/` vazio no dia 1). A revisão é registrada como um ADR (ADR-011), coerente
com a regra "mudar de decisão é ADR novo".

## Decisões fechadas (brainstorming)

- **[Proveniência] ADR cita a spec de origem.** O `architecture.md` passa a referenciar só os
  ADRs (canon limpo de specs). Dentro de cada ADR, o campo **Evidência** é do tipo *conhecimento*
  e aponta o design doc de origem (`docs/superpowers/specs/<origem>-design.md`) — um caminho, que
  o `check-adr.sh` reconhece. A proveniência sobrevive uma camada abaixo do canon.
- **[Numeração] Aposentar D-xx → ADR-0xx (1:1).** D-01 vira ADR-001, …, D-10 vira ADR-010. O
  identificador `D-xx` some do repo; `docs/prd.md` §8 e `CLAUDE.md` passam a citar ADR-0xx.
- **[Fidelidade] Conciso mas completo.** Cada ADR traz as quatro seções
  (Contexto/Decisão/Consequências/Status), um parágrafo cada, destilado do design doc — não uma
  re-derivação nem reabertura.
- **[Dogfood] Ligar `check-adr.sh docs/adr` como backstop.** Hoje o `check-adr` só roda contra
  fixtures; com ADRs reais, roda também contra o `docs/adr/` do repo (pre-commit + CI + eval).
- **[Meta-ADR] Registrar a promoção como ADR-011.** A própria mudança de governança nasce como
  ADR (Evidência: *decisão dada* — este brainstorming).

## Fase A — os 11 ADRs

Cada arquivo `docs/adr/ADR-<n>-<slug>.md` segue o template do `zion-adr-new`:
cabeçalho (`Status: Aceito` · `Data:` a do design doc · `Decisores: autoria do repo` ·
`Evidência:` caminho do design doc de origem) + seções Contexto / Decisão / Consequências /
Status.

| ADR | Slug | Decisão (uma linha) | Data | Evidência → origem |
|---|---|---|---|---|
| ADR-001 | assets-fonte-unica | `assets/` é fonte única; `skills/*/references/` são derivados regenerados por sync (hook + guard de drift). | 2026-07-12 | 2026-07-12-auto-sync-assets-design.md |
| ADR-002 | distribuicao-dual | Distribuição dual — skills.sh e plugin do Claude Code — com autocontenção por cópia real. | 2026-07-12 | 2026-07-12-distribuicao-dual-plugin-deps-design.md |
| ADR-003 | prefixo-zion-skills | Prefixo `zion-` em todas as skills (namespace estável nos dois canais). | 2026-07-12 | 2026-07-12-zion-prefixo-skills-design.md |
| ADR-004 | verificadores-aconselham | Regras decidíveis verificadas por script que **aconselha** no projeto-alvo, nunca bloqueia o autor. | 2026-07-17 | 2026-07-17-check-prd-verificacao-mecanica-design.md |
| ADR-005 | pontes-spec-kit-prosa | Pontes para o Spec Kit montam prompts em **prosa** e param — nunca disparam `/speckit.*`. | 2026-07-13 | 2026-07-13-pontes-spec-kit-prosa-design.md |
| ADR-006 | evidencia-por-risco | Evidência de ADR proporcional ao risco: execução → spike; conhecimento → pesquisa; decisão dada → racional. | 2026-07-17 | 2026-07-17-spike-evidencia-por-risco-design.md |
| ADR-007 | contrato-superpowers | Contrato de capacidades C1–C3 com o superpowers (pin de versão + check de marcadores). | 2026-07-17 | 2026-07-17-r9-contrato-superpowers-design.md |
| ADR-008 | avaliacao-duas-camadas | Avaliação em duas camadas (mecânica no CI; julgamento sob demanda) com fixtures pareadas. | 2026-07-17 | 2026-07-17-r7-fixtures-avaliacao-harness-design.md |
| ADR-009 | unidade-spec | A unidade de trabalho chama-se **spec** (rename fatia → spec) em toda a superfície. | 2026-07-18 | 2026-07-18-rename-fatia-spec-design.md |
| ADR-010 | governanca-canon | O repo governa a si mesmo: `docs/prd.md` + `docs/architecture.md` como fontes da verdade, com guard bloqueante. | 2026-07-18 | 2026-07-18-governanca-canon-design.md |
| ADR-011 | adrs-canonicos | Promover as decisões consolidadas D-xx a ADRs reais; o canon passa a citar ADRs, não specs. | 2026-07-18 | Decisão dada: este brainstorming |

Notas de fidelidade por ADR:

- **ADR-002** — o Contexto cita também `2026-07-12-zion-build-prd-npx-skills-design.md` (empacotamento
  skills.sh), origem irmã da decisão; a Evidência (uma linha) aponta o design doc principal.
- **ADR-006** — o Contexto cita também `2026-07-18-adr-decisao-dada-design.md` (o terceiro tipo de
  evidência), que complementa o spike-por-risco; a Evidência aponta o design doc principal.
- **ADR-011** — sem spike, sem pesquisa: modo **decisão dada**. Evidência
  `Decisão dada: brainstorming 2026-07-18 (revisa a DECIDIR-3 do governanca-canon)`. Não substitui
  o ADR-010 (não o revoga — apenas muda *como* as decisões são registradas), então **não** há
  linha `Substitui:` nem supersessão simétrica.

## Fase B — `docs/architecture.md` (canon deixa de citar specs)

- **Fundir §2 + §3** numa única seção **"§2. Decisões estruturantes (ADRs)"**: a tabela
  D-xx→spec sai; entra o índice ADR-001…011 com o link para cada arquivo e a linha-resumo. Texto
  introdutório: toda decisão estruturante é um ADR aceito em `docs/adr/`; decisão nova ou reversão
  nasce como ADR novo.
- **Renumerar** as seções seguintes: §4 Scripts → §3 · §5 Fonte única → §4 · §6 Canonização → §5.
- Atualizar dentro da §5 (ex-§6) qualquer auto-referência de número de seção.

## Fase C — proveniência da spec e README do ADR

- **`docs/adr/README.md`**: remover "o histórico vive nos design docs… índice vazio no dia 1";
  passar a descrever o índice populado (ADR-001…011) e a convenção de que a Evidência de cada ADR
  retroativo aponta o design doc de origem.

## Fase D — propagação (dever de canonização, mesmo commit)

- **`docs/prd.md` §8**: trocar "decisões D-xx do `architecture.md`" por "ADRs em `docs/adr/`
  (índice na §2 do `architecture.md`)". Sem introduzir bloco de código nem termo de denylist
  (dogfood do `check-prd.sh` continua limpo).
- **`CLAUDE.md`**: "Decisões dos ADRs e D-xx não se reabrem" → "Decisões dos ADRs não se reabrem";
  ajustar os cross-refs de seção do `architecture.md` que mudaram de número (tabela de scripts §4→§3;
  ASSET_MAP §5→§4).

## Fase E — enforcement (`check-adr` como backstop)

- **`.githooks/pre-commit`**: após o `check-canon.sh`, rodar `./scripts/check-adr.sh docs/adr`
  (bloqueia se algum ADR ficar sem evidência ou com supersessão assimétrica).
- **CI (`.github/workflows/check-assets.yml`)**: passo `./scripts/check-adr.sh docs/adr` como
  backstop.
- **`scripts/eval.sh`**: sem entrada nova (o `test-check-adr.sh` já cobre a lógica do script
  contra fixtures); o backstop do repo real vive no pre-commit/CI, no mesmo molde do
  `check-canon.sh`.
- A tabela de scripts (§3/ex-§4 do `architecture.md`) **não** muda: `check-adr.sh` já está listado;
  muda só *onde* ele roda.

## Fora de escopo

- Nenhuma feature de produto nova; nenhuma skill nova; nenhuma mudança no template do
  `zion-adr-new` nem na lógica do `check-adr.sh`/`check-canon.sh`.
- Nenhuma edição à mão em `skills/*/references/` (derivados).
- Os design docs em `docs/superpowers/specs/` permanecem intocados — viram lastro histórico
  citado pelos ADRs, não pelo canon.

## Critérios de aceite (verificação)

1. `docs/adr/ADR-001…011-*.md` existem, cada um com Evidência preenchida e as quatro seções.
2. `./scripts/check-adr.sh docs/adr` limpo.
3. `docs/architecture.md` não contém mais nenhum caminho `docs/superpowers/specs/`; a §2 lista os
   11 ADRs; `check-canon.sh` C5 (ADR no índice) limpo.
4. Nenhuma ocorrência do rótulo aposentado `D-01`…`D-10` em `docs/prd.md`, `docs/architecture.md`
   e `CLAUDE.md`.
5. `./scripts/check-canon.sh` limpo · `./scripts/check-assets.sh` limpo · `./scripts/eval.sh` verde
   · `check-prd.sh prd docs/prd.md` limpo (dogfood).
6. Commit de teste violando a canonização (ex.: ADR fora do índice, ou ADR sem evidência) é
   **bloqueado** pelo pre-commit; após corrigir, o commit passa.
