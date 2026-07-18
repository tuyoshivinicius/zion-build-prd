---
name: zion-prd-decompose
description: Estágio 4 do harness Zion Build PRD — transforma os RF-xx da PRD em épicos, story map e fatias verticais validadas por INVEST, e injeta a tabela de rastreabilidade. Use para "decompor a PRD", "fatiar em histórias/épicos" ou "montar o backlog vertical" depois que a PRD estiver escrita.
argument-hint: "(sem argumento = modo integral; --epico E<k> = re-fatiar só um épico no dia 2)"
metadata:
  author: zion-build-prd
user-invocable: true
disable-model-invocation: false
---

# zion-prd-decompose — Estágio 4 do harness (Decomposição)

Orquestra o Estágio 4 do harness (Decomposição). Sequência dos estágios e fronteira o-quê/como em
`references/process-context.md`. Contrato de 5 fases; gates aconselham.
Regras em `references/quality-rules.md`.

## Fase 0 — Pré-requisito (aconselha)
`docs/PRD.md` deve existir e conter a seção de `RF-xx` por épico. Faltando → avise ("recomendo
`/zion-prd-write` antes") e pergunte se segue. Não bloqueie.

## Fase 1 — Validar entrada bruta
Não há texto novo — trabalha sobre `docs/PRD.md`.

## Fase 2/3 — Formatar e auto-delegar
**Preflight (dependência):** esta etapa exige `superpowers:brainstorming`. Se a skill não estiver
disponível, avise e pare graciosamente: "Instale o superpowers — `/plugin marketplace add
obra/superpowers-marketplace` e `/plugin install superpowers@superpowers-marketplace` — e rode de
novo." (No formato plugin ela é declarada como dependência e instala automaticamente quando o
marketplace está registrado.)

Invoque `superpowers:brainstorming` no mesmo turno para: (1) agrupar os `RF-xx` em épicos;
(2) montar o story map (backbone da jornada); (3) cortar linhas de release R0..Rn; (4) fatiar cada
épico em fatias verticais.

**Modo parcial (dia 2) — `--epico E<k>`:** re-fatia **apenas** o épico indicado (invocado à mão ou pelo
`/zion-prd-evolve` com o épico afetado). Invoque `superpowers:brainstorming` com escopo naquele épico,
aplicando INVEST/SPIDR como no modo integral. **Fatias já implementadas do épico são intocáveis** — viram
**restrição** do re-fatiamento (as novas fatias partem do que já existe). Não mexa na §12 à mão: ao final,
mande rodar `/zion-prd-trace` (dono único da tabela), que reconcilia sem duplicar. O **modo integral**
continua o default; se a PRD **já** tem backlog decomposto, prefira o modo parcial (`--epico E<k>`).

## Fase 4 — Validar saída (aconselha)
Confira contra o critério **decompose** de `quality-rules.md` `#criterios-de-conclusao`:
- Cada fatia passa no **INVEST** (`#invest`) — aplique o teste-relâmpago "esta fatia, sozinha, dá uma
  demo ponta-a-ponta?". Se a resposta é "só a UI" ou "só o back", a fatia é **horizontal** → aponte e
  sugira refatiar pelos eixos do **SPIDR**.
- O **walking skeleton** é a fatia zero (R0).
- Semeie a tabela de rastreabilidade **por máquina** (não à mão): rode

      bash references/trace-prd.sh docs/PRD.md specs

  Ainda não há specs neste ponto → o bootstrap produz a tabela semente na **seção 12** (RF/Descrição/
  Épico da §6, Feature/Spec em branco, tudo ☐ pendente). `trace-prd.sh` é o **dono único** da tabela;
  rodá-lo de novo depois reconcilia em vez de duplicar. A coluna **Release** é preenchida por você/
  brainstorming após o bootstrap. Reconciliar após cada fatia é trabalho de `/zion-prd-trace`.
Emita veredito por item. Não reverta — aconselhe.

## Saída
Lista de épicos, story map, backlog de **fatias verticais** priorizadas com linhas de release, e a
tabela de rastreabilidade **semeada por `trace-prd.sh`** dentro da PRD. **Handoff:** a próxima fatia da
fila entra em `/zion-prd-specify-prompt`; após cada fatia, `/zion-prd-trace` reconcilia a tabela.
