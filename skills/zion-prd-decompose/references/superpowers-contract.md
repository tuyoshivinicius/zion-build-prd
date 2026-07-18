# Contrato harness ↔ superpowers:brainstorming

O harness Zion Build PRD usa `superpowers:brainstorming` como executor de três estágios
criativos (discovery, write, decompose). Ele **não** depende de todo o comportamento da skill —
depende de **três capacidades**. Este documento é a fonte única dessas capacidades e do runbook
de quando elas quebram. O verificador `scripts/check-superpowers-contract.sh` consome os mesmos
marcadores (mantidos em sincronia por disciplina: ao mudar um marcador, mude **aqui e no script**).

`testado-contra: 5.0.7, 6.1.1`

## As três capacidades

### C1 — Aceita um enquadramento fixo e refina ideia → design
**Por quê:** os três estágios injetam um prompt fixo esperando que o brainstorming o aceite e
conduza a ideia até um design. Sem isso, os três estágios perdem o executor.
**Marcadores (grep tolerante, satisfaz com QUALQUER um):**
- `turn ideas into.*designs`
- `refine the idea`

### C2 — Grava o resultado num arquivo cujo caminho nomeamos
**Por quê:** discovery espera o doc em `discovery.md`; write espera a PRD em `PRD.md`. O harness
lê o arquivo que o brainstorming grava — se ele parar de gravar sob um caminho nomeado, a saída
some.
**Marcadores (satisfaz só com os DOIS juntos — capacidade = escreve doc ∧ sob `docs/`):**
- `Write design doc`
- `save to.*docs/`

### C3 — Conduz diálogo uma pergunta / uma seção por vez
**Por quê:** o estágio write preenche a PRD "seção a seção", contando com o diálogo incremental
do brainstorming. Um brainstorming que despeja tudo de uma vez quebra o preenchimento guiado.
**Marcadores (grep tolerante, satisfaz com QUALQUER um):**
- `one question at a time`
- `Present design.*section`

## Fora de escopo (deliberado)

Marcadores de "writing-plans terminal", "spec self-review" etc. **não** entram: o harness
*redireciona* a saída do brainstorming e não depende do terminal padrão dele. Checá-los viraria
ruído a cada reescrita — exatamente o gate que a crítica quer evitar.

## Runbook de drift

Quando `eval.sh` (ou o check direto) acusar `⚠ C_x ... sumiu`:

1. Leia o `SKILL.md` da nova versão do brainstorming.
2. Se a capacidade **mudou de forma mas continua existindo**, atualize o marcador **aqui e no
   script** (`scripts/check-superpowers-contract.sh`) e some a nova versão em `testado-contra`.
3. Se a capacidade **sumiu de verdade**, **não alargue o pin** do `plugin.json` — trate o estágio
   afetado (o harness perdeu um executor; isso é decisão de produto, não de marcador).
