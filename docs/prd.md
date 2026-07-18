# PRD — Zion Build PRD (o harness)

> Fonte da verdade dos **requisitos** deste repo (o-quê/por-quê). O como/com-quê vive em
> `docs/architecture.md`. Toda mudança de comportamento do harness reflete aqui no mesmo commit
> (canonização — veja `CLAUDE.md`); `scripts/check-canon.sh` cruza esta PRD com a implementação.

## 1. Visão

Para o autor de produto que trabalha com agentes no Claude Code e trava entre a ideia bruta e uma
spec executável, o Zion Build PRD é um harness de skills que conduz a autoria da PRD em estágios —
descoberta, decisões estruturantes, escrita, decomposição — e entrega cada spec pronta para o ciclo
do Spec Kit, guardando sempre a fronteira o-quê/como.

## 2. Objetivos & métricas

- Toda PRD produzida chega à ponte do specify com 0 achados de fronteira na verificação mecânica.
- 100% dos RF in-scope de uma PRD rastreados a uma spec na tabela de rastreabilidade.
- O autor sai da ideia bruta ao primeiro prompt de specify em 1 jornada contínua de 5 estágios,
  sem montar prompt de ponte à mão.

## 3. Personas

- **O Autor** — dev de produto (solo ou time pequeno) que usa o Claude Code e quer PRDs enxutas
  sem virar burocrata de documento.
- **O Agente** — o Claude conduzindo um estágio: lê as regras canônicas e os artefatos dos
  estágios anteriores, verifica e aconselha.

## 4. Escopo (in / out)

- **Faz (in):** conduz descoberta enxuta retomável; prova decisões estruturantes com evidência
  proporcional ao risco e as registra como ADRs; escreve a PRD enxuta a partir de esqueleto;
  decompõe em épicos e specs verticais com backlog e rastreabilidade; monta os prompts das três
  pontes para o Spec Kit; verifica por máquina as regras decidíveis; acompanha a evolução
  pós-release (dia 2).
- **Não faz (out):** não executa o ciclo do Spec Kit (specify em diante é do autor); não escreve
  código de produto; não decide stack pelo autor (só registra a decisão dele em ADR); não resolve
  dependência de instalação no canal skills.sh; não bloqueia o autor em gate algum do
  projeto-alvo.

## 5. Regras de negócio (RN-xx)

- `RN-01` Todo gate do harness no projeto-alvo aconselha, nunca bloqueia — o autor decide seguir.
- `RN-02` A fronteira o-quê/por-quê × como/com-quê vale em todo artefato: stack só em ADR e plan.
- `RN-03` Toda decisão estruturante carrega evidência do tipo certo para o seu risco (execução,
  conhecimento ou decisão dada).
- `RN-04` Artefatos derivados (tabela de rastreabilidade, backlog) são semeados e reconciliados
  por máquina, nunca mantidos à mão.
- `RN-05` Regra de qualidade se afina num lugar só (fonte única); toda cópia é derivada e
  verificada contra drift.

## 6. Requisitos funcionais por épico (RF-xx)

- **Épico E1 — Jornada de autoria:** `RF-01` O autor conduz a descoberta enxuta (visão, persona,
  faz/não-faz) e a retoma entre sessões sem perder o que já respondeu. `RF-02` O autor prova as
  2–3 decisões estruturantes com evidência proporcional ao risco antes de fechar a PRD. `RF-03` O
  autor registra cada decisão como ADR com contexto, decisão e consequências — inclusive
  substituindo um ADR anterior com referência simétrica. `RF-04` O autor preenche a PRD seção a
  seção a partir de um esqueleto, com requisitos de uma frase agrupados por épico. `RF-05` O autor
  decompõe a PRD em épicos, story map e specs verticais priorizadas, com o walking skeleton como
  spec zero.
- **Épico E2 — Pontes para o Spec Kit:** `RF-06` O autor recebe pronto o prompt da constitution,
  derivado dos NFRs e restrições da PRD, com princípios decidíveis. `RF-07` O autor recebe pronto
  o prompt do specify de uma spec, blindado contra vazamento de fronteira e com o elo de
  rastreabilidade pedido. `RF-08` O autor recebe pronto o prompt do plan de uma feature, com os
  ADRs confirmados injetados como restrição a honrar.
- **Épico E3 — Rastreabilidade:** `RF-09` O autor reconcilia a qualquer momento a tabela de
  rastreabilidade e o backlog a partir das specs existentes, vendo RF órfão, spec intraçável e RF
  descoberto.
- **Épico E4 — Dia 2:** `RF-10` O autor classifica uma mudança pós-release nos cenários canônicos
  e é roteado aos comandos donos de cada artefato afetado, com o histórico registrado na PRD.
- **Épico E5 — Qualidade mecânica:** `RF-11` O harness verifica por máquina as regras decidíveis
  dos artefatos (fronteira sem stack, NFR com número, RF por épico, evidência presente por risco)
  e ecoa o veredito nos estágios. `RF-12` O harness avalia a si mesmo em duas camadas —
  determinística com fixtures no CI e de julgamento sob demanda. `RF-13` O harness governa a si
  mesmo: requisitos e arquitetura são fontes da verdade versionadas, e o drift entre elas e a
  implementação é acusado por máquina antes do commit.
- **Épico E6 — Distribuição:** `RF-14` O autor instala as skills por um comando, em qualquer um
  dos dois canais suportados. `RF-15` Cada skill é autocontida: carrega consigo as regras e
  templates de que precisa, gerados da fonte única. `RF-16` Uma skill que depende de capacidade
  externa ausente avisa com o comando de instalação e para graciosamente.

## 7. NFRs (com números)

- `NFR-01` A camada mecânica completa (drift de assets + auto-testes + canon) roda em menos de
  60 segundos no CI.
- `NFR-02` Exatamente 1 dependência externa de skill (o executor de brainstorming); o resto viaja
  no repo ou é built-in.
- `NFR-03` 0 de drift tolerado entre fonte única e cópias derivadas: qualquer divergência falha o
  CI.
- `NFR-04` 100% dos verificadores mecânicos têm auto-teste com fixture limpa e suja.
- `NFR-05` 0 gate bloqueante no projeto-alvo: todo veredito mecânico é conselho (exit lido pela
  skill, nunca revertendo trabalho do autor).

## 8. Restrições (das decisões de arquitetura)

As decisões estruturantes deste repo estão consolidadas em `docs/architecture.md` (D-01 em
diante), que também indexa os ADRs futuros de `docs/adr/`. Em especial: fonte única com cópias
derivadas (D-01), distribuição em dois canais com autocontenção (D-02), verificação mecânica que
aconselha no projeto-alvo (D-04) e o contrato de capacidades com o executor externo de
brainstorming (D-07).

## 9. Glossário

- **Harness** — o conjunto de skills que conduz a jornada PRD → Spec Kit.
- **Estágio** — um passo da jornada (descoberta, spike, escrita, decomposição, pontes, trace,
  dia 2).
- **Fronteira** — a separação o-quê/por-quê (PRD, specify) × como/com-quê (ADR, plan).
- **Spec vertical** — unidade de trabalho que atravessa o produto de ponta a ponta e permite demo.
- **Ponte** — comando que monta o prompt de um passo do Spec Kit sem executá-lo.
- **Canonização** — refletir toda mudança de comportamento/estrutura de volta nas fontes da
  verdade deste repo, no mesmo commit.

## 10. Riscos

- Upgrade do executor externo de brainstorming quebra capacidade usada pelos estágios →
  mitigado: contrato C1–C3 com check de drift e pin de versão.
- As fontes da verdade deste repo apodrecem em silêncio → mitigado: guard de canonização no
  pre-commit e no CI (épico E5).
- A denylist de stack envelhece e deixa vazar termo novo → mitigado: curadoria num lugar só,
  afinável num commit.

## 11. Questões abertas

- Promover o runner por agentes da camada LLM a uma skill própria? Decidir quando o roteiro
  manual provar valor.

## 12. Rastreabilidade

Nesta PRD (o harness é o produto), a coluna de destino aponta o **artefato do repo** que realiza
cada RF — é o elo que `scripts/check-canon.sh` cruza com o disco.

| RF | Épico | Artefato |
|----|-------|----------|
| RF-01 | E1 | skills/zion-prd-discovery |
| RF-02 | E1 | skills/zion-prd-spike |
| RF-03 | E1 | skills/zion-adr-new |
| RF-04 | E1 | skills/zion-prd-write |
| RF-05 | E1 | skills/zion-prd-decompose |
| RF-06 | E2 | skills/zion-prd-constitution-prompt |
| RF-07 | E2 | skills/zion-prd-specify-prompt |
| RF-08 | E2 | skills/zion-prd-plan-prompt |
| RF-09 | E3 | skills/zion-prd-trace |
| RF-10 | E4 | skills/zion-prd-evolve |
| RF-11 | E5 | scripts/check-prd.sh · scripts/check-adr.sh · scripts/trace-prd.sh · scripts/trace-backlog.sh |
| RF-12 | E5 | scripts/eval.sh · scripts/fixtures/ · docs/guias/avaliacao-harness.md |
| RF-13 | E5 | scripts/check-canon.sh · CLAUDE.md · docs/prd.md · docs/architecture.md |
| RF-14 | E6 | .claude-plugin/ · README.md |
| RF-15 | E6 | scripts/sync-assets.sh · scripts/asset-map.sh · assets/ |
| RF-16 | E6 | preflight nas SKILL.md das skills dependentes |

## 13. Histórico de mudanças

> Vazia no dia 1 desta PRD. Uma linha por mudança de requisito daqui em diante (regras em
> `assets/quality-rules.md#dia-2`).

| Data | Cenário | Mudança | Motivo | Artefatos afetados |
|------|---------|---------|--------|--------------------|
