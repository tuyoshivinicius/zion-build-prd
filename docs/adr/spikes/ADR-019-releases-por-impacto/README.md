# Spike — ADR-019: releases por impacto via release-PR automatizado

> **Estado:** esqueleto. Os campos `<…>` do Veredito são preenchidos pelo Autor depois de
> provisionar o PAT e rodar o dry-run (passos manuais abaixo). O loop completo (PR abre → dispara
> CI → merge cria tag) fecha na Task 7 do plano `docs/superpowers/plans/2026-07-20-cd-release-pr.md`.

## Pergunta

O modelo release-PR (Alt B do estudo `docs/estudos/distribuicao-releases-cicd.md`) executa com a
credencial mínima e o mecanismo escolhido (`release-please`)? Especificamente (riscos de execução):
1. o release-PR **dispara o CI** (`check-assets.yml`) antes do merge — exige PAT, não o `GITHUB_TOKEN` default;
2. o mecanismo **reescreve `.claude-plugin/plugin.json`.`version`** para o número calculado;
3. o bump segue a tabela Conventional Commits desde a última tag;
4. cada canal (plugin, skills.sh) resolve de qual **ref** (tag × HEAD).

## Passos manuais (Autor) — de-risca a execução

### 1. Provisionar a credencial mínima

Criar um **PAT fine-grained** (ou GitHub App) com escopo estreito **apenas** neste repositório:
- **Contents:** Read and write
- **Pull requests:** Read and write

Guardar como *secret* do repositório com o nome **`RELEASE_PLEASE_TOKEN`**
(Settings → Secrets and variables → Actions). Motivo técnico: um PR aberto pelo `GITHUB_TOKEN`
default **não dispara** workflows `on: push`/`pull_request` — sem o PAT, o release-PR não passaria
pelo `check-assets.yml` antes do merge (ordem segura). No runner da CI a credencial age direto (a
nota "`gh` é abridor de browser" vale só no dev local).

### 2. Dry-run local do cálculo de bump + changelog + updater do plugin.json

Com a config e o manifest já versionados (Task 5 do plano), rodar (read-only: usa o PAT só para ler
o repo via API):

```bash
npx --yes release-please@16 release-pr \
  --token="$RELEASE_PLEASE_TOKEN" \
  --repo-url=tuyoshivinicius/zion-build-prd \
  --config-file=release-please-config.json \
  --manifest-file=.release-please-manifest.json \
  --dry-run 2>&1 | tee docs/adr/spikes/ADR-019-releases-por-impacto/dry-run.txt
```

Confirmar na saída:
1. O **próximo número** calculado bate com a tabela de bump para os commits desde `v2.0.0`
   (ex.: um `feat:` pendente ⇒ `2.1.0`; só `docs`/`chore` ⇒ nenhum release-PR).
2. O corpo do **changelog** proposto lista os commits agrupados por tipo.
3. O **updater do `plugin.json`** é reconhecido: a saída menciona `.claude-plugin/plugin.json`
   como arquivo a atualizar (via `extra-files`/`jsonpath`).
4. **Conjunto de arquivos escritos** — o updater `simple` mantém `version.txt`; confirmar que a
   saída o lista (a Task 5 já semeia `version.txt` por esse motivo).

### 3. Confirmar a resolução por canal (tag × HEAD)

- **Plugin:** `.claude-plugin/marketplace.json` tem `source: "./"` (sem campo de versão) ⇒ resolve por git ref.
- **skills.sh:** `npx skills add tuyoshivinicius/zion-build-prd` (README §Instalação) ⇒ resolve do repositório no GitHub.

Registrar **qual ref** cada canal segue (tag anotada × HEAD da `main`) — responde se o merge do
release-PR é *rollout instantâneo* ou se o usuário *escolhe mover*.

## Veredito (preencher após o dry-run)

- **Bump/changelog:** <o número calculado bateu com a tabela? colar o trecho da saída>
- **Updater do plugin.json:** <reconhecido? sim/não — colar linha da saída>
- **Emite `version.txt`?** <sim/não — a Task 5 semeia `version.txt` no pressuposto de sim (updater `simple`); confirmar>
- **Resolução por canal:** plugin → <tag|HEAD>; skills.sh → <tag|HEAD>.
- **Config validada (copiada pela Task 5):** ver `release-please-config.json` / `.release-please-manifest.json` no root.
- **Recuo D (plano B):** se o PAT não puder disparar o CI no release-PR (permissão intransponível),
  cai-se para o semi-automático por `workflow_dispatch` (o CD calcula versão+changelog, o Autor
  dispara a publicação) — sem PR automático, menor superfície de permissão.

## Config validada

<colar o conteúdo final de release-please-config.json e .release-please-manifest.json que o dry-run confirmou>
