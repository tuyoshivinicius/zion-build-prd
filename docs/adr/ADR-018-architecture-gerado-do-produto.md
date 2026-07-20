# ADR-018 — O architecture.md do produto é gerado sob ditado e reconciliado

- **Status:** Aceito
- **Área:** Integração Spec Kit
- **Data:** 2026-07-20
- **Decisores:** autoria do repo
- **Substitui:** ADR-015
- **Evidência:** Decisão dada: o Autor escolheu a composição A1+A3 no estudo `docs/estudos/geracao-do-architecture-do-produto.md` (ADR-006, evidência por decisão dada); o plano que a formaliza é `docs/superpowers/plans/2026-07-20-architecture-gerado-do-produto.md`.

## Contexto

O ADR-015 fechou o `docs/architecture.md` do produto como documento **semeado**: §1 e §2 são prosa
do Autor "nunca tocada por máquina" (ponto 3), só §3 e §4 derivadas. A dor é comprovada — no
produto conduzido pelo próprio harness, com PRD fechada sobre 10 ADRs e backlog de 19 specs, a §1 e
a §2 seguem com o placeholder literal do esqueleto. A máquina já acusa (`visao-vazia`), o veredito é
advisório (ADR-004, `NFR-05`) e o aviso isolado não moveu o Autor. Enquanto isso a ponte do plan
promete injetar a prosa estrutural (`RF-08`) e injeta vazio.

## Decisão

O documento passa a ser **gerado sob ditado e reconciliado**, compondo duas metades:

1. **Fronteira §1 × plan.** A §1 é **topologia + contratos**: nomeia os componentes de topo e o
   contrato entre eles (quem chama quem, por qual via, quem é dono de qual dado). O interior de cada
   componente é do `plan`. Regra de corte citável: *se a frase muda ao trocar UMA feature, é `plan`;
   se muda só ao trocar o produto, é §1.*
2. **Ditado com lastro.** A §1 e a §2 nascem numa fase final do `/zion-prd-decompose`: a máquina
   redige o rascunho **só sobre o que os ADRs sustentam** — o que não tem lastro vira pergunta ao
   Autor, não prosa — e ele aceita/edita/dita/pula. A prosa **nunca é sobrescrita sem confirmação**;
   é esta cláusula que substitui o "nunca tocada por máquina" do ADR-015.
3. **Âncora invisível.** O marcador de abertura do bloco carrega `adrs=` com os ADRs efetivamente
   usados na redação. Populada pela máquina, zero digitação do Autor, prosa limpa no render.
4. **Mapa no lugar do índice.** A §3 deixa de ser índice plano e vira mapa: decisões agrupadas por
   **área**, com **o que cada uma fixou** e as **specs que a exercitam**. Decisão substituída sai do
   mapa (o mapa é o vigente; o histórico mora nos ADRs). Um dono por pergunta: a §1 responde "como
   conversam", a §3 responde "o que foi decidido e onde vive".
5. **Reconciliação sem invasão.** Um terceiro bloco derivado, adjacente à narrativa, acusa
   supersessão e defasagem da âncora. Ele **nunca escreve dentro da prosa do Autor**; a cura é
   `/zion-prd-decompose --narrativa`, que oferece o rascunho novo sob confirmação.

Reafirmados do ADR-015, sem mudança: a superfície da regra no `CLAUDE.md` entre marcadores
versionados (ponto 1), o dever de origem advisório pela linha `**RF cobertos:**` (ponto 2) e a
fronteira de donos com recorte por passo (ponto 4). Redecidido: o ponto 3.

## Consequências

Zero script novo, zero skill nova, zero fonte nova no `ASSET_MAP`: os dois scripts existentes ganham
capacidade e quatro `SKILL.md` ganham prosa. O bloco de regras do produto sobe para `zion:speckit:v2`
(a cura já existe: `regras-defasadas` → re-rodar `/zion-speckit-install`). Todo ADR passa a carregar
uma **Área** — advisória, com o grupo `Sem área` absorvendo os antigos; a migração em produtos é
oportunista, não big bang. A ponte do plan passa a extrair a narrativa pelo marcador, cumprindo o
`RF-08` que já prometia. Fica fora: gerar a §4, cobertura multi-agente da regra instalada e qualquer
reescrita de prosa sem confirmação do Autor.

## Status

Aceito. Substitui o ADR-015 integralmente.
