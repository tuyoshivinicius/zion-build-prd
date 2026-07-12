# Design — Distribuição dual (npx skills + plugin Claude Code) com garantia de dependências

Data: 2026-07-12
Status: aprovado

## Contexto

O repositório `zion-build-prd` já está empacotado no padrão `npx skills` (skills.sh), com
7 skills autocontidas sob `skills/` e manifestos mínimos em `.claude-plugin/`
(ver `2026-07-12-zion-build-prd-npx-skills-design.md`). O objetivo agora é entregar o
mesmo repositório em **dois formatos simultâneos, sem duplicar arquivos**:

- **(A)** `npx skills add <owner>/<repo>` — ecossistema skills.sh / Agent Skills.
- **(B)** plugin + marketplace do Claude Code (`/plugin marketplace add`, `/plugin install`).

O objetivo central: **garantir que as dependências das skills sejam instaladas
automaticamente quando alguém instalar via plugin do Claude Code (B)**. No formato (A) não
existe resolução de dependência, então a garantia lá é apenas defensiva (preflight + doc).

## Achados de investigação (fundamentam o design)

Capacidades reais do sistema de plugins do Claude Code (verificadas na doc oficial
`code.claude.com/docs/en/plugin-dependencies`):

1. `plugin.json` **suporta** um campo `dependencies` (array de strings ou objetos
   `{name, version?, marketplace?}`), com **auto-instalação transitiva**.
2. Dependência **cross-marketplace** exige que o marketplace-raiz liste o alvo em
   `allowCrossMarketplaceDependenciesOn` (bloqueada por padrão, por segurança).
3. O campo `marketplace` da dependência aceita **apenas o NOME** do marketplace — não uma
   URL/fonte. O marketplace precisa estar **registrado localmente por nome**.
4. **Não é zero-setup:** se o consumidor não tiver adicionado o marketplace do alvo, o
   install falha com erro **acionável** `dependency-unsatisfied` (mostra o comando exato) —
   nunca falha silenciosa. Após `/plugin marketplace add`, resolve automaticamente.
5. **skills.sh / `npx skills` NÃO tem mecanismo de dependência** — `SKILL.md` frontmatter
   não suporta declarar dependências. Garantia em (A) é só defensiva.

### Mapa real de dependências das skills

Auditoria de `grep` sobre `skills/*/SKILL.md`:

| Dependência | Usada por | Natureza | Estratégia |
|---|---|---|---|
| `superpowers:brainstorming` | prd-discovery, prd-decompose, prd-write | Plugin publicado em `obra/superpowers-marketplace` | **Única dep externa real** — declarar (B) + preflight (A) |
| `rewrite-prompt` | prd-constitution-prompt, prd-specify-prompt | Skill pessoal do autor, **não publicada** | **Vendorizar** como 8ª skill first-party |
| `deep-research` | prd-spike | **Built-in** do harness (não existe em disco; não vendorizável) | Assumir presente + **degradação graciosa** + doc |
| `adr-new` | prd-spike | Interna (já em `skills/`) | Nenhuma ação |

Resultado: após vendorizar `rewrite-prompt` e tratar `deep-research` como built-in, **a
única dependência externa que exige resolução é o `superpowers`**.

## Decisões (locked)

1. **Uma árvore, dois porteiros.** `skills/` é fonte única; ambos os formatos a consomem.
   `npx skills` lê `skills/*/SKILL.md` direto; o plugin lê os manifestos em
   `.claude-plugin/` (auto-descoberta padrão de `skills/`). **Zero duplicação por formato.**
2. **Vendorizar `rewrite-prompt`** como `skills/rewrite-prompt/` (8ª skill), copiado
   verbatim de `~/.claude/skills/rewrite-prompt/SKILL.md`, com `metadata.author`
   alinhado para `zion-build-prd`. É autocontido (um único SKILL.md, sem `references/`,
   sem deps externas). O autor é o mesmo → incluível sob a licença MIT do repo.
3. **`deep-research` não é vendorizado** (built-in sem fonte acessível; reconstruir seria
   fabricar). prd-spike passa a **degradar graciosamente**: usa se existir, senão avisa e
   segue com pesquisa manual antes do `adr-new`. README documenta o requisito.
4. **Formato (B): declarar `superpowers` como dependência cross-marketplace**, sem pin de
   versão (aceita qualquer versão instalada — YAGNI).
5. **Formato (A): garantia defensiva dupla** para o `superpowers` — preflight runtime nas
   3 skills que o usam + documentação no README.
6. **Spec Kit permanece fora de escopo** (as pontes só emitem prompts).

## Mudanças por artefato

### `.claude-plugin/plugin.json` (+ campo `dependencies`)

```json
{
  "name": "zion-build-prd",
  "version": "1.0.0",
  "description": "Harness multi-agente para autoria de PRDs, com ponte para o GitHub Spec Kit.",
  "author": { "name": "Tuyoshi Vinicius" },
  "dependencies": [
    { "name": "superpowers", "marketplace": "superpowers-marketplace" }
  ]
}
```

### `.claude-plugin/marketplace.json` (+ allowlist cross-marketplace)

```json
{
  "name": "zion-build-prd",
  "owner": { "name": "Tuyoshi Vinicius" },
  "allowCrossMarketplaceDependenciesOn": ["superpowers-marketplace"],
  "plugins": [
    {
      "name": "zion-build-prd",
      "source": "./",
      "description": "Harness multi-agente para autoria de PRDs, com ponte para o GitHub Spec Kit."
    }
  ]
}
```

### `skills/rewrite-prompt/SKILL.md` (nova — vendorizada)

Cópia verbatim de `~/.claude/skills/rewrite-prompt/SKILL.md`, com `metadata.author:
zion-build-prd`. Comportamento inalterado (reescreve prompt informal → XML estruturado;
nunca executa). As pontes `prd-constitution-prompt` e `prd-specify-prompt` já a invocam por
nome (`rewrite-prompt`) — nenhuma mudança de caminho necessária, pois skills se resolvem
por nome, não por caminho relativo.

### Preflight `superpowers` — prd-discovery, prd-decompose, prd-write

Cada uma dessas 3 skills ganha, no início do contrato (Fase 0 / antes da auto-delegação),
um **preflight**: se `superpowers:brainstorming` não estiver disponível, a skill **avisa
e para graciosamente** com a instrução exata:

> Esta skill depende de `superpowers:brainstorming`. Instale:
> `/plugin marketplace add obra/superpowers-marketplace` e
> `/plugin install superpowers@superpowers-marketplace`.

O preflight é advisory (não trava o harness inteiro), coerente com o padrão "gates
aconselham" já usado nas skills.

### Degradação graciosa `deep-research` — prd-spike

A etapa de pesquisa de trade-offs passa a ser condicional: se `deep-research` disponível →
invoca; senão → avisa ("`deep-research` (built-in) indisponível; seguindo com pesquisa
manual") e conduz o levantamento manualmente antes de `adr-new`. Nunca quebra.

### `README.md` (+ seção Dependências)

Nova seção documentando, para ambos os formatos:

- Tabela de dependências (superpowers = externa; rewrite-prompt = incluída; deep-research =
  built-in; adr-new = incluída).
- **(B) Plugin:** o `superpowers` é auto-instalado *se* o marketplace estiver registrado;
  senão o install pede `/plugin marketplace add obra/superpowers-marketplace` e resolve ao
  re-tentar. Documentar esse pré-requisito de uma linha.
- **(A) npx skills:** instruir a instalar o superpowers manualmente (sem resolução
  automática); citar que as skills fazem preflight e avisam se faltar.

## Garantia entregue (honesta)

- **(B) plugin:** a dependência `superpowers` é **imposta pelo Claude Code** — install
  bloqueia com erro acionável se o marketplace não estiver presente; instala
  automaticamente (transitivo) quando estiver. Não é 100% zero-setup, mas é **enforced**
  em vez de quebrar em runtime. `rewrite-prompt` e `adr-new` viajam no próprio plugin →
  sempre presentes. `deep-research` é built-in.
- **(A) npx skills:** sem resolução automática; preflight nas skills + README cobrem a
  lacuna defensivamente.

## Validação

1. `python3 -m json.tool` valida `plugin.json` e `marketplace.json` (JSON bem-formado).
2. Guard: `plugin.json` contém `dependencies` com `superpowers`/`superpowers-marketplace`;
   `marketplace.json` contém `allowCrossMarketplaceDependenciesOn` com
   `superpowers-marketplace`.
3. `find skills -maxdepth 2 -name SKILL.md | wc -l` → **8** (as 7 + rewrite-prompt).
4. `skills/rewrite-prompt/SKILL.md` tem frontmatter `name` + `description` válido e
   `metadata.author: zion-build-prd`.
5. Grep: prd-discovery, prd-decompose, prd-write contêm o texto de preflight do superpowers;
   prd-spike contém o ramo de degradação de `deep-research`.
6. `./scripts/check-assets.sh` continua sem drift (rewrite-prompt não usa assets canônicos,
   então os scripts de sync não mudam).
7. README contém a seção Dependências cobrindo ambos os formatos.

## Fora de escopo (YAGNI)

- Vendorizar `deep-research` (sem fonte; é built-in).
- Pin de versão do `superpowers`.
- Vendorizar/redistribuir o Spec Kit.
- Renomear slash-commands.
- Auto-registrar o `superpowers-marketplace` no install (impossível pela doc — só o
  consumidor adiciona marketplaces).
- Qualquer registry além do GitHub.
