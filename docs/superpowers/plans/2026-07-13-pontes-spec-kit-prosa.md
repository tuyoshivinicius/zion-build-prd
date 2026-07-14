# Pontes Spec Kit em prosa (remoção do `zion-rewrite-prompt`) — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fazer as três pontes (`constitution`/`specify`/`plan`) montarem, cada uma no seu escopo, um prompt em **linguagem natural (prosa)** para o `/speckit.*` correspondente — sem impor formato de saída e sem delegar — e remover a skill `zion-rewrite-prompt`, atualizando assets e guias vivos.

**Architecture:** Fonte única = `assets/quality-rules.md` (sincronizado para 7 skills por `scripts/sync-assets.sh`). Reescrevem-se as âncoras `#anatomia-*` (conteúdo em prosa, sem XML) e a Fase 2/3 de cada ponte (montar você mesmo, sem `zion-rewrite-prompt`). A skill `zion-rewrite-prompt` é removida via `git rm`; os guias vivos (README, como-usar, guia) perdem toda referência a ela. Os `docs/superpowers/specs|plans` datados ficam intactos (registro histórico).

**Tech Stack:** Markdown; bash (`scripts/sync-assets.sh`, `scripts/check-assets.sh`); git. Sem código de aplicação. As "verificações" são `grep`/scripts, não testes unitários.

**Spec:** `docs/superpowers/specs/2026-07-13-pontes-spec-kit-prosa-design.md`

---

## Mapa de arquivos

| Arquivo | Responsabilidade | Ação |
|---|---|---|
| `assets/quality-rules.md` | Fonte única das regras; âncoras `#anatomia-*` | Reescrever as 3 âncoras + 1 critério; depois `sync` |
| `skills/zion-prd-constitution-prompt/SKILL.md` | Ponte 5a | Reescrever Fase 2/3 |
| `skills/zion-prd-specify-prompt/SKILL.md` | Ponte 5b | Reescrever Fase 2/3 |
| `skills/zion-prd-plan-prompt/SKILL.md` | Ponte 5c | Reescrever Fase 2/3 |
| `skills/zion-rewrite-prompt/` | (a remover) | `git rm -r` |
| `README.md` | Tabela de dependências | Remover a linha `zion-rewrite-prompt` |
| `docs/como-usar.md` | Guia prático | Coluna "Delega" + 3 seções de ponte |
| `docs/guia-prd-para-spec-kit.md` | Guia de processo | P5b + linha da tabela de skills |
| `skills/*/references/quality-rules.md` (×7) | Cópias derivadas | Regeneradas por `sync-assets.sh` (não editar à mão) |

**Não tocar:** `scripts/asset-map.sh` (rewrite-prompt não está no mapa), `.claude-plugin/*` (auto-descobre skills), `docs/superpowers/specs|plans` datados (histórico).

---

## Task 1: Reescrever as âncoras `#anatomia-*` e o critério do plan em `quality-rules.md`

**Files:**
- Modify: `assets/quality-rules.md`

- [ ] **Step 1: Substituir o critério de conclusão do `plan-prompt` (remover termo com cara de tag XML)**

Edit em `assets/quality-rules.md`. Localize (dentro de `{#criterios-de-conclusao}`):

```
- **plan-prompt**: o prompt gerado referencia o `spec.md` da feature ∧ injeta os ADRs confirmados
  como restrição (honrar, não re-decidir) ∧ `success_criteria` = plano honra cada ADR ∧ cobre o
  resultado observável do `spec.md`.
```

Substitua por:

```
- **plan-prompt**: o prompt gerado referencia o `spec.md` da feature ∧ injeta os ADRs confirmados
  como restrição (honrar, não re-decidir) ∧ deixa claro que o plano deve honrar cada ADR e cobrir
  o resultado observável do `spec.md`.
```

- [ ] **Step 2: Reescrever as três âncoras `#anatomia-*` (conteúdo em prosa, sem XML)**

Edit em `assets/quality-rules.md`. Substitua **todo o bloco** que começa em `## Anatomia do prompt do specify {#anatomia-specify}` e vai até o fim do arquivo (as três seções `#anatomia-specify`, `#anatomia-constitution`, `#anatomia-plan`) por:

````markdown
## Anatomia do prompt do specify {#anatomia-specify}

O input do `/speckit.specify` é um prompt em **linguagem natural (prosa)**. O comando já tem o
próprio template e só preenche placeholders — então o prompt é **conteúdo, não formato**: nada de
tags XML, nada de ditar cabeçalhos/seções do `spec.md`. Em prosa, o prompt deve cobrir:

- **O resultado observável** — o que o usuário consegue fazer/ver ao final da fatia (o o-quê/por-quê).
  É o que o gate `/speckit.clarify` vai cobrar em seguida, então já o declara.
- **A guarda da fronteira, em prosa** — escreva explícito "não citar linguagem, framework ou
  bibliotecas; a stack fica no `plan`". Impede o "como" de vazar para o `specify`.
- **`RF-xx` e ADRs como contexto** — cite-os como referência ("Contexto: RF-01…"), não como
  requisitos a copiar.

## Anatomia do prompt do constitution {#anatomia-constitution}

O input do `/speckit.constitution` é um prompt em **linguagem natural (prosa)**, montado a partir da
PRD. O comando já preenche o próprio template — então é **conteúdo, não formato**: nada de tags XML,
nada de ditar as seções ou o versionamento do artefato. Em prosa, o prompt deve cobrir:

- **A fonte, não o princípio pronto** — os NFRs (`NFR-xx`) e as restrições de ADRs como material de
  origem para derivar os princípios.
- **O pedido de derivação** — peça para **derivar** princípios decidíveis dessa fonte (um por
  NFR/restrição relevante).
- **A guarda da decidibilidade, em prosa** — escreva explícito "cada princípio tem um critério
  objetivo (validador / limiar numérico / teste) e rastreia a um NFR ou ADR; nada de genérico
  ('código limpo', 'boa cobertura')". Impede platitude de virar princípio.

## Anatomia do prompt do plan {#anatomia-plan}

O input do `/speckit.plan` é um prompt em **linguagem natural (prosa)** — montado a partir do
`spec.md` da feature (que o comando já carrega como fonte da verdade) e dos ADRs que o spike já
provou. É a única ponte que **entra** no "como", presa ao que foi decidido. O comando já tem o
próprio template — então é **conteúdo, não formato**: nada de tags XML, nada de ditar as seções do
`plan.md`, e **não repita os requisitos** (o `spec.md` já é carregado). Em prosa, o prompt deve
cobrir:

- **As decisões fechadas a honrar** — os **ADRs confirmados** (`ADR-00x: <decisão>`) como restrições:
  "honre cada ADR listado; não re-decida o que um ADR já fixou".
- **O pedido do plano técnico** — peça para descrever a stack, a arquitetura e as restrições técnicas
  que realizam o resultado observável do `spec.md` **dentro** dessas decisões.
- **A guarda secundária, em prosa** — "não expanda além do escopo do `spec.md`". É o que impede o
  spike de virar esforço órfão; o gate `/speckit.analyze` cobra isso depois.
````

- [ ] **Step 3: Verificar que não sobrou tag XML nas âncoras**

Run: `grep -nE '<context>|<constraints>|<instructions>|<success_criteria>' assets/quality-rules.md || echo "OK: sem tags XML"`
Expected: `OK: sem tags XML`

- [ ] **Step 4: Regenerar os `references/` e checar drift**

Run: `./scripts/sync-assets.sh && ./scripts/check-assets.sh`
Expected: `sync-assets: ok` seguido de `check-assets: sem drift`

- [ ] **Step 5: Commit**

```bash
git add assets/quality-rules.md skills/*/references/quality-rules.md
git commit -m "refactor(quality-rules): anatomia dos prompts em prosa, sem XML

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 2: Reescrever a Fase 2/3 da ponte `constitution`

**Files:**
- Modify: `skills/zion-prd-constitution-prompt/SKILL.md`

- [ ] **Step 1: Substituir a Fase 2/3**

Edit em `skills/zion-prd-constitution-prompt/SKILL.md`. Substitua o bloco:

```
## Fase 2/3 — Formatar e auto-delegar
Invoque `zion-rewrite-prompt` no mesmo turno para montar o prompt do `constitution`, seguindo
`quality-rules.md` `#anatomia-constitution`:
- `<context>` — os NFRs (`NFR-xx`) e restrições de ADRs como **fonte** (material de origem), não
  como princípio já pronto.
- `<instructions>` — **derivar** princípios decidíveis dessa fonte.
- `<constraints>` — blinda a decidibilidade: cada princípio tem validador/limiar/teste e rastreia a
  um NFR/ADR; proíbe genérico.
- `<success_criteria>` — todo princípio é decidível ∧ rastreável; nenhum genérico.
```

Por:

```
## Fase 2/3 — Montar o prompt (você mesmo)
Monte, no mesmo turno, o prompt do `constitution` em **linguagem natural (prosa)**, seguindo
`references/quality-rules.md` `#anatomia-constitution`. É **conteúdo, não formato**: não use tags XML
nem dite as seções do artefato — o `/speckit.constitution` já tem o próprio template. Em prosa, o
prompt deve:
- Trazer os NFRs (`NFR-xx`) e restrições de ADRs como **fonte** (material de origem), não como
  princípio já pronto.
- Pedir para **derivar** princípios decidíveis dessa fonte (um por NFR/restrição relevante).
- Blindar a decidibilidade em prosa: cada princípio tem um critério objetivo (validador / limiar
  numérico / teste) e rastreia a um NFR/ADR; nada de genérico ('código limpo', 'boa cobertura').
```

- [ ] **Step 2: Verificar**

Run: `grep -n "zion-rewrite-prompt" skills/zion-prd-constitution-prompt/SKILL.md || echo "OK: sem delegação"; grep -c "PARE AQUI" skills/zion-prd-constitution-prompt/SKILL.md`
Expected: `OK: sem delegação` seguido de `1`

- [ ] **Step 3: Commit**

```bash
git add skills/zion-prd-constitution-prompt/SKILL.md
git commit -m "refactor(constitution-prompt): montar prompt em prosa, sem zion-rewrite-prompt

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 3: Reescrever a Fase 2/3 da ponte `specify`

**Files:**
- Modify: `skills/zion-prd-specify-prompt/SKILL.md`

- [ ] **Step 1: Substituir a Fase 2/3**

Edit em `skills/zion-prd-specify-prompt/SKILL.md`. Substitua o bloco:

```
## Fase 2/3 — Formatar e auto-delegar
Invoque `zion-rewrite-prompt` no mesmo turno para montar o prompt XML do `specify`, seguindo
`quality-rules.md` `#anatomia-specify`:
- `<constraints>` — blinda "não citar linguagem/framework/bibliotecas; stack só no `plan`".
- `<context>` — `RF-xx` e ADRs relevantes como **referência**, não como requisito.
- `<success_criteria>` — o resultado observável da fatia.
```

Por:

```
## Fase 2/3 — Montar o prompt (você mesmo)
Monte, no mesmo turno, o prompt do `specify` em **linguagem natural (prosa)**, seguindo
`references/quality-rules.md` `#anatomia-specify`. É **conteúdo, não formato**: não use tags XML nem
dite as seções do artefato — o `/speckit.specify` já tem o próprio template. Em prosa, o prompt deve:
- Declarar o **resultado observável** da fatia (o que o usuário faz/vê ao final).
- Blindar a fronteira em prosa: "não citar linguagem, framework ou bibliotecas; a stack fica no
  `plan`".
- Citar `RF-xx` e ADRs relevantes como **referência** (contexto), não como requisito.
```

- [ ] **Step 2: Verificar**

Run: `grep -n "zion-rewrite-prompt" skills/zion-prd-specify-prompt/SKILL.md || echo "OK: sem delegação"; grep -c "PARE AQUI" skills/zion-prd-specify-prompt/SKILL.md`
Expected: `OK: sem delegação` seguido de `1`

- [ ] **Step 3: Commit**

```bash
git add skills/zion-prd-specify-prompt/SKILL.md
git commit -m "refactor(specify-prompt): montar prompt em prosa, sem zion-rewrite-prompt

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 4: Reescrever a Fase 2/3 da ponte `plan`

**Files:**
- Modify: `skills/zion-prd-plan-prompt/SKILL.md`

- [ ] **Step 1: Substituir a Fase 2/3**

Edit em `skills/zion-prd-plan-prompt/SKILL.md`. Substitua o bloco (da linha `## Fase 2/3 — Formatar e auto-delegar` até a linha `Não invoque \`deep-research\` — a pesquisa já aconteceu no spike; o ADR é a decisão fechada.` inclusive):

```
## Fase 2/3 — Formatar e auto-delegar
Invoque `zion-rewrite-prompt` no mesmo turno para montar o prompt XML do `plan`, seguindo
`references/quality-rules.md` `#anatomia-plan`:
- `<context>` — o `spec.md` da fatia e os **ADRs confirmados** (`ADR-00x: <decisão>`) como fonte.
- `<instructions>` — **derivar** o plano técnico que realiza o `spec.md` dentro das decisões dos ADRs.
- `<constraints>` — o guardião **invertido**: "honre cada ADR listado; não re-decida o que um ADR já
  fixou". Secundário: "não expanda além do escopo do `spec.md`".
- `<success_criteria>` — o plano honra cada ADR confirmado ∧ cobre o resultado observável do `spec.md`.

Não invoque `deep-research` — a pesquisa já aconteceu no spike; o ADR é a decisão fechada.
```

Por:

```
## Fase 2/3 — Montar o prompt (você mesmo)
Monte, no mesmo turno, o prompt do `plan` em **linguagem natural (prosa)**, seguindo
`references/quality-rules.md` `#anatomia-plan`. É **conteúdo, não formato**: não use tags XML nem
dite as seções do artefato — o `/speckit.plan` já tem o próprio template e já carrega o `spec.md`
como fonte (não repita os requisitos). Em prosa, o prompt deve:
- Listar os **ADRs confirmados** (`ADR-00x: <decisão>`) como decisões fechadas a honrar: "honre cada
  ADR listado; não re-decida o que um ADR já fixou".
- Pedir o plano técnico (stack, arquitetura, restrições) que realiza o resultado observável do
  `spec.md` **dentro** dessas decisões.
- Blindar o escopo em prosa: "não expanda além do escopo do `spec.md`".

Não invoque `deep-research` — a pesquisa já aconteceu no spike; o ADR é a decisão fechada.
```

- [ ] **Step 2: Verificar**

Run: `grep -n "zion-rewrite-prompt" skills/zion-prd-plan-prompt/SKILL.md || echo "OK: sem delegação"; grep -c "PARE AQUI" skills/zion-prd-plan-prompt/SKILL.md`
Expected: `OK: sem delegação` seguido de `1`

- [ ] **Step 3: Commit**

```bash
git add skills/zion-prd-plan-prompt/SKILL.md
git commit -m "refactor(plan-prompt): montar prompt em prosa, sem zion-rewrite-prompt

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 5: Remover a skill `zion-rewrite-prompt`

**Files:**
- Delete: `skills/zion-rewrite-prompt/` (diretório inteiro)

- [ ] **Step 1: Remover via git**

Run: `git rm -r skills/zion-rewrite-prompt`
Expected: `rm 'skills/zion-rewrite-prompt/SKILL.md'`

- [ ] **Step 2: Verificar contagem de skills e mapa de assets intactos**

Run: `find skills -maxdepth 1 -mindepth 1 -type d | wc -l; grep -c "zion-rewrite-prompt" scripts/asset-map.sh || echo "OK: fora do mapa"; ./scripts/check-assets.sh`
Expected: `8`, depois `OK: fora do mapa`, depois `check-assets: sem drift`

- [ ] **Step 3: Commit**

```bash
git commit -m "chore(skill): remover zion-rewrite-prompt (pontes autocontidas)

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 6: Atualizar `README.md` (tabela de dependências)

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Remover a linha da dependência**

Edit em `README.md`. Remova esta linha inteira da tabela de Dependências:

```
| `zion-rewrite-prompt` | `/zion-prd-constitution-prompt`, `/zion-prd-specify-prompt`, `/zion-prd-plan-prompt` | Incluída (skill first-party deste repo) |
```

(A afirmação seguinte, "A **única dependência externa** é o `superpowers`.", continua verdadeira — não mexer.)

- [ ] **Step 2: Verificar**

Run: `grep -n "rewrite-prompt" README.md || echo "OK: README limpo"`
Expected: `OK: README limpo`

- [ ] **Step 3: Commit**

```bash
git add README.md
git commit -m "docs(readme): remover zion-rewrite-prompt da tabela de dependências

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 7: Atualizar `docs/como-usar.md`

**Files:**
- Modify: `docs/como-usar.md`

- [ ] **Step 1: Coluna "Delega a" das três pontes**

Edit em `docs/como-usar.md`. Substitua as três linhas do "Mapa rápido dos comandos":

```
| `/zion-prd-constitution-prompt` | Ponte p/ 5a (bootstrap, 1×) | `docs/PRD.md` (NFRs+ADRs) | prompt do `/speckit.constitution` | `zion-rewrite-prompt` |
| `/zion-prd-specify-prompt` | Ponte p/ 5b | backlog de fatias | prompt do `/speckit.specify` | `zion-rewrite-prompt` |
| `/zion-prd-plan-prompt` | Ponte p/ 5c | `spec.md` da feature + `docs/adr/` | prompt do `/speckit.plan` | `zion-rewrite-prompt` |
```

Por:

```
| `/zion-prd-constitution-prompt` | Ponte p/ 5a (bootstrap, 1×) | `docs/PRD.md` (NFRs+ADRs) | prompt do `/speckit.constitution` | *(monta em prosa; sem delegação)* |
| `/zion-prd-specify-prompt` | Ponte p/ 5b | backlog de fatias | prompt do `/speckit.specify` | *(monta em prosa; sem delegação)* |
| `/zion-prd-plan-prompt` | Ponte p/ 5c | `spec.md` da feature + `docs/adr/` | prompt do `/speckit.plan` | *(monta em prosa; sem delegação)* |
```

- [ ] **Step 2: Seção da ponte `constitution` (exemplo XML → prosa)**

Edit em `docs/como-usar.md`. Substitua o bloco:

````
Delega a `zion-rewrite-prompt` montando as tags de `#anatomia-constitution` e **entrega o comando pronto**
(não dispara nada):

```text
/speckit.constitution "
<context>
Fonte (NFRs e restrições, não princípios prontos): NFR-01 (render < 100ms ao digitar),
NFR-02 (persistência sobrevive a reload). ADR-001 (motor de render), ADR-003 (persistência local).
</context>
<instructions>
Derive um princípio decidível por NFR/restrição relevante.
</instructions>
<constraints>
Cada princípio tem critério objetivo (validador / limiar numérico / teste) e rastreia a um NFR/ADR.
Proibido genérico ('código limpo', 'boa cobertura').
</constraints>
<success_criteria>
Todo princípio é decidível e rastreável a um NFR/ADR; nenhum genérico.
</success_criteria>
"
```
````

Por:

````
Monta o prompt em **prosa** seguindo `#anatomia-constitution` e **entrega o comando pronto** (não
dispara nada):

```text
/speckit.constitution "Crie princípios derivados destes NFRs e restrições da PRD: NFR-01
(render < 100ms ao digitar), NFR-02 (persistência sobrevive a reload); ADR-001 (motor de render),
ADR-003 (persistência local). Cada princípio deve ser decidível — com um critério objetivo
(validador, limiar numérico ou teste) — e rastreável ao NFR ou ADR de origem. Evite princípios
genéricos como 'código limpo' ou 'boa cobertura'."
```
````

- [ ] **Step 3: Seção da ponte `specify` (exemplo XML → prosa)**

Edit em `docs/como-usar.md`. Substitua o bloco:

````
Delega a `zion-rewrite-prompt` montando o XML com as 3 tags de `#anatomia-specify` e **entrega o comando
pronto** (não dispara nada):

```text
/speckit.specify "
<context>
Referência (não requisito): RF-01 (prévia ao digitar), RF-05 (persistência entre sessões).
ADR-001 (motor de render), ADR-003 (persistência local).
</context>
<success_criteria>
A pessoa abre o editor, digita um diagrama mermaid e vê a prévia renderizar; ao recarregar a
página, o diagrama e a prévia continuam lá.
</success_criteria>
<constraints>
Não citar linguagem, framework ou biblioteca — stack fica no plan. Sem critérios de aceite
detalhados nem telas.
</constraints>
"
```
````

Por:

````
Monta o prompt em **prosa** seguindo `#anatomia-specify` e **entrega o comando pronto** (não dispara
nada):

```text
/speckit.specify "O usuário abre o editor, digita um diagrama mermaid e vê a prévia renderizar ao
digitar; ao recarregar a página, o diagrama e a prévia continuam lá. Contexto: RF-01 (prévia ao
digitar), RF-05 (persistência entre sessões); vale a restrição da ADR-003. Não inclua linguagem,
framework ou bibliotecas — a stack fica no plan."
```
````

- [ ] **Step 4: Seção da ponte `plan` (exemplo XML → prosa)**

Edit em `docs/como-usar.md`. Substitua o bloco:

````
Lê o `spec.md` da fatia, cruza com `docs/adr/`, propõe os ADRs relevantes para você confirmar, e
delega a `zion-rewrite-prompt` montando o XML de `#anatomia-plan`. **Entrega o comando pronto** (não
dispara nada):

```text
/speckit.plan "
<context>
spec.md da fatia R0 (prévia ao digitar; persistência entre sessões).
ADR-001: motor de render escolhido. ADR-003: persistência local escolhida.
</context>
<instructions>
Derive o plano técnico que realiza o spec.md dentro das decisões dos ADRs acima.
</instructions>
<constraints>
Honre cada ADR listado; não re-decida o que um ADR já fixou. Não expanda além do escopo do spec.md.
</constraints>
<success_criteria>
O plano honra ADR-001 e ADR-003 e cobre o resultado observável do spec.md.
</success_criteria>
"
```
````

Por:

````
Lê o `spec.md` da fatia, cruza com `docs/adr/`, propõe os ADRs relevantes para você confirmar, e
monta o prompt em **prosa** seguindo `#anatomia-plan`. **Entrega o comando pronto** (não dispara
nada):

```text
/speckit.plan "Realize o spec.md desta feature (prévia ao digitar + persistência entre sessões)
honrando estas decisões já fechadas, sem reabri-las: ADR-001 (motor de render escolhido), ADR-003
(persistência local escolhida). Descreva a stack, a arquitetura e as restrições técnicas que
decorrem dessas decisões e realizam o resultado observável do spec.md."
```
````

- [ ] **Step 5: Confirmar a contagem de skills (linha 20)**

A linha 20 já diz "Isso instala as 8 skills…". Após a remoção do `zion-rewrite-prompt` o total é **8**, então a linha fica correta — **não editar**. Só confirme:

Run: `grep -n "instala as .* skills" docs/como-usar.md`
Expected: uma linha contendo `as 8 skills`. (Se disser outro número, corrija para `8`.)

- [ ] **Step 6: Verificar arquivo limpo**

Run: `grep -nE 'rewrite-prompt|<context>|<constraints>|<success_criteria>' docs/como-usar.md || echo "OK: como-usar limpo"`
Expected: `OK: como-usar limpo`

- [ ] **Step 7: Commit**

```bash
git add docs/como-usar.md
git commit -m "docs(como-usar): pontes montam prompt em prosa; sem zion-rewrite-prompt

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 8: Atualizar `docs/guia-prd-para-spec-kit.md`

**Files:**
- Modify: `docs/guia-prd-para-spec-kit.md`

- [ ] **Step 1: Reescrever a descrição da skill no Passo 5b**

Edit em `docs/guia-prd-para-spec-kit.md`. Substitua o bloco:

```
- **Skill(s):**
  - `zion-rewrite-prompt` (real) — **peça central deste passo**: o input do `/speckit.specify` é
    *literalmente um prompt*, e é aqui que o `zion-rewrite-prompt` paga o próprio custo:
    - `<constraints>` vira o **guardião da fronteira** — é onde você escreve, explícito, "não citar
      linguagem/framework/bibliotecas; stack só no `plan`", impedindo que o "como" vaze para o `specify`;
    - `<context>` **separa referência de instrução** — `RF-xx` e ADRs entram como contexto, não viram
      requisitos acidentais;
    - `<success_criteria>` te obriga a declarar o **resultado observável** antes de rodar — justamente o
      que o gate `/speckit.clarify` vai cobrar em seguida, então você já antecipa o gate.
  - Spec Kit (real) — os comandos `/speckit.*`.
```

Por:

```
- **Skill(s):**
  - `/zion-prd-specify-prompt` (real) — **ponte deste passo**: o input do `/speckit.specify` é
    *literalmente um prompt em linguagem natural*, e a ponte o monta para você, em prosa:
    - **guarda a fronteira** — escreve explícito "não citar linguagem/framework/bibliotecas; stack só
      no `plan`", impedindo que o "como" vaze para o `specify`;
    - **separa referência de instrução** — `RF-xx` e ADRs entram como contexto, não viram requisitos
      acidentais;
    - **declara o resultado observável** antes de rodar — justamente o que o gate `/speckit.clarify`
      vai cobrar em seguida, então você já antecipa o gate.
  - Spec Kit (real) — os comandos `/speckit.*`.
```

- [ ] **Step 2: Reescrever a linha da tabela de skills**

Edit em `docs/guia-prd-para-spec-kit.md`. Substitua a linha:

```
| `zion-rewrite-prompt` | `/zion-rewrite-prompt` ou "reescrever/estruturar prompt" | **Montar o prompt do `/speckit.constitution` (P5a)** — `<constraints>` blinda a decidibilidade dos princípios — **e do `/speckit.specify` (P5b)** — `<constraints>` blinda a fronteira "sem stack" e `<success_criteria>` antecipa o gate `clarify`. |
```

Por:

```
| `/zion-prd-constitution-prompt`, `/zion-prd-specify-prompt`, `/zion-prd-plan-prompt` | Skill tool ou o comando homônimo | **Pontes para o Spec Kit (P5)** — cada uma monta, em prosa, o prompt do seu `/speckit.*`: guarda a decidibilidade+rastreabilidade dos princípios (constitution), a fronteira "sem stack" (specify) e o honrar-ADRs (plan); entrega o comando pronto e para. |
```

- [ ] **Step 3: Verificar arquivo limpo**

Run: `grep -nE 'rewrite-prompt|<context>|<constraints>|<success_criteria>' docs/guia-prd-para-spec-kit.md || echo "OK: guia limpo"`
Expected: `OK: guia limpo`

- [ ] **Step 4: Commit**

```bash
git add docs/guia-prd-para-spec-kit.md
git commit -m "docs(guia): pontes autocontidas em prosa; sem zion-rewrite-prompt

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 9: Verificação final integrada

**Files:** (nenhum — só checagens)

- [ ] **Step 1: Zero referências a rewrite-prompt fora do histórico**

Run:
```bash
grep -rn "rewrite-prompt" skills/ assets/ scripts/ README.md docs/como-usar.md docs/guia-prd-para-spec-kit.md .claude-plugin/ || echo "OK: zero referências pendentes"
```
Expected: `OK: zero referências pendentes`

- [ ] **Step 2: Skill removida e contagem correta**

Run: `test ! -d skills/zion-rewrite-prompt && echo "removida"; find skills -maxdepth 1 -mindepth 1 -type d | wc -l`
Expected: `removida`, depois `8`

- [ ] **Step 3: Nenhum prompt gerado com tag XML nas skills/guias vivos**

Run:
```bash
grep -rnE '<context>|<constraints>|<instructions>|<success_criteria>' skills/*/SKILL.md assets/quality-rules.md docs/como-usar.md docs/guia-prd-para-spec-kit.md || echo "OK: sem tags XML"
```
Expected: `OK: sem tags XML`

- [ ] **Step 4: Assets sem drift**

Run: `./scripts/check-assets.sh`
Expected: `check-assets: sem drift`

- [ ] **Step 5: Cada ponte para no handoff**

Run: `for s in constitution specify plan; do grep -q "PARE AQUI" skills/zion-prd-$s-prompt/SKILL.md && echo "$s: PARE ok"; done`
Expected: `constitution: PARE ok`, `specify: PARE ok`, `plan: PARE ok`

- [ ] **Step 6: Histórico datado intacto**

Run: `git status --porcelain docs/superpowers/specs docs/superpowers/plans | grep -vE '2026-07-13-pontes-spec-kit-prosa' || echo "OK: histórico não modificado"`
Expected: `OK: histórico não modificado`

---

## Notas de execução

- **Ordem importa:** Task 1 antes das 2–4 (as pontes citam as âncoras já reescritas). A remoção (Task 5) pode vir depois das pontes.
- **Pre-commit hook:** ao commitar `assets/quality-rules.md` (Task 1), o hook roda `sync-assets.sh` e inclui os `references/` regenerados. O Step 4 da Task 1 já roda o sync à mão para o caso de `--no-verify`.
- **Sem testes unitários:** este é um harness de conteúdo (skills/markdown). As checagens são `grep` + `check-assets.sh` — tratá-las como o "verde" de cada task.
