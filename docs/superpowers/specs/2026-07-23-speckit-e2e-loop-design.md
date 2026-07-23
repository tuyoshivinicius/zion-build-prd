# Design — `speckit-e2e-loop`: orquestra a spec inteira em laço, do specify-prompt ao trace

- **Data:** 2026-07-23
- **Estado:** design validado em brainstorming, pronto para plano.
- **Natureza:** **ferramenta pessoal de linha de comando**, entregue como binário em
  `~/.local/bin/speckit-e2e-loop`, irmã do `speckit-clarify-loop`. **Não é artefato do repo
  `zion-build-prd`** — não entra em `scripts/`, não tem linha na tabela §3 do `architecture.md`, não
  é tocada por `check-canon.sh` nem por `eval.sh`. Este documento existe aqui porque é onde o
  brainstorming aconteceu.
- **Alvo de execução:** qualquer repositório com estrutura Spec Kit (`.specify/`) **e** o backlog do
  harness (`docs/backlog.md`), pelo `cwd` — os mesmos alvos do clarify-loop.
- **Alternativa escolhida:** **A2** do estudo `docs/estudos/speckit-e2e-loop.md` — orquestrador com
  checkpoints, retomada e parada-por-achado.

## Problema

O fluxo que leva **uma** spec do backlog até "pronta para codar" cruza a fronteira harness↔Spec Kit e
hoje é conduzido inteiramente à mão, sempre nos mesmos 8 passos, cada um numa sessão limpa:

1. `/zion-prd-specify-prompt <slug>` — a ponte monta o prompt do specify e **para** (ADR-005).
2. O Autor cola o `/speckit.specify "..."` numa sessão nova — nasce a branch `specs/###-slug` e o
   `spec.md`.
3. Clarificação em laço (hoje já automatizada pelo `speckit-clarify-loop`).
4. `/zion-prd-plan-prompt <feature>` — a ponte propõe os ADRs, **pergunta** ao Autor para confirmar, e
   monta o prompt do plan e **para**.
5. `/speckit.plan "..."` — nasce o `plan.md`.
6. `/speckit.tasks` — nasce o `tasks.md`.
7. `/speckit.analyze` — achados advisórios.
8. `/zion-prd-trace` — reconcilia o canon do produto (PRD §12, backlog, `architecture.md`).

A toil é mecânica: copiar cada prompt da ponte, colar no `/speckit.*`, dar `/clear`, repetir por 7
sessões, sem esquecer o `trace` no fim. O que se quer automatizar é o **encadeamento** — sem trair a
filosofia do harness ("gates aconselham, humano decide", ADR-004): o laço roda hands-off **até bater
num achado que um humano de verdade não deixaria passar**, e aí para.

## Restrições que moldam o desenho

- **A invariante e o padrão do `speckit-clarify-loop`.** Ferramenta pessoal instalada por cópia no
  PATH; checa as próprias dependências no arranque; **uma unidade de trabalho = um processo `claude`**
  (o término do processo *é* o `/clear`; nunca `--continue`/`--resume`); aborta duro em rate-limit,
  `is_error` e permissão negada; exige working tree limpo; tem um núcleo puro testável por harness
  determinístico a custo zero. O e2e-loop **reusa** essa base e **delega ao próprio clarify-loop** no
  passo 3.
- **ADR-005 — as pontes montam prosa e param.** Nenhuma ponte dispara `/speckit.*`. O laço **captura a
  saída delas e cruza a fronteira ele mesmo**. A captura **não** pode depender de editar as skills
  (isso seria a alternativa A3 — canon distribuído + supersessão do ADR-005 — deixada no bolso).
- **ADR-004 — verificadores aconselham.** Os gates das pontes *perguntam* (o `plan-prompt` Fase 1
  pede confirmar/editar a lista de ADRs; o `specify-prompt` pergunta "segue?"); a Fase 4 **só
  aconselha** (`check-prd.sh`). O laço decide o que fazer com achado advisório sem humano na sala.
- **Cota finita, laço desatendido.** A conta opera no limite de 5h com `overageStatus: rejected`. Um
  pipeline de ~8 passos pagos não pode queimar cota falhando nem repetir passos já feitos numa falha.
- **Escopo "pronto para codar".** O fluxo **termina no `trace`**. `checklist`/`implement`/`converge`
  ficam fora — não se escreve código (edge case #8 do estudo).

## Decisões do brainstorming

Quatro forks resolvidos com o Autor; cada um cita o edge case do estudo que fecha.

1. **Autonomia dos gates das pontes (#2).** O laço **auto-aceita** (`confirma/segue`) por padrão e
   **registra no relatório** a lista de ADRs proposta e cada gate cruzado. **Exceção:** se a *guarda
   de suficiência* do `plan-prompt` disparar (spec vago demais para inferir relevância de ADR), isso
   vira **parada** e entrega ao humano — a própria ponte sinalizou que falta peça. Alinha a autonomia
   à filosofia do harness sem inventar limiar novo.
2. **Limiar de parada-por-achado (#7).** Fora dos abortos duros herdados do clarify, o laço **PARA e
   mostra** num conjunto crítico curado: (i) `check-prd.sh` acusa **vazamento de stack** (no prompt do
   specify e/ou no `spec.md` gerado); (ii) `/speckit.analyze` reporta **inconsistência de severidade
   crítica**; (iii) o `speckit-clarify-loop` sai **rc ≠ 0** (bateu o teto sem convergir). Achado menor
   do `analyze` é logado e o laço segue. Tudo limpo → roda até o `trace`.
3. **Seam de extração (#1).** **File-drop em runtime, fora do canon.** O orquestrador injeta um
   `--append-system-prompt` que instrui a ponte a, além de imprimir, **gravar o comando `/speckit.*`
   exato num arquivo** (`next.txt`) e um token de status (`OK`/`SUFFICIENCY_STOP`) em `signal.txt`. A
   extração fica determinística (lê arquivo), o texto das skills **não muda** (ADR-005 intacto — é
   instrução por-execução, não edição de skill distribuída), e a falha é **detectável** (arquivo
   ausente/vazio → aborta o passo), não um parser que pega a string errada em silêncio. Preferido
   sobre raspar prosa (A1, mesma classe de fragilidade que o clarify-loop *arrancou fora* ao trocar
   classificação-por-prosa por sentinela) e sobre editar a skill (A3, canon).
4. **Git, retomada e reversibilidade (#5, #6, #10).** **Tudo-ou-nada, sem commit.** Exige tree limpo
   no início (`--allow-dirty` burla); A2 **nunca commita** (nem os passos do Spec Kit, nem o `trace`).
   Ao fim, **branch nova + `git diff` = efeito total**, num diff único — a mutação de canon do `trace`
   fica **junto**, máximo de revisão. Retomada **idempotente** por um arquivo de estado **fora do
   repo** mais a existência dos artefatos do Spec Kit; `--from <passo>` força.

## Arquitetura

**Invariante central (herdada):** um passo = um processo `claude`. O término do processo *é* o
`/clear`. Não se usa `--continue`/`--resume` em nenhum ponto.

### A máquina de estados (8 passos)

| # | Passo (`--from`) | Tipo | Produz | "Feito" quando |
|---|---|---|---|---|
| 1 | `specify-prompt` | ponte (`/zion-prd-specify-prompt <slug>`) | `/speckit.specify "..."` | `next.txt` gravado |
| 2 | `specify` | Spec Kit (`/speckit.specify "..."`) | branch `specs/###-slug` + `spec.md` | `spec.md` existe |
| 3 | `clarify` | **delega a `speckit-clarify-loop`** | edições no `spec.md` | tool sai rc 0 |
| 4 | `plan-prompt` | ponte (`/zion-prd-plan-prompt <feature>`) | `/speckit.plan "..."` | `next.txt` gravado |
| 5 | `plan` | Spec Kit (`/speckit.plan "..."`) | `plan.md` | `plan.md` existe |
| 6 | `tasks` | Spec Kit (`/speckit.tasks`) | `tasks.md` | `tasks.md` existe |
| 7 | `analyze` | Spec Kit (`/speckit.analyze`) | achados advisórios | turno classificado |
| 8 | `trace` | harness (`/zion-prd-trace`) | reconciliação do canon do produto | turno classificado |

**Input = o slug do backlog** (antes de a branch existir, #4). A branch criada no passo 2 é o
**cursor compartilhado** dos passos 3–8; todos correm na mesma working tree, resolvendo o alvo por
`.specify/scripts/bash/check-prerequisites.sh --json --paths-only` — a mesma fonte que o clarify-loop
e a skill usam, para nunca divergirem de arquivo-alvo.

### Sessão e extração (file-drop)

Cada passo abre um `claude -p --input-format stream-json --output-format stream-json --verbose`, com
stdin ligado a um FIFO e `cwd` no repo do produto — exatamente o mecanismo validado do clarify-loop.
A cada evento `{"type":"result"}` (fronteira de turno: "o assistente terminou e espera o usuário") o
orquestrador classifica o turno e age.

**Passos de ponte (1 e 4).** O orquestrador injeta um `--append-system-prompt` (instrução por
execução, não edição de skill) que instrui:

> Além de imprimir o comando `/speckit.*`, grave-o **exatamente** (a linha `/speckit.… "…"` inteira)
> em `<scratch>/next.txt`, e grave `OK` ou `SUFFICIENCY_STOP` em `<scratch>/signal.txt`. **Não**
> execute o `/speckit.*` — apenas grave e pare.

O `--append-system-prompt` **não** contradiz a Fase 4 da ponte (que já manda parar); só acrescenta o
efeito colateral do arquivo. O **`next.txt` dobra como sinal de "ponte terminou"**: após cada
`result`, se `next.txt` existe e é não-vazio → o passo está feito, fecha a sessão. Se o turno for um
gate ("confirme a lista de ADRs?" / "segue mesmo assim?") — `next.txt` ainda ausente — o orquestrador
injeta `confirma, siga` (decisão #1), com **teto de confirmações por sessão de ponte** para nunca
ficar pendurado num gate que se repete.

**Passos de Spec Kit (2, 5, 6, 7).** O orquestrador injeta o comando como mensagem de usuário — para
`specify` e `plan`, a string vem do `next.txt` do passo de ponte anterior; para `tasks`/`analyze`, é o
literal `/speckit.tasks` / `/speckit.analyze`. Esses passos são esperados **one-shot** (produzem o
artefato, emitem `result`, encerram). Um turno que pede algo inesperado é classificado
`indeterminada` → fecha a sessão e registra — **nunca fica pendurado**, igual ao clarify. A
interatividade real de cada passo (#3) é confirmada por **sondagem empírica** na validação (ver
abaixo), não presumida.

**Passo de clarify (3) e de trace (8).** O clarify **delega ao binário `speckit-clarify-loop`** (que
já resolve o alvo, roda em sessão limpa por rodada e sai com rc que o e2e-loop lê). O `trace` injeta
`/zion-prd-trace` e classifica o turno de conclusão.

### Protocolo de decisão e parada

Após cada `result`, o texto/estado do turno determina a ação. **`signal.txt` é lido primeiro:**
`SUFFICIENCY_STOP` encerra o laço antes de qualquer outra classificação — mesmo que a ponte já tenha
gravado `next.txt` no mesmo turno (o `plan-prompt` não bloqueia e pode montar um prompt degradado; o
sinal tem precedência).

| Situação | Classificação | Ação |
|---|---|---|
| Ponte pediu confirmação de ADRs / "segue?" (`next.txt` ausente) | gate | injeta `confirma, siga` (teto por sessão) |
| Ponte terminou (`next.txt` não-vazio) | ponte-completa | fecha a sessão; segue ao passo Spec Kit |
| `signal.txt = SUFFICIENCY_STOP` | **parada** | encerra o laço; entrega ao humano (#1) |
| Passo Spec Kit produziu o artefato | passo-completo | fecha a sessão; próximo passo |
| Turno inesperado / não casa | indeterminada | fecha e registra; nunca pendura |

**Parada-por-achado (#2), avaliada pelo orquestrador — não raspando prosa:**

- **Vazamento de stack.** Após o passo 1, o orquestrador roda **ele mesmo** `check-prd.sh specify -`
  sobre o conteúdo de `next.txt` (o prompt do specify); após o passo 2, roda `check-prd.sh` sobre o
  `spec.md` gerado. Achado `stack` → **parada**. Determinístico (o script já é a fonte curada da
  fronteira), não depende do veredito em prosa que a ponte ecoa.
- **`analyze` crítico.** O texto do turno do passo 7 é classificado (crítico?/limpo). Este é o
  **único classificador model-driven residual** do sistema — mora no núcleo testável, coberto por
  fixtures. Achado crítico → **parada**; achado menor → logado, segue.
- **clarify não convergiu.** O `speckit-clarify-loop` sai `rc ≠ 0` → **parada**.

**Abortos duros por passo (herdados do clarify-loop), sempre:** `rate_limit_event` com status ≠
`allowed`; `result` com `is_error: true`; `result` com `permission_denials` não-vazio.

### Estado, retomada e reversibilidade

O estado vive **fora do repo** (mantém a working tree limpa e o "um diff = efeito"), keyed por slug:

```
/tmp/speckit-e2e-loop/<slug>/
  state          # passos concluídos, custo por passo, branch resolvida
  next.txt       # comando /speckit.* capturado do passo de ponte corrente
  signal.txt     # OK | SUFFICIENCY_STOP do passo de ponte corrente
  step-NN.jsonl  # stream bruto de cada passo (matéria-prima de depuração)
```

**Retomada idempotente:** ao iniciar, lê `state` **e** confere os artefatos (`spec.md`/`plan.md`/
`tasks.md` existem, na branch certa). Um passo já feito é pulado. Ponto crítico (#6): **specify não é
re-rodado se `spec.md` já existe** — re-rodar recriaria a branch e regeneraria o `spec.md`, apagando
as edições do clarify. `--from <passo>` **força** a re-execução a partir daquele passo e limpa os
marcadores a jusante.

**Reversibilidade:** working tree limpo exigido no arranque (`--allow-dirty` para burlar
conscientemente). A2 **nunca commita**. Ao final, `git diff` (spec + plan + tasks + a reconciliação do
`trace`) mais a branch nova são o efeito total, num diff único para o humano revisar e commitar;
`git checkout -- .` + apagar a branch desfaz tudo.

### Permissões e custo (mínimo necessário)

`--permission-mode acceptEdits` sozinho não basta — o clarify-loop provou que um prompt de permissão
em modo não-interativo vira **negação silenciosa**. Cada passo recebe seu **`--allowedTools` mínimo**
(as pontes precisam de `Bash(...check-prd.sh*)`, `Read` e `Write(<scratch>/…)`; os passos Spec Kit
precisam de `Bash(.specify/scripts/bash/*)`, `Write`, `Edit`; o `trace` precisa dos scripts de trace
e `Edit` do canon). Sem `--dangerously-skip-permissions`: o raio de ação é conhecido.

Teto global de custo `--max-cost USD` soma `total_cost_usd` de todos os eventos `result`; estourou →
aborta (#9). Combinado com o aborto-em-rate-limit por passo, um laço desatendido não queima cota
falhando.

## Interface

```
speckit-e2e-loop <slug> [--repo DIR] [--from PASSO] [--max-cost USD]
                        [--allow-dirty] [--dry-run] [--quiet] [--self-test]
```

| Flag | Efeito |
|---|---|
| `<slug>` | Slug da spec no `docs/backlog.md` (obrigatório). Entrada do laço, antes da branch existir. |
| `--repo DIR` | Repo alvo; default `cwd`. |
| `--from PASSO` | Retoma de um passo ∈ {`specify-prompt`, `specify`, `clarify`, `plan-prompt`, `plan`, `tasks`, `analyze`, `trace`}, forçando re-execução e limpando o que vem depois. |
| `--max-cost USD` | Teto global de custo somado; estourou, aborta. |
| `--allow-dirty` | Dispensa a exigência de working tree limpo. |
| `--dry-run` | Roda **só o passo 1** com `Edit`/`Write` fora do `--allowedTools`, reportando o comando que capturaria e as injeções que faria; não toca o repo (semântica do clarify-loop). |
| `--quiet` | Cala a narração no stdout; os logs por passo e o resumo continuam. |
| `--self-test` | Roda os testes embutidos do núcleo puro e sai. |

Por ser instalado por cópia para o PATH, o script **checa suas dependências no arranque** (`claude`,
`jq`, `git`, `mkfifo`, e o binário `speckit-clarify-loop`) e falha com mensagem acionável — não presume
o ambiente de nenhum repo.

## Verificação

A parte que envolve o modelo não é determinística e não se testa por igualdade. O **núcleo puro** é
onde mora o risco real de regressão (#11):

- a **máquina de estados** (ordem dos passos, detecção de "feito" por artefato/estado, resolução do
  `--from` e limpeza a jusante);
- o **leitor de extração** (`next.txt` presente, não-vazio, começa com `/speckit.`);
- o **leitor de sinal** (`OK` vs `SUFFICIENCY_STOP`);
- a **lógica de retomada** (state + artefatos → conjunto de passos a pular);
- o **classificador do `analyze`** (texto do turno → `crítico` / `limpo`).

`--self-test` exercita essas funções contra fixtures embutidas (heredocs). Um **harness com stub
determinístico do `claude`** — no padrão do `speckit-clarify-loop-harness.sh`, um `claude` falso que
emite stream-json roteirizado por passo — roda a **máquina inteira a custo zero**, cobrindo no mínimo:
laço completo até o `trace`; retomada via `--from`; parada por `SUFFICIENCY_STOP`; parada por
`check-prd.sh` (stack); parada por `analyze` crítico; parada por clarify `rc ≠ 0`; corte externo no
meio (crash) deixando `state` retomável e sem artefato corrompido.

**Validação empírica paga (não hand-wave, #3):** uma sondagem por passo contra o `claude` real e as
skills de verdade, num repo Spec Kit vivo — confirmando que cada passo do Spec Kit é one-shot (ou
mapeando onde pausa), que o file-drop grava o `next.txt`/`signal.txt` como instruído, e que a
`--append-system-prompt` não faz a ponte disparar o `/speckit.*`. É a mesma disciplina com que o
clarify-loop fechou seu mecanismo antes de confiar nele.

## Fora de escopo (YAGNI)

- Passos além do `trace`: `checklist`, `implement`, `converge` — o escopo é "spec pronta para codar",
  não escrever código (#8).
- Commit automático por passo — o `git diff` acumulado basta, e commitar esconde o efeito total (mesma
  lição do clarify-loop).
- Iterar sobre múltiplas specs/slugs numa execução — uma execução, uma spec.
- **Editar as skills-ponte** para emitir contrato de máquina (alternativa A3) — fica **no bolso**; só
  se paga o custo de canon (supersessão do ADR-005, `sync-assets`, `check-canon`, viagem a todos os
  usuários) se o file-drop provar-se instável na prática.
- Automação via PTY/tmux sobre a TUI real — fidelidade marginal, fragilidade alta.

## Alternativas rejeitadas

Herdadas do estudo `docs/estudos/speckit-e2e-loop.md` (A0/A1/A3), mais o fork de sessão fechado no
brainstorming:

- **A0 — não fazer:** mantém a toil de copiar/colar/limpar por 7 sessões intocada.
- **A1 — orquestrador linear "fino":** roda até o fim e despeja os vereditos num relatório, sem parar
  em achado. Colapsaria A2 na casca sem a parada-por-achado (#7) — adia o julgamento em vez de
  eliminá-lo. A retomada e a parada de A2 são justamente o que o difere.
- **A3 — contrato de máquina nas pontes:** extração à prova de reformulação, mas mexe em skill
  distribuída (canon) e **supersede o ADR-005**, viajando a todos os usuários por uma ferramenta
  pessoal. Substituído pelo file-drop em runtime, que dá o determinismo sem o custo de canon.
- **Fundir ponte + comando na mesma sessão** (economizar um processo): rejeitado. Um slash command só
  é despachado quando vem numa **mensagem de usuário**, não quando o modelo o emite na resposta — logo
  o orquestrador precisa da string exata de qualquer forma. O file-drop entrega isso mantendo a
  invariante de sessão limpa por passo; fundir só traria bleed de contexto sem eliminar o seam.
