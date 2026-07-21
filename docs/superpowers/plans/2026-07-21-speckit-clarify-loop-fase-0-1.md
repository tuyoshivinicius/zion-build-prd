# Evolução do `speckit-clarify-loop` — Fase 0 + Fase 1 + contenção do contrato (plano 1 de 4)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Instrumentar o `tools/speckit-clarify-loop` com medição por rodada (Fase 0), substituir a adivinhação de prosa por um contrato de saída explícito com a skill (Fase 1) — e, no mesmo plano, fechar o vetor de contaminação que a Fase 1 **cria** (M-06, M-07) e tornar legíveis as decisões que o modelo tomou sozinho (M-03, M-04). Nenhuma decisão de parada muda.

**Architecture:** Um único script bash de ~1300 linhas, `set -u`, sem `set -e`. A disciplina do arquivo é: **função pura de decisão** (entra texto/número, sai token, testável no `--self-test` sem repo e sem custo) separada da **cola impura** (fifo, `git`, `claude`, arquivos). Toda função nova deste plano respeita essa divisão: `read_sentinel`, `classify`, `sentinel_note`, `cost_per_line`, `sensor_line`, `diff_numstat` e família, `leaked_sentinel`, `decisions_of` e `decisions_block` são puras; só `narrate_sensors` e o `main_loop` tocam o mundo. A Fase 0 mede snapshot × spec (nunca contra `HEAD`); a Fase 1 põe uma sentinela de estado no `--append-system-prompt` e rebaixa a heurística bilíngue a fallback; a Parte II vigia o prefixo `CLARIFY_` nas linhas que a rodada **adicionou** e reaproveita o mesmo texto de `.result` para montar o resumo de decisões.

**Tech Stack:** bash 5, coreutils GNU (`diff`, `comm`, `sort`, `cut`, `cp`), `jq`, `git`, `awk` (gawk), `grep -E`. Testes: `--self-test` embutido no próprio script, mais um harness de execução sem custo (stub de `claude` + repo Spec Kit falso) entregue neste plano.

**Fonte da verdade:** `docs/superpowers/specs/2026-07-21-speckit-clarify-loop-evolucao-design.md`, Parte I **e** Parte II. Este plano é o **plano 1** do D-4: **Fase 0 + Fase 1** da Parte I, mais os itens da Parte II que o D-4 lhe atribui — **M-06, M-07, M-03, M-04 e M-12 (guarda e parsing)**. Fase 3, Fase 2 e Fase 4 saem em planos próprios, cada um carregando os seus `M-`; Fase 5 e M-11 são protocolo, não viram plano.

Os `M-` viajam distribuídos, e não num plano de mitigação próprio, por uma razão só (D-4): o **M-06 fecha um risco que a Fase 1 cria**. Entre o merge da Fase 1 e o de um plano separado, o vazamento da sentinela para dentro do `spec.md` seria silencioso.

## Global Constraints

- **Alvo único:** `tools/speckit-clarify-loop`. Ferramenta pessoal, instalada por cópia no PATH.
- **Fora do canon:** esta mudança **não** entra em `docs/prd.md` nem em `docs/architecture.md`; o dever de canonização do `CLAUDE.md` não se aplica (spec, cabeçalho). Mesmo assim `./scripts/check-canon.sh` e `./scripts/check-assets.sh` têm de continuar limpos — baseline verificado limpo em 2026-07-21, inclusive com arquivo novo em `tools/`.
- **P-2 — prosa não é contrato:** nenhum sinal de controle novo pode depender de casar texto livre de LLM.
- **P-3 — decisão é função pura:** entra número/texto, sai token; coleta impura fica separada; tudo exercitável pelo `--self-test`, sem repo e sem custo.
- **P-5 — limiar carrega comentário** dizendo se é chute ou evidência, com data, repo e número, no padrão de `ROUND_TIMEOUT` e `pick_cost`.
- **D-5 — a guarda de vazamento casa contra as linhas ADICIONADAS** (`added_lines "$snap" "$SPEC"`), nunca contra o spec inteiro. Um spec que documente o contrato — o R-07 da própria spec é o contra-exemplo — não pode abortar a rodada 1 para sempre. Ocorrência preexistente não envenena a execução; vazamento real é linha nova por definição.
- **D-6 — as decisões saem do `.jsonl`, não do `.log`.** O `round-NN.log` passa pelo `mon_fold`, que indenta a continuação em 9 colunas: uma linha `CLARIFY_DECISION:` chega lá como `         CLARIFY_DECISION: …` e a âncora `^` não casa nunca. A fonte é o campo `.result` do evento `result` — o mesmo texto que o `classify` já lê.
- **D-7 — ordem fixa dentro do contrato:** zero ou mais `CLARIFY_DECISION` primeiro, e `CLARIFY_STATE` sempre por último e sempre exatamente uma. O `tail -n 1` do `read_sentinel` já lê certo nessa ordem.
- **Layout do resumo:** este plano acrescenta o **bloco** de decisões (M-04) e nada mais. O realinhamento da coluna de rótulos para 11 caracteres, o rótulo `sentinela:` e as linhas `base:`/`branch:`/`aceitar:`/`descartar:`/`revisar:` são do M-02 e do M-05, no plano 4 — não se antecipam aqui.
- **Não mexer:** `ratelimit_fatal` com `allowed_*` permissivo · `timeout` embrulhando o `claude` (e não watchdog em subshell) · perfil `plain` forçado no `round-NN.log` · `--dry-run` conferindo o próprio hash.
- **Idioma:** comentários, mensagens e descrições de teste em português, no tom do arquivo — o comentário explica o *porquê* e cita a evidência (data, repo, US$) quando houver.
- **Portão de cada task:** `bash tools/speckit-clarify-loop --self-test` sai 0, e `bash -n tools/speckit-clarify-loop` está limpo.
- **Commits:** um commit por task, mensagem convencional em português, escopo `tools`.
- **Nada de `--dangerously-skip-permissions`, `--continue` ou `--resume`** — a invariante "uma rodada = um processo" não se toca.

---

## File Structure

| arquivo | responsabilidade | neste plano |
|---|---|---|
| `tools/speckit-clarify-loop` | o harness inteiro: constantes, funções puras, monitor, preflight, motor de rodada, driver, `--self-test` | modificado em todas as tasks |
| `tools/speckit-clarify-loop-harness.sh` | execução sem custo: monta um repo Spec Kit falso e um stub determinístico de `claude`, e roda o loop contra eles | **criado** na Task 1 |

O script continua sendo um arquivo só, de propósito: instala-se por cópia (`install -m 755 tools/speckit-clarify-loop ~/.local/bin/`) e não pode depender de nada ao lado dele. O harness é a única exceção — ele não é instalado, só serve para o desenvolvimento.

---

### Task 1: Baseline commitado e harness de execução sem custo

O working tree chega com trabalho não commitado (a regex ancorada do fecho e a família `allowed_*` permissiva). É a linha de base contra a qual a spec foi escrita: vai para um commit próprio antes de qualquer coisa. Em seguida nasce o harness que torna toda task seguinte verificável de ponta a ponta sem gastar cota.

**Files:**
- Modify: `tools/speckit-clarify-loop` (só o commit do que já está no working tree; nenhuma edição)
- Create: `tools/speckit-clarify-loop-harness.sh`

**Interfaces:**
- Produces: `tools/speckit-clarify-loop-harness.sh [flags do loop…]` — monta `/tmp/skcl-harness/repo` e executa `tools/speckit-clarify-loop --repo /tmp/skcl-harness/repo "$@"`. Todas as tasks seguintes usam este comando. Quatro variáveis de ambiente moldam o cenário:

  | variável | efeito | quem exercita |
  |---|---|---|
  | `SKCL_NOSENT=1` | o stub **não** emite a sentinela | Task 12 (R-09) |
  | `SKCL_LEAK=1` | o stub escreve `CLARIFY_STATE:` **dentro** do spec | Task 13 (M-06) |
  | `SKCL_CITA=1` | o spec base já **cita** a sentinela numa cerca | Task 13 (D-5) |
  | — (default) | o stub emite `CLARIFY_DECISION` + `CLARIFY_STATE`, na ordem do D-7 | Task 14 (M-04) |

- [ ] **Step 1: Conferir que o working tree é a linha de base esperada**

```bash
git -C /home/tuyoshi/projects/personal/zion-build-prd diff --stat tools/speckit-clarify-loop
git -C /home/tuyoshi/projects/personal/zion-build-prd diff tools/speckit-clarify-loop | grep -E '^\+(SIG_NEXT_RE|ratelimit_fatal)'
```

Esperado: `1 file changed, 145 insertions(+), 10 deletions(-)` e as duas linhas
`+SIG_NEXT_RE='^(#{1,4}…` e `+ratelimit_fatal() {`.

Se o diff for outro, **pare e relate** — o baseline mudou e o resto do plano precisa ser reconferido.

- [ ] **Step 2: Rodar o self-test antes de tocar em nada**

Run: `bash tools/speckit-clarify-loop --self-test`
Expected: última linha `speckit-clarify-loop: self-test limpo (92 casos)`, exit 0.

- [ ] **Step 3: Commitar a linha de base**

```bash
git add tools/speckit-clarify-loop
git commit -m "fix(tools): fechar rodada por regex ancorada e tolerar allowed_*"
```

- [ ] **Step 4: Criar o harness**

Create `tools/speckit-clarify-loop-harness.sh` com exatamente este conteúdo:

```bash
#!/usr/bin/env bash
# Harness sem custo do speckit-clarify-loop: um repo Spec Kit falso e um stub
# determinístico de `claude`, para exercitar o caminho de execução inteiro —
# preflight, fifo, classificação, snapshot, narração e resumo — sem gastar cota.
#
# Uso:  tools/speckit-clarify-loop-harness.sh [flags do loop…]
#       SKCL_NOSENT=1 …   # stub sem sentinela          (R-09)
#       SKCL_LEAK=1   …   # stub vaza CLARIFY_ no spec  (M-06)
#       SKCL_CITA=1   …   # spec base CITA a sentinela  (D-5)
#
# O repo falso mora em /tmp/skcl-harness/repo e é recriado a cada invocação.
# Não é instalado: existe só para o desenvolvimento do loop.
set -u
ROOT=/tmp/skcl-harness
LOOP="$(cd "$(dirname "$0")" && pwd)/speckit-clarify-loop"
SPEC="$ROOT/repo/specs/001-fake/spec.md"

rm -rf "$ROOT"
mkdir -p "$ROOT/bin" "$ROOT/repo/.specify/scripts/bash" "$ROOT/repo/specs/001-fake"
if [ "${SKCL_CITA:-0}" -eq 1 ]; then
  # D-5: um spec que DOCUMENTA o contrato. A ocorrência é preexistente, então a
  # guarda do M-06 não pode abortar por causa dela — nem na rodada 1, nem nunca.
  # 11 linhas.
  printf '%s\n' '# Spec fake' '' '## Requisitos' '' '- RF-01 algo' \
    '' '## Contrato' '' '```' 'CLARIFY_STATE: ASKING' '```' > "$SPEC"
else
  printf '%s\n' '# Spec fake' '' '## Requisitos' '' '- RF-01 algo' > "$SPEC"
fi

cat > "$ROOT/repo/.specify/scripts/bash/check-prerequisites.sh" <<EOF
#!/usr/bin/env bash
printf '{"FEATURE_SPEC":"%s"}\n' "$SPEC"
EOF
chmod +x "$ROOT/repo/.specify/scripts/bash/check-prerequisites.sh"

git -C "$ROOT/repo" init -q
git -C "$ROOT/repo" add -A
git -C "$ROOT/repo" -c user.email=harness@local -c user.name=harness commit -qm 'spec fake'

cat > "$ROOT/bin/claude" <<'STUB'
#!/usr/bin/env bash
# Stub de `claude`. Consome o /speckit-clarify, pergunta, espera o `yes`,
# escreve no spec (o Edit da skill) e fecha com um Completion Report. Sob
# --dry-run o `yes` nunca chega: o read pega EOF e o stub sai sem escrever, que
# é exatamente o que o modo promete.
#
# Cada turno sai DUAS vezes, como no stream real: um evento `assistant` com a
# prosa (que é o que o monitor narra) e o `result` (que é o que o classificador
# lê). Sem o primeiro, a sentinela não apareceria no round-NN.log e o harness
# não modelaria a narração.
#
# Os `\n` ficam LITERAIS de propósito — são escapes de JSON, e viajam como
# argumento de %s justamente para o printf não os interpretar.
SPEC="${SKCL_SPEC:?}"
ask=''; fim=''
if [ "${SKCL_NOSENT:-0}" -eq 0 ]; then
  ask='\n\nCLARIFY_STATE: ASKING'
  # Ordem do D-7: zero ou mais CLARIFY_DECISION, e a CLARIFY_STATE por último.
  fim='\n\nCLARIFY_DECISION: assunto do teste -> A (recomendada)\nCLARIFY_STATE: COMPLETE'
fi
P1='**Recomendada:** Opção A — texto.'"$ask"
P2='## Relatório\n\n### Próximo comando\n\n`/speckit-plan`'"$fim"
IFS= read -r _prompt || exit 0
printf '%s\n' '{"type":"system","subtype":"init","session_id":"fake"}'
printf '%s\n' '{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Bash","input":{"command":"check-prerequisites.sh --json --paths-only"}}]}}'
printf '%s\n' '{"type":"assistant","message":{"content":[{"type":"text","text":"'"$P1"'"}]}}'
printf '%s\n' '{"type":"result","is_error":false,"total_cost_usd":0.10,"result":"'"$P1"'"}'
IFS= read -r _yes || exit 0
printf '\n## Clarifications\n\n- Q1: A\n' >> "$SPEC"
if [ "${SKCL_LEAK:-0}" -eq 1 ]; then
  # M-06: o vazamento que a guarda existe para pegar — linha NOVA no spec,
  # começada por CLARIFY_ na primeira coluna.
  printf 'CLARIFY_STATE: COMPLETE\n' >> "$SPEC"
fi
printf '%s\n' '{"type":"assistant","message":{"content":[{"type":"text","text":"'"$P2"'"}]}}'
printf '%s\n' '{"type":"result","is_error":false,"total_cost_usd":0.25,"result":"'"$P2"'"}'
STUB
chmod +x "$ROOT/bin/claude"

PATH="$ROOT/bin:$PATH" SKCL_SPEC="$SPEC" \
  SKCL_NOSENT="${SKCL_NOSENT:-0}" SKCL_LEAK="${SKCL_LEAK:-0}" \
  "$LOOP" --repo "$ROOT/repo" "$@"
```

- [ ] **Step 5: Tornar executável e exercitar os cinco cenários**

```bash
chmod +x tools/speckit-clarify-loop-harness.sh
./tools/speckit-clarify-loop-harness.sh --max-rounds 2 | grep -E 'yes:|delta|parada'
./tools/speckit-clarify-loop-harness.sh --dry-run | grep -E 'delta|parada'
SKCL_NOSENT=1 ./tools/speckit-clarify-loop-harness.sh --max-rounds 1 | grep -E 'delta|parada'
SKCL_LEAK=1   ./tools/speckit-clarify-loop-harness.sh --max-rounds 1 | grep delta
SKCL_CITA=1   ./tools/speckit-clarify-loop-harness.sh --max-rounds 1 | grep delta
```

Expected, nesta ordem:

```
yes:      2 (r01=1 r02=1)
spec:     5 → 13 linhas (delta +8)
parada:   teto de rodadas atingido (2) sem convergir
spec:     5 → 5 linhas (delta +0)
parada:   --dry-run: 1 pergunta classificada, nada gravado
spec:     5 → 9 linhas (delta +4)
parada:   teto de rodadas atingido (1) sem convergir
spec:     5 → 10 linhas (delta +5)
spec:     11 → 15 linhas (delta +4)
```

O `--dry-run` com `delta +0` é o teste que importa: prova que o harness modela
o modo de ensaio corretamente. As duas últimas linhas só provam que os cenários
da Parte II montam o que dizem montar — a linha vazada é o `+5` contra o `+4`,
e o spec que cita a sentinela nasce com 11 linhas em vez de 5. Nesta task
**nenhuma das duas aborta**: a guarda que reage a elas chega na Task 13.

- [ ] **Step 6: Confirmar que o repo continua sem drift**

```bash
./scripts/check-canon.sh && ./scripts/check-assets.sh
```
Expected: `check-canon: limpo` e `check-assets: sem drift`.

- [ ] **Step 7: Commit**

```bash
git add tools/speckit-clarify-loop-harness.sh
git commit -m "test(tools): harness sem custo para o speckit-clarify-loop"
```

---

### Task 2: S-1 — colapsar cinco helpers de asserção no `assert_out`

Precede o R-06 de propósito: com cinco helpers a menos, o contador automático da Task 3 instrumenta 2 pontos em vez de 8.

**Files:**
- Modify: `tools/speckit-clarify-loop` — remover `assert_classify`, `assert_kind`, `assert_dedup`, `assert_fatal`, `assert_render`; acrescentar o shim `fatal_str`; reescrever as chamadas em `self_test`.

**Interfaces:**
- Consumes: `assert_out "desc" esperado comando args…` (já existe), `assert_emit` (já existe, fica).
- Produces: `fatal_str status → sim|nao` — adaptador de `ratelimit_fatal`, que devolve por status de saída.

- [ ] **Step 1: Apagar os cinco helpers**

Remover integralmente as funções `assert_classify`, `assert_kind` e `assert_dedup` (logo abaixo de `ST_FAIL=0`) e `assert_fatal` e `assert_render` (logo abaixo de `assert_emit`). `assert_out`, `assert_emit` e `mon_fold_str` **ficam**.

- [ ] **Step 2: Acrescentar o shim, logo abaixo de `mon_fold_str`**

```bash
# Adaptador de teste, irmão do mon_fold_str: ratelimit_fatal responde por status
# de saída, e assert_out só sabe comparar stdout.
fatal_str() { if ratelimit_fatal "${1:-}"; then printf 'sim'; else printf 'nao'; fi; }
```

- [ ] **Step 3: Reescrever o bloco de classificação em `self_test`**

Substituir o bloco inteiro de `assert_classify` por:

```bash
  assert_out "pergunta múltipla escolha"        pergunta-pendente classify "$FIX_MC"
  assert_out "pergunta de resposta curta"       pergunta-pendente classify "$FIX_SHORT"
  assert_out "Completion Report"                rodada-completa   classify "$FIX_REPORT"
  assert_out "frase seca tem prioridade sobre o report" loop-seco  classify "$FIX_DRY"
  assert_out "texto que não casa com nada"      indeterminada     classify "$FIX_NOISE"
  assert_out "texto vazio"                      indeterminada     classify ""
  assert_out "'recommend' em prosa não é pergunta" indeterminada  classify "$FIX_PROSE_RECOMMEND"
  assert_out "só o marcador bold conta"         pergunta-pendente classify '**Recommended:** Option A - x'
  assert_out "pergunta múltipla escolha em pt"  pergunta-pendente classify "$FIX_MC_PT"
  assert_out "pergunta curta em pt"             pergunta-pendente classify "$FIX_SHORT_PT"
  assert_out "Completion Report em pt"          rodada-completa   classify "$FIX_REPORT_PT"
  assert_out "frase seca em pt"                 loop-seco         classify "$FIX_DRY_PT"
  assert_out "pergunta em pt no feminino"       pergunta-pendente classify "$FIX_MC_PT_FEM"
  assert_out "pergunta curta em pt no feminino" pergunta-pendente classify "$FIX_SHORT_PT_FEM"
  assert_out "report que titula 'Próximo passo'" rodada-completa  classify "$FIX_REPORT_PASSO_PT"
  assert_out "'próximo passo' em prosa não encerra a rodada" \
    pergunta-pendente classify "$FIX_MC_PT_COM_PASSO"
  assert_out "report que titula 'Próximo comando'" rodada-completa \
    classify "$FIX_REPORT_COMANDO_PT"
  assert_out "'próximo comando' em prosa não encerra a rodada" \
    pergunta-pendente classify "$FIX_MC_PT_COM_COMANDO"
  assert_out "report com fecho em negrito, sem título da família" \
    rodada-completa classify "$FIX_REPORT_NEGRITO_PT"
  # Guardas da âncora: a regex tem que exigir o `#`/`**` no INÍCIO da linha.
  assert_out "'Próximo passo' sem destaque não conta" \
    indeterminada classify 'Próximo passo do fluxo é o plano.'
  assert_out "negrito no meio da linha não conta" \
    indeterminada classify 'Escrevi **Próximo comando** no rascunho e apaguei.'
```

- [ ] **Step 4: Reescrever o bloco de `event_kind`**

```bash
  assert_out "tool_use Bash"                tool      event_kind "$FX_TOOL_BASH"
  assert_out "tool_use Read"                tool      event_kind "$FX_TOOL_READ"
  assert_out "tool_use desconhecida"        tool      event_kind "$FX_TOOL_OTHER"
  assert_out "thinking"                     thinking  event_kind "$FX_THINK"
  assert_out "texto do assistente"          text      event_kind "$FX_TEXT"
  assert_out "linha em lote: texto vence"   text      event_kind "$FX_MIXED"
  assert_out "system/init é ruído"          nothing   event_kind "$FX_SYS_INIT"
  assert_out "system/thinking_tokens é ruído" nothing event_kind "$FX_SYS_TOK"
  assert_out "tool_result do usuário é ruído" nothing event_kind "$FX_USER_TR"
  assert_out "rate limit allowed é ruído"   nothing   event_kind "$FX_RL_OK"
  assert_out "rate limit não-allowed"       ratelimit event_kind "$FX_RL_BAD"
  # O aviso NÃO é ruído: deixou de abortar, mas continua na tela, porque 90% da
  # janela com excedente indisponível é a informação que decide se vale começar
  # outra rodada agora ou esperar o reset.
  assert_out "rate limit allowed_warning é narrado" ratelimit event_kind "$FX_RL_WARN"
```

- [ ] **Step 5: Reescrever o bloco de rate limit e os três `event_kind` que o seguem**

```bash
  assert_out "allowed não aborta"                 nao fatal_str allowed
  assert_out "allowed_warning não aborta"         nao fatal_str allowed_warning
  assert_out "qualquer allowed_* não aborta"      nao fatal_str allowed_seja_o_que_for
  assert_out "rejected aborta"                    sim fatal_str rejected
  assert_out "status desconhecido aborta"         sim fatal_str '?'
  assert_out "status vazio aborta"                sim fatal_str ''
  assert_out "result"                       result    event_kind "$FX_RESULT"
  assert_out "linha malformada não quebra"  nothing   event_kind "$FX_BAD"
  assert_out "linha vazia não quebra"       nothing   event_kind ""
```

- [ ] **Step 6: Reescrever o bloco de `dedup_kind`**

```bash
  assert_out "thinking após thinking suprime"  nothing  dedup_kind thinking thinking
  assert_out "thinking após tool passa"        thinking dedup_kind tool     thinking
  assert_out "texto após texto passa"          text     dedup_kind text     text
  assert_out "sem anterior passa"              tool     dedup_kind ""       tool
```

- [ ] **Step 7: Reescrever o bloco de `render_line`**

```bash
  assert_out "tool_use Bash mostra o comando" \
    '  01:23  [tool]    Bash     check-prerequisites.sh --json --paths-only' \
    render_line plain 80 '01:23' tool "$FX_TOOL_BASH"
  assert_out "tool_use Read mostra só o basename" \
    '  01:23  [tool]    Read     spec.md' \
    render_line plain 80 '01:23' tool "$FX_TOOL_READ"
  assert_out "ferramenta desconhecida não quebra" \
    '  01:23  [tool]    WebSearch query=spec kit clarify' \
    render_line plain 80 '01:23' tool "$FX_TOOL_OTHER"
  assert_out "thinking vira marcador sem conteúdo" \
    '  01:23  [...]     pensando…' \
    render_line plain 80 '01:23' thinking "$FX_THINK"
  assert_out "texto imprime cabeçalho e preserva a tabela" \
    "$(printf '  01:23  [claude]  claude\n         **Recomendado: Opção B**\n\n         | Opção | Descrição |\n         |---|---|\n         | A | Manter o silêncio |')" \
    render_line plain 80 '01:23' text "$FX_TEXT"
  assert_out "rate limit não-allowed avisa" \
    '  01:23  [!]       rate limit: rejected' \
    render_line plain 80 '01:23' ratelimit "$FX_RL_BAD"
  assert_out "result NÃO reimprime a prosa" '' render_line plain 80 '01:23' result "$FX_RESULT"
  assert_out "kind nothing não imprime nada"  '' render_line plain 80 '01:23' nothing "$FX_SYS_INIT"
  assert_out "linha malformada não imprime nada" '' render_line plain 80 '01:23' tool "$FX_BAD"
```

- [ ] **Step 8: Rodar o self-test**

Run: `bash tools/speckit-clarify-loop --self-test`
Expected: `speckit-clarify-loop: self-test limpo (92 casos)`, exit 0. Nenhuma linha `FALHOU:`.

Se aparecer `FALHOU`, o erro está na tradução mecânica de uma chamada — compare o
esperado com o do helper antigo antes de mexer no código de produção.

- [ ] **Step 9: Commit**

```bash
git add tools/speckit-clarify-loop
git commit -m "refactor(tools): colapsar cinco helpers de asserção no assert_out"
```

---

### Task 3: R-06 — contador de casos automático

O literal `(92 casos)` é uma segunda fonte de verdade sobre o tamanho da suíte, e desatualiza sozinho.

**Files:**
- Modify: `tools/speckit-clarify-loop` — `ST_COUNT`, incremento em `assert_out` e `assert_emit`, rodapé do `self_test`.

**Interfaces:**
- Produces: variável global `ST_COUNT`, incrementada por toda asserção.

- [ ] **Step 1: Declarar o contador ao lado de `ST_FAIL`**

Substituir a linha `ST_FAIL=0` por:

```bash
ST_FAIL=0
# Contador de casos: cresce sozinho a cada asserção. O literal que ele substitui
# era uma segunda verdade sobre o tamanho da suíte — acrescentar um teste e
# esquecer de somar 1 não deixava rastro nenhum.
ST_COUNT=0
```

- [ ] **Step 2: Incrementar em `assert_out`**

Em `assert_out`, logo após `local desc="$1" want="$2"; shift 2`:

```bash
  ST_COUNT=$((ST_COUNT + 1))
```

- [ ] **Step 3: Incrementar em `assert_emit`**

Em `assert_emit`, logo após `local desc="$1" want="$2"; shift 2`:

```bash
  ST_COUNT=$((ST_COUNT + 1))
```

- [ ] **Step 4: Trocar o rodapé do `self_test`**

Substituir:

```bash
  if [ "$ST_FAIL" -eq 0 ]; then
    printf 'speckit-clarify-loop: self-test limpo (92 casos)\n'; exit 0
  fi
  printf 'speckit-clarify-loop: self-test COM FALHAS\n' >&2; exit 1
```

por:

```bash
  if [ "$ST_FAIL" -eq 0 ]; then
    printf 'speckit-clarify-loop: self-test limpo (%d casos)\n' "$ST_COUNT"; exit 0
  fi
  printf 'speckit-clarify-loop: self-test COM FALHAS (%d casos)\n' "$ST_COUNT" >&2; exit 1
```

- [ ] **Step 5: Verificar que o número sai sozinho e é o mesmo de antes**

Run: `bash tools/speckit-clarify-loop --self-test | tail -1`
Expected: `speckit-clarify-loop: self-test limpo (92 casos)` — o mesmo 92 do literal apagado, agora contado.

- [ ] **Step 6: Provar que o contador acompanha (teste do teste)**

```bash
cp tools/speckit-clarify-loop /tmp/skcl-probe
sed -i 's|^  assert_out "texto vazio".*$|&\n  assert_out "sonda do contador" indeterminada classify ""|' /tmp/skcl-probe
bash /tmp/skcl-probe --self-test | tail -1
rm -f /tmp/skcl-probe
```
Expected: `speckit-clarify-loop: self-test limpo (93 casos)`.

- [ ] **Step 7: Commit**

```bash
git add tools/speckit-clarify-loop
git commit -m "test(tools): contar os casos do self-test em vez de fixar o literal"
```

---

### Task 4: S-2 — matar `mon_prefix`

A largura do prefixo é derivável do próprio marcador. A função era uma tabela paralela que podia divergir do `mon_marker`.

**Files:**
- Modify: `tools/speckit-clarify-loop` — apagar `mon_prefix` e seus dois testes; calcular no ramo `tool` de `render_line`; dois testes novos de truncagem.

- [ ] **Step 1: Apagar a função e o comentário acima dela**

Remover:

```bash
# Colunas consumidas por "  CLOCK  MARCADOR  ": 2+5+2+largura(marcador)+2.
mon_prefix() { case "${1:-}" in tty) printf '12' ;; *) printf '19' ;; esac; }
```

- [ ] **Step 2: Tirar o cálculo antecipado do topo de `render_line`**

Em `render_line`, trocar

```bash
  local body prefix tsv name summary st

  prefix="$(mon_prefix "$p")"

```

por

```bash
  local body mark prefix tsv name summary st

```

- [ ] **Step 3: Calcular a partir do marcador, dentro do ramo `tool`**

Substituir o ramo `tool)` inteiro por:

```bash
    tool)
      tsv="$(tool_summary "$line")"
      [ -n "$tsv" ] || return 0
      name="${tsv%%$'\t'*}"
      summary="${tsv#*$'\t'}"
      [ "$summary" != "$tsv" ] || summary=""
      # Colunas consumidas por "  CLOCK  MARCADOR  ": 2+5+2+largura+2. Sai do
      # próprio marcador em vez de uma tabela paralela: `⚙` dá 12 e `[tool]  `
      # dá 19, os mesmos números da função que isto substitui. `${#}` conta
      # caractere e não byte sob locale UTF-8 — a mesma premissa que mon_trunc
      # já faz ao cortar prosa acentuada, não uma premissa nova.
      mark="$(mon_marker "$p" tool)"
      prefix=$(( 2 + 5 + 2 + ${#mark} + 2 ))
      body="$(printf '%-8s %s' "$name" "$summary")"
      body="$(mon_trunc "$body" $(( w - prefix )))"
      mon_head "$clock" "$mark" "$(mon_paint "$p" dim "$body")"
      ;;
```

- [ ] **Step 4: Trocar os dois testes de `mon_prefix` por dois de truncagem**

Substituir

```bash
  assert_out "prefixo tty ocupa 12 colunas"      '12'       mon_prefix tty
  assert_out "prefixo plain ocupa 19 colunas"    '19'       mon_prefix plain
```

por

```bash
  # A largura reservada não é mais observável direto: observa-se onde a
  # truncagem cai. Com w=40, plain reserva 19 e sobra 21; tty reserva 12 e
  # sobra 28. São os mesmos 19 e 12 de antes, agora medidos no resultado.
  assert_out "prefixo plain reserva 19 colunas na truncagem" \
    '  01:23  [tool]    Bash     check-prere…' \
    render_line plain 40 '01:23' tool "$FX_TOOL_BASH"
  assert_out "prefixo tty reserva 12 colunas na truncagem" \
    "$(printf '  01:23  ⚙  \033[2mBash     check-prerequisite…\033[0m')" \
    render_line tty 40 '01:23' tool "$FX_TOOL_BASH"
```

- [ ] **Step 5: Rodar o self-test**

Run: `bash tools/speckit-clarify-loop --self-test | tail -1`
Expected: `speckit-clarify-loop: self-test limpo (92 casos)` (dois testes saíram, dois entraram).

- [ ] **Step 6: Conferir que a narração real não mudou**

```bash
./tools/speckit-clarify-loop-harness.sh --max-rounds 1 | grep '\[tool\]'
```
Expected: `  00:0X  [tool]    Bash     check-prerequisites.sh --json --paths-only`
(o `X` varia com o relógio; o resto é idêntico ao de antes da task).

- [ ] **Step 7: Commit**

```bash
git add tools/speckit-clarify-loop
git commit -m "refactor(tools): derivar a largura do prefixo do próprio marcador"
```

---

### Task 5: S-7 — uma fonte de verdade para a família que escreve

`MUTANTES` já lista as ferramentas que gravam; o `--dry-run` repetia a lista literal.

**Files:**
- Modify: `tools/speckit-clarify-loop` — bloco `if [ "$DRY_RUN" -eq 1 ]` dentro de `run_round`.

- [ ] **Step 1: Trocar a lista literal pela variável**

Substituir

```bash
  if [ "$DRY_RUN" -eq 1 ]; then
    args+=( --disallowedTools Edit Write MultiEdit NotebookEdit )
  fi
```

por

```bash
  if [ "$DRY_RUN" -eq 1 ]; then
    # Word-splitting INTENCIONAL: $MUTANTES é a fonte única da família que
    # escreve, e o ensaio precisa negá-la inteira. Repetir a lista aqui eram
    # duas verdades para um fato só — e a que ficasse para trás seria esta.
    # shellcheck disable=SC2086
    args+=( --disallowedTools $MUTANTES )
  fi
```

- [ ] **Step 2: Conferir que só existe uma lista no arquivo**

Run: `grep -n 'MultiEdit' tools/speckit-clarify-loop`
Expected: exatamente uma linha, a de `MUTANTES='Edit Write MultiEdit NotebookEdit'`, mais as linhas de teste `mutating_only` (que exercitam o filtro e devem continuar).

- [ ] **Step 3: Sintaxe e suíte**

```bash
bash -n tools/speckit-clarify-loop
bash tools/speckit-clarify-loop --self-test | tail -1
./tools/speckit-clarify-loop-harness.sh --dry-run | grep -E 'delta|parada'
```
Expected: sem saída do `bash -n`; `self-test limpo (92 casos)`; `delta +0` e `parada:   --dry-run: 1 pergunta classificada, nada gravado`.

Nota: o stub do harness ignora `--disallowedTools` (ele não é o Claude Code), então este passo prova que a montagem dos argumentos não quebrou, não que a negação funciona. A prova de ponta a ponta é a execução real da Task 15.

- [ ] **Step 4: Commit**

```bash
git add tools/speckit-clarify-loop
git commit -m "refactor(tools): negar a família de escrita a partir do MUTANTES"
```

---

### Task 6: R-01 — um diretório de log por execução

Hoje o `preflight` apaga os logs da execução anterior. Comparar duas execuções — que é o insumo da calibração da Fase 5 — é impossível.

**Files:**
- Modify: `tools/speckit-clarify-loop` — bloco de constantes, `preflight`, resumo do `main_loop`.

**Interfaces:**
- Produces: `LOG_ROOT` (fixo, `/tmp/speckit-clarify-loop`) e `LOG_DIR` (definido no `preflight`, `$LOG_ROOT/<YYYYmmdd-HHMMSS>`). `$LOG_ROOT/latest` é symlink para a execução corrente. Todo o resto do script continua lendo `LOG_DIR`.

- [ ] **Step 1: Trocar a constante**

Substituir `LOG_DIR=/tmp/speckit-clarify-loop` por:

```bash
# Um diretório por execução. Até 2026-07-21 o preflight apagava os logs da
# execução anterior: a rodada 03 de ontem sumia com a rodada 01 de hoje, e
# comparar duas execuções — que é o insumo da calibração dos sensores — era
# impossível. LOG_DIR nasce vazio de propósito: quem o define é o preflight,
# que é o único lugar que sabe a hora do arranque.
LOG_ROOT=/tmp/speckit-clarify-loop
LOG_DIR=""
```

- [ ] **Step 2: Criar o diretório da execução e o `latest` no `preflight`**

Substituir

```bash
  mkdir -p "$LOG_DIR" || die "não consegui criar $LOG_DIR"
  rm -f "$LOG_DIR"/round-*.jsonl "$LOG_DIR"/round-*.jsonl.err "$LOG_DIR"/round-*.log
```

por

```bash
  LOG_DIR="$LOG_ROOT/$(date +%Y%m%d-%H%M%S)"
  mkdir -p "$LOG_DIR" || die "não consegui criar $LOG_DIR"
  # -n para não SEGUIR o symlink existente e acabar criando um `latest/latest`
  # lá dentro. Falhar aqui não derruba a execução: `latest` é conveniência de
  # quem vai ler o log, não contrato de ninguém.
  ln -sfn "$LOG_DIR" "$LOG_ROOT/latest" 2>/dev/null || true
```

- [ ] **Step 3: Imprimir o diretório da execução no resumo**

Substituir `printf 'streams:  %s/round-*.jsonl\n' "$LOG_DIR"` por:

```bash
  printf 'logs:     %s\n' "$LOG_DIR"
  printf '          round-NN.jsonl (stream) · round-NN.log (narração) · latest → esta execução\n'
```

- [ ] **Step 4: Verificar que duas execuções deixam dois diretórios íntegros**

```bash
rm -rf /tmp/speckit-clarify-loop
./tools/speckit-clarify-loop-harness.sh --max-rounds 1 > /dev/null 2>&1
sleep 1
./tools/speckit-clarify-loop-harness.sh --max-rounds 1 | grep -A1 '^logs:'
ls -1 /tmp/speckit-clarify-loop | grep -c '^2'
ls -1 /tmp/speckit-clarify-loop/*/round-01.jsonl | wc -l
readlink /tmp/speckit-clarify-loop/latest
```
Expected: a linha `logs:     /tmp/speckit-clarify-loop/<data>-<hora>` seguida da
linha de legenda; `2` diretórios datados; `2` streams `round-01.jsonl` (nenhum
foi apagado); e o `readlink` apontando para o **segundo** diretório.

- [ ] **Step 5: Suíte e sintaxe**

```bash
bash -n tools/speckit-clarify-loop
bash tools/speckit-clarify-loop --self-test | tail -1
```
Expected: sem saída; `self-test limpo (92 casos)`.

- [ ] **Step 6: Commit**

```bash
git add tools/speckit-clarify-loop
git commit -m "feat(tools): um diretório de log por execução, com symlink latest"
```

---

### Task 7: R-03 — funções de coleta contra (snapshot, spec)

As seis funções que a Fase 2 vai consumir. Nenhuma delas decide nada ainda; nenhuma delas olha para `HEAD`.

**Files:**
- Modify: `tools/speckit-clarify-loop` — `need_deps`; nova seção de coleta logo abaixo de `spec_lines`; fixtures de arquivo e 12 asserções no `self_test`.

**Interfaces:**
- Produces:
  - `diff_numstat snapshot spec` → `"add del"` (sempre duas colunas)
  - `added_lines snapshot spec` → as linhas adicionadas, uma por linha, sem o `> ` do diff
  - `added_fences snapshot spec` → nº de **linhas** de cerca criadas
  - `headings_of arquivo` → títulos markdown do arquivo, um por linha
  - `new_headings snapshot spec` → nº de títulos que só existem no spec
  - `touched_sections snapshot spec` → títulos das seções que receberam linha, na ordem do arquivo novo
  - `count_markers arquivo` → nº de ocorrências de `[NEEDS CLARIFICATION]`

- [ ] **Step 1: Escrever as asserções que falham**

No `self_test`, logo antes do bloco `SECONDS=125`, inserir:

```bash
  # Coleta (R-03): fixtures de ARQUIVO, criadas em $TMPDIR e apagadas no fim.
  # O --self-test continua não exigindo repo, git, rede nem cota.
  assert_out "numstat conta adição e remoção"     '7 0' diff_numstat "$st_old" "$st_new"
  assert_out "numstat inverte com os arquivos"    '0 7' diff_numstat "$st_new" "$st_old"
  assert_out "numstat sem mudança dá duas colunas" '0 0' diff_numstat "$st_old" "$st_old"
  assert_out "linhas adicionadas vêm sem o '> ' do diff" \
    "$(printf -- '- RF-02 novo [NEEDS CLARIFICATION] e outro [NEEDS CLARIFICATION]\n\n## Clarifications\n\n```\ncodigo\n```')" \
    added_lines "$st_old" "$st_new"
  assert_out "cercas criadas contam por linha"    '2' added_fences "$st_old" "$st_new"
  assert_out "sem mudança não há cerca nova"      '0' added_fences "$st_old" "$st_old"
  assert_out "título novo é contado"              '1' new_headings "$st_old" "$st_new"
  assert_out "sem título novo dá zero"            '0' new_headings "$st_old" "$st_old"
  assert_out "seções tocadas saem na ordem do arquivo novo" \
    "$(printf '## Requisitos\n## Clarifications')" \
    touched_sections "$st_old" "$st_new"
  assert_out "sem mudança nenhuma seção é tocada" '' touched_sections "$st_old" "$st_old"
  assert_out "marcadores contam por ocorrência, não por linha" '2' count_markers "$st_new"
  assert_out "arquivo sem marcador dá zero"       '0' count_markers "$st_old"
```

E, no **começo** do corpo de `self_test` (primeira linha da função), inserir a
montagem das fixtures:

```bash
  local st_dir st_old st_new
  st_dir="$(mktemp -d "${TMPDIR:-/tmp}/speckit-clarify-loop-fx.XXXXXX")"
  st_old="$st_dir/old.md"
  st_new="$st_dir/new.md"
  printf '%s\n' '# Spec fake' '' '## Requisitos' '' '- RF-01 algo' > "$st_old"
  printf '%s\n' '# Spec fake' '' '## Requisitos' '' '- RF-01 algo' \
    '- RF-02 novo [NEEDS CLARIFICATION] e outro [NEEDS CLARIFICATION]' \
    '' '## Clarifications' '' '```' 'codigo' '```' > "$st_new"

```

E, logo **antes** do `if [ "$ST_FAIL" -eq 0 ]` do rodapé:

```bash
  rm -rf "$st_dir"

```

- [ ] **Step 2: Rodar para ver falhar**

Run: `bash tools/speckit-clarify-loop --self-test 2>&1 | grep -c FALHOU`
Expected: `11`. São 12 asserções, mas função inexistente devolve saída vazia, e
`"sem mudança nenhuma seção é tocada"` espera justamente `''` — ela passa por
acidente até a implementação existir. As outras onze falham.

- [ ] **Step 3: Implementar as funções**

Inserir logo abaixo de `spec_lines() { … }`:

```bash
# --- Coleta para os sensores ------------------------------------------------
# Todas comparam SNAPSHOT × SPEC — nunca contra HEAD. Sob --allow-dirty o spec
# chega com trabalho alheio já dentro, e o que se quer medir é o que ESTA rodada
# escreveu. Puras no sentido que importa: mesmos dois arquivos, mesma saída, sem
# estado global e sem custo. Nesta fase NENHUMA delas decide parada — só narram
# (R-04/R-05); quem as liga é a Fase 2.
# O `return 0` explícito não é enfeite: `diff` sai 1 quando os arquivos diferem
# e `grep -c` sai 1 quando conta zero, e nenhum dos dois é erro aqui.

diff_numstat() {  # snapshot spec → "add del", sempre duas colunas
  diff -- "${1:-}" "${2:-}" \
    | awk '/^>/ { a++ } /^</ { d++ } END { printf "%d %d", a + 0, d + 0 }'
  return 0
}

added_lines() {  # snapshot spec → as linhas adicionadas, sem o "> " do diff
  diff -- "${1:-}" "${2:-}" | grep '^>' | cut -c3-
  return 0
}

added_fences() {  # snapshot spec → nº de LINHAS de cerca criadas
  # Linhas, não blocos: um bloco completo soma 2. O sensor de deriva quer o
  # volume de código enfiado no spec, e meio bloco também é sintoma.
  added_lines "${1:-}" "${2:-}" | grep -c '^```'
  return 0
}

headings_of() {  # arquivo → seus títulos markdown, um por linha
  grep -E '^#{1,6}[[:space:]]' "${1:-}" 2>/dev/null
  return 0
}

new_headings() {  # snapshot spec → nº de títulos que só existem no spec
  comm -13 <(headings_of "${1:-}" | sort) <(headings_of "${2:-}" | sort) \
    | wc -l | tr -d ' '
  return 0
}

touched_sections() {  # snapshot spec → seções que receberam linha, na ordem
  # O formato de diff abaixo devolve os números de linha do arquivo NOVO; o awk
  # faz fill-down do título e atribui cada linha mudada ao título acima dela.
  # Seção que só PERDEU linha não aparece: é o preço de atribuir toda mudança a
  # um título que ainda existe, e é o comportamento que o sensor de escopo quer.
  local nums
  nums="$(diff --unchanged-line-format='' --old-line-format='' \
               --new-line-format='%dn
' -- "${1:-}" "${2:-}")"
  [ -n "$nums" ] || return 0
  awk -v nums="$nums" '
    BEGIN { n = split(nums, a, "\n"); for (i = 1; i <= n; i++) if (a[i] != "") want[a[i]] = 1 }
    /^#+[[:space:]]/ { sec = $0 }
    want[FNR] { s = (sec == "" ? "(preâmbulo)" : sec); if (!seen[s]++) order[++k] = s }
    END { for (i = 1; i <= k; i++) print order[i] }
  ' < "${2:-}"
  return 0
}

count_markers() {  # arquivo → nº de ocorrências de [NEEDS CLARIFICATION]
  # Contabilidade do próprio Spec Kit, não heurística de prosa. Conta OCORRÊNCIA
  # e não linha: dois marcadores na mesma linha são duas lacunas.
  grep -oF '[NEEDS CLARIFICATION]' "${1:-}" 2>/dev/null | wc -l | tr -d ' '
  return 0
}
```

- [ ] **Step 4: Acrescentar as dependências novas**

Em `need_deps`, trocar a linha do `for` por:

```bash
  for c in claude jq git mkfifo awk tail timeout fold sed comm sort diff cut cp; do
```

(`comm sort diff cut` entram pela coleta; `cp` entra pelo snapshot da Task 8.
`date` e `ln`, usados no R-01, ficam de fora pela mesma razão que `mkdir`, `rm`
e `wc` sempre estiveram: são o núcleo do coreutils que o script já presume.)

- [ ] **Step 5: Rodar para ver passar**

Run: `bash tools/speckit-clarify-loop --self-test | tail -1`
Expected: `speckit-clarify-loop: self-test limpo (104 casos)`.

- [ ] **Step 6: Conferir contra o `git diff --stat`, que é o critério de aceitação**

```bash
cd /tmp/skcl-harness/repo 2>/dev/null || ./tools/speckit-clarify-loop-harness.sh --max-rounds 1 >/dev/null 2>&1
cd /home/tuyoshi/projects/personal/zion-build-prd
cp /tmp/skcl-harness/repo/specs/001-fake/spec.md /tmp/skcl-snap.md
printf '\n## Extra\n\nlinha nova\n' >> /tmp/skcl-harness/repo/specs/001-fake/spec.md
bash -c 'source <(sed -n "/^diff_numstat()/,/^}/p" tools/speckit-clarify-loop); diff_numstat /tmp/skcl-snap.md /tmp/skcl-harness/repo/specs/001-fake/spec.md; echo'
git diff --numstat --no-index -- /tmp/skcl-snap.md /tmp/skcl-harness/repo/specs/001-fake/spec.md
rm -f /tmp/skcl-snap.md
```
Expected: `4 0` da função e `4	0	…` do git — os mesmos dois números.

- [ ] **Step 7: Commit**

```bash
git add tools/speckit-clarify-loop
git commit -m "feat(tools): coleta de sensores contra o snapshot da rodada"
```

---

### Task 8: R-05 e R-04 — o custo por linha e a linha de sensores (parte pura)

Formatação e aritmética primeiro, ainda sem tocar o `main_loop`. `custo/linha` é **narrado, nunca ligado** — R-25 decide na Fase 5 se ele vira sensor.

**Files:**
- Modify: `tools/speckit-clarify-loop` — duas funções puras logo abaixo de `count_markers`; 5 asserções no `self_test`.

**Interfaces:**
- Consumes: nada das tasks anteriores (é aritmética e `printf`).
- Produces:
  - `cost_per_line custo add del` → `US$` por linha mexida com 6 casas, ou `-` se `add+del == 0`
  - `sensor_line add del marc_antes marc_depois secoes cercas titulos custo` → a linha única de narração

- [ ] **Step 1: Escrever as asserções que falham**

No `self_test`, logo depois do bloco de coleta da Task 7:

```bash
  assert_out "custo por linha divide pelo total mexido" '0.025000' cost_per_line 0.5 12 8
  assert_out "rodada sem mudança não divide por zero"   '-'        cost_per_line 0.5 0 0
  assert_out "custo zero continua número"               '0.000000' cost_per_line 0 3 0
  assert_out "linha de sensores é uma só, em chave=valor" \
    'sensores · add=12 del=8 marc=4→2 secoes=2 cercas=1 titulos=0 custo=0.5 custo/linha=0.025000' \
    sensor_line 12 8 4 2 2 1 0 0.5
  assert_out "rodada estéril mostra o traço no custo/linha" \
    'sensores · add=0 del=0 marc=0→0 secoes=0 cercas=0 titulos=0 custo=0.1 custo/linha=-' \
    sensor_line 0 0 0 0 0 0 0 0.1
```

- [ ] **Step 2: Rodar para ver falhar**

Run: `bash tools/speckit-clarify-loop --self-test 2>&1 | grep -c FALHOU`
Expected: `5`.

- [ ] **Step 3: Implementar**

Inserir logo abaixo de `count_markers`:

```bash
# --- Sensores: aritmética e formatação (funções puras) ----------------------
cost_per_line() {  # custo add del → US$ por linha mexida, ou '-' se nada mudou
  # Denominador é add+del: reescrever um requisito é trabalho tanto quanto
  # acrescentar um. Rodada que não mexeu em linha nenhuma não tem custo por
  # linha — tem custo, e o traço diz isso sem fingir um número.
  awk -v c="${1:-0}" -v a="${2:-0}" -v d="${3:-0}" \
    'BEGIN { n = a + d; if (n <= 0) printf "-"; else printf "%.6f", c / n }'
  return 0
}

# Uma linha por rodada, chave=valor em ASCII, para que a calibração da Fase 5
# monte a tabela com um grep nos round-NN.log. NARRADA, nunca ligada: nesta fase
# nenhum destes números decide parada (R-05, R-25).
sensor_line() {  # add del marc_antes marc_depois secoes cercas titulos custo → linha
  printf 'sensores · add=%s del=%s marc=%s→%s secoes=%s cercas=%s titulos=%s custo=%s custo/linha=%s' \
    "${1:-0}" "${2:-0}" "${3:-0}" "${4:-0}" "${5:-0}" "${6:-0}" "${7:-0}" "${8:-0}" \
    "$(cost_per_line "${8:-0}" "${1:-0}" "${2:-0}")"
  return 0
}
```

- [ ] **Step 4: Rodar para ver passar**

Run: `bash tools/speckit-clarify-loop --self-test | tail -1`
Expected: `speckit-clarify-loop: self-test limpo (109 casos)`.

- [ ] **Step 5: Commit**

```bash
git add tools/speckit-clarify-loop
git commit -m "feat(tools): custo por linha e linha de sensores como funções puras"
```

---

### Task 9: R-02 e R-04 — snapshot da rodada e narração em toda rodada

Agora a cola: cada rodada tira um snapshot antes de rodar e narra a linha de sensores depois, via `emit_note ok` — que escreve no `round-NN.log` mesmo sob `--quiet`.

**Files:**
- Modify: `tools/speckit-clarify-loop` — `narrate_sensors` nova; `main_loop` (declaração de `snap`, `cp` antes da rodada, chamada depois).

**Interfaces:**
- Consumes: `diff_numstat`, `touched_sections`, `count_markers`, `added_fences`, `new_headings` (Task 7); `sensor_line` (Task 8); `emit_note` (existente).
- Produces: `narrate_sensors snapshot spec custo` → emite a linha de sensores; sem valor de retorno útil. A Fase 2 (S-5) a absorve em `assess_round`.

- [ ] **Step 1: Implementar a cola**

Inserir logo abaixo de `sensor_line`:

```bash
# --- Sensores: coleta e narração (impura) -----------------------------------
# Junta a coleta, o custo da rodada e a formatação numa linha só, emitida por
# emit_note ok — que escreve no round-NN.log mesmo sob --quiet, que é o que o
# R-04 exige. A Fase 2 transforma isto em `assess_round`, acrescentando a
# avaliação e devolvendo por STOP_KIND/STOP_WHY; por ora só narra.
narrate_sensors() {  # snapshot spec custo
  local snap="${1:-}" spec="${2:-}" cost="${3:-0}"
  local nums add del secs n_secs
  nums="$(diff_numstat "$snap" "$spec")"
  add="${nums%% *}"
  del="${nums##* }"
  secs="$(touched_sections "$snap" "$spec")"
  if [ -z "$secs" ]; then
    n_secs=0
  else
    n_secs="$(printf '%s\n' "$secs" | wc -l | tr -d ' ')"
  fi
  emit_note ok "$(sensor_line "$add" "$del" \
    "$(count_markers "$snap")" "$(count_markers "$spec")" \
    "$n_secs" "$(added_fences "$snap" "$spec")" \
    "$(new_headings "$snap" "$spec")" "$cost")"
  return 0
}
```

- [ ] **Step 2: Declarar `snap` no `main_loop`**

Trocar

```bash
  local start_lines end_lines delta tag rule_pad
```

por

```bash
  local start_lines end_lines delta tag rule_pad snap
```

- [ ] **Step 3: Tirar o snapshot antes da rodada**

No `main_loop`, logo depois de `prev_hash="$(spec_hash)"`, inserir:

```bash
    # Snapshot da rodada: toda medição é snapshot × spec, nunca contra HEAD.
    # Vive no $WORK, que o trap de saída já limpa.
    snap="$WORK/snap-$tag.md"
    cp -- "$SPEC" "$snap" || die "não consegui copiar o spec para $snap"
```

- [ ] **Step 4: Narrar depois da rodada**

Logo depois da linha existente

```bash
    emit_note ok "$(printf '%s · %d yes · US$ %s' "$ROUND_OUTCOME" "$ROUND_YES" "$ROUND_COST")"
```

inserir:

```bash
    narrate_sensors "$snap" "$SPEC" "$ROUND_COST"
```

- [ ] **Step 5: Verificar que a linha aparece em toda rodada**

```bash
bash -n tools/speckit-clarify-loop
./tools/speckit-clarify-loop-harness.sh --max-rounds 2 | grep 'sensores ·'
```
Expected: duas linhas, a primeira com `add=4 del=0` (a rodada escreveu as 4 linhas
do `## Clarifications`) e ambas com `custo=0.25` e `custo/linha=0.062500`.

- [ ] **Step 6: Verificar que sobrevive ao `--quiet` (critério de aceitação do R-04)**

```bash
./tools/speckit-clarify-loop-harness.sh --max-rounds 1 --quiet | grep -c 'sensores ·'
grep -c 'sensores ·' /tmp/speckit-clarify-loop/latest/round-01.log
```
Expected: `0` na tela e `1` no log — a narração cala, a memória não.

- [ ] **Step 7: Verificar que o `--dry-run` continua com `delta +0` (critério do R-02)**

```bash
./tools/speckit-clarify-loop-harness.sh --dry-run | grep -E 'delta|sensores|parada'
```
Expected: `sensores · add=0 del=0 … custo/linha=-`, `delta +0` e
`parada:   --dry-run: 1 pergunta classificada, nada gravado`.

- [ ] **Step 8: Suíte**

Run: `bash tools/speckit-clarify-loop --self-test | tail -1`
Expected: `speckit-clarify-loop: self-test limpo (109 casos)`.

- [ ] **Step 9: Commit**

```bash
git add tools/speckit-clarify-loop
git commit -m "feat(tools): snapshot por rodada e narração dos sensores"
```

---

### Task 10: S-3 — colapsar a família `SIG_*` em quatro sinais

Fim da Fase 0, começo da Fase 1. Seis constantes de pergunta com a mesma forma viram uma; `has_sig` sai.

**Files:**
- Modify: `tools/speckit-clarify-loop` — bloco de constantes `SIG_*`, `has_sig` (apagada), `classify`.

**Interfaces:**
- Produces: `SIG_DRY_RE`, `SIG_COMPLETE_RE`, `SIG_NEXT_RE` (inalterada), `SIG_ASK_RE`. Única função de casamento: `has_re texto regex`.

- [ ] **Step 1: Trocar o par seco**

Substituir

```bash
SIG_DRY='No critical ambiguities detected'
SIG_DRY_PT='Nenhuma ambiguidade crítica detectada'
```

por

```bash
SIG_DRY_RE='No critical ambiguities detected|Nenhuma ambiguidade crítica detectada'
```

- [ ] **Step 2: Trocar o par de fecho**

Substituir

```bash
SIG_COMPLETE='Suggested next command'
SIG_COMPLETE_PT='Próximo comando sugerido'
```

por

```bash
# O fecho por frase fixa continua SEPARADO do SIG_NEXT_RE, e sem âncora: esta
# frase aparece no meio do parágrafo do report, enquanto a do SIG_NEXT_RE só
# vale ancorada depois de `#` ou `**`. Fundir os dois devolveria ao sinal o
# risco de casar prosa que a âncora existe para evitar.
SIG_COMPLETE_RE='Suggested next command|Próximo comando sugerido'
```

- [ ] **Step 3: Trocar os seis marcadores de pergunta**

Substituir

```bash
SIG_MC='**Recommended:'
SIG_MC_PT='**Recomendado:'
SIG_MC_PT_F='**Recomendada:'
SIG_SHORT='**Suggested:'
SIG_SHORT_PT='**Sugerido:'
SIG_SHORT_PT_F='**Sugerida:'
```

por

```bash
# Os seis marcadores de pergunta tinham todos a mesma forma — `**`, o adjetivo,
# `:` — em duas línguas e duas flexões. Uma alternância diz o mesmo e não deixa
# vaga aberta para uma sétima constante.
SIG_ASK_RE='\*\*(Recomendad[oa]|Sugerid[oa]|Recommended|Suggested):'
```

- [ ] **Step 4: Apagar `has_sig` e reescrever `classify`**

Remover a função `has_sig` inteira. Substituir o corpo de `classify` por:

```bash
classify() {  # texto do turno em $1 → rótulo em stdout
  local txt="${1:-}"
  if has_re "$txt" "$SIG_DRY_RE"; then
    printf 'loop-seco\n'
  elif has_re "$txt" "$SIG_COMPLETE_RE" || has_re "$txt" "$SIG_NEXT_RE"; then
    printf 'rodada-completa\n'
  elif has_re "$txt" "$SIG_ASK_RE"; then
    printf 'pergunta-pendente\n'
  else
    printf 'indeterminada\n'
  fi
}
```

- [ ] **Step 5: Conferir que nenhuma constante velha sobrou**

Run: `grep -nE 'SIG_(MC|SHORT|DRY|COMPLETE)(_PT)?(_F)?=|has_sig' tools/speckit-clarify-loop`
Expected: nenhuma saída.

- [ ] **Step 6: Rodar a suíte — ela é o teste desta task**

Run: `bash tools/speckit-clarify-loop --self-test | tail -1`
Expected: `speckit-clarify-loop: self-test limpo (109 casos)`. As 21 asserções de
classificação, incluindo as duas flexões em pt e as duas guardas de âncora,
passam sem nenhuma mudança — é isso que prova que a alternância diz o mesmo que
as seis constantes.

- [ ] **Step 7: Commit**

```bash
git add tools/speckit-clarify-loop
git commit -m "refactor(tools): colapsar a família SIG_* em quatro sinais"
```

---

### Task 11: R-07, R-08, R-10, S-4 — a sentinela vira o contrato, a heurística vira fallback

A classe de bug mais cara do histórico do arquivo: sete comentários datados, mais de US$ 20 em rodadas boas descartadas por variação de prosa.

**Files:**
- Modify: `tools/speckit-clarify-loop` — `SENTINEL_PROMPT` e `read_sentinel` novos; `classify` ganha o caminho da sentinela; `args` de `run_round` ganha `--append-system-prompt`; 8 fixtures e 15 asserções no `self_test`; comentário do S-4.

**Interfaces:**
- Consumes: `has_re`, `SIG_*_RE` (Task 10).
- Produces:
  - `SENTINEL_PROMPT` — texto do contrato, constante do script
  - `read_sentinel texto` → `ASKING|COMPLETE|NO_AMBIGUITY`, ou vazio se ausente
  - `classify` inalterada na assinatura (texto → rótulo), com a sentinela na frente da heurística

- [ ] **Step 1: Escrever as fixtures**

Inserir logo depois de `FIX_PROSE_RECOMMEND`:

```bash
# --- Fixtures da sentinela --------------------------------------------------
FIX_SENT_ASK="$(cat <<'EOF'
**Recomendada:** Opção A — texto da pergunta.

CLARIFY_STATE: ASKING
EOF
)"

FIX_SENT_COMPLETE="$(cat <<'EOF'
## Relatório

Nada Deferred nem Outstanding.

CLARIFY_STATE: COMPLETE
EOF
)"

FIX_SENT_DRY="$(cat <<'EOF'
Li o spec inteiro e não há ambiguidade que justifique perguntar.

CLARIFY_STATE: NO_AMBIGUITY
EOF
)"

# A sentinela VENCE a heurística: este turno traz o marcador de pergunta e a
# sentinela de fim. Se um dia divergirem, quem manda é o contrato — a heurística
# só existe para o caso em que o contrato não veio.
FIX_SENT_VS_HEUR="$(cat <<'EOF'
**Recomendada:** Opção A — texto da pergunta.

CLARIFY_STATE: COMPLETE
EOF
)"

# Os três reversos, que é onde a âncora `^…$` ganha o seu sustento: sentinela
# citada em prosa, embrulhada em crase, e com valor fora dos três aceitos. Nos
# três o turno é PERGUNTA, e ler qualquer um deles como fim descartaria a rodada.
FIX_SENT_PROSA="$(cat <<'EOF'
Vou fechar cada turno com CLARIFY_STATE: COMPLETE na última linha, como pedido.

**Recomendada:** Opção A — texto da pergunta.
EOF
)"

FIX_SENT_CRASE="$(cat <<'EOF'
**Recomendada:** Opção A — texto da pergunta.

`CLARIFY_STATE: COMPLETE`
EOF
)"

FIX_SENT_INVALIDA="$(cat <<'EOF'
**Recomendada:** Opção A — texto da pergunta.

CLARIFY_STATE: TALVEZ
EOF
)"

FIX_SENT_DUAS="$(cat <<'EOF'
CLARIFY_STATE: ASKING

Corrigindo: era o fim da rodada, não uma pergunta.

CLARIFY_STATE: COMPLETE
EOF
)"
```

- [ ] **Step 2: Escrever as asserções que falham**

No `self_test`, logo depois do bloco de classificação existente:

```bash
  assert_out "sentinela ASKING é lida"           'ASKING'       read_sentinel "$FIX_SENT_ASK"
  assert_out "sentinela COMPLETE é lida"         'COMPLETE'     read_sentinel "$FIX_SENT_COMPLETE"
  assert_out "sentinela NO_AMBIGUITY é lida"     'NO_AMBIGUITY' read_sentinel "$FIX_SENT_DRY"
  assert_out "sentinela em prosa não conta"      ''             read_sentinel "$FIX_SENT_PROSA"
  assert_out "sentinela em crase não conta"      ''             read_sentinel "$FIX_SENT_CRASE"
  assert_out "valor desconhecido não é sentinela" ''            read_sentinel "$FIX_SENT_INVALIDA"
  assert_out "turno sem sentinela devolve vazio" ''             read_sentinel "$FIX_MC"
  assert_out "duas sentinelas: a última vence"   'COMPLETE'     read_sentinel "$FIX_SENT_DUAS"

  assert_out "ASKING vira pergunta-pendente"     pergunta-pendente classify "$FIX_SENT_ASK"
  assert_out "COMPLETE vira rodada-completa"     rodada-completa   classify "$FIX_SENT_COMPLETE"
  assert_out "NO_AMBIGUITY vira loop-seco"       loop-seco         classify "$FIX_SENT_DRY"
  assert_out "a sentinela vence a heurística"    rodada-completa   classify "$FIX_SENT_VS_HEUR"
  assert_out "sentinela em prosa cai na heurística"     pergunta-pendente classify "$FIX_SENT_PROSA"
  assert_out "sentinela em crase cai na heurística"     pergunta-pendente classify "$FIX_SENT_CRASE"
  assert_out "valor desconhecido cai na heurística"     pergunta-pendente classify "$FIX_SENT_INVALIDA"
```

- [ ] **Step 3: Rodar para ver falhar**

Run: `bash tools/speckit-clarify-loop --self-test 2>&1 | grep -c FALHOU`
Expected: `7`, com esta divisão:
- `read_sentinel` não existe e devolve vazio: falham as 4 que esperam um valor
  (`ASKING`, `COMPLETE`, `NO_AMBIGUITY`, `duas sentinelas`); as 4 que esperam
  `''` passam por acidente.
- `classify` ainda só tem a heurística: falham as 3 que dependem da sentinela
  (`COMPLETE`, `NO_AMBIGUITY`, `a sentinela vence a heurística`); as 4 de prosa,
  crase, valor inválido e `ASKING` já dão o rótulo certo pela heurística — e é
  exatamente isso que elas existem para travar.

Se o número vier diferente, leia as descrições que falharam antes de seguir: o
que interessa é que `ASKING/COMPLETE/NO_AMBIGUITY` ainda não mapeiam.

- [ ] **Step 4: Implementar o contrato**

Inserir logo **antes** do bloco de constantes `SIG_*` (isto é, antes do comentário
`# --- Classificação do turno`):

```bash
# --- Contrato de saída ------------------------------------------------------
# Sete comentários datados neste arquivo, todos da mesma classe de bug: a skill
# variou a prosa do fecho e o classificador jogou fora uma rodada boa e paga
# (mais de US$ 20 só nas capturas de 2026-07-21). Adivinhar prosa não escala. A
# sentinela é o contrário: uma linha que o script PEDE, que não depende de
# língua, de flexão nem do template do momento.
#
# Vai INLINE no --append-system-prompt, e não no --append-system-prompt-file: o
# texto fica ao lado do classify que o lê, e a rodada não ganha um arquivo
# temporário no $WORK como segundo ponto de falha no arranque. E é --append, e
# não --system-prompt: o prompt de sistema da skill continua inteiro.
#
# A linha aparece na narração, e fica. Filtrá-la exigiria um segundo caminho de
# renderização no ramo `text` do render_line; custa uma linha por turno e é a
# prova visual de que o contrato está de pé.
SENTINEL_PROMPT="$(cat <<'EOF'
Ao final de CADA turno seu, emita como ÚLTIMA LINHA da mensagem, sozinha:

CLARIFY_STATE: ASKING

Use exatamente um destes três valores:
- ASKING       você apresentou uma pergunta de clarificação e aguarda resposta
- COMPLETE     você encerrou a rodada e apresentou o relatório final
- NO_AMBIGUITY você não encontrou ambiguidade crítica que justifique perguntar

Essa linha é lida por um script. Não a traduza, não a formate, não a envolva em
crase, negrito ou bloco de código, e não escreva nada depois dela.
EOF
)"

read_sentinel() {  # texto → ASKING|COMPLETE|NO_AMBIGUITY, ou vazio se ausente
  # Âncora `^…$`: sentinela citada em prosa ou embrulhada em crase não conta —
  # e o modelo cita a própria sentinela ao confirmar que entendeu a instrução.
  # `tail -n 1`: se o turno emitir duas, a última vence, que é a que fecha.
  printf '%s' "${1:-}" \
    | grep -oE '^CLARIFY_STATE: (ASKING|COMPLETE|NO_AMBIGUITY)$' \
    | tail -n 1 | sed 's/^CLARIFY_STATE: //'
  return 0
}
```

- [ ] **Step 5: Pôr a sentinela na frente da heurística, dentro de `classify`**

Substituir o corpo de `classify` por:

```bash
classify() {  # texto do turno em $1 → rótulo em stdout
  local txt="${1:-}"
  case "$(read_sentinel "$txt")" in
    ASKING)       printf 'pergunta-pendente\n'; return 0 ;;
    COMPLETE)     printf 'rodada-completa\n';   return 0 ;;
    NO_AMBIGUITY) printf 'loop-seco\n';         return 0 ;;
  esac
  # Sem sentinela, decide a heurística de prosa — inalterada, com as duas
  # línguas e as duas flexões. Ela NÃO sai: o contrato depende de o modelo
  # obedecer, e uma rodada paga não pode depender só disso.
  if has_re "$txt" "$SIG_DRY_RE"; then
    printf 'loop-seco\n'
  elif has_re "$txt" "$SIG_COMPLETE_RE" || has_re "$txt" "$SIG_NEXT_RE"; then
    printf 'rodada-completa\n'
  elif has_re "$txt" "$SIG_ASK_RE"; then
    printf 'pergunta-pendente\n'
  else
    printf 'indeterminada\n'
  fi
}
```

- [ ] **Step 6: Passar o contrato ao `claude`**

Em `run_round`, no array `args`, acrescentar uma linha depois do `--allowedTools`:

```bash
  local -a args=(
    -p
    --input-format stream-json
    --output-format stream-json
    --verbose
    --permission-mode acceptEdits
    --allowedTools 'Bash(.specify/scripts/bash/check-prerequisites.sh*)'
    --append-system-prompt "$SENTINEL_PROMPT"
  )
```

- [ ] **Step 7: Registrar o congelamento da heurística (S-4)**

Inserir logo acima da linha `SIG_DRY_RE=…`:

```bash
# S-4 — HEURÍSTICA CONGELADA. Depois que o resumo mostrar `sentinela em M/M
# turnos` em 5 execuções reais seguidas, NENHUMA alternância nova entra aqui.
# Falha de classificação passa a ser bug do contrato de saída, e o remédio é o
# SENTINEL_PROMPT — não uma sétima captura de prosa. É a regra que impede este
# arquivo de acumular outros sete comentários datados de US$.
```

- [ ] **Step 8: Rodar para ver passar**

Run: `bash tools/speckit-clarify-loop --self-test | tail -1`
Expected: `speckit-clarify-loop: self-test limpo (124 casos)`.

- [ ] **Step 9: Verificar de ponta a ponta que a sentinela decide**

```bash
bash -n tools/speckit-clarify-loop
./tools/speckit-clarify-loop-harness.sh --max-rounds 1 | grep -E 'rodada-completa|parada'
grep -c 'CLARIFY_STATE' /tmp/speckit-clarify-loop/latest/round-01.log
```
Expected: a rodada fecha em `rodada-completa`, e o `grep -c` devolve `2` — uma
linha de sentinela por turno narrado. Ela **aparece** na narração de propósito
(E-2): filtrá-la exigiria um segundo caminho de renderização, e enquanto o S-4
não fecha ela é a prova visual de que o contrato está de pé.

- [ ] **Step 10: Commit**

```bash
git add tools/speckit-clarify-loop
git commit -m "feat(tools): sentinela de estado como contrato de saída da rodada"
```

---

### Task 12: R-09 — ausência narrada, repetição alarmada, rodada intacta

Por P-1: abortar por sentinela ausente descartaria rodada paga, que é exatamente a classe de bug que a Fase 1 existe para matar. O sinal fica visível, sem poder de veto — nenhum `rc` novo nasce daqui (D-2).

**Files:**
- Modify: `tools/speckit-clarify-loop` — `sentinel_note` nova; contadores em `run_round`; acumulação e linha de resumo no `main_loop`; 4 asserções.

**Interfaces:**
- Consumes: `read_sentinel` (Task 11), `emit_note` (existente).
- Produces:
  - `sentinel_note streak` → texto do aviso, ou vazio se `streak` for 0
  - globais `ROUND_TURNS`, `ROUND_SENT`, `SENT_MISS`, zeradas por rodada como os demais `ROUND_*`

- [ ] **Step 1: Escrever as asserções que falham**

No `self_test`, logo depois do bloco da sentinela:

```bash
  assert_out "sem ausência não há aviso" '' sentinel_note 0
  assert_out "uma ausência é só nota" \
    'turno sem sentinela — classificando pela heurística' \
    sentinel_note 1
  assert_out "duas ausências viram alarme" \
    'contrato de saída quebrado: 2 turnos seguidos sem sentinela — heurística no comando' \
    sentinel_note 2
  assert_out "três ausências seguem no alarme" \
    'contrato de saída quebrado: 3 turnos seguidos sem sentinela — heurística no comando' \
    sentinel_note 3
```

- [ ] **Step 2: Rodar para ver falhar**

Run: `bash tools/speckit-clarify-loop --self-test 2>&1 | grep -c FALHOU`
Expected: `3` (a de `sentinel_note 0` já espera vazio e passa por acidente; as
outras três falham).

- [ ] **Step 3: Implementar a função pura**

Inserir logo abaixo de `read_sentinel`:

```bash
# Aviso de contrato quebrado. Puro: entra a sequência de ausências, sai o texto.
# Ausência NÃO para a rodada, e não ganha `rc` próprio: abortar aqui descartaria
# a rodada paga, que é a classe de bug que a sentinela existe para matar (P-1).
# O sinal fica visível — poder de veto ele não tem.
sentinel_note() {  # nº de turnos consecutivos sem sentinela → aviso, ou vazio
  case "${1:-0}" in
    0|'') : ;;
    1) printf 'turno sem sentinela — classificando pela heurística' ;;
    *) printf 'contrato de saída quebrado: %s turnos seguidos sem sentinela — heurística no comando' "$1" ;;
  esac
  return 0
}
```

- [ ] **Step 4: Declarar e zerar os contadores em `run_round`**

Trocar o bloco de globais da rodada

```bash
ROUND_OUTCOME=""
ROUND_YES=0
ROUND_COST=0
ROUND_ABORT=""
```

por

```bash
ROUND_OUTCOME=""
ROUND_YES=0
ROUND_COST=0
ROUND_ABORT=""
# Contabilidade do contrato de saída: turnos classificados na rodada, quantos
# traziam a sentinela, e a sequência corrente de ausências.
ROUND_TURNS=0
ROUND_SENT=0
SENT_MISS=0
```

E, dentro de `run_round`, trocar a linha de reset

```bash
  ROUND_OUTCOME=""; ROUND_YES=0; ROUND_COST=0; ROUND_ABORT=""
```

por

```bash
  ROUND_OUTCOME=""; ROUND_YES=0; ROUND_COST=0; ROUND_ABORT=""
  ROUND_TURNS=0; ROUND_SENT=0; SENT_MISS=0
```

- [ ] **Step 5: Contar no turno**

Em `run_round`, logo depois de

```bash
    txt="$(printf '%s' "$line" | jq -r '.result // ""')"
```

inserir:

```bash
    ROUND_TURNS=$((ROUND_TURNS + 1))
    if [ -n "$(read_sentinel "$txt")" ]; then
      ROUND_SENT=$((ROUND_SENT + 1)); SENT_MISS=0
    else
      SENT_MISS=$((SENT_MISS + 1))
      emit_note warn "$(sentinel_note "$SENT_MISS")"
    fi
```

- [ ] **Step 6: Acumular e reportar no `main_loop`**

Trocar

```bash
  local total_yes=0 total_cost=0 yes_log="" stop_reason="" rc=1
```

por

```bash
  local total_yes=0 total_cost=0 yes_log="" stop_reason="" rc=1
  local total_turns=0 total_sent=0
```

Logo depois de `total_cost="$(add_cost "$total_cost" "$ROUND_COST")"`, inserir:

```bash
    total_turns=$((total_turns + ROUND_TURNS))
    total_sent=$((total_sent + ROUND_SENT))
```

E, no resumo, logo depois da linha `printf 'custo:    US$ %s\n' "$total_cost"`:

```bash
  printf 'contrato: sentinela em %s/%s turnos\n' "$total_sent" "$total_turns"
```

- [ ] **Step 7: Rodar para ver passar**

Run: `bash tools/speckit-clarify-loop --self-test | tail -1`
Expected: `speckit-clarify-loop: self-test limpo (128 casos)`.

- [ ] **Step 8: Verificar os dois mundos de ponta a ponta**

```bash
bash -n tools/speckit-clarify-loop
./tools/speckit-clarify-loop-harness.sh --max-rounds 1 > /tmp/skcl-com.txt 2>&1; echo "rc=$?"
grep -E '^contrato:|^parada:' /tmp/skcl-com.txt
SKCL_NOSENT=1 ./tools/speckit-clarify-loop-harness.sh --max-rounds 1 > /tmp/skcl-sem.txt 2>&1; echo "rc=$?"
grep -E '^contrato:|^parada:|contrato de saída quebrado|turno sem sentinela' /tmp/skcl-sem.txt
```

Expected:
- com sentinela: `rc=1`, `contrato: sentinela em 2/2 turnos`, `parada:   teto de rodadas atingido (1) sem convergir`
- sem sentinela: `rc=1` (o **mesmo** `rc`), `contrato: sentinela em 0/2 turnos`, o mesmo `parada:`, mais a nota do 1º miss e o alarme `contrato de saída quebrado: 2 turnos seguidos…`

O `rc` e o motivo de parada idênticos nos dois casos são o critério do D-2: o
contrato quebrado é visível e não vota.

- [ ] **Step 9: Commit**

```bash
git add tools/speckit-clarify-loop
git commit -m "feat(tools): narrar a ausência de sentinela sem abortar a rodada"
```

---

### Task 13: M-06, M-07 e M-12 — a guarda de vazamento

A Fase 1 pede ao modelo que escreva uma linha de controle. O risco que ela cria
é o modelo escrever essa linha **dentro do spec**. Enquanto a guarda não existir,
o vazamento é silencioso — é por isso que ela vem no mesmo plano da Fase 1, e não
num plano de mitigação depois (D-4).

**Abortar, não limpar.** Limpeza silenciosa esconderia que o contrato falhou.

**Files:**
- Modify: `tools/speckit-clarify-loop` — `leaked_sentinel` nova; shim `leak_str` ao lado do `fatal_str`; frase nova no `SENTINEL_PROMPT`; guarda no `main_loop`; 5 fixtures de arquivo e 4 asserções no `self_test`.

**Interfaces:**
- Consumes: `added_lines snapshot spec` (Task 7), `SENTINEL_PROMPT` (Task 11), a variável `snap` do `main_loop` (Task 9), `emit_note` (existente).
- Produces:
  - `leaked_sentinel snapshot spec` → **status** 0 se alguma linha *adicionada* começa com `CLARIFY_`
  - `leak_str snapshot spec` → `sim|nao` (adaptador de teste, irmão do `fatal_str`)

- [ ] **Step 1: Escrever as fixtures de arquivo**

No `self_test`, logo depois da montagem de `$st_new` (Task 7), acrescentar:

```bash
  # Fixtures da guarda de vazamento (M-06/D-5). Todas derivam de $st_new, para
  # que a única diferença entre elas seja o que se quer medir.
  local st_leak st_dec st_prosa st_cita st_cita2
  st_leak="$st_dir/leak.md"; st_dec="$st_dir/dec.md"; st_prosa="$st_dir/prosa.md"
  st_cita="$st_dir/cita.md"; st_cita2="$st_dir/cita2.md"
  cp -- "$st_new" "$st_leak"
  printf 'CLARIFY_STATE: COMPLETE\n' >> "$st_leak"
  cp -- "$st_new" "$st_dec"
  printf 'CLARIFY_DECISION: assunto -> A\n' >> "$st_dec"
  cp -- "$st_new" "$st_prosa"
  printf 'A skill fecha o turno com CLARIFY_STATE: COMPLETE na última linha.\n' >> "$st_prosa"
  # D-5: o spec que DOCUMENTA o contrato. A ocorrência está dentro de uma cerca,
  # e dentro de uma cerca a linha ESTÁ no começo da linha — a âncora `^` não
  # protege nada. O que protege é comparar só o que a rodada adicionou.
  cp -- "$st_new" "$st_cita"
  printf '\n## Contrato\n\n```\nCLARIFY_STATE: ASKING\n```\n' >> "$st_cita"
  cp -- "$st_cita" "$st_cita2"
  printf '\n- RF-03 mais um requisito\n' >> "$st_cita2"
```

- [ ] **Step 2: Escrever as asserções que falham**

No `self_test`, logo depois do bloco de `sentinel_note` da Task 12:

```bash
  assert_out "linha adicionada com a sentinela dispara a guarda" \
    sim leak_str "$st_new" "$st_leak"
  assert_out "CLARIFY_DECISION também dispara — a guarda vigia o prefixo inteiro" \
    sim leak_str "$st_new" "$st_dec"
  assert_out "a mesma string no meio de uma frase não dispara" \
    nao leak_str "$st_new" "$st_prosa"
  assert_out "ocorrência já presente no snapshot não dispara" \
    nao leak_str "$st_cita" "$st_cita2"
```

- [ ] **Step 3: Rodar para ver falhar**

Run: `bash tools/speckit-clarify-loop --self-test 2>&1 | grep -c FALHOU`
Expected: `4`. `leak_str` ainda não existe, então as quatro devolvem vazio — e
nenhuma das quatro espera vazio.

- [ ] **Step 4: Implementar a guarda**

Inserir logo abaixo de `sentinel_note`:

```bash
# Guarda de vazamento (M-06). Casa contra as linhas que ESTA rodada adicionou, e
# não contra o spec inteiro: um spec que documente o contrato — a spec desta
# própria evolução é o contra-exemplo — abortaria na rodada 1, e em toda rodada 1
# seguinte, sem saída a não ser editar o spec à mão (D-5). Dentro de uma cerca a
# linha ESTÁ no começo da linha, então a âncora `^` não protege ninguém; quem
# protege é o recorte em linha nova. Vazamento real é linha nova por definição.
#
# Vigia o prefixo `CLARIFY_` inteiro, e não só `CLARIFY_STATE`: o M-03 acrescenta
# uma segunda família ao contrato, e mais superfície é mais chance de vazar.
leaked_sentinel() {  # snapshot spec → 0 se alguma linha ADICIONADA começa com CLARIFY_
  added_lines "${1:-}" "${2:-}" | grep -q '^CLARIFY_'
}
```

E, logo abaixo de `fatal_str` (Task 2), o adaptador de teste:

```bash
# Terceiro adaptador da família: leaked_sentinel responde por status de saída, e
# assert_out só sabe comparar stdout.
leak_str() { if leaked_sentinel "${1:-}" "${2:-}"; then printf 'sim'; else printf 'nao'; fi; }
```

- [ ] **Step 5: Acrescentar a proibição ao contrato (M-07)**

No `SENTINEL_PROMPT` (Task 11), acrescentar um parágrafo ao fim do heredoc,
depois da linha `crase, negrito ou bloco de código, e não escreva nada depois dela.`:

```
Nunca escreva linhas começadas por CLARIFY_ dentro de nenhum arquivo; elas
pertencem apenas à sua mensagem.
```

A frase é escrita no plural e pelo **prefixo**, não pelo nome da linha, de
propósito: ela continua correta depois que o M-03 acrescentar a segunda família,
sem reescrita. M-07 é prevenção; o M-06 é a rede.

- [ ] **Step 6: Ligar a guarda no `main_loop`**

Logo depois de `run_round "$round"` — antes de qualquer contabilidade, para que o
rodapé da rodada já diga `aborto`:

```bash
    # M-06 — a rodada escreveu uma linha de controle dentro do spec. Aborta, não
    # limpa: limpeza silenciosa esconderia que o contrato de saída falhou. Narra
    # mesmo quando a rodada já abortou por outro motivo (o vazamento é
    # informação que o humano precisa ver), mas não sobrescreve a causa original.
    if leaked_sentinel "$snap" "$SPEC"; then
      emit_note warn 'sentinela vazou para dentro do spec — o contrato de saída falhou'
      if [ "$ROUND_OUTCOME" != aborto ]; then
        ROUND_OUTCOME=aborto
        ROUND_ABORT='sentinela vazou para dentro do spec'
      fi
    fi
```

Sai pelo `rc=1` que já existe. Quando o R-19 (plano 2) generalizar a comparação
de hash a todo caminho de aborto, este mesmo código passa a valer `rc=4` sem ser
tocado — a linha vazada é linha nova, então o spec foi alterado por construção.

- [ ] **Step 7: Rodar para ver passar**

Run: `bash tools/speckit-clarify-loop --self-test | tail -1`
Expected: `speckit-clarify-loop: self-test limpo (132 casos)`.

- [ ] **Step 8: Verificar os três cenários de ponta a ponta**

```bash
bash -n tools/speckit-clarify-loop
SKCL_LEAK=1 ./tools/speckit-clarify-loop-harness.sh --max-rounds 1 > /tmp/skcl-leak.txt 2>&1; echo "rc=$?"
grep -E 'vazou|^parada:' /tmp/skcl-leak.txt
SKCL_CITA=1 ./tools/speckit-clarify-loop-harness.sh --max-rounds 1 > /tmp/skcl-cita.txt 2>&1; echo "rc=$?"
grep -cE 'vazou' /tmp/skcl-cita.txt; grep -E '^parada:' /tmp/skcl-cita.txt
./tools/speckit-clarify-loop-harness.sh --max-rounds 1 | grep -cE 'vazou'
```

Expected:
- vazamento: `rc=1`, a linha `sentinela vazou para dentro do spec — o contrato de
  saída falhou` na narração, e
  `parada:   aborto na rodada 01 — sentinela vazou para dentro do spec`
- spec que **cita** a sentinela numa cerca: `rc=1`, `0` ocorrências de `vazou`, e
  `parada:   teto de rodadas atingido (1) sem convergir` — a execução foi até o
  fim, que é o critério do D-5
- execução normal: `0` ocorrências

Os dois primeiros saem com o mesmo `rc=1`, e é o `parada:` que os distingue: o
`rc` próprio para "spec alterado numa rodada abortada" é o `rc=4` do R-19, no
plano 2 (G3).

- [ ] **Step 9: Commit**

```bash
git add tools/speckit-clarify-loop
git commit -m "feat(tools): abortar quando a sentinela vaza para dentro do spec"
```

---

### Task 14: M-03, M-04 e M-12 — as decisões do modelo no resumo

Cada rodada são até 5 decisões de produto tomadas pelo modelo, e o teto de 3
rodadas do R-21 leva isso a 15 por execução. Ler o diff depois não acontece: um
diff de 200 linhas não convida ninguém. Quinze linhas se leem.

Extrair o assunto da pergunta da prosa violaria P-2 — então o assunto vem pelo
contrato, como a sentinela de estado.

**Files:**
- Modify: `tools/speckit-clarify-loop` — bloco novo no `SENTINEL_PROMPT`; `decisions_of` e `decisions_block` novas; `ROUND_DECISIONS` em `run_round`; `all_decisions` e o bloco do resumo no `main_loop`; 3 fixtures e 7 asserções no `self_test`.

**Interfaces:**
- Consumes: `SENTINEL_PROMPT` (Task 11), o `txt` de `.result` que `run_round` já extrai.
- Produces:
  - `decisions_of tag texto` → zero ou mais linhas `tag<TAB>assunto<TAB>opção`
  - `decisions_block yes_total linhas` → o bloco do resumo, ou o fallback, ou vazio
  - global `ROUND_DECISIONS`, zerada por rodada como os demais `ROUND_*`

- [ ] **Step 1: Escrever as fixtures**

Inserir logo depois das fixtures da sentinela (Task 11):

```bash
# --- Fixtures da linha de decisão -------------------------------------------
# Ordem do D-7: zero ou mais CLARIFY_DECISION, e a CLARIFY_STATE por último.
FIX_DEC_UMA="$(cat <<'EOF'
Integrei a resposta ao spec.

CLARIFY_DECISION: igualdade de rótulo -> A (no parse)
CLARIFY_STATE: ASKING
EOF
)"

FIX_DEC_DUAS="$(cat <<'EOF'
Integrei as duas respostas.

CLARIFY_DECISION: igualdade de rótulo -> A (no parse)
CLARIFY_DECISION: feedback de falha de cópia -> B (sinal transitório)
CLARIFY_STATE: COMPLETE
EOF
)"

# Linha malformada — sem a seta. É descartada e conta para o mesmo fallback da
# ausência: melhor não mostrar nada do que mostrar meia decisão (M-04).
FIX_DEC_SEM_SETA="$(cat <<'EOF'
CLARIFY_DECISION: assunto sem opção nenhuma
CLARIFY_STATE: ASKING
EOF
)"
```

- [ ] **Step 2: Escrever as asserções que falham**

No `self_test`, logo depois do bloco da guarda de vazamento (Task 13):

```bash
  assert_out "decisão bem-formada vira tag/assunto/opção" \
    "$(printf 'r01\tigualdade de rótulo\tA (no parse)')" \
    decisions_of r01 "$FIX_DEC_UMA"
  assert_out "duas decisões saem na ordem do turno" \
    "$(printf 'r02\tigualdade de rótulo\tA (no parse)\nr02\tfeedback de falha de cópia\tB (sinal transitório)')" \
    decisions_of r02 "$FIX_DEC_DUAS"
  assert_out "turno sem decisão não inventa linha" '' decisions_of r01 "$FIX_SENT_ASK"
  assert_out "decisão sem a seta é descartada"     '' decisions_of r01 "$FIX_DEC_SEM_SETA"

  # A largura da coluna do assunto é a do maior assunto — o `%-22s` do esperado
  # fixa isso sem que ninguém precise contar espaço à mão.
  assert_out "bloco de decisões alinha a coluna do assunto" \
    "$(printf 'decisões aceitas (2):\n  r01  %-22s -> A\n  r02  %-22s -> B' \
       'assunto curto' 'assunto um pouco maior')" \
    decisions_block 2 "$(printf 'r01\tassunto curto\tA\nr02\tassunto um pouco maior\tB')"
  assert_out "sem decisão capturada, o número continua honesto" \
    'decisões aceitas: 12 (texto indisponível — contrato não aderiu)' \
    decisions_block 12 ''
  assert_out "sem decisão e sem yes, não existe bloco" '' decisions_block 0 ''
```

- [ ] **Step 3: Rodar para ver falhar**

Run: `bash tools/speckit-clarify-loop --self-test 2>&1 | grep -c FALHOU`
Expected: `4`. São 7 asserções; as três que esperam `''` passam por acidente
enquanto as funções não existem.

- [ ] **Step 4: Implementar as duas funções puras**

Inserir logo abaixo de `leaked_sentinel`:

```bash
# --- Decisões aceitas (M-03/M-04) -------------------------------------------
# Lê a segunda família do contrato. A fonte é o texto de `.result` do evento
# `result` — o mesmo que o classify lê — e NUNCA o round-NN.log: lá a prosa já
# passou pelo mon_fold, que indenta a continuação em 9 colunas, e a âncora `^`
# não casaria nunca (D-6).
#
# A seta é obrigatória: linha sem ela é meia decisão, e meia decisão desinforma
# mais do que a ausência. Descartada, cai no mesmo fallback.
decisions_of() {  # tag texto → zero ou mais linhas "tag<TAB>assunto<TAB>opção"
  local tag="${1:-}"
  printf '%s' "${2:-}" \
    | grep -oE '^CLARIFY_DECISION: .+ -> .+$' \
    | sed -e 's/^CLARIFY_DECISION: /'"$tag"'\t/' -e 's/ -> /\t/'
  return 0
}

# O bloco do resumo. Pura: entram o total de `yes` e as linhas acumuladas, sai o
# texto. Alinha a coluna do assunto pelo maior assunto — `length()` conta
# caractere e não byte sob locale UTF-8, a mesma premissa que o mon_trunc já faz.
decisions_block() {  # yes_total  linhas "rNN<TAB>assunto<TAB>opção" → bloco, ou vazio
  local yes="${1:-0}" lines="${2:-}"
  if [ -z "$lines" ]; then
    # Ausência da linha não é erro — é o contrato não tendo aderido. O número
    # continua honesto; o que faltou foi o texto. Sem `yes` não houve decisão
    # nenhuma, e aí o bloco simplesmente não existe.
    [ "${yes:-0}" -gt 0 ] || return 0
    printf 'decisões aceitas: %s (texto indisponível — contrato não aderiu)\n' "$yes"
    return 0
  fi
  printf '%s\n' "$lines" | awk -F'\t' '
    { t[NR] = $1; s[NR] = $2; o[NR] = $3; if (length($2) > w) w = length($2) }
    END { printf "decisões aceitas (%d):\n", NR
          for (i = 1; i <= NR; i++) printf "  %s  %-*s -> %s\n", t[i], w, s[i], o[i] }'
  return 0
}
```

- [ ] **Step 5: Estender o contrato (M-03)**

Substituir o `SENTINEL_PROMPT` inteiro (Task 11 + Task 13) por este, que é o
texto final do contrato neste plano:

```bash
SENTINEL_PROMPT="$(cat <<'EOF'
Ao final de CADA turno seu, emita como ÚLTIMA LINHA da mensagem, sozinha:

CLARIFY_STATE: ASKING

Use exatamente um destes três valores:
- ASKING       você apresentou uma pergunta de clarificação e aguarda resposta
- COMPLETE     você encerrou a rodada e apresentou o relatório final
- NO_AMBIGUITY você não encontrou ambiguidade crítica que justifique perguntar

Quando você integrar uma resposta ao spec, emita também, em linha própria e
ANTES da linha CLARIFY_STATE:

CLARIFY_DECISION: <assunto em até 8 palavras> -> <a opção escolhida>

Zero ou mais linhas CLARIFY_DECISION; a linha CLARIFY_STATE vem sempre por
último, e sempre uma só. O fecho de um turno fica assim:

CLARIFY_DECISION: igualdade de rótulo -> A (no parse)
CLARIFY_STATE: ASKING

Essas linhas são lidas por um script. Não as traduza, não as formate, não as
envolva em crase, negrito ou bloco de código, e não escreva nada depois da
linha CLARIFY_STATE.

Nunca escreva linhas começadas por CLARIFY_ dentro de nenhum arquivo; elas
pertencem apenas à sua mensagem.
EOF
)"
```

A ordem é a do D-7, e o `tail -n 1` do `read_sentinel` continua lendo o estado
certo sem nenhuma mudança. Custo assumido: mais superfície de contrato é mais
chance de vazamento — e é exatamente por isso que a Task 13 vem antes desta.

- [ ] **Step 6: Acumular por rodada em `run_round`**

Acrescentar a global ao bloco dos `ROUND_*` (Task 12):

```bash
ROUND_TURNS=0
ROUND_SENT=0
SENT_MISS=0
# Decisões capturadas na rodada, uma por linha, já com a tag da rodada.
ROUND_DECISIONS=""
```

Na linha de reset de `run_round`, trocar

```bash
  ROUND_TURNS=0; ROUND_SENT=0; SENT_MISS=0
```

por

```bash
  ROUND_TURNS=0; ROUND_SENT=0; SENT_MISS=0; ROUND_DECISIONS=""
```

Declarar a variável de trabalho: na linha
`local line typ status iserr denied mutantes txt`, acrescentar `dec` ao fim.

E, logo depois do bloco de contagem da sentinela (Task 12, Step 5), inserir:

```bash
    dec="$(decisions_of "r$tag" "$txt")"
    [ -z "$dec" ] || ROUND_DECISIONS="${ROUND_DECISIONS}${ROUND_DECISIONS:+$'\n'}$dec"
```

Fica **antes** do `classify`, de propósito: o turno que fecha a rodada é o que
mais costuma trazer decisão, e o `break` do `rodada-completa` viria depois.

- [ ] **Step 7: Acumular por execução e imprimir no resumo**

No `main_loop`, trocar

```bash
  local total_turns=0 total_sent=0
```

por

```bash
  local total_turns=0 total_sent=0 all_decisions="" dec_block=""
```

Logo depois de `total_sent=$((total_sent + ROUND_SENT))`, inserir:

```bash
    [ -z "$ROUND_DECISIONS" ] \
      || all_decisions="${all_decisions}${all_decisions:+$'\n'}$ROUND_DECISIONS"
```

E, no resumo, logo depois de `printf 'parada:   %s\n' "$stop_reason"`:

```bash
  # O único ponto do resumo em que o humano vê O QUE foi decidido, e não só
  # quanto custou. Bloco, e não coluna: o layout canônico de rótulos é do M-02,
  # no plano 4.
  dec_block="$(decisions_block "$total_yes" "$all_decisions")"
  [ -z "$dec_block" ] || printf '\n%s\n' "$dec_block"
```

- [ ] **Step 8: Rodar para ver passar**

Run: `bash tools/speckit-clarify-loop --self-test | tail -1`
Expected: `speckit-clarify-loop: self-test limpo (139 casos)`.

- [ ] **Step 9: Verificar os três caminhos de ponta a ponta**

```bash
bash -n tools/speckit-clarify-loop
./tools/speckit-clarify-loop-harness.sh --max-rounds 1 | grep -A1 'decisões aceitas'
SKCL_NOSENT=1 ./tools/speckit-clarify-loop-harness.sh --max-rounds 1 | grep 'decisões aceitas'
./tools/speckit-clarify-loop-harness.sh --dry-run | grep -c 'decisões aceitas'
```

Expected, nesta ordem:

```
decisões aceitas (1):
  r01  assunto do teste -> A (recomendada)
decisões aceitas: 1 (texto indisponível — contrato não aderiu)
0
```

O `--dry-run` não injeta `yes` nenhum, então não há decisão a relatar e o bloco
não existe — nem como fallback.

- [ ] **Step 10: Commit**

```bash
git add tools/speckit-clarify-loop
git commit -m "feat(tools): resumir no fim da execução as decisões que o modelo aceitou"
```

---

### Task 15: Verificação real, nota datada e reinstalação

O harness prova o caminho de execução; só uma rodada real prova o contrato — que depende de o modelo obedecer, e isso nenhum stub demonstra.

**Files:**
- Modify: `tools/speckit-clarify-loop` — nota de verificação datada no cabeçalho.

- [ ] **Step 1: Rodar o ensaio real num repo Spec Kit de verdade**

O alvo verificado da spec é `zion-test-build-prd` com `SPECIFY_FEATURE=006-code-interop` (~US$ 0,30, ~2 min). Substitua o caminho se o seu repo estiver em outro lugar.

```bash
cd /home/tuyoshi/projects/personal/zion-build-prd
./tools/speckit-clarify-loop --repo ../zion-test-build-prd --dry-run
```

Expected, no resumo:
- `spec:     N → N linhas (delta +0)` — o ensaio não escreveu
- `parada:   --dry-run: 1 pergunta classificada, nada gravado`
- `contrato: sentinela em M/M turnos`, com **M igual ao total** de turnos
- `logs:     /tmp/speckit-clarify-loop/<data>-<hora>`
- uma linha `sensores · add=0 del=0 … custo/linha=-`
- **nenhuma** linha `sentinela vazou` e **nenhum** bloco `decisões aceitas` — o
  ensaio não injeta `yes`, logo não há decisão a relatar
- exit 0

Se `contrato:` vier com `N < M`, **pare e relate**: o modelo não obedeceu ao
contrato, e o texto do `SENTINEL_PROMPT` precisa ser revisto antes de a Fase 2
ser calibrada. A rodada não foi perdida — a heurística classificou —, mas o
S-4 não pode ser aplicado enquanto isso não fechar.

- [ ] **Step 2: Uma rodada real que grava, contra um spec que cita a sentinela**

O `--dry-run` prova a leitura da sentinela, mas nunca produz decisão nem escreve
— e sem escrita a guarda do M-06 não tem linha adicionada para olhar, então o
ensaio não diz nada sobre ela. Uma rodada paga (~US$ 0,50, ~3 min) contra um spec
**adulterado para citar o contrato** fecha os dois de uma vez: o M-03 aderiu? e a
ocorrência preexistente deixa a execução em paz (D-5)?

```bash
git -C ../zion-test-build-prd status --porcelain   # tem que sair vazio
SPEC_ALVO="$(cd ../zion-test-build-prd \
  && bash .specify/scripts/bash/check-prerequisites.sh --json --paths-only | jq -r .FEATURE_SPEC)"
( cd ../zion-test-build-prd \
  && printf '\n## Contrato de saída (fixture do D-5)\n\n```\nCLARIFY_STATE: ASKING\n```\n' >> "$SPEC_ALVO" )
git -C ../zion-test-build-prd commit -qam 'temp: spec que cita a sentinela'
./tools/speckit-clarify-loop --repo ../zion-test-build-prd --max-rounds 1
```

Expected, no resumo:
- um bloco

  ```
  decisões aceitas (K):
    r01  <assunto em até 8 palavras>  -> <opção>
  ```

  com **K igual ao `yes:`**
- **nenhuma** linha `sentinela vazou para dentro do spec`, embora o spec contenha
  a sentinela e a rodada tenha escrito — que é o critério do D-5 num repo de
  verdade
- `parada:` por convergência ou por teto, nunca por aborto

Se vier o fallback `decisões aceitas: K (texto indisponível — contrato não
aderiu)`, **registre o número e siga**: não é falha de código, é o M-03 não tendo
aderido, e é o que a nota datada do Step 4 precisa dizer. Se vier
`sentinela vazou`, **pare e relate**: ou o M-07 não segurou o modelo, ou a guarda
está casando contra o spec inteiro em vez das linhas adicionadas — e a segunda
hipótese é um bug de D-5 que precisa morrer antes de qualquer outra rodada real.

Desfaça a fixture e o que a rodada escreveu, num golpe só (o commit por rodada é
do R-22, no plano 4; até lá o spec alterado fica solto na árvore):

```bash
git -C ../zion-test-build-prd reset -q --hard HEAD~1
git -C ../zion-test-build-prd status --porcelain   # tem que sair vazio de novo
```

- [ ] **Step 3: Conferir que dois diretórios de log convivem**

```bash
ls -1d /tmp/speckit-clarify-loop/*/ | tail -3
readlink /tmp/speckit-clarify-loop/latest
grep -c 'sensores ·' /tmp/speckit-clarify-loop/latest/round-01.log
```
Expected: vários diretórios datados preservados, `latest` apontando para o mais
recente, e `1` linha de sensores no log da rodada.

- [ ] **Step 4: Registrar a verificação no cabeçalho**

Acrescentar ao bloco de notas de verificação do cabeçalho (logo depois do
parágrafo do monitor, antes da linha `# Reinstalar após editar:`), com os
números **observados nos Steps 1 e 2** substituindo os `<…>`:

```bash
# Fase 0 + Fase 1 verificadas em <data> contra claude <versão> e a skill
# speckit-clarify:
#   --dry-run em zion-test-build-prd (SPECIFY_FEATURE=006-code-interop) →
#   sentinela em <M>/<M> turnos, spec intocado (delta +0), US$ <custo>, e um
#   diretório de log próprio em /tmp/speckit-clarify-loop/<data>-<hora>.
#   A linha `sensores ·` sai em toda rodada, inclusive sob --quiet, e NENHUM dos
#   seus números decide parada nesta fase — a Fase 2 é quem os liga.
#   Uma rodada paga no mesmo repo, com o spec adulterado para CITAR a sentinela
#   dentro de uma cerca: <K>/<K> decisões nomeadas no resumo e nenhum falso
#   positivo da guarda de vazamento — a ocorrência preexistente não é linha
#   nova, que é o ponto inteiro de casar contra `added_lines` e não contra o
#   spec (D-5).
```

- [ ] **Step 5: Suíte, sintaxe e guards do repo**

```bash
bash -n tools/speckit-clarify-loop
bash tools/speckit-clarify-loop --self-test | tail -1
./scripts/check-canon.sh && ./scripts/check-assets.sh
```
Expected: sem saída do `bash -n`; `self-test limpo (139 casos)`; `check-canon:
limpo` e `check-assets: sem drift`.

- [ ] **Step 6: Reinstalar no PATH**

```bash
install -m 755 tools/speckit-clarify-loop ~/.local/bin/
speckit-clarify-loop --self-test | tail -1
```
Expected: `speckit-clarify-loop: self-test limpo (139 casos)` — vindo da cópia instalada.

- [ ] **Step 7: Commit**

```bash
git add tools/speckit-clarify-loop
git commit -m "docs(tools): nota de verificação das fases 0 e 1"
```

---

## O que este plano NÃO entrega

Ficam para os planos seguintes, conforme D-4 e a ordem de entrega da spec:

| item | plano |
|---|---|
| R-16…R-20, S-6 (semântica de parada e falha, tabela de `rc` no cabeçalho) · **M-08** (`REPLY_PROBE` no caminho indeterminado) | 2 — Fase 3 |
| R-11…R-15, S-5 (sensores de parada, `--sensors=off\|warn\|stop`, `assess_round`) | 3 — Fase 2, em `warn` |
| R-21, R-22 (teto de rodadas, commit por rodada) · **M-01, M-02** (branch dedicado, as duas saídas) · **M-05** (`revisar:`) · **M-09, M-10** (processo e gates a jusante) · **M-12** (`clarify_branch_name`) | 4 — Fase 4 |
| R-23…R-25 (calibração) · **M-11** (viés de audiência) | — protocolo, não vira plano |

Em particular, **o layout canônico do resumo não é deste plano**: a coluna de
rótulos de 11 caracteres, o rótulo `sentinela:` no lugar do `contrato:` que a
Task 12 escreve, e as linhas `base:`/`branch:`/`aceitar:`/`descartar:`/`revisar:`
chegam com o M-02 e o M-05. Aqui o resumo ganha só o **bloco** de decisões.

E o `rc` do vazamento continua sendo o `rc=1` genérico: o `rc=4` — "aborto com o
spec alterado, revisão obrigatória" — nasce com o R-19, no plano 2, e passa a
valer para o M-06 sem que ninguém toque nele, porque a linha vazada é linha nova
por construção (G3).

Por isso o "Pronto quando" da spec só fecha ao fim do plano 4. Deste plano saem:
o `--self-test` com contador automático e cobertura da leitura da sentinela, dos
três estados da guarda de vazamento e do parsing das decisões; o `--dry-run` real
com `delta +0`; a linha de sensores em toda rodada; e uma rodada paga mostrando
as decisões nomeadas. A tabela de `rc` no cabeçalho e a execução com
`--sensors=warn` são das fases 3 e 2.
