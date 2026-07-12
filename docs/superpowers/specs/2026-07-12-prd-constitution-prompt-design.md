# Design — `/prd-constitution-prompt` (ponte do harness para o Passo 5a)

> Data: 2026-07-12 · Status: aprovado para plano

## Objetivo

Adicionar ao harness-prd uma etapa `/prd-constitution-prompt`, **equivalente e paralela** a
`/prd-specify-prompt`, que facilita o **Bootstrap do Spec Kit** (Passo 5a do guia): monta um prompt
para o usuário criar a `constitution`, derivando **princípios decidíveis** dos **NFRs + restrições de
ADRs** da PRD, entrega o comando pronto (`/speckit.constitution "..."`) e **para** — o ciclo
`/speckit.*` é do usuário.

## Contexto

O harness é um conjunto de skills `prd-*` que leva o usuário de descoberta → spikes → PRD →
decomposição, e então faz a **ponte** para o Spec Kit. Hoje existe **uma** ponte:

- `prd-specify-prompt` → Passo **5b** (por fatia vertical): monta o `/speckit.specify`, guarda a
  fronteira **sem-stack**, delega a `rewrite-prompt`, referencia âncoras de
  `.specify/prd/quality-rules.md` (`#anatomia-specify`, critério `specify-prompt`), entrega e **para**.

Falta a ponte para o Passo **5a** (bootstrap, uma vez por projeto): a `constitution`. O guia
(`docs/guia-prd-para-spec-kit.md` §165–178) descreve o Passo 5a como escrever a `constitution`
**derivada** dos NFRs e restrições (ADRs) da PRD, com princípios **decidíveis** — não genéricos.

## Diferença-chave em relação ao `specify-prompt`

| Dimensão | `prd-specify-prompt` (5b) | `prd-constitution-prompt` (5a) |
|---|---|---|
| Cadência | por fatia vertical | **uma vez por projeto** (bootstrap) |
| Entrada | fatia do backlog (`/prd-decompose`) | **NFRs + restrições de ADRs** de `docs/PRD.md` |
| Pré-requisito | backlog de fatias | `docs/PRD.md` (saída de `/prd-write`); **não** depende de decompose |
| Guarda de fronteira | **sem-stack** (stack só no `plan`) | **decidível-não-genérico ∧ rastreável a NFR/ADR** |
| Saída | `/speckit.specify "..."` pronto | `/speckit.constitution "..."` pronto |

**Nota sobre a guarda:** ao contrário do `specify`, a `constitution` legitimamente carrega padrões
técnicos transversais vindos de ADRs/NFRs (ex.: "componente crítico é função pura com testes de
snapshot"). Portanto a guarda **não** é "sem-stack"; é **decidibilidade** (todo princípio é
objetivamente checável — validador/limiar/teste) + **rastreabilidade** (cada princípio aponta a um
NFR ou restrição de ADR). Princípios genéricos ("código limpo", "boa cobertura") são apontados.

## Componentes

### 1. `.claude/skills/prd-constitution-prompt/SKILL.md`

Espelha a anatomia de fases do `prd-specify-prompt`.

**Frontmatter:**
- `name: prd-constitution-prompt`
- `description`: ponte para o Spec Kit — monta o prompt do `/speckit.constitution` derivando
  princípios decidíveis dos NFRs/restrições da PRD, e entrega para você disparar.
- `argument-hint`: opcional — áreas/princípios a enfatizar; senão deriva dos NFRs/ADRs da PRD.
- `metadata.author: zion-mermaid-editor`; `user-invocable: true`; `disable-model-invocation: false`.

**Fases:**
- **Fase 0 — Pré-requisito (aconselha):** deve existir `docs/PRD.md` com NFRs/restrições. Se não
  houver, avisa ("recomendo `/prd-write` antes") e pergunta se segue. Marca que é bootstrap
  **1×/projeto**.
- **Fase 1 — Validar entrada bruta (aconselha):** colhe NFRs mensuráveis + restrições de ADRs. Se um
  princípio proposto é **genérico** ou **não rastreia** a nenhum NFR/ADR, aponta (ref.
  `#anatomia-constitution`). Não bloqueia.
- **Fase 2/3 — Formatar e auto-delegar:** invoca `rewrite-prompt` no mesmo turno, seguindo
  `quality-rules.md` `#anatomia-constitution`:
  - `<context>` — NFRs (`NFR-xx`) e restrições de ADRs como **fonte/referência**.
  - `<instructions>` — derivar princípios **decidíveis** a partir dessa fonte.
  - `<constraints>` — cada princípio objetivamente checável (validador/limiar/teste) ∧ rastreável a
    um NFR/ADR; proíbe platitudes genéricas.
  - `<success_criteria>` — a `constitution` só tem princípios decidíveis, cada um rastreável a
    NFR/ADR.
- **Fase 4 — Validar saída e handoff (aconselha):** confere contra o critério **constitution-prompt**
  de `#criterios-de-conclusao`. Então **entrega** `/speckit.constitution "..."` e **PARA AQUI** — não
  invoca `/speckit.constitution` nem qualquer `/speckit.*`.

**Saída:** um `/speckit.constitution "..."` pronto para colar + o veredito das checagens da Fase 4.

### 2. `.specify/prd/quality-rules.md` — fonte única de verdade (2 adições)

- Em `#criterios-de-conclusao`, novo item:
  - **constitution-prompt**: o prompt gerado deriva princípios **decidíveis** (com validador/limiar/
    teste) ∧ cada princípio rastreia a um NFR/restrição de ADR ∧ **zero** princípio genérico ("código
    limpo", "boa cobertura").
- Nova âncora `#anatomia-constitution` (paralela a `#anatomia-specify`) descrevendo as 4 tags do
  prompt do `constitution`:
  - `<context>` — os NFRs e restrições de ADRs como **fonte** (referência), não como princípio já
    pronto.
  - `<instructions>` — **derivar** princípios decidíveis dessa fonte.
  - `<constraints>` — o **guardião da decidibilidade**: cada princípio tem um critério objetivo
    (validador/limiar/teste) e rastreia a um NFR/ADR; proíbe genérico.
  - `<success_criteria>` — todo princípio é decidível ∧ rastreável; nenhum genérico.

### 3. Guias — coerência

- **`docs/como-usar-o-harness-prd.md`:**
  - +linha na tabela "Mapa rápido dos comandos": `/prd-constitution-prompt` | Ponte p/ 5a (bootstrap)
    | `docs/PRD.md` (NFRs+ADRs) | prompt do `/speckit.constitution` | `rewrite-prompt`.
  - +nó no fluxo mermaid: ponte bootstrap 1× para o território `/speckit.*`.
  - nova seção "Ponte (bootstrap, 1×) — `/prd-constitution-prompt`" antes da seção do specify, com
    exemplo de saída.
  - item #5 dos "gates em ação" (handoff) cita as **duas** pontes entregando e parando.
  - +passo no "resumo de bolso" (bootstrap antes do specify).
- **`docs/guia-prd-para-spec-kit.md`:**
  - nota no Passo 5a de que o harness oferece `/prd-constitution-prompt` como ponte (monta o prompt e
    entrega; o `/speckit.constitution` é do usuário).
  - a linha `rewrite-prompt` na tabela de skills passa a citar **P5a** (constitution) **e** P5b
    (specify).

## Fora de escopo (YAGNI)

- Não disparar `/speckit.constitution` — o território do Spec Kit é do usuário (mesma regra do
  `specify-prompt`).
- Não gerar/editar `.specify/memory/constitution.md` diretamente — isso é papel do `/speckit.*`.
- Não tornar o decompose pré-requisito do constitution.

## Critério de aceite do trabalho

- `.claude/skills/prd-constitution-prompt/SKILL.md` existe, espelha as fases do `specify-prompt` e
  contém "PARE AQUI".
- `quality-rules.md` tem o critério `constitution-prompt` e a âncora `#anatomia-constitution`.
- Os dois guias referenciam a nova ponte de forma coerente.
