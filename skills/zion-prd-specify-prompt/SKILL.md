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
Deve existir o **backlog** `docs/backlog.md` (saída de `/zion-prd-decompose`). O usuário aponta **qual**
fatia. Se não houver backlog, avise ("recomendo `/zion-prd-decompose` antes") e pergunte se segue.

## Fase 1 — Validar entrada bruta (aconselha)
A fatia deve ter um **resultado observável** (o que o usuário consegue fazer/ver ao final). Se o
usuário descreve a fatia citando **biblioteca/framework/stack**, avise: "isso é do `plan`, não do
`specify`" (veja `quality-rules.md` `#fronteira`). Não bloqueie.

**Resolva a fatia contra o backlog** `docs/backlog.md`: o usuário pode apontá-la em prosa ("a fatia do
preview"); localize a linha na tabela canônica e confirme **slug / demo / RFs**. Fatia fora do backlog →
avise ("registre no backlog via `/zion-prd-decompose` ou adicione a linha") e pergunte se segue — não
bloqueie.

## Fase 2/3 — Montar o prompt (você mesmo)
Monte, no mesmo turno, o prompt do `specify` em **linguagem natural (prosa)**, seguindo
`references/quality-rules.md` `#anatomia-specify`. É **conteúdo, não formato**: não use tags XML nem
dite as seções do artefato — o `/speckit.specify` já tem o próprio template. Em prosa, o prompt deve:
- Declarar o **resultado observável** da fatia (o que o usuário faz/vê ao final).
- Blindar a fronteira em prosa: "não citar linguagem, framework ou bibliotecas; a stack fica no
  `plan`".
- Citar `RF-xx` e ADRs relevantes como **referência** (contexto), não como requisito.
- Pedir explicitamente que o `spec.md` inclua uma linha rotulada **`**RF cobertos:** RF-xx, ...`** com
  os RF que esta fatia cobre — é o elo legível por máquina que o `/zion-prd-trace` grepa para
  reconciliar a rastreabilidade. Declarar *quais* RF a fatia cobre é o-quê/rastreabilidade, não stack:
  não fere a fronteira sem-stack.
- **Nome da feature = slug:** peça explicitamente que a feature/branch use `<slug>` como nome curto — a
  spec nasce `specs/###-<slug>`, fechando o elo fatia↔spec por construção (o `trace-backlog.sh` casa por
  sufixo).
- Preencha a linha **`**RF cobertos:**`** com **os RF-xx da linha da fatia** no backlog — fechando o elo
  de escopo dos dois lados. Como hoje, instruímos via prompt e parseamos o que aterrissa: se o Spec Kit
  batizar diferente do slug, o `trace-backlog.sh` acusa **spec órfã** + **fatia sem spec** e o humano
  renomeia.

**Modo re-specify (dia 2):** quando a fatia apontada **já** tem `specs/<n>-*/spec.md` (invocado pelo
`/zion-prd-evolve` no C2), monte o prompt como **revisão** — "revise a spec existente contra a mudança X"
—, trazendo a linha da §13 (changelog) como contexto, em vez de "especifique do zero". A fronteira
sem-stack fica blindada igual (a stack segue no `plan`), e o `check-prd.sh specify -` verifica igual.

## Fase 4 — Validar saída e handoff (aconselha)
Verifique por máquina, passando o prompt montado ao script via stdin, que o prompt (a) não vaza stack
e (b) pede a linha **`**RF cobertos:**`** — o elo forward RF↔spec:

    printf '%s' "<prompt montado>" | bash references/check-prd.sh specify -

O script casa o prompt contra a denylist e os sinais estruturais (achados de `stack`) e confere que o
prompt pede a linha `**RF cobertos:**` (achado `rf-cobertos-ausente` quando falta). **Ecoe o
veredito** — para cada achado de stack, lembre que a stack fica no `plan`, não no `specify`; se faltar
o pedido de `**RF cobertos:**`, acrescente-o antes do handoff. Complemente com o julgamento que o
script não faz: o prompt declara um resultado observável ∧ cita `RF-xx`/ADR como contexto
(referência), não como requisito. Não bloqueie.

Então **entregue o comando pronto** para o usuário disparar, por exemplo:

    /speckit.specify "<prompt montado>"

**PARE AQUI.** Não invoque `/speckit.specify` nem qualquer `/speckit.*` — o ciclo do Spec Kit é do
usuário. Este é o fim do território do harness.

## Saída
Um `/speckit.specify "..."` pronto para colar, mais o veredito das checagens da Fase 4.
