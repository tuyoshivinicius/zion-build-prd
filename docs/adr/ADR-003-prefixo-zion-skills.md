# ADR-003 — Prefixo zion- em todas as skills

- **Status:** Aceito
- **Data:** 2026-07-12
- **Decisores:** autoria do repo
- **Evidência:** docs/superpowers/specs/2026-07-12-zion-prefixo-skills-design.md

## Contexto

As 8 skills internas do harness Zion Build PRD (`prd-discovery`, `prd-spike`, `prd-write`, `prd-decompose`, `prd-constitution-prompt`, `prd-specify-prompt`, `adr-new` e a utilitária `rewrite-prompt`) tinham nomes genéricos sem namespace próprio, o que as tornava indistintas de skills externas do ecossistema (`superpowers:brainstorming`, `deep-research` built-in do Claude Code, `/speckit.*` do Spec Kit) e frágeis quanto à identidade de marca, ainda que o plugin/marketplace já se chamasse `zion-build-prd`. Buscava-se uma identidade de nomes estável e reconhecível para todas as skills do território do harness, aplicada de forma orgânica em diretórios, corpos de `SKILL.md`, assets canônicos, scripts, guias vivos (README, guia-prd-para-spec-kit, como-usar) e no conteúdo do histórico de design, sem regredir a semântica de processo já validada.

## Decisão

Prefixar `zion-` nas 8 skills do harness (`prd-discovery` → `zion-prd-discovery`, e assim por diante, incluindo `adr-new` e a genérica `rewrite-prompt`), consolidando um namespace estável e coerente com a marca do plugin em ambos os canais (diretórios/`name:` das skills e todas as citações em guias, assets e histórico), via `git mv` das pastas para preservar histórico e reescrita disciplinada de cada `SKILL.md` pela metodologia do skill-creator (`description` mais "pushy" com "quando usar", estrutura imperativa, progressive disclosure) mantendo como invariantes fixos o contrato de 5 fases, os gates que aconselham sem bloquear, os preflights de dependência e a guarda de fronteira o-quê/como; o grafo de referências cruzadas, os assets (`process-context.md`, `prd-skeleton.md`) e o `scripts/asset-map.sh` são atualizados, com os `references/` regenerados por `sync-assets.sh`. Foram descartados: renomear tokens externos (`superpowers`, `deep-research`, `speckit`) e o próprio plugin/marketplace `zion-build-prd`, que já é a marca e permanece; renomear os arquivos do histórico de design (identidade é data+tema, renomear quebraria links sem agregar, então apenas o conteúdo muda); e a substituição global cega por `sed`, preterida por edição arquivo a arquivo dos 8 tokens exatos com negative lookbehind de `zion-` para nunca duplo-prefixar.

## Consequências

Ganha-se um namespace único e alinhado à marca, com histórico Git preservado nas pastas e semântica de processo intacta, ao custo de uma superfície ampla de edição sincronizada (README, guias com 9 e 41 ocorrências, assets, scripts, specs/plans) e de riscos de substituição que exigem disciplina: falsos-positivos porque `zion-build-prd` contém `prd` e `prd-spike-descoberta` contém `prd-spike`, e o perigo de duplo-prefixar ou tocar tokens externos, mitigados por substituição limitada aos 8 tokens exatos com lookbehind/boundaries e verificação manual. O drift entre assets e `references/` é contido rodando `sync-assets.sh` seguido de `check-assets.sh` (deve passar verde), com validação final por grep confirmando zero tokens de skill sem prefixo remanescentes (fora de `zion-build-prd` e dos `zion-*` legítimos) e inspeção de que `superpowers`/`deep-research`/nome-do-plugin permaneceram e as 8 pastas `skills/zion-*/` têm `name:` coerente; fica explicitamente fora de escopo alterar fases/gates/fronteira, renomear o plugin ou dependências externas e renomear arquivos do histórico.

## Status

Aceito.
