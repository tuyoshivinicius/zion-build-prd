---
name: zion-prd-trace
description: Reconcilia a tabela de rastreabilidade (seção 12 da PRD) a partir das specs/*/spec.md — RF↔spec e status ☐/◐/● derivados por máquina. Use para "atualizar a rastreabilidade", "reconciliar a tabela RF↔spec" ou depois de fatiar/implementar uma fatia. Rodável a qualquer momento.
argument-hint: "(sem argumento — trabalha sobre docs/PRD.md e specs/)"
metadata:
  author: zion-build-prd
user-invocable: true
disable-model-invocation: false
---

# zion-prd-trace — Rastreabilidade com mecânica (Passo 6)

Reconcilia a **seção 12** de `docs/PRD.md` (tabela `RF-xx ↔ specs/###`) a partir da §6 da PRD e das
`specs/*/spec.md`. A tabela é um **artefato derivado**, não mantido à mão: "viva" significa *"viva
enquanto você roda `/zion-prd-trace`"*. O script **reconcilia e grava**; o humano **decide**. Contrato
de 5 fases; gates aconselham.

## Fase 0 — Pré-requisito (aconselha)
`docs/PRD.md` deve existir com a **seção 6** (RF por épico) e idealmente a **seção 12**. Faltando →
avise ("recomendo `/zion-prd-write` e `/zion-prd-decompose` antes") e pergunte se segue. Não bloqueie.

## Fase 1 — Validar entrada bruta
Sem texto novo — trabalha sobre `docs/PRD.md` + `specs/`.

## Fase 2/3 — Reconciliar (roda o script)
Rode o reconciliador diretamente do `references/` da skill (autocontido):

    bash references/trace-prd.sh docs/PRD.md specs

Ele regenera RF/Descrição/Épico da §6, recomputa Feature/Spec e Status das `specs/`, **preserva** a
coluna Release, reescreve a §12 e imprime um resumo (linhas atualizadas, transições de status, avisos).
O git é o desfazer.

## Fase 4 — Validar saída (aconselha)
Ecoe o resumo e os avisos **com autoridade**, em tom advisório — não reverta:
- **RF órfão** — uma spec declara um `RF-xx` que não existe na §6: corrija o typo na spec ou registre
  a decisão perdida na PRD.
- **Spec intraçável** — um `spec.md` sem a linha `**RF cobertos:**`: adicione-a para a fatia entrar na
  cadeia (a ponte `/zion-prd-specify-prompt` já pede essa linha no prompt do specify).
- **RF descoberto** — um `RF-xx` in-scope ainda sem spec: permanece ☐ pendente (informativo).

Aponte a próxima ação: rode `/zion-prd-trace` de novo após a próxima fatia (ou use
`bash references/trace-prd.sh docs/PRD.md specs --check` em Fases 4 de outras skills / no CI para uma
leitura read-only que sai 1 se houver drift/avisos).

## Saída
A seção 12 de `docs/PRD.md` reconciliada + o resumo/avisos ecoados. **Handoff:** commit dos artefatos
(`/git-commit`), e a próxima fatia da fila segue para `/zion-prd-specify-prompt`.
