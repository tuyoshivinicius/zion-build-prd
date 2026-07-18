# Estudo — Integração instalável com o Spec Kit: canon reconhecido, reconciliação de volta e a crítica do documento de arquitetura distribuído

## Contexto

O Autor (persona da `prd.md §3`) usa o zion-build-prd para criar e decompor a PRD em backlog de
specs e implementa com o GitHub Spec Kit. Hoje o canon (`docs/prd.md`, `docs/adr/`, backlog) chega
ao Spec Kit **apenas** pelas três pontes manuais (`prd.md` E2: RF-06/07/08), que montam prompts e
param (ADR-005). O candidato pede que a **instalação** do harness configure o repositório do
produto para que o workflow do Spec Kit reconheça esses artefatos como fonte canônica de produto e
arquitetura em todos os passos (specify, clarify, plan, implement); que specs novas nasçam sempre
do fluxo do zion-build-prd; que specs nascidas fora reconciliem com o canon ao fim da
implementação; e que, além da PRD, o repo do produto receba um **documento de arquitetura** como
fonte da verdade de arquitetura. Esta revisão do estudo submete essa última parte à crítica: o
harness grava no projeto-alvo apenas `discovery.md`, `prd.md` e `docs/adr/` (`prd.md`
RF-01/02/03/04); o `architecture.md` que existe é o do próprio harness, natureza **governança**,
não distribuída (`architecture.md §6`) — e o como do produto do Autor **já tem donos**: o ADR para
decisão de repo inteiro (`prd.md §4`: o harness "não decide stack pelo autor, só registra a
decisão dele em ADR"), a constitution do Spec Kit para princípios de repo inteiro (alimentada pela
ponte RF-06) e o plan para o como de cada feature (alimentado pela ponte RF-08). A pergunta que
este estudo responde: o quarto artefato é necessário e mais coeso — ou redundância com custo de
drift? Tudo sob as restrições de sempre: gates advisórios no projeto-alvo (RN-01, NFR-05,
ADR-004), fronteira o-quê/como (RN-02), derivados por máquina (RN-04), fonte única sem drift
(RN-05) e distribuição dual autocontida (ADR-002).

## Edge cases e incertezas

Perguntas que a solução escolhida terá de responder — **[humano]** marca as que só o Autor pode
responder:

Sobre a integração com o Spec Kit:

1. **Onde o Spec Kit lê contexto?** O Spec Kit não tem mecanismo formal de extensão: o contexto
   entra pela constitution, pelos templates de comando e pelo arquivo de regras do agente no
   repo-alvo. Qual dessas superfícies é estável o bastante para ancorar a integração sem quebrar a
   cada versão do Spec Kit?
2. **Upgrade do Spec Kit sobrescreve a integração?** Se a solução tocar arquivos que o Spec Kit
   regenera, como o harness detecta e reaplica a integração — e isso vira um verificador advisório
   no padrão E5 (`prd.md` RF-11)?
3. **"Reconhecer como canônico" é referência ou cópia?** Referência viva evita drift mas depende
   do agente seguir o apontamento; cópia garante presença no contexto mas cria derivado a
   sincronizar (RN-05 exige fonte única com cópia verificada).
4. **O que exatamente reconcilia uma spec nascida fora?** RF novo descoberto vira dia 2
   (`prd.md` RF-10, `zion-prd-evolve`); spec sem elo já é acusada como intraçável pelo
   `zion-prd-trace` (RF-09). A reconciliação é um comando novo ou um roteamento dos dois
   existentes?
5. **Como detectar que uma spec nasceu fora do fluxo?** O prompt do specify já pede o elo de
   rastreabilidade (RF-07); a ausência do elo é o marcador natural — mas ele precisa ser
   machine-legível no artefato da spec.
6. **[humano] "Sempre iniciam do fluxo" pode ser só conselho?** RN-01/NFR-05 proíbem gate
   bloqueante no projeto-alvo. O Autor aceita que o "sempre" do candidato vire dever advisório —
   ou espera trava, o que custaria a supersessão de ADR-004?
7. **Dois territórios de specs.** O backlog do zion e as pastas de spec do Spec Kit convivem no
   mesmo repo; o mapeamento entre eles hoje é o elo de rastreabilidade. A integração cria elo novo
   ou reforça o existente?
8. **Idempotência da instalação.** O passo que escreve no repo do produto precisa ser re-rodável
   (após upgrade do harness ou do Spec Kit) sem duplicar nem destruir customização do Autor — o
   mesmo padrão retomável do discovery (RF-01).
9. **[humano] Integração agnóstica de agente ou só para o agente do harness?** O Spec Kit suporta
   vários agentes; regras no arquivo de memória de um agente específico não alcançam os outros.
   O Autor precisa de cobertura multi-agente (aponta para templates) ou o agente único basta
   (aponta para regras)?
10. **Vazamento de fronteira automatizado.** Se o canon inteiro flui automaticamente para todos os
    passos, o como (ADRs) pode vazar no specify e o o-quê diluir o plan — a injeção precisa ser
    seletiva por passo (RN-02), como as pontes já fazem à mão.
11. **[humano] As pontes ficam obsoletas ou complementares?** Se o contexto flui pela integração,
    o valor das pontes RF-06/07/08 muda de "carregar canon" para "curar o recorte por passo". O
    Autor quer substituição ou convivência?
12. **[humano] Quem dispara a reconciliação ao fim da implementação?** O harness não executa o
    ciclo (ADR-005) e instalar automação no repo do produto é invasivo. O gatilho é ritual humano
    aconselhado pela regra instalada, ou o Autor aceita automação no seu repo?
13. **Envelhecimento do artefato instalado.** O bloco escrito no repo do produto desatualiza
    quando o harness evolui — a atualização é re-rodar o instalador, e o drift entre versões é
    acusado por verificador advisório?

Sobre o documento de arquitetura distribuído — a crítica:

14. **Que pergunta o documento responde que os donos atuais não respondem?** Decisão de repo
    inteiro → ADR (`prd.md §4`); princípio de repo inteiro → constitution (ponte RF-06); como da
    feature → plan (ponte RF-08). O que sobra de conteúdo exclusivo — mapa de componentes, visão
    estrutural — justifica um artefato com status de fonte da verdade, ou é conteúdo que cabe no
    contexto dos próprios ADRs?
15. **Fonte da verdade sem enforcement é fonte da verdade?** O `architecture.md` do harness
    funciona porque o guard de canonização **bloqueia** commit com drift (ADR-010) — governança do
    próprio repo. No repo do produto todo veredito é conselho (RN-01, NFR-05): o documento
    nasceria "canônico" por declaração, sem mecanismo que impeça o apodrecimento. O título vira
    aspiração.
16. **O custo da parte derivada.** Índice de ADRs semeado por máquina exige replicar a maquinaria
    de sincronização e verificação de drift (RN-04/RN-05) dentro do repo do usuário — governança
    do harness exportada para um território onde ela não bloqueia (edge 15). O custo é permanente;
    o benefício sobre "ler `docs/adr/` direto" é um índice.
17. **Duas fontes da verdade de repo inteiro competindo.** Constitution (do Spec Kit, alimentada
    por RF-06) e architecture.md (do zion) cobririam território sobreposto — princípios e
    restrições estruturais. Qual vence quando divergem? A coesão pede um dono por pergunta, não
    dois artefatos com a mesma ambição.
18. **[humano] A dor é "falta documento" ou "falta visão unificada"?** Se o que o Autor sente
    falta é navegar o como do repo num lugar só, uma **vista derivada** (índice de ADRs gerado no
    ritual do trace, como o backlog — RN-04) resolve sem status de fonte da verdade. Se o Autor
    quer prosa estrutural própria com autoridade, aí sim é um artefato novo — com o custo dos
    edges 15–17. Qual das duas dores é a real?
    **Respondida pelo Autor (2026-07-18): a dor é a segunda — prosa estrutural com autoridade
    própria.** A resposta reabre A3 e os custos dos edges 15–17 passam de argumento de veto a
    trade-off aceito conscientemente, a mitigar no desenho.

## Alternativas

### A1 — Não fazer

Manter as três pontes (RF-06/07/08) como único canal de contexto e a disciplina do Autor +
`zion-prd-trace` (RF-09) como reconciliação. Nenhum artefato novo no repo do produto.

- **Prós:** custo zero; nenhum acoplamento à superfície instável do Spec Kit; nenhum artefato novo
  a envelhecer no repo do produto.
- **Contras:** a dor persiste — clarify e implement seguem sem canon; spec nascida fora só aparece
  quando o Autor lembra de rodar o trace; o "reconhecimento canônico" continua dependendo de o
  Autor colar prompt.
- **ADRs tocados:** nenhum.

### A2 — Ciclo fechado sem documento de arquitetura novo

Skill de instalação idempotente que grava um bloco de regras no repo do produto declarando os
artefatos zion como fonte canônica — com a arquitetura canônica sendo **os donos que já existem**:
`docs/adr/` para decisão de repo inteiro (`prd.md §4`), a constitution para princípio de repo
inteiro (ponte RF-06) e o plan para o como por feature (ponte RF-08). A regra define o recorte de
leitura por passo do Spec Kit (RN-02) e o dever advisório de reconciliação. Mais a metade
mecânica: marcador de origem machine-legível na spec (elo de rastreabilidade presente = nascida do
fluxo), verificador advisório no padrão E5 que acusa spec sem elo, e roteamento do ritual de fim
de implementação para `zion-prd-trace` (RF-09) e `zion-prd-evolve` (RF-10). Opcional e sem status
canônico: uma **vista derivada** — índice de ADRs gerado no ritual do trace, como o backlog
(RN-04) — para a dor de navegação, se ela for a real (edge 18).

- **Prós:** cobre a dor central inteira (canon reconhecido + reconciliação mecânica) sem criar
  artefato de autoridade novo; um dono por pergunta — coesão preservada (edge 17); nada a manter
  sincronizado além do que o trace já reconcilia; advisory por construção (RN-01); verificador no
  padrão E5 (RF-11, NFR-04).
- **Contras:** não entrega o "documento de arquitetura" literal do candidato — entrega o
  equivalente funcional (ADRs + constitution + vista derivada); se a dor real do Autor for prosa
  estrutural própria, esta alternativa não a acomoda; o "sempre iniciam do fluxo" continua
  conselho (edge 6).
- **ADRs tocados:** nenhum superseded; pede ADR novo (superfície de integração + semântica do
  marcador de origem); estende ADR-002 e o padrão do ADR-004.

### A3 — Ciclo fechado com architecture.md distribuído

A2 mais o quarto artefato: `docs/architecture.md` do produto semeado de template distribuído
(análogo ao esqueleto da PRD — ADR-002, `architecture.md §4`), parte derivada por máquina (índice
de ADRs, visão do backlog — RN-04), parte prosa estrutural do Autor, declarado fonte da verdade de
arquitetura na regra instalada e injetado na ponte do plan ao lado dos ADRs (RF-08).

Mitigações dos custos declarados, se esta alternativa for a escolhida: **(edge 17)** fronteira de
donos escrita na própria regra instalada — constitution guarda princípios (ponte RF-06),
architecture.md guarda estrutura e prosa do Autor + índice derivado de ADRs; um dono por pergunta,
sem território sobreposto. **(edge 16)** a única parte sincronizada por máquina é o índice
derivado, reconciliado no mesmo ritual do trace (RN-04) — nenhuma maquinaria nova além da que A2
já cria. **(edge 15)** a autoridade é sustentada por verificador advisório no padrão E5 (acusa
índice defasado e seções obrigatórias ausentes) e, opcionalmente, por guard de canonização
**opt-in** no repo do Autor — quem quer os dentes do ADR-010 os ativa por escolha, preservando
RN-01 como default.

- **Prós:** entrega o pedido literal do candidato; visão unificada do como num artefato só; espaço
  legítimo para prosa estrutural (mapa de componentes, integrações) que os ADRs pontuais não
  carregam.
- **Contras:** os da crítica (edges 14–17) — responde perguntas que ADR, constitution e plan já
  respondem; "fonte da verdade" sem enforcement bloqueante é aspiração (RN-01 impede o guard que
  a sustenta no harness — ADR-010); replica a maquinaria de drift RN-04/RN-05 no repo do usuário;
  compete com a constitution pelo mesmo território; a prosa livre apodrece sem que verificador
  algum acuse.
- **ADRs tocados:** nenhum superseded; pede ADR novo maior (os da A2 + natureza e autoridade do
  documento distribuído); tensiona o espírito do `prd.md §4` (o como do harness registra-se em
  ADR) sem contradizê-lo formalmente.

### A4 — Extensão dos templates do Spec Kit (patch de superfície)

O instalador injeta seções nos templates de comando do Spec Kit no repo-alvo, para que specify,
clarify, plan e implement carreguem mecanicamente o recorte certo do canon e cobrem o elo de
rastreabilidade — mais um verificador advisório de drift que acusa quando um upgrade do Spec Kit
sobrescreve o patch.

- **Prós:** contexto flui em todos os passos sem depender de disciplina; agnóstico de agente
  (edge 9 resolvido); o elo de rastreabilidade passa a ser pedido pelo próprio template.
- **Contras:** acopla à superfície interna do Spec Kit, que não oferece contrato de extensão —
  cada versão pode quebrar o patch (edges 1–2); manutenção contínua de compatibilidade; risco de
  conflitar com customizações que o Autor já fez nos templates; o custo recai no elo mais fraco do
  harness (dependência externa, `prd.md §10` risco análogo ao do superpowers).
- **ADRs tocados:** ADR-005 permanece intacto (configurar ≠ disparar), mas a decisão contraria o
  espírito de acoplamento mínimo do ADR-007 (contrato explícito com dependência externa) — exigiria
  ADR novo declarando o contrato de compatibilidade com o Spec Kit como custo permanente.

## ROI

Recalculado após a resposta do Autor ao edge 18 (a dor real inclui prosa estrutural com
autoridade própria — o impacto de A2 e A3 muda de lugar):

| Alternativa | Impacto | Esforço (inv.) | Risco (inv.) | ROI |
|---|---|---|---|---|
| A3 — Ciclo fechado com architecture.md distribuído | 5 | 3 | 3 | **3,7** |
| A2 — Ciclo fechado sem documento novo | 3 | 4 | 4 | **3,7** |
| A1 — Não fazer | 1 | 5 | 5 | **3,7** |
| A4 — Patch dos templates do Spec Kit | 4 | 2 | 2 | **2,7** |

O empate triplo em 3,7 é o retrato honesto do trade-off — e o texto o desfaz: só A3 resolve a dor
como o Autor a definiu; A2 empata subindo em esforço/risco o que perde em impacto; A1 empata só
porque não fazer nada é barato. Número igual, dor diferente.

- **A3 (3,7):** impacto 5 — com o edge 18 respondido, é a única alternativa que acomoda a dor
  real: prosa estrutural com autoridade própria, mais tudo de A2 (canon reconhecido +
  reconciliação mecânica). Esforço 3 — tudo de A2 mais template, semeadura e o verificador do
  documento; as mitigações desenhadas não adicionam maquinaria além do ritual do trace que A2 já
  cria. Risco 3 — os custos dos edges 15–17 seguem reais (prosa sem enforcement duro por default,
  autoridade sustentada por conselho), mas passam de veto a trade-off aceito, mitigado por
  fronteira de donos explícita, índice derivado no ritual existente e guard opt-in.
- **A2 (3,7):** impacto 3 — caiu de 4: com a dor definida como prosa com autoridade, a vista
  derivada sem status canônico deixa de resolver o cerne; cobre integração e reconciliação, não o
  documento. Esforço 4 e risco 4 — inalterados: menos escopo, menos superfície de drift.
- **A1 (3,7):** impacto 1 — não resolve nada; a nota vem só de esforço 5 e risco 5. O empate
  numérico não é equivalência real: aqui a dor fica intacta.
- **A4 (2,7):** impacto 4 — cobertura mecânica total dos passos, mas não trata reconciliação nem
  o documento de arquitetura. Esforço 2 — compatibilidade contínua com superfície sem contrato de
  extensão. Risco 2 — quebra silenciosa a cada upgrade do Spec Kit e conflito com customização do
  Autor; o verificador de drift mitiga mas não elimina.

## Recomendação

**Não vinculante.** Com o edge 18 respondido pelo Autor — a dor é prosa estrutural **com
autoridade própria** — a recomendação passa a **A3 — ciclo fechado com architecture.md
distribuído**, nos termos das mitigações declaradas na alternativa: a crítica desta revisão
continua válida como **condição de desenho**, não mais como veto. O documento só se justifica se
(1) a fronteira de donos for escrita na regra instalada — constitution guarda princípios (RF-06),
architecture.md guarda estrutura e prosa do Autor + índice derivado de ADRs, sem território
sobreposto (edge 17); (2) a única parte sincronizada por máquina for o índice derivado, no ritual
do trace que A2 já cria (RN-04, edge 16); e (3) a autoridade for sustentada por verificador
advisório no padrão E5, com guard de canonização **opt-in** para quem quiser os dentes do ADR-010
no próprio repo — preservando RN-01 como default (edge 15). Sem essas três condições, o documento
degenera na fonte da verdade aspiracional que a crítica descreveu, e A2 volta a ser o caminho. As
demais perguntas humanas (edges 6, 9, 11, 12) seguem abertas e entram no brainstorming da
alternativa escolhida.

## Próximo passo sugerido

Se aprovado, rodar `superpowers:brainstorming` com a alternativa escolhida →
`superpowers:writing-plans` → `superpowers:executing-plans`. Decisão estruturante nova vira ADR via
`/zion-adr-new` e reflete no canon (`prd.md`/`architecture.md` no mesmo commit — CLAUDE.md).
