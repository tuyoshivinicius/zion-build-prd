<!-- zion:speckit:v1:start -->
## Integração Zion ⇄ Spec Kit (instalado por /zion-speckit-install)

> Bloco versionado — re-rodar `/zion-speckit-install` substitui SÓ o que está entre os marcadores.
> Escreva suas regras fora deles.

### Canon declarado

`docs/discovery.md`, `docs/prd.md`, `docs/adr/`, `docs/backlog.md` e `docs/architecture.md` são as
fontes canônicas de produto e arquitetura deste repositório. Spec e plano nascem delas, não do
código.

### Fronteira de donos (um dono por pergunta)

- **Constitution** (Spec Kit) — princípios de repo inteiro (ponte `/zion-prd-constitution-prompt`).
- **`docs/adr/`** — decisões pontuais de repo inteiro, uma por ADR.
- **`docs/architecture.md`** — estrutura e prosa do Autor (§1–§2) + índices derivados (§3–§4,
  reconciliados por `/zion-prd-trace`; não editar à mão).
- **`plan.md`** de cada feature (Spec Kit) — o como daquela feature (ponte `/zion-prd-plan-prompt`).

### Recorte por passo (fronteira o-quê/como)

- `/speckit.specify` e `/speckit.clarify` leem **PRD e backlog** (o-quê); **nunca** ADRs nem
  `docs/architecture.md`.
- `/speckit.plan` lê **ADRs + `docs/architecture.md`**.
- `/speckit.implement` lê **plan + constitution**.

### Dever de origem (advisório — conselho, nunca trava)

Toda spec nasce do fluxo zion (`/zion-prd-specify-prompt`) e carrega no `spec.md` a linha de
rastreabilidade `**RF cobertos:** RF-xx`. Spec sem essa linha será acusada como **intraçável** por
`/zion-prd-trace`. O Autor decide.

### Ritual de fim de spec

- Implementação de uma spec termina → rode `/zion-prd-trace`.
- RF novo descoberto no caminho → rode `/zion-prd-evolve`.
<!-- zion:speckit:v1:end -->
