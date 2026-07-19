# Mapa do Spec Kit — o ciclo e onde o harness entra e sai

> Fonte única do que cada `/speckit.*` faz, o que consome e o que produz, e das fronteiras do
> harness Zion Build PRD com esse ciclo. Autocontido: não depende de nenhum documento externo.
> Envelhece contra o **upstream do Spec Kit** (não contra o harness) — afinar aqui propaga por sync.

## O ciclo

| Passo | O que faz | Entrada | Saída |
|---|---|---|---|
| `/speckit.constitution` | Fixa os princípios do repositório inteiro (uma vez por projeto) | Os NFRs e restrições do produto | O documento de constitution do repositório |
| `/speckit.specify` | Abre uma feature a partir do o-quê/por-quê | A descrição da spec (sem stack) | A pasta da feature com o `spec.md` |
| `/speckit.clarify` | Resolve as ambiguidades do `spec.md` perguntando | O `spec.md` | O `spec.md` desambiguado |
| `/speckit.plan` | Decide o como/com-quê da feature | O `spec.md` + o que restringe a decisão | O `plan.md` (e artefatos de desenho) |
| `/speckit.checklist` | Deriva a lista de conferência da feature | `spec.md` + `plan.md` | O checklist da feature |
| `/speckit.tasks` | Quebra o plano em tarefas executáveis | O `plan.md` | O `tasks.md` |
| `/speckit.analyze` | Confere consistência entre spec, plano e tarefas | `spec.md` + `plan.md` + `tasks.md` | Os achados de inconsistência |
| `/speckit.implement` | Executa as tarefas | `tasks.md` (+ `plan.md`, constitution) | O código da feature |

O ciclo por feature é `specify → clarify → plan → checklist → tasks → analyze → implement`; a
`constitution` é bootstrap do repositório, não passo de feature.

## Onde o harness entra e sai

O harness **monta prompts e para** — nunca dispara um `/speckit.*` por você. São três pontes:

- `/zion-prd-constitution-prompt` → prompt do `/speckit.constitution`, com princípios decidíveis
  derivados dos NFRs e restrições da PRD. Bootstrap, uma vez por projeto.
- `/zion-prd-specify-prompt` → prompt do `/speckit.specify` de **uma** spec do backlog, blindado
  contra vazamento de fronteira e com o elo de rastreabilidade pedido.
- `/zion-prd-plan-prompt` → prompt do `/speckit.plan` de **uma** feature, injetando os ADRs
  confirmados (e a prosa estrutural do documento de arquitetura do produto, quando existe) como
  restrição a honrar. É a única ponte que encosta no "como".

Fora das pontes, o harness volta a aparecer só no fim: rodar `/zion-prd-trace` depois do
`implement` é o **ritual de fim de spec** — reconcilia a rastreabilidade, o backlog e os blocos
derivados do documento de arquitetura.

## O que o harness não faz nesse ciclo

`clarify`, `checklist`, `tasks`, `analyze` e `implement` são do Autor: o harness não tem ponte para
eles e não os executa. Quem quiser que o canon do produto chegue a esses passos instala a regra
versionada no repositório do produto com `/zion-speckit-install` — é a rede de segurança quando a
ponte é pulada, não uma automação do ciclo.
