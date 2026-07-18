---
name: zion-prd-decompose
description: Estágio 4 do harness Zion Build PRD — transforma os RF-xx da PRD em épicos, story map e specs verticais validadas por INVEST, e injeta a tabela de rastreabilidade. Use para "decompor a PRD", "fatiar em histórias/épicos" ou "montar o backlog vertical" depois que a PRD estiver escrita.
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
épico em specs verticais. Para cada spec, **cunhe um slug kebab-case** (curto, estável — ele vira o
nome da spec e da branch no Spec Kit), junto da **demo de 1 frase** (o teste INVEST) e dos **RF-xx
cobertos**. Esses três campos são as colunas humanas do backlog (Fase 4).

**Âncora de experiência:** quando a PRD tem `Superfície de uso: sim`, preencha a coluna `Âncora de
experiência` na(s) spec(s) que **tocam** a superfície — **≥1, não toda spec** — em prosa de o-quê
("o usuário conclui a tarefa-núcleo em ≤N passos"). Spec puramente de backend deixa a âncora em
branco (evita o falso-positivo de exigir âncora onde não há superfície).

**Modo parcial (dia 2) — `--epico E<k>`:** re-fatia **apenas** o épico indicado (invocado à mão ou pelo
`/zion-prd-evolve` com o épico afetado). Invoque `superpowers:brainstorming` com escopo naquele épico,
aplicando INVEST/SPIDR como no modo integral. **Specs já implementadas do épico são intocáveis** — viram
**restrição** do re-fatiamento (as novas specs partem do que já existe). Não mexa na §12 à mão: ao final,
mande rodar `/zion-prd-trace` (dono único da §12 **e** do backlog), que reconcilia sem duplicar.
Specs já implementadas (`●`) permanecem **intocáveis** no re-fatiamento. O **modo integral**
continua o default; se a PRD **já** tem backlog decomposto, prefira o modo parcial (`--epico E<k>`).

## Fase 4 — Validar saída (aconselha)
Confira contra o critério **decompose** de `quality-rules.md` `#criterios-de-conclusao`:
- Cada spec passa no **INVEST** (`#invest`) — aplique o teste-relâmpago "esta spec, sozinha, dá uma
  demo ponta-a-ponta?". Se a resposta é "só a UI" ou "só o back", a spec é **horizontal** → aponte e
  sugira refatiar pelos eixos do **SPIDR**. **Braço de experiência (surface=sim, advisório):** "esta
  spec, onde toca a superfície, demonstra a experiência — ou só a função?".
- O **walking skeleton** é a spec zero (R0).
- Semeie a tabela de rastreabilidade **por máquina** (não à mão): rode

      bash references/trace-prd.sh docs/PRD.md specs

  Ainda não há specs neste ponto → o bootstrap produz a tabela semente na **seção 12** (RF/Descrição/
  Épico da §6, Feature/Spec em branco, tudo ☐ pendente). `trace-prd.sh` é o **dono único** da tabela;
  rodá-lo de novo depois reconcilia em vez de duplicar. A coluna **Release** é preenchida por você/
  brainstorming após o bootstrap. Reconciliar após cada spec é trabalho de `/zion-prd-trace`.
- Semeie o **backlog de specs** `docs/backlog.md` a partir de `references/backlog.md` (template),
  preenchendo as **colunas humanas** (Spec/slug, Demo, RFs, Release) com o resultado do fatiamento; então
  reconcilie as colunas de máquina por bootstrap:

      bash references/trace-backlog.sh docs/backlog.md specs

  Ainda não há specs → Pasta `—`, tudo ☐ pendente; a **ordem das linhas é a fila de prioridade**.
  `trace-backlog.sh` é o **dono único** das colunas Pasta/Status. **Backlog já existente → não
  sobrescreva:** atualize as linhas humanas por conversa e deixe a reconciliação com o script
  (idempotência, como nos demais estágios).
- **Âncora de experiência (advisório).** Quando a PRD tem `Superfície de uso: sim`, rode:

      bash references/check-experiencia.sh docs/PRD.md docs/backlog.md

  Avalia os dois limbs: **limb-PRD** (nenhum NFR tagueado `(experiência)` na PRD) e **limb-backlog**
  (nenhuma spec com a coluna `Âncora de experiência` preenchida) → ⚠ *"produto com superfície mas
  nenhuma spec ancora a experiência"*. Ecoe o veredito; não reverta (`RN-01`).
Emita veredito por item. Não reverta — aconselhe.

## Saída
Lista de épicos, story map, backlog de **specs verticais** priorizadas com linhas de release, o
arquivo **`docs/backlog.md`** semeado por `trace-backlog.sh` (slug/demo/RFs por spec; Pasta/Status por
máquina), e a tabela de rastreabilidade **semeada por `trace-prd.sh`** dentro da PRD. **Handoff:** a próxima spec da
fila entra em `/zion-prd-specify-prompt`; após cada spec, `/zion-prd-trace` reconcilia a tabela.
