# Poda do `speckit-clarify-loop` — a sentinela como caminho único

Spec de implementação. Alvo: o script em `tools/speckit-clarify-loop`, 1786 linhas,
com Fase 0 e Fase 1 entregues e verificadas em 2026-07-21 (`:36-50`).

Origem: `docs/estudos/refatoracao-final-speckit-clarify-loop.md`, alternativa **B —
só a poda, com rede** (ROI 4,00). Supera a `§Ordem de entrega` da
`2026-07-21-speckit-clarify-loop-evolucao-design.md`, que este commit corrige.

O script é ferramenta pessoal, instalada por cópia no PATH. Não aparece em
`docs/prd.md` nem em `docs/architecture.md` e está fora do canon do harness — o
dever de canonização do `CLAUDE.md` não se aplica a esta mudança. Nenhum ADR é
criado ou superado.

---

## O problema

Duas verdades convivem sobre a mesma decisão. A sentinela de estado
(`CLARIFY_STATE:`) é o contrato, entregue na Fase 1; a heurística de prosa
bilíngue é a classificação anterior, que o `S-4` congelou mas deixou viva como
fallback (`tools/speckit-clarify-loop:249-253`, `:295-306`). Enquanto as duas
existirem, elas podem divergir, e consertar uma falha de classificação exige
decidir antes qual das duas errou.

A dor declarada é custo de manutenção. Os planos 2, 3 e 4 da spec de evolução
acrescentavam sensores, seletor de três modos, ramo dedicado e sete linhas novas
de resumo — e não removiam uma única constante da heurística. Esta spec faz o
movimento contrário.

## Princípios herdados

Da spec de evolução, sem alteração. Governam cada decisão adiante.

| | |
|---|---|
| **P-1** | Assimetria de custo governa a parada. Parar cedo = uma invocação a mais. Parar tarde = dólar + spec estragado + humano lendo diff. |
| **P-2** | Prosa não é contrato. Nenhum sinal de controle novo pode depender de casar texto livre de LLM. |
| **P-3** | Decisão é função pura. Tudo exercitável pelo `--self-test`, sem repo e sem custo. |
| **P-6** | Simplificação só entra quando remove duplicação de fonte de verdade. **Nunca apaga fixture capturada de rodada real: aquilo é evidência, não entulho.** |

`P-2` é o que autoriza a poda: a heurística *é* casamento de texto livre, tolerada
enquanto não havia contrato. `P-6` é o que a limita: as fixtures ficam.

## Não mexer

`ratelimit_fatal` com `allowed_*` permissivo · `timeout` embrulhando o `claude` ·
perfil `plain` forçado no `round-NN.log` · `SENTINEL_PROMPT` inline no
`--append-system-prompt` · `leaked_sentinel` casando contra `added_lines` (D-5) ·
`read_sentinel` com âncora `^…$` e `tail -n 1` · `decisions_of` lendo o `.jsonl`.

**Fora de escopo, explicitamente:** Fase 2 (sensores) · Fase 4 (ramo, commit por
rodada, resumo consolidado, teto de rodadas) · `R-17` · `R-18` · `R-19` (o `rc=4`)
· `M-01` · `M-02` · `M-09` · `M-10` · `M-11`. Nada nesta spec toca o repo-alvo:
sem branch, sem commit, sem escrita fora do `$WORK` e do `$LOG_DIR`.

---

## Requisitos

### R-A — `classify` perde o fallback de prosa

Consuma o **S-4**. Saem: `SIG_DRY_RE`, `SIG_COMPLETE_RE`, `SIG_NEXT_RE`,
`SIG_ASK_RE`, a função `has_re` e o bloco de comentário datado que as justifica
(`:232-306`). Nenhuma delas é usada em outro ponto do arquivo — verificado.

```bash
classify() {  # texto do turno em $1 → rótulo em stdout
  case "$(read_sentinel "${1:-}")" in
    ASKING)       printf 'pergunta-pendente\n' ;;
    COMPLETE)     printf 'rodada-completa\n'   ;;
    NO_AMBIGUITY) printf 'loop-seco\n'         ;;
    *)            printf 'indeterminada\n'     ;;
  esac
}
```

**Aceitação:** `grep -c 'SIG_'` no arquivo devolve 0 · `classify` cabe em 8 linhas
· o `--self-test` passa.

**Efeito semântico, que o resto da spec depende:** `indeterminada` deixa de
significar "prosa que não reconheci" e passa a significar exatamente uma coisa —
**o modelo não emitiu a sentinela**. O remédio passa a ser sempre o mesmo, e é
isso que torna a rede do R-B tratável.

### R-B — o primeiro turno indeterminado nunca é fatal

Relaxa o **R-16** da spec de evolução, que condicionava o perdão a
`ROUND_YES > 0`. A condição existia num mundo em que a heurística ainda pegava
perguntas; sem ela, o caso mais provável do mundo pós-poda — rodada 1, turno 1,
modelo esquece a sentinela — cairia em aborto na primeira, que é a classe de bug
que a Fase 1 existe para matar (`P-1`).

Sem contador novo: o `SENT_MISS` que já existe conta exatamente este evento.
Pós-poda, "turno sem sentinela" e "`indeterminada`" são o mesmo acontecimento, e
o `SENT_MISS` já é incrementado e zerado nos pontos certos (`:887-892`). Um
segundo contador seria duplicação de fonte de verdade — o que `P-6` proíbe.

O limiar vira a constante `SENT_MISS_MAX=2`, lida tanto pela `sentinel_note`
quanto pela decisão, e a decisão vira a função pura `miss_action <n> → sonda|aborta`.

```
indeterminada)
  if [ "$(miss_action "$SENT_MISS")" = aborta ]; then
    ROUND_OUTCOME=aborto
    ROUND_ABORT="$SENT_MISS turnos seguidos sem sentinela na rodada $n"
    break
  fi
  emit_note warn 'turno sem sentinela — sondando o estado'
  send_user "$REPLY_PROBE"
  ;;
```

**Aceitação:** um turno indeterminado isolado não encerra a rodada · dois
consecutivos encerram com `ROUND_OUTCOME=aborto` · um turno classificado entre
dois indeterminados zera a sequência.

### R-C — a sonda substitui o `yes` cego no caminho indeterminado

Traz o **M-08**, com a alteração do **D-8**: duas constantes, dois caminhos.

| caminho | envia |
|---|---|
| `pergunta-pendente` | `REPLY_YES='yes'` — inalterado, é o vocabulário que a skill documenta |
| `indeterminada` (R-B) | `REPLY_PROBE` |

```
REPLY_PROBE='Se você fez uma pergunta de clarificação, responda com a opção
recomendada. Se a rodada já terminou, emita apenas a linha
CLARIFY_STATE: COMPLETE.'
```

Duas propriedades, e são elas que autorizam o R-B a dispensar a cláusula
`ROUND_YES > 0`: o texto **não pode ser lido como aprovação de uma ação
inventada**, e **recupera a sentinela** — o turno seguinte volta ao contrato em
vez de encadear indeterminadas.

Fecha o `V3` do modelo de risco da spec de evolução no mesmo commit que o cria.
A regra é a mesma que forçou o `M-06` a viajar no plano 1: mitigação não fica
atrás do requisito que gera o risco.

O probe **não incrementa `ROUND_YES`**. O contador do resumo (`yes: N (r01=…)`)
continua descrevendo só o que foi enviado como `yes` seco, e o `MAX_YES` continua
sendo o teto de perguntas respondidas.

**Aceitação:** `send_user "$REPLY_PROBE"` no caminho indeterminado · `send_user
"$REPLY_YES"` no caminho de pergunta · `ROUND_YES` inalterado pelo probe.

### R-D — uma garantia de "não escreveu", não duas

Consuma o **S-6**, sem o `R-19`. `prev_hash` e `cur_hash` já existem em `:954` e
`:988`, calculados antes do `case "$ROUND_OUTCOME"`. Derivar `spec_mudou` uma vez
logo após `:988`; os três consumidores passam a ser o ramo `aborto` do `case`
(`:995-996`), o bloco do `--dry-run` (`:1004-1016`) e a estagnação (`:1018`), que
hoje refaz a mesma comparação com os dois hashes crus.

O bloco dedicado do `--dry-run` (`:1002-1016`, 15 linhas) reduz-se a definir `rc`
e motivo: a verificação de que o ensaio não gravou nada passa a ser **o mesmo
código** que verifica os demais caminhos.

Aborto com `spec_mudou` verdadeiro emite linha destacada:

```
ATENÇÃO: o spec foi alterado numa rodada abortada
```

**Não nasce `rc` novo.** A tabela de códigos de saída continua com 0, 1 e 2. O
`rc=4` é do `R-19`, deliberadamente fora de escopo: numa ferramenta pessoal
invocada à mão, o resumo na tela é o consumidor, não um script (`E-13` do
estudo). A narração é de graça porque o booleano já está calculado; o código de
saída custaria uma decisão de contrato que ninguém pediu.

**Aceitação:** `--dry-run` real com `delta +0` e hash inalterado, verificado pelo
caminho comum · o bloco de 15 linhas some · aborto com spec alterado narra a
linha destacada e sai `rc=1`.

O ramo `indeterminada)` do `main_loop` (`:997-999`) vira código morto com o `R-B`
e sai junto — `ROUND_OUTCOME=indeterminada` não é mais atribuído em lugar nenhum.

### R-E — `revisar:` fecha todo resumo

Traz o **M-05**. Última linha do resumo, sempre, inclusive em convergência limpa
com `rc=0`. Sem branch e sem commit por rodada, a forma é a da terceira linha da
tabela de modos da spec de evolução (`§Resumo consolidado`):

```
revisar:  git -C <repo> diff -- <spec>
```

Fica **abaixo** do `reverter:` que já existe (`:1052`). A coluna de rótulos
permanece em 10 caracteres: `contrato:`, `reverter:` e `revisar:` cabem.

É o único ponto do desenho em que o humano volta ao laço. Não obriga ninguém a
ler — isso é a fronteira do que um harness pode fazer.

**Aceitação:** `revisar:` é a última linha em todo caminho de saída de `main_loop`,
inclusive `rc=0` e `--dry-run`.

---

## Fixtures — ficam, com o valor esperado invertido

`P-6` é literal e as 17 fixtures de prosa (`FIX_MC`, `FIX_MC_PT_FEM`,
`FIX_REPORT_NEGRITO_PT`, `FIX_REPORT_COMANDO_PT`, …, `:1061-1290`, ~230 linhas)
foram capturadas de rodadas reais — os comentários ao lado citam o custo em dólar
de cada rodada que as produziu. Elas não saem.

Sai o **valor esperado**, não o caso:

```bash
assert_out "pergunta em pt no feminino"  indeterminada  classify "$FIX_MC_PT_FEM"
```

Isso não é teste morto: é o **trinco da poda**. São **dezesseis** asserções que
hoje derivam um rótulo da prosa (`:1497-1519`); se alguém reintroduzir uma
alternância, elas ficam vermelhas na hora. As cinco que já esperam
`indeterminada` (`:1501-1503`, `:1522`, `:1524`) não mudam.

Três casos melhoram de significado. `FIX_SENT_PROSA`, `FIX_SENT_CRASE` e
`FIX_SENT_INVALIDA` hoje afirmam "cai na heurística → `pergunta-pendente`"
(`:1539-1541`); passam a afirmar "não classifica → `indeterminada`", que é a
propriedade que realmente importa numa sentinela citada, cercada ou inválida.

`FIX_SENT_VS_HEUR` (`:1538`) continua devolvendo `rodada-completa`; o nome do caso
muda de "a sentinela vence a heurística" para o que ele agora prova — que um
marcador de pergunta na prosa não interfere no contrato.

---

## Contabilidade do tamanho

**Medida depois da entrega, e a estimativa estava errada.** Os números abaixo saem
de `git show --numstat` em cada commit da série, um commit por requisito:

| movimento | estimado | **medido** |
|---|---|---|
| `R-A` — heurística: 4 constantes, `has_re`, ramo de fallback, comentário datado | −65 | **−50** |
| `R-B`+`R-C` — `SENT_MISS_MAX`, `miss_action`, `REPLY_*`, ramo da sonda | +21 | **+36** |
| `R-D` — `spec_mudou`, a linha destacada, o `--dry-run` colapsado | −8 | **+11** |
| `R-E` — `revisar:` | +2 | **+4** |
| fixtures (`P-6`) | ±0 | **±0** |
| **líquido** | **≈ −50** | **+1** |

**1786 → 1787 linhas.** O arquivo terminou uma linha **maior** do que começou, e
a promessa de `−50` não se cumpriu. Duas causas, ambas de comentário e nenhuma de
código:

- o `R-D` foi estimado como redução e é aumento: o bloco do `--dry-run` cai de 15
  para 13 linhas, não para 3, porque preservar a mensagem `1 pergunta
  classificada` custa as linhas do `case`; e o ramo `aborto` ganha o parágrafo que
  explica por que o `rc` continua `1`;
- a rede custa `+36` e não `+21`: o `REPLY_PROBE` é texto de contrato, e no tom
  deste arquivo ele vem com o parágrafo que explica **por que** não é um `yes`.

**A contagem de linhas não era o ponto, e não se corta comentário para consertar
uma métrica.** O ganho é o que a spec prometeu de fato: uma verdade em vez de duas
sobre a mesma decisão, e um lugar só para consertar quando a classificação falhar.
Este arquivo vale pelos comentários que registram o custo em dólar de cada
decisão; enxugá-los para chegar a 1736 seria trocar o certo pelo bonito.

---

## Correção da spec de evolução, no mesmo commit

Esta spec inverte a `§Ordem de entrega` da
`2026-07-21-speckit-clarify-loop-evolucao-design.md` (Fase 3 → Fase 2 → Fase 4).
Sem a correção, aquele documento passa a descrever um plano que ninguém vai
seguir. Cirurgia, não enxugamento: o texto diferido fica onde está, porque é
evidência (`P-6` vale para o documento).

| alvo | alteração |
|---|---|
| `§Ordem de entrega` (Parte I) | reescrita: Fase 0 → Fase 1 → **poda (esta spec)**. Fase 2 e Fase 4 **Deferidas**, com a razão em uma linha e ponteiro para `docs/estudos/refatoracao-final-speckit-clarify-loop.md` |
| `D-4` (tabela de planos) | planos 2, 3 e 4 marcados como não entregues |
| `R-08` | reescrito: a heurística **não é mais fallback**; a sentinela é caminho único |
| `R-16` | atualizado com o relaxamento do R-B (cai a cláusula `ROUND_YES > 0`) |
| `S-6` | anotado: entregue sem o `R-19`, portanto sem `rc=4` |
| `M-08` | atualizado: o gatilho agora é todo turno indeterminado, não só o do R-16 original |
| `M-05` | marcado entregue, na forma sem branch |
| `§Pronto quando` (I e II) | recortadas para o entregue |
| Fase 2 inteira, `R-17`, `R-18`, `R-19`, `R-20`, `R-21`, `R-22`, `M-01`, `M-02`, `M-09`, `M-10`, `M-11`, `§Resumo consolidado` | marcados **Deferido**, texto preservado |

**No script:** o comentário `S-4` (`:249-253`) é reescrito por necessidade — ele
diz *"nenhuma alternância nova entra **aqui**"* e não haverá mais um "aqui". A
substituição declara a regra pós-poda: falha de classificação é bug do
`SENTINEL_PROMPT`, e a heurística não volta. Fecha o `E-2` do estudo, que
perguntava se o fallback era permanente por desenho.

---

## Pronto quando

- ✅ `--self-test` limpo, com o contador automático subindo sozinho a partir dos
  139 de hoje. **143 casos**, os 4 novos sendo os da `miss_action`.
- ✅ `classify` sem sentinela → `indeterminada` nas 21 asserções de prosa, que
  ficam como o **trinco da poda**.
- ✅ `grep -c 'SIG_\|has_re'` devolve 0.
- A decisão de parada exercitada por `assert_out`, e não por `assert_emit`: com o
  limiar numa função pura que **recebe** o contador, não há estado a preservar.
- ⚠️ **Não coberto pelo auto-teste, por construção:** o envio do `REPLY_PROBE`, o
  aborto no 2º indeterminado consecutivo, o `spec_mudou` em cada caminho de saída
  e o `revisar:` como última linha vivem em `run_round`/`main_loop`, que falam com
  o repo e com o processo `claude`. O auto-teste é sem repo e sem custo (`P-3`), e
  inventar um teste que precise de repo trairia o princípio. A verificação destes
  quatro é o `--dry-run` real abaixo.
- ⬜ Um `--dry-run` real com `delta +0` e hash inalterado, verificado pelo caminho
  comum do R-D e não por bloco próprio. **Pendente — exige execução paga.**
- ⬜ Nota datada no cabeçalho, no padrão do arquivo, registrando repo, custo e
  `sentinela: N/M`. **Pendente, junto com o item acima.**
- ✅ Spec de evolução corrigida conforme a tabela acima.
- ❌ ~~`wc -l` menor que 1786.~~ **Não satisfeito: 1787.** Ver
  `§Contabilidade do tamanho` — a estimativa de `−50` estava errada e o critério
  não sobrevive à medição. Mantido riscado, e não apagado, porque a estimativa
  furada é evidência de como este documento errou (`P-6`).

---

## Risco aceito

O `S-4` pedia `sentinela: M/M` sustentado por **5 execuções reais** e existem
**2** verificadas (`tools/speckit-clarify-loop:36-50`: 1/1 turnos em `--dry-run`,
4/4 turnos numa rodada paga). **A poda antecipa a evidência.**

O R-B relaxado e o R-C são a rede que torna a antecipação recuperável em vez de
fatal: um turno sem sentinela custa uma sonda, não uma rodada paga. Se o contrato
falhar, o sintoma aparece em `contrato: sentinela em N/M turnos` no resumo e num
`warn` por turno, antes de custar caro.

Desfazer é reinstalar a versão anterior — a ferramenta se instala por cópia, e a
reversão é um comando.

**Risco residual, inalterado:** o modelo continua tomando decisões de produto que
ninguém leu no momento em que foram tomadas. `M-04` (entregue na Fase 1) torna a
leitura barata; `R-E` a lembra. Nenhum dos dois obriga ninguém a ler. Conter isso
de verdade é a Fase 4, deferida — e o estudo condiciona abri-la a duas respostas
que ainda não existem: se o autor de fato lê o resumo de decisões (`E-11`), e que
teste autoriza o loop a escrever no histórico do repo-alvo, dado que o auto-teste
é por construção sem repo (`E-9`).
