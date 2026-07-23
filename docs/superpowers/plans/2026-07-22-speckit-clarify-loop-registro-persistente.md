# Registro persistente por rodada no `speckit-clarify-loop` — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Persistir cada rodada do `tools/speckit-clarify-loop` numa linha `chave=valor` incremental (`rounds.txt`) e o resumo consolidado num arquivo (`summary.txt`), pagando a dívida de medição que hoje se paga à mão com `jq` arqueológico.

**Architecture:** Uma função pura nova (`round_record`) espelha o `sensor_line` existente; um escritor impuro fino a anexa a `$LOG_DIR/rounds.txt` no único ponto que roda para toda rodada fechada (após `narrate_sensors`, antes do `case` que dá `break`); o bloco `—— resumo ——` vira a função emissora única `print_summary`, capturada uma vez e destinada a stdout **e** a `summary.txt`. O harness sem custo ganha um modo de corte externo (`SKCL_CUT`) que prova, de graça, a recuperação de um run cortado. Toda escrita nova cai em `$LOG_DIR`; nada toca o repo-alvo nem o spec.

**Tech Stack:** Bash (o script é uma ferramenta pessoal instalada por cópia no PATH); verificação via `--self-test` embutido (puro, sem custo) e via `tools/speckit-clarify-loop-harness.sh` (repo Spec Kit falso + stub determinístico de `claude`, sem custo).

## Global Constraints

Copiadas literalmente da spec (`docs/superpowers/specs/2026-07-22-speckit-clarify-loop-registro-persistente-design.md`). Os requisitos de cada tarefa incluem implicitamente esta seção.

- **`tools/` está FORA do canon.** `scripts/check-canon.sh` não referencia `tools/`. Esta mudança **não** cria nem supera ADR, e **não** toca `docs/prd.md` nem `docs/architecture.md`. O dever de canonização do `CLAUDE.md` não se aplica.
- **P-7 (guia da spec): o registro é conveniência, não contrato.** Falha de escrita degrada gracioso e nunca derruba a execução. Toda escrita nova usa `>> … 2>/dev/null || true` (mesmo espírito do `ln -sfn … || true` do `latest`).
- **P-2:** o registro lê as variáveis de estado já computadas (`ROUND_*`); nunca re-parseia o stream do LLM.
- **P-3:** decisão/formatação é função pura, exercitável pelo `--self-test` sem repo e sem custo.
- **P-6:** os campos do registro **reusam** os locais que já existem — zero coleta nova.
- **NÃO MEXER** (intocados): `SENTINEL_PROMPT` · `classify`/`read_sentinel` · `miss_action`/`SENT_MISS_MAX` e a rede sonda/aborto · `leaked_sentinel` casando contra `added_lines` · a máquina de estados de `run_round` · a lógica de parada de `main_loop` (`case "$ROUND_OUTCOME"`, `--dry-run`, estagnação, teto) · a tabela de códigos de saída (0/1/2) · a linha `sensores ·` e `narrate_sensors`.
- **FORA DE ESCOPO:** Alternativa C (razão de adesão / novo texto de decisão no resumo — o registro grava só a **contagem** `dec=`) · Alternativa D (rede forçada sob `--dry-run`, trap de captura de interrupção) · qualquer mudança de comportamento observável no repo-alvo.
- **O `--self-test` continua puro:** as 4 asserções novas são só do `round_record`; as 21 fixtures de prosa que esperam `indeterminada` continuam lá.
- **Commits:** Conventional Commits (o repo tem `check-commit.sh` + `commit-lint.yml` **bloqueantes**). O pre-commit também regenera derivados e roda os guards — como nada em `assets/`/`skills/` é tocado, não há drift.
- **Só dois arquivos mudam:** `tools/speckit-clarify-loop` e `tools/speckit-clarify-loop-harness.sh`.

---

### Task 1: `round_record` — a linha `chave=valor` por rodada, como função pura (R-1)

**Files:**
- Modify: `tools/speckit-clarify-loop` — inserir `round_record` logo após `sensor_line` (após a linha `751`); inserir 4 asserções em `self_test` após os asserts de `sensor_line` (após a linha `1753`).

**Interfaces:**
- Consumes: nada (função pura, sem estado, sem I/O).
- Produces: `round_record round turns sent yes dec cost delta outcome` → escreve em stdout uma única linha **sem** newline final: `round=<r> turns=<t> sent=<s> yes=<y> dec=<d> cost=<c> delta=<±n> out=<tok>`. O campo `delta` é formatado com `%+d` (sempre com sinal). O `out` é um dos tokens `rodada-completa`/`loop-seco`/`aborto`/`dry-pergunta`. Consumido pelo escritor do R-2 (Task 2), que acrescenta o `\n`.

- [ ] **Step 1: Escrever os 4 testes que falham**

Em `tools/speckit-clarify-loop`, dentro de `self_test`, logo **após** o bloco de asserts do `sensor_line` (a linha que termina em `sensor_line 0 0 0 0 0 0 0 0.1`, atual `:1753`), inserir:

```bash

  # R-1: round_record é pura — RECEBE os oito valores e devolve a linha. Cabe no
  # assert_out (P-3), sem o assert_emit das funções com estado. Cobre: linha
  # bem-formada, out=aborto, dec=0 (rodada sem decisão) e delta negativo com sinal.
  assert_out "registro por rodada sai em chave=valor" \
    'round=03 turns=4 sent=4 yes=3 dec=2 cost=1.33 delta=+36 out=rodada-completa' \
    round_record 03 4 4 3 2 1.33 36 rodada-completa
  assert_out "rodada abortada carrega out=aborto" \
    'round=07 turns=2 sent=0 yes=0 dec=0 cost=0.79 delta=+0 out=aborto' \
    round_record 07 2 0 0 0 0.79 0 aborto
  assert_out "rodada sem decisão nomeada mostra dec=0" \
    'round=01 turns=1 sent=1 yes=0 dec=0 cost=0.10 delta=+0 out=loop-seco' \
    round_record 01 1 1 0 0 0.10 0 loop-seco
  assert_out "delta negativo formata com sinal" \
    'round=02 turns=3 sent=3 yes=2 dec=1 cost=0.50 delta=-12 out=rodada-completa' \
    round_record 02 3 3 2 1 0.50 -12 rodada-completa
```

- [ ] **Step 2: Rodar o auto-teste e confirmar que falha**

Run: `tools/speckit-clarify-loop --self-test 2>&1 | tail -8`
Expected: 4 linhas `FALHOU:` (a saída `[]` vazia porque `round_record` ainda não existe — `round_record: command not found` no stderr) e a linha final:
```
speckit-clarify-loop: self-test COM FALHAS (147 casos)
```
(O contador já sobe para 147 porque `assert_out` incrementa `ST_COUNT` mesmo em falha.)

- [ ] **Step 3: Escrever a implementação mínima**

Em `tools/speckit-clarify-loop`, logo **após** o fechamento de `sensor_line` (o `}` na atual `:751`) e **antes** do comentário `# --- Sensores: coleta e narração (impura)`, inserir:

```bash

# Uma linha por rodada, chave=valor em ASCII (R-1) — espelha o sensor_line: entram
# os oito valores JÁ computados, sai uma linha que a Fase 5 agrega com grep/awk, e
# que já se paga na leitura humana de um run isolado (cat/grep, sem jq). Pura, sem
# I/O, testável por assert_out (P-3). Sem newline final de propósito: quem grava
# (R-2) é que acrescenta o \n. `sent` e `turns` vão em campos separados (dois
# inteiros são mais limpos para o awk do que um par a re-splitar).
round_record() {  # round turns sent yes dec cost delta outcome → linha
  printf 'round=%s turns=%s sent=%s yes=%s dec=%s cost=%s delta=%+d out=%s' \
    "${1:-00}" "${2:-0}" "${3:-0}" "${4:-0}" "${5:-0}" "${6:-0}" "${7:-0}" "${8:-?}"
  return 0
}
```

- [ ] **Step 4: Rodar o auto-teste e confirmar que passa**

Run: `tools/speckit-clarify-loop --self-test 2>&1 | tail -1`
Expected: `speckit-clarify-loop: self-test limpo (147 casos)`

- [ ] **Step 5: Commit**

```bash
git add tools/speckit-clarify-loop
git commit -m "$(cat <<'EOF'
feat(tools): round_record e 4 casos de auto-teste (R-1)

A linha chave=valor por rodada como função pura, espelhando o sensor_line.
Auto-teste sobe de 143 para 147 casos.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 2: escritor incremental — uma linha anexada quando a rodada fecha (R-2)

**Files:**
- Modify: `tools/speckit-clarify-loop` — estender a declaração de locais de `main_loop` (atual `:958`) com `snap_lines r_delta`; inserir o escritor entre `narrate_sensors` (atual `:1009`) e o `case "$ROUND_OUTCOME"` (atual `:1011`).

**Interfaces:**
- Consumes: `round_record` (Task 1); os globais `ROUND_TURNS`, `ROUND_SENT`, `ROUND_YES`, `ROUND_DECISIONS`, `ROUND_COST`, `ROUND_OUTCOME`; os locais de `main_loop` `tag` e `snap`; a função `spec_lines` (lê `$SPEC`); o global `LOG_DIR`.
- Produces: `$LOG_DIR/rounds.txt` — uma linha por rodada que fechou, na ordem, qualquer desfecho (inclusive `aborto` e o vazamento do M-06). É o append incremental que recupera um run cortado (E-2).

- [ ] **Step 1: Declarar os dois locais temporários**

Em `main_loop`, a linha (atual `:958`):
```bash
  local start_lines end_lines delta tag rule_pad snap
```
vira:
```bash
  local start_lines end_lines delta tag rule_pad snap snap_lines r_delta
```

- [ ] **Step 2: Inserir o escritor incremental**

Em `main_loop`, localizar (atual `:1009–1011`):
```bash
    narrate_sensors "$snap" "$SPEC" "$ROUND_COST"

    case "$ROUND_OUTCOME" in
```
e inserir o bloco entre `narrate_sensors …` e `case …`, ficando:
```bash
    narrate_sensors "$snap" "$SPEC" "$ROUND_COST"

    # Registro incremental por rodada (R-2): anexa a linha do R-1 a rounds.txt
    # assim que a rodada fecha — ANTES do case que pode dar break, o único ponto
    # que roda para TODA rodada, qualquer desfecho (inclusive aborto e o vazamento
    # do M-06, que já reescreveu ROUND_OUTCOME acima). É o append incremental — não
    # um tee do resumo final — que recupera um run cortado (E-2). O `|| true` e o
    # `2>/dev/null` são o P-7: se $LOG_DIR sumiu, a rodada segue. `dec` é a CONTAGEM
    # de linhas de ROUND_DECISIONS (não o texto — o texto é da Alternativa C).
    snap_lines="$(wc -l < "$snap" | tr -d ' ')"
    r_delta=$(( $(spec_lines) - snap_lines ))
    printf '%s\n' "$(round_record "$tag" "$ROUND_TURNS" "$ROUND_SENT" "$ROUND_YES" \
      "$(printf '%s' "$ROUND_DECISIONS" | grep -c .)" "$ROUND_COST" "$r_delta" \
      "$ROUND_OUTCOME")" >> "$LOG_DIR/rounds.txt" 2>/dev/null || true

    case "$ROUND_OUTCOME" in
```

- [ ] **Step 3: Confirmar que o `--self-test` continua limpo (não regrediu)**

Run: `tools/speckit-clarify-loop --self-test 2>&1 | tail -1`
Expected: `speckit-clarify-loop: self-test limpo (147 casos)`

- [ ] **Step 4: Exercitar o escritor pelo harness sem custo — run de K rodadas**

Run:
```bash
bash tools/speckit-clarify-loop-harness.sh --max-rounds 3 >/dev/null 2>&1 || true
cat /tmp/speckit-clarify-loop/latest/rounds.txt
```
Expected: exatamente 3 linhas bem-formadas, na ordem (o stub apende 4 linhas por rodada → `delta=+4`; um `yes` e uma decisão por rodada; custo 0.25):
```
round=01 turns=2 sent=2 yes=1 dec=1 cost=0.25 delta=+4 out=rodada-completa
round=02 turns=2 sent=2 yes=1 dec=1 cost=0.25 delta=+4 out=rodada-completa
round=03 turns=2 sent=2 yes=1 dec=1 cost=0.25 delta=+4 out=rodada-completa
```

- [ ] **Step 5: Exercitar o desfecho `aborto` (uma linha, `out=aborto`)**

O modo `SKCL_NOSENT=1` do harness produz uma rodada que aborta na segunda ausência de sentinela.

Run:
```bash
SKCL_NOSENT=1 bash tools/speckit-clarify-loop-harness.sh >/dev/null 2>&1 || true
cat /tmp/speckit-clarify-loop/latest/rounds.txt
```
Expected: uma única linha com `out=aborto`, `sent=0`, `yes=0`, `dec=0`:
```
round=01 turns=2 sent=0 yes=0 dec=0 cost=0.25 delta=+4 out=aborto
```

- [ ] **Step 6: Commit**

```bash
git add tools/speckit-clarify-loop
git commit -m "$(cat <<'EOF'
feat(tools): registro incremental por rodada em rounds.txt (R-2)

Anexa a linha do round_record assim que a rodada fecha, antes do case que
pode dar break. É o append que recupera um run cortado (E-2). Degrade
gracioso (|| true) pelo P-7. Verificado pelo harness sem custo.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 3: `summary.txt` — o resumo consolidado, teado ao fim (R-3)

**Files:**
- Modify: `tools/speckit-clarify-loop` — remover `dec_block=""` da declaração de locais de `main_loop` (atual `:957`); definir `print_summary` logo antes de `main_loop` (após `run_round`, antes do comentário `# --- Driver do loop`); substituir o bloco `—— resumo ——` (atual `:1058–1078`) pela captura-e-tee.

**Interfaces:**
- Consumes: `decisions_block` (existente); por escopo dinâmico do bash, os locais de `main_loop` `round`, `total_yes`, `yes_log`, `total_cost`, `total_sent`, `total_turns`, `start_lines`, `end_lines`, `delta`, `stop_reason`, `all_decisions`, e os globais `REPO`, `SPEC`, `LOG_DIR`.
- Produces: `print_summary` — emite o texto do `—— resumo ——` em stdout, **sem** `return "$rc"` (isso é de `main_loop`). `$LOG_DIR/summary.txt` — o resumo do happy-path (só existe se o run chega ao fim).

> **Sobre escopo dinâmico:** `print_summary` é definida no topo mas só chamada de dentro de `main_loop`. Variáveis `local` do bash são dinamicamente escopadas — uma função chamada (direta ou via `$(...)`) enquanto `main_loop` está na pilha enxerga os locais de `main_loop`. É o desenho que a spec endossa: "`print_summary` só emite texto; `rc`/`stop_reason`/totais já estão setados antes da chamada".

- [ ] **Step 1: Tirar `dec_block` dos locais de `main_loop`**

`print_summary` passa a declarar o seu próprio `dec_block`. A linha (atual `:957`):
```bash
  local total_turns=0 total_sent=0 all_decisions="" dec_block=""
```
vira:
```bash
  local total_turns=0 total_sent=0 all_decisions=""
```

- [ ] **Step 2: Definir `print_summary`**

Localizar o fim de `run_round` e o cabeçalho do driver (atual `:951–954`):
```bash
  [ "$ROUND_OUTCOME" != aborto ] || emit_note warn "aborto: $ROUND_ABORT"
}

# --- Driver do loop ---------------------------------------------------------
main_loop() {
```
e inserir `print_summary` entre o `}` de `run_round` e o comentário `# --- Driver do loop`, ficando:
```bash
  [ "$ROUND_OUTCOME" != aborto ] || emit_note warn "aborto: $ROUND_ABORT"
}

# --- Resumo consolidado -----------------------------------------------------
# Emissor único do —— resumo —— (R-3): gera o texto UMA vez, para tela e para
# summary.txt, sem duplicar os printf. Lê por escopo dinâmico os totais e o
# stop_reason que main_loop já setou; NÃO devolve rc — isso é de main_loop. O `\n`
# inicial e a estrutura interna são preservados na captura `$(...)`, que apara só
# newlines FINAIS, então o stdout casa byte-a-byte o de antes.
print_summary() {
  local dec_block
  printf '\n—— resumo ——\n'
  printf 'repo:     %s\n' "$REPO"
  printf 'spec:     %s\n' "$SPEC"
  printf 'rodadas:  %s\n' "$round"
  printf 'yes:      %s (%s)\n' "$total_yes" "${yes_log# }"
  printf 'custo:    US$ %s\n' "$total_cost"
  printf 'contrato: sentinela em %s/%s turnos\n' "$total_sent" "$total_turns"
  printf 'spec:     %s → %s linhas (delta %+d)\n' "$start_lines" "$end_lines" "$delta"
  printf 'logs:     %s\n' "$LOG_DIR"
  printf '          round-NN.jsonl (stream) · round-NN.log (narração) · latest → esta execução\n'
  printf 'parada:   %s\n' "$stop_reason"
  # O único ponto do resumo em que o humano vê O QUE foi decidido, e não só quanto
  # custou. Bloco, e não coluna.
  dec_block="$(decisions_block "$total_yes" "$all_decisions")"
  [ -z "$dec_block" ] || printf '\n%s\n' "$dec_block"
  printf '\nreverter: git -C %s checkout -- %s\n' "$REPO" "$SPEC"
  # Última linha do resumo, em TODO caminho de saída.
  printf 'revisar:  git -C %s diff -- %s\n' "$REPO" "$SPEC"
  return 0
}

# --- Driver do loop ---------------------------------------------------------
main_loop() {
```

- [ ] **Step 3: Substituir o bloco inline pela captura-e-tee em `main_loop`**

Em `main_loop`, o bloco `—— resumo ——` (atual `:1058–1078`) — que começa em `printf '\n—— resumo ——\n'` e termina em `printf 'revisar:  git -C %s diff -- %s\n' "$REPO" "$SPEC"` — é **removido inteiro** e substituído. **Mantenha** as duas linhas acima dele (`end_lines="$(spec_lines)"` e `delta=$((end_lines - start_lines))`, atual `:1056–1057`) e a linha abaixo (`return "$rc"`, atual `:1080`). O resultado:
```bash
  end_lines="$(spec_lines)"
  delta=$((end_lines - start_lines))
  # Resumo consolidado (R-3): capturado UMA vez e destinado a tela E a summary.txt.
  # Captura em vez de `tee`: se summary.txt não abrir, o `|| true` engole o erro sem
  # arriscar imprimir o resumo duas vezes na tela (P-7). summary.txt é o artefato do
  # happy-path — só nasce se o run chega até aqui; quem sobrevive a corte externo é
  # o rounds.txt do R-2.
  local summ; summ="$(print_summary)"
  printf '%s\n' "$summ"
  printf '%s\n' "$summ" > "$LOG_DIR/summary.txt" 2>/dev/null || true

  return "$rc"
}
```

- [ ] **Step 4: Confirmar que o `--self-test` continua limpo**

Run: `tools/speckit-clarify-loop --self-test 2>&1 | tail -1`
Expected: `speckit-clarify-loop: self-test limpo (147 casos)`

- [ ] **Step 5: Provar que `summary.txt` casa o stdout byte-a-byte**

O resumo é a última coisa que o run imprime, então as últimas N linhas do stdout (N = linhas de `summary.txt`) têm que casar `summary.txt` exatamente.

Run:
```bash
bash tools/speckit-clarify-loop-harness.sh --max-rounds 2 > /tmp/skcl-out.txt 2>/dev/null || true
dir="$(readlink /tmp/speckit-clarify-loop/latest)"
n="$(wc -l < "$dir/summary.txt")"
diff <(tail -n "$n" /tmp/skcl-out.txt) "$dir/summary.txt" && echo "OK: summary.txt casa o stdout byte-a-byte"
```
Expected: sem diff, seguido de `OK: summary.txt casa o stdout byte-a-byte`. O `summary.txt` contém o `—— resumo ——` completo, com o bloco `decisões aceitas (2):` no meio e as linhas `reverter:`/`revisar:` no fim.

- [ ] **Step 6: Commit**

```bash
git add tools/speckit-clarify-loop
git commit -m "$(cat <<'EOF'
feat(tools): print_summary emissor único + summary.txt teado (R-3)

O bloco —— resumo —— vira função emissora única, capturada uma vez e
destinada a stdout e a summary.txt. Captura em vez de tee: || true engole a
falha sem duplicar a tela (P-7). summary.txt é do happy-path. Byte-a-byte
com o stdout verificado pelo harness.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 4: os dois artefatos entram no rodapé do resumo (R-4)

**Files:**
- Modify: `tools/speckit-clarify-loop` — acrescentar uma linha de rodapé em `print_summary` (após a linha `round-NN.jsonl … latest`).

**Interfaces:**
- Consumes: `print_summary` (Task 3).
- Produces: o rodapé do resumo passa a citar `rounds.txt` e `summary.txt`, na coluna de continuação já alinhada (10 colunas).

- [ ] **Step 1: Acrescentar a linha de rodapé**

Em `print_summary`, localizar:
```bash
  printf '          round-NN.jsonl (stream) · round-NN.log (narração) · latest → esta execução\n'
```
e inserir logo abaixo (mesma indentação de 10 colunas do rótulo):
```bash
  printf '          round-NN.jsonl (stream) · round-NN.log (narração) · latest → esta execução\n'
  printf '          rounds.txt (registro por rodada) · summary.txt (este resumo)\n'
```

- [ ] **Step 2: Confirmar que o `--self-test` continua limpo**

Run: `tools/speckit-clarify-loop --self-test 2>&1 | tail -1`
Expected: `speckit-clarify-loop: self-test limpo (147 casos)`

- [ ] **Step 3: Confirmar o rodapé no resumo, alinhado**

Run:
```bash
bash tools/speckit-clarify-loop-harness.sh --max-rounds 1 2>/dev/null | sed -n '/^logs:/,/^parada:/p'
```
Expected: as linhas de `logs:` até `parada:`, com a coluna de rótulos alinhada e as duas linhas de continuação:
```
logs:     /tmp/speckit-clarify-loop/AAAAMMDD-HHMMSS
          round-NN.jsonl (stream) · round-NN.log (narração) · latest → esta execução
          rounds.txt (registro por rodada) · summary.txt (este resumo)
parada:   ...
```

- [ ] **Step 4: Reconfirmar o byte-a-byte (o rodapé novo está nos DOIS, tela e disco)**

Run:
```bash
bash tools/speckit-clarify-loop-harness.sh --max-rounds 2 > /tmp/skcl-out.txt 2>/dev/null || true
dir="$(readlink /tmp/speckit-clarify-loop/latest)"
n="$(wc -l < "$dir/summary.txt")"
diff <(tail -n "$n" /tmp/skcl-out.txt) "$dir/summary.txt" \
  && grep -q 'rounds.txt (registro por rodada) · summary.txt' "$dir/summary.txt" \
  && echo "OK: rodapé presente e byte-a-byte"
```
Expected: `OK: rodapé presente e byte-a-byte`

- [ ] **Step 5: Commit**

```bash
git add tools/speckit-clarify-loop
git commit -m "$(cat <<'EOF'
feat(tools): rodapé do resumo cita rounds.txt e summary.txt (R-4)

Quem lê o resumo passa a saber que o registro por rodada e o resumo em disco
existem e onde. Coluna de rótulos mantém o alinhamento.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 5: harness sem custo — modo de corte externo, a prova do E-2/R7

**Files:**
- Modify: `tools/speckit-clarify-loop-harness.sh` — no stub, um bloco de trava por `SKCL_HANG` (após `SPEC="${SKCL_SPEC:?}"`); no fim, passar `SKCL_COUNT` no ambiente e adicionar a orquestração `SKCL_CUT`.

**Interfaces:**
- Consumes: o comportamento incremental do `rounds.txt` (R-2) e o happy-path do `summary.txt` (R-3).
- Produces: `SKCL_HANG=M` (primitiva) — o stub trava na Mésima invocação antes de emitir qualquer coisa. `SKCL_CUT=N` (orquestração) — sobe o loop em background travando a rodada N+1, mata-o em voo, e verifica que `rounds.txt` ficou com exatamente N linhas e que `summary.txt` NÃO nasceu. Emite `corte OK: …` (exit 0) ou `corte FALHOU: …` (exit 1).

> **Por que o harness precisa mudar:** hoje ele só roda o happy-path. A prova do corte externo — a que só esta alternativa satisfaz — exige travar uma rodada e matar o loop antes do resumo. A trava é determinística (um contador em arquivo, porque cada rodada é um processo novo do stub); o poll espera `rounds.txt` chegar a N linhas (condição, não tempo), então o teste não corre atrás de relógio. `tools/` está fora do canon e o harness é dev-workflow: nada a refletir em PRD/architecture.

- [ ] **Step 1: Adicionar a trava `SKCL_HANG` no stub**

No heredoc do stub (`<<'STUB'` … `STUB`), localizar (as variáveis ficam LITERAIS no heredoc, expandidas quando o stub roda — como o `${SKCL_SPEC:?}` que já existe):
```bash
SPEC="${SKCL_SPEC:?}"
ask=''; fim=''
```
e inserir a trava entre elas:
```bash
SPEC="${SKCL_SPEC:?}"
# Corte externo (SKCL_HANG): na Mésima invocação o stub trava ANTES de emitir
# qualquer coisa, prendendo o loop na rodada M enquanto o teste o mata. O contador
# vive num arquivo porque cada rodada é um processo novo do stub.
if [ -n "${SKCL_HANG:-}" ]; then
  n=$(( $(cat "${SKCL_COUNT:?}" 2>/dev/null || echo 0) + 1 ))
  printf '%s\n' "$n" > "$SKCL_COUNT"
  [ "$n" -lt "$SKCL_HANG" ] || { sleep 60; exit 0; }
fi
ask=''; fim=''
```

- [ ] **Step 2: Passar `SKCL_COUNT` no ambiente e adicionar a orquestração `SKCL_CUT`**

No fim do harness, substituir a invocação atual:
```bash
PATH="$ROOT/bin:$PATH" SKCL_SPEC="$SPEC" \
  SKCL_NOSENT="${SKCL_NOSENT:-0}" SKCL_LEAK="${SKCL_LEAK:-0}" \
  "$LOOP" --repo "$ROOT/repo" "$@"
```
por:
```bash
common_env=(
  "PATH=$ROOT/bin:$PATH" "SKCL_SPEC=$SPEC"
  "SKCL_NOSENT=${SKCL_NOSENT:-0}" "SKCL_LEAK=${SKCL_LEAK:-0}"
  "SKCL_COUNT=$ROOT/turns"
)

if [ -n "${SKCL_CUT:-}" ]; then
  # Prova do corte externo (E-2/R7): trava a rodada CUT+1, mata o loop em voo, e
  # verifica que rounds.txt ficou com exatamente CUT linhas e que summary.txt NÃO
  # nasceu — a recuperação que o run real da R7 não teve, agora de graça.
  # Remove só o symlink `latest` (não o tree inteiro): evita casar com um `latest`
  # velho sem apagar logs de runs reais anteriores.
  rm -f /tmp/speckit-clarify-loop/latest
  env "${common_env[@]}" "SKCL_HANG=$((SKCL_CUT + 1))" \
    "$LOOP" --repo "$ROOT/repo" "$@" >/dev/null 2>&1 &
  loop_pid=$!
  rounds=/tmp/speckit-clarify-loop/latest/rounds.txt
  ok=''
  for ((i = 0; i < 200; i++)); do
    if [ -f "$rounds" ] && [ "$(wc -l < "$rounds" 2>/dev/null || echo 0)" -ge "$SKCL_CUT" ]; then
      ok=1; break
    fi
    sleep 0.1
  done
  kill -TERM "$loop_pid" 2>/dev/null
  wait "$loop_pid" 2>/dev/null
  lines="$(wc -l < "$rounds" 2>/dev/null || echo 0)"
  dir="$(readlink /tmp/speckit-clarify-loop/latest 2>/dev/null)"
  if [ -n "$ok" ] && [ "$lines" -eq "$SKCL_CUT" ] && [ ! -f "$dir/summary.txt" ]; then
    printf 'corte OK: rounds.txt=%s linhas (esperado %s), summary.txt ausente\n' "$lines" "$SKCL_CUT"
    exit 0
  fi
  printf 'corte FALHOU: rounds.txt=%s linhas (esperado %s), summary.txt %s\n' \
    "$lines" "$SKCL_CUT" "$([ -f "$dir/summary.txt" ] && echo presente || echo ausente)"
  exit 1
else
  env "${common_env[@]}" "$LOOP" --repo "$ROOT/repo" "$@"
fi
```

- [ ] **Step 3: Regressão — o harness normal continua idêntico**

O ramo `else` é equivalente à invocação de antes (mais um `SKCL_COUNT` inócuo). Confirmar que o happy-path e o modo `SKCL_NOSENT` seguem funcionando:

Run:
```bash
bash tools/speckit-clarify-loop-harness.sh --max-rounds 2 2>/dev/null | tail -1
SKCL_LEAK=1 bash tools/speckit-clarify-loop-harness.sh 2>/dev/null | grep -c 'sentinela vazou'
```
Expected: a primeira linha é `revisar:  git -C /tmp/skcl-harness/repo diff -- …` (o run chegou ao resumo); a segunda é `2` (a guarda de vazamento do M-06 segue disparando: a frase aparece na narração `[!]` da rodada **e** na linha `parada:` do resumo, via `ROUND_ABORT` — comportamento pré-existente, idêntico em 790e606).

- [ ] **Step 4: A prova do corte externo**

Run:
```bash
SKCL_CUT=2 bash tools/speckit-clarify-loop-harness.sh
```
Expected: exit 0 e a linha:
```
corte OK: rounds.txt=2 linhas (esperado 2), summary.txt ausente
```

- [ ] **Step 5: Confirmar o conteúdo do `rounds.txt` cortado**

Run:
```bash
cat /tmp/speckit-clarify-loop/latest/rounds.txt
test ! -f "$(readlink /tmp/speckit-clarify-loop/latest)/summary.txt" && echo "sem summary.txt — correto"
```
Expected: exatamente 2 linhas `round=01 …`/`round=02 …` com `out=rodada-completa`, seguidas de `sem summary.txt — correto`. É a diferença entre "guardar no fim" e "guardar à medida": as rodadas completas sobreviveram ao corte.

- [ ] **Step 6: Commit**

```bash
git add tools/speckit-clarify-loop-harness.sh
git commit -m "$(cat <<'EOF'
test(tools): harness prova o corte externo do registro (SKCL_CUT)

SKCL_HANG trava o stub numa rodada; SKCL_CUT orquestra o corte: sobe o loop,
mata em voo e verifica rounds.txt com N linhas e nenhum summary.txt. É a prova
do E-2/R7 de graça — a recuperação que o run real não teve.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 6: verificação final, `--dry-run` real e a nota datada

**Files:**
- Modify: `tools/speckit-clarify-loop` — inserir uma nota datada no cabeçalho (após o último bloco datado, atual `:85`, antes de `# Reinstalar após editar:`).

**Interfaces:**
- Consumes: tudo das Tasks 1–5.
- Produces: a nota datada no padrão do arquivo (`:16–85`); o veredito de "pronto".

- [ ] **Step 1: Sweep sem custo — todos os critérios de graça**

Run:
```bash
echo "== self-test ==" && tools/speckit-clarify-loop --self-test 2>&1 | tail -1
echo "== run completo (3 rodadas) ==" && bash tools/speckit-clarify-loop-harness.sh --max-rounds 3 >/dev/null 2>&1 || true
wc -l < /tmp/speckit-clarify-loop/latest/rounds.txt
test -f "$(readlink /tmp/speckit-clarify-loop/latest)/summary.txt" && echo "summary.txt presente"
echo "== dry-run pelo harness ==" && bash tools/speckit-clarify-loop-harness.sh --dry-run >/dev/null 2>&1 || true
cat /tmp/speckit-clarify-loop/latest/rounds.txt
echo "== corte externo ==" && SKCL_CUT=2 bash tools/speckit-clarify-loop-harness.sh
```
Expected:
- `self-test limpo (147 casos)`
- `run completo`: `3` linhas + `summary.txt presente`
- `dry-run pelo harness`: uma linha `round=01 turns=1 sent=1 yes=0 dec=0 cost=0.1 delta=+0 out=dry-pergunta` (spec intocado no ensaio → `delta=+0`; `jq` normaliza o `0.10` do stub para `0.1`)
- `corte externo`: `corte OK: rounds.txt=2 linhas (esperado 2), summary.txt ausente`

- [ ] **Step 2: `--dry-run` REAL contra um repo Spec Kit (pago, ~US$ 0,60)**

Este é o critério que confirma que a persistência escreve **só** em `$LOG_DIR` e nunca no repo-alvo. Exige um repo Spec Kit num branch de feature, working tree limpo, e uma chamada real do `claude` (paga). Use a versão do working tree (`tools/speckit-clarify-loop`), não a instalada. Substitua `<REPO>` e `<FEAT>` pelo seu repo/feature de teste (o histórico do arquivo usa `zion-test-build-prd` com `SPECIFY_FEATURE=006-code-interop`):

Run:
```bash
cd <REPO>
git status --porcelain            # tem que estar vazio ANTES
SPECIFY_FEATURE=<FEAT> /caminho/para/tools/speckit-clarify-loop --repo <REPO> --dry-run
git status --porcelain            # tem que continuar vazio DEPOIS
dir="$(readlink /tmp/speckit-clarify-loop/latest)"
cat "$dir/rounds.txt"; echo "---"; test -f "$dir/summary.txt" && echo "summary.txt presente"
```
Expected: `git status --porcelain` **vazio** antes e depois (o registro escreve só em `$LOG_DIR`; a guarda de vazamento fica intocada); o resumo mostra `delta +0` e o mesmo número de linhas de entrada e saída; `rounds.txt` tem uma linha `out=dry-pergunta`; `summary.txt` presente. **Anote o repo, o custo (`custo:` do resumo) e o `contrato: sentinela em N/M turnos`** — vão para a nota do Step 3.

- [ ] **Step 3: Escrever a nota datada no cabeçalho**

Em `tools/speckit-clarify-loop`, localizar o fim do último bloco datado (atual `:85–86`):
```bash
#   O contorno é real e a negação é a rede.
# Reinstalar após editar:  install -m 755 tools/speckit-clarify-loop ~/.local/bin/
```
e inserir a nota entre elas. As três primeiras sub-linhas são determinísticas (verificadas de graça pelo harness); preencha `<REPO>`/`<FEAT>`/`<N>`/`<CUSTO>` na sub-linha do `--dry-run real` com os valores anotados no Step 2:
```bash
#   O contorno é real e a negação é a rede.
# Registro persistente por rodada verificado em 2026-07-22 contra a skill
# speckit-clarify:
#   Harness sem custo — run completo: `--max-rounds 3` deixou rounds.txt com 3
#   linhas bem-formadas (round=NN turns=2 sent=2 yes=1 dec=1 cost=0.25 delta=+4
#   out=rodada-completa) e summary.txt casando o —— resumo —— do stdout byte-a-byte.
#   Harness sem custo — corte externo (a prova do E-2/R7): SKCL_CUT=2 travou a
#   rodada 3, matou o loop em voo e deixou rounds.txt com EXATAMENTE 2 linhas e
#   NENHUM summary.txt — a recuperação que o run real da R7 não teve, agora de graça.
#   --dry-run real em <REPO> (SPECIFY_FEATURE=<FEAT>) → sentinela em <N>/<N> turnos,
#   spec intocado (delta +0), US$ <CUSTO>; rounds.txt (1 linha, out=dry-pergunta) e
#   summary.txt nasceram em $LOG_DIR, e `git status --porcelain` no repo-alvo ficou
#   vazio: o registro escreve só em $LOG_DIR e a guarda de vazamento fica intocada.
# Reinstalar após editar:  install -m 755 tools/speckit-clarify-loop ~/.local/bin/
```

- [ ] **Step 4: Confirmar que o `--self-test` continua limpo (a nota é comentário)**

Run: `tools/speckit-clarify-loop --self-test 2>&1 | tail -1`
Expected: `speckit-clarify-loop: self-test limpo (147 casos)`

- [ ] **Step 5: Commit**

```bash
git add tools/speckit-clarify-loop
git commit -m "$(cat <<'EOF'
docs(tools): nota datada do registro persistente por rodada

Registro incremental (rounds.txt) e resumo em disco (summary.txt) verificados:
run completo e corte externo pelo harness sem custo, e --dry-run real com o
repo-alvo intocado (git status vazio).

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Self-Review

**1. Cobertura da spec:**
- R-1 (`round_record` pura + 4 asserts, 147 casos) → Task 1. ✓
- R-2 (escritor incremental, `rounds.txt`, append antes do `case`, degrade P-7) → Task 2. ✓
- R-3 (`print_summary` emissor único + `summary.txt` por captura, não `tee`, byte-a-byte) → Task 3. ✓
- R-4 (rodapé cita `rounds.txt`/`summary.txt`, alinhado) → Task 4. ✓
- Verificação sem custo (run completo + corte externo) → Tasks 2, 5, 6. ✓
- `--dry-run` real (delta +0, hash/`git status` intocados no repo-alvo) → Task 6. ✓
- Nota datada no padrão do arquivo → Task 6. ✓
- Guarda de vazamento intocada → constraint global + Task 5 Step 3 (regressão M-06) + Task 6 Step 2. ✓
- Nada em PRD/architecture/ADR (tools/ fora do canon) → constraint global; nenhuma task toca esses arquivos. ✓

**2. Placeholders:** os únicos `<…>` são na nota datada do `--dry-run real` (Task 6 Step 3), que registra resultados de um run pago que só existem após a execução — inerentemente dependente do run; as sub-linhas determinísticas do harness estão concretas. Sem "TODO"/"handle edge cases"/"similar to Task N".

**3. Consistência de tipos/nomes:** `round_record` (Task 1) é chamada com os 8 args na mesma ordem em Task 2. `print_summary` (Task 3) é usada em Task 4 (mesmo nome). `snap_lines`/`r_delta`/`summ` declarados como locais de `main_loop`. `SKCL_HANG`/`SKCL_COUNT`/`SKCL_CUT` consistentes entre o stub e a orquestração (Task 5). Os tokens de `out=` (`rodada-completa`/`loop-seco`/`aborto`/`dry-pergunta`) batem com `ROUND_OUTCOME` do script. Linhas esperadas do `rounds.txt`/resumo conferidas contra o run real do harness (143→147, `add=4`, `cost=0.25`).

---

Plan complete and saved to `docs/superpowers/plans/2026-07-22-speckit-clarify-loop-registro-persistente.md`. Two execution options:

**1. Subagent-Driven (recommended)** — I dispatch a fresh subagent per task, review between tasks, fast iteration.

**2. Inline Execution** — Execute tasks in this session using executing-plans, batch execution with checkpoints.

Which approach?
