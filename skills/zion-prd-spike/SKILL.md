---
name: zion-prd-spike
description: Estágio 2 do harness Zion Build PRD — pesquisa os trade-offs das 2–3 decisões estruturantes e registra ADRs em docs/adr/ antes de fechar a PRD. Use após a descoberta, sempre que houver decisões que mudam a PRD inteira a provar com spike, ou quando o usuário mencionar "decisões estruturantes", "trade-offs" ou "ADRs".
argument-hint: "Opcional: as 2–3 decisões estruturantes, se você já as conhece"
metadata:
  author: zion-build-prd
user-invocable: true
disable-model-invocation: false
---

# zion-prd-spike — Estágio 2 do harness (Spikes técnicos + ADRs)

Orquestra o Estágio 2 do harness (Spikes técnicos + ADRs). Sequência dos estágios e fronteira
o-quê/como em `references/process-context.md`. Contrato de 5 fases; gates aconselham.
Regras em `references/quality-rules.md`.

## Fase 0 — Pré-requisito (aconselha)
`docs/discovery.md` deve existir. Se não existir, avise: "recomendo rodar `/zion-prd-discovery` antes" e
pergunte se segue mesmo assim. Não bloqueie.

## Fase 1 — Levantar e validar as decisões estruturantes (aconselha)
As **2–3 decisões estruturantes** são as que mudam a PRD inteira, não dúvidas menores. Detecte a
origem pelo que o usuário trouxe no argumento e aplique a cada candidata — dada ou proposta — o
filtro "isso muda a PRD inteira?"; candidata que não passa, descarte ou consolide.

- **Caminho A — 2–3 decisões dadas:** não proponha; valide cada uma pelo filtro. Lista longa de
  dúvidas pequenas → sugira consolidar nas 2–3 realmente estruturantes.
- **Caminho C — 1–2 decisões dadas (híbrido):** trate as dadas como fixas e proponha **só as
  faltantes** até fechar 2–3, cada complemento ancorado num trecho de `docs/discovery.md`.
- **Caminho B — 0 decisões dadas:** proponha as 2–3, cada uma ancorada num trecho do discovery.

**Guarda de suficiência (só em B/C, antes de propor).** O discovery tem três peças: visão em 1
frase, persona nomeada, quadro Faz/Não faz. Se uma peça necessária faltar ou for vaga (ex.: sem o
quadro Faz/Não faz não há como isolar uma fronteira de integração), **não fabrique** candidatas para
preencher a cota: aponte qual peça falta e por quê ela trava a inferência, proponha só o que o texto
sustenta, e peça a peça faltante ou sugira rodar `/zion-prd-discovery`. Não bloqueie.

**Apresentação (B/C).** Entregue as 2–3 (ou só o complemento faltante) como recomendação direta e
enxuta, cada uma com uma linha de justificativa ancorada no discovery. Sem shortlist longa.

**Convergência (todos os caminhos, aconselha).** Peça ao usuário para **confirmar**, **editar**
(trocar uma) ou **substituir** (rejeitar todas e ditar as suas). Lista fraca — nenhuma passa no
filtro, virou 4 dúvidas menores, ou ficou com 1 decisão só → aponte e sugira, mas a lista confirmada
pelo usuário é a que vale. Não bloqueie.

**Classificação por risco (aconselha).** Fechadas as 2–3 decisões, **classifique cada uma** como
*risco de execução* ou *risco de conhecimento*, cada classificação com **uma linha de justificativa**
ancorada na heurística `#risco-do-spike` de `references/quality-rules.md`. Peça para **confirmar ou
editar** — mesmo padrão de convergência. Não bloqueie. O risco confirmado escolhe o meio da evidência
na Fase 2/3.

## Fase 2/3 — Formatar e auto-delegar (ramifica por risco)
Para cada decisão, no mesmo turno, **conforme o risco confirmado na Fase 1**:

- **Risco de conhecimento** → levante os trade-offs das opções (custo de manutenção, limites). Se a
  skill built-in `deep-research` estiver disponível, invoque-a; se **não** estiver (harness antigo ou
  variante), avise "`deep-research` (built-in) indisponível — seguindo com pesquisa manual" e conduza
  o levantamento manualmente. Nunca quebre por falta dela. Depois invoque `zion-adr-new` com o título
  da decisão e preencha o campo **Evidência** do ADR com a **URL/caminho** da fonte.
- **Risco de execução** → determine o próximo número de ADR (mesma regra do `zion-adr-new`: maior
  `docs/adr/ADR-*.md` + 1, três dígitos) e o slug do título; **escreva o spike de código** em
  `docs/adr/spikes/ADR-00x-<slug>/` com um `README.md` (pergunta + o que foi rodado + veredito) e os
  artefatos descartáveis; então invoque `zion-adr-new` (que reusa o mesmo número) e preencha o campo
  **Evidência** com o **caminho do dir** `docs/adr/spikes/ADR-00x-<slug>/`.

O número do ADR é conhecido na criação, então o slug do spike dir casa com o do ADR.

## Fase 4 — Rodar `check-adr.sh` (aconselha)
Rode `bash references/check-adr.sh docs/adr/` e **ecoe o veredito** (com o achado e a ação sugerida).
O script confere a **presença** da evidência do tipo certo por ADR — `sem-evidencia`,
`spike-dir-ausente`, `spike-dir-vazio`, `spike-sem-readme`, `evidencia-sem-lastro` — presença, não
qualidade. Exit `0` limpo / `1` achados / `2` erro de uso. Mantenha o tom advisório: "complete a
evidência ou justifique", **não reverte**. Confira também, em prosa, contra o critério **spike** de
`references/quality-rules.md` `#criterios-de-conclusao`.

## Saída
`docs/adr/ADR-00x-*.md` por decisão. Cada ADR aceito vira **restrição** na PRD (seção 8) e alimenta a
`constitution` do Spec Kit.
