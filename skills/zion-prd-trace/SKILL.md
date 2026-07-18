---
name: zion-prd-trace
description: Reconcilia a rastreabilidade da PRD (§12) e o backlog de fatias (docs/backlog.md) a partir das specs/*/spec.md — RF↔spec, fatia↔spec e status ☐/◐/● derivados por máquina. É o ritual de fim de fatia. Use para "atualizar a rastreabilidade", "reconciliar a tabela/o backlog" ou depois de fatiar/implementar uma fatia. Rodável a qualquer momento.
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
Aconselhe também sobre `docs/backlog.md` ausente ("recomendo `/zion-prd-decompose` antes"). Backlog
ausente **não** impede a reconciliação da §12 — e PRD ausente não impede a do backlog.

## Fase 1 — Validar entrada bruta
Sem texto novo — trabalha sobre `docs/PRD.md` + `specs/`.

## Fase 2/3 — Reconciliar (roda o script)
Rode o reconciliador diretamente do `references/` da skill (autocontido):

    bash references/trace-prd.sh docs/PRD.md specs

Ele regenera RF/Descrição/Épico da §6, recomputa Feature/Spec e Status das `specs/`, **preserva** a
coluna Release, reescreve a §12 e imprime um resumo (linhas atualizadas, transições de status, avisos).
O git é o desfazer.

Rode também o reconciliador do backlog:

    bash references/trace-backlog.sh docs/backlog.md specs

Ele recomputa as colunas de máquina (Spec, Status) do backlog casando `specs/###-<slug>` ⇔ slug por
sufixo, **preserva** as colunas humanas e a ordem das linhas, e imprime as transições de status, os avisos
e o **quadro de fatias**.

## Fase 4 — Validar saída (aconselha)
Ecoe o resumo e os avisos **com autoridade**, em tom advisório — não reverta:
- **RF órfão** — uma spec declara um `RF-xx` que não existe na §6: corrija o typo na spec ou registre
  a decisão perdida na PRD.
- **Spec intraçável** — um `spec.md` sem a linha `**RF cobertos:**`: adicione-a para a fatia entrar na
  cadeia (a ponte `/zion-prd-specify-prompt` já pede essa linha no prompt do specify).
- **RF descoberto** — um `RF-xx` in-scope ainda sem spec: permanece ☐ pendente (informativo).

Do lado do backlog, ecoe com o mesmo tom:
- **Fatia sem spec** — a fatia ainda não tem `specs/###-<slug>` (permanece ☐; informativo).
- **Spec órfã** — um diretório `specs/###-nome` que não casa nenhum slug: o slug divergiu (typo) ou a
  spec nasceu fora do backlog → registre a fatia ou renomeie.
- **Divergência de escopo** — os RFs da linha da fatia ≠ a linha `**RF cobertos:**` da spec casada:
  corrija a spec ou o backlog (o humano decide).
- **Slug duplicado / Colisão de casamento** — a primeira linha / o menor prefixo numérico vence, com aviso.

Ecoe o **quadro de fatias** (`● / ◐ / ☐` + a próxima fatia ☐ da fila) — a visibilidade num comando só.

Aponte a próxima ação: rode `/zion-prd-trace` de novo após a próxima fatia (ou use
`bash references/trace-prd.sh docs/PRD.md specs --check` em Fases 4 de outras skills / no CI para uma
leitura read-only que sai 1 se houver drift/avisos).

## Saída
A seção 12 de `docs/PRD.md` **e** `docs/backlog.md` reconciliados + os resumos/avisos e o quadro de fatias
ecoados. Rodar `/zion-prd-trace` após `/speckit.implement`/`converge` é o **ritual de fim de fatia**.
**Handoff:** commit dos artefatos (`/git-commit`), e a próxima fatia ☐ da fila segue para
`/zion-prd-specify-prompt`.
