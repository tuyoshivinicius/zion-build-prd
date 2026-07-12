# Contexto de processo — harness Zion Build PRD

> Bloco invariante compartilhado pelos estágios do harness. Situa cada skill na jornada e fixa
> a fronteira que todo estágio guarda. Autocontido: não depende de nenhum documento externo.

## A sequência (o-quê → pronto para codar)

O harness conduz a autoria da PRD em estágios encadeados, cada um alimentando o próximo:

1. **Descoberta** (`/zion-prd-discovery`) — visão, persona, quadro faz/não-faz → `docs/discovery.md`.
2. **Spikes + ADRs** (`/zion-prd-spike`, `/zion-adr-new`) — provar as 2–3 decisões estruturantes com
   código descartável e registrá-las como ADRs em `docs/adr/` **antes** de fechar a PRD.
3. **PRD enxuta** (`/zion-prd-write`) — visão/escopo, `RF-xx` por épico (1 frase cada), NFRs com
   números, restrições (das ADRs) → `docs/PRD.md`. Sem comportamento detalhado nem stack.
4. **Decomposição** (`/zion-prd-decompose`) — PRD → épicos → story map → fatias verticais validadas
   por INVEST; walking skeleton como fatia zero; tabela de rastreabilidade injetada na PRD.
   **Handoff:** cada fatia priorizada entra no Spec Kit via `/speckit.specify`.
5. **Spec Kit por feature** — `constitution` e o ciclo
   `specify → clarify → plan → checklist → tasks → analyze → implement → converge` (fora do
   harness; pontes montadas por `/zion-prd-constitution-prompt` e `/zion-prd-specify-prompt`).

## A fronteira o-quê/por-quê × como/com-quê

A **PRD** carrega *o-quê / por-quê* (visão e escopo). O **`plan.md`** de cada feature carrega
*como / com quê* (stack e detalhe técnico). Se você está escrevendo linguagem, framework,
biblioteca, tela, contrato de API ou critério de aceite na PRD, parou no lugar errado → isso
vive no `spec.md`/`plan.md` da feature. **Todo estágio deste harness guarda essa fronteira.**
