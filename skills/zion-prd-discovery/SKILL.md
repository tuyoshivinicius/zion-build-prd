---
name: zion-prd-discovery
description: Estágio 1 do harness Zion Build PRD — conduz a descoberta enxuta de produto (visão em 1 frase, persona nomeada, quadro faz/não-faz) e grava docs/discovery.md; idempotente — retoma/revisa um discovery existente sem sobrescrever. Use ao iniciar um produto/feature a partir de uma ideia bruta, antes de qualquer PRD ou stack, ou para retomar/revisar a descoberta em nova sessão, sempre que o usuário quiser "começar a descoberta", "destrinchar a ideia", "definir visão e escopo" ou "continuar/revisar o discovery".
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

## Fase 0 — Pré-requisito / detecção de modo (aconselha)
Este é a entrada do funil — não há pré-requisito de artefato. **Idempotência:** se
`docs/discovery.md` **não** existe, siga em **modo do-zero** (fluxo abaixo, intacto). Se **já
existe**, NÃO sobrescreva — entre em **modo retomar/revisar**: leia o discovery atual e trate-o
como ponto de partida. **Detecção de downstream** (só no modo revisar): se `docs/adr/` contém
ADR(s) **ou** `docs/PRD.md` existe, emita um aviso advisório único: "⚠ já há downstream baseado
neste discovery; se a mudança for estrutural (visão/persona/escopo), rode `/zion-prd-evolve` para
rotear o impacto." Só avisa — não roteia, não bloqueia.

## Fase 1 — Validar entrada bruta (aconselha)
**Modo do-zero:** a semente do usuário deve conter um **problema** e uma **persona candidata**. Se
faltar, pergunte o que estiver faltando. Se o usuário já descreve **stack/framework/biblioteca**,
avise: "isso é cedo — stack é do `plan.md`; aqui é só visão e escopo" (veja `quality-rules.md`
`#fronteira`). Não bloqueie. **Modo retomar/revisar:** o argumento é **opcional** e vira a dica de
*o que revisar* (ex.: "quero rever a persona"); sem argumento, pressione os blocos incompletos ou
fracos do discovery atual.

## Fase 2/3 — Formatar e auto-delegar
**Preflight (dependência):** esta etapa exige `superpowers:brainstorming`. Se a skill não estiver
disponível, avise e pare graciosamente: "Instale o superpowers — `/plugin marketplace add
obra/superpowers-marketplace` e `/plugin install superpowers@superpowers-marketplace` — e rode de
novo." (No formato plugin ela é declarada como dependência e instala automaticamente quando o
marketplace está registrado.)

Invoque `superpowers:brainstorming` no mesmo turno. O enquadramento ramifica pelo modo detectado
na Fase 0:

- **Modo do-zero:** "Refine a visão do produto: (1) visão em UMA frase; (2) persona principal
  nomeada; (3) quadro faz/não-faz, com os 'não faz' explícitos. Grave o resultado em
  `docs/discovery.md`."
- **Modo retomar/revisar:** "Aqui está o `docs/discovery.md` atual: «<conteúdo do arquivo>».
  Preserve visão/persona/faz-não-faz que já estão sólidos; pressione o que está incompleto ou o
  que o usuário quer rever (ver argumento da Fase 1); não reescreva o que está bom. Mantenha os 3
  blocos: visão em UMA frase, persona nomeada, quadro faz/não-faz. Regrave `docs/discovery.md`."

## Fase 4 — Validar saída (aconselha)
Ao terminar, confira `docs/discovery.md` contra o critério **discovery** de `quality-rules.md`
`#criterios-de-conclusao`: visão em 1 frase ∧ ≥1 persona nomeada ∧ pelo menos um "não faz" explícito.
Emita veredito: `✓` cada item ok, ou `⚠ <item> faltando — sugiro <correção>`. Não reverta nada.

## Saída
`docs/discovery.md` — insumo direto do `/zion-prd-spike` (Estágio 2) e do `/zion-prd-write` (Estágio 3).
