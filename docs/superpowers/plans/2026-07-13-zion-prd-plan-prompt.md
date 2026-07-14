# zion-prd-plan-prompt Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Criar a ponte `zion-prd-plan-prompt` (Passo 5c) que monta o prompt do `/speckit.plan` de uma feature injetando os ADRs confirmados como restrição a honrar, e propaga a mudança pelos assets, mapa de sync e docs.

**Architecture:** Skill no mesmo padrão das pontes existentes (`specify-prompt`/`constitution-prompt`): contrato de 5 fases, auto-delega a `zion-rewrite-prompt`, entrega o comando pronto e para. Os assets canônicos (`assets/quality-rules.md`, `assets/process-context.md`) são a fonte única; `scripts/asset-map.sh` mapeia asset→skill e `scripts/sync-assets.sh` regenera `skills/*/references/`. O pre-commit hook sincroniza automaticamente ao commitar.

**Tech Stack:** Markdown (SKILL.md + assets + docs), Bash (asset-map/sync/check), Git.

**Contexto de verificação:** não há test runner de código. A "suíte" é `scripts/check-assets.sh` (guard de drift entre `assets/` e `references/`) mais asserções por `grep` sobre o conteúdo e um dry-run manual do prompt contra o critério **plan-prompt**. Trabalhe na branch `feat/zion-prd-plan-prompt` (já criada; a spec já está commitada nela).

---

## File Structure

- **Create** `skills/zion-prd-plan-prompt/SKILL.md` — a skill (corpo = Fases 0–4 + anatomia). Responsável por orquestrar o Passo 5c.
- **Create** (via sync, não à mão) `skills/zion-prd-plan-prompt/references/quality-rules.md` — cópia derivada do asset canônico.
- **Modify** `assets/quality-rules.md` — nova linha de critério `plan-prompt`, nova seção `#anatomia-plan`, nota na `#fronteira`.
- **Modify** `assets/process-context.md` — registrar a 3ª ponte no passo 5.
- **Modify** `scripts/asset-map.sh` — adicionar `zion-prd-plan-prompt` à linha do `quality-rules.md`.
- **Modify** `README.md` — nota das pontes, linha na tabela de skills, linha na tabela de dependências.
- **Modify** `docs/como-usar.md` — contagem de skills, tabela de comandos, mermaid, seção narrativa da ponte, gate #5, resumo de bolso.
- **Modify** `docs/guia-prd-para-spec-kit.md` — nota da ponte no passo `/speckit.plan`.

Ordem: assets canônicos → SKILL.md → asset-map → sync/check → docs → verificação final. As edições de asset são commitadas com o hook rodando o sync (regenera `references/` no mesmo commit).

---

## Task 1: Editar `assets/quality-rules.md` (critério + anatomia + fronteira)

**Files:**
- Modify: `assets/quality-rules.md`

- [ ] **Step 1: Adicionar a linha de critério `plan-prompt`**

Depois do bullet `constitution-prompt` (que termina em `"boa cobertura")).`), acrescente:

```markdown
- **plan-prompt**: o prompt gerado referencia o `spec.md` da feature ∧ injeta os ADRs confirmados
  como restrição (honrar, não re-decidir) ∧ `success_criteria` = plano honra cada ADR ∧ cobre o
  resultado observável do `spec.md`.
```

O bloco a casar (exato) e substituir é:

```markdown
- **constitution-prompt**: o prompt gerado deriva princípios **decidíveis** (cada um com validador/
  limiar/teste) ∧ cada princípio rastreia a um NFR ou restrição de ADR ∧ **zero** princípio genérico
  ("código limpo", "boa cobertura").
```

por:

```markdown
- **constitution-prompt**: o prompt gerado deriva princípios **decidíveis** (cada um com validador/
  limiar/teste) ∧ cada princípio rastreia a um NFR ou restrição de ADR ∧ **zero** princípio genérico
  ("código limpo", "boa cobertura").
- **plan-prompt**: o prompt gerado referencia o `spec.md` da feature ∧ injeta os ADRs confirmados
  como restrição (honrar, não re-decidir) ∧ `success_criteria` = plano honra cada ADR ∧ cobre o
  resultado observável do `spec.md`.
```

- [ ] **Step 2: Adicionar a nota na seção `#fronteira`**

Logo após a linha que termina em `...sugere movê-la para o `plan.md` da feature.` (fim da `#fronteira`, antes de `## Critérios de conclusão`), insira:

```markdown

> A ponte `plan-prompt` é a única que **cruza** esta fronteira de propósito: monta o prompt do
> `/speckit.plan`, onde o "como" é decidido. Mesmo lá a guarda persiste, invertida — o plano fica
> **preso aos ADRs** já provados (veja `#anatomia-plan`), sem reabrir decisões.
```

- [ ] **Step 3: Adicionar a seção `#anatomia-plan` ao final do arquivo**

Ao final de `assets/quality-rules.md` (depois da seção `#anatomia-constitution`), acrescente:

```markdown

## Anatomia do prompt do plan {#anatomia-plan}

O input do `/speckit.plan` também é um prompt — montado a partir do `spec.md` da feature e dos ADRs
que o spike já provou. É a única ponte que **entra** no "como", presa ao que foi decidido. As tags:

- `<context>` — **a fonte, separando referência de instrução**: o `spec.md` da fatia (o o-quê que o
  plano realiza) e os **ADRs confirmados** (`ADR-00x: <decisão>`) como decisões fechadas.
- `<instructions>` — pede para **derivar** o plano técnico (o como) que realiza o `spec.md` **dentro**
  das decisões dos ADRs.
- `<constraints>` — o **guardião da fronteira, invertido**: em vez de "sem stack", escreva explícito
  "honre cada ADR listado; não re-decida o que um ADR já fixou". Secundário: "não expanda além do
  escopo do `spec.md`". É o que impede o spike de virar esforço órfão.
- `<success_criteria>` — o plano **honra cada ADR confirmado** ∧ cobre o resultado observável do
  `spec.md`. É o que o gate `/speckit.analyze` vai cobrar depois.
```

- [ ] **Step 4: Verificar as âncoras e o critério**

Run: `grep -nE "#anatomia-plan|plan-prompt.*referencia o|preso aos ADRs" assets/quality-rules.md`
Expected: 3 linhas — a âncora `{#anatomia-plan}`, o bullet de critério `plan-prompt`, e a nota da fronteira.

- [ ] **Step 5: Commit (o hook regenera os `references/` existentes)**

```bash
git add assets/quality-rules.md
git commit -m "docs(quality): critério plan-prompt, seção #anatomia-plan e nota de fronteira"
```

Nota: o pre-commit hook roda `sync-assets.sh` e inclui os `references/` das skills que já consomem `quality-rules.md`. Se o hook não estiver ativo, rode antes `./scripts/sync-assets.sh` e `git add skills/*/references/quality-rules.md`.

---

## Task 2: Editar `assets/process-context.md` (registrar a 3ª ponte)

**Files:**
- Modify: `assets/process-context.md:18-20`

- [ ] **Step 1: Substituir o item 5 da sequência**

Casar (exato):

```markdown
5. **Spec Kit por feature** — `constitution` e o ciclo
   `specify → clarify → plan → checklist → tasks → analyze → implement → converge` (fora do
   harness; pontes montadas por `/zion-prd-constitution-prompt` e `/zion-prd-specify-prompt`).
```

Substituir por:

```markdown
5. **Spec Kit por feature** — `constitution` e o ciclo
   `specify → clarify → plan → checklist → tasks → analyze → implement → converge` (fora do
   harness; pontes montadas por `/zion-prd-constitution-prompt`, `/zion-prd-specify-prompt` e
   `/zion-prd-plan-prompt`). A ponte `plan-prompt` é a única que **encosta** no "como": monta o
   prompt do `plan` limitado a honrar os ADRs já provados.
```

- [ ] **Step 2: Verificar**

Run: `grep -n "zion-prd-plan-prompt" assets/process-context.md`
Expected: 1 linha (dentro do item 5).

- [ ] **Step 3: Commit**

```bash
git add assets/process-context.md
git commit -m "docs(process): registrar a ponte plan-prompt no passo 5 da sequência"
```

---

## Task 3: Criar `skills/zion-prd-plan-prompt/SKILL.md`

**Files:**
- Create: `skills/zion-prd-plan-prompt/SKILL.md`

- [ ] **Step 1: Escrever o SKILL.md**

Conteúdo exato do arquivo:

```markdown
---
name: zion-prd-plan-prompt
description: Ponte do harness Zion Build PRD para o Spec Kit — monta o prompt do /speckit.plan de UMA feature injetando os ADRs confirmados como restrição a honrar, entrega pronto e para. Use para levar uma feature (spec.md + ADRs) ao passo plan do Spec Kit; não dispara o /speckit.* por você.
argument-hint: "Qual feature/spec.md levar ao plan (e, se quiser, os ADRs a honrar)"
metadata:
  author: zion-build-prd
user-invocable: true
disable-model-invocation: false
---

# zion-prd-plan-prompt — Ponte do harness para o Spec Kit (Passo 5c)

Prepara o input do `/speckit.plan` de UMA feature. É a **única ponte que entra no território do
"como"** — de propósito, e só o suficiente pra amarrar o que o spike provou. Não gera o `plan.md`
(isso é do `/speckit.plan`); monta o prompt que faz o plan nascer **honrando os ADRs**, entrega
pronto e para — o ciclo `/speckit.*` é seu. Regras em `references/quality-rules.md`.

## Fase 0 — Pré-requisito (aconselha)
Devem existir: `docs/adr/` com ≥1 ADR aceito **e** um `spec.md` da feature (specify+clarify já
rodados no Spec Kit). Sem ADR aceito → avise "sem ADR aceito não há o que honrar; recomendo
`/zion-prd-spike` antes". Sem `spec.md` → avise "recomendo `/speckit.specify` + `/speckit.clarify`
antes". Não bloqueie; pergunte se segue mesmo assim.

## Fase 1 — Levantar e confirmar os ADRs relevantes
1. Leia o `spec.md` da fatia e cruze com `docs/adr/`.
2. Proponha os ADRs relevantes àquela feature, cada um com uma linha de justificativa
   (ex.: "ADR-001 (Postgres) → a fatia persiste pedidos").
3. Peça ao usuário para **confirmar / adicionar / remover**. A lista confirmada por ele é a que vale.

**Guarda de suficiência (aconselha).** Se o `spec.md` for vago demais para inferir relevância, aponte
qual peça falta e por quê ela trava a inferência — **não fabrique** vínculo para preencher cota.
Proponha só o que o texto sustenta e peça a peça faltante. Não bloqueie.

## Fase 2/3 — Formatar e auto-delegar
Invoque `zion-rewrite-prompt` no mesmo turno para montar o prompt XML do `plan`, seguindo
`references/quality-rules.md` `#anatomia-plan`:
- `<context>` — o `spec.md` da fatia e os **ADRs confirmados** (`ADR-00x: <decisão>`) como fonte.
- `<instructions>` — **derivar** o plano técnico que realiza o `spec.md` dentro das decisões dos ADRs.
- `<constraints>` — o guardião **invertido**: "honre cada ADR listado; não re-decida o que um ADR já
  fixou". Secundário: "não expanda além do escopo do `spec.md`".
- `<success_criteria>` — o plano honra cada ADR confirmado ∧ cobre o resultado observável do `spec.md`.

Não invoque `deep-research` — a pesquisa já aconteceu no spike; o ADR é a decisão fechada.

## Fase 4 — Validar saída e handoff (aconselha)
Confira contra o critério **plan-prompt** de `#criterios-de-conclusao`: referencia o `spec.md` ∧
injeta os ADRs confirmados como restrição a honrar ∧ `success_criteria` amarra plano→ADRs. Então
**entregue o comando pronto** para o usuário disparar, por exemplo:

    /speckit.plan "<prompt montado>"

**PARE AQUI.** Não invoque `/speckit.plan` nem qualquer `/speckit.*` — o ciclo do Spec Kit é do
usuário. Este é o fim do território do harness.

## Saída
Um `/speckit.plan "..."` pronto para colar, mais o veredito das checagens da Fase 4.
```

- [ ] **Step 2: Verificar o frontmatter e o "PARE AQUI"**

Run: `grep -nE "^name: zion-prd-plan-prompt|PARE AQUI|#anatomia-plan" skills/zion-prd-plan-prompt/SKILL.md`
Expected: 3 linhas (name no frontmatter, o "PARE AQUI", a referência a `#anatomia-plan`).

- [ ] **Step 3: Commit**

```bash
git add skills/zion-prd-plan-prompt/SKILL.md
git commit -m "feat(skill): zion-prd-plan-prompt — ponte 5c para /speckit.plan"
```

---

## Task 4: Registrar no `asset-map.sh` e sincronizar

**Files:**
- Modify: `scripts/asset-map.sh:9`

- [ ] **Step 1: Adicionar a skill à linha do `quality-rules.md`**

Casar (exato):

```bash
  "assets/quality-rules.md                zion-prd-discovery zion-prd-spike zion-prd-write zion-prd-decompose zion-prd-constitution-prompt zion-prd-specify-prompt"
```

Substituir por:

```bash
  "assets/quality-rules.md                zion-prd-discovery zion-prd-spike zion-prd-write zion-prd-decompose zion-prd-constitution-prompt zion-prd-specify-prompt zion-prd-plan-prompt"
```

(Não adicione à linha do `process-context.md` — as pontes não consomem esse asset.)

- [ ] **Step 2: Sincronizar (gera o `references/` da nova skill)**

Run: `./scripts/sync-assets.sh`
Expected: `sync-assets: ok` e o arquivo `skills/zion-prd-plan-prompt/references/quality-rules.md` passa a existir.

- [ ] **Step 3: Verificar que não há drift**

Run: `./scripts/check-assets.sh`
Expected: `check-assets: sem drift`

- [ ] **Step 4: Confirmar o novo reference**

Run: `diff -q assets/quality-rules.md skills/zion-prd-plan-prompt/references/quality-rules.md && echo IGUAIS`
Expected: `IGUAIS`

- [ ] **Step 5: Commit**

```bash
git add scripts/asset-map.sh skills/zion-prd-plan-prompt/references/quality-rules.md
git commit -m "build(assets): mapear quality-rules para zion-prd-plan-prompt e sincronizar reference"
```

---

## Task 5: Propagar nos docs de usuário (README + como-usar + guia)

**Files:**
- Modify: `README.md:19-21`, `README.md:39-40`, `README.md:47`
- Modify: `docs/como-usar.md:20`, `:42`, `:52`, `:248`, `:288-290`, `:317`
- Modify: `docs/guia-prd-para-spec-kit.md:214`

- [ ] **Step 1: README — nota das pontes**

Casar:

```markdown
> As pontes `/zion-prd-constitution-prompt` e `/zion-prd-specify-prompt` **montam prompts** para o
> `/speckit.constitution` e `/speckit.specify`. Instale o **Spec Kit** separadamente para
> rodar o ciclo `/speckit.*`.
```

Substituir por:

```markdown
> As pontes `/zion-prd-constitution-prompt`, `/zion-prd-specify-prompt` e `/zion-prd-plan-prompt`
> **montam prompts** para o `/speckit.constitution`, `/speckit.specify` e `/speckit.plan`. Instale o
> **Spec Kit** separadamente para rodar o ciclo `/speckit.*`.
```

- [ ] **Step 2: README — linha na tabela de skills**

Casar:

```markdown
| `/zion-prd-specify-prompt` | Ponte → `/speckit.specify` |
| `/zion-adr-new` | Cria um ADR em `docs/adr/` |
```

Substituir por:

```markdown
| `/zion-prd-specify-prompt` | Ponte → `/speckit.specify` |
| `/zion-prd-plan-prompt` | Ponte → `/speckit.plan` |
| `/zion-adr-new` | Cria um ADR em `docs/adr/` |
```

- [ ] **Step 3: README — tabela de dependências (usuárias de `zion-rewrite-prompt`)**

Casar:

```markdown
| `zion-rewrite-prompt` | `/zion-prd-constitution-prompt`, `/zion-prd-specify-prompt` | Incluída (skill first-party deste repo) |
```

Substituir por:

```markdown
| `zion-rewrite-prompt` | `/zion-prd-constitution-prompt`, `/zion-prd-specify-prompt`, `/zion-prd-plan-prompt` | Incluída (skill first-party deste repo) |
```

- [ ] **Step 4: como-usar — contagem de skills e nota das pontes**

Casar:

```markdown
Isso instala as 7 skills em `.claude/skills/` do seu projeto. Instale o **Spec Kit** à parte — as pontes `/zion-prd-constitution-prompt` e `/zion-prd-specify-prompt` apenas montam os prompts do `/speckit.*`.
```

Substituir por:

```markdown
Isso instala as 8 skills em `.claude/skills/` do seu projeto. Instale o **Spec Kit** à parte — as pontes `/zion-prd-constitution-prompt`, `/zion-prd-specify-prompt` e `/zion-prd-plan-prompt` apenas montam os prompts do `/speckit.*`.
```

- [ ] **Step 5: como-usar — linha na tabela de comandos**

Casar:

```markdown
| `/zion-prd-specify-prompt` | Ponte p/ 5b | backlog de fatias | prompt do `/speckit.specify` | `zion-rewrite-prompt` |
```

Substituir por:

```markdown
| `/zion-prd-specify-prompt` | Ponte p/ 5b | backlog de fatias | prompt do `/speckit.specify` | `zion-rewrite-prompt` |
| `/zion-prd-plan-prompt` | Ponte p/ 5c | `spec.md` da feature + `docs/adr/` | prompt do `/speckit.plan` | `zion-rewrite-prompt` |
```

- [ ] **Step 6: como-usar — nó no mermaid**

Casar:

```markdown
    D --> E["/zion-prd-specify-prompt"]
    G -.->|handoff 1×| H["/speckit.constitution (você)"]
    E -.->|handoff| F["/speckit.* (você)"]
```

Substituir por:

```markdown
    D --> E["/zion-prd-specify-prompt"]
    E --> P["/zion-prd-plan-prompt"]
    G -.->|handoff 1×| H["/speckit.constitution (você)"]
    E -.->|handoff| F["/speckit.* (você)"]
    P -.->|handoff| F
```

- [ ] **Step 7: como-usar — seção narrativa da ponte plan**

Casar (fim da seção do specify-prompt):

```markdown
**PARE.** A partir daqui o ciclo `/speckit.*` é seu.

---

## Os gates em ação (o que você vê)
```

Substituir por:

```markdown
**PARE.** A partir daqui o ciclo `/speckit.*` é seu.

### Ponte — `/zion-prd-plan-prompt`

Depois do `specify`+`clarify` da fatia, leve a feature ao `plan` honrando o que o spike provou:

```text
/zion-prd-plan-prompt A feature R0 (prévia ao digitar + persistência): honre os ADRs de render e de persistência local.
```

Lê o `spec.md` da fatia, cruza com `docs/adr/`, propõe os ADRs relevantes para você confirmar, e
delega a `zion-rewrite-prompt` montando o XML de `#anatomia-plan`. **Entrega o comando pronto** (não
dispara nada):

```text
/speckit.plan "
<context>
spec.md da fatia R0 (prévia ao digitar; persistência entre sessões).
ADR-001: motor de render escolhido. ADR-003: persistência local escolhida.
</context>
<instructions>
Derive o plano técnico que realiza o spec.md dentro das decisões dos ADRs acima.
</instructions>
<constraints>
Honre cada ADR listado; não re-decida o que um ADR já fixou. Não expanda além do escopo do spec.md.
</constraints>
<success_criteria>
O plano honra ADR-001 e ADR-003 e cobre o resultado observável do spec.md.
</success_criteria>
"
```

**PARE.** A partir daqui o ciclo `/speckit.*` é seu.

---

## Os gates em ação (o que você vê)
```

- [ ] **Step 8: como-usar — gate #5 (handoff)**

Casar:

```markdown
As duas pontes **entregam** o texto e **param** — nunca disparam um `/speckit.*`.
`/zion-prd-constitution-prompt` entrega o `/speckit.constitution` (bootstrap, 1×) e
`/zion-prd-specify-prompt` entrega o `/speckit.specify` (por fatia). O ciclo do Spec Kit é seu.
```

Substituir por:

```markdown
As pontes **entregam** o texto e **param** — nunca disparam um `/speckit.*`.
`/zion-prd-constitution-prompt` entrega o `/speckit.constitution` (bootstrap, 1×),
`/zion-prd-specify-prompt` entrega o `/speckit.specify` (por fatia) e `/zion-prd-plan-prompt`
entrega o `/speckit.plan` (por feature, honrando os ADRs). O ciclo do Spec Kit é seu.
```

- [ ] **Step 9: como-usar — resumo de bolso (novo passo 7)**

Casar:

```markdown
6. `/zion-prd-specify-prompt <fatia>` → `/speckit.specify "..."` pronto → **você** dispara o Spec Kit.
```

Substituir por:

```markdown
6. `/zion-prd-specify-prompt <fatia>` → `/speckit.specify "..."` pronto → **você** dispara o Spec Kit.
7. `/zion-prd-plan-prompt <feature>` → `/speckit.plan "..."` pronto (honra os ADRs) → **você** dispara o plan.
```

- [ ] **Step 10: guia — nota da ponte no passo `/speckit.plan`**

Casar (o bloco do passo 3 PLAN):

```markdown
  # 3) PLAN — AQUI SIM a stack e o "como".
  /speckit.plan  "<linguagem/framework>; <bibliotecas>; <estratégia de estado>;
  <componente crítico> como função pura testável; <parâmetros de performance>."
```

Substituir por:

```markdown
  # 3) PLAN — AQUI SIM a stack e o "como".
  # Ponte do harness: `/zion-prd-plan-prompt <feature>` monta esse prompt injetando os ADRs
  # confirmados como restrição (honrar, não re-decidir) e entrega o `/speckit.plan` pronto.
  /speckit.plan  "<linguagem/framework>; <bibliotecas>; <estratégia de estado>;
  <componente crítico> como função pura testável; <parâmetros de performance>."
```

- [ ] **Step 11: Verificar que não sobrou nenhuma lista de pontes desatualizada**

Run: `grep -rncE "zion-prd-plan-prompt" README.md docs/como-usar.md docs/guia-prd-para-spec-kit.md`
Expected: `README.md:3`, `docs/como-usar.md:7`, `docs/guia-prd-para-spec-kit.md:1`.

- [ ] **Step 12: Commit**

```bash
git add README.md docs/como-usar.md docs/guia-prd-para-spec-kit.md
git commit -m "docs: refletir a ponte zion-prd-plan-prompt (5c) no README e guias"
```

---

## Task 6: Verificação final ponta a ponta

**Files:** *(nenhum — só validação)*

- [ ] **Step 1: Guard de assets sem drift**

Run: `./scripts/check-assets.sh`
Expected: `check-assets: sem drift`

- [ ] **Step 2: A nova skill tem pasta == name, frontmatter e reference**

Run: `ls skills/zion-prd-plan-prompt && ls skills/zion-prd-plan-prompt/references`
Expected: `SKILL.md` e `references/` no primeiro; `quality-rules.md` no segundo.

- [ ] **Step 3: Exatamente 9 skills no layout flat**

Run: `ls -d skills/*/ | wc -l`
Expected: `9`

- [ ] **Step 4: Dry-run manual do critério plan-prompt (julgamento)**

Leia `skills/zion-prd-plan-prompt/SKILL.md` e confirme, contra o critério **plan-prompt** de `assets/quality-rules.md` `#criterios-de-conclusao`, que a Fase 4 cobra as três cláusulas: (1) referencia o `spec.md`; (2) injeta ADRs confirmados como restrição a honrar; (3) `success_criteria` amarra plano→ADRs. Confirme também que a Fase 2/3 aponta para `#anatomia-plan` e que existe um "PARE AQUI" que proíbe disparar `/speckit.*`.
Expected: as três cláusulas presentes, a referência a `#anatomia-plan` presente, o "PARE AQUI" presente.

- [ ] **Step 5: Árvore limpa e histórico coerente na branch**

Run: `git status --porcelain && git log --oneline -6`
Expected: working tree limpo; os commits das Tasks 1–5 presentes sobre a spec (`docs(spec): design da ponte...`).
```
