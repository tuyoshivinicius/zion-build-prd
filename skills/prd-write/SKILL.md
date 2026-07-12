---
name: prd-write
description: Estágio 3 do harness — copia o esqueleto da PRD e conduz o preenchimento seção a seção, guardando a fronteira o-quê/como
argument-hint: "(sem argumento — trabalha sobre docs/discovery.md e docs/adr/)"
metadata:
  author: zion-build-prd
user-invocable: true
disable-model-invocation: false
---

# prd-write — Estágio 3 do harness (PRD enxuta)

Orquestra o Estágio 3 do harness (PRD enxuta). Sequência dos estágios e fronteira o-quê/como em
`references/process-context.md`. Contrato de 5 fases; gates aconselham. Regras em
`references/quality-rules.md`. Este é o coração do harness: a Fase 4 guarda a fronteira
**o-quê/por-quê vs. como**.

## Fase 0 — Pré-requisito (aconselha)
Confira `docs/discovery.md` e `docs/adr/`. Faltando → avise ("recomendo `/prd-discovery` e
`/prd-spike` antes") e pergunte se segue. **Idempotência:** se `docs/PRD.md` já existe, NÃO
sobrescreva — entre em **modo revisar**: leia a PRD atual e pressione seção a seção o que estiver
fraco. Não bloqueie.

## Fase 1 — Validar entrada bruta
Não há texto novo do usuário aqui — o comando trabalha sobre os artefatos existentes.

## Fase 2 — Formatar
Se `docs/PRD.md` ainda não existe, copie `references/prd-skeleton.md` → `docs/PRD.md`
(as 12 seções em branco) como ponto de partida.

## Fase 3 — Auto-delegar
**Preflight (dependência):** esta etapa exige `superpowers:brainstorming`. Se a skill não estiver
disponível, avise e pare graciosamente: "Instale o superpowers — `/plugin marketplace add
obra/superpowers-marketplace` e `/plugin install superpowers@superpowers-marketplace` — e rode de
novo." (No formato plugin ela é declarada como dependência e instala automaticamente quando o
marketplace está registrado.)

Invoque `superpowers:brainstorming` no mesmo turno para preencher `docs/PRD.md` **seção a seção**, a
partir de `docs/discovery.md` + `docs/adr/`. Trabalhe uma seção por vez — visão, objetivos/métricas,
personas, escopo in/out, `RN-xx`, `RF-xx` por épico, NFRs (com número), restrições (das ADRs),
glossário, riscos, questões abertas — desafiando cada `RF-xx` e cada NFR antes de fechá-la.

## Fase 4 — Validar saída (aconselha) — GUARDA DE FRONTEIRA
Confira contra o critério **prd** de `quality-rules.md` `#criterios-de-conclusao`: escopo in/out
explícito ∧ `RF-xx` por épico (1 frase) ∧ NFRs com número ∧ **zero** stack / critério de aceite /
tela. Para o zero-stack, aplique o teste de vazamento de `#fronteira`: se alguma linha cita
linguagem/framework/biblioteca/tela/contrato de API, **aponte a linha exata** e sugira movê-la para o
`plan.md` da feature. Emita veredito por item. Não reverta — apenas aconselhe.

## Saída
`docs/PRD.md` preenchido sobre o template, com `RF-xx` por épico e sem detalhe técnico. Insumo do
`/prd-decompose` (Estágio 4) e da `constitution`.
