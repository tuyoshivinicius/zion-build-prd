# R7 — Fixtures de avaliação do harness Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Dar ao harness uma suíte de avaliação de duas camadas — um runner mecânico único (`scripts/eval.sh`) rodado no CI e seis fixtures LLM com defeito plantado + sidecar `esperado.md`, guiadas por um roteiro documentado (`docs/avaliacao-harness.md`).

**Architecture:** A camada **mecânica** (determinística, já ~90% pronta) consolida os três `test-*.sh` num runner `eval.sh` que agrega vereditos e é o único passo de avaliação no CI. A camada **LLM** (não-determinística, sob demanda) são artefatos com defeito conhecido em `scripts/fixtures/skills/<skill>/<caso>/`, cada um com um `esperado.md` legível por máquina (frontmatter) e por humano (prosa); o roteiro documenta como rodá-las à mão e por agentes. Testabilidade em ambas: **entrada com defeito conhecido → o veredito deve acusar**, com par `limpa` para pegar falso-positivo.

**Tech Stack:** Bash (runner e self-tests), Markdown (fixtures, sidecars, roteiro), GitHub Actions (CI).

---

## File Structure

Arquivos criados ou modificados por este plano:

- `scripts/eval.sh` — **criar**. Runner único da camada mecânica; roda os três `test-*.sh` na ordem `prd, adr, trace`, agrega vereditos, sai não-zero se qualquer um falhar. Aceita argumento opcional (`prd`/`adr`/`trace`) para rodar um só. É o que o CI chama.
- `scripts/test-check-prd.sh` — **modificar** (linha 2). Remover o rótulo "Semente da suíte de avaliação (R7)" do comentário de cabeçalho; a suíte agora existe.
- `.github/workflows/check-assets.yml` — **modificar**. Colapsar os três passos de auto-teste em um só: `run: ./scripts/eval.sh`. O passo `check-assets.sh` (drift) continua separado.
- `scripts/fixtures/skills/discovery/falta-nao-faz/{discovery.md, esperado.md}` — **criar**. Discovery sem "não faz" → reprova.
- `scripts/fixtures/skills/discovery/limpa/{discovery.md, esperado.md}` — **criar**. Discovery completa → aprova.
- `scripts/fixtures/skills/write/vazamento-tela-aceite/{PRD.md, esperado.md}` — **criar**. PRD que passa no `check-prd.sh` mas vaza tela/aceite em prosa → reprova.
- `scripts/fixtures/skills/write/limpa/{PRD.md, esperado.md}` — **criar**. PRD limpa → aprova.
- `scripts/fixtures/skills/decompose/fatia-horizontal/{backlog.md, esperado.md}` — **criar**. Backlog com fatia só-back → reprova.
- `scripts/fixtures/skills/decompose/skeleton-nao-r0/{backlog.md, esperado.md}` — **criar**. Walking skeleton fora da R0 → reprova.
- `scripts/fixtures/skills/decompose/limpa/{backlog.md, esperado.md}` — **criar**. Backlog vertical + skeleton em R0 → aprova.
- `docs/avaliacao-harness.md` — **criar**. Roteiro: 5 seções + índice de todas as fixtures + procedimento do runner por agentes.

**Notas de fronteira (não violar):**

- As fixtures LLM **não** são assets derivados: **não** entram em `scripts/asset-map.sh` nem no sync. São artefatos de teste próprios.
- `scripts/eval.sh` **não** é consumido por skill nenhuma → **não** entra em `asset-map.sh`.
- A camada LLM **nunca** entra no CI.

---

## Task 1: Runner mecânico `scripts/eval.sh`

**Files:**
- Create: `scripts/eval.sh`

O runner orquestra três self-tests **já testados** (`test-check-prd.sh`, `test-check-adr.sh`, `test-trace-prd.sh`), cada um com exit code próprio. A verificação aqui é de integração: rodar e observar veredito agregado + exit code + dispatch por argumento.

- [ ] **Step 1: Criar o runner**

Create `scripts/eval.sh`:

```bash
#!/usr/bin/env bash
# eval.sh — runner único da camada mecânica da suíte de avaliação (R7).
# Roda os três auto-testes (check-prd, check-adr, trace-prd) e emite veredito
# agregado. Exit 0 = todos verdes; exit 1 = qualquer um falhou; exit 2 = uso.
#
# Uso:
#   eval.sh              # roda os três, na ordem prd → adr → trace
#   eval.sh prd          # roda só um (conveniência de dev)
#   eval.sh adr
#   eval.sh trace
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

declare -A TESTS=(
  [prd]="scripts/test-check-prd.sh"
  [adr]="scripts/test-check-adr.sh"
  [trace]="scripts/test-trace-prd.sh"
)
ORDER=(prd adr trace)

sel="${1:-}"
if [ -n "$sel" ]; then
  case "$sel" in
    prd|adr|trace) ORDER=("$sel") ;;
    *) echo "uso: eval.sh [prd|adr|trace]" >&2; exit 2 ;;
  esac
fi

fail=0
for name in "${ORDER[@]}"; do
  echo "=== eval: $name ==="
  if ! bash "${TESTS[$name]}"; then fail=1; fi
done

if [ "$fail" -eq 0 ]; then
  echo "eval: tudo verde"
else
  echo "eval: FALHOU"
  exit 1
fi
```

- [ ] **Step 2: Torná-lo executável**

Run: `chmod +x scripts/eval.sh`
Expected: sem saída, exit 0. (O CI chama `./scripts/eval.sh`, então precisa do bit de execução.)

- [ ] **Step 3: Rodar o runner completo e verificar veredito agregado verde**

Run: `bash scripts/eval.sh; echo "exit=$?"`
Expected: imprime `=== eval: prd ===`, `=== eval: adr ===`, `=== eval: trace ===` nessa ordem, cada bloco terminando com `test-*: tudo verde`, e ao final `eval: tudo verde` seguido de `exit=0`.

- [ ] **Step 4: Verificar dispatch por argumento**

Run: `bash scripts/eval.sh adr; echo "exit=$?"`
Expected: imprime **só** `=== eval: adr ===` e `test-check-adr: tudo verde`, depois `eval: tudo verde` e `exit=0`. Os blocos `prd` e `trace` **não** aparecem.

- [ ] **Step 5: Verificar erro de uso**

Run: `bash scripts/eval.sh xpto; echo "exit=$?"`
Expected: `uso: eval.sh [prd|adr|trace]` no stderr e `exit=2`.

- [ ] **Step 6: Commit**

```bash
git add scripts/eval.sh
git commit -m "feat(eval): runner único da camada mecânica (R7)"
```

---

## Task 2: CI de um passo só

**Files:**
- Modify: `.github/workflows/check-assets.yml:12-17`

O CI hoje tem três passos de auto-teste. Colapsa em um `run: ./scripts/eval.sh`. O passo de drift (`check-assets.sh`) fica intacto e separado.

- [ ] **Step 1: Substituir os três passos por um**

Em `.github/workflows/check-assets.yml`, substituir este bloco:

```yaml
      - name: Auto-teste do check-prd
        run: bash scripts/test-check-prd.sh
      - name: Auto-teste do trace-prd
        run: bash scripts/test-trace-prd.sh
      - name: Auto-teste do check-adr
        run: bash scripts/test-check-adr.sh
```

por:

```yaml
      - name: Avaliação da camada mecânica
        run: ./scripts/eval.sh
```

O passo anterior (`Verifica drift de assets derivados` → `./scripts/check-assets.sh`) permanece inalterado, acima deste.

- [ ] **Step 2: Verificar o YAML resultante**

Run: `cat .github/workflows/check-assets.yml`
Expected: dois passos após o `checkout` — `Verifica drift de assets derivados` (`./scripts/check-assets.sh`) e `Avaliação da camada mecânica` (`./scripts/eval.sh`). Nenhuma menção a `test-check-prd.sh`/`test-trace-prd.sh`/`test-check-adr.sh`.

- [ ] **Step 3: Reproduzir localmente a sequência que o CI roda**

Run: `./scripts/check-assets.sh && ./scripts/eval.sh; echo "exit=$?"`
Expected: `check-assets: sem drift`, depois os três blocos de eval verdes e `eval: tudo verde`, com `exit=0`.

- [ ] **Step 4: Commit**

```bash
git add .github/workflows/check-assets.yml
git commit -m "ci(eval): colapsa os três auto-testes num passo só (R7)"
```

---

## Task 3: Remover o rótulo "semente (R7)" do `test-check-prd.sh`

**Files:**
- Modify: `scripts/test-check-prd.sh:2`

A suíte agora existe; o comentário que chamava este self-test de "semente" está obsoleto. Escopo exato do spec: **só** `test-check-prd.sh`.

- [ ] **Step 1: Editar o comentário de cabeçalho**

Em `scripts/test-check-prd.sh`, linha 2, trocar:

```bash
# Auto-teste do check-prd.sh contra fixtures. Semente da suíte de avaliação (R7).
```

por:

```bash
# Auto-teste do check-prd.sh contra fixtures. Roda pela camada mecânica (scripts/eval.sh).
```

- [ ] **Step 2: Confirmar que o self-test segue verde após a edição**

Run: `bash scripts/test-check-prd.sh; echo "exit=$?"`
Expected: `test-check-prd: tudo verde` e `exit=0`. (Editar um comentário não muda comportamento; este passo é a rede de segurança.)

- [ ] **Step 3: Commit**

```bash
git add scripts/test-check-prd.sh
git commit -m "docs(eval): tira o rótulo 'semente' do test-check-prd (R7)"
```

---

## Task 4: Fixtures LLM — discovery (`falta-nao-faz` + `limpa`)

**Files:**
- Create: `scripts/fixtures/skills/discovery/falta-nao-faz/discovery.md`
- Create: `scripts/fixtures/skills/discovery/falta-nao-faz/esperado.md`
- Create: `scripts/fixtures/skills/discovery/limpa/discovery.md`
- Create: `scripts/fixtures/skills/discovery/limpa/esperado.md`

Testa a Fase 4 do `zion-prd-discovery` contra o critério **discovery** de `quality-rules.md` `#criterios-de-conclusao` (visão em 1 frase ∧ ≥1 persona nomeada ∧ ≥1 "não faz" explícito). O caso sujo omite o "não faz"; a `limpa` tem os três.

- [ ] **Step 1: Criar a entrada suja (sem "não faz")**

Create `scripts/fixtures/skills/discovery/falta-nao-faz/discovery.md`:

```markdown
# Descoberta — Leitor de Feeds

## Visão
Para a leitora ávida, que perde notícias espalhadas em vários sites, o Leitor reúne todos os feeds numa timeline única.

## Persona
- Ana, leitora ávida — acompanha 20 sites por dia e quer um lugar só para ler.

## Quadro faz / não faz
- **Faz:** agregar feeds RSS numa timeline; marcar item como lido.
```

- [ ] **Step 2: Criar o sidecar `esperado.md` (reprova)**

Create `scripts/fixtures/skills/discovery/falta-nao-faz/esperado.md`:

```markdown
---
skill: zion-prd-discovery
fase: 4
regra: "#criterios-de-conclusao"
defeito: falta-nao-faz
veredito: reprova
achado_esperado:
  - aponta que o quadro faz/não-faz não tem nenhum "não faz" explícito
  - sugere adicionar ao menos um "não faz"
---
## Defeito plantado
O quadro faz/não-faz só lista "faz". O critério **discovery** exige pelo menos um "não faz" explícito
para travar o escopo.

## Como reconhecer o acerto
A Fase 4 do discovery emite `⚠ "não faz" faltando — sugiro <correção>` e mantém ✓ nos dois itens que
existem (visão, persona). Um falso-negativo é dar ✓ nos três itens como se a descoberta estivesse
completa.
```

- [ ] **Step 3: Criar a entrada limpa (guarda de falso-positivo)**

Create `scripts/fixtures/skills/discovery/limpa/discovery.md`:

```markdown
# Descoberta — Leitor de Feeds

## Visão
Para a leitora ávida, que perde notícias espalhadas em vários sites, o Leitor reúne todos os feeds numa timeline única.

## Persona
- Ana, leitora ávida — acompanha 20 sites por dia e quer um lugar só para ler.

## Quadro faz / não faz
- **Faz:** agregar feeds RSS numa timeline; marcar item como lido.
- **Não faz:** hospedar comentários; recomendar conteúdo por algoritmo; ler feeds pagos.
```

- [ ] **Step 4: Criar o sidecar `esperado.md` (aprova)**

Create `scripts/fixtures/skills/discovery/limpa/esperado.md`:

```markdown
---
skill: zion-prd-discovery
fase: 4
regra: "#criterios-de-conclusao"
defeito:
veredito: aprova
achado_esperado:
  - dá ✓ em visão, persona e "não faz"
  - não inventa defeito onde a descoberta está completa
---
## Defeito plantado
Nenhum — a descoberta tem visão em 1 frase, persona nomeada (Ana) e "não faz" explícito.

## Como reconhecer o acerto
A Fase 4 do discovery emite ✓ nos três itens e não sugere correção. Um falso-positivo é reprovar
uma descoberta completa (ex.: exigir mais personas ou mais "não faz").
```

- [ ] **Step 5: Verificar defeito plantado e frontmatter**

Run: `grep -ri "não faz" scripts/fixtures/skills/discovery/falta-nao-faz/discovery.md; echo "---"; grep -c "veredito:" scripts/fixtures/skills/discovery/*/esperado.md`
Expected: no `falta-nao-faz/discovery.md`, o grep casa **só** a linha do cabeçalho `## Quadro faz / não faz` (nenhum bullet "Não faz:"); e cada `esperado.md` tem exatamente 1 linha `veredito:`.

- [ ] **Step 6: Commit**

```bash
git add scripts/fixtures/skills/discovery
git commit -m "test(eval): fixtures LLM do discovery — falta-nao-faz + limpa (R7)"
```

---

## Task 5: Fixtures LLM — write (`vazamento-tela-aceite` + `limpa`)

**Files:**
- Create: `scripts/fixtures/skills/write/vazamento-tela-aceite/PRD.md`
- Create: `scripts/fixtures/skills/write/vazamento-tela-aceite/esperado.md`
- Create: `scripts/fixtures/skills/write/limpa/PRD.md`
- Create: `scripts/fixtures/skills/write/limpa/esperado.md`

Testa o **julgamento** da Fase 4 do `zion-prd-write` na zona cinzenta do F6: um vazamento de **tela/critério de aceite em prosa** que o `check-prd.sh` **não** captura (não é termo da denylist nem sinal estrutural). A PRD suja **precisa passar** no `check-prd.sh prd` (exit 0) — senão redundaria com o script em vez de exercitar o LLM.

**Restrições para a PRD suja não tropeçar no script** (verificadas no Step 3): sem termo da denylist (react, npm, postgres, typescript, …); sem `npm/pip/yarn install`; sem linha começando com `import`/`from … import`; sem bloco de código (linha ``` ```); sem versão `x.y.z`; NFRs da seção 7 todos com número; todo `RF-xx` da seção 6 sob um Épico.

- [ ] **Step 1: Criar a PRD suja (passa no script, vaza tela/aceite em prosa)**

Create `scripts/fixtures/skills/write/vazamento-tela-aceite/PRD.md`:

```markdown
# PRD — Painel de Tarefas

## 1. Visão
Para a gerente de projetos, que perde tempo consolidando status, o Painel reúne o andamento das tarefas numa tela só.

## 4. Escopo (in / out)
- **Faz (in):** ver e atualizar o status das tarefas.
- **Não faz (out):** controle de horas e faturamento.

## 6. Requisitos funcionais por épico (RF-xx)
- **Épico E1 — Acompanhamento:** RF-01 a gerente vê o status agregado do time; RF-02 a gerente filtra por responsável.

### Critério de aceite do RF-01
Dado um projeto com 500 tarefas, quando a gerente abre o Painel, então vê uma barra de progresso verde
no topo da tela com o texto "X de Y concluídas" alinhado à direita, e logo abaixo a lista de tarefas
em duas colunas: título à esquerda, responsável à direita com o avatar circular.

## 7. NFRs (com números)
- A tela carrega em até 2 segundos com 500 tarefas.
- Disponibilidade de 99,9% ao mês.
```

- [ ] **Step 2: Criar o sidecar `esperado.md` (reprova)**

Create `scripts/fixtures/skills/write/vazamento-tela-aceite/esperado.md`:

```markdown
---
skill: zion-prd-write
fase: 4
regra: "#fronteira"
defeito: vazamento-tela-aceite
veredito: reprova
achado_esperado:
  - aponta o critério de aceite detalhado (Dado/Quando/Então) como "como", não "o quê"
  - aponta o detalhe de tela/layout (barra no topo, duas colunas, avatar) vazando
  - sugere mover o detalhe para o spec.md/plan.md da feature
---
## Defeito plantado
A seção "Critério de aceite do RF-01" descreve **como** a tela é (barra de progresso no topo, texto
alinhado à direita, lista em duas colunas, avatar circular) e um critério de aceite detalhado — ambos
"como", que o `check-prd.sh` **não** pega (nenhum termo de denylist, nenhum sinal estrutural). É a zona
cinzenta do F6: julgamento puro da fronteira `#fronteira`.

## Como reconhecer o acerto
A Fase 4 do write roda o `check-prd.sh` (que sai limpo aqui) e **complementa** com o teste de vazamento
de `#fronteira`: aponta o critério de aceite e o detalhe de layout como vazamento de "como", com a
linha, e sugere movê-los para o `spec.md`/`plan.md` da feature. Um falso-negativo é confiar só no
`check-prd.sh` limpo e aprovar a PRD.
```

- [ ] **Step 3: Confirmar que a PRD suja passa no `check-prd.sh` (o defeito é só-LLM)**

Run: `bash scripts/check-prd.sh prd scripts/fixtures/skills/write/vazamento-tela-aceite/PRD.md; echo "exit=$?"`
Expected: `check-prd: limpo` e `exit=0`. Se sair `1`, algum termo/sinal tropeçou o script — reescreva a prosa do vazamento até o script sair limpo (o defeito tem de ser invisível ao script).

- [ ] **Step 4: Criar a PRD limpa (guarda de falso-positivo)**

Create `scripts/fixtures/skills/write/limpa/PRD.md`:

```markdown
# PRD — Painel de Tarefas

## 1. Visão
Para a gerente de projetos, que perde tempo consolidando status, o Painel reúne o andamento das tarefas numa tela só.

## 4. Escopo (in / out)
- **Faz (in):** ver e atualizar o status das tarefas.
- **Não faz (out):** controle de horas e faturamento.

## 6. Requisitos funcionais por épico (RF-xx)
- **Épico E1 — Acompanhamento:** RF-01 a gerente vê o status agregado do time; RF-02 a gerente filtra por responsável.
- **Épico E2 — Atualização:** RF-03 o responsável marca uma tarefa como concluída.

## 7. NFRs (com números)
- A tela carrega em até 2 segundos com 500 tarefas.
- Disponibilidade de 99,9% ao mês.
```

- [ ] **Step 5: Criar o sidecar `esperado.md` (aprova)**

Create `scripts/fixtures/skills/write/limpa/esperado.md`:

```markdown
---
skill: zion-prd-write
fase: 4
regra: "#fronteira"
defeito:
veredito: aprova
achado_esperado:
  - check-prd.sh sai limpo e a Fase 4 ecoa "limpo"
  - o teste de vazamento de #fronteira não acha "como" em prosa
---
## Defeito plantado
Nenhum — RF por épico, NFRs com número, escopo in/out, e nenhum detalhe de tela/aceite vazando.

## Como reconhecer o acerto
A Fase 4 do write roda o `check-prd.sh` (limpo, exit 0), aplica o teste de `#fronteira` e não encontra
"como" em prosa. Um falso-positivo é inventar vazamento onde a PRD está no nível de "o quê".
```

- [ ] **Step 6: Confirmar que a PRD limpa também passa no script**

Run: `bash scripts/check-prd.sh prd scripts/fixtures/skills/write/limpa/PRD.md; echo "exit=$?"`
Expected: `check-prd: limpo` e `exit=0`.

- [ ] **Step 7: Commit**

```bash
git add scripts/fixtures/skills/write
git commit -m "test(eval): fixtures LLM do write — vazamento-tela-aceite + limpa (R7)"
```

---

## Task 6: Fixtures LLM — decompose (`fatia-horizontal` + `skeleton-nao-r0` + `limpa`)

**Files:**
- Create: `scripts/fixtures/skills/decompose/fatia-horizontal/backlog.md`
- Create: `scripts/fixtures/skills/decompose/fatia-horizontal/esperado.md`
- Create: `scripts/fixtures/skills/decompose/skeleton-nao-r0/backlog.md`
- Create: `scripts/fixtures/skills/decompose/skeleton-nao-r0/esperado.md`
- Create: `scripts/fixtures/skills/decompose/limpa/backlog.md`
- Create: `scripts/fixtures/skills/decompose/limpa/esperado.md`

Testa a Fase 4 do `zion-prd-decompose` contra o critério **decompose** de `quality-rules.md`: cada fatia passa no **INVEST** (`#invest`, teste-relâmpago "dá uma demo ponta-a-ponta?") ∧ walking skeleton é a fatia zero (R0). Dois defeitos plantados (fatia horizontal; skeleton fora da R0) + uma `limpa`.

- [ ] **Step 1: Criar o backlog com fatia horizontal**

Create `scripts/fixtures/skills/decompose/fatia-horizontal/backlog.md`:

```markdown
# Backlog — Painel de Tarefas

## Épicos
- E1 — Acompanhamento
- E2 — Atualização

## Story map
- E1: a gerente vê e filtra o status do time.
- E2: o responsável atualiza suas tarefas.

## Fatias verticais (priorizadas)
- **S0 (R0) — Ver uma tarefa:** a gerente abre o Painel e vê uma tarefa com status. Walking skeleton: prova o pipeline ponta-a-ponta com o mínimo.
- **S1 (R1) — Montar todos os endpoints da API de tarefas:** implementa a criação, leitura, atualização e remoção de tarefas no backend.
- **S2 (R2) — Filtrar por responsável:** a gerente filtra a lista por responsável e vê o resultado.
```

- [ ] **Step 2: Criar o sidecar `esperado.md` (reprova)**

Create `scripts/fixtures/skills/decompose/fatia-horizontal/esperado.md`:

```markdown
---
skill: zion-prd-decompose
fase: 4
regra: "#invest"
defeito: fatia-horizontal
veredito: reprova
achado_esperado:
  - aponta S1 como horizontal (só-back, não passa no teste-relâmpago)
  - sugere refatiar por um eixo do SPIDR
---
## Defeito plantado
A fatia "S1 — Montar todos os endpoints da API de tarefas" é horizontal: entrega só backend, não passa
no teste-relâmpago "esta fatia, sozinha, dá uma demo ponta-a-ponta?".

## Como reconhecer o acerto
A Fase 4 do decompose reprova S1, nomeia-a como horizontal (só-back) e sugere refatiar pelos eixos do
SPIDR (ex.: por Path ou Rules, cada fatia com um caminho ponta-a-ponta). Um falso-negativo é deixar S1
passar no INVEST.
```

- [ ] **Step 3: Criar o backlog com skeleton fora da R0**

Create `scripts/fixtures/skills/decompose/skeleton-nao-r0/backlog.md`:

```markdown
# Backlog — Painel de Tarefas

## Épicos
- E1 — Acompanhamento
- E2 — Atualização

## Story map
- E1: a gerente vê e filtra o status do time.
- E2: o responsável atualiza suas tarefas.

## Fatias verticais (priorizadas)
- **S0 (R0) — Filtrar por responsável:** a gerente filtra a lista por responsável e vê o resultado.
- **S1 (R1) — Ver uma tarefa (walking skeleton):** a gerente abre o Painel e vê uma tarefa com status; prova o pipeline ponta-a-ponta com o mínimo.
- **S2 (R2) — Marcar como concluída:** o responsável marca uma tarefa como concluída.
```

- [ ] **Step 4: Criar o sidecar `esperado.md` (reprova)**

Create `scripts/fixtures/skills/decompose/skeleton-nao-r0/esperado.md`:

```markdown
---
skill: zion-prd-decompose
fase: 4
regra: "#invest"
defeito: skeleton-nao-r0
veredito: reprova
achado_esperado:
  - aponta que o walking skeleton (S1) não é a fatia zero (R0)
  - sugere mover o skeleton para a R0
---
## Defeito plantado
O walking skeleton está em S1 (R1), não na fatia zero. A R0 é ocupada por "Filtrar por responsável",
que não prova o pipeline inteiro. O critério **decompose** exige o walking skeleton como fatia zero (R0).

## Como reconhecer o acerto
A Fase 4 do decompose aponta que o walking skeleton não está na R0 e sugere movê-lo para a fatia zero.
Um falso-negativo é aprovar o backlog só porque um skeleton existe, sem checar que ele é a R0.
```

- [ ] **Step 5: Criar o backlog limpo (guarda de falso-positivo)**

Create `scripts/fixtures/skills/decompose/limpa/backlog.md`:

```markdown
# Backlog — Painel de Tarefas

## Épicos
- E1 — Acompanhamento
- E2 — Atualização

## Story map
- E1: a gerente vê e filtra o status do time.
- E2: o responsável atualiza suas tarefas.

## Fatias verticais (priorizadas)
- **S0 (R0) — Ver uma tarefa (walking skeleton):** a gerente abre o Painel e vê uma tarefa com status; prova o pipeline ponta-a-ponta com o mínimo.
- **S1 (R1) — Filtrar por responsável:** a gerente filtra a lista por responsável e vê o resultado.
- **S2 (R2) — Marcar como concluída:** o responsável abre uma tarefa e a marca como concluída, vendo o status mudar.
```

- [ ] **Step 6: Criar o sidecar `esperado.md` (aprova)**

Create `scripts/fixtures/skills/decompose/limpa/esperado.md`:

```markdown
---
skill: zion-prd-decompose
fase: 4
regra: "#invest"
defeito:
veredito: aprova
achado_esperado:
  - cada fatia passa no teste-relâmpago (é vertical)
  - o walking skeleton é a fatia zero (R0)
---
## Defeito plantado
Nenhum — cada fatia é vertical (dá uma demo ponta-a-ponta) e o walking skeleton é a S0 (R0).

## Como reconhecer o acerto
A Fase 4 do decompose dá veredito ✓ por item: fatias verticais e skeleton na R0. Um falso-positivo é
reprovar S1 ou S2 como horizontais quando cada uma entrega um caminho ponta-a-ponta.
```

- [ ] **Step 7: Verificar defeitos plantados e frontmatter**

Run: `grep -i "endpoints da API" scripts/fixtures/skills/decompose/fatia-horizontal/backlog.md; echo "---"; grep -i "R0.*skeleton\|skeleton.*R0" scripts/fixtures/skills/decompose/limpa/backlog.md; echo "---"; grep -c "veredito:" scripts/fixtures/skills/decompose/*/esperado.md`
Expected: `fatia-horizontal/backlog.md` casa a fatia S1 só-back; `limpa/backlog.md` casa o skeleton na R0; cada `esperado.md` tem exatamente 1 linha `veredito:`.

- [ ] **Step 8: Commit**

```bash
git add scripts/fixtures/skills/decompose
git commit -m "test(eval): fixtures LLM do decompose — horizontal + skeleton-nao-r0 + limpa (R7)"
```

---

## Task 7: O roteiro `docs/avaliacao-harness.md`

**Files:**
- Create: `docs/avaliacao-harness.md`

Documento-guia da suíte com as **5 seções** do spec + o **índice de todas as fixtures** (mecânicas + LLM) + o **procedimento do runner por agentes** (prompt colável). É índice/narrativa descobrível, **não** a fonte da verdade (a fonte é cada `esperado.md`).

- [ ] **Step 1: Criar o roteiro**

Create `docs/avaliacao-harness.md`:

```markdown
# Avaliação do harness

O harness tem uma suíte de avaliação de si mesmo, em duas camadas. Este documento é o **roteiro**:
narra as camadas, indexa todas as fixtures e diz como rodá-las. A **fonte da verdade** de cada caso LLM
é o `esperado.md` ao lado da entrada — este índice só aponta para eles.

## 1. As duas camadas e quando cada uma roda

- **Camada mecânica (determinística).** Os verificadores de script (`check-prd.sh`, `check-adr.sh`,
  `trace-prd.sh`) contra fixtures `clean`/`dirty`, consolidados em `scripts/eval.sh`. Roda **no CI a
  cada push** (passo "Avaliação da camada mecânica"). Verde/vermelho binário.
- **Camada LLM (não-determinística).** Fixtures com defeito plantado que exercitam o **julgamento** das
  skills criativas (discovery, write, decompose) — os vereditos que nenhum script decide (fatia
  horizontal, vazamento de tela/aceite, ausência de "não faz"). Roda **sob demanda**, à mão ou por
  agentes: custa token e não é reprodutível bit-a-bit, então **nunca entra no CI**.

## 2. Rodar a camada mecânica

    ./scripts/eval.sh              # roda os três self-tests → veredito agregado
    ./scripts/eval.sh prd          # roda só um (prd | adr | trace)

Exit 0 = tudo verde; exit 1 = algum self-test falhou; exit 2 = argumento inválido. É exatamente o que o
CI executa.

## 3. Rodar a camada LLM à mão

Para cada pasta em `scripts/fixtures/skills/<skill>/<caso>/`:

1. Abra o `esperado.md` e leia o frontmatter (`skill`, `fase`, `regra`, `veredito`, `achado_esperado`).
2. Invoque a **skill alvo** (`zion-prd-<skill>`) rodando a **lente da Fase 4 dela** sobre o artefato de
   entrada (`discovery.md` / `PRD.md` / `backlog.md`) da pasta.
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

Cada skill tem ao menos um par **defeito/`limpa`** — a suíte pega falso-negativo (não acusou o defeito)
e falso-positivo (reprovou o que estava bom).

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
```

- [ ] **Step 2: Verificar as 5 seções + índice + runner**

Run: `grep -nE '^## (1|2|3|4|5)\.|^## Runner|^### Mecânicas|^### LLM' docs/avaliacao-harness.md`
Expected: casa as 5 seções numeradas, as duas subtabelas (`### Mecânicas`, `### LLM`) e `## Runner por agentes`.

- [ ] **Step 3: Verificar que o índice LLM lista os 6 casos + as 7 linhas de fixture LLM**

Run: `grep -cE '^\| (discovery|write|decompose) \|' docs/avaliacao-harness.md`
Expected: `7` (discovery×2, write×2, decompose×3 — os 6 casos com defeito + `limpa`s, 7 linhas no total).

- [ ] **Step 4: Commit**

```bash
git add docs/avaliacao-harness.md
git commit -m "docs(eval): roteiro da suíte de avaliação do harness (R7)"
```

---

## Task 8: Validação final da entrega

**Files:** nenhuma alteração — validação de aceitação de ponta a ponta.

Confere os **critérios de conclusão** do spec: camada mecânica verde no CI, 6 fixtures LLM válidas com par defeito/`limpa`, roteiro completo, comentário "semente" removido, e o roteiro rodado à mão produz os vereditos esperados.

- [ ] **Step 1: Camada mecânica verde ponta a ponta (o que o CI roda)**

Run: `./scripts/check-assets.sh && ./scripts/eval.sh; echo "exit=$?"`
Expected: `check-assets: sem drift`, os três blocos de eval verdes, `eval: tudo verde`, `exit=0`.

- [ ] **Step 2: As 6 fixtures LLM (7 pastas) existem com entrada + `esperado.md` válido**

Run: `for d in scripts/fixtures/skills/*/*/; do in=$(ls "$d" | grep -vx esperado.md); v=$(grep -m1 '^veredito:' "$d/esperado.md"); echo "$d  entrada=$in  $v"; done`
Expected: 7 pastas, cada uma com uma entrada (`discovery.md`/`PRD.md`/`backlog.md`) e um `veredito:` (reprova nos 4 casos de defeito, aprova nas 3 `limpa`). Cada skill (discovery/write/decompose) tem ao menos um par defeito/`limpa`.

- [ ] **Step 3: O rótulo "semente" saiu do `test-check-prd.sh`**

Run: `grep -i "semente" scripts/test-check-prd.sh; echo "exit=$?"`
Expected: nenhuma linha e `exit=1` (grep sem match). (Nota: `test-check-adr.sh` e `test-trace-prd.sh` guardam o mesmo rótulo — fora do escopo deste spec, que cita só `test-check-prd.sh`.)

- [ ] **Step 4: O CI é um passo de avaliação só**

Run: `grep -c "test-check-prd.sh\|test-trace-prd.sh\|test-check-adr.sh" .github/workflows/check-assets.yml; echo "---"; grep "eval.sh" .github/workflows/check-assets.yml`
Expected: `0` referências aos três `test-*.sh` no workflow; uma linha `run: ./scripts/eval.sh`.

- [ ] **Step 5: Rodar o roteiro à mão sobre as 6 fixtures (validação manual única)**

Siga a seção 3 de `docs/avaliacao-harness.md` para cada uma das 7 pastas LLM: invoque a skill alvo sobre a entrada e compare ao `esperado.md`. (Pode usar o prompt colável do runner por agentes.)
Expected: cada caso de defeito produz veredito **reprova** cobrindo o `achado_esperado`; cada `limpa` produz **aprova**. Anote a taxa de acerto. Um erro isolado dispara investigação (skill mudou? quality-rules derivou? fixture ambígua?), não reprova a entrega — mas os 7 casos foram desenhados para acertar.

- [ ] **Step 6 (se necessário): commit de ajustes**

Se o Step 5 revelar fixture ambígua ou `esperado.md` cobrando demais, ajuste o sidecar/entrada e recommite:

```bash
git add scripts/fixtures/skills
git commit -m "test(eval): afina fixture LLM após validação manual (R7)"
```

---

## Self-Review

**1. Cobertura do spec** — cada item mapeado a uma task:

- `scripts/eval.sh` unificando a camada mecânica → **Task 1**.
- CI de um passo só (colapsa 3, mantém `check-assets.sh`) → **Task 2**.
- Remover comentário "semente (R7)" do `test-check-prd.sh` → **Task 3**.
- 6 fixtures LLM (discovery/write/decompose) com sidecar `esperado.md`, cada skill com par defeito/`limpa` → **Tasks 4–6** (discovery 2, write 2, decompose 3 = 7 pastas, 6 casos de defeito + limpas).
- Contrato `esperado.md` (frontmatter `skill`/`fase`/`regra`/`defeito`/`veredito`/`achado_esperado` + prosa) → aplicado em cada sidecar das Tasks 4–6.
- `write/vazamento-tela-aceite` planta defeito que o `check-prd.sh` **não** pega (verificado no Task 5, Step 3) → fronteira "zona cinzenta" do F6.
- `docs/avaliacao-harness.md` com as 5 seções + índice (mecânicas + LLM) + runner por agentes → **Task 7**.
- Bordas: `eval.sh` sem/com argumento (Task 1, Steps 3–5); par `limpa` por skill (Tasks 4–6); `esperado.md` malformado tratado como erro de suíte (roteiro §5, Task 7).
- Critérios de conclusão (CI verde de um passo; 6 fixtures válidas; roteiro com 5 seções; "semente" removido; roteiro rodado à mão) → **Task 8**.

Fora de escopo confirmado ausente do plano: skill `/zion-prd-eval`, fixtures das 3 pontes, camada LLM no CI, novas fixtures mecânicas, pin do superpowers (R9). ✓

**2. Placeholders** — sem "TBD"/"handle edge cases"/"similar to Task N"; todo arquivo tem conteúdo completo; todo passo de código mostra o código. ✓

**3. Consistência de tipos/nomes** — `eval.sh` usa `ORDER=(prd adr trace)` e `TESTS[...]` consistentes entre criação (Task 1) e uso no CI (`./scripts/eval.sh`, Task 2). Nomes de pasta LLM (`falta-nao-faz`, `vazamento-tela-aceite`, `fatia-horizontal`, `skeleton-nao-r0`, `limpa`) e slugs `defeito:` batem entre fixtures (Tasks 4–6), índice do roteiro (Task 7) e validação (Task 8). Anchors `regra:` (`#criterios-de-conclusao`, `#fronteira`, `#invest`) existem em `assets/quality-rules.md`. ✓
```