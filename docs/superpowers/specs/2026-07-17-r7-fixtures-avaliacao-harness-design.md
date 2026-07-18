# R7 — Fixtures de avaliação do harness (design)

> **Recomendação de origem:** R7 em `docs/critica-zion-build-prd.md` — *"Fixtures de avaliação do
> harness: PRDs sintéticas com vazamentos/NFRs sem número/fatias horizontais conhecidos + roteiro que
> roda as skills e confere os vereditos."* Ataca o defeito **H2** (nenhum teste do próprio harness) e
> se apoia na infraestrutura de **R1/R3/R4** (verificadores mecânicos + fixtures + CI).
> **Data:** 2026-07-17.

## Problema

O harness não tem suíte de avaliação de si mesmo. Editar `assets/quality-rules.md` — o ponto único de
afinação — é mexer às cegas: não há fixture de PRD com vazamento conhecido pra conferir se a Fase 4 do
`write` acusa, nem teste de que o `decompose` reprova uma fatia horizontal (H2). Metade das regras
decidíveis já tem verificador mecânico (R1 `check-prd.sh`, R3 `check-adr.sh`, R2 `trace-prd.sh`), cada
um com fixtures e um `test-*.sh` no CI — mas essas peças estão espalhadas e cobrem só o que é
script-verificável. Os vereditos que dependem de julgamento do LLM (fatia horizontal, vazamento de
tela/aceite fora da denylist, ausência de "não faz") não têm nenhuma rede.

## Objetivo

Uma **suíte de avaliação de duas camadas** que:

1. **Consolida** a camada mecânica (já existente) num ponto de entrada único, rodado no CI.
2. **Adiciona** uma camada LLM que exercita o julgamento das skills criativas (discovery, write,
   decompose) contra artefatos com defeito plantado, com veredito esperado declarado — rodada sob
   demanda por um roteiro documentado.

Fora do objetivo (YAGNI): cobrir as 3 pontes na camada LLM, transformar o runner em skill, rodar a
camada LLM no CI, adicionar fixtures mecânicas novas, ou pinar o superpowers (R9).

## Arquitetura: duas camadas, um ponto de entrada

### Camada mecânica (determinística — CI a cada push)

Já ~90% pronta. R7 consolida os três self-tests num runner único `scripts/eval.sh`, que os roda e
emite veredito agregado (sai não-zero se qualquer um falhar). O CI passa a ter **um** passo de
avaliação em vez de três. **Nenhuma fixture mecânica nova** — a cobertura de script (stack, NFR sem
número, RF fora de épico, RF cobertos, evidência de ADR, rastreabilidade) já está completa.

### Camada LLM (não-determinística — sob demanda, nunca no CI normal)

É o gap real do H2. Fixtures são **artefatos com defeito plantado** (mesmo padrão `dirty` da camada
mecânica: entrada suja → espero que o veredito acuse). Para cada caso, roda-se a **lente de validação
da skill** (a Fase 4 dela) sobre a entrada e compara-se com o `esperado.md`.

**Princípio de testabilidade:** testa-se a skill como o `check-prd.sh` é testado — *entrada com defeito
conhecido → o veredito deve acusar*. Não se avalia a saída generativa livre (irreprodutível); planta-se
o defeito num artefato e exercita-se só o julgamento. Cada skill ganha também um par **`limpa`**
(entrada boa → veredito "aprova"), guarda contra a skill que reprova tudo (falso-positivo).

## Layout de diretórios

```
scripts/
  eval.sh                      # NOVO — runner único da camada mecânica; CI chama só isto
  test-check-prd.sh            # (existe) — perde o comentário "semente"; passa a ser chamado pelo eval.sh
  test-check-adr.sh            # (existe) — chamado pelo eval.sh
  test-trace-prd.sh            # (existe) — chamado pelo eval.sh
  fixtures/
    prd-clean.md prd-dirty.md …   # (existem) mecânicas — ficam onde estão
    adr/  trace/                   # (existem) mecânicas
    skills/                        # NOVO — raiz da camada LLM
      discovery/
        falta-nao-faz/  { discovery.md, esperado.md }
        limpa/          { discovery.md, esperado.md }
      write/
        vazamento-tela-aceite/ { PRD.md, esperado.md }
        limpa/                 { PRD.md, esperado.md }
      decompose/
        fatia-horizontal/ { backlog.md, esperado.md }
        skeleton-nao-r0/  { backlog.md, esperado.md }
        limpa/            { backlog.md, esperado.md }

docs/
  avaliacao-harness.md         # NOVO — o roteiro: narrativa + índice + como rodar as duas camadas
                               #        + procedimento do runner por agentes
```

Decisões de nome/lugar:

- `scripts/fixtures/skills/<skill>/<caso>/` — colado nas fixtures mecânicas, agrupado por skill, um
  caso por pasta. `<skill>` sem o prefixo `zion-prd-` (`discovery`, `write`, `decompose`).
- `docs/avaliacao-harness.md` — o roteiro é índice/narrativa descobrível em `docs/`, **não** a fonte
  da verdade (a fonte é cada `esperado.md`).
- `scripts/eval.sh` — nome do runner mecânico unificado.
- As fixtures LLM **não** são assets derivados: não entram em `scripts/asset-map.sh` nem no sync; são
  artefatos de teste próprios.

## O contrato `esperado.md` (sidecar por fixture)

Frontmatter legível por máquina (consumido pelo runner por agentes) + prosa (lida pelo humano):

```markdown
---
skill: zion-prd-decompose      # skill alvo
fase: 4                          # a lente exercitada (validar saída)
regra: "#invest"                 # âncora do quality-rules que decide
defeito: fatia-horizontal        # slug do defeito plantado (vazio na fixture limpa)
veredito: reprova                # reprova | aprova
achado_esperado:                 # o que um acerto contém (casado por semântica, não literal)
  - aponta a fatia como só-UI/só-back
  - manda refatiar (aplicar SPIDR)
---
## Defeito plantado
A fatia "S1 — montar todos os endpoints da API" é horizontal: entrega só backend, não passa no
teste-relâmpago "dá uma demo ponta-a-ponta?".

## Como reconhecer o acerto
A Fase 4 do decompose reprova S1, nomeia-a como horizontal e sugere refatiar por Path/Rules. Um
falso-negativo é deixar S1 passar no INVEST.
```

## Os seis casos LLM (v1)

| Skill | Caso | Defeito plantado | Veredito | Por que sem-script |
|---|---|---|---|---|
| discovery | `falta-nao-faz` | discovery.md sem nenhum "não faz" no quadro faz/não-faz | reprova | critério é prosa (Fase 4), sem `check-*` |
| discovery | `limpa` | visão em 1 frase + persona nomeada + "não faz" presentes | aprova | guarda de falso-positivo |
| write | `vazamento-tela-aceite` | PRD com wireframe / critério de aceite detalhado (não é termo da denylist) | reprova | `check-prd.sh` só pega a denylist de stack; tela/aceite é julgamento (zona cinzenta F6) |
| write | `limpa` | PRD limpa (pode reusar/derivar da `prd-clean.md`) | aprova | — |
| decompose | `fatia-horizontal` | backlog com fatia só-back ("montar todos os endpoints") | reprova | INVEST é puro LLM, sem script |
| decompose | `skeleton-nao-r0` | walking skeleton não é a fatia zero (R0) | reprova | idem |
| decompose | `limpa` | backlog vertical + skeleton em R0 | aprova | guarda de falso-positivo |

O caso `write/vazamento-tela-aceite` planta de propósito um vazamento que o `check-prd.sh` **não**
captura (tela/aceite ≠ denylist de stack), para testar o julgamento da skill em vez de redundar com o
script — exatamente a fronteira "zona cinzenta" do F6 da crítica.

## O roteiro (`docs/avaliacao-harness.md`)

Documento-guia da suíte. Conteúdo:

1. **As duas camadas e quando cada uma roda** — mecânica no CI a cada push; LLM sob demanda
   (não-determinística, custa token).
2. **Rodar a camada mecânica:** `scripts/eval.sh` → veredito agregado.
3. **Rodar a camada LLM à mão:** para cada pasta em `fixtures/skills/`, invocar a skill alvo sobre a
   entrada, comparar a resposta ao `esperado.md`, marcar acerto/erro.
4. **Índice de fixtures** — tabela de todos os casos (mecânicos + LLM) com defeito plantado e veredito
   esperado: o mapa "de relance" da suíte.
5. **Interpretação:** a camada LLM reporta **taxa de acerto**, não verde/vermelho binário. Um erro
   isolado não reprova o harness — dispara investigação (a skill mudou? o `quality-rules` derivou? a
   fixture está ambígua?).

### O runner por agentes (opcional — parte "automatiza depois" do híbrido)

Na v1 é um **procedimento documentado** dentro do roteiro (opção escolhida sobre "skill nova" e "script
Workflow"): passo-a-passo + prompt colável dado ao Claude Code, que itera as pastas `fixtures/skills/`,
dispara **um subagente por caso** para rodar a lente da skill sobre a entrada, e um **agente-juiz**
compara o resultado ao `achado_esperado` do sidecar, emitindo pass/fail + taxa de acerto.

Zero superfície nova a manter além de prosa. Se o roteiro provar valor, promove-se depois a uma skill
`/zion-prd-eval` **sem reescrever fixture nenhuma** — o contrato `esperado.md` já serve os dois modos.

## CI, tratamento de erro e bordas

**CI.** O `.github/workflows/check-assets.yml` colapsa os três passos de auto-teste em um:
`run: ./scripts/eval.sh`. O `eval.sh` roda os três `test-*.sh` e sai não-zero se qualquer um falhar
(preserva o comportamento atual, só unifica a porta). O passo de drift de assets (`check-assets.sh`)
continua separado. **A camada LLM não entra no CI.**

**Bordas:**

- `eval.sh` sem argumento roda tudo; com argumento (`prd`/`adr`/`trace`) roda um só — conveniência de
  dev.
- Fixture LLM com `esperado.md` malformado (sem `veredito`) → o roteiro instrui o runner a tratar como
  erro de suíte, não como falha da skill.
- Todo caso `dirty`/defeito tem par `limpa` — a suíte pega falso-negativo (não acusou o defeito) e
  falso-positivo (reprovou o que estava bom).

## Escopo

**Dentro (v1):**

- `scripts/eval.sh` unificando a camada mecânica + CI de um passo só.
- 6 fixtures LLM em `scripts/fixtures/skills/` (discovery/write/decompose) com sidecar `esperado.md`.
- `docs/avaliacao-harness.md`: roteiro + índice + procedimento do runner por agentes.
- Remoção do comentário "semente (R7)" do `test-check-prd.sh`.

**Fora (YAGNI / outras recomendações):**

- Skill `/zion-prd-eval` (promoção futura da opção b).
- Fixtures LLM das 3 pontes (constitution/specify/plan) — matriz completa fica pra v2.
- Rodar a camada LLM no CI ou agendada.
- Novas fixtures **mecânicas** (cobertura de script já completa).
- Pin de versão do superpowers (isso é R9).

## Critérios de conclusão

- `scripts/eval.sh` existe, roda os três self-tests e é o único passo de avaliação no CI; o CI segue
  verde.
- As 6 fixtures LLM existem com entrada + `esperado.md` válido; cada skill tem ao menos um par
  defeito/`limpa`.
- `docs/avaliacao-harness.md` existe com as 5 seções e o índice de todas as fixtures (mecânicas + LLM).
- O comentário "semente (R7)" saiu do `test-check-prd.sh`.
- Rodar o roteiro à mão sobre as 6 fixtures produz os vereditos esperados (validação manual única na
  entrega).
