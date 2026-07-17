# Spike: evidência proporcional ao risco + `check-adr.sh` (R3) — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Reenquadrar o Estágio 2 do harness de "spike com código descartável (sempre)" para **evidência proporcional ao risco**, e instrumentar a presença dessa evidência com um verificador mecânico `check-adr.sh` — no mesmo molde de `check-prd.sh` (R1) e `trace-prd.sh` (R2).

**Architecture:** Um script novo `scripts/check-adr.sh` (verifica *presença* de evidência por ADR, exit 0/1/2, advisório) com fixtures + auto-teste + passo no CI + sync via `asset-map.sh`. Em paralelo, quatro edições de conteúdo: o template do ADR ganha um campo `Evidência`; `quality-rules.md` ganha a heurística `#risco-do-spike` e ajusta o critério `spike`; a skill `/zion-prd-spike` classifica por risco (Fase 1), ramifica (Fase 2/3) e roda o script (Fase 4); o guia e os docs de uso são reenquadrados.

**Tech Stack:** Bash (POSIX-ish, `set -u`, `awk`/`sed`/`grep`), GitHub Actions, Markdown. Sem novas dependências.

**Fonte:** `docs/superpowers/specs/2026-07-17-spike-evidencia-por-risco-design.md`.

---

## Estrutura de arquivos

Novos:
- `scripts/check-adr.sh` — o verificador de presença de evidência (uma responsabilidade: presença, não qualidade).
- `scripts/test-check-adr.sh` — auto-teste do verificador contra fixtures.
- `scripts/fixtures/adr/clean/` — ADRs que passam limpos (um de execução com spike dir completo, um de conhecimento com URL).
- `scripts/fixtures/adr/dirty/` — ADRs que disparam um achado de cada tipo.

Modificados:
- `scripts/asset-map.sh` — nova entrada de sync `scripts/check-adr.sh → zion-prd-spike`.
- `.github/workflows/check-assets.yml` — novo passo de auto-teste.
- `skills/zion-adr-new/SKILL.md` — template ganha o campo `Evidência`; pergunta de Contexto reformulada; documenta a convenção do spike dir.
- `assets/quality-rules.md` — nova âncora `#risco-do-spike`; edição da linha `spike` em `#criterios-de-conclusao`.
- `skills/zion-prd-spike/SKILL.md` — Fase 1 classifica por risco; Fase 2/3 ramifica; Fase 4 roda `check-adr.sh`.
- `docs/guia-prd-para-spec-kit.md` — Passo 2 reescrito ("evidência proporcional ao risco").
- `docs/como-usar.md`, `README.md` — menção ao Estágio 2 reenquadrado + verificação mecânica.
- `skills/*/references/*` — **regenerados pelo sync** (nunca editados à mão).

**Convenção de resolução de caminho do spike (decisão-chave do script):** o `check-adr.sh` recebe `<dir-de-adrs>` (ex.: `docs/adr`). A linha `Evidência` de um ADR de execução cita o caminho *repo-relativo* `docs/adr/spikes/ADR-00x-<slug>/`. O script **ignora o prefixo citado** e resolve o spike dir como `<dir>/spikes/<seg>`, onde `<seg>` é o segmento após `spikes/`. Isso faz as fixtures (`scripts/fixtures/adr/clean`) funcionarem sem depender de o caminho literal existir no repo real.

---

## Task 1: `check-adr.sh` — fixtures + auto-teste falhando (RED)

Cria as fixtures e o auto-teste **antes** do script. Rodar o teste agora deve falhar porque `check-adr.sh` ainda não existe — esse é o RED correto (o comportamento sob teste está ausente).

**Files:**
- Create: `scripts/fixtures/adr/clean/ADR-001-motor.md`
- Create: `scripts/fixtures/adr/clean/ADR-002-persistencia.md`
- Create: `scripts/fixtures/adr/clean/spikes/ADR-001-motor/README.md`
- Create: `scripts/fixtures/adr/clean/spikes/ADR-001-motor/medicao.txt`
- Create: `scripts/fixtures/adr/dirty/ADR-001-sem-evidencia.md`
- Create: `scripts/fixtures/adr/dirty/ADR-002-conhecimento-sem-url.md`
- Create: `scripts/fixtures/adr/dirty/ADR-003-spike-sem-readme.md`
- Create: `scripts/fixtures/adr/dirty/ADR-004-spike-ausente.md`
- Create: `scripts/fixtures/adr/dirty/ADR-005-spike-vazio.md`
- Create: `scripts/fixtures/adr/dirty/spikes/ADR-003-sem-readme/artefato.txt`
- Create: `scripts/test-check-adr.sh`

- [ ] **Step 1: Criar a fixture clean de execução (ADR-001) + seu spike dir**

Arquivo `scripts/fixtures/adr/clean/ADR-001-motor.md`:

```markdown
# ADR-001 — Motor de renderização do diagrama

- **Status:** Aceito
- **Data:** 2026-07-17
- **Decisores:** time
- **Evidência:** docs/adr/spikes/ADR-001-motor/

## Contexto

Risco de execução: a viabilidade do round-trip texto ↔ canvas só se resolve rodando. Que evidência
sustenta a decisão, e qual risco ela endereça? O spike em `docs/adr/spikes/ADR-001-motor/`.

## Decisão

Usar o motor X. Descartado o motor Y.

## Consequências

Trade-offs aceitos.

## Status

Aceito.
```

Arquivo `scripts/fixtures/adr/clean/spikes/ADR-001-motor/README.md`:

```markdown
# Spike ADR-001 — motor de renderização

- **Pergunta:** o round-trip texto ↔ canvas é viável com o motor X?
- **O que foi rodado:** protótipo descartável em `medicao.txt`.
- **Veredito:** viável; latência dentro do alvo.
```

Arquivo `scripts/fixtures/adr/clean/spikes/ADR-001-motor/medicao.txt`:

```text
p95 render = 42ms (alvo < 100ms)
```

- [ ] **Step 2: Criar a fixture clean de conhecimento (ADR-002)**

Arquivo `scripts/fixtures/adr/clean/ADR-002-persistencia.md`:

```markdown
# ADR-002 — Persistência local entre sessões

- **Status:** Aceito
- **Data:** 2026-07-17
- **Decisores:** time
- **Evidência:** https://exemplo.org/comparativo-persistencia (licença MIT, ecossistema maduro)

## Contexto

Risco de conhecimento: decisão documentável sem rodar. Que evidência sustenta a decisão, e qual
risco ela endereça? A fonte de pesquisa citada acima.

## Decisão

Persistir localmente. Descartado o backend remoto no MVP.

## Consequências

Trade-offs aceitos.

## Status

Aceito.
```

- [ ] **Step 3: Criar a fixture dirty ADR-001 (sem-evidencia)**

Arquivo `scripts/fixtures/adr/dirty/ADR-001-sem-evidencia.md` — **sem** a linha `- **Evidência:**`:

```markdown
# ADR-001 — Decisão sem evidência

- **Status:** Proposto
- **Data:** 2026-07-17
- **Decisores:** time

## Contexto

Nenhuma evidência foi apontada.

## Decisão

Uma decisão qualquer.

## Consequências

Trade-offs.

## Status

Proposto.
```

- [ ] **Step 4: Criar a fixture dirty ADR-002 (conhecimento sem URL/caminho)**

Arquivo `scripts/fixtures/adr/dirty/ADR-002-conhecimento-sem-url.md` — Evidência em prosa, **sem** URL, sem `/`, sem `.<ext>`:

```markdown
# ADR-002 — Conhecimento sem lastro

- **Status:** Proposto
- **Data:** 2026-07-17
- **Decisores:** time
- **Evidência:** biblioteca madura e amplamente adotada segundo a comunidade

## Contexto

Risco de conhecimento, mas a linha de evidência não aponta fonte alguma.

## Decisão

Uma decisão qualquer.

## Consequências

Trade-offs.

## Status

Proposto.
```

- [ ] **Step 5: Criar a fixture dirty ADR-003 (spike sem README) + o dir com artefato mas sem README**

Arquivo `scripts/fixtures/adr/dirty/ADR-003-spike-sem-readme.md`:

```markdown
# ADR-003 — Spike sem README

- **Status:** Proposto
- **Data:** 2026-07-17
- **Decisores:** time
- **Evidência:** docs/adr/spikes/ADR-003-sem-readme/

## Contexto

Risco de execução; o spike dir existe mas não tem README.md.

## Decisão

Uma decisão qualquer.

## Consequências

Trade-offs.

## Status

Proposto.
```

Arquivo `scripts/fixtures/adr/dirty/spikes/ADR-003-sem-readme/artefato.txt` (o dir tem conteúdo, mas **nenhum** `README.md`):

```text
medição solta, sem README
```

- [ ] **Step 6: Criar a fixture dirty ADR-004 (spike dir ausente)**

Arquivo `scripts/fixtures/adr/dirty/ADR-004-spike-ausente.md` — aponta um dir que **não** existe no repo (não crie o dir):

```markdown
# ADR-004 — Spike dir ausente

- **Status:** Proposto
- **Data:** 2026-07-17
- **Decisores:** time
- **Evidência:** docs/adr/spikes/ADR-004-ausente/

## Contexto

Risco de execução; o spike dir referenciado não existe.

## Decisão

Uma decisão qualquer.

## Consequências

Trade-offs.

## Status

Proposto.
```

- [ ] **Step 7: Criar a fixture dirty ADR-005 (spike dir vazio)**

Arquivo `scripts/fixtures/adr/dirty/ADR-005-spike-vazio.md` — o dir vazio é criado em runtime pelo teste (git não versiona dir vazio):

```markdown
# ADR-005 — Spike dir vazio

- **Status:** Proposto
- **Data:** 2026-07-17
- **Decisores:** time
- **Evidência:** docs/adr/spikes/ADR-005-vazio/

## Contexto

Risco de execução; o spike dir existe mas está vazio.

## Decisão

Uma decisão qualquer.

## Consequências

Trade-offs.

## Status

Proposto.
```

- [ ] **Step 8: Escrever o auto-teste `scripts/test-check-adr.sh`**

Arquivo `scripts/test-check-adr.sh`:

```bash
#!/usr/bin/env bash
# Auto-teste do check-adr.sh contra fixtures. Semente da suíte de avaliação (R7).
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
CHECK="scripts/check-adr.sh"
FIX="scripts/fixtures/adr"
fail=0

assert_exit() {  # desc  exit_esperado  exit_veio
  if [ "$2" != "$3" ]; then echo "FALHOU: $1 (exit esperado $2, veio $3)"; fail=1
  else echo "ok: $1"; fi
}
assert_contains() {  # desc  agulha  palheiro
  if printf '%s' "$3" | grep -qi -- "$2"; then echo "ok: $1"
  else echo "FALHOU: $1 (não achou: $2)"; fail=1; fi
}

# 1. Fixture clean → exit 0 / limpo
out="$(bash "$CHECK" "$FIX/clean")"; rc=$?
assert_exit "clean sai 0" 0 "$rc"
assert_contains "clean reporta limpo" "check-adr: limpo" "$out"

# 2. Fixture dirty → exit 1 + um achado de cada tipo.
# spike-dir-vazio precisa de um dir vazio (git não versiona dir vazio) → cria em runtime.
mkdir -p "$FIX/dirty/spikes/ADR-005-vazio"
out="$(bash "$CHECK" "$FIX/dirty")"; rc=$?
rm -rf "$FIX/dirty/spikes/ADR-005-vazio"
assert_exit "dirty sai 1" 1 "$rc"
assert_contains "dirty acha sem-evidencia"        "sem-evidencia" "$out"
assert_contains "dirty acha spike-dir-ausente"    "spike-dir-ausente" "$out"
assert_contains "dirty acha spike-dir-vazio"      "spike-dir-vazio" "$out"
assert_contains "dirty acha spike-sem-readme"     "spike-sem-readme" "$out"
assert_contains "dirty acha evidencia-sem-lastro" "evidencia-sem-lastro" "$out"

# 3. Erro de uso: dir inexistente → exit 2
out="$(bash "$CHECK" "$FIX/nao-existe" 2>&1)"; rc=$?
assert_exit "dir inexistente sai 2" 2 "$rc"

if [ "$fail" -eq 0 ]; then echo "test-check-adr: tudo verde"; else echo "test-check-adr: FALHOU"; exit 1; fi
```

- [ ] **Step 9: Rodar o teste para confirmar que falha (RED)**

Run: `bash scripts/test-check-adr.sh; echo "exit=$?"`
Expected: FALHA — `check-adr.sh` não existe, então `bash "$CHECK" ...` retorna 127 e as asserções de exit/limpo falham. Saída final `test-check-adr: FALHOU`, `exit=1`. (RED correto: o script sob teste está ausente.)

- [ ] **Step 10: Commit das fixtures + teste**

```bash
git add scripts/fixtures/adr scripts/test-check-adr.sh
git commit -m "test(check-adr): fixtures + auto-teste (RED, sem o script ainda)"
```

---

## Task 2: `check-adr.sh` — implementação (GREEN)

**Files:**
- Create: `scripts/check-adr.sh`
- Test: `scripts/test-check-adr.sh`

- [ ] **Step 1: Escrever `scripts/check-adr.sh`**

Arquivo `scripts/check-adr.sh`:

```bash
#!/usr/bin/env bash
# check-adr.sh — verificador de presença de evidência nos ADRs (R3).
# Verifica a PRESENÇA do lastro (não a qualidade), no mesmo molde de
# check-prd.sh (R1) e trace-prd.sh (R2): o script verifica, o humano decide.
# Exit 0 = limpo · 1 = achados · 2 = erro de uso/ambiente.
# Lido pela Fase 4 de /zion-prd-spike, que aconselha (não bloqueia).
#
# Uso:
#   check-adr.sh <dir-de-adrs>     # ex.: check-adr.sh docs/adr
#
# Para cada <dir>/ADR-*.md (glob de filhos diretos → ignora spikes/):
#   1. sem linha **Evidência:** preenchida (vazia ou placeholder <…>) → sem-evidencia
#   2. Evidência aponta docs/adr/spikes/<seg>/ (risco de execução):
#        <dir>/spikes/<seg> ausente        → spike-dir-ausente
#        <dir>/spikes/<seg> vazio          → spike-dir-vazio
#        <dir>/spikes/<seg> sem README.md  → spike-sem-readme
#   3. Evidência de conhecimento sem URL nem caminho → evidencia-sem-lastro
set -u

usage() { echo "uso: check-adr.sh <dir-de-adrs>" >&2; exit 2; }

DIR="${1:-}"
[ -n "$DIR" ] || usage
case "$DIR" in -*) usage ;; esac
[ -d "$DIR" ] || { echo "check-adr: diretório não encontrado: $DIR" >&2; exit 2; }

# Valor da primeira linha `- **Evidência:**`, sem o rótulo. Casa bytes literais
# (a acentuação de "Evidência" é UTF-8 fixa no template e nas fixtures).
evidence_value() {  # $1 arquivo
  sed -n 's/^[[:space:]]*-[[:space:]]*\*\*Evidência:\*\*[[:space:]]*//p' "$1" | head -1
}

findings=""
add() {  # $1 achado
  if [ -z "$findings" ]; then findings="$1"; else findings="$findings
$1"; fi
}

nadr=0
for f in "$DIR"/ADR-*.md; do
  [ -f "$f" ] || continue
  nadr=$((nadr+1))
  label="$(basename "$f")"
  ev="$(evidence_value "$f")"
  ev="$(printf '%s' "$ev" | sed 's/[[:space:]]*$//')"   # trim à direita

  # Vazia ou placeholder <…> → sem evidência.
  if [ -z "$ev" ] || printf '%s' "$ev" | grep -qE '^<.*>$'; then
    add "$label: sem-evidencia — nenhuma linha **Evidência:** preenchida (aponte o spike dir ou a fonte de pesquisa)"
    continue
  fi

  case "$ev" in
    *docs/adr/spikes/*)
      # Risco de execução. Ignora o prefixo citado; resolve <dir>/spikes/<seg>.
      seg="$(printf '%s' "$ev" | grep -oE 'docs/adr/spikes/[^[:space:])]+' | head -1 | sed 's#^docs/adr/spikes/##; s#/*$##')"
      target="$DIR/spikes/$seg"
      if [ ! -d "$target" ]; then
        add "$label: spike-dir-ausente — $ev não existe (crie o spike dir ou corrija o caminho)"
      elif [ -z "$(ls -A "$target" 2>/dev/null)" ]; then
        add "$label: spike-dir-vazio — $target sem artefatos (adicione o spike + README.md)"
      elif [ ! -f "$target/README.md" ]; then
        add "$label: spike-sem-readme — $target sem README.md (documente pergunta/execução/veredito)"
      fi
      ;;
    *)
      # Risco de conhecimento: precisa de URL (http…) ou de um caminho de artefato.
      if ! printf '%s' "$ev" | grep -qE 'https?://|/|\.[A-Za-z0-9]+'; then
        add "$label: evidencia-sem-lastro — \"$ev\" sem URL nem caminho de artefato (aponte a fonte)"
      fi
      ;;
  esac
done

if [ "$nadr" -eq 0 ]; then
  echo "check-adr: nenhum ADR-*.md em $DIR" >&2
  exit 2
fi

if [ -n "$findings" ]; then
  printf '%s\n' "$findings"
  count="$(printf '%s\n' "$findings" | grep -c .)"
  echo "check-adr: $count achado(s)"
  exit 1
else
  echo "check-adr: limpo"
  exit 0
fi
```

- [ ] **Step 2: Tornar executável (paridade com os outros scripts)**

Run: `chmod +x scripts/check-adr.sh`
Expected: sem saída. (O script é invocado com `bash` explícito, então o bit é cosmético — mas mantém a paridade com `check-prd.sh`/`trace-prd.sh`.)

- [ ] **Step 3: Rodar o teste para confirmar que passa (GREEN)**

Run: `bash scripts/test-check-adr.sh; echo "exit=$?"`
Expected: todas as linhas `ok:`, última linha `test-check-adr: tudo verde`, `exit=0`.

- [ ] **Step 4: Sanidade contra o próprio spec dir do repo (se existir `docs/adr`)**

Run: `[ -d docs/adr ] && bash scripts/check-adr.sh docs/adr; echo "exit=$?"`
Expected: roda sem erro de ambiente. Como os ADRs atuais do repo ainda não têm o campo `Evidência`, é normal ver achados `sem-evidencia` e `exit=1` — isso é esperado e **não** é um bug do script (a auditoria retroativa está fora de escopo, §9 do spec). Se `docs/adr` não existir, o comando é no-op (`exit=0`).

- [ ] **Step 5: Commit da implementação**

```bash
git add scripts/check-adr.sh
git commit -m "feat(check-adr): verificador de presença de evidência por ADR (R3)"
```

---

## Task 3: Distribuição (asset-map + sync) e CI

Coloca o `check-adr.sh` no pipeline de sync (para ir ao `references/` da skill que o roda) e adiciona o auto-teste ao CI, ao lado dos de `check-prd` e `trace-prd`.

**Files:**
- Modify: `scripts/asset-map.sh:8-15`
- Modify: `.github/workflows/check-assets.yml:12-15`

- [ ] **Step 1: Adicionar a entrada no `asset-map.sh`**

Edit em `scripts/asset-map.sh` — adicione a linha do `check-adr` logo após a do `trace-prd`:

old_string:
```
  "scripts/check-prd.sh                   zion-prd-write zion-prd-specify-prompt"
  "scripts/trace-prd.sh                   zion-prd-trace zion-prd-decompose"
)
```

new_string:
```
  "scripts/check-prd.sh                   zion-prd-write zion-prd-specify-prompt"
  "scripts/trace-prd.sh                   zion-prd-trace zion-prd-decompose"
  "scripts/check-adr.sh                   zion-prd-spike"
)
```

- [ ] **Step 2: Rodar o sync para gerar a cópia no `references/`**

Run: `bash scripts/sync-assets.sh`
Expected: `sync-assets: ok`. Cria `skills/zion-prd-spike/references/check-adr.sh`.

- [ ] **Step 3: Confirmar que o `check-assets` não acusa drift**

Run: `bash scripts/check-assets.sh; echo "exit=$?"`
Expected: `check-assets: sem drift`, `exit=0`.

- [ ] **Step 4: Adicionar o passo de CI**

Edit em `.github/workflows/check-assets.yml`:

old_string:
```
      - name: Auto-teste do check-prd
        run: bash scripts/test-check-prd.sh
      - name: Auto-teste do trace-prd
        run: bash scripts/test-trace-prd.sh
```

new_string:
```
      - name: Auto-teste do check-prd
        run: bash scripts/test-check-prd.sh
      - name: Auto-teste do trace-prd
        run: bash scripts/test-trace-prd.sh
      - name: Auto-teste do check-adr
        run: bash scripts/test-check-adr.sh
```

- [ ] **Step 5: Verificar o YAML e rodar o teste uma vez pelo caminho do CI**

Run: `bash scripts/test-check-adr.sh && grep -n "check-adr" .github/workflows/check-assets.yml`
Expected: `test-check-adr: tudo verde` e a linha do passo `Auto-teste do check-adr` aparece.

- [ ] **Step 6: Commit**

```bash
git add scripts/asset-map.sh .github/workflows/check-assets.yml skills/zion-prd-spike/references/check-adr.sh
git commit -m "ci(check-adr): sync via asset-map + passo de auto-teste no check-assets"
```

---

## Task 4: Campo `Evidência` no template do ADR (`zion-adr-new`)

O template gerado ganha o campo obrigatório `Evidência` no bloco de metadados; a pergunta de Contexto é reformulada; documenta-se a convenção do spike dir (que o `zion-adr-new` **não** cria).

**Files:**
- Modify: `skills/zion-adr-new/SKILL.md:16` (intro)
- Modify: `skills/zion-adr-new/SKILL.md:43-51` (metadados + Contexto do template)
- Modify: `skills/zion-adr-new/SKILL.md` (nova subseção de convenção, antes de `## Saída`)

- [ ] **Step 1: Reenquadrar a frase de intro**

Edit em `skills/zion-adr-new/SKILL.md`:

old_string:
```
ver `references/process-context.md` — para registrar as 2–3 decisões que mudam a PRD inteira,
sustentadas por um spike que você de fato rodou.
```

new_string:
```
ver `references/process-context.md` — para registrar as 2–3 decisões que mudam a PRD inteira,
sustentadas por **evidência proporcional ao risco** (spike de código para risco de execução; fonte
de pesquisa para risco de conhecimento — ver `#risco-do-spike` em `references/quality-rules.md`).
```

- [ ] **Step 2: Adicionar o campo `Evidência` ao bloco de metadados do template e reformular a pergunta de Contexto**

Edit em `skills/zion-adr-new/SKILL.md`:

old_string:
```
- **Status:** Proposto
- **Data:** <preencher>
- **Decisores:** <preencher>

## Contexto

Qual é a força / problema / dúvida estruturante? Que restrições e requisitos (RF-xx / RN-xx / NFRs)
estão em jogo? Que spike foi rodado para sustentar a decisão?
```

new_string:
```
- **Status:** Proposto
- **Data:** <preencher>
- **Decisores:** <preencher>
- **Evidência:** <um dos dois — o tipo casa com o risco da decisão>
    · execução (só se resolve rodando): `docs/adr/spikes/ADR-<n>-<slug>/` (dir com README.md + artefatos descartáveis)
    · conhecimento (documentável sem rodar): <URL ou caminho do artefato de pesquisa que sustenta a decisão>

## Contexto

Qual é a força / problema / dúvida estruturante? Que restrições e requisitos (RF-xx / RN-xx / NFRs)
estão em jogo? Que evidência (spike de código ou pesquisa) sustenta a decisão, e qual o risco que
ela endereça?
```

- [ ] **Step 3: Documentar a convenção do spike dir (nova subseção antes de `## Saída`)**

Edit em `skills/zion-adr-new/SKILL.md`:

old_string:
```
## Saída

Um arquivo `docs/adr/ADR-<n>-<slug>.md` pronto para revisão. Cada ADR aceito vira uma **restrição**
na PRD (seção de restrições) e alimenta a `constitution` do Spec Kit.
```

new_string:
```
## Convenção do spike dir (risco de execução)

Quando a decisão é de **risco de execução**, o campo `Evidência` aponta um diretório
`docs/adr/spikes/ADR-<n>-<slug>/` (mesmo número/slug do ADR), que deve conter:

- **`README.md`** (obrigatório) — a pergunta do spike, o que foi rodado e o veredito.
- **Artefatos descartáveis** — o código/medições do spike (livre).

O `zion-adr-new` **não** cria o spike dir: o spike é escrito na Fase 2/3 de `/zion-prd-spike`, antes
ou junto do ADR. O template só documenta a convenção e o campo que a referencia. A presença dessa
evidência é verificada por `check-adr.sh` (rodado pela Fase 4 de `/zion-prd-spike`).

## Saída

Um arquivo `docs/adr/ADR-<n>-<slug>.md` pronto para revisão. Cada ADR aceito vira uma **restrição**
na PRD (seção de restrições) e alimenta a `constitution` do Spec Kit.
```

- [ ] **Step 4: Verificar as edições**

Run: `grep -n "Evidência\|risco de execução\|não.*cria o spike dir" skills/zion-adr-new/SKILL.md`
Expected: o campo `- **Evidência:**` no template, a pergunta de Contexto reformulada, e a subseção de convenção aparecem.

- [ ] **Step 5: Commit**

```bash
git add skills/zion-adr-new/SKILL.md
git commit -m "feat(adr): campo Evidência no template + convenção do spike dir (R3)"
```

---

## Task 5: Heurística `#risco-do-spike` e critério `spike` no `quality-rules.md`

Edita o **asset canônico** `assets/quality-rules.md`; o sync propaga para os `references/` das 7 skills que o consomem.

**Files:**
- Modify: `assets/quality-rules.md:43-44` (linha `spike`)
- Modify: `assets/quality-rules.md:61-63` (nova seção entre `#criterios-de-conclusao` e `## INVEST`)

- [ ] **Step 1: Editar a linha `spike` do critério de conclusão**

Edit em `assets/quality-rules.md`:

old_string:
```
- **spike** (`docs/adr/ADR-00x-*.md`): cada decisão estruturante tem um ADR com Contexto/Decisão/
  Consequências ∧ o ADR referencia um spike real.
```

new_string:
```
- **spike** (`docs/adr/ADR-00x-*.md`): cada decisão estruturante tem um ADR com Contexto/Decisão/
  Consequências ∧ o ADR carrega **evidência do tipo certo para seu risco** (spike de código para
  risco de execução; fonte de pesquisa para risco de conhecimento — ver `#risco-do-spike`). A
  presença da evidência é verificada por `check-adr.sh` — a Fase 4 roda o script e ecoa o veredito.
```

- [ ] **Step 2: Inserir a seção `## Risco do spike` antes de `## INVEST e SPIDR`**

Edit em `assets/quality-rules.md`:

old_string:
```
## INVEST e SPIDR {#invest}
```

new_string:
```
## Risco do spike {#risco-do-spike}

Base da classificação da Fase 1 de `/zion-prd-spike`: cada decisão estruturante endereça um tipo de
risco, e o risco escolhe o **meio da evidência**.

- **Risco de execução** — a dúvida **só se resolve rodando algo**: performance sob carga,
  compatibilidade, viabilidade de integração, comportamento observável. **Meio: spike de código** em
  `docs/adr/spikes/ADR-00x-<slug>/` (dir com `README.md` + artefatos descartáveis).
- **Risco de conhecimento** — trade-off **documentável sem rodar**: maturidade, licença, custo de
  manutenção, ecossistema, aderência conceitual. **Meio: pesquisa (deep-research) com fonte citada.**

Regra prática: se você decide lendo docs/benchmarks de terceiros, é **conhecimento**; se precisa do
*seu* caso rodando para confiar, é **execução**. A presença da evidência do tipo certo é verificada
por `check-adr.sh` — o script confere presença, o humano decide qualidade.

## INVEST e SPIDR {#invest}
```

- [ ] **Step 3: Rodar o sync e confirmar ausência de drift**

Run: `bash scripts/sync-assets.sh && bash scripts/check-assets.sh; echo "exit=$?"`
Expected: `sync-assets: ok`, `check-assets: sem drift`, `exit=0`. (O sync reescreve `quality-rules.md` no `references/` de zion-prd-discovery, zion-prd-spike, zion-prd-write, zion-prd-decompose, zion-prd-constitution-prompt, zion-prd-specify-prompt e zion-prd-plan-prompt.)

- [ ] **Step 4: Verificar a âncora e a referência de máquina**

Run: `grep -n "#risco-do-spike\|check-adr.sh" assets/quality-rules.md`
Expected: a nova âncora `{#risco-do-spike}` e a menção a `check-adr.sh` na linha `spike`.

- [ ] **Step 5: Commit (asset + references regenerados juntos)**

```bash
git add assets/quality-rules.md skills/*/references/quality-rules.md
git commit -m "feat(quality-rules): heurística #risco-do-spike + critério spike com check-adr (R3)"
```

---

## Task 6: Fluxo da skill `/zion-prd-spike` (Fase 1 classifica, 2/3 ramifica, 4 roda o script)

**Files:**
- Modify: `skills/zion-prd-spike/SKILL.md:44` (fim da Fase 1 — passo de classificação)
- Modify: `skills/zion-prd-spike/SKILL.md:46-52` (Fase 2/3)
- Modify: `skills/zion-prd-spike/SKILL.md:54-58` (Fase 4)

- [ ] **Step 1: Adicionar o passo de classificação por risco ao fim da Fase 1**

Edit em `skills/zion-prd-spike/SKILL.md`:

old_string:
```
**Convergência (todos os caminhos, aconselha).** Peça ao usuário para **confirmar**, **editar**
(trocar uma) ou **substituir** (rejeitar todas e ditar as suas). Lista fraca — nenhuma passa no
filtro, virou 4 dúvidas menores, ou ficou com 1 decisão só → aponte e sugira, mas a lista confirmada
pelo usuário é a que vale. Não bloqueie.
```

new_string:
```
**Convergência (todos os caminhos, aconselha).** Peça ao usuário para **confirmar**, **editar**
(trocar uma) ou **substituir** (rejeitar todas e ditar as suas). Lista fraca — nenhuma passa no
filtro, virou 4 dúvidas menores, ou ficou com 1 decisão só → aponte e sugira, mas a lista confirmada
pelo usuário é a que vale. Não bloqueie.

**Classificação por risco (aconselha).** Fechadas as 2–3 decisões, **classifique cada uma** como
*risco de execução* ou *risco de conhecimento*, cada classificação com **uma linha de justificativa**
ancorada na heurística `#risco-do-spike` de `references/quality-rules.md`. Peça para **confirmar ou
editar** — mesmo padrão de convergência. Não bloqueie. O risco confirmado escolhe o meio da evidência
na Fase 2/3.
```

- [ ] **Step 2: Reescrever a Fase 2/3 para ramificar por risco**

Edit em `skills/zion-prd-spike/SKILL.md`:

old_string:
```
## Fase 2/3 — Formatar e auto-delegar
Para cada decisão, no mesmo turno:
1. Levante os trade-offs das opções (custo de manutenção, limites). Se a skill built-in
   `deep-research` estiver disponível, invoque-a para isso; se **não** estiver (harness antigo ou
   variante), avise "`deep-research` (built-in) indisponível — seguindo com pesquisa manual" e
   conduza o levantamento manualmente. Nunca quebre por falta dela.
2. Invoque `zion-adr-new` com o título da decisão para registrar o ADR em `docs/adr/`.
```

new_string:
```
## Fase 2/3 — Formatar e auto-delegar (ramifica por risco)
Para cada decisão, no mesmo turno, **conforme o risco confirmado na Fase 1**:

- **Risco de conhecimento** → levante os trade-offs das opções (custo de manutenção, limites). Se a
  skill built-in `deep-research` estiver disponível, invoque-a; se **não** estiver (harness antigo ou
  variante), avise "`deep-research` (built-in) indisponível — seguindo com pesquisa manual" e conduza
  o levantamento manualmente. Nunca quebre por falta dela. Depois invoque `zion-adr-new` com o título
  da decisão e preencha o campo **Evidência** do ADR com a **URL/caminho** da fonte.
- **Risco de execução** → determine o próximo número de ADR (mesma regra do `zion-adr-new`: maior
  `docs/adr/ADR-*.md` + 1, três dígitos) e o slug do título; **escreva o spike de código** em
  `docs/adr/spikes/ADR-00x-<slug>/` com um `README.md` (pergunta + o que foi rodado + veredito) e os
  artefatos descartáveis; então invoque `zion-adr-new` (que reusa o mesmo número) e preencha o campo
  **Evidência** com o **caminho do dir** `docs/adr/spikes/ADR-00x-<slug>/`.

O número do ADR é conhecido na criação, então o slug do spike dir casa com o do ADR.
```

- [ ] **Step 3: Reescrever a Fase 4 para rodar `check-adr.sh`**

Edit em `skills/zion-prd-spike/SKILL.md`:

old_string:
```
## Fase 4 — Validar saída (aconselha)
Confira contra o critério **spike** de `quality-rules.md` `#criterios-de-conclusao`: cada decisão tem
um `docs/adr/ADR-00x-*.md` com Contexto/Decisão/Consequências, e o ADR referencia um spike real. Se
um ADR não menciona um spike de fato rodado, avise: "sem spike, a spec nasce ambígua — sugiro rodar o
spike antes de aceitar a ADR". Não bloqueie.
```

new_string:
```
## Fase 4 — Rodar `check-adr.sh` (aconselha)
Rode `bash references/check-adr.sh docs/adr/` e **ecoe o veredito** (com o achado e a ação sugerida).
O script confere a **presença** da evidência do tipo certo por ADR — `sem-evidencia`,
`spike-dir-ausente`, `spike-dir-vazio`, `spike-sem-readme`, `evidencia-sem-lastro` — presença, não
qualidade. Exit `0` limpo / `1` achados / `2` erro de uso. Mantenha o tom advisório: "complete a
evidência ou justifique", **não reverte**. Confira também, em prosa, contra o critério **spike** de
`references/quality-rules.md` `#criterios-de-conclusao`.
```

- [ ] **Step 4: Verificar as três edições**

Run: `grep -n "Classificação por risco\|ramifica por risco\|check-adr.sh docs/adr" skills/zion-prd-spike/SKILL.md`
Expected: as três âncoras novas aparecem (Fase 1, Fase 2/3, Fase 4).

- [ ] **Step 5: Commit**

```bash
git add skills/zion-prd-spike/SKILL.md
git commit -m "feat(zion-prd-spike): classifica por risco, ramifica evidência, roda check-adr (R3)"
```

---

## Task 7: Reescrever o Passo 2 do guia ("evidência proporcional ao risco")

**Files:**
- Modify: `docs/guia-prd-para-spec-kit.md:83-104`

- [ ] **Step 1: Substituir o bloco do Passo 2**

Edit em `docs/guia-prd-para-spec-kit.md`:

old_string:
```
## Passo 2 — Spikes técnicos + ADRs

- **Objetivo:** responder com **código descartável** (não com opinião) as 2–3 decisões estruturantes
  que mudam a PRD inteira, e registrá-las como ADRs **antes** de fechar a PRD.
- **Skill(s):**
  - `deep-research` (real) — levantar trade-offs das opções (ex.: bibliotecas concorrentes).
  - `superpowers:brainstorming` (real) — decidir critérios de escolha.
  - `zion-adr-new` (real) — registra a decisão como ADR em `docs/adr/`.
- **Invocação (exemplo)** — *você executaria assim:*
  ```text
  # Avaliar opções antes de comprometer a arquitetura:
  /deep-research  Trade-offs entre <Opção A> e <Opção B> para <capacidade central>,
  considerando custo de manutenção e limites conhecidos.

  # Registrar a decisão:
  /zion-adr-new  "Escolha de <decisão estruturante>"   # gera docs/adr/ADR-001-*.md
  ```
- **Entradas:** dúvidas técnicas estruturantes levantadas no Passo 1; repositórios de spike descartáveis.
- **Saídas / artefatos:** `docs/adr/ADR-001-*.md`, `docs/adr/ADR-002-*.md` — cada uma com contexto,
  decisão, consequências. Elas viram **restrições** na PRD (seção 8) e na `constitution`.
- **Critério de conclusão:** cada decisão estruturante tem um ADR aceito, sustentado por um spike que
  você de fato rodou. Sem isso, as specs nascem ambíguas.
```

new_string:
```
## Passo 2 — Spikes técnicos + ADRs

- **Objetivo:** responder as 2–3 decisões estruturantes que mudam a PRD inteira com **evidência
  proporcional ao risco** — não "código sempre" (força código onde o risco é de conhecimento) nem
  "pesquisa sempre" (teatro de conformidade). O *risco* da decisão escolhe o meio, e a decisão vira
  um ADR **antes** de fechar a PRD.
  - **Risco de execução** (só se resolve rodando: performance, compatibilidade, viabilidade) →
    **spike de código** em `docs/adr/spikes/ADR-00x-<slug>/`.
  - **Risco de conhecimento** (documentável sem rodar: maturidade, licença, custo, ecossistema) →
    **pesquisa** (`deep-research`) com fonte citada.
- **Skill(s):**
  - `deep-research` (real) — levantar trade-offs no caminho de conhecimento.
  - `superpowers:brainstorming` (real) — decidir critérios de escolha.
  - `zion-adr-new` (real) — registra a decisão como ADR em `docs/adr/` (com o campo `Evidência`).
- **Invocação (exemplo)** — *os dois caminhos:*
  ```text
  # Caminho de CONHECIMENTO (pesquisa → ADR):
  /deep-research  Trade-offs entre <Opção A> e <Opção B> para <capacidade central>,
  considerando custo de manutenção e limites conhecidos.
  /zion-adr-new  "Escolha de <decisão de conhecimento>"   # Evidência = URL/caminho da fonte

  # Caminho de EXECUÇÃO (spike de código → ADR):
  #   escreva o spike em docs/adr/spikes/ADR-00x-<slug>/ (README.md + artefatos), então:
  /zion-adr-new  "Viabilidade de <decisão de execução>"   # Evidência = docs/adr/spikes/ADR-00x-<slug>/
  ```
- **Entradas:** dúvidas técnicas estruturantes levantadas no Passo 1; spikes de código descartáveis
  (risco de execução).
- **Saídas / artefatos:** `docs/adr/ADR-001-*.md`, `docs/adr/ADR-002-*.md` — cada uma com contexto,
  decisão, consequências e o campo `Evidência`. Elas viram **restrições** na PRD (seção 8) e na
  `constitution`.
- **Critério de conclusão:** cada decisão estruturante tem um ADR com Contexto/Decisão/Consequências
  **∧** o ADR carrega evidência do tipo certo para seu risco (spike de código para execução; fonte de
  pesquisa para conhecimento). A presença da evidência é verificada por `check-adr.sh` — a Fase 4
  roda o script e ecoa o veredito. Sem isso, as specs nascem ambíguas.
```

- [ ] **Step 2: Verificar a reescrita**

Run: `grep -n "evidência proporcional ao risco\|check-adr.sh\|os dois caminhos" docs/guia-prd-para-spec-kit.md`
Expected: as três marcas do reenquadramento aparecem no Passo 2.

- [ ] **Step 3: Commit**

```bash
git add docs/guia-prd-para-spec-kit.md
git commit -m "docs(guia): Passo 2 reenquadrado para evidência proporcional ao risco (R3)"
```

---

## Task 8: Menções nos docs de uso (`como-usar.md` + `README.md`)

**Files:**
- Modify: `docs/como-usar.md:138-139` (Fase 4 do Estágio 2)
- Modify: `README.md:97-105` (seção de CI/verificação mecânica)

- [ ] **Step 1: Atualizar a descrição da Fase 4 do Estágio 2 em `como-usar.md`**

Edit em `docs/como-usar.md`:

old_string:
```
**Fase 4:** avisa se algum ADR não referencia um spike de fato rodado — *"sem spike, a spec nasce
ambígua"*. Cada ADR aceito vira **restrição** na seção 8 da PRD.
```

new_string:
```
**Fase 4:** roda `references/check-adr.sh docs/adr/` e ecoa o veredito — confere a **presença** da
evidência do tipo certo por ADR (spike de código para risco de execução; fonte de pesquisa para risco
de conhecimento), não a qualidade. Advisório: *"complete a evidência ou justifique"*, não reverte.
Cada ADR aceito vira **restrição** na seção 8 da PRD.
```

- [ ] **Step 2: Incluir o `check-adr` na seção de verificação mecânica do `README.md`**

Edit em `README.md`:

old_string:
```
O CI roda `./scripts/check-assets.sh` como guard de drift (backstop para `--no-verify`
ou quem não rodou o `setup-hooks.sh`) e `bash scripts/test-check-prd.sh` como auto-teste do
verificador de regras. Para checar/sincronizar/testar à mão:

```bash
./scripts/sync-assets.sh       # regenera references/ a partir de assets/
./scripts/check-assets.sh      # falha se algum references/ divergir
bash scripts/test-check-prd.sh # auto-teste do check-prd.sh contra as fixtures
```

As Fases 4 de `/zion-prd-write` e `/zion-prd-specify-prompt` rodam `scripts/check-prd.sh` (sincronizado
para o `references/` de cada uma) para verificar mecanicamente as regras decidíveis (zero-stack,
NFR-com-número, RF-por-épico). A denylist de stack é curada em `assets/quality-rules.md` (`#denylist`).
```

new_string:
```
O CI roda `./scripts/check-assets.sh` como guard de drift (backstop para `--no-verify`
ou quem não rodou o `setup-hooks.sh`) e os auto-testes `test-check-prd.sh`, `test-trace-prd.sh` e
`test-check-adr.sh` dos verificadores. Para checar/sincronizar/testar à mão:

```bash
./scripts/sync-assets.sh        # regenera references/ a partir de assets/
./scripts/check-assets.sh       # falha se algum references/ divergir
bash scripts/test-check-prd.sh  # auto-teste do check-prd.sh contra as fixtures
bash scripts/test-check-adr.sh  # auto-teste do check-adr.sh contra as fixtures
```

As Fases 4 de `/zion-prd-write` e `/zion-prd-specify-prompt` rodam `scripts/check-prd.sh` (sincronizado
para o `references/` de cada uma) para verificar mecanicamente as regras decidíveis (zero-stack,
NFR-com-número, RF-por-épico). A denylist de stack é curada em `assets/quality-rules.md` (`#denylist`).
No Estágio 2, a Fase 4 de `/zion-prd-spike` roda `scripts/check-adr.sh` para verificar a **presença**
da evidência do tipo certo por ADR (evidência proporcional ao risco de execução/conhecimento).
```

- [ ] **Step 3: Verificar as menções**

Run: `grep -n "check-adr" docs/como-usar.md README.md`
Expected: `check-adr.sh` aparece na Fase 4 do `como-usar.md` e na seção de verificação do `README.md`.

- [ ] **Step 4: Commit**

```bash
git add docs/como-usar.md README.md
git commit -m "docs(uso): Estágio 2 reenquadrado + check-adr na verificação mecânica (R3)"
```

---

## Task 9: Verificação final ponta-a-ponta

- [ ] **Step 1: Rodar todos os auto-testes e o guard de drift**

Run:
```bash
bash scripts/test-check-prd.sh && \
bash scripts/test-trace-prd.sh && \
bash scripts/test-check-adr.sh && \
bash scripts/check-assets.sh
```
Expected: `test-check-prd: tudo verde`, `test-trace-prd: tudo verde`, `test-check-adr: tudo verde`, `check-assets: sem drift`.

- [ ] **Step 2: Confirmar que a cópia sincronizada é idêntica ao canônico**

Run: `diff scripts/check-adr.sh skills/zion-prd-spike/references/check-adr.sh && echo IDENTICOS`
Expected: `IDENTICOS`.

- [ ] **Step 3: Confirmar a árvore limpa**

Run: `git status --short`
Expected: sem saída (tudo commitado).

---

## Auto-revisão (cobertura do spec)

- **§4.1 heurística de risco** → Task 5 Step 2. **§4.2 critério de conclusão** → Task 5 Step 1. **§4.3 guia** → Task 7.
- **§5.1 Fase 1 classifica** → Task 6 Step 1. **§5.2 Fase 2/3 ramifica** → Task 6 Step 2. **§5.3 Fase 4 roda o script** → Task 6 Step 3.
- **§6.1 campo Evidência + pergunta de Contexto** → Task 4 Steps 1–2. **§6.2 estrutura do spike dir + "não cria"** → Task 4 Step 3.
- **§7.1 contrato do script** (exit 0/1/2, 5 achados, formato de saída) → Task 2 Step 1. **§7.2 distribuição** (asset-map, sync, check-assets) → Task 3. **§7.3 auto-teste** (fixtures clean/dirty, test-check-adr, passo de CI) → Tasks 1 e 3.
- **§8 superfície de mudança** — todos os arquivos da tabela cobertos; `skills/*/references/` regenerados pelo sync (Tasks 3 e 5), nunca à mão.
- **§9 fora de escopo** — respeitado: sem auditoria retroativa, sem julgar qualidade, sem bloqueio (todos os gates advisórios), sem tocar na colisão de nome "spike".
```
