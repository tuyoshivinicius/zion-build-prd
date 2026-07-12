# Auto-sync de Assets Canônicos — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Eliminar o passo manual de sincronizar `assets/` → `skills/*/references/`, mantendo `assets/` como fonte única editável e gerando os `references/` automaticamente via pre-commit hook.

**Architecture:** `assets/` é canônico; `references/` são artefatos derivados (arquivos reais commitados, exigidos pela distribuição isolada do `npx skills`). Um manifesto único (`scripts/asset-map.sh`) é *sourced* por `sync-assets.sh`, `check-assets.sh` e pelo hook. O pre-commit hook roda o sync e faz stage dos `references/` sozinho. Um workflow de CI roda `check-assets.sh` como backstop.

**Tech Stack:** Bash, git hooks (`core.hooksPath`), GitHub Actions.

**Spec:** `docs/superpowers/specs/2026-07-12-auto-sync-assets-design.md`

---

## File Structure

| Arquivo | Responsabilidade |
|---|---|
| `scripts/asset-map.sh` | **novo** — declara `ASSET_MAP` (asset canônico → skills). Sourced; não executável. |
| `scripts/sync-assets.sh` | refatorar — itera `ASSET_MAP`, copia canônico → references. |
| `scripts/check-assets.sh` | refatorar — itera `ASSET_MAP`, falha se houver drift. |
| `.githooks/pre-commit` | **novo** — roda sync + `git add` dos references. |
| `scripts/setup-hooks.sh` | **novo** — bootstrap: seta `core.hooksPath`. |
| `.github/workflows/check-assets.yml` | **novo** — CI guard. |
| `README.md` | atualizar seção Desenvolvimento. |

**Baseline invariante:** os `references/` já estão em sync no `main`. Logo, qualquer refator correto de sync/check deve deixar `git status` **limpo** após rodar. Esse é o teste central.

---

### Task 1: Manifesto único `scripts/asset-map.sh`

**Files:**
- Create: `scripts/asset-map.sh`

- [ ] **Step 1: Criar o manifesto**

Create `scripts/asset-map.sh`:

```bash
#!/usr/bin/env bash
# Fonte única do mapeamento: asset canônico → skills que o consomem.
# Sourced por sync-assets.sh, check-assets.sh e .githooks/pre-commit.
# NÃO executar diretamente.
#
# Cada entrada: "CAMINHO_CANONICO_RELATIVO_A_ROOT  skill1 skill2 ..."
# O destino da cópia é: skills/<skill>/references/<basename do canônico>.
ASSET_MAP=(
  "assets/quality-rules.md                zion-prd-discovery zion-prd-spike zion-prd-write zion-prd-decompose zion-prd-constitution-prompt zion-prd-specify-prompt"
  "assets/templates/prd-skeleton.md       zion-prd-write"
  "assets/templates/traceability-table.md zion-prd-decompose"
)
```

- [ ] **Step 2: Verificar que carrega e mapeia como o esperado**

Run:
```bash
bash -c 'source scripts/asset-map.sh
for e in "${ASSET_MAP[@]}"; do
  read -r src skills <<< "$e"
  for s in $skills; do echo "skills/$s/references/$(basename "$src")"; done
done'
```
Expected (7 linhas, exatamente os paths já existentes hoje):
```
skills/zion-prd-discovery/references/quality-rules.md
skills/zion-prd-spike/references/quality-rules.md
skills/zion-prd-write/references/quality-rules.md
skills/zion-prd-decompose/references/quality-rules.md
skills/zion-prd-constitution-prompt/references/quality-rules.md
skills/zion-prd-specify-prompt/references/quality-rules.md
skills/zion-prd-write/references/prd-skeleton.md
skills/zion-prd-decompose/references/traceability-table.md
```
(São 8 linhas — 6 de quality-rules + 2 templates. Confirme que batem com `find skills -name '*.md' -path '*/references/*'`.)

- [ ] **Step 3: Commit**

```bash
git add scripts/asset-map.sh
git commit -m "feat(scripts): manifesto único asset-map.sh (asset → skills)"
```

---

### Task 2: Refatorar `scripts/sync-assets.sh` para usar o manifesto

**Files:**
- Modify: `scripts/sync-assets.sh` (reescrita completa)

- [ ] **Step 1: Reescrever o script**

Replace o conteúdo inteiro de `scripts/sync-assets.sh` por:

```bash
#!/usr/bin/env bash
# Copia os assets canônicos de assets/ para o references/ de cada skill que os consome.
# Fonte única de verdade: assets/. Mapeamento em scripts/asset-map.sh.
# Rodado automaticamente pelo pre-commit hook; pode ser rodado à mão também.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
source "scripts/asset-map.sh"

for entry in "${ASSET_MAP[@]}"; do
  read -r src skills <<< "$entry"
  base="$(basename "$src")"
  for s in $skills; do
    mkdir -p "skills/$s/references"
    cp "$src" "skills/$s/references/$base"
  done
done

echo "sync-assets: ok"
```

- [ ] **Step 2: Rodar o sync e confirmar que NÃO houve mudança (baseline em sync)**

Run:
```bash
./scripts/sync-assets.sh && git status --porcelain skills
```
Expected: imprime `sync-assets: ok` e a saída de `git status --porcelain skills` é **vazia** (nenhum reference mudou → refator fiel).

- [ ] **Step 3: Teste de regeneração — apagar um reference e regenerar**

Run:
```bash
rm skills/zion-prd-spike/references/quality-rules.md
./scripts/sync-assets.sh
git status --porcelain skills
```
Expected: `sync-assets: ok` e `git status` **vazio** de novo (o arquivo foi recriado idêntico ao commitado).

- [ ] **Step 4: Commit**

```bash
git add scripts/sync-assets.sh
git commit -m "refactor(scripts): sync-assets itera o manifesto asset-map"
```

---

### Task 3: Refatorar `scripts/check-assets.sh` para usar o manifesto

**Files:**
- Modify: `scripts/check-assets.sh` (reescrita completa)

- [ ] **Step 1: Reescrever o script**

Replace o conteúdo inteiro de `scripts/check-assets.sh` por:

```bash
#!/usr/bin/env bash
# Falha se qualquer references/ de skill divergir do asset canônico em assets/.
# Guard contra drift silencioso da autocontenção. Mapeamento em scripts/asset-map.sh.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
source "scripts/asset-map.sh"

fail=0
for entry in "${ASSET_MAP[@]}"; do
  read -r src skills <<< "$entry"
  base="$(basename "$src")"
  for s in $skills; do
    dest="skills/$s/references/$base"
    if ! diff -q "$src" "$dest" >/dev/null 2>&1; then
      echo "DRIFT: $dest difere de $src"
      fail=1
    fi
  done
done

if [ "$fail" -eq 0 ]; then
  echo "check-assets: sem drift"
else
  echo "check-assets: FALHOU — rode scripts/sync-assets.sh"
  exit 1
fi
```

- [ ] **Step 2: Rodar o check no estado limpo — deve passar**

Run:
```bash
./scripts/check-assets.sh
```
Expected: `check-assets: sem drift` e exit code 0 (`echo $?` → 0).

- [ ] **Step 3: Provar que detecta drift**

Run:
```bash
printf '\ndrift\n' >> skills/zion-prd-spike/references/quality-rules.md
./scripts/check-assets.sh; echo "exit=$?"
git checkout -- skills/zion-prd-spike/references/quality-rules.md
```
Expected: imprime `DRIFT: skills/zion-prd-spike/references/quality-rules.md difere de assets/quality-rules.md`, `check-assets: FALHOU …` e `exit=1`. O `git checkout` restaura o arquivo.

- [ ] **Step 4: Confirmar restauração**

Run: `./scripts/check-assets.sh`
Expected: `check-assets: sem drift`.

- [ ] **Step 5: Commit**

```bash
git add scripts/check-assets.sh
git commit -m "refactor(scripts): check-assets itera o manifesto asset-map"
```

---

### Task 4: Pre-commit hook `.githooks/pre-commit`

**Files:**
- Create: `.githooks/pre-commit`

- [ ] **Step 1: Criar o hook**

Create `.githooks/pre-commit`:

```bash
#!/usr/bin/env bash
# Regenera os references/ derivados a partir de assets/ e os inclui no commit.
# Ativado por: git config core.hooksPath .githooks  (rode scripts/setup-hooks.sh).
set -euo pipefail
ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"

# sync é só cp (barato) → roda incondicionalmente. Se falhar, aborta o commit.
./scripts/sync-assets.sh >/dev/null

# stage dos references regenerados; no-op se nada mudou.
git add skills/*/references/
```

- [ ] **Step 2: Torná-lo executável**

Run:
```bash
chmod +x .githooks/pre-commit
```
Expected: sem saída; `test -x .githooks/pre-commit && echo ok` → `ok`.

- [ ] **Step 3: Commit**

```bash
git add .githooks/pre-commit
git commit -m "feat(hooks): pre-commit regenera e faz stage dos references"
```

---

### Task 5: Bootstrap `scripts/setup-hooks.sh` e ativação

**Files:**
- Create: `scripts/setup-hooks.sh`

- [ ] **Step 1: Criar o bootstrap**

Create `scripts/setup-hooks.sh`:

```bash
#!/usr/bin/env bash
# Ativa os git hooks versionados deste repo. Idempotente — rode uma vez após clonar.
set -euo pipefail
ROOT="$(git rev-parse --show-toplevel)"
git -C "$ROOT" config core.hooksPath .githooks
echo "setup-hooks: core.hooksPath = .githooks (hooks ativados)"
```

- [ ] **Step 2: Torná-lo executável e ativá-lo**

Run:
```bash
chmod +x scripts/setup-hooks.sh
./scripts/setup-hooks.sh
git config --get core.hooksPath
```
Expected: `setup-hooks: core.hooksPath = .githooks (hooks ativados)` e a última linha imprime `.githooks`.

- [ ] **Step 3: Teste end-to-end do hook — editar asset dispara sync no commit**

Run:
```bash
printf '\n<!-- sentinela de teste -->\n' >> assets/quality-rules.md
git add assets/quality-rules.md
git commit -m "test: sentinela temporária para validar o hook"
git show --stat HEAD | grep references
```
Expected: o commit inclui **os 6** `skills/*/references/quality-rules.md` além do `assets/quality-rules.md` — o hook regenerou e fez stage sozinho, sem passo manual.

- [ ] **Step 4: Reverter a sentinela (via novo commit, para reexercitar o hook)**

Run:
```bash
git revert --no-edit HEAD
./scripts/check-assets.sh
```
Expected: o revert remove a sentinela de `assets/` e o hook re-sincroniza os references no mesmo commit; `check-assets: sem drift`.

- [ ] **Step 5: Commit do bootstrap**

```bash
git add scripts/setup-hooks.sh
git commit -m "feat(scripts): setup-hooks ativa core.hooksPath"
```

---

### Task 6: CI guard `.github/workflows/check-assets.yml`

**Files:**
- Create: `.github/workflows/check-assets.yml`

- [ ] **Step 1: Criar o workflow**

Create `.github/workflows/check-assets.yml`:

```yaml
name: check-assets
on:
  push:
  pull_request:
jobs:
  check-assets:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Verifica drift de assets derivados
        run: ./scripts/check-assets.sh
```

- [ ] **Step 2: Validar a sintaxe YAML localmente**

Run:
```bash
python3 -c "import yaml,sys; yaml.safe_load(open('.github/workflows/check-assets.yml')); print('yaml ok')"
```
Expected: `yaml ok`. (Se `python3`/PyYAML não existir, pule — a validação real ocorre no push.)

- [ ] **Step 3: Confirmar que o comando do CI passa no estado atual**

Run: `./scripts/check-assets.sh`
Expected: `check-assets: sem drift` (exit 0) — o mesmo comando que o CI roda.

- [ ] **Step 4: Commit**

```bash
git add .github/workflows/check-assets.yml
git commit -m "ci: workflow check-assets como guard de drift"
```

---

### Task 7: Atualizar README (seção Desenvolvimento)

**Files:**
- Modify: `README.md` (seção "## Desenvolvimento")

- [ ] **Step 1: Substituir a seção Desenvolvimento**

Localize a seção que hoje é:

```markdown
## Desenvolvimento

Os assets canônicos vivem em `assets/`. Após editá-los, rode:

```bash
./scripts/sync-assets.sh   # copia assets/ → references/ de cada skill
./scripts/check-assets.sh  # falha se algum references/ divergir
```

O histórico de design está em `docs/superpowers/`.
```

E substitua por:

```markdown
## Desenvolvimento

Os assets canônicos vivem em `assets/` — **fonte única de verdade**. As cópias em
`skills/*/references/` são **artefatos derivados** (arquivos reais, exigidos pela
distribuição isolada do `npx skills`) e são geradas automaticamente.

Após clonar, ative os git hooks versionados uma vez:

```bash
./scripts/setup-hooks.sh   # git config core.hooksPath .githooks
```

A partir daí, basta editar `assets/` e commitar: o pre-commit hook roda o sync e
inclui os `references/` regenerados no commit. Nunca edite `references/` à mão.

Mapeamento asset → skills: `scripts/asset-map.sh` (sourced por sync e check).

O CI roda `./scripts/check-assets.sh` como guard de drift (backstop para `--no-verify`
ou quem não rodou o `setup-hooks.sh`). Para checar/sincronizar à mão:

```bash
./scripts/sync-assets.sh   # regenera references/ a partir de assets/
./scripts/check-assets.sh  # falha se algum references/ divergir
```

O histórico de design está em `docs/superpowers/`.
```

- [ ] **Step 2: Verificar que a seção antiga sumiu**

Run:
```bash
grep -n "Após editá-los, rode" README.md; echo "exit=$?"
```
Expected: nenhuma linha e `exit=1` (o texto antigo foi removido).

- [ ] **Step 3: Commit**

```bash
git add README.md
git commit -m "docs(readme): fluxo de auto-sync (setup-hooks + references derivados)"
```

---

## Self-Review

**Spec coverage:**
- Princípio canônico × derivado → Task 1 (manifesto), Task 7 (docs). ✓
- Manifesto único `asset-map.sh` sourced → Task 1, usado em Tasks 2/3/4. ✓
- Pre-commit hook (sync + `git add`, aborta em falha) → Task 4. ✓
- Bootstrap `setup-hooks.sh` + `core.hooksPath` → Task 5. ✓
- CI guard `check-assets.yml` → Task 6. ✓
- README seção Desenvolvimento → Task 7. ✓
- Verificações do spec (sync limpo; edição dispara stage; no-op sem assets; `--no-verify`/sem-bootstrap pegos no CI; skill nova coberta) → cobertas em Tasks 2 Step 2, 5 Step 3, 4 (no-op via `git add` idempotente), 6, e 1 Step 2. ✓

**Placeholder scan:** nenhum TBD/TODO; todo código e comando estão completos. ✓

**Type/nome consistency:** `ASSET_MAP`, `read -r src skills`, `basename`, `skills/<s>/references/<base>` e `core.hooksPath .githooks` usados de forma idêntica em todas as tasks. ✓
