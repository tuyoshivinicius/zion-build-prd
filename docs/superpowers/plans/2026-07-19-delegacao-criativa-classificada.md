# Delegação criativa classificada — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fazer a delegação criativa dos três estágios (`discovery`, `write`, `decompose`) classificar cada tensão como **diagnóstica** ou **propositiva** antes de delegar ao `superpowers:brainstorming`, a partir de uma rubrica de fonte única, e verificar por máquina o prompt de delegação montado com um gate novo — sem tocar o contrato externo C1–C3.

**Architecture:** Um asset novo (`assets/delegacao-criativa.md`) é a fonte única da rubrica (classificação + dois previews + condução), sincronizado para as `references/` das três skills pelo mesmo mecanismo `sync-assets.sh` já existente. Um verificador novo em shell (`scripts/check-delegacao.sh`) lê o bloco de delegação montado do stdin e greppa marcadores tolerantes (no molde do `check-superpowers-contract.sh`), aconselhando (`RN-01`). Cada `SKILL.md` ganha um passo: materializar o bloco, autoverificar, então invocar. A decisão estruturante vira ADR-017 (ao lado do ADR-007, sem supersedê-lo) e reflete no canon (`prd.md`/`architecture.md`) no mesmo commit.

**Tech Stack:** Bash (POSIX-ish, `set -u`, contrato de exit 0/1/2), Markdown (assets, skills, docs, ADRs), `grep -iE` tolerante a reescrita. Sem runtime próprio — é prosa de skill + verificadores em shell (ADR da arquitetura §1).

## Global Constraints

Copiados verbatim das fontes da verdade e do design. **Toda task herda esta seção.**

- **Fonte única (ADR-001 / `RN-05`):** `assets/` é a fonte única; **nunca** edite `skills/*/references/` à mão — são derivados que o pre-commit regenera via `scripts/sync-assets.sh` a partir do `ASSET_MAP` (`scripts/asset-map.sh`).
- **Canonização no mesmo commit (CLAUDE.md):** toda mudança de comportamento/estrutura reflete nas fontes da verdade no **mesmo commit**. Skill nova/alterada ⇒ RF na §6 + linha na §12 de `docs/prd.md`. Script novo ⇒ tabela §3 de `docs/architecture.md`. Fonte nova no `ASSET_MAP` ⇒ §4 de `docs/architecture.md`. ADR novo ⇒ índice §2 de `docs/architecture.md`.
- **Guards bloqueantes no pre-commit:** `.githooks/pre-commit` roda `sync-assets.sh` → `git add skills/*/references/` → `check-canon.sh` (BLOQUEIA) → `check-adr.sh docs/adr` (BLOQUEIA). Portanto **cada commit deste plano tem de sair canon-limpo**. Ative os hooks uma vez: `./scripts/setup-hooks.sh`.
- **Contrato de exit dos verificadores (ADR-004):** `0` limpo · `1` achados · `2` erro de uso/ambiente. No projeto-alvo o veredito **aconselha, nunca bloqueia** (`RN-01` / `NFR-05`).
- **Fronteira o-quê/como (`RN-02`):** stack só em ADR e `plan.md`. A liberação de preview conceitual fica **escopada à delegação criativa** (mora no asset novo); o `#fronteira` global de `assets/quality-rules.md` fica **intacto** (specify/PRD seguem com tela banida).
- **Não tocar o contrato externo:** C1–C3 (ADR-007) seguem válidos, **sem supersessão**. `NFR-02` (exatamente 1 dependência externa de skill) fica intacto — não aumentamos o acoplamento com o superpowers.
- **Marcadores greppados são tolerantes a reescrita:** grep de marcador de capacidade, não diff de frase (molde C1–C3). Validados neste ambiente (`C.UTF-8`): `diagn[óo]stic`, `propositiv`, `abordagens`, `recomenda`, `ilustra`, `tela`, `plan\.md|proib|banid`, `uma pergunta|passo a passo|tarefa por passo`.
- **NFR-04:** 100% dos verificadores mecânicos têm auto-teste com fixture limpa e suja.
- **Estilo de commit:** conventional commits em português, como no histórico do repo (`feat(...)`, `docs(...)`, `test(...)`).

---

## File Structure

**Criados:**

- `assets/delegacao-criativa.md` — a rubrica (fonte única): classificação diagnóstica×propositiva, os dois previews, a condução. Responsabilidade: dizer *o-quê* a delegação classifica e libera. (Task 1)
- `scripts/check-delegacao.sh` — o gate: lê o bloco de delegação do stdin/arquivo e confere que ele **pede** a distinção. Distribuído como reference. (Task 2)
- `scripts/test-check-delegacao.sh` — auto-teste do gate contra fixtures. Dev-workflow (não viaja). (Task 2)
- `scripts/fixtures/delegacao-clean.md` — bloco de delegação **com** a distinção → exit 0. (Task 2)
- `scripts/fixtures/delegacao-dirty.md` — bloco **sem** a distinção → exit 1. (Task 2)
- `docs/adr/ADR-017-delegacao-criativa-classificada.md` — a decisão estruturante. (Task 3)
- `scripts/fixtures/skills/discovery/revisar-propositiva/discovery.md` — insumo da fixture de julgamento. (Task 5)
- `scripts/fixtures/skills/discovery/revisar-propositiva/esperado.md` — sidecar de veredito esperado. (Task 5)

**Modificados:**

- `scripts/asset-map.sh` — entradas novas: o asset → 3 skills; o gate → 3 skills. (Tasks 1 e 2)
- `scripts/eval.sh` — registra `delegacao` na suíte mecânica. (Task 2)
- `skills/zion-prd-discovery/SKILL.md`, `skills/zion-prd-write/SKILL.md`, `skills/zion-prd-decompose/SKILL.md` — passo de delegação classificada (materializar bloco + autoverificar + invocar); na discovery, a supressão de preview passa a referenciar a rubrica. (Task 4)
- `docs/prd.md` — RF-20 novo (§6/E1), restrição ADR-017 (§8), linhas §12 (RF-20, e RF-11/RF-12 ganham os scripts novos), changelog §13. (Tasks 2 e 3)
- `docs/architecture.md` — §2 (índice ADR-017), §3 (dois scripts novos), §4 (asset novo). (Tasks 1, 2 e 3)
- `docs/guias/avaliacao-harness.md` — §1 e §4 (mecânica: o gate novo; julgamento: a fixture nova). (Tasks 2 e 5)

**Derivados (regenerados pelo pre-commit — nunca editados à mão):**

- `skills/{zion-prd-discovery,zion-prd-write,zion-prd-decompose}/references/delegacao-criativa.md`
- `skills/{zion-prd-discovery,zion-prd-write,zion-prd-decompose}/references/check-delegacao.sh`

**Ordem das tasks** (mantém todo commit canon-limpo e todo ponteiro de §12 resolvendo para um artefato que já existe): asset → gate+teste+fixtures → ADR+canon da PRD → costura nas skills → fixture de julgamento → verificação integral.

---

## Task 1: A rubrica (asset de fonte única)

Cria o asset da rubrica, registra-o no `ASSET_MAP` e o canoniza na §4 do `architecture.md`. Ao commitar, o pre-commit sincroniza o asset para as `references/` das três skills. Deliverable independentemente revisável: o *conteúdo* da rubrica.

**Files:**
- Create: `assets/delegacao-criativa.md`
- Modify: `scripts/asset-map.sh`
- Modify: `docs/architecture.md` (§4)

**Interfaces:**
- Produces: o arquivo `assets/delegacao-criativa.md` carregando os marcadores que o gate da Task 2 vai greppar — `diagnóstica`, `propositiva`, `2–3 abordagens`, `recomendação`, `ilustra(r)`, `tela`, `plan.md`, `uma pergunta`, `crie uma tarefa por passo`. Consumido (via `references/`) pelas três skills na Task 4.

- [ ] **Step 1: Garantir os hooks ativos**

Uma vez por checkout, para que o pre-commit regenere e valide:

Run: `./scripts/setup-hooks.sh`
Expected: `git config core.hooksPath` passa a apontar `.githooks` (comando é idempotente).

- [ ] **Step 2: Criar o asset da rubrica**

Create `assets/delegacao-criativa.md` com exatamente este conteúdo:

```markdown
# Delegação criativa — classificação da tensão antes de delegar

> Fonte única citada pelos estágios que delegam a clarificação ao `superpowers:brainstorming`
> (discovery, write, decompose). Afinar a rubrica se faz **aqui**, num lugar só; o sync propaga
> para os `references/` das três skills. Escopo: **só a delegação criativa** — o `#fronteira`
> global de `quality-rules.md` fica intacto (specify/PRD seguem com tela banida).

Antes de delegar, o harness lê o insumo (discovery / PRD / backlog), **enumera as tensões como
observações suas** (nunca já redigidas como pergunta), **classifica cada uma** pela rubrica abaixo,
monta o bloco de delegação e **se autoverifica** (`check-delegacao.sh`) antes de invocar o
brainstorming. Materializar o bloco e checá-lo é a única diferença de comportamento: o conteúdo da
delegação é o mesmo, só que classificado.

## 1. Classificação diagnóstica × propositiva

A distinção **não é de formatação, é de tipo de pergunta**: uma pede informação, a outra propõe uma
escolha de design.

| Tipo | A tensão pergunta… | Vira |
|---|---|---|
| **Diagnóstica** | *qual dos seus fatos/intenções é o verdadeiro?* | pergunta simples, uma por vez; **sem** recomendação (não há o que recomendar) e **sem** preview (não há artefato a ilustrar) |
| **Propositiva** | *isto admite mais de um desenho?* | **2–3 abordagens** com trade-offs + **recomendação** explícita (liderando pela recomendada) + preview conceitual |

Exemplos reais: uma tensão **diagnóstica** ("qual momento de uso servir primeiro", três leituras do
que o autor quis dizer) pede revelar intenção — não force recomendação onde não há o que recomendar.
Uma tensão **propositiva** ("teclado primeiro × mouse primeiro", três desenhos com recomendação e
mockup) admite desenho — proponha 2–3 abordagens e recomende.

## 2. Os dois previews (escopado aqui)

Em vez de banir preview em bloco, distinga duas categorias — com o **teste crítico** passa/vaza:

| Categoria | Exemplo | Na delegação |
|---|---|---|
| **Preview que ilustra a escolha** | fluxo de dados (`canvas edit ──► reescreve código`), barras de profundidade por tipo, contrato de saída em ✓/✗ | **liberado** — é auxílio de decisão |
| **Preview que desenha tela** | mockup de palette `Ctrl+K`, linha de atalhos sob o nó, arranjo de widget | **proibido** — é do `plan.md` |

Redação-núcleo: **ilustrar a consequência** de uma opção (fluxo, comparação, contrato de saída) é
bem-vindo e ajuda a decidir; **desenhar tela** (mockup, atalho, widget, arranjo de UI) fica no
`plan.md`.

## 3. Condução

Conduza pelo seu protocolo — **uma pergunta por vez**; quando a tensão for propositiva, 2–3
abordagens com trade-offs e sua recomendação explícita; **crie uma tarefa por passo** da sua
checklist, conduzindo **passo a passo**. Isto é instrução, não mecanismo: o efeito é julgamento do
executor, não garantia.

## Vale nos dois modos

No **do-zero**, a rubrica **codifica** o que já dava certo — é aditiva, não regride. No
**retomar/revisar**, **corrige** a degradação para clarificação diagnóstica sem recomendação nem
preview.
```

- [ ] **Step 3: Verificar que o asset carrega todos os marcadores do gate**

Isto é o "teste" do conteúdo do asset — o gate da Task 2 depende destes marcadores existirem.

Run:
```bash
f=assets/delegacao-criativa.md
grep -qiE 'diagn[óo]stic' "$f" && grep -qiE 'propositiv' "$f" \
 && grep -qiE 'abordagens' "$f" && grep -qiE 'recomenda' "$f" \
 && grep -qiE 'ilustra' "$f" && grep -qiE 'tela' "$f" && grep -qiE 'plan\.md|proib|banid' "$f" \
 && grep -qiE 'uma pergunta|passo a passo|tarefa por passo' "$f" \
 && echo "MARCADORES OK" || echo "FALTA MARCADOR"
```
Expected: `MARCADORES OK`

- [ ] **Step 4: Registrar o asset no `ASSET_MAP`**

Edit `scripts/asset-map.sh` — adicione a entrada do asset ao array `ASSET_MAP` (logo após a linha `assets/quality-rules.md ...`, mantendo o alinhamento por espaços do arquivo). Adicione **apenas o asset** nesta task; o script `check-delegacao.sh` entra no `ASSET_MAP` na Task 2 (só depois de existir, senão `sync-assets.sh` falha com `set -e` ao `cp` um arquivo inexistente).

Linha a adicionar:
```bash
  "assets/delegacao-criativa.md          zion-prd-discovery zion-prd-write zion-prd-decompose"
```

- [ ] **Step 5: Rodar o sync e conferir os derivados**

Run:
```bash
./scripts/sync-assets.sh
ls skills/zion-prd-discovery/references/delegacao-criativa.md \
   skills/zion-prd-write/references/delegacao-criativa.md \
   skills/zion-prd-decompose/references/delegacao-criativa.md
```
Expected: `sync-assets: ok` e as três cópias listadas (existem).

- [ ] **Step 6: Canonizar o asset na §4 do `architecture.md`**

Edit `docs/architecture.md` — na seção `## 4. Fonte única e derivados`, na lista de fontes mapeadas no `ASSET_MAP`, adicione o bullet (logo após a linha `- assets/superpowers-contract.md ...`):

```markdown
- assets/delegacao-criativa.md — rubrica da delegação criativa (classificação diagnóstica×propositiva, dois previews, condução); lida pelos estágios discovery/write/decompose.
```

Isto satisfaz o `check_assets_doc` (C4) do `check-canon.sh`, que greppa a string literal `assets/delegacao-criativa.md` no `architecture.md`.

- [ ] **Step 7: Rodar os guards de canonização**

Run: `./scripts/check-canon.sh && ./scripts/check-assets.sh`
Expected: `check-canon: limpo` e `check-assets` sem drift (exit 0 em ambos). Se `check-canon` acusar `asset-sem-doc`, o Step 6 não bateu a string exata.

- [ ] **Step 8: Commit**

O pre-commit vai rodar `sync-assets.sh` + `git add skills/*/references/` + `check-canon.sh` + `check-adr.sh`.

```bash
git add assets/delegacao-criativa.md scripts/asset-map.sh docs/architecture.md skills/*/references/delegacao-criativa.md
git commit -m "feat(delegacao): rubrica de fonte única da delegação criativa classificada"
```
Expected: commit criado; os hooks passam (`check-canon: limpo`).

---

## Task 2: O gate `check-delegacao.sh` + auto-teste + fixtures (TDD)

Cria o verificador do bloco de delegação, seu auto-teste e as fixtures limpa/suja (`NFR-04`), registra-o no `eval.sh` e no `ASSET_MAP`, e canoniza os dois scripts novos na §3 do `architecture.md` e na §12 da PRD (RF-11 ganha o gate, RF-12 ganha o auto-teste). TDD: a fixture + o auto-teste são o teste que falha primeiro.

**Files:**
- Create: `scripts/fixtures/delegacao-clean.md`
- Create: `scripts/fixtures/delegacao-dirty.md`
- Create: `scripts/test-check-delegacao.sh`
- Create: `scripts/check-delegacao.sh`
- Modify: `scripts/eval.sh`
- Modify: `scripts/asset-map.sh`
- Modify: `docs/architecture.md` (§3 tabela de scripts; §4 prosa dos references distribuídos)
- Modify: `docs/prd.md` (§12 — RF-11 e RF-12)
- Modify: `docs/guias/avaliacao-harness.md` (§1 e §4 mecânicas)

**Interfaces:**
- Consumes: os marcadores gravados no asset da Task 1 (o bloco limpo os embute).
- Produces: `scripts/check-delegacao.sh` com a interface `check-delegacao.sh <arquivo|->` (`-` lê do stdin, igual ao `check-prd.sh specify`), exit `0` limpo · `1` achados (`distincao-ausente` / `propositiva-incompleta` / `previews-ausente` / `conducao-ausente`) · `2` uso. Invocado pelas três skills na Task 4 como `bash references/check-delegacao.sh -`.

- [ ] **Step 1: Criar a fixture limpa**

Create `scripts/fixtures/delegacao-clean.md` (um bloco de delegação **com** observações classificadas + a rubrica embutida):

```markdown
# Bloco de delegação — discovery (modo revisar)

Observações do harness sobre o `docs/discovery.md` atual (enumeradas como observações, não como
perguntas prontas):

- **Observação 1 (diagnóstica).** O discovery diz "servir o primeiro acesso" e também "servir o uso
  recorrente"; qual momento de uso é o dominante não está resolvido — tensão *diagnóstica* (revela
  intenção). Trate como pergunta simples, uma por vez, sem recomendação e sem preview.
- **Observação 2 (propositiva).** A entrada da tarefa-núcleo admite mais de um desenho (por teclado
  ou por ponteiro) — tensão *propositiva*: proponha **2–3 abordagens** com trade-offs e uma
  **recomendação** explícita, liderando pela recomendada, com preview conceitual.

Conduza pelo seu protocolo: **uma pergunta por vez**; para a tensão propositiva, 2–3 abordagens +
recomendação; **crie uma tarefa por passo** da sua checklist.

Regra dos previews nesta delegação: **ilustrar** a consequência de uma opção (fluxo, comparação,
contrato de saída) é bem-vindo e ajuda a decidir; **desenhar tela** (mockup, atalho, widget) fica no
`plan.md`.
```

- [ ] **Step 2: Criar a fixture suja**

Create `scripts/fixtures/delegacao-dirty.md` (um bloco ingênuo: tensões já redigidas como pergunta diagnóstica, **sem** a rubrica):

```markdown
# Bloco de delegação — discovery (modo revisar) — SUJO

Perguntas para o brainstorming:

1. Qual dos seus dois fatos é o verdadeiro — servir o primeiro acesso ou o uso recorrente?
2. Você prefere entrada por teclado ou por ponteiro?

Grave o resultado em `docs/discovery.md`.
```

- [ ] **Step 3: Escrever o auto-teste (o teste que falha primeiro)**

Create `scripts/test-check-delegacao.sh` com exatamente este conteúdo:

```bash
#!/usr/bin/env bash
# Auto-teste do check-delegacao.sh contra fixtures. Roda pela camada mecânica (scripts/eval.sh).
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
CHECK="scripts/check-delegacao.sh"
FIX="scripts/fixtures"
fail=0

assert_exit() {  # desc  exit_esperado  exit_veio
  if [ "$2" != "$3" ]; then echo "FALHOU: $1 (exit esperado $2, veio $3)"; fail=1
  else echo "ok: $1"; fi
}
assert_contains() {  # desc  agulha  palheiro
  if printf '%s' "$3" | grep -qi -- "$2"; then echo "ok: $1"
  else echo "FALHOU: $1 (não achou: $2)"; fail=1; fi
}

# 1. Bloco limpo (com a distinção + rubrica) → exit 0 / limpo.
out="$(bash "$CHECK" "$FIX/delegacao-clean.md")"; rc=$?
assert_exit "bloco limpo sai 0" 0 "$rc"
assert_contains "bloco limpo reporta limpo" "check-delegacao: limpo" "$out"

# 2. Bloco limpo via stdin (-) → exit 0 (é como as skills invocam).
out="$(bash "$CHECK" - < "$FIX/delegacao-clean.md")"; rc=$?
assert_exit "bloco limpo via stdin sai 0" 0 "$rc"

# 3. Bloco sujo (sem a distinção) → exit 1 citando cada marcador ausente.
out="$(bash "$CHECK" "$FIX/delegacao-dirty.md")"; rc=$?
assert_exit "bloco sujo sai 1" 1 "$rc"
assert_contains "acha distincao-ausente"      "distincao-ausente"      "$out"
assert_contains "acha propositiva-incompleta" "propositiva-incompleta" "$out"
assert_contains "acha previews-ausente"       "previews-ausente"       "$out"
assert_contains "acha conducao-ausente"       "conducao-ausente"       "$out"

# 4. Sem argumento → exit 2 (erro de uso).
out="$(bash "$CHECK" 2>/dev/null)"; rc=$?
assert_exit "sem argumento sai 2" 2 "$rc"

# 5. Arquivo inexistente → exit 2.
out="$(bash "$CHECK" /caminho/que/nao/existe.md 2>/dev/null)"; rc=$?
assert_exit "arquivo inexistente sai 2" 2 "$rc"

if [ "$fail" -eq 0 ]; then echo "test-check-delegacao: tudo verde"; else echo "test-check-delegacao: FALHOU"; exit 1; fi
```

- [ ] **Step 4: Rodar o auto-teste e confirmar que FALHA**

Run: `bash scripts/test-check-delegacao.sh`
Expected: FALHA — o script `check-delegacao.sh` ainda não existe, então `bash "$CHECK"` erra e os `assert_exit` reportam exits inesperados (linha final `test-check-delegacao: FALHOU`, exit 1).

- [ ] **Step 5: Escrever o gate `check-delegacao.sh`**

Create `scripts/check-delegacao.sh` com exatamente este conteúdo:

```bash
#!/usr/bin/env bash
# check-delegacao.sh — verificador do bloco de delegação criativa montado (RF-20).
# Verifica; NÃO bloqueia. Exit 0 = limpo, 1 = achados, 2 = erro de uso/ambiente.
# Quem lê o exit é a fase de delegação (discovery/write/decompose), que aconselha
# (RN-01) e corrige os marcadores ausentes antes de invocar o brainstorming.
#
# Lê o bloco de delegação montado (observações classificadas + a rubrica) e confere que ele PEDE
# a distinção diagnóstica×propositiva — no molde tolerante do contrato C1–C3 (grep de marcadores,
# não diff de frase). NÃO confirma que o agente classificou certo cada tensão, que nada foi
# pré-mastigado, nem que a experiência melhorou — isso segue julgamento (ver o limite honesto no
# ADR-017 / design). Fonte única da rubrica: assets/delegacao-criativa.md.
#
# Uso:
#   check-delegacao.sh <arquivo|->    # "-" lê o bloco do stdin (igual ao check-prd.sh specify)
set -u

usage() { echo "uso: check-delegacao.sh <arquivo|->" >&2; exit 2; }

target="${1:-}"
[ -n "$target" ] || usage

# Normaliza o alvo: stdin ("-") vira um arquivo temporário; arquivo real precisa existir.
TMPIN=""
cleanup() { [ -n "$TMPIN" ] && rm -f "$TMPIN"; }
trap cleanup EXIT
if [ "$target" = "-" ]; then
  TMPIN="$(mktemp)"; cat > "$TMPIN"; SRC="$TMPIN"; LABEL="delegacao"
else
  [ -f "$target" ] || { echo "check-delegacao: arquivo não encontrado: $target" >&2; exit 2; }
  SRC="$target"; LABEL="$(basename "$target")"
fi

content="$(cat "$SRC")"
has() { printf '%s' "$content" | grep -qiE -- "$1"; }

findings=""
miss() {  # $1 = achado
  if [ -z "$findings" ]; then findings="$1"; else findings="$findings
$1"; fi
}

# 1. A distinção pedida: diagnóstica ∧ propositiva (tolerante a acento).
{ has 'diagn[óo]stic' && has 'propositiv'; } \
  || miss "$LABEL: distincao-ausente — o bloco não pede a distinção diagnóstica×propositiva (classifique cada tensão)"

# 2. Propositiva → 2–3 abordagens + recomendação explícita.
{ has 'abordagens' && has 'recomenda'; } \
  || miss "$LABEL: propositiva-incompleta — falta \"2–3 abordagens\" e/ou a recomendação explícita da tensão propositiva"

# 3. Os dois previews: preview que ilustra a escolha (liberado) ∧ tela (proibida → plan.md).
{ has 'ilustra' && has 'tela' && has 'plan\.md|proib|banid'; } \
  || miss "$LABEL: previews-ausente — falta a regra dos dois previews (ilustrar a escolha liberado ∧ desenhar tela vai para o plan.md)"

# 4. Condução: uma pergunta / passo a passo / tarefa por passo (satisfaz com QUALQUER um).
has 'uma pergunta|passo a passo|tarefa por passo' \
  || miss "$LABEL: conducao-ausente — o bloco não instrui a condução (uma pergunta por vez / passo a passo / uma tarefa por passo)"

if [ -n "$findings" ]; then
  printf '%s\n' "$findings"
  count="$(printf '%s\n' "$findings" | grep -c .)"
  echo "check-delegacao: $count achado(s)"
  exit 1
else
  echo "check-delegacao: limpo"
  exit 0
fi
```

- [ ] **Step 6: Rodar o auto-teste e confirmar que PASSA**

Run: `bash scripts/test-check-delegacao.sh`
Expected: todos `ok:` e a linha final `test-check-delegacao: tudo verde` (exit 0).

- [ ] **Step 7: Registrar `delegacao` no `eval.sh`**

Edit `scripts/eval.sh` em quatro pontos:

1. No `declare -A TESTS=(...)`, adicione (logo após a linha `[experiencia]=...`):
```bash
  [delegacao]="scripts/test-check-delegacao.sh"
```
2. Na linha `ORDER=(...)`, insira `delegacao` após `experiencia`:
```bash
ORDER=(prd estudo experiencia delegacao adr trace backlog arquitetura trace-arquitetura contract canon)
```
3. No `case "$sel" in`, adicione `delegacao` à alternação de nomes válidos:
```bash
    prd|estudo|experiencia|delegacao|adr|trace|backlog|arquitetura|trace-arquitetura|contract|canon) ORDER=("$sel") ;;
```
4. Na mensagem de `usage` do mesmo `case`, adicione `delegacao`:
```bash
    *) echo "uso: eval.sh [prd|estudo|experiencia|delegacao|adr|trace|backlog|arquitetura|trace-arquitetura|contract|canon]" >&2; exit 2 ;;
```

- [ ] **Step 8: Rodar a suíte mecânica isolando `delegacao`, depois inteira**

Run: `./scripts/eval.sh delegacao`
Expected: `=== eval: delegacao ===`, `test-check-delegacao: tudo verde`, `eval: tudo verde`.

Run: `./scripts/eval.sh`
Expected: todos os blocos verdes e `eval: tudo verde` (o `delegacao` aparece na ordem, após `experiencia`).

- [ ] **Step 9: Registrar o gate no `ASSET_MAP` (distribuir como reference)**

Edit `scripts/asset-map.sh` — adicione a entrada do **script** (o `test-*` NÃO se distribui — é Dev-workflow). Coloque junto dos outros scripts distribuídos, após a linha `scripts/check-experiencia.sh ...`:

```bash
  "scripts/check-delegacao.sh             zion-prd-discovery zion-prd-write zion-prd-decompose"
```

- [ ] **Step 10: Sincronizar e conferir o reference derivado**

Run:
```bash
./scripts/sync-assets.sh
ls skills/zion-prd-discovery/references/check-delegacao.sh \
   skills/zion-prd-write/references/check-delegacao.sh \
   skills/zion-prd-decompose/references/check-delegacao.sh
```
Expected: `sync-assets: ok` e as três cópias existem.

- [ ] **Step 11: Canonizar os scripts novos na §3 do `architecture.md`**

Edit `docs/architecture.md`, seção `## 3. Scripts`, tabela de papéis. Adicione a linha do gate após `scripts/check-experiencia.sh | ...`:
```markdown
| scripts/check-delegacao.sh | Verificador do bloco de delegação criativa montado (distinção diagnóstica×propositiva, dois previews, condução); lido pela fase de delegação, que aconselha. |
```
E adicione a linha do auto-teste junto dos outros `test-*` (após `scripts/test-check-experiencia.sh | ...`):
```markdown
| scripts/test-check-delegacao.sh | Auto-teste do check-delegacao.sh contra fixtures. |
```

Ainda no `architecture.md`, na §4, na frase "Também distribuídos como references executáveis:", inclua `scripts/check-delegacao.sh` na lista (é distribuído). Edite a enumeração para conter `scripts/check-delegacao.sh` entre os demais (ex.: após `scripts/check-experiencia.sh`).

Isto satisfaz o `check_scripts_doc` (C3) do `check-canon.sh`, que exige todo `scripts/*.sh` top-level citado na tabela §3 (por basename).

- [ ] **Step 12: Canonizar os scripts na §12 da PRD (RF-11 e RF-12)**

Edit `docs/prd.md`, seção `## 12. Rastreabilidade`:

- Na linha do **RF-11**, acrescente ao fim da célula de artefato: ` · scripts/check-delegacao.sh`
- Na linha do **RF-12**, acrescente ao fim da célula de artefato: ` · scripts/test-check-delegacao.sh`

(Editar a §12 é seguro para o dogfood do `check-prd.sh`: linhas de tabela começam com `|` e não disparam `check_rf`/`check_nfr`/`check_changelog`.)

- [ ] **Step 13: Canonizar o gate no roteiro de avaliação (camada mecânica)**

Edit `docs/guias/avaliacao-harness.md`:

- Na §1, na frase que lista os verificadores de script da camada mecânica ("Os verificadores de script (`check-prd.sh`, `check-adr.sh`, …)"), inclua `check-delegacao.sh` na enumeração.
- Na §4, tabela "Mecânicas (camada determinística — CI)", adicione duas linhas:
```markdown
| `check-delegacao.sh` | `fixtures/delegacao-clean.md` | — (distinção + rubrica presentes) | limpo (exit 0) |
| `check-delegacao.sh` | `fixtures/delegacao-dirty.md` | tensões como pergunta diagnóstica, sem a rubrica | achados (exit 1) |
```

- [ ] **Step 14: Rodar todos os guards**

Run: `./scripts/check-assets.sh && ./scripts/check-canon.sh && ./scripts/eval.sh`
Expected: sem drift; `check-canon: limpo`; `eval: tudo verde`. Se `check-canon` acusar `script-sem-doc`, o Step 11 não bateu o basename.

- [ ] **Step 15: Commit**

```bash
git add scripts/check-delegacao.sh scripts/test-check-delegacao.sh \
        scripts/fixtures/delegacao-clean.md scripts/fixtures/delegacao-dirty.md \
        scripts/eval.sh scripts/asset-map.sh \
        docs/architecture.md docs/prd.md docs/guias/avaliacao-harness.md \
        skills/*/references/check-delegacao.sh
git commit -m "feat(delegacao): gate check-delegacao.sh + auto-teste e fixtures (NFR-04)"
```
Expected: commit criado; hooks passam.

---

## Task 3: ADR-017 + canonização da PRD (a decisão estruturante)

Registra a decisão estruturante como ADR-017 (ao lado do ADR-007, **sem** supersedê-lo), indexa-o na §2 do `architecture.md`, e canoniza a PRD: RF-20 novo (§6/E1), restrição (§8), linha §12 (RF-20) e changelog (§13, cenário C1). Deliverable revisável: a governança/canon.

**Files:**
- Create: `docs/adr/ADR-017-delegacao-criativa-classificada.md`
- Modify: `docs/architecture.md` (§2 índice)
- Modify: `docs/prd.md` (§6, §8, §12, §13)

**Interfaces:**
- Consumes: `assets/delegacao-criativa.md` e `scripts/check-delegacao.sh` (já commitados) como artefatos que RF-20/§12 apontam.
- Produces: `ADR-017` (referenciado pela §8 e pelo §13 da PRD, e pelo índice §2 da arquitetura); `RF-20` na §6/E1.

- [ ] **Step 1: Criar o ADR-017**

Create `docs/adr/ADR-017-delegacao-criativa-classificada.md` (padrão do `/zion-adr-new`, modo *decisão dada* — o dono escolheu a Alt D no estudo; a Evidência aponta o estudo e o design, um caminho com `.md`, que o `check-adr.sh` reconhece):

```markdown
# ADR-017 — Classificação diagnóstica×propositiva na delegação criativa ao brainstorming

- **Status:** Aceito
- **Data:** 2026-07-19
- **Decisores:** autoria do repo
- **Evidência:** Decisão dada: o dono do harness escolheu a alternativa D (ROI 4.0) no estudo `docs/estudos/discovery-delegacao-brainstorming.md`; o design que a formaliza é `docs/superpowers/specs/2026-07-19-delegacao-criativa-classificada-design.md`.

## Contexto

Três estágios criativos — discovery, write, decompose — delegam a clarificação ao
`superpowers:brainstorming` sob o contrato de capacidades C1–C3 (ADR-007). A análise-mãe
(`zion-mermaid-editor-app/docs/analise-brainstorming-no-fluxo-zion.md`) mostra que, no **modo
retomar/revisar**, essa clarificação degrada: o Autor recebe perguntas **diagnósticas** ("qual dos
seus fatos é o verdadeiro?") em vez de **propositivas** ("escolha entre estes desenhos"), sem
recomendação e sem preview que ilustre a escolha. A causa-raiz não é falha da skill — ela roda e
cumpre o contrato —, é que a **natureza da pergunta** chega errada: o harness delega e pré-resolve
ao mesmo tempo, entregando as tensões já redigidas como pergunta. No modo do-zero a delegação é até
melhor que o brainstorming avulso; o defeito é localizado no modo revisar e em write/decompose.

## Decisão

A delegação criativa **classifica cada tensão** — diagnóstica ou propositiva — numa rubrica de
**fonte única** (`assets/delegacao-criativa.md`, sincronizada para as três skills), e **gateia o
prompt montado** por `check-delegacao.sh` (marcadores greppados: a distinção, propositiva→2–3
abordagens+recomendação, os dois previews, a condução), que aconselha (`RN-01`). A liberação do
preview conceitual fica **escopada à delegação** (mora no asset), com o `#fronteira` global de
`quality-rules.md` intacto — specify/PRD seguem com tela banida. Descartadas: declarar uma
capacidade C4 e gatear o **marcador externo** do superpowers (Alt C) — gateia a coisa errada (que o
marcador existe na skill instalada, não que o *nosso* prompt pede) e aumenta o acoplamento; e editar
o `#fronteira` global (opção B da fronteira). O contrato externo **C1–C3 (ADR-007) não é tocado nem
substituído**.

## Consequências

O drift da correção passa a ser pego no **nosso** prompt (as três `SKILL.md`), fechando o modo de
falha "a correção só no prompt regride na próxima reescrita" sem crescer o acoplamento com o
superpowers (`NFR-02` intacto). O harness ganha um asset, um script (`check-delegacao.sh`,
distribuído) e um auto-teste (`test-check-delegacao.sh`, dev-workflow, agregado pelo `eval.sh`). O
**limite honesto**, na mesma candura da Consequência do ADR-007: o gate confirma que o prompt
**pede** a distinção; **não** confirma que o agente classificou certo cada tensão, que nada foi
pré-mastigado, nem que a experiência melhorou — isso segue julgamento, coberto só na camada LLM
(ADR-008). A condução ("crie uma tarefa por passo") é prompt, não mecanismo: efeito declarado como
limite, não promessa. Nenhum ADR vigente é revertido — ADR-007 é honrado, não tocado.

## Status

Aceito.
```

- [ ] **Step 2: Validar o ADR pelo guard de ADRs**

Run: `./scripts/check-adr.sh docs/adr`
Expected: `check-adr: limpo` (a Evidência começa com `Decisão dada:` e tem racional → passa; sem supersessão a declarar).

- [ ] **Step 3: Indexar o ADR-017 na §2 do `architecture.md`**

Edit `docs/architecture.md`, seção `## 2. Decisões estruturantes (ADRs)`, tabela de ADRs. Adicione ao fim da tabela (após a linha do ADR-016):
```markdown
| [ADR-017](adr/ADR-017-delegacao-criativa-classificada.md) | A delegação criativa classifica cada tensão (diagnóstica/propositiva) numa rubrica de fonte única e gateia o prompt montado por `check-delegacao.sh`, sem tocar o contrato externo C1–C3. |
```
Isto satisfaz o `check_adr_index` (C5) do `check-canon.sh` (greppa o basename `ADR-017-delegacao-criativa-classificada.md`).

- [ ] **Step 4: RF-20 novo na §6 (épico E1) da PRD**

Edit `docs/prd.md`, seção `## 6. Requisitos funcionais por épico (RF-xx)`, dentro do bullet do **Épico E1** (o parágrafo que já contém RF-01…RF-05, RF-17). Acrescente ao fim desse bullet, antes do começo do bullet do Épico E2:

```markdown
`RF-20` Nos estágios que delegam a clarificação, a tensão que admite desenho vira 2–3 abordagens com recomendação e preview que ilustra a escolha, não pergunta diagnóstica; o prompt de delegação montado é verificado por máquina.
```

(Fica sob o Épico E1, então o `check_rf` do dogfood não acusa `rf-fora-de-epico`. O texto não contém termo da denylist nem versão `x.y.z` nem bloco de código.)

- [ ] **Step 5: Restrição ADR-017 na §8 da PRD**

Edit `docs/prd.md`, seção `## 8. Restrições (das decisões de arquitetura)`. Na frase "Em especial: …", que hoje termina em "… e a skill de estudo workflow-adaptativa por persona (ADR-013).", acrescente antes do ponto final:
```markdown
, e a classificação diagnóstica×propositiva na delegação criativa ao brainstorming (ADR-017)
```
(O `check_restricao_morta` só acusa restrição apontando ADR **substituído**; ADR-017 não é.)

- [ ] **Step 6: Linha do RF-20 na §12 da PRD**

Edit `docs/prd.md`, seção `## 12. Rastreabilidade`. Adicione a linha (junto aos demais RF de E1, após a linha do RF-17):
```markdown
| RF-20 | E1 | assets/delegacao-criativa.md |
```
(O gate `scripts/check-delegacao.sh` já entrou na §12 sob RF-11 na Task 2; o RF-20 aponta a rubrica, sua casa de fonte única. As três skills que realizam o comportamento já são rastreadas por RF-01/04/05.)

- [ ] **Step 7: Changelog na §13 da PRD (cenário C1)**

Edit `docs/prd.md`, seção `## 13. Histórico de mudanças`, tabela. Adicione a linha:
```markdown
| 2026-07-19 | C1 | `RF-20` novo: delegação criativa classifica a tensão (diagnóstica/propositiva) e gateia o prompt montado | no modo revisar a clarificação degradava para pergunta diagnóstica sem recomendação nem preview | ADR-017 · assets/delegacao-criativa.md · scripts/check-delegacao.sh · skills/zion-prd-discovery · skills/zion-prd-write · skills/zion-prd-decompose |
```
(O `check_changelog` valida: Cenário ∈ {C1,C2,C3} → `C1` ✓; todo `RF-xx` citado existe na §6 → `RF-20` ✓ (Step 4); todo `ADR-xxx` citado existe em `docs/adr/` → `ADR-017` ✓ (Step 1). As referências `skills/...` citadas existem no disco → `check_prd_skills_exist` não acusa.)

- [ ] **Step 8: Rodar o dogfood da PRD e os guards**

Run: `./scripts/check-prd.sh prd docs/prd.md`
Expected: `check-prd: limpo` (exit 0). Se acusar `changelog-rf-inexistente` para RF-20, o Step 4 não gravou; se `rf-fora-de-epico`, RF-20 caiu fora do bullet do E1.

Run: `./scripts/check-canon.sh && ./scripts/check-adr.sh docs/adr`
Expected: `check-canon: limpo` e `check-adr: limpo`.

- [ ] **Step 9: Commit**

```bash
git add docs/adr/ADR-017-delegacao-criativa-classificada.md docs/architecture.md docs/prd.md
git commit -m "docs(canon): ADR-017 + RF-20 da delegação criativa classificada"
```
Expected: commit criado; hooks passam.

---

## Task 4: Costurar a fase de delegação nas três skills

Adiciona, em cada `SKILL.md`, o passo de delegação classificada — enumerar tensões como observações, classificar, montar o bloco, autoverificar com `check-delegacao.sh`, e só então invocar o brainstorming. Na `discovery`, a linha de supressão de preview (ramo surface=sim) passa a referenciar a rubrica em vez do banimento em bloco. Deliverable revisável: a prosa das skills.

**Files:**
- Modify: `skills/zion-prd-discovery/SKILL.md`
- Modify: `skills/zion-prd-write/SKILL.md`
- Modify: `skills/zion-prd-decompose/SKILL.md`

**Interfaces:**
- Consumes: `references/delegacao-criativa.md` e `references/check-delegacao.sh` (sincronizados nas Tasks 1–2), e o comportamento canonizado por RF-20 (Task 3).
- Produces: nenhum artefato novo; muda o comportamento das Fases de delegação. (Não há check de máquina sobre o texto das skills — o `check-canon` não cruza RF-20 com prosa de skill; a fidelidade é dever de quem edita, CLAUDE.md.)

- [ ] **Step 1: discovery — inserir o passo de delegação classificada**

Edit `skills/zion-prd-discovery/SKILL.md`, seção `## Fase 2/3 — Formatar e auto-delegar`. Insira o parágrafo abaixo **imediatamente antes** da frase existente "Invoque `superpowers:brainstorming` no mesmo turno. O enquadramento ramifica pelo modo detectado / na Fase 0:" (isto é, entre o parágrafo de Preflight e essa frase):

```markdown
**Delegação classificada (guiada por `references/delegacao-criativa.md`).** Antes de invocar, no
mesmo turno: (1) leia `docs/discovery.md` e **enumere as tensões como observações** suas — nunca já
redigidas como pergunta; (2) **classifique cada tensão** diagnóstica/propositiva pela rubrica;
(3) **monte o bloco de delegação** = as observações classificadas + a rubrica (distinção, dois
previews, condução); (4) **autoverifique** o bloco montado —
`printf '%s' "<bloco>" | bash references/check-delegacao.sh -` — e ecoe o veredito (aconselha,
`RN-01`); marcador ausente → corrija o bloco antes de delegar; (5) passe o bloco como `args` na
invocação abaixo.

```

- [ ] **Step 2: discovery — a supressão de preview passa a referenciar a rubrica**

Edit `skills/zion-prd-discovery/SKILL.md`, no ramo do Modo do-zero surface=sim. Substitua o trecho:

```markdown
percebe X"), nunca "tela Y". Grave em `docs/discovery.md` a **linha bare** `Superfície de uso: sim`
```

por:

```markdown
percebe X"). Para previews, siga a regra dos dois previews de `references/delegacao-criativa.md` — ilustrar a escolha é liberado, desenhar tela fica no `plan.md`. Grave em `docs/discovery.md` a **linha bare** `Superfície de uso: sim`
```

- [ ] **Step 3: write — inserir o passo de delegação classificada**

Edit `skills/zion-prd-write/SKILL.md`, seção `## Fase 3 — Auto-delegar`. Insira o parágrafo abaixo **imediatamente antes** da frase existente "Invoque `superpowers:brainstorming` no mesmo turno para preencher `docs/PRD.md` **seção a seção**, a / partir de `docs/discovery.md` + `docs/adr/`.":

```markdown
**Delegação classificada (guiada por `references/delegacao-criativa.md`).** Antes de invocar, no
mesmo turno: (1) leia `docs/discovery.md` + `docs/adr/` e **enumere as tensões como observações**
suas — nunca já redigidas como pergunta; (2) **classifique cada tensão** diagnóstica/propositiva
pela rubrica; (3) **monte o bloco de delegação** = as observações classificadas + a rubrica
(distinção, dois previews, condução); (4) **autoverifique** o bloco montado —
`printf '%s' "<bloco>" | bash references/check-delegacao.sh -` — e ecoe o veredito (aconselha,
`RN-01`); marcador ausente → corrija o bloco antes de delegar; (5) passe o bloco como `args` na
invocação abaixo.

```

- [ ] **Step 4: decompose — inserir o passo de delegação classificada**

Edit `skills/zion-prd-decompose/SKILL.md`, seção `## Fase 2/3 — Formatar e auto-delegar`. Insira o parágrafo abaixo **imediatamente antes** da frase existente "Invoque `superpowers:brainstorming` no mesmo turno para: (1) agrupar os `RF-xx` em épicos;":

```markdown
**Delegação classificada (guiada por `references/delegacao-criativa.md`).** Antes de invocar, no
mesmo turno: (1) leia `docs/PRD.md` e **enumere as tensões como observações** suas — nunca já
redigidas como pergunta; (2) **classifique cada tensão** diagnóstica/propositiva pela rubrica;
(3) **monte o bloco de delegação** = as observações classificadas + a rubrica (distinção, dois
previews, condução); (4) **autoverifique** o bloco montado —
`printf '%s' "<bloco>" | bash references/check-delegacao.sh -` — e ecoe o veredito (aconselha,
`RN-01`); marcador ausente → corrija o bloco antes de delegar; (5) passe o bloco como `args` na
invocação abaixo.

```

- [ ] **Step 5: Verificar que as três skills referenciam a rubrica e o gate**

Run:
```bash
for s in discovery write decompose; do
  f="skills/zion-prd-$s/SKILL.md"
  grep -q 'references/delegacao-criativa.md' "$f" \
    && grep -q 'references/check-delegacao.sh' "$f" \
    && echo "OK $s" || echo "FALTA em $s"
done
```
Expected: `OK discovery`, `OK write`, `OK decompose`.

- [ ] **Step 6: Rodar os guards (nada de canon deve quebrar)**

Run: `./scripts/check-canon.sh && ./scripts/check-assets.sh`
Expected: `check-canon: limpo` e sem drift (as skills já são citadas na PRD; editar prosa não muda canon).

- [ ] **Step 7: Commit**

```bash
git add skills/zion-prd-discovery/SKILL.md skills/zion-prd-write/SKILL.md skills/zion-prd-decompose/SKILL.md
git commit -m "feat(delegacao): fase de delegação classificada em discovery/write/decompose"
```
Expected: commit criado; hooks passam.

---

## Task 5: Fixture de julgamento (camada LLM)

Adiciona uma fixture da camada de julgamento (ADR-008): uma pergunta em **modo revisar** cuja resposta esperada carrega a distinção diagnóstica×propositiva, exercitando a **fase de delegação** (Fase 2/3) e não a Fase 4. Indexada no roteiro `avaliacao-harness.md`. Deliverable revisável: o caso de avaliação.

**Files:**
- Create: `scripts/fixtures/skills/discovery/revisar-propositiva/discovery.md`
- Create: `scripts/fixtures/skills/discovery/revisar-propositiva/esperado.md`
- Modify: `docs/guias/avaliacao-harness.md` (§4 tabela LLM + nota)

**Interfaces:**
- Consumes: a rubrica (`references/delegacao-criativa.md`) e o gate (`references/check-delegacao.sh`) que a skill discovery agora usa (Task 4).
- Produces: par de fixtures no contrato `esperado.md` (frontmatter `skill`/`fase`/`regra`/`defeito`/`veredito`/`achado_esperado`), consumível pelo runner por agentes de `avaliacao-harness.md`.

- [ ] **Step 1: Criar o insumo da fixture**

Create `scripts/fixtures/skills/discovery/revisar-propositiva/discovery.md`:

```markdown
# Discovery — App de anotações rápidas (revisar)

## Visão
Capturar uma ideia em segundos e reencontrá-la sem esforço.

## Persona
Marina, consultora que anota entre reuniões e revisita as notas no fim do dia.

## Faz / Não faz
- **Faz:** captura rápida; busca por texto.
- **Não faz:** não sincroniza com serviços de terceiros; não edita colaborativo.

## Tensões abertas (para revisar)
- O produto deve priorizar o **primeiro acesso** (onboarding) ou o **uso recorrente** (Marina já
  fisgada)? O texto do discovery afirma os dois em lugares diferentes.
- Como Marina **entra na tarefa-núcleo** de capturar uma nota — isso ainda não está desenhado e
  admite mais de um caminho.

Superfície de uso: sim

## Experiência
Marina percebe que capturou a ideia sem perder o fio da conversa; a nota some da frente e reaparece
quando ela procura.
```

- [ ] **Step 2: Criar o sidecar `esperado.md`**

Create `scripts/fixtures/skills/discovery/revisar-propositiva/esperado.md`:

```markdown
---
skill: zion-prd-discovery
fase: "2/3"
regra: "references/delegacao-criativa.md"
defeito: modo revisar propenso a pergunta diagnóstica sem recomendação nem preview
veredito: carrega a distinção
achado_esperado:
  - enumera as duas tensões como observações do harness, não como perguntas prontas
  - classifica a tensão que admite desenho (entrada da tarefa-núcleo) como propositiva — 2–3 abordagens + recomendação + preview que ilustra a escolha
  - trata a ambiguidade de intenção (primeiro acesso × uso recorrente) como diagnóstica — pergunta simples, sem recomendação nem preview
  - a autoverificação (check-delegacao.sh) sai limpa sobre o bloco montado
---
## Defeito plantado
No modo revisar, o discovery já tem visão/persona sólidas mas duas tensões abertas: uma **de
intenção** (qual momento de uso servir primeiro — diagnóstica) e uma **de desenho** (como Marina
entra na tarefa-núcleo — propositiva). A degradação típica é o harness entregar as duas ao
brainstorming já redigidas como pergunta diagnóstica, sem recomendação nem preview.

## Como reconhecer o acerto
A fase de delegação enumera as duas como observações classificadas: a de intenção como
**diagnóstica** (pergunta simples, sem recomendação) e a de desenho como **propositiva** (2–3
abordagens + recomendação + preview que ilustra a escolha), e o `check-delegacao.sh` sai limpo sobre
o bloco montado. Um falso-negativo é despejar as duas como perguntas diagnósticas pré-mastigadas; um
falso-positivo é forçar recomendação na tensão de intenção, onde não há o que recomendar.
```

- [ ] **Step 3: Indexar a fixture no roteiro de avaliação**

Edit `docs/guias/avaliacao-harness.md`, §4, tabela "LLM (camada de julgamento — sob demanda)". Adicione, junto às linhas de `discovery`:
```markdown
| discovery | revisar-propositiva | discovery.md | modo revisar propenso a pergunta diagnóstica sem recomendação nem preview | carrega a distinção |
```
E, logo após a tabela LLM (junto da nota que já existe sobre o `evolve`), adicione a nota:
```markdown
> A fixture `revisar-propositiva` testa a **fase de delegação** (Fase 2/3), não a Fase 4: a lente é
> o fluxo enumerar → classificar → montar o bloco de `references/delegacao-criativa.md`, e o acerto
> é o bloco carregar a distinção diagnóstica×propositiva (o `check-delegacao.sh` sai limpo sobre ele).
> O campo `fase` do `esperado.md` é `2/3` e `veredito` carrega "carrega a distinção".
```

- [ ] **Step 4: Sanidade do sidecar e dos guards**

Run:
```bash
head -8 scripts/fixtures/skills/discovery/revisar-propositiva/esperado.md
./scripts/check-canon.sh
```
Expected: o frontmatter mostra `skill`, `fase`, `regra`, `veredito` preenchidos (um `esperado.md` sem `veredito` é erro de suíte); `check-canon: limpo`.

- [ ] **Step 5: Commit**

```bash
git add scripts/fixtures/skills/discovery/revisar-propositiva/ docs/guias/avaliacao-harness.md
git commit -m "test(delegacao): fixture de julgamento (modo revisar carrega a distinção)"
```
Expected: commit criado; hooks passam.

---

## Task 6: Verificação integral + self-review

Roda a suíte inteira que o pre-commit e o CI rodam, confirma que tudo está verde, e faz a checagem final contra o design. Não introduz artefato novo.

**Files:** nenhum (verificação).

- [ ] **Step 1: Rodar exatamente o que o CI roda**

Run:
```bash
./scripts/check-assets.sh
./scripts/eval.sh
./scripts/check-canon.sh
./scripts/check-adr.sh docs/adr
```
Expected: sem drift; `eval: tudo verde` (inclui `=== eval: delegacao ===`); `check-canon: limpo`; `check-adr: limpo`. São os quatro passos do `.github/workflows/check-assets.yml`.

- [ ] **Step 2: Conferir a autocontenção das três skills (references sincronizados)**

Run:
```bash
for s in discovery write decompose; do
  ls "skills/zion-prd-$s/references/delegacao-criativa.md" \
     "skills/zion-prd-$s/references/check-delegacao.sh" >/dev/null \
    && echo "OK $s" || echo "FALTA $s"
done
git status --porcelain
```
Expected: `OK` para os três; `git status` limpo (o pre-commit já regenerou e commitou os derivados — nenhum drift pendente).

- [ ] **Step 3: Cobertura do design (self-review contra o spec)**

Confira cada entregável do design (`docs/superpowers/specs/2026-07-19-delegacao-criativa-classificada-design.md`, seção "Entregáveis") contra o que foi feito:

1. `assets/delegacao-criativa.md` + `ASSET_MAP` + sync p/ 3 skills — Task 1 ✓
2. `scripts/check-delegacao.sh` (stdin, marcadores, exit) + reference — Task 2 ✓
3. `scripts/test-check-delegacao.sh` + fixtures limpa/suja (`NFR-04`) — Task 2 ✓
4. 3 × `SKILL.md` (materializar + self-check + invocar; discovery referencia a rubrica na supressão de preview) — Task 4 ✓
5. `docs/adr/ADR-017-*.md` — Task 3 ✓
6. Canonização: `prd.md` (§6 RF-20, §8, §12, §13) e `architecture.md` (§2, §3, §4) — Tasks 1/2/3 ✓
7. Fixture de julgamento (modo revisar → resposta carrega a distinção) no roteiro de `avaliacao-harness.md` — Task 5 ✓

Confirme também os **Fora de escopo** do design (nenhum tocado): contrato C1–C3 / C4 **intacto**; `#fronteira` global de `quality-rules.md` **não editado**; nenhuma promessa de mecanismo para a condução ou para "a experiência melhorou".

Run (fronteira global intacta — não deve ter mudado nesta jornada):
```bash
git log --oneline -1 -- assets/quality-rules.md
git log --oneline -6
```
Expected: `assets/quality-rules.md` **não** aparece entre os commits desta jornada; os cinco commits das Tasks 1–5 estão presentes.

- [ ] **Step 4: Finalização da branch**

Use `superpowers:finishing-a-development-branch` para decidir merge/PR/cleanup. Antes de qualquer merge, reconfirme o Step 1 verde.

---

## Self-Review (do autor do plano)

**1. Cobertura do spec:** cada entregável do design mapeia a uma task (ver Task 6 Step 3). Escopo (E7/E9/E10) honrado: alcance nos três estágios (Task 4), gate no prompt montado e não no marcador externo (Task 2), fronteira escopada ao asset (Task 1) com `#fronteira` global intacto (Task 6 Step 3). Canonização completa: RF-20/§8/§12/§13 + ADR-017 §2 + §3 + §4 (Tasks 1–3).

**2. Placeholders:** nenhum "TBD"/"handle edge cases" — o asset, o gate, o auto-teste, as fixtures, o ADR e as edições de canon estão com conteúdo completo e comandos com saída esperada.

**3. Consistência de tipos/nomes:** o gate expõe `check-delegacao.sh <arquivo|->` (Task 2), invocado pelas skills como `bash references/check-delegacao.sh -` (Task 4) e pelo auto-teste como `bash "$CHECK" "$FIX/..."` e via stdin (Task 2); os achados `distincao-ausente`/`propositiva-incompleta`/`previews-ausente`/`conducao-ausente` batem entre o gate (Step 5), o auto-teste (Step 3) e o índice do guia (Step 13). O nome `delegacao` é o mesmo em `eval.sh` (TESTS/ORDER/case/usage). Os marcadores greppados pelo gate existem no asset (verificado na Task 1 Step 3) e nas fixtures.

**4. Ordem canon-limpa:** cada commit sai verde no pre-commit — o asset é citado na §4 antes de commitar (T1); os scripts entram na §3 no mesmo commit que os cria (T2); o ADR-017 é indexado na §2 e a §13 só o cita depois de existir (T3); o RF-20 existe na §6 antes do §13 citá-lo (T3). Todo ponteiro de §12 resolve para artefato já existente no momento do commit.
