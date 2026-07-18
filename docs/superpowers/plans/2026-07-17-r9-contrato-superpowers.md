# R9 — Contrato explícito com o superpowers — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Transformar o contrato implícito harness↔`superpowers:brainstorming` em três invariantes verificáveis por máquina (C1–C3), com asset sincronizado, check estático, auto-teste em fixtures, entrada no `eval.sh` e pin de versão no `plugin.json`.

**Architecture:** Um asset canônico (`assets/superpowers-contract.md`) documenta as três capacidades e o runbook de drift; um script (`check-superpowers-contract.sh`) faz `grep` de marcadores de capacidade no `SKILL.md` instalado (degradando gracioso quando o superpowers não está local); um auto-teste (`test-check-superpowers-contract.sh`) roda o check contra duas fixtures (`clean` + `drift-c2`) — portável, entra no CI via `eval.sh`. O pin semver no `plugin.json` trava a porta; o check diz se pode alargar.

**Tech Stack:** Bash (POSIX-ish, `set -u`), `grep -E`, `sort -V`, fixtures em Markdown. Segue o molde de `check-adr.sh` + `test-check-adr.sh` já no repo.

---

## Estrutura de arquivos

| Arquivo | Responsabilidade | Ação |
|---|---|---|
| `assets/superpowers-contract.md` | Fonte única: capacidades C1–C3, marcadores, `testado-contra`, runbook de drift | Criar |
| `scripts/asset-map.sh` | Registrar o novo asset → 3 skills consumidoras | Modificar |
| `scripts/check-superpowers-contract.sh` | O check real: localiza o `SKILL.md`, verifica C1–C3, degrada gracioso | Criar |
| `scripts/fixtures/superpowers/clean/SKILL.md` | Fixture com as 3 capacidades presentes → exit 0 | Criar |
| `scripts/fixtures/superpowers/drift-c2/SKILL.md` | Fixture sem o marcador de C2 → exit 1 citando C2 | Criar |
| `scripts/test-check-superpowers-contract.sh` | Auto-teste do check contra as fixtures (portável, CI) | Criar |
| `scripts/eval.sh` | Registrar a camada `contract` no runner | Modificar |
| `.claude-plugin/plugin.json` | Pin `">=5 <7"` na dependência do superpowers | Modificar |
| `docs/avaliacao-harness.md` | Documentar a camada `contract` da suíte | Modificar |

Os arquivos derivados `skills/{zion-prd-discovery,zion-prd-write,zion-prd-decompose}/references/superpowers-contract.md` **não** são editados à mão — `sync-assets.sh` os gera a partir do canônico.

---

### Task 1: Asset canônico do contrato + sincronização

**Files:**
- Create: `assets/superpowers-contract.md`
- Modify: `scripts/asset-map.sh` (adicionar 1 entrada ao array `ASSET_MAP`)
- Verify: `scripts/check-assets.sh`, `scripts/sync-assets.sh`

- [ ] **Step 1: Criar o asset canônico**

Create `assets/superpowers-contract.md` com este conteúdo exato:

```markdown
# Contrato harness ↔ superpowers:brainstorming

O harness Zion Build PRD usa `superpowers:brainstorming` como executor de três estágios
criativos (discovery, write, decompose). Ele **não** depende de todo o comportamento da skill —
depende de **três capacidades**. Este documento é a fonte única dessas capacidades e do runbook
de quando elas quebram. O verificador `scripts/check-superpowers-contract.sh` consome os mesmos
marcadores (mantidos em sincronia por disciplina: ao mudar um marcador, mude **aqui e no script**).

`testado-contra: 5.0.7, 6.1.1`

## As três capacidades

### C1 — Aceita um enquadramento fixo e refina ideia → design
**Por quê:** os três estágios injetam um prompt fixo esperando que o brainstorming o aceite e
conduza a ideia até um design. Sem isso, os três estágios perdem o executor.
**Marcadores (grep tolerante, satisfaz com QUALQUER um):**
- `turn ideas into.*designs`
- `refine the idea`

### C2 — Grava o resultado num arquivo cujo caminho nomeamos
**Por quê:** discovery espera o doc em `discovery.md`; write espera a PRD em `PRD.md`. O harness
lê o arquivo que o brainstorming grava — se ele parar de gravar sob um caminho nomeado, a saída
some.
**Marcadores (satisfaz só com os DOIS juntos — capacidade = escreve doc ∧ sob `docs/`):**
- `Write design doc`
- `save to.*docs/`

### C3 — Conduz diálogo uma pergunta / uma seção por vez
**Por quê:** o estágio write preenche a PRD "seção a seção", contando com o diálogo incremental
do brainstorming. Um brainstorming que despeja tudo de uma vez quebra o preenchimento guiado.
**Marcadores (grep tolerante, satisfaz com QUALQUER um):**
- `one question at a time`
- `Present design.*section`

## Fora de escopo (deliberado)

Marcadores de "writing-plans terminal", "spec self-review" etc. **não** entram: o harness
*redireciona* a saída do brainstorming e não depende do terminal padrão dele. Checá-los viraria
ruído a cada reescrita — exatamente o gate que a crítica quer evitar.

## Runbook de drift

Quando `eval.sh` (ou o check direto) acusar `⚠ C_x ... sumiu`:

1. Leia o `SKILL.md` da nova versão do brainstorming.
2. Se a capacidade **mudou de forma mas continua existindo**, atualize o marcador **aqui e no
   script** (`scripts/check-superpowers-contract.sh`) e some a nova versão em `testado-contra`.
3. Se a capacidade **sumiu de verdade**, **não alargue o pin** do `plugin.json` — trate o estágio
   afetado (o harness perdeu um executor; isso é decisão de produto, não de marcador).
```

- [ ] **Step 2: Registrar o asset no `asset-map.sh`**

Modify `scripts/asset-map.sh` — adicione a linha abaixo ao array `ASSET_MAP`, logo após a entrada de `process-context.md`:

```bash
  "assets/superpowers-contract.md         zion-prd-discovery zion-prd-write zion-prd-decompose"
```

O array final fica assim (contexto para não errar a posição):

```bash
ASSET_MAP=(
  "assets/quality-rules.md                zion-prd-discovery zion-prd-spike zion-prd-write zion-prd-decompose zion-prd-constitution-prompt zion-prd-specify-prompt zion-prd-plan-prompt zion-prd-evolve"
  "assets/templates/prd-skeleton.md       zion-prd-write"
  "assets/templates/traceability-table.md zion-prd-decompose"
  "assets/process-context.md              zion-prd-discovery zion-prd-spike zion-prd-write zion-prd-decompose zion-adr-new zion-prd-evolve"
  "assets/superpowers-contract.md         zion-prd-discovery zion-prd-write zion-prd-decompose"
  "scripts/check-prd.sh                   zion-prd-write zion-prd-specify-prompt zion-prd-evolve"
  "scripts/trace-prd.sh                   zion-prd-trace zion-prd-decompose"
  "scripts/check-adr.sh                   zion-prd-spike zion-prd-evolve"
)
```

- [ ] **Step 3: Rodar o sync para derivar os `references/`**

Run: `./scripts/sync-assets.sh`
Expected: imprime `sync-assets: ok` e cria os 3 arquivos derivados.

- [ ] **Step 4: Verificar que não há drift de assets**

Run: `./scripts/check-assets.sh`
Expected: `check-assets: sem drift` (exit 0). Confirma que os 3 `references/superpowers-contract.md` batem com o canônico.

- [ ] **Step 5: Confirmar os arquivos derivados**

Run: `ls skills/zion-prd-discovery/references/superpowers-contract.md skills/zion-prd-write/references/superpowers-contract.md skills/zion-prd-decompose/references/superpowers-contract.md`
Expected: os três caminhos existem (sem erro).

- [ ] **Step 6: Commit**

```bash
git add assets/superpowers-contract.md scripts/asset-map.sh skills/zion-prd-discovery/references/superpowers-contract.md skills/zion-prd-write/references/superpowers-contract.md skills/zion-prd-decompose/references/superpowers-contract.md
git commit -m "feat(contract): asset superpowers-contract.md sincronizado para as 3 skills (R9)"
```

---

### Task 2: Fixtures do check (clean + drift-c2)

**Files:**
- Create: `scripts/fixtures/superpowers/clean/SKILL.md`
- Create: `scripts/fixtures/superpowers/drift-c2/SKILL.md`

As fixtures são cópias enxutas do `brainstorming/SKILL.md` real, contendo só as linhas que carregam marcadores. Duas bastam: `clean` (as 3 capacidades) e `drift-c2` (representativo de "capacidade sumiu"; o mecanismo é o mesmo para C1/C3, então uma por capacidade seria YAGNI).

- [ ] **Step 1: Criar a fixture `clean`**

Create `scripts/fixtures/superpowers/clean/SKILL.md`:

```markdown
---
name: brainstorming
description: Fixture enxuta (R9) — as 3 capacidades C1-C3 presentes. Não é a skill real.
---

# Brainstorming (fixture clean)

Help turn ideas into fully formed designs and specs through natural collaborative dialogue.

Start by understanding the current project context, then ask questions one at a time to refine
the idea. Once you understand what you're building, present the design and get user approval.

## Process

5. **Present design** — in sections scaled to their complexity, get user approval after each section
6. **Write design doc** — save to `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md` and commit

## Principles

- **One question at a time** - Don't overwhelm with multiple questions
```

- [ ] **Step 2: Criar a fixture `drift-c2`**

Create `scripts/fixtures/superpowers/drift-c2/SKILL.md` — idêntica à `clean`, mas **sem a linha 6** (o par de marcadores de C2). C1 e C3 continuam satisfeitos, então só C2 deve ser reportado:

```markdown
---
name: brainstorming
description: Fixture de drift (R9) — C2 (gravar doc sob docs/) removida. Não é a skill real.
---

# Brainstorming (fixture drift-c2)

Help turn ideas into fully formed designs and specs through natural collaborative dialogue.

Start by understanding the current project context, then ask questions one at a time to refine
the idea. Once you understand what you're building, present the design and get user approval.

## Process

5. **Present design** — in sections scaled to their complexity, get user approval after each section

## Principles

- **One question at a time** - Don't overwhelm with multiple questions
```

- [ ] **Step 3: Verificar que a fixture `drift-c2` não deixou vazar marcador de C2**

Run: `grep -niE 'Write design doc|save to.*docs/' scripts/fixtures/superpowers/drift-c2/SKILL.md`
Expected: **sem saída** (exit 1 do grep). Confirma que nenhum marcador de C2 sobrou — a fixture isola o drift em C2.

- [ ] **Step 4: Verificar que C1 e C3 continuam presentes na `drift-c2`**

Run: `grep -ciE 'turn ideas into.*designs|refine the idea|one question at a time|Present design.*section' scripts/fixtures/superpowers/drift-c2/SKILL.md`
Expected: número **≥ 2** (C1 e C3 preservados — o drift não pode acusar C1/C3).

- [ ] **Step 5: Commit**

```bash
git add scripts/fixtures/superpowers/
git commit -m "test(contract): fixtures clean + drift-c2 do check de contrato (R9)"
```

---

### Task 3: Auto-teste (escrever o teste que falha)

**Files:**
- Create: `scripts/test-check-superpowers-contract.sh`

Ordem TDD: o auto-teste vem antes do check. Ele referencia `scripts/check-superpowers-contract.sh`, que ainda não existe — então falha. Isso é o esperado no Step 2.

- [ ] **Step 1: Escrever o auto-teste**

Create `scripts/test-check-superpowers-contract.sh`:

```bash
#!/usr/bin/env bash
# Auto-teste do check-superpowers-contract.sh contra fixtures (R9). Portável no CI:
# usa --skill apontando para fixtures, sem depender do superpowers instalado.
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
CHECK="scripts/check-superpowers-contract.sh"
FIX="scripts/fixtures/superpowers"
fail=0

assert_exit() {  # desc  esperado  veio
  if [ "$2" != "$3" ]; then echo "FALHOU: $1 (exit esperado $2, veio $3)"; fail=1
  else echo "ok: $1"; fi
}
assert_contains() {  # desc  agulha  palheiro
  if printf '%s' "$3" | grep -qi -- "$2"; then echo "ok: $1"
  else echo "FALHOU: $1 (não achou: $2)"; fail=1; fi
}

# 1. Fixture clean → contrato intacto (exit 0)
out="$(bash "$CHECK" --skill "$FIX/clean/SKILL.md")"; rc=$?
assert_exit "clean sai 0" 0 "$rc"
assert_contains "clean reporta intacto" "contrato intacto" "$out"

# 2. Fixture drift-c2 → drift (exit 1) citando C2
out="$(bash "$CHECK" --skill "$FIX/drift-c2/SKILL.md")"; rc=$?
assert_exit "drift-c2 sai 1" 1 "$rc"
assert_contains "drift-c2 cita C2" "C2" "$out"
# e NÃO deve citar C1/C3 (a fixture isola só o C2)
if printf '%s' "$out" | grep -qE 'C1|C3'; then
  echo "FALHOU: drift-c2 citou C1/C3 (fixture deveria isolar C2)"; fail=1
else
  echo "ok: drift-c2 isola só C2"
fi

# 3. --skill para arquivo inexistente → erro de ambiente (exit 2)
out="$(bash "$CHECK" --skill "$FIX/nao-existe/SKILL.md" 2>&1)"; rc=$?
assert_exit "--skill inexistente sai 2" 2 "$rc"

if [ "$fail" -eq 0 ]; then echo "test-check-superpowers-contract: tudo verde"; else echo "test-check-superpowers-contract: FALHOU"; exit 1; fi
```

- [ ] **Step 2: Rodar o auto-teste e confirmar que falha**

Run: `bash scripts/test-check-superpowers-contract.sh; echo "exit=$?"`
Expected: FALHA — o check ainda não existe, então `bash "$CHECK"` erra (ex.: `No such file or directory`) e o teste termina com `FALHOU` / `exit=1`. Não prossiga sem ver a falha.

- [ ] **Step 3: Tornar o auto-teste executável**

Run: `chmod +x scripts/test-check-superpowers-contract.sh`
Expected: sem saída (exit 0).

_(Sem commit aqui — o teste vermelho é commitado junto com o script verde na Task 4, para o histórico não conter um estado quebrado.)_

---

### Task 4: O check real (fazer o teste passar)

**Files:**
- Create: `scripts/check-superpowers-contract.sh`
- Test: `scripts/test-check-superpowers-contract.sh` (da Task 3)

- [ ] **Step 1: Escrever o check**

Create `scripts/check-superpowers-contract.sh`:

```bash
#!/usr/bin/env bash
# check-superpowers-contract.sh — checagem estática do contrato harness↔brainstorming (R9).
# NÃO exercita a skill (ela é interativa/socrática): faz grep de marcadores de CAPACIDADE no
# SKILL.md instalado, análogo a check-assets. Detecta quebra de contrato num upgrade do
# superpowers — não diff de frase. Fonte da verdade das capacidades e runbook de drift:
# assets/superpowers-contract.md.
#
# Uso:
#   check-superpowers-contract.sh                 # auto-localiza o brainstorming instalado
#   check-superpowers-contract.sh --skill <path>  # aponta um SKILL.md (usado pelo auto-teste)
#
# Exit: 0 = contrato intacto OU não verificável (superpowers ausente) ·
#       1 = encontrado mas ≥1 capacidade sumiu (drift real) · 2 = erro de uso/ambiente.
set -u

usage() { echo "uso: check-superpowers-contract.sh [--skill <path-para-SKILL.md>]" >&2; exit 2; }

skill_arg=""
while [ $# -gt 0 ]; do
  case "$1" in
    --skill) shift; skill_arg="${1:-}"; [ -n "$skill_arg" ] || usage ;;
    -h|--help) usage ;;
    *) usage ;;
  esac
  shift
done

# --- Localização do brainstorming/SKILL.md (primeira que existir vence) ---
SKILL=""
if [ -n "$skill_arg" ]; then
  [ -f "$skill_arg" ] || { echo "check-superpowers-contract: --skill não encontrado: $skill_arg" >&2; exit 2; }
  SKILL="$skill_arg"
else
  # Plugin cache: havendo várias versões, a maior vence (sort -V), coerente com o load-time.
  cache_hit="$(ls -1 "$HOME"/.claude/plugins/cache/superpowers-marketplace/superpowers/*/skills/brainstorming/SKILL.md 2>/dev/null | sort -V | tail -1)"
  if [ -n "$cache_hit" ]; then
    SKILL="$cache_hit"
  elif [ -f "$HOME/.claude/skills/brainstorming/SKILL.md" ]; then
    SKILL="$HOME/.claude/skills/brainstorming/SKILL.md"   # fallback npx skills
  fi
fi

# --- Degradação graciosa: nada localizado → não verificável, sai 0 (ok em CI) ---
if [ -z "$SKILL" ]; then
  echo "∅ superpowers não instalado localmente — contrato não verificável aqui (ok em CI)"
  exit 0
fi

# Versão só para a mensagem (extraída do caminho do cache; "?" nas fixtures).
ver="$(printf '%s' "$SKILL" | grep -oE '/superpowers/[0-9][^/]*/' | head -1 | sed 's#/superpowers/##; s#/##')"
[ -n "$ver" ] || ver="?"

content="$(cat "$SKILL")"
has() { printf '%s' "$content" | grep -qiE -- "$1"; }

findings=""
drift() {  # $1 = "Cx: descrição da capacidade"
  local msg="⚠ $1 sumiu do brainstorming v$ver — revalidar o contrato (ver superpowers-contract.md)"
  if [ -z "$findings" ]; then findings="$msg"; else findings="$findings
$msg"; fi
}

# C1 — aceita enquadramento fixo e refina ideia → design (satisfaz com QUALQUER marcador)
has 'turn ideas into.*designs' || has 'refine the idea' \
  || drift "C1: aceitar enquadramento e refinar ideia→design"

# C2 — grava o resultado num arquivo sob docs/ (satisfaz só com os DOIS marcadores)
{ has 'Write design doc' && has 'save to.*docs/'; } \
  || drift "C2: gravar o design num arquivo sob docs/"

# C3 — diálogo uma pergunta / uma seção por vez (satisfaz com QUALQUER marcador)
has 'one question at a time' || has 'Present design.*section' \
  || drift "C3: conduzir diálogo uma pergunta/seção por vez"

if [ -n "$findings" ]; then
  printf '%s\n' "$findings"
  echo "check-superpowers-contract: drift no contrato (brainstorming v$ver)"
  exit 1
else
  echo "check-superpowers-contract: contrato intacto (brainstorming v$ver)"
  exit 0
fi
```

- [ ] **Step 2: Tornar o check executável**

Run: `chmod +x scripts/check-superpowers-contract.sh`
Expected: sem saída (exit 0).

- [ ] **Step 3: Rodar o auto-teste e confirmar que passa**

Run: `bash scripts/test-check-superpowers-contract.sh; echo "exit=$?"`
Expected: todas as linhas `ok:` e `test-check-superpowers-contract: tudo verde` / `exit=0`.

- [ ] **Step 4: Verificar a degradação graciosa (∅) direto**

Run: `bash scripts/check-superpowers-contract.sh --skill /caminho/inexistente/SKILL.md; echo "exit=$?"`
Expected: `check-superpowers-contract: --skill não encontrado: ...` no stderr e `exit=2`.

_Nota:_ o ramo `∅ ... não verificável` (exit 0) só é atingido pela auto-localização quando o superpowers **não** está instalado; num ambiente de dev com o plugin em cache, `bash scripts/check-superpowers-contract.sh` (sem `--skill`) deve reportar `contrato intacto (brainstorming v6.1.1)`. Rode uma vez para confirmar o caminho real:

Run: `bash scripts/check-superpowers-contract.sh; echo "exit=$?"`
Expected: `contrato intacto` + `exit=0` (se o superpowers estiver em cache) **ou** a linha `∅ ... não verificável` + `exit=0` (se não estiver). Qualquer um dos dois é verde.

- [ ] **Step 5: Commit**

```bash
git add scripts/check-superpowers-contract.sh scripts/test-check-superpowers-contract.sh
git commit -m "feat(contract): check estático do contrato + auto-teste em fixtures (R9)"
```

---

### Task 5: Integrar a camada `contract` no `eval.sh`

**Files:**
- Modify: `scripts/eval.sh`

- [ ] **Step 1: Registrar o auto-teste no runner**

Modify `scripts/eval.sh`. Faça as quatro edições abaixo.

Na docstring do topo, troque a linha que lista os três testes:

```bash
# eval.sh — runner único da camada mecânica da suíte de avaliação (R7).
# Roda os auto-testes (check-prd, check-adr, trace-prd, contract) e emite veredito
# agregado. Exit 0 = todos verdes; exit 1 = qualquer um falhou; exit 2 = uso.
```

E o bloco de uso da docstring:

```bash
# Uso:
#   eval.sh              # roda todos, na ordem prd → adr → trace → contract
#   eval.sh prd          # roda só um (conveniência de dev)
#   eval.sh adr
#   eval.sh trace
#   eval.sh contract
```

No array `TESTS`, adicione a entrada `contract`:

```bash
declare -A TESTS=(
  [prd]="scripts/test-check-prd.sh"
  [adr]="scripts/test-check-adr.sh"
  [trace]="scripts/test-trace-prd.sh"
  [contract]="scripts/test-check-superpowers-contract.sh"
)
ORDER=(prd adr trace contract)
```

No seletor de argumento único, adicione `contract` aos casos válidos e à mensagem de uso:

```bash
  case "$sel" in
    prd|adr|trace|contract) ORDER=("$sel") ;;
    *) echo "uso: eval.sh [prd|adr|trace|contract]" >&2; exit 2 ;;
  esac
```

- [ ] **Step 2: Rodar só a camada `contract` via eval**

Run: `./scripts/eval.sh contract; echo "exit=$?"`
Expected: `=== eval: contract ===`, o `tudo verde` do auto-teste e `eval: tudo verde` / `exit=0`.

- [ ] **Step 3: Rodar a suíte mecânica inteira**

Run: `./scripts/eval.sh; echo "exit=$?"`
Expected: quatro blocos (`prd`, `adr`, `trace`, `contract`), todos verdes, e `eval: tudo verde` / `exit=0`.

- [ ] **Step 4: Commit**

```bash
git add scripts/eval.sh
git commit -m "feat(eval): camada contract no runner da suíte mecânica (R9)"
```

---

### Task 6: Pin de versão no `plugin.json`

**Files:**
- Modify: `.claude-plugin/plugin.json`

- [ ] **Step 1: Adicionar o range semver à dependência**

Modify `.claude-plugin/plugin.json` — na dependência do superpowers, acrescente o campo `version`:

```json
{
  "name": "zion-build-prd",
  "version": "1.0.0",
  "description": "Harness multi-agente para autoria de PRDs, com ponte para o GitHub Spec Kit.",
  "author": { "name": "Tuyoshi Vinicius" },
  "dependencies": [
    { "name": "superpowers", "marketplace": "superpowers-marketplace", "version": ">=5 <7" }
  ]
}
```

Range `>=5 <7` = os dois majors testados (5.x, 6.x). Um 7.x fica bloqueado até o eval rodar contra ele e alguém alargar o range conscientemente.

- [ ] **Step 2: Validar que o JSON continua bem-formado**

Run: `python3 -m json.tool .claude-plugin/plugin.json > /dev/null && echo OK`
Expected: `OK` (sem erro de parse).

- [ ] **Step 3: Confirmar o campo do pin**

Run: `grep -n '">=5 <7"' .claude-plugin/plugin.json`
Expected: uma linha casando o range.

- [ ] **Step 4: Commit**

```bash
git add .claude-plugin/plugin.json
git commit -m "chore(plugin): pin superpowers >=5 <7 (majors testados) (R9)"
```

---

### Task 7: Documentar a camada `contract` em `avaliacao-harness.md`

**Files:**
- Modify: `docs/avaliacao-harness.md`

- [ ] **Step 1: Incluir o check na descrição da camada mecânica (§1)**

Modify `docs/avaliacao-harness.md`. Troque o bullet **"Camada mecânica"** de §1 por:

```markdown
- **Camada mecânica (determinística).** Os verificadores de script (`check-prd.sh`, `check-adr.sh`,
  `trace-prd.sh`, `check-superpowers-contract.sh`) contra fixtures `clean`/`dirty`, consolidados em
  `scripts/eval.sh`. Roda **no CI a cada push** (passo "Avaliação da camada mecânica"). Verde/vermelho
  binário. O check de contrato **degrada gracioso**: sem o superpowers instalado ele sai 0
  ("não verificável"), então quem garante a lógica no CI é o auto-teste contra fixtures.
```

- [ ] **Step 2: Incluir `contract` nos comandos de execução (§2)**

Na §2, troque a segunda linha do bloco de comandos:

```
    ./scripts/eval.sh              # roda os quatro self-tests → veredito agregado
    ./scripts/eval.sh prd          # roda só um (prd | adr | trace | contract)
```

- [ ] **Step 3: Adicionar as fixtures do contrato ao índice (§4, tabela mecânica)**

Na §4, na tabela **"Mecânicas (camada determinística — CI)"**, acrescente duas linhas ao final:

```markdown
| `check-superpowers-contract.sh` | `fixtures/superpowers/clean/` | — (C1–C3 presentes) | contrato intacto (exit 0) |
| `check-superpowers-contract.sh` | `fixtures/superpowers/drift-c2/` | marcador de C2 (gravar doc sob docs/) removido | drift, cita C2 (exit 1) |
```

- [ ] **Step 4: Adicionar um parágrafo sobre a camada de contrato**

Ao final da §1 (depois do bullet da camada LLM), acrescente:

```markdown
> A camada mecânica inclui um **check de contrato** (`check-superpowers-contract.sh`, R9): o harness usa
> `superpowers:brainstorming` como executor de três estágios e depende de **três capacidades** dele
> (C1–C3). O check faz `grep` de marcadores dessas capacidades no `SKILL.md` instalado e acusa se
> alguma sumir num upgrade. A especificação das capacidades, os marcadores e o runbook de drift vivem
> em `assets/superpowers-contract.md`. O pin `">=5 <7"` no `plugin.json` trava a porta; o check diz
> se dá para alargar.
```

- [ ] **Step 5: Verificar as edições**

Run: `grep -nE 'check-superpowers-contract|superpowers/clean|superpowers/drift-c2|superpowers-contract.md' docs/avaliacao-harness.md`
Expected: linhas cobrindo §1 (descrição + parágrafo), §4 (duas fixtures) e o ponteiro para o asset.

- [ ] **Step 6: Commit**

```bash
git add docs/avaliacao-harness.md
git commit -m "docs(eval): documenta a camada contract da suíte (R9)"
```

---

### Task 8: Verificação final de fechamento

**Files:** nenhum (só verificação contra o Critério de conclusão do spec).

- [ ] **Step 1: `check-assets` verde (asset sincronizado)**

Run: `./scripts/check-assets.sh`
Expected: `check-assets: sem drift`.

- [ ] **Step 2: Suíte mecânica inteira verde**

Run: `./scripts/eval.sh; echo "exit=$?"`
Expected: `prd`, `adr`, `trace`, `contract` todos verdes; `eval: tudo verde` / `exit=0`.

- [ ] **Step 3: Drift real é detectado (exit 1 cita a capacidade)**

Run: `bash scripts/check-superpowers-contract.sh --skill scripts/fixtures/superpowers/drift-c2/SKILL.md; echo "exit=$?"`
Expected: linha `⚠ C2: ... sumiu ...` + `exit=1`.

- [ ] **Step 4: Localização por cache + fallback funcionam**

Run: `bash scripts/check-superpowers-contract.sh; echo "exit=$?"`
Expected: `contrato intacto (brainstorming v6.1.1)` (se o cache tiver 5.0.7 e 6.1.1, a maior vence) **ou** `∅ ... não verificável` — ambos `exit=0`.

- [ ] **Step 5: Confirmar o pin**

Run: `grep -c '">=5 <7"' .claude-plugin/plugin.json`
Expected: `1`.

- [ ] **Step 6: Árvore limpa**

Run: `git status --short`
Expected: sem saída (tudo commitado).

---

## Auto-Review (checklist do autor do plano)

**1. Cobertura do spec** — cada componente do spec tem tarefa:
- §Componente 1 (asset + asset-map + sync) → Task 1. ✔
- §Componente 2 (check-superpowers-contract.sh: localização 3-tier, lógica C1–C3, degradação graciosa, exit codes) → Task 4. ✔
- §Componente 3 (auto-teste + 2 fixtures) → Tasks 2 e 3. ✔
- §Componente 4 (eval.sh: entrada `contract`, `ORDER`) → Task 5. ✔
- §Componente 5 (plugin.json pin `">=5 <7"`) → Task 6. ✔
- §Componente 6 (avaliacao-harness.md) → Task 7. ✔
- §Critério de conclusão → Task 8 (verificação final). ✔

**2. Placeholders** — todos os steps de código mostram o conteúdo completo; nenhum "TODO"/"similar a"/"tratar edge cases" genérico. ✔

**3. Consistência de tipos/nomes** — nomes idênticos entre tarefas: script `scripts/check-superpowers-contract.sh`; auto-teste `scripts/test-check-superpowers-contract.sh`; fixtures `scripts/fixtures/superpowers/{clean,drift-c2}/SKILL.md`; chave do eval `contract`; asset `assets/superpowers-contract.md`; range `">=5 <7"`. Mensagens de drift citam exatamente `C1`/`C2`/`C3`, casadas pelo auto-teste (`assert_contains ... "C2"`). ✔

**Notas de decisão herdadas do spec:**
- O ramo ∅ (exit 0 quando nada é localizado) **não** é coberto por fixture determinística — é a escolha explícita do spec (rodar sem superpowers sai verde "não verificável"). A lógica C1–C3 é garantida no CI pelo auto-teste com `--skill`; o valor do check real é no ambiente de quem faz o upgrade.
- Os marcadores ficam **hardcoded no script** e **documentados no asset**; o runbook (asset) manda atualizar "aqui e no script" — sincronia por disciplina, não parsing do asset pelo script.
