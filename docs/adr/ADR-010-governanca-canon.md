# ADR-010 — O repo governa a si mesmo

- **Status:** Aceito
- **Data:** 2026-07-18
- **Decisores:** autoria do repo
- **Evidência:** docs/superpowers/specs/2026-07-18-governanca-canon-design.md

## Contexto

O zion-build-prd já governa sua *distribuição* (assets → references, drift-guard, CI), mas não governa a si mesmo como **produto**: falta um documento que declare o que o harness faz e não-faz (requisitos) e outro que consolide a arquitetura adotada. Consequentemente, agents que abrem o repo para escrever specs ou planos não encontram uma fonte da verdade a ler, e mudanças de comportamento não têm para onde ser canonizadas — o histórico das decisões fica disperso em `docs/superpowers/specs/`, sem elo legível por máquina entre skills/scripts entregues e o que está documentado.

## Decisão

O repo passa a governar a si mesmo por dogfood total, elegendo **`docs/prd.md`** (o-quê/por-quê) e **`docs/architecture.md`** (como/com-quê) como as duas únicas fontes da verdade de governança: a PRD segue o próprio `assets/templates/prd-skeleton.md` sem stack (rodando limpo no `check-prd.sh`), com épicos E1–E6 e a §12 como tabela RF → épico → artefato; a architecture consolida a visão, as decisões estruturantes já tomadas (uma linha + link para o design doc, sem reabrir), o índice de ADRs, a tabela de scripts e a regra de canonização. Um `CLAUDE.md` na raiz (com `AGENTS.md` como symlink) declara esses dois docs como leitura obrigatória e impõe o dever de canonizar toda mudança de comportamento/estrutura de volta a eles **no mesmo commit**. O elo é fechado por um guard mecânico e **bloqueante**, `scripts/check-canon.sh` (achados C1–C7: skill-sem-rf, skill-fantasma, script-sem-doc, asset-sem-doc, adr-sem-indice, regra-raiz-sem-sot e dogfood delegando ao check-prd), escrito por TDD com fixtures clean/dirty, plugado no `eval.sh`, no pre-commit (após o sync) e no CI como backstop — mesmo rigor do CI de assets, e sem entrar no ASSET_MAP porque governa este repo em vez de ser distribuído. Descartou-se, por atrito, um guard de canonização por toque de arquivo (o elo escolhido é estrutural e decidível); descartou-se também deletar ou reescrever a documentação existente — `avaliacao-harness.md`, `como-usar.md` e `guia-prd-para-spec-kit.md` apenas migram (git mv) para `docs/guias/` com nota curta, intocados.

## Consequências

O repo ganha fonte da verdade única e legível por máquina, e esquecer de canonizar (por exemplo, adicionar uma skill sem RF correspondente) passa a bloquear o commit localmente e no CI, garantindo que PRD, architecture e o código entregue não divirjam; o custo é o rigor assimétrico — diferente dos gates dos projetos-alvo, que apenas aconselham, aqui o guard é blocking, exigindo disciplina de refletir cada mudança no mesmo commit. Os limites conhecidos são deliberados: nenhuma feature de produto nova, nenhuma dependência nova, nenhuma edição manual em `skills/*/references/` (derivados de assets) e nenhuma decisão passada reaberta; o `check-canon.sh` degrada em silêncio quando um ROOT de fixture não tem asset-map (como o `check-prd.sh` faz com `docs/adr/`).

## Status

Aceito.
