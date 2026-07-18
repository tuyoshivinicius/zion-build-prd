# Design — recarregar um estudo pelo slug (zion-prd-estudo)

> Spec de brainstorming. Alvo: a skill `zion-prd-estudo` (Estágio 0 do harness Zion Build PRD).
> Mudança localizada na **Fase 0**; Fases 1–4, output e verificador não mudam.

## Problema

Para revisitar um estudo já gravado, hoje o Autor tem de **re-digitar o candidato inteiro** (2–6
frases: quem sofre, solução imaginada, restrições) só para que o `<slug>` derivado colida com
`docs/estudos/<slug>.md` e a Fase 0 ofereça retomar/sobrescrever. É atrito puro: a informação já
está no documento gravado.

## Objetivo

Permitir reabrir um estudo existente passando **apenas o slug** como argumento
(`/zion-prd-estudo discovery-ux-design`), sem re-digitar o candidato. A skill localiza o documento,
usa-o como ponto de partida e segue para a revisão.

## Escopo

**Faz:** aceita, na Fase 0, uma segunda forma de entrada — o slug de um estudo existente — e
recarrega o documento como fonte do candidato, indo direto para a revisão (retomar).

**Não faz:** não altera as Fases 1–4, os 6 cabeçalhos do output, `check-estudo.sh`, a detecção de
modo interno/distribuído, nem os assets. Não introduz flag nova nem sintaxe de argumento nova. Não
cria ADR (a detecção é mecanismo, não decisão estruturante). Não versiona nem compara estudos
lado a lado.

## Contrato de entrada da Fase 0 (as duas formas)

A Fase 0 passa a aceitar **duas** formas de argumento, distinguidas por **match de arquivo**:

1. **Candidato** — 2–6 frases (quem sofre, solução imaginada, restrições). **Fluxo atual,
   intocado.**
2. **Slug de estudo existente** — um token único cujo arquivo já existe.

### Detecção (match de arquivo, sem flag)

- Faça `trim` do argumento.
- Se o argumento for um **token único** (sem espaços) **e** existir `docs/estudos/<token>.md` →
  **modo recarregar**.
- Caso contrário → **modo candidato** (comportamento atual). Um token único que **não** casa com
  arquivo cai aqui; se não constituir candidato completo, a skill pede o que falta — exatamente
  como hoje ("Peça o que faltar — sem candidato completo não há o que estudar").

A regra é robusta porque um candidato em prosa (múltiplas palavras) nunca casa com um nome de
arquivo, e um slug existente casa sempre. Nenhuma nova superfície de falha.

### Modo recarregar — comportamento

1. Lê `docs/estudos/<slug>.md`.
2. Usa a seção **`## Contexto`** do documento como fonte do candidato — **não** pede as 2–6 frases
   de novo.
3. Vai **direto para retomar**: revisa o documento atual percorrendo as Fases 1–4, cada fase
   reapresentada para o Autor **confirmar ou editar**. **Não oferece sobrescrever.**

Quem quiser sobrescrever continua com o caminho atual: passa o candidato **em texto** (modo
candidato), a skill deriva o slug, ele colide, e aí a Fase 0 oferece retomar/sobrescrever como
hoje. O caminho por slug fica sendo puramente "continuar/revisar".

## O que não muda

- Fases 1–4 (leitura das fontes, edge cases via brainstorming, alternativas+ROI, gravação+veredito).
- Os 6 cabeçalhos obrigatórios do output e o `check-estudo.sh`.
- A detecção de modo interno × distribuído (re-detectada do projeto-alvo no recarregar).
- Os assets e o fluxo de `sync-assets.sh` (o formato de saída é idêntico).

## Reflexo no canon (dever de canonização — mesmo commit)

- **`docs/prd.md` §6** — cláusula em `RF-17`: o Autor pode **reabrir um estudo pelo slug** para
  revisá-lo (retomável), sem re-digitar o candidato. Requisito em nível de o-quê; a mecânica de
  detecção fica no corpo da skill.
- **`docs/prd.md` §13** — entrada C3 no changelog registrando a alteração de `RF-17`.
- **`skills/zion-prd-estudo/SKILL.md`** — `argument-hint` atualizado para refletir as duas formas
  de entrada; corpo da Fase 0 descreve a detecção por match de arquivo e o modo recarregar.
- **§12 inalterada** — continua `RF-17 → skills/zion-prd-estudo`.
- **Sem ADR novo** — "match de arquivo" é mecanismo (como), não decisão estruturante.

## Critérios de aceite

1. `/zion-prd-estudo discovery-ux-design` com o arquivo existente recarrega o documento e entra em
   revisão (retomar) sem pedir o candidato, sem oferecer sobrescrever.
2. `/zion-prd-estudo <slug-inexistente>` (token único sem arquivo) cai no modo candidato e pede o
   que falta — comportamento atual preservado.
3. `/zion-prd-estudo <candidato em 2–6 frases>` cujo slug colide continua oferecendo
   retomar/sobrescrever — comportamento atual preservado.
4. `check-estudo.sh` e os 6 cabeçalhos permanecem idênticos; `check-canon.sh` passa (RF-17
   refletido em §6/§13).
