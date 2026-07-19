---
name: zion-prd-ajuda
description: Ajuda de bolso do harness Zion Build PRD — tira dúvidas sobre os estágios, os comandos `/zion-*`, os artefatos que cada um produz e a costura com o Spec Kit, ancorando cada afirmação na fonte. Use quando o usuário mencionar explicitamente o harness Zion Build PRD, um estágio dele (descoberta, estudo, spike/ADR, PRD, decomposição, pontes, trace, dia 2) ou um comando `zion-*` e perguntar "como funciona", "qual comando resolve", "onde isso entra", "o que vem depois" ou "o que o Spec Kit faz aqui". Não lê nem grava artefato do projeto: tarefa disfarçada é roteada ao comando dono.
argument-hint: "A dúvida em 1–3 frases (ex.: \"quando eu rodo o spike?\")"
metadata:
  author: zion-build-prd
user-invocable: true
disable-model-invocation: false
---

# zion-prd-ajuda — Ajuda de bolso do harness

Responde dúvidas sobre o harness e sobre a costura com o Spec Kit. **Não é um estágio da jornada**:
não tem entrada, saída nem lugar na sequência — é transversal a ela. A sequência dos estágios está
em `references/process-context.md`; o ciclo `/speckit.*` e as fronteiras do harness com ele, em
`references/speckit-map.md`.

**Não grava nada e não lê o projeto do usuário** — nem `docs/prd.md`, nem `docs/adr/`, nem
`docs/backlog.md`. O que ela sabe vem das `SKILL.md` instaladas ao lado dela e das duas referências
acima.

## As quatro guardas

| Guarda | Comportamento |
|---|---|
| **Não executa** | Tarefa disfarçada de dúvida ("escreve minha §6") é roteada ao comando dono, e a ajuda **para** ali. Todo gate do harness aconselha, nunca bloqueia. |
| **Não opina em stack** | Pergunta de tecnologia vira roteamento para `/zion-prd-spike` + `/zion-adr-new`, **sem veredito**: a decisão é do Autor, registrada como ADR. |
| **Não reabre ADR** | Explica a decisão vigente e roteia para supersessão (ADR novo via `/zion-adr-new`) — decisão não se rediscute em ajuda. |
| **Não afirma sem fonte** | Toda afirmação carrega o arquivo de onde veio. Sem fonte, a resposta é **"não sei"** — nunca preenchida com plausibilidade. |

## Fase 0 — Triagem

Classifique a dúvida em **uma** de quatro rotas; a rota decide tudo que vem depois.

| Rota | Exemplo | O que acontece |
|---|---|---|
| **Estágio** | "quando eu rodo o spike?" | Responde, ancorado na `SKILL.md` dona do estágio |
| **Costura / Spec Kit** | "o que a ponte do plan entrega?" | Responde com `references/speckit-map.md` + a `SKILL.md` da ponte |
| **Tarefa disfarçada** | "escreve minha §6" | Roteia ao comando dono e **para** |
| **Fora de escopo** | "meu RF-03 está bom?" | Declina, explica a fronteira (a ajuda não lê o projeto) e roteia ao comando dono |

## Fase 1 — Grounding

**Sempre:** leia o frontmatter (`name` + `description`) de **todas** as skills irmãs, em
`../<nome>/SKILL.md` a partir do diretório-base desta skill (o Claude Code informa esse diretório na
invocação; nos dois canais de instalação as skills ficam lado a lado). Isso produz a **lista fechada
de comandos válidos daquela instalação** — a ajuda só cita comando que acabou de ler no disco.

**Conforme a rota:** abra o **corpo** da `SKILL.md` só da(s) irmã(s) que a dúvida toca, e as
referências que a rota pede (`references/process-context.md` para "onde isso cai";
`references/speckit-map.md` para a costura).

Se uma irmã que este mapa cita não existir no disco, ela não está instalada: diga isso em vez de
descrever o que ela faria.

## Fase 2 — Resposta em molde fixo

Quatro blocos, **nesta ordem**, sempre:

1. **Onde isso cai** — o estágio da jornada a que a dúvida pertence.
2. **O comando que resolve** — sempre da lista fechada lida na Fase 1.
3. **A armadilha** — o erro comum daquele ponto.
4. **Fonte** — por afirmação (o arquivo lido). Faltando fonte, o bloco vira **"não sei — isso não
   está no que eu leio"**, sem preencher com plausibilidade.

## Fase 3 — Próximo passo

Um passo concreto, mais o eco das guardas que se aplicaram — por exemplo: "não vou escrever a seção
por você — quem faz isso é `/zion-prd-write`".

## Mapa de rotas — dúvida → comando dono

A autoridade é a lista lida na Fase 1; este mapa é o roteiro de qual irmã abrir.

| A dúvida é sobre | Comando dono |
|---|---|
| Estudar a ideia antes da descoberta, comparar alternativas, ROI | `/zion-prd-estudo` |
| Visão, persona, quadro faz/não-faz, superfície de uso | `/zion-prd-discovery` |
| Decisão estruturante, trade-off, evidência por risco | `/zion-prd-spike` |
| Registrar/superseder uma decisão de arquitetura | `/zion-adr-new` |
| Escrever/preencher a PRD, RF por épico, NFR com número | `/zion-prd-write` |
| Épicos, story map, specs verticais, backlog, walking skeleton | `/zion-prd-decompose` |
| Princípios do repositório para o Spec Kit | `/zion-prd-constitution-prompt` |
| Levar uma spec ao `/speckit.specify` | `/zion-prd-specify-prompt` |
| Levar uma feature ao `/speckit.plan` com os ADRs como restrição | `/zion-prd-plan-prompt` |
| Instalar a integração com o Spec Kit no repo do produto | `/zion-speckit-install` |
| Rastreabilidade, backlog e blocos derivados desatualizados | `/zion-prd-trace` |
| Mudança pós-release (RF novo/alterado, decisão revertida) | `/zion-prd-evolve` |
| Como o harness funciona, qual comando usar, o que vem depois | `/zion-prd-ajuda` (esta skill) |

## Saída

Nenhum arquivo. A saída é a resposta em 4 blocos + o próximo passo. Se a dúvida virou trabalho, o
trabalho é do comando dono — a ajuda entrega o nome dele e para.
