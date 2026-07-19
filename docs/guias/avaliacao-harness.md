# Avaliação do harness

> **Governança:** este documento é **guia de uso**, não normativo. Os requisitos do harness vivem
> em [`docs/prd.md`](../prd.md) e a arquitetura em [`docs/architecture.md`](../architecture.md) —
> as fontes da verdade deste repo.

O harness tem uma suíte de avaliação de si mesmo, em duas camadas. Este documento é o **roteiro**:
narra as camadas, indexa todas as fixtures e diz como rodá-las. A **fonte da verdade** de cada caso LLM
é o `esperado.md` ao lado da entrada — este índice só aponta para eles.

## 1. As duas camadas e quando cada uma roda

- **Camada mecânica (determinística).** Os verificadores de script (`check-prd.sh`, `check-adr.sh`,
  `trace-prd.sh`, `check-superpowers-contract.sh`, `check-canon.sh`) contra fixtures `clean`/`dirty`,
  consolidados em `scripts/eval.sh`. Roda **no CI a cada push** (passo "Avaliação da camada mecânica"). Verde/vermelho
  binário. O check de contrato **degrada gracioso**: sem o superpowers instalado ele sai 0
  ("não verificável"), então quem garante a lógica no CI é o auto-teste contra fixtures.
- **Camada LLM (não-determinística).** Fixtures com defeito plantado que exercitam o **julgamento** das
  skills criativas (discovery, write, decompose) — os vereditos que nenhum script decide (fatia
  horizontal, vazamento de tela/aceite, ausência de "não faz"). Roda **sob demanda**, à mão ou por
  agentes: custa token e não é reprodutível bit-a-bit, então **nunca entra no CI**.

> A camada mecânica inclui um **check de contrato** (`check-superpowers-contract.sh`, R9): o harness usa
> `superpowers:brainstorming` como executor de três estágios e depende de **três capacidades** dele
> (C1–C3). O check faz `grep` de marcadores dessas capacidades no `SKILL.md` instalado e acusa se
> alguma sumir num upgrade. A especificação das capacidades, os marcadores e o runbook de drift vivem
> em `assets/superpowers-contract.md`. O pin `">=5 <7"` no `plugin.json` trava a porta; o check diz
> se dá para alargar.

## 2. Rodar a camada mecânica

    ./scripts/eval.sh              # roda todos os self-tests → veredito agregado
    ./scripts/eval.sh prd          # roda só um (prd | adr | trace | backlog | contract | canon)

Exit 0 = tudo verde; exit 1 = algum self-test falhou; exit 2 = argumento inválido. É exatamente o que o
CI executa.

## 3. Rodar a camada LLM à mão

Para cada pasta em `scripts/fixtures/skills/<skill>/<caso>/`:

1. Abra o `esperado.md` e leia o frontmatter (`skill`, `fase`, `regra`, `veredito`, `achado_esperado`).
2. Invoque a **skill alvo** (`zion-prd-<skill>`) rodando a **lente da Fase 4 dela** sobre o artefato de
   entrada (`discovery.md` / `PRD.md` / `backlog.md`) da pasta. Na `ajuda`, a entrada é a
   `pergunta.md` e a lente é o molde de 4 blocos da **Fase 2** (a skill não tem Fase 4 — não há saída
   a validar).
3. Compare a resposta da skill ao `achado_esperado` (casado por **semântica**, não literal) e ao
   `veredito` (reprova/aprova).
4. Marque **acerto** (a skill produziu o veredito esperado e cobriu os achados) ou **erro**.

## 4. Índice de fixtures

### Mecânicas (camada determinística — CI)

| Verificador | Fixture | Defeito plantado | Veredito |
|---|---|---|---|
| `check-prd.sh` | `fixtures/prd-clean.md` | — | limpo (exit 0) |
| `check-prd.sh` | `fixtures/prd-dirty.md` | stack (React/Zustand/npm), NFR sem número, RF fora de épico | achados (exit 1) |
| `check-prd.sh specify` | `fixtures/specify-dirty.txt` | stack no prompt do specify | achados (exit 1) |
| `check-prd.sh specify` | `fixtures/specify-sem-rf.txt` | prompt sem a linha **RF cobertos:** | achados (exit 1) |
| `check-adr.sh` | `fixtures/adr/clean/` | — | limpo (exit 0) |
| `check-adr.sh` | `fixtures/adr/dirty/` | sem-evidência, spike-dir ausente/vazio/sem-readme, evidência-sem-lastro | achados (exit 1) |
| `trace-prd.sh` | `fixtures/trace/` | RF órfão, spec intraçável, RF descoberto | avisos (exit 1) |
| `trace-prd.sh` | `fixtures/trace/clean/` | — | em dia (exit 0) |
| `check-superpowers-contract.sh` | `fixtures/superpowers/clean/` | — (C1–C3 presentes) | contrato intacto (exit 0) |
| `check-superpowers-contract.sh` | `fixtures/superpowers/drift-c2/` | marcador de C2 (gravar doc sob docs/) removido | drift, cita C2 (exit 1) |
| `check-canon.sh` | `fixtures/canon/clean/` | — | limpo (exit 0) |
| `check-canon.sh` | `fixtures/canon/dirty/` | skill órfã/fantasma, script/asset sem doc, ADR fora do índice, regra raiz incompleta, stack na PRD | achados (exit 1) |

### LLM (camada de julgamento — sob demanda)

| Skill | Caso | Entrada | Defeito plantado | Veredito |
|---|---|---|---|---|
| discovery | `falta-nao-faz` | `discovery.md` | quadro faz/não-faz sem nenhum "não faz" | reprova |
| discovery | `limpa` | `discovery.md` | — (visão + persona + "não faz") | aprova |
| write | `vazamento-tela-aceite` | `PRD.md` | tela/critério de aceite em prosa (fora da denylist) | reprova |
| write | `limpa` | `PRD.md` | — | aprova |
| decompose | `fatia-horizontal` | `backlog.md` | fatia só-back ("montar todos os endpoints") | reprova |
| decompose | `skeleton-nao-r0` | `backlog.md` | walking skeleton fora da fatia zero (R0) | reprova |
| decompose | `limpa` | `backlog.md` | — (backlog vertical + skeleton em R0) | aprova |
| evolve | `parece-c2-mas-c3` | `mudanca.md` | decisão revertida disfarçada de RF alterado | classifica C3 |
| evolve | `limpa` | `mudanca.md` | — (RF alterado genuíno) | classifica C2 |
| ajuda | `limpa` | `pergunta.md` | — (dúvida de estágio genuína) | aprova |
| ajuda | `tarefa-disfarcada` | `pergunta.md` | pedido de execução embrulhado em dúvida | reprova |

Cada skill tem ao menos um par **defeito/`limpa`** — a suíte pega falso-negativo (não acusou o defeito)
e falso-positivo (reprovou o que estava bom).

> As fixtures do `evolve` testam a **classificação da Fase 1** (não um veredito aprova/reprova de um
> artefato): o campo `veredito` do `esperado.md` carrega a **classe esperada** (C1/C2/C3). O acerto é
> classificar na classe certa — o par `parece-c2-mas-c3`/`limpa` pega tanto o falso-negativo (não viu o
> C3 disfarçado) quanto o falso-positivo (inventou um C3 onde só havia C2).

## 5. Interpretação

A camada LLM reporta **taxa de acerto**, não verde/vermelho binário. Um erro isolado **não reprova o
harness** — dispara investigação:

- A skill mudou (regressão de comportamento)?
- O `quality-rules.md` derivou (o critério afrouxou/apertou)?
- A fixture está ambígua (o defeito não é claro, ou o `esperado.md` cobra além do razoável)?

Um `esperado.md` malformado (ex.: sem `veredito`) é **erro de suíte**, não falha da skill — conserte o
sidecar e rode de novo.

## Runner por agentes (opcional — "automatiza depois")

Na v1 isto é um **procedimento**, não uma skill nem um script. Cole o prompt abaixo no Claude Code, que
itera as pastas `scripts/fixtures/skills/`, dispara **um subagente por caso** para rodar a lente da
skill e um **agente-juiz** para comparar ao `achado_esperado`, emitindo pass/fail + taxa de acerto.

> **Prompt colável:**
>
> Rode a camada LLM da suíte de avaliação do harness. Para cada pasta
> `scripts/fixtures/skills/<skill>/<caso>/`:
> 1. Leia o `esperado.md` (frontmatter: `skill`, `fase`, `regra`, `veredito`, `achado_esperado`). Se
>    faltar `veredito`, marque **erro de suíte** e siga.
> 2. Dispare **um subagente** que invoca a skill `zion-prd-<skill>` rodando a lente da Fase 4 dela
>    sobre o artefato de entrada da pasta (`discovery.md`/`PRD.md`/`backlog.md`), e devolve o veredito
>    (reprova/aprova) + os achados, sem editar nada.
> 3. Dispare um **agente-juiz** que compara a resposta do subagente ao `veredito` e ao
>    `achado_esperado` (semântica, não literal) e devolve **acerto** ou **erro** com uma linha de
>    justificativa.
> 4. Ao final, imprima uma tabela caso→acerto/erro e a **taxa de acerto** global. Não altere fixtures
>    nem skills.

Zero superfície nova a manter além desta prosa. Se o roteiro provar valor, promove-se depois a uma
skill `/zion-prd-eval` **sem reescrever fixture nenhuma** — o contrato `esperado.md` já serve os dois
modos.
