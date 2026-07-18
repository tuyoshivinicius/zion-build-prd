# Contexto de processo — harness Zion Build PRD

> Bloco invariante compartilhado pelos estágios do harness. Situa cada skill na jornada e fixa
> a fronteira que todo estágio guarda. Autocontido: não depende de nenhum documento externo.

## A sequência (o-quê → pronto para codar)

O harness conduz a autoria da PRD em estágios encadeados, cada um alimentando o próximo:

1. **Descoberta** (`/zion-prd-discovery`) — visão, persona, quadro faz/não-faz → `docs/discovery.md`.
   Idempotente: rodar de novo sobre um `docs/discovery.md` existente **retoma/revisa** (não
   sobrescreve) — permite descoberta em várias sessões.
2. **Spikes + ADRs** (`/zion-prd-spike`, `/zion-adr-new`) — provar as 2–3 decisões estruturantes com
   código descartável e registrá-las como ADRs em `docs/adr/` **antes** de fechar a PRD.
3. **PRD enxuta** (`/zion-prd-write`) — visão/escopo, `RF-xx` por épico (1 frase cada), NFRs com
   números, restrições (das ADRs) → `docs/PRD.md`. Sem comportamento detalhado nem stack.
4. **Decomposição** (`/zion-prd-decompose`) — PRD → épicos → story map → specs verticais validadas
   por INVEST; walking skeleton como spec zero; tabela de rastreabilidade injetada na PRD e o backlog
   de specs `docs/backlog.md` (slug + demo + RFs por spec; Pasta/Status por máquina).
   **Handoff:** cada spec priorizada entra no Spec Kit via `/speckit.specify`.
5. **Spec Kit por feature** — `constitution` e o ciclo
   `specify → clarify → plan → checklist → tasks → analyze → implement → converge` (fora do
   harness; pontes montadas por `/zion-prd-constitution-prompt`, `/zion-prd-specify-prompt` e
   `/zion-prd-plan-prompt`). A ponte `plan-prompt` é a única que **encosta** no "como": monta o
   prompt do `plan` limitado a honrar os ADRs já provados.

## A fronteira o-quê/por-quê × como/com-quê

A **PRD** carrega *o-quê / por-quê* (visão e escopo). O **`plan.md`** de cada feature carrega
*como / com quê* (stack e detalhe técnico). Se você está escrevendo linguagem, framework,
biblioteca, tela, contrato de API ou critério de aceite na PRD, parou no lugar errado → isso
vive no `spec.md`/`plan.md` da feature. **Todo estágio deste harness guarda essa fronteira.**
