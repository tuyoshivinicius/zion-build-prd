# Recarregar um estudo pelo slug (zion-prd-estudo) — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Permitir reabrir um estudo já gravado passando só o slug (`/zion-prd-estudo discovery-ux-design`), sem re-digitar o candidato — a Fase 0 detecta a forma do argumento por match de arquivo e, no modo recarregar, usa o documento como fonte e vai direto para a revisão.

**Architecture:** Mudança de **prosa de skill** localizada na Fase 0 de `skills/zion-prd-estudo/SKILL.md` (o harness não tem runtime — a lógica é o texto da `SKILL.md`), refletida no canon (`docs/prd.md` §6/§13) no **mesmo commit** por dever de canonização. Nenhum script, asset, ADR ou verificador muda; a detecção é mecanismo (como), não decisão estruturante.

**Tech Stack:** Markdown (`SKILL.md`, `docs/prd.md`); verificadores em Bash já existentes (`check-prd.sh`, `check-canon.sh`, `check-estudo.sh`, `eval.sh`). Sem dependências novas.

## Global Constraints

- **Fronteira o-quê/como** (`assets/quality-rules.md#fronteira`): o RF em `docs/prd.md` é requisito puro, **sem stack**; a mecânica de detecção por match de arquivo vive só no corpo da `SKILL.md`.
- **Canonização no mesmo commit** (`CLAUDE.md`): a alteração de comportamento (`SKILL.md`) e o reflexo no canon (`docs/prd.md`) entram **num único commit**. `scripts/check-canon.sh` roda no pre-commit e bloqueia drift.
- **`skills/*/references/` são derivados** — nunca editar à mão. Este plano **não** toca `references/` nem `assets/`; `sync-assets.sh` continua no-op para esta mudança.
- **Cenário do changelog** = **C2** (RF alterado), conforme `assets/quality-rules.md` (C1=RF novo, C2=RF alterado/removido, C3=decisão revertida). Não há ADR novo, logo não é C3.
- **Sem escopo além da Fase 0**: Fases 1–4, os 6 cabeçalhos do output, `check-estudo.sh`, a detecção interno×distribuído e os assets permanecem **idênticos**.

---

### Task 1: Fase 0 aceita slug de estudo existente + reflexo no canon

Mudança única e coesa que **deve** entrar num só commit (canonização). Edita dois arquivos: o comportamento (`SKILL.md`) e o canon (`docs/prd.md`). A verificação é feita pelos guards mecânicos do repo (não há teste unitário de prosa) mais uma conferência manual dos 4 critérios de aceite.

**Files:**
- Modify: `docs/prd.md` (§6 — cláusula em `RF-17`, linha 63-66; §13 — nova linha de changelog após a linha 166)
- Modify: `skills/zion-prd-estudo/SKILL.md` (frontmatter `argument-hint`, linha 4; corpo da Fase 0, linhas 23-29)

**Interfaces:**
- Consumes: seção `## Contexto` do documento de estudo já gravado (`docs/estudos/<slug>.md`) — usada como fonte do candidato no modo recarregar. Todo estudo tem essa seção (é um dos 6 cabeçalhos cobrados por `check-estudo.sh`).
- Produces: nenhum símbolo de código; a "interface" é o contrato de entrada da Fase 0 (duas formas: candidato em prosa × slug único que casa com arquivo).

- [ ] **Step 1: Adicionar a cláusula de recarregar por slug em `RF-17` (§6 da PRD)**

Em `docs/prd.md`, no bloco do Épico E1, o `RF-17` atual termina em "…para escolher a direção." Acrescente **uma frase** ao final, sem stack (o-quê puro). O texto do `RF-17` passa a ser:

```markdown
  `RF-17` O autor estuda um candidato antes da descoberta — edge cases, alternativas comparadas
  (sempre incluindo "não fazer") com ROI justificado e recomendação não vinculante — e recebe o
  estudo gravado, com o próximo passo sugerido roteado conforme o contexto detectado, para escolher
  a direção. Pode reabrir um estudo já gravado pelo seu slug para revisá-lo, sem re-digitar o
  candidato.
```

- [ ] **Step 2: Adicionar a linha C2 no changelog (§13 da PRD)**

Em `docs/prd.md` §13, **após** a linha C2 existente (a que termina em "…ADR-013 · skills/zion-prd-estudo · docs/architecture.md §6"), adicione uma nova linha de dados na tabela:

```markdown
| 2026-07-18 | C2 | `RF-17` alterado: reabrir um estudo pelo slug para revisar, sem re-digitar o candidato | remover o atrito de re-digitar o candidato só para revisitar um estudo já gravado | skills/zion-prd-estudo (Fase 0) |
```

Notas de conformidade (para o `check-prd.sh`): a coluna **Cenário** é `C2` (válido); o único `RF-xx` citado é `RF-17`, que existe na §6; **nenhum ADR** é citado na linha (a mudança não cria ADR), então não há risco de `changelog-adr-inexistente`.

- [ ] **Step 3: Verificar que a PRD continua limpa no `check-prd.sh`**

Run: `bash scripts/check-prd.sh prd docs/prd.md`
Expected: `check-prd: limpo` (exit 0). Se aparecer `changelog-cenario-invalido`, `changelog-rf-inexistente` ou `changelog-adr-inexistente`, revise o Step 2.

- [ ] **Step 4: Atualizar o `argument-hint` da `SKILL.md` para refletir as duas formas de entrada**

Em `skills/zion-prd-estudo/SKILL.md`, no frontmatter, substitua a linha:

```yaml
argument-hint: "Candidato a discovery em 2–6 frases: quem sofre, solução imaginada, restrições conhecidas"
```

por:

```yaml
argument-hint: "Candidato em 2–6 frases (quem sofre, solução imaginada, restrições) OU o slug de um estudo já gravado para reabri-lo"
```

- [ ] **Step 5: Reescrever o corpo da Fase 0 (detecção por match de arquivo + modo recarregar)**

Em `skills/zion-prd-estudo/SKILL.md`, substitua **apenas o primeiro parágrafo** da seção `## Fase 0 — Entrada (aconselha)` (o que hoje começa em "O candidato vem no argumento…" e termina em "…ou **sobrescrever**. Não bloqueie.") pelos blocos abaixo. **Preserve intactos** os dois parágrafos seguintes da Fase 0 — "**Detecte o modo (aconselha, não bloqueia):**" (interno × distribuído) e "**Preflight (dependência):**".

Novo texto (substitui só aquele primeiro parágrafo):

```markdown
O argumento chega em **uma de duas formas**, distinguidas por **match de arquivo** (sem flag nova):

1. **Candidato** — 2–6 frases: **quem sofre**, **solução imaginada**, **restrições conhecidas**.
2. **Slug de estudo existente** — um token único cujo arquivo já existe em `docs/estudos/`.

**Detecção (match de arquivo):** faça `trim` do argumento. Se for um **token único** (sem espaços)
**e** existir `docs/estudos/<token>.md` → **modo recarregar**. Caso contrário → **modo candidato**
(comportamento atual): um token único que **não** casa com arquivo cai aqui e, se não constituir
candidato completo, peça o que faltar — sem candidato completo não há o que estudar. A regra é
robusta: um candidato em prosa (várias palavras) nunca casa com nome de arquivo, e um slug existente
casa sempre.

**Modo candidato (fluxo atual, intocado):** derive o `<slug>` do candidato (kebab-case minúsculo,
sem acentos). Se `docs/estudos/<slug>.md` **já existe**, avise e pergunte: **retomar** (partir do
documento atual e revisar) ou **sobrescrever**. Não bloqueie.

**Modo recarregar:** leia `docs/estudos/<slug>.md`. Use a seção **`## Contexto`** do documento como
fonte do candidato — **não** peça as 2–6 frases de novo. Vá **direto para retomar**: revise o
documento percorrendo as Fases 1–4, cada fase reapresentada para o Autor **confirmar ou editar**.
**Não ofereça sobrescrever** — quem quiser sobrescrever passa o candidato em texto (modo candidato),
o slug colide e a Fase 0 oferece retomar/sobrescrever como hoje.
```

- [ ] **Step 6: Verificar que nada quebrou nos guards mecânicos**

Run: `bash scripts/check-canon.sh`
Expected: `check-canon: limpo` (exit 0). Este guard roda o `check-prd.sh` como dogfood (C7) e confere que `skills/zion-prd-estudo` (citada na PRD) existe no disco — cobre os dois arquivos editados.

Run: `bash scripts/eval.sh`
Expected: `eval: tudo verde` (exit 0) — os auto-testes dos verificadores continuam passando (nenhum verificador mudou).

Run: `bash skills/zion-prd-estudo/references/check-estudo.sh docs/estudos/discovery-ux-design.md`
Expected: `check-estudo: limpo` (exit 0) — sanidade de que o verificador de estudo e os 6 cabeçalhos seguem idênticos.

- [ ] **Step 7: Conferência manual dos 4 critérios de aceite**

Não há teste automatizado da prosa da skill; confira cada critério lendo o texto final da Fase 0 e marque:

- [ ] **AC1** — `/zion-prd-estudo discovery-ux-design` (arquivo existe): o texto manda **ler o doc**, usar `## Contexto` como candidato e ir **direto para retomar**, **sem** oferecer sobrescrever. ✔ coberto pelo bloco "Modo recarregar".
- [ ] **AC2** — `/zion-prd-estudo <slug-inexistente>` (token único, sem arquivo): cai no **modo candidato** e pede o que falta. ✔ coberto pela frase "um token único que não casa com arquivo cai aqui…".
- [ ] **AC3** — `/zion-prd-estudo <candidato em 2–6 frases>` cujo slug colide: continua oferecendo **retomar/sobrescrever**. ✔ coberto pelo bloco "Modo candidato (fluxo atual, intocado)".
- [ ] **AC4** — `check-estudo.sh` e os 6 cabeçalhos idênticos; `check-canon.sh` passa com `RF-17` refletido em §6/§13. ✔ verificado nos Steps 3 e 6.

- [ ] **Step 8: Commit (os dois arquivos juntos — canonização no mesmo commit)**

```bash
git add docs/prd.md skills/zion-prd-estudo/SKILL.md
git commit -m "feat(estudo): recarregar um estudo pelo slug na Fase 0

RF-17 ganha a cláusula de reabrir um estudo gravado pelo slug, sem
re-digitar o candidato. A Fase 0 distingue candidato x slug por match
de arquivo; o modo recarregar usa a seção ## Contexto como fonte e vai
direto para retomar. Reflexo no canon (prd.md §6/§13, C2) no mesmo commit."
```

O pre-commit (`.githooks/pre-commit`) roda `sync-assets.sh` (no-op aqui), `check-assets.sh`, `check-canon.sh` e `eval.sh`; todos devem passar. Se o hook bloquear, leia o achado, corrija e refaça o commit — **não** use `--no-verify`.

---

## Self-Review

**1. Spec coverage** — cada requisito do design mapeado a um step:
- Contrato de entrada com duas formas + detecção por match de arquivo → Steps 4, 5.
- Modo recarregar (lê doc, usa `## Contexto`, vai direto para retomar, não oferece sobrescrever) → Step 5.
- Modo candidato preservado (retomar/sobrescrever ao colidir) → Step 5.
- "O que não muda" (Fases 1–4, 6 cabeçalhos, `check-estudo.sh`, interno×distribuído, assets) → garantido por escopo (só o 1º parágrafo da Fase 0 muda) e verificado no Step 6.
- Reflexo no canon: §6 `RF-17` → Step 1; §13 C2 → Step 2; `argument-hint` → Step 4; §12 inalterada (não tocada); sem ADR (não há step de ADR) → conforme.
- 4 critérios de aceite → Step 7.

**2. Placeholder scan** — nenhum "TBD/TODO/etc."; todo texto a escrever está literal nos blocos.

**3. Type consistency** — não há tipos/assinaturas de código (mudança de prosa). Nomes de arquivo, slugs de cabeçalho (`## Contexto`) e o código de cenário (`C2`) usados de forma consistente entre os steps e conferidos contra o disco (`docs/estudos/discovery-ux-design.md` tem `## Contexto`; changelog aceita C1/C2/C3).

Nenhuma lacuna encontrada.
