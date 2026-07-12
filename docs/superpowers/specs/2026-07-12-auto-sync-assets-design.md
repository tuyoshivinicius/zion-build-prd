# Auto-sync de assets canônicos

**Data:** 2026-07-12
**Estágio:** design (brainstorming)

## Problema

Os assets canônicos vivem em `assets/`. Cada skill é **autocontida**: carrega em
`skills/<skill>/references/` uma cópia dos assets que consome. Hoje, após editar
qualquer asset, o desenvolvedor precisa rodar **manualmente**:

```bash
./scripts/sync-assets.sh   # copia assets/ → references/ de cada skill
./scripts/check-assets.sh  # falha se algum references/ divergir
```

Esse passo manual é fácil de esquecer e gera drift silencioso.

## Objetivo

Eliminar a necessidade de o desenvolvedor sincronizar os assets à mão. Preferência
por **1 arquivo único**; se inviável tecnicamente, **duplicação automática**.

## Veredicto de viabilidade: por que não é 1 arquivo

As skills são distribuídas por **dois canais**:

- **Canal A — `npx skills add`:** copia **cada pasta de skill isoladamente** para
  `.claude/skills/<skill>/`. Assumimos o pior caso (**cópia literal**, sem
  dereferência de symlink).
- **Canal B — plugin do Claude Code:** o repositório inteiro está presente sob um
  plugin root.

No canal A, qualquer arquivo que aponte para **fora** da pasta da skill quebra:

- Um **symlink** `references/quality-rules.md → ../../../assets/quality-rules.md`
  apontaria para nada após a cópia isolada.
- Um **arquivo gitignorado** gerado só em publish-time não existiria, pois o
  skills.sh consome o repositório git diretamente.

Portanto **cada `references/*.md` precisa ser um arquivo real, commitado**. Não há
como manter um único arquivo físico na árvore versionada. Honramos o objetivo de
"fonte única de verdade" **no espírito**: `assets/` é a única fonte editável e
`references/` passa a ser **artefato derivado gerado automaticamente**.

## Design

### 1. Princípio — canônico × derivado

- `assets/` = **único lugar** que um humano edita.
- `skills/*/references/*.md` = **saída gerada**, byte-idêntica ao canônico. Sem
  banner "generated" (quebraria o `diff` do check). Documentado como derivado no
  README (seção Desenvolvimento).

### 2. Manifesto único — `scripts/asset-map.sh` (sourced)

Hoje a lista de skills está **duplicada** em `sync-assets.sh` e `check-assets.sh`.
Extrair o mapeamento asset→skills para um arquivo único, **sourced** por ambos os
scripts (e pelo hook). Adicionar uma skill nova passa a ser **1 edição**.

```bash
# scripts/asset-map.sh
# Fonte única do mapeamento: asset canônico → skills que o consomem.
# Sourced por sync-assets.sh e check-assets.sh. NÃO executar diretamente.
#
# Cada entrada: "CAMINHO_CANONICO_RELATIVO_A_ROOT  skill1 skill2 ..."
# A cópia vai para skills/<skill>/references/<basename do canônico>.
ASSET_MAP=(
  "assets/quality-rules.md                prd-discovery prd-spike prd-write prd-decompose prd-constitution-prompt prd-specify-prompt"
  "assets/templates/prd-skeleton.md       prd-write"
  "assets/templates/traceability-table.md prd-decompose"
)
```

`sync-assets.sh` e `check-assets.sh` passam a iterar sobre `ASSET_MAP`:

- **sync:** para cada entrada, `src` = primeiro campo, skills = restante;
  `dest = skills/<skill>/references/<basename src>`; `mkdir -p` + `cp`.
- **check:** mesma iteração, `diff -q src dest`; acumula falha e sai `1` com a
  mensagem acionável existente.

### 3. Pre-commit hook — o gatilho

- Hook versionado em `.githooks/pre-commit`, ativado por
  `git config core.hooksPath .githooks`.
- **Bootstrap:** `scripts/setup-hooks.sh` (roda o `git config` acima; idempotente)
  + instrução no README. O CI é o backstop se alguém não rodar o bootstrap.
- **Lógica do hook:**
  1. Roda `scripts/sync-assets.sh` (só `cp`, barato → **incondicional**).
  2. `git add skills/*/references/` — o commit já sai consistente.
  3. `set -euo pipefail`: se o sync falhar, o commit é **abortado** (nunca commita
     estado quebrado).
- `cp` de arquivo idêntico e `git add` de arquivo inalterado são **no-op** — commits
  que não tocam `assets/` não ganham ruído.

### 4. CI guard — defesa em profundidade

- GitHub Action (`.github/workflows/check-assets.yml`) em `push` e `pull_request`
  roda `scripts/check-assets.sh`.
- Pega: quem deu `git commit --no-verify`, quem nunca rodou o bootstrap, ou
  contribuidor externo. Falha com a mensagem acionável já existente
  (`rode scripts/sync-assets.sh`).
- `check-assets.sh` permanece essencialmente como está (só passa a usar o manifesto).

## Escopo — YAGNI

**Fora de escopo:** watcher de editor, geração em publish-time, tooling novo além de
bash + um workflow YAML.

## Verificação

1. `scripts/check-assets.sh` roda limpo logo após um `sync`.
2. Editar `assets/quality-rules.md` + `git commit` → hook regenera e faz **stage**
   dos 6 references, **sem passo manual**; o commit inclui tudo.
3. Commit que **não toca** `assets/` → hook não adiciona nada (no-op).
4. `git commit --no-verify` com drift → **CI falha** corretamente.
5. Contribuidor sem bootstrap (hooksPath não setado) com drift → **CI falha**.
6. Adicionar uma skill nova ao `ASSET_MAP` → sync e check a cobrem sem editar dois
   lugares.

## Arquivos afetados

| Arquivo | Ação |
|---|---|
| `scripts/asset-map.sh` | **novo** — manifesto sourced |
| `scripts/sync-assets.sh` | refatorar para iterar `ASSET_MAP` |
| `scripts/check-assets.sh` | refatorar para iterar `ASSET_MAP` |
| `.githooks/pre-commit` | **novo** — roda sync + `git add` |
| `scripts/setup-hooks.sh` | **novo** — bootstrap do `core.hooksPath` |
| `.github/workflows/check-assets.yml` | **novo** — CI guard |
| `README.md` | atualizar seção Desenvolvimento (bootstrap + references derivados) |
