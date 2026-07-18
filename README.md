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

> As pontes `/zion-prd-constitution-prompt`, `/zion-prd-specify-prompt` e `/zion-prd-plan-prompt`
> **montam prompts** para o `/speckit.constitution`, `/speckit.specify` e `/speckit.plan`. Instale o
> **Spec Kit** separadamente para rodar o ciclo `/speckit.*`.

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
| `/zion-prd-decompose` | Épicos, story map, specs verticais, backlog (`docs/backlog.md`), rastreabilidade |
| `/zion-prd-constitution-prompt` | Ponte → `/speckit.constitution` |
| `/zion-prd-specify-prompt` | Ponte → `/speckit.specify` |
| `/zion-prd-plan-prompt` | Ponte → `/speckit.plan` |
| `/zion-prd-trace` | Reconcilia a rastreabilidade (§12) e o backlog de specs a partir das specs |
| `/zion-adr-new` | Cria um ADR em `docs/adr/` |
| `/zion-prd-evolve` | Dia 2 — mudança pós-release (RF novo/alterado, decisão revertida) |

## Dependências

| Dependência | Usada por | De onde vem |
|-------------|-----------|-------------|
| `superpowers` (skill `superpowers:brainstorming`) | `/zion-prd-discovery`, `/zion-prd-decompose`, `/zion-prd-write` | Externa — plugin `obra/superpowers-marketplace` |
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

Os assets canônicos vivem em `assets/` — **fonte única de verdade**. As cópias em
`skills/*/references/` são **artefatos derivados** (arquivos reais, exigidos pela
distribuição isolada do `npx skills`) e são geradas automaticamente.

Após clonar, ative os git hooks versionados uma vez:

```bash
./scripts/setup-hooks.sh   # git config core.hooksPath .githooks
```

A partir daí, basta editar `assets/` e commitar: o pre-commit hook roda o sync e
inclui os `references/` regenerados no commit. Nunca edite `references/` à mão.

> O hook sincroniza a partir da **árvore de trabalho**, não do que está staged.
> Commite as mudanças de `assets/` **por inteiro** (evite stage parcial de um asset
> com `git add -p`), senão os `references/` regenerados podem divergir do asset
> parcialmente commitado — o CI pegaria depois.

Mapeamento asset → skills: `scripts/asset-map.sh` (sourced por sync e check).

### Dogfooding local das skills

Para usar as skills do **working tree** (inclusive as ainda não publicadas) no terminal, sem
republicar no GitHub nem reinstalar o plugin:

```bash
./scripts/dev-claude.sh   # abre o Claude Code servindo o working tree via --plugin-dir
```

O `--plugin-dir` tem **precedência** sobre a cópia instalada do marketplace **naquela sessão** —
comando único, sem `/plugin disable` nem desinstalar nada. Argumentos extras são repassados ao
`claude` (ex.: `./scripts/dev-claude.sh --resume`).

Depois de editar um `SKILL.md`, rode `/reload-plugins` na sessão para aplicar a mudança. Alterações
em `hooks/`, `agents/` e afins exigem reabrir a sessão. O escopo vale **só** para sessões abertas
pelo wrapper: o `--plugin-dir` é resolvido no start do `claude` e não retroage à sessão atual.

O CI roda `./scripts/check-assets.sh` como guard de drift (backstop para `--no-verify`
ou quem não rodou o `setup-hooks.sh`) e os auto-testes `test-check-prd.sh`, `test-trace-prd.sh`,
`test-trace-backlog.sh`, `test-check-adr.sh` e `test-check-canon.sh` dos verificadores. Para
checar/sincronizar/testar à mão:

```bash
./scripts/sync-assets.sh        # regenera references/ a partir de assets/
./scripts/check-assets.sh       # falha se algum references/ divergir
bash scripts/test-check-prd.sh  # auto-teste do check-prd.sh contra as fixtures
bash scripts/test-check-adr.sh  # auto-teste do check-adr.sh contra as fixtures
```

O repo **governa a si mesmo**: `docs/prd.md` (requisitos) e `docs/architecture.md` (arquitetura)
são fontes da verdade — as regras para agents estão em `CLAUDE.md` (dever de **canonização**:
toda mudança de comportamento reflete nesses docs no mesmo commit). O guard
`scripts/check-canon.sh` cruza os docs com `skills/`, `scripts/`, o `ASSET_MAP` e `docs/adr/`;
roda no pre-commit (bloqueia) e no CI (backstop). Os guias de uso vivem em `docs/guias/`.

As Fases 4 de `/zion-prd-write` e `/zion-prd-specify-prompt` rodam `scripts/check-prd.sh` (sincronizado
para o `references/` de cada uma) para verificar mecanicamente as regras decidíveis (zero-stack,
NFR-com-número, RF-por-épico). A denylist de stack é curada em `assets/quality-rules.md` (`#denylist`).
No Estágio 2, a Fase 4 de `/zion-prd-spike` roda `scripts/check-adr.sh` para verificar a **presença**
da evidência do tipo certo por ADR (evidência proporcional ao risco de execução/conhecimento).

O histórico de design está em `docs/superpowers/`.

## Licença

MIT — veja [LICENSE](LICENSE).
