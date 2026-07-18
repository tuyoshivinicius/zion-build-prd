# Rename "fatia" → "spec" Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Renomear a unidade de trabalho do harness de "fatia" para "spec" (convergindo com o Spec Kit), sem retrocompatibilidade, mantendo o verbo ("fatiar/fatiamento/refatiar/re-fatiamento") e o conceito "épico" intocados.

**Architecture:** Rename mecânico + prosa em três frentes: (1) o núcleo mecânico — template do backlog, `trace-backlog.sh`, fixtures e teste, cujo parser passa a casar a coluna humana por `slug` e a de máquina por `pasta`; (2) a prosa viva dos assets canônicos, skills e docs; (3) as fixtures de prosa da suíte de avaliação. Assets canônicos vivem em `assets/` e `scripts/` e são copiados para `skills/*/references/` por `scripts/sync-assets.sh`; `scripts/check-assets.sh` falha se houver drift. A validação final é `scripts/eval.sh` (todos verdes), `scripts/check-assets.sh` e um grep que confirma que "fatia" só sobrevive como verbo.

**Tech Stack:** Bash + awk (scripts), Markdown (assets/docs/skills), fixtures `.md`, harness de teste caseiro (`eval.sh` → `test-*.sh`).

---

## Regra de ouro (vale para TODAS as tasks)

O **substantivo** da unidade muda: `fatia`→`spec`, `Fatia`→`Spec`, `fatias`→`specs`, `Fatias`→`Specs`.

O **verbo/ato de cortar NUNCA muda** — deixe intactos, em qualquer forma:
`fatiar`, `fatiamento`, `refatiar`, `refatie`, `re-fatiar`, `re-fatia`, `re-fatiamento`.

Desambiguação com o Spec Kit (decisão #4 do design):
- A unidade é **a spec**. Seus artefatos são **`spec.md`** e a **pasta `specs/###-<slug>`**.
- Elos que ficariam tautológicos são reescritos: `fatia↔spec` (slice↔pasta) vira **`spec↔pasta`**.
- Colunas de máquina do backlog: a antiga `Spec` (link para a pasta) vira **`Pasta`**; o glyph `◐ em spec` vira **`◐ em especificação`**.

Confirmado que **não há** ocorrência de "fatia" em: `skills/zion-prd-write/SKILL.md`, `skills/zion-prd-discovery/SKILL.md`, `skills/zion-prd-spike/SKILL.md`, `skills/zion-prd-constitution-prompt/SKILL.md` (nada a fazer nesses 4 corpos — só recebem sync de `quality-rules.md`/`process-context.md`).

Fora do escopo (NÃO tocar): `docs/superpowers/plans/*`, `docs/superpowers/specs/*`, `docs/critica-zion-build-prd.md`, `docs/avaliacao-harness.md`, `scripts/trace-prd.sh`, `assets/templates/traceability-table.md`, o parser da §12 e os **nomes de diretório** de fixture (ex.: `decompose/fatia-horizontal/`).

---

## File Structure

Núcleo mecânico (Tasks 1–2):
- `assets/templates/backlog.md` — template canônico do backlog (cabeçalho, preâmbulo, legenda).
- `scripts/trace-backlog.sh` — parser/reconciliador; chaves de coluna, glyphs, avisos, comentários.
- `scripts/fixtures/backlog/{backlog,bootstrap,no-table}.md`, `clean/backlog.md`, `collision/backlog.md` — fixtures do teste.
- `scripts/test-trace-backlog.sh` — expectativas do teste.

Prosa viva (Tasks 3–5):
- `assets/quality-rules.md`, `assets/process-context.md`, `assets/templates/prd-skeleton.md` — assets canônicos (sync).
- `skills/{zion-prd-decompose,zion-prd-specify-prompt,zion-prd-trace,zion-prd-evolve,zion-prd-plan-prompt}/SKILL.md`.
- `docs/guia-prd-para-spec-kit.md`, `docs/como-usar.md` (inclui a nota de migração), `README.md`.

Fixtures de prosa (Task 6):
- `scripts/fixtures/skills/decompose/{limpa,fatia-horizontal,skeleton-nao-r0}/{backlog,esperado}.md`.
- `scripts/fixtures/prd-clean.md`, `scripts/fixtures/prd-evolve/{clean,dirty}/PRD.md`.
- `scripts/test-check-prd.sh`, `scripts/fixtures/trace/specs/{001-acao,002-historico}/spec.md`.

Validação (Task 7): `scripts/eval.sh`, `scripts/check-assets.sh`, grep final.

---

## Task 1: Template canônico do backlog

**Files:**
- Modify: `assets/templates/backlog.md`
- Run: `scripts/sync-assets.sh`, `scripts/check-assets.sh`

- [ ] **Step 1: Substituir o conteúdo inteiro do template**

O arquivo é pequeno; substitua-o por completo (preâmbulo + cabeçalho + linhas de exemplo + legenda). Conteúdo novo exato:

```markdown
> Backlog de specs verticais — a fila de trabalho do harness. Uma linha por spec; **a ordem das
> linhas é a fila de prioridade** (o walking skeleton na frente). Semeado por `/zion-prd-decompose`
> a partir deste template.
>
> **Colunas de máquina (artefato derivado)** — **Pasta** e **Status** são recomputadas por
> `/zion-prd-trace` (`scripts/trace-backlog.sh`), casando `specs/###-<slug>` ⇔ slug por sufixo.
> **Não edite Pasta/Status à mão.** As colunas humanas (Spec/Demo/RFs/Release) você preenche e o
> script preserva. A **primeira tabela** deste arquivo é a canônica (dono do script); todo o resto
> (notas, story map, texto livre) é preservado intacto.

| Spec (slug) | Demo (1 frase) | RFs | Release | Pasta | Status |
|-------------|----------------|-----|---------|-------|--------|
| walking-skeleton | _(a demo ponta-a-ponta mínima que prova o pipeline inteiro)_ | RF-xx | R0 | — | ☐ pendente |
| spec-exemplo | _(o que o usuário faz/vê ao final desta spec — o teste INVEST)_ | RF-xx, RF-yy | R1 | — | ☐ pendente |

Legenda de status: ☐ pendente · ◐ em especificação · ● implementada.
```

- [ ] **Step 2: Sincronizar as cópias de skill**

Run: `bash scripts/sync-assets.sh`
Expected: última linha `sync-assets: ok` (copia `assets/templates/backlog.md` para `skills/zion-prd-decompose/references/backlog.md`).

- [ ] **Step 3: Verificar ausência de drift**

Run: `bash scripts/check-assets.sh`
Expected: `check-assets: sem drift`

- [ ] **Step 4: Commit**

```bash
git add assets/templates/backlog.md skills/zion-prd-decompose/references/backlog.md
git commit -m "refactor(backlog): template canônico usa Spec (slug)/Pasta e ◐ em especificação"
```

---

## Task 2: Núcleo mecânico — `trace-backlog.sh` + fixtures + teste (TDD)

O parser casa a coluna humana por substring `slug` e a de máquina por `pasta`, emite `◐ em especificação`, e troca "fatia" (substantivo) por "spec" em comentários/avisos. Fluxo TDD: migramos fixtures e expectativas primeiro (o teste falha porque o parser antigo casa por `fatia`), depois o script.

**Files:**
- Modify: `scripts/fixtures/backlog/backlog.md`, `scripts/fixtures/backlog/bootstrap.md`, `scripts/fixtures/backlog/no-table.md`, `scripts/fixtures/backlog/clean/backlog.md`, `scripts/fixtures/backlog/collision/backlog.md`
- Modify: `scripts/test-trace-backlog.sh`
- Modify: `scripts/trace-backlog.sh`
- Run: `scripts/eval.sh backlog`, `scripts/sync-assets.sh`, `scripts/check-assets.sh`

- [ ] **Step 1: Migrar as 5 fixtures para o cabeçalho/legenda novos**

Em **cada** fixture com tabela canônica, troque a linha de cabeçalho e a de separador:

OLD (cabeçalho): `| Fatia (slug) | Demo (1 frase) | RFs | Release | Spec | Status |`
NEW (cabeçalho): `| Spec (slug) | Demo (1 frase) | RFs | Release | Pasta | Status |`

OLD (separador): `|--------------|----------------|-----|---------|------|--------|`
NEW (separador): `|-------------|----------------|-----|---------|-------|--------|`

Aplica-se a: `backlog/backlog.md`, `backlog/bootstrap.md`, `backlog/clean/backlog.md`, `backlog/collision/backlog.md`.

Edições de prosa adicionais nas fixtures (substantivo → spec):

`scripts/fixtures/backlog/backlog.md`:
```
"# Backlog de fatias — fixture"                          → "# Backlog de specs — fixture"
"| escopo-divergente | Fatia cuja spec cobre RF diferente | RF-08 | R2 | — | ☐ pendente |"
   → "| escopo-divergente | Spec cuja pasta cobre RF diferente | RF-08 | R2 | — | ☐ pendente |"
```

`scripts/fixtures/backlog/collision/backlog.md`:
```
"| preview-ao-vivo | Fatia com dois diretórios casando | RF-01 | R0 | — | ☐ pendente |"
   → "| preview-ao-vivo | Spec com dois diretórios casando | RF-01 | R0 | — | ☐ pendente |"
```

`scripts/fixtures/backlog/clean/backlog.md` (legenda fora da tabela):
```
"Legenda de status: ☐ pendente · ◐ em spec · ● implementada."
   → "Legenda de status: ☐ pendente · ◐ em especificação · ● implementada."
```

`scripts/fixtures/backlog/no-table.md`:
```
"Este arquivo não tem tabela canônica de fatias — só prosa."
   → "Este arquivo não tem tabela canônica de specs — só prosa."
```

- [ ] **Step 2: Atualizar as expectativas do teste**

Em `scripts/test-trace-backlog.sh`, aplique estas 4 edições exatas:

```
L30: assert_file_re "bootstrap: fatia vira ☐ pendente" "$bl" 'walking-skeleton .*\| — \| ☐ pendente'
  →  assert_file_re "bootstrap: spec vira ☐ pendente"  "$bl" 'walking-skeleton .*\| — \| ☐ pendente'

L46: assert_file_re "tasks aberto → ◐ em spec"          "$bl" 'erros-sintaxe .*specs/004-erros-sintaxe.*◐ em spec'
  →  assert_file_re "tasks aberto → ◐ em especificação" "$bl" 'erros-sintaxe .*specs/004-erros-sintaxe.*◐ em especificação'

L62: assert_contains "aviso fatia sem spec"        "Fatia sem spec" "$out"
  →  assert_contains "aviso spec sem pasta"        "Spec sem pasta" "$out"

L63: assert_contains "quadro de fatias"            "Quadro de fatias" "$out"
  →  assert_contains "quadro de specs"             "Quadro de specs" "$out"
```

- [ ] **Step 3: Rodar o teste e confirmar que FALHA**

Run: `bash scripts/eval.sh backlog`
Expected: FALHA. O parser antigo casa a coluna humana por `fatia` (ausente no cabeçalho novo) → `scol` não é setado → `ok=0` → `ROWS` vazio → `trace-backlog: <arquivo> sem tabela canônica` e `exit 2`. Vários `FALHOU:` e a suíte encerra com `eval: FALHOU`.

- [ ] **Step 4: Atualizar o `trace-backlog.sh`**

Edição 4a — comentário de cabeçalho (linhas 2–5):
```
OLD:
# trace-backlog.sh — reconciliador do backlog de fatias (docs/backlog.md).
# Espelho do trace-prd.sh no grão da FATIA. Preserva as colunas humanas
# (Fatia/Demo/RFs/Release) e a ordem das linhas; recomputa as colunas de
# máquina (Spec, Status) casando specs/###-<slug> ⇔ slug por sufixo.
NEW:
# trace-backlog.sh — reconciliador do backlog de specs (docs/backlog.md).
# Espelho do trace-prd.sh no grão da SPEC. Preserva as colunas humanas
# (Spec/Demo/RFs/Release) e a ordem das linhas; recomputa as colunas de
# máquina (Pasta, Status) casando specs/###-<slug> ⇔ slug por sufixo.
```

Edição 4b — comentário do `parse_table` (linha 36):
```
OLD: # --- Lê a PRIMEIRA tabela do arquivo (a canônica). Emite uma linha por fatia:
NEW: # --- Lê a PRIMEIRA tabela do arquivo (a canônica). Emite uma linha por spec:
```

Edição 4c — chaves de coluna no `parse_table` (linhas 51–56). Substitua o bloco:
```
OLD:
          if      (index(h,"fatia"))   scol=i
          else if (index(h,"demo"))    dcol=i
          else if (index(h,"rfs"))     rcol=i
          else if (index(h,"release")) relcol=i
          else if (index(h,"spec"))    spcol=i
          else if (index(h,"status"))  stcol=i
NEW:
          if      (index(h,"slug"))    scol=i
          else if (index(h,"demo"))    dcol=i
          else if (index(h,"rfs"))     rcol=i
          else if (index(h,"release")) relcol=i
          else if (index(h,"pasta"))   spcol=i
          else if (index(h,"status"))  stcol=i
```

Edição 4d — chaves de coluna no `rewrite_table` (linhas 127–130). Substitua o bloco:
```
OLD:
          if      (index(h,"fatia"))  scol=i
          else if (index(h,"spec"))   spcol=i
          else if (index(h,"status")) stcol=i
NEW:
          if      (index(h,"slug"))   scol=i
          else if (index(h,"pasta"))  spcol=i
          else if (index(h,"status")) stcol=i
```

Edição 4e — erro de tabela ausente (linha 148):
```
OLD: [ -s "$ROWS" ] || { echo "trace-backlog: $BACKLOG sem tabela canônica de fatias (veja assets/templates/backlog.md)" >&2; exit 2; }
NEW: [ -s "$ROWS" ] || { echo "trace-backlog: $BACKLOG sem tabela canônica de specs (veja assets/templates/backlog.md)" >&2; exit 2; }
```

Edição 4f — glyph "em spec" (linha 173):
```
OLD:     case "$st" in impl) glyph="● implementada" ;; *) glyph="◐ em spec" ;; esac
NEW:     case "$st" in impl) glyph="● implementada" ;; *) glyph="◐ em especificação" ;; esac
```

Edição 4g — aviso "Fatia sem spec" (linhas 183–185). Substitua:
```
OLD:
    glyph="☐ pendente"; speccell="—"
    [ "$SPEC_COUNT" -gt 0 ] && warnings="${warnings}Fatia sem spec: \`$slug\` ainda não tem spec (permanece ☐ pendente).
"
NEW:
    glyph="☐ pendente"; speccell="—"
    [ "$SPEC_COUNT" -gt 0 ] && warnings="${warnings}Spec sem pasta: \`$slug\` ainda não tem \`specs/###-<slug>\` (permanece ☐ pendente).
"
```

Edição 4h — aviso "Spec órfã" (linha 206), só o substantivo final:
```
OLD:     [ -n "${USEDDIR[$d]:-}" ] || warnings="${warnings}Spec órfã: \`specs/$d\` não casa com nenhum slug do backlog (registre a fatia ou renomeie).
NEW:     [ -n "${USEDDIR[$d]:-}" ] || warnings="${warnings}Spec órfã: \`specs/$d\` não casa com nenhum slug do backlog (registre a spec ou renomeie).
```

Edição 4i — case do glyph no contador (linha 197):
```
OLD:     "◐ em spec")      inspec=$((inspec+1)) ;;
NEW:     "◐ em especificação") inspec=$((inspec+1)) ;;
```

Edição 4j — quadro (linha 214):
```
OLD:   printf 'Quadro de fatias: ● %s · ◐ %s · ☐ %s' "$impl" "$inspec" "$pend"
NEW:   printf 'Quadro de specs: ● %s · ◐ %s · ☐ %s' "$impl" "$inspec" "$pend"
```

- [ ] **Step 5: Rodar o teste e confirmar que PASSA**

Run: `bash scripts/eval.sh backlog`
Expected: todos `ok:`, `test-trace-backlog: tudo verde`, `eval: tudo verde`.

- [ ] **Step 6: Sincronizar cópias e checar drift**

Run: `bash scripts/sync-assets.sh && bash scripts/check-assets.sh`
Expected: `sync-assets: ok` e `check-assets: sem drift` (copia `scripts/trace-backlog.sh` para `zion-prd-trace` e `zion-prd-decompose`).

- [ ] **Step 7: Commit**

```bash
git add scripts/trace-backlog.sh scripts/test-trace-backlog.sh scripts/fixtures/backlog \
        skills/zion-prd-trace/references/trace-backlog.sh skills/zion-prd-decompose/references/trace-backlog.sh
git commit -m "refactor(trace-backlog): casa slug/pasta, emite ◐ em especificação, prosa fatia→spec"
```

---

## Task 3: Prosa dos assets canônicos

**Files:**
- Modify: `assets/quality-rules.md`, `assets/process-context.md`, `assets/templates/prd-skeleton.md`
- Run: `scripts/sync-assets.sh`, `scripts/check-assets.sh`

- [ ] **Step 1: Editar `assets/quality-rules.md`**

Substantivo → spec (mantenha `refatie` e `re-fatiamento` intactos):
```
L52: "existe backlog de fatias verticais priorizadas ∧ cada fatia passa no INVEST ∧"
   → "existe backlog de specs verticais priorizadas ∧ cada spec passa no INVEST ∧"
L53: "walking skeleton é a fatia zero (R0) ∧ a tabela de rastreabilidade (§12) foi **semeada por"
   → "walking skeleton é a spec zero (R0) ∧ a tabela de rastreabilidade (§12) foi **semeada por"
L55: "semeado por `trace-backlog.sh` (colunas humanas — Fatia/slug, Demo, RFs, Release — preenchidas;"
   → "semeado por `trace-backlog.sh` (colunas humanas — Spec/slug, Demo, RFs, Release — preenchidas;"
L56: "colunas Spec/Status por máquina)."   → "colunas Pasta/Status por máquina)."
L90: "**INVEST** — cada fatia vertical deve ser: **I**ndependente"
   → "**INVEST** — cada spec vertical deve ser: **I**ndependente"
L93: "*\"esta fatia, sozinha, permite uma demo ponta-a-ponta?\"*"
   → "*\"esta spec, sozinha, permite uma demo ponta-a-ponta?\"*"
L94: "UI\" ou \"só o back\", a fatia é **horizontal** → refatie."
   → "UI\" ou \"só o back\", a spec é **horizontal** → refatie."     (refatie: NÃO mudar)
L96: "**SPIDR** — eixos para quebrar uma fatia grande: **S**pike"
   → "**SPIDR** — eixos para quebrar uma spec grande: **S**pike"
L97: "Use quando uma fatia não passa no \"Small\" do INVEST."
   → "Use quando uma spec não passa no \"Small\" do INVEST."
L99: "**Walking skeleton:** a fatia zero (R0) prova o pipeline"
   → "**Walking skeleton:** a spec zero (R0) prova o pipeline"
L107: "o que o usuário consegue fazer/ver ao final da fatia (o o-quê/por-quê)."
   → "o que o usuário consegue fazer/ver ao final da spec (o o-quê/por-quê)."
L114: "com os RF que a fatia cobre. É o elo forward RF↔spec legível por"
   → "com os RF que a spec cobre. É o elo forward RF↔spec legível por"
L117: "Declarar *quais* RF a fatia cobre é o-quê/rastreabilidade, não"
   → "Declarar *quais* RF a spec cobre é o-quê/rastreabilidade, não"
L119: "peça que a feature/branch use o `<slug>` da fatia (do"
   → "peça que a feature/branch use o `<slug>` da spec (do"
L120: "a spec nasce `specs/###-<slug>`, fechando o elo fatia↔spec por"
   → "a spec nasce `specs/###-<slug>`, fechando o elo spec↔pasta por"
L202: "fatias do épico afetado e a tabela; fatia já com `spec.md` → prompt de **re-specify** pela ponte."
   → "specs do épico afetado e a tabela; spec já com `spec.md` → prompt de **re-specify** pela ponte."
L216: "ADR-002 → ADR-005 · fatia S4 re-especificada |"
   → "ADR-002 → ADR-005 · spec S4 re-especificada |"
```
NÃO mudar L200 ("o re-fatiamento **parcial** do épico").

- [ ] **Step 2: Editar `assets/process-context.md`**

```
L17: "PRD → épicos → story map → fatias verticais validadas"
   → "PRD → épicos → story map → specs verticais validadas"
L18: "por INVEST; walking skeleton como fatia zero; tabela de rastreabilidade injetada na PRD e o backlog"
   → "por INVEST; walking skeleton como spec zero; tabela de rastreabilidade injetada na PRD e o backlog"
L19: "de fatias `docs/backlog.md` (slug + demo + RFs por fatia; Spec/Status por máquina)."
   → "de specs `docs/backlog.md` (slug + demo + RFs por spec; Pasta/Status por máquina)."
L20: "**Handoff:** cada fatia priorizada entra no Spec Kit via `/speckit.specify`."
   → "**Handoff:** cada spec priorizada entra no Spec Kit via `/speckit.specify`."
```

- [ ] **Step 3: Editar `assets/templates/prd-skeleton.md`**

```
L44: "Tabela de rastreabilidade RF → épico → fatia, injetada por `/zion-prd-decompose`"
   → "Tabela de rastreabilidade RF → épico → spec, injetada por `/zion-prd-decompose`"
```

- [ ] **Step 4: Sincronizar e checar drift**

Run: `bash scripts/sync-assets.sh && bash scripts/check-assets.sh`
Expected: `sync-assets: ok` e `check-assets: sem drift`.

- [ ] **Step 5: Confirmar que só o verbo sobrevive nesses assets**

Run: `grep -niE 'fatia' assets/quality-rules.md assets/process-context.md assets/templates/prd-skeleton.md`
Expected: apenas L200 de `quality-rules.md` (`re-fatiamento`). Nenhum substantivo.

- [ ] **Step 6: Commit**

```bash
git add assets/ skills/*/references/
git commit -m "docs(assets): unidade fatia→spec em quality-rules, process-context e skeleton"
```

---

## Task 4: Prosa das skills (SKILL.md)

**Files:**
- Modify: `skills/zion-prd-decompose/SKILL.md`, `skills/zion-prd-specify-prompt/SKILL.md`, `skills/zion-prd-trace/SKILL.md`, `skills/zion-prd-evolve/SKILL.md`, `skills/zion-prd-plan-prompt/SKILL.md`

- [ ] **Step 1: Editar `skills/zion-prd-decompose/SKILL.md`**

```
L3 (description): "...em épicos, story map e fatias verticais validadas por INVEST..."
   → "...em épicos, story map e specs verticais validadas por INVEST..."
   (NÃO mudar "fatiar em histórias/épicos" — verbo)
L4 (argument-hint): manter "re-fatiar só um épico no dia 2" (verbo) — sem mudança.
L32-33: "(4) fatiar cada épico em fatias verticais. Para cada fatia, **cunhe um slug kebab-case**"
   → "(4) fatiar cada épico em specs verticais. Para cada spec, **cunhe um slug kebab-case**"
   (mantém o verbo "fatiar")
L39: "**Fatias já implementadas do épico são intocáveis** — viram"
   → "**Specs já implementadas do épico são intocáveis** — viram"
L40: "**restrição** do re-fatiamento (as novas fatias partem do que já existe)."
   → "**restrição** do re-fatiamento (as novas specs partem do que já existe)."
L42: "Fatias já implementadas (`●`) permanecem **intocáveis** no re-fatiamento."
   → "Specs já implementadas (`●`) permanecem **intocáveis** no re-fatiamento."
L47-48: "Cada fatia passa no **INVEST** (`#invest`) — aplique o teste-relâmpago \"esta fatia, sozinha, dá uma\n  demo ponta-a-ponta?\". Se a resposta é \"só a UI\" ou \"só o back\", a fatia é **horizontal** → aponte e"
   → "Cada spec passa no **INVEST** (`#invest`) — aplique o teste-relâmpago \"esta spec, sozinha, dá uma\n  demo ponta-a-ponta?\". Se a resposta é \"só a UI\" ou \"só o back\", a spec é **horizontal** → aponte e"
   (L49 "sugira refatiar pelos eixos do **SPIDR**." — verbo, sem mudança)
L50: "O **walking skeleton** é a fatia zero (R0)."
   → "O **walking skeleton** é a spec zero (R0)."
L58: "Reconciliar após cada fatia é trabalho de `/zion-prd-trace`."
   → "Reconciliar após cada spec é trabalho de `/zion-prd-trace`."
L59-60: "Semeie o **backlog de fatias** `docs/backlog.md` ... preenchendo as **colunas humanas** (Fatia/slug, Demo, RFs, Release) com o resultado do fatiamento; então"
   → "Semeie o **backlog de specs** `docs/backlog.md` ... preenchendo as **colunas humanas** (Spec/slug, Demo, RFs, Release) com o resultado do fatiamento; então"
   (mantém "do fatiamento")
L72-73: "backlog de **fatias verticais** priorizadas com linhas de release, o ... (slug/demo/RFs por fatia; Spec/Status por"
   → "backlog de **specs verticais** priorizadas com linhas de release, o ... (slug/demo/RFs por spec; Pasta/Status por"
L74-75: "**Handoff:** a próxima fatia da fila entra em `/zion-prd-specify-prompt`; após cada fatia, `/zion-prd-trace` reconcilia a tabela."
   → "**Handoff:** a próxima spec da fila entra em `/zion-prd-specify-prompt`; após cada spec, `/zion-prd-trace` reconcilia a tabela."
```

- [ ] **Step 2: Editar `skills/zion-prd-specify-prompt/SKILL.md`**

```
L3 (description): "...do /speckit.specify de UMA fatia vertical... Use para levar uma fatia do backlog ao Spec Kit..."
   → "...do /speckit.specify de UMA spec vertical... Use para levar uma spec do backlog ao Spec Kit..."
L4 (argument-hint): "Qual fatia vertical do backlog transformar em prompt de specify"
   → "Qual spec vertical do backlog transformar em prompt de specify"
L13: "Prepara o input do `/speckit.specify` de UMA fatia vertical."
   → "Prepara o input do `/speckit.specify` de UMA spec vertical."
L18: "fatia. Se não houver backlog, avise"   → "spec. Se não houver backlog, avise"
L21: "A fatia deve ter um **resultado observável**"   → "A spec deve ter um **resultado observável**"
L22: "o usuário descreve a fatia citando **biblioteca/framework/stack**"
   → "o usuário descreve a spec citando **biblioteca/framework/stack**"
L25-26: "apontá-la em prosa (\"a fatia do preview\"); localize a linha na tabela canônica e confirme **slug / demo / RFs**. Fatia fora do backlog →"
   → "apontá-la em prosa (\"a spec do preview\"); localize a linha na tabela canônica e confirme **slug / demo / RFs**. Spec fora do backlog →"
L34: "Declarar o **resultado observável** da fatia"   → "Declarar o **resultado observável** da spec"
L39-40: "os RF que esta fatia cobre — é o elo ... Declarar *quais* RF a fatia cobre é o-quê/rastreabilidade"
   → "os RF que esta spec cobre — é o elo ... Declarar *quais* RF a spec cobre é o-quê/rastreabilidade"
L43: "fechando o elo fatia↔spec por construção"   → "fechando o elo spec↔pasta por construção"
L45: "com **os RF-xx da linha da fatia** no backlog"   → "com **os RF-xx da linha da spec** no backlog"
L47: "o `trace-backlog.sh` acusa **spec órfã** + **fatia sem spec**"
   → "o `trace-backlog.sh` acusa **spec órfã** + **spec sem pasta**"
L50: "quando a fatia apontada **já** tem `specs/<n>-*/spec.md`"
   → "quando a spec apontada **já** tem `specs/<n>-*/spec.md`"
```

- [ ] **Step 3: Editar `skills/zion-prd-trace/SKILL.md`**

```
L3 (description): "...e o backlog de fatias (docs/backlog.md) ... RF↔spec, fatia↔spec e status ... É o ritual de fim de fatia. Use ... ou depois de fatiar/implementar uma fatia."
   → "...e o backlog de specs (docs/backlog.md) ... RF↔spec, spec↔pasta e status ... É o ritual de fim de spec. Use ... ou depois de fatiar/implementar uma spec."
   (mantém o verbo "fatiar")
L42: "e o **quadro de fatias**."   → "e o **quadro de specs**."
L48: "adicione-a para a fatia entrar na"   → "adicione-a para a spec entrar na"
L53: "**Fatia sem spec** — a fatia ainda não tem `specs/###-<slug>` (permanece ☐; informativo)."
   → "**Spec sem pasta** — a spec ainda não tem `specs/###-<slug>` (permanece ☐; informativo)."
L55: "spec nasceu fora do backlog → registre a fatia ou renomeie."
   → "spec nasceu fora do backlog → registre a spec ou renomeie."
L56: "os RFs da linha da fatia ≠ a linha `**RF cobertos:**`"
   → "os RFs da linha da spec ≠ a linha `**RF cobertos:**`"
L60: "Ecoe o **quadro de fatias** (`● / ◐ / ☐` + a próxima fatia ☐ da fila)"
   → "Ecoe o **quadro de specs** (`● / ◐ / ☐` + a próxima spec ☐ da fila)"
L62: "rode `/zion-prd-trace` de novo após a próxima fatia (ou use"
   → "rode `/zion-prd-trace` de novo após a próxima spec (ou use"
L67-68: "os resumos/avisos e o quadro de fatias ecoados. ... é o **ritual de fim de fatia**."
   → "os resumos/avisos e o quadro de specs ecoados. ... é o **ritual de fim de spec**."
L69: "a próxima fatia ☐ da fila segue para"   → "a próxima spec ☐ da fila segue para"
```

- [ ] **Step 4: Editar `skills/zion-prd-evolve/SKILL.md`**

```
L23: "fatias do épico afetado + tabela; fatia já com spec → contexto de re-specify montado pela ponte."
   → "specs do épico afetado + tabela; spec já com `spec.md` → contexto de re-specify montado pela ponte."
L53-54: manter "**Re-fatiamento do épico afetado (C1/C2)** → ... re-fatia **apenas** o épico indicado;" (verbos) e trocar só o substantivo em "fatias já implementadas são intocáveis." → "specs já implementadas são intocáveis."
L56: "**Fatia já especificada (C2)** → `/zion-prd-specify-prompt`"
   → "**Spec já especificada (C2)** → `/zion-prd-specify-prompt`"
L74: "uma fatia já especificada — o prompt de re-specify pronto"
   → "uma spec já especificada — o prompt de re-specify pronto"
```

- [ ] **Step 5: Editar `skills/zion-prd-plan-prompt/SKILL.md`**

```
L25: "Leia o `spec.md` da fatia e cruze com `docs/adr/`."
   → "Leia o `spec.md` da spec e cruze com `docs/adr/`."
L27: "(ex.: \"ADR-001 (Postgres) → a fatia persiste pedidos\")."
   → "(ex.: \"ADR-001 (Postgres) → a spec persiste pedidos\")."
```

- [ ] **Step 6: Confirmar que só o verbo sobrevive nas skills**

Run:
```bash
grep -niE 'fatia' skills/zion-prd-decompose/SKILL.md skills/zion-prd-specify-prompt/SKILL.md \
  skills/zion-prd-trace/SKILL.md skills/zion-prd-evolve/SKILL.md skills/zion-prd-plan-prompt/SKILL.md
```
Expected: só formas verbais — `fatiar` (decompose L3, L33, trace L3), `re-fatiar`/`re-fatia`/`re-fatiamento` (decompose L4, L37, L40, L42, L60; evolve L53), `refatiar` (decompose L49). Nenhum substantivo `fatia`/`Fatia`/`fatias`.

- [ ] **Step 7: Commit**

```bash
git add skills/*/SKILL.md
git commit -m "docs(skills): unidade fatia→spec nas 5 SKILL.md afetadas"
```

---

## Task 5: Prosa dos docs (guia, como-usar, README) + nota de migração

**Files:**
- Modify: `docs/guia-prd-para-spec-kit.md`, `docs/como-usar.md`, `README.md`

- [ ] **Step 1: Editar `docs/guia-prd-para-spec-kit.md`**

```
L27: "PRD → épicos → story map → fatias verticais validadas por INVEST/SPIDR;"
   → "PRD → épicos → story map → specs verticais validadas por INVEST/SPIDR;"
L28: "walking skeleton como fatia zero."   → "walking skeleton como spec zero."
L37: "P --> E[\"4. Decomposição<br/>épicos → story map → fatias verticais\"]"
   → "P --> E[\"4. Decomposição<br/>épicos → story map → specs verticais\"]"
L53-54: "backlog de fatias verticais\npriorizadas**. Cada fatia, uma a uma, entra no estágio 5"
   → "backlog de specs verticais\npriorizadas**. Cada spec, uma a uma, entra no estágio 5"
L150: "## Passo 4 — Decomposição: PRD → épicos → story map → fatias verticais"
   → "## Passo 4 — Decomposição: PRD → épicos → story map → specs verticais"
L152: "transformar os `RF-xx` da PRD em um **backlog de fatias verticais priorizadas**,"
   → "transformar os `RF-xx` da PRD em um **backlog de specs verticais priorizadas**,"
L155: manter "extrair épicos, montar o story map e fatiar verticalmente." (verbo) — sem mudança.
L161: "(4) fatiar cada épico em fatias verticais e validar cada uma com INVEST."
   → "(4) fatiar cada épico em specs verticais e validar cada uma com INVEST."   (mantém "fatiar")
L163: "**Checklists textuais a aplicar em cada fatia (não são comandos):**"
   → "**Checklists textuais a aplicar em cada spec (não são comandos):**"
L165-166: "fatia, sozinha, permite uma demo ponta-a-ponta?\" Se a resposta é \"só a UI\" ou \"só o back\", a\n    fatia é horizontal → refatie."
   → "spec, sozinha, permite uma demo ponta-a-ponta?\" Se a resposta é \"só a UI\" ou \"só o back\", a\n    spec é horizontal → refatie."   (mantém "refatie")
L167: "para quebrar fatias grandes por caminhos alternativos"
   → "para quebrar specs grandes por caminhos alternativos"
L168: "**Walking skeleton** — a **fatia zero** (R0) prova o pipeline"
   → "**Walking skeleton** — a **spec zero** (R0) prova o pipeline"
L170: "**backlog de fatias verticais** com linhas de"
   → "**backlog de specs verticais** com linhas de"
L171: "em `docs/backlog.md` (slug/demo/RFs por fatia; Spec/Status semeados por `trace-backlog.sh`), e a"
   → "em `docs/backlog.md` (slug/demo/RFs por spec; Pasta/Status semeados por `trace-backlog.sh`), e a"
L173: "reconcilia **os dois** a cada fatia."   → "reconcilia **os dois** a cada spec."
L174-175: "existe uma fila priorizada de fatias verticais, cada uma passando no teste\n  INVEST ... **Handoff:** a próxima fatia da fila entra no Passo 5."
   → "existe uma fila priorizada de specs verticais, cada uma passando no teste\n  INVEST ... **Handoff:** a próxima spec da fila entra no Passo 5."
L201: "Cada fatia vertical do Passo 4 percorre este"   → "Cada spec vertical do Passo 4 percorre este"
L208: "levar **uma** fatia vertical de \"o-quê/por-quê\" até implementação"
   → "levar **uma** spec vertical de \"o-quê/por-quê\" até implementação"
L220: "`spec.md` da fatia, cruza com `docs/adr/`"   → "`spec.md` da spec, cruza com `docs/adr/`"
L257-258: "a próxima fatia vertical da fila (Passo 4, ... a usar o **slug** da fatia como nome curto → `specs/###-<slug>`);"
   → "a próxima spec vertical da fila (Passo 4, ... a usar o **slug** da spec como nome curto → `specs/###-<slug>`);"
L279: "é o **ritual de fim de fatia** — fecha a fatia e ecoa o quadro"
   → "é o **ritual de fim de spec** — fecha a spec e ecoa o quadro"
L311: "as fatias do épico afetado; se a fatia já tem `spec.md`,"
   → "as specs do épico afetado; se a spec já tem `spec.md`,"
L320: manter "`/zion-prd-decompose --epico E<k>` (re-fatiamento parcial)," (verbo) — sem mudança.
L337: "e decomposição em épicos/fatias (P4)."   → "e decomposição em épicos/specs (P4)."
L401-402: "Backlog de **fatias verticais** priorizadas; cada fatia passa no teste INVEST; walking skeleton\n      é a fatia zero."
   → "Backlog de **specs verticais** priorizadas; cada spec passa no teste INVEST; walking skeleton\n      é a spec zero."
```

- [ ] **Step 2: Editar `docs/como-usar.md`**

```
L40 (tabela): "| `/zion-prd-decompose` | 4 · Decomposição | `docs/PRD.md` (com `RF-xx`) | fatias + `docs/backlog.md` + tabela na PRD |"
   → "...| specs + `docs/backlog.md` + tabela na PRD |"
L42 (tabela): "| `/zion-prd-specify-prompt` | Ponte p/ 5b | backlog de fatias | prompt do `/speckit.specify` |"
   → "...| backlog de specs | prompt do `/speckit.specify` |"
L208-209: "→ cortes de release → **fatias\nverticais**. Cada fatia é validada pelo **INVEST** (teste-relâmpago: *\"esta fatia, sozinha, dá uma"
   → "→ cortes de release → **specs\nverticais**. Cada spec é validada pelo **INVEST** (teste-relâmpago: *\"esta spec, sozinha, dá uma"
L213: "prova o pipeline texto→render→persistência inteiro. É a fatia zero."
   → "prova o pipeline texto→render→persistência inteiro. É a spec zero."
L227: "E **semeia o backlog** `docs/backlog.md` (fila de fatias; slug/demo/RFs humanos, Spec/Status por máquina):"
   → "E **semeia o backlog** `docs/backlog.md` (fila de specs; slug/demo/RFs humanos, Pasta/Status por máquina):"
L230-231 (bloco de exemplo do backlog): troque cabeçalho e separador:
   "| Fatia (slug) | Demo (1 frase) | RFs | Release | Spec | Status |"
     → "| Spec (slug) | Demo (1 frase) | RFs | Release | Pasta | Status |"
   "|--------------|----------------|-----|---------|------|--------|"
     → "|-------------|----------------|-----|---------|-------|--------|"
L260: "Aponte **qual** fatia da fila. Para o walking skeleton:"
   → "Aponte **qual** spec da fila. Para o walking skeleton:"
L263: "/zion-prd-specify-prompt A fatia R0: digitar mermaid, ver a prévia, recarregar e o diagrama continuar."
   → "/zion-prd-specify-prompt A spec R0: digitar mermaid, ver a prévia, recarregar e o diagrama continuar."
L280: "Depois do `specify`+`clarify` da fatia, leve a feature ao `plan`"
   → "Depois do `specify`+`clarify` da spec, leve a feature ao `plan`"
L286: "Lê o `spec.md` da fatia, cruza com `docs/adr/`"   → "Lê o `spec.md` da spec, cruza com `docs/adr/`"
L315: manter "> 4. Re-fatiar o épico de exportação → `/zion-prd-decompose --epico E3`. *(gate)*" (verbo) — sem mudança.
L316: "> 5. Fatia já especificada → `/zion-prd-specify-prompt` em modo re-specify. *(gate)*"
   → "> 5. Spec já especificada → `/zion-prd-specify-prompt` em modo re-specify. *(gate)*"
L359: "### 4. INVEST reprova fatia horizontal"   → "### 4. INVEST reprova spec horizontal"
L360: "Dar ao `/zion-prd-decompose` uma fatia \"só o canvas visual, sem ligar ao texto\":"
   → "Dar ao `/zion-prd-decompose` uma spec \"só o canvas visual, sem ligar ao texto\":"
L362: "> ⚠ Fatia horizontal: é \"só a UI\" — não passa no teste ... Sugiro refatiar pelos"
   → "> ⚠ Spec horizontal: é \"só a UI\" — não passa no teste ... Sugiro refatiar pelos"   (mantém "refatiar")
L368: "entrega o `/speckit.specify` (por fatia) e `/zion-prd-plan-prompt`"
   → "entrega o `/speckit.specify` (por spec) e `/zion-prd-plan-prompt`"
L394: "4. `/zion-prd-decompose` → fatias verticais + tabela na PRD; R0 = walking skeleton."
   → "4. `/zion-prd-decompose` → specs verticais + tabela na PRD; R0 = walking skeleton."
L396: "6. `/zion-prd-specify-prompt <fatia>` → `/speckit.specify \"...\"` pronto"
   → "6. `/zion-prd-specify-prompt <spec>` → `/speckit.specify \"...\"` pronto"
```

- [ ] **Step 3: Inserir a nota de migração do backlog antigo em `docs/como-usar.md`**

Imediatamente **após** o fechamento (```` ``` ````) do bloco de exemplo do backlog (o bloco editado no Step 2, que termina na linha da fixture `erros-sintaxe`), insira este parágrafo:

```markdown

> **Migrando um backlog antigo (formato "fatia"):** o `trace-backlog.sh` só aceita o formato novo, sem
> retrocompatibilidade. Num `docs/backlog.md` já existente, renomeie na linha de cabeçalho os dois
> rótulos — `Fatia (slug)` → **`Spec (slug)`** e a coluna de máquina `Spec` → **`Pasta`** — e, na
> legenda, `◐ em spec` → **`◐ em especificação`**. É uma edição de uma linha (mais a legenda); depois
> rode `/zion-prd-trace` normalmente.
```

- [ ] **Step 4: Editar `README.md`**

```
L37 (tabela): "| `/zion-prd-decompose` | Épicos, story map, fatias verticais, backlog (`docs/backlog.md`), rastreabilidade |"
   → "...| Épicos, story map, specs verticais, backlog (`docs/backlog.md`), rastreabilidade |"
L41 (tabela): "| `/zion-prd-trace` | Reconcilia a rastreabilidade (§12) e o backlog de fatias a partir das specs |"
   → "...| Reconcilia a rastreabilidade (§12) e o backlog de specs a partir das specs |"
```

- [ ] **Step 5: Confirmar que só o verbo sobrevive nos docs**

Run: `grep -niE 'fatia' docs/guia-prd-para-spec-kit.md docs/como-usar.md README.md`
Expected: só formas verbais — guia L155 (`fatiar`), L161 (`fatiar`), L166 (`refatie`), L320 (`re-fatiamento`); como-usar L315 (`Re-fatiar`), L362 (`refatiar`), e a nota de migração do Step 3 (que cita `Fatia (slug)`/`fatia` como o formato **antigo** sendo substituído — isso é intencional e esperado). README: nenhum.

- [ ] **Step 6: Commit**

```bash
git add docs/guia-prd-para-spec-kit.md docs/como-usar.md README.md
git commit -m "docs: unidade fatia→spec no guia, como-usar (com nota de migração) e README"
```

---

## Task 6: Fixtures de prosa da suíte de avaliação

`check-prd.sh` **não** lê a coluna `Fatia` da §12 nem a palavra "fatia" no changelog (só valida stack, RF-por-épico e changelog-*), então renomear estes cabeçalhos/células é seguro; a camada mecânica (`eval.sh`) continua verde.

**Files:**
- Modify: `scripts/fixtures/skills/decompose/limpa/backlog.md`, `.../fatia-horizontal/backlog.md`, `.../skeleton-nao-r0/backlog.md`
- Modify: `scripts/fixtures/skills/decompose/limpa/esperado.md`, `.../fatia-horizontal/esperado.md`, `.../skeleton-nao-r0/esperado.md`
- Modify: `scripts/fixtures/prd-clean.md`, `scripts/fixtures/prd-evolve/clean/PRD.md`, `scripts/fixtures/prd-evolve/dirty/PRD.md`
- Modify: `scripts/test-check-prd.sh`
- Modify: `scripts/fixtures/trace/specs/001-acao/spec.md`, `scripts/fixtures/trace/specs/002-historico/spec.md`

- [ ] **Step 1: Editar os 3 `backlog.md` do decompose**

Em `limpa/backlog.md`, `fatia-horizontal/backlog.md` e `skeleton-nao-r0/backlog.md` (L11 em cada):
```
"## Fatias verticais (priorizadas)"   →   "## Specs verticais (priorizadas)"
```
(os itens S0/S1/S2 abaixo não citam a unidade — não mude.)

- [ ] **Step 2: Editar `scripts/fixtures/skills/decompose/fatia-horizontal/esperado.md`**

```
L5:  "defeito: fatia-horizontal"   →   "defeito: spec-horizontal"
L12: "A fatia \"S1 — Montar todos os endpoints da API de tarefas\" é horizontal: entrega só backend, não passa"
   → "A spec \"S1 — Montar todos os endpoints da API de tarefas\" é horizontal: entrega só backend, não passa"
L13: "no teste-relâmpago \"esta fatia, sozinha, dá uma demo ponta-a-ponta?\"."
   → "no teste-relâmpago \"esta spec, sozinha, dá uma demo ponta-a-ponta?\"."
L17: "SPIDR (ex.: por Path ou Rules, cada fatia com um caminho ponta-a-ponta). Um falso-negativo é deixar S1"
   → "SPIDR (ex.: por Path ou Rules, cada spec com um caminho ponta-a-ponta). Um falso-negativo é deixar S1"
```
(L9 e L16 usam "refatiar" — verbo, sem mudança.)

- [ ] **Step 3: Editar `scripts/fixtures/skills/decompose/skeleton-nao-r0/esperado.md`**

```
L8:  "aponta que o walking skeleton (S1) não é a fatia zero (R0)"
   → "aponta que o walking skeleton (S1) não é a spec zero (R0)"
L12: "O walking skeleton está em S1 (R1), não na fatia zero. A R0 é ocupada por \"Filtrar por responsável\","
   → "O walking skeleton está em S1 (R1), não na spec zero. A R0 é ocupada por \"Filtrar por responsável\","
L13: "que não prova o pipeline inteiro. O critério **decompose** exige o walking skeleton como fatia zero (R0)."
   → "que não prova o pipeline inteiro. O critério **decompose** exige o walking skeleton como spec zero (R0)."
L16: "A Fase 4 do decompose aponta que o walking skeleton não está na R0 e sugere movê-lo para a fatia zero."
   → "A Fase 4 do decompose aponta que o walking skeleton não está na R0 e sugere movê-lo para a spec zero."
```

- [ ] **Step 4: Editar `scripts/fixtures/skills/decompose/limpa/esperado.md`**

```
L8:  "cada fatia passa no teste-relâmpago (é vertical)"   →   "cada spec passa no teste-relâmpago (é vertical)"
L9:  "o walking skeleton é a fatia zero (R0)"             →   "o walking skeleton é a spec zero (R0)"
L12: "Nenhum — cada fatia é vertical (dá uma demo ponta-a-ponta) e o walking skeleton é a S0 (R0)."
   → "Nenhum — cada spec é vertical (dá uma demo ponta-a-ponta) e o walking skeleton é a S0 (R0)."
L15: "A Fase 4 do decompose dá veredito ✓ por item: fatias verticais e skeleton na R0. Um falso-positivo é"
   → "A Fase 4 do decompose dá veredito ✓ por item: specs verticais e skeleton na R0. Um falso-positivo é"
```

> `scripts/fixtures/skills/evolve/limpa/esperado.md` só tem `re-fatiar` (verbo) → **não** mude.

- [ ] **Step 5: Editar os fixtures de PRD**

`scripts/fixtures/prd-clean.md`:
```
L40: "| RF | Épico | Fatia |"   →   "| RF | Épico | Spec |"
```

`scripts/fixtures/prd-evolve/clean/PRD.md`:
```
L40: "| RF | Épico | Fatia |"   →   "| RF | Épico | Spec |"
L48: "| 2026-08-05 | C1 | RF-04 novo: exportar o quadro em vetor | pedido recorrente | RF-04 no épico E2 · fatia nova |"
   → "| 2026-08-05 | C1 | RF-04 novo: exportar o quadro em vetor | pedido recorrente | RF-04 no épico E2 · spec nova |"
```

`scripts/fixtures/prd-evolve/dirty/PRD.md`:
```
L21: "| RF | Épico | Fatia |"   →   "| RF | Épico | Spec |"
L29: "| 2026-08-05 | X | RF-03 alterado | ajuste | fatia S2 |"
   → "| 2026-08-05 | X | RF-03 alterado | ajuste | spec S2 |"
```

- [ ] **Step 6: Editar `scripts/test-check-prd.sh`**

```
L38: printf 'O usuário edita o diagrama e vê a prévia atualizar ao digitar.\nPeça que o spec.md inclua a linha **RF cobertos:** RF-01 com os RF que a fatia cobre.\n'
   → ...com os RF que a spec cobre.\n'
```
(Só a palavra `fatia` → `spec` dentro do `printf`.)

- [ ] **Step 7: Editar os 2 fixtures de trace**

`scripts/fixtures/trace/specs/001-acao/spec.md` e `.../002-historico/spec.md` (L4 em cada):
```
"Descrição da fatia."   →   "Descrição da spec."
```

- [ ] **Step 8: Rodar a suíte mecânica inteira**

Run: `bash scripts/eval.sh`
Expected: `=== eval: prd ===` ... `test-check-prd: tudo verde`; `=== eval: trace ===` verde; `=== eval: backlog ===` `test-trace-backlog: tudo verde`; ao final `eval: tudo verde`.

- [ ] **Step 9: Commit**

```bash
git add scripts/fixtures scripts/test-check-prd.sh
git commit -m "test(fixtures): unidade fatia→spec nas fixtures de prosa da avaliação"
```

---

## Task 7: Validação final

**Files:** nenhum (só verificação).

- [ ] **Step 1: Suíte mecânica verde**

Run: `bash scripts/eval.sh`
Expected: `eval: tudo verde`.

- [ ] **Step 2: Sem drift de assets**

Run: `bash scripts/sync-assets.sh && bash scripts/check-assets.sh`
Expected: `sync-assets: ok` e `check-assets: sem drift`. Se `sync-assets` alterar algo aqui, houve edição num canônico sem sync — comitar a correção.

- [ ] **Step 3: Grep final — "fatia" só como verbo**

Run:
```bash
git ls-files | grep -viE '^docs/superpowers/(plans|specs)/|^docs/critica-|^docs/avaliacao-' \
  | xargs grep -niE 'fatia' 2>/dev/null \
  | grep -viE 'fatiar|fatiamento|refati|re-fati'
```
Expected: a **única** linha remanescente é a nota de migração em `docs/como-usar.md` (que cita `Fatia (slug)`/`Spec` como o **formato antigo** a substituir — intencional). Qualquer outra linha é um substantivo esquecido → corrija-o e re-rode.

> Nota: os **nomes de diretório** `scripts/fixtures/skills/decompose/fatia-horizontal/` e o design/spec datados permanecem com "fatia" — são fora do escopo e não aparecem no grep de conteúdo acima (o grep casa conteúdo de arquivo, não caminhos de pasta).

- [ ] **Step 4: Confirmar hierarquia e verbo preservados**

Run: `grep -rniE 'RF → épico → spec|re-fatiamento|fatiar' assets/ skills/ docs/guia-prd-para-spec-kit.md`
Expected: a §12/§4 descreve "RF → épico → spec"; o verbo "fatiar"/"re-fatiamento" segue presente onde nomeia o ato. "Épico" intacto em todo lugar.

---

## Self-Review (executada ao escrever este plano)

**1. Cobertura do spec:**
- Backlog canônico (cabeçalho `Spec (slug)`/`Pasta`, preâmbulo, legenda `◐ em especificação`, sync) → Task 1. ✓
- `trace-backlog.sh` (parser `slug`/`pasta`, glyph, avisos, comentários) + fixtures + teste → Task 2. ✓
- Assets canônicos de prosa (quality-rules, process-context, prd-skeleton §12) + sync → Task 3. ✓
- Skills (as 5 com ocorrência; as outras 4 confirmadas sem ocorrência) → Task 4. ✓
- Docs (guia, como-usar + **nota de migração**, README) → Task 5. ✓
- Fixtures de prosa (decompose backlog/esperado, prd-clean, prd-evolve, test-check-prd, trace spec.md) → Task 6. ✓
- Validação (eval, check-assets, grep) → Task 7. ✓
- Fora do escopo respeitado: trace-prd.sh, traceability-table.md, §12 parser, históricos datados, nomes de pasta. ✓

**2. Placeholders:** nenhum "TBD/etc" — cada edição mostra o texto exato antes/depois.

**3. Consistência de tipos/strings:** o glyph novo `◐ em especificação` aparece de forma idêntica em `trace-backlog.sh` (Edições 4f e 4i), na legenda das fixtures/template e na regex do teste (Task 2 Step 2 L46). As chaves de parser `slug`/`pasta` casam os cabeçalhos `Spec (slug)`/`Pasta` sem colisão (nenhum outro cabeçalho contém "slug" ou "pasta"). O aviso `Spec sem pasta` está alinhado entre script (Edição 4g), teste (L62) e `zion-prd-trace/SKILL.md` (L53).
