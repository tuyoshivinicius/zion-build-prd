# Discovery iterativo — retomar/revisar o `docs/discovery.md`

> **Origem:** pedido do usuário — "ser capaz de fazer várias sessões de discovery".
> **Data:** 2026-07-18. **Esforço:** Baixo. **Escopo:** modo de idempotência em 1 skill
> (`/zion-prd-discovery`) + 1 linha em `assets/process-context.md` (sincronizada aos
> `references/`) + nota no `docs/como-usar.md`.

## Problema

O Estágio 1 (`/zion-prd-discovery`) é do-zero: a Fase 2/3 delega ao `superpowers:brainstorming`
com o enquadramento fixo e **grava** `docs/discovery.md`, sem considerar um arquivo já existente —
uma re-execução tende a sobrescrever. Mas a descoberta raramente fecha numa sentada: a pessoa para
no meio (só visão e persona prontas), volta depois de aprender algo (feedback, pesquisa) e quer
expandir escopo, ou já tem downstream (ADRs/PRD) e precisa saber que mexer no discovery pode
desatualizá-lo.

A skill irmã `/zion-prd-write` **já resolve isso** para a PRD: a Fase 0 dela detecta `docs/PRD.md`
existente e entra em **modo revisar** ("não sobrescreva; pressione seção a seção o que estiver
fraco"). O discovery não tem esse modo. A correção é dar ao discovery a mesma idempotência já
provada na casa.

## Decisões (discovery)

1. **Abordagem A — espelhar a idempotência do `/zion-prd-write`.** Auto-detecção por presença de
   arquivo (sem flag `--revise` a decorar; sem skill nova a duplicar). Consistente com o padrão da
   casa, superfície mínima.
2. **Discovery só avisa; não roteia propagação.** Se detectar downstream (`docs/adr/` com ADRs ou
   `docs/PRD.md`), emite um aviso advisório único apontando para `/zion-prd-evolve` — que é o dono
   do dia 2. Mantém a separação de responsabilidades: discovery cuida da descoberta, evolve roteia
   o impacto.
3. **Documento vivo, sem log de sessão (YAGNI).** `docs/discovery.md` é sempre o estado atual; cada
   sessão refina no lugar. O histórico das "várias sessões" fica no git, não numa seção de
   changelog dentro do arquivo.
4. **Sem `check-discovery.sh` novo.** O critério **discovery** (visão 1 frase ∧ ≥1 persona nomeada
   ∧ ≥1 "não faz") é simples e continua julgado inline na Fase 4, como hoje.

## Cenários cobertos

Os três momentos em que o usuário retorna para uma nova sessão — todos atendidos pelo mesmo modo
revisar:

| # | Cenário | Como o modo revisar atende |
|---|---------|----------------------------|
| S1 | **Discovery incompleto** — parou no meio | Lê o discovery atual; o brainstorming pressiona os blocos incompletos, preservando os que já estão sólidos |
| S2 | **Discovery "pronto", mudou de ideia** | O argumento vira a dica de *o que revisar* (ex.: "quero rever a persona"); o brainstorming expande/revisa só o alvo |
| S3 | **Downstream já existe** (ADRs/PRD) | Aviso advisório único apontando `/zion-prd-evolve` para a mudança que for estrutural (visão/persona/escopo) |

## A mudança na skill: `/zion-prd-discovery`

Contrato de 5 fases preservado; gates aconselham, nunca bloqueiam.

- **Fase 0 — Pré-requisito (hoje "Nenhum") passa a detectar modo:**
  - `docs/discovery.md` **não existe** → *modo do-zero* (comportamento atual, intacto).
  - `docs/discovery.md` **existe** → *modo retomar/revisar*: **não sobrescreve**; lê o discovery
    atual e o trata como ponto de partida.
  - **Detecção de downstream** (só no modo revisar): se `docs/adr/` tem ADR(s) **ou** `docs/PRD.md`
    existe → aviso advisório único: *"⚠ já há downstream baseado neste discovery; se a mudança for
    estrutural (visão/persona/escopo), rode `/zion-prd-evolve` para rotear o impacto."* Só avisa —
    não roteia, não bloqueia.

- **Fase 1 — Validar entrada bruta:** inalterada no modo do-zero. No modo revisar, o argumento é
  **opcional** e vira a dica de *o que revisar*; sem argumento, o brainstorming varre e pressiona
  os blocos fracos/incompletos.

- **Fase 2/3 — Formatar e auto-delegar:** o preflight de dependência (`superpowers:brainstorming`)
  fica igual. O **enquadramento** passado ao brainstorming ramifica:
  - *Modo do-zero:* enquadramento atual (refinar visão/persona/faz-não-faz do zero).
  - *Modo revisar:* "Aqui está o `docs/discovery.md` atual: «…». **Preserve** visão/persona/
    faz-não-faz que já estão sólidos; **pressione** o que está incompleto ou o que o usuário quer
    rever (ver argumento); não reescreva o que está bom. Mantenha os 3 blocos: visão-1-frase,
    persona nomeada, quadro faz/não-faz."

- **Fase 4 — Validar saída (aconselha):** inalterada — confere o critério **discovery** de
  `quality-rules.md` `#criterios-de-conclusao` e emite `✓`/`⚠`. Sem sobrescrita.

- **Saída:** `docs/discovery.md` (atualizado no lugar) — insumo do `/zion-prd-spike` e do
  `/zion-prd-write`, como hoje.

## Escopo — o que **não** muda (YAGNI)

- Sem arquivos novos, sem seção de log de sessão no discovery.md.
- Sem tocar nas skills downstream nem no `/zion-prd-evolve` (discovery só avisa).
- Sem `check-discovery.sh` novo.
- Sem flag de linha de comando; o modo é auto-detectado.

## Onde as edições caem

1. **`skills/zion-prd-discovery/SKILL.md`** — a mudança principal (Fase 0 detecção de modo +
   Fase 2/3 enquadramento ramificado). SKILL.md é editado direto (não é asset derivado).
2. **`assets/process-context.md`** — acrescentar ao item 1 da sequência uma nota curta de que o
   `/zion-prd-discovery` é idempotente (retomar/revisar sobre `docs/discovery.md` existente). Hoje o
   process-context não fala de idempotência de nenhum estágio (a do write vive só na SKILL.md dela),
   então esta é uma adição nova, não um espelho. Depois `./scripts/sync-assets.sh` propaga aos
   `references/` das skills que embarcam esse asset, e `./scripts/check-assets.sh` confirma que não
   há drift.
3. **`docs/como-usar.md`** — item na seção "Os gates em ação" documentando a idempotência do
   discovery (espelhando o item 3, que já documenta a do write), e nota correspondente no
   resumo/exemplo do Estágio 1.

## Verificação

- `./scripts/check-assets.sh` passa (sem drift após o sync).
- Releitura da SKILL.md: modo do-zero descrito intacto; modo revisar não sobrescreve; aviso de
  downstream é advisório e aponta o evolve.
- Roteiro manual dos três cenários (S1/S2/S3) confere que o enquadramento e o aviso corretos
  disparam em cada caso.
