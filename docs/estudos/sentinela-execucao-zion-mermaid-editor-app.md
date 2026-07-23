# Estudo — a execução do sentinela em `zion-mermaid-editor-app` (métricas de sucesso)

## Contexto

O **sentinela** não é um artefato do `zion-mermaid-editor-app`. É o **contrato de saída de estado**
do harness `tools/speckit-clarify-loop`, que automatiza o ciclo `/speckit.clarify` do Spec Kit sob a
invariante "uma rodada = um processo `claude`" (`tools/speckit-clarify-loop:1-5`). O contrato manda o
modelo fechar **cada turno** com uma linha própria, âncorada e legível por máquina
(`tools/speckit-clarify-loop:163-192`):

```
CLARIFY_STATE: ASKING | COMPLETE | NO_AMBIGUITY
```

`ASKING` pede resposta (o harness injeta um `yes`), `COMPLETE` fecha a rodada, `NO_AMBIGUITY` é o
loop-seco que converge. A poda de 2026-07-21 matou a antiga heurística de prosa bilíngue e deixou o
sentinela como **caminho único** de classificação: turno sem sentinela vira `indeterminada`, sonda
com o `REPLY_PROBE` e só aborta na segunda ausência seguida
(`tools/speckit-clarify-loop:278-303`, `:225`). Toda a aposta da poda é que o contrato se sustente na
prática — e o `zion-mermaid-editor-app` foi o principal campo de prova real dessa mudança.

Este estudo mede se o contrato aderiu na única execução real contra o app cujos logs sobreviveram.

**Nota de canon.** O `speckit-clarify-loop` é ferramenta pessoal **fora do canon** do harness — não
está na tabela de scripts (`docs/architecture.md §3`) nem em RF do `docs/prd.md §6`
(`docs/estudos/refatoracao-final-speckit-clarify-loop.md:23-30`). Um estudo sobre um *run* dessa
ferramenta não reflete em PRD/ADR e não aciona o `check-canon.sh`.

## A execução

- **Run:** `/tmp/speckit-clarify-loop/20260721-112131` (o symlink `latest`).
- **Alvo:** `specs/001-cano-modelo-codigo/spec.md` do `zion-mermaid-editor-app`.
- **Forma:** loop de **7 rodadas**, cada uma um processo `claude` próprio, com o `SENTINEL_PROMPT`
  injetado via `--append-system-prompt` (`tools/speckit-clarify-loop:833`).
- **Reconstrução:** o bloco `—— resumo ——` é impresso em stdout e não é gravado
  (`tools/speckit-clarify-loop:1058-1078`); as métricas abaixo foram reconstruídas dos
  `round-NN.jsonl` preservados (eventos `type=="result"`), com os comandos da seção **Reprodução**.

## Métricas de sucesso

| Métrica | Valor |
|---|---|
| Rodadas | 7 (R1–R6 fecharam em `COMPLETE`; R7 interrompida após 1 turno) |
| Turnos do harness (eventos `result`) | 35 |
| **Sentinela emitida** | **35 / 35 turnos — 100% de adesão ao contrato** |
| Faltas de sentinela (`SENT_MISS`) | **0** → 0 sondas, 0 abortos |
| Decisões nomeadas (`CLARIFY_DECISION`) | 27 |
| Respostas injetadas (`yes`) | 29 |
| Avisos de rate-limit tratados | 9 × `allowed_warning` — 0 fatais, 0 abortos |
| Vazamento `CLARIFY_` no spec commitado | 0 |
| Custo total | **US$ 16,44** (≈ US$ 2,35/rodada · ≈ US$ 0,47/turno · ≈ US$ 0,57/decisão) |
| Tempo | ~39,5 min de relógio (11:28 → 12:07); ~11 min de compute `claude` |

**Leitura.** O contrato de estado aderiu em **100% dos turnos reais**. Todo turno terminou com uma
linha `CLARIFY_STATE` âncorada e legível — o ramo `indeterminada`/sonda/aborto nunca precisou
existir. A máquina de estado andou exatamente como projetada (`ASKING` → injeta `yes`; `COMPLETE` →
fecha a rodada), e nada do prefixo `CLARIFY_` vazou para o spec. Este é o resultado que o `S-4`
prometia e que a poda apostou: a sentinela sozinha, sem heurística de prosa por baixo, classificou
cada turno sem uma única falha.

## Adesão do contrato por rodada

| Rodada | Turnos | Sentinela | `yes` | Decisões | +linhas | −linhas | Custo (US$) | Estados |
|---|---|---|---|---|---|---|---|---|
| R01 | 6 | 6/6 | 5 | 5 | 71 | 24 | 2,3848 | `ASKING`×5 → `COMPLETE` |
| R02 | 6 | 6/6 | 5 | 5 | 60 | 16 | 2,1184 | `ASKING`×5 → `COMPLETE` |
| R03 | 6 | 6/6 | 5 | 5 | 62 | 15 | 2,6094 | `ASKING`×5 → `COMPLETE` |
| R04 | 6 | 6/6 | 5 | 4 | 76 | 20 | 3,1281 | `ASKING`×5 → `COMPLETE` |
| R05 | 5 | 5/5 | 4 | 4 | 61 | 10 | 2,4511 | `ASKING`×4 → `COMPLETE` |
| R06 | 5 | 5/5 | 4 | 4 | 58 | 17 | 2,9365 | `ASKING`×4 → `COMPLETE` |
| R07 | 1 | 1/1 | 1 | 0 | — | — | 0,8108 | `ASKING` (interrompida) |
| **Σ** | **35** | **35/35** | **29** | **27** | **388** | **102** | **16,44** | — |

Duas observações de leitura fina:

- **`yes` (29) > decisões nomeadas (27).** Dois turnos responderam mas não emitiram uma linha
  `CLARIFY_DECISION` bem-formada — a segunda família do contrato (`decisions_of`,
  `tools/speckit-clarify-loop:236-244`) é a de menor adesão, e o resumo cobre esse caso com o
  fallback "texto indisponível — contrato não aderiu" (`:257-266`). O número de `yes` segue honesto;
  o que faltou foi só o rótulo do assunto.
- **Churn ≫ decisões.** Cada rodada integrou 4–5 respostas mas mexeu em 58–76 linhas: a skill
  reescreve FRs, edge cases e critérios ao integrar cada resposta, não só anexa a decisão.

## Guardas exercitadas (e o que a execução NÃO prova)

- **Rate-limit não-fatal.** Chegaram **9 eventos `allowed_warning`** ao longo do run, todos tratados
  como permissão pela `ratelimit_fatal` (`tools/speckit-clarify-loop:840-857`) — nenhum abortou
  rodada. É exatamente o cenário que já custou, no passado, uma rodada paga com 1 `yes` integrado e
  US$ 2,40 jogados fora (`tools/speckit-clarify-loop:329-343`): aqui a guarda corrigida segurou.
- **Sem vazamento.** Zero linhas `CLARIFY_` no spec commitado — a `leaked_sentinel` casa contra as
  linhas *adicionadas*, não contra o spec inteiro, e não teve falso positivo.
- **O ramo da sonda seguiu sem execução real.** Como a sentinela nunca faltou, `indeterminada` nunca
  disparou e `REPLY_PROBE`/`miss_action` continuaram exercitados só pelo auto-teste e por leitura — a
  mesma lacuna que o cabeçalho da ferramenta já registra (`tools/speckit-clarify-loop:60-67`). Uma
  rodada real com o contrato falhando é o que falta, e ela não se encomenda. **Sucesso do contrato e
  ausência de teste do ramo de recuperação são a mesma moeda: o contrato não falhou, então a rede
  não foi puxada.**

## Ressalva de convergência

O run **não convergiu sozinho**. Não houve `NO_AMBIGUITY` (loop-seco) nem estagnação (duas rodadas
sem mexer no spec). R7 registra um único turno `ASKING` — o modelo abriu uma pergunta nova, emitiu a
sentinela corretamente, e o log corta no meio da exploração (custo US$ 0,81, 1 evento `result`). É
assinatura de **interrupção externa** durante a primeira pergunta da 7ª rodada, não de parada pela
lógica do harness (que teria injetado o `yes` e seguido). O spec foi então revisado e commitado
(`zion-mermaid-editor-app@d425ff8`, "cravar as vinte e oito clarificações").

Portanto a condição de parada real desta execução foi: **6 rodadas completas + 1 interrompida**. A
métrica de adesão do sentinela (35/35) permanece íntegra — a interrupção não a contamina, porque o
turno de R7 emitiu a sentinela antes do corte.

## Reprodução

Todos os números são re-deriváveis dos logs em `/tmp/speckit-clarify-loop/20260721-112131`:

```sh
D=/tmp/speckit-clarify-loop/20260721-112131
# turnos, sentinela, yes e decisões por rodada
for f in "$D"/round-0*.jsonl; do
  turns=$(jq -rc 'select(.type=="result")' "$f" | wc -l)
  sent=$(jq -rc 'select(.type=="result") | .result // "" | select(test("(?:^|\n)CLARIFY_STATE: (?:ASKING|COMPLETE|NO_AMBIGUITY)[ \t]*$";"n")) | "x"' "$f" | wc -l)
  yes=$(jq -rc 'select(.type=="result").result // ""' "$f" | grep -cE '(^|\n)CLARIFY_STATE: ASKING[ \t]*$')
  decis=$(jq -rc 'select(.type=="result").result // ""' "$f" | grep -oE 'CLARIFY_DECISION: .+ -> ' | wc -l)
  echo "$(basename "$f"): turns=$turns sent=$sent yes=$yes decis=$decis"
done

# custo total (soma dos total_cost_usd finais por rodada) e avisos de rate-limit
jq -rc 'select(.type=="result").total_cost_usd' "$D"/round-0*.jsonl
jq -rc 'select(.type=="rate_limit_event").rate_limit_info.status' "$D"/round-*.jsonl | sort | uniq -c

# nenhum CLARIFY_ vazou para o spec (espera 0)
grep -c "^CLARIFY_" \
  /home/tuyoshi/projects/personal/zion-mermaid-editor-app/specs/001-cano-modelo-codigo/spec.md
```
