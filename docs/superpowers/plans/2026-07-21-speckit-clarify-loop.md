# `speckit-clarify-loop` Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a single self-contained bash tool that drives the Spec Kit clarification cycle unattended — injecting `yes` on every recommendation, one `claude` process per round — until the spec converges.

**Architecture:** One file, `tools/speckit-clarify-loop`, installed by copy to `~/.local/bin/`. The invariant is **one round = one `claude` process**: the process exiting *is* the `/clear`. Each round opens `claude -p --input-format stream-json --output-format stream-json --verbose` with stdin on a FIFO, injects `/speckit-clarify`, then reads the JSONL stream and reacts to each `{"type":"result"}` event by classifying the turn's text and either injecting `yes` or closing the session. The only deterministically testable component — the text classifier — is exercised by an embedded `--self-test`.

**Tech Stack:** bash (POSIX-ish, `set -u`), `jq`, `git`, `mkfifo`, GNU `tail --pid`, `awk`. Drives `claude` 2.1.216.

## Global Constraints

- **Not a `zion-build-prd` artifact.** The file lives at `tools/speckit-clarify-loop` — **never** in `scripts/`. `scripts/check-canon.sh` C3 only scans `scripts/*.sh` top-level, so `tools/` carries no canonization duty: no row in `docs/architecture.md` §3, no `docs/prd.md` RF, no `eval.sh` wiring, no `ASSET_MAP` entry. Do not add any.
- **Single file, no runtime siblings.** Everything (classifier, fixtures, self-test, loop) lives in that one file; it is installed by `cp`/`install` to `PATH` and must not read any file shipped alongside it.
- **Dependency check at startup.** `claude`, `jq`, `git`, `mkfifo`, `awk` — verified on every run, failing with an actionable message. The tool cannot presume any repo's environment.
- **`set -u`, never `set -e`.** Matches the repo's `check-*.sh` style; all errors handled explicitly via `die`.
- **Exit contract:** `0` = converged (dry phrase or stagnation), or `--self-test`/`--dry-run` completed clean. `1` = stopped by a guard or aborted on error (max-rounds, rate limit, `is_error`, permission denials, indeterminate turn, yes-cap), or self-test failure. `2` = usage or environment error.
- **Messages in Portuguese**, prefixed `speckit-clarify-loop:`, matching the repo's script voice.
- **Never `--continue` / `--resume` / `--dangerously-skip-permissions`.** These are design invariants, not preferences.
- **Hard cap of 5 `yes` per round** (`MAX_YES=5`), mirroring the skill's own limit.
- **Default `--max-rounds` is 10.** The loop is never unbounded.
- **Raw stream per round** at `/tmp/speckit-clarify-loop/round-NN.jsonl`.

### Verified ground truth (do not re-derive)

These were confirmed empirically against `claude` 2.1.216 while writing this plan:

- Multi-turn over a held-open FIFO works and **preserves context**: two turns emitted the same `session_id`, one `{"type":"result"}` event each. Closing stdin exits the process.
- `result` event shape: `{"type":"result","subtype":"success","is_error":false,"result":"<texto do turno>","total_cost_usd":0.11,"permission_denials":[],"num_turns":1,"session_id":"..."}`.
- Rate-limit event shape: `{"type":"rate_limit_event","rate_limit_info":{"status":"allowed","overageStatus":"rejected",...}}` — the field to guard is `.rate_limit_info.status`.
- A `system`/`init` event is re-emitted at the start of each turn; **this is not a context reset** (same `session_id`). Do not treat it as a signal.
- `exec 3<> fifo` (read-write open) never blocks, and `tail -n +1 -f --pid=$PID file` exits cleanly when the process dies — including when it dies instantly at startup. This pair is what keeps the loop from ever hanging.
- In `zion-test-build-prd` (branch `main`, no feature branch), `SPECIFY_FEATURE=006-code-interop bash .specify/scripts/bash/check-prerequisites.sh --json --paths-only` exits 0 and returns `FEATURE_SPEC`. That env var is the smoke-test handle in Task 6.
- Exact skill strings (from `speckit-clarify/SKILL.md`): question format is `**Recommended:** Option [X] - <reasoning>` or `**Suggested:** <answer> - <reasoning>`; the dry response is `"No critical ambiguities detected worth formal clarification."`; the Completion Report's last bullet is `Suggested next command`.

---

### Task 1: File skeleton, flags and dependency check

**Files:**
- Create: `tools/speckit-clarify-loop`

**Interfaces:**
- Consumes: nothing.
- Produces: globals `REPO`, `MAX_ROUNDS`, `ALLOW_DIRTY`, `DRY_RUN`; functions `usage()`, `die(msg[, code])`, `need_deps()`. Every later task builds on these exact names.

- [ ] **Step 1: Create the file with header, globals, `die`, `usage`, `need_deps` and flag parsing**

Create `tools/speckit-clarify-loop`:

```bash
#!/usr/bin/env bash
# speckit-clarify-loop — automatiza o ciclo de clarificação do Spec Kit.
#
# Invariante: uma rodada = um processo `claude`. O término do processo É o
# `/clear`. Nunca usa --continue, --resume ou --dangerously-skip-permissions.
#
# Uso:
#   speckit-clarify-loop [--repo DIR] [--max-rounds N] [--allow-dirty] [--dry-run] [--self-test]
#
# Exit: 0 convergiu (frase seca ou estagnação), ou --self-test/--dry-run limpo
#       1 parada por guarda (teto de rodadas) ou aborto por erro
#       2 erro de uso ou de ambiente
#
# Ferramenta pessoal, instalada por cópia no PATH: não presume o ambiente de
# nenhum repo e checa as próprias dependências no arranque.
set -u

REPO="$PWD"
MAX_ROUNDS=10
ALLOW_DIRTY=0
DRY_RUN=0

# Teto de `yes` por rodada — espelha o limite de 5 perguntas da própria skill.
MAX_YES=5
# Rede contra um turno que trava sem emitir `result`. Não é flag: é salvaguarda.
ROUND_TIMEOUT=900
LOG_DIR=/tmp/speckit-clarify-loop

die() { printf 'speckit-clarify-loop: %s\n' "$1" >&2; exit "${2:-2}"; }

usage() {
  cat >&2 <<'EOF'
uso: speckit-clarify-loop [--repo DIR] [--max-rounds N] [--allow-dirty] [--dry-run] [--self-test]

  --repo DIR       repo alvo (default: cwd)
  --max-rounds N   teto duro de rodadas (default: 10)
  --allow-dirty    dispensa a exigência de working tree limpo
  --dry-run        uma rodada sem Edit/Write: mostra as perguntas e os `yes`, sem tocar o spec
  --self-test      roda os testes embutidos da classificação e sai
EOF
  exit 2
}

need_deps() {
  local missing="" c
  for c in claude jq git mkfifo awk tail; do
    command -v "$c" >/dev/null 2>&1 || missing="$missing $c"
  done
  [ -z "$missing" ] || die "dependência ausente:$missing — instale antes de rodar"
}

while [ $# -gt 0 ]; do
  case "$1" in
    --repo)        [ $# -ge 2 ] || usage; REPO="$2"; shift 2 ;;
    --max-rounds)  [ $# -ge 2 ] || usage; MAX_ROUNDS="$2"; shift 2 ;;
    --allow-dirty) ALLOW_DIRTY=1; shift ;;
    --dry-run)     DRY_RUN=1; shift ;;
    -h|--help)     usage ;;
    *) printf 'speckit-clarify-loop: flag desconhecida: %s\n' "$1" >&2; usage ;;
  esac
done

case "$MAX_ROUNDS" in
  ''|*[!0-9]*) die "--max-rounds exige um inteiro positivo (veio: $MAX_ROUNDS)" ;;
esac
[ "$MAX_ROUNDS" -ge 1 ] || die "--max-rounds exige um inteiro positivo (veio: $MAX_ROUNDS)"

need_deps

# TEMPORÁRIO — substituído pelo driver na Task 5.
printf 'speckit-clarify-loop: arranque ok (repo=%s max-rounds=%s dry-run=%s allow-dirty=%s)\n' \
  "$REPO" "$MAX_ROUNDS" "$DRY_RUN" "$ALLOW_DIRTY"
```

- [ ] **Step 2: Make it executable and verify the happy path**

```bash
cd /home/tuyoshi/projects/personal/zion-build-prd
chmod +x tools/speckit-clarify-loop
./tools/speckit-clarify-loop --repo /tmp --max-rounds 3; echo "rc=$?"
```

Expected: `speckit-clarify-loop: arranque ok (repo=/tmp max-rounds=3 dry-run=0 allow-dirty=0)` and `rc=0`.

- [ ] **Step 3: Verify the error paths**

```bash
./tools/speckit-clarify-loop --max-rounds zero; echo "rc=$?"
./tools/speckit-clarify-loop --bogus; echo "rc=$?"
./tools/speckit-clarify-loop --repo; echo "rc=$?"
```

Expected, in order:
1. `speckit-clarify-loop: --max-rounds exige um inteiro positivo (veio: zero)` / `rc=2`
2. `speckit-clarify-loop: flag desconhecida: --bogus` followed by the usage block / `rc=2`
3. the usage block / `rc=2`

- [ ] **Step 4: Commit**

```bash
git add tools/speckit-clarify-loop
git commit -m "feat(tools): esqueleto do speckit-clarify-loop (flags + checagem de dependências)"
```

---

### Task 2: Turn classifier + `--self-test`

This is the only deterministic component and the only real regression risk: if the skill changes its `**Recommended:**` wording, the loop starts answering the wrong thing. TDD applies fully here.

**Files:**
- Modify: `tools/speckit-clarify-loop` (insert the classifier block after `need_deps()`; add `--self-test` to the flag loop)

**Interfaces:**
- Consumes: `die()` from Task 1.
- Produces: `classify "<texto>"` → prints exactly one of `loop-seco` / `rodada-completa` / `pergunta-pendente` / `indeterminada`. Constants `SIG_DRY`, `SIG_COMPLETE`, `SIG_MC`, `SIG_SHORT`. Function `self_test()` → exit 0 clean / 1 failure. Task 4 calls `classify` on every `result` event.

- [ ] **Step 1: Write the failing test**

Insert this block into `tools/speckit-clarify-loop`, immediately **after** the `need_deps()` function and **before** the `while [ $# -gt 0 ]` flag loop. It defines the fixtures and the self-test but *not* `classify` — that comes in Step 3.

```bash
# --- Auto-teste embutido ---------------------------------------------------
# Fixtures espelham o texto literal de speckit-clarify/SKILL.md. Se a skill
# mudar o formato, é aqui que a regressão aparece.

FIX_MC="$(cat <<'EOF'
**Recommended:** Option B - patching only changed nodes keeps the preview
deterministic and avoids a second render path.

| Option | Description |
|--------|-------------|
| A | Re-render the whole canvas on every keystroke |
| B | Diff the AST and patch only changed nodes |
| C | Debounce for 300ms then full re-render |

You can reply with the option letter (e.g., "A"), accept the recommendation by saying "yes" or "recommended", or provide your own short answer.
EOF
)"

FIX_SHORT="$(cat <<'EOF'
**Suggested:** Soft delete with 30-day retention - preserves undo without unbounded growth.

Format: Short answer (<=5 words). You can accept the suggestion by saying "yes" or "suggested", or provide your own answer.
EOF
)"

FIX_REPORT="$(cat <<'EOF'
## Clarification Summary

- Questions asked & answered: 5
- Updated spec: specs/006-code-interop/spec.md
- Sections touched: Functional Requirements, Data Model, Edge Cases

| Category | Status |
|---|---|
| Functional Scope & Behavior | Resolved |
| Domain & Data Model | Resolved |
| Integration & External Dependencies | Deferred |

Outstanding items remain low impact; I recommend proceeding to planning.

Suggested next command: `/speckit-plan`
EOF
)"

FIX_DRY="$(cat <<'EOF'
No critical ambiguities detected worth formal clarification.

The spec covers all taxonomy categories at Clear status. Suggest proceeding.

Suggested next command: `/speckit-plan`
EOF
)"

FIX_NOISE="$(cat <<'EOF'
I read the spec and started building the internal coverage map. Give me a
moment while I finish scanning the Non-Functional Quality Attributes section.
EOF
)"

FIX_PROSE_RECOMMEND="$(cat <<'EOF'
Based on the current spec I would recommend a stricter retention policy, but
that is a planning-level concern rather than a spec ambiguity.
EOF
)"

ST_FAIL=0
assert_classify() {  # descrição  esperado  texto
  local got; got="$(classify "$3")"
  if [ "$got" = "$2" ]; then
    printf 'ok: %s\n' "$1"
  else
    printf 'FALHOU: %s (esperado %s, veio %s)\n' "$1" "$2" "$got"
    ST_FAIL=1
  fi
}

self_test() {
  assert_classify "pergunta múltipla escolha"        pergunta-pendente "$FIX_MC"
  assert_classify "pergunta de resposta curta"       pergunta-pendente "$FIX_SHORT"
  assert_classify "Completion Report"                rodada-completa   "$FIX_REPORT"
  assert_classify "frase seca tem prioridade sobre o report" loop-seco "$FIX_DRY"
  assert_classify "texto que não casa com nada"      indeterminada     "$FIX_NOISE"
  assert_classify "texto vazio"                      indeterminada     ""
  assert_classify "'recommend' em prosa não é pergunta" indeterminada   "$FIX_PROSE_RECOMMEND"
  assert_classify "só o marcador bold conta"         pergunta-pendente '**Recommended:** Option A - x'

  if [ "$ST_FAIL" -eq 0 ]; then
    printf 'speckit-clarify-loop: self-test limpo (8 casos)\n'; exit 0
  fi
  printf 'speckit-clarify-loop: self-test COM FALHAS\n' >&2; exit 1
}
```

Then add `--self-test` to the flag loop — replace the `--dry-run` line with these two lines:

```bash
    --dry-run)     DRY_RUN=1; shift ;;
    --self-test)   self_test ;;
```

- [ ] **Step 2: Run the test to verify it fails**

Run:
```bash
./tools/speckit-clarify-loop --self-test; echo "rc=$?"
```
Expected: FAIL — eight lines of `classify: command not found` on stderr and eight `FALHOU:` lines (each `got` empty), ending with `speckit-clarify-loop: self-test COM FALHAS` and `rc=1`.

- [ ] **Step 3: Write the classifier**

Insert this block immediately **before** the `# --- Auto-teste embutido` block:

```bash
# --- Classificação do turno (função pura de texto) --------------------------
# Espelha speckit-clarify/SKILL.md: passo 5 (formato das perguntas), a regra de
# comportamento da frase seca e o último item do Completion Report.
#
# A ORDEM IMPORTA. O turno seco também é um Completion Report (traz "Suggested
# next command"), então loop-seco é testado primeiro. E, entre report e
# pergunta, report vem antes: classificar um report como pergunta injetaria
# `yes` numa rodada já encerrada; o inverso apenas gasta uma rodada a mais.
SIG_DRY='No critical ambiguities detected'
SIG_COMPLETE='Suggested next command'
SIG_MC='**Recommended:**'
SIG_SHORT='**Suggested:**'

classify() {  # texto do turno em $1 → rótulo em stdout
  local txt="${1:-}"
  if printf '%s' "$txt" | grep -qF -- "$SIG_DRY"; then
    printf 'loop-seco\n'
  elif printf '%s' "$txt" | grep -qF -- "$SIG_COMPLETE"; then
    printf 'rodada-completa\n'
  elif printf '%s' "$txt" | grep -qF -- "$SIG_MC" \
    || printf '%s' "$txt" | grep -qF -- "$SIG_SHORT"; then
    printf 'pergunta-pendente\n'
  else
    printf 'indeterminada\n'
  fi
}
```

- [ ] **Step 4: Run the test to verify it passes**

Run:
```bash
./tools/speckit-clarify-loop --self-test; echo "rc=$?"
```
Expected: eight `ok:` lines, then `speckit-clarify-loop: self-test limpo (8 casos)` and `rc=0`.

- [ ] **Step 5: Commit**

```bash
git add tools/speckit-clarify-loop
git commit -m "feat(tools): classificação do turno + --self-test com fixtures da skill"
```

---

### Task 3: Preflight — repo, clean tree, target spec

**Files:**
- Modify: `tools/speckit-clarify-loop` (insert preflight block after `classify`; the temporary banner from Task 1 stays until Task 5)

**Interfaces:**
- Consumes: `die()`, `REPO`, `ALLOW_DIRTY`, `LOG_DIR`.
- Produces: `preflight()` which normalizes `REPO` to an absolute path and sets globals `SPEC` (absolute path to `spec.md`) and `WORK` (a per-run scratch dir for FIFOs); helpers `spec_hash()` and `spec_lines()`. Task 4 uses `SPEC`, `WORK`, `LOG_DIR`; Task 5 uses `spec_hash`/`spec_lines`.

- [ ] **Step 1: Write the preflight block**

Insert immediately **after** the `classify()` function and **before** the `# --- Auto-teste embutido` block:

```bash
# --- Preflight -------------------------------------------------------------
# Resolve o spec alvo pela MESMA fonte que a skill usa (passo 1), para que
# script e skill nunca divirjam de arquivo.
SPEC=""
WORK=""

preflight() {
  [ -d "$REPO" ] || die "repo não encontrado: $REPO"
  REPO="$(cd "$REPO" && pwd)"
  [ -d "$REPO/.specify" ] || die "não parece um repo Spec Kit (sem .specify/): $REPO"

  local prereq="$REPO/.specify/scripts/bash/check-prerequisites.sh"
  [ -f "$prereq" ] || die "check-prerequisites.sh ausente em $REPO/.specify/scripts/bash/"

  git -C "$REPO" rev-parse --git-dir >/dev/null 2>&1 \
    || die "repo alvo não é um repositório git: $REPO"
  if [ "$ALLOW_DIRTY" -eq 0 ] && [ -n "$(git -C "$REPO" status --porcelain)" ]; then
    die "working tree sujo em $REPO — commite ou descarte antes (ou passe --allow-dirty)"
  fi

  local json
  json="$(cd "$REPO" && bash "$prereq" --json --paths-only 2>&1)" \
    || die "check-prerequisites.sh falhou: $json"
  SPEC="$(printf '%s' "$json" | jq -r '.FEATURE_SPEC // empty' 2>/dev/null)" \
    || die "saída do check-prerequisites.sh não é JSON: $json"
  [ -n "$SPEC" ] || die "check-prerequisites.sh não devolveu FEATURE_SPEC: $json"
  [ -f "$SPEC" ] || die "spec alvo não existe: $SPEC"

  mkdir -p "$LOG_DIR" || die "não consegui criar $LOG_DIR"
  rm -f "$LOG_DIR"/round-*.jsonl "$LOG_DIR"/round-*.jsonl.err
  WORK="$(mktemp -d "${TMPDIR:-/tmp}/speckit-clarify-loop.XXXXXX")" \
    || die "não consegui criar diretório de trabalho"
}

cleanup() { [ -n "$WORK" ] && rm -rf "$WORK"; }
trap cleanup EXIT

spec_hash()  { git hash-object "$SPEC"; }
spec_lines() { wc -l < "$SPEC" | tr -d ' '; }
```

Then replace the temporary banner at the bottom of the file with:

```bash
preflight

# TEMPORÁRIO — substituído pelo driver na Task 5.
printf 'speckit-clarify-loop: preflight ok\n  repo: %s\n  spec: %s (%s linhas, %s)\n' \
  "$REPO" "$SPEC" "$(spec_lines)" "$(spec_hash)"
```

- [ ] **Step 2: Verify against a real Spec Kit repo**

```bash
cd /home/tuyoshi/projects/personal/zion-build-prd
SPECIFY_FEATURE=006-code-interop ./tools/speckit-clarify-loop \
  --repo /home/tuyoshi/projects/personal/zion-test-build-prd; echo "rc=$?"
```

Expected: `rc=0` and

```
speckit-clarify-loop: preflight ok
  repo: /home/tuyoshi/projects/personal/zion-test-build-prd
  spec: /home/tuyoshi/projects/personal/zion-test-build-prd/specs/006-code-interop/spec.md (188 linhas, <sha>)
```

(The line count may differ if the spec has since changed; the path and a 40-char sha are what matter.)

- [ ] **Step 3: Verify the guards**

```bash
./tools/speckit-clarify-loop --repo /tmp; echo "rc=$?"
./tools/speckit-clarify-loop --repo /home/tuyoshi/projects/personal/zion-test-build-prd; echo "rc=$?"
```

Expected:
1. `speckit-clarify-loop: não parece um repo Spec Kit (sem .specify/): /tmp` / `rc=2`
2. Without `SPECIFY_FEATURE` the target repo is on `main`, so `check-prerequisites.sh` fails: `speckit-clarify-loop: check-prerequisites.sh falhou: ERROR: Not on a feature branch. Current branch: main …` / `rc=2`

Now verify the dirty-tree guard:

```bash
TARGET=/home/tuyoshi/projects/personal/zion-test-build-prd
touch "$TARGET/.dirty-probe"
SPECIFY_FEATURE=006-code-interop ./tools/speckit-clarify-loop --repo "$TARGET"; echo "rc=$?"
SPECIFY_FEATURE=006-code-interop ./tools/speckit-clarify-loop --repo "$TARGET" --allow-dirty; echo "rc=$?"
rm -f "$TARGET/.dirty-probe"
```

Expected: first call `speckit-clarify-loop: working tree sujo em … — commite ou descarte antes (ou passe --allow-dirty)` / `rc=2`; second call prints the `preflight ok` block / `rc=0`.

- [ ] **Step 4: Confirm the self-test still passes**

```bash
./tools/speckit-clarify-loop --self-test; echo "rc=$?"
```
Expected: eight `ok:` lines, `self-test limpo (8 casos)`, `rc=0`.

- [ ] **Step 5: Commit**

```bash
git add tools/speckit-clarify-loop
git commit -m "feat(tools): preflight do loop (repo Spec Kit, tree limpo, spec alvo via check-prerequisites)"
```

---

### Task 4: Round engine — one round, one `claude` process

**Files:**
- Modify: `tools/speckit-clarify-loop` (insert the engine after `spec_lines()`; replace the temporary banner)

**Interfaces:**
- Consumes: `classify()`, `preflight()`, `SPEC`, `REPO`, `WORK`, `LOG_DIR`, `MAX_YES`, `ROUND_TIMEOUT`, `DRY_RUN`, `die()`.
- Produces: `send_user "<texto>"` (writes one JSONL user message to fd 3) and `run_round <n>`, which sets globals `ROUND_OUTCOME` (`loop-seco` | `rodada-completa` | `indeterminada` | `aborto`), `ROUND_YES` (int), `ROUND_COST` (decimal string), `ROUND_ABORT` (reason, only when `aborto`). Task 5's driver reads exactly these four globals.

**Why this shape:** `exec 3<> "$in"` opens the FIFO read-write so it never blocks even if `claude` dies at startup, and `claude`'s stdout goes straight to the round log file, read incrementally via `tail --pid`. When the process dies — for any reason — `tail` exits, the read loop ends, and the round resolves as `indeterminada` instead of hanging. Both behaviors were verified with stubs before this plan was written.

- [ ] **Step 1: Write the engine**

Insert immediately **after** `spec_lines()` and **before** the `# --- Auto-teste embutido` block:

```bash
# --- Motor de uma rodada ----------------------------------------------------
ROUND_OUTCOME=""
ROUND_YES=0
ROUND_COST=0
ROUND_ABORT=""

send_user() {  # texto → uma mensagem de usuário JSONL no fd 3
  jq -cn --arg t "$1" \
    '{type:"user",message:{role:"user",content:[{type:"text",text:$t}]}}' >&3
}

add_cost() {  # a b → a+b com 6 casas
  awk -v a="$1" -v b="$2" 'BEGIN{printf "%.6f", a+b}'
}

run_round() {  # número da rodada em $1
  local n="$1"
  local tag; tag="$(printf '%02d' "$n")"
  local log="$LOG_DIR/round-$tag.jsonl"
  local err="$log.err"
  local in="$WORK/in-$n.fifo"

  ROUND_OUTCOME=""; ROUND_YES=0; ROUND_COST=0; ROUND_ABORT=""

  mkfifo "$in" || { ROUND_OUTCOME=aborto; ROUND_ABORT="mkfifo falhou"; return; }
  : > "$log"; : > "$err"

  # Permissões mínimas: acceptEdits sozinho não basta porque a skill roda o
  # check-prerequisites.sh via Bash, e prompt de permissão em modo não
  # interativo vira negação silenciosa. Em --dry-run, Edit/Write saem de cena.
  local -a args=(
    -p
    --input-format stream-json
    --output-format stream-json
    --verbose
    --permission-mode acceptEdits
    --allowedTools 'Bash(.specify/scripts/bash/check-prerequisites.sh*)'
  )
  if [ "$DRY_RUN" -eq 1 ]; then
    args+=( --disallowedTools Edit Write MultiEdit NotebookEdit )
  fi

  ( cd "$REPO" && exec claude "${args[@]}" ) < "$in" > "$log" 2> "$err" &
  local cpid=$!

  exec 3<> "$in"   # read-write: nunca bloqueia, mesmo se o claude já morreu
  ( sleep "$ROUND_TIMEOUT"; kill -TERM "$cpid" 2>/dev/null ) &
  local wdog=$!

  send_user '/speckit-clarify'

  local line typ status iserr denials cost txt
  while IFS= read -r line; do
    typ="$(printf '%s' "$line" | jq -r '.type // empty' 2>/dev/null)" || continue

    if [ "$typ" = "rate_limit_event" ]; then
      status="$(printf '%s' "$line" | jq -r '.rate_limit_info.status // "?"')"
      if [ "$status" != "allowed" ]; then
        ROUND_OUTCOME=aborto
        ROUND_ABORT="rate limit com status=$status — cota esgotada, não insisto"
        break
      fi
      continue
    fi

    [ "$typ" = "result" ] || continue

    iserr="$(printf '%s' "$line" | jq -r '.is_error // false')"
    denials="$(printf '%s' "$line" | jq -r '(.permission_denials // []) | length')"
    cost="$(printf '%s' "$line" | jq -r '.total_cost_usd // 0')"
    ROUND_COST="$(add_cost "$ROUND_COST" "$cost")"

    if [ "$iserr" = "true" ]; then
      ROUND_OUTCOME=aborto; ROUND_ABORT="result com is_error=true (ver $log)"; break
    fi
    # Em --dry-run a negação de Edit/Write é esperada: é o próprio mecanismo.
    if [ "$denials" != "0" ] && [ "$DRY_RUN" -eq 0 ]; then
      ROUND_OUTCOME=aborto
      ROUND_ABORT="permission_denials não-vazio ($denials) — rodada gravaria spec pela metade"
      break
    fi

    txt="$(printf '%s' "$line" | jq -r '.result // ""')"
    case "$(classify "$txt")" in
      pergunta-pendente)
        if [ "$ROUND_YES" -ge "$MAX_YES" ]; then
          ROUND_OUTCOME=aborto
          ROUND_ABORT="teto de $MAX_YES yes estourado na rodada $n"
          break
        fi
        ROUND_YES=$((ROUND_YES + 1))
        printf '  [r%s] pergunta %d → yes\n' "$tag" "$ROUND_YES"
        send_user 'yes'
        ;;
      loop-seco)       ROUND_OUTCOME=loop-seco;       break ;;
      rodada-completa) ROUND_OUTCOME=rodada-completa; break ;;
      indeterminada)
        ROUND_OUTCOME=indeterminada
        printf '  [r%s] turno indeterminado — stream em %s\n' "$tag" "$log"
        break
        ;;
    esac
  done < <(tail -n +1 -f --pid="$cpid" --sleep-interval=0.2 "$log")

  exec 3>&-              # fecha o stdin do claude → o processo sai → é o /clear
  kill "$wdog" 2>/dev/null
  wait "$cpid" 2>/dev/null
  rm -f "$in"

  # Stream terminou sem classificar nada: o processo caiu.
  if [ -z "$ROUND_OUTCOME" ]; then
    ROUND_OUTCOME=aborto
    ROUND_ABORT="o processo claude terminou sem emitir turno classificável (ver $err)"
  fi
}
```

Then replace the temporary banner at the bottom with:

```bash
preflight

# TEMPORÁRIO — substituído pelo driver na Task 5.
run_round 1
printf 'rodada 1: outcome=%s yes=%s custo=%s %s\n' \
  "$ROUND_OUTCOME" "$ROUND_YES" "$ROUND_COST" "$ROUND_ABORT"
```

- [ ] **Step 2: Verify one real round in dry-run mode**

```bash
cd /home/tuyoshi/projects/personal/zion-build-prd
SPECIFY_FEATURE=006-code-interop ./tools/speckit-clarify-loop \
  --repo /home/tuyoshi/projects/personal/zion-test-build-prd --dry-run; echo "rc=$?"
```

Expected: one or more `[r01] pergunta N → yes` lines, then a final line whose `outcome=` is `rodada-completa` (or `loop-seco` if the spec is already clean). `rc=0`.

**If `outcome=indeterminada` or `outcome=aborto` with "terminou sem emitir turno classificável":** inspect `/tmp/speckit-clarify-loop/round-01.jsonl` and `.err`. The most likely cause is that `/speckit-clarify` sent as plain text was not dispatched as a slash command. Confirm by checking whether the skill ran at all:

```bash
jq -r 'select(.type=="assistant") | .message.content[]? | select(.type=="tool_use") | .name' \
  /tmp/speckit-clarify-loop/round-01.jsonl
```

If no `Bash` call to `check-prerequisites.sh` appears, change the first injected message in `run_round` from `'/speckit-clarify'` to:

```bash
  send_user 'Use the speckit-clarify skill on this repository now.'
```

and re-run Step 2. Record whichever form worked in the file's header comment.

- [ ] **Step 3: Confirm the spec was not touched**

```bash
git -C /home/tuyoshi/projects/personal/zion-test-build-prd status --porcelain; echo "rc=$?"
```
Expected: no output — `--dry-run` must leave the working tree exactly as it found it. If the spec changed, `--disallowedTools` is not holding and the round engine must be fixed before proceeding.

- [ ] **Step 4: Confirm the self-test and preflight guards still pass**

```bash
./tools/speckit-clarify-loop --self-test; echo "rc=$?"
```
Expected: `self-test limpo (8 casos)` / `rc=0`.

- [ ] **Step 5: Commit**

```bash
git add tools/speckit-clarify-loop
git commit -m "feat(tools): motor de rodada do loop (stream-json por FIFO, injeção de yes, abortos)"
```

---

### Task 5: Loop driver — stopping layers, dry-run and final report

**Files:**
- Modify: `tools/speckit-clarify-loop` (insert the driver after `run_round`; replace the temporary banner with the real entry point)

**Interfaces:**
- Consumes: `run_round()`, `spec_hash()`, `spec_lines()`, `add_cost()`, `preflight()`, `MAX_ROUNDS`, `DRY_RUN`, `SIG_DRY`, `LOG_DIR`, `SPEC`, `REPO`.
- Produces: `main_loop()` — the tool's terminal behavior. Nothing consumes it.

**Stopping layers, in the order the driver applies them:** (1) the dry phrase `No critical ambiguities detected` → converged, exit 0; (2) an abort or indeterminate turn → stop and report, exit 1; (3) two consecutive rounds that leave `spec.md` byte-identical → converged by stagnation, exit 0; (4) `--max-rounds` exhausted → exit 1.

- [ ] **Step 1: Write the driver**

Insert immediately **after** `run_round()` and **before** the `# --- Auto-teste embutido` block:

```bash
# --- Driver do loop ---------------------------------------------------------
main_loop() {
  local round=0 same=0 prev_hash cur_hash
  local total_yes=0 total_cost=0 yes_log="" stop_reason="" rc=1
  local start_lines end_lines delta tag

  start_lines="$(spec_lines)"
  printf 'speckit-clarify-loop: %s\n  spec: %s (%s linhas)\n' \
    "$REPO" "$SPEC" "$start_lines"
  [ "$DRY_RUN" -eq 1 ] && printf '  modo: --dry-run (uma rodada, sem Edit/Write)\n'

  while [ "$round" -lt "$MAX_ROUNDS" ]; do
    round=$((round + 1))
    tag="$(printf '%02d' "$round")"
    prev_hash="$(spec_hash)"
    printf 'rodada %s/%s …\n' "$tag" "$MAX_ROUNDS"

    run_round "$round"

    total_yes=$((total_yes + ROUND_YES))
    total_cost="$(add_cost "$total_cost" "$ROUND_COST")"
    yes_log="$yes_log r$tag=$ROUND_YES"
    cur_hash="$(spec_hash)"

    case "$ROUND_OUTCOME" in
      loop-seco)
        stop_reason="convergiu — a skill respondeu \"$SIG_DRY\""; rc=0; break ;;
      aborto)
        stop_reason="aborto na rodada $tag — $ROUND_ABORT"; rc=1; break ;;
      indeterminada)
        stop_reason="turno indeterminado na rodada $tag (stream: $LOG_DIR/round-$tag.jsonl)"
        rc=1; break ;;
    esac

    if [ "$DRY_RUN" -eq 1 ]; then
      stop_reason="--dry-run: uma rodada executada, nada gravado"
      rc=0
      if [ "$cur_hash" != "$prev_hash" ]; then
        stop_reason="--dry-run ALTEROU o spec (hash mudou) — investigue antes de confiar no modo"
        rc=1
      fi
      break
    fi

    if [ "$cur_hash" = "$prev_hash" ]; then
      same=$((same + 1))
      if [ "$same" -ge 2 ]; then
        stop_reason="convergiu por estagnação — 2 rodadas seguidas sem alterar o spec"
        rc=0; break
      fi
    else
      same=0
    fi
  done

  if [ -z "$stop_reason" ]; then
    stop_reason="teto de rodadas atingido ($MAX_ROUNDS) sem convergir"
    rc=1
  fi

  end_lines="$(spec_lines)"
  delta=$((end_lines - start_lines))
  printf '\n—— resumo ——\n'
  printf 'repo:     %s\n' "$REPO"
  printf 'spec:     %s\n' "$SPEC"
  printf 'rodadas:  %s\n' "$round"
  printf 'yes:      %s (%s)\n' "$total_yes" "${yes_log# }"
  printf 'custo:    US$ %s\n' "$total_cost"
  printf 'spec:     %s → %s linhas (delta %+d)\n' "$start_lines" "$end_lines" "$delta"
  printf 'streams:  %s/round-*.jsonl\n' "$LOG_DIR"
  printf 'parada:   %s\n' "$stop_reason"
  printf '\nreverter: git -C %s checkout -- %s\n' "$REPO" "$SPEC"

  return "$rc"
}
```

- [ ] **Step 2: Replace the temporary banner with the real entry point**

Replace these lines at the bottom of the file:

```bash
preflight

# TEMPORÁRIO — substituído pelo driver na Task 5.
run_round 1
printf 'rodada 1: outcome=%s yes=%s custo=%s %s\n' \
  "$ROUND_OUTCOME" "$ROUND_YES" "$ROUND_COST" "$ROUND_ABORT"
```

with:

```bash
preflight
main_loop
```

- [ ] **Step 3: Verify the self-test path still short-circuits before preflight**

```bash
cd /tmp && /home/tuyoshi/projects/personal/zion-build-prd/tools/speckit-clarify-loop --self-test; echo "rc=$?"
```
Expected: `self-test limpo (8 casos)` / `rc=0`. It must succeed from `/tmp`, which is not a Spec Kit repo — proving `--self-test` never touches preflight.

- [ ] **Step 4: Verify the full dry-run report**

```bash
cd /home/tuyoshi/projects/personal/zion-build-prd
SPECIFY_FEATURE=006-code-interop ./tools/speckit-clarify-loop \
  --repo /home/tuyoshi/projects/personal/zion-test-build-prd --dry-run; echo "rc=$?"
git -C /home/tuyoshi/projects/personal/zion-test-build-prd status --porcelain
```
Expected: the header, `modo: --dry-run`, `rodada 01/10 …`, the `[r01] pergunta N → yes` lines, then the `—— resumo ——` block with `parada: --dry-run: uma rodada executada, nada gravado`, `rc=0`, and **no output** from `git status --porcelain`.

- [ ] **Step 5: Commit**

```bash
git add tools/speckit-clarify-loop
git commit -m "feat(tools): driver do loop (parada em camadas, dry-run e resumo final)"
```

---

### Task 6: Install to `PATH` and smoke-test end to end

**Files:**
- Modify: `tools/speckit-clarify-loop` (header comment only, if the smoke run reveals anything)
- Create: `~/.local/bin/speckit-clarify-loop` (installed copy, not version controlled)

**Interfaces:**
- Consumes: the finished tool from Task 5.
- Produces: nothing further.

- [ ] **Step 1: Install**

```bash
cd /home/tuyoshi/projects/personal/zion-build-prd
install -m 755 tools/speckit-clarify-loop ~/.local/bin/speckit-clarify-loop
command -v speckit-clarify-loop
```
Expected: `/home/tuyoshi/.local/bin/speckit-clarify-loop`.

- [ ] **Step 2: Verify the installed copy is self-contained**

Run it from a directory with no relation to this repo:

```bash
cd /tmp && speckit-clarify-loop --self-test; echo "rc=$?"
```
Expected: `self-test limpo (8 casos)` / `rc=0` — the installed file must work with no sibling files.

- [ ] **Step 3: Smoke-test one dry round from the target repo's own cwd**

```bash
cd /home/tuyoshi/projects/personal/zion-test-build-prd
git status --porcelain   # deve estar vazio antes de começar
SPECIFY_FEATURE=006-code-interop speckit-clarify-loop --dry-run; echo "rc=$?"
git status --porcelain   # deve continuar vazio
```
Expected: `rc=0`, a `—— resumo ——` block reporting at least one `yes`, `spec: 188 → 188 linhas (delta +0)`, and empty `git status` output both times. This exercises the default `--repo` (cwd) path that Tasks 3–5 never used.

- [ ] **Step 4: Inspect the raw stream and confirm the skill actually ran**

```bash
jq -r 'select(.type=="assistant") | .message.content[]? | select(.type=="tool_use") | .name' \
  /tmp/speckit-clarify-loop/round-01.jsonl | sort -u
jq -r 'select(.type=="result") | .result' /tmp/speckit-clarify-loop/round-01.jsonl | head -30
```
Expected: `Bash` (and possibly `Read`) in the first output, and turn text in the second containing `**Recommended:**` or `**Suggested:**` — proof that the classifier is matching real skill output, not just fixtures.

- [ ] **Step 5: Record the verified invocation in the file header**

Append these lines to the header comment block of `tools/speckit-clarify-loop`, just above `set -u`, filling in what Step 3 actually produced:

```bash
# Verificado em 2026-07-21 contra claude 2.1.216 e a skill speckit-clarify:
#   --dry-run em zion-test-build-prd (SPECIFY_FEATURE=006-code-interop) →
#   <N> perguntas classificadas, <N> yes injetados, spec intocado.
# Reinstalar após editar:  install -m 755 tools/speckit-clarify-loop ~/.local/bin/
```

- [ ] **Step 6: Confirm no canonization drift was introduced**

```bash
cd /home/tuyoshi/projects/personal/zion-build-prd
./scripts/check-canon.sh; echo "rc=$?"
./scripts/check-assets.sh; echo "rc=$?"
```
Expected: `rc=0` from both. `tools/` must be invisible to the canon guards — if `check-canon.sh` reports `script-sem-doc`, the file was placed in `scripts/` by mistake and must be moved.

- [ ] **Step 7: Commit**

```bash
git add tools/speckit-clarify-loop
git commit -m "docs(tools): registra a verificação end-to-end do speckit-clarify-loop"
```

---

## Notes for the implementer

- **Never let the loop hang.** Every path out of `run_round` sets `ROUND_OUTCOME`. If you add a branch, add its outcome.
- **The classifier's order is load-bearing.** Read the comment above `classify()` before reordering anything there, and add a fixture to `self_test` for any new signal.
- **Quota is finite.** The account runs with `overageStatus: rejected`; a round that hits a rate limit aborts the whole loop by design. Prefer `--dry-run` while iterating, and never leave a real run unattended on the first try.
- **Reverting is one command.** The tool refuses to start on a dirty tree precisely so `git checkout -- <spec>` undoes exactly the loop's effect; the final report prints that command.
