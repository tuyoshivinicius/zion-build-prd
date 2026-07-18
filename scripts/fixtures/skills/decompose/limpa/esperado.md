---
skill: zion-prd-decompose
fase: 4
regra: "#invest"
defeito:
veredito: aprova
achado_esperado:
  - cada fatia passa no teste-relâmpago (é vertical)
  - o walking skeleton é a fatia zero (R0)
---
## Defeito plantado
Nenhum — cada fatia é vertical (dá uma demo ponta-a-ponta) e o walking skeleton é a S0 (R0).

## Como reconhecer o acerto
A Fase 4 do decompose dá veredito ✓ por item: fatias verticais e skeleton na R0. Um falso-positivo é
reprovar S1 ou S2 como horizontais quando cada uma entrega um caminho ponta-a-ponta.
