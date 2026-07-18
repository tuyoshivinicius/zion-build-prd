# Dogfooding local via `--plugin-dir` — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Give the harness developer a versioned wrapper that opens a Claude Code session serving the working tree via `--plugin-dir`, so working-tree skills (including unpublished ones) are live in the terminal without republishing or reinstalling.

**Architecture:** A thin, executable shell wrapper (`scripts/dev-claude.sh`) resolves the repo root from its own path, validates two preconditions (it is the harness root; `claude` is on PATH), prints one transparency line, then `exec`s `claude --plugin-dir <root>`. It mutates nothing under `~/.claude` — the local copy shadows the installed marketplace copy per-session by documented precedence. Canonization is a single new line in `docs/architecture.md §3` (required same-commit by the canon guard) plus a README subsection.

**Tech Stack:** Bash (POSIX-ish, `set -euo pipefail`), Claude Code CLI (`claude --plugin-dir`), the repo's canon guard (`scripts/check-canon.sh`).

## Global Constraints

- **Script-of-dev precedent (`setup-hooks.sh`):** lives in `architecture.md §3` script table, **no RF in `prd.md`**, **no `test-*.sh` auto-test**. `dev-claude.sh` follows this precedent exactly.
- **No new `scripts/test-*.sh`:** `check-canon.sh` C3 greps every top-level `scripts/*.sh` basename in `architecture.md §3`; adding a test script would force a §3 line for it too, and it is not a verifier (no exit 0/1/2 contract). Verify behavior by manual invocation instead.
- **Same-commit canonization:** `check-canon.sh` C3 runs in the pre-commit hook. Committing `scripts/dev-claude.sh` **without** its `architecture.md §3` line fails the commit with `script-sem-doc`. The script file and the §3 line land in the **same commit**.
- **Root resolution from script path**, not `git rev-parse` — the wrapper must work when called from any directory (`$SCRIPT_DIR/..`).
- **No global-state mutation:** the wrapper never writes `~/.claude`, `.claude/settings.json`, or `.claude/settings.local.json`; never touches the installed plugin. Everything is per-session, reversible by closing the session.
- **Error contract:** any validation failure exits with status ≠ 0 and an actionable message (what to fix) on stderr, **before** any `exec`.
- **Not a gate:** convenience for the dev, optional. No PRD RF, no ADR.

---

### Task 1: `scripts/dev-claude.sh` wrapper + canon line (one commit)

**Files:**
- Create: `scripts/dev-claude.sh`
- Modify: `docs/architecture.md` (§3 script table — add one row)
- Test: none as a committed file — behavior verified by manual invocation with a stubbed `claude` (see steps). Temp artifacts live in the scratchpad, never in `scripts/`.

**Interfaces:**
- Consumes: nothing from earlier tasks. Relies on `$ROOT/.claude-plugin/plugin.json` existing (it does — repo root manifest) and on `claude` being resolvable on `PATH` at run time.
- Produces: an executable `scripts/dev-claude.sh` whose contract is:
  - resolves `ROOT` = parent of the script's own directory;
  - exits `1` with an actionable stderr message if `$ROOT/.claude-plugin/plugin.json` is absent;
  - exits `1` with an actionable stderr message if `claude` is not on `PATH`;
  - on success prints one stdout line `dev-claude: servindo o working tree via --plugin-dir=<ROOT> (sombreia a cópia do marketplace nesta sessão).` then `exec claude --plugin-dir "$ROOT" "$@"`, forwarding all extra args.
  - README (Task 2) relies on the script path `./scripts/dev-claude.sh` and the `/reload-plugins` workflow.

- [ ] **Step 1: Write the failing behavioral check (run before the file exists)**

Create a stub `claude` in the scratchpad so the happy path can be observed without launching an interactive session, then invoke the not-yet-existing wrapper. This is the "test" — expect it to fail because the script does not exist.

```bash
SCRATCH="/tmp/claude-1000/-home-tuyoshi-projects-personal-zion-build-prd/e1faedda-f87c-439b-a520-191b01d2ad1d/scratchpad"
mkdir -p "$SCRATCH/fakebin"
cat > "$SCRATCH/fakebin/claude" <<'STUB'
#!/usr/bin/env bash
echo "STUB claude $*"
STUB
chmod +x "$SCRATCH/fakebin/claude"

cd /home/tuyoshi/projects/personal/zion-build-prd
PATH="$SCRATCH/fakebin:$PATH" ./scripts/dev-claude.sh --foo bar; echo "exit=$?"
```

- [ ] **Step 2: Run it to confirm it fails**

Run the Step 1 block.
Expected: `bash: ./scripts/dev-claude.sh: No such file or directory` (or `zsh: no such file or directory`), `exit=127`. The script does not exist yet.

- [ ] **Step 3: Write the wrapper**

Create `scripts/dev-claude.sh`:

```bash
#!/usr/bin/env bash
# dev-claude.sh — abre uma sessão do Claude Code servindo o working tree deste
# repo via `--plugin-dir`, para dogfooding local das skills (inclusive as ainda
# não publicadas no GitHub). A cópia local sombreia a cópia instalada do
# marketplace de mesmo nome, por sessão (precedência documentada do --plugin-dir).
# Não é verificador (sem contrato exit 0/1/2) e não muta ~/.claude — script de
# dev, no precedente de scripts/setup-hooks.sh.
#
# Uso: scripts/dev-claude.sh [args extras repassados ao claude]
set -euo pipefail

# Raiz do repo a partir do caminho do próprio script — funciona de qualquer dir.
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# É a raiz do harness? (tem o manifesto do plugin)
if [ ! -f "$ROOT/.claude-plugin/plugin.json" ]; then
  echo "dev-claude: $ROOT não é a raiz do harness (.claude-plugin/plugin.json ausente)." >&2
  echo "dev-claude: rode o script a partir de scripts/ do repo zion-build-prd." >&2
  exit 1
fi

# O Claude Code está instalado e no PATH?
if ! command -v claude >/dev/null 2>&1; then
  echo "dev-claude: 'claude' não está no PATH — Claude Code não instalado ou fora do PATH." >&2
  echo "dev-claude: instale o Claude Code e garanta que 'claude' resolve no shell." >&2
  exit 1
fi

# Transparência: esta sessão sombreia a cópia instalada do marketplace de mesmo nome.
echo "dev-claude: servindo o working tree via --plugin-dir=$ROOT (sombreia a cópia do marketplace nesta sessão)."

exec claude --plugin-dir "$ROOT" "$@"
```

- [ ] **Step 4: Make it executable**

```bash
chmod +x /home/tuyoshi/projects/personal/zion-build-prd/scripts/dev-claude.sh
```

- [ ] **Step 5: Run the happy-path check to verify it passes**

```bash
SCRATCH="/tmp/claude-1000/-home-tuyoshi-projects-personal-zion-build-prd/e1faedda-f87c-439b-a520-191b01d2ad1d/scratchpad"
cd /home/tuyoshi/projects/personal/zion-build-prd
PATH="$SCRATCH/fakebin:$PATH" ./scripts/dev-claude.sh --foo bar; echo "exit=$?"
```

Expected stdout (two lines) then `exit=0`:
```
dev-claude: servindo o working tree via --plugin-dir=/home/tuyoshi/projects/personal/zion-build-prd (sombreia a cópia do marketplace nesta sessão).
STUB claude --plugin-dir /home/tuyoshi/projects/personal/zion-build-prd --foo bar
exit=0
```
This confirms: root resolves correctly, the transparency line prints, `exec` builds `--plugin-dir <root>` and forwards `--foo bar`.

- [ ] **Step 6: Verify the "not the harness root" error branch**

Copy the script under a fake root (a scratch dir whose parent has no `.claude-plugin/`) and run it:

```bash
SCRATCH="/tmp/claude-1000/-home-tuyoshi-projects-personal-zion-build-prd/e1faedda-f87c-439b-a520-191b01d2ad1d/scratchpad"
mkdir -p "$SCRATCH/fakeroot/scripts"
cp /home/tuyoshi/projects/personal/zion-build-prd/scripts/dev-claude.sh "$SCRATCH/fakeroot/scripts/"
PATH="$SCRATCH/fakebin:$PATH" "$SCRATCH/fakeroot/scripts/dev-claude.sh"; echo "exit=$?"
```

Expected: stderr contains `não é a raiz do harness (.claude-plugin/plugin.json ausente)` and `rode o script a partir de scripts/`, no `STUB claude` line, `exit=1`.

- [ ] **Step 7: Verify the "claude not on PATH" error branch**

Run with a PATH that has coreutils (`dirname`) but no `claude`:

```bash
cd /home/tuyoshi/projects/personal/zion-build-prd
PATH="/usr/bin:/bin" ./scripts/dev-claude.sh; echo "exit=$?"
```

Expected: stderr contains `'claude' não está no PATH` and `instale o Claude Code`, no `STUB claude` line, `exit=1`. (If `claude` happens to live in `/usr/bin`, temporarily point PATH at an empty scratch bin dir plus `/usr/bin` after confirming `command -v claude` there resolves nothing; the branch under test is `command -v claude` failing.)

- [ ] **Step 8: Add the canon line to `architecture.md §3`**

In `docs/architecture.md`, add one row at the end of the §3 scripts table (after the `scripts/setup-hooks.sh` row on line 73):

```markdown
| scripts/dev-claude.sh | Abre uma sessão do Claude Code servindo o working tree via `--plugin-dir` (dogfooding local das skills). |
```

- [ ] **Step 9: Verify the canon guard passes**

```bash
cd /home/tuyoshi/projects/personal/zion-build-prd
./scripts/check-canon.sh; echo "exit=$?"
```

Expected: `check-canon: limpo`, `exit=0`. (Without Step 8 this would print `scripts/dev-claude.sh: script-sem-doc — não citado em docs/architecture.md (tabela de scripts)` and `exit=1`.)

- [ ] **Step 10: Verify the other mechanical layers do not regress**

```bash
cd /home/tuyoshi/projects/personal/zion-build-prd
./scripts/check-assets.sh; echo "assets_exit=$?"
./scripts/eval.sh; echo "eval_exit=$?"
```

Expected: both report clean and exit `0`. (Neither is affected by the new script, but the spec's acceptance criteria require confirming no regression.)

- [ ] **Step 11: Commit (script + canon line together)**

The pre-commit hook runs `check-canon.sh`; both files must be in this one commit or it will block.

```bash
cd /home/tuyoshi/projects/personal/zion-build-prd
git add scripts/dev-claude.sh docs/architecture.md
git commit -m "feat(scripts): dev-claude.sh serve o working tree via --plugin-dir

Wrapper de dogfooding local: abre uma sessão do Claude Code com
--plugin-dir na raiz do repo, sombreando a cópia do marketplace por
sessão. Script de dev (precedente setup-hooks.sh): sem RF, sem ADR, sem
auto-teste. Canoniza a linha na tabela de scripts (architecture.md §3)
no mesmo commit.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

Expected: pre-commit hook runs (sync + guards), `check-canon: limpo`, commit succeeds.

---

### Task 2: README — "Desenvolvimento" dogfooding subsection

**Files:**
- Modify: `README.md` (add a dogfooding subsection inside the existing `## Desenvolvimento` section, after line 96 — the `scripts/asset-map.sh` mapping paragraph, before the CI paragraph)

**Interfaces:**
- Consumes from Task 1: the committed `./scripts/dev-claude.sh` path and its documented per-session shadowing behavior.
- Produces: user-facing docs; nothing downstream depends on it. README is not scanned by `check-canon.sh`, so it may commit separately.

- [ ] **Step 1: Add the dogfooding subsection**

In `README.md`, insert this block immediately after the line `Mapeamento asset → skills: \`scripts/asset-map.sh\` (sourced por sync e check).` (line 96) and its following blank line:

```markdown
### Dogfooding local das skills

Para usar as skills do **working tree** (inclusive as ainda não publicadas) no terminal, sem
republicar no GitHub nem reinstalar o plugin:

```bash
./scripts/dev-claude.sh   # abre o Claude Code servindo o working tree via --plugin-dir
```

O `--plugin-dir` tem **precedência** sobre a cópia instalada do marketplace **naquela sessão** —
comando único, sem `/plugin disable` nem desinstalar nada. Argumentos extras são repassados ao
`claude` (ex.: `./scripts/dev-claude.sh --resume`).

Depois de editar um `SKILL.md`, rode `/reload-plugins` na sessão para aplicar a mudança. Alterações
em `hooks/`, `agents/` e afins exigem reabrir a sessão. O escopo vale **só** para sessões abertas
pelo wrapper: o `--plugin-dir` é resolvido no start do `claude` e não retroage à sessão atual.
```

- [ ] **Step 2: Verify the README renders sensibly and paths are correct**

```bash
cd /home/tuyoshi/projects/personal/zion-build-prd
grep -n "dev-claude.sh" README.md
grep -n "reload-plugins" README.md
```

Expected: `dev-claude.sh` appears on the invocation line(s); `reload-plugins` appears once in the new subsection. Eyeball the section to confirm the fenced code block nesting is intact (the inner ```` ```bash ```` block closes before the prose).

- [ ] **Step 3: Confirm no guard regression from the README edit**

```bash
cd /home/tuyoshi/projects/personal/zion-build-prd
./scripts/check-canon.sh; echo "exit=$?"
```

Expected: `check-canon: limpo`, `exit=0` (README is not a canon input; this only confirms nothing broke).

- [ ] **Step 4: Commit**

```bash
cd /home/tuyoshi/projects/personal/zion-build-prd
git add README.md
git commit -m "docs(readme): seção de dogfooding local via dev-claude.sh

Documenta o wrapper de --plugin-dir na seção Desenvolvimento: comando
único, precedência por sessão sobre a cópia do marketplace, e o fluxo
/reload-plugins após editar SKILL.md.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

Expected: commit succeeds (pre-commit clean).

---

## Self-Review

**1. Spec coverage** — every spec element maps to a task:

| Spec element | Where |
|---|---|
| `scripts/dev-claude.sh` novo, executável | Task 1 Steps 3–4 |
| Resolve raiz do repo do caminho do script (qualquer dir) | Task 1 Step 3 (`$SCRIPT_DIR/..`), verified Step 5 |
| Valida `.claude-plugin/plugin.json`; erro acionável | Task 1 Step 3, verified Step 6 |
| Valida `claude` no PATH; erro acionável | Task 1 Step 3, verified Step 7 |
| Imprime uma linha de transparência (shadow) | Task 1 Step 3, verified Step 5 |
| `exec claude --plugin-dir "$ROOT" "$@"` (repassa args) | Task 1 Step 3, verified Step 5 (`--foo bar`) |
| Contrato de erro: status ≠ 0, não muta ~/.claude | Task 1 Steps 6–7 (exit=1); wrapper writes nothing under `~/.claude` |
| README seção Desenvolvimento — dogfooding | Task 2 Step 1 |
| `--plugin-dir` precedência por sessão, comando único | Task 2 Step 1 |
| `/reload-plugins` após editar SKILL.md; hooks/agents exigem reabrir | Task 2 Step 1 |
| Escopo: só sessões abertas pelo wrapper | Task 2 Step 1 |
| Canon: linha na `architecture.md §3` | Task 1 Step 8, verified Step 9 |
| Sem RF novo em `prd.md` | Not done, by design — no task touches `prd.md` |
| Sem ADR | Not done, by design |
| Sem auto-teste `test-*.sh` | Not done, by design (Global Constraints) |
| `check-canon.sh` passa; `check-assets.sh`/`eval.sh` não regridem | Task 1 Steps 9–10 |

**2. Placeholder scan** — no `TBD`/`TODO`/"add appropriate…"/"similar to Task N". Every code and doc step shows the actual content. The two "not done" rows are deliberate spec instructions (no RF, no ADR, no auto-test), not omissions.

**3. Type/name consistency** — the script path `scripts/dev-claude.sh`, the transparency-line wording, the exit codes (`1`), and the `--plugin-dir` invocation are identical across Task 1's Interfaces block, the wrapper body, the verification steps, the `architecture.md §3` row, and the README. The stderr messages checked in Steps 6–7 match the `echo … >&2` lines in Step 3 verbatim.
