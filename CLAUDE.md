# Regras deste repo — leia antes de qualquer trabalho

## Fontes da verdade (governança)

- **`docs/prd.md`** — o que o harness faz e por quê (RF-xx por épico, NFRs, escopo).
- **`docs/architecture.md`** — como o harness é construído (decisões estruturantes como ADRs,
  scripts, fonte única).

Todo agent DEVE ler os dois antes de escrever qualquer spec, plano ou mudança neste repo.
Especificação nova nasce desses documentos, não do código.

## Dever de canonização

Toda mudança de comportamento ou estrutura reflete de volta nas fontes da verdade **no mesmo
commit**:

- Skill nova/alterada/removida ⇒ RF na §6 e linha na §12 de `docs/prd.md`.
- Script novo/removido ⇒ tabela de scripts (§3) de `docs/architecture.md`.
- Fonte nova no `ASSET_MAP` ⇒ §4 de `docs/architecture.md`.
- Decisão estruturante ⇒ ADR em `docs/adr/` (via `/zion-adr-new`) + índice (§2) do
  `architecture.md`.

O guard `scripts/check-canon.sh` roda no pre-commit e **bloqueia** commit com drift; o CI
(`.github/workflows/check-assets.yml`) repete como backstop.

## Regras operacionais

- `assets/` é a fonte única; **nunca** edite `skills/*/references/` à mão — são derivados que o
  pre-commit regenera via `scripts/sync-assets.sh`.
- Após clonar: `./scripts/setup-hooks.sh` (ativa os hooks versionados).
- A fronteira o-quê/como (`assets/quality-rules.md#fronteira`) vale para os próprios docs:
  requisito sem stack em `docs/prd.md`; stack e mecânica em `docs/architecture.md`.
- Decisões dos ADRs não se reabrem em spec/plano — mudar de decisão é ADR novo
  (supersessão simétrica).
- Verificação local: `./scripts/check-assets.sh` · `./scripts/check-canon.sh` ·
  `./scripts/eval.sh`.
