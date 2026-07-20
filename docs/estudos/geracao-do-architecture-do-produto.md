# Estudo — gerar e reconciliar o `architecture.md` do produto

## Contexto

O `architecture.md` do produto hoje é **semeado, não gerado**: `/zion-speckit-install` copia um
esqueleto em que a §1 (visão geral) e a §2 (integrações externas) são prosa do Autor **nunca tocada
por máquina**, e só a §3 (índice de ADRs) e a §4 (visão do backlog) são blocos derivados,
reconciliados pelo ritual do `/zion-prd-trace` (ADR-015 §3; `prd.md` RF-18 e RF-09). O Autor quer
que o documento seja gerado pelo harness e reconciliado ao longo da jornada, e pergunta: em que
momento gerar, em que momento reconciliar, se o gatilho é um comando próprio e quais validações se
aplicam.

A dor é comprovada, não hipotética. No `zion-mermaid-editor-app` — produto conduzido pelo próprio
harness, com a PRD fechada sobre 10 ADRs e o backlog decomposto em 19 specs — a §1 e a §2 seguem
com o placeholder literal do esqueleto. A máquina **já acusa** o estado (`check-arquitetura.sh`
emite `visao-vazia` quando a §1 não tem prosa), o veredito é advisório (ADR-004, `NFR-05`) e o
placeholder atravessou a jornada inteira intacto: mais aviso, isolado, não moveu o Autor. Enquanto
isso a ponte do plan promete injetar "a prosa estrutural do documento de arquitetura, quando
existe" (`prd.md` RF-08) e injeta vazio.

Duas decisões vigentes restringem qualquer alternativa. A fronteira de donos é fechada em "um dono
por pergunta" — constitution: princípios de repo; ADRs: decisões pontuais; architecture.md:
estrutura e prosa do Autor mais índices derivados; plan: o como por feature (ADR-015 §4). E o repo
do produto recebe **zero automação instalada** (ADR-015 §3, preservando ADR-005: as pontes entregam
prompt e param). Toda alternativa que escreva na §1/§2 declara a supersessão do ADR-015 como custo.

## Edge cases e incertezas

Convergidos com o Autor. 🧑 = só o humano responde.

**Autoria e fronteira**

1. 🧑 Se a máquina redige a §1, quem assina a prosa — o Autor revisa um rascunho ou a máquina
   entrevista e ele dita? ADR-015 diz "nunca tocada por máquina": geração **supersede** a cláusula
   ou a reinterpreta como "não sobrescrita sem consentimento"?
2. A §1 pede "componentes e como conversam" — isso é **como**, não o-quê. Sintetizar prosa a partir
   dos ADRs é síntese fiel, ou o harness passa a inventar arquitetura que ninguém decidiu?
3. 🧑 Onde para a §1 e começa o `plan` do Spec Kit? Uma §1 que nomeie componentes vira
   plan-de-repo-inteiro e quebra "um dono por pergunta" (ADR-015 §4).
4. O que a §1 pode dizer que não esteja em nenhum ADR? Se a resposta for "nada", ela é **derivado**
   e não prosa — muda a natureza do documento inteiro.
5. E a §2, num produto sem serviço externo algum (o caso real)? "Nenhuma integração" precisa ser
   estado válido e declarável, ou a seção fica eternamente vazia.

**Momento**

6. Gerar cedo (pós-spike) dá prosa fina e cara de manter; gerar tarde (pós-decompose) dá prosa fiel,
   mas depois de a ponte do plan já ter precisado dela (RF-08). Qual custo pagar?
7. 🧑 A primeira feature implementada revela estrutura que nenhum ADR previu. A §1 nasce antes ou
   depois do walking skeleton?
8. Um produto de jornada curta (discovery → PRD → decompose, sem spike) tem material para §1? O
   documento só faz sentido acima de um limiar de decisões?
9. Se a geração vier tarde, o repo carrega placeholder acusado por `visao-vazia` a jornada toda — o
   esqueleto deveria deixar de criar §1/§2 até haver o que escrever?

**Reconciliação e dia 2**

10. 🧑 Um ADR citado na §1 é superseded no dia 2. A máquina marca o parágrafo como suspeito,
    reescreve, ou apenas avisa "N decisões entraram desde a última edição"?
11. Como a máquina sabe que a prosa defasou, se prosa livre não tem elo rastreável? Exige âncora
    explícita por parágrafo — e a âncora não polui a prosa do Autor?
12. Reconciliar é **reescrever** ou **acusar**? Reescrevendo, o Autor perde a lapidação manual;
    acusando, volta-se à dor atual.
13. 🧑 Se o Autor escreveu prosa que diverge dos ADRs de propósito (a realidade mudou antes do
    registro), a reconciliação corrige um erro ou apaga um sinal?

**Gatilho**

14. Comando próprio versus fase acoplada: o harness tem 12 comandos — o 13º compra clareza ou dilui
    a jornada que a ajuda tem de explicar (RF-19)?
15. Acoplando ao trace, o ritual de fim de spec passaria a **redigir**, e não só recomputar. Muda a
    natureza do estágio.
16. 🧑 O gatilho roda uma vez (gênese) e nunca mais, ou é idempotente como discovery/estudo? Sendo
    re-rodável, como não sobrescrever o que o Autor lapidou?
17. Zero automação instalada no produto é vigente (ADR-015 §3, ADR-005). Um comando que grava no
    repo do produto fere isso, ou gravar-por-comando é o que discovery/write/decompose já fazem?

**Validação**

18. Além de `visao-vazia`, o que mais é decidível por máquina — a §1 cita ≥1 ADR? tamanho mínimo?
19. A regra "sem stack" (`quality-rules.md#fronteira`) **se inverte** aqui: este é o único documento
    em que nomear tecnologia é obrigatório. O verificador sabe disso, ou acusa falso positivo?
20. A validação nova é advisória (ADR-004, `NFR-05`) — mas o aviso já existia e não moveu o Autor.
    Qual a evidência de que mais aviso muda comportamento?

**O incômodo de fundo**

21. 🧑 O documento se paga? PRD, ADRs, backlog, constitution, plan e architecture são seis
    documentos vivos. Qual pergunta **só** a §1 responde, e com que frequência ela é feita?
22. Se a resposta honesta for "os ADRs e o plan já bastam", a alternativa vencedora é **remover**
    §1/§2 do esqueleto, não gerá-las. O estudo tem de admitir esse desfecho.
23. 🧑 A dor sentida é "falta prosa" ou "falta um mapa para eu me reorientar no meu próprio produto
    meses depois"? São soluções diferentes.

## Alternativas

### A0 — Não fazer

Mantém o ADR-015 intacto: esqueleto semeado, §1–§2 como prosa do Autor, `visao-vazia` como conselho
que ele atende quando quiser.

- **Prós:** custo zero; nenhuma supersessão; nenhum documento novo a manter; preserva integralmente
  a cláusula "prosa nunca tocada por máquina".
- **Contras:** a dor está provada e permanece — no caso real o placeholder atravessou 10 ADRs e 19
  specs; a ponte do plan (RF-08) continua injetando vazio; o aviso já existe e não bastou (edge 20).
- **ADRs tocados:** nenhum.

### A1 — Fase de arquitetura no fim do `/zion-prd-decompose`

O Estágio 4 ganha uma fase final: com os ADRs aceitos e o backlog fatiado, a skill entrevista o
Autor em poucas perguntas ancoradas nas decisões já tomadas e grava a §1–§2 com a prosa **que ele
dita** — a máquina propõe o rascunho, ele confirma ou edita.

- **Prós:** acerta o momento em que o material existe (edges 6 e 7) sem inventá-lo; acontece dentro
  de um comando que o Autor já roda, então não depende de ele lembrar (edge 16); nenhum comando novo
  para a ajuda explicar (edge 14); a autoria continua dele — a máquina propõe, ele assina (edge 1).
- **Contras:** muda a natureza do Estágio 4, que hoje fatia e não redige; engorda um comando já
  longo; a revisão de dia 2 fica descoberta (edge 10); quem já decompôs só é atendido re-rodando o
  estágio.
- **ADRs tocados:** **ADR-015 §3, supersessão parcial** — "§1–§2 nunca tocadas por máquina" passa a
  "redigidas sob ditado, nunca sobrescritas sem confirmação". Custo declarado: ADR novo com
  supersessão simétrica.

### A2 — Comando próprio `/zion-prd-architecture`, idempotente

Um 13º comando no padrão do discovery/estudo: a primeira rodada faz a gênese da §1–§2; re-rodar
retoma o documento e revisa seção a seção sem sobrescrever. Cada parágrafo carrega âncora das
decisões que o sustentam, e o trace passa a acusar quando um ADR ancorado é superseded ou quando
decisões novas entraram sem a prosa ser tocada.

- **Prós:** único desenho puro que cobre gênese, revisão e defasagem com um mecanismo só (edges 10 e
  16); rodável a qualquer momento, inclusive num produto já decomposto como o caso real; a âncora
  torna a defasagem decidível por máquina (edge 11), o que prosa livre não permite.
- **Contras:** o custo mais alto — skill, template, verificador com fixtures, RF novo, entrada na
  ajuda; depende de o Autor lembrar de rodar, que é exatamente a falha que produziu a dor; âncoras
  poluem a prosa; risco real de redigir estrutura que nenhum ADR decidiu (edge 2), invadindo o dono
  `plan` (edge 3).
- **ADRs tocados:** a mesma supersessão parcial do ADR-015 §3 de A1, mais um ADR novo para a
  natureza do documento (prosa ancorada em vez de prosa livre).

### A3 — Não gerar prosa: derivar o mapa

Inverte a leitura da dor (edges 21 e 23): se a pergunta que só este documento responde é "como me
reoriento no meu produto meses depois", a resposta é um **mapa derivado**, não prosa. A §1 vira um
terceiro bloco reconciliado pelo trace — decisões estruturantes agrupadas por área, com o que cada
uma fixou e as specs que a exercitam — e a §2 admite "nenhuma integração externa" como estado
válido. A prosa livre sai do esqueleto e `visao-vazia` deixa de existir, por não haver mais o que
ficar vazio.

- **Prós:** sempre em dia por construção — nunca defasa, nunca é esquecida, o dia 2 sai de graça
  porque o trace já roda; custo marginal baixo, reusa o mecanismo de blocos que já funciona; zero
  risco de inventar arquitetura, pois só reagrupa o que os ADRs decidiram; honesto quanto ao
  inventário de documentos vivos (edge 22).
- **Contras:** não entrega o que motivou o documento — a prosa estrutural com autoridade própria; um
  índice reagrupado diz *o que foi decidido*, não *como os componentes conversam*; a ponte do plan
  segue injetando índice, não narrativa.
- **ADRs tocados:** **ADR-015 §3 e §4, supersessão** — §1–§2 deixam de ser prosa do Autor e o
  documento vira puramente derivado. Custo declarado: reabre uma decisão tomada justamente por
  sentir falta da prosa.

### Composição A1+A3 (escolha do Autor)

As duas compõem e foi este o caminho escolhido: **derivar o mapa** (A3) para a parte que os ADRs já
respondem, e, no fim da decomposição, **ditar por cima** a narrativa que o mapa não expressa (A1). A
composição herda o "sempre em dia" de A3 e a narrativa de A1, ao custo de somar os dois esforços e
as duas supersessões do ADR-015. Aparece na tabela de ROI como linha própria, marcada como
composição.

## ROI

Notas de 1 a 5; esforço e risco são **invertidos** (5 = menor esforço, menor risco e maior
reversibilidade). ROI = média das três.

| # | Alternativa | Impacto | Esforço | Risco | **ROI** |
|---|-------------|---------|---------|-------|---------|
| A3 | Derivar o mapa (sem prosa) | 3 | 4 | 4 | **3,67** |
| A0 | Não fazer | 1 | 5 | 5 | **3,67** |
| A1 | Fase no `/zion-prd-decompose` | 4 | 3 | 3 | **3,33** |
| A2 | Comando próprio idempotente | 5 | 2 | 3 | **3,33** |
| A1+A3 | Composição (escolha do Autor) | 5 | 2 | 3 | **3,33** |

**Justificativas**

- **A3 — 3,67.** Impacto 3: mata o placeholder e entrega o mapa de reorientação, mas não a narrativa
  que motivou o documento. Esforço 4: reusa os blocos derivados e o ritual do trace, sem skill nova.
  Risco 4: nada a inventar e nada a defasar — o risco é de desejo, não técnico, e é altamente
  reversível.
- **A0 — 3,67.** Impacto 1: a dor está provada e permanece. Esforço 5 e Risco 5 por definição. **A
  nota alta é artefato da média**: não fazer sempre pontua bem quando dois dos três critérios medem
  custo. Esta linha é piso de comparação, não recomendação.
- **A1 — 3,33.** Impacto 4: resolve a gênese no momento certo e dentro de um comando já rodado, mas
  deixa o dia 2 descoberto. Esforço 3: uma fase nova, verificador reaproveitado, ADR de supersessão.
  Risco 3: desvia a natureza do Estágio 4 e faz a máquina propor estrutura — reversível, mas cria
  precedente.
- **A2 — 3,33.** Impacto 5: cobre gênese, revisão e defasagem com um mecanismo só. Esforço 2: o
  pacote completo — skill, template, verificador com fixtures, RF, ajuda. Risco 3: depende da
  memória do Autor (a falha original), pressiona a fronteira com o dono `plan` e adiciona o 13º
  comando.
- **A1+A3 — 3,33.** Impacto 5: é o único desenho que entrega mapa sempre em dia **e** narrativa
  assinada pelo Autor, cobrindo tanto a gênese quanto o dia 2. Esforço 2: soma os dois trabalhos —
  bloco derivado novo mais fase nova no Estágio 4. Risco 3: carrega as duas supersessões do ADR-015
  (§3 e §4) e o desvio de natureza do Estágio 4; ambos reversíveis, nenhum barato de reabrir. O ROI
  médio a empata com A1 e A2 porque a média pune a soma de esforços — a escolha do Autor se justifica
  pelo impacto, não pela média.

## Recomendação

**Não vinculante.** A composição A1+A3 é o caminho escolhido pelo Autor e é o que este estudo
sustenta: derivar como bloco reconciliado tudo o que os ADRs já respondem — matando por construção o
`visao-vazia`, a defasagem silenciosa e a dependência da memória do Autor — e reservar a prosa ditada
para a única coisa que nenhum derivado expressa, como os componentes conversam, gravada no fim da
decomposição, quando o material finalmente existe. Antes de implementar, três perguntas continuam
abertas e são do Autor: onde exatamente para a §1 e começa o `plan` (edge 3), o que a máquina faz
quando um ADR citado é superseded no dia 2 (edge 10) e se a prosa ditada precisa de âncora
rastreável ou se basta o aviso por contagem de decisões novas (edge 11). Elas decidem o desenho da
reconciliação e não devem ser respondidas por quem implementa.

## Próximo passo sugerido

Se aprovado, rodar `superpowers:brainstorming` com a alternativa escolhida →
`superpowers:writing-plans` → `superpowers:executing-plans`. Decisão estruturante nova vira ADR via
`/zion-adr-new` e reflete no canon (`prd.md`/`architecture.md` no mesmo commit — CLAUDE.md). Aqui há
supersessão simétrica do ADR-015 (§3 e §4) a registrar.
