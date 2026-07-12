# Harness PRD → Spec Kit — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Construir 5 comandos-skill finos (`prd-*`) que orquestram os estágios 1–4 do guia `docs/guia-prd-para-spec-kit.md` + o construtor do prompt do `specify`, validando/formatando a entrada e a saída (aconselhando) e auto-delegando às skills reais.

**Architecture:** Comandos finos em `.claude/skills/prd-*/SKILL.md` seguem um contrato comum de 5 fases (pré-req → validar entrada → formatar → auto-delegar → validar saída, todos aconselhando, sem bloquear). As regras de qualidade e a fronteira "o-quê vs. como" vivem numa referência única `.specify/prd/quality-rules.md`; o esqueleto da PRD e a tabela de rastreabilidade viram templates em `.specify/prd/templates/`. Sem arquivo de estado — o progresso é derivado dos artefatos no disco.

**Tech Stack:** Markdown com frontmatter YAML (convenção de skill do Claude Code, igual a `.claude/skills/zion-adr-new/SKILL.md`). Nada compila; a verificação é observacional (ler o artefato + exercitar cada comando num cenário real).

**Nota sobre TDD:** estes artefatos são arquivos markdown de skill, não código executável — não há teste unitário. O análogo do "teste que falha primeiro" aqui é: **antes** de criar cada arquivo, escrever o critério de aceitação observável daquele arquivo (o que um leitor/dry-run precisa ver), confirmar que o arquivo ainda não satisfaz (não existe), criar o conteúdo, e então confirmar o critério lendo o resultado. A Task 9 roda os 6 cenários ponta-a-ponta do spec.

---

## File Structure

**Criados:**
- `.specify/prd/quality-rules.md` — fonte única: fronteira o-quê/como, critérios de conclusão por estágio, INVEST/SPIDR, anatomia do specify. (Task 1)
- `.specify/prd/templates/prd-skeleton.md` — esqueleto da PRD, 12 seções. (Task 2)
- `.specify/prd/templates/traceability-table.md` — tabela RF-xx ↔ specs/###. (Task 2)
- `.claude/skills/zion-prd-discovery/SKILL.md` — Estágio 1. (Task 3)
- `.claude/skills/zion-prd-spike/SKILL.md` — Estágio 2. (Task 4)
- `.claude/skills/zion-prd-write/SKILL.md` — Estágio 3. (Task 5)
- `.claude/skills/zion-prd-decompose/SKILL.md` — Estágio 4. (Task 6)
- `.claude/skills/zion-prd-specify-prompt/SKILL.md` — ponte para 5b. (Task 7)

**Modificados:**
- `docs/guia-prd-para-spec-kit.md` — remove os blocos embutidos "Modelo de esqueleto de PRD" e "Modelo de tabela de rastreabilidade", substituindo por links para os templates. (Task 8)

Ordem: fundações compartilhadas (Task 1–2) → comandos (Task 3–7) → migração do guia (Task 8) → verificação ponta-a-ponta (Task 9). Cada comando depende de `quality-rules.md`; `zion-prd-write` depende de `prd-skeleton.md`; `zion-prd-decompose` depende de `traceability-table.md`.

---

### Task 1: Referência de qualidade (`quality-rules.md`)

**Files:**
- Create: `.specify/prd/quality-rules.md`

- [ ] **Step 1: Escreva o critério de aceitação (o "teste")**

O arquivo deve conter quatro seções ancoráveis: `#fronteira`, `#criterios-de-conclusao`, `#invest`, `#anatomia-specify`. Cada uma legível isoladamente. Critério observável: um comando consegue citar "veja `#fronteira`" e o leitor encontra ali a lista do que pode/não pode entrar na PRD, com exemplos de frase-que-passa vs. frase-que-vaza.

- [ ] **Step 2: Verifique que ainda não existe**

Run: `test -f .specify/prd/quality-rules.md && echo EXISTE || echo AUSENTE`
Expected: `AUSENTE`

- [ ] **Step 3: Crie o arquivo com este conteúdo exato**

```markdown
# Regras de qualidade — harness PRD → Spec Kit

> Fonte única de verdade citada pelos comandos `prd-*`. Afinar o padrão de qualidade se faz **aqui**,
> num lugar só. Cada comando referencia as âncoras abaixo em vez de repetir regras.

## Fronteira o-quê/por-quê vs. como {#fronteira}

A PRD e o input do `/speckit.specify` carregam **o-quê / por-quê** (visão e escopo). O `plan.md` de
cada feature carrega **como / com quê** (stack e detalhe técnico).

**Pode entrar na PRD / no specify:**
- Visão, objetivos e métricas de negócio.
- Escopo faz/não-faz.
- Requisitos funcionais por épico (`RF-xx`), uma frase cada, descrevendo o resultado de valor.
- Regras de negócio invariáveis (`RN-xx`).
- NFRs mensuráveis (com número).
- Restrições vindas de ADRs.

**NÃO pode entrar (é do `plan.md`):**
- Linguagem, framework, bibliotecas.
- Critérios de aceite detalhados, telas/wireframes.
- Contratos de API, esquema de dados, estrutura de código.

**Teste de vazamento — frase que passa vs. frase que vaza:**

| Passa (o-quê/por-quê) | Vaza (como) |
|---|---|
| "O usuário edita o diagrama e vê a prévia atualizar ao digitar." | "Usar React + CodeMirror para renderizar a prévia." |
| "Alterações persistem entre sessões." | "Salvar o estado no localStorage via Zustand." |

Ao detectar vazamento, o comando aponta a linha ofensora e sugere movê-la para o `plan.md` da feature.

## Critérios de conclusão por estágio {#criterios-de-conclusao}

Lidos pelas Fases 0 (pré-requisito) e 4 (validar saída) dos comandos.

- **discovery** (`docs/discovery.md`): tem visão em 1 frase ∧ ≥1 persona nomeada ∧ pelo menos um
  "não faz" explícito no quadro faz/não-faz.
- **spike** (`docs/adr/ADR-00x-*.md`): cada decisão estruturante tem um ADR com Contexto/Decisão/
  Consequências ∧ o ADR referencia um spike real.
- **prd** (`docs/PRD.md`): escopo in/out explícito ∧ `RF-xx` agrupados por épico (1 frase cada) ∧
  NFRs com número ∧ **zero** stack / critério de aceite / tela.
- **decompose**: existe backlog de fatias verticais priorizadas ∧ cada fatia passa no INVEST ∧
  walking skeleton é a fatia zero (R0) ∧ a tabela de rastreabilidade está injetada na PRD com uma
  linha por `RF-xx` in-scope.
- **specify-prompt**: o prompt gerado declara resultado observável ∧ não cita stack ∧ RF-xx/ADR
  entram como contexto (referência), não como requisito.

## INVEST e SPIDR {#invest}

**INVEST** — cada fatia vertical deve ser: **I**ndependente, **N**egociável, **V**aliosa,
**E**stimável, **S**mall, **T**estável.

**Teste-relâmpago:** *"esta fatia, sozinha, permite uma demo ponta-a-ponta?"* Se a resposta é "só a
UI" ou "só o back", a fatia é **horizontal** → refatie.

**SPIDR** — eixos para quebrar uma fatia grande: **S**pike, **P**ath (caminhos alternativos),
**I**nterface, **D**ata, **R**ules. Use quando uma fatia não passa no "Small" do INVEST.

**Walking skeleton:** a fatia zero (R0) prova o pipeline inteiro com o mínimo de funcionalidade.

## Anatomia do prompt do specify {#anatomia-specify}

O input do `/speckit.specify` é literalmente um prompt. As três tags que pagam o custo:

- `<constraints>` — o **guardião da fronteira**: escreva explícito "não citar linguagem/framework/
  bibliotecas; stack só no `plan`". Impede o "como" de vazar para o `specify`.
- `<context>` — **separa referência de instrução**: `RF-xx` e ADRs entram como contexto, não viram
  requisitos acidentais.
- `<success_criteria>` — declara o **resultado observável** antes de rodar; é o que o gate
  `/speckit.clarify` vai cobrar em seguida, então já antecipa o gate.
```

- [ ] **Step 4: Verifique o critério lendo o resultado**

Run: `grep -E '\{#fronteira\}|\{#criterios-de-conclusao\}|\{#invest\}|\{#anatomia-specify\}' .specify/prd/quality-rules.md`
Expected: 4 linhas (as quatro âncoras presentes).

- [ ] **Step 5: Commit**

```bash
git add .specify/prd/quality-rules.md
git commit -m "feat(prd): referência única de regras de qualidade do harness"
```

---

### Task 2: Templates extraídos (esqueleto da PRD + tabela)

**Files:**
- Create: `.specify/prd/templates/prd-skeleton.md`
- Create: `.specify/prd/templates/traceability-table.md`

- [ ] **Step 1: Critério de aceitação**

`prd-skeleton.md` tem as 12 seções numeradas (Visão → Rastreabilidade), cada cabeçalho dizendo o que
entra e, quando relevante, o que NÃO entra. `traceability-table.md` tem a tabela de 6 colunas + a
legenda de status. Ambos são cópia fiel dos blocos hoje embutidos no guia (linhas ~280–321 e ~333–339).

- [ ] **Step 2: Verifique que ainda não existem**

Run: `ls .specify/prd/templates/ 2>/dev/null || echo AUSENTE`
Expected: `AUSENTE` (ou diretório vazio).

- [ ] **Step 3a: Crie `prd-skeleton.md` com este conteúdo exato**

```markdown
# PRD — <NOME DO PRODUTO>

> Template do Passo 3. Preencha seção a seção com `superpowers:brainstorming`, a partir de
> `docs/discovery.md` + ADRs. Se começar a escrever critérios de aceite, telas ou stack, parou no
> lugar errado → isso vive no `spec.md`/`plan.md` da feature.

## 1. Visão
Uma frase: para <persona>, que <problema>, o <produto> é um <categoria> que <benefício central>.

## 2. Objetivos & métricas
Objetivos de negócio/produto, cada um com uma métrica numérica (ex.: "reduzir X de A para B").

## 3. Personas
1–2 personas nomeadas (do discovery). Sem detalhamento de jornada — isso é do story map (P4).

## 4. Escopo (in / out)
- **Faz (in):** capacidades desta release.
- **Não faz (out):** escopo negativo explícito (costuma valer mais que o positivo).

## 5. Regras de negócio (RN-xx)
`RN-01`, `RN-02`… — restrições de domínio invariáveis. Uma frase cada.

## 6. Requisitos funcionais por épico (RF-xx)
Agrupados por épico. Uma frase por `RF-xx` — o-quê/por-quê, NUNCA como.
- **Épico E1 — <nome>:** `RF-01` …; `RF-02` …
- **Épico E2 — <nome>:** `RF-03` …

## 7. NFRs (com números)
Requisitos não-funcionais mensuráveis (performance, disponibilidade, segurança) — sempre com número.

## 8. Restrições (das ADRs)
Decisões estruturantes já fechadas nos ADRs (P2), que limitam as specs. Aponte para `docs/adr/ADR-00x`.

## 9. Glossário
Termos do domínio com definição única, para specs não divergirem.

## 10. Riscos
Riscos de produto/técnicos e mitigação prevista.

## 11. Questões abertas
`[NEEDS CLARIFICATION]` que ainda não são bloqueantes — resolvidos até o gate `/speckit.clarify` (P5b).

## 12. Rastreabilidade
Ver `.specify/prd/templates/traceability-table.md` (mantida dentro desta PRD).
```

- [ ] **Step 3b: Crie `traceability-table.md` com este conteúdo exato**

```markdown
> Tabela de rastreabilidade `RF-xx ↔ specs/###-nome`. Uma linha por requisito funcional in-scope.
> Mantida dentro da PRD (`docs/PRD.md`, seção 12).

| RF | Descrição (1 frase) | Épico | Feature / Spec | Release | Status |
|----|---------------------|-------|----------------|---------|--------|
| RF-01 | _(o quê, em uma frase)_ | E1 | `specs/001-nome` | R0 | ☐ pendente |
| RF-02 | _…_ | E1 | `specs/002-nome` | R1 | ☐ pendente |
| RF-xx | _…_ | E_n_ | `specs/###-nome` | R_n_ | ☐ pendente |

Legenda de status: ☐ pendente · ◐ em spec · ● implementada.
```

- [ ] **Step 4: Verifique**

Run: `grep -c '^## ' .specify/prd/templates/prd-skeleton.md && grep -c '☐ pendente' .specify/prd/templates/traceability-table.md`
Expected: `12` (doze seções) e depois `4` (três linhas de exemplo + a legenda).

- [ ] **Step 5: Commit**

```bash
git add .specify/prd/templates/
git commit -m "feat(prd): templates de esqueleto da PRD e tabela de rastreabilidade"
```

---

### Task 3: `/zion-prd-discovery` — Estágio 1

**Files:**
- Create: `.claude/skills/zion-prd-discovery/SKILL.md`

- [ ] **Step 1: Critério de aceitação**

Skill user-invocável que: (0) não exige pré-req; (1) valida que a semente tem problema+persona e
avisa se stack foi colada; (2/3) auto-delega a `superpowers:brainstorming` com enquadramento fixo;
(4) confere `docs/discovery.md` contra o critério `discovery` de `quality-rules.md`.

- [ ] **Step 2: Verifique que ainda não existe**

Run: `test -f .claude/skills/zion-prd-discovery/SKILL.md && echo EXISTE || echo AUSENTE`
Expected: `AUSENTE`

- [ ] **Step 3: Crie o arquivo com este conteúdo exato**

```markdown
---
name: zion-prd-discovery
description: Estágio 1 do harness — conduz a descoberta enxuta (visão, persona, faz/não-faz) e grava docs/discovery.md
argument-hint: "Ideia bruta do produto e, se houver, URLs de referência"
metadata:
  author: zion-mermaid-editor
user-invocable: true
disable-model-invocation: false
---

# zion-prd-discovery — Estágio 1 do harness (Descoberta enxuta)

Orquestra o Passo 1 do guia `docs/guia-prd-para-spec-kit.md`. Contrato de 5 fases; todos os gates
**aconselham** (apontam e sugerem), nunca bloqueiam. Regras em `.specify/prd/quality-rules.md`.

## Fase 0 — Pré-requisito
Nenhum. Este é a entrada do funil.

## Fase 1 — Validar entrada bruta (aconselha)
A semente do usuário deve conter um **problema** e uma **persona candidata**. Se faltar, pergunte
o que estiver faltando. Se o usuário já descreve **stack/framework/biblioteca**, avise: "isso é cedo
— stack é do `plan.md`; aqui é só visão e escopo" (veja `quality-rules.md` `#fronteira`). Não bloqueie.

## Fase 2/3 — Formatar e auto-delegar
Invoque `superpowers:brainstorming` no mesmo turno, com este enquadramento fixo:
"Refine a visão do produto: (1) visão em UMA frase; (2) persona principal nomeada; (3) quadro
faz/não-faz, com os 'não faz' explícitos. Grave o resultado em `docs/discovery.md`."

## Fase 4 — Validar saída (aconselha)
Ao terminar, confira `docs/discovery.md` contra o critério **discovery** de `quality-rules.md`
`#criterios-de-conclusao`: visão em 1 frase ∧ ≥1 persona nomeada ∧ pelo menos um "não faz" explícito.
Emita veredito: `✓` cada item ok, ou `⚠ <item> faltando — sugiro <correção>`. Não reverta nada.

## Saída
`docs/discovery.md` — insumo direto do `/zion-prd-spike` (Estágio 2) e do `/zion-prd-write` (Estágio 3).
```

- [ ] **Step 4: Verifique**

Run: `grep -E 'name: zion-prd-discovery|superpowers:brainstorming|#criterios-de-conclusao' .claude/skills/zion-prd-discovery/SKILL.md`
Expected: 3 linhas (frontmatter, delegação, referência às regras).

- [ ] **Step 5: Commit**

```bash
git add .claude/skills/zion-prd-discovery/SKILL.md
git commit -m "feat(prd): comando zion-prd-discovery (estágio 1)"
```

---

### Task 4: `/zion-prd-spike` — Estágio 2

**Files:**
- Create: `.claude/skills/zion-prd-spike/SKILL.md`

- [ ] **Step 1: Critério de aceitação**

Skill que: (0) exige `docs/discovery.md`; (1) filtra 2–3 decisões estruturantes; (2/3) auto-delega a
`deep-research` e depois a `zion-adr-new` por decisão; (4) confere que cada decisão virou um ADR que
referencia um spike real.

- [ ] **Step 2: Verifique que ainda não existe**

Run: `test -f .claude/skills/zion-prd-spike/SKILL.md && echo EXISTE || echo AUSENTE`
Expected: `AUSENTE`

- [ ] **Step 3: Crie o arquivo com este conteúdo exato**

```markdown
---
name: zion-prd-spike
description: Estágio 2 do harness — pesquisa trade-offs das decisões estruturantes e registra ADRs antes da PRD
argument-hint: "As 2–3 decisões estruturantes que mudam a PRD inteira"
metadata:
  author: zion-mermaid-editor
user-invocable: true
disable-model-invocation: false
---

# zion-prd-spike — Estágio 2 do harness (Spikes técnicos + ADRs)

Orquestra o Passo 2 do guia `docs/guia-prd-para-spec-kit.md`. Contrato de 5 fases; gates aconselham.
Regras em `.specify/prd/quality-rules.md`.

## Fase 0 — Pré-requisito (aconselha)
`docs/discovery.md` deve existir. Se não existir, avise: "recomendo rodar `/zion-prd-discovery` antes" e
pergunte se segue mesmo assim. Não bloqueie.

## Fase 1 — Validar entrada bruta (aconselha)
O usuário deve nomear **2–3 decisões estruturantes** — as que mudam a PRD inteira, não dúvidas
menores. Para cada candidata, aplique o filtro: "isso muda a PRD inteira?". Se surgir uma lista longa
de dúvidas pequenas, sugira consolidar nas 2–3 realmente estruturantes.

## Fase 2/3 — Formatar e auto-delegar
Para cada decisão, no mesmo turno:
1. Invoque `deep-research` para levantar os trade-offs das opções (custo de manutenção, limites).
2. Invoque `zion-adr-new` com o título da decisão para registrar o ADR em `docs/adr/`.

## Fase 4 — Validar saída (aconselha)
Confira contra o critério **spike** de `quality-rules.md` `#criterios-de-conclusao`: cada decisão tem
um `docs/adr/ADR-00x-*.md` com Contexto/Decisão/Consequências, e o ADR referencia um spike real. Se
um ADR não menciona um spike de fato rodado, avise: "sem spike, a spec nasce ambígua — sugiro rodar o
spike antes de aceitar a ADR". Não bloqueie.

## Saída
`docs/adr/ADR-00x-*.md` por decisão. Cada ADR aceito vira **restrição** na PRD (seção 8) e alimenta a
`constitution` do Spec Kit.
```

- [ ] **Step 4: Verifique**

Run: `grep -E 'name: zion-prd-spike|deep-research|zion-adr-new' .claude/skills/zion-prd-spike/SKILL.md`
Expected: 3 linhas.

- [ ] **Step 5: Commit**

```bash
git add .claude/skills/zion-prd-spike/SKILL.md
git commit -m "feat(prd): comando zion-prd-spike (estágio 2)"
```

---

### Task 5: `/zion-prd-write` — Estágio 3 (o coração)

**Files:**
- Create: `.claude/skills/zion-prd-write/SKILL.md`

- [ ] **Step 1: Critério de aceitação**

Skill que: (0) exige `docs/discovery.md` + `docs/adr/`, e detecta `docs/PRD.md` existente → modo
revisar; (2) copia `prd-skeleton.md` → `docs/PRD.md`; (3) auto-delega a `brainstorming` preenchendo
seção a seção; (4) confere fronteira (sem stack/critério de aceite/tela) e aponta a linha ofensora.

- [ ] **Step 2: Verifique que ainda não existe**

Run: `test -f .claude/skills/zion-prd-write/SKILL.md && echo EXISTE || echo AUSENTE`
Expected: `AUSENTE`

- [ ] **Step 3: Crie o arquivo com este conteúdo exato**

```markdown
---
name: zion-prd-write
description: Estágio 3 do harness — copia o esqueleto da PRD e conduz o preenchimento seção a seção, guardando a fronteira o-quê/como
argument-hint: "(sem argumento — trabalha sobre docs/discovery.md e docs/adr/)"
metadata:
  author: zion-mermaid-editor
user-invocable: true
disable-model-invocation: false
---

# zion-prd-write — Estágio 3 do harness (PRD enxuta)

Orquestra o Passo 3 do guia `docs/guia-prd-para-spec-kit.md`. Contrato de 5 fases; gates aconselham.
Regras em `.specify/prd/quality-rules.md`. Este é o coração do harness: a Fase 4 guarda a fronteira
**o-quê/por-quê vs. como**.

## Fase 0 — Pré-requisito (aconselha)
Confira `docs/discovery.md` e `docs/adr/`. Faltando → avise ("recomendo `/zion-prd-discovery` e
`/zion-prd-spike` antes") e pergunte se segue. **Idempotência:** se `docs/PRD.md` já existe, NÃO
sobrescreva — entre em **modo revisar**: leia a PRD atual e pressione seção a seção o que estiver
fraco. Não bloqueie.

## Fase 1 — Validar entrada bruta
Não há texto novo do usuário aqui — o comando trabalha sobre os artefatos existentes.

## Fase 2 — Formatar
Se `docs/PRD.md` ainda não existe, copie `.specify/prd/templates/prd-skeleton.md` → `docs/PRD.md`
(as 12 seções em branco) como ponto de partida.

## Fase 3 — Auto-delegar
Invoque `superpowers:brainstorming` no mesmo turno para preencher `docs/PRD.md` **seção a seção**, a
partir de `docs/discovery.md` + `docs/adr/`. Trabalhe uma seção por vez — visão, objetivos/métricas,
personas, escopo in/out, `RN-xx`, `RF-xx` por épico, NFRs (com número), restrições (das ADRs),
glossário, riscos, questões abertas — desafiando cada `RF-xx` e cada NFR antes de fechá-la.

## Fase 4 — Validar saída (aconselha) — GUARDA DE FRONTEIRA
Confira contra o critério **prd** de `quality-rules.md` `#criterios-de-conclusao`: escopo in/out
explícito ∧ `RF-xx` por épico (1 frase) ∧ NFRs com número ∧ **zero** stack / critério de aceite /
tela. Para o zero-stack, aplique o teste de vazamento de `#fronteira`: se alguma linha cita
linguagem/framework/biblioteca/tela/contrato de API, **aponte a linha exata** e sugira movê-la para o
`plan.md` da feature. Emita veredito por item. Não reverta — apenas aconselhe.

## Saída
`docs/PRD.md` preenchido sobre o template, com `RF-xx` por épico e sem detalhe técnico. Insumo do
`/zion-prd-decompose` (Estágio 4) e da `constitution`.
```

- [ ] **Step 4: Verifique**

Run: `grep -E 'name: zion-prd-write|prd-skeleton.md|#fronteira|modo revisar' .claude/skills/zion-prd-write/SKILL.md`
Expected: 4 linhas (frontmatter, cópia do template, guarda de fronteira, idempotência).

- [ ] **Step 5: Commit**

```bash
git add .claude/skills/zion-prd-write/SKILL.md
git commit -m "feat(prd): comando zion-prd-write (estágio 3, guarda de fronteira)"
```

---

### Task 6: `/zion-prd-decompose` — Estágio 4

**Files:**
- Create: `.claude/skills/zion-prd-decompose/SKILL.md`

- [ ] **Step 1: Critério de aceitação**

Skill que: (0) exige `docs/PRD.md` com seção RF-xx; (2/3) auto-delega a `brainstorming` para épicos →
story map → fatias; (4) valida INVEST por fatia + walking skeleton como R0 + injeta
`traceability-table.md` na seção 12 da PRD; fatia horizontal → sugere SPIDR.

- [ ] **Step 2: Verifique que ainda não existe**

Run: `test -f .claude/skills/zion-prd-decompose/SKILL.md && echo EXISTE || echo AUSENTE`
Expected: `AUSENTE`

- [ ] **Step 3: Crie o arquivo com este conteúdo exato**

```markdown
---
name: zion-prd-decompose
description: Estágio 4 do harness — transforma RF-xx em épicos, story map e fatias verticais validadas por INVEST, e injeta a tabela de rastreabilidade
argument-hint: "(sem argumento — trabalha sobre docs/PRD.md)"
metadata:
  author: zion-mermaid-editor
user-invocable: true
disable-model-invocation: false
---

# zion-prd-decompose — Estágio 4 do harness (Decomposição)

Orquestra o Passo 4 do guia `docs/guia-prd-para-spec-kit.md`. Contrato de 5 fases; gates aconselham.
Regras em `.specify/prd/quality-rules.md`.

## Fase 0 — Pré-requisito (aconselha)
`docs/PRD.md` deve existir e conter a seção de `RF-xx` por épico. Faltando → avise ("recomendo
`/zion-prd-write` antes") e pergunte se segue. Não bloqueie.

## Fase 1 — Validar entrada bruta
Não há texto novo — trabalha sobre `docs/PRD.md`.

## Fase 2/3 — Formatar e auto-delegar
Invoque `superpowers:brainstorming` no mesmo turno para: (1) agrupar os `RF-xx` em épicos;
(2) montar o story map (backbone da jornada); (3) cortar linhas de release R0..Rn; (4) fatiar cada
épico em fatias verticais.

## Fase 4 — Validar saída (aconselha)
Confira contra o critério **decompose** de `quality-rules.md` `#criterios-de-conclusao`:
- Cada fatia passa no **INVEST** (`#invest`) — aplique o teste-relâmpago "esta fatia, sozinha, dá uma
  demo ponta-a-ponta?". Se a resposta é "só a UI" ou "só o back", a fatia é **horizontal** → aponte e
  sugira refatiar pelos eixos do **SPIDR**.
- O **walking skeleton** é a fatia zero (R0).
- Injete a tabela: copie `.specify/prd/templates/traceability-table.md` para a **seção 12** de
  `docs/PRD.md` e preencha uma linha por `RF-xx` in-scope (deixe Feature/Spec e Status pendentes).
Emita veredito por item. Não reverta — aconselhe.

## Saída
Lista de épicos, story map, backlog de **fatias verticais** priorizadas com linhas de release, e a
tabela de rastreabilidade dentro da PRD. **Handoff:** a próxima fatia da fila entra em
`/zion-prd-specify-prompt`.
```

- [ ] **Step 4: Verifique**

Run: `grep -E 'name: zion-prd-decompose|#invest|traceability-table.md|walking skeleton' .claude/skills/zion-prd-decompose/SKILL.md`
Expected: 4 linhas.

- [ ] **Step 5: Commit**

```bash
git add .claude/skills/zion-prd-decompose/SKILL.md
git commit -m "feat(prd): comando zion-prd-decompose (estágio 4)"
```

---

### Task 7: `/zion-prd-specify-prompt` — Ponte para 5b

**Files:**
- Create: `.claude/skills/zion-prd-specify-prompt/SKILL.md`

- [ ] **Step 1: Critério de aceitação**

Skill que: (0) exige backlog de fatias e recebe qual fatia; (1) valida que a fatia tem resultado
observável e avisa se cita stack; (2/3) auto-delega a `zion-rewrite-prompt` montando o XML com as 3 tags;
(4) entrega o `/speckit.specify "..."` pronto como **handoff** e NÃO dispara `/speckit.*`.

- [ ] **Step 2: Verifique que ainda não existe**

Run: `test -f .claude/skills/zion-prd-specify-prompt/SKILL.md && echo EXISTE || echo AUSENTE`
Expected: `AUSENTE`

- [ ] **Step 3: Crie o arquivo com este conteúdo exato**

```markdown
---
name: zion-prd-specify-prompt
description: Ponte para o Spec Kit — monta o prompt do /speckit.specify de uma fatia vertical, blindando a fronteira sem-stack, e entrega para você disparar
argument-hint: "Qual fatia vertical do backlog transformar em prompt de specify"
metadata:
  author: zion-mermaid-editor
user-invocable: true
disable-model-invocation: false
---

# zion-prd-specify-prompt — Ponte do harness para o Spec Kit (Passo 5b)

Prepara o input do `/speckit.specify` de UMA fatia vertical. Encerra o território do harness: entrega
o prompt pronto e para — o ciclo `/speckit.*` é seu. Regras em `.specify/prd/quality-rules.md`.

## Fase 0 — Pré-requisito (aconselha)
Deve existir um backlog de fatias verticais (saída de `/zion-prd-decompose`). O usuário aponta **qual**
fatia. Se não houver backlog, avise ("recomendo `/zion-prd-decompose` antes") e pergunte se segue.

## Fase 1 — Validar entrada bruta (aconselha)
A fatia deve ter um **resultado observável** (o que o usuário consegue fazer/ver ao final). Se o
usuário descreve a fatia citando **biblioteca/framework/stack**, avise: "isso é do `plan`, não do
`specify`" (veja `quality-rules.md` `#fronteira`). Não bloqueie.

## Fase 2/3 — Formatar e auto-delegar
Invoque `zion-rewrite-prompt` no mesmo turno para montar o prompt XML do `specify`, seguindo
`quality-rules.md` `#anatomia-specify`:
- `<constraints>` — blinda "não citar linguagem/framework/bibliotecas; stack só no `plan`".
- `<context>` — `RF-xx` e ADRs relevantes como **referência**, não como requisito.
- `<success_criteria>` — o resultado observável da fatia.

## Fase 4 — Validar saída e handoff (aconselha)
Confira contra o critério **specify-prompt** de `#criterios-de-conclusao`: declara observável ∧ sem
stack ∧ RF-xx/ADR como contexto. Então **entregue o comando pronto** para o usuário disparar, por
exemplo:

    /speckit.specify "<prompt montado>"

**PARE AQUI.** Não invoque `/speckit.specify` nem qualquer `/speckit.*` — o ciclo do Spec Kit é do
usuário. Este é o fim do território do harness.

## Saída
Um `/speckit.specify "..."` pronto para colar, mais o veredito das checagens da Fase 4.
```

- [ ] **Step 4: Verifique**

Run: `grep -E 'name: zion-prd-specify-prompt|zion-rewrite-prompt|#anatomia-specify|PARE AQUI' .claude/skills/zion-prd-specify-prompt/SKILL.md`
Expected: 4 linhas (incluindo a barreira de handoff).

- [ ] **Step 5: Commit**

```bash
git add .claude/skills/zion-prd-specify-prompt/SKILL.md
git commit -m "feat(prd): comando zion-prd-specify-prompt (ponte para o Spec Kit)"
```

---

### Task 8: Migrar o guia para linkar os templates (dono único)

**Files:**
- Modify: `docs/guia-prd-para-spec-kit.md` (seções "Modelo de esqueleto de PRD" ~272–324 e "Modelo de tabela de rastreabilidade" ~328–339)

- [ ] **Step 1: Critério de aceitação**

O guia não embute mais o esqueleto da PRD nem a tabela de rastreabilidade; no lugar, aponta para
`.specify/prd/templates/`. O texto narrativo em volta (o porquê de cada bloco) permanece. Assim os
artefatos formatáveis têm dono único e não divergem.

- [ ] **Step 2: Localize os blocos a substituir**

Run: `grep -n 'Modelo de esqueleto de PRD\|Modelo de tabela de rastreabilidade' docs/guia-prd-para-spec-kit.md`
Expected: duas linhas de cabeçalho `##` (os dois blocos embutidos).

- [ ] **Step 3: Substitua o corpo do bloco "Modelo de esqueleto de PRD"**

Mantenha o cabeçalho `## Modelo de esqueleto de PRD` e o parágrafo introdutório (`> Template em branco
usado no Passo 3...`). Remova o bloco de código markdown das 12 seções e o parágrafo "Fora do
esqueleto..." e substitua por:

```markdown
O esqueleto vive agora em **`.specify/prd/templates/prd-skeleton.md`** (dono único). O comando
`/zion-prd-write` o copia para `docs/PRD.md` no Passo 3. Cada cabeçalho traz *o que entra* e *o que NÃO
entra* (a fronteira o-quê/por-quê vs. como).

**Fora do esqueleto (de propósito):** critérios de aceite, wireframes/telas, stack, contratos de API.
Tudo isso é elaboração progressiva e entra no `spec.md`/`plan.md` de cada feature (P5b).
```

- [ ] **Step 4: Substitua o corpo do bloco "Modelo de tabela de rastreabilidade"**

Mantenha o cabeçalho `## Modelo de tabela de rastreabilidade (...)`. Remova o bloco de tabela embutido
e a legenda, substituindo por:

```markdown
A tabela vive agora em **`.specify/prd/templates/traceability-table.md`** (dono único). O comando
`/zion-prd-decompose` a injeta na seção 12 da PRD no Passo 4. Preencha uma linha por requisito funcional
in-scope quando **você** executar o processo.
```

- [ ] **Step 5: Verifique que os blocos embutidos sumiram e os links entraram**

Run: `grep -c 'specify/prd/templates' docs/guia-prd-para-spec-kit.md && grep -c '# PRD — <NOME DO PRODUTO>' docs/guia-prd-para-spec-kit.md`
Expected: `2` (dois links para os templates) e `0` (o esqueleto embutido saiu).

- [ ] **Step 6: Commit**

```bash
git add docs/guia-prd-para-spec-kit.md
git commit -m "docs: guia linka os templates extraídos em vez de embuti-los"
```

---

### Task 9: Verificação ponta-a-ponta (6 cenários de aceitação)

**Files:**
- (nenhum arquivo de produto — usa artefatos temporários do Zion Mermaid Editor)

> Estes cenários exercitam os comandos e **observam** o comportamento. Rode cada um numa área de
> trabalho descartável (ex.: um branch ou os artefatos reais do Zion via `docs/index.md`). Para cada
> cenário, registre a evidência observada. Se algum falhar, é bug no `SKILL.md` correspondente — corrija
> e recomite antes de considerar o harness pronto.

- [ ] **Cenário 1 — Caminho feliz encadeado.** Rode `/zion-prd-discovery` com a semente do Zion (de
  `docs/index.md`) → confirme que `docs/discovery.md` nasce com "não faz" explícito → `/zion-prd-spike` →
  confirme ADR em `docs/adr/` → `/zion-prd-write` → confirme que copiou o esqueleto e preencheu RF-xx →
  `/zion-prd-decompose` → confirme fatias + tabela injetada na seção 12 → `/zion-prd-specify-prompt <fatia>` →
  confirme o `/speckit.specify` pronto. **Evidência:** cada artefato existe e cada Fase 4 deu `✓`.

- [ ] **Cenário 2 — Gate mole dispara e não trava.** Sem `docs/discovery.md`, rode `/zion-prd-write`.
  **Evidência:** a Fase 0 avisa "recomendo `/zion-prd-discovery` antes" e **pergunta se segue**; ao
  responder "sim", prossegue. (Prova que aconselha, não bloqueia.)

- [ ] **Cenário 3 — Detecção de fronteira vazada.** Force um RF com "usar React para..." em
  `docs/PRD.md` e rode `/zion-prd-write` em modo revisar. **Evidência:** a Fase 4 aponta a linha exata e
  sugere movê-la para o `plan.md`, citando `#fronteira`.

- [ ] **Cenário 4 — Idempotência / revisar.** Com `docs/PRD.md` já existente, rode `/zion-prd-write`.
  **Evidência:** entra em modo *pressionar seção*, não sobrescreve o arquivo do zero.

- [ ] **Cenário 5 — INVEST reprova fatia horizontal.** Dê ao `/zion-prd-decompose` uma fatia "só a UI".
  **Evidência:** aponta que falha no teste "dá demo sozinha?" e sugere SPIDR.

- [ ] **Cenário 6 — Handoff termina o território.** Rode `/zion-prd-specify-prompt`. **Evidência:**
  entrega o texto do `/speckit.specify` e **não** dispara nenhum `/speckit.*`.

- [ ] **Registro final.** Anote os 6 vereditos observados no PR/commit de fechamento. Nenhum "deve
  funcionar" — só evidência observada.

---

## Self-Review (preenchido pelo autor do plano)

**Cobertura do spec:** §3 layout → Tasks 1–7 criam exatamente os arquivos listados. §4 contrato de 5
fases → embutido em cada SKILL.md (Tasks 3–7). §5 os 5 comandos → Tasks 3–7, um a um. §6 conteúdo dos
compartilhados → Tasks 1–2; §6.4 migração do guia → Task 8. §7 verificação (6 cenários) → Task 9. §8
fora de escopo → respeitado (sem wrappers speckit, sem arquivo de estado). Sem lacunas.

**Placeholders:** nenhum "TBD/TODO"; todo conteúdo de arquivo está inline e completo.

**Consistência de nomes:** os nomes de arquivo (`quality-rules.md`, `prd-skeleton.md`,
`traceability-table.md`), as âncoras (`#fronteira`, `#criterios-de-conclusao`, `#invest`,
`#anatomia-specify`) e os nomes de skill (`zion-prd-discovery`, `zion-prd-spike`, `zion-prd-write`, `zion-prd-decompose`,
`zion-prd-specify-prompt`) batem entre as tasks que os definem (1–2) e as que os referenciam (3–9).
```
