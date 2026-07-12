# Design — Rebranding das skills com prefixo `zion-`

- **Data:** 2026-07-12
- **Autor:** Tuyoshi Vinicius
- **Estágio:** Brainstorming → design aprovado

## Objetivo

Renomear as **8 skills internas** do Zion Build PRD adicionando o prefixo `zion-`
(ex.: `prd-discovery` → `zion-prd-discovery`) e refletir a mudança de forma harmônica e
orgânica em todos os guias, assets, scripts e no histórico de design do projeto. A
"recriação" usa a metodologia do **skill-creator** como reescrita disciplinada de cada
`SKILL.md`, **preservando a semântica de processo** já validada.

## Decisões (aprovadas no brainstorming)

1. **Escopo:** todas as **8** skills recebem o prefixo (inclui `adr-new` e a utilitária
   genérica `rewrite-prompt`).
2. **Reescrita:** aplicar a metodologia do skill-creator (description mais "pushy" com
   "quando usar", estrutura imperativa, progressive disclosure) **mantendo como invariantes
   fixos** o contrato de 5 fases, os gates que *aconselham sem bloquear*, os *preflights* de
   dependência e a **guarda de fronteira o-quê/como**. Forma reescrita, semântica preservada.
3. **Histórico:** atualizar o **conteúdo** (tokens de skill) de `docs/superpowers/specs/` e
   `plans/`, mas **manter os nomes de arquivo** intactos (a identidade do registro é
   data+tema; renomear quebra links sem agregar).

## Nomes finais

| Antes | Depois |
|---|---|
| `prd-discovery` | `zion-prd-discovery` |
| `prd-spike` | `zion-prd-spike` |
| `prd-write` | `zion-prd-write` |
| `prd-decompose` | `zion-prd-decompose` |
| `prd-constitution-prompt` | `zion-prd-constitution-prompt` |
| `prd-specify-prompt` | `zion-prd-specify-prompt` |
| `adr-new` | `zion-adr-new` |
| `rewrite-prompt` | `zion-rewrite-prompt` |

**NÃO renomeados** (fora do território do harness): `superpowers:brainstorming` (externo),
`deep-research` (built-in do Claude Code), `/speckit.*` (Spec Kit), e o nome do
**plugin/marketplace** `zion-build-prd` (já é a marca — permanece).

## Camadas de mudança

### a) Diretórios das skills
`git mv skills/<nome> skills/zion-<nome>` para as 8 skills (preserva histórico; a pasta
`references/` viaja junto).

### b) Corpo de cada `SKILL.md`
Três eixos de edição por arquivo, sob o guardrail de preservar semântica:
- `name:` no frontmatter → `zion-<nome>`.
- Título H1 (`# prd-discovery — …` → `# zion-prd-discovery — …`).
- Referências cruzadas internas e exemplos de auto-invocação (ver grafo abaixo).
- Passe skill-creator na `description` e na estrutura, sem alterar as fases/gates/fronteira.

Grafo de referências cruzadas a atualizar (apenas tokens do harness):

| Skill | Referencia internamente |
|---|---|
| `zion-prd-discovery` | `zion-prd-spike`, `zion-prd-write` |
| `zion-prd-spike` | `zion-prd-discovery`, invoca `zion-adr-new` |
| `zion-prd-write` | `zion-prd-discovery`, `zion-prd-spike`, `zion-prd-decompose` |
| `zion-prd-decompose` | `zion-prd-write`, `zion-prd-specify-prompt` |
| `zion-prd-constitution-prompt` | `zion-prd-write`, `zion-prd-decompose`, invoca `zion-rewrite-prompt` |
| `zion-prd-specify-prompt` | `zion-prd-decompose`, invoca `zion-rewrite-prompt` |
| `zion-adr-new` | exemplo `/zion-adr-new "..."` |
| `zion-rewrite-prompt` | `/zion-rewrite-prompt` |

### c) Assets canônicos (`assets/`)
- `assets/process-context.md` — 7 referências (todas as skills do harness).
- `assets/templates/prd-skeleton.md` — 1 referência (`/prd-decompose`).
- `assets/quality-rules.md` e `assets/templates/traceability-table.md` — nenhuma; não mudam.

### d) `scripts/asset-map.sh`
Atualizar os nomes de skill no manifesto `ASSET_MAP` para `zion-*` (o destino das cópias
passa a ser `skills/zion-*/references/`).

### e) `skills/*/references/*.md` (derivados)
**Não editar à mão.** Regenerados por `./scripts/sync-assets.sh` a partir de (c)+(d).

### f) Guias vivos
- `README.md` — tabela de skills, tabela de dependências, exemplos de comando.
- `docs/guia-prd-para-spec-kit.md` — 9 ocorrências.
- `docs/como-usar.md` — 41 ocorrências.

### g) Histórico `docs/superpowers/`
Atualizar o **conteúdo** (tokens de skill) de todos os specs/plans que citam skills;
**manter nomes de arquivo**. Já contém `zion-build-prd` (nome do plugin) — não duplo-prefixar.

### h) `.claude-plugin/*.json`
Nome do plugin permanece `zion-build-prd`; não há lista de skills ali. **Sem mudança.**

## Riscos e mitigação

- **Falso-positivo de substituição:** `zion-build-prd` contém `prd`; `prd-spike-descoberta`
  contém `prd-spike`. Mitigação: substituir apenas os **8 tokens exatos** com *negative
  lookbehind* de `zion-` (nunca duplo-prefixa) e boundaries adequados — jamais `sed` cego.
  Preferir edição arquivo a arquivo com verificação, não replace global irrestrito.
- **Não tocar tokens externos:** `superpowers`, `deep-research`, `speckit`, e o nome do
  plugin/marketplace `zion-build-prd` ficam intactos.
- **Drift assets ↔ references:** após editar (c)+(d), rodar `sync-assets.sh` e então
  `check-assets.sh` (deve passar limpo).

## Validação final

1. `./scripts/sync-assets.sh` regenera os `references/`.
2. `./scripts/check-assets.sh` passa verde (sem drift).
3. Grep confirma **zero** tokens de skill sem prefixo remanescentes (fora de `zion-build-prd`
   e dos `zion-*` legítimos).
4. Inspeção manual de que `superpowers` / `deep-research` / nome-do-plugin permaneceram.
5. As 8 pastas `skills/zion-*/` existem e cada `SKILL.md` tem `name:` coerente com a pasta.

## Fora de escopo

- Alterar a semântica de processo de qualquer skill (fases, gates, fronteira).
- Renomear o plugin/marketplace ou dependências externas.
- Renomear arquivos do histórico de design.
