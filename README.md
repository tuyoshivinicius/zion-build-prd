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

## Desenvolvimento

Os assets canônicos vivem em `assets/`. Após editá-los, rode:

```bash
./scripts/sync-assets.sh   # copia assets/ → references/ de cada skill
./scripts/check-assets.sh  # falha se algum references/ divergir
```

O histórico de design está em `docs/superpowers/`.

## Licença

MIT — veja [LICENSE](LICENSE).
