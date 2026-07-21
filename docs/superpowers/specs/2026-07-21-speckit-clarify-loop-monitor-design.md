# Design — monitor de sessão do `speckit-clarify-loop`

- **Data:** 2026-07-21
- **Estado:** design validado em brainstorming, pronto para plano.
- **Natureza:** incremento sobre a ferramenta pessoal `tools/speckit-clarify-loop`, descrita em
  [`2026-07-21-speckit-clarify-loop-design.md`](2026-07-21-speckit-clarify-loop-design.md). Valem
  todas as restrições daquele documento — não é artefato canônico do repo, não entra em `scripts/`,
  não é tocada por `check-canon.sh` nem por `eval.sh`.

## Problema

O loop é hands-off por desenho, mas hoje é também **opaco**. Uma rodada inteira imprime três coisas:

```
rodada 01/10 …
  [r01] pergunta 1 → yes
```

Entre `rodada 01/10 …` e a primeira pergunta passam-se minutos em que o script não diz nada. O
Autor não consegue distinguir "a skill está lendo um spec de 1081 linhas" de "o processo travou", e
não vê **a pergunta que está sendo aceita com `yes`** — a única coisa que a automação decide por
ele. Quando a rodada termina em `indeterminada`, o único recurso é garimpar um JSONL de 372 KB.

O stream já carrega tudo que falta: `assistant`/`text`, `assistant`/`thinking`,
`assistant`/`tool_use`, `user`/`tool_result`, `rate_limit_event`, `system/*` e o `result` com custo.
O motor atual lê cada uma dessas linhas e **descarta todas menos `result` e `rate_limit_event`**.

## Decisão de conteúdo

O monitor mostra:

- **texto do assistente integral** — a pergunta com a tabela de opções, o Completion Report;
- **uma linha por tool call**, com resumo do input;
- **`thinking` como marcador único**, sem conteúdo;
- **o `yes` injetado ecoado**, para o log ler como uma conversa de verdade.

Rejeitado o ticker de uma linha por evento (responde "não travou", mas não mostra a decisão) e
rejeitado o modo integral com `thinking` e `tool_result` completos (o payload de um `Read` de spec
longo afoga as duas coisas que importam).

O monitor é o **padrão**; `--quiet` volta ao output enxuto de hoje. O silêncio é o problema que
motivou o trabalho, logo a narração deve acontecer sem ser pedida; a flag serve ao caso oposto —
deixar rodando e ler o resumo depois — que é real, mas raro.

## Forma na tela

```
speckit-clarify-loop: /home/tuyoshi/projects/personal/zion-mermaid-editor-app
  spec: specs/001-cano-modelo-codigo/spec.md (1081 linhas)

── rodada 01/10 ──────────────────────────────────────────
  00:02  ⚙  Bash    check-prerequisites.sh --json --paths-only
  00:04  ⚙  Read    spec.md
  00:31  ·  pensando…
  00:48  ◆  claude
         This spec is large (1081 lines) and heavily clarified
         already. Let me map its structure before scanning for gaps.
  01:05  ⚙  Bash    grep -n '^#\{1,4\} ' specs/001-.../spec.md
  02:10  ◆  claude
         **Q1 — Feedback quando a área de transferência falha.**
         **Recomendado: Opção B** — sinal de falha transitório…

         | Opção | Descrição |
         |---|---|
         | A | Manter o silêncio |
         | B | Sinal de falha transitório no próprio controle |
  02:10  ▸  você    yes                              (pergunta 1/5)
  04:22  ◆  claude
         ## Resumo da clarificação
         Próximo comando sugerido: `/speckit-plan`
  04:22  ✓  rodada completa · 3 yes · US$ 0,41 · spec 1081 → 1094
```

## Arquitetura

Um componente novo e um ponto de mudança no motor existente.

### `render_event` — o renderizador

Função de texto puro: recebe uma linha do stream, escreve zero ou mais linhas de narração. Toda a
lógica de apresentação mora aí. Despacho por `.type`:

| Evento | Narração |
|---|---|
| `system/init` | nada (ruído de arranque) |
| `system/*` (`thinking_tokens`, `hook_started`, `hook_response`) | nada |
| `assistant` + `thinking` | `· pensando…`, suprimido se a linha anterior já foi um `pensando…` |
| `assistant` + `text` | `◆ claude` + prosa indentada e quebrada |
| `assistant` + `tool_use` | `⚙ <Nome>  <resumo do input>` |
| `user` + `tool_result` | nada |
| `rate_limit_event` | só quando `status ≠ allowed`: `⚠ rate limit: <status>` |
| `result` | rodapé `✓ <desfecho> · N yes · US$ X · spec A → B` |

Resumo do `tool_use`, por ferramenta: `Bash` mostra `.input.command`; `Read`/`Edit`/`Write` mostram
o `basename` do `.input.file_path`, não o caminho absoluto; qualquer outra cai num genérico de
primeira chave. Tudo truncado na largura do terminal.

**O eco do `yes` não passa pelo renderizador.** Ele não é evento de stream: é emitido pelo motor no
mesmo ponto onde hoje sai `[rNN] pergunta N → yes`, junto ao `send_user 'yes'`, usando o mesmo fd 4.
A linha `▸ você    yes    (pergunta N/5)` substitui aquela — não se acumula com ela.

**O `result` nunca reimprime prosa.** Verificado empiricamente contra um stream real: o campo
`.result` do evento final é byte a byte idêntico ao último bloco `assistant`/`text`. Quem imprime
prosa é o evento `assistant`; o `result` só fecha a rodada e alimenta a classificação.

### Mudança no motor

O laço `while IFS= read -r line` de `run_round` passa a chamar `render_event "$line"` antes do
despacho de controle. **A classificação, o `send_user 'yes'`, os abortos e o teto de 5 `yes` não
mudam.**

O monitor é **estritamente aditivo**: nenhum caminho de `render_event` pode encerrar a rodada. Linha
malformada, tipo desconhecido, `jq` que não casa — tudo resulta em saída vazia e continuação. Essa é
a invariante do componente, e o auto-teste a protege.

### Destino da saída

`render_event` escreve num fd dedicado (`fd 4`), apontado no arranque de cada rodada para
`tee round-NN.log` — ou, sob `--quiet`, só para o arquivo. O `--quiet` é assim uma decisão única no
arranque, não um `if` espalhado por dez pontos.

O `round-NN.log` fica ao lado do `round-NN.jsonl` já existente, em `/tmp/speckit-clarify-loop/`, e
é limpo pelo mesmo `rm -f` do preflight. Persistir a narração é o que dá sentido ao `--quiet`: o
modo existe para rodar desatendido, e é exatamente aí que o arquivo legível vira a única forma de
saber o que aconteceu.

## Formatação

**Detecção de TTY, uma vez no arranque** (`[ -t 1 ]`), decide dois conjuntos de constantes:

| | TTY | pipe / arquivo |
|---|---|---|
| marcadores | `⚙ ◆ ▸ · ✓ ⚠` | `[tool] [claude] [você] [...] [ok] [!]` |
| cor | dim nas ferramentas, negrito no `▸ você`, vermelho no `⚠` | nenhuma |
| largura | `tput cols`, teto de 100 | 80 fixo |

O `round-NN.log` recebe **sempre** a forma ASCII sem escape — arquivo com sequência ANSI dentro é
arquivo que ninguém consegue reler. Consequência aceita: no TTY sem `--quiet` o texto é renderizado
duas vezes, uma por destino. É baratíssimo e evita um `sed` de remoção de ANSI no caminho de escrita.

**Quebra de linha.** A prosa passa por `fold -s -w $((WIDTH-9))` e é indentada em 9 colunas,
alinhada sob o `◆ claude`. Linhas de tabela markdown (começam com `|`) e blocos de código escapam do
`fold`: quebrar uma tabela de opções destrói exatamente a informação que se quer ler. Se estourar a
largura, estoura.

**Relógio.** `SECONDS` é zerado no início de cada rodada; o carimbo é `mm:ss` decorrido. Sem
dependência de `date`, imune a fuso. O que interessa não é a hora, é há quanto tempo nada acontece.

## Interface

Uma flag nova na assinatura existente:

```
speckit-clarify-loop [--repo DIR] [--max-rounds N] [--allow-dirty] [--dry-run] [--quiet] [--self-test]
```

| Flag | Efeito |
|---|---|
| `--quiet` | Suprime a narração no stdout; o `round-NN.log`, as linhas de estrutura e o resumo final continuam. |

## Efeito nos modos existentes

- **`--dry-run` narra igual.** Hoje ele para na 1ª pergunta imprimindo uma linha seca; com o monitor
  o Autor vê o preflight, o `Read` do spec e a pergunta inteira que *teria* recebido `yes`. O modo
  passa a valer como ensaio de verdade, não só como checagem de hash.
- **`--quiet`** suprime apenas o stdout da narração. As linhas de estrutura (`rodada NN/10`), o
  resumo final e o `round-NN.log` continuam.
- **Caminhos de falha.** `indeterminada` e os abortos passam a chegar com os últimos turnos narrados
  logo acima. A referência ao `.jsonl` continua no resumo, mas deixa de ser o primeiro recurso.

## Verificação

O renderizador é a segunda função pura do script, testável do mesmo jeito que a classificação:
linha JSONL → texto de narração, sem processo `claude` envolvido.

`--self-test` ganha um bloco de asserções (`assert_render <descrição> <esperado> <linha-jsonl>`)
cobrindo no mínimo:

| Caso | Verifica |
|---|---|
| `assistant`+`tool_use` Bash | resumo pelo `.input.command` |
| `assistant`+`tool_use` Read | `basename` do `file_path`, não o caminho absoluto |
| `assistant`+`tool_use` desconhecida | fallback genérico, sem quebrar |
| dois `thinking` seguidos | **uma** linha `pensando…`, não duas |
| `assistant`+`text` com tabela | tabela intacta, prosa dobrada |
| `system/init` e `system/thinking_tokens` | saída vazia |
| `rate_limit_event` com `allowed` | saída vazia |
| `result` | rodapé, e nenhuma reimpressão da prosa |
| linha JSONL malformada | saída vazia, exit 0 |

O último caso é o que protege a invariante aditiva: o teste falha se um dia o monitor passar a poder
derrubar a rodada.

O contrato de largura/TTY não é testado por igualdade de string — é verificado uma vez à mão
(`--dry-run` num TTY e `--dry-run | cat`), do mesmo modo que a verificação end-to-end registrada no
cabeçalho do script.

## Fora de escopo (YAGNI)

- Painel/TUI com regiões fixas, barra de progresso ou reposicionamento via `tput` — o histórico
  rolante é justamente o que se quer reler depois.
- Renderizar `tool_result`: o payload de um `Read` de spec longo afoga a narração inteira.
- Flag de verbosidade granular (`--show-thinking`, `--show-tool-results`). Dois modos — monitor e
  `--quiet` — cobrem o uso real; um terceiro nasce quando doer.
- Cor configurável ou `NO_COLOR` além da detecção de TTY.
- Narrar o stream de rodadas passadas a partir dos `.jsonl` gravados (um "replay").
