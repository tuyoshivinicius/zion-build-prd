---
name: zion-prd-trace
description: Reconcilia a rastreabilidade da PRD (§12), o backlog de specs (docs/backlog.md) e os blocos derivados do docs/architecture.md do produto (índice de ADRs, visão do backlog) a partir das specs/*/spec.md — RF↔spec, spec↔pasta e status ☐/◐/● derivados por máquina, com o veredito advisório do check de arquitetura ecoado. É o ritual de fim de spec. Use para "atualizar a rastreabilidade", "reconciliar a tabela/o backlog" ou depois de fatiar/implementar uma spec. Rodável a qualquer momento.
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

Ele recomputa as colunas de máquina (Pasta, Status) do backlog casando `specs/###-<slug>` ⇔ slug por
sufixo, **preserva** as colunas humanas e a ordem das linhas, e imprime as transições de status, os avisos
e o **quadro de specs**.

Se `docs/architecture.md` existir no repo do produto, rode também o reconciliador dos blocos
derivados da arquitetura (ADR-015):

    bash references/trace-arquitetura.sh docs/architecture.md docs/adr docs/backlog.md specs

Ele regenera **só** o conteúdo dos blocos `zion:adr-index` (§3 — o mapa de decisões vigentes por
área, com o que cada uma fixou e as specs que a exercitam), `zion:backlog-view` (§4) e
`zion:narrativa-avisos` (§1 — supersessão e defasagem da âncora). A prosa do Autor entre
`zion:narrativa` **nunca é tocada** (ADR-018). O argumento `specs` é o que permite derivar as specs
de cada decisão pela linha `**ADRs honrados:**` do `spec.md`; spec sem essa linha simplesmente não
aparece no mapa (o dever de origem é advisório). `docs/architecture.md` ausente → aconselhe
`/zion-speckit-install` (informativo; não impede o resto do ritual).

## Fase 4 — Validar saída (aconselha)
Ecoe o resumo e os avisos **com autoridade**, em tom advisório — não reverta:
- **RF órfão** — uma spec declara um `RF-xx` que não existe na §6: corrija o typo na spec ou registre
  a decisão perdida na PRD.
- **Spec intraçável** — um `spec.md` sem a linha `**RF cobertos:**`: adicione-a para a spec entrar na
  cadeia (a ponte `/zion-prd-specify-prompt` já pede essa linha no prompt do specify).
- **RF descoberto** — um `RF-xx` in-scope ainda sem spec: permanece ☐ pendente (informativo).

Do lado do backlog, ecoe com o mesmo tom:
- **Spec sem pasta** — a spec ainda não tem `specs/###-<slug>` (permanece ☐; informativo).
- **Spec órfã** — um diretório `specs/###-nome` que não casa nenhum slug: o slug divergiu (typo) ou a
  spec nasceu fora do backlog → registre a spec ou renomeie.
- **Divergência de escopo** — os RFs da linha da spec ≠ a linha `**RF cobertos:**` da spec casada:
  corrija a spec ou o backlog (o humano decide).
- **Slug duplicado / Colisão de casamento** — a primeira linha / o menor prefixo numérico vence, com aviso.

Ecoe o **quadro de specs** (`● / ◐ / ☐` + a próxima spec ☐ da fila) — a visibilidade num comando só.

Do lado da arquitetura (quando `docs/architecture.md` existe), ecoe também o veredito advisório de:

    bash references/check-arquitetura.sh .

- **Marcador ausente** (aviso do `trace-arquitetura.sh` da Fase 2/3; o check acusa o efeito como
  `adr-index-defasado`/`backlog-view-defasada`) — o documento perdeu os marcadores
  `zion:adr-index`/`zion:backlog-view`: restaure as §3/§4 do esqueleto para os blocos voltarem a
  reconciliar.
- **regras-ausentes / regras-defasadas** — o bloco do `CLAUDE.md` nunca foi instalado ou ficou
  velho após upgrade: rode/re-rode `/zion-speckit-install`.
- **narrativa-ausente / ancora-ausente** — a §1 nunca foi ditada, ou a prosa perdeu a âncora nos
  ADRs: aconselhe `/zion-prd-decompose --narrativa` (a prosa é do Autor; nunca a reescreva por ele).
- **narrativa-superseded / narrativa-defasada** (no bloco de avisos que você acabou de reconciliar)
  — a narrativa cita uma decisão substituída, ou decisões aceitas ficaram de fora dela: mesma cura,
  `/zion-prd-decompose --narrativa`, que mostra o rascunho novo lado a lado e só grava sob confirmação.
- **integracoes-nao-declaradas / secao-ausente** — a §2 ainda tem o placeholder do esqueleto, ou o
  documento perdeu uma seção: aconselhe, não corrija por ele (declarar
  `_(nenhuma integração externa)_` é saída válida).

Aponte a próxima ação: rode `/zion-prd-trace` de novo após a próxima spec (ou use
`bash references/trace-prd.sh docs/PRD.md specs --check` em Fases 4 de outras skills / no CI para uma
leitura read-only que sai 1 se houver drift/avisos).

## Saída
A seção 12 de `docs/PRD.md`, `docs/backlog.md` **e os blocos derivados de `docs/architecture.md`
(mapa de decisões, visão do backlog e avisos de narrativa)** reconciliados + os resumos/avisos e o
quadro de specs ecoados. Rodar `/zion-prd-trace` após `/speckit.implement`/`converge` é o **ritual de fim de spec**.
**Handoff:** commit dos artefatos (`/git-commit`), e a próxima spec ☐ da fila segue para
`/zion-prd-specify-prompt`.
