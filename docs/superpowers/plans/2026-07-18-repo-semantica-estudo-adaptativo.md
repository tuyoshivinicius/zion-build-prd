# Separação semântica do repo + estudo workflow-adaptativo — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Tornar a skill `zion-prd-estudo` workflow-adaptativa (roteia o "Próximo passo sugerido" por persona detectada via marcador do repo-harness) e canonizar o vocabulário das três naturezas do repo, tudo refletido nas fontes da verdade no mesmo commit.

**Architecture:** Nenhum runtime novo — a mudança é prosa de `SKILL.md` + docs de governança. A skill lê um marcador (`.claude-plugin/plugin.json` com `name: zion-build-prd`) na Fase 0 e ramifica só a Fase 4; Fases 1–3 ficam intactas. A separação das três naturezas vira uma §6 nova em `docs/architecture.md`, sustentada por um ADR novo (ADR-013, decisão dada). Zero moves de pasta, zero script novo, zero asset novo, zero mudança de verificador.

**Tech Stack:** Markdown (docs + SKILL.md), Bash (guards existentes: `check-canon.sh`, `check-adr.sh`, `check-estudo.sh`, `check-prd.sh`, `check-assets.sh`, `eval.sh`). Sem código de aplicação.

## Global Constraints

Toda tarefa herda estas restrições (valores copiados verbatim do spec e do `CLAUDE.md`):

- **Commit único e atômico.** Canonização é no mesmo commit da mudança de comportamento (`CLAUDE.md`). O `check-canon.sh` roda no pre-commit e **bloqueia** commit parcial (ADR sem índice, etc.). Por isso as Tasks 1–4 **constroem e verificam sem commitar**; a Task 5 faz o único commit com todos os 4 arquivos. Não commitar no meio.
- **`assets/` é a fonte única.** **Nunca** editar `skills/*/references/` à mão — são derivados regenerados pelo pre-commit via `sync-assets.sh`. Neste plano **nenhum** asset/reference muda: só `SKILL.md` (hand-authored) é tocado dentro de `skills/`.
- **Fora de escopo (não tocar):** `assets/process-context.md` ou qualquer asset distribuído além do `SKILL.md` da estudo; mover pastas fisicamente; Fases 1–3 da skill; `check-estudo.sh` e suas fixtures.
- **Marcador do repo-harness:** projeto-alvo cujo `.claude-plugin/plugin.json` tem exatamente `name: zion-build-prd`. É a identidade única deste repo.
- **Fronteira o-quê/como:** requisito sem stack em `docs/prd.md`; stack e mecânica em `docs/architecture.md`/ADR. O texto amendado do RF-17 permanece em nível de o-quê (sem termos de stack).
- **Loose end (não resolver aqui):** `docs/estudos/discovery-ux-design.md` está untracked; versioná-lo é decisão separada do mantenedor. O `git add` da Task 5 é **escopado aos 4 arquivos**, nunca `git add -A`.
- **Escopo do commit (exatamente 4 arquivos):** `docs/adr/ADR-013-estudo-workflow-adaptativo.md` (novo), `docs/architecture.md`, `docs/prd.md`, `skills/zion-prd-estudo/SKILL.md`.

---

## File Structure

- **Create:** `docs/adr/ADR-013-estudo-workflow-adaptativo.md` — o ADR (decisão dada) que sustenta a separação semântica + o estudo adaptativo. Responsabilidade: registrar a decisão estruturante e o racional; é a evidência que a §6 e o RF-17 citam.
- **Modify:** `docs/architecture.md` — (a) linha do ADR-013 no índice §2; (b) nova §6 "As três naturezas do repo" (vocabulário + marcador). Responsabilidade: fonte da verdade do como/com-quê.
- **Modify:** `docs/prd.md` — RF-17 amendado (§6), ADR-013 citado na §8, linha C2 no changelog §13. Responsabilidade: fonte da verdade dos requisitos.
- **Modify:** `skills/zion-prd-estudo/SKILL.md` — detecção de modo na Fase 0 + ramo do "Próximo passo sugerido" na Fase 4. Responsabilidade: o comportamento distribuído da skill (hand-authored; os `references/` derivados não mudam).

Ordenação por dependência: ADR-013 primeiro (o changelog §13 e a §8 da PRD citam ADR-013 e o `check-prd.sh` cobra que todo ADR citado exista em `docs/adr/`). Depois a §6, depois a PRD, depois a SKILL.md, depois a verificação+commit.

---

### Task 1: ADR-013 + linha no índice §2 do architecture.md

Cria o ADR (decisão dada) e o registra no índice. O par arquivo-existe + arquivo-indexado é o que o `check-canon.sh` (C5) exige — é o red/green natural desta task.

**Files:**
- Create: `docs/adr/ADR-013-estudo-workflow-adaptativo.md`
- Modify: `docs/architecture.md:47` (linha do ADR-012 no índice §2)

**Interfaces:**
- Consumes: nada (primeira task).
- Produces: o arquivo `docs/adr/ADR-013-estudo-workflow-adaptativo.md` com Evidência iniciando por `Decisão dada:` (consumido pelo `check-adr.sh`); o id `ADR-013` (citado pela §6, pela §8 e pelo §13 nas tasks seguintes).

- [ ] **Step 1: Criar o arquivo do ADR**

Create `docs/adr/ADR-013-estudo-workflow-adaptativo.md` com exatamente este conteúdo:

```markdown
# ADR-013 — Skill de estudo workflow-adaptativa por marcador do repo (persona dupla)

- **Status:** Aceito
- **Data:** 2026-07-18
- **Decisores:** autoria do repo
- **Evidência:** Decisão dada: o modelo de duas personas (dev do harness × autor externo) foi decidido nesta sessão de design; não há nada a provar rodando nem pesquisando — a direção chega batida. O design que a formaliza é `docs/superpowers/specs/2026-07-18-repo-semantica-estudo-adaptativo-design.md`.

## Contexto

A skill `zion-prd-estudo` é o Estágio 0 **distribuído** do harness: o autor externo a roda no
próprio produto e o "Próximo passo sugerido" aponta `/zion-prd-discovery`. Mas o **dev do próprio
harness** também a usa internamente para estudar candidatos deste repo — onde o downstream correto
é o SDD leve (`superpowers:brainstorming → writing-plans → executing-plans`), não o discovery. Hoje
a skill hard-coda o downstream distribuído, servindo mal uma das duas personas. A dúvida
estruturante — uma skill adaptativa vs. duas skills — é uma **decisão dada** (RN-03, ADR-006): o
modelo de duas personas foi decidido no design; não há execução nem pesquisa a fazer.

## Decisão

Uma **única** skill de estudo, **workflow-adaptativa**: detecta o modo por um marcador do
repo-harness — projeto-alvo cujo `.claude-plugin/plugin.json` tem `name: zion-build-prd` → modo
**interno**; caso contrário **distribuído** (default). Só a Fase 4 ramifica o "Próximo passo
sugerido" (interno → SDD leve + ADR/canon; distribuído → discovery); as Fases 1–3 permanecem
idênticas. Estrutura **Opção A**: dois ramos gated numa única `SKILL.md`, com `description` e
`argument-hint` 100% distribuídos — o ramo interno viaja shipado mas fica **inerte** para o usuário
externo (o marcador nunca casa no produto dele). Preterido: **duas skills separadas** (duplicariam
as Fases 1–3 e divergiriam) e **flag/pergunta manual** (menos robusto, ruído para o usuário
externo).

## Consequências

A skill passa a servir as duas personas sem duplicação. A adaptação é cirúrgica (Fase 4 só) e o
resto da superfície descobrível fica intocado. O vocabulário das três naturezas do repo
(distribuído / governança / dev-workflow) é canonizado numa nova §6 do `architecture.md`, que a
skill consome pelo marcador. Nada muda na verificação: `check-estudo.sh` é agnóstico ao conteúdo do
"Próximo passo sugerido" (cobra só os 6 cabeçalhos) — nenhuma fixture nova. Limite conhecido: a
detecção é por presença de um arquivo/campo; um projeto-alvo que copiasse esse marcador ativaria o
ramo interno indevidamente (aceito — o marcador é a identidade única deste repo).

## Status

Aceito.
```

- [ ] **Step 2: Rodar o check-canon para ver o red**

Run: `./scripts/check-canon.sh`
Expected: **FAIL (exit 1)** com a linha `docs/adr/ADR-013-estudo-workflow-adaptativo.md: adr-sem-indice — não citado no índice de docs/architecture.md`. É o vermelho esperado: o ADR existe mas ainda não está no índice.

- [ ] **Step 3: Adicionar a linha do ADR-013 no índice §2**

Em `docs/architecture.md`, logo após a linha do ADR-012 (linha 47):

Old:
```
| [ADR-012](adr/ADR-012-estagio-0-estudo-pre-discovery.md) | Estágio 0 formal e opcional (`/zion-prd-estudo`): estudo pré-discovery que aconselha e não decide, verificado por `check-estudo.sh` no padrão E5. |
```

New (adiciona a linha do ADR-013 abaixo, mantendo a do ADR-012):
```
| [ADR-012](adr/ADR-012-estagio-0-estudo-pre-discovery.md) | Estágio 0 formal e opcional (`/zion-prd-estudo`): estudo pré-discovery que aconselha e não decide, verificado por `check-estudo.sh` no padrão E5. |
| [ADR-013](adr/ADR-013-estudo-workflow-adaptativo.md) | Skill de estudo (Estágio 0) roteia o "Próximo passo sugerido" por marcador do repo-harness: modo interno (SDD leve) × distribuído (discovery), numa única `SKILL.md` gated. |
```

- [ ] **Step 4: Rodar check-canon e check-adr para ver o green**

Run: `./scripts/check-canon.sh`
Expected: **PASS (exit 0)** — `check-canon: limpo`. O ADR-013 agora está indexado (C5) e a PRD dogfood (C7) segue limpa.

Run: `bash scripts/check-adr.sh docs/adr`
Expected: **PASS (exit 0)** — `check-adr: limpo`. A Evidência do ADR-013 começa por `Decisão dada:` com racional preenchido, e não há supersessão declarada (sem `Substitui:` / `Substituído por`).

---

### Task 2: Nova §6 "As três naturezas do repo" no architecture.md

Canoniza o vocabulário que a skill consome. Aponta para as tabelas existentes em vez de re-listar, para não criar uma quarta fonte da verdade.

**Files:**
- Modify: `docs/architecture.md` (anexar §6 ao fim do arquivo, após a §5)

**Interfaces:**
- Consumes: `ADR-013` (Task 1) — a §6 o cita ao descrever o marcador.
- Produces: a §6 e o nome do marcador (consumidos conceitualmente pela Task 4; sem elo mecânico).

- [ ] **Step 1: Anexar a §6 ao final do architecture.md**

Ao final de `docs/architecture.md` (após a última linha da §5), acrescente:

```markdown

## 6. As três naturezas do repo

Este repo mistura três naturezas de artefato; a separação já é **física** (só `skills/` é empacotado
pelo plugin — `docs/` e o tooling interno nunca viajam), esta seção a **nomeia e canoniza**. Ela
**aponta** para as tabelas existentes (§3 scripts, §4 assets, §12 da PRD) em vez de re-listar — para
não criar uma quarta fonte da verdade a manter.

| Natureza | O que é | Artefatos |
|---|---|---|
| **Distribuído** | Viaja ao usuário via plugin/skills.sh | `skills/zion-*`, `assets/`, `.claude-plugin/`, os `references/` derivados, e os scripts distribuídos como references da §4 (`check-prd.sh`, `check-adr.sh`, `check-estudo.sh`, `trace-prd.sh`, `trace-backlog.sh`) |
| **Governança** | Governa o próprio harness (canon) | `docs/prd.md`, `docs/architecture.md`, `docs/adr/`, `CLAUDE.md`, `scripts/check-canon.sh`, `scripts/check-assets.sh`, os guards versionados e o CI |
| **Dev-workflow** | SDD leve interno (não viaja) | `docs/superpowers/specs\|plans/`, `docs/estudos/` (deste repo), `scripts/dev-claude.sh`, `scripts/setup-hooks.sh`, `scripts/eval.sh`, os `test-*.sh` |

**Marcador do repo-harness.** O projeto-alvo cujo `.claude-plugin/plugin.json` tem
`name: zion-build-prd` é este repo — identidade única que nenhum produto de usuário possui. É o
marcador que a skill de estudo (`zion-prd-estudo`) lê na Fase 0 para decidir o modo (interno ×
distribuído) e ramificar o "Próximo passo sugerido" na Fase 4 (ADR-013). O ramo interno viaja
shipado mas fica **inerte** no produto do usuário, onde o marcador nunca casa.
```

- [ ] **Step 2: Rodar check-canon para confirmar que segue verde**

Run: `./scripts/check-canon.sh`
Expected: **PASS (exit 0)** — `check-canon: limpo`. A §6 é prosa que só cita scripts/assets já existentes (C3/C4 continuam satisfeitos por citações em qualquer lugar do doc); nenhuma nova exigência estrutural é criada.

---

### Task 3: Amendas na PRD (RF-17, §8, changelog §13)

Reflete a adaptividade no requisito, cita o ADR-013 nas restrições e registra a mudança de comportamento no changelog. O texto do RF-17 fica em nível de o-quê (sem stack).

**Files:**
- Modify: `docs/prd.md:63-65` (RF-17, §6)
- Modify: `docs/prd.md:104` (§8 restrições)
- Modify: `docs/prd.md:163` (changelog §13 — nova linha)

**Interfaces:**
- Consumes: `ADR-013` (Task 1) — citado na §8 e no §13; o `check-prd.sh` cobra que ADR citado no changelog exista em `docs/adr/`.
- Produces: nada para tasks seguintes.

- [ ] **Step 1: Rodar check-prd para registrar o baseline verde**

Run: `bash scripts/check-prd.sh prd docs/prd.md`
Expected: **PASS (exit 0)** — `check-prd: limpo`. É o baseline antes de amendar.

- [ ] **Step 2: Amendar o texto do RF-17 (§6)**

Old:
```
  `RF-17` O autor estuda um candidato antes da descoberta — edge cases, alternativas comparadas
  (sempre incluindo "não fazer") com ROI justificado e recomendação não vinculante — e recebe o
  estudo gravado para escolher a direção.
```

New:
```
  `RF-17` O autor estuda um candidato antes da descoberta — edge cases, alternativas comparadas
  (sempre incluindo "não fazer") com ROI justificado e recomendação não vinculante — e recebe o
  estudo gravado, com o próximo passo sugerido roteado conforme o contexto detectado, para escolher
  a direção.
```

- [ ] **Step 3: Citar o ADR-013 na §8 (restrições)**

Old:
```
(ADR-004) e o contrato de capacidades com o executor externo de brainstorming (ADR-007).
```

New:
```
(ADR-004), o contrato de capacidades com o executor externo de brainstorming (ADR-007) e a skill de
estudo workflow-adaptativa por persona (ADR-013).
```

- [ ] **Step 4: Adicionar a linha C2 no changelog §13**

Old:
```
| 2026-07-18 | C1 | `RF-17` novo: Estágio 0 opcional de estudo pré-discovery | governar o estudo que vivia num prompt one-shot fora do harness | ADR-012 · skills/zion-prd-estudo · scripts/check-estudo.sh |
```

New (mantém a linha C1 e adiciona a C2 abaixo):
```
| 2026-07-18 | C1 | `RF-17` novo: Estágio 0 opcional de estudo pré-discovery | governar o estudo que vivia num prompt one-shot fora do harness | ADR-012 · skills/zion-prd-estudo · scripts/check-estudo.sh |
| 2026-07-18 | C2 | `RF-17` alterado: próximo passo do estudo roteado por persona (interno × distribuído) | o dev do harness usa a mesma skill internamente, onde o downstream é SDD leve, não discovery | ADR-013 · skills/zion-prd-estudo · docs/architecture.md §6 |
```

- [ ] **Step 5: Rodar check-prd e check-canon para confirmar verde**

Run: `bash scripts/check-prd.sh prd docs/prd.md`
Expected: **PASS (exit 0)** — `check-prd: limpo`. As regras do §13 conferem: `RF-17` existe na §6; `ADR-013` existe em `docs/adr/`; a coluna Cenário usa `C2`; a §8 não aponta ADR morto (ADR-013 está `Aceito`). O RF-17 amendado não introduz termo da denylist de stack.

Run: `./scripts/check-canon.sh`
Expected: **PASS (exit 0)** — `check-canon: limpo` (C7 dogfood roda o check-prd internamente).

---

### Task 4: SKILL.md dual-mode (detecção na Fase 0 + ramo na Fase 4)

Torna a skill workflow-adaptativa: detecta o modo pelo marcador e ramifica só o "Próximo passo sugerido". O template das 6 seções fica intacto (default = distribuído), então o `check-estudo.sh` não muda de comportamento e nenhuma fixture é tocada.

**Files:**
- Modify: `skills/zion-prd-estudo/SKILL.md` (Fase 0 e Fase 4)

**Interfaces:**
- Consumes: o marcador canonizado na §6 (Task 2) e o ADR-013 (Task 1), citados na prosa.
- Produces: nada para tasks seguintes.

- [ ] **Step 1: Adicionar a detecção de modo na Fase 0**

Em `skills/zion-prd-estudo/SKILL.md`, dentro da "## Fase 0 — Entrada (aconselha)":

Old:
```
O candidato vem no argumento, em 2–6 frases: **quem sofre**, **solução imaginada**, **restrições
conhecidas**. Peça o que faltar — sem candidato completo não há o que estudar. Derive o `<slug>`
do candidato (kebab-case minúsculo, sem acentos). Se `docs/estudos/<slug>.md` **já existe**,
avise e pergunte: **retomar** (partir do documento atual e revisar) ou **sobrescrever**. Não
bloqueie.
```

New:
```
O candidato vem no argumento, em 2–6 frases: **quem sofre**, **solução imaginada**, **restrições
conhecidas**. Peça o que faltar — sem candidato completo não há o que estudar. Derive o `<slug>`
do candidato (kebab-case minúsculo, sem acentos). Se `docs/estudos/<slug>.md` **já existe**,
avise e pergunte: **retomar** (partir do documento atual e revisar) ou **sobrescrever**. Não
bloqueie.

**Detecte o modo (aconselha, não bloqueia):** se o projeto-alvo tiver
`.claude-plugin/plugin.json` com `name: zion-build-prd`, o modo é **interno** (dev do próprio
harness); caso contrário, **distribuído** (default). O modo afeta **apenas** o "Próximo passo
sugerido" da Fase 4 — as Fases 1–3 são idênticas.
```

- [ ] **Step 2: Ramificar o "Próximo passo sugerido" na Fase 4**

Ainda em `SKILL.md`, logo após o fechamento do bloco de template (a cerca ```` ``` ````) e antes do parágrafo "Rode `bash references/check-estudo.sh ...`":

Old:
```
Se aprovado, rodar `/zion-prd-discovery` com a alternativa escolhida (e `/zion-prd-spike` se
houver decisão estruturante nova).
```

Rode `bash references/check-estudo.sh docs/estudos/<slug>.md`
```

New:
```
Se aprovado, rodar `/zion-prd-discovery` com a alternativa escolhida (e `/zion-prd-spike` se
houver decisão estruturante nova).
```

**Ramo por modo (Fase 0) — a seção "## Próximo passo sugerido" gravada reflete o modo detectado:**

- **Distribuído (default):** o texto do template acima — `/zion-prd-discovery` com a alternativa
  escolhida (e `/zion-prd-spike` se houver decisão estruturante nova).
- **Interno:** substitua o corpo da seção por: "Se aprovado, rodar `superpowers:brainstorming` com a
  alternativa escolhida → `superpowers:writing-plans` → `superpowers:executing-plans`. Decisão
  estruturante nova vira ADR via `/zion-adr-new` e reflete no canon (`prd.md`/`architecture.md` no
  mesmo commit — CLAUDE.md)."

Os 6 cabeçalhos e o resto do documento não mudam com o modo — só o corpo desta seção.

Rode `bash references/check-estudo.sh docs/estudos/<slug>.md`
```

> Nota para o executor: o `old_string`/`new_string` acima inclui a linha "Rode `bash references/check-estudo.sh docs/estudos/<slug>.md`" apenas como âncora de posição — ela permanece idêntica; o que se insere é o bloco "**Ramo por modo…**" entre o fim do template e essa linha.

- [ ] **Step 3: Verificar que os 6 cabeçalhos do template seguem intactos**

Run: `grep -c '^## \(Contexto\|Edge cases e incertezas\|Alternativas\|ROI\|Recomendação\|Próximo passo sugerido\)$' skills/zion-prd-estudo/SKILL.md`
Expected: `6` — o template ainda declara exatamente as 6 seções que o `check-estudo.sh` cobra (a edição não mexeu nos cabeçalhos, só no corpo do "Próximo passo sugerido" e na prosa ao redor).

- [ ] **Step 4: Confirmar que o `references/` derivado não foi tocado à mão**

Run: `git status --porcelain skills/zion-prd-estudo/references/`
Expected: **saída vazia** — nenhum arquivo em `references/` mudou (só `SKILL.md`, que é hand-authored). Se algo aparecer aqui, reverta: `references/` só se regenera via `sync-assets.sh`.

- [ ] **Step 5: Rodar a suíte mecânica completa**

Run: `./scripts/eval.sh`
Expected: **PASS (exit 0)** — todos os `test-*.sh` verdes, incluindo `test-check-estudo.sh` (fixtures inalteradas). Confirma que o comportamento do verificador do estudo não mudou.

---

### Task 5: Verificação final + commit único de canonização

Roda todos os guards no working tree e faz o único commit atômico com os 4 arquivos.

**Files:**
- Nenhuma edição nova; apenas verificação e commit.

**Interfaces:**
- Consumes: todo o trabalho das Tasks 1–4.
- Produces: o commit de canonização.

- [ ] **Step 1: Rodar todos os guards de integridade**

Run:
```bash
./scripts/check-assets.sh && \
./scripts/check-canon.sh && \
bash scripts/check-adr.sh docs/adr && \
bash scripts/check-prd.sh prd docs/prd.md && \
./scripts/eval.sh
```
Expected: **todos PASS (exit 0)** — `check-assets: limpo` (sem drift, nenhum reference tocado), `check-canon: limpo`, `check-adr: limpo`, `check-prd: limpo`, e `eval.sh` verde.

- [ ] **Step 2: Conferir o escopo do stage (exatamente 4 arquivos, sem o untracked)**

Run: `git status --porcelain`
Expected: os 4 arquivos do escopo aparecem (`?? docs/adr/ADR-013-estudo-workflow-adaptativo.md`, ` M docs/architecture.md`, ` M docs/prd.md`, ` M skills/zion-prd-estudo/SKILL.md`) e `?? docs/estudos/` continua untracked (não entra no commit). Não usar `git add -A`.

- [ ] **Step 3: Stage escopado dos 4 arquivos**

Run:
```bash
git add docs/adr/ADR-013-estudo-workflow-adaptativo.md docs/architecture.md docs/prd.md skills/zion-prd-estudo/SKILL.md
```

- [ ] **Step 4: Commit único de canonização**

O pre-commit hook (`check-assets` + `check-canon` + `check-adr`) roda e deve passar; se bloquear, corrija antes de reforçar o commit.

Run:
```bash
git commit -m "$(cat <<'EOF'
feat(estudo): skill de estudo workflow-adaptativa por marcador do repo

Roteia o "Próximo passo sugerido" da zion-prd-estudo por persona detectada
(interno: SDD leve · distribuído: discovery), ramificando só a Fase 4. Canoniza
as três naturezas do repo em architecture.md §6, com ADR-013 (decisão dada) e
as amendas de RF-17/§8/§13 na PRD no mesmo commit.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
EOF
)"
```
Expected: commit criado, pre-commit verde.

- [ ] **Step 5: Confirmar o resultado do commit**

Run: `git show --stat HEAD`
Expected: o commit lista exatamente os 4 arquivos (1 novo, 3 modificados). `docs/estudos/` **não** aparece.

---

## Self-Review

**1. Spec coverage:**
- Spec §1 (três naturezas, nova §6 + marcador) → Task 2. ✔
- Spec §1 (linha do ADR-013 no índice §2) → Task 1, Step 3. ✔
- Spec §2 (Fase 0 detecção) → Task 4, Step 1. ✔
- Spec §2 (Fase 4 ramifica; template default distribuído; superfície descobrível intocada) → Task 4, Step 2 (front-matter `description`/`argument-hint` não é tocado). ✔
- Spec §3 (ADR-013 decisão dada, evidência aponta o design, supersede nada, índice §2) → Task 1. ✔
- Spec §3 (RF-17 amendado; artefato §12 permanece) → Task 3, Step 2 (a §12 não é editada). ✔
- Spec §3 (§13 changelog; §8 cita ADR-013) → Task 3, Steps 3–4. ✔
- Spec §4 (check-estudo não muda, sem fixture nova; check-canon verde; check-adr verde) → Tasks 4–5. ✔
- Spec "Fora de escopo" (sem move, sem tocar process-context/assets, sem adaptar Fases 1–3) → Global Constraints + Task 4, Step 4. ✔
- Spec "Loose end" (discovery-ux-design.md untracked, decisão do mantenedor) → Global Constraints + Task 5, Steps 2/5. ✔

**2. Placeholder scan:** Nenhum TBD/TODO/"handle edge cases". Todo conteúdo de edição está literal (ADR completo, texto exato das amendas, blocos old/new).

**3. Type consistency:** Nome do arquivo `docs/adr/ADR-013-estudo-workflow-adaptativo.md` idêntico no ADR (Task 1), no índice §2 (Task 1 Step 3), no changelog §13 (Task 3 Step 4) e no `git add` (Task 5). O marcador `name: zion-build-prd` idêntico em ADR-013, §6 e Fase 0. A string do modo (**interno** × **distribuído**) consistente entre §6, RF-17 (via "contexto detectado") e Fase 0/Fase 4. Cenário `C2` bate com a definição de "RF alterado" em `quality-rules.md#dia-2`.
