# ADR-017 — Classificação diagnóstica×propositiva na delegação criativa ao brainstorming

- **Status:** Aceito
- **Data:** 2026-07-19
- **Decisores:** autoria do repo
- **Evidência:** Decisão dada: o dono do harness escolheu a alternativa D (ROI 4.0) no estudo `docs/estudos/discovery-delegacao-brainstorming.md`; o design que a formaliza é `docs/superpowers/specs/2026-07-19-delegacao-criativa-classificada-design.md`.

## Contexto

Três estágios criativos — discovery, write, decompose — delegam a clarificação ao
`superpowers:brainstorming` sob o contrato de capacidades C1–C3 (ADR-007). A análise-mãe
(`zion-mermaid-editor-app/docs/analise-brainstorming-no-fluxo-zion.md`) mostra que, no **modo
retomar/revisar**, essa clarificação degrada: o Autor recebe perguntas **diagnósticas** ("qual dos
seus fatos é o verdadeiro?") em vez de **propositivas** ("escolha entre estes desenhos"), sem
recomendação e sem preview que ilustre a escolha. A causa-raiz não é falha da skill — ela roda e
cumpre o contrato —, é que a **natureza da pergunta** chega errada: o harness delega e pré-resolve
ao mesmo tempo, entregando as tensões já redigidas como pergunta. No modo do-zero a delegação é até
melhor que o brainstorming avulso; o defeito é localizado no modo revisar e em write/decompose.

## Decisão

A delegação criativa **classifica cada tensão** — diagnóstica ou propositiva — numa rubrica de
**fonte única** (`assets/delegacao-criativa.md`, sincronizada para as três skills), e **gateia o
prompt montado** por `check-delegacao.sh` (marcadores greppados: a distinção, propositiva→2–3
abordagens+recomendação, os dois previews, a condução), que aconselha (`RN-01`). A liberação do
preview conceitual fica **escopada à delegação** (mora no asset), com o `#fronteira` global de
`quality-rules.md` intacto — specify/PRD seguem com tela banida. Descartadas: declarar uma
capacidade C4 e gatear o **marcador externo** do superpowers (Alt C) — gateia a coisa errada (que o
marcador existe na skill instalada, não que o *nosso* prompt pede) e aumenta o acoplamento; e editar
o `#fronteira` global (opção B da fronteira). O contrato externo **C1–C3 (ADR-007) não é tocado nem
substituído**.

## Consequências

O drift da correção passa a ser pego no **nosso** prompt (as três `SKILL.md`), fechando o modo de
falha "a correção só no prompt regride na próxima reescrita" sem crescer o acoplamento com o
superpowers (`NFR-02` intacto). O harness ganha um asset, um script (`check-delegacao.sh`,
distribuído) e um auto-teste (`test-check-delegacao.sh`, dev-workflow, agregado pelo `eval.sh`). O
**limite honesto**, na mesma candura da Consequência do ADR-007: o gate confirma que o prompt
**pede** a distinção; **não** confirma que o agente classificou certo cada tensão, que nada foi
pré-mastigado, nem que a experiência melhorou — isso segue julgamento, coberto só na camada LLM
(ADR-008). A condução ("crie uma tarefa por passo") é prompt, não mecanismo: efeito declarado como
limite, não promessa. Nenhum ADR vigente é revertido — ADR-007 é honrado, não tocado.

## Status

Aceito.
