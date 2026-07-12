# Skills autocontidas — remover a âncora ao `guia-prd-para-spec-kit.md`

- **Data:** 2026-07-12
- **Status:** Aprovado (design)
- **Autor:** Tuyoshi Vinicius

## Problema

As 5 skills `zion-prd-discovery`, `zion-prd-spike`, `zion-prd-write`, `zion-prd-decompose` e `zion-adr-new`
referenciam `docs/guia-prd-para-spec-kit.md` numa linha de orientação (ex.: *"Orquestra o
Passo N do guia `docs/guia-prd-para-spec-kit.md`"*). O procedimento operacional, as
quality-rules e a lógica de fronteira já vivem **dentro** de cada skill (ou em seus
`references/`); o guia funciona só como **âncora de "qual passo do processo eu sou"** e como
fonte da numeração `Passo N`.

O problema real que isso expõe: quando as skills são distribuídas via `npx skills` para
`.claude/skills/` de um projeto, a pasta `docs/` **não viaja junto**. Logo,
`docs/guia-prd-para-spec-kit.md` não existe no projeto instalado — o ponteiro já é uma
**referência quebrada** no momento da instalação. O README afirma que as skills são
"autocontidas", o que hoje não é estritamente verdade.

## Objetivo

Fazer cada uma das 5 skills **absorver** o contexto de processo de que precisa e **deixar de
depender** da âncora externa em `docs/`. O `guia-prd-para-spec-kit.md` permanece em `docs/`
como **fonte da verdade do processo, para o desenvolvedor** do Zion Build PRD — sem nenhuma
skill apontando para ele.

Decisões de design (confirmadas com o usuário):

- **Absorção enriquecida/autônoma:** cada skill deve se explicar sozinha, sem conhecimento
  externo do fluxo — não apenas remover o ponteiro.
- **Asset compartilhado → `references/`:** o bloco invariante de contexto vira um asset
  canônico único, sincronizado para o `references/` de cada skill pelo mesmo mecanismo que já
  serve `quality-rules.md`. A âncora deixa de ser externa (`docs/`) e passa a ser **interna à
  skill** (viaja no bundle).

## Solução

### 1. Novo asset canônico: `assets/process-context.md`

Arquivo compacto (~20 linhas), fonte única de verdade, contendo o **bloco invariante**
compartilhado por todos os estágios do harness:

1. **A sequência de estágios** — Descoberta → Spikes/ADRs → PRD → Decomposição → Spec Kit,
   cada estágio nomeando sua skill e seu artefato de saída, para que qualquer skill situe a si
   mesma e a seus vizinhos.
2. **A fronteira o-quê/por-quê × como/com-quê** — a PRD carrega *o-quê/por-quê*; o `plan.md`
   de cada feature carrega *como/com-quê*. O invariante que todo estágio guarda.

**Restrição crítica:** este arquivo **não pode apontar para o guia** (`guia-prd-para-spec-kit.md`)
nem para qualquer doc dev-only que não viaja no bundle, senão reintroduziria a referência
quebrada no projeto instalado. Caminhos de **artefatos que o próprio usuário produz** no projeto
dele (`docs/discovery.md`, `docs/PRD.md`, `docs/adr/`) são permitidos e esperados — não são
âncoras dev-only. O arquivo é 100% autocontido e user-facing. É uma *distilação* do guia mantida
à mão; o guia continua sendo a fonte completa — essa relação vive apenas neste spec e na cabeça
do mantenedor, nunca dentro do arquivo distribuído.

Conteúdo canônico:

```markdown
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
```

### 2. Wiring de sync (1 linha)

Adicionar ao `ASSET_MAP` em `scripts/asset-map.sh`:

```
"assets/process-context.md              zion-prd-discovery zion-prd-spike zion-prd-write zion-prd-decompose zion-adr-new"
```

Consequências automáticas (nenhuma mudança nos scripts em si):

- `scripts/sync-assets.sh` passa a gerar `skills/<skill>/references/process-context.md` nas 5
  skills. `zion-adr-new` ganha seu primeiro diretório `references/` — o `mkdir -p` do sync o cria.
- `scripts/check-assets.sh` e o workflow de CI (`check-assets`) passam a guardar o novo
  reference contra drift, sem alteração.
- O pre-commit hook (`.githooks/pre-commit`) já roda o sync a partir do `ASSET_MAP`; nada a
  mudar.

### 3. Edições nas 5 `SKILL.md`

Cada skill troca a linha de orientação que cita `docs/guia-prd-para-spec-kit.md` por uma versão
autocontida que aponta ao **reference local**, padronizando o vocabulário em **"Estágio N do
harness"** (que as skills já usam em título/descrição) e eliminando "Passo N do guia".

- **`zion-prd-discovery/SKILL.md`** (linha 13):
  `Orquestra o Estágio 1 do harness (Descoberta enxuta). Sequência completa dos estágios e a
  fronteira o-quê/como em `references/process-context.md`. Contrato de 5 fases; todos os gates
  **aconselham** (apontam e sugerem), nunca bloqueiam. Regras em `references/quality-rules.md`.`

- **`zion-prd-spike/SKILL.md`** (linha 13):
  `Orquestra o Estágio 2 do harness (Spikes técnicos + ADRs). Sequência dos estágios e fronteira
  o-quê/como em `references/process-context.md`. Contrato de 5 fases; gates aconselham. Regras em
  `references/quality-rules.md`.`

- **`zion-prd-write/SKILL.md`** (linhas 13–15):
  `Orquestra o Estágio 3 do harness (PRD enxuta). Sequência dos estágios e fronteira o-quê/como
  em `references/process-context.md`. Contrato de 5 fases; gates aconselham. Regras em
  `references/quality-rules.md`. Este é o coração do harness: a Fase 4 guarda a fronteira
  **o-quê/por-quê vs. como**.`

- **`zion-prd-decompose/SKILL.md`** (linha 13):
  `Orquestra o Estágio 4 do harness (Decomposição). Sequência dos estágios e fronteira o-quê/como
  em `references/process-context.md`. Contrato de 5 fases; gates aconselham. Regras em
  `references/quality-rules.md`.`

- **`zion-adr-new/SKILL.md`** (linhas 13–16):
  `Registra uma decisão estruturante como um ADR em `docs/adr/`, com as seções
  **Contexto / Decisão / Consequências / Status**. Use no Estágio 2 do harness (Spikes + ADRs) —
  ver `references/process-context.md` — para registrar as 2–3 decisões que mudam a PRD inteira,
  sustentadas por um spike que você de fato rodou.`

O texto exato pode ser ajustado na implementação, desde que: (a) nenhuma linha cite
`docs/guia-prd-para-spec-kit.md`; (b) cada skill aponte ao seu `references/process-context.md`
local; (c) o vocabulário seja "Estágio N do harness".

## Fora de escopo (deliberadamente)

- **Bridge skills** `zion-prd-constitution-prompt` e `zion-prd-specify-prompt`: não referenciam o guia
  hoje → não recebem `process-context.md` e ficam intocadas.
- **`docs/guia-prd-para-spec-kit.md`:** não muda. Segue como fonte da verdade dev-facing e pode
  continuar citando as skills (direção dev→skill é aceitável e desejada).
- **Histórico** (`docs/superpowers/**`) e `docs/como-usar.md`: intocados.
- **README:** nenhuma mudança obrigatória — a afirmação "skills autocontidas" apenas passa a ser
  verdadeira. (Ajuste opcional fica para outra oportunidade.)

## Critérios de conclusão / verificação

1. `assets/process-context.md` existe, é autocontido e **não cita** `guia-prd-para-spec-kit.md`
   nem qualquer doc dev-only (`grep -n "guia-prd-para-spec-kit" assets/process-context.md`
   vazio). Caminhos de artefatos do usuário (`docs/discovery.md`, `docs/PRD.md`, `docs/adr/`)
   são permitidos.
2. `scripts/asset-map.sh` tem a nova entrada.
3. `./scripts/sync-assets.sh` roda limpo e gera os 5 `references/process-context.md`.
4. `./scripts/check-assets.sh` retorna "check-assets: sem drift".
5. `grep -rn "guia-prd-para-spec-kit" skills/` retorna **vazio**.
6. Cada uma das 5 `SKILL.md` referencia `references/process-context.md` e usa "Estágio N do
   harness".
```
