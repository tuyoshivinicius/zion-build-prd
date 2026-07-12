---
name: prd-specify-prompt
description: Ponte para o Spec Kit — monta o prompt do /speckit.specify de uma fatia vertical, blindando a fronteira sem-stack, e entrega para você disparar
argument-hint: "Qual fatia vertical do backlog transformar em prompt de specify"
metadata:
  author: zion-mermaid-editor
user-invocable: true
disable-model-invocation: false
---

# prd-specify-prompt — Ponte do harness para o Spec Kit (Passo 5b)

Prepara o input do `/speckit.specify` de UMA fatia vertical. Encerra o território do harness: entrega
o prompt pronto e para — o ciclo `/speckit.*` é seu. Regras em `.specify/prd/quality-rules.md`.

## Fase 0 — Pré-requisito (aconselha)
Deve existir um backlog de fatias verticais (saída de `/prd-decompose`). O usuário aponta **qual**
fatia. Se não houver backlog, avise ("recomendo `/prd-decompose` antes") e pergunte se segue.

## Fase 1 — Validar entrada bruta (aconselha)
A fatia deve ter um **resultado observável** (o que o usuário consegue fazer/ver ao final). Se o
usuário descreve a fatia citando **biblioteca/framework/stack**, avise: "isso é do `plan`, não do
`specify`" (veja `quality-rules.md` `#fronteira`). Não bloqueie.

## Fase 2/3 — Formatar e auto-delegar
Invoque `rewrite-prompt` no mesmo turno para montar o prompt XML do `specify`, seguindo
`quality-rules.md` `#anatomia-specify`:
- `<constraints>` — blinda "não citar linguagem/framework/bibliotecas; stack só no `plan`".
- `<context>` — `RF-xx` e ADRs relevantes como **referência**, não como requisito.
- `<success_criteria>` — o resultado observável da fatia.

## Fase 4 — Validar saída e handoff (aconselha)
Confira contra o critério **specify-prompt** de `#criterios-de-conclusao`: declara observável ∧ sem
stack ∧ RF-xx/ADR como contexto. Então **entregue o comando pronto** para o usuário disparar, por
exemplo:

    /speckit.specify "<prompt montado>"

**PARE AQUI.** Não invoque `/speckit.specify` nem qualquer `/speckit.*` — o ciclo do Spec Kit é do
usuário. Este é o fim do território do harness.

## Saída
Um `/speckit.specify "..."` pronto para colar, mais o veredito das checagens da Fase 4.
