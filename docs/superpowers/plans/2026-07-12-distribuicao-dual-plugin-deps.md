# Distribuição dual (npx skills + plugin Claude Code) com garantia de dependências — Plano de Implementação

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Entregar o repositório `zion-build-prd` em dois formatos simultâneos (npx skills + plugin/marketplace do Claude Code) sem duplicar arquivos, com a dependência externa `superpowers` auto-instalada pelo plugin e defesa por preflight+doc no npx skills.

**Architecture:** Uma única árvore `skills/` serve os dois formatos. Vendoriza-se `zion-rewrite-prompt` como 8ª skill first-party (elimina uma dep externa). A única dep externa restante (`superpowers`) é declarada em `plugin.json` (`dependencies`) com allowlist cross-marketplace em `marketplace.json` para o formato plugin, e coberta por preflight runtime nas 3 skills que a usam + documentação no README para o formato npx skills. `deep-research` (built-in) ganha degradação graciosa no zion-prd-spike.

**Tech Stack:** Markdown (SKILL.md), JSON (manifestos de plugin/marketplace do Claude Code), bash (guards de validação), git.

**Referência:** `docs/superpowers/specs/2026-07-12-distribuicao-dual-plugin-deps-design.md`

**Convenção:** CWD = `~/projects/personal/zion-build-prd`. Branch atual: `feat/npx-skills-packaging`. Não há suíte de testes de código; a validação é por guards de `grep` e `python3 -m json.tool`, seguindo o padrão do plano anterior deste repo.

---

### Task 1: Vendorizar `zion-rewrite-prompt` como 8ª skill first-party

**Files:**
- Create: `skills/zion-rewrite-prompt/SKILL.md` (cópia verbatim do corpo, com frontmatter alinhado)

- [ ] **Step 1: Copiar o SKILL.md pessoal para dentro do repo**

Run:
```bash
cd ~/projects/personal/zion-build-prd
mkdir -p skills/zion-rewrite-prompt
cp ~/.claude/skills/zion-rewrite-prompt/SKILL.md skills/zion-rewrite-prompt/SKILL.md
```
Expected: sem saída (arquivo copiado).

- [ ] **Step 2: Alinhar o frontmatter ao padrão das outras 7 skills**

O frontmatter original do `zion-rewrite-prompt` só tem `name` + `description`. Alinhá-lo ao padrão
das skills-irmãs (adicionar bloco `metadata.author` + flags de invocação). Usar a ferramenta
Edit em `skills/zion-rewrite-prompt/SKILL.md`.

old_string (as 3 primeiras linhas do frontmatter, terminando na linha `---` de fechamento):
```
description: Reescreve um prompt informal em prompt XML estruturado (tags <role>, <context>, <instructions>, <constraints>, <output_format>, <tone>, <success_criteria>) seguindo melhores práticas de Anthropic/OpenAI/Google. Use quando o usuário invocar /zion-rewrite-prompt ou pedir para "reescrever", "reestruturar", "melhorar" ou "formalizar" um prompt. Aceita --prompt "..." (obrigatório) e --context arq1 arq2 (opcional). NUNCA executa o prompt — apenas reescreve.
---
```
new_string:
```
description: Reescreve um prompt informal em prompt XML estruturado (tags <role>, <context>, <instructions>, <constraints>, <output_format>, <tone>, <success_criteria>) seguindo melhores práticas de Anthropic/OpenAI/Google. Use quando o usuário invocar /zion-rewrite-prompt ou pedir para "reescrever", "reestruturar", "melhorar" ou "formalizar" um prompt. Aceita --prompt "..." (obrigatório) e --context arq1 arq2 (opcional). NUNCA executa o prompt — apenas reescreve.
argument-hint: "--prompt \"...\" (obrigatório) [--context arq1 arq2 ...]"
metadata:
  author: zion-build-prd
user-invocable: true
disable-model-invocation: false
---
```

- [ ] **Step 3: Guard — frontmatter válido e author alinhado**

Run:
```bash
cd ~/projects/personal/zion-build-prd
f=skills/zion-rewrite-prompt/SKILL.md
grep -qm1 '^name: zion-rewrite-prompt$' "$f" \
  && grep -qm1 '^description:' "$f" \
  && grep -qm1 '^  author: zion-build-prd$' "$f" \
  && echo "frontmatter zion-rewrite-prompt ok"
```
Expected: `frontmatter zion-rewrite-prompt ok`

- [ ] **Step 4: Guard — o corpo veio verbatim (sem perda de conteúdo)**

Compara o corpo (do cabeçalho `# Rewrite Prompt` até o fim) de ambos os arquivos, ancorado no
cabeçalho para não depender da contagem de linhas do frontmatter.

Run:
```bash
diff \
  <(sed -n '/^# Rewrite Prompt/,$p' ~/.claude/skills/zion-rewrite-prompt/SKILL.md) \
  <(sed -n '/^# Rewrite Prompt/,$p' skills/zion-rewrite-prompt/SKILL.md) \
  && echo "corpo identico ao original"
```
Expected: `corpo identico ao original` (o corpo é idêntico; apenas o frontmatter cresceu).

- [ ] **Step 5: Guard — agora são exatamente 8 skills no layout flat**

Run: `find skills -maxdepth 2 -name SKILL.md | wc -l`
Expected: `8`

- [ ] **Step 6: Commit**

```bash
git add skills/zion-rewrite-prompt/SKILL.md
git commit -m "feat(skills): vendorizar zion-rewrite-prompt como skill first-party"
```

---

### Task 2: Declarar a dependência `superpowers` nos manifestos do plugin

**Files:**
- Modify: `.claude-plugin/plugin.json` (adicionar `dependencies`)
- Modify: `.claude-plugin/marketplace.json` (adicionar `allowCrossMarketplaceDependenciesOn`)

- [ ] **Step 1: Adicionar `dependencies` ao `plugin.json`**

Editar `.claude-plugin/plugin.json` com a ferramenta Edit.

old_string:
```
{
  "name": "zion-build-prd",
  "version": "1.0.0",
  "description": "Harness multi-agente para autoria de PRDs, com ponte para o GitHub Spec Kit.",
  "author": { "name": "Tuyoshi Vinicius" }
}
```
new_string:
```
{
  "name": "zion-build-prd",
  "version": "1.0.0",
  "description": "Harness multi-agente para autoria de PRDs, com ponte para o GitHub Spec Kit.",
  "author": { "name": "Tuyoshi Vinicius" },
  "dependencies": [
    { "name": "superpowers", "marketplace": "superpowers-marketplace" }
  ]
}
```

- [ ] **Step 2: Adicionar `allowCrossMarketplaceDependenciesOn` ao `marketplace.json`**

Editar `.claude-plugin/marketplace.json` com a ferramenta Edit.

old_string:
```
{
  "name": "zion-build-prd",
  "owner": { "name": "Tuyoshi Vinicius" },
  "plugins": [
```
new_string:
```
{
  "name": "zion-build-prd",
  "owner": { "name": "Tuyoshi Vinicius" },
  "allowCrossMarketplaceDependenciesOn": ["superpowers-marketplace"],
  "plugins": [
```

- [ ] **Step 3: Validar que os dois manifestos continuam JSON bem-formado**

Run:
```bash
cd ~/projects/personal/zion-build-prd
python3 -m json.tool .claude-plugin/plugin.json >/dev/null \
  && python3 -m json.tool .claude-plugin/marketplace.json >/dev/null \
  && echo "json ok"
```
Expected: `json ok`

- [ ] **Step 4: Guard — a dependência e a allowlist estão presentes e casadas**

Run:
```bash
cd ~/projects/personal/zion-build-prd
python3 -c "import json;d=json.load(open('.claude-plugin/plugin.json'));assert any(x.get('name')=='superpowers' and x.get('marketplace')=='superpowers-marketplace' for x in d['dependencies']);print('dep superpowers ok')"
python3 -c "import json;m=json.load(open('.claude-plugin/marketplace.json'));assert 'superpowers-marketplace' in m['allowCrossMarketplaceDependenciesOn'];print('allowlist ok')"
```
Expected: `dep superpowers ok` e `allowlist ok`

- [ ] **Step 5: Commit**

```bash
git add .claude-plugin/plugin.json .claude-plugin/marketplace.json
git commit -m "feat(plugin): declarar dependencia cross-marketplace de superpowers"
```

---

### Task 3: Preflight de `superpowers` nas 3 skills que o usam

**Files:**
- Modify: `skills/zion-prd-discovery/SKILL.md` (Fase 2/3)
- Modify: `skills/zion-prd-decompose/SKILL.md` (Fase 2/3)
- Modify: `skills/zion-prd-write/SKILL.md` (Fase 3)

- [ ] **Step 1: Inserir o preflight em `zion-prd-discovery`**

Editar `skills/zion-prd-discovery/SKILL.md` com a ferramenta Edit.

old_string:
```
## Fase 2/3 — Formatar e auto-delegar
Invoque `superpowers:brainstorming` no mesmo turno, com este enquadramento fixo:
```
new_string:
```
## Fase 2/3 — Formatar e auto-delegar
**Preflight (dependência):** esta etapa exige `superpowers:brainstorming`. Se a skill não estiver
disponível, avise e pare graciosamente: "Instale o superpowers — `/plugin marketplace add
obra/superpowers-marketplace` e `/plugin install superpowers@superpowers-marketplace` — e rode de
novo." (No formato plugin ela é declarada como dependência e instala automaticamente quando o
marketplace está registrado.)

Invoque `superpowers:brainstorming` no mesmo turno, com este enquadramento fixo:
```

- [ ] **Step 2: Inserir o preflight em `zion-prd-decompose`**

Editar `skills/zion-prd-decompose/SKILL.md` com a ferramenta Edit.

old_string:
```
## Fase 2/3 — Formatar e auto-delegar
Invoque `superpowers:brainstorming` no mesmo turno para: (1) agrupar os `RF-xx` em épicos;
```
new_string:
```
## Fase 2/3 — Formatar e auto-delegar
**Preflight (dependência):** esta etapa exige `superpowers:brainstorming`. Se a skill não estiver
disponível, avise e pare graciosamente: "Instale o superpowers — `/plugin marketplace add
obra/superpowers-marketplace` e `/plugin install superpowers@superpowers-marketplace` — e rode de
novo." (No formato plugin ela é declarada como dependência e instala automaticamente quando o
marketplace está registrado.)

Invoque `superpowers:brainstorming` no mesmo turno para: (1) agrupar os `RF-xx` em épicos;
```

- [ ] **Step 3: Inserir o preflight em `zion-prd-write`**

Editar `skills/zion-prd-write/SKILL.md` com a ferramenta Edit.

old_string:
```
## Fase 3 — Auto-delegar
Invoque `superpowers:brainstorming` no mesmo turno para preencher `docs/PRD.md` **seção a seção**, a
```
new_string:
```
## Fase 3 — Auto-delegar
**Preflight (dependência):** esta etapa exige `superpowers:brainstorming`. Se a skill não estiver
disponível, avise e pare graciosamente: "Instale o superpowers — `/plugin marketplace add
obra/superpowers-marketplace` e `/plugin install superpowers@superpowers-marketplace` — e rode de
novo." (No formato plugin ela é declarada como dependência e instala automaticamente quando o
marketplace está registrado.)

Invoque `superpowers:brainstorming` no mesmo turno para preencher `docs/PRD.md` **seção a seção**, a
```

- [ ] **Step 4: Guard — as 3 skills têm o preflight; nenhuma outra tem**

Run:
```bash
cd ~/projects/personal/zion-build-prd
n=$(grep -rl 'Preflight (dependência)' skills/ | wc -l)
echo "skills com preflight: $n"
grep -rl 'Preflight (dependência)' skills/ | sort
[ "$n" -eq 3 ] && echo "preflight em 3 skills ok"
```
Expected: `skills com preflight: 3`, as três linhas `zion-prd-discovery`, `zion-prd-decompose`, `zion-prd-write`, e `preflight em 3 skills ok`.

- [ ] **Step 5: Commit**

```bash
git add skills/zion-prd-discovery/SKILL.md skills/zion-prd-decompose/SKILL.md skills/zion-prd-write/SKILL.md
git commit -m "feat(skills): preflight defensivo de superpowers nas skills que o usam"
```

---

### Task 4: Degradação graciosa de `deep-research` no `zion-prd-spike`

**Files:**
- Modify: `skills/zion-prd-spike/SKILL.md` (Fase 2/3, passo 1)

- [ ] **Step 1: Tornar a chamada a `deep-research` condicional**

Editar `skills/zion-prd-spike/SKILL.md` com a ferramenta Edit.

old_string:
```
Para cada decisão, no mesmo turno:
1. Invoque `deep-research` para levantar os trade-offs das opções (custo de manutenção, limites).
2. Invoque `zion-adr-new` com o título da decisão para registrar o ADR em `docs/adr/`.
```
new_string:
```
Para cada decisão, no mesmo turno:
1. Levante os trade-offs das opções (custo de manutenção, limites). Se a skill built-in
   `deep-research` estiver disponível, invoque-a para isso; se **não** estiver (harness antigo ou
   variante), avise "`deep-research` (built-in) indisponível — seguindo com pesquisa manual" e
   conduza o levantamento manualmente. Nunca quebre por falta dela.
2. Invoque `zion-adr-new` com o título da decisão para registrar o ADR em `docs/adr/`.
```

- [ ] **Step 2: Guard — o ramo de degradação está presente**

Run:
```bash
cd ~/projects/personal/zion-build-prd
grep -q 'pesquisa manual' skills/zion-prd-spike/SKILL.md \
  && grep -q 'deep-research` estiver disponível' skills/zion-prd-spike/SKILL.md \
  && echo "degradacao deep-research ok"
```
Expected: `degradacao deep-research ok`

- [ ] **Step 3: Commit**

```bash
git add skills/zion-prd-spike/SKILL.md
git commit -m "feat(skills): zion-prd-spike degrada graciosamente sem deep-research"
```

---

### Task 5: Documentar as dependências no README (ambos os formatos)

**Files:**
- Modify: `README.md` (nova seção `## Dependências`, entre `## As skills` e `## Desenvolvimento`)

- [ ] **Step 1: Inserir a seção `## Dependências`**

Editar `README.md` com a ferramenta Edit. Ancorar antes de `## Desenvolvimento`.

old_string:
```
## Desenvolvimento
```
new_string:
```
## Dependências

| Dependência | Usada por | De onde vem |
|-------------|-----------|-------------|
| `superpowers` (skill `superpowers:brainstorming`) | `/zion-prd-discovery`, `/zion-prd-decompose`, `/zion-prd-write` | Externa — plugin `obra/superpowers-marketplace` |
| `zion-rewrite-prompt` | `/zion-prd-constitution-prompt`, `/zion-prd-specify-prompt` | Incluída (skill first-party deste repo) |
| `deep-research` | `/zion-prd-spike` | Built-in do Claude Code (degrada para pesquisa manual se ausente) |
| `zion-adr-new` | `/zion-prd-spike` | Incluída (skill deste repo) |

A **única dependência externa** é o `superpowers`.

**Instalado via plugin do Claude Code (B):** o `superpowers` é declarado como dependência e o
Claude Code o instala **automaticamente** — desde que o marketplace dele já esteja registrado. Se
não estiver, o install para com um erro acionável; basta rodar uma vez:

```
/plugin marketplace add obra/superpowers-marketplace
```

e reinstalar. As demais dependências viajam no próprio plugin ou são built-in.

**Instalado via `npx skills` (A):** o ecossistema skills.sh **não resolve dependências**. Instale o
`superpowers` manualmente:

```
/plugin marketplace add obra/superpowers-marketplace
/plugin install superpowers@superpowers-marketplace
```

As skills que dependem dele fazem um **preflight**: se faltar, avisam com o comando de instalação e
param graciosamente em vez de quebrar no meio do fluxo.

## Desenvolvimento
```

- [ ] **Step 2: Guard — a seção existe e cita os dois formatos**

Run:
```bash
cd ~/projects/personal/zion-build-prd
grep -q '^## Dependências$' README.md \
  && grep -q 'obra/superpowers-marketplace' README.md \
  && grep -q 'não resolve dependências' README.md \
  && echo "secao dependencias ok"
```
Expected: `secao dependencias ok`

- [ ] **Step 3: Commit**

```bash
git add README.md
git commit -m "docs(readme): documentar dependencias para ambos os formatos"
```

---

### Task 6: Validação final do pacote dual

**Files:** (nenhuma modificação — apenas verificação)

- [ ] **Step 1: Exatamente 8 skills no layout flat, todas com frontmatter válido**

Run:
```bash
cd ~/projects/personal/zion-build-prd
n=$(find skills -maxdepth 2 -name SKILL.md | wc -l); echo "skills=$n"
miss=0
for f in skills/*/SKILL.md; do
  grep -qm1 '^name:' "$f" && grep -qm1 '^description:' "$f" || { echo "FALTA name/description: $f"; miss=1; }
done
[ "$n" -eq 8 ] && [ "$miss" -eq 0 ] && echo "8 skills, frontmatter ok"
```
Expected: `skills=8` e `8 skills, frontmatter ok`

- [ ] **Step 2: Manifestos válidos e dependência declarada**

Run:
```bash
cd ~/projects/personal/zion-build-prd
python3 -m json.tool .claude-plugin/plugin.json >/dev/null && python3 -m json.tool .claude-plugin/marketplace.json >/dev/null
python3 -c "import json;d=json.load(open('.claude-plugin/plugin.json'));assert any(x.get('name')=='superpowers' for x in d['dependencies'])"
python3 -c "import json;m=json.load(open('.claude-plugin/marketplace.json'));assert 'superpowers-marketplace' in m['allowCrossMarketplaceDependenciesOn']"
echo "manifestos + dep ok"
```
Expected: `manifestos + dep ok`

- [ ] **Step 3: Preflight (3) + degradação (1) presentes**

Run:
```bash
cd ~/projects/personal/zion-build-prd
[ "$(grep -rl 'Preflight (dependência)' skills/ | wc -l)" -eq 3 ] \
  && grep -q 'pesquisa manual' skills/zion-prd-spike/SKILL.md \
  && echo "guardas de dependencia ok"
```
Expected: `guardas de dependencia ok`

- [ ] **Step 4: Assets canônicos sem drift (zion-rewrite-prompt não afeta o sync)**

Run: `./scripts/check-assets.sh`
Expected: `check-assets: sem drift`

- [ ] **Step 5: README cobre dependências dos dois formatos**

Run: `grep -q '^## Dependências$' README.md && echo "readme ok"`
Expected: `readme ok`

- [ ] **Step 6: Working tree limpo**

Run: `git status --porcelain`
Expected: sem saída (tudo commitado).

---

## Notas de execução

- **Uma árvore, dois formatos:** nenhum arquivo de skill é duplicado por formato; só os manifestos
  em `.claude-plugin/` habilitam o formato plugin sobre a mesma `skills/`.
- **`superpowers` é a única dep externa:** vendorizar `zion-rewrite-prompt` e tratar `deep-research` como
  built-in reduz o problema a uma única dependência resolvível.
- **Honestidade da garantia:** a auto-instalação cross-marketplace do `superpowers` **não é
  zero-setup** — exige o marketplace registrado; senão, erro acionável (não falha silenciosa).
- **Sem mudança nos scripts de sync:** `zion-rewrite-prompt` é autocontido (um SKILL.md, sem
  `references/`), então `sync-assets.sh`/`check-assets.sh` permanecem intactos.
