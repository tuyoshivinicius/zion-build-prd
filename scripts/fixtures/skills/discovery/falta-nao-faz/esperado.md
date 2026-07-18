---
skill: zion-prd-discovery
fase: 4
regra: "#criterios-de-conclusao"
defeito: falta-nao-faz
veredito: reprova
achado_esperado:
  - aponta que o quadro faz/não-faz não tem nenhum "não faz" explícito
  - sugere adicionar ao menos um "não faz"
---
## Defeito plantado
O quadro faz/não-faz só lista "faz". O critério **discovery** exige pelo menos um "não faz" explícito
para travar o escopo.

## Como reconhecer o acerto
A Fase 4 do discovery emite `⚠ "não faz" faltando — sugiro <correção>` e mantém ✓ nos dois itens que
existem (visão, persona). Um falso-negativo é dar ✓ nos três itens como se a descoberta estivesse
completa.
