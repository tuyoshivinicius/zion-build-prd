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
  Consequências ∧ o ADR referencia um spike real.
- **prd** (`docs/PRD.md`): escopo in/out explícito ∧ `RF-xx` agrupados por épico (1 frase cada) ∧
  NFRs com número ∧ **zero** stack / critério de aceite / tela. As três regras decidíveis
  (zero-stack, NFR-com-número, RF-por-épico) são verificadas por `check-prd.sh` — a Fase 4 roda o
  script e ecoa o veredito.
- **decompose**: existe backlog de fatias verticais priorizadas ∧ cada fatia passa no INVEST ∧
  walking skeleton é a fatia zero (R0) ∧ a tabela de rastreabilidade está injetada na PRD com uma
  linha por `RF-xx` in-scope.
- **specify-prompt**: o prompt gerado declara resultado observável ∧ não cita stack ∧ RF-xx/ADR
  entram como contexto (referência), não como requisito. O zero-stack é verificado por
  `check-prd.sh specify -` sobre o prompt montado.
- **constitution-prompt**: o prompt gerado deriva princípios **decidíveis** (cada um com validador/
  limiar/teste) ∧ cada princípio rastreia a um NFR ou restrição de ADR ∧ **zero** princípio genérico
  ("código limpo", "boa cobertura").
- **plan-prompt**: o prompt gerado referencia o `spec.md` da feature ∧ injeta os ADRs confirmados
  como restrição (honrar, não re-decidir) ∧ deixa claro que o plano deve honrar cada ADR e cobrir
  o resultado observável do `spec.md`.

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
