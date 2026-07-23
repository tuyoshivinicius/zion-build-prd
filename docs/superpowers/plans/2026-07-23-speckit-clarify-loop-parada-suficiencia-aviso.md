# Aviso de suficiência (teto suave *warn-only*) no `speckit-clarify-loop` — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Narrar um aviso por-run — `ⓘ suficiência: N decisões · M rodadas · +D linhas — considere parar (teto suave)` — quando as decisões/rodadas/linhas cumulativas cruzam um limiar env-tuneável, **sem nunca** alterar `rc`, `stop_reason` ou o fluxo de parada.

**Architecture:** Uma função pura nova (`nudge_note`) espelha o `sentinel_note`: recebe os três contadores cumulativos e devolve a linha do aviso, ou vazio, se **algum** limiar (default 20/4/300, OR) foi cruzado. Um quarto *kind* de marcador (`info` → `ⓘ` / `[nota]`) dá ao aviso um glifo distinto, nem `ok` (some) nem `warn` (grita). Um escritor impuro fino em `main_loop`, no **fundo do laço** (alcançado só quando a rodada não deu `break`), dispara o aviso **uma vez** por run atrás de uma trava `nudged`. Toda a leitura vem de contadores que já existem; nada toca o contrato, os sensores, o resumo ou a lógica de parada.

**Tech Stack:** Bash (ferramenta pessoal instalada por cópia no PATH). Verificação via `--self-test` embutido (puro, sem custo) e via `tools/speckit-clarify-loop-harness.sh` (repo Spec Kit falso + stub determinístico de `claude`, sem custo). O harness **não muda**: ele já encaminha o ambiente herdado (`env "${common_env[@]}" "$LOOP"`, sem `-i`), então `SKCL_NUDGE_*` exportado alcança o loop.

## Global Constraints

Copiadas da spec (`docs/superpowers/specs/2026-07-23-speckit-clarify-loop-parada-suficiencia-aviso-design.md`). Os requisitos de cada tarefa incluem implicitamente esta seção.

- **`tools/` está FORA do canon.** `scripts/check-canon.sh` não referencia `tools/`. Esta mudança **não** cria nem supera ADR e **não** toca `docs/prd.md` nem `docs/architecture.md`. O dever de canonização do `CLAUDE.md` não se aplica.
- **P-7 (guia da spec): o aviso é conveniência, não contrato.** Ele **nunca** altera `rc`, `stop_reason` ou o fluxo de parada — é uma única linha de narração a mais, atrás de uma trava que dispara uma vez.
- **P-2:** o aviso lê os contadores de estado já computados (`total_yes`, `round`, `spec_lines`/`start_lines`); nunca re-parseia o stream do LLM.
- **P-3:** o gatilho (`nudge_note`) é função pura, exercitável pelo `--self-test` sem repo e sem custo.
- **P-6:** o aviso **reusa** os contadores que já existem — zero coleta nova.
- **OR, defaults, uma vez:** dispara quando `total_yes ≥ SKCL_NUDGE_YES` (default **20**) **OU** `round ≥ SKCL_NUDGE_ROUNDS` (default **4**) **OU** `delta_cumulativo ≥ SKCL_NUDGE_DELTA` (default **300**); depois fica quieto (trava `nudged`). Os três limiares são env-tuneáveis.
- **NÃO MEXER** (intocados): `SENTINEL_PROMPT` · `classify`/`read_sentinel` · `miss_action`/`SENT_MISS_MAX` e a rede sonda/aborto · `leaked_sentinel` · a máquina de estados de `run_round` · **a lógica de parada de `main_loop`** (`case "$ROUND_OUTCOME"`, `--dry-run`, estagnação, teto) · a tabela de códigos de saída (0/1/2) · a linha `sensores ·`, `sensor_line`, `narrate_sensors` e seus limiares (`SENSOR_MIN_*`) · `round_record`/`rounds.txt` · o `—— resumo ——`/`print_summary`.
- **FORA DE ESCOPO:** corte automático `rc=0` (o `--soft-stop-after N` que *para*) · Alternativa C (campo `CLARIFY_SATURATION` no contrato) · Alternativa D · parada calibrada (sensores da Fase 3, atrás do `R-23`/`R-24`) · **qualquer mudança no resumo**.
- **Commits:** Conventional Commits (o repo tem `check-commit.sh` + `commit-lint.yml` **bloqueantes**). Nada em `assets/`/`skills/` é tocado → sem drift no pre-commit.
- **Só um arquivo de produção muda:** `tools/speckit-clarify-loop`. O harness **não muda**.

---

## File Structure

- **`tools/speckit-clarify-loop`** (modify) — único arquivo de produção. Ganha: `nudge_note` (função pura, após `round_record`); o *kind* `info` em `mon_marker` e `emit_note`; a fiação no `main_loop` (dois locais + o disparo no fundo do laço); asserções novas no `self_test`; e uma nota datada no cabeçalho.
- **`tools/speckit-clarify-loop-harness.sh`** (não muda) — usado só para verificar o disparo/não-disparo de graça.

---

### Task 1: `nudge_note` — o gatilho do aviso, como função pura (R-1)

**Files:**
- Modify: `tools/speckit-clarify-loop` — inserir `nudge_note` logo após o `}` de `round_record` (após `:778`), antes do comentário `# --- Sensores: coleta e narração (impura)`; inserir 4 asserções em `self_test` após o último assert de `round_record` (após `:1826`).

**Interfaces:**
- Consumes: nada (função pura); lê os três limiares do ambiente com default: `SKCL_NUDGE_YES` (20), `SKCL_NUDGE_ROUNDS` (4), `SKCL_NUDGE_DELTA` (300).
- Produces: `nudge_note yes rounds delta` → escreve em stdout uma única linha **sem** newline final se **qualquer** limiar foi cruzado (`yes≥…` OR `rounds≥…` OR `delta≥…`), ou **nada** (string vazia) caso contrário. A linha é `suficiência: <yes> decisões · <rounds> rodadas · <±delta> linhas — a carga marginal cai; considere parar (teto suave)`. Consumido pelo disparo do R-3 (Task 3).

- [ ] **Step 1: Escrever os 4 testes que falham**

Em `tools/speckit-clarify-loop`, dentro de `self_test`, logo **após** o último assert de `round_record` (a linha `round_record 02 3 3 2 1 0.50 -12 rodada-completa`, atual `:1826`), inserir:

```bash

  # R-1: nudge_note é pura — RECEBE os três contadores cumulativos e devolve a
  # linha do aviso (ou vazio). Cabe no assert_out (P-3). O `unset` garante os
  # DEFAULTS (20/4/300) mesmo se o ambiente do teste tiver SKCL_NUDGE_* setado.
  # Cobre: cruza por yes, cruza por rounds, cruza por delta, e vazio abaixo dos três.
  unset SKCL_NUDGE_YES SKCL_NUDGE_ROUNDS SKCL_NUDGE_DELTA
  assert_out "aviso dispara ao cruzar as decisões" \
    'suficiência: 20 decisões · 1 rodadas · +0 linhas — a carga marginal cai; considere parar (teto suave)' \
    nudge_note 20 1 0
  assert_out "aviso dispara ao cruzar as rodadas" \
    'suficiência: 5 decisões · 4 rodadas · +50 linhas — a carga marginal cai; considere parar (teto suave)' \
    nudge_note 5 4 50
  assert_out "aviso dispara ao cruzar as linhas líquidas" \
    'suficiência: 5 decisões · 1 rodadas · +300 linhas — a carga marginal cai; considere parar (teto suave)' \
    nudge_note 5 1 300
  assert_out "abaixo dos três limiares o aviso é vazio" '' nudge_note 19 3 299
```

- [ ] **Step 2: Rodar o auto-teste e confirmar que falha**

Run: `tools/speckit-clarify-loop --self-test 2>&1 | tail -6`
Expected: linhas `FALHOU:` para os asserts do `nudge_note` (`nudge_note: command not found` no stderr, saída vazia) e a linha final:
```
speckit-clarify-loop: self-test COM FALHAS (151 casos)
```
(O contador sobe para 151 porque `assert_out` incrementa `ST_COUNT` mesmo em falha.)

- [ ] **Step 3: Escrever a implementação mínima**

Em `tools/speckit-clarify-loop`, localizar o fim de `round_record` seguido do comentário da seção de sensores (atual `:776–780`):
```bash
    "${1:-00}" "${2:-0}" "${3:-0}" "${4:-0}" "${5:-0}" "${6:-0}" "${7:-0}" "${8:-?}"
  return 0
}

# --- Sensores: coleta e narração (impura) -----------------------------------
```
e inserir `nudge_note` entre o `}` de `round_record` e o comentário `# --- Sensores…`, ficando:
```bash
    "${1:-00}" "${2:-0}" "${3:-0}" "${4:-0}" "${5:-0}" "${6:-0}" "${7:-0}" "${8:-?}"
  return 0
}

# Aviso de suficiência (teto suave, só-aviso) — espelha o sentinel_note: entram
# os três contadores CUMULATIVOS já computados, sai a linha do aviso se QUALQUER
# limiar foi cruzado (semântica OR), ou vazio. Política, não limiar calibrado: não
# afirma "o valor caiu abaixo de X", só "o Autor decidiu que N basta" — por isso
# fica FORA da trava R-24 dos sensores. Os três limiares são env-tuneáveis (N é
# incerto com dois pontos de dados); lidos de um lugar só, com default. Pura, sem
# I/O, testável por assert_out (P-3). Sem newline final: quem grava (R-3) narra.
nudge_note() {  # yes rounds delta → linha de aviso, ou vazio
  local yes="${1:-0}" rounds="${2:-0}" delta="${3:-0}"
  local ty="${SKCL_NUDGE_YES:-20}" tr="${SKCL_NUDGE_ROUNDS:-4}" td="${SKCL_NUDGE_DELTA:-300}"
  if [ "$yes" -ge "$ty" ] || [ "$rounds" -ge "$tr" ] || [ "$delta" -ge "$td" ]; then
    printf 'suficiência: %s decisões · %s rodadas · %+d linhas — a carga marginal cai; considere parar (teto suave)' \
      "$yes" "$rounds" "$delta"
  fi
  return 0
}

# --- Sensores: coleta e narração (impura) -----------------------------------
```

- [ ] **Step 4: Rodar o auto-teste e confirmar que passa**

Run: `tools/speckit-clarify-loop --self-test 2>&1 | tail -1`
Expected: `speckit-clarify-loop: self-test limpo (151 casos)`

- [ ] **Step 5: Commit**

```bash
git add tools/speckit-clarify-loop
git commit -m "$(cat <<'EOF'
feat(tools): nudge_note e 4 casos de auto-teste (R-1)

O gatilho do aviso de suficiência como função pura, espelhando o sentinel_note:
dispara (OR) ao cruzar decisões/rodadas/linhas, com limiares env-tuneáveis
(defaults 20/4/300). Auto-teste sobe de 147 para 151 casos.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 2: o marcador `info` — glifo distinto para o aviso (R-2)

**Files:**
- Modify: `tools/speckit-clarify-loop` — acrescentar dois casos `info` em `mon_marker` (atual `:399–411`); acrescentar `info) color=bold` em `emit_note` (atual `:619–623`); inserir 3 asserções em `self_test` após o assert `emit_note ecoa a linha do motor` (após `:1842`).

**Interfaces:**
- Consumes: nada novo.
- Produces: `mon_marker tty info` → `ⓘ`; `mon_marker plain info` → `[nota]  ` (8 colunas); `emit_note info "texto"` → narra `texto` sob o marcador `info`, pintado `bold` (o mesmo realce discreto do `you`; `bold` só afeta o perfil `tty`, então a narração em arquivo/`plain` sai literal). Consumido pelo disparo do R-3 (Task 3).

- [ ] **Step 1: Escrever os 3 testes que falham**

Em `tools/speckit-clarify-loop`, dentro de `self_test`, logo **após** o assert `emit_note ecoa a linha do motor` (as três linhas terminando em `emit_note you 'yes                    (pergunta 1/5)'`, atual `:1840–1842`), inserir:

```bash
  # R-2: o kind `info` do aviso. mon_marker é pura e exata nos dois perfis; o
  # assert_emit prova que emit_note ROTEIA o kind info (mesmo espaçamento do
  # `you`, porque [nota] e [você] têm 6 chars → marcador de 8 colunas idêntico).
  # bold só pinta no tty; aqui o perfil é plain, então o texto sai literal.
  assert_out "marcador info no tty é o glifo ⓘ" 'ⓘ' mon_marker tty info
  assert_out "marcador info no plain tem 8 colunas" '[nota]  ' mon_marker plain info
  assert_emit "emit_note roteia o kind info" \
    '  00:00  [nota]    considere parar (teste)' \
    emit_note info 'considere parar (teste)'
```

- [ ] **Step 2: Rodar o auto-teste e confirmar que falha**

Run: `tools/speckit-clarify-loop --self-test 2>&1 | tail -8`
Expected: 3 linhas `FALHOU:` — `mon_marker … info` cai no `*) printf '?'` (esperado `ⓘ`/`[nota]  `, veio `?`), e `emit_note info` narra sob `?` em vez de `[nota]`. Linha final:
```
speckit-clarify-loop: self-test COM FALHAS (154 casos)
```

- [ ] **Step 3: Acrescentar o kind `info` em `mon_marker`**

Em `tools/speckit-clarify-loop`, localizar os casos do `mon_marker` (atual `:404–410`) e inserir os dois casos `info` — o `tty:info` após `tty:warn` e o `plain:info` após `plain:warn`:
```bash
    tty:ok)         printf '✓' ;;
    tty:warn)       printf '⚠' ;;
    tty:info)       printf 'ⓘ' ;;
    plain:tool)     printf '[tool]  ' ;;
    plain:text)     printf '[claude]' ;;
    plain:you)      printf '[você]  ' ;;
    plain:thinking) printf '[...]   ' ;;
    plain:ok)       printf '[ok]    ' ;;
    plain:warn)     printf '[!]     ' ;;
    plain:info)     printf '[nota]  ' ;;
    *)              printf '?' ;;
```

- [ ] **Step 4: Acrescentar a cor de `info` em `emit_note`**

Em `tools/speckit-clarify-loop`, localizar o `case` de cores de `emit_note` (atual `:619–623`) e inserir `info) color=bold`:
```bash
  case "$kind" in
    you)  color=bold ;;
    warn) color=red ;;
    info) color=bold ;;
    *)    color=none ;;
  esac
```

- [ ] **Step 5: Rodar o auto-teste e confirmar que passa**

Run: `tools/speckit-clarify-loop --self-test 2>&1 | tail -1`
Expected: `speckit-clarify-loop: self-test limpo (154 casos)`

- [ ] **Step 6: Commit**

```bash
git add tools/speckit-clarify-loop
git commit -m "$(cat <<'EOF'
feat(tools): kind info (ⓘ/[nota]) para o aviso de suficiência (R-2)

Um quarto marcador, nem ok (some) nem warn (grita em vermelho): ⓘ no tty,
[nota] de 8 colunas no plain, pintado bold. Auto-teste sobe para 154 casos.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 3: o disparo no `main_loop` — uma vez, no fundo do laço (R-3)

**Files:**
- Modify: `tools/speckit-clarify-loop` — estender os locais de `main_loop` (atual `:1012` e `:1015`) com `nudged=0` e `nudge_msg`; inserir o disparo entre o `fi` da estagnação (atual `:1118`) e o `done` do `while` (atual `:1119`).

**Interfaces:**
- Consumes: `nudge_note` (Task 1); `emit_note info` (Task 2); os locais/globais de `main_loop` `total_yes`, `round`, `start_lines`; a função `spec_lines` (lê `$SPEC`).
- Produces: nenhuma interface nova. Efeito: uma linha `ⓘ suficiência: …` na narração da rodada (stdout + `round-NN.log`), **uma vez** por run, quando o laço vai continuar e um limiar foi cruzado. **Não** altera `rc`, `stop_reason` nem qualquer parada.

- [ ] **Step 1: Declarar os dois locais (a trava e a mensagem)**

Em `main_loop`, a linha (atual `:1012`):
```bash
  local round=0 same=0 prev_hash cur_hash spec_mudou
```
vira (acrescenta `nudged=0`):
```bash
  local round=0 same=0 prev_hash cur_hash spec_mudou nudged=0
```
E a linha (atual `:1015`):
```bash
  local start_lines end_lines delta tag rule_pad snap snap_lines r_delta
```
vira (acrescenta `nudge_msg`):
```bash
  local start_lines end_lines delta tag rule_pad snap snap_lines r_delta nudge_msg
```

- [ ] **Step 2: Inserir o disparo no fundo do laço**

Em `main_loop`, localizar o fim do ramo de estagnação e o `done` do `while` (atual `:1116–1119`):
```bash
    else
      same=0
    fi
  done
```
e inserir o bloco do aviso entre o `fi` e o `done`, ficando:
```bash
    else
      same=0
    fi

    # Aviso de suficiência (teto suave, só-aviso): dispara UMA vez, no fundo do
    # laço — o ponto alcançado só quando a rodada NÃO deu break (não convergiu,
    # não abortou, não é --dry-run; a essas, "considere parar" seria ruído). Lê
    # os contadores CUMULATIVOS já computados (P-2/P-6) — o delta é vs start_lines,
    # não o r_delta por-rodada do R-2 — e NUNCA toca rc/stop_reason/parada (P-7).
    # A trava `nudged` impede repetir a cada rodada; limiares em nudge_note.
    if [ "$nudged" -eq 0 ]; then
      nudge_msg="$(nudge_note "$total_yes" "$round" "$(( $(spec_lines) - start_lines ))")"
      [ -z "$nudge_msg" ] || { emit_note info "$nudge_msg"; nudged=1; }
    fi
  done
```

- [ ] **Step 3: Confirmar que o `--self-test` continua limpo (não regrediu)**

Run: `tools/speckit-clarify-loop --self-test 2>&1 | tail -1`
Expected: `speckit-clarify-loop: self-test limpo (154 casos)`

- [ ] **Step 4: Harness sem custo — dispara EXATAMENTE uma vez**

Limiar de rodadas baixo (2), os outros dois altos, para forçar o disparo pela via de rodadas na rodada 2 — e provar que a trava impede um segundo aviso na rodada 3. O `grep` casa o texto `suficiência:` (independe do perfil tty/plain).

Run:
```bash
SKCL_NUDGE_ROUNDS=2 SKCL_NUDGE_YES=999 SKCL_NUDGE_DELTA=9999 \
  bash tools/speckit-clarify-loop-harness.sh --max-rounds 3 2>&1 | grep -c 'suficiência:'
```
Expected: `1`

- [ ] **Step 5: Harness sem custo — nunca dispara**

Os três limiares acima dos totais do run (yes=3, rounds=3, delta=12 ao fim de 3 rodadas do stub) → zero avisos.

Run:
```bash
SKCL_NUDGE_ROUNDS=999 SKCL_NUDGE_YES=999 SKCL_NUDGE_DELTA=9999 \
  bash tools/speckit-clarify-loop-harness.sh --max-rounds 3 2>&1 | grep -c 'suficiência:'
```
Expected: `0`

- [ ] **Step 6: Harness sem custo — a PARADA fica intocada**

O `stop_reason` (`parada:` do resumo) tem que ser idêntico com o aviso ligado e desligado — a prova de que o aviso não mexe na lógica de parada (P-7). Os dois runs têm `$LOG_DIR` diferente (timestamp), então compara-se só a linha `parada:`, não o resumo inteiro.

Run:
```bash
SKCL_NUDGE_ROUNDS=2   SKCL_NUDGE_YES=999 SKCL_NUDGE_DELTA=9999 \
  bash tools/speckit-clarify-loop-harness.sh --max-rounds 3 > /tmp/skcl-on.txt  2>/dev/null || true
SKCL_NUDGE_ROUNDS=999 SKCL_NUDGE_YES=999 SKCL_NUDGE_DELTA=9999 \
  bash tools/speckit-clarify-loop-harness.sh --max-rounds 3 > /tmp/skcl-off.txt 2>/dev/null || true
diff <(grep '^parada:' /tmp/skcl-on.txt) <(grep '^parada:' /tmp/skcl-off.txt) \
  && [ "$(grep -c 'suficiência:' /tmp/skcl-on.txt)" = 1 ] \
  && [ "$(grep -c 'suficiência:' /tmp/skcl-off.txt)" = 0 ] \
  && echo "OK: parada idêntica; aviso só no run de limiar baixo"
```
Expected: sem diff na linha `parada:`, seguido de `OK: parada idêntica; aviso só no run de limiar baixo`.

- [ ] **Step 7: Commit**

```bash
git add tools/speckit-clarify-loop
git commit -m "$(cat <<'EOF'
feat(tools): dispara o aviso de suficiência no fundo do laço (R-3)

Narra o aviso UMA vez (trava nudged), no ponto alcançado só quando a rodada
não deu break, lendo os contadores cumulativos. Nunca toca rc/stop_reason/
parada (P-7). Harness sem custo prova dispara-uma-vez, nunca-dispara e
parada-intocada.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 4: `--dry-run` real, nota datada e o sweep final

**Files:**
- Modify: `tools/speckit-clarify-loop` — inserir uma nota datada no cabeçalho, antes de `# Reinstalar após editar:` (atual `:101`).

**Interfaces:**
- Consumes: tudo das Tasks 1–3.
- Produces: a nota datada no padrão do arquivo; o veredito de "pronto".

- [ ] **Step 1: Sweep sem custo — todos os critérios de graça**

Run:
```bash
echo "== self-test ==" && tools/speckit-clarify-loop --self-test 2>&1 | tail -1
echo "== dispara uma vez ==" && SKCL_NUDGE_ROUNDS=2 SKCL_NUDGE_YES=999 SKCL_NUDGE_DELTA=9999 \
  bash tools/speckit-clarify-loop-harness.sh --max-rounds 3 2>&1 | grep -c 'suficiência:'
echo "== nunca dispara ==" && SKCL_NUDGE_ROUNDS=999 SKCL_NUDGE_YES=999 SKCL_NUDGE_DELTA=9999 \
  bash tools/speckit-clarify-loop-harness.sh --max-rounds 3 2>&1 | grep -c 'suficiência:'
```
Expected:
- `self-test limpo (154 casos)`
- `dispara uma vez`: `1`
- `nunca dispara`: `0`

- [ ] **Step 2: `--dry-run` REAL contra um repo Spec Kit (pago, ~US$ 0,10–0,60)**

Confirma que o aviso **não** dispara no ensaio (uma rodada só, `break` antes do fundo do laço) e que nada no comportamento observável mudou. Exige um repo Spec Kit num branch de feature, working tree limpo, e uma chamada real do `claude` (paga). Use a versão do working tree, não a instalada. Substitua `<REPO>`/`<FEAT>` (o histórico do arquivo usa `zion-test-build-prd` com `SPECIFY_FEATURE=006-code-interop`):

Run:
```bash
cd <REPO>
git status --porcelain            # tem que estar vazio ANTES
SPECIFY_FEATURE=<FEAT> /caminho/para/tools/speckit-clarify-loop --repo <REPO> --dry-run 2>&1 | tee /tmp/skcl-dry.txt
git status --porcelain            # tem que continuar vazio DEPOIS
grep -c 'suficiência:' /tmp/skcl-dry.txt   # tem que ser 0
```
Expected: `git status --porcelain` **vazio** antes e depois; `grep -c 'suficiência:'` = **0** (o `--dry-run` roda uma rodada e dá `break` antes do disparo). **Anote o repo, o custo (`custo:` do resumo) e o `contrato: sentinela em N/M turnos`** — vão para a nota do Step 3.

- [ ] **Step 3: Escrever a nota datada no cabeçalho**

Em `tools/speckit-clarify-loop`, localizar (atual `:100–101`):
```bash
#   summary.txt casando o —— resumo —— do stdout byte-a-byte.
# Reinstalar após editar:  install -m 755 tools/speckit-clarify-loop ~/.local/bin/
```
Localize a **última** linha do último bloco datado (a que precede `# Reinstalar após editar:`) e insira a nota entre ela e o `# Reinstalar…`. As duas primeiras sub-linhas são determinísticas (verificadas de graça pelo harness); preencha `<REPO>`/`<FEAT>`/`<N>`/`<CUSTO>` na sub-linha do `--dry-run real` com os valores anotados no Step 2:
```bash
#   summary.txt casando o —— resumo —— do stdout byte-a-byte.
# Aviso de suficiência (teto suave só-aviso) verificado em 2026-07-23 contra a
# skill speckit-clarify (auto-teste 147 → 154 casos):
#   Harness sem custo — dispara uma vez: SKCL_NUDGE_ROUNDS=2 (demais altos) em
#   --max-rounds 3 narrou `ⓘ suficiência: …` EXATAMENTE uma vez (a trava nudged
#   segurou a rodada 3); com os três limiares altos, zero avisos.
#   Harness sem custo — parada intocada: a linha `parada:` do resumo é idêntica
#   com o aviso ligado e desligado — só a linha ⓘ da rodada difere (P-7).
#   --dry-run real em <REPO> (SPECIFY_FEATURE=<FEAT>) → sentinela em <N>/<N>
#   turnos, US$ <CUSTO>, zero avisos (o ensaio dá break antes do fundo do laço) e
#   `git status --porcelain` no repo-alvo vazio: o aviso só narra, nunca escreve.
# Reinstalar após editar:  install -m 755 tools/speckit-clarify-loop ~/.local/bin/
```

- [ ] **Step 4: Confirmar que o `--self-test` continua limpo (a nota é comentário)**

Run: `tools/speckit-clarify-loop --self-test 2>&1 | tail -1`
Expected: `speckit-clarify-loop: self-test limpo (154 casos)`

- [ ] **Step 5: Commit**

```bash
git add tools/speckit-clarify-loop
git commit -m "$(cat <<'EOF'
docs(tools): nota datada do aviso de suficiência (teto suave)

Aviso dispara-uma-vez e nunca-dispara pelo harness sem custo, parada intocada
(P-7), e --dry-run real sem aviso com o repo-alvo intocado (git status vazio).

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Self-Review

**1. Cobertura da spec:**
- R-1 (`nudge_note` pura, OR, defaults 20/4/300, 4 asserts, 151 casos) → Task 1. ✓
- R-2 (kind `info`: `ⓘ`/`[nota]`, `bold`; asserts, 154 casos) → Task 2. ✓
- R-3 (disparo uma vez no fundo do laço, contadores cumulativos, P-7) → Task 3. ✓
- Decisão de desenho "sem tocar o resumo" → constraint global (NÃO MEXER: `—— resumo ——`/`print_summary`) + nenhuma task toca o resumo. ✓
- Verificação sem custo (dispara-uma-vez, nunca-dispara, parada-intocada) → Task 3 Steps 4–6, Task 4 Step 1. ✓
- `--dry-run` real (sem aviso, `git status` vazio) → Task 4 Step 2. ✓
- Nota datada no padrão do arquivo → Task 4 Step 3. ✓
- Distinção dos sensores (R-24) e nada em PRD/architecture/ADR → constraint global; nenhuma task toca sensores nem esses arquivos. ✓

**2. Placeholders:** os únicos `<…>` são na nota datada do `--dry-run real` (Task 4 Step 3), resultados de um run pago que só existem após a execução — inerentemente dependentes do run; as sub-linhas do harness estão concretas. Sem "TODO"/"handle edge cases"/"similar to Task N".

**3. Consistência de tipos/nomes:** `nudge_note yes rounds delta` (Task 1) é chamada com os 3 args na mesma ordem em Task 3 (`nudge_note "$total_yes" "$round" "$(( … ))"`). O kind `info` (Task 2) é o mesmo passado a `emit_note info` (Task 3). Locais `nudged=0`/`nudge_msg` declarados em `main_loop` (Task 3 Step 1) e usados no disparo (Step 2). As strings esperadas do `assert_out`/`assert_emit` batem byte-a-byte o formato de `nudge_note` e do marcador `[nota]` (mesmas 8 colunas de `[você]`, template provado pelo assert do `you`). Contador 147 → 151 (Task 1) → 154 (Task 2), consistente em todas as linhas `Expected`. Env `SKCL_NUDGE_YES`/`ROUNDS`/`DELTA` idênticos entre `nudge_note`, os testes e os comandos do harness.
