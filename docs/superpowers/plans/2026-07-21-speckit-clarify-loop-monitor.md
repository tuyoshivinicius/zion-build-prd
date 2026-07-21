# Monitor de sessão do `speckit-clarify-loop` — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fazer o `speckit-clarify-loop` narrar em tempo real, no terminal e num `.log` legível, tudo que acontece dentro de cada rodada — texto do assistente integral, uma linha por tool call, `thinking` como marcador e o `yes` ecoado.

**Architecture:** Três funções puras de texto (`event_kind`, `dedup_kind`, `render_line`) mais uma cola com estado (`emit_event` / `emit_note`). O laço de leitura do stream em `run_round` passa a chamar `emit_event` antes do despacho de controle já existente. Nada da classificação, do `send_user 'yes'`, dos abortos ou do teto de 5 `yes` é alterado — o monitor é estritamente aditivo.

**Tech Stack:** Bash 5.1 (`set -u`, sem `set -e`), `jq`, `fold`, `sed`, `tput`. Testes são o `--self-test` embutido no próprio arquivo.

**Spec:** [`docs/superpowers/specs/2026-07-21-speckit-clarify-loop-monitor-design.md`](../specs/2026-07-21-speckit-clarify-loop-monitor-design.md)

## Global Constraints

- **Arquivo único:** todo o trabalho acontece em `tools/speckit-clarify-loop`. Nenhum arquivo novo.
- **Não é artefato canônico.** Não tocar `docs/prd.md`, `docs/architecture.md`, `docs/adr/`, `assets/`, `skills/` nem `scripts/`. O `check-canon.sh` do pre-commit não deve ter nada a reconciliar.
- **`set -u` ligado, `set -e` desligado** (linha 26 do script). Nenhuma função nova pode derrubar o processo por status de saída; sempre terminar com `return 0` explícito onde o último comando puder falhar.
- **Invariante aditiva:** nenhum caminho de código do monitor pode encerrar a rodada. Linha malformada, tipo desconhecido ou `jq` que não casa → saída vazia e continuação.
- **Idioma:** comentários e saída em português do Brasil, como o resto do arquivo.
- **Indentação de continuação: 9 espaços**, sempre, nos dois perfis. Largura de dobra = `WIDTH - 9`.
- **O `round-NN.log` recebe sempre o perfil `plain` com largura 80**, sem nenhuma sequência ANSI.
- **Reinstalar após editar:** `install -m 755 tools/speckit-clarify-loop ~/.local/bin/`
- Rodar o `--self-test` sem argumentos de repo: ele sai antes do `preflight` (linha 505), então funciona de qualquer diretório.

## File Structure

| Arquivo | Responsabilidade | Mudança |
|---|---|---|
| `tools/speckit-clarify-loop` | A ferramenta inteira | Modificado — novo bloco "Monitor" entre a classificação (linha ~105) e o Preflight; wiring em `run_round`/`main_loop`; flag `--quiet`; casos novos no `--self-test` |

Ordem dos blocos no arquivo depois do trabalho:

1. cabeçalho / `die` / `usage` / `need_deps`
2. Classificação do turno (`classify`) — **intocado**
3. **Monitor: perfis e primitivas de formatação** ← novo (Task 2)
4. **Monitor: leitura de eventos** (`event_kind`, `dedup_kind`) ← novo (Task 1)
5. **Monitor: renderização** (`render_line`) ← novo (Task 3)
6. **Monitor: cola com estado** (`emit_event`, `emit_note`, `emit_rule`) ← novo (Task 4)
7. Preflight → Motor de rodada → Driver → Auto-teste → parsing de flags

Como o bash resolve funções em tempo de chamada, a ordem física só precisa colocar todas as definições **antes** de `need_deps`/`preflight`/`main_loop` no fim do arquivo. Coloque cada bloco novo logo após o bloco `classify`, na ordem 3→4→5→6 acima.

---

## Task 1: `event_kind` e `dedup_kind` — a leitura do evento

Traduz uma linha JSONL do stream num rótulo, e decide a supressão de `thinking` consecutivo. Duas funções puras, sem I/O.

**Files:**
- Modify: `tools/speckit-clarify-loop` (novo bloco após a linha 105, fim de `classify`; casos novos em `self_test`, linha ~479)

**Interfaces:**
- Consumes: nada.
- Produces:
  - `event_kind <linha-jsonl>` → escreve em stdout exatamente um de: `nothing` | `thinking` | `text` | `tool` | `ratelimit` | `result`
  - `dedup_kind <kind-anterior> <kind>` → escreve o kind efetivo, ou `nothing` quando `thinking` segue `thinking`

- [ ] **Step 1: Escrever as fixtures e os testes que falham**

Adicione as fixtures logo depois de `FIX_PROSE_RECOMMEND` (linha ~466), antes de `ST_FAIL=0`:

```bash
# --- Fixtures do monitor ---------------------------------------------------
# Capturadas de /tmp/speckit-clarify-loop/round-01.jsonl numa rodada real.
# Nesse stream toda linha `assistant` trazia exatamente 1 bloco de conteúdo,
# mas a precedência text > tool_use > thinking existe para que uma linha em
# lote nunca faça a prosa desaparecer.
FX_TOOL_BASH='{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Bash","input":{"command":"check-prerequisites.sh --json --paths-only","description":"Run prerequisites check"}}]}}'
FX_TOOL_READ='{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Read","input":{"file_path":"/home/tuyoshi/projects/personal/zion-mermaid-editor-app/specs/001-cano-modelo-codigo/spec.md"}}]}}'
FX_TOOL_OTHER='{"type":"assistant","message":{"content":[{"type":"tool_use","name":"WebSearch","input":{"query":"spec kit clarify"}}]}}'
FX_THINK='{"type":"assistant","message":{"content":[{"type":"thinking","thinking":"Vou mapear a estrutura do spec antes de procurar lacunas."}]}}'
FX_TEXT='{"type":"assistant","message":{"content":[{"type":"text","text":"**Recomendado: Opção B**\n\n| Opção | Descrição |\n|---|---|\n| A | Manter o silêncio |"}]}}'
FX_MIXED='{"type":"assistant","message":{"content":[{"type":"thinking","thinking":"z"},{"type":"text","text":"prosa"}]}}'
FX_SYS_INIT='{"type":"system","subtype":"init","session_id":"x"}'
FX_SYS_TOK='{"type":"system","subtype":"thinking_tokens","tokens":128}'
FX_RL_OK='{"type":"rate_limit_event","rate_limit_info":{"status":"allowed","rateLimitType":"five_hour"}}'
FX_RL_BAD='{"type":"rate_limit_event","rate_limit_info":{"status":"rejected","rateLimitType":"five_hour"}}'
FX_RESULT='{"type":"result","is_error":false,"result":"prosa que NAO pode reaparecer","total_cost_usd":0.41}'
FX_BAD='{not json'
FX_USER_TR='{"type":"user","message":{"content":[{"type":"tool_result","content":"1081 linhas"}]}}'
```

Adicione o assert helper logo depois de `assert_classify` (linha ~477):

```bash
assert_kind() {  # descrição  esperado  linha-jsonl
  local got; got="$(event_kind "$3")"
  if [ "$got" = "$2" ]; then
    printf 'ok: %s\n' "$1"
  else
    printf 'FALHOU: %s (esperado %s, veio %s)\n' "$1" "$2" "$got"
    ST_FAIL=1
  fi
}

assert_dedup() {  # descrição  esperado  prev  kind
  local got; got="$(dedup_kind "$3" "$4")"
  if [ "$got" = "$2" ]; then
    printf 'ok: %s\n' "$1"
  else
    printf 'FALHOU: %s (esperado %s, veio %s)\n' "$1" "$2" "$got"
    ST_FAIL=1
  fi
}
```

E as chamadas dentro de `self_test`, logo após a última `assert_classify` (linha ~491):

```bash
  assert_kind "tool_use Bash"                tool      "$FX_TOOL_BASH"
  assert_kind "tool_use Read"                tool      "$FX_TOOL_READ"
  assert_kind "tool_use desconhecida"        tool      "$FX_TOOL_OTHER"
  assert_kind "thinking"                     thinking  "$FX_THINK"
  assert_kind "texto do assistente"          text      "$FX_TEXT"
  assert_kind "linha em lote: texto vence"   text      "$FX_MIXED"
  assert_kind "system/init é ruído"          nothing   "$FX_SYS_INIT"
  assert_kind "system/thinking_tokens é ruído" nothing "$FX_SYS_TOK"
  assert_kind "tool_result do usuário é ruído" nothing "$FX_USER_TR"
  assert_kind "rate limit allowed é ruído"   nothing   "$FX_RL_OK"
  assert_kind "rate limit não-allowed"       ratelimit "$FX_RL_BAD"
  assert_kind "result"                       result    "$FX_RESULT"
  assert_kind "linha malformada não quebra"  nothing   "$FX_BAD"
  assert_kind "linha vazia não quebra"       nothing   ""

  assert_dedup "thinking após thinking suprime"  nothing  thinking thinking
  assert_dedup "thinking após tool passa"        thinking tool     thinking
  assert_dedup "texto após texto passa"          text     text     text
  assert_dedup "sem anterior passa"              tool     ""       tool
```

Atualize também a contagem final (linha ~494), de `12 casos` para `30 casos`:

```bash
    printf 'speckit-clarify-loop: self-test limpo (30 casos)\n'; exit 0
```

- [ ] **Step 2: Rodar o teste e verificar que falha**

Run: `bash tools/speckit-clarify-loop --self-test`
Expected: FAIL — as 12 `assert_classify` passam, e cada `assert_kind`/`assert_dedup` imprime `FALHOU: ... (esperado X, veio )` porque `event_kind` e `dedup_kind` não existem. A saída de erro do bash inclui `event_kind: comando não encontrado`. Exit code 1.

- [ ] **Step 3: Implementar as duas funções**

Insira este bloco logo após o fim de `classify` (depois da linha 105, antes de `# --- Preflight`):

```bash
# --- Monitor: leitura de eventos -------------------------------------------
# Traduz uma linha do stream JSONL num rótulo. Função pura: sem I/O além do
# stdout, sem estado global. Qualquer linha que o jq não digira cai em
# `nothing` — o monitor é aditivo e jamais derruba a rodada.
#
# Precedência dentro de uma linha `assistant`: text > tool_use > thinking.
# No stream observado toda linha trazia um único bloco, mas se a API um dia
# agrupar blocos, perder a prosa seria a única falha inaceitável.
event_kind() {
  local line="${1:-}" typ types st
  typ="$(printf '%s' "$line" | jq -r '.type // empty' 2>/dev/null)"
  case "$typ" in
    result)
      printf 'result\n'; return 0 ;;
    rate_limit_event)
      st="$(printf '%s' "$line" | jq -r '.rate_limit_info.status // "?"' 2>/dev/null)"
      if [ "$st" = "allowed" ]; then printf 'nothing\n'; else printf 'ratelimit\n'; fi
      return 0 ;;
    assistant)
      types="$(printf '%s' "$line" | jq -r '[.message.content[]?.type] | join(" ")' 2>/dev/null)"
      case " $types " in
        *' text '*)     printf 'text\n' ;;
        *' tool_use '*) printf 'tool\n' ;;
        *' thinking '*) printf 'thinking\n' ;;
        *)              printf 'nothing\n' ;;
      esac
      return 0 ;;
    *)
      printf 'nothing\n'; return 0 ;;
  esac
}

# Suprime `pensando…` repetido. Note que o kind anterior é o último kind
# EFETIVO — eventos que não rendem linha (system/*, tool_result) não o mexem,
# de modo que thinking · ruído · thinking conta como um só arroubo de reflexão.
dedup_kind() {  # kind-anterior  kind → kind efetivo
  if [ "${2:-}" = thinking ] && [ "${1:-}" = thinking ]; then
    printf 'nothing\n'
  else
    printf '%s\n' "${2:-nothing}"
  fi
}
```

- [ ] **Step 4: Rodar o teste e verificar que passa**

Run: `bash tools/speckit-clarify-loop --self-test`
Expected: PASS — 30 linhas `ok:` e `speckit-clarify-loop: self-test limpo (30 casos)`. Exit code 0.

Rode também `bash -n tools/speckit-clarify-loop` — sem saída.

- [ ] **Step 5: Commit**

```bash
git add tools/speckit-clarify-loop
git commit -m "feat(tools): leitura de eventos do stream para o monitor do loop"
```

---

## Task 2: primitivas de formatação e resumo de ferramenta

Os tijolos que `render_line` vai usar: marcadores por perfil, cabeçalho de linha, cor, truncagem, dobra de prosa e o resumo de um `tool_use`. Todos puros.

**Files:**
- Modify: `tools/speckit-clarify-loop` (novo bloco antes do bloco "Monitor: leitura de eventos" da Task 1; casos novos em `self_test`)

**Interfaces:**
- Consumes: nada.
- Produces:
  - `mon_marker <perfil> <kind>` → marcador; kinds de marcador: `tool` `text` `you` `thinking` `ok` `warn`. Perfis: `tty` | `plain`. No perfil `plain` o marcador já vem preenchido para 8 colunas.
  - `mon_prefix <perfil>` → largura em colunas que o prefixo consome (`12` para `tty`, `19` para `plain`)
  - `mon_head <clock> <marcador> <corpo>` → escreve `  CLOCK  MARCADOR  CORPO`
  - `mon_paint <perfil> <cor> <texto>` → texto com ANSI se `tty`, cru se `plain`. Cores: `dim` `bold` `red` `none`
  - `mon_trunc <texto> <largura>` → texto truncado com reticências
  - `mon_fold <largura>` → filtro de stdin para stdout: dobra e indenta em 9 colunas
  - `tool_summary <linha-jsonl>` → `NOME<TAB>RESUMO`, vazio se não houver `tool_use`

- [ ] **Step 1: Escrever os testes que falham**

Adicione os asserts depois de `assert_dedup` (do Task 1):

```bash
assert_out() {  # descrição  esperado  comando…
  local desc="$1" want="$2"; shift 2
  local got; got="$("$@")"
  if [ "$got" = "$want" ]; then
    printf 'ok: %s\n' "$desc"
  else
    printf 'FALHOU: %s\n  esperado: [%s]\n  veio:     [%s]\n' "$desc" "$want" "$got"
    ST_FAIL=1
  fi
}
```

E as chamadas em `self_test`, após o bloco de `assert_dedup`:

```bash
  assert_out "marcador plain preenche 8 colunas" '[tool]  ' mon_marker plain tool
  assert_out "marcador tty é um símbolo"         '⚙'        mon_marker tty   tool
  assert_out "prefixo tty ocupa 12 colunas"      '12'       mon_prefix tty
  assert_out "prefixo plain ocupa 19 colunas"    '19'       mon_prefix plain
  assert_out "cabeçalho monta a linha"           '  01:23  [ok]      pronto' \
    mon_head '01:23' '[ok]    ' 'pronto'
  assert_out "perfil plain não pinta"            'nu'       mon_paint plain red 'nu'
  assert_out "truncagem curta não mexe"          'abc'      mon_trunc 'abc' 10
  assert_out "truncagem longa corta com reticências" 'abcdefg…' mon_trunc 'abcdefghijklmno' 8
  assert_out "resumo de Bash usa o command" \
    "$(printf 'Bash\tcheck-prerequisites.sh --json --paths-only')" \
    tool_summary "$FX_TOOL_BASH"
  assert_out "resumo de Read usa só o basename" \
    "$(printf 'Read\tspec.md')" \
    tool_summary "$FX_TOOL_READ"
  assert_out "resumo de ferramenta desconhecida cai no genérico" \
    "$(printf 'WebSearch\tquery=spec kit clarify')" \
    tool_summary "$FX_TOOL_OTHER"
  assert_out "resumo de linha sem tool_use é vazio" '' tool_summary "$FX_THINK"

  assert_out "tabela markdown escapa da dobra" \
    '         | Opção | Descrição |' \
    mon_fold_str 40 '| Opção | Descrição |'
  assert_out "prosa longa dobra e indenta em 9" \
    "$(printf '         palavra palavra palavra\n         palavra palavra')" \
    mon_fold_str 40 'palavra palavra palavra palavra palavra'
  # Verificado: `fold -s -w 31` quebra essa frase em "palavra palavra palavra "
  # (COM espaço à direita) e "palavra palavra". O `sed` de mon_fold apara esse
  # espaço — se não aparasse, o log ficaria cheio de espaço invisível no fim da
  # linha e esta expectativa seria impossível de escrever à mão.
  assert_out "linha vazia continua vazia" '' mon_fold_str 40 ''
```

`mon_fold_str` é um adaptador de teste (filtro de stdin não se testa com `assert_out` diretamente). Adicione junto dos asserts:

```bash
mon_fold_str() { printf '%s\n' "$2" | mon_fold "$1"; }
```

Atualize a contagem final de `30 casos` para `45 casos`.

> Se alguma expectativa divergir **só na contagem de espaços**, ajuste a string esperada do teste — o contrato é o conteúdo e a ordem das colunas, não o número exato de espaços. Divergência de conteúdo é bug de implementação.

- [ ] **Step 2: Rodar o teste e verificar que falha**

Run: `bash tools/speckit-clarify-loop --self-test`
Expected: FAIL — os 30 casos anteriores passam; os 15 novos imprimem `FALHOU:` com `veio: []`, e o stderr traz `mon_marker: comando não encontrado`. Exit 1.

- [ ] **Step 3: Implementar as primitivas**

Insira este bloco logo após o fim de `classify` (ele deve ficar **antes** do bloco da Task 1 no arquivo):

```bash
# --- Monitor: primitivas de formatação -------------------------------------
# Dois perfis. `tty` usa símbolos e ANSI; `plain` usa rótulos ASCII e nada de
# escape — porque o round-NN.log tem que continuar legível seis meses depois,
# e arquivo com sequência ANSI dentro é arquivo que ninguém relê.
MON_IND='         '   # 9 colunas: a indentação de continuação, nos dois perfis

mon_marker() {  # perfil kind → marcador (no perfil plain, já com 8 colunas)
  case "${1:-}:${2:-}" in
    tty:tool)       printf '⚙' ;;
    tty:text)       printf '◆' ;;
    tty:you)        printf '▸' ;;
    tty:thinking)   printf '·' ;;
    tty:ok)         printf '✓' ;;
    tty:warn)       printf '⚠' ;;
    plain:tool)     printf '[tool]  ' ;;
    plain:text)     printf '[claude]' ;;
    plain:you)      printf '[você]  ' ;;
    plain:thinking) printf '[...]   ' ;;
    plain:ok)       printf '[ok]    ' ;;
    plain:warn)     printf '[!]     ' ;;
    *)              printf '?' ;;
  esac
}

# Colunas consumidas por "  CLOCK  MARCADOR  ": 2+5+2+largura(marcador)+2.
mon_prefix() { case "${1:-}" in tty) printf '12' ;; *) printf '19' ;; esac; }

mon_head() {  # clock marcador corpo
  printf '  %s  %s  %s\n' "${1:-}" "${2:-}" "${3:-}"
}

mon_paint() {  # perfil cor texto
  if [ "${1:-}" != tty ]; then printf '%s' "${3:-}"; return 0; fi
  local c
  case "${2:-}" in
    dim)  c=$'\033[2m' ;;
    bold) c=$'\033[1m' ;;
    red)  c=$'\033[31m' ;;
    *)    printf '%s' "${3:-}"; return 0 ;;
  esac
  printf '%s%s\033[0m' "$c" "${3:-}"
}

mon_trunc() {  # texto largura
  local t="${1:-}" w="${2:-80}"
  [ "$w" -ge 8 ] || w=8
  if [ "${#t}" -le "$w" ]; then printf '%s' "$t"; return 0; fi
  printf '%s…' "${t:0:$((w - 1))}"
}

# Dobra a prosa e indenta em 9 colunas. Tabelas markdown e cercas de código
# escapam da dobra de propósito: quebrar a tabela de opções destrói exatamente
# a informação que se quer ler. Se estourar a largura, estoura.
mon_fold() {  # largura total; stdin → stdout
  local w=$(( ${1:-80} - 9 ))
  [ "$w" -ge 20 ] || w=20
  local l
  while IFS= read -r l || [ -n "$l" ]; do
    case "$l" in
      '')        printf '\n' ;;
      '|'*|'```'*) printf '%s%s\n' "$MON_IND" "$l" ;;
      *)         printf '%s\n' "$l" | fold -s -w "$w" \
                   | sed -e "s/^/$MON_IND/" -e 's/[[:space:]]*$//' ;;
    esac
  done
  return 0
}

# Resumo de um tool_use: comando para Bash, basename para quem tem file_path,
# e um genérico de primeira chave para o resto (nenhuma ferramenta fica muda).
# Só o primeiro tool_use da linha é resumido — perder uma chamada de ferramenta
# é aceitável; perder prosa não é, e por isso a prosa tem precedência em
# event_kind.
tool_summary() {  # linha-jsonl → NOME<TAB>RESUMO
  printf '%s' "${1:-}" | jq -r '
    ([.message.content[]? | select(.type=="tool_use")] | first) as $t
    | if $t == null then empty else
        ($t.input // {}) as $i
        | [ ($t.name // "?"),
            ( if   $i.command   then ($i.command | gsub("\\s+"; " "))
              elif $i.file_path then ($i.file_path | split("/") | last)
              elif $i.pattern   then $i.pattern
              else (($i | keys | first) as $k
                    | if $k == null then "" else "\($k)=\($i[$k] | tostring)" end)
              end ) ]
        | @tsv
      end' 2>/dev/null
  return 0
}
```

- [ ] **Step 4: Rodar o teste e verificar que passa**

Run: `bash tools/speckit-clarify-loop --self-test`
Expected: PASS — `self-test limpo (45 casos)`, exit 0.

Run: `bash -n tools/speckit-clarify-loop` — sem saída.

- [ ] **Step 5: Commit**

```bash
git add tools/speckit-clarify-loop
git commit -m "feat(tools): primitivas de formatação do monitor (perfis, dobra, resumo de tool)"
```

---

## Task 3: `render_line` — a narração de um evento

A função que transforma `(perfil, largura, clock, kind, linha)` em linhas de narração. Pura: recebe o relógio pronto, não consulta tempo nem estado global mutável.

**Files:**
- Modify: `tools/speckit-clarify-loop` (novo bloco depois do bloco "leitura de eventos"; casos novos em `self_test`)

**Interfaces:**
- Consumes: `mon_marker`, `mon_prefix`, `mon_head`, `mon_paint`, `mon_trunc`, `mon_fold`, `tool_summary` (Task 2); os kinds de `event_kind` (Task 1).
- Produces: `render_line <perfil> <largura> <clock> <kind> <linha-jsonl>` → zero ou mais linhas em stdout.

- [ ] **Step 1: Escrever os testes que falham**

Adicione o helper junto dos outros asserts:

```bash
assert_render() {  # descrição  esperado  kind  linha-jsonl
  local got; got="$(render_line plain 80 '01:23' "$3" "$4")"
  if [ "$got" = "$2" ]; then
    printf 'ok: %s\n' "$1"
  else
    printf 'FALHOU: %s\n  esperado: [%s]\n  veio:     [%s]\n' "$1" "$2" "$got"
    ST_FAIL=1
  fi
}
```

E as chamadas em `self_test`, depois do bloco da Task 2:

```bash
  assert_render "tool_use Bash mostra o comando" \
    '  01:23  [tool]    Bash     check-prerequisites.sh --json --paths-only' \
    tool "$FX_TOOL_BASH"
  assert_render "tool_use Read mostra só o basename" \
    '  01:23  [tool]    Read     spec.md' \
    tool "$FX_TOOL_READ"
  assert_render "ferramenta desconhecida não quebra" \
    '  01:23  [tool]    WebSearch query=spec kit clarify' \
    tool "$FX_TOOL_OTHER"
  assert_render "thinking vira marcador sem conteúdo" \
    '  01:23  [...]     pensando…' \
    thinking "$FX_THINK"
  assert_render "texto imprime cabeçalho e preserva a tabela" \
    "$(printf '  01:23  [claude]  claude\n         **Recomendado: Opção B**\n\n         | Opção | Descrição |\n         |---|---|\n         | A | Manter o silêncio |')" \
    text "$FX_TEXT"
  assert_render "rate limit não-allowed avisa" \
    '  01:23  [!]       rate limit: rejected' \
    ratelimit "$FX_RL_BAD"
  assert_render "result NÃO reimprime a prosa" '' result "$FX_RESULT"
  assert_render "kind nothing não imprime nada"  '' nothing "$FX_SYS_INIT"
  assert_render "linha malformada não imprime nada" '' tool "$FX_BAD"
```

Atualize a contagem final de `45 casos` para `54 casos`.

> O caso `result → ''` é o que trava a propriedade central verificada empiricamente: o campo `.result` do evento final é byte a byte idêntico ao último bloco `assistant/text`, então quem imprime prosa é o `assistant` e mais ninguém. O rodapé da rodada vem de `emit_note` (Task 4), não daqui — ele depende do contador de `yes` e do delta do spec, que são estado do motor.
>
> O caso `linha malformada` é o que trava a invariante aditiva: o teste passa a falhar no dia em que o monitor puder derrubar a rodada.

- [ ] **Step 2: Rodar o teste e verificar que falha**

Run: `bash tools/speckit-clarify-loop --self-test`
Expected: FAIL — os 45 anteriores passam; os 9 novos falham com `render_line: comando não encontrado`. Exit 1.

- [ ] **Step 3: Implementar `render_line`**

Insira depois do bloco "Monitor: leitura de eventos":

```bash
# --- Monitor: renderização --------------------------------------------------
# (perfil, largura, clock, kind, linha) → narração. Pura: o relógio chega
# pronto, nada de estado mutável. É a única função que sabe como a saída se
# parece, e por isso a única que precisa mudar se a apresentação mudar.
render_line() {  # perfil largura clock kind linha
  local p="${1:-plain}" w="${2:-80}" clock="${3:-00:00}" kind="${4:-nothing}" line="${5:-}"
  local body prefix tsv name summary st

  prefix="$(mon_prefix "$p")"

  case "$kind" in
    thinking)
      mon_head "$clock" "$(mon_marker "$p" thinking)" "$(mon_paint "$p" dim 'pensando…')"
      ;;
    tool)
      tsv="$(tool_summary "$line")"
      [ -n "$tsv" ] || return 0
      name="${tsv%%$'\t'*}"
      summary="${tsv#*$'\t'}"
      [ "$summary" != "$tsv" ] || summary=""
      body="$(printf '%-8s %s' "$name" "$summary")"
      body="$(mon_trunc "$body" $(( w - prefix )))"
      mon_head "$clock" "$(mon_marker "$p" tool)" "$(mon_paint "$p" dim "$body")"
      ;;
    text)
      mon_head "$clock" "$(mon_marker "$p" text)" 'claude'
      printf '%s' "$line" \
        | jq -r '[.message.content[]? | select(.type=="text") | .text] | join("\n\n")' 2>/dev/null \
        | mon_fold "$w"
      ;;
    ratelimit)
      st="$(printf '%s' "$line" | jq -r '.rate_limit_info.status // "?"' 2>/dev/null)"
      mon_head "$clock" "$(mon_marker "$p" warn)" "$(mon_paint "$p" red "rate limit: $st")"
      ;;
    *)
      # nothing e result não rendem linha. O rodapé da rodada é emitido pelo
      # motor (emit_note), que é quem conhece o contador de yes e o delta do
      # spec; e a prosa do `.result` é a mesma do último bloco assistant, que
      # já foi impressa — reimprimi-la duplicaria a pergunta inteira.
      return 0
      ;;
  esac
  return 0
}
```

- [ ] **Step 4: Rodar o teste e verificar que passa**

Run: `bash tools/speckit-clarify-loop --self-test`
Expected: PASS — `self-test limpo (54 casos)`, exit 0.

Run: `bash -n tools/speckit-clarify-loop` — sem saída.

- [ ] **Step 5: Commit**

```bash
git add tools/speckit-clarify-loop
git commit -m "feat(tools): renderizador de eventos do monitor do loop"
```

---

## Task 4: cola com estado, perfil ativo e flag `--quiet`

Onde o monitor encontra o mundo: detecção de TTY, relógio, dois destinos de saída, supressão de `thinking` repetido e a flag.

**Files:**
- Modify: `tools/speckit-clarify-loop` (novo bloco após "renderização"; variáveis globais junto de `LOG_DIR` na linha ~37; `usage` linha 42; `need_deps` linha 56; `preflight` linha 136; parsing de flags linha ~499)

**Interfaces:**
- Consumes: `event_kind`, `dedup_kind` (Task 1); `mon_*` (Task 2); `render_line` (Task 3).
- Produces:
  - `mon_setup` → define `MON_PROFILE` (`tty`|`plain`) e `MON_WIDTH` (inteiro 40–100). Chamada uma vez no arranque.
  - `mon_clock` → `MM:SS` decorridos desde o último `mon_round_start`
  - `mon_round_start <caminho-do-log>` → zera `SECONDS`, zera `LAST_KIND`, define e trunca `ROUND_LOG`
  - `emit_event <linha-jsonl>` → narra um evento do stream nos destinos ativos
  - `emit_note <kind> <texto>` → narra uma linha originada no motor (kinds `you` `ok` `warn` `tool` `text`)
  - `emit_rule <texto>` → linha de estrutura (cabeçalho de rodada), nos dois destinos, sem relógio
  - Globais: `QUIET` (0|1), `MON_PROFILE`, `MON_WIDTH`, `ROUND_LOG`, `LAST_KIND`

- [ ] **Step 1: Escrever os testes que falham**

Adicione em `self_test`, depois do bloco da Task 3:

```bash
  # A cola tem estado, então o teste a exercita com destinos controlados:
  # sem log em arquivo (ROUND_LOG vazio) e com o perfil plain forçado.
  MON_PROFILE=plain; MON_WIDTH=80; QUIET=0; ROUND_LOG=""; LAST_KIND=""; SECONDS=0
  assert_out "emit_note ecoa a linha do motor" \
    '  00:00  [você]    yes                    (pergunta 1/5)' \
    emit_note you 'yes                    (pergunta 1/5)'
  assert_out "emit_rule não leva relógio" \
    '── rodada 01/10 ──' \
    emit_rule '── rodada 01/10 ──'

  LAST_KIND=""
  assert_out "emit_event narra o primeiro thinking" \
    '  00:00  [...]     pensando…' \
    emit_event "$FX_THINK"
  assert_out "emit_event suprime o thinking seguinte" '' emit_event "$FX_THINK"
  assert_out "system entre thinkings não imprime nada" '' emit_event "$FX_SYS_TOK"
  assert_out "thinking após ruído continua suprimido"  '' emit_event "$FX_THINK"
  assert_out "tool reabre a supressão" \
    '  00:00  [tool]    Bash     check-prerequisites.sh --json --paths-only' \
    emit_event "$FX_TOOL_BASH"
  assert_out "thinking após tool volta a narrar" \
    '  00:00  [...]     pensando…' \
    emit_event "$FX_THINK"

  QUIET=1
  assert_out "--quiet cala o stdout" '' emit_event "$FX_TOOL_BASH"
  QUIET=0
```

Total do bloco: 9 asserts. Atualize a contagem final de `54 casos` para `63 casos`.

`SECONDS=0` no início do bloco garante o relógio `00:00`. Se o `--self-test` ficar lento a ponto de virar a casa do segundo, o caso `00:00` fica intermitente — nesse caso, reatribua `SECONDS=0` imediatamente antes de cada `assert_out` do bloco.

- [ ] **Step 2: Rodar o teste e verificar que falha**

Run: `bash tools/speckit-clarify-loop --self-test`
Expected: FAIL — os 54 anteriores passam; os 9 novos falham com `emit_note: comando não encontrado` / `emit_event: comando não encontrado`. Exit 1.

- [ ] **Step 3: Implementar a cola, o perfil e a flag**

**3a.** Junto das globais, logo depois de `LOG_DIR=/tmp/speckit-clarify-loop` (linha 37):

```bash
QUIET=0
MON_PROFILE=plain
MON_WIDTH=80
ROUND_LOG=""
LAST_KIND=""
```

**3b.** O bloco da cola, depois de "Monitor: renderização":

```bash
# --- Monitor: cola com estado -----------------------------------------------
# O único lugar do monitor que fala com o mundo: relógio, destinos e a memória
# do último kind. As três funções acima permanecem puras justamente porque tudo
# que é impuro está aqui.

mon_setup() {  # decide perfil e largura, uma vez, no arranque
  if [ -t 1 ]; then
    MON_PROFILE=tty
    MON_WIDTH="$(tput cols 2>/dev/null || printf '80')"
    case "$MON_WIDTH" in ''|*[!0-9]*) MON_WIDTH=80 ;; esac
    [ "$MON_WIDTH" -le 100 ] || MON_WIDTH=100
    [ "$MON_WIDTH" -ge 40 ] || MON_WIDTH=40
  else
    MON_PROFILE=plain
    MON_WIDTH=80
  fi
  return 0
}

mon_clock() { printf '%02d:%02d' $(( SECONDS / 60 )) $(( SECONDS % 60 )); }

mon_round_start() {  # caminho do round-NN.log
  ROUND_LOG="${1:-}"
  LAST_KIND=""
  SECONDS=0
  [ -z "$ROUND_LOG" ] || : > "$ROUND_LOG"
  return 0
}

# O log em arquivo recebe SEMPRE perfil plain com largura 80 — daí a prosa ser
# renderizada duas vezes no TTY. É baratíssimo, e evita ter que arrancar ANSI
# com sed no caminho de escrita.
emit_event() {  # linha-jsonl
  local line="${1:-}" kind clock
  kind="$(event_kind "$line")"
  kind="$(dedup_kind "$LAST_KIND" "$kind")"
  [ "$kind" = nothing ] && return 0
  LAST_KIND="$kind"
  clock="$(mon_clock)"
  [ "$QUIET" -eq 1 ] || render_line "$MON_PROFILE" "$MON_WIDTH" "$clock" "$kind" "$line"
  [ -z "$ROUND_LOG" ] || render_line plain 80 "$clock" "$kind" "$line" >> "$ROUND_LOG"
  return 0
}

# Linhas que nascem no motor, não no stream: o eco do `yes`, o rodapé da
# rodada, os avisos de aborto.
emit_note() {  # kind texto
  local kind="${1:-text}" text="${2:-}" clock color
  case "$kind" in
    you)  color=bold ;;
    warn) color=red ;;
    *)    color=none ;;
  esac
  clock="$(mon_clock)"
  [ "$QUIET" -eq 1 ] || \
    mon_head "$clock" "$(mon_marker "$MON_PROFILE" "$kind")" "$(mon_paint "$MON_PROFILE" "$color" "$text")"
  [ -z "$ROUND_LOG" ] || \
    mon_head "$clock" "$(mon_marker plain "$kind")" "$text" >> "$ROUND_LOG"
  return 0
}

# Estrutura (cabeçalho de rodada): sem relógio, e sobrevive ao --quiet — é o
# mínimo que diz "ainda estou vivo" quando a narração está calada.
emit_rule() {  # texto
  printf '%s\n' "${1:-}"
  [ -z "$ROUND_LOG" ] || printf '%s\n' "${1:-}" >> "$ROUND_LOG"
  return 0
}
```

**3c.** A flag, no `case` de parsing (linha ~499, junto de `--dry-run`):

```bash
    --quiet)       QUIET=1; shift ;;
```

**3d.** O texto de uso (`usage`, linha ~43). Substitua as duas linhas:

```
uso: speckit-clarify-loop [--repo DIR] [--max-rounds N] [--allow-dirty] [--dry-run] [--quiet] [--self-test]
```

e acrescente, depois da linha do `--dry-run`:

```
  --quiet          cala a narração no stdout; o round-NN.log e o resumo continuam
```

**3e.** Dependências (`need_deps`, linha 56). Acrescente `fold` e `sed` à lista:

```bash
  for c in claude jq git mkfifo awk tail timeout fold sed; do
```

`tput` fica **fora** da lista: ele já tem fallback para 80 e é ausente em contêiner enxuto — exigi-lo negaria a ferramenta a quem só quer o perfil `plain`.

**3f.** Limpeza dos logs (`preflight`, linha 136). Estenda o `rm`:

```bash
  rm -f "$LOG_DIR"/round-*.jsonl "$LOG_DIR"/round-*.jsonl.err "$LOG_DIR"/round-*.log
```

**3g.** Chame `mon_setup` no arranque, entre `need_deps` e `preflight` (linha ~516):

```bash
need_deps
mon_setup

preflight
main_loop
```

- [ ] **Step 4: Rodar o teste e verificar que passa**

Run: `bash tools/speckit-clarify-loop --self-test`
Expected: PASS — `self-test limpo (63 casos)`, exit 0.

Run: `bash tools/speckit-clarify-loop --help 2>&1 | grep -c quiet`
Expected: `2` (a linha de uso e a linha de descrição).

Run: `bash -n tools/speckit-clarify-loop` — sem saída.

- [ ] **Step 5: Commit**

```bash
git add tools/speckit-clarify-loop
git commit -m "feat(tools): cola do monitor (perfil por TTY, dois destinos, --quiet)"
```

---

## Task 5: ligar o monitor ao motor da rodada

O wiring. Nenhuma linha da classificação, do `send_user 'yes'`, dos abortos ou do teto de 5 muda — só se acrescenta narração.

**Files:**
- Modify: `tools/speckit-clarify-loop` — `run_round` (linhas ~162-273) e `main_loop` (linhas ~276-355)

**Interfaces:**
- Consumes: `emit_event`, `emit_note`, `emit_rule`, `mon_round_start` (Task 4).
- Produces: nenhuma função nova. Efeito observável: cada rodada narra, e `/tmp/speckit-clarify-loop/round-NN.log` existe ao final.

- [ ] **Step 1: Escrever a verificação que falha**

Este task não tem asserção unitária — o que ele muda é I/O de um laço que só existe com um processo `claude` do outro lado. A verificação é comportamental e roda em Task 6. Aqui a checagem é estrutural:

Run: `grep -n 'emit_event\|emit_note\|emit_rule\|mon_round_start' tools/speckit-clarify-loop | grep -v 'assert_out\|^[0-9]*:emit_\|^[0-9]*:mon_round_start()'`
Expected antes: só as definições — nenhuma chamada dentro de `run_round`/`main_loop`.

Run: `grep -n '\[r%s\]' tools/speckit-clarify-loop`
Expected antes: 3 ocorrências (linhas ~242, ~251, ~258) — as linhas que o monitor substitui.

- [ ] **Step 2: Confirmar o estado inicial**

Rode os dois `grep` acima e anote a saída. Se `[r%s]` não devolver 3 linhas, pare: o arquivo divergiu do plano e as substituições abaixo não vão casar.

- [ ] **Step 3: Aplicar o wiring**

**3a. Alimentar o monitor** — em `run_round`, dentro do `while IFS= read -r line`, como **primeira** instrução do corpo, antes do `typ="$(...)"` (linha ~203):

```bash
    emit_event "$line"
```

O `jq` do `typ` logo abaixo permanece — são duas passadas de `jq` na mesma linha, e o stream real de uma rodada tem ~100 linhas. Não vale acoplar o monitor ao despacho de controle para economizar isso.

**3b. Eco do `yes`** — substitua a linha ~251:

```bash
        printf '  [r%s] pergunta %d → yes\n' "$tag" "$ROUND_YES"
```

por:

```bash
        emit_note you "$(printf '%-24s (pergunta %d/%d)' 'yes' "$ROUND_YES" "$MAX_YES")"
```

**3c. Pergunta do `--dry-run`** — substitua a linha ~242:

```bash
          printf '  [r%s] pergunta 1 detectada (dry-run: não respondo)\n' "$tag"
```

por:

```bash
          emit_note warn 'dry-run: pergunta detectada, não respondo'
```

**3d. Turno indeterminado** — substitua a linha ~258:

```bash
        printf '  [r%s] turno indeterminado — stream em %s\n' "$tag" "$log"
```

por:

```bash
        emit_note warn "turno indeterminado — stream em $log"
```

**3e. Aborto narrado** — no fim de `run_round`, depois do bloco `if [ -z "$ROUND_OUTCOME" ]` (linha ~272):

```bash
  [ "$ROUND_OUTCOME" != aborto ] || emit_note warn "aborto: $ROUND_ABORT"
```

**3f. Abertura e cabeçalho da rodada** — em `main_loop`, substitua a linha ~290:

```bash
    printf 'rodada %s/%s …\n' "$tag" "$MAX_ROUNDS"
```

por:

```bash
    mon_round_start "$LOG_DIR/round-$tag.log"
    emit_rule ''
    emit_rule "$(printf '── rodada %s/%s ' "$tag" "$MAX_ROUNDS"; \
                 printf '─%.0s' $(eval echo "{1..$(( MON_WIDTH > 30 ? MON_WIDTH - 20 : 10 ))}"))"
```

`mon_round_start` fica aqui, e **não** dentro de `run_round`: `main_loop` já calculou `tag` (linha ~289), e é o único ponto em que o cabeçalho da rodada consegue nascer dentro do log daquela rodada. Se ele ficasse em `run_round`, o cabeçalho iria para o log da rodada anterior.

O `eval echo "{1..N}"` existe porque `seq` não está em `need_deps` — brace expansion do bash não aceita variável sem o `eval`. Se preferir evitar `eval`, troque a segunda linha por um traço fixo: `printf '───────────────────────────────'`.

**3g. Rodapé da rodada** — em `main_loop`, logo depois de `cur_hash="$(spec_hash)"` (linha ~297):

```bash
    emit_note ok "$(printf '%s · %d yes · US$ %s' "$ROUND_OUTCOME" "$ROUND_YES" "$ROUND_COST")"
```

- [ ] **Step 4: Verificar**

Run: `bash -n tools/speckit-clarify-loop`
Expected: sem saída.

Run: `bash tools/speckit-clarify-loop --self-test`
Expected: PASS — `self-test limpo (63 casos)`, exit 0. O wiring não pode ter quebrado nenhuma função pura.

Run: `grep -c '\[r%s\]' tools/speckit-clarify-loop`
Expected: `0` — as três linhas antigas sumiram.

Run: `grep -n 'mon_round_start' tools/speckit-clarify-loop`
Expected: 2 linhas — a definição e **uma** chamada, dentro de `main_loop`.

Run: `bash tools/speckit-clarify-loop --repo /tmp 2>&1 | head -3`
Expected: `speckit-clarify-loop: não parece um repo Spec Kit (sem .specify/): /tmp` — o preflight ainda barra antes de qualquer rodada.

- [ ] **Step 5: Commit**

```bash
git add tools/speckit-clarify-loop
git commit -m "feat(tools): motor da rodada narrando cada evento do stream"
```

---

## Task 6: verificação end-to-end e registro no cabeçalho

O contrato de TTY, largura e log em arquivo não se testa por igualdade de string. Verifica-se à mão, uma vez, do mesmo jeito que a verificação end-to-end já registrada no cabeçalho do script.

**Files:**
- Modify: `tools/speckit-clarify-loop` (comentário de cabeçalho, linhas 17-25)

**Interfaces:**
- Consumes: tudo das Tasks 1-5.
- Produces: nada em código.

- [ ] **Step 1: Instalar a versão de trabalho e escolher o repo alvo**

```bash
install -m 755 tools/speckit-clarify-loop ~/.local/bin/
```

Repo alvo: um repo Spec Kit com working tree limpo. `~/projects/personal/zion-mermaid-editor-app` foi o usado na verificação anterior. Confirme:

```bash
git -C ~/projects/personal/zion-mermaid-editor-app status --porcelain
```
Expected: vazio. Se sujo, use `--allow-dirty` e diga isso no registro do Step 4.

- [ ] **Step 2: Rodar o ensaio no TTY**

```bash
speckit-clarify-loop --repo ~/projects/personal/zion-mermaid-editor-app --dry-run
```

Verifique, olhando a tela:

1. O cabeçalho `── rodada 01/10 ───…` aparece.
2. Linhas `⚙ Bash …` e `⚙ Read spec.md` aparecem **enquanto** a rodada corre, não no fim.
3. `· pensando…` aparece, e nunca duas vezes seguidas.
4. `◆ claude` traz a prosa dobrada, com tabelas de opções intactas.
5. O relógio `mm:ss` cresce monotonicamente.
6. A pergunta aparece inteira, seguida de `⚠ dry-run: pergunta detectada, não respondo`.
7. O resumo final e a linha `reverter:` continuam iguais.

Expected exit code: 0.

- [ ] **Step 3: Rodar em pipe e conferir o log**

```bash
speckit-clarify-loop --repo ~/projects/personal/zion-mermaid-editor-app --dry-run | cat > /tmp/mon-pipe.txt
```

Run: `grep -cP '\x1b\[' /tmp/mon-pipe.txt`
Expected: `0` — nenhuma sequência ANSI quando o stdout não é TTY.

Run: `grep -cP '\x1b\[' /tmp/speckit-clarify-loop/round-01.log`
Expected: `0` — o log nunca leva ANSI, nem quando a execução foi num TTY.

Run: `grep -c 'claude\]' /tmp/speckit-clarify-loop/round-01.log`
Expected: `>= 1` — o log tem a prosa.

Run: `diff <(grep -v '^  [0-9][0-9]:[0-9][0-9]' /tmp/mon-pipe.txt) /dev/null | head`
— só para inspeção: as linhas sem relógio são cabeçalho, resumo e continuação de prosa.

Agora o `--quiet`:

```bash
speckit-clarify-loop --repo ~/projects/personal/zion-mermaid-editor-app --dry-run --quiet
```

Verifique: a tela mostra só cabeçalho de rodada e resumo; e

Run: `grep -c 'claude\]' /tmp/speckit-clarify-loop/round-01.log`
Expected: `>= 1` — **a narração continua no arquivo mesmo calada na tela.** É a razão de o `--quiet` não perder informação.

- [ ] **Step 4: Registrar a verificação no cabeçalho do script**

Substitua o parágrafo de verificação do cabeçalho (linhas 17-24, o bloco `# Verificado em 2026-07-21 …`) mantendo o que já está lá e acrescentando ao final, antes da linha `# Reinstalar após editar:`:

```bash
# Monitor verificado em 2026-07-21 no mesmo repo alvo:
#   --dry-run num TTY  → narração com símbolos, prosa dobrada, tabela intacta;
#   --dry-run | cat    → zero sequências ANSI no stdout;
#   --dry-run --quiet  → tela só com cabeçalho e resumo, e a narração inteira
#                        preservada em round-01.log. É o que faz do --quiet um
#                        modo sem perda: cala a tela, não a memória.
```

Ajuste a data e o repo se a verificação tiver sido feita em outro dia ou alvo. Se algum dos passos 2-3 falhou, **não** escreva este registro: corrija primeiro.

- [ ] **Step 5: Commit**

```bash
git add tools/speckit-clarify-loop
git commit -m "docs(tools): registra a verificação end-to-end do monitor do loop"
```

---

## Cobertura da spec

| Requisito da spec | Onde |
|---|---|
| Texto do assistente integral | Task 3 (`render_line` kind `text`) |
| Uma linha por tool call, com resumo | Task 2 (`tool_summary`) + Task 3 |
| `thinking` como marcador, sem conteúdo | Task 3 |
| Supressão de `thinking` consecutivo | Task 1 (`dedup_kind`) + Task 4 (`LAST_KIND`) |
| `yes` ecoado como `▸ você` | Task 5 (3c) |
| `tool_result` não renderizado | Task 1 (`user` → `nothing`) |
| `system/*` não renderizado | Task 1 |
| `rate_limit_event` só quando ≠ `allowed` | Task 1 + Task 3 |
| `result` não reimprime prosa | Task 3 (caso de teste explícito) |
| Rodapé da rodada | Task 5 (3h, via `emit_note`) |
| Monitor é padrão; `--quiet` opta por sair | Task 4 (3c, 3d) |
| Narração espelhada em `round-NN.log` | Task 4 (`emit_event`/`emit_note`) + Task 5 |
| Log sempre ASCII, sem ANSI | Task 4 (perfil `plain` fixo) + Task 6 (Step 3) |
| Perfil por TTY, largura `tput` com teto 100 | Task 4 (`mon_setup`) |
| Indentação 9, dobra `WIDTH-9`, tabelas intactas | Task 2 (`mon_fold`) |
| Relógio `mm:ss` por rodada via `SECONDS` | Task 4 (`mon_clock`, `mon_round_start`) |
| `--dry-run` narra igual | Task 5 (3d) + Task 6 (Step 2) |
| Caminhos de falha narrados | Task 5 (3e, 3f) |
| Monitor estritamente aditivo | Task 3 (caso da linha malformada) + Task 5 (Step 4) |
| Limpeza dos `.log` no preflight | Task 4 (3f) |
| Interface com `--quiet` no `usage` | Task 4 (3d) |

Fora de escopo, conforme a spec e sem task: TUI com regiões fixas, renderização de `tool_result`, flags de verbosidade granular, `NO_COLOR`, replay dos `.jsonl` gravados.
