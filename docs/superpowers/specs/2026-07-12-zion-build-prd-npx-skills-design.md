# Design — Zion Build PRD: empacotamento no padrão `npx skills` (skills.sh)

Data: 2026-07-12
Status: aprovado

## Contexto

O repositório atual `zion-mermaid-editor` **é**, de fato, o produto **harness-prd**: um
harness multi-agente para autoria de PRDs que faz a ponte para o GitHub Spec Kit. O
fluxo é encenado em estágios:

1. `/prd-discovery` — descoberta enxuta → `docs/discovery.md`
2. `/prd-spike` — pesquisa de trade-offs + ADRs
3. `/prd-write` — preenche a PRD a partir do esqueleto
4. `/prd-decompose` — épicos, story map, fatias verticais, rastreabilidade
5. `/prd-constitution-prompt` — ponte para `/speckit.constitution`
6. `/prd-specify-prompt` — ponte para `/speckit.specify`
+ `/adr-new` — helper para criar ADRs

As skills `/prd-*` referenciam assets compartilhados por caminho:
`.specify/prd/quality-rules.md` e `.specify/prd/templates/*.md`.

O objetivo é **recriar** esse produto em `~/projects/personal/zion-build-prd`, renomeá-lo
para **Zion Build PRD** e entregá-lo conforme o padrão comunitário multi-agente
**`npx skills` / skills.sh**, preservando o histórico de desenvolvimento.

### O padrão skills.sh (alvo)

- Layout flat: `skills/<name>/SKILL.md` (ou catalog: `skills/<cat>/<name>/SKILL.md`).
- `SKILL.md` com frontmatter YAML contendo `name` + `description` (obrigatórios).
- Instalação: `npx skills add owner/repo` — copia **cada pasta de skill** para o
  `.claude/skills/<name>/` do consumidor. **Não** recria uma árvore `.specify/prd/`.
- Sem manifesto obrigatório; opcionalmente `.claude-plugin/marketplace.json` habilita
  compatibilidade com o marketplace/`/plugin` do Claude Code.

## Decisões (locked)

1. **Escopo:** harness + assets, **sem** vendorizar o Spec Kit. As `speckit-*` e o
   scaffolding `.specify/` do Spec Kit saem da árvore de trabalho (permanecem no
   histórico git via clone completo). As pontes já apenas *emitem prompts* para
   `/speckit.*` — nunca as chamam — então o consumidor instala o Spec Kit à parte.
2. **Autocontenção:** cada skill carrega seus assets numa subpasta `references/`,
   referenciada por caminho relativo à própria skill. Funciona com `npx skills add`
   puro, zero setup.
3. **Histórico:** repo novo baseado em **clone completo** do repo atual (todos os
   commits preservados), depois reestruturado para o layout skills.sh.
4. **Nomes das slash-commands preservados** (`/prd-discovery`, etc.). Só o **produto**
   é renomeado para "Zion Build PRD".
5. **Incluir** `.claude-plugin/marketplace.json` (aprovado).

## Layout alvo do repositório

```
zion-build-prd/
├── README.md                          # o que é, as 7 skills, `npx skills add tuyoshivinicius/zion-build-prd`
├── LICENSE
├── .claude-plugin/marketplace.json    # compat marketplace/`/plugin` do Claude Code
├── assets/                            # ← fonte única de verdade
│   ├── quality-rules.md
│   └── templates/{prd-skeleton.md, traceability-table.md}
├── scripts/
│   ├── sync-assets.sh                 # copia assets/ → references/ de cada skill
│   └── check-assets.sh                # falha em caso de drift (guarda CI/pre-commit)
├── skills/
│   ├── prd-discovery/{SKILL.md, references/quality-rules.md}
│   ├── prd-spike/{SKILL.md, references/quality-rules.md}
│   ├── prd-write/{SKILL.md, references/{quality-rules.md, prd-skeleton.md}}
│   ├── prd-decompose/{SKILL.md, references/{quality-rules.md, traceability-table.md}}
│   ├── prd-constitution-prompt/{SKILL.md, references/quality-rules.md}
│   ├── prd-specify-prompt/{SKILL.md, references/quality-rules.md}
│   └── adr-new/SKILL.md               # sem dependência de asset compartilhado
└── docs/
    ├── como-usar.md                   # guia do harness, renomeado → Zion Build PRD + instalação npx skills
    ├── guia-prd-para-spec-kit.md      # nomenclatura atualizada
    └── superpowers/{specs/*, plans/*} # ← histórico de desenvolvimento, preservado verbatim
```

### Mapa asset → skills que o consomem

| Asset (canônico em `assets/`)      | Skills que recebem cópia em `references/`                                          |
|------------------------------------|------------------------------------------------------------------------------------|
| `quality-rules.md`                 | prd-discovery, prd-spike, prd-write, prd-decompose, prd-constitution-prompt, prd-specify-prompt |
| `templates/prd-skeleton.md`        | prd-write                                                                           |
| `templates/traceability-table.md`  | prd-decompose                                                                       |
| (nenhum)                           | adr-new                                                                             |

## Mecânica de autocontenção

- Assets canônicos vivem uma vez em `assets/`. `scripts/sync-assets.sh` os copia para
  o `references/` de cada skill. `check-assets.sh` faz `diff` e falha em drift — logo
  "autocontido" nunca significa "divergiu em silêncio".
- Cada `SKILL.md` tem seus caminhos reescritos:
  - `.specify/prd/quality-rules.md` → `references/quality-rules.md`
  - `.specify/prd/templates/prd-skeleton.md` → `references/prd-skeleton.md`
  - `.specify/prd/templates/traceability-table.md` → `references/traceability-table.md`
- Após instalar em `.claude/skills/<name>/`, esses caminhos resolvem relativos à pasta
  da skill.

## Procedimento de migração (histórico completo)

1. `git clone <zion-mermaid-editor local> ~/projects/personal/zion-build-prd`
   (o diretório alvo já existe e está vazio).
2. Reestruturar:
   - criar `assets/` a partir de `.specify/prd/`;
   - criar `skills/` movendo as 7 pastas de `.claude/skills/<name>/`;
   - rodar `sync-assets.sh`;
   - reescrever os caminhos nos `SKILL.md`;
   - remover `speckit-*`, `.specify/` e o artefato de dogfood `docs/index.md`
     (amostra do "mermaid editor" — permanece no histórico).
3. Renomear o produto em README/docs → "Zion Build PRD".
4. Repontar o remote para um repositório GitHub **novo**
   `tuyoshivinicius/zion-build-prd`.
   ⚠️ **Ação externa — confirmar antes de criar/dar push.**

## Validação ("testes" de um repo de skills)

1. Todo `SKILL.md` tem frontmatter `name` + `description` válido (exigência skills.sh).
2. `check-assets.sh` — sem drift entre `assets/` e qualquer `references/` de skill.
3. Guarda por grep — zero referências remanescentes a `.specify/prd/` em qualquer SKILL.md.
4. `npx skills` (dry-run/discovery) encontra todas as 7 skills sob `skills/`.

## Fora de escopo (YAGNI)

- Vendorizar ou redistribuir o Spec Kit (`speckit-*`).
- Renomear as slash-commands `/prd-*`.
- Publicar em qualquer registry além do GitHub (skills.sh usa GitHub como registry).
- Uso local dogfood via `.claude/skills/` no repo novo: opcional, pode ser gerado por
  `sync`/`npx skills add` sobre o próprio repo; não é requisito da entrega.
