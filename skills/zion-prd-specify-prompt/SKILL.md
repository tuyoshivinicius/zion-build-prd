---
name: zion-prd-specify-prompt
description: Ponte do harness Zion Build PRD para o Spec Kit — monta o prompt do /speckit.specify de UMA fatia vertical, blindando a fronteira sem-stack, entrega pronto e para. Use para levar uma fatia do backlog ao Spec Kit; não dispara o /speckit.* por você.
argument-hint: "Qual fatia vertical do backlog transformar em prompt de specify"
metadata:
  author: zion-build-prd
user-invocable: true
disable-model-invocation: false
---

# zion-prd-specify-prompt — Ponte do harness para o Spec Kit (Passo 5b)

Prepara o input do `/speckit.specify` de UMA fatia vertical. Encerra o território do harness: entrega
o prompt pronto e para — o ciclo `/speckit.*` é seu. Regras em `references/quality-rules.md`.

## Fase 0 — Pré-requisito (aconselha)
Deve existir um backlog de fatias verticais (saída de `/zion-prd-decompose`). O usuário aponta **qual**
fatia. Se não houver backlog, avise ("recomendo `/zion-prd-decompose` antes") e pergunte se segue.

## Fase 1 — Validar entrada bruta (aconselha)
A fatia deve ter um **resultado observável** (o que o usuário consegue fazer/ver ao final). Se o
usuário descreve a fatia citando **biblioteca/framework/stack**, avise: "isso é do `plan`, não do
`specify`" (veja `quality-rules.md` `#fronteira`). Não bloqueie.

## Fase 2/3 — Montar o prompt (você mesmo)
Monte, no mesmo turno, o prompt do `specify` em **linguagem natural (prosa)**, seguindo
`references/quality-rules.md` `#anatomia-specify`. É **conteúdo, não formato**: não use tags XML nem
dite as seções do artefato — o `/speckit.specify` já tem o próprio template. Em prosa, o prompt deve:
- Declarar o **resultado observável** da fatia (o que o usuário faz/vê ao final).
- Blindar a fronteira em prosa: "não citar linguagem, framework ou bibliotecas; a stack fica no
  `plan`".
- Citar `RF-xx` e ADRs relevantes como **referência** (contexto), não como requisito.

## Fase 4 — Validar saída e handoff (aconselha)
Verifique o zero-stack por máquina, passando o prompt montado ao script via stdin:

    printf '%s' "<prompt montado>" | bash references/check-prd.sh specify -

O script casa o prompt contra a denylist e os sinais estruturais e imprime cada achado com o número
da linha do prompt. **Ecoe o veredito** — para cada achado, lembre que a stack fica no `plan`, não no
`specify`. Complemente com o julgamento que o script não faz: o prompt declara um resultado
observável ∧ cita `RF-xx`/ADR como contexto (referência), não como requisito. Não bloqueie.

Então **entregue o comando pronto** para o usuário disparar, por exemplo:

    /speckit.specify "<prompt montado>"

**PARE AQUI.** Não invoque `/speckit.specify` nem qualquer `/speckit.*` — o ciclo do Spec Kit é do
usuário. Este é o fim do território do harness.

## Saída
Um `/speckit.specify "..."` pronto para colar, mais o veredito das checagens da Fase 4.
