# Design — Spike: evidência proporcional ao risco + `check-adr.sh` (R3)

> **Origem:** recomendação R3 de `docs/critica-zion-build-prd.md` §5.2 (fragilidades F1 e H5).
> **Data:** 2026-07-17.
> **Escopo:** resolver a contradição embarcada do Estágio 2 — o guia promete "spike com **código
> descartável**", mas a skill `/zion-prd-spike` só faz pesquisa e a Fase 4 cobra um "spike real" que
> o comando não produz. A correção reenquadra a promessa para **evidência proporcional ao risco** e
> instrumenta a evidência com um verificador mecânico, no mesmo molde de R1/R2.

---

## 1. Problema

O guia é enfático: "responder com **código descartável** (não com opinião) as 2–3 decisões
estruturantes" (`guia-prd-para-spec-kit.md:85`) e "cada decisão estruturante tem um ADR aceito,
**sustentado por um spike que você de fato rodou**" (`guia:103-104`). O critério de conclusão repete:
"o ADR referencia um spike real" (`quality-rules.md:44`).

Mas a skill que executa o estágio **nunca pede código**: a Fase 2/3 de `/zion-prd-spike`
(`SKILL.md:46-52`) levanta trade-offs via `deep-research` e registra o ADR — só isso. A Fase 4
(`SKILL.md:54-58`) então cobra um spike real que o próprio comando não produziu. O harness
institucionalizou a versão diluída (pesquisa no lugar de spike) **e** manteve o texto de cobrança.

Resultado no único projeto que usou o método ponta-a-ponta: dos 4 ADRs, apenas ADR-002 tem spike de
código de verdade (`docs/adr/spikes/adr-002-*`, 633 linhas); ADR-001, ADR-003 e ADR-004 rotularam
execuções de deep-research como "Spike/evidência" — pesquisa, não código. É precisamente a "opinião"
(agora com citações) que o guia diz querer evitar: teatro de conformidade. Prometer um rigor sem
mecanismo é pior que a promessa menor cumprida.

A crítica registra ainda que o elo **spike→ADR como pré-requisito é síntese própria do zion**, sem
respaldo canônico (§4.3) — o que legitima *dimensioná-lo* em vez de mantê-lo como dogma retórico.

## 2. Princípio organizador

**Evidência proporcional ao risco, e a evidência verificada por máquina.** Dois movimentos, os
mesmos que atravessam R1–R5 da crítica:

1. **Promessa sem mecanismo → promessa certa com mecanismo.** Nem "código sempre" (força código onde
   o risco é de conhecimento) nem "pesquisa sempre" (o teatro atual). O *risco* da decisão escolhe o
   meio da evidência.
2. **Invariante de prosa → invariante de máquina.** A presença da evidência do tipo certo é
   verificada por `check-adr.sh`, no mesmo padrão de `check-prd.sh` (R1) e `trace-prd.sh` (R2). O
   script **verifica presença**; o humano **decide**. Gates aconselham, não bloqueiam.

## 3. Decisões estruturais (tomadas no discovery)

1. **Híbrido, não ou-ou.** A crítica enquadra R3 como fork (código *ou* honestidade); adotamos os
   dois lados: reenquadra a promessa **e** dá estrutura de spike de código para quando código é o meio
   certo. Resolve a contradição sem mentir sobre rigor nem forçar código onde pesquisa basta.
2. **Classificação: skill propõe, usuário confirma.** A Fase 1 classifica cada decisão
   (execução/conhecimento) com uma linha de justificativa e pede confirmação — mesmo padrão de
   convergência que a Fase 1 já usa. A base da proposta é uma **heurística decidível** documentada no
   `quality-rules.md` (para a skill não classificar no vácuo).
3. **Evidência mínima = campo obrigatório no ADR + verificação por script.** O ADR ganha um campo
   `Evidência`; `check-adr.sh` confere a *presença* do elo (não a qualidade — igual ao `check-prd.sh`,
   que casa denylist sem julgar semântica). Fecha F1/H5 do jeito que R1/R2 fecharam suas lacunas.
4. **Spike dir chaveado pelo ADR + README obrigatório.** `docs/adr/spikes/ADR-00x-<slug>/` (mesmo
   número/slug do ADR) com `README.md` (pergunta + o que foi rodado + veredito) além dos artefatos
   descartáveis. Correlação ADR↔spike automática pelo número — sem elo manual a quebrar.
5. **Script novo, não extensão do `check-prd.sh`.** Preocupações distintas (stack-leak × presença de
   evidência); o repo já trata `trace-prd.sh` como script próprio. Mesmo molde: fixtures + `test-*.sh`
   + passo no CI + cópia via `asset-map.sh`.
6. **Advisório, sem bloqueio.** Exit `0`/`1`/`2`; a Fase 4 ecoa o veredito com autoridade mas não
   reverte. Coerente com a filosofia do harness.

## 4. O reenquadramento (guia + quality-rules)

### 4.1 A heurística de risco (nova âncora no `quality-rules.md`)

Nova seção `## Risco do spike {#risco-do-spike}`, base da classificação da Fase 1:

- **Risco de execução** → a dúvida **só se resolve rodando algo**: performance sob carga,
  compatibilidade, viabilidade de integração, comportamento observável. **Meio: spike de código** em
  `docs/adr/spikes/ADR-00x-<slug>/`.
- **Risco de conhecimento** → trade-off **documentável sem rodar**: maturidade, licença, custo de
  manutenção, ecossistema, aderência conceitual. **Meio: pesquisa (deep-research) com fonte citada.**

Regra prática: se você consegue decidir lendo docs/benchmarks de terceiros, é conhecimento; se
precisa do *seu* caso rodando para confiar, é execução.

### 4.2 O critério de conclusão (edição na âncora existente)

`quality-rules.md` `#criterios-de-conclusao`, linha do `spike`, passa de:

> cada decisão estruturante tem um ADR com Contexto/Decisão/Consequências ∧ o ADR referencia um spike
> real.

para:

> cada decisão estruturante tem um ADR com Contexto/Decisão/Consequências ∧ o ADR carrega
> **evidência do tipo certo para seu risco** (spike de código para risco de execução; fonte de
> pesquisa para risco de conhecimento). A presença da evidência é verificada por `check-adr.sh` — a
> Fase 4 roda o script e ecoa o veredito.

### 4.3 O guia (Passo 2)

`docs/guia-prd-para-spec-kit.md:83-104` reescrito para "evidência proporcional ao risco": remove
"código descartável (não com opinião)" como imperativo universal, substitui pela heurística de risco,
e ajusta o critério de conclusão do passo para casar com 4.2. O exemplo de invocação passa a mostrar
os **dois caminhos** (deep-research → ADR; spike de código → ADR).

## 5. O fluxo da skill `/zion-prd-spike`

### 5.1 Fase 1 — classificar por risco (novo passo, aconselha)

Ao fechar as 2–3 decisões estruturantes (caminhos A/B/C inalterados), a skill **classifica cada uma**
como execução ou conhecimento, cada classificação com uma linha de justificativa ancorada na
heurística `#risco-do-spike`, e pede **confirmar/editar** — mesmo padrão de convergência já usado. Não
bloqueia.

### 5.2 Fase 2/3 — ramificar por risco

Para cada decisão, no mesmo turno, **conforme o risco confirmado**:

- **Risco de conhecimento** → levanta trade-offs via `deep-research` (com a degradação graciosa
  atual: se indisponível, avisa e conduz manual) e invoca `zion-adr-new`, preenchendo o campo
  `Evidência` com a fonte.
- **Risco de execução** → orienta escrever o spike de código em `docs/adr/spikes/ADR-00x-<slug>/`
  (com `README.md`: pergunta + o que rodar + veredito), depois invoca `zion-adr-new`, preenchendo o
  campo `Evidência` com o caminho do dir.

O número do ADR é conhecido na criação (`zion-adr-new` já o determina), então o slug do spike dir
casa com o do ADR.

### 5.3 Fase 4 — rodar `check-adr.sh` (substitui a prosa)

Deixa de "conferir em prosa se o ADR menciona um spike" e passa a rodar
`bash references/check-adr.sh docs/adr/`, ecoando o veredito com número de linha. Mantém o tom
advisório — "complete a evidência ou justifique", não reverte.

## 6. O contrato de evidência no ADR (`zion-adr-new`)

### 6.1 Campo novo no template

O template gerado por `zion-adr-new/SKILL.md` ganha um campo obrigatório no bloco de metadados (ao
lado de Status/Data/Decisores):

```
- **Evidência:** <um dos dois — o tipo casa com o risco da decisão>
    · execução:     docs/adr/spikes/ADR-00x-<slug>/   (dir com README.md + artefatos descartáveis)
    · conhecimento: <URL ou caminho do artefato de pesquisa que sustenta a decisão>
```

A seção **Contexto** do template já pergunta "Que spike foi rodado para sustentar a decisão?"; passa a
"Que evidência (spike de código ou pesquisa) sustenta a decisão, e qual o risco que ela endereça?".

### 6.2 Estrutura do spike dir (risco de execução)

`docs/adr/spikes/ADR-00x-<slug>/` deve conter:

- **`README.md`** — pergunta do spike (a dúvida de execução), o que foi rodado, e o veredito (a
  resposta que sustenta a decisão do ADR). Obrigatório.
- **Artefatos descartáveis** — o código/medições do spike. Livre.

O `zion-adr-new` **não** cria o spike dir (o spike é escrito na Fase 2/3 da `/zion-prd-spike`, antes
ou junto do ADR); o template só documenta a convenção de caminho e o campo que o referencia.

## 7. A verificação mecânica — `scripts/check-adr.sh`

### 7.1 Contrato

```
check-adr.sh <dir-de-adrs>     # ex.: check-adr.sh docs/adr
```

Para cada `docs/adr/ADR-*.md` (ignora `spikes/`):

1. **Sem linha `Evidência`** (ou vazia) → achado `sem-evidencia`.
2. **Evidência aponta um `docs/adr/spikes/…/`** → confere que o dir existe, é **não-vazio** e contém
   `README.md`. Faltando qualquer um → achado (`spike-dir-ausente` / `spike-dir-vazio` /
   `spike-sem-readme`).
3. **Evidência de conhecimento** → confere que a linha contém pelo menos **uma URL (`http…`) ou um
   caminho de artefato**. Texto sem URL/caminho → achado `evidencia-sem-lastro`.

Presença, não qualidade — o script não julga se o spike foi bem-feito nem se a fonte é boa, só que o
lastro concreto existe e está apontável. Exit **`0` limpo / `1` achados / `2` erro de uso/ambiente**.
Saída por achado: `ADR-003-…md: <regra> — <detalhe> (<ação sugerida>)`; linha final
`check-adr: N achado(s)` ou `check-adr: limpo`. Lido pela Fase 4, que aconselha.

### 7.2 Distribuição

- **Canônico:** `scripts/check-adr.sh`, ao lado de `check-prd.sh` / `trace-prd.sh`.
- **Sync:** nova entrada em `scripts/asset-map.sh` — `scripts/check-adr.sh → zion-prd-spike`. O
  `sync-assets.sh` copia para `skills/zion-prd-spike/references/check-adr.sh`; `check-assets.sh`
  vigia drift; o pre-commit hook regenera. Invocado com `bash` explícito → bit de execução da cópia é
  irrelevante.

### 7.3 Auto-teste (semente da R7)

- `scripts/fixtures/adr/` — ADRs sintéticos: **clean** (um de execução com spike dir completo, um de
  conhecimento com URL) e **dirty** (sem evidência; spike dir vazio; spike sem README; conhecimento
  sem URL/caminho).
- `scripts/test-check-adr.sh` — assere exit code + achados esperados por fixture.
- **CI:** novo passo `Auto-teste do check-adr` em `.github/workflows/check-assets.yml`, ao lado dos
  auto-testes de `check-prd` e `trace-prd`.

## 8. Superfície de mudança

| Arquivo | Mudança |
|---|---|
| `docs/guia-prd-para-spec-kit.md` | Passo 2 reescrito: "evidência proporcional ao risco"; exemplo com os dois caminhos; critério de conclusão casado com 4.2. |
| `assets/quality-rules.md` | Nova âncora `## Risco do spike {#risco-do-spike}`; edição da linha `spike` em `#criterios-de-conclusao`. |
| `skills/zion-adr-new/SKILL.md` | Template ganha o campo `Evidência`; pergunta de Contexto reformulada; documenta a convenção do spike dir. |
| `skills/zion-prd-spike/SKILL.md` | Fase 1 classifica por risco; Fase 2/3 ramifica; Fase 4 roda `check-adr.sh`. |
| `scripts/check-adr.sh` | **Novo.** O verificador de presença de evidência. |
| `scripts/asset-map.sh` | Nova entrada: `scripts/check-adr.sh → zion-prd-spike`. |
| `scripts/fixtures/adr/` + `scripts/test-check-adr.sh` | **Novo.** Fixtures + auto-teste. |
| `.github/workflows/check-assets.yml` | Novo passo de auto-teste do `check-adr`. |
| `docs/como-usar.md`, `README.md` | Menção ao Estágio 2 reenquadrado + verificação mecânica. |
| `skills/*/references/` | Regenerados pelo sync (não editados à mão). |

## 9. Fora de escopo (consciente)

- **Auditoria retroativa de ADRs antigos** (rodar `check-adr.sh` como comando avulso sobre projetos já
  feitos) — é o território de H8/R8 (dia 2), outra recomendação.
- **Julgar a qualidade** do spike ou da fonte — o script verifica presença; qualidade fica com a
  Fase 4/humano.
- **Bloqueio / exit gate no fluxo** — advisório, como o resto do harness.
- **Colisão de nome "spike"** (S de SPIDR × Estágio 2, §4.4 da crítica) — custo cognitivo pequeno,
  não endereçado aqui.
- **Suíte completa de avaliação do harness (R7)** — só a semente de fixtures do `check-adr` entra.

O padrão é o mesmo que o repo já provou saber executar — fez exatamente isso pelos próprios assets
(R1) e pela rastreabilidade (R2). R3 estende-o ao Estágio 2.
