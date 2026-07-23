# Registro persistente por rodada no `speckit-clarify-loop`

Spec de implementação. Alvo: o script em `tools/speckit-clarify-loop`, com Fase 0,
Fase 1 e a poda da heurística entregues e verificadas em 2026-07-21 (`:36-85`).

Origem: `docs/estudos/refatoracoes-roi-pos-run-speckit-clarify-loop.md`, alternativa
**B — só o registro persistente** (ROI 4,67), recomendada como primeiro e único
passo. **C** (instrumentar a adesão da família de decisões) e **D** (rede forçada +
captura de interrupção) ficam explicitamente para depois, como manda a Recomendação
daquele estudo (`:161-172`).

O script é ferramenta pessoal, instalada por cópia no PATH. Não aparece em
`docs/prd.md` (que põe "não executa o ciclo do Spec Kit" no fora-de-escopo, §4) nem
na tabela de scripts de `docs/architecture.md` (§3), e está **fora do canon** do
harness — o `check-canon.sh` não referencia `tools/` (verificado). O dever de
canonização do `CLAUDE.md` não se aplica a esta mudança. **Nenhum ADR é criado ou
superado, e nada em `docs/prd.md`/`docs/architecture.md` é tocado.**

---

## O problema

A execução real que motiva este estudo aderiu ao contrato em **35/35 turnos, 100%**
(`docs/estudos/sentinela-execucao-zion-mermaid-editor-app.md:39-59`) — e mesmo assim
**foi cara de medir**. O bloco `—— resumo ——` é `printf`'ado só para stdout e nunca
gravado (`tools/speckit-clarify-loop:1058-1078`); os locais por rodada
(`ROUND_YES`/`ROUND_SENT`/`ROUND_TURNS`/`ROUND_COST`/`ROUND_DECISIONS`) são dobrados
em totais e jogados fora (`:995-1001`). Toda a seção **Reprodução** do estudo do run
— `jq` arqueológico sobre os `round-NN.jsonl` crus — existe **só** por isso.

Pior: a R7 foi **interrompida externamente** e o `main_loop` morreu **antes** do
`printf` do resumo (`sentinela-execucao-…:99-110`). Um `tee` do resumo final não
teria pego a R7: **só persistência incremental por rodada** recupera um run cortado
(E-2 do estudo). É a diferença entre "guardar no fim" e "guardar à medida".

## Princípios herdados

Da família de specs do loop, sem alteração. Governam cada decisão adiante.

| | |
|---|---|
| **P-2** | Prosa não é contrato. O registro **lê as variáveis de estado já computadas** (`ROUND_*`), nunca re-parseia o stream do LLM. |
| **P-3** | Decisão/formatação é função pura, exercitável pelo `--self-test` sem repo e sem custo. |
| **P-6** | Simplificação só entra quando remove duplicação de fonte de verdade. Os campos do registro **reusam** os locais que já existem — zero coleta nova. |
| **P-7** | **(guia desta spec)** O registro é **conveniência, não contrato**: falha de escrita degrada gracioso e nunca derruba a execução — o mesmo espírito do `ln -sfn … \|\| true` do `latest` (`:655-658`). |

## Não mexer

`SENTINEL_PROMPT` inline no `--append-system-prompt` · `classify`/`read_sentinel` ·
`miss_action`/`SENT_MISS_MAX` e a rede sonda/aborto · `leaked_sentinel` casando
contra `added_lines` · a máquina de estados de `run_round` e a lógica de parada de
`main_loop` (`case ROUND_OUTCOME`, `--dry-run`, estagnação, teto) · a tabela de
códigos de saída (0/1/2) · a linha `sensores ·` e `narrate_sensors`.

**Fora de escopo, explicitamente:**

- **Alternativa C** — a linha de adesão da família de decisões (`decisões nomeadas
  N / yes M`) no resumo. O registro grava a **contagem** de decisões da rodada
  (`dec=`), que já existe como local; a **razão de adesão** e qualquer novo texto de
  resumo são de C, deferidos (estudo `:101-108`, `:169`).
- **Alternativa D** — o caminho versionado que força sonda/aborto sob `--dry-run` e
  o trap de captura de interrupção externa. O registro **recupera as rodadas
  completas** de um run cortado (R1–R6 do caso R7); capturar a rodada **em voo** no
  instante do corte é o trap de D, que o estudo condiciona a evidência que ainda não
  existe (`:150-159`, `:169-171`).
- Qualquer mudança de comportamento observável no repo-alvo. **Nada nesta spec toca
  o repo-alvo nem o spec:** toda escrita nova cai em `$LOG_DIR`, ao lado dos
  `round-NN.jsonl`/`round-NN.log`/`latest` que já vivem lá.

---

## Requisitos

### R-1 — `round_record`: a linha `chave=valor` por rodada, como função pura

Espelha o **`sensor_line`** (`:744-750`): entram os valores, sai uma linha ASCII
`chave=valor` separada por espaço; sem estado, sem I/O, testável por `assert_out`
(P-3). É o formato que a Fase 5 agrega com `grep`/`awk` — o mesmo motivo que fez o
`sensor_line` nascer assim.

```bash
round_record() {  # round turns sent yes dec cost delta outcome → linha
  printf 'round=%s turns=%s sent=%s yes=%s dec=%s cost=%s delta=%+d out=%s' \
    "${1:-00}" "${2:-0}" "${3:-0}" "${4:-0}" "${5:-0}" "${6:-0}" "${7:-0}" "${8:-?}"
  return 0
}
```

Esquema dos oito campos, cada um mapeado a um local que **já é computado** hoje —
zero coleta nova (P-6):

| campo | fonte | nota |
|---|---|---|
| `round` | `tag` (`:967`) | dois dígitos, `%02d` |
| `turns` | `ROUND_TURNS` (`:891`) | |
| `sent` | `ROUND_SENT` (`:893`) | adesão da rodada = `sent/turns`, derivável sem gravar a razão |
| `yes` | `ROUND_YES` (`:917`) | só o `yes` seco; a sonda não conta, como no resumo |
| `dec` | contagem de linhas de `ROUND_DECISIONS` (`:899`) | a **contagem**, não o texto (o texto é C) |
| `cost` | `ROUND_COST` (`:875`) | já é o custo da rodada (`pick_cost`), não a soma inflada |
| `delta` | `spec_lines(SPEC) − wc-l(snap)` | linhas líquidas **desta** rodada, contra o snapshot `$snap` (`:971`) |
| `out` | `ROUND_OUTCOME` | token único: `rodada-completa`/`loop-seco`/`aborto`/`dry-pergunta` |

`sent` e `turns` vão em campos separados, e não `sent=6/6`: dois inteiros são mais
limpos para o `awk` da Fase 5 do que um par a re-`split`ar, e a razão continua
trivial de derivar.

**Aceitação:** `assert_out` para linha bem-formada · `out=aborto` · `dec=0` (rodada
sem decisão nomeada) · `delta` negativo formatado com sinal (`delta=-12`) · a função
cabe em ≤ 5 linhas e não faz I/O.

### R-2 — o escritor incremental: uma linha anexada quando a rodada fecha

Escritor **impuro** fino, como `narrate_sensors` faz para o `round-NN.log`. Anexa a
linha do R-1 a `$LOG_DIR/rounds.txt` **logo após o fold dos totais e a
`narrate_sensors`** (após `:1009`), **antes** do `case "$ROUND_OUTCOME"` que pode dar
`break`. É o único ponto que roda para **toda** rodada que fechou, qualquer desfecho
— inclusive `aborto` e o vazamento de sentinela do M-06 (que já reescreveu
`ROUND_OUTCOME` em `:987-992` antes deste ponto).

```bash
# após narrate_sensors (:1009), antes do case:
snap_lines="$(wc -l < "$snap" | tr -d ' ')"
r_delta=$(( $(spec_lines) - snap_lines ))
printf '%s\n' "$(round_record "$tag" "$ROUND_TURNS" "$ROUND_SENT" "$ROUND_YES" \
  "$(printf '%s' "$ROUND_DECISIONS" | grep -c .)" "$ROUND_COST" "$r_delta" \
  "$ROUND_OUTCOME")" >> "$LOG_DIR/rounds.txt" 2>/dev/null || true
```

É o append incremental — não um `tee` do resumo final — que recupera um run cortado:
morto após a rodada N, `rounds.txt` fica com N linhas. **É a prova viva do E-2/R7.**
O `|| true` e o `2>/dev/null` são o P-7: se `$LOG_DIR` sumiu, a rodada segue.

**Aceitação:** um run de K rodadas deixa `rounds.txt` com K linhas, uma por rodada,
na ordem · uma rodada abortada aparece com `out=aborto` · matar o processo após a
rodada N deixa `rounds.txt` com exatamente N linhas (harness sem custo, abaixo).

### R-3 — `summary.txt`: o resumo consolidado, teado ao fim

O bloco `—— resumo ——` (`:1058-1078`) vira uma função emissora única `print_summary`
(uma fonte da verdade para tela e disco, sem duplicar os `printf`), capturada **uma
vez** e destinada a stdout e ao arquivo:

```bash
summ="$(print_summary)"          # gera o texto uma vez
printf '%s\n' "$summ"            # sempre ao stdout
printf '%s\n' "$summ" > "$LOG_DIR/summary.txt" 2>/dev/null || true
```

O `return "$rc"` de `main_loop` (`:1080`) fica **fora** da função — `print_summary`
só emite texto; `rc`/`stop_reason`/totais já estão setados antes da chamada. Captura
única em vez de `tee`: se o arquivo não abrir, o `|| true` engole o erro **sem**
arriscar imprimir o resumo duas vezes na tela (P-7). `$(…)` apara só newlines finais;
o `\n` inicial do `—— resumo ——` e a estrutura interna são preservados, então o
stdout casa byte-a-byte o de hoje.

`summary.txt` é o artefato **do happy-path**: só existe se o run chega ao fim, e por
isso **não** sobrevive a corte externo — e não precisa, porque quem sobrevive é o
`rounds.txt` do R-2. Essa divisão de papéis é literalmente o que o E-2 desenha:
legível-consolidado ao fim, estruturado-incremental à medida.

**Aceitação:** `summary.txt` casa byte-a-byte o `—— resumo ——` do stdout · existe em
todo caminho de saída que alcança `:1058` (convergência, aborto, `--dry-run`, teto) ·
um corte antes de `:1058` **não** cria `summary.txt`, e `rounds.txt` segue íntegro.

### R-4 — os dois artefatos entram no rodapé do resumo

O resumo já lista os logs da execução (`:1066-1067`). As duas linhas novas ganham
menção ali, para que quem lê o resumo saiba que o registro existe e onde:

```
logs:     /tmp/speckit-clarify-loop/AAAAMMDD-HHMMSS
          round-NN.jsonl (stream) · round-NN.log (narração) · latest → esta execução
          rounds.txt (registro por rodada) · summary.txt (este resumo)
```

**Aceitação:** o rodapé cita `rounds.txt` e `summary.txt`; a coluna de rótulos
permanece alinhada.

---

## Verificação — sem custo, e é o ponto

A ferramenta tem um **harness sem custo** — `tools/speckit-clarify-loop-harness.sh`
— que sobe um repo Spec Kit falso e um stub determinístico de `claude` e exercita o
caminho inteiro (preflight, fifo, classificação, snapshot, narração, **resumo**) sem
gastar cota. Ele é o que torna o registro — inclusive o caso de corte — provável de
graça, e o que separa esta entrega das anteriores, cuja rede só se exercitava com
cota paga ou hack não commitado.

## Pronto quando

- ✅ `--self-test` limpo, com o contador automático subindo sozinho a partir dos 143
  de hoje. **147 casos**, os 4 novos sendo os `assert_out` do `round_record` (R-1).
- ✅ **Harness sem custo — run completo:** um run de K rodadas deixa `rounds.txt` com
  K linhas bem-formadas e `summary.txt` casando o stdout. Cobre R-1, R-2, R-3 e R-4
  sem tocar cota.
- ✅ **Harness sem custo — corte externo (a prova do E-2/R7):** matar o processo
  (`TERM`) após a rodada N deixa `rounds.txt` com exatamente N linhas e **nenhum**
  `summary.txt` — a recuperação que o run real da R7 não teve, agora demonstrada de
  graça. É o critério que só esta alternativa satisfaz.
- ⚠️ **Não coberto pelo auto-teste, por construção:** o append em `rounds.txt` e o
  `tee` de `summary.txt` vivem em `main_loop`, que fala com `$LOG_DIR` e com o
  processo `claude`. O `--self-test` é sem repo e sem custo (P-3); quem os exercita
  ponta-a-ponta é o harness sem custo, não o auto-teste.
- ✅ **`--dry-run` real** com `delta +0` e hash inalterado no repo-alvo, confirmando
  que a persistência escreve só em `$LOG_DIR` e que `rounds.txt`/`summary.txt`
  nascem também no modo de ensaio.
- ✅ **Nota datada no cabeçalho**, no padrão do arquivo (`:16-85`): repo, custo,
  `sentinela: N/M`, e a menção de que `rounds.txt`/`summary.txt` foram gerados e
  conferidos — inclusive o caso de corte pelo harness.
- ✅ A guarda de vazamento (`leaked_sentinel`, casando só `added_lines`) fica
  **intocada**: o registro escreve exclusivamente em `$LOG_DIR` e nunca no spec, então
  não há superfície nova de vazamento — `git status --porcelain` no repo-alvo continua
  vazio ao fim de um `--dry-run`.

---

## Risco aceito

Mínimo por construção, e é o *Risco 5* que o ROI deu a B: o registro **anexa ao
diretório da execução e nunca toca o repo-alvo nem o spec** — não há como corromper
o trabalho do Autor. O único modo de falha novo é I/O de disco (`$LOG_DIR`
removido/cheio), coberto pelo degrade gracioso do P-7: a escrita falha em silêncio e
o run segue.

**Risco residual assumido, herdado do estudo:** o valor de máquina do `rounds.txt`
pressupõe um consumidor programático — a agregação da Fase 5 (≥10 runs) que **ninguém
agendou** (E-1/E-5). A escolha do formato `chave=valor` mitiga isso: o mesmo arquivo
**já se paga na leitura humana** de um run isolado (`cat`/`grep`, sem `jq`
arqueológico), então não depende da Fase 5 acontecer para valer a pena. Se a Fase 5
nunca vier, o registro ainda quitou a dívida de medição que este estudo pagou à mão.

Desfazer é reinstalar a versão anterior — a ferramenta se instala por cópia, e a
reversão é um comando.
