---
skill: zion-prd-write
fase: 4
regra: "#fronteira"
defeito:
veredito: aprova
achado_esperado:
  - check-prd.sh sai limpo e a Fase 4 ecoa "limpo"
  - o teste de vazamento de #fronteira não acha "como" em prosa
---
## Defeito plantado
Nenhum — RF por épico, NFRs com número, escopo in/out, e nenhum detalhe de tela/aceite vazando.

## Como reconhecer o acerto
A Fase 4 do write roda o `check-prd.sh` (limpo, exit 0), aplica o teste de `#fronteira` e não encontra
"como" em prosa. Um falso-positivo é inventar vazamento onde a PRD está no nível de "o quê".
