# ADR-012 — Estágio 0 opcional de estudo pré-discovery

- **Status:** Aceito
- **Área:** Jornada
- **Data:** 2026-07-18
- **Decisores:** autoria do repo
- **Evidência:** Decisão dada: o prompt one-shot de estudo já provou o valor na prática do autor; o design que o formaliza é `docs/superpowers/specs/2026-07-18-zion-prd-estudo-design.md`.

## Contexto

Antes de rodar o discovery, o autor às vezes precisa de um estudo que oriente a direção: edge
cases, alternativas comparadas, ROI e uma recomendação não vinculante. Hoje isso é feito por um
prompt one-shot fora do harness — sem governança: não lê as fontes canônicas do projeto-alvo por
contrato, não respeita mecanicamente a fronteira o-quê/como, não é verificável (padrão E5) nem
distribuível pelos dois canais. A dúvida estruturante era se esse passo entra na jornada como
estágio formal ou permanece fora; não há nada a provar rodando nem lendo — o valor já foi provado
na prática do autor —, então a decisão chega como decisão dada (RN-03, ADR-006).

## Decisão

A jornada ganha um **Estágio 0 formal e opcional** — a skill `zion-prd-estudo` (prefixo por
ADR-003) —, antes da descoberta: contrato de fases com convergência no padrão dos irmãos (gates
aconselham, nunca bloqueiam — RN-01), saída `docs/estudos/<slug>.md` com 6 seções fixas, e
verificador mecânico próprio `check-estudo.sh` no padrão E5 (fixtures limpa/suja + auto-teste,
agregado pelo `eval.sh`, distribuído como reference executável via `ASSET_MAP`). O estudo
**aconselha, não decide**: subsidia; o humano escolhe a alternativa e conduz ele mesmo
discovery → spike/ADR → PRD. Preterido: manter o prompt one-shot fora do harness (o estado que
esta decisão revisa).

## Consequências

O estudo passa a ler as fontes canônicas do projeto-alvo por contrato (brownfield: nenhuma
alternativa contradiz ADR vigente sem declarar a supersessão como custo; greenfield: degrada
graciosamente), guarda a fronteira sem-stack por máquina nas seções de Alternativas e ROI, e
viaja pelos dois canais de distribuição (ADR-002). A jornada ganha um estágio a mais para manter
(RF-17, `check-estudo.sh`, fixtures). Limite conhecido: a skill estuda um candidato por vez, não
rankeia candidatos, e não executa o discovery nem grava artefato downstream algum.

## Status

Aceito.
