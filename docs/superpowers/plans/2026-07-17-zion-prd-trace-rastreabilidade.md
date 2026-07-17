# `/zion-prd-trace` — Rastreabilidade com mecânica (R2) — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Substituir a "tabela de rastreabilidade mantida à mão" (seção 12 da PRD) por um artefato **derivado por máquina** — um script `scripts/trace-prd.sh` que reconcilia a §12 a partir da §6 da PRD e das `specs/*/spec.md`, mais uma 9ª skill `/zion-prd-trace` que o embrulha.

**Architecture:** `trace-prd.sh <prd> <specs> [--check]` parseia a §6 (RF/Descrição/Épico), varre as specs em busca da linha rotulada `**RF cobertos:** RF-xx, ...`, deriva o status de cada RF a partir do `tasks.md` da spec (☐/◐/●), preserva a coluna Release da §12 existente e reescreve a §12 in-place. O modo `--check` escreve numa cópia temporária e diffa contra o original (read-only). Distribuído para `references/` de duas skills pela mesma máquina `asset-map.sh` + `sync-assets.sh` + `check-assets.sh` que já governa `check-prd.sh`.

**Tech Stack:** Bash + awk (POSIX, sem extensões gawk), no mesmo estilo de `scripts/check-prd.sh`. Testes: script bash com asserts (padrão de `scripts/test-check-prd.sh`). CI: GitHub Actions (`.github/workflows/check-assets.yml`).

---

## File Structure

**Novos arquivos**

- `scripts/trace-prd.sh` — o reconciliador. Funções (contrato estável entre tasks):
  - `parse_section6 <prd>` → emite `RF\tEPICO\tDESCRICAO`, uma linha por RF, na ordem da §6.
  - `table_col <prd> <colname>` → emite `RF\tVALOR` para cada linha de dados da tabela §12 (indexado pelo cabeçalho; robusto a reordenação/ausência de coluna). Usado para preservar Release e ler o Status antigo.
  - `scan_specs <specs-dir>` → popula os temporários `$RFSPEC` (`RF\tnome-da-spec`), `$UNTRACE` (nomes de specs sem a linha `**RF cobertos:**`) e `$SPECSTATUS` (`nome-da-spec\tspec|impl`).
  - `spec_status <spec-dir>` → ecoa `spec` ou `impl` a partir do `tasks.md`.
  - `specs_for_rf <rf>` → ecoa as specs que cobrem o RF, como `` `specs/nome` `` unidas por `, ` (vazio se nenhuma).
  - `status_for_rf <rf>` → ecoa o glifo de status (menos avançado entre as specs cobrindo; ☐ se nenhuma).
  - `release_for_rf <rf>` → ecoa o Release preservado da §12 antiga (vazio se novo).
  - `build_table` → monta o bloco Markdown completo da §12 (nota + tabela + legenda).
  - `write_section12 <prd> <tabela-file>` → reescreve a §12 in-place, preservando o cabeçalho e as seções vizinhas.
  - `run_check <warnings> <tabela>` → modo read-only: escreve numa cópia temporária, diffa, sai `1` se drift/avisos.
  - `compute_warnings` → emite os avisos (RF órfão, spec intraçável, RF descoberto).
- `scripts/test-trace-prd.sh` — auto-teste com fixtures.
- `scripts/fixtures/trace/` — PRD sintética + árvore `specs/` + subárvore `clean/`.
- `skills/zion-prd-trace/SKILL.md` — a 9ª skill.

**Arquivos modificados**

- `scripts/asset-map.sh` — nova entrada de sync.
- `skills/zion-prd-decompose/SKILL.md` — Fase 4 roda `trace-prd.sh` em vez de injetar a tabela à mão.
- `skills/zion-prd-specify-prompt/SKILL.md` — Fase 2/3 pede a linha `**RF cobertos:**`.
- `assets/quality-rules.md` — `#anatomia-specify` + `#criterios-de-conclusao`.
- `assets/templates/traceability-table.md` — nota de "tabela derivada".
- `.github/workflows/check-assets.yml` — passo do auto-teste do trace.
- `docs/guia-prd-para-spec-kit.md`, `docs/como-usar.md`, `README.md` — menção à skill + contagem 8→9.
- `skills/*/references/` — regenerados pelo sync (não editados à mão).

**Convenção de status (glifos — use EXATAMENTE estes em todo o código e testes):**
`☐ pendente` · `◐ em spec` · `● implementada`.

---

## Task 1: Fixtures do trace

Dados puros contra os quais todo o resto é testado. Sem código de teste ainda.

**Files:**
- Create: `scripts/fixtures/trace/PRD.md`
- Create: `scripts/fixtures/trace/specs/001-acao/spec.md`
- Create: `scripts/fixtures/trace/specs/001-acao/tasks.md`
- Create: `scripts/fixtures/trace/specs/002-historico/spec.md`
- Create: `scripts/fixtures/trace/specs/002-historico/tasks.md`
- Create: `scripts/fixtures/trace/specs/003-orfao/spec.md`
- Create: `scripts/fixtures/trace/specs/003-orfao/tasks.md`
- Create: `scripts/fixtures/trace/specs/004-intracavel/spec.md`
- Create: `scripts/fixtures/trace/clean/PRD.md`
- Create: `scripts/fixtures/trace/clean/specs/001-unica/spec.md`
- Create: `scripts/fixtures/trace/clean/specs/001-unica/tasks.md`

- [ ] **Step 1: Criar a PRD sintética principal**

Create `scripts/fixtures/trace/PRD.md`:

```markdown
# PRD — Fixture Trace

## 6. Requisitos funcionais por épico (RF-xx)
- **Épico E1 — Núcleo:** RF-01 o usuário faz a ação principal; RF-02 o usuário revê o histórico.
- **Épico E2 — Extras:** RF-03 o usuário exporta os dados; RF-04 o usuário compartilha um link.

## 12. Rastreabilidade
| RF | Descrição | Épico | Feature / Spec | Release | Status |
|----|-----------|-------|----------------|---------|--------|
| RF-01 | desc antiga | E1 |  | R0 | ☐ pendente |
| RF-02 | desc antiga | E1 |  | R1 | ☐ pendente |
| RF-03 | desc antiga | E2 |  | R2 | ☐ pendente |
| RF-04 | desc antiga | E2 |  |  | ☐ pendente |

## 13. Apêndice
Conteúdo que não deve ser tocado pela reescrita da §12.
```

- [ ] **Step 2: Criar as specs (001 implementada, 002 em spec)**

Create `scripts/fixtures/trace/specs/001-acao/spec.md`:

```markdown
# Spec 001 — Ação principal
**RF cobertos:** RF-01

Descrição da fatia.
```

Create `scripts/fixtures/trace/specs/001-acao/tasks.md`:

```markdown
# Tarefas
- [x] montar a tela
- [x] ligar a ação
```

Create `scripts/fixtures/trace/specs/002-historico/spec.md`:

```markdown
# Spec 002 — Histórico
**RF cobertos:** RF-02

Descrição da fatia.
```

Create `scripts/fixtures/trace/specs/002-historico/tasks.md`:

```markdown
# Tarefas
- [x] listar itens
- [ ] paginar
```

- [ ] **Step 3: Criar as specs de aviso (003 órfã, 004 intraçável)**

Create `scripts/fixtures/trace/specs/003-orfao/spec.md`:

```markdown
# Spec 003 — Órfã
**RF cobertos:** RF-99

Declara um RF que não existe na §6 da PRD.
```

Create `scripts/fixtures/trace/specs/003-orfao/tasks.md`:

```markdown
# Tarefas
- [x] feito
```

Create `scripts/fixtures/trace/specs/004-intracavel/spec.md`:

```markdown
# Spec 004 — Sem rótulo
Esta spec não tem a linha **RF cobertos:** — é intraçável.
```

- [ ] **Step 4: Criar a subárvore `clean/` (sem avisos, para o caminho exit 0)**

Create `scripts/fixtures/trace/clean/PRD.md`:

```markdown
# PRD — Fixture Clean

## 6. Requisitos funcionais por épico (RF-xx)
- **Épico E1 — Núcleo:** RF-01 o usuário faz a única ação.

## 12. Rastreabilidade
| RF | Descrição | Épico | Feature / Spec | Release | Status |
|----|-----------|-------|----------------|---------|--------|
| RF-01 | x | E1 |  | R0 | ☐ pendente |
```

Create `scripts/fixtures/trace/clean/specs/001-unica/spec.md`:

```markdown
# Spec 001 — Única
**RF cobertos:** RF-01

Cobre o único RF da §6.
```

Create `scripts/fixtures/trace/clean/specs/001-unica/tasks.md`:

```markdown
# Tarefas
- [x] pronto
```

- [ ] **Step 5: Commit**

```bash
git add scripts/fixtures/trace
git commit -m "test(trace): fixtures da rastreabilidade (PRD + specs + clean)"
```

---

## Task 2: `trace-prd.sh` — bootstrap (parse §6, tabela, escrita, --check, resumo)

Cria o script funcionando para o **bootstrap** (sem specs): parse da §6, preservação de Release, escrita da §12, modo `--check` e resumo. `scan_specs` e `compute_warnings` entram como stubs (preenchidos nas Tasks 3 e 4) — exatamente o walking skeleton: com specs ausentes, todo RF sai `☐ pendente`.

**Files:**
- Create: `scripts/trace-prd.sh`
- Create: `scripts/test-trace-prd.sh`

- [ ] **Step 1: Escrever o teste de bootstrap (falha antes do script existir)**

Create `scripts/test-trace-prd.sh`:

```bash
#!/usr/bin/env bash
# Auto-teste do trace-prd.sh contra fixtures. Semente da suíte de avaliação (R7).
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
TRACE="scripts/trace-prd.sh"
FIX="scripts/fixtures/trace"
fail=0

assert_exit() {  # desc  exit_esperado  exit_veio
  if [ "$2" != "$3" ]; then echo "FALHOU: $1 (exit esperado $2, veio $3)"; fail=1
  else echo "ok: $1"; fi
}
assert_contains() {  # desc  agulha  palheiro
  if printf '%s' "$3" | grep -qi -- "$2"; then echo "ok: $1"
  else echo "FALHOU: $1 (não achou: $2)"; fail=1; fi
}
assert_file_re() {  # desc  arquivo  regex_estendida
  if grep -Eq -- "$3" "$2"; then echo "ok: $1"
  else echo "FALHOU: $1 (regex não casou: $3)"; fail=1; fi
}
fresh_prd() {  # copia a fixture $1 para um temp e ecoa o caminho
  local t; t="$(mktemp)"; cp "$1" "$t"; printf '%s' "$t"
}

# --- Task 2: bootstrap (sem specs) ---
prd="$(fresh_prd "$FIX/PRD.md")"
out="$(bash "$TRACE" "$prd" "$FIX/nao-existe")"; rc=$?
assert_exit "bootstrap sai 0" 0 "$rc"
assert_file_re "bootstrap: RF-01 vira linha pendente" "$prd" 'RF-01.*☐ pendente'
assert_file_re "bootstrap: descrição regenerada da §6" "$prd" 'o usuário faz a ação principal'
assert_file_re "bootstrap: Release R0 preservado" "$prd" 'RF-01.*R0.*pendente'
assert_file_re "bootstrap: §13 preservada" "$prd" '## 13\. Apêndice'
rm -f "$prd"

# erro de uso: PRD inexistente → exit 2
out="$(bash "$TRACE" nao/existe.md specs 2>&1)"; rc=$?
assert_exit "PRD inexistente sai 2" 2 "$rc"

if [ "$fail" -eq 0 ]; then echo "test-trace-prd: tudo verde"; else echo "test-trace-prd: FALHOU"; exit 1; fi
```

- [ ] **Step 2: Rodar o teste e confirmar que falha**

Run: `bash scripts/test-trace-prd.sh`
Expected: FALHA — `trace-prd.sh` não existe (bash reclama e/ou asserts falham).

- [ ] **Step 3: Escrever `scripts/trace-prd.sh` (bootstrap completo, stubs em scan_specs/compute_warnings)**

Create `scripts/trace-prd.sh`:

```bash
#!/usr/bin/env bash
# trace-prd.sh — reconciliador da tabela de rastreabilidade (§12) da PRD (R2).
# Deriva a §12 a partir da §6 da PRD + specs/*/spec.md. ESCREVE (git é o desfazer);
# --check é read-only. Verifica e reconcilia; o humano decide.
#
# Uso:
#   trace-prd.sh <prd-file> <specs-dir> [--check]
#     <specs-dir> ausente/vazio → bootstrap (tudo pendente).
#     --check → não grava; reporta drift/avisos e sai 1.
#
# Exit: 0 (limpo) · 1 (drift/avisos) · 2 (erro de uso/ambiente).
set -u

usage() { echo "uso: trace-prd.sh <prd-file> <specs-dir> [--check]" >&2; exit 2; }

PRD=""; SPECS_DIR=""; MODE_CHECK=0
for a in "$@"; do
  case "$a" in
    --check) MODE_CHECK=1 ;;
    -*) usage ;;
    *) if [ -z "$PRD" ]; then PRD="$a"
       elif [ -z "$SPECS_DIR" ]; then SPECS_DIR="$a"
       else usage; fi ;;
  esac
done
[ -n "$PRD" ] || usage
[ -f "$PRD" ] || { echo "trace-prd: arquivo não encontrado: $PRD" >&2; exit 2; }
grep -qE '^##[[:space:]]*6([^0-9]|$)'  "$PRD" || { echo "trace-prd: PRD sem seção 6"  >&2; exit 2; }
grep -qE '^##[[:space:]]*12([^0-9]|$)' "$PRD" || { echo "trace-prd: PRD sem seção 12" >&2; exit 2; }

TAB="$(printf '\t')"
SEC6=""; RFSPEC=""; UNTRACE=""; SPECSTATUS=""; OLDREL=""; OLDSTATUS=""
cleanup() { rm -f "$SEC6" "$RFSPEC" "$UNTRACE" "$SPECSTATUS" "$OLDREL" "$OLDSTATUS" 2>/dev/null; }
trap cleanup EXIT

# --- §6 da PRD: RF agrupado por Épico E#, com descrição de 1 frase por RF. ---
# Múltiplos RF por linha separados por ';'. Casa "pico E#" (evita o É multibyte).
parse_section6() {
  awk '
    /^## / { n=$2; sub(/\./,"",n); sect=n; next }
    sect=="6" {
      if (match($0, /pico[[:space:]]+E[0-9]+/)) { e=substr($0,RSTART,RLENGTH); sub(/.*[[:space:]]/,"",e); cur=e }
      line=$0
      while (match(line, /RF-[0-9]+/)) {
        rf=substr(line,RSTART,RLENGTH); rest=substr(line,RSTART+RLENGTH); desc=rest
        if (match(desc,/RF-[0-9]+/)) desc=substr(desc,1,RSTART-1)
        if (match(desc,/;/))         desc=substr(desc,1,RSTART-1)
        gsub(/\*/,"",desc); gsub(/^[[:space:]:]+/,"",desc); gsub(/[[:space:];.]+$/,"",desc)
        print rf "\t" cur "\t" desc
        line=rest
      }
    }
  ' "$1"
}

# --- Uma coluna da tabela §12 existente, indexada pelo cabeçalho (RF\tvalor). ---
table_col() {  # $1 prd  $2 nome-da-coluna
  awk -v want="$2" '
    function lc(s){ return tolower(s) }
    /^##[[:space:]]*12([^0-9]|$)/ { in12=1; next }
    in12 && /^## / { in12=0 }
    in12 && /^[[:space:]]*\|/ {
      line=$0; sub(/^[[:space:]]*\|/,"",line); sub(/\|[[:space:]]*$/,"",line)
      nc=split(line, c, /\|/)
      for(i=1;i<=nc;i++){ gsub(/^[[:space:]]+|[[:space:]]+$/,"",c[i]) }
      if (!hdr) {
        for(i=1;i<=nc;i++) if (lc(c[i])=="rf") rfcol=i
        if (rfcol) { for(i=1;i<=nc;i++) if (index(lc(c[i]), lc(want))) wcol=i; hdr=1 }
        next
      }
      if (c[1] ~ /^[-:]+$/) next
      if (rfcol && wcol && match(c[rfcol],/RF-[0-9]+/))
        print substr(c[rfcol],RSTART,RLENGTH) "\t" c[wcol]
    }
  ' "$1"
}

# --- STUB (Task 3): varre specs → $RFSPEC, $UNTRACE, $SPECSTATUS. Bootstrap = vazio. ---
scan_specs() {
  : > "$RFSPEC"; : > "$UNTRACE"; : > "$SPECSTATUS"
}

# --- STUB (Task 4): avisos. Bootstrap = nenhum. ---
compute_warnings() {
  :
}

specs_for_rf() {  # $1 rf → `specs/a`, `specs/b`  (vazio se nenhuma)
  local rf="$1" out="" r name
  while IFS="$TAB" read -r r name; do
    [ "$r" = "$rf" ] || continue
    if [ -z "$out" ]; then out="\`specs/$name\`"; else out="$out, \`specs/$name\`"; fi
  done < "$RFSPEC"
  printf '%s' "$out"
}

status_for_rf() {  # $1 rf → glifo (menos avançado entre as specs; ☐ se nenhuma)
  local rf="$1" rank=-1 r name st v
  while IFS="$TAB" read -r r name; do
    [ "$r" = "$rf" ] || continue
    st="$(awk -F'\t' -v n="$name" '$1==n{print $2; exit}' "$SPECSTATUS")"
    case "$st" in impl) v=2 ;; *) v=1 ;; esac
    if [ "$rank" -eq -1 ] || [ "$v" -lt "$rank" ]; then rank="$v"; fi
  done < "$RFSPEC"
  case "$rank" in 2) printf '● implementada' ;; 1) printf '◐ em spec' ;; *) printf '☐ pendente' ;; esac
}

release_for_rf() { awk -F'\t' -v r="$1" '$1==r{print $2; exit}' "$OLDREL"; }

# --- Monta o bloco completo da §12 (nota + tabela + legenda). ---
build_table() {
  printf '> Tabela derivada — regenerada por `/zion-prd-trace`. Não edite Status/Feature/Spec à mão.\n\n'
  printf '| RF | Descrição | Épico | Feature / Spec | Release | Status |\n'
  printf '|----|-----------|-------|----------------|---------|--------|\n'
  while IFS="$TAB" read -r rf epic desc; do
    [ -n "$rf" ] || continue
    printf '| %s | %s | %s | %s | %s | %s |\n' \
      "$rf" "$desc" "$epic" "$(specs_for_rf "$rf")" "$(release_for_rf "$rf")" "$(status_for_rf "$rf")"
  done < "$SEC6"
  printf '\nLegenda de status: ☐ pendente · ◐ em spec · ● implementada.\n'
}

# --- Reescreve a §12 in-place: preserva o cabeçalho e as seções vizinhas. ---
write_section12() {  # $1 prd  $2 arquivo-com-a-tabela
  local prd="$1" tf="$2" tmp; tmp="$(mktemp)"
  awk -v tf="$tf" '
    BEGIN { while ((getline l < tf) > 0) body = body l "\n" }
    /^##[[:space:]]*12([^0-9]|$)/ && !done { print; print ""; printf "%s", body; print ""; done=1; skip=1; next }
    skip && /^## / { skip=0 }
    skip { next }
    { print }
  ' "$prd" > "$tmp" && mv "$tmp" "$prd"
}

# --- Modo read-only: escreve numa cópia e diffa contra o original. ---
run_check() {  # $1 avisos  $2 tabela
  local warnings="$1" table="$2" tmpprd tf drift=""
  tmpprd="$(mktemp)"; cp "$PRD" "$tmpprd"
  tf="$(mktemp)"; printf '%s\n' "$table" > "$tf"
  write_section12 "$tmpprd" "$tf"
  if ! diff -q "$PRD" "$tmpprd" >/dev/null 2>&1; then
    echo "trace-prd: drift na seção 12 (rode sem --check para reconciliar):"
    diff "$PRD" "$tmpprd" || true
    drift=1
  fi
  [ -n "$warnings" ] && printf '%s\n' "$warnings"
  rm -f "$tmpprd" "$tf"
  if [ -n "$drift" ] || [ -n "$warnings" ]; then echo "trace-prd: fora de dia"; return 1; fi
  echo "trace-prd: em dia"; return 0
}

# --- Orquestração ---
SEC6="$(mktemp)"; RFSPEC="$(mktemp)"; UNTRACE="$(mktemp)"
SPECSTATUS="$(mktemp)"; OLDREL="$(mktemp)"; OLDSTATUS="$(mktemp)"

parse_section6 "$PRD" > "$SEC6"
[ -s "$SEC6" ] || { echo "trace-prd: nenhum RF-xx na seção 6 de $PRD" >&2; exit 2; }
table_col "$PRD" Release > "$OLDREL"
table_col "$PRD" Status  > "$OLDSTATUS"
scan_specs "$SPECS_DIR"
warnings="$(compute_warnings)"
wcount=0; [ -n "$warnings" ] && wcount="$(printf '%s\n' "$warnings" | grep -c .)"
table="$(build_table)"

if [ "$MODE_CHECK" = "1" ]; then
  run_check "$warnings" "$table"; exit $?
fi

tf="$(mktemp)"; printf '%s\n' "$table" > "$tf"
write_section12 "$PRD" "$tf"; rm -f "$tf"

updated=0
while IFS="$TAB" read -r rf epic desc; do
  [ -n "$rf" ] || continue
  newst="$(status_for_rf "$rf")"
  oldst="$(awk -F'\t' -v r="$rf" '$1==r{print $2; exit}' "$OLDSTATUS")"
  if [ "$oldst" != "$newst" ]; then
    echo "  $rf: ${oldst:-☐ (nova)} → $newst"
    updated=$((updated+1))
  fi
done < "$SEC6"

[ -n "$warnings" ] && printf '%s\n' "$warnings"

if [ "$updated" -eq 0 ] && [ "$wcount" -eq 0 ]; then
  echo "trace-prd: em dia"; exit 0
fi
echo "trace-prd: $updated linha(s) atualizada(s), $wcount aviso(s)"
[ "$wcount" -gt 0 ] && exit 1 || exit 0
```

- [ ] **Step 4: Rodar o teste e confirmar que passa**

Run: `bash scripts/test-trace-prd.sh`
Expected: PASS — todas as linhas `ok:` e `test-trace-prd: tudo verde`.

Nota: o bootstrap passa `$FIX/nao-existe` (dir de specs inexistente) → `scan_specs` deixa os temporários vazios → tudo `☐ pendente`, Release preservado da §12 antiga (R0), descrições regeneradas da §6.

- [ ] **Step 5: Commit**

```bash
git add scripts/trace-prd.sh scripts/test-trace-prd.sh
git commit -m "feat(trace): trace-prd.sh — bootstrap (parse §6, escrita §12, --check, resumo)"
```

---

## Task 3: `scan_specs` — status e Feature/Spec a partir das specs

Preenche o stub de `scan_specs` e adiciona `spec_status`. Agora RF cobertos por spec ganham Feature/Spec e status real (● / ◐), e RF sem spec permanecem ☐.

**Files:**
- Modify: `scripts/trace-prd.sh` (substitui `scan_specs`, adiciona `spec_status`)
- Modify: `scripts/test-trace-prd.sh` (novo bloco de teste)

- [ ] **Step 1: Adicionar o teste de scan (falha com o stub atual)**

In `scripts/test-trace-prd.sh`, insira este bloco **imediatamente antes** da linha final `if [ "$fail" -eq 0 ]; then echo "test-trace-prd: tudo verde"; ...`:

```bash
# --- Task 3: specs varridas (status + Feature/Spec + idempotência) ---
prd="$(fresh_prd "$FIX/PRD.md")"
bash "$TRACE" "$prd" "$FIX/specs" >/dev/null 2>&1
assert_file_re "RF-01 implementada c/ spec" "$prd" 'RF-01.*specs/001-acao.*● implementada'
assert_file_re "RF-02 em spec c/ spec"      "$prd" 'RF-02.*specs/002-historico.*◐ em spec'
assert_file_re "RF-03 permanece pendente"   "$prd" 'RF-03.*☐ pendente'
# idempotência: rodar de novo não muda o arquivo
cp "$prd" "$prd.bak"
bash "$TRACE" "$prd" "$FIX/specs" >/dev/null 2>&1
if diff -q "$prd" "$prd.bak" >/dev/null 2>&1; then echo "ok: reconciliação idempotente"
else echo "FALHOU: reconciliação não é idempotente"; fail=1; fi
rm -f "$prd" "$prd.bak"
```

- [ ] **Step 2: Rodar e confirmar que o novo bloco falha**

Run: `bash scripts/test-trace-prd.sh`
Expected: FALHA nos asserts de Task 3 (status ainda `☐ pendente`, sem `specs/001-acao`), porque `scan_specs` é stub.

- [ ] **Step 3: Substituir o stub de `scan_specs` e adicionar `spec_status`**

In `scripts/trace-prd.sh`, substitua o bloco stub:

```bash
# --- STUB (Task 3): varre specs → $RFSPEC, $UNTRACE, $SPECSTATUS. Bootstrap = vazio. ---
scan_specs() {
  : > "$RFSPEC"; : > "$UNTRACE"; : > "$SPECSTATUS"
}
```

por:

```bash
# --- Status de UMA spec a partir do tasks.md ---
#   ausente ou com ao menos um "- [ ]" aberto → spec;  senão → impl.
spec_status() {  # $1 spec-dir
  local tasks="$1/tasks.md"
  [ -f "$tasks" ] || { printf 'spec'; return; }
  if grep -qE '^[[:space:]]*- \[ \]' "$tasks"; then printf 'spec'; return; fi
  printf 'impl'
}

# --- Varre specs/*/spec.md → $RFSPEC (RF\tnome), $UNTRACE (nome), $SPECSTATUS (nome\tstatus). ---
scan_specs() {
  local dir="$1" spec name line rf
  : > "$RFSPEC"; : > "$UNTRACE"; : > "$SPECSTATUS"
  [ -n "$dir" ] && [ -d "$dir" ] || return 0
  for spec in "$dir"/*/spec.md; do
    [ -f "$spec" ] || continue
    name="$(basename "$(dirname "$spec")")"
    printf '%s\t%s\n' "$name" "$(spec_status "$(dirname "$spec")")" >> "$SPECSTATUS"
    line="$(grep -iE 'RF cobertos:' "$spec" | head -1)"
    if [ -z "$line" ]; then printf '%s\n' "$name" >> "$UNTRACE"; continue; fi
    for rf in $(printf '%s' "$line" | grep -oE 'RF-[0-9]+'); do
      printf '%s\t%s\n' "$rf" "$name" >> "$RFSPEC"
    done
  done
}
```

- [ ] **Step 4: Rodar e confirmar que passa**

Run: `bash scripts/test-trace-prd.sh`
Expected: PASS — `test-trace-prd: tudo verde` (bootstrap + scan + idempotência).

- [ ] **Step 5: Commit**

```bash
git add scripts/trace-prd.sh scripts/test-trace-prd.sh
git commit -m "feat(trace): scan_specs — status (☐/◐/●) e Feature/Spec das specs"
```

---

## Task 4: `compute_warnings` — órfão, intraçável, descoberto + exit codes + --check

Preenche o stub de `compute_warnings` e cobre os avisos, o exit 1 do modo padrão com avisos, e os dois caminhos do `--check` (drift → 1; limpo → 0).

**Files:**
- Modify: `scripts/trace-prd.sh` (substitui `compute_warnings`)
- Modify: `scripts/test-trace-prd.sh` (novo bloco de teste)

- [ ] **Step 1: Adicionar o teste de avisos + --check (falha com o stub atual)**

In `scripts/test-trace-prd.sh`, insira este bloco **imediatamente antes** da linha final `if [ "$fail" -eq 0 ]; ...`:

```bash
# --- Task 4: avisos + exit codes + --check ---
prd="$(fresh_prd "$FIX/PRD.md")"
out="$(bash "$TRACE" "$prd" "$FIX/specs")"; rc=$?
assert_exit "modo padrão com avisos sai 1" 1 "$rc"
assert_contains "aviso RF órfão (RF-99)"       "RF órfão" "$out"
assert_contains "aviso spec intraçável (004)"  "intraçável" "$out"
assert_contains "aviso RF descoberto (RF-03)"  "RF descoberto" "$out"
rm -f "$prd"

# --check é read-only e sinaliza drift
prd="$(fresh_prd "$FIX/PRD.md")"; cp "$prd" "$prd.bak"
out="$(bash "$TRACE" "$prd" "$FIX/specs" --check)"; rc=$?
assert_exit "--check com drift sai 1" 1 "$rc"
if diff -q "$prd" "$prd.bak" >/dev/null 2>&1; then echo "ok: --check não escreve"
else echo "FALHOU: --check escreveu no arquivo"; fail=1; fi
rm -f "$prd" "$prd.bak"

# fixture clean: reconcilia (exit 0, sem avisos) e depois --check diz "em dia" (exit 0)
prd="$(fresh_prd "$FIX/clean/PRD.md")"
out="$(bash "$TRACE" "$prd" "$FIX/clean/specs")"; rc=$?
assert_exit "clean reconcilia sem avisos sai 0" 0 "$rc"
assert_file_re "clean: RF-01 implementada" "$prd" 'RF-01.*specs/001-unica.*● implementada'
out="$(bash "$TRACE" "$prd" "$FIX/clean/specs" --check)"; rc=$?
assert_exit "clean --check em dia sai 0" 0 "$rc"
assert_contains "clean --check diz em dia" "em dia" "$out"
rm -f "$prd"
```

- [ ] **Step 2: Rodar e confirmar que o novo bloco falha**

Run: `bash scripts/test-trace-prd.sh`
Expected: FALHA nos asserts de avisos (nenhum aviso é emitido; modo padrão sai 0 em vez de 1).

- [ ] **Step 3: Substituir o stub de `compute_warnings`**

In `scripts/trace-prd.sh`, substitua o bloco stub:

```bash
# --- STUB (Task 4): avisos. Bootstrap = nenhum. ---
compute_warnings() {
  :
}
```

por:

```bash
# --- Avisos: RF órfão (spec cita RF fora da §6), spec intraçável, RF descoberto. ---
compute_warnings() {
  # RF órfão: RF em $RFSPEC ausente da §6.
  awk -F'\t' 'NR==FNR{ins[$1]=1; next}
    { if(!($1 in ins)) print "RF órfão: specs/" $2 " declara " $1 " (fora da seção 6 da PRD)" }' \
    "$SEC6" "$RFSPEC" | sort -u
  # Spec intraçável: sem a linha **RF cobertos:**.
  while read -r name; do
    [ -n "$name" ] && echo "Spec intraçável: specs/$name sem linha **RF cobertos:**"
  done < "$UNTRACE"
  # RF descoberto: RF in-scope na §6 sem nenhuma spec (permanece pendente).
  awk -F'\t' 'NR==FNR{cov[$1]=1; next}
    { if(!($1 in cov)) print "RF descoberto: " $1 " sem spec (permanece pendente)" }' \
    "$RFSPEC" "$SEC6" | sort -u
}
```

- [ ] **Step 4: Rodar e confirmar que passa**

Run: `bash scripts/test-trace-prd.sh`
Expected: PASS — `test-trace-prd: tudo verde`. Confirma exit 1 c/ avisos, `--check` read-only, e o caminho exit 0 da fixture `clean`.

- [ ] **Step 5: Commit**

```bash
git add scripts/trace-prd.sh scripts/test-trace-prd.sh
git commit -m "feat(trace): avisos (órfão/intraçável/descoberto) + exit codes + --check"
```

---

## Task 5: Skill `/zion-prd-trace` (9ª skill)

Wrapper fino de 5 fases sobre o script, user-invocable, rodável a qualquer momento.

**Files:**
- Create: `skills/zion-prd-trace/SKILL.md`

- [ ] **Step 1: Escrever a SKILL.md**

Create `skills/zion-prd-trace/SKILL.md`:

```markdown
---
name: zion-prd-trace
description: Reconcilia a tabela de rastreabilidade (seção 12 da PRD) a partir das specs/*/spec.md — RF↔spec e status ☐/◐/● derivados por máquina. Use para "atualizar a rastreabilidade", "reconciliar a tabela RF↔spec" ou depois de fatiar/implementar uma fatia. Rodável a qualquer momento.
argument-hint: "(sem argumento — trabalha sobre docs/PRD.md e specs/)"
metadata:
  author: zion-build-prd
user-invocable: true
disable-model-invocation: false
---

# zion-prd-trace — Rastreabilidade com mecânica (Passo 6)

Reconcilia a **seção 12** de `docs/PRD.md` (tabela `RF-xx ↔ specs/###`) a partir da §6 da PRD e das
`specs/*/spec.md`. A tabela é um **artefato derivado**, não mantido à mão: "viva" significa *"viva
enquanto você roda `/zion-prd-trace`"*. O script **reconcilia e grava**; o humano **decide**. Contrato
de 5 fases; gates aconselham.

## Fase 0 — Pré-requisito (aconselha)
`docs/PRD.md` deve existir com a **seção 6** (RF por épico) e idealmente a **seção 12**. Faltando →
avise ("recomendo `/zion-prd-write` e `/zion-prd-decompose` antes") e pergunte se segue. Não bloqueie.

## Fase 1 — Validar entrada bruta
Sem texto novo — trabalha sobre `docs/PRD.md` + `specs/`.

## Fase 2/3 — Reconciliar (roda o script)
Rode o reconciliador diretamente do `references/` da skill (autocontido):

    bash references/trace-prd.sh docs/PRD.md specs

Ele regenera RF/Descrição/Épico da §6, recomputa Feature/Spec e Status das `specs/`, **preserva** a
coluna Release, reescreve a §12 e imprime um resumo (linhas atualizadas, transições de status, avisos).
O git é o desfazer.

## Fase 4 — Validar saída (aconselha)
Ecoe o resumo e os avisos **com autoridade**, em tom advisório — não reverta:
- **RF órfão** — uma spec declara um `RF-xx` que não existe na §6: corrija o typo na spec ou registre
  a decisão perdida na PRD.
- **Spec intraçável** — um `spec.md` sem a linha `**RF cobertos:**`: adicione-a para a fatia entrar na
  cadeia (a ponte `/zion-prd-specify-prompt` já pede essa linha no prompt do specify).
- **RF descoberto** — um `RF-xx` in-scope ainda sem spec: permanece ☐ pendente (informativo).

Aponte a próxima ação: rode `/zion-prd-trace` de novo após a próxima fatia (ou use
`bash references/trace-prd.sh docs/PRD.md specs --check` em Fases 4 de outras skills / no CI para uma
leitura read-only que sai 1 se houver drift/avisos).

## Saída
A seção 12 de `docs/PRD.md` reconciliada + o resumo/avisos ecoados. **Handoff:** commit dos artefatos
(`/git-commit`), e a próxima fatia da fila segue para `/zion-prd-specify-prompt`.
```

- [ ] **Step 2: Sanidade do front-matter (nome bate com o diretório)**

Run: `grep -m1 '^name:' skills/zion-prd-trace/SKILL.md`
Expected: `name: zion-prd-trace`

- [ ] **Step 3: Commit**

```bash
git add skills/zion-prd-trace/SKILL.md
git commit -m "feat(trace): skill /zion-prd-trace (9ª skill, wrapper de 5 fases)"
```

---

## Task 6: Distribuição — asset-map + sync + check-assets

Registra `trace-prd.sh` no mapa de distribuição e propaga para o `references/` das duas skills que o consomem, sob a mesma máquina que já governa `check-prd.sh`.

**Files:**
- Modify: `scripts/asset-map.sh:13-14`

- [ ] **Step 1: Adicionar a entrada no `asset-map.sh`**

In `scripts/asset-map.sh`, substitua:

```bash
  "scripts/check-prd.sh                   zion-prd-write zion-prd-specify-prompt"
)
```

por:

```bash
  "scripts/check-prd.sh                   zion-prd-write zion-prd-specify-prompt"
  "scripts/trace-prd.sh                   zion-prd-trace zion-prd-decompose"
)
```

- [ ] **Step 2: Rodar o sync**

Run: `bash scripts/sync-assets.sh`
Expected: `sync-assets: ok`

- [ ] **Step 3: Confirmar que os references foram criados**

Run: `ls skills/zion-prd-trace/references/trace-prd.sh skills/zion-prd-decompose/references/trace-prd.sh`
Expected: ambos os caminhos listados (sem erro).

- [ ] **Step 4: Confirmar ausência de drift**

Run: `bash scripts/check-assets.sh`
Expected: `check-assets: sem drift`

- [ ] **Step 5: Commit**

```bash
git add scripts/asset-map.sh skills/zion-prd-trace/references skills/zion-prd-decompose/references
git commit -m "build(trace): distribui trace-prd.sh para zion-prd-trace e zion-prd-decompose"
```

---

## Task 7: `decompose` delega ao `trace` (dono único; corrige o H6)

`zion-prd-decompose` para de injetar a tabela à mão e passa a semear via `trace-prd.sh` (bootstrap). Um único caminho cria e atualiza a tabela → idempotente.

**Files:**
- Modify: `skills/zion-prd-decompose/SKILL.md:35-48`

- [ ] **Step 1: Reescrever a Fase 4 (item da tabela) e o Handoff**

In `skills/zion-prd-decompose/SKILL.md`, substitua o bullet da tabela na Fase 4:

```markdown
- Injete a tabela: copie `references/traceability-table.md` para a **seção 12** de
  `docs/PRD.md` e preencha uma linha por `RF-xx` in-scope (deixe Feature/Spec e Status pendentes).
Emita veredito por item. Não reverta — aconselhe.
```

por:

```markdown
- Semeie a tabela de rastreabilidade **por máquina** (não à mão): rode

      bash references/trace-prd.sh docs/PRD.md specs

  Ainda não há specs neste ponto → o bootstrap produz a tabela semente na **seção 12** (RF/Descrição/
  Épico da §6, Feature/Spec em branco, tudo ☐ pendente). `trace-prd.sh` é o **dono único** da tabela;
  rodá-lo de novo depois reconcilia em vez de duplicar. A coluna **Release** é preenchida por você/
  brainstorming após o bootstrap. Reconciliar após cada fatia é trabalho de `/zion-prd-trace`.
Emita veredito por item. Não reverta — aconselhe.
```

- [ ] **Step 2: Atualizar a linha de Saída (a tabela agora é derivada)**

In `skills/zion-prd-decompose/SKILL.md`, substitua:

```markdown
tabela de rastreabilidade dentro da PRD. **Handoff:** a próxima fatia da fila entra em
`/zion-prd-specify-prompt`.
```

por:

```markdown
tabela de rastreabilidade **semeada por `trace-prd.sh`** dentro da PRD. **Handoff:** a próxima fatia da
fila entra em `/zion-prd-specify-prompt`; após cada fatia, `/zion-prd-trace` reconcilia a tabela.
```

- [ ] **Step 3: Confirmar que a skill não menciona mais a injeção manual do template**

Run: `grep -n 'traceability-table.md' skills/zion-prd-decompose/SKILL.md`
Expected: nenhuma linha (a referência ao template foi removida da Fase 4).

- [ ] **Step 4: Confirmar ausência de drift (references intactos)**

Run: `bash scripts/check-assets.sh`
Expected: `check-assets: sem drift`

- [ ] **Step 5: Commit**

```bash
git add skills/zion-prd-decompose/SKILL.md
git commit -m "feat(trace): decompose delega a semeadura da tabela ao trace-prd.sh (H6)"
```

---

## Task 8: `specify-prompt` pede a linha `**RF cobertos:**` + regras + template

Absorve o núcleo da R4: a ponte do specify passa a pedir a linha rotulada no prompt, e as regras/template canônicos documentam a convenção. `quality-rules.md` e `traceability-table.md` são **assets canônicos** — edite em `assets/` e re-sincronize.

**Files:**
- Modify: `skills/zion-prd-specify-prompt/SKILL.md:29-33`
- Modify: `assets/quality-rules.md:75-86` (`#anatomia-specify`)
- Modify: `assets/quality-rules.md:49-51` (`#criterios-de-conclusao`, item decompose)
- Modify: `assets/templates/traceability-table.md`

- [ ] **Step 1: Pedir a linha no prompt do specify (SKILL.md)**

In `skills/zion-prd-specify-prompt/SKILL.md`, na Fase 2/3, substitua:

```markdown
- Citar `RF-xx` e ADRs relevantes como **referência** (contexto), não como requisito.
```

por:

```markdown
- Citar `RF-xx` e ADRs relevantes como **referência** (contexto), não como requisito.
- Pedir explicitamente que o `spec.md` inclua uma linha rotulada **`**RF cobertos:** RF-xx, ...`** com
  os RF que esta fatia cobre — é o elo legível por máquina que o `/zion-prd-trace` grepa para
  reconciliar a rastreabilidade. Declarar *quais* RF a fatia cobre é o-quê/rastreabilidade, não stack:
  não fere a fronteira sem-stack.
```

- [ ] **Step 2: Documentar a convenção em `#anatomia-specify` (asset canônico)**

In `assets/quality-rules.md`, na seção `## Anatomia do prompt do specify {#anatomia-specify}`, substitua:

```markdown
- **`RF-xx` e ADRs como contexto** — cite-os como referência ("Contexto: RF-01…"), não como
  requisitos a copiar.
```

por:

```markdown
- **`RF-xx` e ADRs como contexto** — cite-os como referência ("Contexto: RF-01…"), não como
  requisitos a copiar.
- **A linha `**RF cobertos:**`** — peça que o `spec.md` inclua uma linha rotulada
  `**RF cobertos:** RF-xx, ...` com os RF que a fatia cobre. É o elo forward RF↔spec legível por
  máquina: o `/zion-prd-trace` a grepa para reconciliar a tabela de rastreabilidade. Declarar *quais*
  RF a fatia cobre é o-quê/rastreabilidade, não stack — não fere a fronteira sem-stack.
```

- [ ] **Step 3: Reenquadrar o critério `decompose` em `#criterios-de-conclusao` (asset canônico)**

In `assets/quality-rules.md`, substitua:

```markdown
- **decompose**: existe backlog de fatias verticais priorizadas ∧ cada fatia passa no INVEST ∧
  walking skeleton é a fatia zero (R0) ∧ a tabela de rastreabilidade está injetada na PRD com uma
  linha por `RF-xx` in-scope.
```

por:

```markdown
- **decompose**: existe backlog de fatias verticais priorizadas ∧ cada fatia passa no INVEST ∧
  walking skeleton é a fatia zero (R0) ∧ a tabela de rastreabilidade (§12) foi **semeada por
  `trace-prd.sh`** (não à mão) com uma linha por `RF-xx` in-scope. A tabela é um artefato **derivado**,
  reconciliado a qualquer momento por `/zion-prd-trace`; não é mantida à mão.
```

- [ ] **Step 4: Marcar o template como derivado**

Replace the entire contents of `assets/templates/traceability-table.md` with:

```markdown
> Tabela de rastreabilidade `RF-xx ↔ specs/###-nome`. Uma linha por requisito funcional in-scope.
> Mantida dentro da PRD (`docs/PRD.md`, seção 12).
>
> **Artefato derivado** — regenerada por `/zion-prd-trace` (`scripts/trace-prd.sh`) a partir da §6 da
> PRD e das `specs/*/spec.md`. **Não edite Status/Feature/Spec à mão** (o `trace` os recomputa); só a
> coluna **Release** é preenchida por você e preservada entre reconciliações. Este bloco é apenas a
> forma inicial semeada pelo bootstrap.

| RF | Descrição | Épico | Feature / Spec | Release | Status |
|----|-----------|-------|----------------|---------|--------|
| RF-01 | _(o quê, em uma frase)_ | E1 | `specs/001-nome` | R0 | ☐ pendente |
| RF-02 | _…_ | E1 | `specs/002-nome` | R1 | ☐ pendente |
| RF-xx | _…_ | E_n_ | `specs/###-nome` | R_n_ | ☐ pendente |

Legenda de status: ☐ pendente · ◐ em spec · ● implementada.
```

- [ ] **Step 5: Re-sincronizar os assets derivados e checar drift**

Run: `bash scripts/sync-assets.sh && bash scripts/check-assets.sh`
Expected: `sync-assets: ok` seguido de `check-assets: sem drift`.

- [ ] **Step 6: Commit**

```bash
git add skills/zion-prd-specify-prompt/SKILL.md assets/quality-rules.md assets/templates/traceability-table.md skills/*/references
git commit -m "feat(trace): specify pede **RF cobertos:**; regras+template como artefato derivado (R4)"
```

---

## Task 9: Auto-teste do trace no CI

Adiciona o passo do auto-teste ao workflow existente, ao lado do `test-check-prd`.

**Files:**
- Modify: `.github/workflows/check-assets.yml:12-13`

- [ ] **Step 1: Adicionar o passo ao workflow**

In `.github/workflows/check-assets.yml`, substitua:

```yaml
      - name: Auto-teste do check-prd
        run: bash scripts/test-check-prd.sh
```

por:

```yaml
      - name: Auto-teste do check-prd
        run: bash scripts/test-check-prd.sh
      - name: Auto-teste do trace-prd
        run: bash scripts/test-trace-prd.sh
```

- [ ] **Step 2: Validar o YAML localmente rodando os dois testes**

Run: `bash scripts/test-check-prd.sh && bash scripts/test-trace-prd.sh`
Expected: `test-check-prd: tudo verde` seguido de `test-trace-prd: tudo verde`.

- [ ] **Step 3: Commit**

```bash
git add .github/workflows/check-assets.yml
git commit -m "ci(trace): roda scripts/test-trace-prd.sh no check-assets"
```

---

## Task 10: Docs — guia, como-usar, README (8 → 9 skills)

Reenquadra a "tabela viva" e registra a nova skill nas três superfícies de documentação.

**Files:**
- Modify: `docs/guia-prd-para-spec-kit.md` (Passo 4, Passo 6, tabela de skills, seção do modelo da tabela)
- Modify: `docs/como-usar.md:20` e a tabela de skills (linha 40-43)
- Modify: `README.md:37` (tabela de skills)

- [ ] **Step 1: Reenquadrar o Passo 6 do guia**

In `docs/guia-prd-para-spec-kit.md`, substitua o corpo do `## Passo 6` (linhas do `- **Objetivo:**` até o `- **Critério de conclusão:**`):

```markdown
- **Objetivo:** manter a ponte `RF-xx ↔ specs/###-nome` viva e confirmar, via checklist, que a feature
  está pronta para implementação.
- **Skill(s):**
  - `git-commit` (real) — versionar os artefatos-guia (PRD, ADRs, specs).
- **Invocação (exemplo)** — *você executaria assim:*
  ```text
  # Versionar os artefatos do processo:
  /git-commit
  ```
- **Entradas:** `docs/PRD.md`, `specs/###-nome/`, a tabela de rastreabilidade.
- **Saídas / artefatos:** tabela `RF-xx ↔ specs/###` atualizada (no uso real) + checklist "pronto para
  codar" confirmado.
- **Critério de conclusão:** todo `RF-xx` in-scope tem uma linha na tabela apontando para sua spec, e o
  checklist final está inteiramente marcado.
```

por:

```markdown
- **Objetivo:** manter a ponte `RF-xx ↔ specs/###-nome` **viva por máquina** e confirmar, via checklist,
  que a feature está pronta para implementação. "Viva" aqui significa *"viva enquanto você roda
  `/zion-prd-trace`"*: a tabela é um artefato **derivado**, reconciliado por comando a partir da §6 da
  PRD e das `specs/`, não mantido à mão.
- **Skill(s):**
  - `zion-prd-trace` (real) — reconcilia a seção 12 da PRD a partir das `specs/*/spec.md` (status
    ☐/◐/● derivado do `tasks.md`); rodável a qualquer momento, tipicamente após cada fatia.
  - `git-commit` (real) — versionar os artefatos-guia (PRD, ADRs, specs).
- **Invocação (exemplo)** — *você executaria assim:*
  ```text
  # Reconciliar a rastreabilidade a partir das specs:
  /zion-prd-trace
  # Versionar os artefatos do processo:
  /git-commit
  ```
- **Entradas:** `docs/PRD.md` (§6 + §12), `specs/###-nome/` (com a linha `**RF cobertos:**` e o
  `tasks.md`).
- **Saídas / artefatos:** seção 12 da PRD reconciliada por `/zion-prd-trace` + checklist "pronto para
  codar" confirmado.
- **Critério de conclusão:** `/zion-prd-trace` roda limpo (ou os avisos — RF órfão / spec intraçável —
  estão justificados), todo `RF-xx` in-scope tem sua linha na tabela, e o checklist final está marcado.
```

- [ ] **Step 2: Ajustar a Saída do Passo 4 do guia (tabela agora derivada)**

In `docs/guia-prd-para-spec-kit.md`, na seção `## Passo 4`, substitua:

```markdown
- **Saídas / artefatos:** lista de épicos, story map, **backlog de fatias verticais** com linhas de
  release, e a primeira versão da **tabela de rastreabilidade** (ainda em branco, ver modelo abaixo).
```

por:

```markdown
- **Saídas / artefatos:** lista de épicos, story map, **backlog de fatias verticais** com linhas de
  release, e a **tabela de rastreabilidade semeada por máquina** (`trace-prd.sh` em bootstrap: tudo ☐
  pendente; ver modelo abaixo). Depois, `/zion-prd-trace` a reconcilia a cada fatia.
```

- [ ] **Step 3: Adicionar a skill à tabela "Implementação das skills" do guia**

In `docs/guia-prd-para-spec-kit.md`, na tabela `## Implementação das skills`, substitua a linha:

```markdown
| `git-commit` | `/git-commit` ou "commit" | Versionar PRD, ADRs e specs (P6). |
```

por:

```markdown
| `/zion-prd-trace` | Skill tool ou o comando homônimo | **Rastreabilidade mecânica (P6)** — reconcilia a seção 12 da PRD a partir das `specs/*/spec.md` (RF↔spec + status ☐/◐/● do `tasks.md`); a tabela é derivada, não mantida à mão. |
| `git-commit` | `/git-commit` ou "commit" | Versionar PRD, ADRs e specs (P6). |
```

- [ ] **Step 4: Reenquadrar a seção "Modelo de tabela de rastreabilidade" do guia**

In `docs/guia-prd-para-spec-kit.md`, substitua:

```markdown
A tabela vive agora em **`assets/templates/traceability-table.md`** (dono único). O comando
`/zion-prd-decompose` a injeta na seção 12 da PRD no Passo 4. Preencha uma linha por requisito funcional
in-scope quando **você** executar o processo.
```

por:

```markdown
A tabela é um **artefato derivado**: `/zion-prd-decompose` a **semeia** por máquina (rodando
`trace-prd.sh` em bootstrap) na seção 12 da PRD no Passo 4, e `/zion-prd-trace` a **reconcilia** a
qualquer momento a partir da §6 e das `specs/`. O template em `assets/templates/traceability-table.md`
é só a forma inicial. **Não edite Status/Feature/Spec à mão** — o `trace` os recomputa; só a coluna
**Release** você preenche (ela é preservada entre reconciliações).
```

- [ ] **Step 5: Atualizar `docs/como-usar.md` (contagem + tabela + fluxo)**

In `docs/como-usar.md`, substitua:

```markdown
Isso instala as 8 skills em `.claude/skills/` do seu projeto.
```

por:

```markdown
Isso instala as 9 skills em `.claude/skills/` do seu projeto.
```

In `docs/como-usar.md`, na tabela de skills, substitua a linha do `plan-prompt`:

```markdown
| `/zion-prd-plan-prompt` | Ponte p/ 5c | `spec.md` da feature + `docs/adr/` | prompt do `/speckit.plan` | *(monta em prosa; sem delegação)* |
```

por:

```markdown
| `/zion-prd-plan-prompt` | Ponte p/ 5c | `spec.md` da feature + `docs/adr/` | prompt do `/speckit.plan` | *(monta em prosa; sem delegação)* |
| `/zion-prd-trace` | 6 · Rastreabilidade | `docs/PRD.md` (§6+§12) + `specs/` | seção 12 reconciliada | `scripts/trace-prd.sh` |
```

In `docs/como-usar.md`, no diagrama mermaid do fluxo, substitua:

```markdown
    E --> P["/zion-prd-plan-prompt"]
```

por:

```markdown
    E --> P["/zion-prd-plan-prompt"]
    D --> T["/zion-prd-trace"]
    P --> T
```

- [ ] **Step 6: Atualizar a tabela de skills do `README.md`**

In `README.md`, substitua a linha:

```markdown
| `/zion-prd-plan-prompt` | Ponte → `/speckit.plan` |
```

por:

```markdown
| `/zion-prd-plan-prompt` | Ponte → `/speckit.plan` |
| `/zion-prd-trace` | Reconcilia a rastreabilidade (seção 12) a partir das specs |
```

- [ ] **Step 7: Verificar que não sobrou "8 skills" e que o repo está consistente**

Run: `grep -rn '8 skills\|as 8 ' README.md docs/como-usar.md docs/guia-prd-para-spec-kit.md; bash scripts/check-assets.sh`
Expected: nenhuma ocorrência de "8 skills"; `check-assets: sem drift`.

- [ ] **Step 8: Commit**

```bash
git add README.md docs/como-usar.md docs/guia-prd-para-spec-kit.md
git commit -m "docs(trace): registra /zion-prd-trace; tabela viva reenquadrada (8→9 skills)"
```

---

## Self-Review

**1. Spec coverage** (cada seção do design → task):

- §3.1 construir a mecânica → Tasks 2–4 (script) + Task 5 (skill).
- §3.2 specs são a fonte / tabela derivada → Tasks 2–3 (parse §6 + scan specs) + Task 8 (template/regras).
- §3.3 status em 3 estados via `tasks.md` → Task 3 (`spec_status`, `status_for_rf`).
- §3.4 conciliação in-place + Release preservada + idempotente → Task 2 (`table_col`/`release_for_rf`/`write_section12`) + Task 3 (teste de idempotência).
- §3.5 convenção `**RF cobertos:**` → Task 3 (grep) + Task 8 (pedir no prompt).
- §3.6 `trace` dono único; `decompose` semeia → Task 7.
- §3.7 escrita in-place + `--check` → Task 2 (`run_check`).
- §4 convenção RF↔spec (R4) → Task 8.
- §5.1 interface → Task 2 (arg parsing). §5.2 fontes por coluna → Tasks 2–3. §5.3 status → Task 3. §5.4 modos/saída → Task 2. §5.5 avisos → Task 4. §5.6 contrato de saída (exit 0/1/2) → Tasks 2 (exit 2, resumo) + 4 (exit 1 c/ avisos).
- §6 skill 5 fases → Task 5.
- §7 decompose delega + sync p/ ambas as skills → Task 6 (sync) + Task 7 (delegação).
- §8 distribuição (asset-map/sync/check) → Task 6.
- §9 auto-teste + fixtures + CI → Task 1 (fixtures) + Tasks 2–4 (testes) + Task 9 (CI).
- §10 superfície de mudança → coberta task a task. §11 fora de escopo → respeitado (sem hook no consumidor, sem FR-interno, sem git-merge).

**2. Placeholder scan:** todos os passos de código trazem o conteúdo real (script completo na Task 2; funções completas nas substituições das Tasks 3–4; SKILL.md completa na Task 5; blocos de doc completos na Task 10). Os "STUBS" das Tasks 2→3/4 são o padrão TDD (implementação mínima primeiro, estendida depois) e são substituídos por código completo em tasks nomeadas — não são placeholders abertos.

**3. Type/name consistency:** nomes de função estáveis entre tasks — `parse_section6`, `table_col`, `scan_specs`, `spec_status`, `specs_for_rf`, `status_for_rf`, `release_for_rf`, `build_table`, `write_section12`, `run_check`, `compute_warnings`. Temporários globais (`SEC6`, `RFSPEC`, `UNTRACE`, `SPECSTATUS`, `OLDREL`, `OLDSTATUS`, `TAB`) definidos na Task 2 e usados coerentemente. Glifos `☐ pendente` / `◐ em spec` / `● implementada` idênticos em script, fixtures, testes e docs. A entrada do `asset-map.sh` (`zion-prd-trace zion-prd-decompose`) casa com os dois `references/` esperados na Task 6 e com o consumo em Tasks 5 e 7.
```
