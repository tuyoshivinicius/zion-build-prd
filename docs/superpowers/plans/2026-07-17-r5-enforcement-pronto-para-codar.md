# R5 — Exigir o executor dos gates no "pronto para codar" — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Adicionar ao guia a exigência advisória de que cada princípio *decidível* da constitution só vira gate quando um executor (CI mínimo por PR) o roda e barra o merge em regressão.

**Architecture:** Mudança **doc-only** em um único arquivo (`docs/guia-prd-para-spec-kit.md`). Três inserções: (M1) uma subseção tool-agnóstica acima do "Checklist final"; (M2) um item novo no checklist apontando para ela; (M3) uma frase no Passo 6 mencionando o executor. Nenhum script, skill, template de CI ou asset é tocado — o harness para nas pontes e não alcança o repo de implementação, então a exigência só pode viver como orientação de guia.

**Tech Stack:** Markdown. Verificação por inspeção de prosa + `./scripts/check-assets.sh` (deve seguir limpo, pois nada em `assets/` muda).

---

## Contexto para quem vai executar

- **Spec de origem:** `docs/superpowers/specs/2026-07-17-r5-enforcement-pronto-para-codar-design.md`. Leia-o antes de começar; este plano é a execução literal dele.
- **Por que não há teste automatizado:** é prosa. TDD não se aplica; o análogo do "teste" aqui é um `grep`/leitura que confirma que o texto entrou no lugar certo e que as âncoras que deviam ficar **intactas** ficaram intactas. Cada task tem esse passo de confirmação.
- **Único arquivo tocado:** `docs/guia-prd-para-spec-kit.md`. Se você se pegar editando `assets/`, uma skill, um script ou `como-usar.md`, parou no lugar errado.
- **Números de linha** citados abaixo são do estado atual do arquivo e servem de orientação; **âncore sempre pelo texto exato** mostrado em cada Edit, não pelo número (o número desloca a cada inserção).

---

## Task 1: M1 — Subseção "Do princípio decidível ao gate que trava o merge"

Insere a subseção nova logo **acima** de `## Checklist final "pronto para codar"`, como sua própria seção delimitada por `---`.

**Files:**
- Modify: `docs/guia-prd-para-spec-kit.md` (região do separador `---` que antecede o "Checklist final", ~linha 331-333)

- [ ] **Step 1: Confirmar a âncora antes de editar**

Run: `grep -n '## Checklist final "pronto para codar"' docs/guia-prd-para-spec-kit.md`
Expected: uma única linha (ex.: `333:## Checklist final "pronto para codar"`). Se aparecer mais de uma, pare e reavalie a âncora.

- [ ] **Step 2: Inserir a subseção**

Edit em `docs/guia-prd-para-spec-kit.md`.

old_string:
````text
---

## Checklist final "pronto para codar"
````

new_string:
````text
---

## Do princípio decidível ao gate que trava o merge

Cada princípio **decidível** da constitution (aquele com validador, limiar numérico ou
teste — a decidibilidade que `/zion-prd-constitution-prompt` já exige) só vira gate de
verdade quando algo o executa a cada mudança. Sem executor, "bloqueia o merge" é
aspiração. Antes da primeira branch de implementação, monte o executor mínimo:

1. **Liste os princípios decidíveis** da constitution — cada um já nasceu com critério
   objetivo.
2. **Ligue cada um a um comando de teste** que falha quando o princípio regride (o teste
   de contrato/perf/roundtrip que a própria constitution induz).
3. **Rode todos num CI a cada PR** e configure a branch para **barrar o merge** se algum
   quebrar. Um único job que roda a suíte já cumpre o mínimo.

O objetivo não é cobertura — é o *executor*: transformar cada princípio decidível num gate
que a máquina cobra, do mesmo jeito que `check-assets.yml` protege os assets deste harness.

---

## Checklist final "pronto para codar"
````

- [ ] **Step 3: Confirmar que a subseção entrou acima do checklist**

Run: `grep -n -e '## Do princípio decidível ao gate que trava o merge' -e '## Checklist final "pronto para codar"' docs/guia-prd-para-spec-kit.md`
Expected: duas linhas, com a da subseção **antes** (número menor) da linha do "Checklist final".

- [ ] **Step 4: Confirmar a referência a `check-assets.yml`**

Run: `grep -n 'check-assets.yml' docs/guia-prd-para-spec-kit.md`
Expected: pelo menos uma ocorrência (a que você acabou de inserir). O arquivo `.github/workflows/check-assets.yml` existe no repo, então a referência é válida.

---

## Task 2: M2 — Item novo no "Checklist final pronto para codar"

Adiciona um item de checklist sobre o CI mínimo, **logo após** a linha de Definition of Done (que permanece **intacta**), apontando para a subseção da Task 1.

**Files:**
- Modify: `docs/guia-prd-para-spec-kit.md` (dentro do "Checklist final", após o item de DoD, ~linha 346)

- [ ] **Step 1: Confirmar a linha de DoD (âncora que deve ficar intacta)**

Run: `grep -n 'Definition of Done acordada' docs/guia-prd-para-spec-kit.md`
Expected: uma única linha (ex.: `346:- [ ] Definition of Done acordada (testes do componente crítico, lint, deploy de preview por feature).`).

- [ ] **Step 2: Inserir o item novo depois da linha de DoD**

Edit em `docs/guia-prd-para-spec-kit.md`.

old_string:
````text
- [ ] Definition of Done acordada (testes do componente crítico, lint, deploy de preview por feature).
- [ ] Tabela de rastreabilidade `RF-xx ↔ specs/###` criada na PRD.
````

new_string:
````text
- [ ] Definition of Done acordada (testes do componente crítico, lint, deploy de preview por feature).
- [ ] **CI mínimo em cada PR** roda os testes dos princípios **decidíveis** da constitution
      e **falha o merge** em regressão — o executor que a promessa "regressão bloqueia o
      merge" pressupõe (veja *"Do princípio decidível ao gate que trava o merge"*).
- [ ] Tabela de rastreabilidade `RF-xx ↔ specs/###` criada na PRD.
````

- [ ] **Step 3: Confirmar que o item entrou e a linha de DoD segue intacta**

Run: `grep -n -e 'Definition of Done acordada' -e 'CI mínimo em cada PR' docs/guia-prd-para-spec-kit.md`
Expected: a linha de DoD **exatamente** como antes + a nova linha do "CI mínimo em cada PR" logo abaixo dela.

- [ ] **Step 4: Confirmar que o novo item referencia a subseção da Task 1**

Run: `grep -n 'Do princípio decidível ao gate que trava o merge' docs/guia-prd-para-spec-kit.md`
Expected: duas ocorrências — o título da subseção (Task 1) **e** a referência entre aspas dentro do item de checklist.

---

## Task 3: M3 — Toque mínimo no Passo 6

Uma frase no **objetivo** e uma no **critério de conclusão** do Passo 6, deixando explícito que "pronto para codar" confirma **o executor** dos gates, não só que o checklist está marcado. Sem reescrever o passo.

**Files:**
- Modify: `docs/guia-prd-para-spec-kit.md` (Passo 6, objetivo ~linha 267 e critério de conclusão ~linha 286-287)

- [ ] **Step 1: Confirmar as âncoras do Passo 6**

Run: `grep -n -e 'está pronta para implementação' -e 'o checklist final está marcado' docs/guia-prd-para-spec-kit.md`
Expected: duas linhas, ambas dentro do Passo 6 (objetivo e critério de conclusão).

- [ ] **Step 2: Ajustar o objetivo do Passo 6**

Edit em `docs/guia-prd-para-spec-kit.md`.

old_string:
````text
- **Objetivo:** manter a ponte `RF-xx ↔ specs/###-nome` **viva por máquina** e confirmar, via checklist,
  que a feature está pronta para implementação. "Viva" aqui significa *"viva enquanto você roda
````

new_string:
````text
- **Objetivo:** manter a ponte `RF-xx ↔ specs/###-nome` **viva por máquina** e confirmar, via checklist,
  que a feature está pronta para implementação — incluindo **o executor dos gates** (o CI que roda os
  testes dos princípios decidíveis e barra o merge em regressão), não só que o checklist está marcado.
  "Viva" aqui significa *"viva enquanto você roda
````

- [ ] **Step 3: Ajustar o critério de conclusão do Passo 6**

Edit em `docs/guia-prd-para-spec-kit.md`.

old_string:
````text
- **Critério de conclusão:** `/zion-prd-trace` roda limpo (ou os avisos — RF órfão / spec intraçável —
  estão justificados), todo `RF-xx` in-scope tem sua linha na tabela, e o checklist final está marcado.
````

new_string:
````text
- **Critério de conclusão:** `/zion-prd-trace` roda limpo (ou os avisos — RF órfão / spec intraçável —
  estão justificados), todo `RF-xx` in-scope tem sua linha na tabela, e o checklist final está marcado —
  inclusive o item do **CI mínimo** que executa os testes dos princípios decidíveis e falha o merge em
  regressão.
````

- [ ] **Step 4: Confirmar que o Passo 6 menciona o executor**

Run: `grep -n 'executor dos gates' docs/guia-prd-para-spec-kit.md`
Expected: uma ocorrência (o objetivo do Passo 6). Confirme também, por leitura, que a menção ao "CI mínimo" está no critério de conclusão.

---

## Task 4: Verificação final e commit

Confere a spec inteira (os três critérios de verificação) e versiona a mudança.

**Files:**
- (nenhuma edição nova) — apenas verificação e commit de `docs/guia-prd-para-spec-kit.md` e do plano/spec.

- [ ] **Step 1: Verificar os três pontos da spec**

Run: `grep -n -e '## Do princípio decidível ao gate que trava o merge' -e '## Checklist final' -e 'CI mínimo em cada PR' -e 'Definition of Done acordada' -e 'executor dos gates' docs/guia-prd-para-spec-kit.md`
Expected, confirmando por leitura:
  - (a) o título da subseção aparece **antes** do "## Checklist final";
  - (b) o item "CI mínimo em cada PR" existe e a linha "Definition of Done acordada" segue **intacta**;
  - (c) "executor dos gates" aparece no Passo 6.

- [ ] **Step 2: Confirmar que nenhum asset mudou**

Run: `./scripts/check-assets.sh`
Expected: sai limpo (exit 0, sem divergências). Nada em `assets/` foi tocado.

- [ ] **Step 3: Confirmar que só o arquivo esperado (e plano/spec) mudou**

Run: `git status --porcelain`
Expected: apenas `docs/guia-prd-para-spec-kit.md` modificado, mais os arquivos novos do plano/spec em `docs/superpowers/`. Nenhum arquivo em `assets/`, `scripts/`, skills ou `como-usar.md`.

- [ ] **Step 4: Commit**

```bash
git add docs/guia-prd-para-spec-kit.md docs/superpowers/plans/2026-07-17-r5-enforcement-pronto-para-codar.md docs/superpowers/specs/2026-07-17-r5-enforcement-pronto-para-codar-design.md
git commit -m "docs(guia): R5 — exigir o executor dos gates no \"pronto para codar\""
```

---

## Self-Review

**Spec coverage:**
- M1 (subseção acima do checklist) → Task 1. ✓
- M2 (item novo no checklist, DoD intacta) → Task 2. ✓
- M3 (Passo 6 menciona o executor) → Task 3. ✓
- Verificação (a/b/c + `check-assets.sh`) → Task 4. ✓
- Fronteira "O que R5 NÃO faz" → respeitada: nenhuma task cria script/skill/template de CI, campo "bloqueante", nem toca `quality-rules.md`/skills/`como-usar.md`.

**Placeholder scan:** todo texto a inserir está literal nas old/new strings; M3 (subespecificado na spec como "uma frase") foi fixado em wording concreto nas Tasks 3.2 e 3.3. Sem TBD/TODO.

**Type consistency:** a mesma frase de referência — *"Do princípio decidível ao gate que trava o merge"* — é usada como título (Task 1), como alvo do link no checklist (Task 2) e reconferida na Task 4. `check-assets.yml` / `./scripts/check-assets.sh` conferidos como existentes no repo.
