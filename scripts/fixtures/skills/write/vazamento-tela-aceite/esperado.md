---
skill: zion-prd-write
fase: 4
regra: "#fronteira"
defeito: vazamento-tela-aceite
veredito: reprova
achado_esperado:
  - aponta o critério de aceite detalhado (Dado/Quando/Então) como "como", não "o quê"
  - aponta o detalhe de tela/layout (barra no topo, duas colunas, avatar) vazando
  - sugere mover o detalhe para o spec.md/plan.md da feature
---
## Defeito plantado
A seção "Critério de aceite do RF-01" descreve **como** a tela é (barra de progresso no topo, texto
alinhado à direita, lista em duas colunas, avatar circular) e um critério de aceite detalhado — ambos
"como", que o `check-prd.sh` **não** pega (nenhum termo de denylist, nenhum sinal estrutural). É a zona
cinzenta do F6: julgamento puro da fronteira `#fronteira`.

## Como reconhecer o acerto
A Fase 4 do write roda o `check-prd.sh` (que sai limpo aqui) e **complementa** com o teste de vazamento
de `#fronteira`: aponta o critério de aceite e o detalhe de layout como vazamento de "como", com a
linha, e sugere movê-los para o `spec.md`/`plan.md` da feature. Um falso-negativo é confiar só no
`check-prd.sh` limpo e aprovar a PRD.
