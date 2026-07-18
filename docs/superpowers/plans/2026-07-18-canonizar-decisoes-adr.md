# Canonizar as decisões consolidadas em ADRs reais — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Promover as decisões consolidadas D-01…D-10 do `docs/architecture.md` a ADRs reais (ADR-001…ADR-010, 1:1) em `docs/adr/`, registrar a própria promoção como ADR-011, e fazer o canon citar os ADRs em vez das specs — com `check-adr.sh docs/adr` plugado como backstop no pre-commit e no CI.

**Architecture:** Sem código de produto novo, sem skill nova, sem mudança na lógica de `check-adr.sh`/`check-canon.sh`/`check-prd.sh`. A mudança é documental + de enforcement: (1) 11 arquivos ADR novos no padrão do `zion-adr-new`; (2) `architecture.md` funde §2+§3 num índice de ADRs e renumera §4/§5/§6 → §3/§4/§5; (3) propagação a `docs/adr/README.md`, `docs/prd.md` §8 e `CLAUDE.md`; (4) `check-adr.sh docs/adr` no `.githooks/pre-commit` e no CI. Cada commit permanece **verde** sob o pre-commit bloqueante — a ordem das tasks é escolhida para isso.

**Tech Stack:** Markdown (docs/ADRs), Bash (`.githooks/pre-commit`), GitHub Actions YAML (`.github/workflows/check-assets.yml`). Verificadores existentes: `scripts/check-canon.sh`, `scripts/check-adr.sh`, `scripts/check-prd.sh`, `scripts/check-assets.sh`, `scripts/eval.sh`.

## Global Constraints

- **Um paradigma de commit: sempre verde.** O `.githooks/pre-commit` roda `sync-assets.sh` + `check-canon.sh` (e, a partir da Task 5, `check-adr.sh docs/adr`) e **bloqueia** commit com drift. Nunca use `git commit --no-verify`. A ordem das tasks garante que cada commit passe.
- **Fronteira o-quê/como.** ADRs e `architecture.md` são a camada *como/com-quê* — menção a stack/mecanismo é permitida ali. `docs/prd.md` é *o-quê/por-quê* — o `check-prd.sh` roda como dogfood dentro do `check-canon.sh` sobre `docs/prd.md` e **deve continuar limpo**; não introduza bloco de código, comando de instalação, `import`, versão `x.y.z` nem termo de denylist ao editar a PRD.
- **Nunca edite `skills/*/references/` à mão** — são derivados regenerados pelo `sync-assets.sh` no pre-commit. Este plano não toca em nenhum asset, então nenhum `references/` deve mudar.
- **Rótulo aposentado.** Após a Task 4, `grep -nE 'D-0[0-9]|D-10' docs/prd.md docs/architecture.md CLAUDE.md` deve retornar **zero** ocorrências. (O token genérico `D-xx` — sem número — é permitido onde descreve a família aposentada, ex.: a linha-resumo do ADR-011.)
- **Formato de cabeçalho de ADR** (idêntico em todos): `- **Status:** Aceito` · `- **Data:** <a do design doc>` · `- **Decisores:** autoria do repo` · `- **Evidência:** <caminho do design doc, OU `Decisão dada: <racional>` no ADR-011>`. Seções fixas: `## Contexto` · `## Decisão` · `## Consequências` · `## Status`.
- **Nomes de arquivo canônicos** (o `check-canon.sh` C5 casa o basename literal no `architecture.md`): `ADR-001-assets-fonte-unica.md`, `ADR-002-distribuicao-dual.md`, `ADR-003-prefixo-zion-skills.md`, `ADR-004-verificadores-aconselham.md`, `ADR-005-pontes-spec-kit-prosa.md`, `ADR-006-evidencia-por-risco.md`, `ADR-007-contrato-superpowers.md`, `ADR-008-avaliacao-duas-camadas.md`, `ADR-009-unidade-spec.md`, `ADR-010-governanca-canon.md`, `ADR-011-adrs-canonicos.md`.

## File Structure

| Arquivo | Responsabilidade | Task |
|---|---|---|
| `docs/architecture.md` | Funde §2 (D-xx) + §3 (índice ADR) num único **§2. Decisões estruturantes (ADRs)** que cita só ADRs; renumera §4/§5/§6 → §3/§4/§5. | Task 1 |
| `docs/adr/ADR-001…010-*.md` (10 arquivos) | ADRs retroativos, Evidência = caminho do design doc de origem (risco de conhecimento). | Task 2 |
| `docs/adr/ADR-011-adrs-canonicos.md` | Meta-ADR da promoção; Evidência = `Decisão dada:` (este brainstorming). | Task 2 |
| `docs/adr/README.md` | Passa a descrever o índice populado (ADR-001…011) e a convenção da Evidência retroativa. | Task 3 |
| `docs/prd.md` (§8) | Troca "decisões D-xx do `architecture.md`" por "ADRs em `docs/adr/` (índice na §2)". | Task 4 |
| `CLAUDE.md` | Remove "D-xx" da linha "não se reabrem" e da descrição do architecture; corrige cross-refs de seção (§4→§3, §5→§4, §3→§2). | Task 4 |
| `.githooks/pre-commit` | Após `check-canon.sh`, roda `./scripts/check-adr.sh docs/adr`. | Task 5 |
| `.github/workflows/check-assets.yml` | Passo `./scripts/check-adr.sh docs/adr` como backstop. | Task 5 |

**Não muda:** `scripts/check-adr.sh`, `scripts/check-canon.sh`, `scripts/check-prd.sh` (lógica), `scripts/eval.sh` (sem entrada nova — o `test-check-adr.sh` já cobre a lógica contra fixtures), a tabela de scripts do `architecture.md` (o `check-adr.sh` já está listado), `assets/**`, `skills/**`, os design docs em `docs/superpowers/specs/`.

---

## Task 1: Fundir §2+§3 do `architecture.md` num índice de ADRs (canon deixa de citar specs)

**Files:**
- Modify: `docs/architecture.md:26-101` (da linha `## 2. Decisões consolidadas (D-xx)` até o fim do arquivo)

**Interfaces:**
- Consumes: nada (primeira task).
- Produces: os 11 basenames `ADR-00n-<slug>.md` citados no índice §2 — o `check-canon.sh` C5 casa cada basename literal; a Task 2 cria os arquivos correspondentes.

**Por que esta task vem primeiro:** o `check-canon.sh` C5 (`check_adr_index`) só verifica que cada ADR **existente** em `docs/adr/` está no índice — não o inverso. Com `docs/adr/` ainda sem ADRs, referenciar os 11 no índice é verde. Criar os ADRs antes do índice, ao contrário, **bloquearia** o commit (`adr-sem-indice`).

- [ ] **Step 1: Verificar o estado atual (baseline verde)**

Run: `cd /home/tuyoshi/projects/personal/zion-build-prd && ./scripts/check-canon.sh`
Expected: `check-canon: limpo` (exit 0).

- [ ] **Step 2: Substituir §2 até o fim do arquivo**

Abra `docs/architecture.md`, leia o arquivo, e substitua todo o bloco que começa em `## 2. Decisões consolidadas (D-xx)` (linha ~26) até o fim do arquivo por exatamente este conteúdo:

```markdown
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
```

- [ ] **Step 3: Confirmar que nenhum caminho de spec e nenhum rótulo D-0x sobrou**

Run: `grep -nE 'docs/superpowers/specs|D-0[0-9]|D-10' docs/architecture.md`
Expected: nenhuma saída (exit 1 do grep — zero ocorrências).

- [ ] **Step 4: Rodar o guard de canonização**

Run: `./scripts/check-canon.sh`
Expected: `check-canon: limpo` (exit 0). *(C5 passa porque `docs/adr/` ainda não tem ADR-*.md; o dogfood do check-prd sobre a PRD não mudou.)*

- [ ] **Step 5: Commit**

```bash
git add docs/architecture.md
git commit -m "docs(arch): funde §2+§3 num índice de ADRs; canon deixa de citar specs"
```

---

## Task 2: Criar os 11 ADRs em `docs/adr/`

**Files:**
- Create: `docs/adr/ADR-001-assets-fonte-unica.md` … `docs/adr/ADR-011-adrs-canonicos.md` (11 arquivos)

**Interfaces:**
- Consumes: os basenames já citados no índice §2 do `architecture.md` (Task 1).
- Produces: `docs/adr/ADR-*.md` válidos para o `check-adr.sh docs/adr` (Evidência presente; sem supersessão). ADR-001…010 usam Evidência de **conhecimento** (caminho do design doc); ADR-011 usa **decisão dada**.

**Nota de verificação do `check-adr.sh`:** para ADR-001…010, a Evidência é um caminho `docs/superpowers/specs/…-design.md` — cai no ramo "conhecimento" e satisfaz o teste `https?://|/|\.[A-Za-z0-9]+` (tem `/` e `.md`). Para ADR-011, a Evidência começa com `Decisão dada:` seguida de racional não-vazio — cai no ramo "decisão dada" e passa. Nenhum aponta `docs/adr/spikes/`, então não há spike dir a criar.

- [ ] **Step 1: Verificar que `docs/adr/` só tem README (baseline)**

Run: `ls docs/adr/`
Expected: `README.md` (nenhum `ADR-*.md` ainda).

- [ ] **Step 2: Criar `docs/adr/ADR-001-assets-fonte-unica.md`**

```markdown
# ADR-001 — Fonte única de assets com derivados sincronizados

- **Status:** Aceito
- **Data:** 2026-07-12
- **Decisores:** autoria do repo
- **Evidência:** docs/superpowers/specs/2026-07-12-auto-sync-assets-design.md

## Contexto

Os assets canônicos vivem em `assets/`, mas cada skill é autocontida e precisa carregar em `skills/<skill>/references/` uma cópia byte-idêntica dos assets que consome, porque as skills são distribuídas por dois canais incompatíveis com referências externas: o `npx skills add` (Canal A) copia cada pasta de skill isoladamente — assumindo cópia literal, sem dereferência de symlink — e o plugin do Claude Code (Canal B) consome o repositório git diretamente; assim, um symlink ou um arquivo gitignorado gerado só em publish-time quebraria, obrigando cada `references/*.md` a ser um arquivo real e commitado. Hoje a sincronização (`scripts/sync-assets.sh`) e a verificação (`scripts/check-assets.sh`) são disparadas manualmente e a lista de skills está duplicada nos dois scripts, o que é fácil de esquecer e produz drift silencioso entre o canônico e seus derivados.

## Decisão

Adotamos `assets/` como a única fonte de verdade editável por humanos e tratamos `skills/*/references/*.md` como artefatos derivados byte-idênticos, regenerados automaticamente — descartando explicitamente a alternativa de arquivo físico único (inviável pelos dois canais de distribuição) e o watcher de editor ou geração em publish-time (YAGNI): o mapeamento asset→skills é centralizado em um manifesto único `scripts/asset-map.sh` (sourced por ambos os scripts e pelo hook, eliminando a duplicação), um pre-commit hook versionado em `.githooks/pre-commit` (ativado via `git config core.hooksPath .githooks` pelo bootstrap idempotente `scripts/setup-hooks.sh`) roda `sync-assets.sh` incondicionalmente e faz `git add` dos references para o commit já sair consistente sob `set -euo pipefail`, e um CI guard (`.github/workflows/check-assets.yml`) roda `check-assets.sh` em push e pull_request como defesa em profundidade, sem banner "generated" nos derivados para não quebrar o `diff` do check.

## Consequências

O desenvolvedor deixa de sincronizar assets à mão — editar um asset e commitar regenera e faz stage de todos os references automaticamente — e adicionar uma skill nova passa a ser uma única edição no `ASSET_MAP`; commits que não tocam `assets/` permanecem no-op (nem `cp` de arquivo idêntico nem `git add` de arquivo inalterado geram ruído), e o CI cobre quem usou `git commit --no-verify`, quem nunca rodou o bootstrap ou contribuidores externos, falhando com a mensagem acionável já existente (`rode scripts/sync-assets.sh`). Em troca, aceita-se manter cópias físicas duplicadas na árvore versionada (não há fonte única literal, apenas "no espírito"), depender de um bootstrap manual de hooks por clone tendo o CI como backstop, e tratar os `references/` como saída gerada que nunca deve ser editada diretamente — limite documentado na seção Desenvolvimento do README.

## Status

Aceito.
```

- [ ] **Step 3: Criar `docs/adr/ADR-002-distribuicao-dual.md`**

```markdown
# ADR-002 — Distribuição dual com autocontenção por cópia

- **Status:** Aceito
- **Data:** 2026-07-12
- **Decisores:** autoria do repo
- **Evidência:** docs/superpowers/specs/2026-07-12-distribuicao-dual-plugin-deps-design.md

## Contexto

O repositório `zion-build-prd` já vinha empacotado no padrão comunitário `npx skills` (skills.sh) — origem detalhada no doc irmão `2026-07-12-zion-build-prd-npx-skills-design.md`, que estabeleceu a árvore única `skills/<name>/SKILL.md`, a fonte canônica em `assets/` sincronizada para o `references/` de cada skill (via `sync-assets.sh`/`check-assets.sh`) e a autocontenção por caminho relativo que permite `npx skills add owner/repo` sem setup. Sobre essa base surgiu a necessidade de entregar o mesmo repositório em dois formatos simultâneos e sem duplicar arquivos — (A) `npx skills`/skills.sh e (B) plugin + marketplace do Claude Code — com o objetivo central de garantir que as dependências das skills sejam resolvidas automaticamente na instalação via plugin (B), sabendo que o skills.sh (A) não possui mecanismo algum de dependência. A auditoria das skills revelou que, após tratar os casos internos, a única dependência externa que exige resolução é `superpowers:brainstorming` (publicada em `obra/superpowers-marketplace`), pois `zion-rewrite-prompt` é skill pessoal não publicada e `deep-research` é built-in do harness sem fonte em disco.

## Decisão

Adotar distribuição dual sobre uma única árvore `skills/` ("uma árvore, dois porteiros"): o `npx skills` lê `skills/*/SKILL.md` direto e o plugin lê os manifestos em `.claude-plugin/`, com zero duplicação por formato. A autocontenção se faz por cópia real — `zion-rewrite-prompt` é vendorizada como 8ª skill first-party (cópia verbatim, `metadata.author: zion-build-prd`, sob a licença MIT do repo, resolvida por nome sem mudança de caminho nas pontes que a invocam); `deep-research` não é vendorizada (built-in sem fonte) e passa a degradar graciosamente em `zion-prd-spike`; e `superpowers` é declarada como dependência cross-marketplace no `plugin.json` (sem pin de versão) mais `allowCrossMarketplaceDependenciesOn` no `marketplace.json` para (B), somada a garantia defensiva dupla em (A) via preflight advisory nas três skills que a usam (discovery, decompose, write) e seção Dependências no README. Ficaram descartadas: vendorizar `deep-research` (fabricar sem fonte), pinar a versão do `superpowers` (YAGNI), auto-registrar o marketplace no install (impossível pela doc — só o consumidor adiciona marketplaces), redistribuir o Spec Kit e renomear slash-commands.

## Consequências

A garantia entregue é honesta e assimétrica entre formatos. No plugin (B), a dependência `superpowers` é imposta pelo próprio Claude Code: o install não falha em silêncio, mas bloqueia com erro acionável `dependency-unsatisfied` (mostra o comando exato) quando o marketplace-raiz não está registrado localmente por nome, e resolve automaticamente por auto-instalação transitiva assim que `/plugin marketplace add obra/superpowers-marketplace` foi feito — ou seja, não é 100% zero-setup (exige o pré-requisito de uma linha), mas é enforced em vez de quebrar em runtime; `zion-rewrite-prompt` e `zion-adr-new` viajam no próprio plugin e `deep-research` é built-in. No `npx skills` (A) não há resolução automática alguma, então a lacuna é coberta apenas defensivamente por preflight que avisa e para graciosamente mais o README, aceitando que o consumidor instale o `superpowers` manualmente. A vendorização por cópia mantém os scripts de sync inalterados (a 8ª skill não usa assets canônicos), ao custo de assumir a responsabilidade de manter a cópia alinhada à origem, e o Spec Kit permanece fora de escopo — as pontes só emitem prompts.

## Status

Aceito.
```

- [ ] **Step 4: Criar `docs/adr/ADR-003-prefixo-zion-skills.md`**

```markdown
# ADR-003 — Prefixo zion- em todas as skills

- **Status:** Aceito
- **Data:** 2026-07-12
- **Decisores:** autoria do repo
- **Evidência:** docs/superpowers/specs/2026-07-12-zion-prefixo-skills-design.md

## Contexto

As 8 skills internas do harness Zion Build PRD (`prd-discovery`, `prd-spike`, `prd-write`, `prd-decompose`, `prd-constitution-prompt`, `prd-specify-prompt`, `adr-new` e a utilitária `rewrite-prompt`) tinham nomes genéricos sem namespace próprio, o que as tornava indistintas de skills externas do ecossistema (`superpowers:brainstorming`, `deep-research` built-in do Claude Code, `/speckit.*` do Spec Kit) e frágeis quanto à identidade de marca, ainda que o plugin/marketplace já se chamasse `zion-build-prd`. Buscava-se uma identidade de nomes estável e reconhecível para todas as skills do território do harness, aplicada de forma orgânica em diretórios, corpos de `SKILL.md`, assets canônicos, scripts, guias vivos (README, guia-prd-para-spec-kit, como-usar) e no conteúdo do histórico de design, sem regredir a semântica de processo já validada.

## Decisão

Prefixar `zion-` nas 8 skills do harness (`prd-discovery` → `zion-prd-discovery`, e assim por diante, incluindo `adr-new` e a genérica `rewrite-prompt`), consolidando um namespace estável e coerente com a marca do plugin em ambos os canais (diretórios/`name:` das skills e todas as citações em guias, assets e histórico), via `git mv` das pastas para preservar histórico e reescrita disciplinada de cada `SKILL.md` pela metodologia do skill-creator (`description` mais "pushy" com "quando usar", estrutura imperativa, progressive disclosure) mantendo como invariantes fixos o contrato de 5 fases, os gates que aconselham sem bloquear, os preflights de dependência e a guarda de fronteira o-quê/como; o grafo de referências cruzadas, os assets (`process-context.md`, `prd-skeleton.md`) e o `scripts/asset-map.sh` são atualizados, com os `references/` regenerados por `sync-assets.sh`. Foram descartados: renomear tokens externos (`superpowers`, `deep-research`, `speckit`) e o próprio plugin/marketplace `zion-build-prd`, que já é a marca e permanece; renomear os arquivos do histórico de design (identidade é data+tema, renomear quebraria links sem agregar, então apenas o conteúdo muda); e a substituição global cega por `sed`, preterida por edição arquivo a arquivo dos 8 tokens exatos com negative lookbehind de `zion-` para nunca duplo-prefixar.

## Consequências

Ganha-se um namespace único e alinhado à marca, com histórico Git preservado nas pastas e semântica de processo intacta, ao custo de uma superfície ampla de edição sincronizada (README, guias com 9 e 41 ocorrências, assets, scripts, specs/plans) e de riscos de substituição que exigem disciplina: falsos-positivos porque `zion-build-prd` contém `prd` e `prd-spike-descoberta` contém `prd-spike`, e o perigo de duplo-prefixar ou tocar tokens externos, mitigados por substituição limitada aos 8 tokens exatos com lookbehind/boundaries e verificação manual. O drift entre assets e `references/` é contido rodando `sync-assets.sh` seguido de `check-assets.sh` (deve passar verde), com validação final por grep confirmando zero tokens de skill sem prefixo remanescentes (fora de `zion-build-prd` e dos `zion-*` legítimos) e inspeção de que `superpowers`/`deep-research`/nome-do-plugin permaneceram e as 8 pastas `skills/zion-*/` têm `name:` coerente; fica explicitamente fora de escopo alterar fases/gates/fronteira, renomear o plugin ou dependências externas e renomear arquivos do histórico.

## Status

Aceito.
```

- [ ] **Step 5: Criar `docs/adr/ADR-004-verificadores-aconselham.md`**

```markdown
# ADR-004 — Verificadores aconselham no projeto-alvo

- **Status:** Aceito
- **Data:** 2026-07-17
- **Decisores:** autoria do repo
- **Evidência:** docs/superpowers/specs/2026-07-17-check-prd-verificacao-mecanica-design.md

## Contexto

O harness Zion Build PRD define regras genuinamente decidíveis em `assets/quality-rules.md` — zero stack na PRD e no specify, todo NFR com número, cada RF-xx agrupado por épico — mas delega **toda** a verificação à Fase 4 de cada skill, ou seja, a prosa interpretada pelo mesmo LLM que acabou de escrever o artefato. A falha previsível se materializou no único projeto que usou o método ponta-a-ponta: "React Flow" vazou para a PRD real (`zion-mermaid-editor-app/docs/PRD.md:220`) e nenhum gate apontou, embora um simples `grep` contra a denylist da própria fronteira o pegasse. A ironia é que o repositório já possui o padrão certo de enforcement mecânico (`scripts/check-assets.sh` + hook + CI), porém só para proteger os assets do harness, não para executar as regras de qualidade que justificam sua existência — e a falha real ocorre no projeto *consumidor*, que não tem este repo, logo o check precisa viajar junto e rodar lá.

## Decisão

Adotar um verificador em shell, `scripts/check-prd.sh`, que executa mecanicamente as três regras decidíveis da R1 contra os artefatos reais e **aconselha no projeto-alvo** sem nunca bloquear o autor: o script apenas verifica (exit `0` limpo / `1` com achados ancorados em `arquivo:linha`), enquanto o humano decide — quem lê o exit code é a Fase 4 das skills `zion-prd-write` (`check-prd.sh prd docs/PRD.md`) e `zion-prd-specify-prompt` (`check-prd.sh specify -` via stdin), que reporta o veredito com autoridade mas não reverte. A detecção é híbrida (denylist curada, case-insensitive, encodada num bloco cercado `denylist` de fonte única no `quality-rules.md`, mais sinais estruturais de alta precisão: blocos de código, `npm/pip/yarn`, `import`, versão `x.y.z`); a distribuição reaproveita o padrão já existente — canônico em `scripts/`, sincronizado para `references/` via `asset-map.sh`/`sync-assets.sh`, vigiado por `check-assets.sh` e regenerado pelo hook. Foram conscientemente descartadas: a supressão inline de falso-positivo e o bloqueio/exit gate (YAGNI — só importariam se o gate barrasse; o humano descarta um falso-positivo na hora); tratamento especial da seção 8 de ADRs (um nome de stack ali É o vazamento a expor); e, como plano B caso o `npx skills` não empacote `references/*.sh`, embutir o script no `SKILL.md` via heredoc.

## Consequências

O harness passa a aplicar às próprias regras de qualidade o enforcement mecânico que já usava para os assets, com baixo falso-positivo e achados que apontam a linha exata, mantendo a filosofia "gates aconselham, não bloqueiam"; a arquitetura de funções de check independentes com dispatch por modo deixa R4 (RF↔FR) e outras regras plugarem depois sem retrabalho, e cada fixture do auto-teste (`test-check-prd.sh` + `fixtures/`, mais um job de CI) já é metade de uma futura fixture de avaliação da R7. Os limites conhecidos e assumidos: continua fora de escopo a supressão inline, o bloqueio de fluxo, a regra R4, o hook/CI dentro do projeto consumidor e a suíte completa de avaliação (R7, da qual só entra a semente de fixtures); a robustez depende de curar bem a denylist e resta o ponto de verificação explícito sobre o empacotamento de `references/*.sh` pelo `npx skills`, com o heredoc no `SKILL.md` como contingência.

## Status

Aceito.
```

- [ ] **Step 6: Criar `docs/adr/ADR-005-pontes-spec-kit-prosa.md`**

```markdown
# ADR-005 — Pontes para o Spec Kit montam prompts em prosa

- **Status:** Aceito
- **Data:** 2026-07-13
- **Decisores:** autoria do repo
- **Evidência:** docs/superpowers/specs/2026-07-13-pontes-spec-kit-prosa-design.md

## Contexto

As três pontes do harness para o Spec Kit — `zion-prd-constitution-prompt`, `zion-prd-specify-prompt` e `zion-prd-plan-prompt` — delegavam a montagem final do prompt à skill `zion-rewrite-prompt`, que embrulhava o texto em um esqueleto XML (`<context>`, `<constraints>`, `<instructions>`, `<success_criteria>`), produzindo saídas como `/speckit.constitution "<context>…</context>…"`. Isso conflitava com dois pontos: o requisito do usuário de remover a skill `zion-rewrite-prompt`, fazer cada ponte assumir o próprio escopo sem delegar e não impor formato de saída (o `/speckit.*` já define o formato do artefato); e a pesquisa no repositório `github/spec-kit` (README, `spec-driven.md`, templates de comando e de artefato), que evidenciou que cada comando carrega um template pré-escrito e apenas preenche placeholders — logo o prompt do usuário é conteúdo, não formato — e que todos os exemplos oficiais são prosa em linguagem natural, sem tags XML. Manter o XML e remover a skill seria contraditório.

## Decisão

Cada ponte, nas Fases 2/3, passa a montar ela mesma o prompt do `/speckit.*` correspondente em prosa (linguagem natural), como conteúdo e não formato, sem delegar ao `zion-rewrite-prompt` (skill removida por inteiro), sem tags XML e sem ditar a estrutura do artefato, transformando as guardas de cada etapa em conteúdo em prosa: `constitution` deriva princípios decidíveis/testáveis e rastreáveis dos NFRs e ADRs, sem genéricos; `specify` descreve o o-quê/por-quê com resultado observável e blindagem sem-stack; `plan` fornece o como honrando os ADRs confirmados sem reabri-los; preservam-se o contrato de fases 0/1/4, a fronteira o-quê/como (só `plan` a cruza, presa aos ADRs) e o handoff no qual a ponte entrega o comando pronto e PARA — nenhuma ponte dispara `/speckit.*`. A alternativa de manter internamente o esqueleto XML cortando apenas a delegação foi considerada e descartada, porque tanto a pesquisa quanto as restrições do usuário apontam para prosa e o XML é justamente o que o Spec Kit não espera na entrada.

## Consequências

Os prompts gerados ficam alinhados à convenção oficial do Spec Kit (prosa, conteúdo em vez de formato), copiáveis e executáveis diretamente na skill correspondente, e o harness perde uma dependência inteira (`zion-rewrite-prompt`), simplificando a superfície de skills para 8; em contrapartida, exige reescrever as três âncoras `#anatomia-*` em `assets/quality-rules.md` (removendo a moldura XML e o auto-delegar, descrevendo o conteúdo de cada prompt e a nota de idioma) e propagar a mudança via `sync-assets.sh`/`check-assets.sh` para as skills e guias vivos (`README.md`, `docs/como-usar.md`, `docs/guia-prd-para-spec-kit.md`), enquanto os specs/plans datados permanecem intactos como registro histórico. O trade-off assumido é que a qualidade e a consistência de cada prompt deixam de ser garantidas por um wrapper central e passam a depender de cada ponte seguir fielmente sua âncora em prosa; a fronteira sem-stack no `specify` e o honrar-ADRs no `plan` continuam sendo guardas verificáveis, e a verificação inclui zero ocorrências de `zion-rewrite-prompt`, ausência de XML nos exemplos e ausência de drift de assets.

## Status

Aceito.
```

- [ ] **Step 7: Criar `docs/adr/ADR-006-evidencia-por-risco.md`**

```markdown
# ADR-006 — Evidência de ADR proporcional ao risco

- **Status:** Aceito
- **Data:** 2026-07-17
- **Decisores:** autoria do repo
- **Evidência:** docs/superpowers/specs/2026-07-17-spike-evidencia-por-risco-design.md

## Contexto

O Estágio 2 do harness carregava uma contradição embarcada: o guia prometia responder às 2–3 decisões estruturantes com "código descartável (não com opinião)" e cobrava, na Fase 4, um "spike real que você de fato rodou", mas a skill `/zion-prd-spike` apenas levantava trade-offs via `deep-research` e registrava o ADR — nunca produzia código. No único projeto que usou o método ponta-a-ponta, só 1 dos 4 ADRs tinha spike de código real; os demais rotulavam execuções de pesquisa como "spike", exatamente a "opinião com citações" que o guia dizia evitar — teatro de conformidade. Como a própria crítica registra que o elo spike→ADR é síntese do zion, sem respaldo canônico, cabia dimensioná-lo em vez de mantê-lo como dogma. Este ADR complementa-se com o doc irmão `2026-07-18-adr-decisao-dada-design.md`, que introduz um terceiro tipo de risco — a "decisão dada" (a escolha que já chega batida de fora, sustentada pela autoridade de quem a tomou) — fechando o vocabulário de riscos aberto aqui.

## Decisão

A evidência de cada ADR passa a ser proporcional ao risco da decisão, com o tipo de risco escolhendo o meio da evidência: risco de execução (a dúvida só se resolve rodando algo) exige spike de código descartável em `docs/adr/spikes/ADR-00x-<slug>/` com `README.md` obrigatório (pergunta + o que foi rodado + veredito); risco de conhecimento (trade-off documentável sem rodar) exige pesquisa com fonte citada (URL ou caminho de artefato); e o risco de decisão dada exige racional escrito no próprio ADR (quem/que autoridade decidiu e por quê). O ADR ganha um campo obrigatório `Evidência`, a Fase 1 da skill classifica cada decisão por uma heurística decidível ancorada em `#risco-do-spike` (skill propõe, usuário confirma), e a presença — não a qualidade — do lastro é verificada mecanicamente por um novo `scripts/check-adr.sh`, no mesmo molde de `check-prd.sh`/`trace-prd.sh` (fixtures, auto-teste, sync via `asset-map.sh`, passo no CI). Descartaram-se o "código sempre" (força código onde o risco é de conhecimento), o "pesquisa sempre" (o teatro atual), estender o `check-prd.sh` em vez de um script próprio (preocupações distintas) e o bloqueio por gate (mantém-se advisório).

## Consequências

O harness deixa de mentir sobre rigor: fecha as fragilidades F1/H5 fazendo a promessa casar com o mecanismo, correlaciona ADR↔spike automaticamente pelo número/slug (sem elo manual a quebrar) e mantém a filosofia advisória (exit `0`/`1`/`2`; a Fase 4 ecoa o veredito com autoridade mas não reverte). Em contrapartida, o verificador confere apenas presença do lastro apontável, não a qualidade do spike ou da fonte — o julgamento fica com a Fase 4/humano; a classificação de risco depende da confirmação do usuário e pode ser mal-calibrada; e ficam conscientemente fora de escopo a auditoria retroativa de ADRs antigos (território de H8/R8), a colisão de nome "spike" com o S de SPIDR, o bloqueio por gate e a suíte completa de avaliação do harness (entra só a semente de fixtures do `check-adr`).

## Status

Aceito.
```

- [ ] **Step 8: Criar `docs/adr/ADR-007-contrato-superpowers.md`**

```markdown
# ADR-007 — Contrato de capacidades C1–C3 com o superpowers

- **Status:** Aceito
- **Data:** 2026-07-17
- **Decisores:** autoria do repo
- **Evidência:** docs/superpowers/specs/2026-07-17-r9-contrato-superpowers-design.md

## Contexto

A skill `superpowers:brainstorming` é o executor de três dos quatro estágios criativos do harness (discovery, write, decompose), mas o contrato entre harness e brainstorming era implícito: espera-se que a skill aceite um enquadramento fixo e grave um arquivo no caminho nomeado, sem pin de versão nem teste de contrato (gap H4 da crítica). O preflight de cada estágio cobria apenas a ausência da skill, não a mudança de comportamento, de modo que uma atualização do superpowers poderia degradar silenciosamente os três estágios centrais sem que nada acusasse. O risco era real e não hipotético — havia duas versões em cache (5.0.7 e 6.1.1, um major bump) e a dependência em `plugin.json` não tinha pin; o major bump chegou a ocorrer e só não quebrou por sorte, já que a única mudança relevante foi o timing da oferta do visual companion. O princípio norteador, herdado de R1/R7 e do padrão assets→references, é mover o invariante de prosa para máquina e trocar a promessa sem mecanismo por uma promessa menor com mecanismo.

## Decisão

Estabelecer um contrato explícito de três capacidades que o harness efetivamente consome do brainstorming — C1: aceitar um enquadramento fixo e refinar ideia em design; C2: gravar o resultado num arquivo cujo caminho nomeamos (sob `docs/`); C3: conduzir diálogo seção a seção / uma pergunta por vez — verificado por dois mecanismos complementares e pareados. Primeiro, um pin semver hard no `plugin.json` (`"version": ">=5 <7"`), que trava a dependência aos dois majors testados e transforma um upstream fora do range em erro visível no load time, não em degradação silenciosa. Segundo, um check estático (`check-superpowers-contract.sh`) que faz grep de marcadores de capacidade tolerantes a reescrita no `SKILL.md` instalado — C1 e C3 satisfeitas por qualquer marcador alternante (OR), C2 exigindo os dois marcadores juntos (escreve doc ∧ caminho sob `docs/`) — rodando apenas na suíte `eval.sh` e coberto por um auto-teste com fixtures (`clean` → exit 0, `drift-c2` → exit 1 citando C2). O contrato vive como asset único em `assets/superpowers-contract.md`, sincronizado para as `references/` das três skills dependentes. Foram descartadas: testar a execução real da skill (é interativa/socrática, não roda headless — daí a opção pela checagem estática análoga ao `check-assets`); rodar o check na Fase 0 (introduziria atrito no uso normal, sendo o drift um problema de manutenção/upgrade); falhar com exit 1 quando o superpowers não é encontrado (quebraria sempre o CI do repo, que não tem o plugin); e checar marcadores fora de escopo como "writing-plans terminal" ou "spec self-review", que virariam ruído a cada refraseado.

## Consequências

O drift dos três estágios centrais passa a ser detectável e o pin torna qualquer major não testado um erro explícito no carregamento, ao custo de manutenção deliberadamente contida (duas fixtures em vez de uma por capacidade, marcadores mínimos de capacidade em vez de diff de frase). A limitação conhecida mais importante é a degradação graciosa: quando nada é localizado, o check emite aviso de "não verificável" e sai 0, de modo que rodar `eval.sh` sem o superpowers instalado — como no CI do repo — não acusa R9; a proteção real depende de rodar no ambiente de quem faz o upgrade, e no CI a lógica é garantida apenas pelo auto-teste contra fixtures. Havendo múltiplas versões em cache, vence a maior (`sort -V`), coerente com o load-time do Claude Code, e o runbook de drift orienta a atualizar o marcador quando a capacidade muda de forma mas persiste, e a não alargar o pin quando ela realmente some. R9 não altera a Fase 0 das skills, não adiciona ritual de revisão humana (F3/R6) e não resolve a retomada da Fase 4 após o brainstorming (H3) — entrega apenas o contrato, o teste e o pin.

## Status

Aceito.
```

- [ ] **Step 9: Criar `docs/adr/ADR-008-avaliacao-duas-camadas.md`**

```markdown
# ADR-008 — Avaliação em duas camadas

- **Status:** Aceito
- **Data:** 2026-07-17
- **Decisores:** autoria do repo
- **Evidência:** docs/superpowers/specs/2026-07-17-r7-fixtures-avaliacao-harness-design.md

## Contexto

O harness não possuía suíte de avaliação de si mesmo (defeito H2): editar `assets/quality-rules.md`, o ponto único de afinação, era mexer às cegas, sem fixture que confirmasse que a Fase 4 do `write` acusa vazamento conhecido ou que o `decompose` reprova uma fatia horizontal. Cerca de metade das regras decidíveis já tinha verificador mecânico (R1 `check-prd.sh`, R2 `trace-prd.sh`, R3 `check-adr.sh`), cada um com fixtures e um `test-*.sh` no CI, mas essas peças estavam espalhadas e cobriam apenas o que é script-verificável; os vereditos que dependem de julgamento do LLM — fatia horizontal, vazamento de tela/aceite fora da denylist, ausência de "não faz" — não tinham nenhuma rede de proteção.

## Decisão

Adotar uma suíte de avaliação de duas camadas com um ponto de entrada unificado: (1) a camada mecânica determinística, já ~90% pronta, consolidada num runner único `scripts/eval.sh` que roda os três self-tests existentes e emite veredito agregado (sai não-zero se qualquer um falhar), rodada no CI a cada push sem nenhuma fixture mecânica nova; e (2) uma camada LLM não-determinística, rodada sob demanda e nunca no CI, com seis fixtures em `scripts/fixtures/skills/` (discovery/write/decompose) onde cada caso é um artefato com defeito plantado exercitado pela lente de validação (Fase 4) da skill e comparado a um sidecar `esperado.md` de frontmatter legível por máquina, sempre com um par `limpa` (entrada boa → aprova) como guarda contra falso-positivo. O julgamento manual segue um roteiro documentado em `docs/avaliacao-harness.md` (as duas camadas, como rodar cada uma, índice de fixtures e interpretação por taxa de acerto), incluindo um procedimento opcional de runner por agentes (subagente por caso + agente-juiz). Foram descartadas as opções de transformar o runner numa skill nova `/zion-prd-eval` e de implementá-lo como script Workflow, ambas adiadas para promoção futura sem reescrita de fixtures; ficaram fora (YAGNI) cobrir as três pontes na camada LLM, rodar a camada LLM no CI, adicionar fixtures mecânicas novas e pinar o superpowers (R9).

## Consequências

A suíte fecha o gap H2 sobre o julgamento das skills criativas com custo de manutenção mínimo — na v1 a camada LLM é só prosa e fixtures, zero superfície de código nova além do `eval.sh`, e o contrato `esperado.md` já serve tanto ao modo manual quanto a uma futura skill `/zion-prd-eval`. Em troca, aceita-se que a camada LLM é não-determinística, custa token, roda apenas sob demanda e reporta taxa de acerto (não verde/vermelho binário), de modo que um erro isolado dispara investigação — mudou a skill, o `quality-rules` derivou ou a fixture está ambígua? — em vez de reprovar o harness; o caso `write/vazamento-tela-aceite` planta de propósito um defeito que o `check-prd.sh` não captura, marcando a fronteira da zona cinzenta entre script e julgamento. Limites conhecidos: matriz de fixtures das três pontes (constitution/specify/plan) fica para v2, a validação de entrega é manual única sobre as seis fixtures, e um `esperado.md` malformado é tratado como erro de suíte, não como falha da skill.

## Status

Aceito.
```

- [ ] **Step 10: Criar `docs/adr/ADR-009-unidade-spec.md`**

```markdown
# ADR-009 — A unidade de trabalho chama-se spec

- **Status:** Aceito
- **Data:** 2026-07-18
- **Decisores:** autoria do repo
- **Evidência:** docs/superpowers/specs/2026-07-18-rename-fatia-spec-design.md

## Contexto

O harness carregava três nomes para granularidades vizinhas — "fatia" (a unidade vertical do backlog), "épico" (agrupador de RFs) e "spec" (o artefato do Spec Kit) —, e como cada fatia vira exatamente uma spec no Spec Kit (o slug da fatia já é o nome da pasta `specs/###-<slug>` e da branch), manter dois nomes para a mesma unidade gerava atrito de vocabulário; o escopo foi confirmado com o usuário no sentido de renomear apenas "fatia", preservando "épico", que ocupa outra granularidade ao agrupar RFs na §6 e conter várias specs (hierarquia RF → épico → spec).

## Decisão

A unidade de trabalho passa a chamar-se **spec** (feminino, "a spec"), convergindo com a nomenclatura do Spec Kit e consolidando a hierarquia RF → épico → spec em toda a superfície: o verbo permanece ("fatiar", "fatiamento", "refatiar" seguem nomeando o ato de cortar por INVEST/SPIDR), a migração é total e sem retrocompatibilidade (o parser do `trace-backlog.sh` só aceita o formato novo, casando coluna humana por `slug` e coluna de máquina por `pasta`), o backlog canônico troca `Fatia (slug)`→`Spec (slug)` e a coluna de máquina `Spec`→`Pasta` para eliminar colisão, a legenda `◐ em spec`→`◐ em especificação`, e a renomeação percorre assets canônicos, as 9 SKILL.md zion, docs, README, fixtures e testes, com desambiguação frente ao Spec Kit ("spec" = unidade; "`spec.md`" e "pasta `specs/###-<slug>`" = seus artefatos); foram descartadas as opções de manter os dois nomes (o problema original), renomear também "épico" (fora de granularidade) e oferecer retrocompatibilidade no parser (rejeitada explicitamente pelo usuário).

## Consequências

O vocabulário fica alinhado ao Spec Kit e sem duplicidade, ao custo de uma quebra deliberada: backlogs existentes deixam de ser reconhecidos pelo parser e exigem migração manual (renomear dois cabeçalhos, uma linha cada), documentada em `docs/como-usar.md`; ficam intocados o histórico datado (`plans/*`, `specs/*`, críticas e avaliações), o `trace-prd.sh` e a tabela §12 (já usam `Feature / Spec`), os nomes de diretórios de fixture de teste (apenas seu conteúdo muda se citar a unidade) e o conceito e nome "épico", com validação garantida por `test-trace-backlog.sh`, `test-check-prd.sh` e `check-assets.sh` verdes e por grep final assegurando que "fatia" só sobrevive como verbo/ato, nunca como substantivo da unidade.

## Status

Aceito.
```

- [ ] **Step 11: Criar `docs/adr/ADR-010-governanca-canon.md`**

```markdown
# ADR-010 — O repo governa a si mesmo

- **Status:** Aceito
- **Data:** 2026-07-18
- **Decisores:** autoria do repo
- **Evidência:** docs/superpowers/specs/2026-07-18-governanca-canon-design.md

## Contexto

O zion-build-prd já governa sua *distribuição* (assets → references, drift-guard, CI), mas não governa a si mesmo como **produto**: falta um documento que declare o que o harness faz e não-faz (requisitos) e outro que consolide a arquitetura adotada. Consequentemente, agents que abrem o repo para escrever specs ou planos não encontram uma fonte da verdade a ler, e mudanças de comportamento não têm para onde ser canonizadas — o histórico das decisões fica disperso em `docs/superpowers/specs/`, sem elo legível por máquina entre skills/scripts entregues e o que está documentado.

## Decisão

O repo passa a governar a si mesmo por dogfood total, elegendo **`docs/prd.md`** (o-quê/por-quê) e **`docs/architecture.md`** (como/com-quê) como as duas únicas fontes da verdade de governança: a PRD segue o próprio `assets/templates/prd-skeleton.md` sem stack (rodando limpo no `check-prd.sh`), com épicos E1–E6 e a §12 como tabela RF → épico → artefato; a architecture consolida a visão, as decisões estruturantes já tomadas (uma linha + link para o design doc, sem reabrir), o índice de ADRs, a tabela de scripts e a regra de canonização. Um `CLAUDE.md` na raiz (com `AGENTS.md` como symlink) declara esses dois docs como leitura obrigatória e impõe o dever de canonizar toda mudança de comportamento/estrutura de volta a eles **no mesmo commit**. O elo é fechado por um guard mecânico e **bloqueante**, `scripts/check-canon.sh` (achados C1–C7: skill-sem-rf, skill-fantasma, script-sem-doc, asset-sem-doc, adr-sem-indice, regra-raiz-sem-sot e dogfood delegando ao check-prd), escrito por TDD com fixtures clean/dirty, plugado no `eval.sh`, no pre-commit (após o sync) e no CI como backstop — mesmo rigor do CI de assets, e sem entrar no ASSET_MAP porque governa este repo em vez de ser distribuído. Descartou-se, por atrito, um guard de canonização por toque de arquivo (o elo escolhido é estrutural e decidível); descartou-se também deletar ou reescrever a documentação existente — `avaliacao-harness.md`, `como-usar.md` e `guia-prd-para-spec-kit.md` apenas migram (git mv) para `docs/guias/` com nota curta, intocados.

## Consequências

O repo ganha fonte da verdade única e legível por máquina, e esquecer de canonizar (por exemplo, adicionar uma skill sem RF correspondente) passa a bloquear o commit localmente e no CI, garantindo que PRD, architecture e o código entregue não divirjam; o custo é o rigor assimétrico — diferente dos gates dos projetos-alvo, que apenas aconselham, aqui o guard é blocking, exigindo disciplina de refletir cada mudança no mesmo commit. Os limites conhecidos são deliberados: nenhuma feature de produto nova, nenhuma dependência nova, nenhuma edição manual em `skills/*/references/` (derivados de assets) e nenhuma decisão passada reaberta; o `check-canon.sh` degrada em silêncio quando um ROOT de fixture não tem asset-map (como o `check-prd.sh` faz com `docs/adr/`).

## Status

Aceito.
```

- [ ] **Step 12: Criar `docs/adr/ADR-011-adrs-canonicos.md`** (meta-ADR, modo decisão dada)

```markdown
# ADR-011 — Promover as decisões consolidadas a ADRs reais

- **Status:** Aceito
- **Data:** 2026-07-18
- **Decisores:** autoria do repo
- **Evidência:** Decisão dada: brainstorming 2026-07-18 (revisa a DECIDIR-3 do governanca-canon)

## Contexto

A governança do dia 1 (ADR-010 / governanca-canon) consolidou as decisões estruturantes já tomadas como a tabela D-01…D-10 na §2 do `docs/architecture.md`, cada linha apontando o design doc de origem em `docs/superpowers/specs/`, e deixou `docs/adr/` vazio (só README), reservado para decisões futuras via `/zion-adr-new`. A consequência é que a fonte da verdade de arquitetura referencia as specs para lastrear cada decisão, e o padrão de ADR que o próprio harness adota e cobra (via `/zion-adr-new` + `check-adr.sh`) não é dogfoodado nas suas próprias decisões estruturantes. Esta é uma revisão da DECIDIR-3 do `governanca-canon`, registrada — coerente com a regra "mudar de decisão é ADR novo" — como decisão dada, sem spike nem pesquisa: o lastro é este próprio brainstorming.

## Decisão

Promover D-01…D-10 a ADRs reais em `docs/adr/` (ADR-001…ADR-010, mapeamento 1:1), no padrão do `zion-adr-new`, e transformar a §2 do `architecture.md` num índice que cita apenas os ADRs — o canon deixa de referenciar as specs. A proveniência desce uma camada: dentro de cada ADR retroativo, o campo Evidência é do tipo *conhecimento* e aponta o design doc de origem (`docs/superpowers/specs/<origem>-design.md`), reconhecido pelo `check-adr.sh`. Esta própria promoção nasce como ADR-011 (decisão dada). Preterido: manter a tabela D-xx→spec com `docs/adr/` vazio (o estado que esta decisão revisa). Como ADR-011 não revoga o ADR-010 — apenas muda *como* as decisões são registradas — não há linha `Substitui:` nem supersessão simétrica.

## Consequências

O harness passa a dogfoodar o próprio padrão de ADR nas suas decisões estruturantes, e o `check-adr.sh docs/adr` entra como backstop no pre-commit e no CI (além dos fixtures), fechando o elo entre a regra e a prática. O identificador `D-xx` some do repo — `docs/prd.md` §8 e `CLAUDE.md` passam a citar ADR-0xx. Aceita-se o trade-off de que a proveniência histórica agora vive dentro de cada ADR (uma camada abaixo do canon), e não mais na fonte da verdade de arquitetura; os design docs em `docs/superpowers/specs/` permanecem intocados como lastro citado pelos ADRs. Limite conhecido: os ADRs retroativos são destilações concisas dos design docs, não re-derivações — a decisão em si não se reabre.

## Status

Aceito.
```

- [ ] **Step 13: Rodar o verificador de ADRs manualmente (ainda não plugado no hook)**

Run: `./scripts/check-adr.sh docs/adr`
Expected: `check-adr: limpo` (exit 0). *(Confirma que os 11 ADRs têm Evidência válida e nenhuma supersessão assimétrica, antes de plugar o guard na Task 5.)*

- [ ] **Step 14: Rodar o guard de canonização (índice ↔ arquivos)**

Run: `./scripts/check-canon.sh`
Expected: `check-canon: limpo` (exit 0). *(C5 confirma que cada `docs/adr/ADR-*.md` está no índice §2.)*

- [ ] **Step 15: Commit**

```bash
git add docs/adr/ADR-0*.md
git commit -m "docs(adr): promove as decisões consolidadas a ADR-001..011"
```

---

## Task 3: Atualizar `docs/adr/README.md` para o índice populado

**Files:**
- Modify: `docs/adr/README.md`

**Interfaces:**
- Consumes: os 11 ADRs (Task 2) e o índice §2 do `architecture.md` (Task 1).
- Produces: nada consumido por tasks seguintes.

- [ ] **Step 1: Substituir o corpo do README**

Substitua todo o conteúdo de `docs/adr/README.md` por:

```markdown
# ADRs do zion-build-prd

Decisões estruturantes **deste repo** (não dos projetos-alvo), registradas no padrão do
`/zion-adr-new` com as seções Contexto / Decisão / Consequências / Status. O índice está populado
com **ADR-001…ADR-011** e é espelhado na §2 de `docs/architecture.md` — `scripts/check-canon.sh`
acusa ADR fora do índice.

ADR-001…ADR-010 são **retroativos**: promovem as decisões antes consolidadas como D-01…D-10 e sua
Evidência é do tipo *conhecimento*, apontando o design doc de origem em `docs/superpowers/specs/`
(que permanece como lastro histórico, citado pelos ADRs e não mais pelo canon). ADR-011 registra a
própria promoção, no modo *decisão dada*. Decisão nova ou reversão nasce como ADR novo (supersessão
simétrica), e o `scripts/check-adr.sh docs/adr` (pre-commit + CI) cobra Evidência presente.
```

- [ ] **Step 2: Confirmar que nada quebrou**

Run: `./scripts/check-canon.sh && ./scripts/check-adr.sh docs/adr`
Expected: `check-canon: limpo` e `check-adr: limpo` (ambos exit 0).

- [ ] **Step 3: Commit**

```bash
git add docs/adr/README.md
git commit -m "docs(adr): README descreve o índice populado (ADR-001..011)"
```

---

## Task 4: Propagar para `docs/prd.md` §8 e `CLAUDE.md` (dever de canonização)

**Files:**
- Modify: `docs/prd.md:94-100` (§8. Restrições)
- Modify: `CLAUDE.md:6-7` (descrição do architecture) · `CLAUDE.md:18-21` (cross-refs de seção) · `CLAUDE.md:33` (linha "não se reabrem")

**Interfaces:**
- Consumes: o índice §2 do `architecture.md` (Task 1) e os ADRs (Task 2).
- Produces: canon sem nenhum rótulo `D-01`…`D-10` nem `D-xx`.

**Guarda de fronteira:** o `check-canon.sh` roda o `check-prd.sh` como dogfood sobre `docs/prd.md`. O novo texto da §8 não pode conter bloco de código, comando de instalação, `import`, versão `x.y.z` nem termo de denylist. As menções `ADR-001`/`ADR-002`/`ADR-004`/`ADR-007` são inofensivas (não são stack).

- [ ] **Step 1: Reescrever a §8 da PRD**

Em `docs/prd.md`, substitua o parágrafo da §8 (linhas 96-100, começando em "As decisões estruturantes deste repo estão consolidadas…") por:

```markdown
As decisões estruturantes deste repo estão registradas como ADRs em `docs/adr/`, indexadas na §2 de
`docs/architecture.md`. Em especial: fonte única com cópias derivadas (ADR-001), distribuição em
dois canais com autocontenção (ADR-002), verificação mecânica que aconselha no projeto-alvo
(ADR-004) e o contrato de capacidades com o executor externo de brainstorming (ADR-007).
```

- [ ] **Step 2: Rodar o dogfood do check-prd sobre a PRD**

Run: `./scripts/check-prd.sh prd docs/prd.md`
Expected: `check-prd: limpo` (exit 0).

- [ ] **Step 3: Corrigir a descrição do architecture em `CLAUDE.md`**

Em `CLAUDE.md`, na seção "Fontes da verdade", troque a linha:

```markdown
- **`docs/architecture.md`** — como o harness é construído (decisões D-xx, índice de ADRs,
  scripts, fonte única).
```

por:

```markdown
- **`docs/architecture.md`** — como o harness é construído (decisões estruturantes como ADRs,
  scripts, fonte única).
```

- [ ] **Step 4: Corrigir os cross-refs de seção no "Dever de canonização" de `CLAUDE.md`**

Troque o bloco (as três linhas de canonização que citam números de seção):

```markdown
- Script novo/removido ⇒ tabela de scripts (§4) de `docs/architecture.md`.
- Fonte nova no `ASSET_MAP` ⇒ §5 de `docs/architecture.md`.
- Decisão estruturante ⇒ ADR em `docs/adr/` (via `/zion-adr-new`) + índice (§3) do
  `architecture.md`.
```

por:

```markdown
- Script novo/removido ⇒ tabela de scripts (§3) de `docs/architecture.md`.
- Fonte nova no `ASSET_MAP` ⇒ §4 de `docs/architecture.md`.
- Decisão estruturante ⇒ ADR em `docs/adr/` (via `/zion-adr-new`) + índice (§2) do
  `architecture.md`.
```

- [ ] **Step 5: Remover "D-xx" da linha "não se reabrem" em `CLAUDE.md`**

Troque a linha:

```markdown
- Decisões dos ADRs e D-xx não se reabrem em spec/plano — mudar de decisão é ADR novo
  (supersessão simétrica).
```

por:

```markdown
- Decisões dos ADRs não se reabrem em spec/plano — mudar de decisão é ADR novo
  (supersessão simétrica).
```

- [ ] **Step 6: Confirmar zero rótulos aposentados e canon limpo**

Run: `grep -nE 'D-0[0-9]|D-10|D-xx' docs/prd.md docs/architecture.md CLAUDE.md; ./scripts/check-canon.sh`
Expected: o `grep` não retorna nada (zero ocorrências) e `check-canon: limpo` (exit 0).

- [ ] **Step 7: Commit**

```bash
git add docs/prd.md CLAUDE.md
git commit -m "docs(canon): prd §8 e CLAUDE.md citam ADRs; aposenta rótulo D-xx"
```

---

## Task 5: Plugar `check-adr.sh docs/adr` como backstop (pre-commit + CI)

**Files:**
- Modify: `.githooks/pre-commit` (após a chamada de `check-canon.sh`)
- Modify: `.github/workflows/check-assets.yml` (novo passo após o guard de canonização)

**Interfaces:**
- Consumes: os 11 ADRs válidos (Task 2) — o `check-adr.sh docs/adr` exige ≥1 ADR (senão exit 2) e todos com Evidência válida.
- Produces: enforcement bloqueante de ADR sem evidência / supersessão assimétrica, local e no CI.

**Por que esta task vem depois da Task 2:** com `docs/adr/` sem nenhum `ADR-*.md`, o `check-adr.sh docs/adr` sairia com exit 2 (erro de uso) e **bloquearia todos os commits**. Só é seguro plugá-lo depois que os 11 ADRs existem.

- [ ] **Step 1: Demonstrar a lacuna atual (o pre-commit ainda não checa ADR)**

Verifique o hook atual:

Run: `grep -n check-adr .githooks/pre-commit`
Expected: nenhuma saída (o `check-adr` ainda não está no hook — a lacuna a fechar).

- [ ] **Step 2: Adicionar o passo ao `.githooks/pre-commit`**

Ao final de `.githooks/pre-commit`, logo após a linha `./scripts/check-canon.sh`, acrescente:

```bash

# Dogfood dos ADRs: evidência presente + supersessão simétrica nos ADRs do repo.
# Mesmo molde do check-canon (aqui BLOQUEIA); o CI repete como backstop.
./scripts/check-adr.sh docs/adr
```

O arquivo final deve terminar assim:

```bash
# Canonização: docs/prd.md e docs/architecture.md devem refletir a implementação.
# Diferente dos gates dos projetos-alvo (aconselham), aqui BLOQUEIA o commit.
./scripts/check-canon.sh

# Dogfood dos ADRs: evidência presente + supersessão simétrica nos ADRs do repo.
# Mesmo molde do check-canon (aqui BLOQUEIA); o CI repete como backstop.
./scripts/check-adr.sh docs/adr
```

- [ ] **Step 3: Adicionar o passo ao CI**

Em `.github/workflows/check-assets.yml`, após o passo "Guard de canonização", acrescente um passo:

```yaml
      - name: Guard de ADRs (evidência + supersessão simétrica)
        run: ./scripts/check-adr.sh docs/adr
```

O bloco `steps:` final deve ficar:

```yaml
    steps:
      - uses: actions/checkout@v4
      - name: Verifica drift de assets derivados
        run: ./scripts/check-assets.sh
      - name: Avaliação da camada mecânica
        run: ./scripts/eval.sh
      - name: Guard de canonização (prd/architecture ↔ implementação)
        run: ./scripts/check-canon.sh
      - name: Guard de ADRs (evidência + supersessão simétrica)
        run: ./scripts/check-adr.sh docs/adr
```

- [ ] **Step 4: Confirmar que o guard roda verde sobre os ADRs reais**

Run: `./scripts/check-adr.sh docs/adr`
Expected: `check-adr: limpo` (exit 0).

- [ ] **Step 5: Commit (o próprio commit já exercita o hook novo)**

```bash
git add .githooks/pre-commit .github/workflows/check-assets.yml
git commit -m "feat(canon): check-adr docs/adr como backstop no pre-commit e CI"
```

Expected: o commit passa — o pre-commit recém-editado roda `check-adr.sh docs/adr` (limpo) e `check-canon.sh` (limpo).

---

## Task 6: Verificação final dos critérios de aceite

**Files:** nenhum (só verificação; a demonstração de bloqueio usa edições temporárias revertidas).

**Interfaces:**
- Consumes: o repositório completo pós-Task 5.
- Produces: evidência de que os 6 critérios de aceite do design passam.

- [ ] **Step 1: Critérios 1–5 (artefatos + verificadores limpos)**

Run:
```bash
ls docs/adr/ADR-0*.md | wc -l
./scripts/check-adr.sh docs/adr
./scripts/check-canon.sh
./scripts/check-assets.sh
./scripts/check-prd.sh prd docs/prd.md
./scripts/eval.sh
grep -rnE 'docs/superpowers/specs' docs/architecture.md
grep -rnE 'D-0[0-9]|D-10' docs/prd.md docs/architecture.md CLAUDE.md
```
Expected:
- `11` (os 11 ADRs existem — critério 1).
- `check-adr: limpo` (critério 2).
- `check-canon: limpo` (critério 3 + 5 — C5 do ADR no índice).
- `check-assets: …` sem drift, exit 0 (critério 5).
- `check-prd: limpo` (critério 5 — dogfood).
- `eval: tudo verde` (critério 5).
- as duas linhas de `grep` **sem saída** (critérios 3 e 4).

- [ ] **Step 2: Critério 6a — commit com ADR sem evidência é BLOQUEADO**

Quebre temporariamente um ADR (apaga o valor da Evidência), stage e tente commitar:

```bash
cp docs/adr/ADR-001-assets-fonte-unica.md /tmp/adr-001.bak
sed -i 's|^- \*\*Evidência:\*\* .*|- **Evidência:**|' docs/adr/ADR-001-assets-fonte-unica.md
git add docs/adr/ADR-001-assets-fonte-unica.md
git commit -m "TESTE: ADR sem evidência (deve ser bloqueado)"
```
Expected: o commit **falha** — o pre-commit imprime `ADR-001-...: sem-evidencia …` e `check-adr` sai com exit 1, abortando o commit.

- [ ] **Step 3: Critério 6b — commit com ADR fora do índice é BLOQUEADO**

Restaure o ADR-001, depois crie um ADR novo não indexado e tente commitar:

```bash
cp /tmp/adr-001.bak docs/adr/ADR-001-assets-fonte-unica.md
git add docs/adr/ADR-001-assets-fonte-unica.md
cat > docs/adr/ADR-999-teste-fora-do-indice.md <<'EOF'
# ADR-999 — Teste fora do índice

- **Status:** Aceito
- **Data:** 2026-07-18
- **Decisores:** autoria do repo
- **Evidência:** Decisão dada: teste de bloqueio do check-canon

## Contexto

Teste.

## Decisão

Teste.

## Consequências

Teste.

## Status

Aceito.
EOF
git add docs/adr/ADR-999-teste-fora-do-indice.md
git commit -m "TESTE: ADR fora do índice (deve ser bloqueado)"
```
Expected: o commit **falha** — o pre-commit imprime `docs/adr/ADR-999-teste-fora-do-indice.md: adr-sem-indice …` do `check-canon` (exit 1).

- [ ] **Step 4: Limpar os artefatos de teste e confirmar árvore limpa**

```bash
rm -f docs/adr/ADR-999-teste-fora-do-indice.md /tmp/adr-001.bak
git reset
git status
```
Expected: `git status` mostra a árvore **limpa** (o ADR-001 restaurado é byte-idêntico ao commitado; o ADR-999 foi removido). Nenhuma mudança pendente.

- [ ] **Step 5: Critério 6 (fechamento) — após corrigir, um commit real passa**

Confirme que um commit legítimo qualquer passa o pre-commit (prova o "após corrigir, o commit passa"). Como a árvore está limpa, faça um commit vazio de sanidade e desfaça-o:

```bash
git commit --allow-empty -m "chore: sanidade do pre-commit (pós-canonização)"
```
Expected: o commit passa — `check-assets`, `check-canon` e `check-adr docs/adr` todos limpos no hook.

---

## Self-Review (executada pelo autor do plano)

**1. Cobertura da spec:**
- Fase A (11 ADRs) → Task 2 (Steps 2–12), com ADR-002/ADR-006 citando o doc irmão no Contexto e ADR-011 em modo decisão dada sem `Substitui:`. ✅
- Fase B (funde §2+§3, renumera §4/§5/§6→§3/§4/§5, corrige auto-refs) → Task 1. ✅
- Fase C (README populado) → Task 3. ✅
- Fase D (PRD §8 + CLAUDE.md cross-refs + rótulo aposentado) → Task 4. ✅
- Fase E (pre-commit + CI; eval sem entrada nova; tabela de scripts intacta) → Task 5 (eval e tabela de scripts explicitamente **não** tocados). ✅
- Critérios de aceite 1–6 → Task 6. ✅

**2. Placeholder scan:** nenhum "TBD/TODO/similar a…"; cada ADR e cada edição trazem o texto literal. ✅

**3. Consistência de tipos/nomes:** os 11 basenames em Global Constraints, no índice §2 (Task 1) e nos arquivos criados (Task 2) coincidem exatamente; os cross-refs de seção (§3/§4/§2) são idênticos em `architecture.md` (Task 1) e em `CLAUDE.md` (Task 4). ✅

**4. Ordem sempre-verde:** Task 1 (índice antes dos arquivos, C5 é verde) → Task 2 (arquivos, agora indexados) → Task 5 (plugar `check-adr` só depois que ADRs existem, senão exit 2 bloquearia tudo). ✅
```