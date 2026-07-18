# Rename "fatia" → "spec" — Design

**Data:** 2026-07-18
**Status:** Aprovado

## Problema

O harness usa três nomes para granularidades vizinhas: "fatia" (a unidade vertical do
backlog), "épico" (agrupador de RFs) e "spec" (o artefato do Spec Kit). Como cada fatia
vira exatamente uma spec no Spec Kit (slug da fatia = nome da pasta `specs/###-<slug>` e
da branch), manter dois nomes para a mesma unidade gera atrito de vocabulário. Decisão:
a unidade passa a se chamar **spec**, convergindo com a nomenclatura do Spec Kit.

**Escopo confirmado com o usuário:** só "fatia" é renomeada. "Épico" permanece — no repo
ele NÃO está na mesma granularidade: agrupa RFs na §6 e contém várias specs (hierarquia
RF → épico → spec). O flag `--epico E<k>` do decompose fica intocado.

## Decisões

1. **Unidade → "spec"** (feminino: "a spec"). Hierarquia passa a ser RF → épico → spec.
2. **O verbo permanece:** "fatiar", "fatiamento", "refatiar", "re-fatiamento" continuam
   nomeando o ato de cortar (INVEST/SPIDR). Ex.: "fatiar cada épico em specs verticais",
   "spec horizontal → refatiar pelos eixos do SPIDR", "a spec zero é o walking skeleton",
   "backlog de specs".
3. **Total, sem retrocompatibilidade** (escolha explícita do usuário): o parser do
   `trace-backlog.sh` só aceita o formato novo. Backlogs existentes migram à mão
   (renomear dois cabeçalhos — 1 linha), documentado no `docs/como-usar.md`.
4. **Desambiguação com o Spec Kit:** "spec" = a unidade de trabalho; os artefatos dela
   são "o `spec.md`" e "a pasta `specs/###-<slug>`". Frases que ficariam tautológicas
   ("o slug da fatia vira o nome da spec") são reescritas ("o slug da spec vira o nome
   da pasta `specs/###-<slug>` e da branch").

## Artefatos mecânicos

### Backlog (`assets/templates/backlog.md`, canônico)

Cabeçalho novo:

```
| Spec (slug) | Demo (1 frase) | RFs | Release | Pasta | Status |
```

- A coluna humana `Fatia (slug)` vira **`Spec (slug)`**.
- A coluna de máquina `Spec` (link para `specs/###-<slug>`) vira **`Pasta`** — elimina a
  colisão de nomes.
- Preâmbulo atualizado: "backlog de specs", "colunas de máquina **Pasta** e **Status**",
  colunas humanas Spec/Demo/RFs/Release.
- Legenda de status: `◐ em spec` fica ambíguo quando a unidade se chama spec → vira
  **`◐ em especificação`**.
- Cópia sincronizada para `zion-prd-decompose` via `sync-assets.sh`.

### `scripts/trace-backlog.sh` (canônico + cópias em trace e decompose)

- Parser: coluna humana casada por substring **`slug`**; coluna de máquina por **`pasta`**.
  Sem fallback para `fatia`/`spec` antigos.
- Emite `◐ em especificação` no lugar de `◐ em spec`.
- Comentários, avisos e mensagens de erro trocam "fatia" (substantivo) por "spec".
- Backlog no formato antigo → tabela canônica não reconhecida, mesmo comportamento de
  hoje para tabela ausente.

### Fixtures e testes

- `scripts/fixtures/backlog/*.md` e `scripts/fixtures/skills/decompose/*/backlog.md`
  migram para o cabeçalho novo e a legenda nova.
- `scripts/test-trace-backlog.sh` atualizado para as expectativas novas.

## Prosa viva (unidade → "spec")

- **Assets canônicos:** `assets/quality-rules.md`, `assets/process-context.md`,
  `assets/templates/prd-skeleton.md` (§12: "RF → épico → spec") — seguidos de
  `sync-assets.sh` para atualizar as cópias em `skills/*/references/`.
- **Skills:** `SKILL.md` das 9 skills zion (decompose, specify-prompt, trace, evolve,
  plan-prompt, write, discovery, spike, constitution-prompt) — descrições,
  argument-hints e corpo. O hint do decompose mantém o verbo: "re-fatiar só um épico".
- **Docs:** `docs/guia-prd-para-spec-kit.md`, `docs/como-usar.md` (inclui a nota de
  migração do backlog antigo), `README.md`.
- **Fixtures de prosa** usados pela avaliação: `scripts/fixtures/prd-clean.md`,
  `scripts/fixtures/prd-evolve/`, `scripts/fixtures/skills/**` (ex.: `esperado.md`),
  para os testes continuarem coerentes com as regras.

## Fora do escopo (intocados)

- Histórico datado: `docs/superpowers/plans/*`, `docs/superpowers/specs/*`,
  `docs/critica-zion-build-prd.md`, `docs/avaliacao-harness.md`.
- `trace-prd.sh` e a tabela §12: já usam `Feature / Spec`; nada muda no parser (só a
  frase descritiva no skeleton da PRD).
- Nomes de diretórios de fixture (ex.: `decompose/fatia-horizontal/`) podem ficar — são
  nomes de pasta de teste, não prosa; o conteúdo (`esperado.md` etc.) muda se citar a
  unidade.
- O conceito e o nome "épico".

## Validação

- `scripts/test-trace-backlog.sh`, `scripts/test-check-prd.sh` e `scripts/check-assets.sh`
  verdes (sync em dia).
- Grep final nos arquivos vivos: "fatia" só sobrevive como verbo/ato (fatiar, fatiamento,
  refatiar) — nunca como substantivo da unidade.
