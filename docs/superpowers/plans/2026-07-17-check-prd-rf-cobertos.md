# `check-prd.sh` — verificar o pedido de `**RF cobertos:**` no modo specify (R4) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fazer o `check-prd.sh specify` verificar por máquina que o prompt montado pede a linha `**RF cobertos:**` — o elo forward RF↔spec que hoje só é conferido no `trace`, tarde demais.

**Architecture:** Nova função `check_rf_cobertos` no `check-prd.sh`, simétrica ao `check_stack` e ligada **só no modo `specify`**. Grepa `RF cobertos:` (mesmo padrão do `trace-prd.sh`); ausência → um achado advisório `rf-cobertos-ausente` sem número de linha (é uma ausência, não há linha para ancorar). Exit `1`, não bloqueia — igual a todo o resto do harness. A prosa (SKILL Fase 4 + quality-rules `#anatomia-specify`) é alinhada ao novo mecanismo. `check-prd.sh` e `quality-rules.md` são assets canônicos; o pre-commit hook re-sincroniza os `references/` das skills automaticamente.

**Tech Stack:** Bash (POSIX-ish, `set -u`), `grep -iE`, auto-teste `scripts/test-check-prd.sh` contra `scripts/fixtures/`. Sync via `scripts/sync-assets.sh` (disparado pelo `.githooks/pre-commit`).

---

## Contexto que o implementador precisa (leia antes de começar)

**O que já existe (não repetir):**
- A skill `zion-prd-specify-prompt` já **manda** o prompt pedir a linha `**RF cobertos:**` (`SKILL.md:33-36`) e `quality-rules.md` a descreve (`:105-108`).
- O `trace-prd.sh` já grepa `RF cobertos:` no `spec.md` final e emite "Spec intraçável" quando falta (`trace-prd.sh:96,111-113`).

**O que falta (este plano):** o `check-prd.sh` **não** confere se o *prompt montado* pede a linha. Hoje `specify` só roda `check_stack` (`check-prd.sh:110`).

**Divisão de responsabilidade (complementar, não redundante):**
- `check-prd.sh specify` → protege a **montagem do prompt** (Fase 4, antes do handoff).
- `trace-prd.sh` → protege o **artefato final** (`spec.md`, depois).
- Os dois grepam o **mesmo padrão** `RF cobertos:` (case-insensitive), então concordam sobre o que é "o elo".

**Por que o gatilho é só o pedido da linha (§4.1 do design):** o achado dispara **apenas** pela ausência do pedido da linha — **nunca** por não haver um `RF-xx` concreto. A fatia walking skeleton (spec 001) legitimamente não cobre nenhum RF e declara `**RF cobertos:** (nenhum)`. O padrão `RF cobertos:` casa o rótulo mesmo sem número depois — então o skeleton passa limpo. Exigir um `RF-xx` nomeado daria falso-positivo justamente nele.

**Denylist (confirmado):** os termos `linguagem`, `framework`, `bibliotecas`, `stack`, `plan` **não** estão na denylist do `quality-rules.md`. A frase-guarda "não citar linguagem, framework ou bibliotecas; a stack fica no plan" é limpa de stack — por isso as fixtures abaixo podem usá-la.

---

## File Structure

| Arquivo | Responsabilidade | Mudança |
|---|---|---|
| `scripts/check-prd.sh` | Verificador mecânico (asset canônico) | Nova função `check_rf_cobertos`; wire no modo `specify`; atualizar comentário de uso |
| `scripts/fixtures/specify-sem-rf.txt` | Fixture de teste | **Novo.** Prompt com resultado observável, zero stack, **sem** o pedido de RF |
| `scripts/test-check-prd.sh` | Auto-teste (semente R7) | Corrige teste #4 (prompt limpo inclui o pedido de RF); novo teste #5 |
| `skills/zion-prd-specify-prompt/SKILL.md` | Prosa da ponte specify | Fase 4 menciona a checagem do pedido de `**RF cobertos:**` |
| `assets/quality-rules.md` | Regras de qualidade (asset canônico) | `#anatomia-specify`: o elo é verificado por máquina |
| `skills/*/references/` | Cópias derivadas | **Não editar à mão** — regeneradas pelo pre-commit hook |

---

## Task 1: Fixture + teste que falha (TDD — vermelho primeiro)

Cria a fixture nova e ajusta o auto-teste. O teste #5 vai **falhar** agora porque `check_rf_cobertos` ainda não existe (o modo `specify` só roda `check_stack`, então a fixture sem-stack sai `0` em vez de `1`). O teste #4 vira preparatório: seu prompt "limpo" passa a incluir o pedido de RF, para continuar limpo **depois** que a checagem existir.

**Files:**
- Create: `scripts/fixtures/specify-sem-rf.txt`
- Modify: `scripts/test-check-prd.sh:37-39` (teste #4) e inserir teste #5 antes da linha de resumo (`:40`)

- [ ] **Step 1: Criar a fixture `specify-sem-rf.txt`**

Resultado observável + frase-guarda (limpa de stack), mas **sem** `RF cobertos:`.

Create `scripts/fixtures/specify-sem-rf.txt`:

```
Como usuário, quero editar o diagrama e ver a prévia atualizar ao digitar.
Não citar linguagem, framework ou bibliotecas; a stack fica no plan.
```

- [ ] **Step 2: Corrigir o teste #4 (prompt limpo passa a pedir a linha de RF)**

Em `scripts/test-check-prd.sh`, substitua o bloco atual do teste #4:

```bash
# 4. specify limpo via stdin → exit 0
out="$(printf 'O usuário edita o diagrama e vê a prévia atualizar ao digitar.\n' | bash "$CHECK" specify -)"; rc=$?
assert_exit "specify limpo sai 0" 0 "$rc"
```

por:

```bash
# 4. specify limpo (com o pedido de **RF cobertos:**) via stdin → exit 0
out="$(printf 'O usuário edita o diagrama e vê a prévia atualizar ao digitar.\nPeça que o spec.md inclua a linha **RF cobertos:** RF-01 com os RF que a fatia cobre.\n' | bash "$CHECK" specify -)"; rc=$?
assert_exit "specify limpo sai 0" 0 "$rc"
```

- [ ] **Step 3: Adicionar o teste #5**

Em `scripts/test-check-prd.sh`, **imediatamente antes** da linha final de resumo:

```bash
if [ "$fail" -eq 0 ]; then echo "test-check-prd: tudo verde"; else echo "test-check-prd: FALHOU"; exit 1; fi
```

insira:

```bash
# 5. specify sem o pedido de **RF cobertos:** → exit 1 + rf-cobertos-ausente
out="$(bash "$CHECK" specify - < "$FIX/specify-sem-rf.txt")"; rc=$?
assert_exit "specify sem RF sai 1" 1 "$rc"
assert_contains "specify sem RF acha rf-cobertos-ausente" "rf-cobertos-ausente" "$out"

```

- [ ] **Step 4: Rodar a suíte e confirmar que o teste #5 FALHA**

Run: `bash scripts/test-check-prd.sh`
Expected: teste #4 continua `ok`; teste #5 FALHA com:
```
FALHOU: specify sem RF sai 1 (exit esperado 1, veio 0)
FALHOU: specify sem RF acha rf-cobertos-ausente (não achou: rf-cobertos-ausente)
test-check-prd: FALHOU
```
(A fixture não tem stack e o modo `specify` ainda só roda `check_stack`, então sai `0`. É o vermelho esperado — a Task 2 o torna verde.)

---

## Task 2: Implementar `check_rf_cobertos` e ligá-la (verde)

Adiciona a função e o wiring. Depois disto a suíte inteira fica verde.

**Files:**
- Modify: `scripts/check-prd.sh` (comentário de uso `:8`; nova função após `check_stack` em `:76`; wiring `:110`)
- Test: `scripts/test-check-prd.sh`

- [ ] **Step 1: Atualizar o comentário de uso do modo `specify`**

Em `scripts/check-prd.sh`, substitua a linha:

```bash
#   check-prd.sh specify <arquivo|->  # só stack (prompt do specify; - lê do stdin)
```

por:

```bash
#   check-prd.sh specify <arquivo|->  # stack + rf-cobertos-ausente (prompt do specify; - lê do stdin)
```

- [ ] **Step 2: Adicionar a função `check_rf_cobertos`**

Em `scripts/check-prd.sh`, logo **após** a chave de fechamento da `check_stack` (a linha `}` em `:76`, antes do comentário `# Seção 7: item de NFR ...`), insira:

```bash
# O prompt do specify deve pedir a linha **RF cobertos:** (elo forward RF↔spec).
# Simétrica ao check_stack, mas só no modo specify. Grepa o MESMO padrão do trace-prd.sh.
# Como é uma *ausência*, não há linha para ancorar → achado sem número de linha.
# Gatilho: só o pedido do rótulo — NÃO um RF-xx concreto (o skeleton declara "(nenhum)").
check_rf_cobertos() {
  if ! grep -iqE 'RF cobertos:' "$SRC" 2>/dev/null; then
    printf '%s: rf-cobertos-ausente — o prompt não pede a linha **RF cobertos:** (elo forward RF↔spec; veja quality-rules #anatomia-specify)\n' "$LABEL"
  fi
}
```

- [ ] **Step 3: Ligar a função no modo `specify`**

Em `scripts/check-prd.sh`, substitua a linha do wiring:

```bash
  specify) findings="$(check_stack)" ;;
```

por:

```bash
  specify) findings="$(check_stack; check_rf_cobertos)" ;;
```

(O modo `prd` **não muda**: a linha `**RF cobertos:**` é artefato do `spec.md`, não da PRD.)

- [ ] **Step 4: Rodar a suíte e confirmar tudo verde**

Run: `bash scripts/test-check-prd.sh`
Expected: última linha `test-check-prd: tudo verde` (todos os `ok:`, nenhum `FALHOU`). Em particular:
- `ok: specify limpo sai 0` (o prompt limpo agora tem `RF cobertos:`)
- `ok: specify sem RF sai 1`
- `ok: specify sem RF acha rf-cobertos-ausente`

- [ ] **Step 5: Sanidade manual — a fixture sem-RF só acha `rf-cobertos-ausente` (zero stack)**

Run: `bash scripts/check-prd.sh specify - < scripts/fixtures/specify-sem-rf.txt`
Expected: exit `1`; a saída contém a linha
```
specify: rf-cobertos-ausente — o prompt não pede a linha **RF cobertos:** ...
```
e **não** contém nenhum achado de `stack`, terminando em `check-prd: 1 achado(s)`.

- [ ] **Step 6: Sanidade manual — o walking skeleton (`(nenhum)`) passa limpo (§4.1)**

Run: `printf '%s\n' 'Fatia-zero de infraestrutura. **RF cobertos:** (nenhum)' | bash scripts/check-prd.sh specify -`
Expected: exit `0`, saída `check-prd: limpo`. (O rótulo sozinho satisfaz o padrão — não exigimos `RF-xx` concreto.)

- [ ] **Step 7: Commit do mecanismo**

```bash
git add scripts/check-prd.sh scripts/test-check-prd.sh scripts/fixtures/specify-sem-rf.txt
git commit -m "feat(check-prd): verifica pedido de **RF cobertos:** no modo specify (R4)"
```
Nota: o pre-commit hook roda `sync-assets.sh` e faz `git add skills/*/references/` — o `check-prd.sh` regenerado nas duas skills consumidoras entra no mesmo commit automaticamente.

---

## Task 3: Alinhar a prosa ao mecanismo

A prosa e o mecanismo têm de concordar. Atualiza a Fase 4 da SKILL e a nota em `#anatomia-specify`.

**Files:**
- Modify: `skills/zion-prd-specify-prompt/SKILL.md:38-46` (Fase 4)
- Modify: `assets/quality-rules.md:105-108` (`#anatomia-specify`)

- [ ] **Step 1: Atualizar a Fase 4 da SKILL**

Em `skills/zion-prd-specify-prompt/SKILL.md`, substitua o bloco atual:

```markdown
## Fase 4 — Validar saída e handoff (aconselha)
Verifique o zero-stack por máquina, passando o prompt montado ao script via stdin:

    printf '%s' "<prompt montado>" | bash references/check-prd.sh specify -

O script casa o prompt contra a denylist e os sinais estruturais e imprime cada achado com o número
da linha do prompt. **Ecoe o veredito** — para cada achado, lembre que a stack fica no `plan`, não no
`specify`. Complemente com o julgamento que o script não faz: o prompt declara um resultado
observável ∧ cita `RF-xx`/ADR como contexto (referência), não como requisito. Não bloqueie.
```

por:

```markdown
## Fase 4 — Validar saída e handoff (aconselha)
Verifique por máquina, passando o prompt montado ao script via stdin, que o prompt (a) não vaza stack
e (b) pede a linha **`**RF cobertos:**`** — o elo forward RF↔spec:

    printf '%s' "<prompt montado>" | bash references/check-prd.sh specify -

O script casa o prompt contra a denylist e os sinais estruturais (achados de `stack`) e confere que o
prompt pede a linha `**RF cobertos:**` (achado `rf-cobertos-ausente` quando falta). **Ecoe o
veredito** — para cada achado de stack, lembre que a stack fica no `plan`, não no `specify`; se faltar
o pedido de `**RF cobertos:**`, acrescente-o antes do handoff. Complemente com o julgamento que o
script não faz: o prompt declara um resultado observável ∧ cita `RF-xx`/ADR como contexto
(referência), não como requisito. Não bloqueie.
```

- [ ] **Step 2: Atualizar `#anatomia-specify` no `quality-rules.md`**

Em `assets/quality-rules.md`, substitua o bullet atual:

```markdown
- **A linha `**RF cobertos:**`** — peça que o `spec.md` inclua uma linha rotulada
  `**RF cobertos:** RF-xx, ...` com os RF que a fatia cobre. É o elo forward RF↔spec legível por
  máquina: o `/zion-prd-trace` a grepa para reconciliar a tabela de rastreabilidade. Declarar *quais*
  RF a fatia cobre é o-quê/rastreabilidade, não stack — não fere a fronteira sem-stack.
```

por:

```markdown
- **A linha `**RF cobertos:**`** — peça que o `spec.md` inclua uma linha rotulada
  `**RF cobertos:** RF-xx, ...` com os RF que a fatia cobre. É o elo forward RF↔spec legível por
  máquina. O `check-prd.sh specify` verifica por máquina que o prompt **pede** essa linha (achado
  `rf-cobertos-ausente` quando falta); o `/zion-prd-trace` depois confere que o `spec.md` resultante a
  **tem** (aviso "Spec intraçável"). Declarar *quais* RF a fatia cobre é o-quê/rastreabilidade, não
  stack — não fere a fronteira sem-stack.
```

- [ ] **Step 3: Confirmar que nada quebrou**

Run: `bash scripts/test-check-prd.sh`
Expected: `test-check-prd: tudo verde` (a prosa não altera o comportamento do script).

- [ ] **Step 4: Commit da prosa**

```bash
git add skills/zion-prd-specify-prompt/SKILL.md assets/quality-rules.md
git commit -m "docs(specify): prosa alinha check-prd verificar pedido de **RF cobertos:** (R4)"
```
Nota: o pre-commit hook re-sincroniza `quality-rules.md` para os `references/` das 7 skills consumidoras e os inclui no commit automaticamente.

---

## Task 4: Verificação final (sem drift, tudo verde)

Confirma que os `references/` derivados batem com os canônicos e que a suíte passa — o mesmo que o CI (`check-assets.yml`) roda.

**Files:** nenhum (só verificação).

- [ ] **Step 1: Confirmar sync sem drift**

Run: `bash scripts/check-assets.sh`
Expected: saída sem nenhuma linha `DRIFT:` e exit `0`. (Confirma que o `check-prd.sh` e o `quality-rules.md` nos `references/` das skills batem com `assets/` — o hook já os regenerou nos commits anteriores.)

- [ ] **Step 2: Confirmar o auto-teste verde**

Run: `bash scripts/test-check-prd.sh`
Expected: `test-check-prd: tudo verde`.

- [ ] **Step 3: Sanidade do elo compartilhado — `check-prd` e `trace` concordam no padrão**

Run: `grep -n "RF cobertos:" scripts/check-prd.sh scripts/trace-prd.sh`
Expected: ambos grepam o literal `RF cobertos:` (case-insensitive via `-i`), confirmando que "o elo" é o mesmo padrão nos dois verificadores.

- [ ] **Step 4: Confirmar árvore limpa**

Run: `git status --short`
Expected: vazio (todos os commits incluíram os `references/` regenerados pelo hook; nada pendente).

---

## Self-Review (feita ao escrever o plano)

**1. Cobertura do design:**
- §4 (nova função `check_rf_cobertos`, slug `rf-cobertos-ausente`, formato sem número de linha, wiring, `prd` intacto) → Task 2.
- §4.1 (gatilho só o pedido da linha, skeleton `(nenhum)` passa) → Task 2 Step 6 (sanidade) + comentário na função.
- §5 (corrigir teste #4, novo teste #5) → Task 1.
- §6 (prosa SKILL Fase 4 + quality-rules `#anatomia-specify`) → Task 3.
- §7 (superfície de mudança, sync sem entrada nova no mapa) → Tasks 2/3 (commits com hook) + Task 4 (verificação).
- §8 (fora de escopo) → respeitado: sem modo `prd`, sem verificar `spec.md` final, sem exigir `RF-xx` concreto, sem mapear RF↔FR-xxx, sem bloqueio.

**2. Placeholders:** nenhum — todo passo tem conteúdo/comando/saída esperada concretos.

**3. Consistência de tipos/nomes:** função `check_rf_cobertos` (mesmo nome no design §4, na implementação Task 2 e no wiring), slug `rf-cobertos-ausente` idêntico em fixture/teste/função/prosa, padrão `RF cobertos:` idêntico ao do `trace-prd.sh`.
