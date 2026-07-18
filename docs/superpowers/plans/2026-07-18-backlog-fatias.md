# Backlog de fatias por máquina (`docs/backlog.md`) — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Tornar a fatia vertical um artefato de primeira classe — um `docs/backlog.md` versionado (semeado pelo `/zion-prd-decompose`), reconciliado no grão da fatia por um script de dono único (`scripts/trace-backlog.sh`), com o slug cunhado no decompose e carregado até o `/speckit.specify`, e o `/zion-prd-trace` estendido para reconciliar os dois artefatos.

**Architecture:** Espelha o padrão já existente da §12 (`trace-prd.sh` ↔ tabela derivada dentro da PRD). O novo `trace-backlog.sh` é dono das colunas de máquina (Spec, Status) do backlog; preserva as colunas humanas (Fatia/Demo/RFs/Release) e a ordem das linhas; casa `specs/###-<slug>` ⇔ slug por sufixo; deriva status do `tasks.md`. Distribuição via `assets/` + `sync-assets.sh` (mapa em `asset-map.sh`); auto-teste com fixtures no `eval.sh` (rodado no CI). Skills editadas em prosa; docs atualizados.

**Tech Stack:** Bash + awk (POSIX-ish, `set -u`, sem `set -e`), fixtures em `scripts/fixtures/`, harness de teste no estilo `test-trace-prd.sh`.

---

## Setup (antes da Task 1)

- [ ] **Criar a branch de trabalho**

Estamos em `main`. Crie uma branch antes de qualquer commit:

Run: `git switch -c feat/backlog-fatias`
Expected: `Switched to a new branch 'feat/backlog-fatias'`

---

## Convenções do repositório (leia uma vez)

- **Fronteira do-quê/como:** o backlog carrega *o-quê* (slug, demo, RFs) — **nunca stack**. O slug é kebab-case, curto, estável.
- **Gates aconselham:** divergências viram avisos; o git é o desfazer; `--check` é read-only para CI/Fases 4.
- **Contrato de exit dos reconciliadores:** `0` limpo · `1` drift/avisos · `2` erro de uso/ambiente.
- **Distribuição:** o canônico vive em `assets/` ou `scripts/`; `scripts/asset-map.sh` mapeia canônico → skills que o consomem; `scripts/sync-assets.sh` copia para `skills/<skill>/references/<basename>`; `scripts/check-assets.sh` falha se algum `references/` divergir. **Nunca edite `skills/*/references/` à mão** — são regenerados pelo sync.
- **Runner de testes:** `scripts/eval.sh` roda todos os auto-testes; o CI (`.github/workflows/check-assets.yml`) chama `./scripts/check-assets.sh` e `./scripts/eval.sh`. Adicionar um teste ao `eval.sh` já o coloca no CI — **não é preciso editar o YAML**.

---

## File Structure

Arquivos novos:
- `assets/templates/backlog.md` — template canônico do backlog (tabela canônica + nota de dono único).
- `scripts/trace-backlog.sh` — reconciliador do backlog (casamento por sufixo, status por `tasks.md`, avisos, `--check`).
- `scripts/test-trace-backlog.sh` — auto-teste contra fixtures.
- `scripts/fixtures/backlog/` — fixtures (dirty, clean, collision, bootstrap, no-table).

Arquivos modificados:
- `scripts/asset-map.sh` — 2 entradas novas.
- `scripts/eval.sh` — registra o teste `backlog`.
- `skills/zion-prd-decompose/SKILL.md` — cunha slug; semeia `docs/backlog.md`; `--epico` preserva `●`.
- `skills/zion-prd-specify-prompt/SKILL.md` — resolve fatia contra o backlog; nome-da-feature = slug; RFs da fatia.
- `skills/zion-prd-trace/SKILL.md` — roda os dois reconciliadores; ecoa quadro de fatias; ritual de fim de fatia.
- `assets/quality-rules.md` — `#anatomia-specify` (slug) + critério do decompose (backlog por máquina).
- `assets/process-context.md` — backlog no item 4 da sequência.
- `docs/guia-prd-para-spec-kit.md`, `docs/como-usar.md`, `README.md` — backlog no mapa/estágios.
- `skills/*/references/` — **regenerados pelo sync** (Tasks 4 e 8), nunca editados à mão.

---

## Task 1: Template `assets/templates/backlog.md`

**Files:**
- Create: `assets/templates/backlog.md`

- [ ] **Step 1: Criar o template**

Escreva exatamente este conteúdo (linhas de dados com padding de espaço único — é o formato que o reconciliador reemite, garantindo bootstrap idempotente):

```markdown
> Backlog de fatias verticais — a fila de trabalho do harness. Uma linha por fatia; **a ordem das
> linhas é a fila de prioridade** (o walking skeleton na frente). Semeado por `/zion-prd-decompose`
> a partir deste template.
>
> **Colunas de máquina (artefato derivado)** — **Spec** e **Status** são recomputadas por
> `/zion-prd-trace` (`scripts/trace-backlog.sh`), casando `specs/###-<slug>` ⇔ slug por sufixo.
> **Não edite Spec/Status à mão.** As colunas humanas (Fatia/Demo/RFs/Release) você preenche e o
> script preserva. A **primeira tabela** deste arquivo é a canônica (dono do script); todo o resto
> (notas, story map, texto livre) é preservado intacto.

| Fatia (slug) | Demo (1 frase) | RFs | Release | Spec | Status |
|--------------|----------------|-----|---------|------|--------|
| walking-skeleton | _(a demo ponta-a-ponta mínima que prova o pipeline inteiro)_ | RF-xx | R0 | — | ☐ pendente |
| fatia-exemplo | _(o que o usuário faz/vê ao final desta fatia — o teste INVEST)_ | RF-xx, RF-yy | R1 | — | ☐ pendente |

Legenda de status: ☐ pendente · ◐ em spec · ● implementada.
```

- [ ] **Step 2: Verificar o template**

Run: `head -1 assets/templates/backlog.md && grep -c '☐ pendente' assets/templates/backlog.md`
Expected: primeira linha começa com `> Backlog de fatias` e a contagem é `3` (2 linhas + legenda).

- [ ] **Step 3: Commit**

```bash
git add assets/templates/backlog.md
git commit -m "feat(backlog): template do backlog de fatias"
```

---

## Task 2: Fixtures `scripts/fixtures/backlog/`

Fixtures que o auto-teste da Task 3 consome. Cobrem: bootstrap, casamento por sufixo (+ substring que **não** casa), status ●/◐/☐, divergência de escopo, slug duplicado, spec órfã, colisão de casamento, `--check`, e backlog sem tabela canônica.

**Files:**
- Create: `scripts/fixtures/backlog/backlog.md` (dirty)
- Create: `scripts/fixtures/backlog/specs/003-preview-ao-vivo/{spec.md,tasks.md}`
- Create: `scripts/fixtures/backlog/specs/004-erros-sintaxe/{spec.md,tasks.md}`
- Create: `scripts/fixtures/backlog/specs/005-escopo-divergente/{spec.md,tasks.md}`
- Create: `scripts/fixtures/backlog/specs/006-orfa/{spec.md,tasks.md}`
- Create: `scripts/fixtures/backlog/clean/backlog.md`
- Create: `scripts/fixtures/backlog/clean/specs/001-walking-skeleton/{spec.md,tasks.md}`
- Create: `scripts/fixtures/backlog/collision/backlog.md`
- Create: `scripts/fixtures/backlog/collision/specs/001-preview-ao-vivo/{spec.md,tasks.md}`
- Create: `scripts/fixtures/backlog/collision/specs/002-preview-ao-vivo/{spec.md,tasks.md}`
- Create: `scripts/fixtures/backlog/bootstrap.md`
- Create: `scripts/fixtures/backlog/no-table.md`

- [ ] **Step 1: Criar `scripts/fixtures/backlog/backlog.md`** (dirty — várias situações + tabela secundária fora da canônica)

```markdown
# Backlog de fatias — fixture

> Nota preservada acima da tabela canônica.

| Fatia (slug) | Demo (1 frase) | RFs | Release | Spec | Status |
|--------------|----------------|-----|---------|------|--------|
| preview-ao-vivo | Digitar mermaid, ver prévia, recarregar e continuar | RF-01, RF-05 | R0 | — | ☐ pendente |
| erros-sintaxe | Erro de sintaxe apontado sem perder a prévia | RF-02 | R1 | — | ☐ pendente |
| exportar-svg | Exportar o diagrama como SVG | RF-07 | R2 | — | ☐ pendente |
| escopo-divergente | Fatia cuja spec cobre RF diferente | RF-08 | R2 | — | ☐ pendente |
| vivo | Slug que é sufixo de outro (não casa por substring) | RF-10 | R3 | — | ☐ pendente |
| preview-ao-vivo | Linha duplicada — deve ser ignorada | RF-01 | R0 | — | ☐ pendente |

## Story map (fora da tabela canônica)

| Passo | Descrição |
|-------|-----------|
| 1 | tabela secundária que deve sobreviver |
```

- [ ] **Step 2: Criar as specs da fixture dirty**

`scripts/fixtures/backlog/specs/003-preview-ao-vivo/spec.md`:
```markdown
# Spec 003 — Preview ao vivo
**RF cobertos:** RF-01, RF-05
```
`scripts/fixtures/backlog/specs/003-preview-ao-vivo/tasks.md`:
```markdown
# Tarefas
- [x] montar editor
- [x] ligar prévia
```
`scripts/fixtures/backlog/specs/004-erros-sintaxe/spec.md`:
```markdown
# Spec 004 — Erros de sintaxe
**RF cobertos:** RF-02
```
`scripts/fixtures/backlog/specs/004-erros-sintaxe/tasks.md`:
```markdown
# Tarefas
- [x] detectar erro
- [ ] apontar linha
```
`scripts/fixtures/backlog/specs/005-escopo-divergente/spec.md` (declara RF-09; o backlog diz RF-08 → divergência):
```markdown
# Spec 005 — Escopo divergente
**RF cobertos:** RF-09
```
`scripts/fixtures/backlog/specs/005-escopo-divergente/tasks.md`:
```markdown
# Tarefas
- [x] algo
```
`scripts/fixtures/backlog/specs/006-orfa/spec.md` (nenhum slug casa "orfa" → spec órfã):
```markdown
# Spec 006 — Órfã
**RF cobertos:** RF-20
```
`scripts/fixtures/backlog/specs/006-orfa/tasks.md`:
```markdown
# Tarefas
- [x] algo
```

- [ ] **Step 3: Criar a fixture `clean/`** (tudo já reconciliado → `--check` diz "em dia")

`scripts/fixtures/backlog/clean/backlog.md`:
```markdown
# Backlog — clean

| Fatia (slug) | Demo (1 frase) | RFs | Release | Spec | Status |
|--------------|----------------|-----|---------|------|--------|
| walking-skeleton | Pipeline mínimo ponta-a-ponta | RF-01 | R0 | `specs/001-walking-skeleton` | ● implementada |

Legenda de status: ☐ pendente · ◐ em spec · ● implementada.
```
`scripts/fixtures/backlog/clean/specs/001-walking-skeleton/spec.md`:
```markdown
# Spec 001 — Walking skeleton
**RF cobertos:** RF-01
```
`scripts/fixtures/backlog/clean/specs/001-walking-skeleton/tasks.md`:
```markdown
# Tarefas
- [x] tudo
```

- [ ] **Step 4: Criar a fixture `collision/`** (dois diretórios casam o mesmo slug → 001 vence)

`scripts/fixtures/backlog/collision/backlog.md`:
```markdown
# Backlog — collision

| Fatia (slug) | Demo (1 frase) | RFs | Release | Spec | Status |
|--------------|----------------|-----|---------|------|--------|
| preview-ao-vivo | Fatia com dois diretórios casando | RF-01 | R0 | — | ☐ pendente |
```
`scripts/fixtures/backlog/collision/specs/001-preview-ao-vivo/spec.md`:
```markdown
# Spec 001
**RF cobertos:** RF-01
```
`scripts/fixtures/backlog/collision/specs/001-preview-ao-vivo/tasks.md`:
```markdown
# Tarefas
- [x] algo
```
`scripts/fixtures/backlog/collision/specs/002-preview-ao-vivo/spec.md`:
```markdown
# Spec 002
**RF cobertos:** RF-01
```
`scripts/fixtures/backlog/collision/specs/002-preview-ao-vivo/tasks.md`:
```markdown
# Tarefas
- [x] algo
```

- [ ] **Step 5: Criar `bootstrap.md` e `no-table.md`**

`scripts/fixtures/backlog/bootstrap.md` (colunas de máquina já em placeholder → bootstrap não gera drift):
```markdown
# Backlog — bootstrap

| Fatia (slug) | Demo (1 frase) | RFs | Release | Spec | Status |
|--------------|----------------|-----|---------|------|--------|
| walking-skeleton | Pipeline mínimo | RF-01 | R0 | — | ☐ pendente |
```
`scripts/fixtures/backlog/no-table.md` (sem tabela canônica → exit 2):
```markdown
# Backlog sem tabela

Este arquivo não tem tabela canônica de fatias — só prosa.
```

- [ ] **Step 6: Verificar a árvore de fixtures**

Run: `find scripts/fixtures/backlog -type f | sort`
Expected: lista com os 16 arquivos acima (dirty backlog + 4 specs×2, clean backlog + 1 spec×2, collision backlog + 2 specs×2, bootstrap.md, no-table.md).

(Sem commit aqui — as fixtures são commitadas junto do script na Task 3.)

---

## Task 3: `scripts/trace-backlog.sh` + auto-teste (TDD)

**Files:**
- Create: `scripts/trace-backlog.sh`
- Test: `scripts/test-trace-backlog.sh`

- [ ] **Step 1: Escrever o auto-teste que falha**

Crie `scripts/test-trace-backlog.sh` com este conteúdo (mesmo estilo de `scripts/test-trace-prd.sh`):

```bash
#!/usr/bin/env bash
# Auto-teste do trace-backlog.sh contra fixtures. Camada mecânica (R7).
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
TRACE="scripts/trace-backlog.sh"
FIX="scripts/fixtures/backlog"
fail=0

assert_exit() {  # desc  esperado  veio
  if [ "$2" != "$3" ]; then echo "FALHOU: $1 (exit esperado $2, veio $3)"; fail=1
  else echo "ok: $1"; fi
}
assert_contains() {  # desc  agulha  palheiro
  if printf '%s' "$3" | grep -qi -- "$2"; then echo "ok: $1"
  else echo "FALHOU: $1 (não achou: $2)"; fail=1; fi
}
assert_file_re() {  # desc  arquivo  regex-estendida
  if grep -Eq -- "$3" "$2"; then echo "ok: $1"
  else echo "FALHOU: $1 (regex não casou: $3)"; fail=1; fi
}
fresh() {  # copia a fixture $1 para um temp e ecoa o caminho
  local t; t="$(mktemp)"; cp "$1" "$t"; printf '%s' "$t"
}

# --- bootstrap: sem specs → Spec —, tudo ☐, exit 0 ---
bl="$(fresh "$FIX/bootstrap.md")"
out="$(bash "$TRACE" "$bl" "$FIX/nao-existe")"; rc=$?
assert_exit "bootstrap sai 0" 0 "$rc"
assert_file_re "bootstrap: fatia vira ☐ pendente" "$bl" 'walking-skeleton .*\| — \| ☐ pendente'
rm -f "$bl"

# erro de uso: backlog inexistente → exit 2
out="$(bash "$TRACE" nao/existe.md "$FIX/specs" 2>&1)"; rc=$?
assert_exit "backlog inexistente sai 2" 2 "$rc"

# backlog sem tabela canônica → exit 2 com mensagem acionável
out="$(bash "$TRACE" "$FIX/no-table.md" "$FIX/specs" 2>&1)"; rc=$?
assert_exit "sem tabela canônica sai 2" 2 "$rc"
assert_contains "sem tabela: mensagem aponta o template" "assets/templates/backlog.md" "$out"

# --- casamento por sufixo + status + substring NÃO casa ---
bl="$(fresh "$FIX/backlog.md")"
bash "$TRACE" "$bl" "$FIX/specs" >/dev/null 2>&1
assert_file_re "casa por sufixo → ● implementada" "$bl" 'preview-ao-vivo .*specs/003-preview-ao-vivo.*● implementada'
assert_file_re "tasks aberto → ◐ em spec"          "$bl" 'erros-sintaxe .*specs/004-erros-sintaxe.*◐ em spec'
assert_file_re "sem spec → ☐ pendente"             "$bl" 'exportar-svg .*\| — \| ☐ pendente'
assert_file_re "substring não casa (vivo)"         "$bl" 'vivo .*\| — \| ☐ pendente'
# idempotência
cp "$bl" "$bl.bak"; bash "$TRACE" "$bl" "$FIX/specs" >/dev/null 2>&1
if diff -q "$bl" "$bl.bak" >/dev/null 2>&1; then echo "ok: reconciliação idempotente"
else echo "FALHOU: reconciliação não é idempotente"; fail=1; fi
rm -f "$bl" "$bl.bak"

# --- avisos + exit 1 + quadro ---
bl="$(fresh "$FIX/backlog.md")"
out="$(bash "$TRACE" "$bl" "$FIX/specs")"; rc=$?
assert_exit "modo padrão com avisos sai 1" 1 "$rc"
assert_contains "aviso divergência de escopo" "Divergência de escopo" "$out"
assert_contains "aviso slug duplicado"        "Slug duplicado" "$out"
assert_contains "aviso spec órfã"             "Spec órfã" "$out"
assert_contains "aviso fatia sem spec"        "Fatia sem spec" "$out"
assert_contains "quadro de fatias"            "Quadro de fatias" "$out"
rm -f "$bl"

# --- preservação: colunas humanas, ordem das linhas, texto fora da tabela ---
bl="$(fresh "$FIX/backlog.md")"
bash "$TRACE" "$bl" "$FIX/specs" >/dev/null 2>&1
assert_file_re "demo humana preservada"          "$bl" 'Digitar mermaid, ver prévia'
assert_file_re "ordem preservada (1ª linha)"     "$bl" '^\| preview-ao-vivo '
assert_file_re "texto fora da tabela preservado" "$bl" 'tabela secundária que deve sobreviver'
rm -f "$bl"

# --- colisão de casamento: 001 (menor prefixo) vence ---
bl="$(fresh "$FIX/collision/backlog.md")"
out="$(bash "$TRACE" "$bl" "$FIX/collision/specs")"; rc=$?
assert_contains "aviso colisão de casamento" "Colisão de casamento" "$out"
assert_file_re "colisão: menor prefixo (001) vence" "$bl" 'preview-ao-vivo .*specs/001-preview-ao-vivo'
rm -f "$bl"

# --- --check: drift sai 1 e NÃO escreve ---
bl="$(fresh "$FIX/backlog.md")"; cp "$bl" "$bl.bak"
out="$(bash "$TRACE" "$bl" "$FIX/specs" --check)"; rc=$?
assert_exit "--check com drift sai 1" 1 "$rc"
if diff -q "$bl" "$bl.bak" >/dev/null 2>&1; then echo "ok: --check não escreve"
else echo "FALHOU: --check escreveu no arquivo"; fail=1; fi
rm -f "$bl" "$bl.bak"

# --- clean: reconcilia sem avisos (exit 0) e --check diz "em dia" (exit 0) ---
bl="$(fresh "$FIX/clean/backlog.md")"
out="$(bash "$TRACE" "$bl" "$FIX/clean/specs")"; rc=$?
assert_exit "clean reconcilia sem avisos sai 0" 0 "$rc"
out="$(bash "$TRACE" "$bl" "$FIX/clean/specs" --check)"; rc=$?
assert_exit "clean --check em dia sai 0" 0 "$rc"
assert_contains "clean --check diz em dia" "em dia" "$out"
rm -f "$bl"

if [ "$fail" -eq 0 ]; then echo "test-trace-backlog: tudo verde"; else echo "test-trace-backlog: FALHOU"; exit 1; fi
```

- [ ] **Step 2: Rodar o teste para confirmar que falha**

Run: `bash scripts/test-trace-backlog.sh; echo "rc=$?"`
Expected: falha — o script `scripts/trace-backlog.sh` ainda não existe, então cada caso reporta `FALHOU` e o exit final é `rc=1`.

- [ ] **Step 3: Escrever `scripts/trace-backlog.sh`**

Crie `scripts/trace-backlog.sh` com exatamente este conteúdo (validado contra as fixtures da Task 2):

```bash
#!/usr/bin/env bash
# trace-backlog.sh — reconciliador do backlog de fatias (docs/backlog.md).
# Espelho do trace-prd.sh no grão da FATIA. Preserva as colunas humanas
# (Fatia/Demo/RFs/Release) e a ordem das linhas; recomputa as colunas de
# máquina (Spec, Status) casando specs/###-<slug> ⇔ slug por sufixo.
# ESCREVE (git é o desfazer); --check é read-only.
#
# Uso:
#   trace-backlog.sh <backlog-file> <specs-dir> [--check]
#     <specs-dir> ausente/vazio → bootstrap (Spec —, tudo ☐).
#     --check → não grava; reporta drift/avisos e sai 1.
#
# Exit: 0 (limpo) · 1 (drift/avisos) · 2 (erro de uso/ambiente).
set -u

usage() { echo "uso: trace-backlog.sh <backlog-file> <specs-dir> [--check]" >&2; exit 2; }

BACKLOG=""; SPECS_DIR=""; MODE_CHECK=0
for a in "$@"; do
  case "$a" in
    --check) MODE_CHECK=1 ;;
    -*) usage ;;
    *) if [ -z "$BACKLOG" ]; then BACKLOG="$a"
       elif [ -z "$SPECS_DIR" ]; then SPECS_DIR="$a"
       else usage; fi ;;
  esac
done
[ -n "$BACKLOG" ] || usage
[ -f "$BACKLOG" ] || { echo "trace-backlog: arquivo não encontrado: $BACKLOG" >&2; exit 2; }

TAB="$(printf '\t')"
ROWS=""; NEWCOLS=""; SPECDIRS=""
cleanup() { rm -f "$ROWS" "$NEWCOLS" "$SPECDIRS" 2>/dev/null; }
trap cleanup EXIT

# --- Lê a PRIMEIRA tabela do arquivo (a canônica). Emite uma linha por fatia:
#     slug \t demo \t rfs \t release \t spec-antiga \t status-antigo.
#     Só emite se o cabeçalho tiver as 6 colunas esperadas. ---
parse_table() {
  awk '
    function trim(s){ gsub(/^[[:space:]]+|[[:space:]]+$/,"",s); return s }
    function lc(s){ return tolower(s) }
    done { next }
    /^[[:space:]]*\|/ {
      line=$0; sub(/^[[:space:]]*\|/,"",line); sub(/\|[[:space:]]*$/,"",line)
      nc=split(line, c, /\|/)
      for(i=1;i<=nc;i++) c[i]=trim(c[i])
      if (!intab) {
        for(i=1;i<=nc;i++){
          h=lc(c[i])
          if      (index(h,"fatia"))   scol=i
          else if (index(h,"demo"))    dcol=i
          else if (index(h,"rfs"))     rcol=i
          else if (index(h,"release")) relcol=i
          else if (index(h,"spec"))    spcol=i
          else if (index(h,"status"))  stcol=i
        }
        ok = (scol && dcol && rcol && relcol && spcol && stcol)
        intab=1; next
      }
      if (c[1] ~ /^[-:]+$/) next
      if (ok) printf "%s\t%s\t%s\t%s\t%s\t%s\n", c[scol], c[dcol], c[rcol], c[relcol], c[spcol], c[stcol]
      next
    }
    intab { done=1 }
  ' "$1"
}

# --- Lista os diretórios (basename) sob <specs-dir>. Bootstrap → vazio. ---
scan_specs_dirs() {
  : > "$SPECDIRS"
  [ -n "$SPECS_DIR" ] && [ -d "$SPECS_DIR" ] || return 0
  local d
  for d in "$SPECS_DIR"/*/; do
    [ -d "$d" ] || continue
    basename "$d" >> "$SPECDIRS"
  done
}

# --- Diretório casado para um slug: D==slug (prefixo -1) ou D=~^[0-9]+-slug$.
#     Menor prefixo numérico vence. Define MATCH_DIR e MATCH_COUNT (sem subshell). ---
match_dir_for_slug() {  # $1 slug
  local slug="$1" d num bestnum=""
  MATCH_DIR=""; MATCH_COUNT=0
  while read -r d; do
    [ -n "$d" ] || continue
    if [ "$d" = "$slug" ]; then
      num=-1
    elif printf '%s' "$d" | grep -qE "^[0-9]+-$slug$"; then
      num="${d%%-*}"; num=$((10#$num))
    else
      continue
    fi
    MATCH_COUNT=$((MATCH_COUNT+1))
    if [ -z "$MATCH_DIR" ] || [ "$num" -lt "$bestnum" ]; then MATCH_DIR="$d"; bestnum="$num"; fi
  done < "$SPECDIRS"
}

# --- Status de UMA spec pelo tasks.md: ausente/com "- [ ]" aberto → spec; senão impl. ---
spec_status() {  # $1 spec-dir
  local tasks="$1/tasks.md"
  [ -f "$tasks" ] || { printf 'spec'; return; }
  if grep -qE '^[[:space:]]*- \[ \]' "$tasks"; then printf 'spec'; return; fi
  printf 'impl'
}

# --- Reescreve a PRIMEIRA tabela in-place: troca só as células Spec/Status
#     das linhas cujo slug está em $NEWCOLS; preserva o resto do arquivo. ---
rewrite_table() {  # imprime o backlog reconciliado no stdout
  awk -v cols="$NEWCOLS" '
    function trim(s){ gsub(/^[[:space:]]+|[[:space:]]+$/,"",s); return s }
    function lc(s){ return tolower(s) }
    BEGIN {
      while ((getline l < cols) > 0) {
        n=split(l, a, "\t"); newspec[a[1]]=a[2]; newstat[a[1]]=a[3]
      }
    }
    tabdone { print; next }
    /^[[:space:]]*\|/ {
      raw=$0
      line=$0; sub(/^[[:space:]]*\|/,"",line); sub(/\|[[:space:]]*$/,"",line)
      nc=split(line, c, /\|/)
      for(i=1;i<=nc;i++) c[i]=trim(c[i])
      if (!intab) {
        for(i=1;i<=nc;i++){
          h=lc(c[i])
          if      (index(h,"fatia"))  scol=i
          else if (index(h,"spec"))   spcol=i
          else if (index(h,"status")) stcol=i
        }
        intab=1; print raw; next
      }
      if (c[1] ~ /^[-:]+$/) { print raw; next }
      slug=c[scol]
      if (slug in newspec) { c[spcol]=newspec[slug]; c[stcol]=newstat[slug] }
      out="|"
      for(i=1;i<=nc;i++) out=out " " c[i] " |"
      print out
      next
    }
    { if (intab) tabdone=1; print }
  ' "$BACKLOG"
}

# --- Orquestração ---
ROWS="$(mktemp)"; NEWCOLS="$(mktemp)"; SPECDIRS="$(mktemp)"
parse_table "$BACKLOG" > "$ROWS"
[ -s "$ROWS" ] || { echo "trace-backlog: $BACKLOG sem tabela canônica de fatias (veja assets/templates/backlog.md)" >&2; exit 2; }

scan_specs_dirs
SPEC_COUNT=$(grep -c . "$SPECDIRS")
: > "$NEWCOLS"

declare -A SEEN USEDDIR
warnings=""; transitions=""
impl=0; inspec=0; pend=0; firstpending=""

while IFS="$TAB" read -r slug demo rfs release oldspec oldstatus; do
  [ -n "$slug" ] || continue
  if [ -n "${SEEN[$slug]:-}" ]; then
    warnings="${warnings}Slug duplicado: \`$slug\` aparece mais de uma vez no backlog (a primeira linha vence; as demais são ignoradas).
"
    continue
  fi
  SEEN[$slug]=1

  match_dir_for_slug "$slug"; dir="$MATCH_DIR"; matched="$MATCH_COUNT"
  if [ -n "$dir" ]; then
    USEDDIR[$dir]=1
    [ "$matched" -gt 1 ] && warnings="${warnings}Colisão de casamento: mais de um diretório casa \`$slug\`; \`specs/$dir\` (menor prefixo) vence.
"
    st="$(spec_status "$SPECS_DIR/$dir")"
    case "$st" in impl) glyph="● implementada" ;; *) glyph="◐ em spec" ;; esac
    speccell="\`specs/$dir\`"
    decl="$(printf '%s' "$rfs" | grep -oE 'RF-[0-9]+' | sort -u | tr '\n' ' ')"
    covline="$(grep -iE 'RF cobertos:' "$SPECS_DIR/$dir/spec.md" 2>/dev/null | head -1)"
    cov="$(printf '%s' "$covline" | grep -oE 'RF-[0-9]+' | sort -u | tr '\n' ' ')"
    if [ -n "$covline" ] && [ "$decl" != "$cov" ]; then
      warnings="${warnings}Divergência de escopo: \`$slug\` declara [${decl% }] mas specs/$dir cobre [${cov% }] — corrija a spec ou o backlog.
"
    fi
  else
    glyph="☐ pendente"; speccell="—"
    [ "$SPEC_COUNT" -gt 0 ] && warnings="${warnings}Fatia sem spec: \`$slug\` ainda não tem spec (permanece ☐ pendente).
"
  fi

  printf '%s\t%s\t%s\n' "$slug" "$speccell" "$glyph" >> "$NEWCOLS"

  if [ "$(printf '%s' "$oldstatus" | tr -d ' ')" != "$(printf '%s' "$glyph" | tr -d ' ')" ]; then
    transitions="${transitions}  $slug: ${oldstatus:-—} → $glyph
"
  fi

  case "$glyph" in
    "● implementada") impl=$((impl+1)) ;;
    "◐ em spec")      inspec=$((inspec+1)) ;;
    *)                pend=$((pend+1)); [ -z "$firstpending" ] && firstpending="$slug" ;;
  esac
done < "$ROWS"

# spec órfã: diretório que não casou com nenhum slug
if [ "$SPEC_COUNT" -gt 0 ]; then
  while read -r d; do
    [ -n "$d" ] || continue
    [ -n "${USEDDIR[$d]:-}" ] || warnings="${warnings}Spec órfã: \`specs/$d\` não casa com nenhum slug do backlog (registre a fatia ou renomeie).
"
  done < "$SPECDIRS"
fi

wcount=0; [ -n "$warnings" ] && wcount="$(printf '%s' "$warnings" | grep -c .)"

quadro() {
  printf 'Quadro de fatias: ● %s · ◐ %s · ☐ %s' "$impl" "$inspec" "$pend"
  if [ -n "$firstpending" ]; then printf ' · próxima ☐: %s\n' "$firstpending"; else printf '\n'; fi
}

if [ "$MODE_CHECK" = "1" ]; then
  tmp="$(mktemp)"; rewrite_table > "$tmp"; drift=""
  if ! diff -q "$BACKLOG" "$tmp" >/dev/null 2>&1; then
    echo "trace-backlog: drift no backlog (rode sem --check para reconciliar):"
    diff "$BACKLOG" "$tmp" || true
    drift=1
  fi
  rm -f "$tmp"
  [ -n "$warnings" ] && printf '%s' "$warnings"
  quadro
  if [ -n "$drift" ] || [ "$wcount" -gt 0 ]; then echo "trace-backlog: fora de dia"; exit 1; fi
  echo "trace-backlog: em dia"; exit 0
fi

tmp="$(mktemp)"; rewrite_table > "$tmp"; mv "$tmp" "$BACKLOG"

[ -n "$transitions" ] && printf '%s' "$transitions"
[ -n "$warnings" ] && printf '%s' "$warnings"
quadro

updated=0; [ -n "$transitions" ] && updated="$(printf '%s' "$transitions" | grep -c .)"
if [ "$updated" -eq 0 ] && [ "$wcount" -eq 0 ]; then
  echo "trace-backlog: em dia"; exit 0
fi
echo "trace-backlog: $updated linha(s) atualizada(s), $wcount aviso(s)"
[ "$wcount" -gt 0 ] && exit 1 || exit 0
```

> **Nota de contrato (por que "Fatia sem spec" não derruba o exit no bootstrap):** como no `trace-prd.sh`, "sem spec" é um aviso *informativo*. No bootstrap (`SPEC_COUNT=0`, nenhuma spec ainda) ele é suprimido, então semear o backlog sai `0`. Assim que existe ≥1 spec, fatias pendentes viram aviso e o modo padrão sai `1` — o mesmo padrão do `RF descoberto` do `trace-prd`. No modo padrão o exit é `1` sse houver avisos; no `--check` o exit é `1` se houver drift **ou** avisos.

- [ ] **Step 4: Tornar o script executável**

Run: `chmod +x scripts/trace-backlog.sh`
Expected: sem saída.

- [ ] **Step 5: Rodar o teste para confirmar que passa**

Run: `bash scripts/test-trace-backlog.sh; echo "rc=$?"`
Expected: todas as linhas `ok:`, terminando com `test-trace-backlog: tudo verde` e `rc=0`.

- [ ] **Step 6: Commit** (script + teste + fixtures da Task 2)

```bash
git add scripts/trace-backlog.sh scripts/test-trace-backlog.sh scripts/fixtures/backlog
git commit -m "feat(trace-backlog): reconciliador do backlog de fatias + auto-teste com fixtures"
```

---

## Task 4: Distribuição (asset-map + sync) e wiring do CI

**Files:**
- Modify: `scripts/asset-map.sh`
- Modify: `scripts/eval.sh`
- Generated: `skills/zion-prd-trace/references/trace-backlog.sh`, `skills/zion-prd-decompose/references/{trace-backlog.sh,backlog.md}`

- [ ] **Step 1: Adicionar as entradas no `asset-map.sh`**

Em `scripts/asset-map.sh`, dentro do array `ASSET_MAP=( ... )`, após a linha `"scripts/trace-prd.sh                   zion-prd-trace zion-prd-decompose"`, adicione:

```bash
  "scripts/trace-backlog.sh               zion-prd-trace zion-prd-decompose"
  "assets/templates/backlog.md            zion-prd-decompose"
```

- [ ] **Step 2: Registrar o teste no `eval.sh`**

Em `scripts/eval.sh`:

Troque o bloco `declare -A TESTS`:
```bash
declare -A TESTS=(
  [prd]="scripts/test-check-prd.sh"
  [adr]="scripts/test-check-adr.sh"
  [trace]="scripts/test-trace-prd.sh"
  [contract]="scripts/test-check-superpowers-contract.sh"
)
ORDER=(prd adr trace contract)
```
por:
```bash
declare -A TESTS=(
  [prd]="scripts/test-check-prd.sh"
  [adr]="scripts/test-check-adr.sh"
  [trace]="scripts/test-trace-prd.sh"
  [backlog]="scripts/test-trace-backlog.sh"
  [contract]="scripts/test-check-superpowers-contract.sh"
)
ORDER=(prd adr trace backlog contract)
```
E no `case "$sel"`, troque `prd|adr|trace|contract)` por `prd|adr|trace|backlog|contract)` e a mensagem de uso `"uso: eval.sh [prd|adr|trace|contract]"` por `"uso: eval.sh [prd|adr|trace|backlog|contract]"`.

- [ ] **Step 3: Sincronizar os assets para os `references/`**

Run: `bash scripts/sync-assets.sh`
Expected: `sync-assets: ok`. Cria `skills/zion-prd-trace/references/trace-backlog.sh`, `skills/zion-prd-decompose/references/trace-backlog.sh` e `skills/zion-prd-decompose/references/backlog.md`.

- [ ] **Step 4: Verificar sem drift e o teste no runner**

Run: `bash scripts/check-assets.sh && bash scripts/eval.sh backlog`
Expected: `check-assets: sem drift`, depois `=== eval: backlog ===` com `test-trace-backlog: tudo verde`.

- [ ] **Step 5: Commit**

```bash
git add scripts/asset-map.sh scripts/eval.sh skills/zion-prd-trace/references/trace-backlog.sh skills/zion-prd-decompose/references/trace-backlog.sh skills/zion-prd-decompose/references/backlog.md
git commit -m "build(backlog): distribui trace-backlog.sh + template e registra no eval"
```

---

## Task 5: `skills/zion-prd-decompose/SKILL.md` — cunha slug e semeia o backlog

**Files:**
- Modify: `skills/zion-prd-decompose/SKILL.md`

- [ ] **Step 1: Cunhar o slug na Fase 2/3**

Localize (linhas ~31-34) e troque:
```
Invoque `superpowers:brainstorming` no mesmo turno para: (1) agrupar os `RF-xx` em épicos;
(2) montar o story map (backbone da jornada); (3) cortar linhas de release R0..Rn; (4) fatiar cada
épico em fatias verticais.
```
por:
```
Invoque `superpowers:brainstorming` no mesmo turno para: (1) agrupar os `RF-xx` em épicos;
(2) montar o story map (backbone da jornada); (3) cortar linhas de release R0..Rn; (4) fatiar cada
épico em fatias verticais. Para cada fatia, **cunhe um slug kebab-case** (curto, estável — ele vira o
nome da spec e da branch no Spec Kit), junto da **demo de 1 frase** (o teste INVEST) e dos **RF-xx
cobertos**. Esses três campos são as colunas humanas do backlog (Fase 4).
```

- [ ] **Step 2: `--epico` reconcilia os dois artefatos**

No parágrafo do modo parcial (linhas ~35-40), troque:
```
mande rodar `/zion-prd-trace` (dono único da tabela), que reconcilia sem duplicar.
```
por:
```
mande rodar `/zion-prd-trace` (dono único da §12 **e** do backlog), que reconcilia sem duplicar.
Fatias já implementadas (`●`) permanecem **intocáveis** no re-fatiamento.
```

- [ ] **Step 3: Semear `docs/backlog.md` na Fase 4**

Localize o bullet do `trace-prd.sh` na Fase 4. Após a linha:
```
  brainstorming após o bootstrap. Reconciliar após cada fatia é trabalho de `/zion-prd-trace`.
```
adicione um bullet novo:
```
- Semeie o **backlog de fatias** `docs/backlog.md` a partir de `references/backlog.md` (template),
  preenchendo as **colunas humanas** (Fatia/slug, Demo, RFs, Release) com o resultado do fatiamento; então
  reconcilie as colunas de máquina por bootstrap:

      bash references/trace-backlog.sh docs/backlog.md specs

  Ainda não há specs → Spec `—`, tudo ☐ pendente; a **ordem das linhas é a fila de prioridade**.
  `trace-backlog.sh` é o **dono único** das colunas Spec/Status. **Backlog já existente → não
  sobrescreva:** atualize as linhas humanas por conversa e deixe a reconciliação com o script
  (idempotência, como nos demais estágios).
```

- [ ] **Step 4: Mencionar o backlog na Saída**

Na seção `## Saída` (linhas ~58-61), troque:
```
Lista de épicos, story map, backlog de **fatias verticais** priorizadas com linhas de release, e a
tabela de rastreabilidade **semeada por `trace-prd.sh`** dentro da PRD.
```
por:
```
Lista de épicos, story map, backlog de **fatias verticais** priorizadas com linhas de release, o
arquivo **`docs/backlog.md`** semeado por `trace-backlog.sh` (slug/demo/RFs por fatia; Spec/Status por
máquina), e a tabela de rastreabilidade **semeada por `trace-prd.sh`** dentro da PRD.
```

- [ ] **Step 5: Verificar**

Run: `grep -c 'trace-backlog.sh\|slug kebab-case\|docs/backlog.md' skills/zion-prd-decompose/SKILL.md`
Expected: `≥ 3`.

- [ ] **Step 6: Commit**

```bash
git add skills/zion-prd-decompose/SKILL.md
git commit -m "feat(zion-prd-decompose): cunha slug e semeia docs/backlog.md por máquina"
```

---

## Task 6: `skills/zion-prd-specify-prompt/SKILL.md` — carrega o slug até o Spec Kit

**Files:**
- Modify: `skills/zion-prd-specify-prompt/SKILL.md`

- [ ] **Step 1: Fase 0 aponta o backlog**

Troque (linhas ~16-18):
```
Deve existir um backlog de fatias verticais (saída de `/zion-prd-decompose`). O usuário aponta **qual**
fatia. Se não houver backlog, avise ("recomendo `/zion-prd-decompose` antes") e pergunte se segue.
```
por:
```
Deve existir o **backlog** `docs/backlog.md` (saída de `/zion-prd-decompose`). O usuário aponta **qual**
fatia. Se não houver backlog, avise ("recomendo `/zion-prd-decompose` antes") e pergunte se segue.
```

- [ ] **Step 2: Fase 1 resolve a fatia contra o backlog**

No fim da seção `## Fase 1` (após "Não bloqueie.", linha ~24), adicione um parágrafo:
```
**Resolva a fatia contra o backlog** `docs/backlog.md`: o usuário pode apontá-la em prosa ("a fatia do
preview"); localize a linha na tabela canônica e confirme **slug / demo / RFs**. Fatia fora do backlog →
avise ("registre no backlog via `/zion-prd-decompose` ou adicione a linha") e pergunte se segue — não
bloqueie.
```

- [ ] **Step 3: Fase 2/3 instrui slug + RFs da fatia**

Na lista de bullets da Fase 2/3, após o bullet que começa com "- Pedir explicitamente que o `spec.md` inclua uma linha rotulada", adicione dois bullets:
```
- **Nome da feature = slug:** peça explicitamente que a feature/branch use `<slug>` como nome curto — a
  spec nasce `specs/###-<slug>`, fechando o elo fatia↔spec por construção (o `trace-backlog.sh` casa por
  sufixo).
- Preencha a linha **`**RF cobertos:**`** com **os RF-xx da linha da fatia** no backlog — fechando o elo
  de escopo dos dois lados. Como hoje, instruímos via prompt e parseamos o que aterrissa: se o Spec Kit
  batizar diferente do slug, o `trace-backlog.sh` acusa **spec órfã** + **fatia sem spec** e o humano
  renomeia.
```

- [ ] **Step 4: Verificar**

Run: `grep -cE 'docs/backlog.md|Nome da feature = slug|specs/###-<slug>' skills/zion-prd-specify-prompt/SKILL.md`
Expected: `≥ 2`.

- [ ] **Step 5: Commit**

```bash
git add skills/zion-prd-specify-prompt/SKILL.md
git commit -m "feat(zion-prd-specify-prompt): resolve fatia no backlog e carrega o slug"
```

---

## Task 7: `skills/zion-prd-trace/SKILL.md` — reconcilia os dois; ritual de fim de fatia

**Files:**
- Modify: `skills/zion-prd-trace/SKILL.md`

- [ ] **Step 1: Atualizar a `description` do frontmatter**

Troque a linha `description:` (linha 3) por:
```
description: Reconcilia a rastreabilidade da PRD (§12) e o backlog de fatias (docs/backlog.md) a partir das specs/*/spec.md — RF↔spec, fatia↔spec e status ☐/◐/● derivados por máquina. É o ritual de fim de fatia. Use para "atualizar a rastreabilidade", "reconciliar a tabela/o backlog" ou depois de fatiar/implementar uma fatia. Rodável a qualquer momento.
```

- [ ] **Step 2: Fase 0 aconselha sobre o backlog**

No fim da `## Fase 0` (após "pergunte se segue. Não bloqueie.", linha ~20), adicione:
```
Aconselhe também sobre `docs/backlog.md` ausente ("recomendo `/zion-prd-decompose` antes"). Backlog
ausente **não** impede a reconciliação da §12 — e PRD ausente não impede a do backlog.
```

- [ ] **Step 3: Fase 2/3 roda os dois reconciliadores**

Após o bloco de comando do `trace-prd.sh` e seu parágrafo (linha ~32, "...O git é o desfazer."), adicione:
```
Rode também o reconciliador do backlog:

    bash references/trace-backlog.sh docs/backlog.md specs

Ele recomputa as colunas de máquina (Spec, Status) do backlog casando `specs/###-<slug>` ⇔ slug por
sufixo, **preserva** as colunas humanas e a ordem das linhas, e imprime as transições de status, os avisos
e o **quadro de fatias**.
```

- [ ] **Step 4: Fase 4 ecoa os avisos do backlog + quadro + ritual**

Na `## Fase 4`, após o bullet "- **RF descoberto** ...", adicione os avisos do backlog:
```
Do lado do backlog, ecoe com o mesmo tom:
- **Fatia sem spec** — a fatia ainda não tem `specs/###-<slug>` (permanece ☐; informativo).
- **Spec órfã** — um diretório `specs/###-nome` que não casa nenhum slug: o slug divergiu (typo) ou a
  spec nasceu fora do backlog → registre a fatia ou renomeie.
- **Divergência de escopo** — os RFs da linha da fatia ≠ a linha `**RF cobertos:**` da spec casada:
  corrija a spec ou o backlog (o humano decide).
- **Slug duplicado / Colisão de casamento** — a primeira linha / o menor prefixo numérico vence, com aviso.

Ecoe o **quadro de fatias** (`● / ◐ / ☐` + a próxima fatia ☐ da fila) — a visibilidade num comando só.
```

- [ ] **Step 5: Documentar o ritual de fim de fatia na Saída**

Na `## Saída` (linhas ~46-48), troque:
```
A seção 12 de `docs/PRD.md` reconciliada + o resumo/avisos ecoados. **Handoff:** commit dos artefatos
(`/git-commit`), e a próxima fatia da fila segue para `/zion-prd-specify-prompt`.
```
por:
```
A seção 12 de `docs/PRD.md` **e** `docs/backlog.md` reconciliados + os resumos/avisos e o quadro de fatias
ecoados. Rodar `/zion-prd-trace` após `/speckit.implement`/`converge` é o **ritual de fim de fatia**.
**Handoff:** commit dos artefatos (`/git-commit`), e a próxima fatia ☐ da fila segue para
`/zion-prd-specify-prompt`.
```

- [ ] **Step 6: Verificar**

Run: `grep -c 'trace-backlog.sh\|quadro de fatias\|ritual de fim de fatia' skills/zion-prd-trace/SKILL.md`
Expected: `≥ 3`.

- [ ] **Step 7: Commit**

```bash
git add skills/zion-prd-trace/SKILL.md
git commit -m "feat(zion-prd-trace): reconcilia backlog + §12 e vira ritual de fim de fatia"
```

---

## Task 8: Assets sincronizados — `quality-rules.md` + `process-context.md`

**Files:**
- Modify: `assets/quality-rules.md`
- Modify: `assets/process-context.md`
- Generated: `skills/*/references/{quality-rules.md,process-context.md}` (via sync)

- [ ] **Step 1: `#anatomia-specify` ganha o slug**

Em `assets/quality-rules.md`, na seção `## Anatomia do prompt do specify {#anatomia-specify}`, após o bullet "- **A linha `**RF cobertos:**`** ..." (que termina em "...não fere a fronteira sem-stack."), adicione:
```
- **O slug como nome da feature** — peça que a feature/branch use o `<slug>` da fatia (do
  `docs/backlog.md`) como nome curto: a spec nasce `specs/###-<slug>`, fechando o elo fatia↔spec por
  construção que o `trace-backlog.sh` casa por sufixo. Declarar o slug é o-quê/rastreabilidade, não stack.
```

- [ ] **Step 2: Critério do decompose menciona o backlog por máquina**

Na seção `## Critérios de conclusão por estágio {#criterios-de-conclusao}`, no item **decompose**, troque:
```
- **decompose**: existe backlog de fatias verticais priorizadas ∧ cada fatia passa no INVEST ∧
  walking skeleton é a fatia zero (R0) ∧ a tabela de rastreabilidade (§12) foi **semeada por
  `trace-prd.sh`** (não à mão) com uma linha por `RF-xx` in-scope. A tabela é um artefato **derivado**,
  reconciliado a qualquer momento por `/zion-prd-trace`; não é mantida à mão.
```
por:
```
- **decompose**: existe backlog de fatias verticais priorizadas ∧ cada fatia passa no INVEST ∧
  walking skeleton é a fatia zero (R0) ∧ a tabela de rastreabilidade (§12) foi **semeada por
  `trace-prd.sh`** (não à mão) com uma linha por `RF-xx` in-scope ∧ o **backlog** `docs/backlog.md` foi
  semeado por `trace-backlog.sh` (colunas humanas — Fatia/slug, Demo, RFs, Release — preenchidas;
  colunas Spec/Status por máquina). Ambos são artefatos **derivados**, reconciliados a qualquer momento
  por `/zion-prd-trace`; não são mantidos à mão.
```

- [ ] **Step 3: `process-context.md` inclui o backlog no item 4**

Em `assets/process-context.md`, no item 4 da sequência, troque:
```
4. **Decomposição** (`/zion-prd-decompose`) — PRD → épicos → story map → fatias verticais validadas
   por INVEST; walking skeleton como fatia zero; tabela de rastreabilidade injetada na PRD.
   **Handoff:** cada fatia priorizada entra no Spec Kit via `/speckit.specify`.
```
por:
```
4. **Decomposição** (`/zion-prd-decompose`) — PRD → épicos → story map → fatias verticais validadas
   por INVEST; walking skeleton como fatia zero; tabela de rastreabilidade injetada na PRD e o backlog
   de fatias `docs/backlog.md` (slug + demo + RFs por fatia; Spec/Status por máquina).
   **Handoff:** cada fatia priorizada entra no Spec Kit via `/speckit.specify`.
```

- [ ] **Step 4: Sincronizar e verificar sem drift**

Run: `bash scripts/sync-assets.sh && bash scripts/check-assets.sh`
Expected: `sync-assets: ok` seguido de `check-assets: sem drift`.

- [ ] **Step 5: Commit** (inclui os `references/` regenerados)

```bash
git add assets/quality-rules.md assets/process-context.md skills/*/references/quality-rules.md skills/*/references/process-context.md
git commit -m "docs(quality-rules): slug no specify e backlog por máquina no critério do decompose"
```

---

## Task 9: Docs de guia — guia, como-usar, README

**Files:**
- Modify: `docs/guia-prd-para-spec-kit.md`
- Modify: `docs/como-usar.md`
- Modify: `README.md`

- [ ] **Step 1: `guia` Passo 4 — backlog como artefato de saída**

Em `docs/guia-prd-para-spec-kit.md`, troque:
```
- **Saídas / artefatos:** lista de épicos, story map, **backlog de fatias verticais** com linhas de
  release, e a **tabela de rastreabilidade semeada por máquina** (`trace-prd.sh` em bootstrap: tudo ☐
  pendente; ver modelo abaixo). Depois, `/zion-prd-trace` a reconcilia a cada fatia.
```
por:
```
- **Saídas / artefatos:** lista de épicos, story map, **backlog de fatias verticais** com linhas de
  release em `docs/backlog.md` (slug/demo/RFs por fatia; Spec/Status semeados por `trace-backlog.sh`), e a
  **tabela de rastreabilidade semeada por máquina** (`trace-prd.sh` em bootstrap: tudo ☐ pendente; ver
  modelo abaixo). Depois, `/zion-prd-trace` reconcilia **os dois** a cada fatia.
```

- [ ] **Step 2: `guia` Passo 5b — o slug vira o nome da spec**

Troque:
```
- **Entradas:** a próxima fatia vertical da fila (Passo 4); `constitution`; `docs/PRD.md`; ADRs.
```
por:
```
- **Entradas:** a próxima fatia vertical da fila (Passo 4, resolvida contra `docs/backlog.md` pela ponte
  `specify`, que instrui o Spec Kit a usar o **slug** da fatia como nome curto → `specs/###-<slug>`);
  `constitution`; `docs/PRD.md`; ADRs.
```

- [ ] **Step 3: `guia` Passo 6 — trace reconcilia os dois + ritual**

Troque o bullet da skill `zion-prd-trace`:
```
  - `zion-prd-trace` (real) — reconcilia a seção 12 da PRD a partir das `specs/*/spec.md` (status
    ☐/◐/● derivado do `tasks.md`); rodável a qualquer momento, tipicamente após cada fatia.
```
por:
```
  - `zion-prd-trace` (real) — reconcilia a seção 12 da PRD **e** o backlog `docs/backlog.md` a partir das
    `specs/*/spec.md` (status ☐/◐/● derivado do `tasks.md`); rodável a qualquer momento. Rodá-lo após
    `/speckit.implement`/`converge` é o **ritual de fim de fatia** — fecha a fatia e ecoa o quadro
    `● / ◐ / ☐` com a próxima da fila.
```

- [ ] **Step 4: `como-usar` mapa de comandos**

Em `docs/como-usar.md`, na tabela `## Mapa rápido dos comandos`, troque a linha do decompose:
```
| `/zion-prd-decompose` | 4 · Decomposição | `docs/PRD.md` (com `RF-xx`) | fatias + tabela na PRD | `superpowers:brainstorming` |
```
por:
```
| `/zion-prd-decompose` | 4 · Decomposição | `docs/PRD.md` (com `RF-xx`) | fatias + `docs/backlog.md` + tabela na PRD | `superpowers:brainstorming` |
```
E a linha do trace:
```
| `/zion-prd-trace` | 6 · Rastreabilidade | `docs/PRD.md` (§6+§12) + `specs/` | seção 12 reconciliada | `scripts/trace-prd.sh` |
```
por:
```
| `/zion-prd-trace` | 6 · Rastreabilidade | `docs/PRD.md` (§6+§12) + `docs/backlog.md` + `specs/` | §12 + backlog reconciliados | `scripts/trace-prd.sh` + `trace-backlog.sh` |
```

- [ ] **Step 5: `como-usar` Estágio 4 — exemplo do backlog**

No `### Estágio 4 — /zion-prd-decompose`, após o bloco de código markdown que mostra a tabela `| RF | Descrição (1 frase) | ...` injetada na §12, adicione:
```

E **semeia o backlog** `docs/backlog.md` (fila de fatias; slug/demo/RFs humanos, Spec/Status por máquina):

```markdown
| Fatia (slug) | Demo (1 frase) | RFs | Release | Spec | Status |
|--------------|----------------|-----|---------|------|--------|
| preview-ao-vivo | Digitar mermaid, ver prévia, recarregar e continuar | RF-01, RF-05 | R0 | — | ☐ pendente |
| erros-sintaxe | Erro de sintaxe apontado sem perder a prévia | RF-02 | R1 | — | ☐ pendente |
```
```

- [ ] **Step 6: `README` — mapa de skills e lista de testes**

Em `README.md`, troque a linha do decompose:
```
| `/zion-prd-decompose` | Épicos, story map, fatias verticais, rastreabilidade |
```
por:
```
| `/zion-prd-decompose` | Épicos, story map, fatias verticais, backlog (`docs/backlog.md`), rastreabilidade |
```
E a linha do trace:
```
| `/zion-prd-trace` | Reconcilia a rastreabilidade (seção 12) a partir das specs |
```
por:
```
| `/zion-prd-trace` | Reconcilia a rastreabilidade (§12) e o backlog de fatias a partir das specs |
```
E a lista de auto-testes:
```
ou quem não rodou o `setup-hooks.sh`) e os auto-testes `test-check-prd.sh`, `test-trace-prd.sh` e
`test-check-adr.sh` dos verificadores. Para checar/sincronizar/testar à mão:
```
por:
```
ou quem não rodou o `setup-hooks.sh`) e os auto-testes `test-check-prd.sh`, `test-trace-prd.sh`,
`test-trace-backlog.sh` e `test-check-adr.sh` dos verificadores. Para checar/sincronizar/testar à mão:
```

- [ ] **Step 7: Verificar**

Run: `grep -l 'docs/backlog.md\|trace-backlog' docs/guia-prd-para-spec-kit.md docs/como-usar.md README.md`
Expected: os três arquivos listados.

- [ ] **Step 8: Commit**

```bash
git add docs/guia-prd-para-spec-kit.md docs/como-usar.md README.md
git commit -m "docs: backlog de fatias no guia, no como-usar e no README"
```

---

## Task 10: Verificação final ponta-a-ponta

**Files:** *(nenhum — só verificação)*

- [ ] **Step 1: Suíte mecânica inteira verde**

Run: `bash scripts/eval.sh`
Expected: cada bloco `=== eval: prd|adr|trace|backlog|contract ===` verde e, no fim, `eval: tudo verde`.

- [ ] **Step 2: Sem drift de assets**

Run: `bash scripts/check-assets.sh`
Expected: `check-assets: sem drift`.

- [ ] **Step 3: Smoke real do ciclo (bootstrap → spec → status)**

Run:
```bash
tmp="$(mktemp -d)"; cp assets/templates/backlog.md "$tmp/backlog.md"
bash scripts/trace-backlog.sh "$tmp/backlog.md" "$tmp/specs"; echo "boot rc=$?"
mkdir -p "$tmp/specs/001-walking-skeleton"
printf '# Spec\n**RF cobertos:** RF-xx\n' > "$tmp/specs/001-walking-skeleton/spec.md"
printf '# Tarefas\n- [x] tudo\n' > "$tmp/specs/001-walking-skeleton/tasks.md"
bash scripts/trace-backlog.sh "$tmp/backlog.md" "$tmp/specs"; echo "recon rc=$?"
grep 'walking-skeleton' "$tmp/backlog.md"; rm -rf "$tmp"
```
Expected: bootstrap `boot rc=0` (fatias ☐, Spec `—`); depois a reconciliação move `walking-skeleton` para `` `specs/001-walking-skeleton` `` / `● implementada` e imprime `Quadro de fatias: ● 1 · ◐ 0 · ☐ 1 · próxima ☐: fatia-exemplo`.

- [ ] **Step 4: Confirmar árvore de commits**

Run: `git log --oneline main..HEAD`
Expected: os commits das Tasks 1–9 na branch `feat/backlog-fatias`.

---

## Self-Review (rodada pelo autor do plano)

**1. Cobertura do spec (design §):**
- §4 template com tabela canônica + colunas humanas/máquina → Task 1. ✓
- §5 reconciliador (interface, casamento por sufixo, fontes por coluna, avisos, contrato de saída) → Task 3 (script validado contra fixtures). ✓
- §6 decompose (slug na Fase 2/3, semeia backlog na Fase 4, `--epico` preserva `●`) → Task 5. ✓
- §7 specify-prompt (resolve fatia, nome=slug, RFs da fatia) → Task 6. ✓
- §8 trace (Fase 0 backlog, roda os dois, quadro, ritual) → Task 7. ✓
- §9 distribuição (asset-map + sync) → Task 4. ✓
- §10 auto-teste + fixtures (todos os casos) → Tasks 2 e 3. ✓
- §11 superfície: quality-rules (`#anatomia-specify` + critério decompose) → Task 8; process-context → Task 8; guia/como-usar/README → Task 9. ✓
- §11 `.github/workflows/check-assets.yml`: **desvio consciente e verificado** — o YAML já roda `./scripts/eval.sh`, então registrar o teste no `eval.sh` (Task 4) já o coloca no CI. Editar o YAML seria redundante; nenhuma mudança lá é necessária.

**2. Placeholders:** nenhum "TODO"/"similar a"/"trate erros" — todo passo traz código ou texto exato, e o script/teste foram executados contra fixtures reais antes de entrar no plano.

**3. Consistência de tipos/nomes:** `trace-backlog.sh <backlog-file> <specs-dir> [--check]`, `MATCH_DIR`/`MATCH_COUNT`, `spec_status()`, glifos `☐ pendente`/`◐ em spec`/`● implementada`, e o formato de linha `| a | b | ... |` (padding único) são idênticos entre o template (Task 1), o script (Task 3), as fixtures (Task 2) e as instruções das skills (Tasks 5–7).
