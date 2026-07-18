# zion-prd-estudo (Estágio 0) — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Trazer o estudo pré-discovery (hoje um prompt one-shot fora do harness) para dentro da governança, como Estágio 0 formal e opcional: skill `zion-prd-estudo` + verificador `check-estudo.sh` no padrão E5 + ADR-012 + canonização completa.

**Architecture:** O harness não tem runtime — a skill é prosa em `skills/zion-prd-estudo/SKILL.md` e a regra decidível vira shell script (`scripts/check-estudo.sh`, contrato exit 0/1/2) com auto-teste e fixtures agregados por `eval.sh`. A distribuição é por cópia real: `scripts/asset-map.sh` mapeia fontes → `references/` da skill, regenerados por `sync-assets.sh`.

**Tech Stack:** Bash (POSIX awk/grep — sem gawk-ismos como IGNORECASE), Markdown. Sem dependência nova (a única externa continua `superpowers:brainstorming`, NFR-02).

**Spec:** `docs/superpowers/specs/2026-07-18-zion-prd-estudo-design.md`

## Global Constraints

- **Canonização no mesmo commit** (CLAUDE.md): cada commit deste plano deve passar o pre-commit (`sync-assets.sh` → `check-canon.sh` → `check-adr.sh docs/adr`). Script novo ⇒ tabela §3 do `architecture.md` no MESMO commit; skill nova ⇒ RF na §6 + linha na §12 da PRD no MESMO commit; ADR novo ⇒ índice §2 no MESMO commit.
- **Nunca editar `skills/*/references/` à mão** — são derivados; rodar `./scripts/sync-assets.sh`.
- **Contrato comum dos verificadores:** exit 0 = limpo · 1 = achados · 2 = erro de uso/ambiente. No projeto-alvo o veredito **aconselha** (RN-01, NFR-05) — a Fase 4 ecoa, nunca reverte.
- **NFR-04:** todo verificador mecânico tem auto-teste com fixture limpa E suja.
- **Fronteira o-quê/como** (`assets/quality-rules.md#fronteira`): requisito sem stack em `docs/prd.md`; a skill nova guarda a mesma fronteira nas alternativas do estudo.
- **Prosa em pt-BR**, no tom dos irmãos (advisório, "não bloqueie").
- **Numeração fixa:** o ADR é **ADR-012**; o RF é **RF-17** no épico **E1**.
- **Data de hoje:** 2026-07-18 (usar nos artefatos datados).
- Mensagens de commit em português, conventional commits, terminando com `Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>`.

## File Structure

| Arquivo | Ação | Responsabilidade |
|---|---|---|
| `docs/adr/ADR-012-estagio-0-estudo-pre-discovery.md` | criar | Decisão do Estágio 0 (decisão dada) |
| `docs/adr/README.md` | editar | Faixa do índice ADR-001…012 |
| `docs/architecture.md` | editar | §2 índice ADR-012 · §3 dois scripts novos · §4 reference executável |
| `scripts/check-estudo.sh` | criar | Verificador mecânico do estudo (6 seções, "não fazer", denylist em Alternativas/ROI) |
| `scripts/test-check-estudo.sh` | criar | Auto-teste contra fixtures |
| `scripts/fixtures/estudo-clean.md` | criar | Fixture limpa (exit 0) |
| `scripts/fixtures/estudo-dirty.md` | criar | Fixture suja (1 achado de cada tipo) |
| `scripts/eval.sh` | editar | Registrar o auto-teste novo |
| `skills/zion-prd-estudo/SKILL.md` | criar | A skill (contrato de fases 0–4) |
| `scripts/asset-map.sh` | editar | zion-prd-estudo consome quality-rules, process-context, superpowers-contract, check-estudo.sh |
| `assets/process-context.md` | editar | Estágio 0 na sequência da jornada |
| `docs/prd.md` | editar | §2 objetivo · §4 escopo · §6 RF-17 · §12 (RF-17, RF-11, RF-12) · §13 changelog C1 |
| `skills/zion-prd-estudo/references/*` | derivado | Gerado por `sync-assets.sh` — nunca à mão |

---

### Task 1: ADR-012 + índice (§2) + README dos ADRs

**Files:**
- Create: `docs/adr/ADR-012-estagio-0-estudo-pre-discovery.md`
- Modify: `docs/architecture.md` (§2, tabela de ADRs, após a linha do ADR-011)
- Modify: `docs/adr/README.md`

**Interfaces:**
- Consumes: template de ADR de `skills/zion-adr-new/SKILL.md` (seções Contexto/Decisão/Consequências/Status; evidência `Decisão dada: <racional>` reconhecida por `check-adr.sh`).
- Produces: `ADR-012`, citado depois pela §8-implícita via §13 da PRD (Task 3) e pela SKILL.md.

- [x] **Step 1: Criar o ADR-012**

Criar `docs/adr/ADR-012-estagio-0-estudo-pre-discovery.md` com exatamente:

```markdown
# ADR-012 — Estágio 0 opcional de estudo pré-discovery

- **Status:** Aceito
- **Data:** 2026-07-18
- **Decisores:** autoria do repo
- **Evidência:** Decisão dada: o prompt one-shot de estudo já provou o valor na prática do autor; o design que o formaliza é `docs/superpowers/specs/2026-07-18-zion-prd-estudo-design.md`.

## Contexto

Antes de rodar o discovery, o autor às vezes precisa de um estudo que oriente a direção: edge
cases, alternativas comparadas, ROI e uma recomendação não vinculante. Hoje isso é feito por um
prompt one-shot fora do harness — sem governança: não lê as fontes canônicas do projeto-alvo por
contrato, não respeita mecanicamente a fronteira o-quê/como, não é verificável (padrão E5) nem
distribuível pelos dois canais. A dúvida estruturante era se esse passo entra na jornada como
estágio formal ou permanece fora; não há nada a provar rodando nem lendo — o valor já foi provado
na prática do autor —, então a decisão chega como decisão dada (RN-03, ADR-006).

## Decisão

A jornada ganha um **Estágio 0 formal e opcional** — a skill `zion-prd-estudo` (prefixo por
ADR-003) —, antes da descoberta: contrato de fases com convergência no padrão dos irmãos (gates
aconselham, nunca bloqueiam — RN-01), saída `docs/estudos/<slug>.md` com 6 seções fixas, e
verificador mecânico próprio `check-estudo.sh` no padrão E5 (fixtures limpa/suja + auto-teste,
agregado pelo `eval.sh`, distribuído como reference executável via `ASSET_MAP`). O estudo
**aconselha, não decide**: subsidia; o humano escolhe a alternativa e conduz ele mesmo
discovery → spike/ADR → PRD. Preterido: manter o prompt one-shot fora do harness (o estado que
esta decisão revisa).

## Consequências

O estudo passa a ler as fontes canônicas do projeto-alvo por contrato (brownfield: nenhuma
alternativa contradiz ADR vigente sem declarar a supersessão como custo; greenfield: degrada
graciosamente), guarda a fronteira sem-stack por máquina nas seções de Alternativas e ROI, e
viaja pelos dois canais de distribuição (ADR-002). A jornada ganha um estágio a mais para manter
(RF-17, `check-estudo.sh`, fixtures). Limite conhecido: a skill estuda um candidato por vez, não
rankeia candidatos, e não executa o discovery nem grava artefato downstream algum.

## Status

Aceito.
```

- [x] **Step 2: Indexar no §2 do architecture.md**

Em `docs/architecture.md`, na tabela da §2, logo após a linha do ADR-011, inserir:

```markdown
| [ADR-012](adr/ADR-012-estagio-0-estudo-pre-discovery.md) | Estágio 0 formal e opcional (`/zion-prd-estudo`): estudo pré-discovery que aconselha e não decide, verificado por `check-estudo.sh` no padrão E5. |
```

- [x] **Step 3: Atualizar a faixa no README dos ADRs**

Em `docs/adr/README.md`, trocar:

```markdown
com **ADR-001…ADR-011** e é espelhado na §2 de `docs/architecture.md` — `scripts/check-canon.sh`
```

por:

```markdown
com **ADR-001…ADR-012** e é espelhado na §2 de `docs/architecture.md` — `scripts/check-canon.sh`
```

- [x] **Step 4: Verificar os guards**

Run: `./scripts/check-adr.sh docs/adr && ./scripts/check-canon.sh`
Expected: `check-adr: limpo` e `check-canon: limpo` (exit 0 nos dois).

- [x] **Step 5: Commit**

```bash
git add docs/adr/ADR-012-estagio-0-estudo-pre-discovery.md docs/adr/README.md docs/architecture.md
git commit -m "docs(adr): ADR-012 — Estágio 0 opcional de estudo pré-discovery

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 2: check-estudo.sh no padrão E5 (TDD) + canonização dos scripts

**Files:**
- Create: `scripts/fixtures/estudo-clean.md`
- Create: `scripts/fixtures/estudo-dirty.md`
- Create: `scripts/test-check-estudo.sh`
- Create: `scripts/check-estudo.sh`
- Modify: `scripts/eval.sh`
- Modify: `docs/architecture.md` (§3 e §4)
- Modify: `docs/prd.md` (§12, linhas RF-11 e RF-12)

**Interfaces:**
- Consumes: bloco ```` ```denylist ```` de `assets/quality-rules.md` (mesmo mecanismo de lookup do `check-prd.sh`: `$SCRIPT_DIR/quality-rules.md` no caso references/, senão `$SCRIPT_DIR/../assets/quality-rules.md`).
- Produces: `check-estudo.sh <arquivo>` → exit 0/1/2; achados `secao-ausente`, `nao-fazer-ausente`, `stack`; veredito final `check-estudo: limpo` ou `check-estudo: N achado(s)`. A Task 3 invoca como `bash references/check-estudo.sh docs/estudos/<slug>.md`. Os cabeçalhos que ele exige (com numeração `N.` opcional) são exatamente: `## Contexto`, `## Edge cases e incertezas`, `## Alternativas`, `## ROI`, `## Recomendação`, `## Próximo passo sugerido`.

- [x] **Step 1: Criar a fixture limpa**

Criar `scripts/fixtures/estudo-clean.md`. Nota de design: o termo `typescript` no Contexto é proposital — prova que a denylist só varre Alternativas e ROI.

```markdown
# Estudo — exportar o consolidado do painel

## Contexto

A gerente de projetos perde tempo consolidando status à mão fora do painel (prd.md §1). O painel
atual usa typescript por decisão registrada (ADR-001 do projeto). Candidato: permitir que a
gerente exporte o andamento consolidado para compartilhar com a diretoria.

## Edge cases e incertezas

- Tarefas sem responsável entram no consolidado? **(só o humano responde)**
- A exportação respeita o filtro ativo ou sempre o quadro inteiro?

## Alternativas

1. **Não fazer** — a gerente segue consolidando à mão. Prós: custo zero. Contras: a dor da
   consolidação manual permanece. ADRs tocados: nenhum.
2. **Exportar o consolidado** — a gerente gera um arquivo com o andamento agregado e compartilha.
   Prós: resolve a dor central. Contras: mais uma superfície a manter. ADRs tocados: nenhum.
3. **Visão somente-leitura para a diretoria** — a diretoria acompanha o andamento ao vivo. Prós:
   elimina o compartilhamento manual. Contras: exige rever a decisão de acesso único — supersessão
   do ADR-002 do projeto declarada como custo.

## ROI

| Alternativa | Impacto (1–5) | Esforço (1–5, invertido) | Risco (1–5, invertido) | ROI |
|---|---|---|---|---|
| Exportar o consolidado | 4 | 4 | 5 | 4,3 |
| Não fazer | 1 | 5 | 5 | 3,7 |
| Visão somente-leitura | 5 | 2 | 2 | 3,0 |

Justificativa: exportar entrega o valor central com pouco esforço e é reversível; a visão ao vivo
tem o maior impacto mas carrega a supersessão do ADR-002 como custo e o maior esforço.

## Recomendação

Recomendação **não vinculante**: exportar o consolidado — maior ROI, sem tocar ADR vigente. A
decisão é do autor.

## Próximo passo sugerido

Se aprovado, rodar `/zion-prd-discovery` com a alternativa escolhida (e `/zion-prd-spike` se
houver decisão estruturante nova).
```

- [x] **Step 2: Criar a fixture suja**

Criar `scripts/fixtures/estudo-dirty.md`. Defeitos plantados: falta a seção Recomendação; Alternativas sem "não fazer" e com `react`; ROI com `redis`. Cabeçalhos numerados para exercitar a tolerância a `N.`:

```markdown
# Estudo — trocar o quadro de tarefas

## 1. Contexto

O time quer um quadro novo porque o atual é lento.

## 2. Edge cases e incertezas

- O que acontece com as tarefas arquivadas?

## 3. Alternativas

1. **Reescrever o quadro com react** — prós: moderno. Contras: reescrita grande.
2. **Otimizar o quadro atual** — prós: menor risco. Contras: teto de ganho.

## 4. ROI

| Alternativa | Impacto | Esforço | Risco | ROI |
|---|---|---|---|---|
| Reescrever (cache em redis) | 4 | 1 | 1 | 2,0 |
| Otimizar o atual | 3 | 4 | 4 | 3,7 |

## 6. Próximo passo sugerido

Se aprovado, rodar `/zion-prd-discovery` com a alternativa escolhida.
```

- [x] **Step 3: Escrever o auto-teste (falha primeiro)**

Criar `scripts/test-check-estudo.sh`:

```bash
#!/usr/bin/env bash
# Auto-teste do check-estudo.sh contra fixtures. Roda pela camada mecânica (scripts/eval.sh).
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
CHECK="scripts/check-estudo.sh"
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
assert_not_contains() {  # desc  agulha  palheiro
  if printf '%s' "$3" | grep -qi -- "$2"; then echo "FALHOU: $1 (achou indevido: $2)"; fail=1
  else echo "ok: $1"; fi
}

# 1. Estudo limpo → exit 0 / limpo. O termo "typescript" no Contexto NÃO pode ser achado
#    (a denylist só varre Alternativas e ROI).
out="$(bash "$CHECK" "$FIX/estudo-clean.md")"; rc=$?
assert_exit "estudo limpo sai 0" 0 "$rc"
assert_contains "estudo limpo reporta limpo" "check-estudo: limpo" "$out"
assert_not_contains "denylist não vaza para o Contexto" "typescript" "$out"

# 2. Estudo sujo → exit 1 + um achado de cada tipo.
out="$(bash "$CHECK" "$FIX/estudo-dirty.md")"; rc=$?
assert_exit "estudo sujo sai 1" 1 "$rc"
assert_contains "acha secao-ausente"      "secao-ausente"      "$out"
assert_contains "aponta a Recomendação"   "Recomenda"          "$out"
assert_contains "acha nao-fazer-ausente"  "nao-fazer-ausente"  "$out"
assert_contains "acha stack nas Alternativas" "react"          "$out"
assert_contains "acha stack no ROI"       "redis"              "$out"

# 3. Sem argumento → exit 2 (erro de uso).
out="$(bash "$CHECK" 2>/dev/null)"; rc=$?
assert_exit "sem argumento sai 2" 2 "$rc"

# 4. Arquivo inexistente → exit 2.
out="$(bash "$CHECK" /caminho/que/nao/existe.md 2>/dev/null)"; rc=$?
assert_exit "arquivo inexistente sai 2" 2 "$rc"

if [ "$fail" -eq 0 ]; then echo "test-check-estudo: tudo verde"; else echo "test-check-estudo: FALHOU"; exit 1; fi
```

Depois: `chmod +x scripts/test-check-estudo.sh`

- [x] **Step 4: Rodar o teste e vê-lo falhar**

Run: `bash scripts/test-check-estudo.sh`
Expected: linhas `FALHOU: ...` e exit 1 (o `check-estudo.sh` ainda não existe — bash retorna 127 nos asserts de exit).

- [x] **Step 5: Implementar o check-estudo.sh**

Criar `scripts/check-estudo.sh`:

```bash
#!/usr/bin/env bash
# check-estudo.sh — verificador mecânico do documento de estudo (Estágio 0 / RF-17).
# Verifica; NÃO bloqueia. Exit 0 = limpo, 1 = achados, 2 = erro de uso/ambiente.
# Quem lê o exit é a Fase 4 do /zion-prd-estudo, que aconselha (não reverte).
#
# Uso:
#   check-estudo.sh <arquivo>
#
# Verifica o decidível:
#   - as 6 seções obrigatórias presentes (## Contexto, ## Edge cases e incertezas,
#     ## Alternativas, ## ROI, ## Recomendação, ## Próximo passo sugerido; numeração
#     "N. " opcional);
#   - alternativa "não fazer" presente na seção Alternativas;
#   - denylist de stack (bloco ```denylist do quality-rules.md, mesmo mecanismo do
#     check-prd.sh) aplicada SÓ às seções Alternativas e ROI.
# Fica em prosa na Fase 4 (indecidível): citação de fonte em toda afirmação.
#
# Denylist: quality-rules.md ao lado do script (references/) ou, no repo,
# em ../assets/quality-rules.md.
set -u

usage() { echo "uso: check-estudo.sh <arquivo>" >&2; exit 2; }

target="${1:-}"
[ -n "$target" ] || usage
[ -f "$target" ] || { echo "check-estudo: arquivo não encontrado: $target" >&2; exit 2; }

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
if [ -f "$SCRIPT_DIR/quality-rules.md" ]; then
  QR="$SCRIPT_DIR/quality-rules.md"                 # caso references/
elif [ -f "$SCRIPT_DIR/../assets/quality-rules.md" ]; then
  QR="$SCRIPT_DIR/../assets/quality-rules.md"       # caso repo
else
  echo "check-estudo: quality-rules.md não encontrado (denylist indisponível)" >&2
  exit 2
fi

LABEL="$(basename "$target")"

SECTIONS=("Contexto" "Edge cases e incertezas" "Alternativas" "ROI" "Recomendação" "Próximo passo sugerido")

# Cabeçalho de seção: "## Nome" ou "## N. Nome" (numeração opcional, nada além do nome).
has_section() {
  grep -qiE "^##[[:space:]]+([0-9]+\.[[:space:]]+)?$1[[:space:]]*$" "$target"
}

# Corpo de uma seção (nome ASCII — usado só para Alternativas e ROI): imprime "NR:linha"
# do cabeçalho ao próximo "## ". Case-insensitive via tolower (POSIX awk, sem IGNORECASE).
section_body() {
  awk -v name="$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')" '
    /^##[[:space:]]/ {
      line=tolower($0)
      sub(/^##[[:space:]]+/,"",line)
      sub(/^[0-9]+\.[[:space:]]+/,"",line)
      sub(/[[:space:]]+$/,"",line)
      inside=(line==name)
      next
    }
    inside { printf "%d:%s\n", NR, $0 }
  ' "$target"
}

check_sections() {
  local s
  for s in "${SECTIONS[@]}"; do
    has_section "$s" \
      || printf '%s: secao-ausente — falta a seção "## %s" (as 6 seções do estudo são obrigatórias)\n' "$LABEL" "$s"
  done
}

# A alternativa "não fazer" é obrigatória DENTRO da seção Alternativas.
check_nao_fazer() {
  has_section "Alternativas" || return 0
  section_body "Alternativas" | grep -qiE 'n[aã]o fazer' \
    || printf '%s: nao-fazer-ausente — a seção Alternativas não inclui a alternativa "não fazer"\n' "$LABEL"
}

# Extrai os termos do bloco ```denylist do quality-rules.md (um por linha, minúsculo).
extract_denylist() {
  awk '
    /^```denylist[[:space:]]*$/ { inblock=1; next }
    inblock && /^```/           { inblock=0; next }
    inblock && NF               { print tolower($0) }
  ' "$QR"
}

# Denylist (palavra inteira, case-insensitive) só nas seções Alternativas e ROI —
# as alternativas ficam em nível de o-quê; o Contexto pode citar a stack vigente.
check_stack() {
  local denyfile; denyfile="$(mktemp)"
  extract_denylist > "$denyfile"
  if [ -s "$denyfile" ]; then
    { section_body "Alternativas"; section_body "ROI"; } | while IFS=: read -r n text; do
      printf '%s\n' "$text" | grep -iwoF -f "$denyfile" | while read -r term; do
        printf '%s:%s: stack — "%s" (alternativa em nível de o-quê; stack fica para o plan.md)\n' "$LABEL" "$n" "$term"
      done
    done
  fi
  rm -f "$denyfile"
}

findings="$(check_sections; check_nao_fazer; check_stack)"

if [ -n "$findings" ]; then
  printf '%s\n' "$findings"
  count="$(printf '%s\n' "$findings" | grep -c .)"
  echo "check-estudo: $count achado(s)"
  exit 1
else
  echo "check-estudo: limpo"
  exit 0
fi
```

Depois: `chmod +x scripts/check-estudo.sh`

- [x] **Step 6: Rodar o teste e vê-lo passar**

Run: `bash scripts/test-check-estudo.sh`
Expected: só linhas `ok: ...` e, ao final, `test-check-estudo: tudo verde` (exit 0).

- [x] **Step 7: Registrar no eval.sh**

Em `scripts/eval.sh`, três edições:

(a) no comentário de uso do cabeçalho, trocar:

```bash
#   eval.sh              # roda todos, na ordem prd → adr → trace → contract
```

por:

```bash
#   eval.sh              # roda todos, na ordem prd → estudo → adr → trace → contract
```

(b) trocar o bloco:

```bash
declare -A TESTS=(
  [prd]="scripts/test-check-prd.sh"
  [adr]="scripts/test-check-adr.sh"
  [trace]="scripts/test-trace-prd.sh"
  [backlog]="scripts/test-trace-backlog.sh"
  [contract]="scripts/test-check-superpowers-contract.sh"
  [canon]="scripts/test-check-canon.sh"
)
ORDER=(prd adr trace backlog contract canon)
```

por:

```bash
declare -A TESTS=(
  [prd]="scripts/test-check-prd.sh"
  [estudo]="scripts/test-check-estudo.sh"
  [adr]="scripts/test-check-adr.sh"
  [trace]="scripts/test-trace-prd.sh"
  [backlog]="scripts/test-trace-backlog.sh"
  [contract]="scripts/test-check-superpowers-contract.sh"
  [canon]="scripts/test-check-canon.sh"
)
ORDER=(prd estudo adr trace backlog contract canon)
```

(c) trocar as duas linhas do seletor:

```bash
    prd|adr|trace|backlog|contract|canon) ORDER=("$sel") ;;
    *) echo "uso: eval.sh [prd|adr|trace|backlog|contract|canon]" >&2; exit 2 ;;
```

por:

```bash
    prd|estudo|adr|trace|backlog|contract|canon) ORDER=("$sel") ;;
    *) echo "uso: eval.sh [prd|estudo|adr|trace|backlog|contract|canon]" >&2; exit 2 ;;
```

Run: `./scripts/eval.sh estudo`
Expected: `=== eval: estudo ===` … `test-check-estudo: tudo verde` … `eval: tudo verde` (exit 0).

- [x] **Step 8: Canonizar — architecture §3 e §4, PRD §12**

(a) Em `docs/architecture.md`, tabela §3, logo após a linha do `check-prd.sh`, inserir:

```markdown
| scripts/check-estudo.sh | Verificador das regras decidíveis do documento de estudo (Estágio 0). |
```

e logo após a linha do `test-check-prd.sh`, inserir:

```markdown
| scripts/test-check-estudo.sh | Auto-teste do check-estudo.sh contra fixtures. |
```

(b) Ainda em `docs/architecture.md`, §4, trocar:

```markdown
Também distribuídos como references executáveis: `scripts/check-prd.sh`, `scripts/check-adr.sh`,
`scripts/trace-prd.sh`, `scripts/trace-backlog.sh` (cobertos pela tabela da §3).
```

por:

```markdown
Também distribuídos como references executáveis: `scripts/check-prd.sh`, `scripts/check-adr.sh`,
`scripts/check-estudo.sh`, `scripts/trace-prd.sh`, `scripts/trace-backlog.sh` (cobertos pela
tabela da §3).
```

(c) Em `docs/prd.md`, §12, trocar:

```markdown
| RF-11 | E5 | scripts/check-prd.sh · scripts/check-adr.sh · scripts/trace-prd.sh · scripts/trace-backlog.sh |
```

por:

```markdown
| RF-11 | E5 | scripts/check-prd.sh · scripts/check-adr.sh · scripts/check-estudo.sh · scripts/trace-prd.sh · scripts/trace-backlog.sh |
```

e trocar:

```markdown
| RF-12 | E5 | scripts/eval.sh · scripts/fixtures/ · docs/guias/avaliacao-harness.md |
```

por:

```markdown
| RF-12 | E5 | scripts/eval.sh · scripts/test-check-estudo.sh · scripts/fixtures/ · docs/guias/avaliacao-harness.md |
```

- [x] **Step 9: Verificar os guards**

Run: `./scripts/check-canon.sh && ./scripts/eval.sh`
Expected: `check-canon: limpo` e `eval: tudo verde` (exit 0 nos dois).

- [x] **Step 10: Commit**

```bash
git add scripts/check-estudo.sh scripts/test-check-estudo.sh scripts/fixtures/estudo-clean.md scripts/fixtures/estudo-dirty.md scripts/eval.sh docs/architecture.md docs/prd.md
git commit -m "feat(eval): check-estudo.sh no padrão E5 com auto-teste e fixtures

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 3: Skill zion-prd-estudo + jornada canonizada (ASSET_MAP, process-context, PRD)

**Files:**
- Create: `skills/zion-prd-estudo/SKILL.md`
- Modify: `scripts/asset-map.sh`
- Modify: `assets/process-context.md`
- Modify: `docs/prd.md` (§2, §4, §6, §12, §13)
- Derivados (via sync, nunca à mão): `skills/zion-prd-estudo/references/{quality-rules.md,process-context.md,superpowers-contract.md,check-estudo.sh}`

**Interfaces:**
- Consumes: `scripts/check-estudo.sh` da Task 2 (invocado como `bash references/check-estudo.sh <arquivo>`; cabeçalhos exigidos: `## Contexto`, `## Edge cases e incertezas`, `## Alternativas`, `## ROI`, `## Recomendação`, `## Próximo passo sugerido`); `ADR-012` da Task 1; `superpowers:brainstorming` (contrato C1–C3, ADR-007).
- Produces: comando `/zion-prd-estudo`, RF-17 na PRD. Nenhuma task posterior consome — é a entrega final.

- [x] **Step 1: Criar a SKILL.md**

Criar `skills/zion-prd-estudo/SKILL.md` com exatamente:

````markdown
---
name: zion-prd-estudo
description: Estágio 0 (opcional) do harness Zion Build PRD — estudo pré-discovery de UM candidato: edge cases, 2–4 alternativas comparadas (sempre incluindo "não fazer"), ROI justificado e recomendação não vinculante, gravado em docs/estudos/<slug>.md do projeto-alvo. Use antes do discovery, quando a direção ainda não está clara, ou quando o usuário quiser "estudar uma ideia", "comparar alternativas" ou "avaliar o ROI antes da descoberta".
argument-hint: "Candidato a discovery em 2–6 frases: quem sofre, solução imaginada, restrições conhecidas"
metadata:
  author: zion-build-prd
user-invocable: true
disable-model-invocation: false
---

# zion-prd-estudo — Estágio 0 do harness (Estudo pré-discovery, opcional)

Orquestra o Estágio 0 da jornada: um **estudo** que orienta a direção antes do discovery.
Sequência dos estágios e fronteira o-quê/como em `references/process-context.md`. Contrato de
fases; todos os gates **aconselham**, nunca bloqueiam. Regras em `references/quality-rules.md`.

**Aconselha, não decide:** o documento subsidia; o humano escolhe a alternativa e conduz ele mesmo
discovery → spike/ADR → PRD. **Guardas (não faz):** não cria/altera ADRs, PRD, architecture,
skills ou assets do projeto-alvo; não grava `docs/discovery.md` nem código; a recomendação é
sempre marcada como **não vinculante**. A skill estuda **um** candidato por vez (sem ranking de
candidatos) e não persiste estado entre sessões além do próprio documento gravado.

## Fase 0 — Entrada (aconselha)

O candidato vem no argumento, em 2–6 frases: **quem sofre**, **solução imaginada**, **restrições
conhecidas**. Peça o que faltar — sem candidato completo não há o que estudar. Derive o `<slug>`
do candidato (kebab-case minúsculo, sem acentos). Se `docs/estudos/<slug>.md` **já existe**,
avise e pergunte: **retomar** (partir do documento atual e revisar) ou **sobrescrever**. Não
bloqueie.

**Preflight (dependência):** a Fase 2 exige `superpowers:brainstorming`. Se a skill não estiver
disponível, avise e pare graciosamente: "Instale o superpowers — `/plugin marketplace add
obra/superpowers-marketplace` e `/plugin install superpowers@superpowers-marketplace` — e rode de
novo." (No formato plugin ela é declarada como dependência e instala automaticamente quando o
marketplace está registrado.)

## Fase 1 — Leitura das fontes (aconselha)

Leia as fontes canônicas do projeto-alvo — **as que existirem**: `docs/prd.md`,
`docs/architecture.md` e `docs/adr/`. Resuma em **3–5 linhas** o que restringe o candidato,
**citando a fonte** de cada afirmação (`prd.md §x`, `ADR-xxx`). Brownfield: **nenhuma alternativa
pode contradizer ADR vigente** — alternativa que exigir reverter uma decisão declara a
**supersessão do ADR como custo** (dela, na Fase 3). Fontes ausentes → declare greenfield ("sem
fontes canônicas; o estudo ancora só no candidato") e siga.

## Fase 2 — Edge cases via brainstorming (convergência)

Invoque `superpowers:brainstorming` no mesmo turno (única dependência externa — contrato C1–C3,
ver ADR-007 do harness), com o enquadramento: "Explore edge cases e incertezas do candidato:
«candidato da Fase 0», sob estas restrições do projeto: «resumo da Fase 1». Produza perguntas que
a solução escolhida terá de responder — inclua as incômodas." Apresente a lista resultante
**marcando as perguntas que só o humano pode responder** e peça para **confirmar ou editar**. Não
bloqueie.

## Fase 3 — Alternativas + ROI (convergência)

Proponha **2–4 alternativas**, **sempre incluindo "não fazer"**, cada uma em nível de **o-quê**
(fronteira sem stack — `references/quality-rules.md` `#fronteira`): o que a persona passa a
conseguir, prós, contras, **ADRs tocados** e supersessões declaradas como custo (da Fase 1).

**ROI por alternativa**, três notas com justificativa em texto:

- **Impacto na persona** (1–5; 5 = resolve a dor central);
- **Esforço** (1–5, invertido; 5 = menor esforço);
- **Risco/reversibilidade** (1–5, invertido; 5 = menor risco, mais reversível).

ROI = média das três, **justificada em texto** (a nota sem o porquê não vale); tabela **ordenada
por ROI decrescente**. Apresente alternativas + tabela para **confirmar ou editar** antes de
gravar. Não bloqueie.

## Fase 4 — Gravação + veredito (aconselha)

Grave `docs/estudos/<slug>.md` com **exatamente** estas 6 seções (`##`, nesta ordem — o
verificador cobra os cabeçalhos):

```markdown
# Estudo — <candidato em meia frase>

## Contexto

<candidato em 1 parágrafo; relação com a visão da PRD e a persona, quando existirem, com fonte
citada — ou a declaração de greenfield da Fase 1>

## Edge cases e incertezas

<perguntas convergidas na Fase 2, marcadas as que só o humano responde>

## Alternativas

<as 2–4 convergidas na Fase 3, incluindo "não fazer", cada uma com prós/contras/ADRs tocados>

## ROI

<tabela ordenada + justificativas em texto>

## Recomendação

<1 parágrafo, claramente marcado como **não vinculante**>

## Próximo passo sugerido

Se aprovado, rodar `/zion-prd-discovery` com a alternativa escolhida (e `/zion-prd-spike` se
houver decisão estruturante nova).
```

Rode `bash references/check-estudo.sh docs/estudos/<slug>.md` e **ecoe o veredito como conselho**
(exit `0` limpo / `1` achados / `2` erro de uso): aponte cada achado — `secao-ausente`,
`nao-fazer-ausente`, `stack` — com a correção sugerida; **não reverta nada**. Dever em prosa
(indecidível por máquina): **toda afirmação sobre o estado atual do projeto cita a fonte**
(`prd.md §`, `ADR-xxx`) — confira antes de entregar.

## Saída

`docs/estudos/<slug>.md` — subsídio para o humano escolher a alternativa e conduzir
`/zion-prd-discovery` (Estágio 1). O estudo não dispara estágio algum.
````

- [x] **Step 2: Estágio 0 no process-context.md (fonte única)**

Em `assets/process-context.md`, logo após a linha "O harness conduz a autoria da PRD em estágios encadeados, cada um alimentando o próximo:" e a linha em branco, inserir antes do item `1.`:

```markdown
0. **Estudo pré-discovery — opcional** (`/zion-prd-estudo`) — quando a direção ainda não está
   clara: edge cases, 2–4 alternativas comparadas (sempre incluindo "não fazer"), ROI justificado
   e recomendação **não vinculante** → `docs/estudos/<slug>.md`. Subsidia; o humano escolhe a
   alternativa e conduz ele mesmo a descoberta.
```

- [x] **Step 3: Registrar a skill no ASSET_MAP**

Em `scripts/asset-map.sh`, dentro de `ASSET_MAP=(...)`:

(a) acrescentar ` zion-prd-estudo` ao final da lista de skills das três linhas existentes `assets/quality-rules.md`, `assets/process-context.md` e `assets/superpowers-contract.md`;

(b) acrescentar uma linha nova após a do `scripts/check-adr.sh`:

```bash
  "scripts/check-estudo.sh                zion-prd-estudo"
```

O bloco final fica:

```bash
ASSET_MAP=(
  "assets/quality-rules.md                zion-prd-discovery zion-prd-spike zion-prd-write zion-prd-decompose zion-prd-constitution-prompt zion-prd-specify-prompt zion-prd-plan-prompt zion-prd-evolve zion-prd-estudo"
  "assets/templates/prd-skeleton.md       zion-prd-write"
  "assets/templates/traceability-table.md zion-prd-decompose"
  "assets/process-context.md              zion-prd-discovery zion-prd-spike zion-prd-write zion-prd-decompose zion-adr-new zion-prd-evolve zion-prd-estudo"
  "assets/superpowers-contract.md         zion-prd-discovery zion-prd-write zion-prd-decompose zion-prd-estudo"
  "scripts/check-prd.sh                   zion-prd-write zion-prd-specify-prompt zion-prd-evolve"
  "scripts/trace-prd.sh                   zion-prd-trace zion-prd-decompose"
  "scripts/trace-backlog.sh               zion-prd-trace zion-prd-decompose"
  "assets/templates/backlog.md            zion-prd-decompose"
  "scripts/check-adr.sh                   zion-prd-spike zion-prd-evolve"
  "scripts/check-estudo.sh                zion-prd-estudo"
)
```

- [x] **Step 4: Sincronizar derivados e conferir**

Run: `./scripts/sync-assets.sh && ls skills/zion-prd-estudo/references/ && ./scripts/check-assets.sh`
Expected: `sync-assets: ok`; o `ls` mostra `check-estudo.sh  process-context.md  quality-rules.md  superpowers-contract.md`; check-assets limpo (exit 0).

- [x] **Step 5: Smoke do verificador no caso references/**

Prova que o lookup da denylist funciona ao lado do script (caso distribuído):

Run: `bash skills/zion-prd-estudo/references/check-estudo.sh scripts/fixtures/estudo-clean.md`
Expected: `check-estudo: limpo` (exit 0).

- [x] **Step 6: Canonizar a PRD (§2, §4, §6, §12, §13)**

Em `docs/prd.md`:

(a) §2 — trocar:

```markdown
- O autor sai da ideia bruta ao primeiro prompt de specify em 1 jornada contínua de 5 estágios,
  sem montar prompt de ponte à mão.
```

por:

```markdown
- O autor sai da ideia bruta ao primeiro prompt de specify em 1 jornada contínua de 5 estágios —
  precedida, quando a direção ainda não está clara, por um estudo opcional (Estágio 0) —, sem
  montar prompt de ponte à mão.
```

(b) §4 — trocar:

```markdown
- **Faz (in):** conduz descoberta enxuta retomável; prova decisões estruturantes com evidência
```

por:

```markdown
- **Faz (in):** produz sob demanda um estudo pré-discovery com alternativas comparadas, ROI e
  recomendação não vinculante; conduz descoberta enxuta retomável; prova decisões estruturantes com evidência
```

(c) §6, épico E1 — ao final do bloco do E1 (após a frase do RF-05, antes do bullet do épico E2), acrescentar:

```markdown
  `RF-17` O autor estuda um candidato antes da descoberta — edge cases, alternativas comparadas
  (sempre incluindo "não fazer") com ROI justificado e recomendação não vinculante — e recebe o
  estudo gravado para escolher a direção.
```

(d) §12 — após a linha `| RF-05 | E1 | skills/zion-prd-decompose |`, inserir:

```markdown
| RF-17 | E1 | skills/zion-prd-estudo |
```

(e) §13 — após a linha de separador da tabela (`|------|---------|...`), acrescentar a primeira linha de histórico:

```markdown
| 2026-07-18 | C1 | `RF-17` novo: Estágio 0 opcional de estudo pré-discovery | governar o estudo que vivia num prompt one-shot fora do harness | ADR-012 · skills/zion-prd-estudo · scripts/check-estudo.sh |
```

- [x] **Step 7: Verificar os guards (inclui o dogfood da PRD)**

Run: `bash scripts/check-prd.sh prd docs/prd.md && ./scripts/check-canon.sh && ./scripts/eval.sh`
Expected: `check-prd: limpo`, `check-canon: limpo`, `eval: tudo verde` (exit 0 em todos).

- [x] **Step 8: Commit**

```bash
git add skills/zion-prd-estudo/ scripts/asset-map.sh assets/process-context.md docs/prd.md skills/*/references/
git commit -m "feat(skill): zion-prd-estudo — Estágio 0 de estudo pré-discovery (RF-17)

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

(O pre-commit regenera e adiciona os `references/` de todas as skills consumidoras do
`process-context.md` alterado — por isso o `git add skills/*/references/`.)

---

### Task 4: Verificação integrada (sem commit)

**Files:** nenhum (somente leitura/execução).

**Interfaces:**
- Consumes: tudo das Tasks 1–3.
- Produces: evidência de verde geral antes de declarar o plano concluído.

- [x] **Step 1: Camada mecânica completa**

Run: `./scripts/eval.sh && ./scripts/check-assets.sh && ./scripts/check-canon.sh && ./scripts/check-adr.sh docs/adr`
Expected: `eval: tudo verde` · check-assets limpo · `check-canon: limpo` · `check-adr: limpo` (exit 0 em todos).

- [x] **Step 2: Smoke funcional do verificador (dois lados)**

Run: `bash scripts/check-estudo.sh scripts/fixtures/estudo-dirty.md; echo "exit=$?"`
Expected: lista de achados (`secao-ausente`, `nao-fazer-ausente`, `stack — "react"`, `stack — "redis"`), linha `check-estudo: N achado(s)` e `exit=1`.

- [x] **Step 3: Árvore de trabalho limpa**

Run: `git status --short`
Expected: saída vazia (tudo commitado; nenhum derivado com drift).
