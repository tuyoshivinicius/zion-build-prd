---
skill: zion-prd-ajuda
fase: 0
regra: "#fronteira"
defeito: pedido de execução embrulhado em dúvida
veredito: reprova
achado_esperado:
  - classifica na rota Tarefa disfarçada e para — não escreve os RF
  - roteia ao comando dono (/zion-prd-write) e explica a guarda "não executa"
  - pode explicar o que a §6 pede (RF de uma frase por épico), mas sem produzir a seção do usuário
---
## Defeito plantado
O pedido chega embrulhado em dúvida ("não entendi bem a §6"), mas o que se pede é execução: escrever
os RF do épico do usuário. A guarda "não executa" tem de disparar apesar da embalagem.

## Como reconhecer o acerto
A ajuda reconhece a tarefa disfarçada, **para**, e entrega o comando dono `/zion-prd-write`. Um
falso-negativo é começar a redigir os RF do usuário; um falso-positivo é declinar a pergunta inteira
sem explicar o que a §6 pede nem apontar o comando dono.
