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
  NFRs com número ∧ **zero** stack / critério de aceite / tela.
- **decompose**: existe backlog de fatias verticais priorizadas ∧ cada fatia passa no INVEST ∧
  walking skeleton é a fatia zero (R0) ∧ a tabela de rastreabilidade está injetada na PRD com uma
  linha por `RF-xx` in-scope.
- **specify-prompt**: o prompt gerado declara resultado observável ∧ não cita stack ∧ RF-xx/ADR
  entram como contexto (referência), não como requisito.
- **constitution-prompt**: o prompt gerado deriva princípios **decidíveis** (cada um com validador/
  limiar/teste) ∧ cada princípio rastreia a um NFR ou restrição de ADR ∧ **zero** princípio genérico
  ("código limpo", "boa cobertura").
- **plan-prompt**: o prompt gerado referencia o `spec.md` da feature ∧ injeta os ADRs confirmados
  como restrição (honrar, não re-decidir) ∧ `success_criteria` = plano honra cada ADR ∧ cobre o
  resultado observável do `spec.md`.

## INVEST e SPIDR {#invest}

**INVEST** — cada fatia vertical deve ser: **I**ndependente, **N**egociável, **V**aliosa,
**E**stimável, **S**mall, **T**estável.

**Teste-relâmpago:** *"esta fatia, sozinha, permite uma demo ponta-a-ponta?"* Se a resposta é "só a
UI" ou "só o back", a fatia é **horizontal** → refatie.

**SPIDR** — eixos para quebrar uma fatia grande: **S**pike, **P**ath (caminhos alternativos),
**I**nterface, **D**ata, **R**ules. Use quando uma fatia não passa no "Small" do INVEST.

**Walking skeleton:** a fatia zero (R0) prova o pipeline inteiro com o mínimo de funcionalidade.

## Anatomia do prompt do specify {#anatomia-specify}

O input do `/speckit.specify` é literalmente um prompt. As três tags que pagam o custo:

- `<constraints>` — o **guardião da fronteira**: escreva explícito "não citar linguagem/framework/
  bibliotecas; stack só no `plan`". Impede o "como" de vazar para o `specify`.
- `<context>` — **separa referência de instrução**: `RF-xx` e ADRs entram como contexto, não viram
  requisitos acidentais.
- `<success_criteria>` — declara o **resultado observável** antes de rodar; é o que o gate
  `/speckit.clarify` vai cobrar em seguida, então já antecipa o gate.

## Anatomia do prompt do constitution {#anatomia-constitution}

O input do `/speckit.constitution` também é um prompt, montado a partir da PRD. As tags que pagam o
custo:

- `<context>` — **a fonte, não o princípio pronto**: os NFRs (`NFR-xx`) e as restrições de ADRs
  entram como material de origem para derivar os princípios; não são princípios já formatados.
- `<instructions>` — pede para **derivar** princípios decidíveis dessa fonte (um por
  NFR/restrição relevante).
- `<constraints>` — o **guardião da decidibilidade**: escreva explícito "cada princípio tem um
  critério objetivo (validador / limiar numérico / teste) e rastreia a um NFR ou ADR; proibido
  genérico ('código limpo', 'boa cobertura')". Impede platitude de virar princípio.
- `<success_criteria>` — todo princípio é **decidível** ∧ **rastreável** a um NFR/ADR; nenhum
  genérico. É o que torna a `constitution` cobrável depois.

## Anatomia do prompt do plan {#anatomia-plan}

O input do `/speckit.plan` também é um prompt — montado a partir do `spec.md` da feature e dos ADRs
que o spike já provou. É a única ponte que **entra** no "como", presa ao que foi decidido. As tags:

- `<context>` — **a fonte, separando referência de instrução**: o `spec.md` da fatia (o o-quê que o
  plano realiza) e os **ADRs confirmados** (`ADR-00x: <decisão>`) como decisões fechadas.
- `<instructions>` — pede para **derivar** o plano técnico (o como) que realiza o `spec.md` **dentro**
  das decisões dos ADRs.
- `<constraints>` — o **guardião da fronteira, invertido**: em vez de "sem stack", escreva explícito
  "honre cada ADR listado; não re-decida o que um ADR já fixou". Secundário: "não expanda além do
  escopo do `spec.md`". É o que impede o spike de virar esforço órfão.
- `<success_criteria>` — o plano **honra cada ADR confirmado** ∧ cobre o resultado observável do
  `spec.md`. É o que o gate `/speckit.analyze` vai cobrar depois.
