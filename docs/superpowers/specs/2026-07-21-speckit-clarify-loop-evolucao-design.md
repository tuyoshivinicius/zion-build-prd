# Evolução do `speckit-clarify-loop`

Spec de implementação. Alvo: o script verificado em 2026-07-21 contra
`claude 2.1.216` e a skill `speckit-clarify`.

Fases são incrementos mergeáveis. A ordem importa num ponto só: a Fase 0 produz
os dados que a Fase 2 consome para calibrar.

O script é ferramenta pessoal, instalada por cópia no PATH. Não aparece em
`docs/prd.md` nem em `docs/architecture.md` e está fora do canon do harness —
o dever de canonização do `CLAUDE.md` não se aplica a esta mudança.

---

## Princípios

| | |
|---|---|
| **P-1** | Assimetria de custo governa a parada. Parar cedo = uma invocação a mais. Parar tarde = dólar + spec estragado + humano lendo diff. No empate, continua — salvo sinal de deriva. |
| **P-2** | Prosa não é contrato. Nenhum sinal de controle novo pode depender de casar texto livre de LLM. |
| **P-3** | Decisão é função pura (entra número/texto, sai token). Coleta impura fica separada. Tudo exercitável pelo `--self-test`, sem repo e sem custo. |
| **P-4** | Sensor novo entra em modo narrativo; vira critério de parada só depois de medido. |
| **P-5** | Limiar carrega comentário dizendo se é chute ou evidência — com data, repo e número, no padrão de `ROUND_TIMEOUT` e `pick_cost`. |
| **P-6** | Simplificação (itens `S-`) só entra quando remove duplicação de fonte de verdade ou um vetor de crescimento. Nunca apaga fixture capturada de rodada real: aquilo é evidência, não entulho. |

## Não mexer

`ratelimit_fatal` com `allowed_*` permissivo · `timeout` embrulhando o `claude`
(e não watchdog em subshell) · perfil `plain` forçado no `round-NN.log` ·
`--dry-run` conferindo o próprio hash.

---

## Decisões desta sessão

Quatro pontos que a spec original deixava em aberto ou definia contra a
evidência. Cada um altera requisitos nomeados adiante; as tabelas de fase já
vêm com a alteração dobrada dentro.

### D-1 — `count_markers` é sensor de transição, com abstenção

Altera **R-12** e **R-13**.

Contagem de `[NEEDS CLARIFICATION]` nos specs reais dos dois repos alvo, medida
em 2026-07-21:

| repo / spec | marcadores |
|---|---|
| zion-mermaid-editor-app / 001-cano-modelo-codigo | 0 |
| zion-test-build-prd / 001…006 (seis specs) | 0 |

Zero em sete de sete, incluindo os dois specs contra os quais o loop já rodou de
verdade. A regra original — `marcadores == 0` → parada dura — dispararia na
rodada 1, sempre, em todo repo existente: com `--sensors=stop` o loop viraria
"uma rodada e sai".

A assinatura passa de `spec → inteiro` para
`(snapshot, spec) → caiu-a-zero | ativo | abstem`:

- **`caiu-a-zero`** — a contagem caiu de >0 para 0 nesta rodada. Parada dura.
- **`ativo`** — ainda há marcadores. Nenhum efeito na parada.
- **`abstem`** — a contagem era 0 antes e depois. O sensor não entra no
  `eval_sensors`, nem como duro nem como macio.

Narrado nos três estados, inclusive na abstenção — que é a evidência de que
aquele repo não usa marcadores.

### D-2 — `contrato de saída quebrado` não é caminho de parada

Fecha o buraco do **R-09**, que nomeava o estado sem dizer o que ele faz, e cuja
consequência não tinha entrada na tabela de `rc` do **R-20**.

`SENT_MISS` conta os turnos sem sentinela. O segundo miss consecutivo emite
`emit_note warn` destacado e o resumo ganha `sentinela: N/M turnos`. A
classificação segue pela heurística de fallback. Não há `rc` novo: a tabela do
R-20 fica com cinco linhas.

Por P-1 — abortar por sentinela ausente descarta rodada paga, que é exatamente a
classe de bug que a Fase 1 existe para matar. O sinal fica visível para o S-4
sem poder de veto.

### D-3 — `reverter:` imprime intervalo e sugere `--soft`

Altera **R-22**. O resumo passa a trazer:

```
commits:  <base>..HEAD (N)
          r01 <sha>  r02 <sha>  r03 <sha>
reverter: git -C <repo> reset --soft <base>
```

`--soft` desfaz os commits do loop e deixa o resultado inteiro staged, para
escolha manual do que fica. Descartar só a última rodada vira
`git reset --hard <sha-da-rodada-anterior>`, com o SHA já impresso acima. O
`reset --hard <base>` da spec original não cobria o caso em que uma rodada
abortada (rc=4) deixou o spec alterado e não commitado.

### D-4 — Escopo da entrega

Este documento cobre as cinco fases e é a fonte de verdade da ordem. Os planos
de implementação saem por fase, e cada `M-` da Parte II viaja no plano da fase
de que ele depende — não num plano de mitigação separado:

| plano | fases | `M-*` | estado |
|---|---|---|---|
| 1 | Fase 0 + Fase 1 | M-06 M-07 M-03 M-04 M-12 (guarda e parsing) | entregue |
| 2 | Fase 3 | M-08 | não entregue — ver estudo |
| 3 | Fase 2 (em `warn`) | — | não entregue — ver estudo |
| 4 | Fase 4 | M-01 M-02 M-05 M-09 M-10 M-12 (nome de branch) | não entregue — ver estudo |
| — | Fase 5 | M-11 | não agendada (R-23 pede ≥10 execuções pagas em ≥2 repos) |

**Nota de 2026-07-21.** A poda entregou, fora desta tabela, o `R-16` relaxado, o
`S-6` sem o `R-19`, o `M-05` e o `M-08`. Ver `§Ordem de entrega`.

Distribuir em vez de agrupar tem uma razão só: o M-06 fecha um risco que a
Fase 1 **cria**. Num plano próprio, entre o merge da Fase 1 e o dele o
vazamento seria silencioso.

### E-1 — A sentinela vai inline no `--append-system-prompt`

`claude 2.1.216` oferece `--append-system-prompt` e `--append-system-prompt-file`
(verificado). Fica o inline: mantém o texto do contrato numa constante do script,
ao lado do `classify` que o lê, sem arquivo temporário para gerenciar no `$WORK`
e sem um segundo ponto de falha no arranque da rodada.

### E-2 — A linha da sentinela fica visível na narração

Filtrá-la exigiria um segundo caminho de renderização no ramo `text` do
`render_line`. Custa uma linha por turno e é a prova visual de que o contrato
está de pé enquanto o S-4 não fecha.

---

## Fase 0 — Instrumentação

Não altera nenhuma decisão. Produz a evidência das fases seguintes.

| id | requisito | aceitação |
|---|---|---|
| **R-01** | `LOG_DIR` vira `/tmp/speckit-clarify-loop/<YYYYmmdd-HHMMSS>/`; remover o `rm -f` do `preflight`; symlink `latest`; resumo imprime o diretório da execução. | duas execuções deixam dois diretórios íntegros |
| **R-02** | Snapshot antes da rodada: `snap="$WORK/snap-$tag.md"; cp "$SPEC" "$snap"` (no `WORK`, já coberto pelo `trap`). | `--dry-run` mantém `delta +0` |
| **R-03** | Funções de coleta contra `(snapshot, spec)` — nunca contra `HEAD`. | números batem com `git diff --stat` |
| **R-04** | Linha `sensores · …` narrada em **toda** rodada via `emit_note ok`. | aparece no `round-NN.log` mesmo sob `--quiet` |
| **R-05** | `custo/linha` = `ROUND_COST / (add+del)`, com guarda de divisão por zero. **Narrado, nunca ligado** — ver R-25. | fora de `eval_sensors` |
| **S-1** | Colapsar `assert_classify`, `assert_kind`, `assert_dedup`, `assert_fatal` e `assert_render` no `assert_out` que já existe (`assert_out "desc" esperado funcao args…`). Mantém `assert_emit` para o caso com estado, e um shim de uma linha para o `ratelimit_fatal`, que devolve por status. **Fazer antes do R-06.** | 5 helpers a menos, e o R-06 passa a instrumentar 2 pontos em vez de 8 |
| **R-06** | `ST_COUNT` incrementado nos helpers de asserção, substituindo o literal `(92 casos)`. | acrescentar um caso faz o número subir sozinho |
| **S-2** | Substituir `mon_prefix` por cálculo a partir do próprio marcador (`2+5+2+${#marcador}+2`) e apagar a função e seus dois testes. | `⚙` = 1 caractere → 12; `[tool]␣␣` = 8 → 19, idênticos aos literais de hoje. Os `assert_render` já fixam as colunas do resultado, então os testes de `mon_prefix` eram redundantes |
| **S-7** | `--disallowedTools $MUTANTES` no `--dry-run`, em vez de repetir a lista literal em `args`. Word-splitting intencional, comentado. | uma fonte de verdade para a família que escreve |

**R-03 — funções:**

| função | devolve |
|---|---|
| `diff_numstat` | `"add del"`, garantindo duas colunas mesmo sem mudança |
| `added_lines` | linhas adicionadas, sem o `+` |
| `added_fences` | nº de cercas de código criadas |
| `headings_of` / `new_headings` | títulos do arquivo / nº de títulos criados |
| `touched_sections` | seções tocadas (fill-down `awk`, atribuindo cada linha ao título acima dela **no arquivo novo**) |
| `count_markers` | nº de `[NEEDS CLARIFICATION]` de um arquivo (a decisão de transição é do sensor — D-1) |

Acrescentar ao `need_deps`: `comm sort diff cut cp`.

---

## Fase 1 — Contrato de saída

Encerra a classe de bug mais cara do histórico do arquivo (sete comentários
datados, >US$ 20 em rodadas boas descartadas por variação de prosa).

**R-07 — sentinela via `--append-system-prompt`** (aditivo, não `--system-prompt`;
inline, não `-file` — ver E-1):

```
Ao final de CADA turno seu, emita como ÚLTIMA LINHA da mensagem, sozinha:

CLARIFY_STATE: ASKING

Use exatamente um destes três valores:
- ASKING       você apresentou uma pergunta de clarificação e aguarda resposta
- COMPLETE     você encerrou a rodada e apresentou o relatório final
- NO_AMBIGUITY você não encontrou ambiguidade crítica que justifique perguntar

Essa linha é lida por um script. Não a traduza, não a formate, não a envolva em
crase, negrito ou bloco de código, e não escreva nada depois dela.
```

O M-03 acrescenta uma segunda família de linhas ao mesmo contrato, e o M-07 uma
proibição; a ordem entre elas está fixada no D-7. O `CLARIFY_STATE` continua
sendo a última linha da mensagem em qualquer combinação.

**R-08 — `classify` lê a sentinela; heurística vira fallback.**

```bash
read_sentinel() {  # texto → ASKING|COMPLETE|NO_AMBIGUITY|'' se ausente
  printf '%s' "${1:-}" \
    | grep -oE '^CLARIFY_STATE: (ASKING|COMPLETE|NO_AMBIGUITY)$' \
    | tail -n 1 | sed 's/^CLARIFY_STATE: //'
}
```

Ordem: sentinela → mapeia direto (`ASKING`→`pergunta-pendente`,
`COMPLETE`→`rodada-completa`, `NO_AMBIGUITY`→`loop-seco`); ausente → heurística
atual **inalterada**, com todas as constantes bilíngues e a `SIG_NEXT_RE`.
Âncora `^…$` (sentinela citada em prosa não conta); `tail -n 1` (última vence).

**Superado em 2026-07-21.** A heurística saiu: a sentinela é caminho único, e um
turno sem ela vira `indeterminada`, que sonda em vez de abortar (`R-16` relaxado
+ `M-08`). O `S-4` está consumado.

**R-09 — ausência é narrada, repetida é alarme, nenhuma das duas para a rodada.**
Contador `SENT_MISS` por rodada; um turno sem sentinela → `warn`; dois seguidos →
`emit_note warn` destacado com `contrato de saída quebrado`. A classificação
segue pela heurística nos dois casos, e nenhum `rc` novo nasce daqui — ver D-2.
Resumo reporta `sentinela: N/M turnos`.

**R-10 — fixtures:** três valores válidos · ausente cai na heurística · em prosa
não conta · em crase não conta · duas sentinelas, última vence · valor
desconhecido cai na heurística · dois misses consecutivos não mudam o `rc`. As
fixtures bilíngues existentes passam a testar o fallback.

**S-3 — colapsar a família `SIG_*` de pergunta numa regex.** Os seis literais
(`SIG_MC`, `SIG_MC_PT`, `SIG_MC_PT_F`, `SIG_SHORT`, `SIG_SHORT_PT`,
`SIG_SHORT_PT_F`) têm todos a mesma forma — `**`, o adjetivo, `:` — e viram uma:

```bash
SIG_ASK_RE='\*\*(Recomendad[oa]|Sugerid[oa]|Recommended|Suggested):'
```

O par seco (`SIG_DRY`/`SIG_DRY_PT`) vira uma alternância. O par de fecho
(`SIG_COMPLETE`/`SIG_COMPLETE_PT`) **fica como está**: seus dois membros aparecem
sem âncora, com semântica diferente da `SIG_NEXT_RE`, e fundi-los reintroduziria
o risco de casar prosa. Resultado: 13 constantes e duas funções de casamento
(`has_sig`, `has_re`) → 4 sinais e uma função; `has_sig` sai.

**S-4 — congelar a heurística.** Depois que `sentinela: M/M` se sustentar por 5
execuções reais, **nenhuma alternância nova entra em `SIG_*`**. Falha de
classificação passa a ser bug do contrato (R-09), corrigido no
`--append-system-prompt`. É a regra que impede o arquivo de acumular outros sete
comentários datados de US$.

---

## Fase 2 — Sensores de parada

> **Deferida.** Ver `§Ordem de entrega`. Vale para a fase inteira, incluindo o
> seletor `--sensors` e a linha de narração por rodada.

**R-11 — três famílias, não uma escala:**

| família | significa | `rc` | ação humana |
|---|---|---|---|
| duro | acabou de verdade | 0 | nenhuma |
| macio | rendimento caiu | 0 | nenhuma |
| deriva | a rodada pode ter **piorado** o spec | 3 | revisar o diff |

**R-12 — sensores puros** (`SENSOR_MIN_YES=2`, `SENSOR_MIN_CHURN=5` — chutes até R-24):

| sensor | entrada → saída | fundamento |
|---|---|---|
| `sensor_marcadores` | snapshot, spec → `caiu-a-zero`\|`ativo`\|`abstem` | contabilidade do próprio Spec Kit, não heurística — mas só decide na transição (D-1) |
| `sensor_yes` | nº yes → `firme`\|`quieto` | a série 5·5·3·1 descreve convergência melhor que linha |
| `sensor_churn` | add, del → `farta`\|`magra` | soma add **e** del: reescrever requisito é trabalho |
| `sensor_escopo` | seções → `util`\|`so-registro` | diff só em `## Clarifications` = respostas no-op |
| `sensor_deriva` | cercas, títulos novos → `limpo`\|`deriva` | independente de língua e template (P-2) |

`sensor_escopo` reconhece `Clarifications`/`Clarificações`/`Clarificacoes`.
`sensor_deriva` não tenta reconhecer nome de seção.

**R-13 — `eval_sensors`** (com `FADIGA` persistindo entre rodadas):

1. `deriva` → para, e **vence até `loop-seco`**.
2. `sensor_marcadores` = `caiu-a-zero` → parada dura. `ativo` e `abstem` não
   param nada; `abstem` também não conta como sinal macio.
3. Sinais macios (`yes` quieto, churn magro, escopo só-registro): ≥2 na mesma
   rodada param na hora; exatamente 1 incrementa `FADIGA` e dois strikes seguidos
   param; nenhum zera `FADIGA`.

OU nos fortes, dois strikes nos fracos, **nunca consenso** — consenso erra para o
lado caro (P-1).

**R-14 — `--sensors=off|warn|stop`, default `warn`.** `warn` computa e narra sem
parar; torna a fase segura de mergear antes da calibração. Default vira `stop` no
commit que registra os números (R-24).

**R-15 — self-test:** cada sensor nos dois extremos e na borda ·
`sensor_marcadores` nos três estados, com a abstenção explicitamente exercitada ·
`eval_sensors` para deriva-vence-tudo, marcador-caiu-a-zero,
marcador-abstem-não-para, dois-macios, rodada-farta · sequência de dois strikes
exercitada **no shell corrente** (padrão `assert_emit`; `$(...)` perderia o
`FADIGA`).

**S-5 — extrair `assess_round`.** Coleta (R-03), avaliação (R-13) e narração
(R-04, R-05) saem do `main_loop` para uma função única, devolvendo por
`STOP_KIND`/`STOP_WHY` como o `run_round` já faz com os `ROUND_*`. Sem isso a
Fase 2 acrescenta ~12 linhas de coleta inline a um laço que já é o trecho mais
longo do arquivo; com isso o `main_loop` volta a ser só driver.

---

## Fase 3 — Semântica de parada e falha

> **Parcialmente entregue em 2026-07-21:** o `R-16` (relaxado) e o `S-6` (sem o
> `R-19`). O `R-17`, o `R-18`, o `R-19` e o `R-20` seguem **Deferidos**. Ver
> `§Ordem de entrega`.

| id | requisito | por quê |
|---|---|---|
| **R-16** | `indeterminada` isolada deixa de ser fatal: 1ª com `ROUND_YES > 0` narra e envia `yes`; 2ª **consecutiva** aborta; com `ROUND_YES == 0` aborta na 1ª (atual). | ambíguo lido como pergunta gasta um `yes` (o `MAX_YES` cobre); lido como fim descarta rodada paga (nada cobre) |
| **R-17** | Estouro de `MAX_YES` vira `rodada-completa`, não `aborto`. | o spec está íntegro; só ficou mais longo |
| **R-18** | `--max-yes N`, default 5, mantendo o comentário de origem. | se a skill mudar para 7, o script descarta rodada legítima |
| **R-19** | Comparar hash inicial/final em **todo** caminho de aborto. Diferiu → `rc=4` + linha destacada `ATENÇÃO: o spec foi alterado numa rodada abortada`. Igual → `rc=1`. | o `TERM` do `ROUND_TIMEOUT` ainda deixa spec meio escrito; hoje o resumo trata os dois casos no mesmo tom |
| **S-6** | Generalizar a comparação do R-19 para **todo** caminho de saída de rodada, não só aborto. O bloco dedicado do `--dry-run` no `main_loop` reduz-se a definir `rc` e motivo. | a verificação de "não escreveu" do `--dry-run` passa a ser o mesmo código; uma garantia em vez de duas, e ~15 linhas de ramificação viram 3 |

**R-16 — alterado na entrega.** A cláusula `ROUND_YES > 0` caiu. Com a heurística
removida, o caso mais provável — rodada 1, turno 1, sentinela esquecida — cairia
em aborto na primeira, que é a classe de bug que a Fase 1 existe para matar. O
primeiro turno indeterminado nunca é fatal; o contador é o `SENT_MISS`, não um
`IND_STREAK` novo.

**S-6 — entregue sem o `R-19`.** A comparação foi generalizada e o aborto com
spec alterado ganha linha destacada, mas nenhum `rc` novo nasce. A tabela do
`R-20` segue deferida com os três códigos de hoje.

**R-17, R-18, R-19 — Deferidos.** Ver `§Ordem de entrega`.

**R-20 — tabela de `rc` no cabeçalho do arquivo:**

> **Deferido.** Ver `§Ordem de entrega`. O arquivo continua com os três códigos
> de hoje (0, 1, 2); as linhas 3 e 4 abaixo não existem no script.

| `rc` | significado |
|---|---|
| 0 | convergiu (duro, macio, `loop-seco`, estagnação) ou `--self-test`/`--dry-run` limpo |
| 1 | guarda sem convergência, ou aborto com o spec **intacto** |
| 2 | erro de uso ou ambiente |
| 3 | deriva — o spec pode ter piorado |
| 4 | aborto com o spec **alterado** — revisão obrigatória |

Cinco linhas, e só cinco: contrato de saída quebrado (R-09) não é caminho de
parada e não ganha `rc` — ver D-2.

---

## Fase 4 — Custo e auditoria

> **Deferida.** Ver `§Ordem de entrega`. Vale para o `R-21`, o `R-22` e todos os
> `M-` que viajavam no plano 4, exceto o `M-05`, entregue com a poda.

**R-21 — `MAX_ROUNDS`: default 3, teto 5, `--yes-i-know` acima.** O retorno cai
forte após a 2ª rodada e da 4ª em diante o clarify empurra decisão de
implementação para dentro do spec. Default 10 convida a rodar 10. Valores 4–5
passam com aviso.

**R-22 — commit por rodada.** Ao fim de cada rodada não abortada que alterou o
spec: `git -C "$REPO" commit -q -m "clarify: rodada NN (+K yes)" -- "$SPEC"`.
Nunca sob `--dry-run`. Sob `--allow-dirty` não commita (árvore tem trabalho
alheio) e narra o motivo. O resumo ganha, conforme D-3:

```
commits:  <base>..HEAD (N)
          r01 <sha>  r02 <sha>  r03 <sha>
reverter: git -C <repo> reset --soft <base>
```

Efeito: `git diff HEAD~1` julga rodada a rodada — o que permite descartar a
rodada 3 quando ela só inchou, com `git reset --hard <sha da r02>`.

---

## Fase 5 — Calibração (protocolo, não código)

| id | requisito |
|---|---|
| **R-23** | Rodar com `--sensors=warn` por ≥10 execuções reais, em ≥2 repos, com specs de tamanhos diferentes. A linha de R-04 já dá a tabela `(rodada, yes, add, del, escopo, deriva, custo, custo/linha)`. |
| **R-24** | Substituir os dois limiares pelos valores observados, com comentário datado no padrão do arquivo. Só então `--sensors` passa a `stop` por default. |
| **R-25** | Decidir se `custo/linha` vira sensor. Critério: separação limpa entre rodadas produtivas e improdutivas nos dados. Sem separação, permanece narrado e fora de `eval_sensors`. |

---

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

## Pronto quando (Parte I)

> Recortado ao entregue. Os critérios de Fase 2 e Fase 4 seguem deferidos.

`--self-test` limpo com contador automático e cobertura de todo sensor puro,
dos três estados do `sensor_marcadores` e da leitura da sentinela · `--dry-run`
real com `delta +0`, hash inalterado e nenhum commit · ~~uma execução com
`--sensors=warn` mostrando a linha de sensores em toda rodada~~ e
`sentinela: M/M` · ~~cabeçalho com a tabela de `rc`~~ e nota de verificação
datada · nenhuma constante `SIG_*` acrescentada depois da Fase 1 (S-4) — **e,
desde 2026-07-21, nenhuma `SIG_*` existindo: a poda as removeu.**

---

# Parte II — Mitigação de contaminação

A Parte I faz o laço convergir. Esta trata do risco de ele degradar o `spec.md`
que deveria melhorar.

Depende inteiramente dos `R-*` da Parte I. Requisitos aqui são `M-*`.

---

## Modelo de risco

| vetor | origem | mitigação |
|---|---|---|
| **V1** — decisões de produto aceitas sem leitura humana | já existia no fluxo manual; a automação apenas remove a percepção periférica de ver a pergunta passar | M-01, M-04, M-09 |
| **V2** — sentinela vaza para dentro do spec, ou muda a noção de plateia do modelo | **introduzido pela Fase 1** | M-06, M-07, M-11 |
| **V3** — resposta enviada a um turno que não era pergunta | introduzido pelo R-16 | M-08 |

**V1 é o maior e o menos tratável.** Cada rodada são até 5 decisões tomadas
pelo modelo; com o teto de 3 do R-21, até 15 por execução. Nenhum `M-` elimina
isso — M-01 e M-04 tornam recuperável e legível, M-09 é o único que devolve
julgamento humano ao ponto onde ele rende.

---

## Decisões desta sessão (Parte II)

Cinco pontos que o texto original desta parte deixava em aberto ou definia
contra o código verificado. Cada um altera requisitos nomeados adiante; os
grupos já vêm com a alteração dobrada dentro.

### D-5 — a guarda de vazamento casa contra as linhas adicionadas

Altera **M-06**.

O texto original casava contra o spec inteiro (`grep -q '^CLARIFY_' "$SPEC"`),
com a justificativa de que a âncora `^` protegia a sentinela citada dentro de um
bloco de exemplo. Não protege: dentro de uma cerca a linha *está* no começo da
linha. O R-07 desta própria spec é o contra-exemplo — um spec que documente o
contrato aborta na rodada 1, e em toda rodada 1 seguinte, sem saída a não ser
editar o spec à mão.

A guarda passa a casar contra `added_lines "$snap" "$SPEC"` — a função que o
R-03 já entrega. Ocorrência preexistente não envenena a execução; vazamento
real é linha nova por definição.

### D-6 — as decisões saem do `.jsonl`, não do `.log`

Altera **M-04**.

O `round-NN.log` recebe a prosa do turno depois do `mon_fold`, que indenta a
continuação em 9 colunas. Uma linha `CLARIFY_DECISION:` no meio da mensagem
chega lá como `         CLARIFY_DECISION: …`, e a âncora `^` não casa nunca. A
fonte é o `round-NN.jsonl`, campo `.result` do evento `result` — o mesmo texto
que o `classify` já lê para achar a sentinela do R-08.

### D-7 — ordem fixa entre as duas famílias de sentinela

Altera **M-03** e **R-07**.

O R-07 fecha com "não escreva nada depois dela". O M-03 acrescenta uma segunda
linha ao contrato. Sem ordem declarada os dois se contradizem. A ordem é:

```
CLARIFY_DECISION: <assunto> -> <opção>
CLARIFY_DECISION: <assunto> -> <opção>
CLARIFY_STATE: ASKING
```

`CLARIFY_DECISION` primeiro, zero ou mais; `CLARIFY_STATE` sempre por último e
sempre exatamente uma. O R-08 já lê com `tail -n 1`, então a leitura da
sentinela de estado não muda.

### D-8 — o M-08 vale só no caminho indeterminado

Altera **M-08**.

O texto original dizia "substituir o `yes` cego do R-16", mas o `yes` não é do
R-16: o script o envia em **toda** pergunta classificada, e a skill documenta
literalmente `accept the recommendation by saying "yes"`. Trocar isso por um
parágrafo no caminho normal sairia do vocabulário da skill em toda rodada, e
tornaria o contador `yes: 12 (r01=5 …)` um nome que não descreve mais o que foi
enviado.

Duas constantes, dois caminhos:

| caminho | envia |
|---|---|
| `pergunta-pendente` | `REPLY_YES` = `yes` (inalterado) |
| `indeterminada` com `ROUND_YES > 0` (R-16) | `REPLY_PROBE` — o texto do M-08 |

### D-9 — branch vazio não sobrevive à execução

Acrescenta ao **M-01**.

Criar um branch no `preflight` é um efeito colateral que ninguém desfaz: uma
execução que aborta na rodada 1 deixa o humano parado num branch idêntico ao
base, e a próxima execução deixa outro.

Regra de saída, no `trap`:

- zero commits **e** hash do spec igual ao inicial → volta ao base e apaga o
  branch, narrado.
- qualquer outro caso → o branch fica. Em particular o `rc=4` do R-19, em que a
  rodada abortada deixou o spec alterado e não commitado: apagar o branch
  arrastaria a alteração de volta para o base, que é exatamente a contaminação
  que o M-01 existe para conter.

---

## G1 — Contenção

> **Deferido.** Ver `§Ordem de entrega`.

**M-01 — branch dedicado, ativo por default.**

```bash
BASE_BRANCH="$(git -C "$REPO" rev-parse --abbrev-ref HEAD)"
CLARIFY_BRANCH="$(clarify_branch_name "$(dirname "$SPEC")" "$(date +%Y%m%d-%H%M%S)")"
git -C "$REPO" checkout -q -b "$CLARIFY_BRANCH"
```

- Criado no `preflight`, depois da checagem de árvore limpa.
- `--no-branch` desliga. `--allow-dirty` **implica** `--no-branch` (a árvore tem
  trabalho alheio; não é do script decidir o que entra), narrado.
- `--dry-run` nunca cria branch.
- Nome do branch e branch base impressos no cabeçalho, antes da rodada 1.
- Saída conforme D-9.

O nome sai de `clarify_branch_name <dir-do-spec> <timestamp>`, função pura —
`clarify/<basename do dir>-<timestamp>` — pelo M-12.

Contenção só funciona se for o default. Opt-in não contém.

> **Deferido.** Ver `§Ordem de entrega`.

**M-02 — o resumo imprime as duas saídas, sempre.** Layout canônico e as três
combinações de modo estão na §"Resumo consolidado" adiante.

O objetivo é transformar contaminação de "algo que você desfaz" em "algo que
você não aceita".

---

## G2 — Revisão

**M-03 — linha de decisão no contrato de saída.**

Extrair o assunto de cada pergunta da prosa violaria P-2. Em vez disso, estender
o `--append-system-prompt` do R-07:

```
Quando você integrar uma resposta ao spec, emita também, em linha própria e
ANTES da linha CLARIFY_STATE:

CLARIFY_DECISION: <assunto em até 8 palavras> -> <a opção escolhida>

Mesmas regras da linha CLARIFY_STATE: sem tradução, sem formatação, e nunca
dentro de nenhum arquivo.
```

Ordem conforme D-7. Custo assumido: mais superfície de contrato = mais chance de
vazamento e de não-aderência. É por isso que o M-06 vigia o prefixo `CLARIFY_`
inteiro, e não só `CLARIFY_STATE`.

**M-04 — resumo das decisões no fim da execução.**

Montado a partir das linhas `CLARIFY_DECISION` capturadas nos `round-NN.jsonl`
(D-6), na ordem das rodadas:

```
decisões aceitas (12):
  r01  igualdade de rótulo          -> A (no parse)
  r01  feedback de falha de cópia   -> B (sinal transitório)
  …
```

Ausência da linha não é erro: cai para `decisões aceitas: 12 (texto
indisponível — contrato não aderiu)`. Linha malformada — sem a seta — é
descartada e conta para o mesmo fallback.

O problema de "ler o diff depois" não é preguiça: um diff de 200 linhas não
convida ninguém. Quinze linhas se leem.

**M-05 — `revisar:` como última linha do resumo, sempre.** Inclusive em
convergência limpa com `rc=0`. É o único ponto do desenho em que o humano volta
ao laço. Hoje não existe.

**Entregue em 2026-07-21**, na forma sem branch:
`revisar: git -C <repo> diff -- <spec>`.

---

## Resumo consolidado

> **Deferido.** Ver `§Ordem de entrega`. O layout de 11 colunas depende do
> `R-22` e do `M-02`, ambos diferidos; o resumo de hoje continua em 10, e o
> `M-05` foi entregue nessa largura.

Sete requisitos escrevem no mesmo resumo — R-09 (`sentinela:`), R-01 (`logs:`),
D-3/R-22 (`commits:`/`reverter:`), M-02, M-04, M-05, M-10. Sem um layout
canônico eles se atropelam. A coluna de rótulos passa de 10 para 11 caracteres
(`descartar:` e `sentinela:` são os mais longos).

```
—— resumo ——
repo:      /home/tuyoshi/projects/zion-test-build-prd
spec:      specs/006-code-interop/spec.md
base:      006-code-interop
branch:    clarify/006-code-interop-20260721-143012
rodadas:   3
yes:       12 (r01=5 r02=5 r03=2)
sentinela: 8/8 turnos
custo:     US$ 4,12
spec:      120 → 187 linhas (delta +67)
commits:   r01 a1b2c3d  r02 e4f5g6h  r03 i7j8k9l
logs:      /tmp/speckit-clarify-loop/20260721-143012
           round-NN.jsonl (stream) · round-NN.log (narração) · latest → esta execução
parada:    convergiu — a skill declarou não haver ambiguidade crítica

decisões aceitas (12):
  r01  igualdade de rótulo          -> A (no parse)
  r01  feedback de falha de cópia   -> B (sinal transitório)
  …

a seguir:  /speckit.checklist · /speckit.analyze
aceitar:   git checkout 006-code-interop && git merge --no-ff clarify/006-…
descartar: git checkout 006-code-interop && git branch -D clarify/006-…
revisar:   git diff 006-code-interop..HEAD -- specs/006-code-interop/spec.md
```

`revisar:` é sempre a última linha (M-05). `a seguir:` só aparece em `rc=0`
(M-10). O par `aceitar:`/`descartar:` substitui o `reverter:` do D-3 quando há
branch — com o branch, `reset --soft` é redundante:

| modo | linhas de contenção |
|---|---|
| branch ativo (default) | `base:` `branch:` `commits:` `aceitar:` `descartar:` `revisar:` |
| `--no-branch` | `base:` `commits:` `reverter: git -C <repo> reset --soft <base>` `revisar:` |
| `--allow-dirty` (implica `--no-branch`; o R-22 não commita) | `reverter: git -C <repo> checkout -- <spec>` (o de hoje) · `revisar: git -C <repo> diff -- <spec>` |

Os SHAs por rodada ficam nos dois primeiros modos: são eles que permitem
descartar só a rodada 3 com `git reset --hard <sha da r02>`.

---

## G3 — Contrato seguro

| id | requisito | nota |
|---|---|---|
| **M-06** | Após **cada** rodada: `added_lines "$snap" "$SPEC" \| grep -q '^CLARIFY_'` → `ROUND_OUTCOME=aborto`, `ROUND_ABORT='sentinela vazou para dentro do spec'`. | **Abortar, não limpar.** Limpeza silenciosa esconde que o contrato falhou. Casa contra as linhas adicionadas, não contra o spec inteiro — D-5. |
| **M-07** | Acrescentar ao contrato: `Nunca escreva essas linhas dentro de nenhum arquivo; elas pertencem apenas à sua mensagem.` | prevenção; M-06 é a rede |
| **M-08** | **Entregue em 2026-07-21.** No caminho `indeterminada` do R-16, enviar `REPLY_PROBE` em vez de `yes`: `Se você fez uma pergunta de clarificação, responda com a opção recomendada. Se a rodada já terminou, emita apenas a linha CLARIFY_STATE: COMPLETE.` | não pode ser lido como aprovação de uma ação inventada, e ainda recupera a sentinela. Pergunta classificada continua com `yes` seco — D-8. |

**M-06 antes do R-19.** O `rc=4` é do R-19, que é Fase 3 (plano 2), e o M-06 vai
no plano 1. No plano 1 o M-06 define `ROUND_OUTCOME`/`ROUND_ABORT` e sai pelo
`rc=1` existente, com linha destacada. Quando o R-19 generaliza a comparação de
hash a todo caminho de aborto, o `rc=4` passa a valer sem tocar no M-06 — o spec
foi alterado por construção, já que a linha vazada é linha nova. É o
comportamento correto nos dois momentos, e é o que permite o M-06 não esperar.

**M-08 — alterado na entrega.** O gatilho é todo turno `indeterminada`, não só o
caminho do `R-16` original: pós-poda os dois são o mesmo caminho.

---

## G4 — Processo (não é código)

> **Deferido.** Ver `§Ordem de entrega`.

**M-09 — rodada 1 fica com o humano.**

As perguntas de maior impacto estão na primeira rodada, que é também a mais
barata (spec ainda pequeno). Automatizar a rodada 1 entrega as decisões caras à
máquina para poupar o trabalho barato.

Fluxo recomendado, documentado no cabeçalho do script e no `usage`:

```
1.  /speckit-clarify à mão, aceitando ou não as recomendações
2.  speckit-clarify-loop --max-rounds 2
```

Único item que ataca V1 na raiz.

> **Deferido.** Ver `§Ordem de entrega`.

**M-10 — gates a jusante no resumo.** Em convergência (`rc=0`), a linha
`a seguir:` sugere `/speckit.checklist` e `/speckit.analyze`. Eles pegam o que
os sensores não veem: requisito incoerente, decisão técnica travestida de
requisito. É o uso que o próprio Spec Kit prescreve.

---

## G5 — Medição

> **Deferido.** Ver `§Ordem de entrega`.

**M-11 — verificar se o viés de audiência existe.**

Hipótese: dizer ao modelo que a saída é lida por um script pode fazê-lo escrever
o spec de forma mais telegráfica, ou otimizada para máquina onde deveria ser
para humano. É especulação — e especulação se mede.

Protocolo, com a Fase 0 no ar:

1. Mesmo repo, mesmo spec base, `git reset --hard` entre execuções.
2. Três execuções com contrato, três sem (`--no-contract`, flag temporária).
3. Comparar `yes` por rodada e churn por rodada nas duas amostras, a partir da
   linha `sensores · …` do R-04.

Distribuições parecidas → o viés não existe na prática; encerrar o assunto e
remover a flag. Distribuições distintas → enxugar o contrato, tirando a frase
`Essa linha é lida por um script` e deixando só a instrução. Menos explicação
pode custar aderência: é trade-off a medir, não a supor.

---

## G6 — Testes

**M-12** — no `--self-test`, via `assert_out` (após S-1). Parte no plano 1,
parte no plano 4, conforme o D-4:

| teste | plano |
|---|---|
| Guarda de vazamento: linha adicionada com `CLARIFY_STATE` no início dispara; a mesma string no meio de uma frase não dispara; ocorrência **já presente no snapshot** não dispara (D-5) | 1 |
| Parsing de `CLARIFY_DECISION`: linha bem-formada, linha ausente, linha com seta faltando, duas linhas na mesma mensagem | 1 |
| `clarify_branch_name <dir-do-spec> <timestamp>`: função pura, determinística | 4 |

---

## Dependências

| `M-` | precisa de |
|---|---|
| M-01, M-02 | R-22 (commit por rodada) — sem ele o branch guarda um blob só |
| M-03, M-04 | R-07 (contrato), R-01 (logs preservados por execução) |
| M-06 | R-03 (`added_lines`). O R-19 melhora o `rc` mas não bloqueia — ver G3 |
| M-08 | R-16 |
| M-11 | Fase 0 completa (R-04, R-05) |
| M-12 | S-1 (colapso dos helpers); a terceira linha também M-01 |

---

## Ordem de entrega

**M-06 + M-07** (fecham o risco que a Fase 1 introduziu; quatro linhas) →
**M-03 + M-04** (resumo de decisões) → **M-08** → **M-01 + M-02** (contenção) →
**M-05** (empurrão de revisão, uma linha) → **M-09 + M-10** (processo) →
**M-11**.

M-06 não deve ficar atrás da Fase 1 em produção: enquanto não existir, o
vazamento é silencioso. É a razão de os `M-` viajarem distribuídos pelos planos
das fases (D-4) em vez de num plano de mitigação próprio.

---

## Risco residual

Depois de tudo isto, permanece: **o modelo continua tomando decisões de produto
que ninguém leu no momento em que foram tomadas.** M-04 e M-05 tornam a leitura
barata e a lembram; M-01 torna a rejeição possível; M-09 preserva julgamento
humano onde ele mais rende. Nenhum deles obriga ninguém a ler.

Essa é a fronteira do que um harness pode fazer. O resto é disciplina, e não se
implementa em bash.

---

## Pronto quando (Parte II)

> Recortado ao entregue. Os critérios de Fase 2 e Fase 4 seguem deferidos.

`--self-test` cobrindo o M-12 · uma execução real ~~criando branch, imprimindo as
duas saídas do M-02~~ e terminando com a linha `revisar:` · resumo de decisões
legível a partir de logs reais · guarda de vazamento exercitada com um spec
adulterado à mão, saindo ~~`rc=4`~~ `rc=1` (o R-19 segue deferido — ver G3) · um spec que **cita** a sentinela numa cerca
rodando até o fim sem abortar (D-5) · ~~execução abortada na rodada 1 sem commit
deixando o repo no branch base, sem branch órfão (D-9)~~ · ~~protocolo M-11
executado e o resultado registrado como comentário datado, no padrão do arquivo.~~
