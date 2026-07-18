# ADR-014 — Qualidade de experiência é NFR carregado, com verificador que aconselha

- **Status:** Aceito
- **Data:** 2026-07-18
- **Decisores:** autoria do repo
- **Evidência:** Decisão dada: o Autor escolheu a alternativa A2 no estudo `docs/estudos/discovery-ux-design.md` (ADR-006, evidência por decisão dada); o design que a formaliza é `docs/superpowers/specs/2026-07-18-nfr-experiencia-carrier-design.md`.

## Contexto

O backlog decomposto (RF-05) não se preocupa com experiência, e o app resultante fica rico em
função e pobre de uso. A dor mora no backlog, mas o sinal de qualidade de experiência precisa
nascer antes — no discovery — e sobreviver por discovery → PRD → decomposição → backlog. Hoje nada
carrega esse sinal, e nada de máquina acusa sua ausência. A dúvida estruturante — se a experiência
entra como carregador forte (marcador + verificador) ou fica em prosa solta — foi decidida pelo
Autor ao escolher a alternativa A2 do estudo `discovery-ux-design.md`; chega como decisão dada
(RN-03, ADR-006), sem nada a provar rodando nem lendo.

## Decisão

A qualidade de experiência vira um **NFR mensurável** carregado por um único marcador
machine-legível — `Superfície de uso: sim/não` — nascido no discovery e cobrado por um verificador
novo `check-experiencia.sh` que **aconselha** (honra ADR-004, RN-01, NFR-05) tanto na PRD quanto no
backlog. Quatro decisões fechadas: (1) gatilho advisório no discovery, `não` por default;
(2) carregador **forte** — verificador novo, não só prosa; (3) âncora na própria PRD, distinguida
pela tag `(experiência)` num NFR (contrato 1-arquivo preservado); (4) o carregador de máquina vai
até o backlog (âncora por spec), não para na PRD. Preterido: deixar a experiência como prosa não
verificável (o estado que esta decisão revisa).

## Consequências

O harness ganha um verificador a mais para manter (`check-experiencia.sh`, `test-check-experiencia.sh`,
fixtures pareadas), no padrão E5, agregado pelo `eval.sh` e distribuído como reference executável via
ASSET_MAP a `zion-prd-write` e `zion-prd-decompose`. As skills de discovery, write e decompose ganham
um passo advisório cada. Nenhuma dependência externa nova (NFR-02, ADR-007 intactos). Não toca o
specify-prompt (RF-07) nem o trace (RF-09): o alcance de máquina para no backlog. Limite conhecido: o
check verifica **presença** da âncora, não vazamento visual — detectar "tela" vazando continua
julgamento humano na fronteira (denylist stack-only, inalterado).

## Status

Aceito.
