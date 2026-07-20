# Design — CD por release-PR automatizado (releases por impacto)

- **Data:** 2026-07-20
- **Origem:** `docs/estudos/distribuicao-releases-cicd.md`, alternativa **B** (ROI 3,33 — líder entre as que agem; "não fazer" só ganha a aritmética por custo/risco zero).
- **Estado:** design validado em brainstorming, pronto para plano.
- **Continuidade:** honra o design `2026-07-19-releases-v1-v2` — tags anotadas + GitHub Releases,
  **um número** para os dois canais, **sem branches de release** (YAGNI), `marketplace.json`
  intocado. Este design **automatiza** aquele fluxo manual, não o revoga.

## Problema

O mantenedor libera releases à mão: edita `plugin.json.version` num commit `chore: bump` e cria a
tag (existem `v1.0.0` e `v2.0.0`), **sem CHANGELOG** e **sem um PR que documente** a mudança. Isso
preserva três riscos latentes: erro humano de versão, ausência de rastro/changelog, e divergência de
número entre os dois canais por serem editados à mão.

O candidato quer as releases **distribuídas via CI/CD**: o mantenedor continua implementando pelo SDD
leve interno (superpowers — `architecture.md §6`, `ADR-013`), e o CD **abre um PR documentando as
mudanças** e **cria tags com a versão gerada automaticamente conforme o impacto**, seguindo o SemVer
já praticado pela convenção de commits (`feat`/`fix`/`chore`…).

Brownfield: nenhuma alternativa reverte ADR vigente — todas honram a **distribuição dual por cópia
real** (`ADR-002`) e o **canon bloqueante** (`ADR-010`, `RF-13`).

## Decisões do brainstorming

Quatro decisões do Autor + uma proposta aprovada fixam o desenho (o resto é spike/plan):

1. **Fronteira (edge 9): é requisito.** A automação de release vira **RF-21 no épico E6** +
   **ADR-018** — canonizada no mesmo commit, coerente com o ethos `ADR-010`/`RF-13` de que o não
   canonizado apodrece. Não é plumbing invisível.
2. **Versionamento (edges 1, 2): Conventional Commits puro.** Fonte = os commits (o repo já pratica).
   `fix→patch`, `feat→minor`, `feat(x)!:`/footer `BREAKING CHANGE:`→major;
   `docs/test/chore/ci/refactor/style→sem release`. Major automático é seguro **porque** o gate de
   merge do release-PR confere o número calculado antes de taguear.
3. **Changelog (edge 5): `CHANGELOG.md` no root**, escrito pelo bot; o diff do changelog vive no
   próprio release-PR (é o "documentar" que o candidato pede) e a GitHub Release copia dele.
4. **Credencial (edge 10): mira B inteiro.** O Autor topa provisionar PAT fine-grained ou GitHub App
   se o spike exigir. Recuo **D** (semi-automático por dispatch) fica documentado como plano B.
5. **Proposta aprovada — commit-lint bloqueante.** Como este é o repo-harness (natureza Governança,
   que já **bloqueia** local+CI, diferente do projeto-alvo onde `RN-01` só aconselha), a disciplina de
   Conventional Commits é **guard bloqueante** (pre-commit + CI), para o cálculo de bump nunca ver
   commit fora da convenção.

## Escopo e fronteira (o-quê)

**RF-21 (épico E6 — Distribuição):** *As releases do harness são distribuídas via CI/CD por impacto:
cada merge na main atualiza um release-PR que acumula o changelog derivado dos commits e o bump SemVer
calculado; mergear o release-PR cria a tag única e publica os dois canais no mesmo número.*

Uma frase, sem stack. A **fronteira fica guardada**: o RF não cita ferramenta. Qual mecanismo
(release-please, semantic-release ou script próprio) e PAT × GitHub App vivem no **ADR-018** e no
spike, nunca na PRD (`RN-02`).

## Mecânica do release-PR

1. **Gatilho:** merge na `main`. O CD mantém **um release-PR permanente** (padrão release-please):
   acumula o changelog derivado dos commits e o bump calculado desde a última tag.
2. **Cálculo do bump** pela tabela Conventional Commits acima. Um batch só de
   `docs/test/chore/ci/refactor/style` **não abre release-PR** (PR só de docs não gera release).
3. **Mergear o release-PR = a publicação.** O merge:
   - cria a **tag anotada `vX.Y.Z`**;
   - cria a **GitHub Release** com o corpo do `CHANGELOG.md`;
   - reescreve `plugin.json.version` para o **mesmo número** — um número, dois canais (honra
     `ADR-002`; `marketplace.json` segue sem campo de versão, resolvendo por git ref).
4. **O commit de release é `chore`** (ex.: `chore(release): vX.Y.Z`) — logo é **ignorado** pelo
   cálculo do ciclo seguinte. O modelo é auto-consistente com a regra "chore→sem release".

## Ordem segura e robustez (verificável — edges 7, 8, 12)

- **Sync + guards antes de taguear.** O release-PR **passa pelo CI existente** (`check-assets.yml`:
  `check-assets` drift + `eval.sh` + `check-canon` + `check-adr`) **antes** do merge. Publicar
  derivado com drift feriria a autocontenção do `ADR-002`; o gate do PR fecha isso. É a razão técnica
  de precisarmos do PAT/App (§Credenciais): PR aberto pelo `GITHUB_TOKEN` default **não dispara**
  workflows `on: push`/`pull_request`.
- **`plugin.json.version` não é drift de canon.** Confirmado no disco: `check-canon.sh` não referencia
  `plugin.json` nem `version` — reescrever a versão não é acusado. (edge 8)
- **Idempotência/retentabilidade.** O passo de publicação checa existência de tag/Release antes de
  criar; re-rodar após falha parcial (tag criada, um canal falhou) não duplica. O padrão release-PR
  já é idempotente por reconciliar o PR a cada push. (edge 12)

## Changelog e disciplina de commit (edges 5, 11)

- **`CHANGELOG.md` no root**, derivado dos commits pelo bot; diff revisável no release-PR; a Release
  copia dele. Não viaja ao usuário (o plugin empacota só `skills/`).
- **Commit-lint bloqueante** de Conventional Commits (pre-commit + CI). Preferência por **verificador
  em shell** (molde `check-*.sh` do repo, contrato exit 0/1/2 + auto-teste com fixture — `NFR-04`),
  para não introduzir toolchain nova só pra isso; mecanismo exato é detalhe de plano.
- **Recuperação pós-erro** (tags são imutáveis): nunca reescrever tag — **corrige pra frente** (patch
  corretivo, ou novo major se a versão saiu errada). Runbook curto no README/CONTRIBUTING. (edge 11)

## Credenciais e recuo (edge 10)

- **Mira B:** provisiona **PAT fine-grained** (escopo estreito: `contents` + `pull-requests`) **ou
  GitHub App**. O **spike** decide o mínimo e **confirma que o release-PR dispara o CI** (o ponto que
  motiva a credencial). No runner do CI a credencial age direto — a nota "`gh` é abridor de browser"
  vale só no **dev local**, não no Actions.
- **Recuo D** documentado como plano B se o spike achar bloqueio de permissão intransponível: o CD
  **calcula** versão + changelog e o mantenedor **dispara** a publicação à mão — sem PR automático,
  menor superfície de permissão. Não entrega o "abrir PR", mas resolve o cálculo.

## Publicação por canal — **spike-confirm** (edge 6)

- **Hipótese:** ambos os canais resolvem por **git ref** (plugin: `marketplace.json source: "./"`;
  skills.sh: `npx skills add`), **sem registry externo**. "Publicar" = tag + Release + bump merged.
- O spike **confirma** o ponto que muda o comportamento do usuário: cada canal resolve da **tag**
  (usuário escolhe mover) ou do **HEAD da main** (merge do release-PR = rollout instantâneo)? A
  resposta afina a narrativa do RF, não a sua mecânica de bump.

## Decisão estruturante — ADR-018

**ADR-018 — "Releases por impacto via release-PR automatizado"**, via `/zion-adr-new`. Decisão nova
**ao lado** de `ADR-002`/`ADR-010`, **sem supersessão** (nenhuma referência de supersedência).
Evidência (`ADR-006`): **spike** — o risco é de execução (permissões de bot, disparo de CI no
release-PR, mecanismo de reescrita de `plugin.json.version`, resolução por canal). Registra a
convenção de versionamento (Conventional Commits + mapa de bump), o modelo release-PR, a escolha de
ferramenta e a credencial mínima. Entra no índice §2 do `architecture.md` e na restrição §8 da PRD.

## Canonização (mesmo commit — `architecture.md` §5)

| Mudança | Reflete em |
|---|---|
| Comportamento novo de distribuição | **RF-21 novo** na §6 (épico E6) de `docs/prd.md` + linha na §12 |
| Decisão estruturante | **ADR-018** em `docs/adr/` + índice §2 de `architecture.md` + restrição §8 da PRD |
| Workflow + config do mecanismo de release | `.github/workflows/release.yml` (+ config): natureza **Governança** da §6 — **não viaja** |
| Commit-lint / wrapper de release em `scripts/` | Se o spike os introduzir: **tabela de scripts §3** de `architecture.md` (o que `check-canon.sh` cruza), como artefatos de **RF-21** na §12; `check-*.sh` ganha auto-teste na §3 (`NFR-04`). Não é RF-11 — não verifica *regra de artefato*, é maquinário da release. |
| Histórico | Linha no §13 de `docs/prd.md`, cenário **C1** (RF-21 novo) |

Notas de fronteira/canon:

- **Artefato de RF-21 na §12:** `.github/workflows/release.yml` (+ config; + eventual script). Como
  `RF-14` (artefato `.claude-plugin/ · README.md`), o alvo não é obrigatoriamente um script —
  `check-canon.sh` guarda `scripts/` contra a §3, não `.github/workflows/`. Coberto e honesto.
- **`check-canon.sh` e `sync-assets.sh` não mudam de código** — genéricos; passam a cobrir os
  artefatos novos uma vez canonizados.
- **Natureza (§6):** o workflow + config de release são **Governança** (governam o harness, não
  viajam); o commit-lint `check-*.sh`, se distribuído como reference, seria **Distribuído**, e seu
  `test-*.sh` **Dev-workflow** — já cobertos pelo padrão, sem linha nova na §6.

## Entregáveis

1. `.github/workflows/release.yml` + config do mecanismo (release-PR: mantém PR, calcula bump, escreve
   `CHANGELOG.md`, no merge cria tag + Release + bump de `plugin.json.version`).
2. `CHANGELOG.md` no root (semeado; daí em diante escrito pelo bot).
3. Commit-lint bloqueante de Conventional Commits (pre-commit + CI) — preferência shell, com
   auto-teste + fixture (`NFR-04`) se virar `check-*.sh`.
4. `docs/adr/ADR-018-*.md` — a decisão estruturante, sustentada por spike.
5. Canonização: `docs/prd.md` (§6 RF-21, §12, §13 cenário C1, §8) e `docs/architecture.md` (§2, §3 se
   houver script, §6 sem linha nova).
6. Runbook curto (README/CONTRIBUTING): como declarar major (`!`/`BREAKING CHANGE:`), como corrigir
   versão pós-tag (pra frente, nunca reescrever tag).

## Verificação (fecha o loop — SDD leve interno)

1. **Spike primeiro:** provar num dry-run que o release-PR abre, dispara o CI, e que o mecanismo
   reescreve `plugin.json.version`; confirmar a resolução por canal (tag × HEAD).
2. Um merge de teste na main gera release-PR com o número **certo** pela tabela de bump.
3. O CI roda **no** release-PR (drift + canon + adr + eval) antes do merge.
4. Mergear cria tag anotada + GitHub Release (corpo do CHANGELOG) + bump no mesmo número.
5. Re-rodar o passo de publicação é idempotente (não duplica tag/Release).

## Fora de escopo

- **Branches de manutenção** (`release/1.x`) / backport — o harness evolui linearmente (herdado do
  design v1/v2, YAGNI).
- **Registry externo** por canal — a hipótese é resolução por git ref; se o spike revelar índice
  próprio, entra como trabalho novo, não neste desenho.
- **Escolher a ferramenta na PRD** — é "como", fica no ADR-018/spike.
- **Releases no repositório do produto** (`zion-mermaid-editor-app`) — outro repo, outra jornada.
- **Garantir por máquina que o número calculado está "certo"** — o gate humano do release-PR é o
  juiz; o CD calcula e documenta, o Autor confere e mergeia.
