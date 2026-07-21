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
de implementação saem por fase:

| plano | fases | estado |
|---|---|---|
| 1 | Fase 0 + Fase 1 | próximo |
| 2 | Fase 3 | depois |
| 3 | Fase 2 (em `warn`) | depois |
| 4 | Fase 4 | depois |
| — | Fase 5 | protocolo de execução, não vira plano |

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
A heurística não sai: o contrato depende do modelo obedecer.

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

| id | requisito | por quê |
|---|---|---|
| **R-16** | `indeterminada` isolada deixa de ser fatal: 1ª com `ROUND_YES > 0` narra e envia `yes`; 2ª **consecutiva** aborta; com `ROUND_YES == 0` aborta na 1ª (atual). | ambíguo lido como pergunta gasta um `yes` (o `MAX_YES` cobre); lido como fim descarta rodada paga (nada cobre) |
| **R-17** | Estouro de `MAX_YES` vira `rodada-completa`, não `aborto`. | o spec está íntegro; só ficou mais longo |
| **R-18** | `--max-yes N`, default 5, mantendo o comentário de origem. | se a skill mudar para 7, o script descarta rodada legítima |
| **R-19** | Comparar hash inicial/final em **todo** caminho de aborto. Diferiu → `rc=4` + linha destacada `ATENÇÃO: o spec foi alterado numa rodada abortada`. Igual → `rc=1`. | o `TERM` do `ROUND_TIMEOUT` ainda deixa spec meio escrito; hoje o resumo trata os dois casos no mesmo tom |
| **S-6** | Generalizar a comparação do R-19 para **todo** caminho de saída de rodada, não só aborto. O bloco dedicado do `--dry-run` no `main_loop` reduz-se a definir `rc` e motivo. | a verificação de "não escreveu" do `--dry-run` passa a ser o mesmo código; uma garantia em vez de duas, e ~15 linhas de ramificação viram 3 |

**R-20 — tabela de `rc` no cabeçalho do arquivo:**

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

Fase 0 → Fase 1 → Fase 3 → Fase 2 (`warn`) → Fase 4 → Fase 5 (vira `stop`).

Fase 1 tem o maior retorno isolado; Fase 3 é barata e para de descartar rodada
boa desde já. O único erro de ordem que importa é Fase 2 antes da 0 — implica
escolher limiar no escuro.

Planos de implementação conforme D-4: Fase 0 + Fase 1 no primeiro; Fase 3,
Fase 2 e Fase 4 em planos próprios; Fase 5 não vira plano.

## Pronto quando

`--self-test` limpo com contador automático e cobertura de todo sensor puro,
dos três estados do `sensor_marcadores` e da leitura da sentinela · `--dry-run`
real com `delta +0`, hash inalterado e nenhum commit · uma execução com
`--sensors=warn` mostrando a linha de sensores em toda rodada e `sentinela: M/M`
· cabeçalho com a tabela de `rc` e nota de verificação datada · nenhuma
constante `SIG_*` acrescentada depois da Fase 1 (S-4).
