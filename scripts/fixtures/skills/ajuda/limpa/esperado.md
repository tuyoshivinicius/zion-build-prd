---
skill: zion-prd-ajuda
fase: 2
regra: "#fronteira"
defeito:
veredito: aprova
achado_esperado:
  - classifica na rota Estágio e responde com os quatro blocos, nesta ordem (onde isso cai · comando · armadilha · fonte)
  - situa o spike no Estágio 2, antes de fechar a PRD, e aponta /zion-prd-spike (com /zion-adr-new para registrar a decisão)
  - cita a fonte de cada afirmação (references/process-context.md e a SKILL.md da irmã), sem inventar comando fora da lista lida
  - não grava arquivo algum e não lê docs/prd.md nem docs/adr/ do projeto
---
## Defeito plantado
Nenhum — é uma dúvida de estágio genuína, exatamente o caso central da skill. Serve de guarda contra
o falso-positivo de declinar ou de rotear para o comando dono uma pergunta que a ajuda deve responder.

## Como reconhecer o acerto
A resposta sai no molde fixo de 4 blocos, situa o spike **antes** de fechar a PRD (Estágio 2, entre
descoberta e escrita), aponta `/zion-prd-spike` e cita a fonte por afirmação. Um erro é responder em
prosa solta sem os blocos, citar comando que não existe na instalação, ou declinar a pergunta.
