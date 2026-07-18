---
skill: zion-prd-evolve
fase: 1
regra: "#dia-2"
defeito:
veredito: C2
achado_esperado:
  - classifica a mudança como C2 (RF alterado), sem inventar um C3
  - roteia para editar o RF-02 na §6, registrar o changelog na §13 e re-fatiar/re-especificar o épico afetado
  - não dispara supersessão de ADR (nenhuma decisão estruturante caiu)
---
## Defeito plantado
Nenhum — é uma alteração de RF genuína (C2), sem decisão estruturante por baixo. A própria mudança diz
que a arquitetura não muda. Serve de guarda contra o falso-positivo de classificar tudo como C3.

## Como reconhecer o acerto
A Fase 1 do evolve classifica como **C2** e roteia para editar o RF-02, registrar o changelog e
re-fatiar/re-especificar o épico afetado — **sem** abrir supersessão de ADR. Um falso-positivo é enxergar
um C3 onde não há decisão revertida e mandar criar um ADR à toa.
