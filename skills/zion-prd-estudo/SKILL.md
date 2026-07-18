---
name: zion-prd-estudo
description: Estágio 0 (opcional) do harness Zion Build PRD — estudo pré-discovery de UM candidato: edge cases, 2–4 alternativas comparadas (sempre incluindo "não fazer"), ROI justificado e recomendação não vinculante, gravado em docs/estudos/<slug>.md do projeto-alvo. Use antes do discovery, quando a direção ainda não está clara, ou quando o usuário quiser "estudar uma ideia", "comparar alternativas" ou "avaliar o ROI antes da descoberta".
argument-hint: "Candidato a discovery em 2–6 frases: quem sofre, solução imaginada, restrições conhecidas"
metadata:
  author: zion-build-prd
user-invocable: true
disable-model-invocation: false
---

# zion-prd-estudo — Estágio 0 do harness (Estudo pré-discovery, opcional)

Orquestra o Estágio 0 da jornada: um **estudo** que orienta a direção antes do discovery.
Sequência dos estágios e fronteira o-quê/como em `references/process-context.md`. Contrato de
fases; todos os gates **aconselham**, nunca bloqueiam. Regras em `references/quality-rules.md`.

**Aconselha, não decide:** o documento subsidia; o humano escolhe a alternativa e conduz ele mesmo
discovery → spike/ADR → PRD. **Guardas (não faz):** não cria/altera ADRs, PRD, architecture,
skills ou assets do projeto-alvo; não grava `docs/discovery.md` nem código; a recomendação é
sempre marcada como **não vinculante**. A skill estuda **um** candidato por vez (sem ranking de
candidatos) e não persiste estado entre sessões além do próprio documento gravado.

## Fase 0 — Entrada (aconselha)

O candidato vem no argumento, em 2–6 frases: **quem sofre**, **solução imaginada**, **restrições
conhecidas**. Peça o que faltar — sem candidato completo não há o que estudar. Derive o `<slug>`
do candidato (kebab-case minúsculo, sem acentos). Se `docs/estudos/<slug>.md` **já existe**,
avise e pergunte: **retomar** (partir do documento atual e revisar) ou **sobrescrever**. Não
bloqueie.

**Preflight (dependência):** a Fase 2 exige `superpowers:brainstorming`. Se a skill não estiver
disponível, avise e pare graciosamente: "Instale o superpowers — `/plugin marketplace add
obra/superpowers-marketplace` e `/plugin install superpowers@superpowers-marketplace` — e rode de
novo." (No formato plugin ela é declarada como dependência e instala automaticamente quando o
marketplace está registrado.)

## Fase 1 — Leitura das fontes (aconselha)

Leia as fontes canônicas do projeto-alvo — **as que existirem**: `docs/prd.md`,
`docs/architecture.md` e `docs/adr/`. Resuma em **3–5 linhas** o que restringe o candidato,
**citando a fonte** de cada afirmação (`prd.md §x`, `ADR-xxx`). Brownfield: **nenhuma alternativa
pode contradizer ADR vigente** — alternativa que exigir reverter uma decisão declara a
**supersessão do ADR como custo** (dela, na Fase 3). Fontes ausentes → declare greenfield ("sem
fontes canônicas; o estudo ancora só no candidato") e siga.

## Fase 2 — Edge cases via brainstorming (convergência)

Invoque `superpowers:brainstorming` no mesmo turno (única dependência externa — contrato C1–C3,
ver ADR-007 do harness), com o enquadramento: "Explore edge cases e incertezas do candidato:
«candidato da Fase 0», sob estas restrições do projeto: «resumo da Fase 1». Produza perguntas que
a solução escolhida terá de responder — inclua as incômodas." Apresente a lista resultante
**marcando as perguntas que só o humano pode responder** e peça para **confirmar ou editar**. Não
bloqueie.

## Fase 3 — Alternativas + ROI (convergência)

Proponha **2–4 alternativas**, **sempre incluindo "não fazer"**, cada uma em nível de **o-quê**
(fronteira sem stack — `references/quality-rules.md` `#fronteira`): o que a persona passa a
conseguir, prós, contras, **ADRs tocados** e supersessões declaradas como custo (da Fase 1).

**ROI por alternativa**, três notas com justificativa em texto:

- **Impacto na persona** (1–5; 5 = resolve a dor central);
- **Esforço** (1–5, invertido; 5 = menor esforço);
- **Risco/reversibilidade** (1–5, invertido; 5 = menor risco, mais reversível).

ROI = média das três, **justificada em texto** (a nota sem o porquê não vale); tabela **ordenada
por ROI decrescente**. Apresente alternativas + tabela para **confirmar ou editar** antes de
gravar. Não bloqueie.

## Fase 4 — Gravação + veredito (aconselha)

Grave `docs/estudos/<slug>.md` com **exatamente** estas 6 seções (`##`, nesta ordem — o
verificador cobra os cabeçalhos):

```markdown
# Estudo — <candidato em meia frase>

## Contexto

<candidato em 1 parágrafo; relação com a visão da PRD e a persona, quando existirem, com fonte
citada — ou a declaração de greenfield da Fase 1>

## Edge cases e incertezas

<perguntas convergidas na Fase 2, marcadas as que só o humano responde>

## Alternativas

<as 2–4 convergidas na Fase 3, incluindo "não fazer", cada uma com prós/contras/ADRs tocados>

## ROI

<tabela ordenada + justificativas em texto>

## Recomendação

<1 parágrafo, claramente marcado como **não vinculante**>

## Próximo passo sugerido

Se aprovado, rodar `/zion-prd-discovery` com a alternativa escolhida (e `/zion-prd-spike` se
houver decisão estruturante nova).
```

Rode `bash references/check-estudo.sh docs/estudos/<slug>.md` e **ecoe o veredito como conselho**
(exit `0` limpo / `1` achados / `2` erro de uso): aponte cada achado — `secao-ausente`,
`nao-fazer-ausente`, `stack` — com a correção sugerida; **não reverta nada**. Dever em prosa
(indecidível por máquina): **toda afirmação sobre o estado atual do projeto cita a fonte**
(`prd.md §`, `ADR-xxx`) — confira antes de entregar.

## Saída

`docs/estudos/<slug>.md` — subsídio para o humano escolher a alternativa e conduzir
`/zion-prd-discovery` (Estágio 1). O estudo não dispara estágio algum.
