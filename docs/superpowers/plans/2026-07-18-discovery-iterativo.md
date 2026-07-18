# Discovery iterativo — retomar/revisar o `docs/discovery.md` — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Dar ao `/zion-prd-discovery` a mesma idempotência que o `/zion-prd-write` já tem — detectar `docs/discovery.md` existente e entrar em modo retomar/revisar (sem sobrescrever), com aviso advisório apontando `/zion-prd-evolve` quando há downstream.

**Architecture:** A mudança principal é editorial numa skill (`skills/zion-prd-discovery/SKILL.md`): a Fase 0 passa a ramificar por presença de arquivo (do-zero vs. retomar/revisar) e a Fase 2/3 ramifica o enquadramento passado ao `superpowers:brainstorming`. Uma linha no asset canônico `assets/process-context.md` registra a idempotência e é propagada aos `references/` de 6 skills por `sync-assets.sh`. O `docs/como-usar.md` documenta o comportamento espelhando o item já existente do write. Nenhum arquivo novo, nenhum script novo, nenhuma skill downstream tocada.

**Tech Stack:** Markdown (SKILL.md + docs), Bash (`sync-assets.sh` / `check-assets.sh` como guarda de drift). Sem framework de teste — a verificação é mecânica (`check-assets.sh`) + releitura dirigida.

---

## Estrutura de arquivos

| Arquivo | Responsabilidade | Ação |
|---|---|---|
| `assets/process-context.md` | Fonte única do contexto de processo; item 1 ganha nota de idempotência do discovery | Modificar |
| `skills/zion-prd-discovery/SKILL.md` | A mudança principal: Fase 0 (detecção de modo + aviso de downstream), Fase 1 (argumento no modo revisar), Fase 2/3 (enquadramento ramificado), frontmatter (gatilhos) | Modificar |
| `docs/como-usar.md` | Documentar a idempotência do discovery (item "gates em ação" + nota no Estágio 1) | Modificar |

Os derivados `skills/{zion-prd-discovery,zion-prd-spike,zion-prd-write,zion-prd-decompose,zion-adr-new,zion-prd-evolve}/references/process-context.md` **não** são editados à mão — `sync-assets.sh` os regenera a partir do canônico.

---

### Task 1: Nota de idempotência no asset `process-context.md` + sync

**Files:**
- Modify: `assets/process-context.md` (item 1 da sequência)
- Verify: `scripts/sync-assets.sh`, `scripts/check-assets.sh`

- [ ] **Step 1: Editar o item 1 da sequência**

Em `assets/process-context.md`, substitua a linha do item 1:

```markdown
1. **Descoberta** (`/zion-prd-discovery`) — visão, persona, quadro faz/não-faz → `docs/discovery.md`.
```

por (acrescenta a nota de idempotência ao final da mesma linha):

```markdown
1. **Descoberta** (`/zion-prd-discovery`) — visão, persona, quadro faz/não-faz → `docs/discovery.md`.
   Idempotente: rodar de novo sobre um `docs/discovery.md` existente **retoma/revisa** (não
   sobrescreve) — permite descoberta em várias sessões.
```

- [ ] **Step 2: Propagar aos references/**

Run: `./scripts/sync-assets.sh`
Expected: saída indicando que os `references/process-context.md` das 6 skills consumidoras foram regenerados (ver `ASSET_MAP` em `scripts/asset-map.sh`).

- [ ] **Step 3: Verificar ausência de drift**

Run: `./scripts/check-assets.sh`
Expected: exit `0`, sem divergência reportada.

- [ ] **Step 4: Commit**

```bash
git add assets/process-context.md skills/*/references/process-context.md
git commit -m "docs(process): registra idempotência do discovery (retomar/revisar)

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 2: Modo retomar/revisar no `/zion-prd-discovery`

**Files:**
- Modify: `skills/zion-prd-discovery/SKILL.md` (frontmatter `description`, Fase 0, Fase 1, Fase 2/3)

- [ ] **Step 1: Ampliar os gatilhos no frontmatter `description`**

Em `skills/zion-prd-discovery/SKILL.md`, substitua a linha `description:` inteira:

```yaml
description: Estágio 1 do harness Zion Build PRD — conduz a descoberta enxuta de produto (visão em 1 frase, persona nomeada, quadro faz/não-faz) e grava docs/discovery.md. Use ao iniciar um produto/feature a partir de uma ideia bruta, antes de qualquer PRD ou stack, sempre que o usuário quiser "começar a descoberta", "destrinchar a ideia" ou "definir visão e escopo".
```

por:

```yaml
description: Estágio 1 do harness Zion Build PRD — conduz a descoberta enxuta de produto (visão em 1 frase, persona nomeada, quadro faz/não-faz) e grava docs/discovery.md; idempotente — retoma/revisa um discovery existente sem sobrescrever. Use ao iniciar um produto/feature a partir de uma ideia bruta, antes de qualquer PRD ou stack, ou para retomar/revisar a descoberta em nova sessão, sempre que o usuário quiser "começar a descoberta", "destrinchar a ideia", "definir visão e escopo" ou "continuar/revisar o discovery".
```

- [ ] **Step 2: Reescrever a Fase 0 (detecção de modo + aviso de downstream)**

Substitua o bloco:

```markdown
## Fase 0 — Pré-requisito
Nenhum. Este é a entrada do funil.
```

por:

```markdown
## Fase 0 — Pré-requisito / detecção de modo (aconselha)
Este é a entrada do funil — não há pré-requisito de artefato. **Idempotência:** se
`docs/discovery.md` **não** existe, siga em **modo do-zero** (fluxo abaixo, intacto). Se **já
existe**, NÃO sobrescreva — entre em **modo retomar/revisar**: leia o discovery atual e trate-o
como ponto de partida. **Detecção de downstream** (só no modo revisar): se `docs/adr/` contém
ADR(s) **ou** `docs/PRD.md` existe, emita um aviso advisório único: "⚠ já há downstream baseado
neste discovery; se a mudança for estrutural (visão/persona/escopo), rode `/zion-prd-evolve` para
rotear o impacto." Só avisa — não roteia, não bloqueia.
```

- [ ] **Step 3: Ampliar a Fase 1 (argumento no modo revisar)**

Substitua o bloco:

```markdown
## Fase 1 — Validar entrada bruta (aconselha)
A semente do usuário deve conter um **problema** e uma **persona candidata**. Se faltar, pergunte
o que estiver faltando. Se o usuário já descreve **stack/framework/biblioteca**, avise: "isso é cedo
— stack é do `plan.md`; aqui é só visão e escopo" (veja `quality-rules.md` `#fronteira`). Não bloqueie.
```

por:

```markdown
## Fase 1 — Validar entrada bruta (aconselha)
**Modo do-zero:** a semente do usuário deve conter um **problema** e uma **persona candidata**. Se
faltar, pergunte o que estiver faltando. Se o usuário já descreve **stack/framework/biblioteca**,
avise: "isso é cedo — stack é do `plan.md`; aqui é só visão e escopo" (veja `quality-rules.md`
`#fronteira`). Não bloqueie. **Modo retomar/revisar:** o argumento é **opcional** e vira a dica de
*o que revisar* (ex.: "quero rever a persona"); sem argumento, pressione os blocos incompletos ou
fracos do discovery atual.
```

- [ ] **Step 4: Ramificar o enquadramento na Fase 2/3**

Substitua o bloco:

```markdown
Invoque `superpowers:brainstorming` no mesmo turno, com este enquadramento fixo:
"Refine a visão do produto: (1) visão em UMA frase; (2) persona principal nomeada; (3) quadro
faz/não-faz, com os 'não faz' explícitos. Grave o resultado em `docs/discovery.md`."
```

por:

```markdown
Invoque `superpowers:brainstorming` no mesmo turno. O enquadramento ramifica pelo modo detectado
na Fase 0:

- **Modo do-zero:** "Refine a visão do produto: (1) visão em UMA frase; (2) persona principal
  nomeada; (3) quadro faz/não-faz, com os 'não faz' explícitos. Grave o resultado em
  `docs/discovery.md`."
- **Modo retomar/revisar:** "Aqui está o `docs/discovery.md` atual: «<conteúdo do arquivo>».
  Preserve visão/persona/faz-não-faz que já estão sólidos; pressione o que está incompleto ou o
  que o usuário quer rever (ver argumento da Fase 1); não reescreva o que está bom. Mantenha os 3
  blocos: visão em UMA frase, persona nomeada, quadro faz/não-faz. Regrave `docs/discovery.md`."
```

- [ ] **Step 5: Releitura dirigida (verificação)**

Run: `sed -n '1,50p' skills/zion-prd-discovery/SKILL.md`
Expected — confirme os quatro pontos:
1. `description` cita "retomar/revisar" e o gatilho "continuar/revisar o discovery".
2. Fase 0 tem os dois modos e o aviso de downstream disparando por `docs/adr/` **ou** `docs/PRD.md`.
3. Fase 1 tem o parágrafo do modo revisar (argumento opcional = o que revisar).
4. Fase 2/3 tem os dois enquadramentos (do-zero intacto; revisar preserva-e-pressiona).

- [ ] **Step 6: Commit**

```bash
git add skills/zion-prd-discovery/SKILL.md
git commit -m "feat(discovery): modo retomar/revisar sobre discovery.md existente

Espelha a idempotência do /zion-prd-write: detecta docs/discovery.md
existente e entra em modo revisar (sem sobrescrever); avisa e aponta
/zion-prd-evolve quando há downstream (ADRs/PRD).

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 3: Documentar no `docs/como-usar.md`

**Files:**
- Modify: `docs/como-usar.md` (seção "Os gates em ação" item 3; seção "Estágio 1")

- [ ] **Step 1: Ampliar o item 3 dos gates para cobrir o discovery**

Em `docs/como-usar.md`, substitua o bloco:

```markdown
### 3. Idempotência — modo revisar
Rodar `/zion-prd-write` com `docs/PRD.md` **já existente**: ele **não sobrescreve** — entra em modo
*pressionar seção a seção*, apontando o que está fraco na PRD atual.
```

por:

```markdown
### 3. Idempotência — modo revisar
Vale para os estágios que mantêm um artefato vivo. Rodar `/zion-prd-write` com `docs/PRD.md` **já
existente**: ele **não sobrescreve** — entra em modo *pressionar seção a seção*, apontando o que
está fraco na PRD atual. O mesmo vale para `/zion-prd-discovery` com `docs/discovery.md` **já
existente**: entra em **modo retomar/revisar** (preserva o que está sólido, pressiona o incompleto).
Se já houver downstream (`docs/adr/` ou `docs/PRD.md`), avisa para considerar `/zion-prd-evolve` na
mudança estrutural. Uma **nova sessão de discovery** é só rodar o comando de novo.
```

- [ ] **Step 2: Adicionar nota de nova sessão ao Estágio 1**

Em `docs/como-usar.md`, localize a linha que fecha o Estágio 1:

```markdown
**Fase 4 (veredito):** `✓ visão em 1 frase · ✓ persona nomeada (Ana) · ✓ "não faz" explícito`.
```

Insira **logo após** ela este blockquote:

```markdown
> **Nova sessão / retomar:** rodar `/zion-prd-discovery` de novo com `docs/discovery.md` já
> existente **não** recomeça do zero — entra em **modo retomar/revisar** (preserva o sólido,
> pressiona o incompleto). Passe o que quer rever como argumento (ex.: "quero rever a persona");
> sem argumento, ele varre os blocos fracos. Se já houver ADRs/PRD, avisa para considerar
> `/zion-prd-evolve`.
```

- [ ] **Step 3: Releitura dirigida (verificação)**

Run: `grep -n "retomar/revisar\|Nova sessão\|modo revisar" docs/como-usar.md`
Expected: mostra o item 3 ampliado e o blockquote do Estágio 1 — ambos presentes.

- [ ] **Step 4: Commit**

```bash
git add docs/como-usar.md
git commit -m "docs(como-usar): documenta discovery iterativo (retomar/revisar)

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 4: Verificação final

**Files:** nenhum (só verificação)

- [ ] **Step 1: Guarda de drift limpa**

Run: `./scripts/check-assets.sh`
Expected: exit `0`, sem divergência (confirma que os `references/` estão em sincronia com `assets/` após a Task 1).

- [ ] **Step 2: Árvore limpa**

Run: `git status --short`
Expected: saída vazia (tudo commitado nas Tasks 1–3).

- [ ] **Step 3: Sanidade do fluxo do-zero preservado**

Run: `grep -n "Modo do-zero\|modo do-zero" skills/zion-prd-discovery/SKILL.md`
Expected: o enquadramento do-zero continua presente e idêntico ao original — a mudança adicionou o modo revisar sem regredir o caminho greenfield.
