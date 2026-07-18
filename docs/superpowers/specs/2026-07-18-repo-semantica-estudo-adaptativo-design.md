# Design — Separação semântica do repo + estudo workflow-adaptativo

> Spec do dev-workflow interno (SDD leve). Produz uma mudança de comportamento do harness, então
> canoniza em `docs/prd.md` e `docs/architecture.md` no mesmo commit da implementação (CLAUDE.md).

## Problema

O repo mistura três naturezas de artefato sem rótulo, e a skill `zion-prd-estudo` vive nos dois
mundos ao mesmo tempo:

- **Artefato distribuído** (o que o usuário do harness recebe): `skills/zion-*`, `assets/`,
  `.claude-plugin/`, os `references/`.
- **Governança/canon** do harness: `docs/prd.md`, `docs/architecture.md`, `docs/adr/`, `CLAUDE.md`,
  os guards de canonização.
- **Dev-workflow** interno (SDD leve: `superpowers:brainstorming → writing-plans →
  executing-plans`): `docs/superpowers/specs|plans/`, `docs/estudos/` (deste repo).

A `zion-prd-estudo` é o Estágio 0 **distribuído** (que o usuário roda no produto dele, cujo
"Próximo passo" aponta `/zion-prd-discovery`), mas o **dev do harness também a usa internamente**
para estudar candidatos do próprio harness — onde o próximo passo correto é
`superpowers:brainstorming → writing-plans → executing-plans`, não discovery. Hoje a skill
hard-coda o downstream distribuído.

## Duas personas

- **Dev do zion-build-prd** (mantenedor): SDD leve com `superpowers:brainstorming`,
  `writing-plans`, `executing-plans`. Do harness, só precisa da skill de estudo.
- **Usuário do harness** (dev que usa o zion-build-prd): usa superpowers só através da fachada do
  harness + Spec Kit para implementar as specs.

Uma **única** skill de estudo, adaptativa: detecta o contexto e roteia o downstream conforme a
persona. Duas skills separadas foram rejeitadas (duplicariam as Fases 1–3 e divergiriam).

## Decisões (já tomadas nesta sessão)

- **Um design coeso:** a separação semântica dá o vocabulário; o estudo adaptativo é o primeiro a
  consumi-lo.
- **Detecção automática por marcador do repo-harness** (sem flag, sem pergunta): robusto e inerte
  para o usuário externo.
- **Adaptação cirúrgica + canon:** só a Fase 4 ramifica o downstream; Fases 1–3 intactas.
- **Separação documentada no `architecture.md`** (nova seção), sem mover pastas.
- **Estrutura Opção A:** Fase 4 com dois ramos gated numa única `SKILL.md`.
- **Canonização via ADR-013** + amendas em `prd.md`.

## Solução

### 1. As três naturezas do repo (nova §6 em `docs/architecture.md`)

Seção nova que classifica cada artefato de topo em **uma** das três naturezas e **aponta** para as
tabelas existentes (§3 scripts, §4 assets, §12 da PRD) em vez de re-listar — para não criar uma
quarta fonte da verdade a manter.

| Natureza | O que é | Artefatos |
|---|---|---|
| **Distribuído** | Viaja ao usuário via plugin/skills.sh | `skills/zion-*`, `assets/`, `.claude-plugin/`, os `references/` derivados, e os scripts marcados "distribuídos como references" na §4 (`check-prd.sh`, `check-adr.sh`, `check-estudo.sh`, `trace-prd.sh`, `trace-backlog.sh`) |
| **Governança** | Governa o próprio harness (canon) | `docs/prd.md`, `docs/architecture.md`, `docs/adr/`, `CLAUDE.md`, `scripts/check-canon.sh`, `scripts/check-assets.sh`, os guards versionados e o CI |
| **Dev-workflow** | SDD leve interno (não viaja) | `docs/superpowers/specs\|plans/`, `docs/estudos/` (deste repo), `scripts/dev-claude.sh`, `scripts/setup-hooks.sh`, `scripts/eval.sh`, os `test-*.sh` |

**Fato reforçado na seção:** só `skills/` é empacotado pelo plugin; `docs/` e o tooling interno
nunca viajam — a separação física já existe, a seção a **nomeia e canoniza**.

**Marcador do repo-harness:** projeto-alvo cujo `.claude-plugin/plugin.json` tem `name:
zion-build-prd`. É a identidade única deste repo; nenhum produto de usuário a possui. É o marcador
que a skill de estudo lê para decidir o modo.

A §2 (índice de ADRs) do `architecture.md` ganha a linha do ADR-013.

### 2. Skill `zion-prd-estudo` dual-mode (Opção A)

Editar `skills/zion-prd-estudo/SKILL.md` (hand-authored; os `references/` derivados não mudam):

- **Fase 0 (+detecção):** após derivar o `<slug>`, passo novo em prosa —
  > "Detecte o modo: se o projeto-alvo tiver `.claude-plugin/plugin.json` com `name:
  > zion-build-prd`, modo **interno**; caso contrário, **distribuído** (default)."

  Aconselha, não bloqueia.
- **Fases 1–3:** intactas (no dogfood interno os caminhos coincidem — o projeto-alvo é o próprio
  repo).
- **Fase 4 — "Próximo passo sugerido" ramifica**, e o conteúdo gravado na seção homônima de
  `docs/estudos/<slug>.md` reflete o modo detectado:
  - **Distribuído (default):**
    > Se aprovado, rodar `/zion-prd-discovery` com a alternativa escolhida (e `/zion-prd-spike` se
    > houver decisão estruturante nova).
  - **Interno:**
    > Se aprovado, rodar `superpowers:brainstorming` com a alternativa escolhida →
    > `superpowers:writing-plans` → `superpowers:executing-plans`. Decisão estruturante nova vira
    > ADR via `/zion-adr-new` e reflete no canon (`prd.md`/`architecture.md` no mesmo commit —
    > CLAUDE.md).
- **Superfície descobrível intocada:** `description` e `argument-hint` do front-matter permanecem
  100% distribuídos. O ramo interno viaja shipado mas fica **inerte** para o usuário externo
  (o marcador nunca casa no produto dele).

### 3. Canonização (mesmo commit da implementação)

- **ADR-013** via `/zion-adr-new` — "Skill de estudo workflow-adaptativa por marcador do repo
  (persona dupla)". Evidência: **decisão dada** (o modelo de duas personas foi decidido) ⇒ racional
  basta, sem spike (ADR-006). Campo *Evidência* aponta este design doc. Supersede nada. Entra no
  índice §2 do `architecture.md`.
- **RF-17** (`prd.md` §6) — texto amendado para incluir a adaptividade (rotear o próximo passo
  conforme o contexto detectado). Artefato na §12 permanece `skills/zion-prd-estudo`.
- **§13 changelog** da PRD — uma linha (cenário de mudança de comportamento).
- **§8 restrições** da PRD — cita ADR-013 junto às demais.

### 4. Verificação

- `check-estudo.sh` **não muda:** cobra só a presença dos 6 cabeçalhos `##`, agnóstico ao conteúdo
  do "Próximo passo sugerido" — nada vaza e **nenhuma fixture nova** é necessária (NFR-04 intacto).
- `check-canon.sh` continua verde: ADR-013 no índice, RF-17 mapeado, nenhum script novo, nenhum
  asset novo no `ASSET_MAP`.
- `check-adr.sh` sobre ADR-013: evidência presente, sem supersessão pendente → verde.

## Fora de escopo

- Mover pastas fisicamente (rejeitado: alto raio; a separação é conceitual/documentada).
- Tocar `process-context.md` ou qualquer asset distribuído além do `SKILL.md` da estudo (evita
  vazar vocabulário interno na superfície shipada).
- Adaptar Fases 1–3 (rejeitado em favor de "cirúrgica + canon").

## Loose end (sinalizado, decisão do mantenedor)

`docs/estudos/discovery-ux-design.md` está untracked. Se `docs/estudos/` passa a ser dev-workflow
reconhecido, provavelmente vale versioná-lo — mas é decisão separada, fora deste design.

## Blast radius

1 seção nova no `architecture.md` + linha no índice §2 · 1 ADR novo · ~3 linhas no `prd.md`
(RF-17, §8, §13) · ~2 parágrafos no `SKILL.md` da estudo. **Zero** moves, **zero** script novo,
**zero** mudança de verificador.
