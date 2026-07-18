# NFR de experiência — o carregador forte (A2) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Introduzir um *carregador forte* de qualidade de experiência: um marcador machine-legível (`Superfície de uso: sim/não`) que nasce no discovery, vira NFR tagueado `(experiência)` na PRD e âncora por spec no backlog, cobrado por um verificador novo (`check-experiencia.sh`) que **aconselha** — nunca bloqueia.

**Architecture:** O harness é um conjunto de skills (`skills/zion-*`) + verificadores em shell. Nenhum runtime próprio: lógica é prosa de `SKILL.md` + `check-*.sh`. A fonte única é `assets/`; os `skills/*/references/` são derivados regenerados por `scripts/sync-assets.sh` (pre-commit). Toda mudança de comportamento reflete em `docs/prd.md` + `docs/architecture.md` no mesmo commit (canonização, cobrada por `scripts/check-canon.sh` bloqueante no pre-commit). O verificador novo espelha `check-estudo.sh` (script dedicado + auto-teste + fixtures pareadas limpa/suja, agregado por `scripts/eval.sh`).

**Tech Stack:** Bash (POSIX-ish, `set -u`, `awk`/`grep`), Markdown (skills, templates, docs), git. Sem dependências externas novas (`NFR-02` intacto).

## Global Constraints

Todo task herda implicitamente estas regras (valores copiados verbatim do spec e do repo):

- **Marcador único:** a linha do marcador é sempre `Superfície de uso: sim` ou `Superfície de uso: não`, escrita como **linha bare** (não dentro de backticks, não em blockquote `>`), para o `awk` do check lê-la limpa.
- **Tag do NFR:** o NFR de experiência é tagueado com o token literal `(experiência)` (com acento e parênteses), numa linha de NFR (bullet), nunca em blockquote.
- **Coluna do backlog:** o cabeçalho exato é `Âncora de experiência` (com acento), posicionada **ao lado de `Demo`**.
- **Contrato de exit dos scripts:** `exit 0` = limpo · `1` = achados · `2` = erro de uso/ambiente.
- **Advisório, nunca bloqueia** (`RN-01`, `NFR-05`, `ADR-004`): o exit é lido pela Fase 4 da skill; o autor decide. `não` é o **default** — produto sem superfície de uso não vê bloco algum nem trip a check algum.
- **Fronteira o-quê/como** (`quality-rules.md#fronteira`, `RN-02`): captura de UX é sempre o-quê ("o usuário conclui a tarefa-núcleo em ≤N passos"), nunca tela/wireframe/stack. Experiência entra como **NFR mensurável**, nunca tela.
- **Presença, não vazamento visual:** o check verifica *presença* da âncora. Detectar "tela" vazando continua julgamento humano; o denylist de `check-prd.sh` permanece stack-only.
- **NFR-01 (60s):** a camada mecânica completa (`eval.sh`) roda em <60s no CI. O teste novo é shell puro (negligível).
- **NFR-04:** 100% dos verificadores têm auto-teste com fixture **limpa e suja** pareadas.
- **Canonização no mesmo commit** (`CLAUDE.md`): script novo ⇒ tabela §3 de `architecture.md`; ADR novo ⇒ índice §2 de `architecture.md` + evidência válida; comportamento de skill muda ⇒ RF em `docs/prd.md §6`.
- **Guards bloqueantes no pre-commit:** `sync-assets.sh` (auto) → `check-canon.sh` → `check-adr.sh docs/adr`. **Cada commit deste plano deve deixar o repo canon-clean e adr-clean.** Antes de todo commit que toca `assets/` ou `scripts/` mapeados: rode `./scripts/sync-assets.sh`, `git add skills/*/references/`, e verifique `./scripts/check-assets.sh` + `./scripts/check-canon.sh`.

---

## File Structure

**Criados:**
- `docs/adr/ADR-014-experiencia-nfr-carregado.md` — a decisão estruturante (Task 1).
- `scripts/check-experiencia.sh` — o verificador (Task 2).
- `scripts/test-check-experiencia.sh` — auto-teste do verificador (Task 2).
- `scripts/fixtures/prd-exp-sim-clean.md`, `prd-exp-sim-dirty.md`, `prd-exp-nao.md` — fixtures de PRD (Task 2).
- `scripts/fixtures/backlog-exp-clean.md`, `backlog-exp-dirty.md` — fixtures de backlog (Task 2).

**Modificados:**
- `docs/architecture.md` — §2 índice (ADR-014, Task 1); §3 tabela de scripts + §4 references executáveis (Task 2).
- `scripts/eval.sh` — registra o teste novo (Task 2).
- `scripts/asset-map.sh` — distribui `check-experiencia.sh` a write/decompose (Task 2).
- `docs/prd.md` — §6 RF-11 + §12 (Task 2); §6 RF-01 (Task 3); §6 RF-04 (Task 4); §6 RF-05 (Task 5); §13 changelog (Task 6).
- `assets/quality-rules.md` — critérios de conclusão (discovery/prd/decompose) + nota "experiência é NFR, não tela" (Task 3).
- `skills/zion-prd-discovery/SKILL.md` — captura + gate (Task 3).
- `skills/zion-prd-write/SKILL.md` — carrega marcador + aterrissa NFR + invoca o check (Task 4).
- `assets/templates/prd-skeleton.md` — §7 marcador + slot de NFR tagueado (Task 4).
- `skills/zion-prd-decompose/SKILL.md` — ancora no backlog + braço INVEST + invoca o check (Task 5).
- `assets/templates/backlog.md` — coluna `Âncora de experiência` (Task 5).

Os `skills/*/references/` derivados são regenerados por `sync-assets.sh` — **nunca editados à mão**.

---

## Task 1: Governança — ADR-014 + índice

Cria a decisão estruturante e a indexa. Deve ficar antes de tudo porque o `check-adr.sh` (pre-commit bloqueante) exige evidência válida, e o changelog (Task 6) cita ADR-014 — que precisa existir. Nada mais referencia o ADR ainda, então é self-contained.

**Files:**
- Create: `docs/adr/ADR-014-experiencia-nfr-carregado.md`
- Modify: `docs/architecture.md` (§2, tabela de ADRs)

**Interfaces:**
- Consumes: nada.
- Produces: o arquivo `docs/adr/ADR-014-experiencia-nfr-carregado.md` (cujo id `ADR-014` o changelog da Task 6 cita) e a linha de índice em `architecture.md §2`.

- [ ] **Step 1: Criar o ADR-014**

Escreva `docs/adr/ADR-014-experiencia-nfr-carregado.md` com este conteúdo exato (mesmo molde de `ADR-012`; a evidência é **Decisão dada** — o Autor escolheu A2 no estudo, então o `check-adr.sh` só exige racional presente):

```markdown
# ADR-014 — Qualidade de experiência é NFR carregado, com verificador que aconselha

- **Status:** Aceito
- **Data:** 2026-07-18
- **Decisores:** autoria do repo
- **Evidência:** Decisão dada: o Autor escolheu a alternativa A2 no estudo `docs/estudos/discovery-ux-design.md` (ADR-006, evidência por decisão dada); o design que a formaliza é `docs/superpowers/specs/2026-07-18-nfr-experiencia-carrier-design.md`.

## Contexto

O backlog decomposto (RF-05) não se preocupa com experiência, e o app resultante fica rico em
função e pobre de uso. A dor mora no backlog, mas o sinal de qualidade de experiência precisa
nascer antes — no discovery — e sobreviver por discovery → PRD → decomposição → backlog. Hoje nada
carrega esse sinal, e nada de máquina acusa sua ausência. A dúvida estruturante — se a experiência
entra como carregador forte (marcador + verificador) ou fica em prosa solta — foi decidida pelo
Autor ao escolher a alternativa A2 do estudo `discovery-ux-design.md`; chega como decisão dada
(RN-03, ADR-006), sem nada a provar rodando nem lendo.

## Decisão

A qualidade de experiência vira um **NFR mensurável** carregado por um único marcador
machine-legível — `Superfície de uso: sim/não` — nascido no discovery e cobrado por um verificador
novo `check-experiencia.sh` que **aconselha** (honra ADR-004, RN-01, NFR-05) tanto na PRD quanto no
backlog. Quatro decisões fechadas: (1) gatilho advisório no discovery, `não` por default;
(2) carregador **forte** — verificador novo, não só prosa; (3) âncora na própria PRD, distinguida
pela tag `(experiência)` num NFR (contrato 1-arquivo preservado); (4) o carregador de máquina vai
até o backlog (âncora por spec), não para na PRD. Preterido: deixar a experiência como prosa não
verificável (o estado que esta decisão revisa).

## Consequências

O harness ganha um verificador a mais para manter (`check-experiencia.sh`, `test-check-experiencia.sh`,
fixtures pareadas), no padrão E5, agregado pelo `eval.sh` e distribuído como reference executável via
ASSET_MAP a `zion-prd-write` e `zion-prd-decompose`. As skills de discovery, write e decompose ganham
um passo advisório cada. Nenhuma dependência externa nova (NFR-02, ADR-007 intactos). Não toca o
specify-prompt (RF-07) nem o trace (RF-09): o alcance de máquina para no backlog. Limite conhecido: o
check verifica **presença** da âncora, não vazamento visual — detectar "tela" vazando continua
julgamento humano na fronteira (denylist stack-only, inalterado).

## Status

Aceito.
```

- [ ] **Step 2: Indexar o ADR-014 em architecture.md §2**

Em `docs/architecture.md`, na tabela de ADRs (§2), logo após a linha do `ADR-013`, adicione:

Localize:
```
| [ADR-013](adr/ADR-013-estudo-workflow-adaptativo.md) | Skill de estudo (Estágio 0) roteia o "Próximo passo sugerido" por marcador do repo-harness: modo interno (SDD leve) × distribuído (discovery), numa única `SKILL.md` gated. |
```
e adicione **abaixo** dela:
```
| [ADR-014](adr/ADR-014-experiencia-nfr-carregado.md) | Qualidade de experiência é NFR carregado por marcador machine-legível (`Superfície de uso` + tag `(experiência)`), com verificador que aconselha até o backlog. |
```

- [ ] **Step 3: Verificar que os guards passam**

Run: `bash scripts/check-adr.sh docs/adr && bash scripts/check-canon.sh`
Expected: `check-adr: limpo` e `check-canon: limpo` (o ADR-014 tem Evidência preenchida por decisão dada e está no índice §2; C5 do canon satisfeito).

- [ ] **Step 4: Commit**

```bash
git add docs/adr/ADR-014-experiencia-nfr-carregado.md docs/architecture.md
git commit -m "docs(adr): ADR-014 — experiência é NFR carregado com verificador que aconselha"
```

---

## Task 2: O verificador `check-experiencia.sh` (+ auto-teste, fixtures, eval, canon)

O coração da mudança de máquina. TDD: fixtures → auto-teste (falha) → script (passa) → wiring do `eval.sh` → canonização (architecture §3/§4, ASSET_MAP, prd §6 RF-11 + §12). Tudo num commit canon-clean: o `check-canon.sh` (C3) exige que **os dois** scripts novos estejam citados em `architecture.md §3` no mesmo commit.

**Files:**
- Create: `scripts/check-experiencia.sh`
- Create: `scripts/test-check-experiencia.sh`
- Create: `scripts/fixtures/prd-exp-sim-clean.md`, `scripts/fixtures/prd-exp-sim-dirty.md`, `scripts/fixtures/prd-exp-nao.md`, `scripts/fixtures/backlog-exp-clean.md`, `scripts/fixtures/backlog-exp-dirty.md`
- Modify: `scripts/eval.sh`, `scripts/asset-map.sh`, `docs/architecture.md` (§3, §4), `docs/prd.md` (§6 RF-11, §12 RF-11/RF-12)

**Interfaces:**
- Consumes: nada.
- Produces: o executável `check-experiencia.sh <PRD> [backlog]` — invocado pela Fase 4 de `zion-prd-write` (Task 4, só `<PRD>` → só limb-PRD) e `zion-prd-decompose` (Task 5, `<PRD> <backlog>` → ambos os limbs). Contrato: exit 0 limpo · 1 achados · 2 uso. Achados: `limb-PRD` e `limb-backlog`, ambos guardados por `Superfície de uso: sim`.

- [ ] **Step 1: Criar as fixtures de PRD**

`scripts/fixtures/prd-exp-sim-clean.md` (surface=sim **com** NFR tagueado — limpo):
```markdown
# PRD — Exemplo com superfície de uso

## 7. NFRs (com números)
Superfície de uso: sim

- `NFR-01` A resposta média fica abaixo de 200 ms.
- `NFR-02` (experiência): a tarefa-núcleo é concluída em ≤3 passos.
```

`scripts/fixtures/prd-exp-sim-dirty.md` (surface=sim **sem** NFR tagueado — limb-PRD):
```markdown
# PRD — Exemplo com superfície mas sem âncora

## 7. NFRs (com números)
Superfície de uso: sim

- `NFR-01` A resposta média fica abaixo de 200 ms.
```

`scripts/fixtures/prd-exp-nao.md` (surface=não — gate fechado, limpo):
```markdown
# PRD — Backend puro, sem superfície de uso

## 7. NFRs (com números)
Superfície de uso: não

- `NFR-01` A resposta média fica abaixo de 200 ms.
```

- [ ] **Step 2: Criar as fixtures de backlog**

`scripts/fixtures/backlog-exp-clean.md` (≥1 linha com `Âncora de experiência` preenchida — limpo):
```markdown
| Spec (slug) | Demo (1 frase) | Âncora de experiência | RFs | Release | Pasta | Status |
|-------------|----------------|-----------------------|-----|---------|-------|--------|
| walking-skeleton | demo mínima ponta-a-ponta | usuário conclui a tarefa-núcleo em ≤3 passos | RF-01 | R0 | — | ☐ pendente |
| relatorio-backend | agrega dados no servidor | — | RF-02 | R1 | — | ☐ pendente |
```

`scripts/fixtures/backlog-exp-dirty.md` (nenhuma linha com âncora preenchida — limb-backlog):
```markdown
| Spec (slug) | Demo (1 frase) | Âncora de experiência | RFs | Release | Pasta | Status |
|-------------|----------------|-----------------------|-----|---------|-------|--------|
| walking-skeleton | demo mínima ponta-a-ponta | — | RF-01 | R0 | — | ☐ pendente |
| relatorio-backend | agrega dados no servidor | — | RF-02 | R1 | — | ☐ pendente |
```

- [ ] **Step 3: Escrever o auto-teste (que vai falhar)**

`scripts/test-check-experiencia.sh` (mesmo molde de `test-check-estudo.sh`; cobre gate=não, limb-PRD, limb-backlog e os dois juntos, mais os erros de uso — fixtures pareadas limpa/suja por NFR-04):
```bash
#!/usr/bin/env bash
# Auto-teste do check-experiencia.sh contra fixtures. Roda pela camada mecânica (scripts/eval.sh).
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
CHECK="scripts/check-experiencia.sh"
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

# 1. surface=não → gate fechado: exit 0 / limpo, mesmo sem NFR de experiência.
out="$(bash "$CHECK" "$FIX/prd-exp-nao.md")"; rc=$?
assert_exit "surface=não sai 0" 0 "$rc"
assert_contains "surface=não reporta limpo" "check-experiencia: limpo" "$out"

# 2. surface=sim com NFR tagueado, sem backlog → exit 0 / limpo (limb-backlog pulado).
out="$(bash "$CHECK" "$FIX/prd-exp-sim-clean.md")"; rc=$?
assert_exit "surface=sim + tag sai 0" 0 "$rc"
assert_contains "surface=sim + tag reporta limpo" "check-experiencia: limpo" "$out"

# 3. surface=sim sem NFR tagueado, sem backlog → exit 1 + limb-PRD.
out="$(bash "$CHECK" "$FIX/prd-exp-sim-dirty.md")"; rc=$?
assert_exit "limb-PRD sai 1" 1 "$rc"
assert_contains "acha limb-PRD" "limb-PRD" "$out"
assert_not_contains "sem backlog não acusa limb-backlog" "limb-backlog" "$out"

# 4. surface=sim + tag + backlog com âncora preenchida → exit 0 / limpo.
out="$(bash "$CHECK" "$FIX/prd-exp-sim-clean.md" "$FIX/backlog-exp-clean.md")"; rc=$?
assert_exit "PRD+backlog limpos saem 0" 0 "$rc"
assert_contains "PRD+backlog limpos reporta limpo" "check-experiencia: limpo" "$out"

# 5. surface=sim + tag + backlog sem âncora → exit 1 + limb-backlog (só).
out="$(bash "$CHECK" "$FIX/prd-exp-sim-clean.md" "$FIX/backlog-exp-dirty.md")"; rc=$?
assert_exit "limb-backlog sai 1" 1 "$rc"
assert_contains "acha limb-backlog" "limb-backlog" "$out"
assert_not_contains "PRD com tag não acusa limb-PRD" "limb-PRD" "$out"

# 6. surface=sim sem tag + backlog sem âncora → exit 1 + os dois limbs.
out="$(bash "$CHECK" "$FIX/prd-exp-sim-dirty.md" "$FIX/backlog-exp-dirty.md")"; rc=$?
assert_exit "dois achados sai 1" 1 "$rc"
assert_contains "acha limb-PRD (duplo)" "limb-PRD" "$out"
assert_contains "acha limb-backlog (duplo)" "limb-backlog" "$out"

# 7. sem argumento → exit 2.
out="$(bash "$CHECK" 2>/dev/null)"; rc=$?
assert_exit "sem argumento sai 2" 2 "$rc"

# 8. PRD inexistente → exit 2.
out="$(bash "$CHECK" /caminho/que/nao/existe.md 2>/dev/null)"; rc=$?
assert_exit "PRD inexistente sai 2" 2 "$rc"

# 9. backlog inexistente → exit 2.
out="$(bash "$CHECK" "$FIX/prd-exp-sim-clean.md" /nao/existe-backlog.md 2>/dev/null)"; rc=$?
assert_exit "backlog inexistente sai 2" 2 "$rc"

if [ "$fail" -eq 0 ]; then echo "test-check-experiencia: tudo verde"; else echo "test-check-experiencia: FALHOU"; exit 1; fi
```

- [ ] **Step 4: Rodar o teste para confirmar que falha**

Run: `bash scripts/test-check-experiencia.sh`
Expected: FALHA — o script `check-experiencia.sh` ainda não existe (as invocações saem com erro/exit inesperado; termina em `test-check-experiencia: FALHOU`).

- [ ] **Step 5: Escrever o verificador**

`scripts/check-experiencia.sh` (verifica **presença** da âncora; sem dependência de `quality-rules.md` — não usa denylist):
```bash
#!/usr/bin/env bash
# check-experiencia.sh — verificador do carregador de experiência (A2 / RF-11).
# Verifica; NÃO bloqueia. Exit 0 = limpo, 1 = achados, 2 = erro de uso/ambiente.
# Lido pela Fase 4 de /zion-prd-write (só PRD → só limb-PRD) e de /zion-prd-decompose
# (PRD + backlog → ambos os limbs), que aconselham (não revertem — RN-01, ADR-004).
#
# Uso:
#   check-experiencia.sh <PRD> [backlog]
#
# Gate: "Superfície de uso: sim" na §7 da PRD. Ausente ou "não" → produto sem
# superfície de uso: nada a cobrar (exit 0). Só com surface=sim há achados:
#   - limb-PRD     — nenhum NFR tagueado "(experiência)" na PRD (fora de blockquote).
#   - limb-backlog — (só com arg backlog) nenhuma linha do backlog com a coluna
#                    "Âncora de experiência" preenchida.
# Verifica PRESENÇA da âncora, não vazamento visual (isso continua julgamento humano).
set -u

usage() { echo "uso: check-experiencia.sh <PRD> [backlog]" >&2; exit 2; }

prd="${1:-}"
backlog="${2:-}"
[ -n "$prd" ] || usage
case "$prd" in -*) usage ;; esac
[ -f "$prd" ] || { echo "check-experiencia: arquivo não encontrado: $prd" >&2; exit 2; }
if [ -n "$backlog" ]; then
  [ -f "$backlog" ] || { echo "check-experiencia: backlog não encontrado: $backlog" >&2; exit 2; }
fi

PRD_LABEL="$(basename "$prd")"
BACKLOG_LABEL="$(basename "${backlog:-backlog.md}")"

# Valor do marcador "Superfície de uso: <valor>" (primeira ocorrência, minúsculo).
surface_value() {
  awk '
    /Superfície de uso:/ {
      v=$0
      sub(/^.*Superfície de uso:[[:space:]]*/,"",v)
      sub(/[[:space:]]+$/,"",v)
      print tolower(v)
      exit
    }
  ' "$prd"
}

# Há um NFR tagueado "(experiência)" fora de blockquote? (a guia do template mora em
# blockquote ">"; a âncora real é uma linha de NFR — bullet. Excluir ">" evita
# falso-negativo por boilerplate deixado no lugar.)
has_exp_nfr() {  # exit 0 se há, 1 se não
  awk '/\(experiência\)/ && $0 !~ /^[[:space:]]*>/ { found=1 } END { exit(found?0:1) }' "$prd"
}

# A coluna "Âncora de experiência" da primeira tabela do backlog tem ≥1 célula
# preenchida? Preenchida = conteúdo real (não vazia, não "—", não placeholder _..._).
backlog_anchor_filled() {  # $1 backlog -> exit 0 se preenchida, 1 se não
  awk '
    function trim(s){ gsub(/^[[:space:]]+|[[:space:]]+$/,"",s); return s }
    !colidx && /\|/ && /Âncora de experiência/ {
      n=split($0, c, /\|/)
      for (i=1;i<=n;i++) if (trim(c[i])=="Âncora de experiência") colidx=i
      if (colidx) next
    }
    colidx && /^[[:space:]]*\|[[:space:]]*[-:]/ { next }      # separador |---|
    colidx && /\|/ {
      n=split($0, c, /\|/)
      cell=trim(c[colidx])
      if (cell!="" && cell!="—" && cell !~ /^_.*_$/) found=1
      next
    }
    colidx && !/\|/ { exit }                                  # 1ª linha fora da tabela encerra
    END { exit(found?0:1) }
  ' "$1"
}

surface="$(surface_value)"
case "$surface" in
  sim) ;;
  *) echo "check-experiencia: limpo"; exit 0 ;;
esac

findings=""
add() {  # $1 achado
  if [ -z "$findings" ]; then findings="$1"; else findings="$findings
$1"; fi
}

# limb-PRD: surface=sim ∧ nenhum NFR tagueado "(experiência)".
has_exp_nfr \
  || add "$PRD_LABEL: limb-PRD — produto com superfície de uso mas nenhum NFR tagueado \"(experiência)\" na §7"

# limb-backlog: só quando o backlog é passado.
if [ -n "$backlog" ]; then
  backlog_anchor_filled "$backlog" \
    || add "$BACKLOG_LABEL: limb-backlog — produto com superfície de uso mas nenhuma spec com a coluna \"Âncora de experiência\" preenchida"
fi

if [ -n "$findings" ]; then
  printf '%s\n' "$findings"
  count="$(printf '%s\n' "$findings" | grep -c .)"
  echo "check-experiencia: $count achado(s)"
  exit 1
else
  echo "check-experiencia: limpo"
  exit 0
fi
```

- [ ] **Step 6: Tornar executável e rodar o teste até passar**

Run: `chmod +x scripts/check-experiencia.sh && bash scripts/test-check-experiencia.sh`
Expected: PASS — termina em `test-check-experiencia: tudo verde` (todas as asserções `ok:`).

- [ ] **Step 7: Registrar o teste no `eval.sh`**

Em `scripts/eval.sh`, adicione a entrada ao array `TESTS` — localize:
```
  [estudo]="scripts/test-check-estudo.sh"
```
e adicione **abaixo**:
```
  [experiencia]="scripts/test-check-experiencia.sh"
```

No mesmo arquivo, atualize a ordem — localize:
```
ORDER=(prd estudo adr trace backlog contract canon)
```
troque por:
```
ORDER=(prd estudo experiencia adr trace backlog contract canon)
```

E atualize as duas strings de uso. Localize:
```
    prd|estudo|adr|trace|backlog|contract|canon) ORDER=("$sel") ;;
    *) echo "uso: eval.sh [prd|estudo|adr|trace|backlog|contract|canon]" >&2; exit 2 ;;
```
troque por:
```
    prd|estudo|experiencia|adr|trace|backlog|contract|canon) ORDER=("$sel") ;;
    *) echo "uso: eval.sh [prd|estudo|experiencia|adr|trace|backlog|contract|canon]" >&2; exit 2 ;;
```

- [ ] **Step 8: Rodar a suíte inteira e cronometrar (NFR-01)**

Run: `time bash scripts/eval.sh`
Expected: `eval: tudo verde`, incluindo `=== eval: experiencia ===` → `test-check-experiencia: tudo verde`; tempo total bem abaixo de 60s.

- [ ] **Step 9: Distribuir o script via ASSET_MAP**

Em `scripts/asset-map.sh`, dentro do array `ASSET_MAP`, após a linha do `check-estudo.sh` — localize:
```
  "scripts/check-estudo.sh                zion-prd-estudo"
```
e adicione **abaixo**:
```
  "scripts/check-experiencia.sh           zion-prd-write zion-prd-decompose"
```

- [ ] **Step 10: Sincronizar os derivados**

Run: `./scripts/sync-assets.sh`
Expected: `sync-assets: ok`. Isso copia `check-experiencia.sh` para `skills/zion-prd-write/references/` e `skills/zion-prd-decompose/references/`.

Confirme: `ls skills/zion-prd-write/references/check-experiencia.sh skills/zion-prd-decompose/references/check-experiencia.sh`
Expected: os dois caminhos existem.

- [ ] **Step 11: Canonizar em architecture.md §3 (tabela de scripts) e §4**

Em `docs/architecture.md §3`, na tabela de scripts, após a linha do `check-estudo.sh` — localize:
```
| scripts/check-estudo.sh | Verificador das regras decidíveis do documento de estudo (Estágio 0). |
```
adicione **abaixo**:
```
| scripts/check-experiencia.sh | Verificador do carregador de experiência (marcador `Superfície de uso` + âncora na PRD/backlog). |
```

Ainda na §3, após a linha do `test-check-estudo.sh` — localize:
```
| scripts/test-check-estudo.sh | Auto-teste do check-estudo.sh contra fixtures. |
```
adicione **abaixo**:
```
| scripts/test-check-experiencia.sh | Auto-teste do check-experiencia.sh contra fixtures. |
```

Na §4, na nota de references executáveis — localize:
```
Também distribuídos como references executáveis: `scripts/check-prd.sh`, `scripts/check-adr.sh`,
`scripts/check-estudo.sh`, `scripts/trace-prd.sh`, `scripts/trace-backlog.sh` (cobertos pela
tabela da §3).
```
troque por:
```
Também distribuídos como references executáveis: `scripts/check-prd.sh`, `scripts/check-adr.sh`,
`scripts/check-estudo.sh`, `scripts/check-experiencia.sh`, `scripts/trace-prd.sh`,
`scripts/trace-backlog.sh` (cobertos pela tabela da §3).
```

- [ ] **Step 12: Canonizar em prd.md — RF-11 (§6) e artefatos (§12)**

Em `docs/prd.md §6`, no Épico E5, atualize o texto de RF-11 — localize:
```
dos artefatos (fronteira sem stack, NFR com número, RF por épico, evidência presente por risco)
e ecoa o veredito nos estágios.
```
troque por:
```
dos artefatos (fronteira sem stack, NFR com número, RF por épico, evidência presente por risco,
âncora de experiência presente quando há superfície de uso) e ecoa o veredito nos estágios.
```

Na §12 (Rastreabilidade), na linha de RF-11 — localize:
```
| RF-11 | E5 | scripts/check-prd.sh · scripts/check-adr.sh · scripts/check-estudo.sh · scripts/trace-prd.sh · scripts/trace-backlog.sh |
```
troque por:
```
| RF-11 | E5 | scripts/check-prd.sh · scripts/check-adr.sh · scripts/check-estudo.sh · scripts/check-experiencia.sh · scripts/trace-prd.sh · scripts/trace-backlog.sh |
```

Na §12, na linha de RF-12 — localize:
```
| RF-12 | E5 | scripts/eval.sh · scripts/test-check-estudo.sh · scripts/fixtures/ · docs/guias/avaliacao-harness.md |
```
troque por:
```
| RF-12 | E5 | scripts/eval.sh · scripts/test-check-estudo.sh · scripts/test-check-experiencia.sh · scripts/fixtures/ · docs/guias/avaliacao-harness.md |
```

- [ ] **Step 13: Verificar guards + drift**

Run: `./scripts/sync-assets.sh && ./scripts/check-assets.sh && ./scripts/check-canon.sh && bash scripts/eval.sh`
Expected: `sync-assets: ok`, `check-assets` sem drift, `check-canon: limpo` (C3 vê os dois scripts novos citados na §3), `eval: tudo verde`.

- [ ] **Step 14: Commit**

```bash
git add scripts/check-experiencia.sh scripts/test-check-experiencia.sh scripts/fixtures/ scripts/eval.sh scripts/asset-map.sh docs/architecture.md docs/prd.md skills/zion-prd-write/references/ skills/zion-prd-decompose/references/
git commit -m "feat(check): check-experiencia.sh — verificador advisório do carregador de experiência (RF-11)"
```

---

## Task 3: Discovery captura o marcador + critérios de qualidade

O discovery ganha o gate advisório e o bloco Experiência. Consolida **todos** os critérios de conclusão de `quality-rules.md` (discovery/prd/decompose) e a nota "experiência é NFR, não tela" — regra de qualidade se afina num lugar só (`RN-05`). Sem script novo → sem exigência nova de canon de máquina; só sync dos derivados.

**Files:**
- Modify: `skills/zion-prd-discovery/SKILL.md`
- Modify: `assets/quality-rules.md`
- Modify: `docs/prd.md` (§6 RF-01)

**Interfaces:**
- Consumes: nada de máquina.
- Produces: `docs/discovery.md` passa a conter, quando surface=sim, a **linha bare** `Superfície de uso: sim` e um bloco `## Experiência` em prosa. Esses viram a fonte que `zion-prd-write` (Task 4) carrega para a §7.

- [ ] **Step 1: Adicionar o gate + captura ao discovery (Fase 1)**

Em `skills/zion-prd-discovery/SKILL.md`, ao final da seção `## Fase 1 — Validar entrada bruta`, após a frase que termina em `pressione os blocos incompletos ou fracos do discovery atual.`, adicione um parágrafo novo:
```markdown

**Gate de superfície (advisório, `não` por default):** pergunte uma vez — *"o usuário opera uma
superfície de uso (tela, CLI, API que alguém maneja)?"*. Aconselha, não bloqueia (`RN-01`). Em
**não** (o default), skip silencioso: o fluxo fica idêntico ao de hoje, sem bloco de experiência.
Em **sim**, a Fase 2/3 captura a camada de experiência (abaixo).
```

- [ ] **Step 2: Ramificar o enquadramento do brainstorming por surface (Fase 2/3)**

Ainda em `skills/zion-prd-discovery/SKILL.md`, na seção `## Fase 2/3 — Formatar e auto-delegar`, no bullet do **Modo do-zero** — localize:
```
- **Modo do-zero:** "Refine a visão do produto: (1) visão em UMA frase; (2) persona principal
  nomeada; (3) quadro faz/não-faz, com os 'não faz' explícitos. Grave o resultado em
  `docs/discovery.md`."
```
troque por:
```
- **Modo do-zero:** "Refine a visão do produto: (1) visão em UMA frase; (2) persona principal
  nomeada; (3) quadro faz/não-faz, com os 'não faz' explícitos. Grave o resultado em
  `docs/discovery.md`." **Quando surface=sim,** acrescente um 4º item de captura — a camada de
  experiência, em **prosa**, ancorada na persona nomeada: contexto de uso, expectativas, e a
  qualidade de experiência que o produto precisa transmitir — sempre no nível de o-quê ("o usuário
  percebe X"), nunca "tela Y". Grave em `docs/discovery.md` a **linha bare** `Superfície de uso: sim`
  e um bloco `## Experiência` com essa prosa.
```

No bullet do **Modo retomar/revisar** — localize:
```
  blocos: visão em UMA frase, persona nomeada, quadro faz/não-faz. Regrave `docs/discovery.md`."
```
troque por:
```
  blocos: visão em UMA frase, persona nomeada, quadro faz/não-faz. Regrave `docs/discovery.md`."
  **Idempotência do bloco de experiência:** pressione o bloco `## Experiência` só se estiver
  incompleto ou se o usuário pedir para revê-lo; não reescreva o que já está sólido. Se o gate de
  superfície virou `sim` agora, capture o bloco pela primeira vez.
```

- [ ] **Step 3: Cobrar o bloco na validação (Fase 4)**

Ainda em `skills/zion-prd-discovery/SKILL.md`, na seção `## Fase 4 — Validar saída (aconselha)` — localize:
```
`#criterios-de-conclusao`: visão em 1 frase ∧ ≥1 persona nomeada ∧ pelo menos um "não faz" explícito.
Emita veredito: `✓` cada item ok, ou `⚠ <item> faltando — sugiro <correção>`. Não reverta nada.
```
troque por:
```
`#criterios-de-conclusao`: visão em 1 frase ∧ ≥1 persona nomeada ∧ pelo menos um "não faz" explícito
∧ **quando surface=sim**, a linha `Superfície de uso: sim` e o bloco `## Experiência` presentes.
Emita veredito: `✓` cada item ok, ou `⚠ <item> faltando — sugiro <correção>`. Não reverta nada.
```

- [ ] **Step 4: Atualizar os critérios de conclusão em quality-rules.md**

Em `assets/quality-rules.md`, seção `## Critérios de conclusão por estágio {#criterios-de-conclusao}`.

Bullet **discovery** — localize:
```
- **discovery** (`docs/discovery.md`): tem visão em 1 frase ∧ ≥1 persona nomeada ∧ pelo menos um
  "não faz" explícito no quadro faz/não-faz.
```
troque por:
```
- **discovery** (`docs/discovery.md`): tem visão em 1 frase ∧ ≥1 persona nomeada ∧ pelo menos um
  "não faz" explícito no quadro faz/não-faz ∧ **quando o produto opera uma superfície de uso**, a
  linha bare `Superfície de uso: sim` e um bloco `## Experiência` em prosa (contexto de uso e a
  qualidade de experiência esperada, no nível de o-quê). `não` é o default — produto sem superfície
  não grava bloco algum.
```

Bullet **prd** — localize:
```
- **prd** (`docs/PRD.md`): escopo in/out explícito ∧ `RF-xx` agrupados por épico (1 frase cada) ∧
  NFRs com número ∧ **zero** stack / critério de aceite / tela. As três regras decidíveis
  (zero-stack, NFR-com-número, RF-por-épico) são verificadas por `check-prd.sh` — a Fase 4 roda o
  script e ecoa o veredito.
```
troque por:
```
- **prd** (`docs/PRD.md`): escopo in/out explícito ∧ `RF-xx` agrupados por épico (1 frase cada) ∧
  NFRs com número ∧ **zero** stack / critério de aceite / tela ∧ **quando surface=sim**, a §7
  carrega a linha `Superfície de uso: sim` e ≥1 NFR tagueado `(experiência)` com número. As três
  regras decidíveis (zero-stack, NFR-com-número, RF-por-épico) são verificadas por `check-prd.sh`;
  a âncora de experiência é verificada por `check-experiencia.sh docs/PRD.md` — a Fase 4 roda os
  scripts e ecoa o veredito.
```

Bullet **decompose** — localize:
```
  colunas Pasta/Status por máquina). Ambos são artefatos **derivados**, reconciliados a qualquer momento
  por `/zion-prd-trace`; não são mantidos à mão.
```
troque por:
```
  colunas Pasta/Status por máquina). Ambos são artefatos **derivados**, reconciliados a qualquer momento
  por `/zion-prd-trace`; não são mantidos à mão ∧ **quando surface=sim**, ≥1 spec que toca a
  superfície tem a coluna `Âncora de experiência` preenchida (verificada por
  `check-experiencia.sh docs/PRD.md docs/backlog.md`; spec puramente de backend deixa a âncora em branco).
```

- [ ] **Step 5: Adicionar a nota "experiência é NFR, não tela" em quality-rules.md**

Em `assets/quality-rules.md`, ao final da seção `## Fronteira o-quê/por-quê vs. como {#fronteira}` (após o blockquote que termina em `**preso aos ADRs** já provados (veja `#anatomia-plan`), sem reabrir decisões.`), adicione:
```markdown

> **Experiência é NFR, não tela.** A qualidade de experiência entra na PRD como **NFR mensurável**
> tagueado `(experiência)` — "o usuário conclui a tarefa-núcleo em ≤N passos" —, nunca como arranjo
> de tela. Já está dentro do que esta fronteira admite (NFR com número). O `check-experiencia.sh`
> verifica a **presença** dessa âncora (marcador `Superfície de uso` → NFR tagueado → coluna no
> backlog); detectar "tela" vazando continua julgamento humano — o denylist do `check-prd.sh`
> permanece stack-only.
```

- [ ] **Step 6: Canonizar RF-01 em prd.md §6**

Em `docs/prd.md §6`, Épico E1, texto de RF-01 — localize:
```
`RF-01` O autor conduz a descoberta enxuta (visão, persona,
  faz/não-faz) e a retoma entre sessões sem perder o que já respondeu.
```
troque por:
```
`RF-01` O autor conduz a descoberta enxuta (visão, persona,
  faz/não-faz) e a retoma entre sessões sem perder o que já respondeu, capturando — quando o produto
  opera uma superfície de uso — a qualidade de experiência esperada como marcador que viaja a jusante.
```

- [ ] **Step 7: Sincronizar derivados e verificar guards**

Run: `./scripts/sync-assets.sh && ./scripts/check-assets.sh && ./scripts/check-canon.sh`
Expected: `sync-assets: ok`, sem drift, `check-canon: limpo`. (`quality-rules.md` é mapeado a 9 skills; o sync regenera todos os `references/quality-rules.md`. A edição de RF-01 é prosa sem termo de denylist — o dogfood C7 do `check-prd` sobre `docs/prd.md` segue limpo.)

- [ ] **Step 8: Commit**

```bash
git add skills/zion-prd-discovery/SKILL.md assets/quality-rules.md docs/prd.md skills/*/references/quality-rules.md
git commit -m "feat(discovery): captura advisória de superfície de uso + bloco de experiência (RF-01)"
```

---

## Task 4: PRD write carrega o marcador e aterrissa o NFR

`zion-prd-write` lê o marcador do discovery, carrega para a §7 e pede ≥1 NFR de experiência tagueado; a Fase 4 roda `check-experiencia.sh docs/PRD.md`. O template ganha o slot. Sem script novo → só sync.

**Files:**
- Modify: `skills/zion-prd-write/SKILL.md`
- Modify: `assets/templates/prd-skeleton.md`
- Modify: `docs/prd.md` (§6 RF-04)

**Interfaces:**
- Consumes: `docs/discovery.md` (linha `Superfície de uso: sim/não` + bloco `## Experiência` da Task 3); o executável `references/check-experiencia.sh` (distribuído na Task 2).
- Produces: `docs/PRD.md §7` com a linha `Superfície de uso: sim` e ≥1 `NFR-0x (experiência)`. Consumido pela Fase 4 do próprio write (check só limb-PRD) e por `zion-prd-decompose` (Task 5).

- [ ] **Step 1: Carregar o marcador + aterrissar o NFR (Fase 3)**

Em `skills/zion-prd-write/SKILL.md`, seção `## Fase 3 — Auto-delegar`, ao final do parágrafo que termina em `desafiando cada `RF-xx` e cada NFR antes de fechá-la.`, adicione:
```markdown

**Carregador de experiência:** leia a linha `Superfície de uso: sim/não` de `docs/discovery.md`
e **carregue-a** para o cabeçalho da §7 (NFRs) como a linha bare `Superfície de uso: sim` (ou
`não`). Quando `sim`, derive do bloco `## Experiência` do discovery **≥1 NFR de experiência**,
tagueado e machine-legível: `NFR-0x` (experiência): a tarefa-núcleo é concluída em ≤N passos.
Carrega um número, como todo NFR — a tag `(experiência)` é o marcador que o check casa. Mantém a
fronteira: é NFR mensurável, nunca tela.
```

- [ ] **Step 2: Rodar o check na Fase 4**

Em `skills/zion-prd-write/SKILL.md`, seção `## Fase 4 — Validar saída (aconselha) — GUARDA DE FRONTEIRA`, após o parágrafo que termina em `Exit `1` = há achados; exit `0` = limpo.`, adicione:
```markdown

**Âncora de experiência (advisório).** Quando a §7 tem `Superfície de uso: sim`, rode também:

    bash references/check-experiencia.sh docs/PRD.md

Sem arg de backlog, o check avalia só o **limb-PRD**: surface=sim ∧ nenhum NFR tagueado
`(experiência)` → ⚠ *"produto com superfície mas sem âncora de experiência na PRD"*. Ecoe o
veredito e sugira aterrissar ≥1 NFR de experiência. Exit `1` = achado; `0` = limpo. Não reverte
(`RN-01`).
```

- [ ] **Step 3: Adicionar o marcador + slot de NFR ao template**

Em `assets/templates/prd-skeleton.md`, seção `## 7. NFRs (com números)` — localize:
```
## 7. NFRs (com números)
Requisitos não-funcionais mensuráveis (performance, disponibilidade, segurança) — sempre com número.
```
troque por:
```
## 7. NFRs (com números)
Superfície de uso: não

> `sim/não` carregado do `docs/discovery.md`. Vira `sim` quando o produto opera uma superfície de
> uso (tela, CLI, API que alguém maneja). Quando `sim`, inclua ≥1 NFR de experiência tagueado e
> machine-legível — `NFR-0x` (experiência): a tarefa-núcleo é concluída em ≤N passos. É NFR
> mensurável, nunca tela (veja `quality-rules.md` `#fronteira`).

Requisitos não-funcionais mensuráveis (performance, disponibilidade, segurança) — sempre com número.
```

> **Nota:** a linha bare `Superfície de uso: não` é o default seguro (o check pula produto sem
> superfície). A guia com o exemplo `(experiência)` mora em **blockquote `>`** de propósito: o
> `has_exp_nfr` do `check-experiencia.sh` ignora linhas `>`, então boilerplate deixado no template
> não finge presença de âncora.

- [ ] **Step 4: Canonizar RF-04 em prd.md §6**

Em `docs/prd.md §6`, Épico E1, texto de RF-04 — localize:
```
`RF-04` O autor
  preenche a PRD seção a seção a partir de um esqueleto, com requisitos de uma frase agrupados por
  épico.
```
troque por:
```
`RF-04` O autor
  preenche a PRD seção a seção a partir de um esqueleto, com requisitos de uma frase agrupados por
  épico, carregando o marcador de superfície para os NFRs e aterrissando ≥1 NFR de experiência
  mensurável quando há superfície de uso.
```

- [ ] **Step 5: Verificar a invocação do skill de ponta a ponta**

O skill roda `bash references/check-experiencia.sh docs/PRD.md`. Confirme que o reference distribuído funciona com as fixtures da Task 2:

Run: `bash skills/zion-prd-write/references/check-experiencia.sh scripts/fixtures/prd-exp-sim-dirty.md`
Expected: exit 1, imprime `limb-PRD` e `check-experiencia: 1 achado(s)`.

Run: `bash skills/zion-prd-write/references/check-experiencia.sh scripts/fixtures/prd-exp-sim-clean.md`
Expected: exit 0, `check-experiencia: limpo`.

- [ ] **Step 6: Sincronizar derivados e verificar guards**

Run: `./scripts/sync-assets.sh && ./scripts/check-assets.sh && ./scripts/check-canon.sh`
Expected: `sync-assets: ok`, sem drift, `check-canon: limpo`. (`prd-skeleton.md` é mapeado a `zion-prd-write`; o sync regenera `skills/zion-prd-write/references/prd-skeleton.md`. A edição de RF-04 é prosa sem stack.)

- [ ] **Step 7: Commit**

```bash
git add skills/zion-prd-write/SKILL.md assets/templates/prd-skeleton.md docs/prd.md skills/zion-prd-write/references/
git commit -m "feat(prd-write): carrega o marcador de superfície e aterrissa o NFR de experiência (RF-04)"
```

---

## Task 5: Decompose ancora a experiência no backlog

`zion-prd-decompose` ganha a coluna `Âncora de experiência` no template do backlog, preenche a âncora nas specs que **tocam** a superfície (≥1, não toda spec), ganha o braço de experiência no INVEST, e a Fase 4 roda `check-experiencia.sh docs/PRD.md docs/backlog.md`. Verifica que `trace-backlog.sh` preserva a coluna nova (comportamento já existente — column-agnostic).

**Files:**
- Modify: `skills/zion-prd-decompose/SKILL.md`
- Modify: `assets/templates/backlog.md`
- Modify: `docs/prd.md` (§6 RF-05)

**Interfaces:**
- Consumes: `docs/PRD.md §7` (marcador da Task 4); `references/check-experiencia.sh` (Task 2); `references/backlog.md` (template, editado aqui).
- Produces: `docs/backlog.md` com a coluna `Âncora de experiência` preenchida em ≥1 spec quando surface=sim. `trace-backlog.sh` reconcilia sem tocar a coluna nova.

- [ ] **Step 1: Verificar que trace-backlog.sh preserva a coluna nova (regressão manual)**

Antes de editar, confirme o comportamento column-agnostic do `trace-backlog.sh` (ele só recomputa Pasta/Status; preserva as demais células e a ordem). Use a fixture limpa da Task 2:

```bash
cp scripts/fixtures/backlog-exp-clean.md /tmp/backlog-anchor-test.md
bash scripts/trace-backlog.sh /tmp/backlog-anchor-test.md /diretorio/de/specs/inexistente
grep -q "usuário conclui a tarefa-núcleo em ≤3 passos" /tmp/backlog-anchor-test.md && echo "ANCHOR-PRESERVED" || echo "ANCHOR-LOST"
rm -f /tmp/backlog-anchor-test.md
```
Expected: o `trace-backlog` roda (bootstrap: specs ausentes → Pasta `—`, tudo ☐), e a última linha imprime `ANCHOR-PRESERVED` — a célula da âncora sobreviveu à reescrita da tabela.

> Se imprimir `ANCHOR-LOST`, **pare**: o `trace-backlog.sh` precisaria de ajuste (fora do escopo previsto pelo spec, que assume preservação). Investigue `rewrite_table` antes de seguir.

- [ ] **Step 2: Adicionar a coluna ao template do backlog**

Em `assets/templates/backlog.md`, a tabela canônica — localize:
```
| Spec (slug) | Demo (1 frase) | RFs | Release | Pasta | Status |
|-------------|----------------|-----|---------|-------|--------|
| walking-skeleton | _(a demo ponta-a-ponta mínima que prova o pipeline inteiro)_ | RF-xx | R0 | — | ☐ pendente |
| spec-exemplo | _(o que o usuário faz/vê ao final desta spec — o teste INVEST)_ | RF-xx, RF-yy | R1 | — | ☐ pendente |
```
troque por:
```
| Spec (slug) | Demo (1 frase) | Âncora de experiência | RFs | Release | Pasta | Status |
|-------------|----------------|-----------------------|-----|---------|-------|--------|
| walking-skeleton | _(a demo ponta-a-ponta mínima que prova o pipeline inteiro)_ | _(a experiência que esta spec demonstra, se toca a superfície — senão em branco)_ | RF-xx | R0 | — | ☐ pendente |
| spec-exemplo | _(o que o usuário faz/vê ao final desta spec — o teste INVEST)_ | — | RF-xx, RF-yy | R1 | — | ☐ pendente |
```

Ainda em `assets/templates/backlog.md`, na nota do cabeçalho — localize:
```
> **Não edite Pasta/Status à mão.** As colunas humanas (Spec/Demo/RFs/Release) você preenche e o
> script preserva. A **primeira tabela** deste arquivo é a canônica (dono do script); todo o resto
```
troque por:
```
> **Não edite Pasta/Status à mão.** As colunas humanas (Spec/Demo/Âncora de experiência/RFs/Release)
> você preenche e o script preserva. Preencha `Âncora de experiência` só nas specs que **tocam** a
> superfície de uso (≥1, não toda spec; spec de backend puro deixa em branco). A **primeira tabela**
> deste arquivo é a canônica (dono do script); todo o resto
```

- [ ] **Step 3: Preencher a âncora no fatiamento (Fase 2/3)**

Em `skills/zion-prd-decompose/SKILL.md`, seção `## Fase 2/3 — Formatar e auto-delegar`, ao final do parágrafo que termina em `Esses três campos são as colunas humanas do backlog (Fase 4).`, adicione:
```markdown

**Âncora de experiência:** quando a PRD tem `Superfície de uso: sim`, preencha a coluna `Âncora de
experiência` na(s) spec(s) que **tocam** a superfície — **≥1, não toda spec** — em prosa de o-quê
("o usuário conclui a tarefa-núcleo em ≤N passos"). Spec puramente de backend deixa a âncora em
branco (evita o falso-positivo de exigir âncora onde não há superfície).
```

- [ ] **Step 4: Braço de experiência no INVEST + rodar o check (Fase 4)**

Em `skills/zion-prd-decompose/SKILL.md`, seção `## Fase 4 — Validar saída (aconselha)`, no bullet do INVEST — localize:
```
- Cada spec passa no **INVEST** (`#invest`) — aplique o teste-relâmpago "esta spec, sozinha, dá uma
  demo ponta-a-ponta?". Se a resposta é "só a UI" ou "só o back", a spec é **horizontal** → aponte e
  sugira refatiar pelos eixos do **SPIDR**.
```
troque por:
```
- Cada spec passa no **INVEST** (`#invest`) — aplique o teste-relâmpago "esta spec, sozinha, dá uma
  demo ponta-a-ponta?". Se a resposta é "só a UI" ou "só o back", a spec é **horizontal** → aponte e
  sugira refatiar pelos eixos do **SPIDR**. **Braço de experiência (surface=sim, advisório):** "esta
  spec, onde toca a superfície, demonstra a experiência — ou só a função?".
```

Ainda na Fase 4, antes de `Emita veredito por item. Não reverta — aconselhe.` (a última linha da seção), adicione um bullet novo:
```markdown
- **Âncora de experiência (advisório).** Quando a PRD tem `Superfície de uso: sim`, rode:

      bash references/check-experiencia.sh docs/PRD.md docs/backlog.md

  Avalia os dois limbs: **limb-PRD** (nenhum NFR tagueado `(experiência)` na PRD) e **limb-backlog**
  (nenhuma spec com a coluna `Âncora de experiência` preenchida) → ⚠ *"produto com superfície mas
  nenhuma spec ancora a experiência"*. Ecoe o veredito; não reverta (`RN-01`).
```

- [ ] **Step 5: Canonizar RF-05 em prd.md §6**

Em `docs/prd.md §6`, Épico E1, texto de RF-05 — localize:
```
`RF-05` O autor
  decompõe a PRD em épicos, story map e specs verticais priorizadas, com o walking skeleton como
  spec zero.
```
troque por:
```
`RF-05` O autor
  decompõe a PRD em épicos, story map e specs verticais priorizadas, com o walking skeleton como
  spec zero, ancorando a experiência em ≥1 spec que toca a superfície de uso quando ela existe.
```

- [ ] **Step 6: Verificar a invocação do skill + guards**

Run: `bash skills/zion-prd-decompose/references/check-experiencia.sh scripts/fixtures/prd-exp-sim-clean.md scripts/fixtures/backlog-exp-dirty.md`
Expected: exit 1, imprime `limb-backlog`, `check-experiencia: 1 achado(s)`.

Run: `bash skills/zion-prd-decompose/references/check-experiencia.sh scripts/fixtures/prd-exp-sim-clean.md scripts/fixtures/backlog-exp-clean.md`
Expected: exit 0, `check-experiencia: limpo`.

Run: `./scripts/sync-assets.sh && ./scripts/check-assets.sh && ./scripts/check-canon.sh`
Expected: `sync-assets: ok`, sem drift, `check-canon: limpo`.

- [ ] **Step 7: Commit**

```bash
git add skills/zion-prd-decompose/SKILL.md assets/templates/backlog.md docs/prd.md skills/zion-prd-decompose/references/
git commit -m "feat(decompose): ancora a experiência no backlog + braço INVEST (RF-05)"
```

---

## Task 6: Changelog §13 + verificação final da suíte

Fecha a canonização com a linha de changelog (cenário C2 — comportamento de RF existente muda + artefato de script novo) e roda a suíte inteira como gate final. A §13 cita ADR-014 (Task 1) e RF-01/04/05/11 (existem na §6) — todas as referências resolvem.

**Files:**
- Modify: `docs/prd.md` (§13)

**Interfaces:**
- Consumes: ADR-014 (Task 1), RF-01/04/05/11 (§6, já editados).
- Produces: nada a jusante.

- [ ] **Step 1: Adicionar a linha de changelog em prd.md §13**

Em `docs/prd.md §13` (Histórico de mudanças), na tabela, após a última linha existente — localize:
```
| 2026-07-18 | C2 | `RF-17` alterado: reabrir um estudo pelo slug para revisar, sem re-digitar o candidato | remover o atrito de re-digitar o candidato só para revisitar um estudo já gravado | skills/zion-prd-estudo (Fase 0) |
```
adicione **abaixo**:
```
| 2026-07-18 | C2 | Carregador forte de experiência: `RF-01`/`RF-04`/`RF-05`/`RF-11` passam a carregar o marcador `Superfície de uso` e a âncora de experiência (NFR tagueado + coluna no backlog); `check-experiencia.sh` novo | app rico em função e pobre de uso — o sinal de experiência precisa nascer no discovery e sobreviver até o backlog | ADR-014 · scripts/check-experiencia.sh · skills/zion-prd-discovery · skills/zion-prd-write · skills/zion-prd-decompose |
```

- [ ] **Step 2: Verificar as regras decidíveis da §13 (via dogfood do check-prd)**

Run: `bash scripts/check-prd.sh prd docs/prd.md`
Expected: `check-prd: limpo` (todo `RF-xx` da §13 existe na §6; `ADR-014` existe em `docs/adr/`; Cenário `C2` válido; sem stack).

- [ ] **Step 3: Rodar a suíte mecânica completa (gate final)**

Run: `time bash scripts/eval.sh && ./scripts/check-assets.sh && ./scripts/check-canon.sh && bash scripts/check-adr.sh docs/adr`
Expected: `eval: tudo verde`, `check-assets` sem drift, `check-canon: limpo`, `check-adr: limpo`; `eval.sh` bem abaixo de 60s (`NFR-01`).

- [ ] **Step 4: Commit**

```bash
git add docs/prd.md
git commit -m "docs(prd): changelog do carregador de experiência (§13, cenário C2)"
```

---

## Self-Review

**1. Spec coverage** (cada componente do spec → task):
- §Componentes 1 (Discovery / RF-01, gate + captura + idempotência): **Task 3** (skill Fase 1/2/3/4 + RF-01).
- §Componentes 2 (PRD write / RF-04, carrega marcador + NFR + template): **Task 4** (skill Fase 3/4 + prd-skeleton + RF-04).
- §Componentes 3 (Decompose / RF-05, coluna + braço INVEST + preservação trace): **Task 5** (skill + backlog template + RF-05 + Step 1 regressão trace-backlog).
- §Componentes 4 (o verificador / RF-11, script dedicado, dois limbs, scope presença): **Task 2** (check-experiencia.sh + RF-11 + §12).
- §Componentes 5 (avaliação mecânica / RF-12, NFR-04, NFR-01): **Task 2** (test + fixtures pareadas + eval wiring + timing).
- §Componentes 6 (governança / ADR-014 + canonização): **Task 1** (ADR-014 + §2), distribuída por commit em cada task (arch §3/§4 + prd §6/§12 na Task 2; §13 na Task 6; RFs nas Tasks 3/4/5); quality-rules na Task 3.
- §Não faz: honrado — nenhuma detecção de "tela" por máquina (check é presença-only, denylist stack-only); NFR forçado só surface=sim; âncora ≥1 spec, não toda; sem dependência externa; specify-prompt/trace intocados; nenhum gate bloqueante.
- §Critérios de conclusão: cobertos pelos Steps de verificação de cada task + a suíte final da Task 6.

**2. Placeholder scan:** sem "TBD/TODO/etc." — todo script e fixture têm conteúdo integral; todos os edits têm âncora localize→troque exata.

**3. Type/name consistency:**
- Marcador: `Superfície de uso: sim/não` (bare) — consistente em check (`surface_value`), template (Task 4), skills, fixtures, quality-rules.
- Tag: `(experiência)` — consistente em check (`has_exp_nfr`), template, skill write, fixture `prd-exp-sim-clean.md`, RF-04.
- Coluna: `Âncora de experiência` — consistente em check (`backlog_anchor_filled`), template backlog, fixtures, skill decompose, quality-rules.
- Funções do check: `surface_value`, `has_exp_nfr`, `backlog_anchor_filled` — definidas e chamadas com os mesmos nomes.
- Achados: `limb-PRD`, `limb-backlog` — emitidos pelo check e asseridos pelo teste (Steps 4/5/6 da Task 2) com o mesmo literal.
- Fixtures: os 5 nomes criados na Task 2 batem exatamente com os referenciados em `test-check-experiencia.sh` e nos Steps de verificação das Tasks 4/5.
- eval selector `experiencia` — registrado em `TESTS`, `ORDER` e nas duas strings de uso.

**Ordem de commits (canon-safe):** cada commit deixa o repo canon-clean + adr-clean. Task 1 cria ADR-014 antes de qualquer referência a ele (Task 6 §13). Task 2 cita os dois scripts novos em `architecture.md §3` no mesmo commit (C3). Guards do pre-commit (`sync-assets` → `check-canon` → `check-adr`) validados manualmente em cada task antes do commit.
