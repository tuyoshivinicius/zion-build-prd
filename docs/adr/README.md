# ADRs do zion-build-prd

Decisões estruturantes **deste repo** (não dos projetos-alvo), registradas no padrão do
`/zion-adr-new` com as seções Contexto / Decisão / Consequências / Status. O índice está populado
com **ADR-001…ADR-011** e é espelhado na §2 de `docs/architecture.md` — `scripts/check-canon.sh`
acusa ADR fora do índice.

ADR-001…ADR-010 são **retroativos**: promovem as decisões antes consolidadas como D-01…D-10 e sua
Evidência é do tipo *conhecimento*, apontando o design doc de origem em `docs/superpowers/specs/`
(que permanece como lastro histórico, citado pelos ADRs e não mais pelo canon). ADR-011 registra a
própria promoção, no modo *decisão dada*. Decisão nova ou reversão nasce como ADR novo (supersessão
simétrica), e o `scripts/check-adr.sh docs/adr` (pre-commit + CI) cobra Evidência presente.
