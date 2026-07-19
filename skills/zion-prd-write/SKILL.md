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

**Delegação classificada (guiada por `references/delegacao-criativa.md`).** Antes de invocar, no
mesmo turno: (1) leia `docs/discovery.md` + `docs/adr/` e **enumere as tensões como observações**
suas — nunca já redigidas como pergunta; (2) **classifique cada tensão** diagnóstica/propositiva
pela rubrica; (3) **monte o bloco de delegação** = as observações classificadas + a rubrica
(distinção, dois previews, condução); (4) **autoverifique** o bloco montado —
`printf '%s' "<bloco>" | bash references/check-delegacao.sh -` — e ecoe o veredito (aconselha,
`RN-01`); marcador ausente → corrija o bloco antes de delegar; (5) passe o bloco como `args` na
invocação abaixo.

Invoque `superpowers:brainstorming` no mesmo turno para preencher `docs/PRD.md` **seção a seção**, a
partir de `docs/discovery.md` + `docs/adr/`. Trabalhe uma seção por vez — visão, objetivos/métricas,
personas, escopo in/out, `RN-xx`, `RF-xx` por épico, NFRs (com número), restrições (das ADRs),
glossário, riscos, questões abertas — desafiando cada `RF-xx` e cada NFR antes de fechá-la.

**Carregador de experiência:** leia a linha `Superfície de uso: sim/não` de `docs/discovery.md`
e **carregue-a** para o cabeçalho da §7 (NFRs) como a linha bare `Superfície de uso: sim` (ou
`não`). Quando `sim`, derive do bloco `## Experiência` do discovery **≥1 NFR de experiência**,
tagueado e machine-legível: `NFR-0x` (experiência): a tarefa-núcleo é concluída em ≤N passos.
Carrega um número, como todo NFR — a tag `(experiência)` é o marcador que o check casa. Mantém a
fronteira: é NFR mensurável, nunca tela.

## Fase 4 — Validar saída (aconselha) — GUARDA DE FRONTEIRA
As três regras decidíveis são verificadas por máquina. Rode:

    bash references/check-prd.sh prd docs/PRD.md

O script executa zero-stack (denylist + sinais estruturais), NFR-com-número e RF-por-épico, e imprime
cada achado ancorado em `arquivo:linha`. **Ecoe o veredito com autoridade** — reproduza os achados
com número de linha — e para cada um sugira mover a linha para o `plan.md` da feature (stack) ou
corrigir/justificar (NFR, RF). Exit `1` = há achados; exit `0` = limpo.

**Âncora de experiência (advisório).** Quando a §7 tem `Superfície de uso: sim`, rode também:

    bash references/check-experiencia.sh docs/PRD.md

Sem arg de backlog, o check avalia só o **limb-PRD**: surface=sim ∧ nenhum NFR tagueado
`(experiência)` → ⚠ *"produto com superfície mas sem âncora de experiência na PRD"*. Ecoe o
veredito e sugira aterrissar ≥1 NFR de experiência. Exit `1` = achado; `0` = limpo. Não reverte
(`RN-01`).

Complemente com o que o script não decide: os itens **prd** de `quality-rules.md`
`#criterios-de-conclusao` que dependem de julgamento (escopo in/out explícito, critério de aceite ou
tela vazando em prosa) — aplique o teste de vazamento de `#fronteira` e aponte a linha.

Não reverta — apenas aconselhe. Falso-positivo o humano descarta na hora.

## Saída
`docs/PRD.md` preenchido sobre o template, com `RF-xx` por épico e sem detalhe técnico. Insumo do
`/zion-prd-decompose` (Estágio 4) e da `constitution`.
