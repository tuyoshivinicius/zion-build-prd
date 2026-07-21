# Poda do `speckit-clarify-loop` — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remover a heurística de prosa bilíngue do `speckit-clarify-loop`, deixando a sentinela de estado como caminho único de classificação, com uma rede que impede um turno sem sentinela de descartar uma rodada paga.

**Architecture:** Cinco requisitos da spec, entregues em ordem de segurança: **a rede entra antes da poda**, para que nenhum commit da série deixe a ferramenta num estado em que um turno indeterminado é fatal e não há fallback. Depois a poda, depois a unificação da checagem de hash, depois a linha de resumo, e por fim a correção documental. Toda decisão é função pura exercitada pelo `--self-test` embutido, sem repo e sem custo.

**Tech Stack:** Bash (`set -u`, sem `pipefail`), `jq`, `grep -E`, `awk`. Auto-teste embutido no próprio arquivo via `--self-test`, com `assert_out` e contador automático `ST_COUNT`. Nenhuma dependência nova.

## Global Constraints

Copiados da spec `docs/superpowers/specs/2026-07-21-speckit-clarify-loop-poda-design.md`. Valem para toda task.

- **P-1** — Assimetria de custo governa a parada. Parar cedo = uma invocação a mais. Parar tarde = dólar + spec estragado + humano lendo diff.
- **P-2** — Prosa não é contrato. Nenhum sinal de controle novo pode depender de casar texto livre de LLM.
- **P-3** — Decisão é função pura. Tudo exercitável pelo `--self-test`, sem repo e sem custo.
- **P-6** — Simplificação só entra quando remove duplicação de fonte de verdade. **Nunca apaga fixture capturada de rodada real: aquilo é evidência, não entulho.**
- **Não mexer:** `ratelimit_fatal` com `allowed_*` permissivo · `timeout` embrulhando o `claude` · perfil `plain` forçado no `round-NN.log` · `SENTINEL_PROMPT` inline no `--append-system-prompt` · `leaked_sentinel` casando contra `added_lines` · `read_sentinel` com âncora `^…$` e `tail -n 1` · `decisions_of` lendo o `.jsonl`.
- **Fora de escopo:** Fase 2 (sensores) · Fase 4 (ramo, commit por rodada, resumo consolidado, teto de rodadas) · `R-17` · `R-18` · `R-19` (o `rc=4`) · `M-01` · `M-02` · `M-09` · `M-10` · `M-11`.
- **Nada toca o repo-alvo.** Sem branch, sem commit por rodada, sem escrita fora do `$WORK` e do `$LOG_DIR`. Se uma task pedir `git` contra `$REPO`, ela está errada.
- **O arquivo é fonte única e se instala por cópia.** Não pode depender de nada ao lado dele. Nenhum arquivo novo é criado em `tools/`.
- **Idioma:** todo comentário, mensagem e descrição de teste em português, no tom do arquivo (frase curta, o porquê antes do quê, custo em dólar quando houver).
- **O `--self-test` tem de ficar verde em TODO commit.** 139 casos hoje.

---

## Desvios desta implementação em relação à spec

Três, todos descobertos ao mapear o código e todos na direção de menos código. A **Task 6** reflete cada um de volta na spec, no mesmo commit em que a série fecha.

| # | a spec diz | o plano faz | por quê |
|---|---|---|---|
| **1** | `R-B` cria o contador `IND_STREAK` | usa o `SENT_MISS` que já existe | Pós-poda, "turno sem sentinela" e "`indeterminada`" são o **mesmo evento**. `SENT_MISS` já é incrementado e zerado nos pontos exatos (`:887-892`). Um segundo contador seria duplicação de fonte de verdade — o que `P-6` proíbe. |
| **2** | `R-B` exercitado com `assert_emit` (estado no shell corrente) | exercitado com `assert_out` | Com o limiar numa função pura que **recebe** o contador (`miss_action`), não há estado a preservar. `P-3` na forma mais forte. |
| **3** | contabilidade prevê **≈ −50 linhas** (1786 → ≈1736) | **≈ −10 a −25 linhas** (1786 → ≈1765–1775) | Ver abaixo. |

**Sobre o desvio 3 — a contabilidade da spec está otimista, e por três razões:**

| | |
|---|---|
| o bloco da heurística | rende o que se esperava: **≈ −57** (78 linhas de `:230-307` viram ~21) |
| a rede (`R-B` + `R-C`) | custa **≈ +28**, não os +21 previstos: o `REPLY_PROBE` é texto de contrato de três linhas, e no tom deste arquivo ele vem com o parágrafo que explica **por que** não é um `yes` |
| o bloco do `--dry-run` | rende **−6**, não −12: preservar a mensagem `1 pergunta classificada` custa as 3 linhas do `case`, e vale |
| a nota datada (Task 5) | custa **+10**, e não estava na conta nenhuma |

**O arquivo ainda termina menor do que começou, mas por pouco — e a linha de contagem nunca foi o ponto.** O ganho é qualitativo: uma verdade em vez de duas sobre a mesma decisão, e um lugar só para consertar quando a classificação falhar. Não corte comentário para melhorar o número: o valor deste arquivo está justamente nos comentários que explicam o custo em dólar de cada decisão, e otimizar a métrica contra a coisa seria trocar o certo pelo bonito. A **Task 6** grava o número medido, não o estimado.

---

## File Structure

| arquivo | responsabilidade | tasks |
|---|---|---|
| `tools/speckit-clarify-loop` | **único arquivo de código.** 1786 linhas, monólito por desenho (instala-se por cópia e não pode depender de nada ao lado). Já é internamente seccionado por comentários `# --- Nome ---`; cada task fica dentro de uma ou duas seções. | 1–4 |
| `docs/superpowers/specs/2026-07-21-speckit-clarify-loop-poda-design.md` | spec desta mudança; recebe a correção da contabilidade e dos três desvios | 6 |
| `docs/superpowers/specs/2026-07-21-speckit-clarify-loop-evolucao-design.md` | spec de evolução (731 linhas); recebe a correção da `§Ordem de entrega` e as marcas `Deferido` | 6 |

Seções do script tocadas, por ordem de aparição:

- `# --- Leitura da sentinela ---` (`:158-192`) — `sentinel_note`, e a nova `miss_action` (Task 1)
- `# --- Classificação do turno ---` (`:230-307`) — a poda inteira (Task 2)
- constantes de resposta, logo antes de `send_user` (`:796`) — `REPLY_YES`/`REPLY_PROBE` (Task 1)
- `run_round`, o `case "$(classify "$txt")"` (`:895-923`) — o ramo indeterminado (Task 1)
- `main_loop` (`:988-1020`) — `spec_mudou` e o colapso do `--dry-run` (Task 3)
- bloco do resumo (`:1036-1052`) — `revisar:` (Task 4)
- `# --- Auto-teste embutido ---` (`:1057+`) — asserções, em toda task

---

### Task 1: A rede — sonda em vez de aborto no turno sem sentinela

Entrega `R-B` e `R-C`. **Vem antes da poda de propósito:** enquanto a heurística existir, esta rede fica quase dormente, e é exatamente por isso que ela é segura de mergear primeiro. Se a ordem se invertesse, haveria um commit no histórico em que `indeterminada` é fatal e não há fallback nenhum.

**Files:**
- Modify: `tools/speckit-clarify-loop:168-179` (textos de `sentinel_note`; acrescenta `SENT_MISS_MAX` e `miss_action`)
- Modify: `tools/speckit-clarify-loop:796` (constantes `REPLY_YES`/`REPLY_PROBE`, antes de `send_user`)
- Modify: `tools/speckit-clarify-loop:914` (`send_user 'yes'` → `send_user "$REPLY_YES"`)
- Modify: `tools/speckit-clarify-loop:918-922` (ramo `indeterminada` do `case`)
- Modify: `tools/speckit-clarify-loop:997-999` (remove o arm morto de `main_loop`)
- Test: `tools/speckit-clarify-loop:1543-1552` (asserções de `sentinel_note`) e logo abaixo (asserções novas de `miss_action`)

**Interfaces:**
- Consumes: `SENT_MISS` (inteiro, já mantido em `run_round:887-892`) · `send_user <texto>` · `emit_note warn <texto>` · `assert_out <desc> <esperado> <cmd…>`
- Produces:
  - `SENT_MISS_MAX=2` — constante inteira, limiar único de ausências consecutivas
  - `miss_action <n>` → imprime `sonda` (n < 2) ou `aborta` (n ≥ 2). Função pura, sem estado.
  - `REPLY_YES` — string `yes`
  - `REPLY_PROBE` — string de três linhas (texto exato no Step 3)
  - `sentinel_note <n>` → texto sem a palavra "heurística" (assinatura inalterada)

**O que o auto-teste cobre, e o que não cobre.** Cobre a **decisão** — `miss_action` e `sentinel_note` são puras e recebem o contador. Não cobre o **envio**: `send_user "$REPLY_PROBE"` vive dentro do laço de `run_round`, que fala com o processo `claude` por FIFO, e o auto-teste é por construção sem repo e sem custo. Não invente um teste que precise de repo — a verificação do envio é o `--dry-run` real da Task 5. Esta separação é o `P-3` funcionando como projetado: o que decide é puro e testável, o que faz efeito colateral fica fino o bastante para ser lido.

- [ ] **Step 1: Escrever as asserções que falham**

Em `tools/speckit-clarify-loop`, **substituir** o bloco de asserções de `sentinel_note` (hoje em `:1543-1552`) por este, que já traz os textos novos e as asserções de `miss_action`:

```bash
  assert_out "sem ausência não há aviso" '' sentinel_note 0
  assert_out "uma ausência é só nota" \
    'turno sem sentinela' \
    sentinel_note 1
  assert_out "duas ausências viram alarme" \
    'contrato de saída quebrado: 2 turnos seguidos sem sentinela' \
    sentinel_note 2
  assert_out "três ausências seguem no alarme" \
    'contrato de saída quebrado: 3 turnos seguidos sem sentinela' \
    sentinel_note 3

  # O limiar é função pura e RECEBE o contador — por isso cabe no assert_out, sem
  # o assert_emit que as funções com estado exigem.
  assert_out "sem ausência nenhuma, nada a decidir"  sonda  miss_action 0
  assert_out "a primeira ausência sonda, não aborta" sonda  miss_action 1
  assert_out "a segunda ausência seguida aborta"     aborta miss_action 2
  assert_out "a terceira também aborta"              aborta miss_action 3
```

- [ ] **Step 2: Rodar o auto-teste e confirmar que falha**

Run: `bash tools/speckit-clarify-loop --self-test`

Expected: FALHA. Quatro linhas `FALHOU:` nas asserções de `sentinel_note` (o texto atual ainda tem "heurística") e o teste morre em `miss_action: command not found` — o `set -u` não cobre comando ausente, então as quatro últimas saem como `FALHOU` com `veio: []`. A última linha traz `self-test FALHOU`.

- [ ] **Step 3: Implementar — o limiar, a nota e as duas respostas**

**3a.** Em `tools/speckit-clarify-loop`, **substituir** o bloco de comentário e a função `sentinel_note` (`:168-179`) por:

```bash
# Teto de turnos consecutivos sem sentinela, e a única fonte do limiar: tanto a
# nota quanto a decisão de parar leem daqui. Uma ausência é esquecimento e se
# resolve com uma sonda (R-C); duas seguidas não são esquecimento, são o
# contrato caído, e aí a rodada não tem mais como ser interpretada.
SENT_MISS_MAX=2

# Aviso de contrato quebrado. Puro: entra a sequência de ausências, sai o texto.
# A primeira ausência não para a rodada — abortar ali descartaria a rodada paga,
# que é a classe de bug que a sentinela existe para matar (P-1).
sentinel_note() {  # nº de turnos consecutivos sem sentinela → aviso, ou vazio
  case "${1:-0}" in
    0|'') : ;;
    1) printf 'turno sem sentinela' ;;
    *) printf 'contrato de saída quebrado: %s turnos seguidos sem sentinela' "$1" ;;
  esac
  return 0
}

# A decisão de parada do contrato, isolada como função pura (P-3): recebe o
# contador, devolve o token. Sem estado interno, por isso não precisa do
# assert_emit — e por isso o limiar tem um lugar só para mudar.
miss_action() {  # nº de turnos consecutivos sem sentinela → sonda|aborta
  if [ "${1:-0}" -lt "$SENT_MISS_MAX" ]; then printf 'sonda'; else printf 'aborta'; fi
}
```

**3b.** Em `tools/speckit-clarify-loop`, **inserir** imediatamente antes de `send_user()` (hoje `:796`):

```bash
# As duas respostas do laço, e a diferença entre elas é de segurança, não de
# estilo. `yes` é o vocabulário que a própria skill documenta ("accept the
# recommendation by saying yes") e vale para pergunta CLASSIFICADA — onde se sabe
# que houve pergunta. No turno sem sentinela não se sabe, e um `yes` cego ali pode
# ser lido como aprovação de uma ação que ninguém propôs. A sonda é redigida para
# não poder: ela condiciona, e ainda pede a sentinela de volta.
REPLY_YES='yes'
REPLY_PROBE='Se você fez uma pergunta de clarificação, responda com a opção
recomendada. Se a rodada já terminou, emita apenas a linha
CLARIFY_STATE: COMPLETE.'
```

**3c.** Em `run_round`, **trocar** `send_user 'yes'` (hoje `:914`) por:

```bash
        send_user "$REPLY_YES"
```

**3d.** Em `run_round`, **substituir** o ramo `indeterminada)` do `case` (hoje `:918-922`) por:

```bash
      indeterminada)
        # O SENT_MISS já foi incrementado para ESTE turno lá em cima, antes do
        # classify — então aqui ele conta a sequência corrente, inclusive o turno
        # em curso. Não nasce contador novo: pós-poda "sem sentinela" e
        # "indeterminada" são o mesmo evento, e dois contadores para um evento
        # divergem no dia em que alguém mexer num só (P-6).
        if [ "$(miss_action "$SENT_MISS")" = aborta ]; then
          ROUND_OUTCOME=aborto
          ROUND_ABORT="$SENT_MISS turnos seguidos sem sentinela na rodada $n"
          break
        fi
        emit_note warn 'turno sem sentinela — sondando o estado'
        send_user "$REPLY_PROBE"
        ;;
```

**3e.** Em `main_loop`, **remover** o arm que virou código morto (hoje `:997-999`):

```bash
      indeterminada)
        stop_reason="turno indeterminado na rodada $tag (stream: $LOG_DIR/round-$tag.jsonl)"
        rc=1; break ;;
```

`ROUND_OUTCOME=indeterminada` não é mais atribuído em lugar nenhum: o ramo do 3d ou sonda e continua, ou vira `aborto`. O arm passa a ser inalcançável, e `set -u` não avisa sobre isso — só a leitura avisa.

- [ ] **Step 4: Rodar o auto-teste e confirmar que passa**

Run: `bash tools/speckit-clarify-loop --self-test`

Expected: PASSA. Última linha: `speckit-clarify-loop: self-test limpo (143 casos)` — 139 + 4 asserções novas de `miss_action`.

- [ ] **Step 5: Confirmar que o arm morto sumiu e que nada mais referencia `indeterminada` como desfecho**

Run: `grep -n 'ROUND_OUTCOME=indeterminada' tools/speckit-clarify-loop`

Expected: nenhuma saída (status 1). Se aparecer alguma linha, o Step 3d não foi aplicado por inteiro.

- [ ] **Step 6: Commit**

```bash
git add tools/speckit-clarify-loop
git commit -m "feat(tools): sondar o estado em vez de abortar no turno sem sentinela

Um turno sem sentinela deixa de encerrar a rodada na primeira ocorrência:
envia REPLY_PROBE, que não pode ser lido como aprovação de ação inventada e
ainda pede a sentinela de volta. A segunda ausência seguida aborta.

O limiar vira SENT_MISS_MAX, lido tanto pela nota quanto pela decisão, e a
decisão vira a função pura miss_action. Sem contador novo: SENT_MISS já
conta esse exato evento.

Entra ANTES da poda da heurística de propósito — invertida a ordem, haveria
um commit em que o turno indeterminado é fatal e não há fallback."
```

---

### Task 2: A poda — a sentinela como caminho único

Entrega `R-A`. Este é o commit que consuma o `S-4`.

**Files:**
- Modify: `tools/speckit-clarify-loop:230-307` (bloco inteiro da classificação)
- Test: `tools/speckit-clarify-loop:1497-1524` (16 asserções que hoje derivam rótulo da prosa) e `:1538-1541` (as quatro de sentinela adulterada)

**Interfaces:**
- Consumes: `read_sentinel <texto>` → `ASKING|COMPLETE|NO_AMBIGUITY` ou vazio (inalterada) · `miss_action`/`REPLY_PROBE` da Task 1
- Produces: `classify <texto>` → `pergunta-pendente|rodada-completa|loop-seco|indeterminada`. Assinatura idêntica; muda só o que a produz.
- Removes: `SIG_DRY_RE`, `SIG_COMPLETE_RE`, `SIG_NEXT_RE`, `SIG_ASK_RE`, `has_re`. Nenhuma delas é referenciada fora deste bloco — verificado.

- [ ] **Step 1: Escrever as asserções que falham**

**1a.** Em `tools/speckit-clarify-loop`, **substituir** as asserções de `:1497-1524` por este bloco. As fixtures **não** saem (`P-6`: foram capturadas de rodadas reais e os comentários ao lado citam o custo em dólar de cada uma); o que muda é o valor esperado.

```bash
  # A prosa não classifica mais nada — este bloco é o TRINCO DA PODA. São as
  # mesmas fixtures capturadas das rodadas reais de 2026-07-21, com o valor
  # esperado invertido: se alguém reintroduzir uma alternância de prosa, dezesseis
  # casos ficam vermelhos na hora. Elas não são teste morto e não saem (P-6).
  assert_out "múltipla escolha não classifica"  indeterminada classify "$FIX_MC"
  assert_out "resposta curta não classifica"    indeterminada classify "$FIX_SHORT"
  assert_out "Completion Report não classifica" indeterminada classify "$FIX_REPORT"
  assert_out "frase seca não classifica"        indeterminada classify "$FIX_DRY"
  assert_out "texto que não casa com nada"      indeterminada classify "$FIX_NOISE"
  assert_out "texto vazio"                      indeterminada classify ""
  assert_out "'recommend' em prosa"             indeterminada classify "$FIX_PROSE_RECOMMEND"
  assert_out "o marcador bold sozinho"          indeterminada classify '**Recommended:** Option A - x'
  assert_out "múltipla escolha em pt"           indeterminada classify "$FIX_MC_PT"
  assert_out "resposta curta em pt"             indeterminada classify "$FIX_SHORT_PT"
  assert_out "Completion Report em pt"          indeterminada classify "$FIX_REPORT_PT"
  assert_out "frase seca em pt"                 indeterminada classify "$FIX_DRY_PT"
  assert_out "pergunta em pt no feminino"       indeterminada classify "$FIX_MC_PT_FEM"
  assert_out "resposta curta em pt no feminino" indeterminada classify "$FIX_SHORT_PT_FEM"
  assert_out "report que titula 'Próximo passo'"   indeterminada classify "$FIX_REPORT_PASSO_PT"
  assert_out "'próximo passo' em prosa"            indeterminada classify "$FIX_MC_PT_COM_PASSO"
  assert_out "report que titula 'Próximo comando'" indeterminada classify "$FIX_REPORT_COMANDO_PT"
  assert_out "'próximo comando' em prosa"          indeterminada classify "$FIX_MC_PT_COM_COMANDO"
  assert_out "report com fecho em negrito"         indeterminada classify "$FIX_REPORT_NEGRITO_PT"
  assert_out "'Próximo passo' sem destaque" \
    indeterminada classify 'Próximo passo do fluxo é o plano.'
  assert_out "negrito no meio da linha" \
    indeterminada classify 'Escrevi **Próximo comando** no rascunho e apaguei.'
```

**1b.** **Substituir** as quatro asserções de `:1538-1541` por:

```bash
  # Estas quatro melhoram de significado com a poda. Antes afirmavam "cai na
  # heurística"; agora afirmam a propriedade que importa de verdade numa
  # sentinela citada, cercada ou inválida — ela não classifica coisa nenhuma.
  assert_out "marcador de pergunta na prosa não interfere no contrato" \
    rodada-completa   classify "$FIX_SENT_VS_HEUR"
  assert_out "sentinela em prosa não classifica"   indeterminada classify "$FIX_SENT_PROSA"
  assert_out "sentinela em crase não classifica"   indeterminada classify "$FIX_SENT_CRASE"
  assert_out "valor desconhecido não classifica"   indeterminada classify "$FIX_SENT_INVALIDA"
```

- [ ] **Step 2: Rodar o auto-teste e confirmar que falha**

Run: `bash tools/speckit-clarify-loop --self-test`

Expected: FALHA, com 19 linhas `FALHOU:` — as 16 que hoje derivam rótulo da prosa mais as 3 de sentinela adulterada. Cada uma mostra `esperado: [indeterminada]` e `veio:` com o rótulo que a heurística ainda produz (`pergunta-pendente`, `rodada-completa` ou `loop-seco`). Última linha: `self-test FALHOU`.

- [ ] **Step 3: Implementar — remover a heurística**

Em `tools/speckit-clarify-loop`, **substituir o bloco inteiro de `:230` até `:307`** (do comentário `# --- Classificação do turno …` até o `}` que fecha `classify`, inclusive as quatro constantes `SIG_*` e a função `has_re`) por:

```bash
# --- Classificação do turno (função pura de texto) --------------------------
# Uma verdade só: a sentinela de estado do SENTINEL_PROMPT. Até 2026-07-21 havia
# duas — a sentinela e uma heurística de prosa bilíngue com quatro regexes, seis
# marcadores de pergunta em duas línguas e duas flexões, e sete comentários
# datados somando mais de US$ 20 em rodadas boas descartadas por variação de
# prosa. Ela morreu aqui, e é isto que o S-4 prometia:
#
#   falha de classificação é bug do CONTRATO, não vaga para uma sétima captura de
#   prosa. O remédio é o SENTINEL_PROMPT, e a heurística NÃO volta.
#
# Casar texto livre de LLM para derivar sinal de controle é o que o P-2 proíbe;
# a heurística era a exceção tolerada enquanto não havia contrato. Há.
#
# Turno sem sentinela não classifica — e não custa a rodada: o ramo indeterminado
# do run_round sonda com o REPLY_PROBE e só aborta na segunda ausência seguida.
# As fixtures de prosa continuam no auto-teste, todas esperando `indeterminada`:
# são o trinco que fica vermelho se alguém tentar trazer a heurística de volta.
classify() {  # texto do turno em $1 → rótulo em stdout
  case "$(read_sentinel "${1:-}")" in
    ASKING)       printf 'pergunta-pendente\n' ;;
    COMPLETE)     printf 'rodada-completa\n'   ;;
    NO_AMBIGUITY) printf 'loop-seco\n'         ;;
    *)            printf 'indeterminada\n'     ;;
  esac
}
```

- [ ] **Step 4: Rodar o auto-teste e confirmar que passa**

Run: `bash tools/speckit-clarify-loop --self-test`

Expected: PASSA. Última linha: `speckit-clarify-loop: self-test limpo (143 casos)` — o total não muda em relação à Task 1: nenhuma asserção foi acrescentada nem removida, só invertida.

- [ ] **Step 5: Confirmar que a heurística sumiu por inteiro**

Run: `grep -c 'SIG_\|has_re' tools/speckit-clarify-loop`

Expected: `0`

- [ ] **Step 6: Medir o arquivo**

Run: `wc -l tools/speckit-clarify-loop`

Expected: ≈ **1760** linhas — era 1786, a Task 1 acrescentou ~28 e esta remove ~51 líquidos. Uma faixa de **1745 a 1775** está correta.

Este passo **mede**, não julga: o número exato depende de quanto comentário você escreveu, e o plano manda não cortar comentário para melhorar métrica. O que seria erro é passar de **1790** — isso significaria que o bloco `:230-307` não saiu por inteiro. Nesse caso, rode `grep -n 'SIG_\|has_re' tools/speckit-clarify-loop` e remova o que sobrou.

- [ ] **Step 7: Commit**

```bash
git add tools/speckit-clarify-loop
git commit -m "refactor(tools): a sentinela como caminho único de classificação

Consuma o S-4: saem SIG_DRY_RE, SIG_COMPLETE_RE, SIG_NEXT_RE, SIG_ASK_RE,
a função has_re e os sete comentários datados que as justificavam. O
classify vai de 20 linhas com quatro regexes para 8 sem nenhuma.

Duas verdades sobre a mesma decisão viram uma. Falha de classificação passa
a ser bug do SENTINEL_PROMPT, com um lugar só para consertar.

As fixtures de prosa capturadas de rodadas reais ficam (P-6), com o valor
esperado invertido para indeterminada — são o trinco que fica vermelho se
alguém trouxer a heurística de volta."
```

---

### Task 3: Uma garantia de "não escreveu", não três

Entrega `R-D` (o `S-6`), **sem** o `R-19`: nenhum `rc` novo nasce.

**Files:**
- Modify: `tools/speckit-clarify-loop:941-942` (declaração de `spec_mudou` nos locais de `main_loop`)
- Modify: `tools/speckit-clarify-loop:988` (derivação, logo após `cur_hash`)
- Modify: `tools/speckit-clarify-loop:992-1000` (ramo `aborto` do `case`)
- Modify: `tools/speckit-clarify-loop:1002-1016` (bloco do `--dry-run`)
- Modify: `tools/speckit-clarify-loop:1018` (estagnação)

**Interfaces:**
- Consumes: `spec_hash` → hash do spec via `git hash-object` (inalterada) · `prev_hash`/`cur_hash`, já calculados em `:954` e `:988`
- Produces: `spec_mudou` — inteiro local de `main_loop`, `0` ou `1`. Três consumidores: ramo `aborto`, bloco do `--dry-run`, estagnação.

Não há teste de auto-teste nesta task: `main_loop` fala com o repo e com o processo `claude`, e o auto-teste é por construção sem repo. A verificação é o `--dry-run` real do Step 5, mais a leitura do Step 4. Isto é uma limitação conhecida e declarada — não invente um teste que precise de repo.

- [ ] **Step 1: Declarar o local**

Em `main_loop`, **trocar** a linha `:941`:

```bash
  local round=0 same=0 prev_hash cur_hash
```

por:

```bash
  local round=0 same=0 prev_hash cur_hash spec_mudou
```

- [ ] **Step 2: Derivar uma vez**

Logo **após** a linha `cur_hash="$(spec_hash)"` (hoje `:988`), **inserir**:

```bash
    # "A rodada escreveu no spec" derivado UMA vez. Antes disto a mesma
    # comparação vivia em três lugares — o ramo de aborto, o bloco do --dry-run
    # e a estagnação —, e três cópias de uma verdade são três chances de
    # divergir no dia em que uma delas mudar (S-6).
    spec_mudou=0; [ "$cur_hash" = "$prev_hash" ] || spec_mudou=1
```

- [ ] **Step 3: Os três consumidores**

**3a.** No `case "$ROUND_OUTCOME"`, **substituir** o ramo `aborto)` (hoje `:995-996`) por:

```bash
      aborto)
        stop_reason="aborto na rodada $tag — $ROUND_ABORT"; rc=1
        # O rc continua 1: o rc=4 é do R-19, fora do escopo desta entrega. O que
        # muda é o humano saber. Numa ferramenta pessoal invocada à mão, quem lê
        # é o resumo na tela, não um script.
        [ "$spec_mudou" -eq 0 ] \
          || emit_note warn 'ATENÇÃO: o spec foi alterado numa rodada abortada'
        break ;;
```

**3b.** **Substituir** o bloco do `--dry-run` inteiro (hoje `:1002-1016`, 15 linhas) por:

```bash
    # O --dry-run vive de uma rodada só, e a prova de que o ensaio não gravou
    # nada é agora O MESMO código que julga os demais caminhos — uma garantia em
    # vez de duas (S-6). O bloco aqui só escolhe rc e motivo.
    if [ "$DRY_RUN" -eq 1 ]; then
      case "$ROUND_OUTCOME" in
        dry-pergunta) stop_reason='--dry-run: 1 pergunta classificada, nada gravado' ;;
        *) stop_reason="--dry-run: rodada encerrada em $ROUND_OUTCOME sem perguntas, nada gravado" ;;
      esac
      rc=0
      [ "$spec_mudou" -eq 0 ] || {
        stop_reason='--dry-run ALTEROU o spec (hash mudou) — investigue antes de confiar no modo'
        rc=1
      }
      break
    fi
```

**3c.** **Substituir** a abertura do bloco de estagnação (hoje `:1018`):

```bash
    if [ "$cur_hash" = "$prev_hash" ]; then
```

por:

```bash
    if [ "$spec_mudou" -eq 0 ]; then
```

- [ ] **Step 4: Confirmar que a comparação crua não sobrou em lugar nenhum**

Run: `grep -n 'cur_hash' tools/speckit-clarify-loop`

Expected: exatamente **duas** linhas — a atribuição `cur_hash="$(spec_hash)"` e a derivação do `spec_mudou`. Se aparecer uma terceira, um dos três consumidores do Step 3 não foi convertido.

- [ ] **Step 5: Rodar o auto-teste**

Run: `bash tools/speckit-clarify-loop --self-test`

Expected: PASSA, `self-test limpo (143 casos)`. O total não muda: `main_loop` não é coberto pelo auto-teste.

- [ ] **Step 6: Verificar a sintaxe do arquivo inteiro**

Run: `bash -n tools/speckit-clarify-loop && echo sintaxe-ok`

Expected: `sintaxe-ok`. Este passo existe porque o Step 3 mexe em três blocos aninhados de `main_loop` e um `}` a menos passaria despercebido pelo auto-teste, que não chega a executar `main_loop`.

- [ ] **Step 7: Commit**

```bash
git add tools/speckit-clarify-loop
git commit -m "refactor(tools): uma derivação de \"a rodada escreveu no spec\"

A comparação de hash vivia em três lugares — o ramo de aborto, o bloco do
--dry-run e a estagnação. Vira o spec_mudou, derivado uma vez após o
cur_hash, e o bloco de 15 linhas do --dry-run cai para 9.

A prova de que o ensaio não gravou nada passa a ser o mesmo código que
julga os demais caminhos: uma garantia em vez de duas (S-6).

Aborto que alterou o spec ganha linha destacada. O rc continua 1 — o rc=4
é do R-19, fora do escopo."
```

---

### Task 4: `revisar:` fecha todo resumo

Entrega `R-E` (o `M-05`).

**Files:**
- Modify: `tools/speckit-clarify-loop:1052` (última linha do bloco de resumo)

**Interfaces:**
- Consumes: `$REPO`, `$SPEC` — variáveis globais já definidas
- Produces: nada que outra task consuma. É a última task de código.

O bloco de resumo é `printf` inline dentro de `main_loop`, não função pura — pelo mesmo motivo da Task 3, o auto-teste não o alcança. A verificação é o `grep` do Step 3 mais o `--dry-run` real da Task 5, cujo Expected já exige `reverter:` e `revisar:` como as duas últimas linhas, nessa ordem.

- [ ] **Step 1: Acrescentar a linha**

Em `main_loop`, **substituir** a linha `:1052`:

```bash
  printf '\nreverter: git -C %s checkout -- %s\n' "$REPO" "$SPEC"
```

por:

```bash
  printf '\nreverter: git -C %s checkout -- %s\n' "$REPO" "$SPEC"
  # Última linha do resumo, em TODO caminho de saída — inclusive na convergência
  # limpa com rc=0. É o único ponto do desenho em que o humano volta ao laço.
  # Não obriga ninguém a ler; essa é a fronteira do que um harness pode fazer.
  printf 'revisar:  git -C %s diff -- %s\n' "$REPO" "$SPEC"
```

A coluna de rótulos continua em 10 caracteres: `reverter:` são 9 + 1 espaço, `revisar:` são 8 + 2. Confira o alinhamento no Step 3.

- [ ] **Step 2: Rodar o auto-teste**

Run: `bash tools/speckit-clarify-loop --self-test`

Expected: PASSA, `self-test limpo (143 casos)`.

- [ ] **Step 3: Conferir o alinhamento da coluna**

Run: `grep -n "^  printf '.*:  *%s" tools/speckit-clarify-loop | grep -c "revisar\|reverter\|contrato"`

Expected: `3`. Depois, inspecione visualmente as três linhas com `grep -n "reverter:\|revisar:\|contrato:" tools/speckit-clarify-loop` e confirme que os dois-pontos são seguidos de espaços até a coluna 11 em todas.

- [ ] **Step 4: Commit**

```bash
git add tools/speckit-clarify-loop
git commit -m "feat(tools): fechar todo resumo com a linha revisar

Última linha do resumo em todo caminho de saída, inclusive na convergência
limpa com rc=0. Sem branch e sem commit por rodada, a forma é o diff seco
do spec contra a árvore.

É o único ponto do desenho em que o humano volta ao laço."
```

---

### Task 5: Verificação real — `--dry-run` pago e nota datada

**Esta task exige um humano e custa dinheiro.** Um agente não pode executá-la: ela chama a API paga contra um repo de verdade. Se você é um subagente, **pare aqui e devolva o controle**, dizendo que as Tasks 1–4 estão prontas e que a 5 aguarda execução do autor.

O arquivo carrega notas de verificação datadas desde a primeira versão (`:17-50`), e o `§Pronto quando` da spec exige uma para esta mudança. Nota sem execução real seria mentira no cabeçalho de um arquivo cuja credibilidade inteira vem dessas notas.

**Files:**
- Modify: `tools/speckit-clarify-loop:36-51` (acrescenta o parágrafo de verificação após o bloco da Fase 0 + Fase 1)

**Interfaces:**
- Consumes: as Tasks 1–4 completas e commitadas.
- Produces: a nota datada que o `§Pronto quando` da spec exige.

- [ ] **Step 1: Reinstalar a versão de trabalho**

Run: `install -m 755 tools/speckit-clarify-loop ~/.local/bin/`

Expected: sem saída. É o passo que o próprio cabeçalho do arquivo manda dar depois de editar (`:51`).

- [ ] **Step 2: Rodar o `--dry-run` contra o repo de teste**

O repo alvo precisa estar num branch de feature, ou o `check-prerequisites.sh` do Spec Kit recusa antes de qualquer chamada paga — daí o `SPECIFY_FEATURE` (`:48-50`).

Run:
```bash
SPECIFY_FEATURE=006-code-interop speckit-clarify-loop \
  --repo ~/projects/personal/zion-test-build-prd --dry-run
```

Expected: `rc=0`. No resumo: `spec: 188 → 188 linhas (delta +0)`, `contrato: sentinela em N/N turnos` com N ≥ 1, e as duas últimas linhas sendo `reverter:` e `revisar:` nessa ordem. Custo na faixa de US$ 0,30 a US$ 0,60, pela série histórica do arquivo. Anote o custo, o `N/N` e o diretório de log.

- [ ] **Step 3: Conferir que o spec ficou intocado**

Run: `git -C ~/projects/personal/zion-test-build-prd status --porcelain`

Expected: nenhuma saída. Se aparecer o `spec.md` modificado, **pare** — o `--dry-run` gravou, e o R-D perdeu a razão de existir. Nesse caso o resumo do Step 2 já teria acusado `--dry-run ALTEROU o spec`; se ele não acusou e mesmo assim há mudança, é bug no `spec_mudou` e a série toda precisa voltar à Task 3.

- [ ] **Step 4: Escrever a nota datada**

Em `tools/speckit-clarify-loop`, **inserir** após o bloco da Fase 0 + Fase 1 (que hoje termina em `:50`, na linha do `SPECIFY_FEATURE`) e **antes** da linha `# Reinstalar após editar:`, substituindo os valores entre `<>` pelos observados no Step 2:

```bash
# Poda da heurística verificada em 2026-07-21 contra claude 2.1.216 e a skill
# speckit-clarify:
#   --dry-run em zion-test-build-prd (SPECIFY_FEATURE=006-code-interop) →
#   sentinela em <N>/<N> turnos, spec intocado (188 → 188 linhas), US$ <custo>,
#   log em <diretório>. A classificação por prosa não existe mais: turno sem
#   sentinela vira `indeterminada`, sonda com o REPLY_PROBE e só aborta na
#   segunda ausência seguida.
#   O auto-teste fecha com 143 casos, e as 21 fixtures de prosa capturadas das
#   rodadas de 2026-07-21 continuam lá, todas esperando `indeterminada` — é o
#   trinco que fica vermelho se alguém trouxer a heurística de volta.
```

- [ ] **Step 5: Rodar o auto-teste uma última vez**

Run: `bash tools/speckit-clarify-loop --self-test`

Expected: PASSA, `self-test limpo (143 casos)`. A nota é comentário; se isto falhar, o Step 4 quebrou a sintaxe do cabeçalho.

- [ ] **Step 6: Commit**

```bash
git add tools/speckit-clarify-loop
git commit -m "docs(tools): nota de verificação da poda da heurística"
```

---

### Task 6: Reflexo nas duas specs

Fecha o dever declarado na spec: *"a §Ordem de entrega da spec de evolução deixa de descrever o que existe e precisa ser corrigida no mesmo movimento."* Sem isto, aquele documento passa a descrever um plano que ninguém vai seguir.

Cirurgia, **não** enxugamento: o texto diferido fica onde está, porque é evidência — `P-6` vale para o documento também.

**Files:**
- Modify: `docs/superpowers/specs/2026-07-21-speckit-clarify-loop-evolucao-design.md` (§Ordem de entrega, D-4, R-08, R-16, S-6, M-05, M-08, §Pronto quando I e II, e as marcas `Deferido`)
- Modify: `docs/superpowers/specs/2026-07-21-speckit-clarify-loop-poda-design.md` (os três desvios e a contabilidade)

**Interfaces:**
- Consumes: o resultado das Tasks 1–5, incluindo o `wc -l` final e o número de casos do auto-teste.
- Produces: nada. É a última task.

- [ ] **Step 1: Medir o resultado real, para não escrever número inventado**

Run: `wc -l tools/speckit-clarify-loop && bash tools/speckit-clarify-loop --self-test | tail -1`

Expected: duas linhas — a contagem final (≈1770, contando a nota datada da Task 5) e `speckit-clarify-loop: self-test limpo (143 casos)`. **Use estes dois números literais nos Steps 2 e 3.** Não copie as estimativas do plano: elas existem para você reconhecer um resultado absurdo, não para virar texto de spec.

- [ ] **Step 2: Corrigir a spec da poda**

Em `docs/superpowers/specs/2026-07-21-speckit-clarify-loop-poda-design.md`:

**2a.** Na seção **`R-B`**, substituir a menção ao contador novo. O texto que hoje diz *"Contador `IND_STREAK`, por rodada, inicializado ao lado dos demais `ROUND_*` (`:812-813`) e **zerado no ramo `pergunta-pendente`**"* passa a:

```markdown
Sem contador novo: o `SENT_MISS` que já existe conta exatamente este evento.
Pós-poda, "turno sem sentinela" e "`indeterminada`" são o mesmo acontecimento, e
o `SENT_MISS` já é incrementado e zerado nos pontos certos (`:887-892`). Um
segundo contador seria duplicação de fonte de verdade — o que `P-6` proíbe.

O limiar vira a constante `SENT_MISS_MAX=2`, lida tanto pela `sentinel_note`
quanto pela decisão, e a decisão vira a função pura `miss_action <n> → sonda|aborta`.
```

**2b.** No bloco de código do `R-B`, trocar `IND_STREAK` por `miss_action "$SENT_MISS"`, refletindo o que a Task 1 implementou.

**2c.** Em **`§Pronto quando`**, substituir a linha *"A sequência de dois indeterminados exercitada **no shell corrente** (padrão `assert_emit`…)"* por:

```markdown
- A decisão de parada exercitada por `assert_out`, e não por `assert_emit`: com o
  limiar numa função pura que **recebe** o contador, não há estado a preservar.
```

**2d.** Na tabela **`§Contabilidade do tamanho`**, substituir os valores estimados pelos reais medidos no Step 1, e a linha do `S-6` de `−12` para `−6`, com a nota: *"preservar a mensagem `1 pergunta classificada` custa as 3 linhas do `case`, e vale."* Ajustar o total e a frase de fecho para o número real.

**2e.** Em **`R-D`**, acrescentar ao fim: *"O ramo `indeterminada)` do `main_loop` (`:997-999`) vira código morto com o `R-B` e sai junto — `ROUND_OUTCOME=indeterminada` não é mais atribuído em lugar nenhum."*

- [ ] **Step 3: Corrigir a spec de evolução**

Em `docs/superpowers/specs/2026-07-21-speckit-clarify-loop-evolucao-design.md`:

**3a.** Substituir a `§Ordem de entrega` da Parte I (hoje `:349-361`) por:

```markdown
## Ordem de entrega

Fase 0 → Fase 1 → **poda da heurística (entregue em 2026-07-21)**.

**Fase 2 (sensores) e Fase 4 (custo e auditoria) estão DEFERIDAS.** A ordem
original — Fase 3 → Fase 2 → Fase 4 — foi invertida pelo estudo
`docs/estudos/refatoracao-final-speckit-clarify-loop.md`, que mediu o ROI das
alternativas e concluiu que a camada de sensores entregue antes da Fase 5 é
código que narra e nunca decide, e que a Fase 4 é o único ponto em que um
defeito passa a custar trabalho e não dólar.

O que foi entregue da Fase 3: o `R-16` (relaxado) e o `S-6` (sem o `R-19`).
O resto da Fase 3 — `R-17`, `R-18`, `R-19`, `R-20` — segue deferido.

A spec da entrega é `2026-07-21-speckit-clarify-loop-poda-design.md`.
```

**3b.** Na tabela do `D-4` (`:106-110`), trocar a coluna `estado`: plano 1 → `entregue`; planos 2, 3 e 4 → `não entregue — ver estudo`; Fase 5 → `não agendada (R-23 pede ≥10 execuções pagas em ≥2 repos)`.

**3c.** No `R-08` (`:188-202`), substituir a frase final *"A heurística não sai: o contrato depende do modelo obedecer."* por:

```markdown
**Superado em 2026-07-21.** A heurística saiu: a sentinela é caminho único, e um
turno sem ela vira `indeterminada`, que sonda em vez de abortar (`R-16` relaxado
+ `M-08`). O `S-4` está consumado.
```

**3d.** No `R-16` (`:295`), acrescentar: *"**Alterado na entrega:** a cláusula `ROUND_YES > 0` caiu. Com a heurística removida, o caso mais provável — rodada 1, turno 1, sentinela esquecida — cairia em aborto na primeira, que é a classe de bug que a Fase 1 existe para matar. O primeiro turno indeterminado nunca é fatal; o contador é o `SENT_MISS`, não um `IND_STREAK` novo."*

**3e.** No `S-6` (`:299`), acrescentar: *"**Entregue sem o `R-19`:** a comparação foi generalizada e o aborto com spec alterado ganha linha destacada, mas nenhum `rc` novo nasce. A tabela do `R-20` segue deferida com os três códigos de hoje."*

**3f.** No `M-08` (`:614`), acrescentar: *"**Alterado na entrega:** o gatilho é todo turno `indeterminada`, não só o caminho do `R-16` original — pós-poda os dois são o mesmo caminho."*

**3g.** No `M-05` (`:553-556`), acrescentar: *"**Entregue em 2026-07-21**, na forma sem branch: `revisar: git -C <repo> diff -- <spec>`."*

**3h.** Marcar como **Deferido** — acrescentando a linha `> **Deferido.** Ver `§Ordem de entrega`.` logo abaixo do título ou do id, **sem apagar o texto**: a `## Fase 2` inteira, `R-17`, `R-18`, `R-19`, `R-20`, `R-21`, `R-22`, `M-01`, `M-02`, `M-09`, `M-10`, `M-11`, e a `## Resumo consolidado`.

**3i.** Nas duas `§Pronto quando` (Parte I `:363-370` e Parte II `:722-731`), acrescentar no topo de cada uma: `> Recortado ao entregue. Os critérios de Fase 2 e Fase 4 seguem deferidos.` e riscar (`~~texto~~`) os critérios que dependem de requisitos deferidos.

- [ ] **Step 4: Confirmar que os guards do repo aceitam**

Run: `./scripts/check-canon.sh && ./scripts/check-assets.sh`

Expected: `check-canon: limpo` e o veredito limpo do `check-assets`. Nenhum dos dois deve reclamar: o script vive em `tools/`, não em `scripts/`, e está fora do canon do harness por desenho — `docs/prd.md` e `docs/architecture.md` **não** são tocados por esta série. Se o `check-canon` acusar drift, **pare e reporte**: significa que alguma task saiu do escopo declarado.

- [ ] **Step 5: Commit**

```bash
git add docs/superpowers/specs/2026-07-21-speckit-clarify-loop-poda-design.md \
        docs/superpowers/specs/2026-07-21-speckit-clarify-loop-evolucao-design.md
git commit -m "docs(specs): refletir a poda nas duas specs

A §Ordem de entrega da spec de evolução passa a descrever o que existe:
Fase 0, Fase 1 e a poda entregues; Fase 2 e Fase 4 deferidas, com o texto
preservado porque é evidência (P-6).

A spec da poda recebe os três desvios da implementação — SENT_MISS no lugar
do IND_STREAK, assert_out no lugar do assert_emit, e a contabilidade real
de linhas no lugar da estimada."
```

---

## Ordem e critério de parada

1. **Task 1** — a rede (`R-B`, `R-C`). Auto-teste: 139 → 143.
2. **Task 2** — a poda (`R-A`). Auto-teste: 143, invertidas 19 asserções.
3. **Task 3** — hash único (`R-D`). Auto-teste: 143.
4. **Task 4** — `revisar:` (`R-E`). Auto-teste: 143.
5. **Task 5** — verificação paga e nota datada. **Requer humano.**
6. **Task 6** — reflexo nas duas specs.

As Tasks 1–4 e a 6 são executáveis por agente. A 5 não é.

**Pronto quando**, conforme a spec:

- [ ] `bash tools/speckit-clarify-loop --self-test` limpo, com o contador subindo sozinho a partir dos 139 de hoje
- [ ] `grep -c 'SIG_\|has_re' tools/speckit-clarify-loop` devolve `0`
- [ ] `grep -n 'cur_hash' tools/speckit-clarify-loop` devolve exatamente duas linhas
- [ ] `bash -n tools/speckit-clarify-loop` limpo
- [ ] `wc -l tools/speckit-clarify-loop` menor que 1786
- [ ] `--dry-run` real com `delta +0` e hash inalterado, verificado pelo caminho comum do `R-D`
- [ ] nota datada no cabeçalho registrando repo, custo e `sentinela: N/M`
- [ ] as duas specs corrigidas, e `./scripts/check-canon.sh` limpo

## Reversão

A ferramenta se instala por cópia, então desfazer é um comando:

```bash
git checkout <sha-anterior-à-série> -- tools/speckit-clarify-loop
install -m 755 tools/speckit-clarify-loop ~/.local/bin/
```

Se o contrato falhar em produção, o sintoma aparece antes de custar caro: `contrato: sentinela em N/M turnos` no resumo, e um `warn` por turno sem sentinela.
