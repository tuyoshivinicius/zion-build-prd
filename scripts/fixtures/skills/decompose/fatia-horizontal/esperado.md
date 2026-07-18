---
skill: zion-prd-decompose
fase: 4
regra: "#invest"
defeito: fatia-horizontal
veredito: reprova
achado_esperado:
  - aponta S1 como horizontal (só-back, não passa no teste-relâmpago)
  - sugere refatiar por um eixo do SPIDR
---
## Defeito plantado
A fatia "S1 — Montar todos os endpoints da API de tarefas" é horizontal: entrega só backend, não passa
no teste-relâmpago "esta fatia, sozinha, dá uma demo ponta-a-ponta?".

## Como reconhecer o acerto
A Fase 4 do decompose reprova S1, nomeia-a como horizontal (só-back) e sugere refatiar pelos eixos do
SPIDR (ex.: por Path ou Rules, cada fatia com um caminho ponta-a-ponta). Um falso-negativo é deixar S1
passar no INVEST.
