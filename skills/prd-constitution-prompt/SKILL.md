---
name: prd-constitution-prompt
description: Ponte para o Spec Kit — monta o prompt do /speckit.constitution derivando princípios decidíveis dos NFRs/restrições da PRD, e entrega para você disparar
argument-hint: "Opcional: áreas/princípios a enfatizar na constitution (senão, deriva dos NFRs/ADRs da PRD)"
metadata:
  author: zion-mermaid-editor
user-invocable: true
disable-model-invocation: false
---

# prd-constitution-prompt — Ponte do harness para o Spec Kit (Passo 5a)

Prepara o input do `/speckit.constitution` — o **bootstrap, uma vez por projeto**. Monta o prompt
que deriva princípios **decidíveis** dos NFRs e restrições (ADRs) da PRD, entrega pronto e para — o
ciclo `/speckit.*` é seu. Regras em `references/quality-rules.md`.

## Fase 0 — Pré-requisito (aconselha)
Deve existir `docs/PRD.md` (saída de `/prd-write`) com NFRs e restrições vindas de ADRs. Não depende
de `/prd-decompose`. Se não houver PRD, avise ("recomendo `/prd-write` antes") e pergunte se segue.
Lembre que isto é bootstrap: roda **uma vez por projeto**.

## Fase 1 — Validar entrada bruta (aconselha)
Colha os NFRs mensuráveis e as restrições dos ADRs — é deles que os princípios saem. Se um princípio
proposto é **genérico** ("código limpo", "boa cobertura") sem critério objetivo, ou **não rastreia**
a nenhum NFR/ADR, avise: "princípio não decidível/rastreável" (veja `quality-rules.md`
`#anatomia-constitution`). A guarda aqui **não** é "sem-stack" — a constitution carrega padrões
técnicos transversais de propósito; a guarda é **decidibilidade + rastreabilidade**. Não bloqueie.

## Fase 2/3 — Formatar e auto-delegar
Invoque `rewrite-prompt` no mesmo turno para montar o prompt do `constitution`, seguindo
`quality-rules.md` `#anatomia-constitution`:
- `<context>` — os NFRs (`NFR-xx`) e restrições de ADRs como **fonte** (material de origem), não
  como princípio já pronto.
- `<instructions>` — **derivar** princípios decidíveis dessa fonte.
- `<constraints>` — blinda a decidibilidade: cada princípio tem validador/limiar/teste e rastreia a
  um NFR/ADR; proíbe genérico.
- `<success_criteria>` — todo princípio é decidível ∧ rastreável; nenhum genérico.

## Fase 4 — Validar saída e handoff (aconselha)
Confira contra o critério **constitution-prompt** de `#criterios-de-conclusao`: princípios decidíveis
∧ rastreáveis a NFRs/ADRs ∧ zero genérico. Então **entregue o comando pronto** para o usuário
disparar, por exemplo:

    /speckit.constitution "<prompt montado>"

**PARE AQUI.** Não invoque `/speckit.constitution` nem qualquer `/speckit.*` — o ciclo do Spec Kit é
do usuário. Este é o fim do território do harness.

## Saída
Um `/speckit.constitution "..."` pronto para colar, mais o veredito das checagens da Fase 4.
