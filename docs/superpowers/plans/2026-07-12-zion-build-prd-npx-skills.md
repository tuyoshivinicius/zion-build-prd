# Zion Build PRD — Empacotamento `npx skills` — Plano de Implementação

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Recriar o produto harness-prd em `~/projects/personal/zion-build-prd`, renomeado para **Zion Build PRD**, empacotado no padrão comunitário `npx skills` (skills.sh), preservando o histórico git completo e as specs de desenvolvimento.

**Architecture:** Clonar o repo atual (histórico completo) para o novo diretório; reestruturar para o layout flat do skills.sh (`skills/<name>/SKILL.md`); tornar cada skill autocontida copiando os assets canônicos (`assets/`) para o `references/` de cada skill via script, com um guard de drift; reescrever os caminhos nos SKILL.md; renomear o produto; adicionar README/LICENSE/marketplace.json; validar; e (com confirmação) criar/pushar o repo GitHub novo.

**Tech Stack:** git, bash (scripts POSIX), Markdown, JSON (Claude Code plugin manifests), `npx skills` (skills.sh).

**Referência:** `docs/superpowers/specs/2026-07-12-zion-build-prd-npx-skills-design.md`

**Convenção:** Todos os comandos assumem, salvo indicação, que o CWD é o repositório novo `~/projects/personal/zion-build-prd`. `SRC` refere o repo de origem `~/projects/personal/zion-mermaid-editor`.

---

### Task 1: Clonar o repo de origem com histórico completo

**Files:**
- Create: `~/projects/personal/zion-build-prd/` (populado pelo clone)

- [ ] **Step 1: Confirmar que o diretório alvo existe e está vazio**

Run: `ls -A ~/projects/personal/zion-build-prd`
Expected: sem saída (diretório vazio). Se houver conteúdo, PARAR e reportar.

- [ ] **Step 2: Confirmar que a spec e este plano estão commitados na origem**

Run: `git -C ~/projects/personal/zion-mermaid-editor status --porcelain docs/superpowers`
Expected: sem saída (specs/planos já commitados). Se houver pendências em `docs/superpowers`, commitá-las antes de clonar para que entrem no clone.

- [ ] **Step 3: Clonar a origem local para dentro do diretório alvo**

Run:
```bash
git clone ~/projects/personal/zion-mermaid-editor ~/projects/personal/zion-build-prd
```
Expected: `Cloning into ... done.` (o clone popula o diretório vazio existente).

- [ ] **Step 4: Verificar que o histórico completo veio junto**

Run: `git -C ~/projects/personal/zion-build-prd log --oneline | wc -l`
Expected: um número > 15 (todos os commits preservados).

- [ ] **Step 5: Remover o remote de origem (evita push acidental para zion-mermaid-editor)**

Run:
```bash
cd ~/projects/personal/zion-build-prd && git remote remove origin && git remote -v
```
Expected: sem saída em `git remote -v` (nenhum remote). O remote novo será configurado na Task 11, com confirmação.

- [ ] **Step 6: Criar branch de trabalho da migração**

Run: `cd ~/projects/personal/zion-build-prd && git switch -c feat/npx-skills-packaging`
Expected: `Switched to a new branch 'feat/npx-skills-packaging'`.

---

### Task 2: Promover os assets do Spec Kit para `assets/` canônico

**Files:**
- Create: `assets/quality-rules.md` (de `.specify/prd/quality-rules.md`)
- Create: `assets/templates/prd-skeleton.md` (de `.specify/prd/templates/prd-skeleton.md`)
- Create: `assets/templates/traceability-table.md` (de `.specify/prd/templates/traceability-table.md`)

- [ ] **Step 1: Criar a estrutura de assets e mover com histórico**

Run:
```bash
cd ~/projects/personal/zion-build-prd
mkdir -p assets/templates
git mv .specify/prd/quality-rules.md assets/quality-rules.md
git mv .specify/prd/templates/prd-skeleton.md assets/templates/prd-skeleton.md
git mv .specify/prd/templates/traceability-table.md assets/templates/traceability-table.md
```
Expected: sem erros (git mv preserva histórico de cada arquivo).

- [ ] **Step 2: Verificar que os 3 assets existem no novo lugar**

Run: `ls assets assets/templates`
Expected: `assets/` contém `quality-rules.md` e `templates/`; `assets/templates/` contém `prd-skeleton.md` e `traceability-table.md`.

- [ ] **Step 3: Commit**

```bash
git add -A && git commit -m "refactor(assets): promover quality-rules e templates da PRD para assets/ canônico"
```

---

### Task 3: Mover as 7 skills do harness para `skills/` e remover o que sai de escopo

**Files:**
- Create: `skills/{zion-prd-discovery,zion-prd-spike,zion-prd-write,zion-prd-decompose,zion-prd-constitution-prompt,zion-prd-specify-prompt,zion-adr-new}/`
- Delete: `.claude/skills/speckit-*` (fora de escopo — Spec Kit é instalado à parte)
- Delete: `.specify/` (scaffolding do Spec Kit; assets já promovidos na Task 2)
- Delete: `docs/index.md` (artefato de dogfood "Zion Mermaid Editor"; permanece no histórico)

- [ ] **Step 1: Criar `skills/` e mover as 7 pastas de skill preservando histórico**

Run:
```bash
cd ~/projects/personal/zion-build-prd
mkdir -p skills
for s in zion-prd-discovery zion-prd-spike zion-prd-write zion-prd-decompose zion-prd-constitution-prompt zion-prd-specify-prompt zion-adr-new; do
  git mv ".claude/skills/$s" "skills/$s"
done
```
Expected: sem erros; as 7 pastas agora em `skills/`.

- [ ] **Step 2: Verificar que exatamente 7 SKILL.md estão sob `skills/`**

Run: `find skills -name SKILL.md | wc -l`
Expected: `7`

- [ ] **Step 3: Remover as skills fora de escopo e o scaffolding do Spec Kit**

Run:
```bash
git rm -r .claude/skills          # sobra só o speckit-* aqui; as 7 já saíram
git rm -r .specify
git rm docs/index.md
```
Expected: git lista os arquivos removidos, sem erro.

- [ ] **Step 4: Confirmar que não sobrou nenhum vestígio de Spec Kit vendorizado**

Run: `ls .specify .claude/skills 2>/dev/null; find . -path ./.git -prune -o -name 'SKILL.md' -print | grep -c speckit`
Expected: os dois `ls` falham (não existem) e o `grep -c speckit` retorna `0`.

- [ ] **Step 5: Commit**

```bash
git add -A && git commit -m "refactor(skills): mover 7 skills do harness para skills/ e remover Spec Kit vendorizado"
```

---

### Task 4: Escrever os scripts de sincronização e guard de drift

**Files:**
- Create: `scripts/sync-assets.sh`
- Create: `scripts/check-assets.sh`

- [ ] **Step 1: Escrever `scripts/sync-assets.sh`**

Conteúdo exato de `scripts/sync-assets.sh`:
```bash
#!/usr/bin/env bash
# Copia os assets canônicos de assets/ para o references/ de cada skill que os consome.
# Fonte única de verdade: assets/. Rode este script após editar qualquer asset.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

QR="assets/quality-rules.md"
SKELETON="assets/templates/prd-skeleton.md"
TRACE="assets/templates/traceability-table.md"

# quality-rules.md → todas as skills prd-* que a citam
for s in zion-prd-discovery zion-prd-spike zion-prd-write zion-prd-decompose zion-prd-constitution-prompt zion-prd-specify-prompt; do
  mkdir -p "skills/$s/references"
  cp "$QR" "skills/$s/references/quality-rules.md"
done

# templates específicos por skill
mkdir -p skills/zion-prd-write/references skills/zion-prd-decompose/references
cp "$SKELETON" "skills/zion-prd-write/references/prd-skeleton.md"
cp "$TRACE" "skills/zion-prd-decompose/references/traceability-table.md"

echo "sync-assets: ok"
```

- [ ] **Step 2: Escrever `scripts/check-assets.sh`**

Conteúdo exato de `scripts/check-assets.sh`:
```bash
#!/usr/bin/env bash
# Falha se qualquer references/ de skill divergir do asset canônico em assets/.
# Guard contra drift silencioso da autocontenção.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

fail=0
check() { # $1=canônico  $2=cópia na skill
  if ! diff -q "$1" "$2" >/dev/null 2>&1; then
    echo "DRIFT: $2 difere de $1"
    fail=1
  fi
}

for s in zion-prd-discovery zion-prd-spike zion-prd-write zion-prd-decompose zion-prd-constitution-prompt zion-prd-specify-prompt; do
  check "assets/quality-rules.md" "skills/$s/references/quality-rules.md"
done
check "assets/templates/prd-skeleton.md" "skills/zion-prd-write/references/prd-skeleton.md"
check "assets/templates/traceability-table.md" "skills/zion-prd-decompose/references/traceability-table.md"

if [ "$fail" -eq 0 ]; then
  echo "check-assets: sem drift"
else
  echo "check-assets: FALHOU — rode scripts/sync-assets.sh"
  exit 1
fi
```

- [ ] **Step 3: Tornar os scripts executáveis**

Run: `cd ~/projects/personal/zion-build-prd && chmod +x scripts/sync-assets.sh scripts/check-assets.sh`
Expected: sem saída.

- [ ] **Step 4: Verificar sintaxe bash dos dois scripts**

Run: `bash -n scripts/sync-assets.sh && bash -n scripts/check-assets.sh && echo "sintaxe ok"`
Expected: `sintaxe ok`

- [ ] **Step 5: Commit**

```bash
git add scripts/sync-assets.sh scripts/check-assets.sh
git commit -m "build(scripts): sync-assets e check-assets para skills autocontidas"
```

---

### Task 5: Popular os `references/` das skills e provar o guard de drift

**Files:**
- Create: `skills/*/references/*.md` (gerados pelo sync)

- [ ] **Step 1: Rodar o sync**

Run: `cd ~/projects/personal/zion-build-prd && ./scripts/sync-assets.sh`
Expected: `sync-assets: ok`

- [ ] **Step 2: Conferir os arquivos gerados**

Run: `find skills -path '*/references/*' -name '*.md' | sort`
Expected exatamente 8 linhas:
```
skills/zion-prd-constitution-prompt/references/quality-rules.md
skills/zion-prd-decompose/references/quality-rules.md
skills/zion-prd-decompose/references/traceability-table.md
skills/zion-prd-discovery/references/quality-rules.md
skills/zion-prd-specify-prompt/references/quality-rules.md
skills/zion-prd-spike/references/quality-rules.md
skills/zion-prd-write/references/prd-skeleton.md
skills/zion-prd-write/references/quality-rules.md
```

- [ ] **Step 3: Provar que o check passa sem drift**

Run: `./scripts/check-assets.sh`
Expected: `check-assets: sem drift`

- [ ] **Step 4: Provar que o check DETECTA drift (teste negativo)**

Run:
```bash
printf '\n<!-- drift proposital -->\n' >> skills/zion-prd-discovery/references/quality-rules.md
./scripts/check-assets.sh; echo "exit=$?"
```
Expected: linha `DRIFT: skills/zion-prd-discovery/references/quality-rules.md difere de assets/quality-rules.md`, depois `check-assets: FALHOU ...` e `exit=1`.

- [ ] **Step 5: Restaurar via sync e reconfirmar**

Run: `./scripts/sync-assets.sh && ./scripts/check-assets.sh`
Expected: `sync-assets: ok` seguido de `check-assets: sem drift`.

- [ ] **Step 6: Commit**

```bash
git add skills
git commit -m "feat(skills): popular references/ com assets canônicos (autocontenção)"
```

---

### Task 6: Reescrever os caminhos `.specify/prd/…` nos SKILL.md

**Files:**
- Modify: `skills/zion-prd-discovery/SKILL.md:14`
- Modify: `skills/zion-prd-spike/SKILL.md:14`
- Modify: `skills/zion-prd-write/SKILL.md:14,27`
- Modify: `skills/zion-prd-decompose/SKILL.md:14,34`
- Modify: `skills/zion-prd-constitution-prompt/SKILL.md:15`
- Modify: `skills/zion-prd-specify-prompt/SKILL.md:14`

- [ ] **Step 1: Substituir os caminhos em todos os SKILL.md que os citam**

Run:
```bash
cd ~/projects/personal/zion-build-prd
grep -rl '\.specify/prd/' skills/ | while read -r f; do
  sed -i \
    -e 's#\.specify/prd/templates/prd-skeleton\.md#references/prd-skeleton.md#g' \
    -e 's#\.specify/prd/templates/traceability-table\.md#references/traceability-table.md#g' \
    -e 's#\.specify/prd/quality-rules\.md#references/quality-rules.md#g' \
    "$f"
done
```
Expected: sem saída (sucesso).

- [ ] **Step 2: Guard — nenhuma referência `.specify/prd` pode sobrar nas skills**

Run: `grep -rn '\.specify/prd' skills/ || echo "GUARD OK: zero referencias .specify/prd"`
Expected: `GUARD OK: zero referencias .specify/prd`

- [ ] **Step 3: Conferir que as novas referências relativas apareceram**

Run: `grep -rn 'references/' skills/*/SKILL.md`
Expected: linhas em zion-prd-discovery, zion-prd-spike, zion-prd-write (2x: quality-rules e prd-skeleton), zion-prd-decompose (2x: quality-rules e traceability-table), zion-prd-constitution-prompt, zion-prd-specify-prompt — todas apontando para `references/…`.

- [ ] **Step 4: Commit**

```bash
git add skills
git commit -m "fix(skills): apontar referencias para references/ local (pós-instalação npx skills)"
```

---

### Task 7: Renomear o produto para "Zion Build PRD"

**Files:**
- Modify: `skills/{zion-prd-discovery,zion-prd-spike,zion-prd-write,zion-prd-decompose,zion-prd-constitution-prompt,zion-prd-specify-prompt,zion-adr-new}/SKILL.md:6` (linha `author:`)

- [ ] **Step 1: Renomear `metadata.author` nas 7 skills**

Run:
```bash
cd ~/projects/personal/zion-build-prd
sed -i 's/author: zion-mermaid-editor/author: zion-build-prd/' skills/*/SKILL.md
```
Expected: sem saída.

- [ ] **Step 2: Guard — nenhum `zion-mermaid-editor` remanescente nas skills**

Run: `grep -rn 'zion-mermaid-editor' skills/ || echo "GUARD OK: skills sem referencia ao nome antigo"`
Expected: `GUARD OK: skills sem referencia ao nome antigo`

- [ ] **Step 3: Confirmar o novo author**

Run: `grep -rc 'author: zion-build-prd' skills/*/SKILL.md | grep -c ':1'`
Expected: `7`

- [ ] **Step 4: Commit**

```bash
git add skills
git commit -m "chore(skills): metadata.author -> zion-build-prd"
```

---

### Task 8: Adicionar README, LICENSE e manifests de plugin

**Files:**
- Create: `README.md`
- Create: `LICENSE`
- Create: `.claude-plugin/marketplace.json`
- Create: `.claude-plugin/plugin.json`

- [ ] **Step 1: Escrever `README.md`**

Conteúdo exato de `README.md`:
```markdown
# Zion Build PRD

Harness multi-agente para **autoria de PRDs** que faz a ponte para o
[GitHub Spec Kit](https://github.com/github/spec-kit). Conduz a jornada em estágios —
descoberta → spike/ADRs → PRD → decomposição → pontes para o `/speckit.*` — guardando
sempre a fronteira **o-quê × como**.

## Instalação

Via [skills.sh](https://skills.sh):

```bash
npx skills add tuyoshivinicius/zion-build-prd
```

Isso instala as skills em `.claude/skills/` do seu projeto. Elas são **autocontidas**:
cada uma carrega em `references/` os assets (regras de qualidade, templates) de que precisa.

> As pontes `/zion-prd-constitution-prompt` e `/zion-prd-specify-prompt` **montam prompts** para o
> `/speckit.constitution` e `/speckit.specify`. Instale o **Spec Kit** separadamente para
> rodar o ciclo `/speckit.*`.

Alternativa (Claude Code plugin marketplace):

```
/plugin marketplace add tuyoshivinicius/zion-build-prd
/plugin install zion-build-prd@zion-build-prd
```

## As skills

| Skill | Estágio |
|-------|---------|
| `/zion-prd-discovery` | Descoberta enxuta → `docs/discovery.md` |
| `/zion-prd-spike` | Pesquisa de trade-offs + ADRs |
| `/zion-prd-write` | Preenche a PRD a partir do esqueleto |
| `/zion-prd-decompose` | Épicos, story map, fatias verticais, rastreabilidade |
| `/zion-prd-constitution-prompt` | Ponte → `/speckit.constitution` |
| `/zion-prd-specify-prompt` | Ponte → `/speckit.specify` |
| `/zion-adr-new` | Cria um ADR em `docs/adr/` |

## Desenvolvimento

Os assets canônicos vivem em `assets/`. Após editá-los, rode:

```bash
./scripts/sync-assets.sh   # copia assets/ → references/ de cada skill
./scripts/check-assets.sh  # falha se algum references/ divergir
```

O histórico de design está em `docs/superpowers/`.

## Licença

MIT — veja [LICENSE](LICENSE).
```

- [ ] **Step 2: Escrever `LICENSE` (MIT)**

Conteúdo exato de `LICENSE`:
```
MIT License

Copyright (c) 2026 Tuyoshi Vinicius

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

- [ ] **Step 3: Escrever `.claude-plugin/plugin.json`**

Run: `mkdir -p ~/projects/personal/zion-build-prd/.claude-plugin`

Conteúdo exato de `.claude-plugin/plugin.json`:
```json
{
  "name": "zion-build-prd",
  "version": "1.0.0",
  "description": "Harness multi-agente para autoria de PRDs, com ponte para o GitHub Spec Kit.",
  "author": { "name": "Tuyoshi Vinicius" }
}
```

- [ ] **Step 4: Escrever `.claude-plugin/marketplace.json`**

Conteúdo exato de `.claude-plugin/marketplace.json`:
```json
{
  "name": "zion-build-prd",
  "owner": { "name": "Tuyoshi Vinicius" },
  "plugins": [
    {
      "name": "zion-build-prd",
      "source": "./",
      "description": "Harness multi-agente para autoria de PRDs, com ponte para o GitHub Spec Kit."
    }
  ]
}
```

- [ ] **Step 5: Validar o JSON dos dois manifests**

Run:
```bash
cd ~/projects/personal/zion-build-prd
python3 -m json.tool .claude-plugin/plugin.json >/dev/null && python3 -m json.tool .claude-plugin/marketplace.json >/dev/null && echo "json ok"
```
Expected: `json ok`

- [ ] **Step 6: Commit**

```bash
git add README.md LICENSE .claude-plugin
git commit -m "docs(pkg): README, LICENSE (MIT) e manifests de plugin"
```

---

### Task 9: Atualizar os guias do harness (nomenclatura + instalação)

**Files:**
- Rename+Modify: `docs/como-usar-o-harness-prd.md` → `docs/como-usar.md`
- Modify: `docs/guia-prd-para-spec-kit.md`

- [ ] **Step 1: Renomear o guia principal preservando histórico**

Run: `cd ~/projects/personal/zion-build-prd && git mv docs/como-usar-o-harness-prd.md docs/como-usar.md`
Expected: sem saída.

- [ ] **Step 2: Ver as ocorrências do nome antigo nos dois guias**

Run: `grep -rni 'harness.prd\|harness prd\|zion-mermaid-editor' docs/como-usar.md docs/guia-prd-para-spec-kit.md`
Expected: uma lista de linhas a revisar (referências textuais a "harness PRD"/"harness-prd").

- [ ] **Step 3: Substituir a nomenclatura do produto nos dois guias**

Run:
```bash
cd ~/projects/personal/zion-build-prd
sed -i \
  -e 's/harness-prd/zion-build-prd/g' \
  -e 's/harness PRD/Zion Build PRD/g' \
  -e 's/Harness PRD/Zion Build PRD/g' \
  docs/como-usar.md docs/guia-prd-para-spec-kit.md
```
Expected: sem saída.

- [ ] **Step 4: Ler `docs/como-usar.md` e ajustar manualmente o que o sed não cobriu**

Ler o arquivo inteiro. Garantir que: (a) o título e a introdução digam "Zion Build PRD"; (b) exista uma seção de instalação citando `npx skills add tuyoshivinicius/zion-build-prd`; (c) menções ao `.specify/prd/…` como caminho de assets sejam ajustadas para `assets/`/`references/` quando descreverem o novo layout; (d) a contagem de comandos e os nomes `/prd-*` continuem corretos. Editar com a ferramenta Edit onde necessário (sem sed cego para prosa).

- [ ] **Step 5: Guard — sem resquícios do nome antigo nos guias**

Run: `grep -rni 'harness.prd\|zion-mermaid-editor' docs/como-usar.md docs/guia-prd-para-spec-kit.md || echo "GUARD OK: guias renomeados"`
Expected: `GUARD OK: guias renomeados`

- [ ] **Step 6: Commit**

```bash
git add docs/como-usar.md docs/guia-prd-para-spec-kit.md
git commit -m "docs(guias): renomear para Zion Build PRD e citar instalacao via npx skills"
```

---

### Task 10: Validação final do pacote

**Files:** (nenhuma modificação — apenas verificação)

- [ ] **Step 1: Frontmatter — toda SKILL.md tem `name` e `description`**

Run:
```bash
cd ~/projects/personal/zion-build-prd
miss=0
for f in skills/*/SKILL.md; do
  grep -qm1 '^name:' "$f" && grep -qm1 '^description:' "$f" || { echo "FALTA name/description: $f"; miss=1; }
done
[ "$miss" -eq 0 ] && echo "frontmatter ok (7/7)"
```
Expected: `frontmatter ok (7/7)`

- [ ] **Step 2: Assets sem drift**

Run: `./scripts/check-assets.sh`
Expected: `check-assets: sem drift`

- [ ] **Step 3: Guard `.specify/prd` — zero referências nas skills**

Run: `grep -rn '\.specify/prd' skills/ || echo "GUARD OK"`
Expected: `GUARD OK`

- [ ] **Step 4: Estrutura skills.sh — exatamente 7 skills no layout flat**

Run:
```bash
cd ~/projects/personal/zion-build-prd
n=$(find skills -maxdepth 2 -name SKILL.md | wc -l)
echo "skills=$n"; [ "$n" -eq 7 ] && echo "layout flat ok"
```
Expected: `skills=7` e `layout flat ok`

- [ ] **Step 5: Árvore final (inspeção visual)**

Run: `find . -path ./.git -prune -o -type f -print | grep -v '^\./\.git' | sort`
Expected: presença de `README.md`, `LICENSE`, `.claude-plugin/marketplace.json`, `.claude-plugin/plugin.json`, `assets/…`, `scripts/…`, `skills/<7>/…` (com `references/`), `docs/como-usar.md`, `docs/guia-prd-para-spec-kit.md`, `docs/superpowers/{specs,plans}/…`; ausência de `.specify`, `docs/index.md` e qualquer `speckit-*`.

- [ ] **Step 6: Working tree limpo**

Run: `git status --porcelain`
Expected: sem saída (tudo commitado).

---

### Task 11: Publicar o repositório GitHub novo ⚠️ (ação externa — confirmar)

> **GATE:** Este é o único passo outward-facing. NÃO executar sem confirmação explícita do usuário. Apresentar os comandos, confirmar nome/visibilidade do repo, e só então rodar.

**Files:** (nenhuma — operação de git/GitHub)

- [ ] **Step 1: Confirmar com o usuário**

Perguntar: criar `github.com/tuyoshivinicius/zion-build-prd` (público, exigido para `npx skills add`)? Confirmar visibilidade. Aguardar "sim".

- [ ] **Step 2: Criar o repo remoto e pushar (após confirmação)**

Run:
```bash
cd ~/projects/personal/zion-build-prd
gh repo create tuyoshivinicius/zion-build-prd --public --source=. --remote=origin --description "Harness multi-agente para autoria de PRDs, com ponte para o Spec Kit — instale via npx skills."
git push -u origin feat/npx-skills-packaging
```
Expected: repo criado; branch pushado.

- [ ] **Step 3: Abrir PR (ou mergear para main conforme preferência do usuário)**

Perguntar ao usuário: abrir PR de `feat/npx-skills-packaging` → `master`, ou mergear direto? Executar a opção escolhida.

- [ ] **Step 4: Provar o caminho de instalação real (pós-push)**

Run: `npx -y skills add tuyoshivinicius/zion-build-prd --help >/dev/null 2>&1; npx -y skills find zion-build-prd`
Expected: o CLI resolve o repo e lista as skills sob `skills/`. (Se o subcomando/flag divergir na versão do CLI, ajustar conforme `npx skills --help`.)

---

## Notas de execução

- **DRY/fonte única:** `assets/` é a verdade; `references/` são cópias geradas. Nunca editar `references/` à mão — editar `assets/` e rodar `sync-assets.sh`.
- **Nomes das slash-commands preservados** (`/prd-*`, `/zion-adr-new`) — só o produto foi renomeado.
- **Spec Kit fora de escopo:** consumidores instalam o Spec Kit separadamente; as pontes só emitem prompts.
- **Histórico:** preservado via `git mv` (arquivos) e clone completo (commits). As specs/planos em `docs/superpowers/` viajam no clone.
