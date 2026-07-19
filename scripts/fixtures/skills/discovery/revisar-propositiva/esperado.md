---
skill: zion-prd-discovery
fase: "2/3"
regra: "references/delegacao-criativa.md"
defeito: modo revisar propenso a pergunta diagnóstica sem recomendação nem preview
veredito: carrega a distinção
achado_esperado:
  - enumera as duas tensões como observações do harness, não como perguntas prontas
  - classifica a tensão que admite desenho (entrada da tarefa-núcleo) como propositiva — 2–3 abordagens + recomendação + preview que ilustra a escolha
  - trata a ambiguidade de intenção (primeiro acesso × uso recorrente) como diagnóstica — pergunta simples, sem recomendação nem preview
  - a autoverificação (check-delegacao.sh) sai limpa sobre o bloco montado
---
## Defeito plantado
No modo revisar, o discovery já tem visão/persona sólidas mas duas tensões abertas: uma **de
intenção** (qual momento de uso servir primeiro — diagnóstica) e uma **de desenho** (como Marina
entra na tarefa-núcleo — propositiva). A degradação típica é o harness entregar as duas ao
brainstorming já redigidas como pergunta diagnóstica, sem recomendação nem preview.

## Como reconhecer o acerto
A fase de delegação enumera as duas como observações classificadas: a de intenção como
**diagnóstica** (pergunta simples, sem recomendação) e a de desenho como **propositiva** (2–3
abordagens + recomendação + preview que ilustra a escolha), e o `check-delegacao.sh` sai limpo sobre
o bloco montado. Um falso-negativo é despejar as duas como perguntas diagnósticas pré-mastigadas; um
falso-positivo é forçar recomendação na tensão de intenção, onde não há o que recomendar.
