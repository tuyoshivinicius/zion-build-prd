# Aviso de suficiência (teto suave *warn-only*) no `speckit-clarify-loop`

Spec de implementação. Alvo: o script em `tools/speckit-clarify-loop`, com Fase 0,
Fase 1, a poda da heurística e o registro persistente por rodada (`round_record`,
`rounds.txt`) já entregues.

Origem: `docs/estudos/parada-por-suficiencia-speckit-clarify-loop.md`, alternativa
**B — teto suave de rodadas/decisões** (ROI 4,67), recomendada como primeiro e único
passo, **na sua forma mais leve possível: o modo só-aviso** (`estudo:177-190,269-274`).
O corte automático em `rc=0` da mesma alternativa B, o sinal de saturação no contrato
(**C**) e a combinação (**D**) ficam explicitamente para depois, como manda a
Recomendação daquele estudo (`:276-284`).

O script é ferramenta pessoal, instalada por cópia no PATH. Não aparece em
`docs/prd.md` (que põe "não executa o ciclo do Spec Kit" no fora-de-escopo, §4) nem
na tabela de scripts de `docs/architecture.md` (§3), e está **fora do canon** do
harness — o `check-canon.sh` não referencia `tools/` (verificado). O dever de
canonização do `CLAUDE.md` não se aplica a esta mudança. **Nenhum ADR é criado ou
superado, e nada em `docs/prd.md`/`docs/architecture.md` é tocado.**

---

## O problema

Em dois runs de convergência reais consecutivos contra o `zion-mermaid-editor-app`, o
loop **nunca parou sozinho** — o stop de fato foi o humano matando o processo
(`estudo:35-71`). As duas paradas por convergência do harness são estruturalmente
inatingíveis num spec rico:

- **`NO_AMBIGUITY` nunca sai:** a skill é gulosa sem fundo — a cada rodada acha outras
  5 perguntas (run 002: 5 rodadas × 5 = 25 perguntas, zero `NO_AMBIGUITY`).
- **Estagnação nunca dispara:** integrar qualquer resposta reescreve FRs/edge-cases
  (run 002: +81 a +116 linhas por rodada), então o `spec_hash` muda toda rodada e o
  contador `same` volta a zero antes de chegar a 2.

Sobram o **teto** (`rc=1`, freio bruto de descontrole) e o **aborto** (erro). Nenhum é
um sinal de "clarificamos o suficiente". E o dano à `plan` não é o custo — é o
**conteúdo** das rodadas tardias: elas param de descobrir ambiguidade **estrutural** e
passam a enumerar o **fecho** de invariantes já decididos em casos-limite cada vez mais
finos, cada resposta virando uma micro-restrição que **pré-decide** o que pertencia ao
`/speckit.plan` (`estudo:92-109`). A suficiência é atingida muito antes de o humano
puxar o cabo — e hoje nada a torna visível no instante em que ela chega.

## A moldura de governança — por que *warn-only*, e por que agora

O estudo separa duas alavancas de parada (`estudo:111-131`):

- A parada **calibrada** (um limiar aprendido de churn/yes/marginalidade) segue
  **bloqueada** pelo gate `R-23`/`R-24`: exige ≥10 execuções reais pagas em ≥2 repos, e
  temos ~2 runs, **ambos no mesmo repo**. Não há dados para calibrar.
- Uma parada por **política** — um teto que é *knob*, não limiar — **não precisa de
  calibração** e está **legitimamente desbloqueada**. Não afirma "o valor caiu abaixo de
  X"; afirma "o Autor decidiu que N basta".

Esta spec entrega a política na sua forma mais conservadora: **um aviso, não uma
parada**. O Autor **já** exerce a parada por suficiência — matando o processo (E-6,
`estudo:154-157`). O aviso não delega esse julgamento a um número; ele apenas **torna
visível**, no instante em que chega, que a suficiência foi cruzada — mantendo a decisão
no humano e a invariante não-interativa do loop (stream-json, `yes` injetado) intacta.
O corte automático em `rc=0` fica para quando o Autor julgar que "quantas decisões"
merece virar parada de fato; o bom valor de N ainda é incerto com dois pontos de dados
(E-1/E-2, `:137-143`).

**Distinção que sustenta o desbloqueio.** O aviso é **por-run e cumulativo**; os
`sensor_line`/`narrate_sensors` são **por-rodada** e é a agregação deles (Fase 5) que o
`R-24` tranca. Esta spec **não toca** os sensores nem seus limiares (`SENSOR_MIN_YES`,
`SENSOR_MIN_CHURN`). São dois mecanismos distintos que não se cruzam.

## Princípios herdados

Da família de specs do loop, sem alteração. Governam cada decisão adiante.

| | |
|---|---|
| **P-2** | Prosa não é contrato. O aviso **lê os contadores de estado já computados** (`total_yes`, `round`, `spec_lines`), nunca re-parseia o stream do LLM. |
| **P-3** | Decisão/formatação é função pura, exercitável pelo `--self-test` sem repo e sem custo. O gatilho do aviso é `nudge_note`, pura, testada por `assert_out`. |
| **P-6** | Simplificação/reúso: o aviso **reusa** os contadores que já existem (`total_yes`, `round`, `start_lines`) — zero coleta nova. |
| **P-7** | O aviso é **conveniência, não contrato**: nunca altera `rc`, `stop_reason` ou o fluxo de parada. Uma linha de narração a mais, nada além. |

## Não mexer

`SENTINEL_PROMPT` inline no `--append-system-prompt` · `classify`/`read_sentinel` ·
`miss_action`/`SENT_MISS_MAX` e a rede sonda/aborto · `leaked_sentinel` casando contra
`added_lines` · a máquina de estados de `run_round` · **a lógica de parada de
`main_loop`** (`case "$ROUND_OUTCOME"`, `--dry-run`, estagnação, teto) · a tabela de
códigos de saída (0/1/2) · a linha `sensores ·`, `sensor_line` e `narrate_sensors` e
seus limiares · o registro `round_record`/`rounds.txt`.

**Fora de escopo, explicitamente:**

- **Corte automático (`rc=0`)** — o `--soft-stop-after N` que *para* a run limpa, com
  `stop_reason` próprio distinto do teto duro (E-5). Esta spec **só avisa**; a parada
  segue sendo as quatro existentes. Deferido até o Autor querer delegar o julgamento
  (`estudo:181-190,276-279`).
- **Alternativa C** — o campo de saturação no contrato (`CLARIFY_SATURATION`) e qualquer
  mudança no `SENTINEL_PROMPT`. Reabre a classe de bug que a sentinela matou; deferido
  (`estudo:193-207,276-278`).
- **Alternativa D** — B (corte) + C juntos. Não se justifica antes de C existir isolada
  (`estudo:210-218,278-279`).
- **Parada calibrada (sensores da Fase 3)** — atrás do `R-23`/`R-24`, sem dados.
- **Qualquer mudança no resumo (`—— resumo ——`).** O aviso é um sinal *ao vivo*: por
  hora do resumo a run acabou e a decisão de matar já não cabe. Ver "Decisão de
  desenho" abaixo.

---

## Requisitos

### R-1 — `nudge_note`: o gatilho do aviso, como função pura

Espelha o **`sentinel_note`** (`:212-219`): entram os três contadores cumulativos, sai
o **texto do aviso** se **qualquer** limiar foi cruzado (semântica **OR**), ou **vazio**
se nenhum. Sem estado além dos limiares (lidos do ambiente, com default), sem I/O,
testável por `assert_out` (P-3).

```bash
nudge_note() {  # yes rounds delta → linha de aviso, ou vazio
  local yes="${1:-0}" rounds="${2:-0}" delta="${3:-0}"
  local ty="${SKCL_NUDGE_YES:-20}" tr="${SKCL_NUDGE_ROUNDS:-4}" td="${SKCL_NUDGE_DELTA:-300}"
  if [ "$yes" -ge "$ty" ] || [ "$rounds" -ge "$tr" ] || [ "$delta" -ge "$td" ]; then
    printf 'suficiência: %s decisões · %s rodadas · %+d linhas — a carga marginal cai; considere parar (teto suave)' \
      "$yes" "$rounds" "$delta"
  fi
  return 0
}
```

**Os três proxies e seus defaults.** Os três contadores já existem; o Autor os quis
todos observados (E-1), e a linha reporta os três sempre — o **OR** só escolhe qual
*dispara* primeiro conforme a forma do spec:

| proxy | fonte | default | por quê |
|---|---|---|---|
| `yes` | `total_yes` (`:1007`) | `SKCL_NUDGE_YES=20` | decisões integradas; os dois runs foram mortos em ~25/28 (E-2). 20 avisa **antes** do ponto de morte típico. |
| `rounds` | `round` (`:978`) | `SKCL_NUDGE_ROUNDS=4` | rodada 4 é o "você já passou do estrutural"; dá ~1 rodada de antecedência à morte típica (5–7). |
| `delta` | `spec_lines − start_lines` | `SKCL_NUDGE_DELTA=300` | inflação líquida do spec; ≈ +100/rodada × 3 (run 002: +488 em 5). Pega o spec churny antes dos outros dois. |

Os limiares são **env-tuneáveis** justamente porque N é incerto com dois pontos de
dados — o Autor ajusta por-run sem editar código, e um dia calibra quando o gate
`R-23` amadurecer.

**Aceitação:** `assert_out` para (a) cruza por `yes` (`yes=20`, demais abaixo) · (b)
cruza por `rounds` (`rounds=4`, demais abaixo) · (c) cruza por `delta` (`delta=300`,
demais abaixo) · (d) **nenhum** cruzado → **string vazia** · a função não faz I/O e
lê os três limiares de um lugar só.

### R-2 — o marcador `info`: um glifo distinto para o aviso

O aviso não é `ok` (✓ — leria como sucesso, some no meio da narração de rodada) nem
`warn` (⚠ vermelho — reservado a aborto/vazamento reais; um aviso em vermelho gritaria
lobo). É informativo. Um **quarto kind** `info`, notável sem alarmar:

- `mon_marker` (`:382-398`): `tty:info` → `ⓘ` · `plain:info` → `[nota]  ` (8 colunas,
  como os demais do perfil `plain`).
- `emit_note` (`:602-615`): `info` → cor `bold` (o mesmo realce discreto do `you`;
  chama atenção, não é vermelho).

**Aceitação:** `assert_emit` (ou `assert_out` do marcador, no padrão do teste existente
de `emit_note`, `:1825-1827`) confirma o glifo/rótulo do `info`; o `plain:info` tem
exatamente 8 colunas, alinhado com os outros marcadores.

### R-3 — o disparo, uma vez, no fundo do laço

Escritor impuro fino em `main_loop`. Dispara no **fundo do corpo do `while`** — depois
do `case "$ROUND_OUTCOME"`, do bloco `--dry-run` e do ramo de estagnação —, o **único
ponto alcançado só quando o laço vai girar de novo**. Uma rodada que convergiu, abortou
ou foi ensaio (`--dry-run`) já deu `break` antes daqui e **não** recebe o aviso: dizer
"considere parar" a quem já parou seria ruído.

```bash
    # ... (fim do ramo de estagnação, dentro do while) ...

    # Aviso de suficiência (teto suave, só-aviso): dispara UMA vez, no ponto
    # alcançado só quando o laço vai continuar. Lê os contadores cumulativos já
    # computados (P-2/P-6); nunca toca rc/stop_reason/parada (P-7). O `nudged`
    # trava para não repetir a cada rodada. Limiares env-tuneáveis, defaults em
    # nudge_note.
    if [ "$nudged" -eq 0 ]; then
      nudge_msg="$(nudge_note "$total_yes" "$round" "$(( $(spec_lines) - start_lines ))")"
      [ -z "$nudge_msg" ] || { emit_note info "$nudge_msg"; nudged=1; }
    fi
  done
```

Locais novos em `main_loop`: `nudged` (a trava, inicia `0`) e `nudge_msg`. O delta é
**cumulativo** (`spec_lines` atual − `start_lines`), não o `r_delta` por-rodada do R-2 —
proxies distintos, contadores distintos.

**Aceitação:** um run que cruza um limiar mostra a linha `ⓘ` **exatamente uma vez**,
mesmo continuando por mais rodadas · um run cujos totais ficam abaixo dos três limiares
**nunca** mostra a linha · a rodada que converge/aborta/`--dry-run` **não** dispara o
aviso (o `break` vem antes) · `rc`, `stop_reason` e a tabela de saída ficam **idênticos**
com e sem o aviso.

---

## Decisão de desenho — narração ao vivo, **sem** tocar o resumo

Considerada e **rejeitada** para v1: uma linha no `—— resumo ——` registrando se/quando
o aviso disparou. Fica de fora porque o aviso é um sinal **ao vivo**, cujo único valor é
influenciar a decisão de matar **enquanto a run corre**; por hora do resumo a run
terminou e a decisão é discutível. O aviso já persiste no `round-NN.log` e no stdout da
rodada. Manter o resumo intocado também preserva a fronteira do "Não mexer" e o
byte-a-byte que o registro persistente (R-3 daquela spec) protege. Um *breadcrumb* de
resumo é adição trivial e reversível se o Autor um dia o quiser — mas não entra agora,
para manter o escopo honesto.

## Verificação — sem custo, e é o ponto

A ferramenta tem um **harness sem custo** — `tools/speckit-clarify-loop-harness.sh` —
que sobe um repo Spec Kit falso e um stub determinístico de `claude` e exercita o
caminho inteiro sem gastar cota. Ele prova o disparo (e o não-disparo) de graça.

- **`--self-test` limpo**, contador subindo sozinho a partir dos 147 de hoje: os casos
  novos são os `assert_out` do `nudge_note` (R-1) e a asserção do marcador `info` (R-2).
- **Harness sem custo — dispara uma vez:** um run de K rodadas com `SKCL_NUDGE_ROUNDS=2`
  (limiar baixo, os outros dois altos) mostra a linha `ⓘ suficiência: …` **exatamente
  uma vez**, a partir da rodada 2, e o run segue até seu stop normal.
- **Harness sem custo — nunca dispara:** o mesmo run com os três limiares acima dos
  totais (`SKCL_NUDGE_YES`/`ROUNDS`/`DELTA` altos) **não** mostra a linha `ⓘ` em rodada
  alguma.
- **Harness sem custo — o resumo e a parada não mudam:** o `—— resumo ——` e o
  `stop_reason`/`rc` de um run com o aviso ligado casam byte-a-byte os de um run com os
  limiares altos (o aviso é a única diferença de saída, e só na narração de rodada).
- **`--dry-run` real** (uma rodada paga, ~US$ 0,10–0,60) contra um repo Spec Kit:
  confirma que o modo de ensaio não dispara o aviso (uma rodada, `break` antes do fundo
  do laço) e que nada no comportamento observável mudou; `git status --porcelain` no
  repo-alvo vazio antes e depois.
- **Nota datada no cabeçalho**, no padrão do arquivo: repo, custo, e a menção de que o
  aviso foi exercitado (dispara-uma-vez e nunca-dispara) pelo harness sem custo.

## Pronto quando

- ✅ `--self-test` limpo, com os casos novos do `nudge_note` (4 `assert_out`: cruza por
  yes, por rounds, por delta, e vazio abaixo de todos) e o marcador `info`.
- ✅ **Harness — dispara uma vez:** `SKCL_NUDGE_ROUNDS=2` num run de ≥3 rodadas deixa
  **uma** linha `ⓘ` na narração; nunca duas.
- ✅ **Harness — nunca dispara:** limiares altos → zero linhas `ⓘ`.
- ✅ **Harness — parada intocada:** `rc`, `stop_reason` e o `—— resumo ——` idênticos
  com o aviso ligado e desligado (só a linha `ⓘ` de rodada difere).
- ✅ **`--dry-run` real** sem aviso disparado, `git status --porcelain` vazio, e nota
  datada preenchida com repo/custo.

---

## Risco aceito

Mínimo por construção, e é o *Risco 5* que o ROI deu a B: o aviso **nunca altera o
fluxo de parada, o `rc` ou o spec** — é uma única linha de narração a mais, atrás de uma
trava que dispara uma vez. Não há como contaminar a `plan`, o repo-alvo ou a decisão de
parada; o pior caso é uma linha `ⓘ` que o Autor ignora. Não toca o contrato
(`SENTINEL_PROMPT`), então **não reabre** a classe de bug que a sentinela matou — a
diferença exata entre esta alternativa e a C.

**Risco residual assumido, herdado do estudo:** os defaults 20/4/300 são "chutes
declarados" de política, não limiares calibrados — dois pontos de dados não fazem uma
distribuição (E-2). Mitigação: são **env-tuneáveis**, e como o aviso só narra, um limiar
mal-posto custa no máximo um aviso cedo ou tarde demais, nunca uma parada errada. Quando
o gate `R-23` amadurecer (repo nº 2, ≥8 runs), estes defaults viram a base honesta de
uma eventual calibração.

Desfazer é reinstalar a versão anterior — a ferramenta se instala por cópia, e a
reversão é um comando.
