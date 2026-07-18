# Design — NFR de experiência: o carregador forte (A2)

> Spec de mudança do **harness** (não de produto do usuário). Nasce da alternativa **A2** do estudo
> `docs/estudos/discovery-ux-design.md`. Sujeita ao dever de canonização (`CLAUDE.md`): toda mudança
> de comportamento reflete em `docs/prd.md` e `docs/architecture.md` no mesmo commit.

## Problema

O backlog decomposto (`RF-05`) não se preocupa com experiência, e o app resultante fica rico em
função e pobre de uso. A dor mora no backlog, mas o sinal precisa nascer antes e **sobreviver**
discovery → PRD → decomposição → backlog. Hoje nada carrega esse sinal, e nada de máquina acusa sua
ausência.

## Decisão

Introduzir um **carregador forte**: a qualidade de experiência vira um **NFR mensurável** que viaja
por um único marcador machine-legível — `Superfície de uso: sim/não` — nascido no discovery e
cobrado por um verificador que **aconselha** (nunca bloqueia) tanto na PRD quanto no backlog.

Quatro decisões fechadas no discovery desta spec (todas do Autor):

1. **Gatilho** — pergunta barata e advisória no discovery; `não` é o default. Produto sem superfície
   de uso (lib headless, backend puro, cron) nunca vê o bloco de experiência nem trip a nenhum check.
2. **Força do verificador** — carregador **forte**: um verificador novo que aconselha, não só prosa.
3. **Âncora** — marcador **na própria PRD** (check self-contained, contrato 1-arquivo preservado);
   o NFR de experiência é distinguido por uma **tag** `(experiência)`.
4. **Alcance** — o carregador de máquina vai **até o backlog** (âncora por spec), não para na PRD.

## O carregador, ponta a ponta

Um único sinal — `Superfície de uso: sim/não` — nasce no discovery e cavalga o pipeline inteiro;
tudo a jusante deriva dele.

```
discovery.md          PRD.md §7              backlog.md           check (aconselha)
─────────────         ──────────             ──────────           ────────────────
Superfície: sim   ──▶ Superfície: sim    ──▶ (herdado)       ┌──▶ limb-PRD:  sim & nenhum
+ bloco Experiência   NFR-0x (experiência)   coluna Âncora-exp│    NFR (experiência) → ⚠
(prosa, na persona)   : <=N passos       ──▶ ≥1 spec c/ âncora└──▶ limb-backlog: sim & nenhuma
                                                                   spec com âncora → ⚠
```

O gate é **`não` por default**. Zero peso morto para produto sem superfície de uso.

## Componentes

### 1. Discovery (`RF-01`) — captura + gate

- Passo **advisório** novo, uma pergunta: *"o usuário opera uma superfície de uso (tela, CLI, API
  que alguém maneja)?"*. Aconselha, não bloqueia (`RN-01`).
- Em **sim**, o enquadramento do `superpowers:brainstorming` ganha um 4º item de captura — a camada
  A1, em **prosa**: contexto de uso, expectativas, e a qualidade de experiência que o produto
  precisa transmitir. Sempre no nível de o-quê — *"o usuário percebe X"*, nunca *"tela Y"*.
- `docs/discovery.md` ganha:
  - uma linha `Superfície de uso: sim/não`;
  - quando `sim`, um bloco **Experiência** em prosa, ancorado na persona nomeada.
- Em **não**, skip silencioso — o fluxo fica idêntico ao de hoje.
- **Idempotência preservada:** no modo retomar/revisar, o passo pressiona o bloco de experiência só
  se estiver incompleto; não reescreve o que já está sólido (como os demais blocos).

### 2. PRD write (`RF-04`) — carrega o marcador, aterrissa o NFR

- `prd-write` lê o marcador do discovery e o **carrega para a §7**: uma linha `Superfície de uso:
  sim` no cabeçalho da seção de NFRs.
- Quando `sim`, pede ao Autor **≥1 NFR de experiência**, tagueado para ser machine-legível:
  `NFR-0x (experiência): tarefa-núcleo concluída em ≤N passos`. Carrega um número, como todo NFR.
  Fronteira já legal (NFR mensurável); a tag `(experiência)` é o marcador que o check casa.
- `assets/templates/prd-skeleton.md` (fonte única) ganha a linha do marcador e um slot de NFR
  tagueado. O `sync-assets.sh` regenera os `references/` derivados.

### 3. Decompose (`RF-05`) — ancora no backlog

- `assets/templates/backlog.md` (fonte única) ganha uma **coluna humana** `Âncora de experiência`,
  ao lado de `Demo`.
- Quando surface=sim, o passe do `brainstorming` preenche a âncora na(s) spec(s) que **tocam** a
  superfície — **≥1, não toda spec**. Spec puramente de backend deixa a âncora em branco (evita o
  falso-positivo de exigir âncora onde não há superfície).
- A **Fase 4 (INVEST)** ganha um braço de experiência no teste-relâmpago: *"esta spec, onde toca a
  superfície, demonstra a experiência — ou só a função?"* — advisório (`RN-01`).
- `trace-backlog.sh` já preserva colunas humanas na reconciliação; a âncora sobrevive ao re-seed
  sem edição à mão (`RN-04`).

### 4. O verificador (`RF-11`) — `check-experiencia.sh`

Script novo `check-experiencia.sh <PRD> [backlog]`. Contrato comum do repo:
`exit 0 limpo · 1 achados · 2 erro de uso`. **Aconselha** — lido pela Fase 4, nunca reverte trabalho
(`NFR-05`, `ADR-004`).

Dois achados advisórios:

- **limb-PRD** — `Superfície de uso: sim` ∧ nenhum NFR tagueado `(experiência)` na §7
  → ⚠ *"produto com superfície mas sem âncora de experiência na PRD"*.
- **limb-backlog** — PRD com surface=sim ∧ backlog sem nenhuma linha com `Âncora de experiência`
  preenchida → ⚠ *"produto com superfície mas nenhuma spec ancora a experiência"*.

Invocação:

- `prd-write` Fase 4 → `check-experiencia.sh docs/PRD.md` (só limb-PRD; sem arg de backlog, o
  limb-backlog é pulado).
- `decompose` Fase 4 → `check-experiencia.sh docs/PRD.md docs/backlog.md` (ambos os limbs).

**Escopo do check:** verifica **presença** da âncora, não vazamento visual. O denylist de
`check-prd.sh` permanece **stack-only** — detectar "tela" vazando continua julgamento humano na
fronteira, como hoje. O check não tenta decidir por máquina se um NFR de experiência descreve uma
tela.

**Home do script (decidido):** script novo dedicado, não extensão do `check-prd.sh`. A política do
carregador de experiência é uma família de regra coesa em um lugar só — um script, um auto-teste, um
par de fixtures — espelhando `check-estudo.sh`. Mantém o `check-prd.sh` focado na fronteira.

### 5. Avaliação mecânica (`RF-12`, `NFR-04`)

- Auto-teste `test-check-experiencia.sh` contra fixtures pareadas **limpa/suja** em
  `scripts/fixtures/` (`NFR-04`: 100% dos verificadores com auto-teste de fixture limpa e suja).
- Agregado por `scripts/eval.sh`; a camada mecânica completa continua sob o orçamento de 60s
  (`NFR-01`).

### 6. Governança — ADR-014 + canonização (mesmo commit)

- **ADR-014** — *"Qualidade de experiência é NFR carregado, com verificador que aconselha"*. É a
  decisão estruturante. **Evidência:** este design + o estudo `discovery-ux-design.md` (decisão
  dada — o Autor escolheu A2, `ADR-006`). **Honra `ADR-004`** (aconselha); não toca nenhum outro
  ADR; `NFR-02`/`ADR-007` intactos (nenhuma dependência externa nova). Criado via `/zion-adr-new`.
- **Canonização no mesmo commit** (`CLAUDE.md`):
  - `docs/prd.md §6` — texto de `RF-01`, `RF-04`, `RF-05`, `RF-11` atualizado.
  - `docs/prd.md §12` — linha do artefato de `RF-11` ganha `check-experiencia.sh`.
  - `docs/prd.md §13` — linha de changelog (cenário C2 — comportamento de RF existente muda; mais o
    artefato de script novo).
  - `docs/architecture.md §2` — ADR-014 no índice.
  - `docs/architecture.md §3` — `check-experiencia.sh` e `test-check-experiencia.sh` na tabela de
    scripts.
  - `assets/quality-rules.md` — cláusula de critério de conclusão (discovery ganha o gate;
    prd/decompose ganham a âncora) + nota de que experiência entra como **NFR mensurável, nunca
    tela**.
- Os guards `check-canon.sh` e `check-assets.sh` (pre-commit + CI) validam que o canon e os
  derivados batem.

## Fronteira o-quê/como

- A captura de UX é sempre **o-quê**: *"o usuário conclui a tarefa-núcleo em ≤N passos"*,
  *"o usuário percebe X"* — nunca arranjo de tela.
- O NFR de experiência é NFR mensurável — já dentro do que a fronteira admite
  (`quality-rules.md#fronteira`).
- Nenhum wireframe, critério de aceite detalhado ou tela entra na PRD ou no prompt do specify. O
  "como" da experiência (componentes, layout) continua morando no `plan.md`.

## Não faz (out of scope)

- **Não** detecta por máquina vazamento visual ("tela") — o denylist fica stack-only; a guarda de
  tela continua humana.
- **Não** força NFR de experiência em todo produto — só quando surface=sim.
- **Não** exige âncora em **toda** spec — ≥1 spec que toca a superfície basta.
- **Não** adiciona dependência externa (`NFR-02` intacto); a exploração de UX usa o
  `brainstorming` já existente.
- **Não** toca o specify-prompt (`RF-07`) nem o trace (`RF-09`): o alcance de máquina para no
  backlog, não no `spec.md` gerado pelo Spec Kit.
- **Não** bloqueia o Autor em gate algum (`RN-01`, `NFR-05`).

## Critérios de conclusão

- Discovery, quando surface=sim, grava a linha `Superfície de uso: sim` e o bloco Experiência; quando
  não, nada muda.
- PRD com surface=sim carrega a linha na §7 e ≥1 NFR tagueado `(experiência)` com número.
- Backlog com surface=sim tem ≥1 spec com `Âncora de experiência` preenchida.
- `check-experiencia.sh` emite os dois achados corretos nas fixtures suja/limpa; auto-teste passa;
  `eval.sh` verde sob 60s.
- Canon reflete tudo no mesmo commit; `check-canon.sh` e `check-assets.sh` verdes.
- ADR-014 aceito, indexado, com evidência presente (`check-adr.sh` verde).

## Próximo passo

`superpowers:writing-plans` para o plano de implementação (multi-fase). ADR-014 nasce via
`/zion-adr-new` durante a execução; canon reflete no mesmo commit.
