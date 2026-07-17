---
name: zion-prd-write
description: Estágio 3 do harness Zion Build PRD — copia o esqueleto da PRD e conduz o preenchimento seção a seção (RF-xx por épico, NFRs com número, restrições das ADRs), guardando a fronteira o-quê/como. Use para "escrever a PRD", "preencher a PRD" ou revisar uma PRD existente, depois da descoberta e dos spikes.
argument-hint: "(sem argumento — trabalha sobre docs/discovery.md e docs/adr/)"
metadata:
  author: zion-build-prd
user-invocable: true
disable-model-invocation: false
---

# zion-prd-write — Estágio 3 do harness (PRD enxuta)

Orquestra o Estágio 3 do harness (PRD enxuta). Sequência dos estágios e fronteira o-quê/como em
`references/process-context.md`. Contrato de 5 fases; gates aconselham. Regras em
`references/quality-rules.md`. Este é o coração do harness: a Fase 4 guarda a fronteira
**o-quê/por-quê vs. como**.

## Fase 0 — Pré-requisito (aconselha)
Confira `docs/discovery.md` e `docs/adr/`. Faltando → avise ("recomendo `/zion-prd-discovery` e
`/zion-prd-spike` antes") e pergunte se segue. **Idempotência:** se `docs/PRD.md` já existe, NÃO
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
As três regras decidíveis são verificadas por máquina. Rode:

    bash references/check-prd.sh prd docs/PRD.md

O script executa zero-stack (denylist + sinais estruturais), NFR-com-número e RF-por-épico, e imprime
cada achado ancorado em `arquivo:linha`. **Ecoe o veredito com autoridade** — reproduza os achados
com número de linha — e para cada um sugira mover a linha para o `plan.md` da feature (stack) ou
corrigir/justificar (NFR, RF). Exit `1` = há achados; exit `0` = limpo.

Complemente com o que o script não decide: os itens **prd** de `quality-rules.md`
`#criterios-de-conclusao` que dependem de julgamento (escopo in/out explícito, critério de aceite ou
tela vazando em prosa) — aplique o teste de vazamento de `#fronteira` e aponte a linha.

Não reverta — apenas aconselhe. Falso-positivo o humano descarta na hora.

## Saída
`docs/PRD.md` preenchido sobre o template, com `RF-xx` por épico e sem detalhe técnico. Insumo do
`/zion-prd-decompose` (Estágio 4) e da `constitution`.
