# Skills autocontidas — remover a âncora ao guia — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fazer as 5 skills que citam `docs/guia-prd-para-spec-kit.md` absorverem o contexto de processo via um asset compartilhado autocontido, eliminando a referência externa quebrada no install.

**Architecture:** Um novo asset canônico `assets/process-context.md` (bloco invariante: sequência de estágios + fronteira o-quê/como) é sincronizado para o `references/` de cada uma das 5 skills pelo mecanismo `asset-map.sh` já existente. Cada `SKILL.md` troca a linha que cita o guia por uma que aponta ao reference local. O guia permanece em `docs/` como fonte da verdade dev-facing, sem skills apontando para ele.

**Tech Stack:** Markdown; Bash (scripts de sync `sync-assets.sh` / `check-assets.sh`, mapa `asset-map.sh`); git hooks já existentes.

**Nota sobre "testes":** este é um trabalho de docs/config. Não há framework de teste unitário; a verificação de cada task é feita por `grep`, pelos scripts `sync-assets.sh`/`check-assets.sh`, e por inspeção dos arquivos gerados. Esses comandos são os "testes".

---

### Task 1: Criar o asset canônico `assets/process-context.md`

**Files:**
- Create: `assets/process-context.md`

- [ ] **Step 1: Escrever o asset canônico**

Crie `assets/process-context.md` com exatamente este conteúdo:

```markdown
# Contexto de processo — harness Zion Build PRD

> Bloco invariante compartilhado pelos estágios do harness. Situa cada skill na jornada e fixa
> a fronteira que todo estágio guarda. Autocontido: não depende de nenhum documento externo.

## A sequência (o-quê → pronto para codar)

O harness conduz a autoria da PRD em estágios encadeados, cada um alimentando o próximo:

1. **Descoberta** (`/prd-discovery`) — visão, persona, quadro faz/não-faz → `docs/discovery.md`.
2. **Spikes + ADRs** (`/prd-spike`, `/adr-new`) — provar as 2–3 decisões estruturantes com
   código descartável e registrá-las como ADRs em `docs/adr/` **antes** de fechar a PRD.
3. **PRD enxuta** (`/prd-write`) — visão/escopo, `RF-xx` por épico (1 frase cada), NFRs com
   números, restrições (das ADRs) → `docs/PRD.md`. Sem comportamento detalhado nem stack.
4. **Decomposição** (`/prd-decompose`) — PRD → épicos → story map → fatias verticais validadas
   por INVEST; walking skeleton como fatia zero; tabela de rastreabilidade injetada na PRD.
   **Handoff:** cada fatia priorizada entra no Spec Kit via `/speckit.specify`.
5. **Spec Kit por feature** — `constitution` e o ciclo
   `specify → clarify → plan → checklist → tasks → analyze → implement → converge` (fora do
   harness; pontes montadas por `/prd-constitution-prompt` e `/prd-specify-prompt`).

## A fronteira o-quê/por-quê × como/com-quê

A **PRD** carrega *o-quê / por-quê* (visão e escopo). O **`plan.md`** de cada feature carrega
*como / com quê* (stack e detalhe técnico). Se você está escrevendo linguagem, framework,
biblioteca, tela, contrato de API ou critério de aceite na PRD, parou no lugar errado → isso
vive no `spec.md`/`plan.md` da feature. **Todo estágio deste harness guarda essa fronteira.**
```

- [ ] **Step 2: Verificar que o asset não cita o guia (dev-only)**

Run: `grep -n "guia-prd-para-spec-kit" assets/process-context.md; echo "exit=$?"`
Expected: nenhuma linha de match e `exit=1` (grep não achou nada). Caminhos de artefatos do usuário (`docs/discovery.md`, `docs/PRD.md`, `docs/adr/`) presentes são esperados e OK.

- [ ] **Step 3: Commit**

```bash
git add assets/process-context.md
git commit -m "feat(assets): process-context.md — contexto de processo autocontido"
```

---

### Task 2: Ligar o asset ao sync (`asset-map.sh`) e gerar os references

**Files:**
- Modify: `scripts/asset-map.sh` (adicionar 1 entrada ao array `ASSET_MAP`)
- Create (gerado pelo sync): `skills/prd-discovery/references/process-context.md`, `skills/prd-spike/references/process-context.md`, `skills/prd-write/references/process-context.md`, `skills/prd-decompose/references/process-context.md`, `skills/adr-new/references/process-context.md`

- [ ] **Step 1: Adicionar a entrada no `ASSET_MAP`**

Em `scripts/asset-map.sh`, dentro do array `ASSET_MAP=( ... )`, adicione esta linha após a entrada `traceability-table.md`:

```bash
  "assets/process-context.md              prd-discovery prd-spike prd-write prd-decompose adr-new"
```

O bloco resultante deve ficar:

```bash
ASSET_MAP=(
  "assets/quality-rules.md                prd-discovery prd-spike prd-write prd-decompose prd-constitution-prompt prd-specify-prompt"
  "assets/templates/prd-skeleton.md       prd-write"
  "assets/templates/traceability-table.md prd-decompose"
  "assets/process-context.md              prd-discovery prd-spike prd-write prd-decompose adr-new"
)
```

- [ ] **Step 2: Rodar o sync**

Run: `./scripts/sync-assets.sh`
Expected: termina com `sync-assets: ok` (sem erro).

- [ ] **Step 3: Verificar que os 5 references foram gerados e batem com o canônico**

Run: `./scripts/check-assets.sh`
Expected: `check-assets: sem drift`

Run: `ls skills/prd-discovery/references/process-context.md skills/prd-spike/references/process-context.md skills/prd-write/references/process-context.md skills/prd-decompose/references/process-context.md skills/adr-new/references/process-context.md`
Expected: os 5 caminhos existem (nenhum "No such file"). Confirma que `adr-new` ganhou seu primeiro `references/`.

- [ ] **Step 4: Commit**

```bash
git add scripts/asset-map.sh skills/prd-discovery/references/process-context.md skills/prd-spike/references/process-context.md skills/prd-write/references/process-context.md skills/prd-decompose/references/process-context.md skills/adr-new/references/process-context.md
git commit -m "feat(scripts): distribuir process-context.md via asset-map para as 5 skills"
```

> Nota: se o pre-commit hook estiver ativo (`core.hooksPath=.githooks`), ele roda o sync e re-stage automaticamente — o commit acima ainda é correto. Se algum reference for adicionado pelo hook, ele entra no mesmo commit.

---

### Task 3: Trocar a linha de orientação de cada `SKILL.md`

**Files:**
- Modify: `skills/prd-discovery/SKILL.md:13-14`
- Modify: `skills/prd-spike/SKILL.md:13-14`
- Modify: `skills/prd-write/SKILL.md:13-15`
- Modify: `skills/prd-decompose/SKILL.md:13-14`
- Modify: `skills/adr-new/SKILL.md:13-16`

- [ ] **Step 1: Editar `skills/prd-discovery/SKILL.md`**

Substitua exatamente:

```
Orquestra o Passo 1 do guia `docs/guia-prd-para-spec-kit.md`. Contrato de 5 fases; todos os gates
**aconselham** (apontam e sugerem), nunca bloqueiam. Regras em `references/quality-rules.md`.
```

por:

```
Orquestra o Estágio 1 do harness (Descoberta enxuta). Sequência completa dos estágios e a
fronteira o-quê/como em `references/process-context.md`. Contrato de 5 fases; todos os gates
**aconselham** (apontam e sugerem), nunca bloqueiam. Regras em `references/quality-rules.md`.
```

- [ ] **Step 2: Editar `skills/prd-spike/SKILL.md`**

Substitua exatamente:

```
Orquestra o Passo 2 do guia `docs/guia-prd-para-spec-kit.md`. Contrato de 5 fases; gates aconselham.
Regras em `references/quality-rules.md`.
```

por:

```
Orquestra o Estágio 2 do harness (Spikes técnicos + ADRs). Sequência dos estágios e fronteira
o-quê/como em `references/process-context.md`. Contrato de 5 fases; gates aconselham.
Regras em `references/quality-rules.md`.
```

- [ ] **Step 3: Editar `skills/prd-write/SKILL.md`**

Substitua exatamente:

```
Orquestra o Passo 3 do guia `docs/guia-prd-para-spec-kit.md`. Contrato de 5 fases; gates aconselham.
Regras em `references/quality-rules.md`. Este é o coração do harness: a Fase 4 guarda a fronteira
**o-quê/por-quê vs. como**.
```

por:

```
Orquestra o Estágio 3 do harness (PRD enxuta). Sequência dos estágios e fronteira o-quê/como em
`references/process-context.md`. Contrato de 5 fases; gates aconselham. Regras em
`references/quality-rules.md`. Este é o coração do harness: a Fase 4 guarda a fronteira
**o-quê/por-quê vs. como**.
```

- [ ] **Step 4: Editar `skills/prd-decompose/SKILL.md`**

Substitua exatamente:

```
Orquestra o Passo 4 do guia `docs/guia-prd-para-spec-kit.md`. Contrato de 5 fases; gates aconselham.
Regras em `references/quality-rules.md`.
```

por:

```
Orquestra o Estágio 4 do harness (Decomposição). Sequência dos estágios e fronteira o-quê/como em
`references/process-context.md`. Contrato de 5 fases; gates aconselham.
Regras em `references/quality-rules.md`.
```

- [ ] **Step 5: Editar `skills/adr-new/SKILL.md`**

Substitua exatamente:

```
Registra uma decisão estruturante como um ADR em `docs/adr/`, com as seções
**Contexto / Decisão / Consequências / Status**. Use no Passo 2 do guia
`docs/guia-prd-para-spec-kit.md` para registrar as 2–3 decisões que mudam a PRD inteira,
sustentadas por um spike que você de fato rodou.
```

por:

```
Registra uma decisão estruturante como um ADR em `docs/adr/`, com as seções
**Contexto / Decisão / Consequências / Status**. Use no Estágio 2 do harness (Spikes + ADRs) —
ver `references/process-context.md` — para registrar as 2–3 decisões que mudam a PRD inteira,
sustentadas por um spike que você de fato rodou.
```

- [ ] **Step 6: Verificar que nenhuma skill cita mais o guia**

Run: `grep -rn "guia-prd-para-spec-kit" skills/; echo "exit=$?"`
Expected: nenhuma linha de match e `exit=1` (vazio).

- [ ] **Step 7: Verificar que cada skill aponta ao reference local**

Run: `grep -rln "references/process-context.md" skills/*/SKILL.md`
Expected: exatamente os 5 arquivos — `skills/prd-discovery/SKILL.md`, `skills/prd-spike/SKILL.md`, `skills/prd-write/SKILL.md`, `skills/prd-decompose/SKILL.md`, `skills/adr-new/SKILL.md`.

- [ ] **Step 8: Commit**

```bash
git add skills/prd-discovery/SKILL.md skills/prd-spike/SKILL.md skills/prd-write/SKILL.md skills/prd-decompose/SKILL.md skills/adr-new/SKILL.md
git commit -m "refactor(skills): trocar âncora ao guia por references/process-context.md"
```

---

### Task 4: Verificação final integrada

**Files:** nenhum (só verificação)

- [ ] **Step 1: Sync + check-assets limpos**

Run: `./scripts/sync-assets.sh && ./scripts/check-assets.sh`
Expected: `sync-assets: ok` seguido de `check-assets: sem drift`.

- [ ] **Step 2: Zero referências ao guia nas skills e nos assets**

Run: `grep -rn "guia-prd-para-spec-kit" skills/ assets/; echo "exit=$?"`
Expected: vazio, `exit=1`.

- [ ] **Step 3: O guia continua existindo como fonte da verdade dev-facing**

Run: `test -f docs/guia-prd-para-spec-kit.md && echo "guia presente"`
Expected: `guia presente`.

- [ ] **Step 4: Working tree limpo**

Run: `git status --short`
Expected: vazio (tudo commitado).
```
