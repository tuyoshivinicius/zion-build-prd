# ADR-013 — Skill de estudo workflow-adaptativa por marcador do repo (persona dupla)

- **Status:** Aceito
- **Data:** 2026-07-18
- **Decisores:** autoria do repo
- **Evidência:** Decisão dada: o modelo de duas personas (dev do harness × autor externo) foi decidido nesta sessão de design; não há nada a provar rodando nem pesquisando — a direção chega batida. O design que a formaliza é `docs/superpowers/specs/2026-07-18-repo-semantica-estudo-adaptativo-design.md`.

## Contexto

A skill `zion-prd-estudo` é o Estágio 0 **distribuído** do harness: o autor externo a roda no
próprio produto e o "Próximo passo sugerido" aponta `/zion-prd-discovery`. Mas o **dev do próprio
harness** também a usa internamente para estudar candidatos deste repo — onde o downstream correto
é o SDD leve (`superpowers:brainstorming → writing-plans → executing-plans`), não o discovery. Hoje
a skill hard-coda o downstream distribuído, servindo mal uma das duas personas. A dúvida
estruturante — uma skill adaptativa vs. duas skills — é uma **decisão dada** (RN-03, ADR-006): o
modelo de duas personas foi decidido no design; não há execução nem pesquisa a fazer.

## Decisão

Uma **única** skill de estudo, **workflow-adaptativa**: detecta o modo por um marcador do
repo-harness — projeto-alvo cujo `.claude-plugin/plugin.json` tem `name: zion-build-prd` → modo
**interno**; caso contrário **distribuído** (default). Só a Fase 4 ramifica o "Próximo passo
sugerido" (interno → SDD leve + ADR/canon; distribuído → discovery); as Fases 1–3 permanecem
idênticas. Estrutura **Opção A**: dois ramos gated numa única `SKILL.md`, com `description` e
`argument-hint` 100% distribuídos — o ramo interno viaja shipado mas fica **inerte** para o usuário
externo (o marcador nunca casa no produto dele). Preterido: **duas skills separadas** (duplicariam
as Fases 1–3 e divergiriam) e **flag/pergunta manual** (menos robusto, ruído para o usuário
externo).

## Consequências

A skill passa a servir as duas personas sem duplicação. A adaptação é cirúrgica (Fase 4 só) e o
resto da superfície descobrível fica intocado. O vocabulário das três naturezas do repo
(distribuído / governança / dev-workflow) é canonizado numa nova §6 do `architecture.md`, que a
skill consome pelo marcador. Nada muda na verificação: `check-estudo.sh` é agnóstico ao conteúdo do
"Próximo passo sugerido" (cobra só os 6 cabeçalhos) — nenhuma fixture nova. Limite conhecido: a
detecção é por presença de um arquivo/campo; um projeto-alvo que copiasse esse marcador ativaria o
ramo interno indevidamente (aceito — o marcador é a identidade única deste repo).

## Status

Aceito.
