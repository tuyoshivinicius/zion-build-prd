---
skill: zion-prd-evolve
fase: 1
regra: "#dia-2"
defeito: decisao-disfarcada-de-requisito
veredito: C3
achado_esperado:
  - classifica a mudança como C3 (decisão revertida), não apenas C2 (RF alterado)
  - identifica que o driver é trocar o motor de exportação fixado na ADR-002 (uma decisão estruturante)
  - roteia para a supersessão de ADR (`/zion-adr-new --substitui ADR-002`), além de editar o RF-06 e o changelog
---
## Defeito plantado
A mudança **parece** um simples RF alterado (C2 — "exportar vetor em vez de raster"), mas o que a
sustenta é a queda de uma decisão estruturante: o motor de exportação fixado na ADR-002 não gera vetor.
Endereçar só o RF (C2) deixa a ADR-002 viva e a §8 apontando uma restrição morta. É C3 (decisão
revertida) disfarçada de requisito — a classe que a Fase 1 do evolve precisa enxergar.

## Como reconhecer o acerto
A Fase 1 do evolve classifica a mudança como **C3** (ou C2+C3), não só C2: aponta que trocar o motor
implica substituir a ADR-002 por um ADR novo (referência simétrica) e atualizar a restrição da §8, além
de editar o RF-06 e registrar a linha no changelog. Um falso-negativo é classificar como só C2 e seguir
para re-specify sem tocar o ADR — deixando a decisão revertida sem lastro.
