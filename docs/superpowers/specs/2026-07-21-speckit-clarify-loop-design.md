# Design — `speckit-clarify-loop`: automação do ciclo de clarificação do Spec Kit

- **Data:** 2026-07-21
- **Estado:** design validado em brainstorming, pronto para plano.
- **Natureza:** **ferramenta pessoal de linha de comando**, entregue como binário em
  `~/.local/bin/speckit-clarify-loop`. **Não é artefato do repo `zion-build-prd`** — não entra em
  `scripts/`, não tem linha na tabela §3 do `architecture.md`, não é tocada por `check-canon.sh`
  nem por `eval.sh`. Este documento existe aqui porque é onde o brainstorming aconteceu.
- **Alvo de execução:** qualquer repositório com estrutura Spec Kit (`.specify/`), pelo `cwd` —
  `zion-mermaid-editor-app`, `zion-test-build-prd`, `corporate/wispot/zion-brownfield/legacy-consumer-repo`.

## Problema

O ciclo de clarificação do Spec Kit é executado à mão, e sempre da mesma forma:

1. Roda `/speckit-clarify` no repo do produto.
2. A skill apresenta **uma pergunta por turno**, cada uma com um bloco
   `**Recommended:** Option X — <razão>` (ou `**Suggested:** <resposta>` no formato curto).
3. O Autor responde `yes` — **sempre** aceitando a recomendação.
4. A skill grava a resposta no `spec.md` a cada aceite e, no máximo na 5ª pergunta, encerra com o
   Completion Report.
5. O Autor dá `/clear` e recomeça, até a skill responder que não há mais ambiguidades críticas.

O trabalho humano é integralmente mecânico: digitar `yes` até cinco vezes, digitar `/clear`,
repetir. O que se quer automatizar é exatamente isso — **sem alterar a decisão tomada em nenhum
ponto**, porque a decisão já é constante ("a recomendação").

## Restrições que moldam o desenho

- **Fidelidade ao fluxo interativo, não só ao resultado.** A skill (`speckit-clarify/SKILL.md`,
  passo 5) instrui explicitamente "apresente EXATAMENTE UMA pergunta por vez" e encerra o turno
  esperando resposta. Uma automação que peça ao modelo para responder a si mesmo em um único turno
  contraria o texto da skill e pode gravar menos — ou nada.
- **`/clear` é obrigatório entre rodadas.** Cada rodada precisa começar com contexto zerado.
- **Teto de 5 perguntas por rodada** é da própria skill (passo 4 e regra de comportamento).
- **Cota é finita e o loop é hands-off.** A conta do Autor opera no limite de 5h com
  `overageStatus: rejected` (`out_of_credits`) — um loop desatendido não pode queimar rodadas
  falhando.

## Mecanismo (validado empiricamente)

Duas sondas contra `claude` 2.1.216 confirmaram o mecanismo antes do design ser fechado:

1. `claude -p --input-format stream-json --output-format stream-json --verbose` aceita mensagens de
   usuário em JSONL pelo stdin. (`--output-format=stream-json` **exige** `--verbose`.)
2. Com o stdin mantido aberto (FIFO), a sessão é **multi-turno**: preserva contexto entre turnos e
   emite **um evento `{"type":"result", ...}` por turno**. Fechar o stdin encerra o processo.

O evento `result` é o gancho central: ele significa "o assistente terminou de falar e está
esperando o usuário" — exatamente o momento em que hoje o Autor digita `yes`.

## Arquitetura

**Invariante central: uma rodada = um processo `claude`.** O término do processo *é* o `/clear`.
Não se usa `--continue` nem `--resume` em nenhum ponto.

Fluxo por rodada:

1. Resolve o spec alvo rodando `.specify/scripts/bash/check-prerequisites.sh --json --paths-only` e
   lendo `FEATURE_SPEC` — **a mesma fonte que a skill usa** (passo 1), de modo que script e skill
   nunca divirjam de arquivo-alvo.
2. Abre `claude -p --input-format stream-json --output-format stream-json --verbose`, com stdin
   ligado a um FIFO e `cwd` no repo do produto.
3. Injeta a primeira mensagem de usuário: `/speckit-clarify`.
4. Lê o stdout linha a linha; a cada evento `result`, classifica o turno e age.
5. Fecha o FIFO → o processo sai → equivale ao `/clear`.
6. Avalia o critério de parada; se não bateu, abre a rodada seguinte com contexto zero.

### Protocolo de decisão

Após cada evento `result`, o texto do turno é classificado:

| Sinal no texto do turno | Classificação | Ação |
|---|---|---|
| `**Recommended:**` ou `**Suggested:**` | pergunta pendente | injeta a mensagem de usuário `yes` |
| `No critical ambiguities detected` | loop seco | encerra o **loop inteiro** |
| `Suggested next command` (assinatura do Completion Report) | rodada completa | fecha a sessão; próxima rodada |
| nenhum dos anteriores | indeterminada | fecha a sessão e registra; **nunca fica pendurado** |

O `yes` injetado é literalmente o mesmo token que o Autor digita hoje — a skill (passo 5) trata
`yes` / `recommended` / `suggested` como aceite da própria recomendação.

Teto duro de **5 `yes` por rodada**, espelhando o limite da skill. Se estourar, a sessão é fechada
por segurança.

Essa classificação é **função pura de texto** e é o único componente do sistema que dá para testar
de forma determinística — ver "Verificação".

### Parada em camadas

O critério primário é a frase `No critical ambiguities detected`, mas ele depende de o modelo
emitir texto exato. Duas redes abaixo dele:

- **Estagnação:** o hash do `spec.md` é capturado antes e depois de cada rodada. **Duas rodadas
  seguidas sem alterar o arquivo** encerram o loop, mesmo sem a frase.
- **Teto duro:** `--max-rounds`, default **10**. O loop nunca é ilimitado.

### Aborto por erro (não degradar em silêncio)

O loop para imediatamente, reportando a causa, quando:

- um `rate_limit_event` chega com status ≠ `allowed`;
- um `result` chega com `is_error: true`;
- um `result` traz `permission_denials` não-vazio — rodada com ferramenta negada produz spec pela
  metade, e insistir só multiplica o dano.

### Permissões (mínimo necessário)

`--permission-mode acceptEdits` sozinho não basta: a skill roda `check-prerequisites.sh` via Bash, e
em modo não-interativo um prompt de permissão vira negação silenciosa. Logo:

```
--permission-mode acceptEdits \
--allowedTools 'Bash(.specify/scripts/bash/check-prerequisites.sh*)'
```

Sem `--dangerously-skip-permissions`: o objetivo é um loop desatendido cujo raio de ação é
conhecido — editar o spec e ler os pré-requisitos.

### Reversibilidade

O script **exige working tree limpo** ao iniciar (`--allow-dirty` para burlar conscientemente).
Assim o `git diff` ao final é exatamente o efeito do loop, e `git checkout -- <spec>` desfaz tudo.

### Observabilidade

- Stream bruto de cada rodada em `/tmp/speckit-clarify-loop/round-NN.jsonl` (matéria-prima para
  depurar quando a classificação escorregar).
- Resumo final: rodadas executadas, `yes` por rodada, causa da parada, custo somado
  (`total_cost_usd` dos eventos `result`) e delta de linhas do `spec.md`.

## Interface

```
speckit-clarify-loop [--repo DIR] [--max-rounds N] [--allow-dirty] [--dry-run] [--self-test]
```

| Flag | Efeito |
|---|---|
| `--repo DIR` | Repo alvo; default `cwd`. |
| `--max-rounds N` | Teto duro de rodadas; default 10. |
| `--allow-dirty` | Dispensa a exigência de working tree limpo. |
| `--dry-run` | Executa **uma** rodada com `Edit`/`Write` fora do `--allowedTools`, reportando as perguntas e os `yes` que teria injetado; o `spec.md` não é alterado. |
| `--self-test` | Roda os testes embutidos da classificação e sai. |

Por ser instalado por cópia para o PATH, o script **checa suas dependências no arranque**
(`claude`, `jq`, `git`, `mkfifo`) e falha com mensagem acionável — não pode presumir o ambiente de
nenhum repo.

## Verificação

A parte que envolve o modelo não é determinística e não se testa por igualdade. A **função de
classificação** (texto do turno → `pergunta-pendente` / `rodada-completa` / `loop-seco` /
`indeterminada`) é pura e é onde mora o risco real de regressão — se a skill mudar o texto do
`**Recommended:**`, o loop passa a responder errado.

`--self-test` exercita essa função contra fixtures embutidas no próprio arquivo (heredocs), cobrindo
no mínimo: pergunta múltipla escolha, pergunta de resposta curta (`**Suggested:**`), Completion
Report, "no critical ambiguities", e texto que não casa com nada. Um arquivo para copiar, um comando
para reverificar depois de um upgrade do Claude Code ou da skill.

## Fora de escopo (YAGNI)

- Responder qualquer coisa que não seja a recomendação (não há caso de uso — a decisão é constante).
- Commit automático por rodada; o `git diff` acumulado basta, e commitar esconde o efeito total.
- Iterar sobre múltiplas features/branches numa execução; uma execução, uma feature.
- Encadear `/speckit-plan` ou qualquer outro passo do Spec Kit após a convergência.
- Automação via PTY/tmux sobre a TUI real (fidelidade marginalmente maior, fragilidade alta).

## Alternativas rejeitadas

- **One-shot por rodada** (`claude -p "/speckit-clarify (responda cada pergunta com a própria
  recomendação)"`): ~30 linhas, sem parsing de JSON, mas contraria o passo 5 da skill; sem um
  usuário respondendo, o modelo pode encerrar após a primeira pergunta e gravar menos ou nada.
- **PTY/tmux + expect sobre a TUI:** fidelidade máxima ao caminho de renderização real, mas é
  screen-scraping de ANSI com dependência de timing — quebra a cada mudança de UI.
- **Script em `scripts/` do `zion-build-prd`:** traria dever de canonização (tabela §3 do
  `architecture.md`, `check-canon.sh` C3) para uma ferramenta que roda *nos repos de produto*,
  não no harness. Rejeitado por acoplamento indevido.
