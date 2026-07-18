# Integração instalável com o Spec Kit — Plano de implementação

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implementar a alternativa A3 do design `docs/superpowers/specs/2026-07-18-integracao-speckit-instalavel-design.md`: skill instaladora `zion-speckit-install` (regras no `CLAUDE.md` do produto + `architecture.md` semeado + guard opt-in), dois scripts novos (`check-arquitetura.sh`, `trace-arquitetura.sh`) com auto-testes, dois templates novos no `ASSET_MAP`, extensões em `zion-prd-trace` e `zion-prd-plan-prompt`, ADR-015 e canonização completa.

**Architecture:** O harness não tem runtime — toda lógica nova é prosa de `SKILL.md` + verificadores shell no contrato comum (exit 0 limpo · 1 achados · 2 erro de uso). Os scripts novos seguem o molde de `trace-backlog.sh`/`check-experiencia.sh` (awk POSIX, `set -u`, fixtures limpa/suja). A distribuição é por cópia real via `ASSET_MAP` + `sync-assets.sh` (ADR-001/002).

**Tech Stack:** Bash + awk POSIX (sem dependência nova — NFR-02), Markdown.

## Global Constraints

Copiadas do spec e das regras do repo — valem para TODAS as tasks:

- **Idioma:** todo artefato em pt-BR, no idioma dos vizinhos (comentários de script inclusive).
- **Canonização no mesmo commit:** o pre-commit roda `sync-assets.sh` + `check-canon.sh` + `check-adr.sh docs/adr` e **BLOQUEIA** commit com drift. Cada task já inclui as edições de `docs/prd.md` / `docs/architecture.md` que o seu commit exige. Nunca dividir uma task em dois commits.
- **Nunca** editar `skills/*/references/` à mão — o pre-commit regenera via `scripts/sync-assets.sh` e auto-stageia.
- **Contrato de exit dos verificadores:** `0` limpo · `1` achados · `2` erro de uso/ambiente. No projeto-alvo o veredito **aconselha** (RN-01, NFR-05, ADR-004) — só o guard opt-in bloqueia, por escolha do Autor.
- **Marcadores exatos** (linha inteira, byte a byte):
  - Bloco de regras: `<!-- zion:speckit:v1:start -->` / `<!-- zion:speckit:v1:end -->`
  - Índice de ADRs: `<!-- zion:adr-index:start -->` / `<!-- zion:adr-index:end -->`
  - Visão do backlog: `<!-- zion:backlog-view:start -->` / `<!-- zion:backlog-view:end -->`
- **Gramática do elo (confirmada contra o parser, condição do spec):** `scripts/trace-prd.sh` linha 96 lê `grep -iE 'RF cobertos:'` e extrai `RF-[0-9]+`. A gramática formalizada na regra instalada é portanto a linha `**RF cobertos:** RF-xx` — **não** criar formato novo (`**Elo:**` etc.).
- **Versão do bloco:** `EXPECTED_VERSION="v1"` hardcoded em `check-arquitetura.sh` DEVE ser igual à versão dos marcadores de `assets/templates/regras-speckit.md`. Mudar um exige mudar o outro (comentário no script avisa).
- **NFR-01:** `./scripts/eval.sh` completo em < 60 s. **NFR-04:** todo verificador novo com auto-teste fixture limpa + suja. **NFR-03:** zero drift fonte→derivado.
- **Fronteira nos docs:** `docs/prd.md` sem stack (o `check-canon` roda `check-prd.sh prd docs/prd.md` como dogfood); mecânica em `docs/architecture.md`.
- Scripts de verificação usam `set -u` (não `-e` — os exits são parte do contrato).
- Mensagens de commit terminam com a linha `Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>`.

## Estrutura de arquivos (visão do todo)

| Arquivo | Ação | Task |
|---|---|---|
| `docs/adr/ADR-015-integracao-speckit-instalavel.md` | criar | 1 |
| `docs/architecture.md` | modificar (§2, §3, §4, §6) | 1, 2, 3, 4, 5 |
| `scripts/trace-arquitetura.sh` | criar | 2 |
| `scripts/test-trace-arquitetura.sh` + `scripts/fixtures/arquitetura/trace/` | criar | 2 |
| `scripts/check-arquitetura.sh` | criar | 3 |
| `scripts/test-check-arquitetura.sh` + `scripts/fixtures/arquitetura/{clean,dirty}/` | criar | 3 |
| `scripts/eval.sh` | modificar | 2, 3 |
| `docs/prd.md` | modificar (§6, §12, §13) | 3, 5, 6, 7 |
| `assets/templates/regras-speckit.md` | criar | 4 |
| `assets/templates/architecture-skeleton.md` | criar | 4 |
| `skills/zion-speckit-install/SKILL.md` | criar | 5 |
| `scripts/asset-map.sh` | modificar | 5 |
| `skills/zion-prd-trace/SKILL.md` | modificar | 6 |
| `skills/zion-prd-plan-prompt/SKILL.md` | modificar | 7 |

---

### Task 1: ADR-015 + índice

**Files:**
- Create: `docs/adr/ADR-015-integracao-speckit-instalavel.md`
- Modify: `docs/architecture.md` (§2, tabela de ADRs — após a linha do ADR-014)
- Commit também: `docs/estudos/integracao-speckit-fonte-canonica.md` (já existe no disco, untracked — é a Evidência do ADR)

**Interfaces:**
- Consumes: nada.
- Produces: `ADR-015` existente em `docs/adr/` — as linhas de changelog (§13 da PRD) das Tasks 3/5/6/7 o citam, e `check-prd.sh` valida que todo ADR citado no changelog existe no disco. Esta task vem PRIMEIRO por isso.

- [ ] **Step 1: Criar o ADR-015**

Criar `docs/adr/ADR-015-integracao-speckit-instalavel.md` com exatamente:

```markdown
# ADR-015 — Integração instalável com o Spec Kit e architecture.md distribuído

- **Status:** Aceito
- **Data:** 2026-07-18
- **Decisores:** autoria do repo
- **Evidência:** Decisão dada: o Autor escolheu a alternativa A3 no estudo `docs/estudos/integracao-speckit-fonte-canonica.md` (ADR-006, evidência por decisão dada); o design que a formaliza é `docs/superpowers/specs/2026-07-18-integracao-speckit-instalavel-design.md`.

## Contexto

O canon do produto (`docs/prd.md`, `docs/adr/`, backlog) chega ao Spec Kit apenas pelas três
pontes manuais (RF-06/07/08): clarify e implement rodam sem canon, spec nascida fora do fluxo só
aparece quando o Autor lembra do trace, e o reconhecimento canônico depende de colar prompt. Além
disso o Autor definiu (edge 18 do estudo) que sente falta de prosa estrutural com autoridade
própria — um documento de arquitetura do produto que os ADRs pontuais, a constitution e o plan por
feature não acomodam.

## Decisão

Uma skill instaladora idempotente (`zion-speckit-install`) configura o repositório do produto.
Quatro pontos fechados:

1. **Superfície** — a regra mora só no `CLAUDE.md` do produto (agente único, Claude Code), entre
   marcadores versionados `<!-- zion:speckit:v1:start/end -->`; re-rodar substitui só o bloco
   marcado. Nada de patch nos templates de comando do Spec Kit (A4, rejeitada no estudo).
2. **Marcador de origem** — o elo de rastreabilidade formalizado é a linha `**RF cobertos:** RF-xx`
   que o parser de `trace-prd.sh` já reconhece; elo ausente = spec acusada como intraçável pelo
   trace (mecanismo RF-09 existente). Dever de origem advisório — conselho, nunca trava (RN-01,
   ADR-004 não superseded).
3. **architecture.md distribuído** — semeado de `assets/templates/architecture-skeleton.md`
   (análogo ao prd-skeleton, ADR-002): prosa do Autor (§1–§2) nunca tocada por máquina + dois
   blocos derivados (§3 índice de ADRs, §4 visão do backlog) reconciliados só pelo ritual do trace
   (RN-04, zero automação instalada — ADR-005 preservado). Autoridade **advisória** sustentada por
   `check-arquitetura.sh` (padrão E5), com guard de pre-commit **opt-in** — o ADR-010 exportado por
   escolha do Autor; default é não instalar.
4. **Fronteira de donos** — constitution: princípios de repo inteiro; ADRs: decisões pontuais de
   repo inteiro; architecture.md: estrutura e prosa do Autor + índices derivados; plan: o como por
   feature. Um dono por pergunta. Recorte por passo: specify/clarify leem PRD e backlog; plan lê
   ADRs + architecture.md; implement lê plan + constitution.

As pontes RF-06/07/08 seguem como caminho rico (curam o recorte por passo); a regra instalada é a
rede de segurança quando o Autor pula a ponte.

## Consequências

O harness ganha dois scripts distribuídos (`check-arquitetura.sh`, `trace-arquitetura.sh`) com
auto-testes e fixtures pareadas (NFR-04, dentro do orçamento do NFR-01), dois templates novos no
ASSET_MAP e uma skill a mais para manter. O ritual do trace passa a reconciliar também os blocos
derivados do documento; a ponte do plan injeta a prosa estrutural ao lado dos ADRs — specify e
clarify nunca recebem o documento (RN-02). Upgrade do harness que mude o bloco de regras é acusado
por versão de marcador (`regras-defasadas`), resolvido re-rodando a instalação. Cobertura
multi-agente da regra fica fora de escopo (ampliável depois sem quebrar nada).

## Status

Aceito.
```

- [ ] **Step 2: Indexar no architecture.md (§2)**

Em `docs/architecture.md`, após a linha da tabela §2 que começa com `| [ADR-014]`, inserir:

```markdown
| [ADR-015](adr/ADR-015-integracao-speckit-instalavel.md) | Integração instalável com o Spec Kit: regras versionadas no `CLAUDE.md` do produto, `architecture.md` distribuído (prosa do Autor + blocos derivados) e autoridade advisória com guard opt-in. |
```

- [ ] **Step 3: Verificar os guards**

Rodar: `bash scripts/check-adr.sh docs/adr && bash scripts/check-canon.sh`
Esperado: `check-adr: limpo` (ou equivalente sem achados) e `check-canon: limpo`.

- [ ] **Step 4: Commit**

```bash
git add docs/adr/ADR-015-integracao-speckit-instalavel.md docs/architecture.md docs/estudos/integracao-speckit-fonte-canonica.md
git commit -m "docs(adr): ADR-015 — integração instalável com o Spec Kit

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 2: `trace-arquitetura.sh` (TDD)

**Files:**
- Create: `scripts/trace-arquitetura.sh`
- Create: `scripts/test-trace-arquitetura.sh`
- Create: `scripts/fixtures/arquitetura/trace/architecture.md`, `scripts/fixtures/arquitetura/trace/sem-marcadores.md`, `scripts/fixtures/arquitetura/trace/adr/ADR-001-banco-unico.md`, `scripts/fixtures/arquitetura/trace/adr/ADR-002-fila-simples.md`, `scripts/fixtures/arquitetura/trace/backlog.md`
- Modify: `scripts/eval.sh`
- Modify: `docs/architecture.md` (§3, tabela de scripts)

**Interfaces:**
- Consumes: nada das tasks anteriores.
- Produces: CLI `trace-arquitetura.sh <arquitetura> <adr-dir> <backlog-file> [--check]` — exit 0/1/2 no contrato comum. Regenera SÓ o conteúdo entre `<!-- zion:adr-index:start/end -->` e `<!-- zion:backlog-view:start/end -->`. Formato gerado (as Tasks 3, 5 e 6 dependem dele):
  - Índice: `- [<título do primeiro "# ">](<basename do adr-dir>/<basename do arquivo>)` por ADR; sem ADRs → `_(nenhum ADR ainda)_`.
  - Visão: `- ` + backtick + slug + backtick + ` — <status>` por linha da primeira tabela do backlog; backlog ausente → `_(sem backlog ainda)_`.

- [ ] **Step 1: Criar as fixtures**

`scripts/fixtures/arquitetura/trace/architecture.md`:

```markdown
# Arquitetura — Produto de Teste

> Fonte da verdade do como/com-quê deste produto (fixture).

## 1. Visão geral

Um serviço que recebe pedidos e os grava.

## 2. Integrações externas

Nenhuma por enquanto.

## 3. Decisões estruturantes

<!-- zion:adr-index:start -->
_(conteúdo velho a ser substituído)_
<!-- zion:adr-index:end -->

## 4. Visão do backlog

<!-- zion:backlog-view:start -->
_(conteúdo velho a ser substituído)_
<!-- zion:backlog-view:end -->

## 5. Notas do Autor

Prosa que o reconciliador nunca toca.
```

`scripts/fixtures/arquitetura/trace/sem-marcadores.md`:

```markdown
# Arquitetura — Produto de Teste

## 1. Visão geral

Documento antigo, sem os marcadores dos blocos derivados.
```

`scripts/fixtures/arquitetura/trace/adr/ADR-001-banco-unico.md`:

```markdown
# ADR-001 — Banco único

- **Status:** Aceito
- **Data:** 2026-07-18
- **Evidência:** Decisão dada: racional registrado (fixture).

## Contexto

Fixture de teste.

## Decisão

Um banco único.

## Consequências

Nenhuma.
```

`scripts/fixtures/arquitetura/trace/adr/ADR-002-fila-simples.md`:

```markdown
# ADR-002 — Fila simples

- **Status:** Aceito
- **Data:** 2026-07-18
- **Evidência:** Decisão dada: racional registrado (fixture).

## Contexto

Fixture de teste.

## Decisão

Uma fila simples.

## Consequências

Nenhuma.
```

`scripts/fixtures/arquitetura/trace/backlog.md`:

```markdown
> Backlog de specs — fixture.

| Spec (slug) | Demo (1 frase) | RFs | Release | Pasta | Status |
|-------------|----------------|-----|---------|-------|--------|
| walking-skeleton | demo mínima ponta a ponta | RF-01 | R0 | `specs/001-walking-skeleton` | ● implementada |
| historico | ver histórico de pedidos | RF-02 | R1 | — | ☐ pendente |
```

- [ ] **Step 2: Escrever o auto-teste (falhando)**

Criar `scripts/test-trace-arquitetura.sh`:

```bash
#!/usr/bin/env bash
# Auto-teste do trace-arquitetura.sh contra fixtures (NFR-04). Roda pela camada mecânica (scripts/eval.sh).
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
TRACE="scripts/trace-arquitetura.sh"
FIX="scripts/fixtures/arquitetura/trace"
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
assert_file_not_re() {  # desc  arquivo  regex_estendida
  if grep -Eq -- "$3" "$2"; then echo "FALHOU: $1 (regex casou indevido: $3)"; fail=1
  else echo "ok: $1"; fi
}
fresh() {  # copia a fixture $1 para um temp e ecoa o caminho
  local t; t="$(mktemp)"; cp "$1" "$t"; printf '%s' "$t"
}

# 1. Reconciliação: blocos regenerados, prosa intacta.
arch="$(fresh "$FIX/architecture.md")"
out="$(bash "$TRACE" "$arch" "$FIX/adr" "$FIX/backlog.md")"; rc=$?
assert_exit "reconciliação sai 0" 0 "$rc"
assert_file_re "índice ganha ADR-001" "$arch" 'ADR-001-banco-unico\.md'
assert_file_re "índice ganha ADR-002" "$arch" 'ADR-002-fila-simples\.md'
assert_file_re "índice usa o título do ADR" "$arch" 'Banco único'
assert_file_re "visão ganha walking-skeleton com status" "$arch" 'walking-skeleton.*implementada'
assert_file_re "visão ganha historico pendente" "$arch" 'historico.*pendente'
assert_file_re "prosa do Autor preservada" "$arch" 'Prosa que o reconciliador nunca toca'
assert_file_not_re "conteúdo velho dos blocos substituído" "$arch" 'conteúdo velho'

# 2. Idempotência: rodar de novo não muda o arquivo.
cp "$arch" "$arch.bak"
bash "$TRACE" "$arch" "$FIX/adr" "$FIX/backlog.md" >/dev/null 2>&1
if diff -q "$arch" "$arch.bak" >/dev/null 2>&1; then echo "ok: reconciliação idempotente"
else echo "FALHOU: reconciliação não é idempotente"; fail=1; fi

# 3. --check em dia após reconciliar.
out="$(bash "$TRACE" "$arch" "$FIX/adr" "$FIX/backlog.md" --check)"; rc=$?
assert_exit "--check em dia sai 0" 0 "$rc"
assert_contains "--check diz em dia" "em dia" "$out"
rm -f "$arch" "$arch.bak"

# 4. --check com drift é read-only e sai 1.
arch="$(fresh "$FIX/architecture.md")"; cp "$arch" "$arch.bak"
out="$(bash "$TRACE" "$arch" "$FIX/adr" "$FIX/backlog.md" --check)"; rc=$?
assert_exit "--check com drift sai 1" 1 "$rc"
if diff -q "$arch" "$arch.bak" >/dev/null 2>&1; then echo "ok: --check não escreve"
else echo "FALHOU: --check escreveu no arquivo"; fail=1; fi
rm -f "$arch" "$arch.bak"

# 5. Backlog ausente → semeia "(sem backlog ainda)" e sai 0.
arch="$(fresh "$FIX/architecture.md")"
out="$(bash "$TRACE" "$arch" "$FIX/adr" "$FIX/nao-existe.md")"; rc=$?
assert_exit "backlog ausente sai 0" 0 "$rc"
assert_file_re "backlog ausente semeia o bloco" "$arch" 'sem backlog ainda'
rm -f "$arch"

# 6. Sem ADRs → índice "(nenhum ADR ainda)".
arch="$(fresh "$FIX/architecture.md")"
bash "$TRACE" "$arch" "$FIX/nao-existe" "$FIX/backlog.md" >/dev/null 2>&1
assert_file_re "sem ADRs semeia nenhum ADR ainda" "$arch" 'nenhum ADR ainda'
rm -f "$arch"

# 7. Marcadores ausentes → aviso, exit 1, arquivo intacto.
arch="$(fresh "$FIX/sem-marcadores.md")"; cp "$arch" "$arch.bak"
out="$(bash "$TRACE" "$arch" "$FIX/adr" "$FIX/backlog.md")"; rc=$?
assert_exit "sem marcadores sai 1" 1 "$rc"
assert_contains "avisa marcador ausente" "Marcador ausente" "$out"
if diff -q "$arch" "$arch.bak" >/dev/null 2>&1; then echo "ok: sem marcadores não toca o arquivo"
else echo "FALHOU: escreveu num arquivo sem marcadores"; fail=1; fi
rm -f "$arch" "$arch.bak"

# 8. Arquitetura inexistente → exit 2.
out="$(bash "$TRACE" nao/existe.md "$FIX/adr" "$FIX/backlog.md" 2>&1)"; rc=$?
assert_exit "arquitetura inexistente sai 2" 2 "$rc"

# 9. Sem argumentos → exit 2.
out="$(bash "$TRACE" 2>/dev/null)"; rc=$?
assert_exit "sem argumentos sai 2" 2 "$rc"

if [ "$fail" -eq 0 ]; then echo "test-trace-arquitetura: tudo verde"; else echo "test-trace-arquitetura: FALHOU"; exit 1; fi
```

- [ ] **Step 3: Rodar o teste e ver falhar**

Rodar: `bash scripts/test-trace-arquitetura.sh`
Esperado: várias linhas `FALHOU:` (o script `scripts/trace-arquitetura.sh` não existe) e exit ≠ 0.

- [ ] **Step 4: Implementar o script**

Criar `scripts/trace-arquitetura.sh`:

```bash
#!/usr/bin/env bash
# trace-arquitetura.sh — reconciliador dos blocos derivados do architecture.md do PRODUTO (ADR-015).
# Regenera SÓ o conteúdo entre os marcadores zion:adr-index (§3) e zion:backlog-view (§4);
# a prosa do Autor nunca é tocada. ESCREVE (git é o desfazer); --check é read-only.
#
# Uso:
#   trace-arquitetura.sh <arquitetura> <adr-dir> <backlog-file> [--check]
#     <adr-dir> sem ADRs     → índice "_(nenhum ADR ainda)_".
#     <backlog-file> ausente → visão "_(sem backlog ainda)_".
#     --check → não grava; reporta drift/avisos e sai 1.
#
# Exit: 0 (limpo) · 1 (drift/avisos) · 2 (erro de uso/ambiente).
set -u

usage() { echo "uso: trace-arquitetura.sh <arquitetura> <adr-dir> <backlog-file> [--check]" >&2; exit 2; }

ARCH=""; ADR_DIR=""; BACKLOG=""; MODE_CHECK=0
for a in "$@"; do
  case "$a" in
    --check) MODE_CHECK=1 ;;
    -*) usage ;;
    *) if [ -z "$ARCH" ]; then ARCH="$a"
       elif [ -z "$ADR_DIR" ]; then ADR_DIR="$a"
       elif [ -z "$BACKLOG" ]; then BACKLOG="$a"
       else usage; fi ;;
  esac
done
[ -n "$ARCH" ] && [ -n "$ADR_DIR" ] && [ -n "$BACKLOG" ] || usage
[ -f "$ARCH" ] || { echo "trace-arquitetura: arquivo não encontrado: $ARCH" >&2; exit 2; }

# --- Índice de ADRs: uma linha por <adr-dir>/ADR-*.md, título do primeiro "# ". ---
build_adr_index() {
  local f title found=0
  for f in "$ADR_DIR"/ADR-*.md; do
    [ -f "$f" ] || continue
    found=1
    title="$(sed -n '/^# /{s/^# //;p;q;}' "$f")"
    [ -n "$title" ] || title="$(basename "$f" .md)"
    printf -- '- [%s](%s/%s)\n' "$title" "$(basename "$ADR_DIR")" "$(basename "$f")"
  done
  [ "$found" -eq 1 ] || printf -- '_(nenhum ADR ainda)_\n'
}

# --- Visão do backlog: slug + status da PRIMEIRA tabela do backlog (a canônica). ---
build_backlog_view() {
  if [ ! -f "$BACKLOG" ]; then printf -- '_(sem backlog ainda)_\n'; return; fi
  awk '
    function trim(s){ gsub(/^[[:space:]]+|[[:space:]]+$/,"",s); return s }
    function lc(s){ return tolower(s) }
    done { next }
    /^[[:space:]]*\|/ {
      line=$0; sub(/^[[:space:]]*\|/,"",line); sub(/\|[[:space:]]*$/,"",line)
      nc=split(line, c, /\|/)
      for(i=1;i<=nc;i++) c[i]=trim(c[i])
      if (!intab) {
        for(i=1;i<=nc;i++){ h=lc(c[i]); if (index(h,"slug")) scol=i; else if (index(h,"status")) stcol=i }
        ok=(scol && stcol); intab=1; next
      }
      if (c[1] ~ /^[-:]+$/) next
      if (ok && c[scol] != "") { printf "- `%s` — %s\n", c[scol], c[stcol]; n++ }
      next
    }
    intab { done=1 }
    END { if (!n) print "_(sem specs no backlog ainda)_" }
  ' "$BACKLOG"
}

# --- Substitui o conteúdo entre os marcadores de UM bloco; o resto passa intacto. ---
replace_block() {  # $1 arquivo  $2 nome-do-bloco  $3 arquivo-com-conteudo → stdout
  awk -v start="<!-- zion:$2:start -->" -v end="<!-- zion:$2:end -->" -v cf="$3" '
    $0==start { print; while ((getline l < cf) > 0) print l; skip=1; next }
    $0==end   { skip=0 }
    skip { next }
    { print }
  ' "$1"
}

# --- Orquestração ---
warnings=""
add_warning() { if [ -z "$warnings" ]; then warnings="$1"; else warnings="$warnings
$1"; fi; }

TMPA="$(mktemp)"; TMPB="$(mktemp)"; NEW="$(mktemp)"; CUR="$(mktemp)"
cleanup() { rm -f "$TMPA" "$TMPB" "$NEW" "$CUR" 2>/dev/null; }
trap cleanup EXIT

build_adr_index    > "$TMPA"
build_backlog_view > "$TMPB"

cp "$ARCH" "$CUR"
for pair in "adr-index:$TMPA" "backlog-view:$TMPB"; do
  name="${pair%%:*}"; cf="${pair#*:}"
  if grep -qF "<!-- zion:$name:start -->" "$CUR" && grep -qF "<!-- zion:$name:end -->" "$CUR"; then
    replace_block "$CUR" "$name" "$cf" > "$NEW"
    cp "$NEW" "$CUR"
  else
    add_warning "Marcador ausente: bloco zion:$name sem <!-- zion:$name:start/end --> em $ARCH (bloco não reconciliado; restaure os marcadores do esqueleto)"
  fi
done

wcount=0; [ -n "$warnings" ] && wcount="$(printf '%s\n' "$warnings" | grep -c .)"

if [ "$MODE_CHECK" = "1" ]; then
  drift=""
  if ! diff -q "$ARCH" "$CUR" >/dev/null 2>&1; then
    echo "trace-arquitetura: drift nos blocos derivados (rode sem --check para reconciliar):"
    diff "$ARCH" "$CUR" || true
    drift=1
  fi
  [ -n "$warnings" ] && printf '%s\n' "$warnings"
  if [ -n "$drift" ] || [ "$wcount" -gt 0 ]; then echo "trace-arquitetura: fora de dia"; exit 1; fi
  echo "trace-arquitetura: em dia"; exit 0
fi

changed=0
if ! diff -q "$ARCH" "$CUR" >/dev/null 2>&1; then
  cp "$CUR" "$ARCH"; changed=1
fi
[ -n "$warnings" ] && printf '%s\n' "$warnings"
if [ "$changed" -eq 0 ] && [ "$wcount" -eq 0 ]; then
  echo "trace-arquitetura: em dia"; exit 0
fi
[ "$changed" -eq 1 ] && echo "trace-arquitetura: blocos derivados reconciliados"
if [ "$wcount" -gt 0 ]; then echo "trace-arquitetura: $wcount aviso(s)"; exit 1; fi
exit 0
```

Depois: `chmod +x scripts/trace-arquitetura.sh`

- [ ] **Step 5: Rodar o teste e ver passar**

Rodar: `bash scripts/test-trace-arquitetura.sh`
Esperado: todas as linhas `ok:` e a final `test-trace-arquitetura: tudo verde`, exit 0.

- [ ] **Step 6: Agregar no eval.sh**

Em `scripts/eval.sh`, na `declare -A TESTS=(`, após a linha `[backlog]="scripts/test-trace-backlog.sh"`, inserir:

```bash
  [trace-arquitetura]="scripts/test-trace-arquitetura.sh"
```

Trocar a linha `ORDER=(prd estudo experiencia adr trace backlog contract canon)` por:

```bash
ORDER=(prd estudo experiencia adr trace backlog trace-arquitetura contract canon)
```

Trocar o padrão do `case "$sel" in` de `prd|estudo|experiencia|adr|trace|backlog|contract|canon) ORDER=("$sel") ;;` por:

```bash
    prd|estudo|experiencia|adr|trace|backlog|trace-arquitetura|contract|canon) ORDER=("$sel") ;;
```

e a mensagem de uso correspondente por:

```bash
    *) echo "uso: eval.sh [prd|estudo|experiencia|adr|trace|backlog|trace-arquitetura|contract|canon]" >&2; exit 2 ;;
```

Rodar: `bash scripts/eval.sh trace-arquitetura` → esperado `tudo verde`.

- [ ] **Step 7: Canonizar (§3 do architecture.md)**

Em `docs/architecture.md`, tabela da §3, após a linha de `scripts/trace-backlog.sh`, inserir:

```markdown
| scripts/trace-arquitetura.sh | Semeia/reconcilia os blocos derivados (índice de ADRs, visão do backlog) do architecture.md do produto. |
```

e, após a linha de `scripts/test-trace-backlog.sh`, inserir:

```markdown
| scripts/test-trace-arquitetura.sh | Auto-teste do trace-arquitetura.sh contra fixtures. |
```

- [ ] **Step 8: Commit**

```bash
git add scripts/trace-arquitetura.sh scripts/test-trace-arquitetura.sh scripts/fixtures/arquitetura scripts/eval.sh docs/architecture.md
git commit -m "feat(trace): reconciliador dos blocos derivados do architecture.md do produto

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

(O pre-commit roda `check-canon.sh` — deve passar porque a §3 já cita os dois scripts.)

---

### Task 3: `check-arquitetura.sh` (TDD) + RF-11

**Files:**
- Create: `scripts/check-arquitetura.sh`
- Create: `scripts/test-check-arquitetura.sh`
- Create: fixtures `scripts/fixtures/arquitetura/clean/` e `scripts/fixtures/arquitetura/dirty/` (cada uma é a RAIZ de um repo de produto fake)
- Modify: `scripts/eval.sh`
- Modify: `docs/architecture.md` (§3)
- Modify: `docs/prd.md` (§6 RF-11, §12 linha RF-11, §13 changelog)

**Interfaces:**
- Consumes: os formatos gerados pela Task 2 (linha de índice `- [título](adr/arquivo.md)`; linha de visão `- ` + backtick + slug + backtick + ` — status`) e os marcadores globais.
- Produces: CLI `check-arquitetura.sh [ROOT]` (default `.`) — olha `ROOT/docs/architecture.md`, `ROOT/docs/adr/`, `ROOT/docs/backlog.md`, `ROOT/CLAUDE.md`. Exit 0/1/2. Achados nomeados (as skills das Tasks 5/6 ecoam esses nomes): `arquitetura-ausente`, `secao-ausente`, `visao-vazia`, `adr-index-defasado`, `backlog-view-defasada`, `regras-ausentes`, `regras-defasadas`. Constante `EXPECTED_VERSION="v1"`.

- [ ] **Step 1: Criar a fixture limpa**

`scripts/fixtures/arquitetura/clean/CLAUDE.md`:

```markdown
# Regras do produto (fixture)

Prosa do Autor fora do bloco — nunca tocada pela instalação.

<!-- zion:speckit:v1:start -->
Regras instaladas (conteúdo de fixture; a versão no marcador é o que o check compara).
<!-- zion:speckit:v1:end -->
```

`scripts/fixtures/arquitetura/clean/docs/architecture.md`:

```markdown
# Arquitetura — Produto Fixture

> Fonte da verdade do como/com-quê deste produto (fixture limpa).

## 1. Visão geral

Um serviço que recebe pedidos e os grava.

## 2. Integrações externas

Nenhuma por enquanto.

## 3. Decisões estruturantes

<!-- zion:adr-index:start -->
- [ADR-001 — Banco único](adr/ADR-001-banco-unico.md)
<!-- zion:adr-index:end -->

## 4. Visão do backlog

<!-- zion:backlog-view:start -->
- `walking-skeleton` — ☐ pendente
<!-- zion:backlog-view:end -->
```

`scripts/fixtures/arquitetura/clean/docs/adr/ADR-001-banco-unico.md`: mesmo conteúdo do `ADR-001-banco-unico.md` da Task 2 (copie o arquivo).

`scripts/fixtures/arquitetura/clean/docs/backlog.md`:

```markdown
| Spec (slug) | Demo (1 frase) | RFs | Release | Pasta | Status |
|-------------|----------------|-----|---------|-------|--------|
| walking-skeleton | demo mínima | RF-01 | R0 | — | ☐ pendente |
```

- [ ] **Step 2: Criar a fixture suja**

`scripts/fixtures/arquitetura/dirty/CLAUDE.md` (bloco de versão velha → `regras-defasadas`):

```markdown
# Regras do produto (fixture suja)

<!-- zion:speckit:v0:start -->
Bloco de uma versão anterior do harness.
<!-- zion:speckit:v0:end -->
```

`scripts/fixtures/arquitetura/dirty/docs/architecture.md` (sem `## 2.` → `secao-ausente`; §1 só placeholder → `visao-vazia`; índice sem o ADR-001 do disco → `adr-index-defasado`; visão com status divergente do backlog → `backlog-view-defasada`):

```markdown
# Arquitetura — Produto Fixture

## 1. Visão geral

_(prosa do Autor ainda não escrita)_

## 3. Decisões estruturantes

<!-- zion:adr-index:start -->
_(nenhum ADR ainda)_
<!-- zion:adr-index:end -->

## 4. Visão do backlog

<!-- zion:backlog-view:start -->
- `walking-skeleton` — ☐ pendente
<!-- zion:backlog-view:end -->
```

`scripts/fixtures/arquitetura/dirty/docs/adr/ADR-001-banco-unico.md`: mesma cópia do ADR-001 de fixture.

`scripts/fixtures/arquitetura/dirty/docs/backlog.md`:

```markdown
| Spec (slug) | Demo (1 frase) | RFs | Release | Pasta | Status |
|-------------|----------------|-----|---------|-------|--------|
| walking-skeleton | demo mínima | RF-01 | R0 | `specs/001-walking-skeleton` | ● implementada |
```

- [ ] **Step 3: Escrever o auto-teste (falhando)**

Criar `scripts/test-check-arquitetura.sh`:

```bash
#!/usr/bin/env bash
# Auto-teste do check-arquitetura.sh contra fixtures limpa/suja (NFR-04). Roda pela camada mecânica (scripts/eval.sh).
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
CHECK="scripts/check-arquitetura.sh"
FIX="scripts/fixtures/arquitetura"
fail=0

assert_exit() {  # desc  exit_esperado  exit_veio
  if [ "$2" != "$3" ]; then echo "FALHOU: $1 (exit esperado $2, veio $3)"; fail=1
  else echo "ok: $1"; fi
}
assert_contains() {  # desc  agulha  palheiro
  if printf '%s' "$3" | grep -qi -- "$2"; then echo "ok: $1"
  else echo "FALHOU: $1 (não achou: $2)"; fail=1; fi
}
assert_not_contains() {  # desc  agulha  palheiro
  if printf '%s' "$3" | grep -qi -- "$2"; then echo "FALHOU: $1 (achou indevido: $2)"; fail=1
  else echo "ok: $1"; fi
}

# 1. Fixture limpa → exit 0, sem achados.
out="$(bash "$CHECK" "$FIX/clean")"; rc=$?
assert_exit "clean sai 0" 0 "$rc"
assert_contains "clean reporta limpo" "check-arquitetura: limpo" "$out"
assert_not_contains "clean não acusa defasado" "defasad" "$out"

# 2. Fixture suja → exit 1 com os cinco achados.
out="$(bash "$CHECK" "$FIX/dirty")"; rc=$?
assert_exit "dirty sai 1" 1 "$rc"
assert_contains "acha secao-ausente" "secao-ausente" "$out"
assert_contains "acha visao-vazia" "visao-vazia" "$out"
assert_contains "acha adr-index-defasado" "adr-index-defasado" "$out"
assert_contains "acha backlog-view-defasada" "backlog-view-defasada" "$out"
assert_contains "acha regras-defasadas" "regras-defasadas" "$out"

# 3. Repo vazio → arquitetura-ausente + regras-ausentes (e nada de erro).
empty="$(mktemp -d)"
out="$(bash "$CHECK" "$empty")"; rc=$?
assert_exit "repo vazio sai 1" 1 "$rc"
assert_contains "acha arquitetura-ausente" "arquitetura-ausente" "$out"
assert_contains "acha regras-ausentes" "regras-ausentes" "$out"
rmdir "$empty"

# 4. ROOT inexistente → exit 2.
out="$(bash "$CHECK" nao/existe 2>/dev/null)"; rc=$?
assert_exit "ROOT inexistente sai 2" 2 "$rc"

if [ "$fail" -eq 0 ]; then echo "test-check-arquitetura: tudo verde"; else echo "test-check-arquitetura: FALHOU"; exit 1; fi
```

Rodar: `bash scripts/test-check-arquitetura.sh` → esperado `FALHOU` (script inexistente), exit ≠ 0.

- [ ] **Step 4: Implementar o script**

Criar `scripts/check-arquitetura.sh`:

```bash
#!/usr/bin/env bash
# check-arquitetura.sh — verificador do architecture.md do PRODUTO + regra instalada (ADR-015).
# Verifica; NÃO bloqueia (RN-01, ADR-004): a Fase 4 das skills ecoa e o Autor decide. O guard
# de pre-commit opt-in do /zion-speckit-install usa o exit 1 para bloquear POR ESCOLHA do Autor.
#
# Uso:
#   check-arquitetura.sh [ROOT]   # raiz do repo do produto (default: .)
#
# Olha: ROOT/docs/architecture.md · ROOT/docs/adr/ · ROOT/docs/backlog.md · ROOT/CLAUDE.md.
# Exit: 0 (limpo) · 1 (achados) · 2 (erro de uso/ambiente).
set -u

usage() { echo "uso: check-arquitetura.sh [ROOT]" >&2; exit 2; }

ROOT="${1:-.}"
case "$ROOT" in -*) usage ;; esac
[ -d "$ROOT" ] || { echo "check-arquitetura: diretório não encontrado: $ROOT" >&2; exit 2; }

# Acompanha a versão dos marcadores de assets/templates/regras-speckit.md — mude os dois juntos.
EXPECTED_VERSION="v1"

ARCH="$ROOT/docs/architecture.md"
ADR_DIR="$ROOT/docs/adr"
BACKLOG="$ROOT/docs/backlog.md"
RULES="$ROOT/CLAUDE.md"
TAB="$(printf '\t')"

# Conteúdo entre os marcadores de um bloco (vazio se marcadores ausentes).
block_content() {  # $1 arquivo  $2 nome-do-bloco
  awk -v start="<!-- zion:$2:start -->" -v end="<!-- zion:$2:end -->" '
    $0==start { inb=1; next }
    $0==end   { inb=0 }
    inb { print }
  ' "$1"
}

# 1. Documento presente + as quatro seções obrigatórias do esqueleto.
check_secoes() {
  if [ ! -f "$ARCH" ]; then
    printf 'docs/architecture.md: arquitetura-ausente — documento não existe (rode /zion-speckit-install)\n'
    return 0
  fi
  grep -q '^## 1\. Visão geral'            "$ARCH" || printf 'docs/architecture.md: secao-ausente — "## 1. Visão geral"\n'
  grep -q '^## 2\. Integrações externas'   "$ARCH" || printf 'docs/architecture.md: secao-ausente — "## 2. Integrações externas"\n'
  grep -q '^## 3\. Decisões estruturantes' "$ARCH" || printf 'docs/architecture.md: secao-ausente — "## 3. Decisões estruturantes"\n'
  grep -q '^## 4\. Visão do backlog'       "$ARCH" || printf 'docs/architecture.md: secao-ausente — "## 4. Visão do backlog"\n'
}

# 2. §1 Visão geral com prosa real (não vazio, não blockquote, não placeholder _..._).
#    A prosa das demais seções é do Autor e não se cobra conteúdo.
check_visao_vazia() {
  [ -f "$ARCH" ] || return 0
  grep -q '^## 1\. Visão geral' "$ARCH" || return 0
  awk '
    /^## 1\. Visão geral/ { insec=1; next }
    insec && /^## /       { insec=0 }
    insec {
      line=$0; gsub(/^[[:space:]]+|[[:space:]]+$/,"",line)
      if (line=="" || line ~ /^>/ || line ~ /^_.*_$/ || line ~ /^<!--/) next
      found=1
    }
    END { exit(found?0:1) }
  ' "$ARCH" || printf 'docs/architecture.md: visao-vazia — a §1 Visão geral ainda não tem prosa do Autor\n'
}

# 3. Índice de ADRs (bloco zion:adr-index) em dia com docs/adr/ — nos dois sentidos.
check_adr_index() {
  [ -f "$ARCH" ] && [ -d "$ADR_DIR" ] || return 0
  local blk f base tgt
  blk="$(block_content "$ARCH" adr-index)"
  for f in "$ADR_DIR"/ADR-*.md; do
    [ -f "$f" ] || continue
    base="$(basename "$f")"
    printf '%s' "$blk" | grep -qF "$base" \
      || printf 'docs/architecture.md: adr-index-defasado — %s fora do bloco zion:adr-index (rode /zion-prd-trace)\n' "$base"
  done
  printf '%s\n' "$blk" | grep -oE '\([^)]*ADR-[0-9]+[^)]*\.md\)' | tr -d '()' | sort -u | while read -r tgt; do
    [ -f "$ADR_DIR/$(basename "$tgt")" ] \
      || printf 'docs/architecture.md: adr-index-defasado — %s citado no bloco mas ausente de docs/adr/ (rode /zion-prd-trace)\n' "$(basename "$tgt")"
  done
}

# 4. Visão do backlog (bloco zion:backlog-view) em dia: cada slug da PRIMEIRA tabela do
#    backlog presente no bloco com o MESMO status.
check_backlog_view() {
  [ -f "$ARCH" ] && [ -f "$BACKLOG" ] || return 0
  local blk slug status
  blk="$(block_content "$ARCH" backlog-view)"
  awk '
    function trim(s){ gsub(/^[[:space:]]+|[[:space:]]+$/,"",s); return s }
    function lc(s){ return tolower(s) }
    done { next }
    /^[[:space:]]*\|/ {
      line=$0; sub(/^[[:space:]]*\|/,"",line); sub(/\|[[:space:]]*$/,"",line)
      nc=split(line, c, /\|/); for(i=1;i<=nc;i++) c[i]=trim(c[i])
      if (!intab) {
        for(i=1;i<=nc;i++){ h=lc(c[i]); if (index(h,"slug")) scol=i; else if (index(h,"status")) stcol=i }
        ok=(scol && stcol); intab=1; next
      }
      if (c[1] ~ /^[-:]+$/) next
      if (ok && c[scol] != "") printf "%s\t%s\n", c[scol], c[stcol]
      next
    }
    intab { done=1 }
  ' "$BACKLOG" | while IFS="$TAB" read -r slug status; do
    printf '%s' "$blk" | grep -qF "\`$slug\` — $status" \
      || printf 'docs/architecture.md: backlog-view-defasada — `%s` (%s) fora do bloco zion:backlog-view (rode /zion-prd-trace)\n' "$slug" "$status"
  done
}

# 5. Bloco de regras do CLAUDE.md presente e na versão esperada (drift pós-upgrade).
check_regras() {
  if [ ! -f "$RULES" ] || ! grep -qE '<!-- zion:speckit:v[0-9]+:start -->' "$RULES"; then
    printf 'CLAUDE.md: regras-ausentes — bloco zion:speckit não instalado (rode /zion-speckit-install)\n'
    return 0
  fi
  local ver
  ver="$(grep -oE '<!-- zion:speckit:v[0-9]+:start -->' "$RULES" | head -1 | grep -oE 'v[0-9]+')"
  [ "$ver" = "$EXPECTED_VERSION" ] \
    || printf 'CLAUDE.md: regras-defasadas — bloco %s instalado, o harness espera %s (re-rode /zion-speckit-install)\n' "$ver" "$EXPECTED_VERSION"
}

findings="$(
  check_secoes
  check_visao_vazia
  check_adr_index
  check_backlog_view
  check_regras
)"

if [ -n "$findings" ]; then
  printf '%s\n' "$findings"
  count="$(printf '%s\n' "$findings" | grep -c .)"
  echo "check-arquitetura: $count achado(s)"
  exit 1
else
  echo "check-arquitetura: limpo"
  exit 0
fi
```

Depois: `chmod +x scripts/check-arquitetura.sh`

- [ ] **Step 5: Rodar o teste e ver passar**

Rodar: `bash scripts/test-check-arquitetura.sh`
Esperado: todas `ok:` e `test-check-arquitetura: tudo verde`, exit 0.

- [ ] **Step 6: Agregar no eval.sh**

Em `scripts/eval.sh` (já com as edições da Task 2): na `TESTS`, após a linha `[trace-arquitetura]=...`, inserir:

```bash
  [arquitetura]="scripts/test-check-arquitetura.sh"
```

Atualizar `ORDER`, o `case` e o uso para incluir `arquitetura` (mesmo molde da Task 2), ficando:

```bash
ORDER=(prd estudo experiencia adr trace backlog arquitetura trace-arquitetura contract canon)
```

```bash
    prd|estudo|experiencia|adr|trace|backlog|arquitetura|trace-arquitetura|contract|canon) ORDER=("$sel") ;;
    *) echo "uso: eval.sh [prd|estudo|experiencia|adr|trace|backlog|arquitetura|trace-arquitetura|contract|canon]" >&2; exit 2 ;;
```

Rodar: `bash scripts/eval.sh` → esperado `eval: tudo verde`.

- [ ] **Step 7: Canonizar (§3 do architecture.md + RF-11 na PRD)**

Em `docs/architecture.md`, §3: após a linha de `scripts/check-experiencia.sh`, inserir:

```markdown
| scripts/check-arquitetura.sh | Verificador advisório do architecture.md do produto (seções, prosa da §1, blocos derivados em dia) + drift do bloco de regras instalado no CLAUDE.md do produto. |
```

e após a linha de `scripts/test-check-experiencia.sh`, inserir:

```markdown
| scripts/test-check-arquitetura.sh | Auto-teste do check-arquitetura.sh contra fixtures. |
```

Em `docs/prd.md`, §6, trocar (Edit, string exata do arquivo):

```
  âncora de experiência presente quando há superfície de uso) e ecoa o veredito nos estágios.
```

por:

```
  âncora de experiência presente quando há superfície de uso, documento de arquitetura do produto e
  regra instalada em dia) e ecoa o veredito nos estágios.
```

Em `docs/prd.md`, §12, trocar a linha do RF-11 por:

```markdown
| RF-11 | E5 | scripts/check-prd.sh · scripts/check-adr.sh · scripts/check-estudo.sh · scripts/check-experiencia.sh · scripts/check-arquitetura.sh · scripts/trace-prd.sh · scripts/trace-backlog.sh · scripts/trace-arquitetura.sh |
```

Em `docs/prd.md`, §13, acrescentar ao FINAL da tabela:

```markdown
| 2026-07-18 | C2 | `RF-11` alterado: verificadores de arquitetura do produto na camada mecânica | sustentar por conselho a autoridade do documento de arquitetura distribuído | ADR-015 · scripts/check-arquitetura.sh · scripts/trace-arquitetura.sh |
```

Verificar: `bash scripts/check-prd.sh prd docs/prd.md` → `check-prd: limpo`; `bash scripts/check-canon.sh` → `check-canon: limpo`.

- [ ] **Step 8: Commit**

```bash
git add scripts/check-arquitetura.sh scripts/test-check-arquitetura.sh scripts/fixtures/arquitetura scripts/eval.sh docs/architecture.md docs/prd.md
git commit -m "feat(check): verificador advisório do architecture.md do produto (RF-11, padrão E5)

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 4: Templates distribuídos

**Files:**
- Create: `assets/templates/regras-speckit.md`
- Create: `assets/templates/architecture-skeleton.md`
- Modify: `docs/architecture.md` (§4, lista de fontes)

**Interfaces:**
- Consumes: gramática do elo (`**RF cobertos:** RF-xx`), marcadores globais, `EXPECTED_VERSION="v1"` da Task 3.
- Produces: os dois arquivos-fonte que a Task 5 coloca no `ASSET_MAP`. O placeholder `<NOME DO PRODUTO>` no esqueleto é o que a skill instaladora substitui. As seções/headings do esqueleto são EXATAMENTE as que `check-arquitetura.sh` cobra (`## 1. Visão geral`, `## 2. Integrações externas`, `## 3. Decisões estruturantes`, `## 4. Visão do backlog`).

- [ ] **Step 1: Criar o template do bloco de regras**

Criar `assets/templates/regras-speckit.md` (os marcadores fazem parte do arquivo — a skill grava o arquivo inteiro no `CLAUDE.md` do produto; a versão `v1` DEVE bater com `EXPECTED_VERSION` de `scripts/check-arquitetura.sh`):

```markdown
<!-- zion:speckit:v1:start -->
## Integração Zion ⇄ Spec Kit (instalado por /zion-speckit-install)

> Bloco versionado — re-rodar `/zion-speckit-install` substitui SÓ o que está entre os marcadores.
> Escreva suas regras fora deles.

### Canon declarado

`docs/discovery.md`, `docs/prd.md`, `docs/adr/`, `docs/backlog.md` e `docs/architecture.md` são as
fontes canônicas de produto e arquitetura deste repositório. Spec e plano nascem delas, não do
código.

### Fronteira de donos (um dono por pergunta)

- **Constitution** (Spec Kit) — princípios de repo inteiro (ponte `/zion-prd-constitution-prompt`).
- **`docs/adr/`** — decisões pontuais de repo inteiro, uma por ADR.
- **`docs/architecture.md`** — estrutura e prosa do Autor (§1–§2) + índices derivados (§3–§4,
  reconciliados por `/zion-prd-trace`; não editar à mão).
- **`plan.md`** de cada feature (Spec Kit) — o como daquela feature (ponte `/zion-prd-plan-prompt`).

### Recorte por passo (fronteira o-quê/como)

- `/speckit.specify` e `/speckit.clarify` leem **PRD e backlog** (o-quê); **nunca** ADRs nem
  `docs/architecture.md`.
- `/speckit.plan` lê **ADRs + `docs/architecture.md`**.
- `/speckit.implement` lê **plan + constitution**.

### Dever de origem (advisório — conselho, nunca trava)

Toda spec nasce do fluxo zion (`/zion-prd-specify-prompt`) e carrega no `spec.md` a linha de
rastreabilidade `**RF cobertos:** RF-xx`. Spec sem essa linha será acusada como **intraçável** por
`/zion-prd-trace`. O Autor decide.

### Ritual de fim de spec

- Implementação de uma spec termina → rode `/zion-prd-trace`.
- RF novo descoberto no caminho → rode `/zion-prd-evolve`.
<!-- zion:speckit:v1:end -->
```

- [ ] **Step 2: Criar o esqueleto do architecture.md do produto**

Criar `assets/templates/architecture-skeleton.md`:

```markdown
# Arquitetura — <NOME DO PRODUTO>

> Fonte da verdade do **como/com-quê** deste produto. O o-quê/por-quê vive em `docs/prd.md`
> (fronteira o-quê/como). A fronteira de donos completa está no bloco de regras do `CLAUDE.md`
> (instalado por `/zion-speckit-install`): constitution = princípios de repo; ADRs = decisões
> pontuais; este documento = estrutura e prosa do Autor + índices derivados; plan = o como por
> feature. As §3 e §4 são **derivadas** — reconciliadas por `/zion-prd-trace`; não as edite à mão.

## 1. Visão geral

_(prosa do Autor: os componentes do produto e como conversam — nunca tocada por máquina)_

## 2. Integrações externas

_(prosa do Autor: contratos com o mundo de fora — serviços consumidos, eventos, protocolos)_

## 3. Decisões estruturantes

<!-- zion:adr-index:start -->
_(nenhum ADR ainda)_
<!-- zion:adr-index:end -->

## 4. Visão do backlog

<!-- zion:backlog-view:start -->
_(sem backlog ainda)_
<!-- zion:backlog-view:end -->
```

- [ ] **Step 3: Sanidade cruzada com os verificadores**

Rodar (o esqueleto recém-nascido deve reconciliar sem erro e o check deve acusar SÓ `visao-vazia` + `regras-ausentes` num repo fake mínimo):

```bash
T="$(mktemp -d)" && mkdir -p "$T/docs"
sed 's/<NOME DO PRODUTO>/Sanidade/' assets/templates/architecture-skeleton.md > "$T/docs/architecture.md"
bash scripts/trace-arquitetura.sh "$T/docs/architecture.md" "$T/docs/adr" "$T/docs/backlog.md"
bash scripts/check-arquitetura.sh "$T"; echo "exit=$?"
rm -rf "$T"
```

Esperado: trace sai `0` (blocos semeados com "nenhum ADR ainda"/"sem backlog ainda"), check imprime exatamente 2 achados (`visao-vazia`, `regras-ausentes`) e `exit=1`.

- [ ] **Step 4: Canonizar (§4 do architecture.md)**

Em `docs/architecture.md`, §4, após a linha `- assets/templates/backlog.md — template do backlog de specs.`, inserir:

```markdown
- assets/templates/regras-speckit.md — bloco versionado de regras da integração com o Spec Kit, gravado no CLAUDE.md do produto pela instalação.
- assets/templates/architecture-skeleton.md — esqueleto do docs/architecture.md do produto (análogo ao prd-skeleton).
```

- [ ] **Step 5: Commit**

```bash
git add assets/templates/regras-speckit.md assets/templates/architecture-skeleton.md docs/architecture.md
git commit -m "feat(assets): templates do bloco de regras e do esqueleto de arquitetura do produto

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

(Os templates ainda não estão no `ASSET_MAP` — entram na Task 5 junto com a skill consumidora, porque `check-canon` acusaria `skills/zion-speckit-install` sem RF se o sync criasse a pasta antes da skill+PRD.)

---

### Task 5: Skill `zion-speckit-install` + RF-18

**Files:**
- Create: `skills/zion-speckit-install/SKILL.md`
- Modify: `scripts/asset-map.sh`
- Modify: `docs/prd.md` (§6 título do E2 + RF-18, §12, §13)
- Modify: `docs/architecture.md` (§4 lista de scripts distribuídos, §6 tabela de naturezas)
- Gerado por sync (NÃO editar à mão): `skills/zion-speckit-install/references/` e `skills/zion-prd-trace/references/` ganham cópias novas

**Interfaces:**
- Consumes: `references/regras-speckit.md`, `references/architecture-skeleton.md`, `references/trace-arquitetura.sh` (CLI da Task 2), `references/check-arquitetura.sh` (CLI e nomes de achados da Task 3).
- Produces: a skill `/zion-speckit-install` completa e o `RF-18` na PRD; o `ASSET_MAP` também já entrega `check-arquitetura.sh`/`trace-arquitetura.sh` ao `references/` de `zion-prd-trace` (a Task 6 passa a citá-los).

- [ ] **Step 1: Criar a SKILL.md**

Criar `skills/zion-speckit-install/SKILL.md`:

```markdown
---
name: zion-speckit-install
description: Instala a integração do harness Zion Build PRD com o Spec Kit no repositório do PRODUTO — grava o bloco versionado de regras de fonte canônica no CLAUDE.md, semeia docs/architecture.md de esqueleto e oferece um guard de pre-commit opt-in. Idempotente e re-rodável, substitui só o bloco marcado e nunca sobrescreve documento existente. Use para "instalar a integração com o Spec Kit", "declarar o canon no repo do produto" ou para atualizar o bloco de regras após upgrade do harness.
argument-hint: "(sem argumento — instala no repo atual)"
metadata:
  author: zion-build-prd
user-invocable: true
disable-model-invocation: false
---

# zion-speckit-install — Integração instalável com o Spec Kit (ADR-015)

Configura o repositório do PRODUTO para que o ciclo `/speckit.*` reconheça o canon zion sem
depender de prompt colado: as pontes RF-06/07/08 seguem como caminho rico (curam o recorte por
passo); a regra instalada é a **rede de segurança** quando o Autor pula a ponte. Contrato de
fases; os gates **aconselham** — a única coisa bloqueante é o guard da Fase 3, que o Autor
**escolhe** instalar.

**Guardas (não faz):** não dispara `/speckit.*` (ADR-005); não instala automação de reconciliação
no repo do produto — o gatilho é ritual humano (fim de implementação → `/zion-prd-trace`; RF
descoberto → `/zion-prd-evolve`); não toca o que o Autor escreveu fora dos marcadores.

## Fase 0 — Preflight (aconselha; um caso para)

1. **`docs/prd.md` ausente no repo atual** → a jornada zion vem antes desta instalação. Avise
   ("recomendo `/zion-prd-discovery` → `/zion-prd-write` primeiro") e **pare graciosamente** —
   sem PRD não há canon a declarar.
2. **Spec Kit não inicializado** (sem diretório `.specify/`) → avise que a regra vale desde já e
   o Spec Kit chega depois; **instale mesmo assim**.
3. `CLAUDE.md` já com bloco `<!-- zion:speckit:` → é re-execução/upgrade (informativo; siga).

## Fase 1 — Gravar o bloco de regras no CLAUDE.md do produto

O conteúdo canônico do bloco é `references/regras-speckit.md` (marcadores incluídos). Grave-o no
`CLAUDE.md` da raiz do repo:

- **CLAUDE.md não existe** → crie-o contendo só o conteúdo de `references/regras-speckit.md`.
- **Existe sem bloco `zion:speckit`** → acrescente o bloco ao final, separado por uma linha em
  branco.
- **Existe com bloco `<!-- zion:speckit:vN:start --> … <!-- zion:speckit:vN:end -->`** (qualquer
  versão) → substitua da linha do marcador start até a do marcador end, **inclusive**, pelo
  conteúdo novo. **Nada fora dos marcadores é tocado** — preserve byte a byte o que o Autor
  escreveu antes e depois do bloco.

## Fase 2 — Semear docs/architecture.md do produto

- **Não existe** → copie `references/architecture-skeleton.md` para `docs/architecture.md`,
  trocando `<NOME DO PRODUTO>` pelo nome do produto (do título da §1 Visão de `docs/prd.md`).
- **Já existe** → **não sobrescreva** (semeadura retomável, padrão do discovery). Siga direto
  para a reconciliação.
- Em ambos os casos, reconcilie os blocos derivados (índice de ADRs + visão do backlog):

      bash references/trace-arquitetura.sh docs/architecture.md docs/adr docs/backlog.md

  `docs/adr/` ou `docs/backlog.md` ainda ausentes → o script semeia os blocos com
  "(nenhum … ainda)" — normal em repo recém-começado. Documento existente sem os marcadores → o
  script avisa e não toca nada; ofereça ao Autor acrescentar as §3/§4 do esqueleto (ele decide).

## Fase 3 — Guard de pre-commit (opt-in; default NÃO instalar)

Pergunte ao Autor se quer o guard **bloqueante** de drift de arquitetura no próprio repo — o
enforcement do harness (ADR-010) exportado **por escolha**. Sem resposta afirmativa clara, **não
instale** (RN-01 intacto). Se ele aceitar:

1. Copie `references/check-arquitetura.sh` para `.zion/check-arquitetura.sh` no repo do produto
   (cópia real — autocontenção, ADR-002).
2. Descubra o diretório de hooks ativo: `git config core.hooksPath` (se vazio, `.git/hooks`).
   Sobre o arquivo `pre-commit` desse diretório:
   - **Não existe** → crie com o conteúdo abaixo e dê permissão de execução (`chmod +x`):

         #!/usr/bin/env bash
         # zion-speckit guard (opt-in) — bloqueia commit com drift de arquitetura (ADR-015)
         bash .zion/check-arquitetura.sh . || exit 1

   - **Existe e é shell script** → **nunca sobrescreva**: acrescente ao final as duas linhas
     (o comentário e a chamada `bash .zion/check-arquitetura.sh . || exit 1`).
   - **Existe noutro formato** (gerenciado por outra ferramenta, não-shell) → não toque; instrua
     o Autor a acrescentar `bash .zion/check-arquitetura.sh .` ao mecanismo dele e **pare** esta
     fase.

## Fase 4 — Validar saída (aconselha)

Rode e ecoe o veredito, em tom advisório — o Autor decide:

    bash references/check-arquitetura.sh .

Instalação recém-feita costuma sair com `visao-vazia` — a prosa da §1 é do Autor; aconselhe
escrevê-la. `regras-defasadas` após upgrade do harness → re-rode `/zion-speckit-install`.
**Handoff:** a jornada segue normal — próxima spec via `/zion-prd-specify-prompt`; fim de
implementação → `/zion-prd-trace` (o ritual reconcilia também os blocos derivados do
architecture.md).

## Saída

`CLAUDE.md` com o bloco de regras v1, `docs/architecture.md` semeado/reconciliado, guard opt-in
instalado (se o Autor escolheu) e o veredito do verificador ecoado.
```

- [ ] **Step 2: Registrar no ASSET_MAP**

Em `scripts/asset-map.sh`, acrescentar ao final do array `ASSET_MAP` (antes do `)`), alinhando as colunas com espaços como as linhas vizinhas:

```bash
  "assets/templates/regras-speckit.md        zion-speckit-install"
  "assets/templates/architecture-skeleton.md zion-speckit-install"
  "scripts/check-arquitetura.sh              zion-speckit-install zion-prd-trace"
  "scripts/trace-arquitetura.sh              zion-speckit-install zion-prd-trace"
```

Rodar: `./scripts/sync-assets.sh` → `sync-assets: ok`; conferir que nasceram `skills/zion-speckit-install/references/` (4 arquivos) e `skills/zion-prd-trace/references/{check,trace}-arquitetura.sh`.
Rodar: `./scripts/check-assets.sh` → `check-assets: sem drift`.

- [ ] **Step 3: Canonizar a PRD (RF-18 + retítulo do E2 + §12 + §13)**

Em `docs/prd.md`, §6 — trocar (string exata, com a quebra de linha do arquivo):

```
- **Épico E2 — Pontes para o Spec Kit:** `RF-06` O autor recebe pronto o prompt da constitution,
```

por:

```
- **Épico E2 — Pontes e integração com o Spec Kit:** `RF-06` O autor recebe pronto o prompt da constitution,
```

e trocar o final do parágrafo do E2:

```
  ADRs confirmados injetados como restrição a honrar.
```

por:

```
  ADRs confirmados injetados como restrição a honrar. `RF-18` O autor instala num comando, no
  repositório do produto, a integração com o Spec Kit — fontes canônicas declaradas nas regras do
  repositório, documento de arquitetura semeado de esqueleto e guard opt-in — re-rodável sem
  perder o que ele escreveu.
```

Em `docs/prd.md`, §12 — após a linha `| RF-08 | E2 | skills/zion-prd-plan-prompt |`, inserir:

```markdown
| RF-18 | E2 | skills/zion-speckit-install |
```

Em `docs/prd.md`, §13 — acrescentar ao final da tabela:

```markdown
| 2026-07-18 | C1 | `RF-18` novo: instalação da integração com o Spec Kit no repositório do produto | o canon chegava ao Spec Kit só pelas pontes manuais; clarify e implement rodavam sem canon | ADR-015 · skills/zion-speckit-install · assets/templates/regras-speckit.md · assets/templates/architecture-skeleton.md |
```

- [ ] **Step 4: Canonizar o architecture.md (§4 e §6)**

Em `docs/architecture.md`, §4 — trocar o parágrafo:

```
Também distribuídos como references executáveis: `scripts/check-prd.sh`, `scripts/check-adr.sh`,
`scripts/check-estudo.sh`, `scripts/check-experiencia.sh`, `scripts/trace-prd.sh`,
`scripts/trace-backlog.sh` (cobertos pela tabela da §3).
```

por:

```
Também distribuídos como references executáveis: `scripts/check-prd.sh`, `scripts/check-adr.sh`,
`scripts/check-estudo.sh`, `scripts/check-experiencia.sh`, `scripts/check-arquitetura.sh`,
`scripts/trace-prd.sh`, `scripts/trace-backlog.sh`, `scripts/trace-arquitetura.sh` (cobertos pela
tabela da §3).
```

Em `docs/architecture.md`, §6 — na linha da natureza **Distribuído** da tabela, trocar o trecho:

```
(`check-prd.sh`, `check-adr.sh`, `check-estudo.sh`, `trace-prd.sh`, `trace-backlog.sh`)
```

por:

```
(`check-prd.sh`, `check-adr.sh`, `check-estudo.sh`, `check-arquitetura.sh`, `trace-prd.sh`, `trace-backlog.sh`, `trace-arquitetura.sh`)
```

- [ ] **Step 5: Verificar guards**

Rodar: `bash scripts/check-prd.sh prd docs/prd.md && bash scripts/check-canon.sh && ./scripts/check-assets.sh`
Esperado: `check-prd: limpo` · `check-canon: limpo` · `check-assets: sem drift`.

- [ ] **Step 6: Commit**

```bash
git add skills/zion-speckit-install skills/zion-prd-trace/references scripts/asset-map.sh docs/prd.md docs/architecture.md
git commit -m "feat(speckit-install): skill instaladora da integração com o Spec Kit (RF-18)

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 6: Ritual do trace reconcilia a arquitetura (RF-09)

**Files:**
- Modify: `skills/zion-prd-trace/SKILL.md`
- Modify: `docs/prd.md` (§6 RF-09, §13)

**Interfaces:**
- Consumes: `references/trace-arquitetura.sh` e `references/check-arquitetura.sh` (já copiados para `skills/zion-prd-trace/references/` pela Task 5) e os nomes de achados da Task 3.
- Produces: ritual de fim de spec estendido — nada de novo para as tasks seguintes.

- [ ] **Step 1: Estender a Fase 2/3 da SKILL.md**

Em `skills/zion-prd-trace/SKILL.md`, após o parágrafo que termina em `e imprime as transições de status, os avisos\ne o **quadro de specs**.`, acrescentar:

```markdown

Se `docs/architecture.md` existir no repo do produto, rode também o reconciliador dos blocos
derivados da arquitetura (ADR-015):

    bash references/trace-arquitetura.sh docs/architecture.md docs/adr docs/backlog.md

Ele regenera **só** o conteúdo dos blocos `zion:adr-index` (§3) e `zion:backlog-view` (§4); a
prosa do Autor nunca é tocada. `docs/architecture.md` ausente → aconselhe `/zion-speckit-install`
(informativo; não impede o resto do ritual).
```

- [ ] **Step 2: Estender a Fase 4 da SKILL.md**

Após o parágrafo `Ecoe o **quadro de specs** …` (e antes de `Aponte a próxima ação:`), acrescentar:

```markdown
Do lado da arquitetura (quando `docs/architecture.md` existe), ecoe também o veredito advisório de:

    bash references/check-arquitetura.sh .

- **Marcador ausente** — o documento perdeu os marcadores `zion:adr-index`/`zion:backlog-view`:
  restaure as §3/§4 do esqueleto para os blocos voltarem a reconciliar.
- **regras-ausentes / regras-defasadas** — o bloco do `CLAUDE.md` nunca foi instalado ou ficou
  velho após upgrade: rode/re-rode `/zion-speckit-install`.
- **visao-vazia / secao-ausente** — prosa e estrutura do documento são do Autor; aconselhe, não
  corrija por ele.
```

- [ ] **Step 3: Atualizar a seção Saída**

Trocar:

```
A seção 12 de `docs/PRD.md` **e** `docs/backlog.md` reconciliados + os resumos/avisos e o quadro de specs
ecoados.
```

por:

```
A seção 12 de `docs/PRD.md`, `docs/backlog.md` **e os blocos derivados de `docs/architecture.md`**
reconciliados + os resumos/avisos e o quadro de specs ecoados.
```

- [ ] **Step 4: Canonizar a PRD (RF-09 + §13)**

Em `docs/prd.md`, §6, trocar:

```
- **Épico E3 — Rastreabilidade:** `RF-09` O autor reconcilia a qualquer momento a tabela de
  rastreabilidade e o backlog a partir das specs existentes, vendo RF órfão, spec intraçável e RF
  descoberto.
```

por:

```
- **Épico E3 — Rastreabilidade:** `RF-09` O autor reconcilia a qualquer momento a tabela de
  rastreabilidade e o backlog a partir das specs existentes, vendo RF órfão, spec intraçável e RF
  descoberto — e reconcilia junto os blocos derivados do documento de arquitetura do produto
  (índice de decisões e visão do backlog).
```

Em `docs/prd.md`, §13, acrescentar ao final da tabela:

```markdown
| 2026-07-18 | C2 | `RF-09` alterado: o trace reconcilia também os blocos derivados do documento de arquitetura do produto | artefato derivado se reconcilia por máquina, nunca à mão (RN-04) | ADR-015 · skills/zion-prd-trace · scripts/trace-arquitetura.sh |
```

- [ ] **Step 5: Verificar e commitar**

Rodar: `bash scripts/check-prd.sh prd docs/prd.md && bash scripts/check-canon.sh` → ambos limpos.

```bash
git add skills/zion-prd-trace/SKILL.md docs/prd.md
git commit -m "feat(trace): ritual reconcilia os blocos derivados da arquitetura (RF-09)

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 7: Ponte do plan injeta a prosa estrutural (RF-08)

**Files:**
- Modify: `skills/zion-prd-plan-prompt/SKILL.md`
- Modify: `docs/prd.md` (§6 RF-08, §13)

**Interfaces:**
- Consumes: existência do `docs/architecture.md` do produto (semeado pela Task 5) — a skill só lê, nunca roda script novo (não precisa de reference nova).
- Produces: nada para tasks seguintes.

- [ ] **Step 1: Estender a Fase 0 da SKILL.md**

Em `skills/zion-prd-plan-prompt/SKILL.md`, no fim do parágrafo da Fase 0 (após `Não bloqueie; pergunte se segue mesmo assim.`), acrescentar:

```markdown
`docs/architecture.md` do produto é opcional: existindo, a prosa estrutural dele entra no prompt
(ADR-015); ausente → aconselhe `/zion-speckit-install` (não bloqueie).
```

- [ ] **Step 2: Estender a Fase 1**

Trocar:

```
1. Leia o `spec.md` da spec e cruze com `docs/adr/`.
```

por:

```
1. Leia o `spec.md` da spec e cruze com `docs/adr/`; se `docs/architecture.md` existir, leia
   também a prosa do Autor (§1 Visão geral, §2 Integrações externas).
```

- [ ] **Step 3: Estender a Fase 2/3**

Após o bullet `- Listar os **ADRs confirmados** … "honre cada\n  ADR listado; não re-decida o que um ADR já fixou".`, acrescentar o bullet:

```markdown
- Injetar a prosa estrutural do `docs/architecture.md` do produto (§1–§2) como restrição a honrar:
  resuma fiel os componentes e contratos externos descritos — não invente estrutura que o
  documento não tem. A injeção é seletiva por passo (RN-02): só o plan recebe este documento;
  specify e clarify nunca.
```

- [ ] **Step 4: Estender o critério da Fase 4**

Trocar:

```
injeta os ADRs confirmados como restrição a honrar ∧ deixa claro que o plano honra cada ADR e cobre
o resultado observável do `spec.md`.
```

por:

```
injeta os ADRs confirmados — e, quando existe, a prosa estrutural do `architecture.md` do produto —
como restrição a honrar ∧ deixa claro que o plano honra cada ADR e cobre o resultado observável do
`spec.md`.
```

- [ ] **Step 5: Canonizar a PRD (RF-08 + §13)**

Em `docs/prd.md`, §6, trocar:

```
`RF-08` O autor recebe pronto o prompt do plan de uma feature, com os
  ADRs confirmados injetados como restrição a honrar.
```

por:

```
`RF-08` O autor recebe pronto o prompt do plan de uma feature, com os
  ADRs confirmados e a prosa estrutural do documento de arquitetura do produto injetados como
  restrição a honrar.
```

Em `docs/prd.md`, §13, acrescentar ao final da tabela:

```markdown
| 2026-07-18 | C2 | `RF-08` alterado: o prompt do plan injeta também a prosa estrutural do documento de arquitetura do produto | o plan é o único passo do Spec Kit que lê o como estrutural (recorte por passo) | ADR-015 · skills/zion-prd-plan-prompt |
```

- [ ] **Step 6: Verificar e commitar**

Rodar: `bash scripts/check-prd.sh prd docs/prd.md && bash scripts/check-canon.sh` → ambos limpos.

```bash
git add skills/zion-prd-plan-prompt/SKILL.md docs/prd.md
git commit -m "feat(plan-prompt): injeta a prosa estrutural do architecture.md do produto (RF-08)

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 8: Verificação final de ponta a ponta

**Files:** nenhum novo (correções pontuais se algo falhar — cada correção volta pela task dona).

**Interfaces:**
- Consumes: tudo das Tasks 1–7.
- Produces: evidência de conclusão (saídas dos comandos abaixo).

- [ ] **Step 1: Camada mecânica completa dentro do orçamento (NFR-01)**

Rodar: `time ./scripts/eval.sh`
Esperado: `eval: tudo verde` com as 10 suítes (`prd estudo experiencia adr trace backlog arquitetura trace-arquitetura contract canon`) e tempo real < 60 s.

- [ ] **Step 2: Guards de integridade**

Rodar: `./scripts/check-assets.sh && bash scripts/check-canon.sh && bash scripts/check-adr.sh docs/adr`
Esperado: `check-assets: sem drift` · `check-canon: limpo` · sem achados de ADR.

- [ ] **Step 3: Smoke da instalação num repo de produto fake**

Simular mecanicamente o que a skill instrui (valida os contratos entre skill e scripts):

```bash
T="$(mktemp -d)" && mkdir -p "$T/docs/adr"
printf '# PRD — Produto Smoke\n\n## 1. Visão\n\nPara a persona X…\n' > "$T/docs/prd.md"
printf '# Regras existentes do Autor\n\nProsa a preservar.\n' > "$T/CLAUDE.md"
# Fase 1: acrescentar o bloco (CLAUDE.md sem bloco → append com linha em branco)
printf '\n' >> "$T/CLAUDE.md"
cat skills/zion-speckit-install/references/regras-speckit.md >> "$T/CLAUDE.md"
# Fase 2: semear + reconciliar
sed 's/<NOME DO PRODUTO>/Produto Smoke/' skills/zion-speckit-install/references/architecture-skeleton.md > "$T/docs/architecture.md"
cp scripts/fixtures/arquitetura/trace/adr/ADR-001-banco-unico.md "$T/docs/adr/"
bash skills/zion-speckit-install/references/trace-arquitetura.sh "$T/docs/architecture.md" "$T/docs/adr" "$T/docs/backlog.md"
# Fase 4: veredito
bash skills/zion-speckit-install/references/check-arquitetura.sh "$T"; echo "exit=$?"
# Idempotência da regra: o bloco aparece exatamente 1 vez e a prosa do Autor sobreviveu
grep -c 'zion:speckit:v1:start' "$T/CLAUDE.md"
grep -q 'Prosa a preservar' "$T/CLAUDE.md" && echo "prosa preservada"
grep -q 'ADR-001-banco-unico' "$T/docs/architecture.md" && echo "índice semeado"
rm -rf "$T"
```

Esperado: trace reconcilia (exit 0); check acusa SÓ `visao-vazia` (`exit=1` com 1 achado — comportamento documentado na Fase 4 da skill); contagem `1`; `prosa preservada`; `índice semeado`.

- [ ] **Step 4: Estado do repo**

Rodar: `git status --short && git log --oneline -8`
Esperado: working tree limpo; 7 commits novos das Tasks 1–7 no topo.

---

## Cobertura do spec (auto-checagem do plano)

| Item do spec | Task |
|---|---|
| Skill instaladora idempotente (bloco marcado, semeadura, guard opt-in) | 5 |
| `assets/templates/regras-speckit.md` (5 partes, marcadores v1) | 4 |
| `assets/templates/architecture-skeleton.md` (4 seções + blocos derivados) | 4 |
| `scripts/check-arquitetura.sh` (4 acusações do spec + contrato E5) | 3 |
| `scripts/trace-arquitetura.sh` (reconciliação dos 2 blocos, ritual RN-04) | 2 |
| Auto-testes + fixtures limpa/suja no `eval.sh` (NFR-04, NFR-01) | 2, 3, 8 |
| `zion-prd-trace` roda trace-arquitetura + ecoa check-arquitetura | 6 |
| `zion-prd-plan-prompt` injeta a prosa estrutural (RN-02 preservada) | 7 |
| Gramática do elo confirmada contra o parser (`**RF cobertos:**`) | Global Constraints + Task 4 (texto da regra) |
| Preflight (sem prd.md para; sem Spec Kit instala), CLAUDE.md ausente, hook existente | 5 (Fases 0/1/3 da SKILL.md) |
| ADR-015 + índice §2 | 1 |
| PRD: RF-18 novo, E2 retitulado, RF-08/09/11 alterados, §12, §13 | 5, 7, 6, 3 |
| architecture.md: §3 scripts, §4 assets, §6 naturezas | 2, 3, 4, 5 |
| Fora de escopo honrado (sem patch em templates Spec Kit, sem automação instalada, agente único) | design das Tasks 4/5 |
