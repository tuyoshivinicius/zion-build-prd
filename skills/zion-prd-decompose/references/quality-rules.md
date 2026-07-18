# Regras de qualidade — harness PRD → Spec Kit

> Fonte única de verdade citada pelos comandos `prd-*`. Afinar o padrão de qualidade se faz **aqui**,
> num lugar só. Cada comando referencia as âncoras abaixo em vez de repetir regras.

## Fronteira o-quê/por-quê vs. como {#fronteira}

A PRD e o input do `/speckit.specify` carregam **o-quê / por-quê** (visão e escopo). O `plan.md` de
cada feature carrega **como / com quê** (stack e detalhe técnico).

**Pode entrar na PRD / no specify:**
- Visão, objetivos e métricas de negócio.
- Escopo faz/não-faz.
- Requisitos funcionais por épico (`RF-xx`), uma frase cada, descrevendo o resultado de valor.
- Regras de negócio invariáveis (`RN-xx`).
- NFRs mensuráveis (com número).
- Restrições vindas de ADRs.

**NÃO pode entrar (é do `plan.md`):**
- Linguagem, framework, bibliotecas.
- Critérios de aceite detalhados, telas/wireframes.
- Contratos de API, esquema de dados, estrutura de código.

**Teste de vazamento — frase que passa vs. frase que vaza:**

| Passa (o-quê/por-quê) | Vaza (como) |
|---|---|
| "O usuário edita o diagrama e vê a prévia atualizar ao digitar." | "Usar React + CodeMirror para renderizar a prévia." |
| "Alterações persistem entre sessões." | "Salvar o estado no localStorage via Zustand." |

Ao detectar vazamento, o comando aponta a linha ofensora e sugere movê-la para o `plan.md` da feature.

> A ponte `plan-prompt` é a única que **cruza** esta fronteira de propósito: monta o prompt do
> `/speckit.plan`, onde o "como" é decidido. Mesmo lá a guarda persiste, invertida — o plano fica
> **preso aos ADRs** já provados (veja `#anatomia-plan`), sem reabrir decisões.

## Critérios de conclusão por estágio {#criterios-de-conclusao}

Lidos pelas Fases 0 (pré-requisito) e 4 (validar saída) dos comandos.

- **discovery** (`docs/discovery.md`): tem visão em 1 frase ∧ ≥1 persona nomeada ∧ pelo menos um
  "não faz" explícito no quadro faz/não-faz.
- **spike** (`docs/adr/ADR-00x-*.md`): cada decisão estruturante tem um ADR com Contexto/Decisão/
  Consequências ∧ o ADR carrega **evidência do tipo certo para seu risco** (spike de código para
  risco de execução; fonte de pesquisa para risco de conhecimento; racional escrito para decisão
  dada — ver `#risco-do-spike`). A presença da evidência é verificada por `check-adr.sh` — a Fase 4
  roda o script e ecoa o veredito.
- **prd** (`docs/PRD.md`): escopo in/out explícito ∧ `RF-xx` agrupados por épico (1 frase cada) ∧
  NFRs com número ∧ **zero** stack / critério de aceite / tela. As três regras decidíveis
  (zero-stack, NFR-com-número, RF-por-épico) são verificadas por `check-prd.sh` — a Fase 4 roda o
  script e ecoa o veredito.
- **decompose**: existe backlog de fatias verticais priorizadas ∧ cada fatia passa no INVEST ∧
  walking skeleton é a fatia zero (R0) ∧ a tabela de rastreabilidade (§12) foi **semeada por
  `trace-prd.sh`** (não à mão) com uma linha por `RF-xx` in-scope. A tabela é um artefato **derivado**,
  reconciliado a qualquer momento por `/zion-prd-trace`; não é mantida à mão.
- **specify-prompt**: o prompt gerado declara resultado observável ∧ não cita stack ∧ RF-xx/ADR
  entram como contexto (referência), não como requisito. O zero-stack é verificado por
  `check-prd.sh specify -` sobre o prompt montado.
- **constitution-prompt**: o prompt gerado deriva princípios **decidíveis** (cada um com validador/
  limiar/teste) ∧ cada princípio rastreia a um NFR ou restrição de ADR ∧ **zero** princípio genérico
  ("código limpo", "boa cobertura").
- **plan-prompt**: o prompt gerado referencia o `spec.md` da feature ∧ injeta os ADRs confirmados
  como restrição (honrar, não re-decidir) ∧ deixa claro que o plano deve honrar cada ADR e cobrir
  o resultado observável do `spec.md`.

## Risco do spike {#risco-do-spike}

Base da classificação da Fase 1 de `/zion-prd-spike`: cada decisão estruturante endereça um tipo de
risco, e o risco escolhe o **meio da evidência**.

- **Risco de execução** — a dúvida **só se resolve rodando algo**: performance sob carga,
  compatibilidade, viabilidade de integração, comportamento observável. **Meio: spike de código** em
  `docs/adr/spikes/ADR-00x-<slug>/` (dir com `README.md` + artefatos descartáveis).
- **Risco de conhecimento** — trade-off **documentável sem rodar**: maturidade, licença, custo de
  manutenção, ecossistema, aderência conceitual. **Meio: pesquisa (deep-research) com fonte citada.**
- **Decisão dada** — a escolha **já chegou batida de fora** (política da org, restrição externa,
  padrão já estabelecido); não há dúvida a resolver rodando nem lendo. **Meio: racional escrito no
  próprio ADR** — quem/que autoridade decidiu e por quê.

Regra prática: se você decide lendo docs/benchmarks de terceiros, é **conhecimento**; se precisa do
*seu* caso rodando para confiar, é **execução**; se não há dúvida a provar — a decisão vem batida —
é **decisão dada**, e o lastro é registrar a autoridade, não prová-la. A presença da evidência do
tipo certo é verificada
por `check-adr.sh` — o script confere presença, o humano decide qualidade.

## INVEST e SPIDR {#invest}

**INVEST** — cada fatia vertical deve ser: **I**ndependente, **N**egociável, **V**aliosa,
**E**stimável, **S**mall, **T**estável.

**Teste-relâmpago:** *"esta fatia, sozinha, permite uma demo ponta-a-ponta?"* Se a resposta é "só a
UI" ou "só o back", a fatia é **horizontal** → refatie.

**SPIDR** — eixos para quebrar uma fatia grande: **S**pike, **P**ath (caminhos alternativos),
**I**nterface, **D**ata, **R**ules. Use quando uma fatia não passa no "Small" do INVEST.

**Walking skeleton:** a fatia zero (R0) prova o pipeline inteiro com o mínimo de funcionalidade.

## Anatomia do prompt do specify {#anatomia-specify}

O input do `/speckit.specify` é um prompt em **linguagem natural (prosa)**. O comando já tem o
próprio template e só preenche placeholders — então o prompt é **conteúdo, não formato**: nada de
tags XML, nada de ditar cabeçalhos/seções do `spec.md`. Em prosa, o prompt deve cobrir:

- **O resultado observável** — o que o usuário consegue fazer/ver ao final da fatia (o o-quê/por-quê).
  É o que o gate `/speckit.clarify` vai cobrar em seguida, então já o declara.
- **A guarda da fronteira, em prosa** — escreva explícito "não citar linguagem, framework ou
  bibliotecas; a stack fica no `plan`". Impede o "como" de vazar para o `specify`.
- **`RF-xx` e ADRs como contexto** — cite-os como referência ("Contexto: RF-01…"), não como
  requisitos a copiar.
- **A linha `**RF cobertos:**`** — peça que o `spec.md` inclua uma linha rotulada
  `**RF cobertos:** RF-xx, ...` com os RF que a fatia cobre. É o elo forward RF↔spec legível por
  máquina. O `check-prd.sh specify` verifica por máquina que o prompt **pede** essa linha (achado
  `rf-cobertos-ausente` quando falta); o `/zion-prd-trace` depois confere que o `spec.md` resultante a
  **tem** (aviso "Spec intraçável"). Declarar *quais* RF a fatia cobre é o-quê/rastreabilidade, não
  stack — não fere a fronteira sem-stack.

## Anatomia do prompt do constitution {#anatomia-constitution}

O input do `/speckit.constitution` é um prompt em **linguagem natural (prosa)**, montado a partir da
PRD. O comando já preenche o próprio template — então é **conteúdo, não formato**: nada de tags XML,
nada de ditar as seções ou o versionamento do artefato. Em prosa, o prompt deve cobrir:

- **A fonte, não o princípio pronto** — os NFRs (`NFR-xx`) e as restrições de ADRs como material de
  origem para derivar os princípios.
- **O pedido de derivação** — peça para **derivar** princípios decidíveis dessa fonte (um por
  NFR/restrição relevante).
- **A guarda da decidibilidade, em prosa** — escreva explícito "cada princípio tem um critério
  objetivo (validador / limiar numérico / teste) e rastreia a um NFR ou ADR; nada de genérico
  ('código limpo', 'boa cobertura')". Impede platitude de virar princípio.

## Anatomia do prompt do plan {#anatomia-plan}

O input do `/speckit.plan` é um prompt em **linguagem natural (prosa)** — montado a partir do
`spec.md` da feature (que o comando já carrega como fonte da verdade) e dos ADRs que o spike já
provou. É a única ponte que **entra** no "como", presa ao que foi decidido. O comando já tem o
próprio template — então é **conteúdo, não formato**: nada de tags XML, nada de ditar as seções do
`plan.md`, e **não repita os requisitos** (o `spec.md` já é carregado). Em prosa, o prompt deve
cobrir:

- **As decisões fechadas a honrar** — os **ADRs confirmados** (`ADR-00x: <decisão>`) como restrições:
  "honre cada ADR listado; não re-decida o que um ADR já fixou".
- **O pedido do plano técnico** — peça para descrever a stack, a arquitetura e as restrições técnicas
  que realizam o resultado observável do `spec.md` **dentro** dessas decisões.
- **A guarda secundária, em prosa** — "não expanda além do escopo do `spec.md`". É o que impede o
  spike de virar esforço órfão; o gate `/speckit.analyze` cobra isso depois.

## Denylist de stack {#denylist}

Termos de linguagem/framework/biblioteca que **não** podem aparecer na PRD nem no prompt do
`/speckit.specify` (vivem no `plan.md` da feature). O `check-prd.sh` extrai o bloco cercado abaixo e
casa cada termo **palavra inteira, case-insensitive** contra o alvo. Afinar a lista = editar aqui (o
sync propaga para os `references/`). Um termo por linha, minúsculo.

```denylist
react
react flow
vue
angular
svelte
zustand
redux
localstorage
dagre
elk
next.js
node.js
codemirror
tailwind
postgres
mysql
mongodb
redis
sqlite
prisma
graphql
django
flask
fastapi
express
webpack
vite
d3
three.js
typescript
```

## Dia 2 — evolução pós-release {#dia-2}

Depois da release 1, requisitos mudam. O ponto de entrada único é `/zion-prd-evolve`, que versiona a PRD
e roteia para os comandos donos de cada artefato, parando em cada gate. Uma mudança se classifica em um
ou mais **cenários canônicos** (pode combinar mais de um):

- **C1 — RF novo:** requisito que não existia. Toca a §6 (RF no épico certo ou num épico novo), o
  changelog (§13), o re-fatiamento **parcial** do épico e a tabela (§12 via trace).
- **C2 — RF alterado ou removido:** requisito muda de significado ou sai de escopo. Toca a §6, o §13, as
  fatias do épico afetado e a tabela; fatia já com `spec.md` → prompt de **re-specify** pela ponte.
- **C3 — Decisão revertida:** decisão estruturante caiu. Nasce um ADR que **substitui** o antigo
  (referência simétrica) + §8 (restrições) + §13 + aviso de revisar a `constitution`.

> Cuidado com a decisão que cai **disfarçada de requisito**: se uma mudança que parece só um RF alterado
> (C2) só se resolve trocando uma decisão já registrada num ADR, é **C3**.

### Changelog da PRD (§13) — regras decidíveis

A §13 "Histórico de mudanças" é uma tabela, **uma linha por mudança**, escrita por `/zion-prd-evolve`
(edição manual continua possível):

| Data | Cenário | Mudança | Motivo | Artefatos afetados |
|------|---------|---------|--------|--------------------|
| 2026-08-02 | C2 | `RF-07` alterado: exportar SVG em vez de PNG | feedback de usuários | ADR-002 → ADR-005 · fatia S4 re-especificada |

Regras que o `check-prd.sh` verifica sobre a §13 (a §13 é **opcional** — PRD sem ela, dia 1 ou pré-R8,
não dispara estes checks):

- Todo `RF-xx` citado no changelog **existe na §6** — ou a própria linha o declara **"removido"**.
- Todo `ADR-xxx` citado **existe em `docs/adr/`**.
- A coluna **Cenário** usa só **C1**, **C2** ou **C3**.
- Check cruzado sobre a §8: uma restrição apontando um ADR com `Status: Substituído por` é uma
  **restrição morta** → o script acusa.

### Supersessão de ADR — referência simétrica

Quando uma decisão cai (C3), `/zion-adr-new "<título>" --substitui ADR-<n>` cria o ADR novo e edita o
antigo, deixando uma referência **cruzada e simétrica**:

- No ADR novo (ADR-`<m>`): campo de cabeçalho `- **Substitui:** ADR-<n>`.
- No ADR antigo (ADR-`<n>`): cabeçalho `- **Status:** Substituído por ADR-<m>`.

O `check-adr.sh` verifica a **simetria**: `Status: Substituído por ADR-<m>` exige que ADR-`<m>` exista e
declare `Substitui: ADR-<n>`, e vice-versa. Referência quebrada ou unilateral → o script acusa.
