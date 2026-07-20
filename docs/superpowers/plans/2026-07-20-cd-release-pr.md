# CD por release-PR automatizado — plano de implementação

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Distribuir as releases do harness via CI/CD por impacto — cada merge na `main` atualiza um release-PR permanente que acumula o `CHANGELOG.md` derivado dos commits e o bump SemVer calculado; mergear o release-PR cria a tag única e publica os dois canais (plugin + skills.sh) no mesmo número.

**Architecture:** `googleapis/release-please-action@v4` (escolha do Autor, registrada no ADR-018) mantém o release-PR, escreve o `CHANGELOG.md`, calcula o bump por Conventional Commits e, no merge, cria a tag anotada + a GitHub Release e reescreve `.claude-plugin/plugin.json`.`version` via *extra-file* JSON — um número, dois canais, honrando `ADR-002`. Um commit-lint **em shell** (molde `check-*.sh` do repo, exit 0/1/2 + auto-teste com fixture) bloqueia local (hook `commit-msg`) e na CI, para o cálculo de bump nunca ver commit fora da convenção. A automação vira **RF-21 (épico E6)** + **ADR-018**, canonizada no mesmo commit.

**Tech Stack:** GitHub Actions · release-please v4 (Node, roda **só na CI** — governança, não viaja ao usuário) · Bash (commit-lint no molde dos verificadores do repo) · JSON (config + manifest do release-please).

## Global Constraints

Todo requisito de tarefa inclui implicitamente esta seção. Valores copiados literalmente da spec e das regras do repo (`CLAUDE.md`, `docs/prd.md`, `docs/architecture.md`).

- **Canonização no mesmo commit** (`CLAUDE.md`): toda mudança de comportamento/estrutura reflete nas fontes da verdade (`docs/prd.md`, `docs/architecture.md`, `docs/adr/`) **no mesmo commit**. O `scripts/check-canon.sh` roda no `.githooks/pre-commit` e **bloqueia** commit com drift; o CI (`.github/workflows/check-assets.yml`) repete como backstop. **Todo commit deste plano deixa `check-canon` e `check-adr` verdes.**
- **Contrato dos verificadores em shell** (`architecture.md §1`, `NFR-04`): exit `0` limpo · `1` achados · `2` erro de uso/ambiente; 100% dos verificadores mecânicos têm auto-teste com fixture **limpa e suja**, agregado por `scripts/eval.sh`.
- **Guards de governança bloqueiam** local + CI (diferente dos verificadores dos projetos-alvo, que só aconselham — `RN-01`/`ADR-004`). O commit-lint é guard de **governança** deste repo: **bloqueia**.
- **Fronteira o-quê/como** (`RN-02`, `quality-rules.md#fronteira`): o RF não cita ferramenta. `release-please`, PAT × GitHub App e resolução por canal vivem no **ADR-018** e no spike, **nunca** na PRD.
- **Um número, dois canais; sem branches de release** (YAGNI, herdado do design `2026-07-19-releases-v1-v2`); `.claude-plugin/marketplace.json` **intocado** (resolve por git ref, sem campo de versão).
- **`NFR-01`**: a camada mecânica (drift + auto-testes + canon) roda em **< 60 s** na CI. **`NFR-02`**: exatamente **1** dependência externa de *skill* (o executor de brainstorming) — a *action* release-please é infra de CI (governança), **não** é dependência de skill; `NFR-02` permanece intacto. **`NFR-03`**: 0 de drift tolerado. **`NFR-05`** não se aplica (é regra do projeto-alvo).
- **`assets/` é fonte única**: nenhuma tarefa deste plano edita `assets/` ou `skills/*/references/` (não há asset novo — o commit-lint é governança, não viaja; não entra no `ASSET_MAP`). O `sync-assets.sh` roda no pre-commit como no-op.
- **Idioma**: prosa dos docs/canon em **português** (idioma do repo).
- **Conventional Commits** (tabela de bump do ADR-018): `fix`→patch · `feat`→minor · `feat(x)!:` ou footer `BREAKING CHANGE:`→major · `docs`/`test`/`chore`/`ci`/`refactor`/`style`/`perf`/`build`/`revert`→sem release. O commit de release é `chore(release): vX.Y.Z` (ignorado pelo ciclo seguinte).

---

## File Structure

Arquivos criados/modificados e a responsabilidade de cada um. Decomposição travada aqui.

**Criar (mecanismo de release — governança, não viaja):**
- `.github/workflows/release.yml` — dispara release-please no push à `main` e no `workflow_dispatch`.
- `release-please-config.json` — config do release-please (release-type, changelog, extra-file do `plugin.json`).
- `.release-please-manifest.json` — âncora de versão do release-please (`{".":"2.0.0"}`).
- `version.txt` — âncora de versão do updater `simple` do release-please (bookkeeping inerte; a confirmar no spike).
- `CHANGELOG.md` — semeado no root; daí em diante escrito pelo bot.

**Criar (commit-lint — governança, bloqueia):**
- `scripts/check-commit.sh` — verificador de Conventional Commits de **uma** mensagem (exit 0/1/2).
- `scripts/test-check-commit.sh` — auto-teste do commit-lint contra fixtures (`NFR-04`).
- `scripts/fixtures/commit-clean.txt` — fixture limpa (mensagem conforme).
- `scripts/fixtures/commit-dirty.txt` — fixture suja (mensagem fora da convenção).
- `.githooks/commit-msg` — hook local bloqueante (chama `check-commit.sh`).
- `.github/workflows/commit-lint.yml` — commit-lint na CI (valida cada commit do PR).

**Criar (decisão + evidência):**
- `docs/adr/spikes/ADR-018-releases-por-impacto/README.md` — spike (pergunta/execução/veredito) + artefatos descartáveis.
- `docs/adr/ADR-018-releases-por-impacto.md` — a decisão estruturante.

**Modificar (canonização):**
- `docs/prd.md` — §6 (RF-21 no épico E6), §8 (restrição citando ADR-018), §12 (linha RF-21), §13 (cenário C1).
- `docs/architecture.md` — §2 (índice ADR-018), §3 (linhas de `check-commit.sh` e `test-check-commit.sh`).
- `scripts/eval.sh` — registra o auto-teste `commit` (3 pontos: `TESTS`, `ORDER`, validação de `sel`).
- `README.md` — seção "Releases" (runbook: declarar major, corrigir versão pós-tag).

---

## Task 1: Spike — de-risca o release-please e registra a evidência do ADR-018

**Files:**
- Create: `docs/adr/spikes/ADR-018-releases-por-impacto/README.md`
- Create (descartável): `docs/adr/spikes/ADR-018-releases-por-impacto/dry-run.txt` (saída do dry-run)

**Interfaces:**
- Consumes: nada (primeira tarefa).
- Produces: o **diretório de spike** que o `Evidência:` do ADR-018 (Task 2) aponta; o `check-adr.sh` exige `docs/adr/spikes/ADR-018-releases-por-impacto/README.md`. Produz também o **veredito** que confirma/ajusta a config concreta usada na Task 5 (conjunto exato de arquivos que o release-please escreve — em especial se o updater `simple` emite `version.txt`) e a **resposta de resolução por canal** (tag × HEAD) que afina a redação do RF-21.

Esta é a evidência de **risco de execução** que o `ADR-006` (evidência por risco) e a spec exigem para o ADR-018. Prova o que se prova localmente/read-only; o loop completo (PR abre, dispara CI, merge cria tag) é fechado na Task 7.

- [ ] **Step 1: O Autor provisiona a credencial mínima (passo manual, fora do shell)**

Criar um **PAT fine-grained** (ou GitHub App) com escopo estreito **apenas** neste repositório:
- **Contents:** Read and write
- **Pull requests:** Read and write

Guardar como *secret* do repositório com o nome **`RELEASE_PLEASE_TOKEN`** (Settings → Secrets and variables → Actions). Motivo técnico: um PR aberto pelo `GITHUB_TOKEN` default **não dispara** workflows `on: push`/`pull_request` — sem o PAT, o release-PR não passaria pelo `check-assets.yml` antes do merge (ordem segura, spec §"Ordem segura"). No runner da CI a credencial age direto (a nota "`gh` é abridor de browser" vale só no dev local).

- [ ] **Step 2: Dry-run local do cálculo de bump + changelog + updater do plugin.json**

Com a config e o manifest **provisórios** (conteúdo definido na Task 5, colar aqui para o dry-run), rodar:

```bash
# read-only: usa o PAT só para ler o repo via API
npx --yes release-please@16 release-pr \
  --token="$RELEASE_PLEASE_TOKEN" \
  --repo-url=tuyoshivinicius/zion-build-prd \
  --config-file=release-please-config.json \
  --manifest-file=.release-please-manifest.json \
  --dry-run 2>&1 | tee docs/adr/spikes/ADR-018-releases-por-impacto/dry-run.txt
```

Confirmar na saída:
1. O **próximo número** calculado bate com a tabela de bump para os commits desde `v2.0.0` (ex.: um `feat:` pendente ⇒ `2.1.0`; só `docs`/`chore` ⇒ nenhum release-PR).
2. O corpo do **changelog** proposto lista os commits agrupados por tipo.
3. O **updater do `plugin.json`** é reconhecido: a saída menciona `.claude-plugin/plugin.json` como arquivo a atualizar (via `extra-files`/`jsonpath`).
4. **Conjunto de arquivos escritos** — registrar se o updater `simple` emite/atualiza `version.txt` (decide se a Task 5 semeia `version.txt`).

- [ ] **Step 3: Confirmar a resolução por canal (tag × HEAD)**

Verificar como cada canal consome o ref (a resposta afina **só** a narrativa do RF-21, não a mecânica de bump):
- **Plugin:** `.claude-plugin/marketplace.json` tem `source: "./"` (sem campo de versão) ⇒ resolve por git ref.
- **skills.sh:** `npx skills add tuyoshivinicius/zion-build-prd` (README §Instalação) ⇒ resolve do repositório no GitHub.

Registrar no README do spike **qual ref** cada canal segue (tag anotada × HEAD da `main`) — isto responde se o merge do release-PR é *rollout instantâneo* ou se o usuário *escolhe mover*.

- [ ] **Step 4: Escrever o README do spike com pergunta / execução / veredito**

Create `docs/adr/spikes/ADR-018-releases-por-impacto/README.md`:

```markdown
# Spike — ADR-018: releases por impacto via release-PR automatizado

## Pergunta

O modelo release-PR (Alt B do estudo `docs/estudos/distribuicao-releases-cicd.md`) executa com a
credencial mínima e o mecanismo escolhido (`release-please`)? Especificamente (riscos de execução):
1. o release-PR **dispara o CI** (`check-assets.yml`) antes do merge — exige PAT, não o `GITHUB_TOKEN` default;
2. o mecanismo **reescreve `.claude-plugin/plugin.json`.`version`** para o número calculado;
3. o bump segue a tabela Conventional Commits desde a última tag;
4. cada canal (plugin, skills.sh) resolve de qual **ref** (tag × HEAD).

## O que foi rodado

- PAT fine-grained (`contents` RW + `pull-requests` RW), secret `RELEASE_PLEASE_TOKEN`.
- `npx release-please@16 release-pr --dry-run` contra a config/manifest provisórios (saída em `dry-run.txt`).
- Inspeção de `marketplace.json` (source `./`) e do comando `npx skills add` (README §Instalação).

## Veredito

- **Bump/changelog:** <o número calculado bateu com a tabela? colar o trecho da saída>
- **Updater do plugin.json:** <reconhecido? sim/não — colar linha da saída>
- **Emite `version.txt`?** <sim/não — decide o seed da Task 5>
- **Resolução por canal:** plugin → <tag|HEAD>; skills.sh → <tag|HEAD>.
- **Config validada (copiada pela Task 5):** ver `release-please-config.json` / `.release-please-manifest.json` abaixo.
- **Recuo D (plano B):** se o PAT não puder disparar o CI no release-PR (permissão intransponível),
  cai-se para o semi-automático por `workflow_dispatch` (o CD calcula versão+changelog, o Autor
  dispara a publicação) — sem PR automático, menor superfície de permissão.

## Config validada

<colar o conteúdo final de release-please-config.json e .release-please-manifest.json que o dry-run confirmou>
```

- [ ] **Step 5: Commit**

O diretório de spike **não** casa `docs/adr/ADR-*.md` (glob de filhos diretos), então `check-canon`/`check-adr` não o inspecionam — o commit fica verde antes do ADR existir.

```bash
git add docs/adr/spikes/ADR-018-releases-por-impacto/
git commit -m "docs(adr): spike ADR-018 — release-PR dispara CI + reescreve plugin.json (risco de execução)"
```

Expected: pre-commit verde (`check-canon: limpo`, `check-adr: limpo`).

---

## Task 2: ADR-018 + canonização do requisito e da decisão

**Files:**
- Create: `docs/adr/ADR-018-releases-por-impacto.md`
- Modify: `docs/architecture.md` (§2 — índice de ADRs)
- Modify: `docs/prd.md` (§6 E6 — RF-21; §8 — restrição; §12 — linha RF-21; §13 — cenário C1)

**Interfaces:**
- Consumes: `docs/adr/spikes/ADR-018-releases-por-impacto/README.md` (Task 1) — o `Evidência:` do ADR aponta para ele; `check-adr.sh` exige o dir com `README.md`.
- Produces: **RF-21** (referenciável por `docs/prd.md §12`/§13 e pelo runbook) e **ADR-018** (indexado em `architecture.md §2`). Sem `Substitui:` — decisão nova **ao lado** de `ADR-002`/`ADR-010`, sem supersessão.

- [ ] **Step 1: Criar o ADR-018**

Create `docs/adr/ADR-018-releases-por-impacto.md`:

```markdown
# ADR-018 — Releases por impacto via release-PR automatizado

- **Status:** Aceito
- **Data:** 2026-07-20
- **Decisores:** autoria do repo
- **Evidência:** docs/adr/spikes/ADR-018-releases-por-impacto/README.md (risco de execução: permissões de bot, disparo de CI no release-PR, reescrita de plugin.json.version, resolução por canal)

## Contexto

O mantenedor libera releases à mão: edita `plugin.json`.`version` num commit e cria a tag (existem
`v1.0.0`/`v2.0.0`), **sem CHANGELOG** e **sem um PR que documente** a mudança. Isso preserva três
riscos: erro humano de versão, ausência de rastro/changelog, e divergência de número entre os dois
canais por serem editados à mão. O candidato quer as releases **distribuídas via CI/CD**: o CD abre
um PR documentando as mudanças e cria a tag com a versão gerada **por impacto**, seguindo o SemVer já
praticado pela convenção de commits (`RF-21`, épico E6). Brownfield: honra a distribuição dual por
cópia real (`ADR-002`) e o canon bloqueante (`ADR-010`/`RF-13`), sem reabrir nenhuma decisão.

## Decisão

Adota-se o modelo **release-PR automatizado** (Alt B do estudo `docs/estudos/distribuicao-releases-cicd.md`),
implementado por **`googleapis/release-please-action@v4`**:

- **Versionamento — Conventional Commits puro** (fonte = os commits, que o repo já pratica):
  `fix`→patch, `feat`→minor, `feat(x)!:` / footer `BREAKING CHANGE:`→major;
  `docs`/`test`/`chore`/`ci`/`refactor`/`style`/`perf`/`build`/`revert`→sem release. O major automático é
  seguro **porque** o gate humano do release-PR confere o número calculado antes de taguear.
- **Um release-PR permanente**: a cada merge na `main`, o bot acumula o `CHANGELOG.md` (root) e o bump
  desde a última tag. Um batch só de tipos sem release **não abre** release-PR.
- **Mergear o release-PR = a publicação**: cria a **tag anotada `vX.Y.Z`** + a **GitHub Release** (corpo
  do `CHANGELOG.md`) e reescreve `plugin.json`.`version` para o **mesmo número** via *extra-file* JSON —
  um número, dois canais (`ADR-002`; `marketplace.json` intocado, resolve por git ref). O commit de
  release é `chore(release): vX.Y.Z`, logo ignorado pelo ciclo seguinte.
- **Credencial mínima**: **PAT fine-grained** (`contents` + `pull-requests`), secret `RELEASE_PLEASE_TOKEN`
  — necessário porque um PR aberto pelo `GITHUB_TOKEN` default **não dispara** os workflows `on:`, e o
  release-PR precisa passar pelo `check-assets.yml` (drift + eval + canon + adr) antes do merge.
- **Commit-lint bloqueante** de Conventional Commits (verificador em **shell**, molde `check-*.sh`),
  no hook `commit-msg` e na CI, para o cálculo de bump nunca ver commit fora da convenção.

Descartadas: **C — tag-on-merge direto** (sem o PR que documenta, sem gate humano antes de taguear);
**semantic-release** (orientado a publicar no push, encaixa pior no gate por PR). **Recuo D** (semi-automático
por `workflow_dispatch`) fica documentado como plano B se o spike achasse bloqueio de permissão intransponível.

## Consequências

O harness ganha um workflow + config de release e um commit-lint (`check-commit.sh` + auto-teste),
todos **governança** — não viajam ao usuário (o plugin empacota só `skills/`). O gate do release-PR
combina com a cultura advisory (`RN-01`): o humano confere o número antes de taguear e força a passagem
pelo CI. **Limite honesto**: a automação **calcula e documenta**; garantir por máquina que o número está
"certo" segue sendo o juízo humano do release-PR. Recuperação pós-erro (tags são imutáveis): **corrige
pra frente** (patch corretivo ou novo major), nunca reescreve tag — runbook no README. `NFR-02` intacto
(a *action* é infra de CI, não dependência de skill). Nenhum ADR vigente é revertido.

## Status

Aceito.
```

- [ ] **Step 2: Indexar o ADR-018 no `architecture.md §2`**

Modify `docs/architecture.md` — adicionar, **após** a linha do ADR-017 na tabela de ADRs (§2):

```markdown
| [ADR-018](adr/ADR-018-releases-por-impacto.md) | Releases por impacto via release-PR automatizado (release-please): Conventional Commits → bump SemVer, CHANGELOG no root, um número para os dois canais; commit-lint bloqueante. |
```

- [ ] **Step 3: RF-21 no `prd.md §6` (épico E6)**

Modify `docs/prd.md §6` — no **Épico E6 — Distribuição**, adicionar `RF-21` após `RF-16`:

```markdown
`RF-21` As releases do harness são distribuídas via CI/CD por impacto: cada merge na main atualiza um
release-PR que acumula o changelog derivado dos commits e o bump SemVer calculado; mergear o release-PR
cria a tag única e publica os dois canais no mesmo número.
```

(Uma frase, sem stack — a fronteira fica guardada: nenhuma ferramenta citada.)

- [ ] **Step 4: Restrição no `prd.md §8`**

Modify `docs/prd.md §8` — acrescentar `ADR-018` à lista de decisões estruturantes citadas (ao final da frase "Em especial: …"):

```markdown
, e as releases por impacto via release-PR automatizado (ADR-018).
```

- [ ] **Step 5: Linha RF-21 na rastreabilidade `prd.md §12`**

Modify `docs/prd.md §12` — adicionar, após a linha `RF-16`:

```markdown
| RF-21 | E6 | .github/workflows/release.yml · release-please-config.json |
```

(As linhas de `scripts/check-commit.sh` e do restante do maquinário entram nesta célula nas Tasks 3 e 5, no mesmo commit que cria cada artefato.)

- [ ] **Step 6: Cenário C1 no histórico `prd.md §13`**

Modify `docs/prd.md §13` — adicionar uma linha na tabela:

```markdown
| 2026-07-20 | C1 | `RF-21` novo: releases por impacto via release-PR automatizado (CI/CD) | governar a distribuição de releases que era manual (bump à mão, sem changelog nem PR) | ADR-018 · .github/workflows/release.yml · scripts/check-commit.sh |
```

- [ ] **Step 7: Rodar os guards antes de commitar**

```bash
./scripts/check-prd.sh prd docs/prd.md
./scripts/check-adr.sh docs/adr
./scripts/check-canon.sh
```

Expected: os três exit `0` — `check-prd: limpo`, `check-adr: limpo` (ADR-018 com Evidência apontando o spike dir criado na Task 1), `check-canon: limpo` (ADR-018 no índice §2; RF-21 na §6/§12; §13 cita ADR-018 existente).

- [ ] **Step 8: Commit**

```bash
git add docs/adr/ADR-018-releases-por-impacto.md docs/architecture.md docs/prd.md
git commit -m "docs(canon): ADR-018 + RF-21 das releases por impacto via release-PR (E6)"
```

Expected: pre-commit verde.

---

## Task 3: Commit-lint em shell (guard bloqueante) + hook local

**Files:**
- Create: `scripts/check-commit.sh`
- Create: `scripts/test-check-commit.sh`
- Create: `scripts/fixtures/commit-clean.txt`, `scripts/fixtures/commit-dirty.txt`
- Create: `.githooks/commit-msg`
- Modify: `scripts/eval.sh` (registra o auto-teste `commit`)
- Modify: `docs/architecture.md §3` (linhas dos dois scripts)
- Modify: `docs/prd.md §12` (acrescenta `scripts/check-commit.sh` à célula RF-21)

**Interfaces:**
- Consumes: RF-21 (Task 2) — os scripts são artefatos de `RF-21`.
- Produces: `scripts/check-commit.sh <arquivo-de-mensagem>` — exit `0` conforme · `1` fora da convenção · `2` uso/ambiente; lê a **1ª linha não-comentário** do arquivo como header. Consumido pelo `.githooks/commit-msg` (Task 3) e por `.github/workflows/commit-lint.yml` (Task 4).

TDD: teste primeiro, depois o script mínimo, depois a fiação de canon/eval no mesmo commit (exigência do `check-canon` C3: todo `scripts/*.sh` precisa estar na §3).

- [ ] **Step 1: Escrever as fixtures**

Create `scripts/fixtures/commit-clean.txt`:

```text
feat(release): distribui releases por impacto via release-PR
```

Create `scripts/fixtures/commit-dirty.txt`:

```text
atualiza uns arquivos
```

- [ ] **Step 2: Escrever o auto-teste (falha primeiro)**

Create `scripts/test-check-commit.sh`:

```bash
#!/usr/bin/env bash
# Auto-teste do check-commit.sh contra fixtures. Roda pela camada mecânica (scripts/eval.sh).
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
CHECK="scripts/check-commit.sh"
FIX="scripts/fixtures"
fail=0

assert_exit() {  # desc  exit_esperado  exit_veio
  if [ "$2" != "$3" ]; then echo "FALHOU: $1 (exit esperado $2, veio $3)"; fail=1
  else echo "ok: $1"; fi
}
assert_contains() {  # desc  agulha  palheiro
  if printf '%s' "$3" | grep -qi -- "$2"; then echo "ok: $1"
  else echo "FALHOU: $1 (não achou: $2)"; fail=1; fi
}

# 1. Mensagem conforme → exit 0.
out="$(bash "$CHECK" "$FIX/commit-clean.txt")"; rc=$?
assert_exit "commit conforme sai 0" 0 "$rc"
assert_contains "reporta conforme" "conforme" "$out"

# 2. Mensagem fora da convenção → exit 1 + achado.
out="$(bash "$CHECK" "$FIX/commit-dirty.txt")"; rc=$?
assert_exit "commit fora da convenção sai 1" 1 "$rc"
assert_contains "acha fora-da-convencao" "fora-da-convencao" "$out"

# 3. Sem argumento → exit 2 (erro de uso).
out="$(bash "$CHECK" 2>/dev/null)"; rc=$?
assert_exit "sem argumento sai 2" 2 "$rc"

# 4. Arquivo inexistente → exit 2.
out="$(bash "$CHECK" /caminho/que/nao/existe 2>/dev/null)"; rc=$?
assert_exit "arquivo inexistente sai 2" 2 "$rc"

if [ "$fail" -eq 0 ]; then echo "test-check-commit: tudo verde"; else echo "test-check-commit: FALHOU"; exit 1; fi
```

- [ ] **Step 3: Rodar o teste para confirmar que falha**

Run: `bash scripts/test-check-commit.sh`
Expected: FALHA — o `check-commit.sh` ainda não existe (assertivas de exit 0/1 quebram; provavelmente `FALHOU` + exit 1).

- [ ] **Step 4: Escrever o `check-commit.sh` mínimo**

Create `scripts/check-commit.sh`:

```bash
#!/usr/bin/env bash
# check-commit.sh — verificador de Conventional Commits de UMA mensagem (RF-21 / ADR-018).
# Guard de GOVERNANÇA: lido pelo .githooks/commit-msg e pela CI (commit-lint.yml) — BLOQUEIA.
# (Diferente dos verificadores dos projetos-alvo, que aconselham — RN-01/ADR-004.)
# Exit 0 = conforme · 1 = fora da convenção · 2 = erro de uso/ambiente.
#
# Uso:
#   check-commit.sh <arquivo-de-mensagem>   # 1ª linha não-comentário = header
#
# Convenção (tabela de bump do ADR-018):
#   <tipo>(<escopo>)?!?: <assunto>
#   tipos: feat fix docs test chore ci refactor style perf build revert
set -u

usage() { echo "uso: check-commit.sh <arquivo-de-mensagem>" >&2; exit 2; }

target="${1:-}"
[ -n "$target" ] || usage
case "$target" in -*) usage ;; esac
[ -f "$target" ] || { echo "check-commit: arquivo não encontrado: $target" >&2; exit 2; }

TYPES='feat|fix|docs|test|chore|ci|refactor|style|perf|build|revert'

# Header = 1ª linha não-vazia que não seja comentário (# …) — ignora o template do
# editor e o corpo/diff do modo verbose.
header="$(grep -vE '^[[:space:]]*#' "$target" | grep -vE '^[[:space:]]*$' | head -1)"

if [ -z "$header" ]; then
  echo "check-commit: mensagem-vazia — nenhuma linha de assunto encontrada"
  exit 1
fi

# Commits de merge/revert automáticos do git não são autoria de convenção — aceitos.
case "$header" in
  "Merge "*|"Revert \""*) echo "check-commit: conforme (merge/revert)"; exit 0 ;;
esac

if printf '%s\n' "$header" | grep -qE "^(${TYPES})(\([a-z0-9._-]+\))?!?: .+"; then
  echo "check-commit: conforme"
  exit 0
else
  printf 'check-commit: fora-da-convencao — "%s"\n' "$header"
  printf '  esperado: <tipo>(<escopo>)?!?: <assunto>  (tipos: %s)\n' "$TYPES"
  exit 1
fi
```

Tornar executável:

```bash
chmod +x scripts/check-commit.sh scripts/test-check-commit.sh
```

- [ ] **Step 5: Rodar o teste para confirmar que passa**

Run: `bash scripts/test-check-commit.sh`
Expected: PASSA — `test-check-commit: tudo verde`.

- [ ] **Step 6: Registrar o auto-teste no `eval.sh` (3 pontos)**

Modify `scripts/eval.sh`:

Ponto 1 — dentro do `declare -A TESTS=( … )`, adicionar a entrada (após `[canon]="scripts/test-check-canon.sh"`):

```bash
  [commit]="scripts/test-check-commit.sh"
```

Ponto 2 — na linha `ORDER=(…)`, acrescentar `commit` ao final:

```bash
ORDER=(prd estudo experiencia delegacao adr trace backlog arquitetura trace-arquitetura contract canon commit)
```

Ponto 3 — no `case "$sel"` (validação do argumento de conveniência), acrescentar `commit` à lista de padrões e ao texto de uso:

```bash
    prd|estudo|experiencia|delegacao|adr|trace|backlog|arquitetura|trace-arquitetura|contract|canon|commit) ORDER=("$sel") ;;
    *) echo "uso: eval.sh [prd|estudo|experiencia|delegacao|adr|trace|backlog|arquitetura|trace-arquitetura|contract|canon|commit]" >&2; exit 2 ;;
```

- [ ] **Step 7: Documentar os dois scripts no `architecture.md §3`**

Modify `docs/architecture.md §3` (tabela de scripts) — adicionar a linha do verificador (após `check-superpowers-contract.sh`, junto dos outros `check-*.sh`):

```markdown
| scripts/check-commit.sh | Verificador de Conventional Commits de uma mensagem (guard de governança: hook commit-msg + CI); BLOQUEIA. |
```

E a linha do auto-teste (junto dos outros `test-*.sh`):

```markdown
| scripts/test-check-commit.sh | Auto-teste do check-commit.sh contra fixtures. |
```

- [ ] **Step 8: Acrescentar `check-commit.sh` à célula RF-21 do `prd.md §12`**

Modify `docs/prd.md §12` — a linha `RF-21` passa a:

```markdown
| RF-21 | E6 | .github/workflows/release.yml · release-please-config.json · scripts/check-commit.sh · .github/workflows/commit-lint.yml |
```

- [ ] **Step 9: Criar o hook local `commit-msg`**

Create `.githooks/commit-msg`:

```bash
#!/usr/bin/env bash
# commit-msg — commit-lint bloqueante de Conventional Commits (RF-21 / ADR-018).
# Ativado por scripts/setup-hooks.sh (core.hooksPath .githooks). $1 = arquivo da mensagem.
set -euo pipefail
ROOT="$(git rev-parse --show-toplevel)"
exec "$ROOT/scripts/check-commit.sh" "$1"
```

```bash
chmod +x .githooks/commit-msg
```

- [ ] **Step 10: Rodar a suíte mecânica inteira + os guards**

```bash
./scripts/eval.sh commit      # só o novo, rápido
./scripts/eval.sh             # tudo verde (< 60s, NFR-01)
./scripts/check-canon.sh      # check-commit.sh e test-check-commit.sh na §3 (C3)
```

Expected: `eval: tudo verde` · `check-canon: limpo`.

- [ ] **Step 11: Commit (o próprio hook valida a mensagem)**

```bash
git add scripts/check-commit.sh scripts/test-check-commit.sh scripts/fixtures/commit-clean.txt \
        scripts/fixtures/commit-dirty.txt scripts/eval.sh .githooks/commit-msg \
        docs/architecture.md docs/prd.md
git commit -m "feat(release): commit-lint de Conventional Commits em shell + auto-teste (NFR-04)"
```

Expected: o `commit-msg` recém-criado valida esta própria mensagem (`feat(release): …` ⇒ conforme); pre-commit verde.

---

## Task 4: Commit-lint na CI

**Files:**
- Create: `.github/workflows/commit-lint.yml`

**Interfaces:**
- Consumes: `scripts/check-commit.sh` (Task 3).
- Produces: gate de CI que valida cada commit do PR contra Conventional Commits.

`.github/workflows/` não é guardado pelo `check-canon` (guarda `scripts/`/§3, `assets/`/§4, `skills/`/§12, ADRs/§2) — o arquivo é artefato de `RF-21` (já na célula §12 via Task 3) e não força linha de canon.

- [ ] **Step 1: Escrever o workflow**

Create `.github/workflows/commit-lint.yml`:

```yaml
name: commit-lint
on:
  pull_request:
jobs:
  commit-lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      - name: Lint Conventional Commits do PR
        shell: bash
        run: |
          git fetch --no-tags origin "${{ github.base_ref }}" >/dev/null 2>&1 || true
          base="origin/${{ github.base_ref }}"
          fail=0
          while read -r sha; do
            [ -n "$sha" ] || continue
            msg="$(mktemp)"
            git log -1 --format=%B "$sha" > "$msg"
            if ! ./scripts/check-commit.sh "$msg"; then fail=1; fi
            rm -f "$msg"
          done < <(git rev-list "$base..HEAD")
          exit "$fail"
```

- [ ] **Step 2: Validar a sintaxe do YAML e a lógica localmente**

Simular o loop contra os commits deste branch (prova que o script casa mensagens reais):

```bash
# lint dos últimos 5 commits desta branch — todos devem sair conforme
for sha in $(git rev-list -n 5 HEAD); do
  msg="$(mktemp)"; git log -1 --format=%B "$sha" > "$msg"
  ./scripts/check-commit.sh "$msg" || echo "  ↑ FORA DA CONVENÇÃO: $sha"
  rm -f "$msg"
done
```

Expected: cada commit sai `check-commit: conforme` (o histórico do repo já pratica Conventional Commits).

- [ ] **Step 3: Commit**

```bash
git add .github/workflows/commit-lint.yml
git commit -m "ci(release): commit-lint valida Conventional Commits em cada PR"
```

Expected: pre-commit verde; a mensagem `ci(release): …` passa no hook `commit-msg`.

---

## Task 5: Mecanismo de release (release-please)

**Files:**
- Create: `.github/workflows/release.yml`
- Create: `release-please-config.json`
- Create: `.release-please-manifest.json`
- Create: `CHANGELOG.md`
- Create (se o spike confirmou): `version.txt`

**Interfaces:**
- Consumes: o veredito da Task 1 (config validada, secret `RELEASE_PLEASE_TOKEN`, seed de `version.txt` sim/não), RF-21 (Task 2), o commit-lint (Tasks 3–4) garantindo commits limpos para o cálculo de bump.
- Produces: o CD que mantém o release-PR e, no merge, cria tag + Release + bump — verificado ponta-a-ponta na Task 7.

- [ ] **Step 1: Semear o `CHANGELOG.md`**

Create `CHANGELOG.md` (root):

```markdown
# Changelog

Todas as mudanças relevantes deste projeto são documentadas aqui. As entradas abaixo desta linha são
escritas pelo release-please (Conventional Commits → SemVer por impacto — ver ADR-018). Não editar à mão.

## [2.0.0] — histórico pré-automação

- Distribuição dual (plugin do Claude Code + skills.sh) por cópia real (ADR-002).
```

- [ ] **Step 2: Semear o manifest do release-please**

Create `.release-please-manifest.json`:

```json
{
  ".": "2.0.0"
}
```

- [ ] **Step 3: Escrever a config do release-please (a validada no spike da Task 1)**

Create `release-please-config.json` (conteúdo confirmado pelo dry-run da Task 1 — colar do README do spike se divergir):

```json
{
  "$schema": "https://raw.githubusercontent.com/googleapis/release-please/main/schemas/config.json",
  "packages": {
    ".": {
      "release-type": "simple",
      "package-name": "zion-build-prd",
      "changelog-path": "CHANGELOG.md",
      "include-component-in-tag": false,
      "include-v-in-tag": true,
      "bump-minor-pre-major": false,
      "extra-files": [
        { "type": "json", "path": ".claude-plugin/plugin.json", "jsonpath": "$.version" }
      ]
    }
  }
}
```

- [ ] **Step 4: Semear `version.txt` se o spike confirmou que o updater `simple` o exige**

Se o veredito da Task 1 disse **sim** (o updater `simple` emite/atualiza `version.txt`), criar `version.txt` (root) para o release-please ter uma âncora determinística — é bookkeeping inerte (`plugin.json`.`version` continua o vetor do canal via `extra-files`):

Create `version.txt`:

```text
2.0.0
```

Se o veredito disse **não**, pular este passo (e não listar `version.txt` na §12).

- [ ] **Step 5: Escrever o workflow de release**

Create `.github/workflows/release.yml`:

```yaml
name: release
on:
  push:
    branches: [main]
  workflow_dispatch:
permissions:
  contents: write
  pull-requests: write
jobs:
  release-please:
    runs-on: ubuntu-latest
    steps:
      - uses: googleapis/release-please-action@v4
        with:
          token: ${{ secrets.RELEASE_PLEASE_TOKEN }}
          config-file: release-please-config.json
          manifest-file: .release-please-manifest.json
```

(O `token` é o PAT — não o `GITHUB_TOKEN` default — para o release-PR **disparar** o `check-assets.yml` e o `commit-lint.yml` antes do merge. O bloco `permissions` cobre o caso de fallback ao `GITHUB_TOKEN`.)

- [ ] **Step 6: Finalizar a célula RF-21 do `prd.md §12` (se semeou `version.txt`)**

Se criou `version.txt`, Modify `docs/prd.md §12` — acrescentá-lo à célula RF-21:

```markdown
| RF-21 | E6 | .github/workflows/release.yml · release-please-config.json · .release-please-manifest.json · version.txt · CHANGELOG.md · scripts/check-commit.sh · .github/workflows/commit-lint.yml |
```

(Se não semeou `version.txt`, omitir esse item da lista.) `CHANGELOG.md` e `.release-please-manifest.json` são maquinário de release — não guardados por `check-canon`, listados por disciplina de canonização (`CLAUDE.md`).

- [ ] **Step 7: Validar os JSON e rodar os guards**

```bash
python3 -m json.tool release-please-config.json >/dev/null && echo "config OK"
python3 -m json.tool .release-please-manifest.json >/dev/null && echo "manifest OK"
python3 -m json.tool .claude-plugin/plugin.json >/dev/null && echo "plugin.json ainda válido"
./scripts/check-canon.sh
```

Expected: os três `OK`; `check-canon: limpo` (nenhum destes arquivos é acusado — não são `scripts/*.sh` nem fonte do `ASSET_MAP`).

- [ ] **Step 8: Commit**

```bash
git add .github/workflows/release.yml release-please-config.json .release-please-manifest.json \
        CHANGELOG.md docs/prd.md
git add version.txt 2>/dev/null || true   # só se criado no Step 4
git commit -m "feat(release): release-PR automatizado via release-please (RF-21)"
```

Expected: pre-commit verde; mensagem `feat(release): …` conforme.

---

## Task 6: Runbook de release no README

**Files:**
- Modify: `README.md`

**Interfaces:**
- Consumes: o modelo de release do ADR-018.
- Produces: a documentação humana (declarar major, corrigir versão pós-tag) que a spec pede (entregável 6).

- [ ] **Step 1: Adicionar a seção "Releases" ao README**

Modify `README.md` — adicionar, ao final do arquivo, a seção:

```markdown
## Releases (mantenedor)

As releases são **automatizadas por impacto** (ADR-018): cada merge na `main` atualiza um **release-PR**
que acumula o `CHANGELOG.md` e o bump SemVer calculado pela convenção de commits. **Mergear o release-PR**
cria a tag `vX.Y.Z`, publica a GitHub Release e reescreve `plugin.json`.`version` — o mesmo número nos
dois canais.

**Como o impacto vira versão** (Conventional Commits):

| Commit | Bump |
|--------|------|
| `fix: …` | patch (`x.y.Z`) |
| `feat: …` | minor (`x.Y.0`) |
| `feat(x)!: …` ou footer `BREAKING CHANGE:` | major (`X.0.0`) |
| `docs`/`test`/`chore`/`ci`/`refactor`/`style`/`perf`/`build`/`revert` | nenhum (não abre release-PR) |

**Declarar um major:** use `!` depois do tipo/escopo (`feat(api)!: …`) **ou** um footer `BREAKING CHANGE: …`
no corpo do commit. O número calculado passa pelo **gate humano do release-PR** antes de taguear.

**Corrigir versão errada pós-tag:** tags são **imutáveis** — **nunca reescreva uma tag**. Corrija **pra
frente**: um `fix:` corretivo (novo patch) ou, se a versão saiu no nível errado, um commit `feat!:` que
força o próximo major. O release-PR seguinte acumula a correção.

O commit-lint (`scripts/check-commit.sh`) bloqueia mensagens fora da convenção no hook `commit-msg`
(rode `./scripts/setup-hooks.sh` após clonar) e na CI (`commit-lint.yml`), para o cálculo de bump nunca
ver commit inválido.
```

- [ ] **Step 2: Commit**

```bash
git add README.md
git commit -m "docs(release): runbook de release (declarar major, corrigir versão pós-tag)"
```

Expected: pre-commit verde.

---

## Task 7: Verificação ponta-a-ponta (fecha o loop)

**Files:** nenhum (validação de comportamento no GitHub).

**Interfaces:**
- Consumes: tudo das Tasks 1–6, já na `main` (ou numa branch de teste), com o secret `RELEASE_PLEASE_TOKEN` provisionado (Task 1).
- Produces: a evidência viva de que o modelo executa (spec §Verificação) — o loop que o dry-run da Task 1 não fechava.

Segue a spec §Verificação. Cada passo observa comportamento real; não é código.

- [ ] **Step 1: Um merge de teste gera release-PR com o número certo**

Mergear na `main` um commit de impacto conhecido (ex.: um `feat:` trivial de teste, ou o próprio merge deste plano se ele já carrega `feat`). Observar: o workflow `release` roda e o **release-PR** é aberto/atualizado pelo bot, com o **número** batendo a tabela de bump (um `feat:` ⇒ minor) e o **`CHANGELOG.md`** com o diff dos commits.

Expected: PR "chore(release): …" aberto pelo bot; título/label com `vX.Y.0`.

- [ ] **Step 2: O CI roda NO release-PR antes do merge**

Confirmar que, **no** release-PR, rodaram `check-assets` (drift) + `eval.sh` + `check-canon` + `check-adr` (via `check-assets.yml`) e o `commit-lint.yml` — todos verdes. (É a prova de que o PAT dispara os workflows `on:` — o motivo técnico da credencial. Se **não** dispararam, o PAT/App está mal-escopado ⇒ acionar o **recuo D** documentado no ADR-018/spike.)

Expected: checks verdes listados no release-PR.

- [ ] **Step 3: Mergear o release-PR cria tag + Release + bump**

Mergear o release-PR. Observar o workflow `release` rodar de novo e:
- criar a **tag anotada `vX.Y.Z`**;
- criar a **GitHub Release** com o corpo do `CHANGELOG.md`;
- o commit de release conter `plugin.json`.`version` = **mesmo número** da tag (e `version.txt`/manifest, se semeados).

```bash
git fetch --tags
git tag -l 'vX.Y.Z'                                   # a tag existe
python3 -c "import json;print(json.load(open('.claude-plugin/plugin.json'))['version'])"  # == número da tag
```

Expected: tag presente; `plugin.json`.`version` igual ao número da Release.

- [ ] **Step 4: Re-rodar a publicação é idempotente**

Re-disparar o workflow `release` (`workflow_dispatch` ou um push sem impacto). Observar que **não** duplica tag nem Release — o release-please reconcilia e reconhece a release já publicada.

Expected: nenhuma tag/Release nova; o run sai limpo (nada a fazer).

- [ ] **Step 5: Registrar o veredito no README do spike**

Fechar o loop atualizando o **Veredito** de `docs/adr/spikes/ADR-018-releases-por-impacto/README.md` com o resultado real (PR abriu, CI disparou, tag/Release/bump criados, idempotência confirmada), e commitar:

```bash
git add docs/adr/spikes/ADR-018-releases-por-impacto/README.md
git commit -m "docs(adr): veredito do spike ADR-018 — loop fechado (PR→CI→tag→Release→bump)"
```

Expected: pre-commit verde; o modelo release-PR está operante.

---

## Self-Review

**1. Cobertura da spec (§Entregáveis + §Verificação + §Canonização):**

| Item da spec | Task |
|---|---|
| 1. `.github/workflows/release.yml` + config (release-PR, bump, CHANGELOG, tag+Release+bump no merge) | Task 5 |
| 2. `CHANGELOG.md` no root (semeado) | Task 5 |
| 3. Commit-lint bloqueante (pre-commit + CI), shell, auto-teste + fixture (NFR-04) | Tasks 3–4 |
| 4. `docs/adr/ADR-018-*.md` sustentado por spike | Tasks 1–2 |
| 5. Canonização: prd.md (§6 RF-21, §8, §12, §13 C1) + architecture.md (§2, §3) | Tasks 2, 3 |
| 6. Runbook (declarar major, corrigir versão pós-tag) | Task 6 |
| Verificação (spike → merge de teste → CI no PR → tag/Release/bump → idempotência) | Tasks 1, 7 |
| Credencial (PAT fine-grained `contents`+`pull-requests`; recuo D documentado) | Task 1, ADR-018 |
| Resolução por canal (spike-confirm tag × HEAD) | Task 1 (Step 3) |

**2. Placeholders:** os únicos `<…>` vivem **dentro** do template do README do spike (Task 1) e são os campos que o próprio spike preenche com a saída real — é o produto da tarefa, não um buraco do plano. A config do release-please (Task 5) é concreta; o único ponto condicional (`version.txt` sim/não) é resolvido pelo veredito determinístico do spike (Task 1, Step 2.4), com os dois ramos explicitados.

**3. Consistência de nomes/tipos:** `scripts/check-commit.sh` (contrato `<arquivo-de-mensagem>` → exit 0/1/2, achado `fora-da-convencao`) é consumido igual pelo `.githooks/commit-msg` (Task 3) e pelo `commit-lint.yml` (Task 4). O secret é `RELEASE_PLEASE_TOKEN` em Task 1, ADR-018 e Task 5. O eval alias é `commit` nos 3 pontos do `eval.sh` (Task 3, Step 6) e no `test-check-commit.sh`. RF-21 é referenciado consistentemente em §6/§8/§12/§13 e no ADR-018.

**4. Ordem × pre-commit verde:** cada commit foi checado contra os guards bloqueantes — o spike (Task 1) não casa `docs/adr/ADR-*.md`; o ADR-018 (Task 2) já tem o spike dir como Evidência e entra no índice §2 no mesmo commit; os scripts (Task 3) entram na §3 (C3) no mesmo commit que os cria; os JSON/workflows/CHANGELOG (Tasks 4–5) não são guardados por `check-canon`.

---

## Execution Handoff

**Plano completo e salvo em `docs/superpowers/plans/2026-07-20-cd-release-pr.md`. Duas opções de execução:**

**1. Subagent-Driven (recomendado)** — dispatch de um subagente novo por task, revisão entre tasks, iteração rápida.

**2. Inline Execution** — executa as tasks nesta sessão via executing-plans, em lotes com checkpoints de revisão.

**Nota de dependência humana:** a **Task 1, Step 1** (provisionar o PAT `RELEASE_PLEASE_TOKEN`) e toda a **Task 7** (observação no GitHub) exigem ação do Autor no repositório/GitHub — não são automatizáveis pelo executor. As Tasks 2–6 são executáveis fim-a-fim.

**Qual abordagem?**
