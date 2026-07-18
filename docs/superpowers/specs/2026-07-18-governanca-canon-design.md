# Design — governança do zion-build-prd por si mesmo (canon)

**Data:** 2026-07-18 · **Status:** aprovado

## Problema

O repo governa a *distribuição* (assets → references, drift-guard, CI), mas não governa a si
mesmo como **produto**: não há documento que diga o que o harness faz/não-faz (requisitos) nem
um que consolide a arquitetura adotada. Agents que abrem o repo para escrever specs/planos não
têm fonte da verdade a ler, e mudanças de comportamento não têm para onde ser canonizadas.

## Decisões fechadas (brainstorming)

- **[DECIDIR-1] Dogfood total.** `docs/prd.md` usa o próprio `assets/templates/prd-skeleton.md`
  (§1–§13), com zero stack — e `check-prd.sh prd docs/prd.md` roda limpo. Bash/grep/markdown são
  "como" e vivem no `architecture.md`.
- **[DECIDIR-2] Manter + reorganizar.** `avaliacao-harness.md`, `como-usar.md` e
  `guia-prd-para-spec-kit.md` movem (git mv) para `docs/guias/`, intocados exceto por nota curta
  no topo apontando a governança para prd.md/architecture.md. Nada é deletado. Só
  prd.md + architecture.md são fonte da verdade de governança.
- **[DECIDIR-3] Consolidar + criar `docs/adr/`.** O repo não tem ADRs; o histórico vive em
  `docs/superpowers/specs/`. O `architecture.md` consolida as decisões estruturantes já tomadas
  como D-01…D-0n (uma linha + link para o design doc — não reescreve, não reabre) e cria
  `docs/adr/` com README para decisões futuras via `/zion-adr-new` (dogfood).
- **[check-canon] Inventário cruzado + dogfood.** Sem guard de canonização por toque de arquivo
  (atrito); o elo é estrutural e decidível.

## Fase A — fontes da verdade

### `docs/prd.md`

Segue o esqueleto seção a seção. Pontos que o formato do `check-prd.sh` impõe:

- Cabeçalhos `## N. Título` (o parser lê `$2` de `^## `).
- **Nenhum bloco de código** (todo ``` é achado de stack), nenhum termo da denylist, nenhum
  padrão `x.y.z` de versão.
- §6: todo `RF-xx` sob uma linha `**Épico E# — nome:**`; RF fora da §6 só em tabela.
- §7: todo item de NFR com dígito.

Épicos da §6: **E1** Jornada de autoria (discovery, spike, write, decompose) · **E2** Pontes
Spec Kit (constitution/specify/plan-prompt) · **E3** Rastreabilidade (trace) · **E4** Dia 2
(evolve, adr-new) · **E5** Qualidade mecânica (checks, eval, fixtures) · **E6** Distribuição
(dois canais, autocontenção, preflight de dependência).

§8 aponta para as decisões D-xx do `architecture.md` e futuros ADRs. **§12 é a tabela
RF → épico → artefato (`skills/...`, `scripts/...`)** — o elo legível por máquina que o
`check-canon.sh` cruza. §13 nasce vazia (dia 1).

### `docs/architecture.md`

O "como" do harness, consolidado:

1. **Visão** — skills autocontidas (SKILL.md + `references/` derivados); `assets/` fonte única;
   verificadores shell advisory-nos-alvos / blocking-no-repo; hooks versionados + CI backstop;
   distribuição dual; contrato superpowers (C1–C3) com check de drift.
2. **Decisões consolidadas D-01…D-0n** — uma linha por decisão estruturante já tomada, com link
   para o design doc de origem em `docs/superpowers/specs/`. Não reabre decisão.
3. **Índice de ADRs** — `docs/adr/` (novo, README explicando quando um ADR nasce aqui via
   `/zion-adr-new`); o índice lista todo `ADR-*.md` existente (vazio no dia 1).
4. **Tabela de scripts** — todo `scripts/*.sh` com papel de uma linha (o check C3 cruza).
5. **Regra de canonização** — o que muda ⇒ onde reflete.

## Fase B — regra raiz

`CLAUDE.md` na raiz (arquivo real) + `AGENTS.md` symlink → `CLAUDE.md`. Conteúdo:

1. **Fontes da verdade:** `docs/prd.md` (o-quê/por-quê) e `docs/architecture.md` (como/com-quê)
   — leitura obrigatória antes de escrever qualquer spec/plano neste repo.
2. **Dever de canonização:** toda mudança de comportamento/estrutura reflete de volta nesses
   docs **no mesmo commit** (novo skill/script ⇒ RF na prd.md + linha no architecture.md; ADR
   novo ⇒ índice). `check-canon.sh` acusa o esquecimento.
3. **Regras operacionais existentes:** nunca editar `skills/*/references/` (derivados de
   `assets/`); rodar `./scripts/setup-hooks.sh` após clonar; fronteira o-quê/como
   (`assets/quality-rules.md#fronteira`) vale para os próprios docs.

## Fase C — enforcement mecânico

### `scripts/check-canon.sh`

Contrato dos irmãos: exit 0 limpo / 1 achados / 2 erro de uso; achados no formato
`arquivo: codigo — mensagem`. Uso: `check-canon.sh [ROOT]` (default: raiz do repo) — o ROOT
opcional torna o script testável contra fixtures.

| # | Achado | Regra decidível |
|---|--------|-----------------|
| C1 | `skill-sem-rf` | dir em `skills/` não citado em `docs/prd.md` |
| C2 | `skill-fantasma` | `skills/<nome>` citado na prd.md que não existe no disco |
| C3 | `script-sem-doc` | `scripts/*.sh` (top-level) não citado em `docs/architecture.md` |
| C4 | `asset-sem-doc` | fonte do `ASSET_MAP` não citada em `docs/architecture.md` |
| C5 | `adr-sem-indice` | `docs/adr/ADR-*.md` não citado no architecture.md |
| C6 | `regra-raiz-sem-sot` | `CLAUDE.md` ausente ou não cita ambos os docs de governança |
| C7 | *(dogfood)* | delega a `check-prd.sh prd docs/prd.md` e propaga achados |

C4 lê o `ASSET_MAP` via `source scripts/asset-map.sh` do ROOT; se o ROOT de fixture não tiver
asset-map, o check degrada em silêncio (como o `check-prd.sh` faz com `docs/adr/`).

### TDD e fixtures

`scripts/test-check-canon.sh` + `scripts/fixtures/canon/{clean,dirty}/` escritos **antes** da
lógica (padrão `test-check-prd.sh`). `clean/` = mini-árvore consistente; `dirty/` = defeitos
plantados cobrindo cada achado C1–C6 (C7 coberto pela própria suíte do check-prd).

### Plugagem

- `eval.sh`: entrada `[canon]="scripts/test-check-canon.sh"` + `canon` no `ORDER`/usage.
- `.githooks/pre-commit`: roda `./scripts/check-canon.sh` **após** o sync; drift ⇒ commit
  bloqueado (diferente dos gates dos projetos-alvo, que só aconselham — aqui é o repo
  guardando a si mesmo, mesmo rigor do CI de assets).
- CI (`check-assets.yml`): passo `./scripts/check-canon.sh` como backstop.
- `check-canon.sh` **não** entra no `ASSET_MAP` — governa este repo, não é distribuído.

## Reorganização

`git mv docs/{avaliacao-harness,como-usar,guia-prd-para-spec-kit}.md docs/guias/` + nota de
2 linhas no topo de cada um. Os três só se citam entre si (por nome, mesmo dir) — nenhum outro
arquivo do repo os referencia; a movimentação não quebra link. README: seção Desenvolvimento
ganha a canonização e os novos caminhos.

## Fora de escopo

Nenhuma feature de produto nova; nenhuma dependência nova; nenhuma edição em
`skills/*/references/` (à mão); nenhuma decisão passada reaberta.

## Critérios de aceite (verificação)

1. `docs/prd.md` e `docs/architecture.md` existem; `CLAUDE.md` os declara como SoT.
2. `bash scripts/test-check-canon.sh` verde; `./scripts/eval.sh` verde (inclui canon).
3. `./scripts/check-canon.sh` e `./scripts/check-assets.sh` limpos no repo real.
4. `check-prd.sh prd docs/prd.md` limpo (dogfood).
5. Commit de teste violando a canonização (ex.: skill nova sem RF) é **bloqueado** pelo
   pre-commit; após reverter, commit passa.
