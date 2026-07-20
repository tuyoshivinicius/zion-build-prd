# ADR-019 — Releases por impacto via release-PR automatizado

- **Status:** Aceito
- **Área:** Distribuição
- **Data:** 2026-07-20
- **Decisores:** autoria do repo
- **Evidência:** docs/adr/spikes/ADR-019-releases-por-impacto/ (risco de execução: permissões de bot, disparo de CI no release-PR, reescrita de plugin.json.version, resolução por canal)

## Contexto

O mantenedor libera releases à mão: edita `plugin.json`.`version` num commit e cria a tag (existem
`v1.0.0`/`v2.0.0`), **sem CHANGELOG** e **sem um PR que documente** a mudança. Isso preserva três
riscos: erro humano de versão, ausência de rastro/changelog, e divergência de número entre os dois
canais por serem editados à mão. O candidato quer as releases **distribuídas via CI/CD**: o CD abre
um PR documentando as mudanças e cria a tag com a versão gerada **por impacto**, seguindo o SemVer já
praticado pela convenção de commits (`RF-21`, épico E6). Brownfield: honra a distribuição dual por
cópia real (`ADR-002`) e o canon bloqueante (`ADR-010`/`RF-13`), sem reabrir nenhuma decisão.

## Decisão

Adota-se o modelo **release-PR automatizado** (Alt B do estudo `docs/estudos/distribuicao-releases-cicd.md`),
implementado por **`googleapis/release-please-action@v4`**:

- **Versionamento — Conventional Commits puro** (fonte = os commits, que o repo já pratica):
  `fix`→patch, `feat`→minor, `feat(x)!:` / footer `BREAKING CHANGE:`→major;
  `docs`/`test`/`chore`/`ci`/`refactor`/`style`/`perf`/`build`/`revert`→sem release. O major automático é
  seguro **porque** o gate humano do release-PR confere o número calculado antes de taguear.
- **Um release-PR permanente**: a cada merge na `main`, o bot acumula o `CHANGELOG.md` (root) e o bump
  desde a última tag. Um batch só de tipos sem release **não abre** release-PR.
- **Mergear o release-PR = a publicação**: cria a **tag anotada `vX.Y.Z`** + a **GitHub Release** (corpo
  do `CHANGELOG.md`) e reescreve `plugin.json`.`version` para o **mesmo número** via *extra-file* JSON —
  um número, dois canais (`ADR-002`; `marketplace.json` intocado, resolve por git ref). O commit de
  release é `chore(release): vX.Y.Z`, logo ignorado pelo ciclo seguinte.
- **Credencial mínima**: **PAT fine-grained** (`contents` + `pull-requests`), secret `RELEASE_PLEASE_TOKEN`
  — necessário porque um PR aberto pelo `GITHUB_TOKEN` default **não dispara** os workflows `on:`, e o
  release-PR precisa passar pelo `check-assets.yml` (drift + eval + canon + adr) antes do merge.
- **Commit-lint bloqueante** de Conventional Commits (verificador em **shell**, molde `check-*.sh`),
  no hook `commit-msg` e na CI, para o cálculo de bump nunca ver commit fora da convenção.

Descartadas: **C — tag-on-merge direto** (sem o PR que documenta, sem gate humano antes de taguear);
**semantic-release** (orientado a publicar no push, encaixa pior no gate por PR). **Recuo D** (semi-automático
por `workflow_dispatch`) fica documentado como plano B se o spike achasse bloqueio de permissão intransponível.

## Consequências

O harness ganha um workflow + config de release e um commit-lint (`check-commit.sh` + auto-teste),
todos **governança** — não viajam ao usuário (o plugin empacota só `skills/`). O gate do release-PR
combina com a cultura advisory (`RN-01`): o humano confere o número antes de taguear e força a passagem
pelo CI. **Limite honesto**: a automação **calcula e documenta**; garantir por máquina que o número está
"certo" segue sendo o juízo humano do release-PR. Recuperação pós-erro (tags são imutáveis): **corrige
pra frente** (patch corretivo ou novo major), nunca reescreve tag — runbook no README. `NFR-02` intacto
(a *action* é infra de CI, não dependência de skill). Nenhum ADR vigente é revertido.

## Status

Aceito.
