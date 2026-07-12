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

> As pontes `/prd-constitution-prompt` e `/prd-specify-prompt` **montam prompts** para o
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
| `/prd-discovery` | Descoberta enxuta → `docs/discovery.md` |
| `/prd-spike` | Pesquisa de trade-offs + ADRs |
| `/prd-write` | Preenche a PRD a partir do esqueleto |
| `/prd-decompose` | Épicos, story map, fatias verticais, rastreabilidade |
| `/prd-constitution-prompt` | Ponte → `/speckit.constitution` |
| `/prd-specify-prompt` | Ponte → `/speckit.specify` |
| `/adr-new` | Cria um ADR em `docs/adr/` |

## Dependências

| Dependência | Usada por | De onde vem |
|-------------|-----------|-------------|
| `superpowers` (skill `superpowers:brainstorming`) | `/prd-discovery`, `/prd-decompose`, `/prd-write` | Externa — plugin `obra/superpowers-marketplace` |
| `rewrite-prompt` | `/prd-constitution-prompt`, `/prd-specify-prompt` | Incluída (skill first-party deste repo) |
| `deep-research` | `/prd-spike` | Built-in do Claude Code (degrada para pesquisa manual se ausente) |
| `adr-new` | `/prd-spike` | Incluída (skill deste repo) |

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

Os assets canônicos vivem em `assets/`. Após editá-los, rode:

```bash
./scripts/sync-assets.sh   # copia assets/ → references/ de cada skill
./scripts/check-assets.sh  # falha se algum references/ divergir
```

O histórico de design está em `docs/superpowers/`.

## Licença

MIT — veja [LICENSE](LICENSE).
