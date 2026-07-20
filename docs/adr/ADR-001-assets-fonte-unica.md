# ADR-001 — Fonte única de assets com derivados sincronizados

- **Status:** Aceito
- **Área:** Distribuição
- **Data:** 2026-07-12
- **Decisores:** autoria do repo
- **Evidência:** docs/superpowers/specs/2026-07-12-auto-sync-assets-design.md

## Contexto

Os assets canônicos vivem em `assets/`, mas cada skill é autocontida e precisa carregar em `skills/<skill>/references/` uma cópia byte-idêntica dos assets que consome, porque as skills são distribuídas por dois canais incompatíveis com referências externas: o `npx skills add` (Canal A) copia cada pasta de skill isoladamente — assumindo cópia literal, sem dereferência de symlink — e o plugin do Claude Code (Canal B) consome o repositório git diretamente; assim, um symlink ou um arquivo gitignorado gerado só em publish-time quebraria, obrigando cada `references/*.md` a ser um arquivo real e commitado. Hoje a sincronização (`scripts/sync-assets.sh`) e a verificação (`scripts/check-assets.sh`) são disparadas manualmente e a lista de skills está duplicada nos dois scripts, o que é fácil de esquecer e produz drift silencioso entre o canônico e seus derivados.

## Decisão

Adotamos `assets/` como a única fonte de verdade editável por humanos e tratamos `skills/*/references/*.md` como artefatos derivados byte-idênticos, regenerados automaticamente — descartando explicitamente a alternativa de arquivo físico único (inviável pelos dois canais de distribuição) e o watcher de editor ou geração em publish-time (YAGNI): o mapeamento asset→skills é centralizado em um manifesto único `scripts/asset-map.sh` (sourced por ambos os scripts e pelo hook, eliminando a duplicação), um pre-commit hook versionado em `.githooks/pre-commit` (ativado via `git config core.hooksPath .githooks` pelo bootstrap idempotente `scripts/setup-hooks.sh`) roda `sync-assets.sh` incondicionalmente e faz `git add` dos references para o commit já sair consistente sob `set -euo pipefail`, e um CI guard (`.github/workflows/check-assets.yml`) roda `check-assets.sh` em push e pull_request como defesa em profundidade, sem banner "generated" nos derivados para não quebrar o `diff` do check.

## Consequências

O desenvolvedor deixa de sincronizar assets à mão — editar um asset e commitar regenera e faz stage de todos os references automaticamente — e adicionar uma skill nova passa a ser uma única edição no `ASSET_MAP`; commits que não tocam `assets/` permanecem no-op (nem `cp` de arquivo idêntico nem `git add` de arquivo inalterado geram ruído), e o CI cobre quem usou `git commit --no-verify`, quem nunca rodou o bootstrap ou contribuidores externos, falhando com a mensagem acionável já existente (`rode scripts/sync-assets.sh`). Em troca, aceita-se manter cópias físicas duplicadas na árvore versionada (não há fonte única literal, apenas "no espírito"), depender de um bootstrap manual de hooks por clone tendo o CI como backstop, e tratar os `references/` como saída gerada que nunca deve ser editada diretamente — limite documentado na seção Desenvolvimento do README.

## Status

Aceito.
