# ADR-011 — Promover as decisões consolidadas a ADRs reais

- **Status:** Aceito
- **Data:** 2026-07-18
- **Decisores:** autoria do repo
- **Evidência:** Decisão dada: brainstorming 2026-07-18 (revisa a DECIDIR-3 do governanca-canon)

## Contexto

A governança do dia 1 (ADR-010 / governanca-canon) consolidou as decisões estruturantes já tomadas como a tabela D-01…D-10 na §2 do `docs/architecture.md`, cada linha apontando o design doc de origem em `docs/superpowers/specs/`, e deixou `docs/adr/` vazio (só README), reservado para decisões futuras via `/zion-adr-new`. A consequência é que a fonte da verdade de arquitetura referencia as specs para lastrear cada decisão, e o padrão de ADR que o próprio harness adota e cobra (via `/zion-adr-new` + `check-adr.sh`) não é dogfoodado nas suas próprias decisões estruturantes. Esta é uma revisão da DECIDIR-3 do `governanca-canon`, registrada — coerente com a regra "mudar de decisão é ADR novo" — como decisão dada, sem spike nem pesquisa: o lastro é este próprio brainstorming.

## Decisão

Promover D-01…D-10 a ADRs reais em `docs/adr/` (ADR-001…ADR-010, mapeamento 1:1), no padrão do `zion-adr-new`, e transformar a §2 do `architecture.md` num índice que cita apenas os ADRs — o canon deixa de referenciar as specs. A proveniência desce uma camada: dentro de cada ADR retroativo, o campo Evidência é do tipo *conhecimento* e aponta o design doc de origem (`docs/superpowers/specs/<origem>-design.md`), reconhecido pelo `check-adr.sh`. Esta própria promoção nasce como ADR-011 (decisão dada). Preterido: manter a tabela D-xx→spec com `docs/adr/` vazio (o estado que esta decisão revisa). Como ADR-011 não revoga o ADR-010 — apenas muda *como* as decisões são registradas — não há linha `Substitui:` nem supersessão simétrica.

## Consequências

O harness passa a dogfoodar o próprio padrão de ADR nas suas decisões estruturantes, e o `check-adr.sh docs/adr` entra como backstop no pre-commit e no CI (além dos fixtures), fechando o elo entre a regra e a prática. O identificador `D-xx` some do repo — `docs/prd.md` §8 e `CLAUDE.md` passam a citar ADR-0xx. Aceita-se o trade-off de que a proveniência histórica agora vive dentro de cada ADR (uma camada abaixo do canon), e não mais na fonte da verdade de arquitetura; os design docs em `docs/superpowers/specs/` permanecem intocados como lastro citado pelos ADRs. Limite conhecido: os ADRs retroativos são destilações concisas dos design docs, não re-derivações — a decisão em si não se reabre.

## Status

Aceito.
