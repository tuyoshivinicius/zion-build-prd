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
- O autor sai da ideia bruta ao primeiro prompt de specify em 1 jornada contínua de 5 estágios —
  precedida, quando a direção ainda não está clara, por um estudo opcional (Estágio 0) —, sem
  montar prompt de ponte à mão.

## 3. Personas

- **O Autor** — dev de produto (solo ou time pequeno) que usa o Claude Code e quer PRDs enxutas
  sem virar burocrata de documento.
- **O Agente** — o Claude conduzindo um estágio: lê as regras canônicas e os artefatos dos
  estágios anteriores, verifica e aconselha.

## 4. Escopo (in / out)

- **Faz (in):** produz sob demanda um estudo pré-discovery com alternativas comparadas, ROI e
  recomendação não vinculante; conduz descoberta enxuta retomável; prova decisões estruturantes com evidência
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
  faz/não-faz) e a retoma entre sessões sem perder o que já respondeu, capturando — quando o produto
  opera uma superfície de uso — a qualidade de experiência esperada como marcador que viaja a jusante. `RF-02` O autor prova as
  2–3 decisões estruturantes com evidência proporcional ao risco antes de fechar a PRD. `RF-03` O
  autor registra cada decisão como ADR com contexto, decisão e consequências — inclusive
  substituindo um ADR anterior com referência simétrica. `RF-04` O autor preenche a PRD seção a
  seção a partir de um esqueleto, com requisitos de uma frase agrupados por épico, carregando o
  marcador de superfície para os NFRs e aterrissando ≥1 NFR de experiência mensurável quando há
  superfície de uso. `RF-05` O autor
  decompõe a PRD em épicos, story map e specs verticais priorizadas, com o walking skeleton como
  spec zero, ancorando a experiência em ≥1 spec que toca a superfície de uso quando ela existe.
  `RF-17` O autor estuda um candidato antes da descoberta — edge cases, alternativas comparadas
  (sempre incluindo "não fazer") com ROI justificado e recomendação não vinculante — e recebe o
  estudo gravado, com o próximo passo sugerido roteado conforme o contexto detectado, para escolher
  a direção. Pode reabrir um estudo já gravado pelo seu slug para revisá-lo, sem re-digitar o
  candidato.
- **Épico E2 — Pontes e integração com o Spec Kit:** `RF-06` O autor recebe pronto o prompt da constitution,
  derivado dos NFRs e restrições da PRD, com princípios decidíveis. `RF-07` O autor recebe pronto
  o prompt do specify de uma spec, blindado contra vazamento de fronteira e com o elo de
  rastreabilidade pedido. `RF-08` O autor recebe pronto o prompt do plan de uma feature, com os
  ADRs confirmados e a prosa estrutural do documento de arquitetura do produto injetados como
  restrição a honrar. `RF-18` O autor instala num comando, no
  repositório do produto, a integração com o Spec Kit — fontes canônicas declaradas nas regras do
  repositório, documento de arquitetura semeado de esqueleto e guard opt-in — re-rodável sem
  perder o que ele escreveu.
- **Épico E3 — Rastreabilidade:** `RF-09` O autor reconcilia a qualquer momento a tabela de
  rastreabilidade e o backlog a partir das specs existentes, vendo RF órfão, spec intraçável e RF
  descoberto — e reconcilia junto os blocos derivados do documento de arquitetura do produto
  (índice de decisões e visão do backlog).
- **Épico E4 — Dia 2:** `RF-10` O autor classifica uma mudança pós-release nos cenários canônicos
  e é roteado aos comandos donos de cada artefato afetado, com o histórico registrado na PRD.
- **Épico E5 — Qualidade mecânica:** `RF-11` O harness verifica por máquina as regras decidíveis
  dos artefatos (fronteira sem stack, NFR com número, RF por épico, evidência presente por risco,
  âncora de experiência presente quando há superfície de uso, documento de arquitetura do produto e
  regra instalada em dia) e ecoa o veredito nos estágios. `RF-12` O harness avalia a si mesmo em duas camadas —
  determinística com fixtures no CI e de julgamento sob demanda. `RF-13` O harness governa a si
  mesmo: requisitos e arquitetura são fontes da verdade versionadas, e o drift entre elas e a
  implementação é acusado por máquina antes do commit.
- **Épico E6 — Distribuição:** `RF-14` O autor instala as skills por um comando, em qualquer um
  dos dois canais suportados. `RF-15` Cada skill é autocontida: carrega consigo as regras e
  templates de que precisa, gerados da fonte única. `RF-16` Uma skill que depende de capacidade
  externa ausente avisa com o comando de instalação e para graciosamente.
- **Épico E7 — Ajuda e orientação:** `RF-19` O autor tira dúvidas sobre o harness e sobre a costura
  com o Spec Kit em conversa, e recebe onde a dúvida cai na jornada, o comando que a resolve — sempre
  da lista de comandos daquela instalação —, a armadilha daquele ponto e a fonte de cada afirmação;
  dúvida que é tarefa disfarçada é roteada ao comando dono, e o que não está nas fontes vira "não
  sei". A ajuda não lê o projeto do autor nem grava artefato.

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

As decisões estruturantes deste repo estão registradas como ADRs em `docs/adr/`, indexadas na §2 de
`docs/architecture.md`. Em especial: fonte única com cópias derivadas (ADR-001), distribuição em
dois canais com autocontenção (ADR-002), verificação mecânica que aconselha no projeto-alvo
(ADR-004), o contrato de capacidades com o executor externo de brainstorming (ADR-007) e a skill de
estudo workflow-adaptativa por persona (ADR-013).

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
| RF-17 | E1 | skills/zion-prd-estudo |
| RF-06 | E2 | skills/zion-prd-constitution-prompt |
| RF-07 | E2 | skills/zion-prd-specify-prompt |
| RF-08 | E2 | skills/zion-prd-plan-prompt |
| RF-18 | E2 | skills/zion-speckit-install |
| RF-09 | E3 | skills/zion-prd-trace |
| RF-10 | E4 | skills/zion-prd-evolve |
| RF-11 | E5 | scripts/check-prd.sh · scripts/check-adr.sh · scripts/check-estudo.sh · scripts/check-experiencia.sh · scripts/check-arquitetura.sh · scripts/trace-prd.sh · scripts/trace-backlog.sh · scripts/trace-arquitetura.sh · scripts/check-delegacao.sh |
| RF-12 | E5 | scripts/eval.sh · scripts/test-check-estudo.sh · scripts/test-check-experiencia.sh · scripts/fixtures/ · docs/guias/avaliacao-harness.md · scripts/test-check-delegacao.sh |
| RF-13 | E5 | scripts/check-canon.sh · CLAUDE.md · docs/prd.md · docs/architecture.md |
| RF-14 | E6 | .claude-plugin/ · README.md |
| RF-15 | E6 | scripts/sync-assets.sh · scripts/asset-map.sh · assets/ |
| RF-16 | E6 | preflight nas SKILL.md das skills dependentes |
| RF-19 | E7 | skills/zion-prd-ajuda |

## 13. Histórico de mudanças

> Vazia no dia 1 desta PRD. Uma linha por mudança de requisito daqui em diante (regras em
> `assets/quality-rules.md#dia-2`).

| Data | Cenário | Mudança | Motivo | Artefatos afetados |
|------|---------|---------|--------|--------------------|
| 2026-07-18 | C1 | `RF-17` novo: Estágio 0 opcional de estudo pré-discovery | governar o estudo que vivia num prompt one-shot fora do harness | ADR-012 · skills/zion-prd-estudo · scripts/check-estudo.sh |
| 2026-07-18 | C2 | `RF-17` alterado: próximo passo do estudo roteado por persona (interno × distribuído) | o dev do harness usa a mesma skill internamente, onde o downstream é SDD leve, não discovery | ADR-013 · skills/zion-prd-estudo · docs/architecture.md §6 |
| 2026-07-18 | C2 | `RF-17` alterado: reabrir um estudo pelo slug para revisar, sem re-digitar o candidato | remover o atrito de re-digitar o candidato só para revisitar um estudo já gravado | skills/zion-prd-estudo (Fase 0) |
| 2026-07-18 | C2 | Carregador forte de experiência: `RF-01`/`RF-04`/`RF-05`/`RF-11` passam a carregar o marcador `Superfície de uso` e a âncora de experiência (NFR tagueado + coluna no backlog); `check-experiencia.sh` novo | app rico em função e pobre de uso — o sinal de experiência precisa nascer no discovery e sobreviver até o backlog | ADR-014 · scripts/check-experiencia.sh · skills/zion-prd-discovery · skills/zion-prd-write · skills/zion-prd-decompose |
| 2026-07-18 | C2 | `RF-11` alterado: verificadores de arquitetura do produto na camada mecânica | sustentar por conselho a autoridade do documento de arquitetura distribuído | ADR-015 · scripts/check-arquitetura.sh · scripts/trace-arquitetura.sh |
| 2026-07-18 | C1 | `RF-18` novo: instalação da integração com o Spec Kit no repositório do produto | o canon chegava ao Spec Kit só pelas pontes manuais; clarify e implement rodavam sem canon | ADR-015 · skills/zion-speckit-install · assets/templates/regras-speckit.md · assets/templates/architecture-skeleton.md |
| 2026-07-18 | C2 | `RF-09` alterado: o trace reconcilia também os blocos derivados do documento de arquitetura do produto | artefato derivado se reconcilia por máquina, nunca à mão (RN-04) | ADR-015 · skills/zion-prd-trace · scripts/trace-arquitetura.sh |
| 2026-07-19 | C1 | `RF-19` novo: skill de ajuda de bolso do harness (épico E7 novo) | a ajuda ao iniciante vivia num prompt one-shot colado à mão: não viajava com a instalação e não era descobrível | ADR-016 · skills/zion-prd-ajuda · assets/speckit-map.md · scripts/check-canon.sh (C8) |
| 2026-07-18 | C2 | `RF-08` alterado: o prompt do plan injeta também a prosa estrutural do documento de arquitetura do produto | o plan é o único passo do Spec Kit que lê o como estrutural (recorte por passo) | ADR-015 · skills/zion-prd-plan-prompt |
