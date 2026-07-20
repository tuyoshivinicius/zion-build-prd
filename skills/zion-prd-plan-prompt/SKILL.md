---
name: zion-prd-plan-prompt
description: Ponte do harness Zion Build PRD para o Spec Kit — monta o prompt do /speckit.plan de UMA feature injetando os ADRs confirmados — e, quando existe, a prosa estrutural do docs/architecture.md do produto — como restrição a honrar, entrega pronto e para. Use para levar uma feature (spec.md + ADRs) ao passo plan do Spec Kit; não dispara o /speckit.* por você.
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

`docs/architecture.md` do produto é opcional: existindo, a prosa estrutural dele entra no prompt
(ADR-015); ausente → aconselhe `/zion-speckit-install` (não bloqueie).

## Fase 1 — Levantar e confirmar os ADRs relevantes
1. Leia o `spec.md` da spec e cruze com `docs/adr/`; se `docs/architecture.md` existir, extraia a
   **narrativa estrutural** pelo marcador — o conteúdo entre `<!-- zion:narrativa:start … -->` e
   `<!-- zion:narrativa:end -->`, **sem** os marcadores — mais a prosa da §2 (Integrações externas).
   Não raspe a §1 inteira: o que está fora do bloco é ruído de esqueleto. Bloco ausente ou só com
   placeholder `_(…)_` → não há narrativa; avise que a §1 nunca foi ditada e aconselhe
   `/zion-prd-decompose --narrativa` (não bloqueie).
2. Proponha os ADRs relevantes àquela feature, cada um com uma linha de justificativa
   (ex.: "ADR-001 (Postgres) → a spec persiste pedidos").
3. Peça ao usuário para **confirmar / adicionar / remover**. A lista confirmada por ele é a que vale.

**Guarda de suficiência (aconselha).** Se o `spec.md` for vago demais para inferir relevância, aponte
qual peça falta e por quê ela trava a inferência — **não fabrique** vínculo para preencher cota.
Proponha só o que o texto sustenta e peça a peça faltante. Não bloqueie.

**Avisos de defasagem (ecoe, não corrija).** Se o bloco `zion:narrativa-avisos` do
`docs/architecture.md` trouxer `narrativa-superseded` ou `narrativa-defasada`, ecoe-os antes de
montar o prompt: a narrativa que você vai injetar pode estar velha em relação aos ADRs. A cura é
`/zion-prd-decompose --narrativa`; o Autor decide se cura agora ou segue (`RN-01`).

## Fase 2/3 — Montar o prompt (você mesmo)
Monte, no mesmo turno, o prompt do `plan` em **linguagem natural (prosa)**, seguindo
`references/quality-rules.md` `#anatomia-plan`. É **conteúdo, não formato**: não use tags XML nem
dite as seções do artefato — o `/speckit.plan` já tem o próprio template e já carrega o `spec.md`
como fonte (não repita os requisitos). Em prosa, o prompt deve:
- Listar os **ADRs confirmados** (`ADR-00x: <decisão>`) como decisões fechadas a honrar: "honre cada
  ADR listado; não re-decida o que um ADR já fixou".
- Injetar a **narrativa estrutural** extraída do bloco `zion:narrativa` mais a §2 do
  `docs/architecture.md` como restrição a honrar: resuma fiel os componentes de topo e os contratos
  externos — não invente estrutura que o documento não tem. O **interior** de cada componente é o
  que o `plan` vai decidir; a §1 só fixa a topologia e os contratos. A injeção é seletiva por passo
  (RN-02): só o plan recebe este documento; specify e clarify nunca.
- Pedir o plano técnico (stack, arquitetura, restrições) que realiza o resultado observável do
  `spec.md` **dentro** dessas decisões.
- Blindar o escopo em prosa: "não expanda além do escopo do `spec.md`".

Não invoque `deep-research` — a pesquisa já aconteceu no spike; o ADR é a decisão fechada.

## Fase 4 — Validar saída e handoff (aconselha)
Confira contra o critério **plan-prompt** de `#criterios-de-conclusao`: referencia o `spec.md` ∧
injeta os ADRs confirmados — e, quando existe, a prosa estrutural do `architecture.md` do produto —
como restrição a honrar ∧ deixa claro que o plano honra cada ADR e cobre o resultado observável do
`spec.md`. Então
**entregue o comando pronto** para o usuário disparar, por exemplo:

    /speckit.plan "<prompt montado>"

**PARE AQUI.** Não invoque `/speckit.plan` nem qualquer `/speckit.*` — o ciclo do Spec Kit é do
usuário. Este é o fim do território do harness.

## Saída
Um `/speckit.plan "..."` pronto para colar, mais o veredito das checagens da Fase 4.
