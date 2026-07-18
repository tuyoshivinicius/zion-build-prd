# Governança canônica (prd/architecture + check-canon) — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fazer o repo governar a si mesmo: `docs/prd.md` + `docs/architecture.md` como fontes da verdade, `CLAUDE.md` como regra raiz, e `scripts/check-canon.sh` (TDD, fixtures) bloqueando drift no pre-commit com CI como backstop.

**Architecture:** Espelha o padrão existente dos verificadores (`check-*.sh` com exit 0/1/2, `test-check-*.sh` contra `scripts/fixtures/`, agregação em `eval.sh`). A PRD dogfooda o próprio esqueleto e passa no `check-prd.sh`. Spec de origem: `docs/superpowers/specs/2026-07-18-governanca-canon-design.md`.

**Tech Stack:** Bash (mesmo estilo dos scripts existentes), Markdown. Zero dependência nova.

---

### Task 1: Mover os guias para `docs/guias/`

Os três guias só se citam entre si (por nome, sem path) — nenhum outro arquivo os referencia. Mover juntos não quebra nada.

**Files:**
- Move: `docs/avaliacao-harness.md` → `docs/guias/avaliacao-harness.md`
- Move: `docs/como-usar.md` → `docs/guias/como-usar.md`
- Move: `docs/guia-prd-para-spec-kit.md` → `docs/guias/guia-prd-para-spec-kit.md`

- [ ] **Step 1: git mv**

```bash
mkdir -p docs/guias
git mv docs/avaliacao-harness.md docs/como-usar.md docs/guia-prd-para-spec-kit.md docs/guias/
```

- [ ] **Step 2: Nota de governança no topo de cada guia**

Em cada um dos três arquivos, logo **após a linha do título `# ...`**, inserir (linha em branco antes e depois):

```markdown
> **Governança:** este documento é **guia de uso**, não normativo. Os requisitos do harness vivem
> em [`docs/prd.md`](../prd.md) e a arquitetura em [`docs/architecture.md`](../architecture.md) —
> as fontes da verdade deste repo.
```

- [ ] **Step 3: Verificar que nada quebrou**

```bash
./scripts/check-assets.sh && ./scripts/eval.sh
grep -rn 'docs/como-usar\|docs/avaliacao-harness\|docs/guia-prd' README.md skills/ scripts/ .github/ || echo "sem referências órfãs"
```

Expected: `check-assets: sem drift`, `eval: tudo verde`, `sem referências órfãs`.

- [ ] **Step 4: Commit**

```bash
git add -A && git commit -m "docs: move guias de uso para docs/guias/ (separa SoT de material de apoio)"
```

---

### Task 2: Criar `docs/prd.md` (dogfood do esqueleto)

**Files:**
- Create: `docs/prd.md`

Restrições do `check-prd.sh` que este arquivo respeita: cabeçalhos `## N. Título`; **nenhum** bloco cercado (```); nenhum termo da denylist; nenhum padrão `nome x.y.z`; §6 com RF só sob linha `**Épico E# — ...**`; §7 com dígito em todo item; RF fora da §6 só em linha de tabela.

- [ ] **Step 1: Escrever `docs/prd.md`** com o conteúdo integral:

```markdown
# PRD — Zion Build PRD (o harness)

> Fonte da verdade dos **requisitos** deste repo (o-quê/por-quê). O como/com-quê vive em
> `docs/architecture.md`. Toda mudança de comportamento do harness reflete aqui no mesmo commit
> (canonização — veja `CLAUDE.md`); `scripts/check-canon.sh` cruza esta PRD com a implementação.

## 1. Visão

Para o autor de produto que trabalha com agentes no Claude Code e trava entre a ideia bruta e uma
spec executável, o Zion Build PRD é um harness de skills que conduz a autoria da PRD em estágios —
descoberta, decisões estruturantes, escrita, decomposição — e entrega cada spec pronta para o ciclo
do Spec Kit, guardando sempre a fronteira o-quê/como.

## 2. Objetivos & métricas

- Toda PRD produzida chega à ponte do specify com 0 achados de fronteira na verificação mecânica.
- 100% dos RF in-scope de uma PRD rastreados a uma spec na tabela de rastreabilidade.
- O autor sai da ideia bruta ao primeiro prompt de specify em 1 jornada contínua de 5 estágios,
  sem montar prompt de ponte à mão.

## 3. Personas

- **O Autor** — dev de produto (solo ou time pequeno) que usa o Claude Code e quer PRDs enxutas
  sem virar burocrata de documento.
- **O Agente** — o Claude conduzindo um estágio: lê as regras canônicas e os artefatos dos
  estágios anteriores, verifica e aconselha.

## 4. Escopo (in / out)

- **Faz (in):** conduz descoberta enxuta retomável; prova decisões estruturantes com evidência
  proporcional ao risco e as registra como ADRs; escreve a PRD enxuta a partir de esqueleto;
  decompõe em épicos e specs verticais com backlog e rastreabilidade; monta os prompts das três
  pontes para o Spec Kit; verifica por máquina as regras decidíveis; acompanha a evolução
  pós-release (dia 2).
- **Não faz (out):** não executa o ciclo do Spec Kit (specify em diante é do autor); não escreve
  código de produto; não decide stack pelo autor (só registra a decisão dele em ADR); não resolve
  dependência de instalação no canal skills.sh; não bloqueia o autor em gate algum do
  projeto-alvo.

## 5. Regras de negócio (RN-xx)

- `RN-01` Todo gate do harness no projeto-alvo aconselha, nunca bloqueia — o autor decide seguir.
- `RN-02` A fronteira o-quê/por-quê × como/com-quê vale em todo artefato: stack só em ADR e plan.
- `RN-03` Toda decisão estruturante carrega evidência do tipo certo para o seu risco (execução,
  conhecimento ou decisão dada).
- `RN-04` Artefatos derivados (tabela de rastreabilidade, backlog) são semeados e reconciliados
  por máquina, nunca mantidos à mão.
- `RN-05` Regra de qualidade se afina num lugar só (fonte única); toda cópia é derivada e
  verificada contra drift.

## 6. Requisitos funcionais por épico (RF-xx)

- **Épico E1 — Jornada de autoria:** `RF-01` O autor conduz a descoberta enxuta (visão, persona,
  faz/não-faz) e a retoma entre sessões sem perder o que já respondeu. `RF-02` O autor prova as
  2–3 decisões estruturantes com evidência proporcional ao risco antes de fechar a PRD. `RF-03` O
  autor registra cada decisão como ADR com contexto, decisão e consequências — inclusive
  substituindo um ADR anterior com referência simétrica. `RF-04` O autor preenche a PRD seção a
  seção a partir de um esqueleto, com requisitos de uma frase agrupados por épico. `RF-05` O autor
  decompõe a PRD em épicos, story map e specs verticais priorizadas, com o walking skeleton como
  spec zero.
- **Épico E2 — Pontes para o Spec Kit:** `RF-06` O autor recebe pronto o prompt da constitution,
  derivado dos NFRs e restrições da PRD, com princípios decidíveis. `RF-07` O autor recebe pronto
  o prompt do specify de uma spec, blindado contra vazamento de fronteira e com o elo de
  rastreabilidade pedido. `RF-08` O autor recebe pronto o prompt do plan de uma feature, com os
  ADRs confirmados injetados como restrição a honrar.
- **Épico E3 — Rastreabilidade:** `RF-09` O autor reconcilia a qualquer momento a tabela de
  rastreabilidade e o backlog a partir das specs existentes, vendo RF órfão, spec intraçável e RF
  descoberto.
- **Épico E4 — Dia 2:** `RF-10` O autor classifica uma mudança pós-release nos cenários canônicos
  e é roteado aos comandos donos de cada artefato afetado, com o histórico registrado na PRD.
- **Épico E5 — Qualidade mecânica:** `RF-11` O harness verifica por máquina as regras decidíveis
  dos artefatos (fronteira sem stack, NFR com número, RF por épico, evidência presente por risco)
  e ecoa o veredito nos estágios. `RF-12` O harness avalia a si mesmo em duas camadas —
  determinística com fixtures no CI e de julgamento sob demanda. `RF-13` O harness governa a si
  mesmo: requisitos e arquitetura são fontes da verdade versionadas, e o drift entre elas e a
  implementação é acusado por máquina antes do commit.
- **Épico E6 — Distribuição:** `RF-14` O autor instala as skills por um comando, em qualquer um
  dos dois canais suportados. `RF-15` Cada skill é autocontida: carrega consigo as regras e
  templates de que precisa, gerados da fonte única. `RF-16` Uma skill que depende de capacidade
  externa ausente avisa com o comando de instalação e para graciosamente.

## 7. NFRs (com números)

- `NFR-01` A camada mecânica completa (drift de assets + auto-testes + canon) roda em menos de
  60 segundos no CI.
- `NFR-02` Exatamente 1 dependência externa de skill (o executor de brainstorming); o resto viaja
  no repo ou é built-in.
- `NFR-03` 0 de drift tolerado entre fonte única e cópias derivadas: qualquer divergência falha o
  CI.
- `NFR-04` 100% dos verificadores mecânicos têm auto-teste com fixture limpa e suja.
- `NFR-05` 0 gate bloqueante no projeto-alvo: todo veredito mecânico é conselho (exit lido pela
  skill, nunca revertendo trabalho do autor).

## 8. Restrições (das decisões de arquitetura)

As decisões estruturantes deste repo estão consolidadas em `docs/architecture.md` (D-01 em
diante), que também indexa os ADRs futuros de `docs/adr/`. Em especial: fonte única com cópias
derivadas (D-01), distribuição em dois canais com autocontenção (D-02), verificação mecânica que
aconselha no projeto-alvo (D-04) e o contrato de capacidades com o executor externo de
brainstorming (D-07).

## 9. Glossário

- **Harness** — o conjunto de skills que conduz a jornada PRD → Spec Kit.
- **Estágio** — um passo da jornada (descoberta, spike, escrita, decomposição, pontes, trace,
  dia 2).
- **Fronteira** — a separação o-quê/por-quê (PRD, specify) × como/com-quê (ADR, plan).
- **Spec vertical** — unidade de trabalho que atravessa o produto de ponta a ponta e permite demo.
- **Ponte** — comando que monta o prompt de um passo do Spec Kit sem executá-lo.
- **Canonização** — refletir toda mudança de comportamento/estrutura de volta nas fontes da
  verdade deste repo, no mesmo commit.

## 10. Riscos

- Upgrade do executor externo de brainstorming quebra capacidade usada pelos estágios →
  mitigado: contrato C1–C3 com check de drift e pin de versão.
- As fontes da verdade deste repo apodrecem em silêncio → mitigado: guard de canonização no
  pre-commit e no CI (épico E5).
- A denylist de stack envelhece e deixa vazar termo novo → mitigado: curadoria num lugar só,
  afinável num commit.

## 11. Questões abertas

- Promover o runner por agentes da camada LLM a uma skill própria? Decidir quando o roteiro
  manual provar valor.

## 12. Rastreabilidade

Nesta PRD (o harness é o produto), a coluna de destino aponta o **artefato do repo** que realiza
cada RF — é o elo que `scripts/check-canon.sh` cruza com o disco.

| RF | Épico | Artefato |
|----|-------|----------|
| RF-01 | E1 | skills/zion-prd-discovery |
| RF-02 | E1 | skills/zion-prd-spike |
| RF-03 | E1 | skills/zion-adr-new |
| RF-04 | E1 | skills/zion-prd-write |
| RF-05 | E1 | skills/zion-prd-decompose |
| RF-06 | E2 | skills/zion-prd-constitution-prompt |
| RF-07 | E2 | skills/zion-prd-specify-prompt |
| RF-08 | E2 | skills/zion-prd-plan-prompt |
| RF-09 | E3 | skills/zion-prd-trace |
| RF-10 | E4 | skills/zion-prd-evolve |
| RF-11 | E5 | scripts/check-prd.sh · scripts/check-adr.sh · scripts/trace-prd.sh · scripts/trace-backlog.sh |
| RF-12 | E5 | scripts/eval.sh · scripts/fixtures/ · docs/guias/avaliacao-harness.md |
| RF-13 | E5 | scripts/check-canon.sh · CLAUDE.md · docs/prd.md · docs/architecture.md |
| RF-14 | E6 | .claude-plugin/ · README.md |
| RF-15 | E6 | scripts/sync-assets.sh · scripts/asset-map.sh · assets/ |
| RF-16 | E6 | preflight nas SKILL.md das skills dependentes |

## 13. Histórico de mudanças

> Vazia no dia 1 desta PRD. Uma linha por mudança de requisito daqui em diante (regras em
> `assets/quality-rules.md#dia-2`).

| Data | Cenário | Mudança | Motivo | Artefatos afetados |
|------|---------|---------|--------|--------------------|
```

- [ ] **Step 2: Verificar dogfood**

```bash
bash scripts/check-prd.sh prd docs/prd.md
```

Expected: `check-prd: limpo` (exit 0). Se houver achado, corrigir a PRD (não o check) até limpar.

- [ ] **Step 3: Commit**

```bash
git add docs/prd.md && git commit -m "docs: PRD do próprio harness como fonte da verdade (dogfood do esqueleto)"
```

---

### Task 3: Criar `docs/architecture.md` + `docs/adr/README.md`

**Files:**
- Create: `docs/architecture.md`
- Create: `docs/adr/README.md`

- [ ] **Step 1: Escrever `docs/architecture.md`** com o conteúdo integral:

````markdown
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
````

- [ ] **Step 2: Escrever `docs/adr/README.md`**:

```markdown
# ADRs do zion-build-prd

Decisões estruturantes **deste repo** (não dos projetos-alvo), registradas via `/zion-adr-new` a
partir da governança canônica (D-10). O histórico anterior vive nos design docs de
`docs/superpowers/specs/`, consolidado em `docs/architecture.md` (§2) — que também mantém o
índice dos ADRs daqui (§3). ADR novo fora do índice é acusado por `scripts/check-canon.sh`.
```

- [ ] **Step 3: Commit**

```bash
git add docs/architecture.md docs/adr/README.md
git commit -m "docs: architecture.md consolida decisões D-01..D-10 e cria docs/adr/ (dogfood)"
```

---

### Task 4: Criar `CLAUDE.md` + symlink `AGENTS.md`

**Files:**
- Create: `CLAUDE.md`
- Create: `AGENTS.md` (symlink → `CLAUDE.md`)

- [ ] **Step 1: Escrever `CLAUDE.md`** com o conteúdo integral:

```markdown
# Regras deste repo — leia antes de qualquer trabalho

## Fontes da verdade (governança)

- **`docs/prd.md`** — o que o harness faz e por quê (RF-xx por épico, NFRs, escopo).
- **`docs/architecture.md`** — como o harness é construído (decisões D-xx, índice de ADRs,
  scripts, fonte única).

Todo agent DEVE ler os dois antes de escrever qualquer spec, plano ou mudança neste repo.
Especificação nova nasce desses documentos, não do código.

## Dever de canonização

Toda mudança de comportamento ou estrutura reflete de volta nas fontes da verdade **no mesmo
commit**:

- Skill nova/alterada/removida ⇒ RF na §6 e linha na §12 de `docs/prd.md`.
- Script novo/removido ⇒ tabela de scripts (§4) de `docs/architecture.md`.
- Fonte nova no `ASSET_MAP` ⇒ §5 de `docs/architecture.md`.
- Decisão estruturante ⇒ ADR em `docs/adr/` (via `/zion-adr-new`) + índice (§3) do
  `architecture.md`.

O guard `scripts/check-canon.sh` roda no pre-commit e **bloqueia** commit com drift; o CI
(`.github/workflows/check-assets.yml`) repete como backstop.

## Regras operacionais

- `assets/` é a fonte única; **nunca** edite `skills/*/references/` à mão — são derivados que o
  pre-commit regenera via `scripts/sync-assets.sh`.
- Após clonar: `./scripts/setup-hooks.sh` (ativa os hooks versionados).
- A fronteira o-quê/como (`assets/quality-rules.md#fronteira`) vale para os próprios docs:
  requisito sem stack em `docs/prd.md`; stack e mecânica em `docs/architecture.md`.
- Decisões dos ADRs e D-xx não se reabrem em spec/plano — mudar de decisão é ADR novo
  (supersessão simétrica).
- Verificação local: `./scripts/check-assets.sh` · `./scripts/check-canon.sh` ·
  `./scripts/eval.sh`.
```

- [ ] **Step 2: Symlink**

```bash
ln -s CLAUDE.md AGENTS.md
```

- [ ] **Step 3: Commit**

```bash
git add CLAUDE.md AGENTS.md
git commit -m "docs: CLAUDE.md declara as fontes da verdade e o dever de canonização (AGENTS.md symlink)"
```

---

### Task 5: Fixtures + `test-check-canon.sh` (RED — antes da lógica)

**Files:**
- Create: `scripts/fixtures/canon/clean/…` e `scripts/fixtures/canon/dirty/…` (árvores abaixo)
- Create: `scripts/test-check-canon.sh`

- [ ] **Step 1: Fixture `clean/`** — mini-árvore consistente:

`scripts/fixtures/canon/clean/CLAUDE.md`:

```markdown
Fontes da verdade: docs/prd.md e docs/architecture.md. Canonize toda mudança.
```

`scripts/fixtures/canon/clean/docs/prd.md`:

```markdown
# PRD — Harness de Exemplo

## 6. Requisitos funcionais por épico (RF-xx)

- **Épico E1 — Autoria:** `RF-01` O autor registra a descoberta do produto.

## 7. NFRs (com números)

- NFR-01: a verificação completa roda em menos de 60 segundos.

## 12. Rastreabilidade

| RF | Épico | Artefato |
|----|-------|----------|
| RF-01 | E1 | skills/zion-prd-foo |
```

`scripts/fixtures/canon/clean/docs/architecture.md`:

```markdown
# Arquitetura — Harness de Exemplo

## Scripts

- scripts/check-foo.sh — verificador de exemplo.
- scripts/asset-map.sh — mapa fonte única → skills.

## Fontes

- assets/regras.md — regras canônicas.

## Índice de ADRs

- ADR-001-formato.md — formato dos documentos.
```

`scripts/fixtures/canon/clean/docs/adr/ADR-001-formato.md`:

```markdown
# ADR-001 — Formato dos documentos

- **Status:** Aceito
```

`scripts/fixtures/canon/clean/skills/zion-prd-foo/SKILL.md`:

```markdown
# zion-prd-foo (fixture)
```

`scripts/fixtures/canon/clean/scripts/check-foo.sh`:

```bash
#!/usr/bin/env bash
# fixture — sem lógica
```

`scripts/fixtures/canon/clean/scripts/asset-map.sh`:

```bash
#!/usr/bin/env bash
# fixture do mapa
ASSET_MAP=(
  "assets/regras.md  zion-prd-foo"
)
```

- [ ] **Step 2: Fixture `dirty/`** — um defeito por achado C1–C6 + stack para o dogfood (C7):

`scripts/fixtures/canon/dirty/CLAUDE.md` (cita só a prd → `regra-raiz-sem-sot`):

```markdown
Fonte da verdade: docs/prd.md.
```

`scripts/fixtures/canon/dirty/docs/prd.md` (cita skill fantasma; não cita a órfã; tem stack):

```markdown
# PRD — Harness de Exemplo (sujo)

A prévia usa react para renderizar o diagrama.

## 12. Rastreabilidade

| RF | Épico | Artefato |
|----|-------|----------|
| RF-01 | E1 | skills/zion-prd-fantasma |
```

`scripts/fixtures/canon/dirty/docs/architecture.md` (não cita `solto.sh`, nem `assets/nao-doc.md`, nem o ADR-002):

```markdown
# Arquitetura — Harness de Exemplo (suja)

## Scripts

- scripts/asset-map.sh — mapa fonte única → skills.

## Índice de ADRs

*(vazio)*
```

`scripts/fixtures/canon/dirty/docs/adr/ADR-002-perdido.md`:

```markdown
# ADR-002 — Decisão fora do índice

- **Status:** Aceito
```

`scripts/fixtures/canon/dirty/skills/zion-prd-orfao/SKILL.md`:

```markdown
# zion-prd-orfao (fixture — não citada na PRD)
```

`scripts/fixtures/canon/dirty/scripts/solto.sh`:

```bash
#!/usr/bin/env bash
# fixture — script sem doc
```

`scripts/fixtures/canon/dirty/scripts/asset-map.sh`:

```bash
#!/usr/bin/env bash
# fixture do mapa — fonte não documentada na arquitetura
ASSET_MAP=(
  "assets/nao-doc.md  zion-prd-orfao"
)
```

- [ ] **Step 3: Escrever `scripts/test-check-canon.sh`** (mesmo molde de `test-check-adr.sh`):

```bash
#!/usr/bin/env bash
# Auto-teste do check-canon.sh contra fixtures. Roda pela camada mecânica (scripts/eval.sh).
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
CHECK="scripts/check-canon.sh"
FIX="scripts/fixtures/canon"
fail=0

assert_exit() {  # desc  exit_esperado  exit_veio
  if [ "$2" != "$3" ]; then echo "FALHOU: $1 (exit esperado $2, veio $3)"; fail=1
  else echo "ok: $1"; fi
}
assert_contains() {  # desc  agulha  palheiro
  if printf '%s' "$3" | grep -qi -- "$2"; then echo "ok: $1"
  else echo "FALHOU: $1 (não achou: $2)"; fail=1; fi
}

# 1. Fixture clean → exit 0 / limpo
out="$(bash "$CHECK" "$FIX/clean")"; rc=$?
assert_exit "clean sai 0" 0 "$rc"
assert_contains "clean reporta limpo" "check-canon: limpo" "$out"

# 2. Fixture dirty → exit 1 + um achado de cada tipo
out="$(bash "$CHECK" "$FIX/dirty")"; rc=$?
assert_exit "dirty sai 1" 1 "$rc"
assert_contains "acha skill-sem-rf"       "skill-sem-rf"       "$out"
assert_contains "acha skill-fantasma"     "skill-fantasma"     "$out"
assert_contains "acha script-sem-doc"     "script-sem-doc"     "$out"
assert_contains "acha asset-sem-doc"      "asset-sem-doc"      "$out"
assert_contains "acha adr-sem-indice"     "adr-sem-indice"     "$out"
assert_contains "acha regra-raiz-sem-sot" "regra-raiz-sem-sot" "$out"
assert_contains "dogfood acha stack (via check-prd)" "stack" "$out"

# 3. ROOT inexistente → exit 2
out="$(bash "$CHECK" /caminho/que/nao/existe 2>&1)"; rc=$?
assert_exit "root inexistente sai 2" 2 "$rc"

if [ "$fail" -eq 0 ]; then echo "test-check-canon: tudo verde"; else echo "test-check-canon: FALHOU"; exit 1; fi
```

- [ ] **Step 4: Rodar e ver FALHAR (red)**

```bash
bash scripts/test-check-canon.sh
```

Expected: FALHOU em todos os asserts (`check-canon.sh` ainda não existe → exit ≠ esperado).

- [ ] **Step 5: Commit (red)**

```bash
git add scripts/fixtures/canon scripts/test-check-canon.sh
git commit -m "test(canon): fixtures clean/dirty e auto-teste do check-canon (red, TDD)"
```

---

### Task 6: Implementar `scripts/check-canon.sh` (GREEN)

**Files:**
- Create: `scripts/check-canon.sh` (chmod +x)

- [ ] **Step 1: Escrever o script** com o conteúdo integral:

```bash
#!/usr/bin/env bash
# check-canon.sh — guard de canonização do próprio repo (RF-13 / D-10).
# Cruza as fontes da verdade (docs/prd.md, docs/architecture.md, CLAUDE.md) com a
# implementação (skills/, scripts/, ASSET_MAP, docs/adr/). Presença/estrutura por
# máquina; a qualidade do texto é dever de quem edita (CLAUDE.md).
# Diferente dos verificadores dos projetos-alvo (aconselham), este BLOQUEIA:
# roda no .githooks/pre-commit e no CI. Exit 0 = limpo · 1 = achados · 2 = uso.
#
# Uso:
#   check-canon.sh [ROOT]   # default: raiz do repo (testável com fixtures)
set -u

usage() { echo "uso: check-canon.sh [ROOT]" >&2; exit 2; }

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="${1:-$(cd "$SCRIPT_DIR/.." && pwd)}"
case "$ROOT" in -*) usage ;; esac
[ -d "$ROOT" ] || { echo "check-canon: diretório não encontrado: $ROOT" >&2; exit 2; }

PRD="$ROOT/docs/prd.md"
ARCH="$ROOT/docs/architecture.md"
RULES="$ROOT/CLAUDE.md"

# As fontes da verdade existem?
check_docs_exist() {
  [ -f "$PRD" ]  || printf 'docs/prd.md: canon-ausente — fonte da verdade de requisitos não existe\n'
  [ -f "$ARCH" ] || printf 'docs/architecture.md: canon-ausente — fonte da verdade de arquitetura não existe\n'
}

# C1: todo dir de skills/ citado na prd.md.
check_skills_prd() {
  [ -d "$ROOT/skills" ] && [ -f "$PRD" ] || return 0
  local d name
  for d in "$ROOT"/skills/*/; do
    [ -d "$d" ] || continue
    name="$(basename "$d")"
    grep -qF "$name" "$PRD" \
      || printf 'skills/%s: skill-sem-rf — não citada em docs/prd.md (dê um RF na §6 e uma linha na §12)\n' "$name"
  done
}

# C2: todo skills/<nome> citado na prd.md existe no disco.
check_prd_skills_exist() {
  [ -f "$PRD" ] || return 0
  local ref
  grep -oE 'skills/[a-z0-9-]+' "$PRD" | sort -u | while read -r ref; do
    [ -d "$ROOT/$ref" ] \
      || printf 'docs/prd.md: skill-fantasma — "%s" citada mas não existe no disco\n' "$ref"
  done
}

# C3: todo scripts/*.sh (top-level) citado no architecture.md.
check_scripts_doc() {
  [ -d "$ROOT/scripts" ] && [ -f "$ARCH" ] || return 0
  local f base
  for f in "$ROOT"/scripts/*.sh; do
    [ -f "$f" ] || continue
    base="$(basename "$f")"
    grep -qF "$base" "$ARCH" \
      || printf 'scripts/%s: script-sem-doc — não citado em docs/architecture.md (tabela de scripts)\n' "$base"
  done
}

# C4: toda fonte assets/ do ASSET_MAP citada no architecture.md (scripts/ já cobertos por C3).
check_assets_doc() {
  local map="$ROOT/scripts/asset-map.sh" entry src
  [ -f "$map" ] && [ -f "$ARCH" ] || return 0
  ASSET_MAP=()
  # shellcheck disable=SC1090
  source "$map"
  for entry in "${ASSET_MAP[@]}"; do
    read -r src _ <<< "$entry"
    case "$src" in assets/*) ;; *) continue ;; esac
    grep -qF "$src" "$ARCH" \
      || printf '%s: asset-sem-doc — fonte do ASSET_MAP não citada em docs/architecture.md\n' "$src"
  done
}

# C5: todo docs/adr/ADR-*.md citado no architecture.md (índice).
check_adr_index() {
  [ -d "$ROOT/docs/adr" ] && [ -f "$ARCH" ] || return 0
  local af base
  for af in "$ROOT"/docs/adr/ADR-*.md; do
    [ -f "$af" ] || continue
    base="$(basename "$af")"
    grep -qF "$base" "$ARCH" \
      || printf 'docs/adr/%s: adr-sem-indice — não citado no índice de docs/architecture.md\n' "$base"
  done
}

# C6: CLAUDE.md existe e cita as duas fontes da verdade.
check_root_rules() {
  if [ ! -f "$RULES" ]; then
    printf 'CLAUDE.md: regra-raiz-sem-sot — arquivo de regras ausente na raiz\n'
    return 0
  fi
  grep -qF 'docs/prd.md' "$RULES" \
    || printf 'CLAUDE.md: regra-raiz-sem-sot — não cita docs/prd.md\n'
  grep -qF 'docs/architecture.md' "$RULES" \
    || printf 'CLAUDE.md: regra-raiz-sem-sot — não cita docs/architecture.md\n'
}

# C7 (dogfood): a própria PRD passa no check-prd.sh do harness.
check_prd_dogfood() {
  [ -f "$PRD" ] || return 0
  local out rc
  out="$(bash "$SCRIPT_DIR/check-prd.sh" prd "$PRD")"; rc=$?
  [ "$rc" -eq 1 ] && printf '%s\n' "$out" | grep -v '^check-prd:'
  return 0
}

findings="$(
  check_docs_exist
  check_skills_prd
  check_prd_skills_exist
  check_scripts_doc
  check_assets_doc
  check_adr_index
  check_root_rules
  check_prd_dogfood
)"

if [ -n "$findings" ]; then
  printf '%s\n' "$findings"
  count="$(printf '%s\n' "$findings" | grep -c .)"
  echo "check-canon: $count achado(s) — canonize (veja CLAUDE.md) e tente de novo"
  exit 1
else
  echo "check-canon: limpo"
  exit 0
fi
```

```bash
chmod +x scripts/check-canon.sh
```

- [ ] **Step 2: Rodar o auto-teste e ver PASSAR (green)**

```bash
bash scripts/test-check-canon.sh
```

Expected: `test-check-canon: tudo verde` (exit 0).

- [ ] **Step 3: Rodar contra o repo real**

```bash
./scripts/check-canon.sh
```

Expected: `check-canon: limpo`. Se acusar algo, o drift é real → corrigir **os docs** (Tasks 2–4), não o check.

- [ ] **Step 4: Commit**

```bash
git add scripts/check-canon.sh
git commit -m "feat(canon): check-canon.sh cruza as fontes da verdade com a implementação (green)"
```

---

### Task 7: Plugar em `eval.sh`, pre-commit e CI + canonizar o guia de avaliação

**Files:**
- Modify: `scripts/eval.sh:16-31`
- Modify: `.githooks/pre-commit` (fim do arquivo)
- Modify: `.github/workflows/check-assets.yml` (novo step)
- Modify: `docs/guias/avaliacao-harness.md` (§1 e tabela de fixtures mecânicas)

- [ ] **Step 1: `eval.sh`** — adicionar a entrada e a ordem:

```bash
declare -A TESTS=(
  [prd]="scripts/test-check-prd.sh"
  [adr]="scripts/test-check-adr.sh"
  [trace]="scripts/test-trace-prd.sh"
  [backlog]="scripts/test-trace-backlog.sh"
  [contract]="scripts/test-check-superpowers-contract.sh"
  [canon]="scripts/test-check-canon.sh"
)
ORDER=(prd adr trace backlog contract canon)
```

e no `case` de seleção:

```bash
    prd|adr|trace|backlog|contract|canon) ORDER=("$sel") ;;
    *) echo "uso: eval.sh [prd|adr|trace|backlog|contract|canon]" >&2; exit 2 ;;
```

- [ ] **Step 2: `.githooks/pre-commit`** — acrescentar ao final:

```bash

# Canonização: docs/prd.md e docs/architecture.md devem refletir a implementação.
# Diferente dos gates dos projetos-alvo (aconselham), aqui BLOQUEIA o commit.
./scripts/check-canon.sh
```

- [ ] **Step 3: CI** — novo step ao final de `.github/workflows/check-assets.yml`:

```yaml
      - name: Guard de canonização (prd/architecture ↔ implementação)
        run: ./scripts/check-canon.sh
```

- [ ] **Step 4: Canonizar `docs/guias/avaliacao-harness.md`** — na §1, incluir `check-canon.sh` na
lista de verificadores da camada mecânica; na tabela "Mecânicas", acrescentar:

```markdown
| `check-canon.sh` | `fixtures/canon/clean/` | — | limpo (exit 0) |
| `check-canon.sh` | `fixtures/canon/dirty/` | skill órfã/fantasma, script/asset sem doc, ADR fora do índice, regra raiz incompleta, stack na PRD | achados (exit 1) |
```

- [ ] **Step 5: Rodar tudo**

```bash
./scripts/eval.sh && ./scripts/check-assets.sh && ./scripts/check-canon.sh
```

Expected: `eval: tudo verde` (com `=== eval: canon ===`), `check-assets: sem drift`, `check-canon: limpo`.

- [ ] **Step 6: Commit** (já passa pelo pre-commit com o guard novo)

```bash
git add scripts/eval.sh .githooks/pre-commit .github/workflows/check-assets.yml docs/guias/avaliacao-harness.md
git commit -m "feat(canon): guard plugado no eval, pre-commit (bloqueia) e CI (backstop)"
```

---

### Task 8: Canonizar o README

**Files:**
- Modify: `README.md` (seção Desenvolvimento)

- [ ] **Step 1:** Na seção **Desenvolvimento**, após o parágrafo do CI (que lista os auto-testes),
incluir `test-check-canon.sh` na lista e acrescentar o parágrafo:

```markdown
O repo **governa a si mesmo**: `docs/prd.md` (requisitos) e `docs/architecture.md` (arquitetura)
são fontes da verdade — as regras para agents estão em `CLAUDE.md` (dever de **canonização**:
toda mudança de comportamento reflete nesses docs no mesmo commit). O guard
`scripts/check-canon.sh` cruza os docs com `skills/`, `scripts/`, o `ASSET_MAP` e `docs/adr/`;
roda no pre-commit (bloqueia) e no CI (backstop). Os guias de uso vivem em `docs/guias/`.
```

- [ ] **Step 2: Commit**

```bash
git add README.md && git commit -m "docs: README aponta a governança canônica e docs/guias/"
```

---

### Task 9: Verificação final (verification-before-completion)

- [ ] **Step 1: Suíte completa**

```bash
./scripts/setup-hooks.sh
./scripts/check-assets.sh && ./scripts/check-canon.sh && ./scripts/eval.sh
bash scripts/check-prd.sh prd docs/prd.md
```

Expected: tudo verde/limpo.

- [ ] **Step 2: Commit-teste que viola a canonização → pre-commit BLOQUEIA**

```bash
mkdir -p skills/zion-prd-canary && echo '# canary' > skills/zion-prd-canary/SKILL.md
git add skills/zion-prd-canary
git commit -m "teste: viola canonização"   # deve FALHAR
echo "exit do commit: $?"
```

Expected: achado `skills/zion-prd-canary: skill-sem-rf …`, commit **não** criado (exit ≠ 0).

- [ ] **Step 3: Limpar o canário e confirmar que volta a passar**

```bash
git reset HEAD skills/zion-prd-canary && rm -rf skills/zion-prd-canary
./scripts/check-canon.sh
git log --oneline -3   # sem o commit de teste
```

Expected: `check-canon: limpo`; o commit "teste: viola canonização" não existe.
```
