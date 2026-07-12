---
name: zion-prd-discovery
description: Estágio 1 do harness — conduz a descoberta enxuta (visão, persona, faz/não-faz) e grava docs/discovery.md
argument-hint: "Ideia bruta do produto e, se houver, URLs de referência"
metadata:
  author: zion-build-prd
user-invocable: true
disable-model-invocation: false
---

# zion-prd-discovery — Estágio 1 do harness (Descoberta enxuta)

Orquestra o Estágio 1 do harness (Descoberta enxuta). Sequência completa dos estágios e a
fronteira o-quê/como em `references/process-context.md`. Contrato de 5 fases; todos os gates
**aconselham** (apontam e sugerem), nunca bloqueiam. Regras em `references/quality-rules.md`.

## Fase 0 — Pré-requisito
Nenhum. Este é a entrada do funil.

## Fase 1 — Validar entrada bruta (aconselha)
A semente do usuário deve conter um **problema** e uma **persona candidata**. Se faltar, pergunte
o que estiver faltando. Se o usuário já descreve **stack/framework/biblioteca**, avise: "isso é cedo
— stack é do `plan.md`; aqui é só visão e escopo" (veja `quality-rules.md` `#fronteira`). Não bloqueie.

## Fase 2/3 — Formatar e auto-delegar
**Preflight (dependência):** esta etapa exige `superpowers:brainstorming`. Se a skill não estiver
disponível, avise e pare graciosamente: "Instale o superpowers — `/plugin marketplace add
obra/superpowers-marketplace` e `/plugin install superpowers@superpowers-marketplace` — e rode de
novo." (No formato plugin ela é declarada como dependência e instala automaticamente quando o
marketplace está registrado.)

Invoque `superpowers:brainstorming` no mesmo turno, com este enquadramento fixo:
"Refine a visão do produto: (1) visão em UMA frase; (2) persona principal nomeada; (3) quadro
faz/não-faz, com os 'não faz' explícitos. Grave o resultado em `docs/discovery.md`."

## Fase 4 — Validar saída (aconselha)
Ao terminar, confira `docs/discovery.md` contra o critério **discovery** de `quality-rules.md`
`#criterios-de-conclusao`: visão em 1 frase ∧ ≥1 persona nomeada ∧ pelo menos um "não faz" explícito.
Emita veredito: `✓` cada item ok, ou `⚠ <item> faltando — sugiro <correção>`. Não reverta nada.

## Saída
`docs/discovery.md` — insumo direto do `/zion-prd-spike` (Estágio 2) e do `/zion-prd-write` (Estágio 3).
