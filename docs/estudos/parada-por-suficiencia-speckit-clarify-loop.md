# Estudo — parada por suficiência no `speckit-clarify-loop`: quando já se clarificou o bastante

## Contexto

O `tools/speckit-clarify-loop` automatiza o ciclo `/speckit.clarify` do Spec Kit sob a invariante
"uma rodada = um processo `claude`" (`tools/speckit-clarify-loop:1-5`). Cada turno fecha com a
**sentinela** de estado, âncorada e legível por máquina (`:163-191`):

```
CLARIFY_STATE: ASKING | COMPLETE | NO_AMBIGUITY
```

O harness tem **quatro condições de parada automática** (`:1011-1054`):

| Parada | Gatilho | Código |
|---|---|---|
| `loop-seco` | a skill emite `NO_AMBIGUITY` | rc=0 |
| estagnação | 2 rodadas seguidas sem alterar o spec (`:1040-1045`) | rc=0 |
| teto de rodadas | `MAX_ROUNDS=10` (`:90`) | rc=1 |
| aborto | rate-limit fatal, negação de mutante, vazamento, contrato caído | rc=1 |

A pergunta que motiva este estudo não é sobre **adesão** do contrato — essa já foi medida e deu
100% (`docs/estudos/sentinela-execucao-zion-mermaid-editor-app.md:39-59`). É sobre **suficiência**:
**parar quando já se clarificou o bastante**, antes que rodadas marginais contaminem a `plan` com
sobre-especificação. O sintoma observado pelo Autor: o loop roda até alguém matá-lo — não até
convergir.

**Nota de canon.** O `speckit-clarify-loop` é ferramenta pessoal **fora do canon**: não está na
tabela de scripts (`docs/architecture.md §3`) nem em RF do `docs/prd.md §6`, que põe "não executa o
ciclo do Spec Kit" no fora-de-escopo (`docs/prd.md §4`). Nenhuma alternativa aqui toca `prd.md`,
`architecture.md` ou ADR algum; nenhuma supersessão entra como custo — o mesmo que a seção Contexto
dos estudos irmãos estabelece (`refatoracoes-roi-pos-run-speckit-clarify-loop.md:14-18`). Um estudo
sobre a heurística de parada dessa ferramenta não reflete em PRD/ADR e não aciona o `check-canon.sh`.

## A evidência — dois runs reais, zero paradas naturais

Existem dois runs de convergência reais cujos logs sobreviveram, ambos contra o
`zion-mermaid-editor-app`. **Em nenhum dos dois o loop parou sozinho.**

### Run 001 — `/tmp/speckit-clarify-loop/20260721-112131`

7 rodadas, R1–R6 em `COMPLETE`, **R7 cortada externamente** durante a primeira pergunta
(`sentinela-execucao-…:99-110`). Custo US$ 16,44. A condição de parada real foi: 6 rodadas completas
+ 1 interrompida — **não** a lógica do harness, que teria injetado o `yes` e seguido.

### Run 002 — `/tmp/speckit-clarify-loop/20260722-183628` (a última sessão)

O run que este estudo analisa. **5 rodadas, todas com a mesma forma**: 5 perguntas, 5 `yes`, fecho
`COMPLETE`, e a rodada seguinte encontrando 5 ambiguidades **novas**.

| Rodada | Turnos | Sentinela | `yes` | Decisões | +add | −del | Custo (US$) | Estados |
|---|---|---|---|---|---|---|---|---|
| R01 | 6 | 6/6 | 5 | 5 | 116 | 32 | 2,9127 | `ASKING`×5 → `COMPLETE` |
| R02 | 6 | 6/6 | 5 | 5 | 81 | 18 | 2,6360 | `ASKING`×5 → `COMPLETE` |
| R03 | 6 | 6/6 | 5 | 5 | 97 | 20 | 3,1033 | `ASKING`×5 → `COMPLETE` |
| R04 | 6 | 6/6 | 5 | 5 | 90 | 18 | 2,8720 | `ASKING`×5 → `COMPLETE` |
| R05 | 6 | 6/6 | 5 | 5 | 104 | 19 | 2,4808 | `ASKING`×5 → `COMPLETE` |
| **Σ** | **30** | **30/30** | **25** | **25** | **488** | **107** | **14,00** | — |

R5 fechou em `COMPLETE`, o spec mudou (`+104/−19`), então `same=0` e o `main_loop` iria para a
rodada 06. **Não existe `round-06.jsonl`** — o processo foi cortado antes de a próxima rodada nascer.
É a **mesma assinatura da R7 do run 001**: interrupção externa, não parada da lógica.

> **Custo — a ressalva do `pick_cost`.** Os US$ 14,00 são a **soma dos custos finais por rodada**
> (`total_cost_usd` do último `result` de cada `round-NN.jsonl`). Somar **todos** os `result` infla
> para ~US$ 49, porque o campo é acumulado da sessão e cresce a cada turno (`:344-357`). Cada rodada
> é uma sessão nova por invariante, então a soma por-rodada é a correta.

**Leitura.** Em dois runs reais consecutivos, o stop de fato foi o **humano matando o processo**. As
duas paradas por convergência (`loop-seco` e estagnação) **nunca dispararam**; o teto de 10 rodadas
seria o único freio automático, e é um `rc=1` de "falha", não de suficiência.

## A moldura do problema — por que os sinais naturais são inalcançáveis

Os dois gatilhos de convergência do harness são estruturalmente inatingíveis num spec rico:

1. **`NO_AMBIGUITY` nunca sai porque a skill é gulosa sem fundo.** A própria skill limita-se a 5
   perguntas por rodada, mas **nunca seca**: a cada nova rodada acha outras 5. No run 002 foram
   5 rodadas × 5 = 25 perguntas sem uma única `NO_AMBIGUITY`. A skill sempre encontra o que
   perguntar; logo o sinal de "não há mais ambiguidade" é emitido só quando o *processo* é
   interrompido, nunca por saturação.

2. **Estagnação nunca dispara porque churn ≫ decisões.** Integrar qualquer resposta faz a skill
   reescrever FRs, edge cases e critérios — não só anexar a decisão. No run 002, cada rodada mexeu
   entre **+81 e +116 linhas** (Σ +488/−107). O `spec_hash` muda em toda rodada, então o contador
   `same` (`:1040-1047`) volta a zero antes de chegar a 2. As duas rodadas idênticas que a
   estagnação exige não acontecem enquanto houver 5 perguntas por rodada reescrevendo o spec.

Sobram o **teto** (freio bruto, `rc=1`) e o **aborto** (erro). Nenhum é um sinal de "clarificamos o
suficiente"; são redes contra descontrole e falha.

### A marginalidade tardia é o dano à `plan`

A parte que fere a `plan` não é o custo — é o **conteúdo** das rodadas tardias. A carga de valor cai
de rodada em rodada, das decisões estruturais para a enumeração de casos-limite:

- **R1 — estrutura.** "O que *mover* significa" (toca `FR-009`/`SC-004`, código byte-idêntico);
  "agrupamento no envelope de densidade" (toca `NFR-03`, o orçamento de 400 nós/500 conexões). São
  decisões que mudam requisito de produto.
- **R5 — caso-limite sobre caso-limite.** "Teto do tamanho do texto colado" → *sem teto, medido não
  limitado*; "agrupar seleção vazia ou só conexões" → *nada nasce*; "agrupamento aninhado esvaziado"
  → *cascata até o nível com membro*. Cada resposta apenas **reafirma um invariante já decidido** —
  as próprias justificativas citam `RN-02`/`FR-006`/`FR-011` já fixados em rodadas anteriores.

Isso é o mecanismo da contaminação: a rodada tardia não descobre ambiguidade **estrutural** nova —
enumera o **fecho** de invariantes já decididos em casos-limite cada vez mais finos, e cada resposta
vira uma linha de FR/edge-case no spec. Um spec inflado de micro-restrições **pré-decide** o que
pertence ao `/speckit.plan` e obriga o agente de plano a honrar 25+ amarras que a arquitetura não
pediu. A suficiência foi atingida muito antes de o humano puxar o cabo.

## A trava de governança — `R-23`/`R-24`

O próprio desenho da ferramenta proíbe trocar o padrão de parada por chute. Os limiares dos sensores
(`SENSOR_MIN_YES=2`, `SENSOR_MIN_CHURN=5`) são "chutes declarados" mantidos **narrativos** até haver
calibração; o `R-24` só liga uma parada efetiva **depois de ≥10 execuções reais pagas em ≥2 repos**
(`R-23`) — "custo em dólar e em calendário, não em código"
(`docs/estudos/refatoracao-final-speckit-clarify-loop.md:35-36,69`).

**Onde estamos:** ~2 runs de convergência reais (001 e 002), **ambos no mesmo repo**. O gate `R-23`
está longe — falta repo nº 2 e faltam ≥8 runs. Consequência de desenho, e é o eixo da recomendação:

- Uma parada **calibrada** (limiar aprendido de churn/yes/marginalidade) segue **bloqueada** pelo
  `R-24` — não há dados para calibrar, e a ironia é que o motivo de faltarem dados é o mesmo motivo
  de o loop nunca parar: os runs não convergem sozinhos.
- Uma parada por **política** — um teto suave, que é *knob* e não limiar — **não precisa de
  calibração** e está **legitimamente desbloqueada**. Ela não afirma "o valor caiu abaixo de X";
  afirma "o Autor decidiu que N decisões bastam". É a única alavanca de parada que o `R-23` não
  tranca.

Este estudo também **conta como run-evidência nº 2** rumo ao gate — registrar o run 002 é, por si, um
passo do `R-23`.

## Edge cases e incertezas

Derivadas da leitura do run e do código. **👤** marca as que só o Autor pode responder.

- **E-1** 👤 O teto suave é um número de política. Ele deveria contar **decisões** (`total_yes`),
  **rodadas** (`round`) ou **linhas líquidas** (delta do spec)? Decisões espelham "o quanto se
  perguntou"; rodadas são mais grossas; delta captura a inflação do spec diretamente. Qual é o
  proxy de "o suficiente" que o Autor tem na cabeça quando decide matar o processo?
- **E-2** 👤 O run 002 foi cortado após **5 rodadas / 25 decisões**; o 001, após 7 / ~28. Os dois
  números batem com um teto natural na casa de **20–25 decisões** — ou isso é coincidência de dois
  pontos? Dois runs não fazem uma distribuição; um teto suave calibrado ainda cai no `R-24`.
- **E-3** A marginalidade é **legível pela categoria** que a skill já emite ("Casos-limite &
  Tratamento de Falha" vs "Escopo Funcional"). Uma rodada 100% casos-limite é um sinal forte de
  saturação. Mas ler a categoria da prosa é exatamente o que o `P-2` proíbe — só entra se virar
  **campo de contrato**, não heurística de texto (é o que a alternativa C explora).
- **E-4** 👤 Estender o contrato (C) reabre, de leve, a classe de bug que a sentinela matou: mais
  superfície de contrato é mais chance de o modelo variar o formato (`:148-153`). O ganho de uma
  parada informada paga esse risco, ou o teto suave (B) já resolve o essencial sem tocar o contrato?
- **E-5** Um teto suave que para em `rc=0` ("clarificado o suficiente") tem semântica diferente do
  teto duro (`rc=1`, "não convergiu"). São **dois desfechos distintos** e o resumo/`stop_reason`
  precisa distinguir — senão "parei porque bastou" e "parei porque estourei" viram o mesmo texto.
- **E-6** 👤 A ferramenta é pessoal e invocada à mão. O Autor **já** exerce a parada por
  suficiência — matando o processo. Um flag automatiza esse julgamento; um checkpoint interativo o
  mantém no humano ao custo da invariante não-interativa. O Autor quer **delegar** a decisão a um
  número, ou só quer **enxergar melhor** quando ela chegou (um aviso, não uma parada)?
- **E-7** 👤 Custo de oportunidade: o script está fora do canon; cada hora aqui é uma hora fora do
  harness, que é o produto (`refatoracoes-…:68-70`). O teto suave é barato o bastante para não
  disputar; o sinal de contrato (C) é?

## Alternativas

Nenhuma toca `prd.md`, `architecture.md` ou ADR — pelo que a Nota de canon estabelece.

### A — Não fazer

Congelar o loop no estado pós-poda. O stop segue sendo o humano matando o processo; as quatro
paradas automáticas permanecem como estão.

- **Prós:** custo zero, nenhum risco novo. A adesão do contrato (30/30) já é 100% — a fatia mais cara
  de valor já foi colhida. O `R-24` fica intocado.
- **Contras:** toda run futura depende de **vigilância manual** para não derrapar; a `plan` segue
  exposta à enumeração tardia de casos-limite. O sintoma que motiva o estudo permanece.
- **ADRs tocados:** nenhum.

### B — Teto suave de rodadas/decisões  *(alavanca escolhida)*

Um flag `--soft-stop-after N` (e/ou um default conservador) que, ao cruzar N **decisões** ou
**rodadas**, para **limpo (`rc=0`)** com `stop_reason` próprio — "clarificado o suficiente (teto
suave)" — distinto do teto duro (`rc=1`). Reusa contadores que já existem: `total_yes`, a contagem de
`ROUND_DECISIONS`, `round` (`:995-1001`). Opcionalmente, um modo **só-aviso** que narra "você já
integrou N decisões em M rodadas — considere parar" sem interromper (endereça E-6).

- **Prós:** não toca prosa (`P-2`), não toca o contrato, **não precisa de calibração** → **fora da
  trava `R-24`** (é política, não limiar aprendido). Menor risco de todos. Automatiza o julgamento
  que o Autor já faz à mão. Distingue "bastou" de "estourou" no resumo (E-5).
- **Contras:** um número de política é grosso — não sabe *quais* decisões foram marginais, só *quantas*
  houve. Pode cortar uma rodada estrutural tão bem quanto uma de casos-limite. O bom valor de N é
  incerto com dois pontos de dados (E-2).
- **ADRs tocados:** nenhum.

### C — Sinal de saturação no contrato  *(alavanca escolhida)*

Estender a sentinela com um campo que o modelo **auto-reporta** por rodada — a categoria dominante
das perguntas, ou um flag explícito de marginalidade (ex.: `CLARIFY_SATURATION: EDGE_ONLY` quando a
rodada só levanta casos-limite). Lido como o `CLARIFY_DECISION` já é (`decisions_of`, âncora `^…$`,
sem re-parsear prosa livre). A parada dispara quando o próprio modelo declara a rodada saturada.

- **Prós:** fecha o ponto cego que o run expôs — a marginalidade tardia passa a ser **observável e
  acionável**, não só visível no post-mortem. É a parada *informada* que B não consegue ser: sabe
  *por que* parou, não só *quando*. Continua dentro do contrato (não é heurística de texto).
- **Contras:** **amplia a superfície do contrato** e mexe no `SENTINEL_PROMPT` — reabre, de leve, a
  classe de bug que a sentinela matou (`:148-153`, E-4). E depende do auto-relato do modelo ser
  honesto sobre a própria marginalidade, o que é justamente o julgamento que ele demonstrou não ter
  (ele nunca emitiu `NO_AMBIGUITY`). Visibilidade da saturação ≠ o modelo admiti-la.
- **ADRs tocados:** nenhum.

### D — B + C

O teto suave (B) como **rede dura de política** e o sinal de saturação (C) como **parada informada**
por cima: para quando o modelo declara saturação **ou** quando o teto é cruzado, o que vier antes.

- **Prós:** a rede de B garante que a run não derrapa mesmo se o auto-relato de C falhar; C dá o
  motivo quando funciona. Cobre os dois modos de falha.
- **Contras:** maior escopo e o risco de contrato de C junto; e o auto-teste cresce com as duas
  paradas. Herda a incerteza de calibração de ambos.
- **ADRs tocados:** nenhum.

### Postas de lado (com razão registrada)

- **Elevar a régua no prompt** — ajustar o `SENTINEL_PROMPT` para o modelo só perguntar sobre
  ambiguidade que muda o **plano/arquitetura**, fazendo `NO_AMBIGUITY` finalmente disparar.
  **Rejeitada:** é a alavanca de maior risco — mexer na instrução para moldar o *conteúdo* das
  perguntas reabre em cheio a classe de bug que a sentinela matou, e transfere para o prompt um
  julgamento que o modelo já mostrou não sustentar.
- **Checkpoint humano por rodada** — pausar e consultar o Autor a cada K rodadas. **Rejeitada como
  desenho próprio:** fricção direta com a invariante não-interativa do loop (stream-json, `yes`
  injetado). Sobrevive apenas na forma leve do modo **só-aviso** de B, que narra sem pausar.

## ROI

Três notas de 1 a 5; **Esforço** e **Risco** invertidos (5 = menor esforço, menor risco, mais
reversível). ROI é a média. Tabela ordenada por ROI decrescente.

| # | Alternativa | Impacto | Esforço | Risco | **ROI** |
|---|---|:-:|:-:|:-:|:-:|
| B | Teto suave de rodadas/decisões | 4 | 5 | 5 | **4,67** |
| A | Não fazer | 1 | 5 | 4 | **3,33** |
| C | Sinal de saturação no contrato | 4 | 3 | 2 | **3,00** |
| D | B + C | 5 | 2 | 2 | **3,00** |

**B — 4,67.** *Impacto 4:* automatiza a parada por suficiência que hoje só o humano faz, e distingue
"bastou" de "estourou" (E-5); não chega a 5 porque é grosso — conta decisões, não sabe quais foram
marginais. *Esforço 5:* os contadores já existem (`:995-1001`); é um `if` e um `stop_reason`, mais
o flag. *Risco 5:* não toca prosa, não toca o contrato, é knob de política **fora do `R-24`**, e
desfazer é reinstalar a versão anterior.

**A — 3,33.** *Impacto 1:* por definição, nada muda. *Esforço 5:* zero. *Risco 4, não 5:* nada
quebra, mas a dívida continua — cada run futura pede vigilância manual para não contaminar a `plan`.

**C — 3,00.** *Impacto 4:* torna a marginalidade acionável, não só visível — a parada informada que
B não é. *Esforço 3:* um campo de contrato, sua leitura âncorada e casos de auto-teste. *Risco 2:*
mexe no `SENTINEL_PROMPT` e amplia a superfície do contrato (E-4), e depende do auto-relato do modelo
ser honesto — o mesmo que falha em `NO_AMBIGUITY`.

**D — 3,00.** *Impacto 5:* rede dura + parada informada, cobre os dois modos de falha. *Esforço 2:* o
maior escopo, auto-teste cresce em dobro. *Risco 2:* carrega o risco de contrato de C inteiro.

**Sinal a registrar:** "não fazer" (3,33) pontua **acima** de C e D (3,00). O run licencia forte o
teto suave (B) — barato, sem calibração, fora da trava —, mas ainda **não** licencia mexer no
contrato (C) sobre só congelar, porque o ganho de uma parada informada não paga a reabertura da
classe de bug da sentinela enquanto o teto suave resolve o essencial. É o mesmo formato dos estudos
irmãos, e o mesmo motivo de a alternativa "não fazer" ser obrigatória
(`refatoracoes-…:155-159`).

## Recomendação

**Não vinculante.** A recomendação é a **alternativa B — teto suave de rodadas/decisões** como
primeiro e único passo: é o maior ROI, o menor risco, e a **única alavanca de parada legitimamente
desbloqueada** — por ser política e não limiar, o `R-24` não a tranca, ao contrário de qualquer
parada calibrada. Sugere-se começar pela forma **mais leve possível**: o modo **só-aviso** (narra
"N decisões em M rodadas — considere parar") antes do corte automático, porque endereça E-6 sem tirar
a decisão do Autor, e porque o bom valor de N ainda é incerto com dois pontos de dados (E-1/E-2).

A **alternativa C** (sinal de saturação no contrato) é o seguimento natural **se e quando** o Autor
julgar que "quantas decisões" não basta e quiser "quais foram marginais" — mas só depois de B provar
o esqueleto, e sabendo que ela reabre de leve a classe de bug da sentinela (E-4). A **alternativa D**
não se justifica antes de C existir isolada.

Nada disto destrava a parada **calibrada** (sensores da Fase 3): essa segue atrás do `R-23`/`R-24` —
faltam repo nº 2 e ≥8 runs, e este estudo registra apenas o run nº 2. Enquanto o gate não amadurece,
o teto suave é a ponte honesta: encoda o julgamento do Autor sem fingir um limiar que não temos dados
para afirmar.

## Próximo passo sugerido

Se aprovado, rodar `superpowers:brainstorming` com a alternativa B →
`superpowers:writing-plans` → `superpowers:executing-plans`. O estudo já vale por si como
run-evidência nº 2 do `R-23`; um run num **segundo repo** é o item que mais aproxima do gate para,
um dia, ligar a parada calibrada.

## Reprodução

Todos os números do run 002 são re-deriváveis dos logs em
`/tmp/speckit-clarify-loop/20260722-183628`:

```sh
D=/tmp/speckit-clarify-loop/20260722-183628
# turnos, sentinela, yes e decisões por rodada
for f in "$D"/round-0*.jsonl; do
  turns=$(jq -rc 'select(.type=="result")' "$f" | wc -l)
  sent=$(jq -rc 'select(.type=="result").result // ""' "$f" \
         | grep -cE '(^|\n)CLARIFY_STATE: (ASKING|COMPLETE|NO_AMBIGUITY)[ \t]*$')
  yes=$(jq -rc 'select(.type=="result").result // ""' "$f" \
        | grep -cE '(^|\n)CLARIFY_STATE: ASKING[ \t]*$')
  decis=$(jq -rc 'select(.type=="result").result // ""' "$f" \
          | grep -oE 'CLARIFY_DECISION: .+ -> ' | wc -l)
  echo "$(basename "$f"): turns=$turns sent=$sent yes=$yes decis=$decis"
done

# custo da rodada = ÚLTIMO total_cost_usd por arquivo; a soma por-rodada é a correta
for f in "$D"/round-0*.jsonl; do
  jq -rc 'select(.type=="result").total_cost_usd // empty' "$f" | tail -n1
done | awk '{s+=$1} END{printf "custo total (per-round-final) = US$ %.2f\n", s}'

# a assinatura do corte externo: R5 fecha COMPLETE e não há round-06
ls "$D"/round-06* 2>/dev/null || echo "sem round-06 — parada por interrupção, não por convergência"
```
