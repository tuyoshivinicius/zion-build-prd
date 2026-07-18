---
skill: zion-prd-decompose
fase: 4
regra: "#invest"
defeito: skeleton-nao-r0
veredito: reprova
achado_esperado:
  - aponta que o walking skeleton (S1) não é a fatia zero (R0)
  - sugere mover o skeleton para a R0
---
## Defeito plantado
O walking skeleton está em S1 (R1), não na fatia zero. A R0 é ocupada por "Filtrar por responsável",
que não prova o pipeline inteiro. O critério **decompose** exige o walking skeleton como fatia zero (R0).

## Como reconhecer o acerto
A Fase 4 do decompose aponta que o walking skeleton não está na R0 e sugere movê-lo para a fatia zero.
Um falso-negativo é aprovar o backlog só porque um skeleton existe, sem checar que ele é a R0.
