# Design — `zion-prd-plan-prompt` (Ponte 5c do harness para o Spec Kit)

- **Data:** 2026-07-13
- **Status:** aprovado (brainstorming)
- **Autor:** zion-build-prd

## Problema

O Estágio 2 do harness (`zion-prd-spike`) produz ADRs — decisões estruturantes de *como*, já
provadas com spike descartável. Mas o harness hoje para no `/speckit.specify` (Passo 5b): as duas
pontes existentes (`constitution-prompt`, `specify-prompt`) entregam o prompt e param na fronteira do
"o-quê". Quando o usuário chega no `/speckit.plan` — o passo onde o *como* realmente é decidido — ele
**re-alimenta manualmente** as restrições dos ADRs, e o `plan` corre o risco de **reinventar uma
decisão que já foi provada**. O esforço de spike vira órfão: sem ponte garantida até onde a decisão
é implementada.

## Objetivo

Criar `zion-prd-plan-prompt`, a **terceira e única ponte que entra no território do "como"** — de
propósito, e só o suficiente pra amarrar o que o spike provou. Ela **não gera o `plan.md`** (isso é
do `/speckit.plan`); monta o *prompt* que faz o plan nascer **honrando os ADRs**, e para na fronteira.

Abordagem escolhida: **A — Ponte fina de injeção de ADR** (espelha `specify-prompt` osso a osso; a
única lógica nova é inferir+confirmar os ADRs relevantes do `spec.md`). Rejeitadas: B (assistente
"grosso" que rascunha o plano — invade o trabalho do `/speckit.plan`, quebra o "PARE AQUI"); C (só
checklist de ADRs — quebra o padrão "entrega comando pronto" das irmãs).

## Seção 1 — Identidade e posicionamento

- **Nome/passo:** `zion-prd-plan-prompt` — Ponte do harness para o Spec Kit (**Passo 5c**).
- **Sequência:** 5a `constitution-prompt` (bootstrap, 1×/projeto) → 5b `specify-prompt` (por fatia) →
  **5c `plan-prompt` (por fatia, depois do `clarify`, antes do `/speckit.plan`)**.
- **Natureza:** primeira e única ponte que entra no "como", limitada a honrar decisões já provadas.
- **Guarda-assinatura:** honrar os ADRs (rastreabilidade ADR→plan).
- **Fim de território:** entrega o `/speckit.plan "..."` pronto e **PARA**. Não dispara `/speckit.*`.

## Seção 2 — Contrato de 5 fases (comportamento)

Espelha `specify-prompt`; toda gate **aconselha** (não bloqueia). Lógica nova só na Fase 1.

- **Fase 0 — Pré-requisito (aconselha):** `docs/adr/` com ≥1 ADR aceito **e** um `spec.md` da feature
  (specify+clarify já rodados).
  - Sem ADR aceito → "sem ADR aceito não há o que honrar; recomendo `/zion-prd-spike` antes".
  - Sem `spec.md` → "recomendo `/speckit.specify` + `/speckit.clarify` antes".
  - Não bloqueia; pergunta se segue mesmo assim.

- **Fase 1 — Levantar e confirmar ADRs relevantes (lógica nova):**
  1. Lê o `spec.md` da fatia e cruza com `docs/adr/`.
  2. Propõe os ADRs relevantes àquela feature, cada um com uma linha de justificativa
     (ex.: "ADR-001 (Postgres) → a fatia persiste pedidos").
  3. Pede pra **confirmar / adicionar / remover**. A lista confirmada pelo usuário é a que vale.
  4. **Guarda de suficiência:** se o `spec.md` for vago demais pra inferir relevância, aponta qual
     peça falta e por quê trava a inferência — **não fabrica** vínculo pra preencher cota. Não bloqueia.

- **Fase 2/3 — Formatar e auto-delegar:** invoca `zion-rewrite-prompt` no mesmo turno pra montar o
  XML do `plan`, seguindo `quality-rules.md` `#anatomia-plan`. **Não** invoca `deep-research` — a
  pesquisa já aconteceu no spike; o ADR é a decisão fechada.

- **Fase 4 — Validar saída e handoff (aconselha):** confere contra o critério **plan-prompt** de
  `#criterios-de-conclusao`. Então entrega o comando pronto:

      /speckit.plan "<prompt montado>"

  **PARE AQUI.** Não dispara nenhum `/speckit.*` — o ciclo do Spec Kit é do usuário.

## Seção 3 — Anatomia do prompt (`#anatomia-plan`, novo em `quality-rules.md`)

O `zion-rewrite-prompt` monta o XML do `/speckit.plan` com estas tags:

- **`<context>`** — material de origem, separando referência de instrução:
  - o `spec.md` da fatia (o **o-quê** que o plano vai realizar);
  - os **ADRs confirmados** na Fase 1, cada um citado como decisão fechada (`ADR-00x: <decisão>`).
- **`<instructions>`** — derivar o plano técnico (o **como**) que realiza o `spec.md` **dentro** das
  decisões dos ADRs.
- **`<constraints>`** — o **guardião da fronteira, invertido** em relação ao specify: em vez de "sem
  stack", escreve explícito **"honre cada ADR listado; não re-decida o que um ADR já fixou"**.
  Secundário/opcional: "não expanda além do escopo do `spec.md`".
- **`<success_criteria>`** — o plano **honra cada ADR confirmado** ∧ cobre o resultado observável do
  `spec.md`. Antecipa o gate `/speckit.analyze`.

Contraste (fixa a fronteira):

| Ponte | `<constraints>` blinda | Direção |
|---|---|---|
| `specify` | "sem stack — stack só no plan" | mantém o **como** fora |
| `constitution` | "decidível + rastreável a NFR/ADR" | qualidade do princípio |
| **`plan`** | **"honre os ADRs; não re-decida"** | traz o **como**, preso ao que foi provado |

## Seção 4 — Mudanças de doc/asset

1. **`skills/zion-prd-plan-prompt/SKILL.md`** (novo) — frontmatter no padrão das irmãs:
   `name`, `description` (ponte 5c; lê ADRs+`spec.md`; monta prompt do plan; entrega e para; não
   dispara `/speckit.*`), `argument-hint: "Qual feature/spec.md levar ao plan (e, se quiser, os ADRs
   a honrar)"`, `metadata.author: zion-build-prd`, `user-invocable: true`,
   `disable-model-invocation: false`. Corpo = Seções 1–3.

2. **`assets/quality-rules.md`** (canônico) — três edições:
   - `#criterios-de-conclusao`: nova linha **plan-prompt** — *"o prompt gerado referencia o `spec.md`
     da feature ∧ injeta os ADRs confirmados como restrição (honrar, não re-decidir) ∧
     `success_criteria` = plano honra cada ADR ∧ cobre o observável do spec"*.
   - Nova seção **`#anatomia-plan`** (Seção 3 acima).
   - `#fronteira`: nota curta de que a `plan-prompt` é a ponte que **cruza** a fronteira de propósito,
     presa aos ADRs — pra o doc não se contradizer.

3. **`assets/process-context.md`** (canônico) — no passo 5, registrar a terceira ponte: `plan-prompt`
   monta o prompt do `plan` e é o ponto onde o harness **encosta** no "como", limitado a honrar ADRs.

4. **`scripts/asset-map.sh`** — adicionar `zion-prd-plan-prompt` à linha do `assets/quality-rules.md`
   (as pontes consomem só esse asset). **Não** entra na linha do `process-context.md`, igual às irmãs.

5. **Sincronizar e validar** — rodar `scripts/sync-assets.sh` (gera
   `skills/zion-prd-plan-prompt/references/quality-rules.md`) e `scripts/check-assets.sh`. Fora do
   asset system, varrer README/docs/guias por listas de "8 skills" que precisem virar "9".

## Critério de conclusão do design

A skill existe, é sincronizada e validada por `check-assets.sh`, e um passo-a-passo manual
(spec.md + ADRs → `/zion-prd-plan-prompt` → prompt do `plan` que honra os ADRs) produz um comando
`/speckit.plan "..."` que passa no critério **plan-prompt** de `#criterios-de-conclusao`.
