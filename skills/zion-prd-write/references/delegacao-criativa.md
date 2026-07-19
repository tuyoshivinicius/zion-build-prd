# Delegação criativa — classificação da tensão antes de delegar

> Fonte única citada pelos estágios que delegam a clarificação ao `superpowers:brainstorming`
> (discovery, write, decompose). Afinar a rubrica se faz **aqui**, num lugar só; o sync propaga
> para os `references/` das três skills. Escopo: **só a delegação criativa** — o `#fronteira`
> global de `quality-rules.md` fica intacto (specify/PRD seguem com tela banida).

Antes de delegar, o harness lê o insumo (discovery / PRD / backlog), **enumera as tensões como
observações suas** (nunca já redigidas como pergunta), **classifica cada uma** pela rubrica abaixo,
monta o bloco de delegação e **se autoverifica** (`check-delegacao.sh`) antes de invocar o
brainstorming. Materializar o bloco e checá-lo é a única diferença de comportamento: o conteúdo da
delegação é o mesmo, só que classificado.

## 1. Classificação diagnóstica × propositiva

A distinção **não é de formatação, é de tipo de pergunta**: uma pede informação, a outra propõe uma
escolha de design.

| Tipo | A tensão pergunta… | Vira |
|---|---|---|
| **Diagnóstica** | *qual dos seus fatos/intenções é o verdadeiro?* | pergunta simples, uma por vez; **sem** recomendação (não há o que recomendar) e **sem** preview (não há artefato a ilustrar) |
| **Propositiva** | *isto admite mais de um desenho?* | **2–3 abordagens** com trade-offs + **recomendação** explícita (liderando pela recomendada) + preview conceitual |

Exemplos reais: uma tensão **diagnóstica** ("qual momento de uso servir primeiro", três leituras do
que o autor quis dizer) pede revelar intenção — não force recomendação onde não há o que recomendar.
Uma tensão **propositiva** ("teclado primeiro × mouse primeiro", três desenhos com recomendação e
mockup) admite desenho — proponha 2–3 abordagens e recomende.

## 2. Os dois previews (escopado aqui)

Em vez de banir preview em bloco, distinga duas categorias — com o **teste crítico** passa/vaza:

| Categoria | Exemplo | Na delegação |
|---|---|---|
| **Preview que ilustra a escolha** | fluxo de dados (`canvas edit ──► reescreve código`), barras de profundidade por tipo, contrato de saída em ✓/✗ | **liberado** — é auxílio de decisão |
| **Preview que desenha tela** | mockup de palette `Ctrl+K`, linha de atalhos sob o nó, arranjo de widget | **proibido** — é do `plan.md` |

Redação-núcleo: **ilustrar a consequência** de uma opção (fluxo, comparação, contrato de saída) é
bem-vindo e ajuda a decidir; **desenhar tela** (mockup, atalho, widget, arranjo de UI) fica no
`plan.md`.

## 3. Condução

Conduza pelo seu protocolo — **uma pergunta por vez**; quando a tensão for propositiva, 2–3
abordagens com trade-offs e sua recomendação explícita; **crie uma tarefa por passo** da sua
checklist, conduzindo **passo a passo**. Isto é instrução, não mecanismo: o efeito é julgamento do
executor, não garantia.

## Vale nos dois modos

No **do-zero**, a rubrica **codifica** o que já dava certo — é aditiva, não regride. No
**retomar/revisar**, **corrige** a degradação para clarificação diagnóstica sem recomendação nem
preview.
