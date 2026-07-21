# Provisionar o `RELEASE_PLEASE_TOKEN`

> **Governança:** este documento é **guia de uso**, não normativo. O requisito vive em
> [`docs/prd.md`](../prd.md) (`RF-21`) e a decisão em
> [`docs/adr/ADR-019-releases-por-impacto.md`](../adr/ADR-019-releases-por-impacto.md) — as fontes da
> verdade. Aqui só se narra **como** criar, cadastrar, validar e rotacionar a credencial.

A esteira de release (`ADR-019`) é movida pela `googleapis/release-please-action@v4` no workflow
[`.github/workflows/release.yml`](../../.github/workflows/release.yml). A action precisa de uma
credencial para abrir/atualizar o release-PR e, no merge, criar a tag e a GitHub Release.

## Por que não basta o `GITHUB_TOKEN` default

Um PR (ou push) feito com o `GITHUB_TOKEN` **default** do runner **não dispara** outros workflows
`on: push`/`on: pull_request` — é a proteção do GitHub contra loops de automação. Como a **ordem
segura** desta esteira exige que o release-PR passe pelo `check-assets.yml` (drift + `eval.sh` +
canon + adr) e pelo `commit-lint.yml` **antes** do merge, a credencial precisa ser um **PAT
fine-grained** (ou GitHub App). Sem isso, o release-PR abriria sem CI — o gate humano perderia o
respaldo mecânico.

## 1. Criar o PAT fine-grained

GitHub → **Settings → Developer settings → Personal access tokens → Fine-grained tokens →
Generate new token**.

- **Token name:** `release-please — zion-build-prd`
- **Expiration:** 90 dias (a rotação faz parte do runbook — ver §4). Evite "No expiration".
- **Resource owner:** a conta/org dona do repositório.
- **Repository access:** **Only select repositories** → `tuyoshivinicius/zion-build-prd`
  (escopo estreito — só este repo).
- **Repository permissions** (o mínimo que a action usa):
  - **Contents:** Read and write — criar a tag, o commit de release e a GitHub Release.
  - **Pull requests:** Read and write — abrir/atualizar o release-PR.
  - _(deixe todo o resto em "No access".)_

Gere e **copie o token uma vez** (o GitHub não o mostra de novo).

> **Alternativa — GitHub App.** Para uma credencial que não expira com uma pessoa, instale uma
> GitHub App com as mesmas duas permissões e troque `secrets.RELEASE_PLEASE_TOKEN` por um token de
> instalação gerado no job (ex.: `actions/create-github-app-token`). Mesma superfície de permissão,
> mais cerimônia — o PAT fine-grained é o caminho default deste repo.

## 2. Cadastrar como secret do repositório

Repositório → **Settings → Secrets and variables → Actions → New repository secret**.

- **Name:** `RELEASE_PLEASE_TOKEN` (exatamente — é o nome lido pelo `release.yml`).
- **Secret:** cole o PAT.

Confirme que o nome bate com a referência no workflow:

```bash
grep -n RELEASE_PLEASE_TOKEN .github/workflows/release.yml
```

## 3. Validar

**Dry-run local (read-only)** — confirma o cálculo de bump/changelog e o updater do `plugin.json`
sem escrever nada no GitHub:

```bash
export RELEASE_PLEASE_TOKEN=<o-pat>   # só na sessão; não commitar
npx --yes release-please@16 release-pr \
  --token="$RELEASE_PLEASE_TOKEN" \
  --repo-url=tuyoshivinicius/zion-build-prd \
  --config-file=release-please-config.json \
  --manifest-file=.release-please-manifest.json \
  --dry-run
```

Registre o resultado no **Veredito** do spike
([`docs/adr/spikes/ADR-019-releases-por-impacto/README.md`](../adr/spikes/ADR-019-releases-por-impacto/README.md)).

**Ponta-a-ponta (a prova real):** com o secret cadastrado, um merge na `main` deve abrir/atualizar o
release-PR e — o ponto crítico — **disparar** `check-assets` e `commit-lint` **no** release-PR. Se os
checks **não** aparecerem no release-PR, o PAT está mal-escopado (permissão ou repo errados) ⇒ acione
o **Recuo D** documentado no ADR-019 (semi-automático por `workflow_dispatch`).

## 4. Rotacionar

Antes da expiração (ou a qualquer suspeita de vazamento):

1. Gere um **novo** PAT fine-grained com os mesmos escopos (§1).
2. Atualize o secret `RELEASE_PLEASE_TOKEN` (§2) — o "Update secret" substitui o valor sem renomear.
3. **Revogue** o PAT antigo em Developer settings.
4. Valide com o dry-run (§3).

Como tags são imutáveis, um PAT comprometido não "desfaz" releases já publicadas — mas pode abrir PRs
e criar tags novas; revogue assim que rotacionar.

## Ver também

- [`README.md` §Releases (mantenedor)](../../README.md) — o runbook de versionamento por impacto.
- [`ADR-019`](../adr/ADR-019-releases-por-impacto.md) — a decisão e o Recuo D.
