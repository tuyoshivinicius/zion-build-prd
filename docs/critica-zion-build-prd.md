# Crítica rigorosa do zion-build-prd

> **Escopo:** avaliação do zion-build-prd nas suas duas formas — o **processo** narrativo
> (`docs/guia-prd-para-spec-kit.md`) e o **harness** de 8 skills (`docs/como-usar.md` +
> `skills/*/SKILL.md` + `assets/quality-rules.md`) — com métricas derivadas diretamente do único
> projeto que usou o método ponta-a-ponta (`zion-mermaid-editor-app`) e comparação com o estado da
> prática da indústria (fontes verificadas, links na seção final).
> **Data da apuração:** 2026-07-17. **Método:** leitura integral do harness, mineração do git/artefatos
> do projeto real, pesquisa multi-fonte com verificação adversarial de claims (3 votos por claim).
> **Aviso de validade que atravessa todo o documento:** n=1, sem grupo de controle, e o autor do
> harness é o mesmo operador do projeto avaliado — nada aqui é prova estatística; é diagnóstico
> qualitativo ancorado em evidências.

---

## Resumo executivo

O zion-build-prd é um harness bem-arquitetado em torno de uma ideia central correta — a fronteira
"o-quê/por-quê × como/com-quê" — que converge com a filosofia declarada do próprio GitHub Spec Kit e
ataca uma limitação que o mantenedor do Spec Kit admite publicamente (vazamento de detalhe técnico
para a spec). A decisão de **parar nas pontes** em vez de automatizar o ciclo inteiro é defensável e
alinhada com a cautela da indústria sobre autonomia agêntica. No projeto real, a cadência
**spec-antes-do-código foi 100% respeitada** e a constituição gerada é exemplar (8 princípios
decidíveis, rastreáveis, cobertos por testes de contrato reais). Porém, três promessas centrais
**quebraram na única execução existente**: a tabela de rastreabilidade nasceu e morreu no mesmo
commit (17/17 linhas "pendente" com 3 fatias já implementadas); a PRD vazou stack ("React Flow",
`docs/PRD.md:220`) sem que o gate detectasse; e o "spike com código descartável" prometido pelo guia
virou, na prática do próprio harness, pesquisa bibliográfica — a skill `/zion-prd-spike` nunca pede
código. A causa comum é estrutural: **toda regra decidível do harness é verificada por prosa
interpretada por LLM, nunca por script** — num repositório que, ironicamente, tem shell script e CI
para vigiar drift dos próprios assets. As recomendações priorizadas atacam exatamente isso.

---

## Sumário

1. [Crítica sob a ótica "como processo"](#1-crítica-sob-a-ótica-como-processo)
2. [Crítica sob a ótica "como harness"](#2-crítica-sob-a-ótica-como-harness)
3. [Métricas de sucesso no zion-mermaid-editor-app](#3-métricas-de-sucesso-no-zion-mermaid-editor-app)
4. [Comparação com as práticas da indústria](#4-comparação-com-as-práticas-da-indústria)
5. [Síntese: o que preservar e recomendações priorizadas](#5-síntese-o-que-preservar-e-recomendações-priorizadas)
6. [Fontes](#6-fontes)
7. [Apêndice: método de apuração e limites de validade](#7-apêndice-método-de-apuração-e-limites-de-validade)

---

## 1. Crítica sob a ótica "como processo"

Avalia a metodologia dos 6 estágios em si (`docs/guia-prd-para-spec-kit.md`), independente da
ferramenta que a executa.

### 1.1 O que sustenta o processo (e por quê)

**A fronteira o-quê × como é o invariante certo.** O guia a declara logo no cabeçalho
(`guia-prd-para-spec-kit.md:9-11`) e a repete em cada estágio. Isso não é preciosismo: é exatamente a
fronteira que o Spec Kit declara como fundacional ("specifications are intentionally detached from
technical details" — Den Delimarsky, mantenedor), e o vazamento de stack para a spec é uma das
limitações que ele mesmo lista como problema recorrente na prática (ver §4.1). Um processo de PRD que
policia essa fronteira *antes* do `specify` ataca o problema no lugar certo da cadeia.

**ADRs antes de fechar a PRD inverte um vício comum — para melhor.** O Passo 2
(`guia-prd-para-spec-kit.md:83-104`) exige que as 2–3 decisões estruturantes estejam decididas e
registradas antes da PRD, e que virem restrições (seção 8) e insumo da constitution. A prática
dominante registra decisões tarde ou nunca; aqui elas são o *input* do documento de requisitos. O
encadeamento ADR → restrição na PRD → princípio na constitution → "honrar, não re-decidir" no
plan-prompt é a contribuição mais original do método e funcionou no projeto real (a constitution
gerada rastreia cada princípio a um NFR ou ADR de origem).

**Walking skeleton como fatia zero e INVEST/SPIDR como validadores** (`guia:151-156`,
`quality-rules.md:59-70`) são aplicações fiéis do cânone (Cockburn, Wake, Cohn — ver §4.4). O
teste-relâmpago "esta fatia, sozinha, dá uma demo ponta-a-ponta?" é uma operacionalização feliz do
INVEST — mais decidível que o acrônimo original.

**A ênfase no escopo negativo** ("os 'não faz' explícitos... o escopo negativo costuma valer mais que
o positivo", `guia:78-79`) é rara em templates de PRD e valiosa: no projeto real, a seção "Não faz"
da PRD (`zion-mermaid-editor-app/docs/PRD.md:60-71`) é a mais informativa do documento.

### 1.2 Onde o processo é frágil

**F1 — A promessa do spike-como-código não tem mecanismo que a cumpra.** O guia é enfático:
"responder com **código descartável** (não com opinião) as 2–3 decisões estruturantes"
(`guia:85-86`) e "cada decisão estruturante tem um ADR aceito, **sustentado por um spike que você de
fato rodou**" (`guia:103-104`). Mas o processo não define o que constitui um spike suficiente, onde o
código vive, nem qual evidência mínima o ADR deve citar. Resultado observado no projeto real: dos 4
ADRs, apenas o ADR-002 tem spikes de código de verdade (`docs/adr/spikes/adr-002-*`, 633 linhas);
ADR-001, ADR-003 e ADR-004 declaram como "spike/evidência" execuções de deep-research — pesquisa,
não código. Isso é precisamente a "opinião" (agora com citações) que o guia diz querer evitar. O
processo promete um rigor que não instrumenta.

**F2 — A rastreabilidade tem cerimônia de nascimento e nenhuma de manutenção.** O Passo 4 injeta a
tabela `RF-xx ↔ specs/###` e o Passo 6 promete mantê-la "viva" (`guia:253-267`) — mas nenhum estágio,
skill ou checklist posterior tem a *tarefa* de atualizá-la. O ciclo por feature (Passo 5b) termina em
`converge` e volta para a próxima fatia sem passar pela tabela. Um artefato manual sem dono e sem
gatilho de atualização morre — e morreu (ver métrica 3.b: 17/17 linhas "pendente" com 3 fatias
implementadas). Esse é um defeito de *design do processo*, não só de execução: a indústria conhece
esse modo de falha em ADRs ("write-only records") e a resposta padrão é automatizar ou abandonar a
promessa.

**F3 — Gates que "aconselham mas não bloqueiam" sem nenhum backstop.** A filosofia
(`como-usar.md:28-29`) é coerente com human-in-the-loop, e o Spec Kit faz o mesmo (checkpoints
advisórios, ver §4.1). Mas o Spec Kit assume revisão humana ativa em cada checkpoint, e o processo
zion não institui *nenhum* momento estruturado de revisão humana (compare com a leitura silenciosa de
15–20 min + ciclos escalonados do PR/FAQ da Amazon, §4.2). Quando o gate é um aviso do mesmo agente
que escreveu o artefato, e o humano é um dev solo com pressa, o custo de ignorar é zero. As três
quebras observadas (tabela morta, vazamento de stack, spike-sem-código) passaram todas por gates que
"aconselharam". Gate advisório sem ritual de revisão nem verificação mecânica é, na prática, um
comentário.

**F4 — O processo não dimensiona a si mesmo.** São 6 estágios + 8 passos do Spec Kit por fatia — até
14 etapas para entregar uma fatia que, no projeto real, tem em média ~620 linhas de código. O guia
prescreve PRD de 6–12 páginas (`guia:110`) enquanto a recomendação enxuta dominante (PR/FAQ) fala em
primeiro rascunho "em horas, não dias" (§4.2). Não existe uma seção "quando NÃO usar este processo"
nem um modo leve (o Kiro, por exemplo, oferece "Quick Plan" sem approval gates para features bem
compreendidas — §4.5). Para um dev solo num projeto pessoal, o custo observado foi ~1,6 linha de
markdown de processo por linha de código (ver métrica 3.e) — sem qualquer evidência de que o
benefício escale junto.

**F5 — O vocabulário da PRD e o do Spec Kit não se encontram.** A PRD numera `RF-xx`; o Spec Kit
gera `FR-xxx` internos por spec. O processo manda citar RF-xx "como contexto" no specify
(`quality-rules.md:82-84`), mas não exige que o `spec.md` resultante **liste os RF cobertos** — e no
projeto real a spec 001 (walking skeleton) não menciona nenhum RF-xx (só FR-001…FR-008 próprios). A
cadeia RF→spec depende então exclusivamente da tabela manual — exatamente o artefato que morre (F2).
Rastreabilidade que depende de um único elo manual não é rastreabilidade.

**F6 — A fronteira tem zona cinzenta que o processo finge não existir.** As "restrições vindas de
ADRs" podem entrar na PRD (`quality-rules.md:17`), mas restrição de ADR frequentemente *é* "como": a
R2 da PRD real fala em "camada de adaptação isolada e substituível"
(`zion-mermaid-editor-app/docs/PRD.md:137-140`) — arquitetura, dentro da PRD, legitimada pela regra.
O processo trata a fronteira como binária ("cita biblioteca → vaza") quando ela é um gradiente, e não
oferece critério para o caso intermediário. Não por acaso, os dois vazamentos reais observados
(discovery citando `localStorage`/dagre/ELK em `docs/discovery.md:44,91`; PRD citando "React Flow" em
`docs/PRD.md:220`) ocorreram em zonas que as regras não exemplificam.

**F7 — O processo é greenfield-only.** Não há palavra sobre o dia 2: requisito que muda depois da
release, ADR substituído (o template de `zion-adr-new` até prevê "Substituído por ADR-m", mas nenhum
estágio dispara isso), re-decomposição quando a PRD evolui, ou o que fazer com a PRD quando a
realidade diverge dela. Um método cuja tese é "artefatos-guia versionados" precisa dizer como os
artefatos evoluem — senão eles congelam no dia 1, como a PRD real congelou (1 único commit em toda a
história, ver §3.a).

---

## 2. Crítica sob a ótica "como harness"

Avalia a implementação como scaffold agêntico: as 8 skills, o contrato de fases, a cadeia de
delegação e a infraestrutura de manutenção.

### 2.1 Acertos de engenharia

**O padrão assets → references com sync + hook + CI é a melhor engenharia do repositório.** Fonte
única em `assets/`, cópias derivadas geradas por `scripts/sync-assets.sh`, mapeamento declarativo em
`scripts/asset-map.sh`, pre-commit hook que regenera e um workflow de CI (`.github/workflows/check-assets.yml`)
como backstop contra `--no-verify`. Isso resolve corretamente um problema real (o `npx skills` exige
skills autocontidas e não resolve dependências) sem sacrificar manutenção. É o único ponto do
harness onde uma invariante é garantida por máquina — e não por acaso é o único que não quebrou.

**O contrato de 5 fases dá previsibilidade real.** Toda skill segue Fase 0 (pré-requisito) → 1
(validar entrada) → 2/3 (formatar e delegar/montar) → 4 (validar saída). Uniformidade de contrato é o
que separa um scaffold de uma coleção de prompts; facilita auditar, comparar e evoluir os comandos.

**Parar nas pontes é uma decisão de produto correta.** As três pontes montam o prompt e "PARAM"
(`skills/zion-prd-*-prompt/SKILL.md`, Fase 4: "PARE AQUI. Não invoque... o ciclo do Spec Kit é do
usuário"). Isso posiciona o gate humano na fronteira mais cara (o momento em que a spec vira
compromisso) e é coerente tanto com o desenho do Spec Kit quanto com o alerta empírico do estudo METR
(devs experientes *acham* que a IA os acelera mesmo quando ela os atrasa — §4.5): manter o humano no
disparo é proteção contra exatamente esse viés.

**Degradação graciosa bem pensada.** Preflight de `superpowers` com mensagem acionável e parada limpa;
`deep-research` degrada para pesquisa manual (`skills/zion-prd-spike/SKILL.md`, Fase 2/3);
idempotência no `write` ("se `docs/PRD.md` já existe, NÃO sobrescreva — modo revisar",
`skills/zion-prd-write/SKILL.md`, Fase 0). São detalhes que a maioria dos scaffolds de prompt ignora.

**As descriptions das skills são bem escritas** — gatilhos explícitos, escopo claro, "não dispara o
/speckit.* por você" repetido onde importa. Isso reduz invocação errada por modelo, que é o modo de
falha mais comum de skills.

### 2.2 Onde o harness é frágil

**H1 — Nenhuma regra decidível é verificada por máquina.** Este é o defeito estrutural do harness.
`quality-rules.md` define critérios genuinamente decidíveis — "zero stack" com denylist implícita
(linguagem/framework/biblioteca), "NFRs com número", "uma linha por RF-xx in-scope" — e toda a
verificação é delegada à Fase 4 de cada skill: prosa interpretada pelo mesmo LLM que acabou de
escrever o artefato. O resultado previsível aconteceu: "React Flow" está na PRD real
(`docs/PRD.md:220`) e nenhum gate apontou. Um `grep` de 20 linhas com a denylist do próprio
`#fronteira` teria pego. A ironia é dura: o repositório *tem* shell scripts e CI — mas só para
proteger os assets do harness, não para executar as regras de qualidade que são a razão de existir
do harness. Auto-revisão por LLM sem verificação mecânica é conhecidamente fraca; aqui ela é o único
mecanismo.

**H2 — Não-determinismo sem rede de testes.** Mesma entrada, execuções diferentes, vereditos
diferentes — é a natureza de instruções em markdown puro. Não existe suíte de avaliação do harness:
nenhuma fixture de PRD com vazamento conhecido para conferir se a Fase 4 do `write` acusa, nenhum
teste de que `decompose` reprova uma fatia horizontal. Editar `quality-rules.md` (o ponto único de
afinação, `como-usar.md:303-311`) não tem como ser validado além de rodar na mão e olhar. Para um
projeto que se define como harness, a ausência de harness de teste *de si mesmo* é uma lacuna de
identidade.

**H3 — A cadeia de auto-delegação é o elo mais quebradiço.** `/zion-prd-spike` encadeia, "no mesmo
turno", deep-research → `zion-adr-new`, por decisão; `/zion-prd-write` delega o preenchimento de 12
seções a `superpowers:brainstorming` e deve *depois* executar a Fase 4. Brainstorming é uma skill
longa e socrática; a probabilidade de o modelo perder o contrato das fases após um subfluxo de dezenas
de turnos é material, e não há mecanismo de retomada ("ao final do brainstorming, retorne à Fase 4")
além da esperança. Os sintomas no projeto real são compatíveis com Fase 4 pulada ou executada
superficialmente (vazamento não apontado; ADRs aceitos sem spike de código sem o aviso previsto).

**H4 — Dependência dura de um plugin de terceiro para 3 dos 4 estágios criativos.**
`superpowers:brainstorming` é o executor de discovery, write e decompose (`README.md:44-51`). O
preflight cobre *ausência*, mas não *mudança de comportamento*: o contrato entre o harness e o
brainstorming é implícito (espera-se que ele aceite um enquadramento fixo e grave um arquivo), sem
pin de versão nem teste de contrato. Uma atualização do superpowers pode degradar silenciosamente os
três estágios centrais do harness.

**H5 — A skill de spike contradiz o guia que a origina.** A Fase 2/3 de `/zion-prd-spike` instrui:
levantar trade-offs via deep-research e registrar o ADR — *nenhuma menção a escrever ou rodar código
descartável*. A Fase 4 então cobra que "o ADR referencia um spike real" — um critério que o próprio
comando não produz. O harness institucionalizou a versão diluída do estágio 2 (pesquisa no lugar de
spike) e ainda mantém o texto de cobrança, gerando o teatro observado nos ADRs reais ("Spike/evidência
(deep-research…)"). Ou a skill passa a estruturar spikes de código, ou o guia rebaixa a promessa;
manter os dois é incoerência embarcada.

**H6 — A tabela de rastreabilidade não tem comando.** O gap F2 do processo é também gap de
ferramenta: existe skill para injetar a tabela (`decompose`, Fase 4) e nenhuma para reconciliá-la com
`specs/` depois. É o único artefato do método que exige manutenção contínua e o único sem skill. (De
quebra, a instrução "injete a tabela: copie… para a seção 12" não trata reexecução — um segundo
`decompose` pode duplicar a tabela; a idempotência que o `write` tem, o `decompose` não tem.)

**H7 — Drift de nomenclatura dentro dos próprios documentos.** `como-usar.md:2` fala em "7 comandos
`/prd-*`" (são 8 skills, e os comandos são `/zion-prd-*`); `como-usar.md:24` e `quality-rules.md:3`
ainda referem "comandos `prd-*`" — resíduo do rename para o prefixo `zion` (plano
`docs/superpowers/plans/2026-07-12-zion-prefixo-skills.md`). Menor, mas sintomático: consistência
mantida por prosa deriva até dentro do repositório que inventou scripts anti-drift para outra coisa.

**H8 — O harness não fecha o próprio loop de aprendizado.** Não há telemetria nem um comando de
auditoria (`/zion-prd-audit`) que rode os critérios de conclusão sobre os artefatos de um projeto a
qualquer momento. A Fase 4 só existe no instante em que o comando roda; no dia seguinte, ninguém
vigia. Como o harness aconselha e esquece, os desvios se acumulam invisíveis — a tabela morta ficou
4 dias e 3 features sem que nada a acusasse.

---

## 3. Métricas de sucesso no zion-mermaid-editor-app

Todas as métricas abaixo foram derivadas diretamente do repositório
(`/home/tuyoshi/projects/personal/zion-mermaid-editor-app`) em 2026-07-17: `git log` completo (15
commits, 2026-07-13 → 2026-07-17), `docs/`, `specs/`, `tests/`, `src/`. Nenhum valor veio de resumo
de terceiros.

| # | Métrica | Valor apurado | O que indica | Limite de validade |
|---|---------|--------------|--------------|--------------------|
| a1 | Artefatos do processo presentes | discovery ✓, 4 ADRs ✓, PRD ✓, constitution ✓ (8 princípios), specs 001–004 ✓ | Aderência formal completa aos 6 estágios | n=1; autor do harness = operador (viés de adesão máxima) |
| a2 | Cadência spec-antes-do-código | 3/3 features: commit `docs:` precede o `feat:` (001: 13h25→14h40; 002: 23h23→00h06; 003: 23h56→08h07) | A disciplina central do método foi respeitada em 100% dos casos | Granularidade grossa: 1 commit `feat:` por feature (36–44 tasks cada) impede verificar cadência *dentro* da feature |
| a3 | Estágios 1–3 no git | discovery + 4 ADRs + PRD entraram num único commit (`d4dbb9e`) | Os estágios zion rodaram numa única sessão; a separação por estágio não é auditável no histórico | Impossível medir esforço por estágio a partir do git |
| a4 | Higiene de histórico | commit `97ece23` com mensagem "test" (apaga a constitution intermediária); branches 001–004 nunca mergeadas em master | Execução solo informal | Falha do operador, não do método |
| b1 | Tabela de rastreabilidade | **17/17 linhas "☐ pendente"**, coluna Feature/Spec inteira "*(pendente)*"; PRD tocada em exatamente 1 commit em toda a história | A promessa "tabela viva" (guia:264) falhou por completo desde o dia 1 | Método (sem dono/mecânica — F2/H6) **e** operador (não atualizou) |
| b2 | Cadeia RF→spec nos artefatos | spec 001: **zero** menções a RF-xx (só FR-001…008 internos do Spec Kit); specs 002–004 citam RF-xx | Rastreabilidade forward existe só a partir da 2ª feature e nunca via tabela | Colisão RF-xx×FR-xxx não prevista pelo método (F5) |
| c1 | Backlog: planejado vs entregue | 17 fatias (S0–S16), 5 releases (R0–R4); **3 implementadas** (S0,S1,S2 ≈ 18%), 1 só spec (S3); release R0 completa, R1 incompleta | ~4 dias de projeto: ritmo de ~0,75 fatia/dia com toda a cerimônia | Projeto de 4 dias; nada se pode afirmar sobre sustentabilidade do ritmo |
| c2 | NFR de cobertura (NFR-03: 5 tipos) | **1/5** tipos de diagrama (só Flowchart) | Meta de cobertura distante; consistente com fatiamento (tipos são fatias tardias) | Não é atraso — é sequenciamento; mas mostra que "% do backlog" ainda é baixo |
| d1 | Razão teste:fonte | **2.416 : 1.868 LOC (1,29:1)**; 136 casos (68 unit, 43 e2e, 25 contract/perf/roundtrip) | Cobertura de teste alta para projeto pessoal de 4 dias | LOC não mede qualidade de asserção |
| d2 | Constitution → testes reais | Princípios I (perf), II/IV (roundtrip), V–VII + ADR-004 têm testes dedicados (`tests/perf/preview-latency`, `tests/roundtrip/*`, `tests/contract/no-coordinates`, `acl-isolation`, `no-image-export`, `no-nextjs`…) | O melhor resultado do método: princípios decidíveis viraram gates executáveis de verdade | Roundtrip cobre só Flowchart (único tipo implementado) |
| d3 | CI | **Ausente** (sem `.github/` no projeto) | A constitution promete "regressão bloqueia o merge" — sem CI, os gates só rodam se alguém lembrar | Operador; mas o checklist final do método também não exige CI (F3) |
| e1 | Cerimônia antes do 1º código | **7 de 15 commits** (47%) e **~20h40 de relógio** entre init e primeiro `feat:` | Custo de entrada alto para projeto solo | Relógio ≠ esforço líquido; parte é Spec Kit, não zion |
| e2 | Markdown de processo vs código | Artefatos zion 959 linhas + spikes 633 + artefatos Spec Kit 5.427 = **7.019 linhas de processo** vs **4.284 linhas de código** (src+testes) — razão 1,64:1; só specs:src = 2,9:1 | Cada fatia implementada custou ~1.400 linhas de spec para ~620 de src | Maior parte do volume é do Spec Kit (o guia herda esse custo ao fazer a ponte); markdown gerado por LLM custa pouco esforço humano — o custo real é revisão |

**Separando falha do método × falha da execução/operador:**

- **Do método (aconteceriam com qualquer operador):** tabela sem mecânica de atualização (b1);
  RF×FR sem mapeamento (b2); spike diluído em pesquisa pela própria skill (a1/§1-F1); ausência de
  exigência de CI/enforcement no checklist final (d3, parcial).
- **Da execução/operador:** não atualizar a tabela manualmente (b1, em conjunto); commit "test" e
  branches não mergeadas (a4); não montar CI num projeto cuja constitution o pressupõe (d3);
  vazamento "React Flow" não corrigido (embora a não-detecção seja falha do harness, H1).
- **Indistinguíveis com n=1:** se a cadência spec-antes-do-código (a2) se sustenta com outro
  operador; se o custo de cerimônia (e1/e2) compra qualidade (d1/d2) ou apenas coexiste com ela — o
  operador é experiente e enviesado a favor do método; o estudo METR (§4.5) mostra que
  autoavaliação de produtividade com IA erra por ~40 pontos percentuais, então a percepção do autor
  não é evidência.

---

## 4. Comparação com as práticas da indústria

Claims dos temas 1–3 passaram por verificação adversarial (3 votos por claim, fontes primárias
checadas ao vivo); os temas 4–5 foram verificados por consulta direta às fontes primárias. Links
completos na seção [Fontes](#6-fontes).

### 4.1 Spec-driven development e o GitHub Spec Kit (o alvo da ponte)

**Indústria:** o Spec Kit (GitHub, set/2025) canoniza `constitution → specify → plan → tasks →
implement` com comandos de qualidade (`clarify`, `analyze`, `checklist`) e a filosofia de que "specs
become executable... the code becomes the compiled specification", com a spec deliberadamente sem
stack. Os checkpoints humanos são **explícitos, porém advisórios** ("The process builds in explicit
checkpoints for you to critique what's been generated"). Crucialmente, o próprio mantenedor o
enquadra como **experimento, não produto** ("it's an experiment designed to test how well the
methodologies behind SDD actually work") e lista limitações cândidas: specs não fazem one-shot; o
maior problema prático é **subespecificação**; e modelos deixam **detalhe de implementação vazar
para a spec funcional**.

**Zion:** converge fortemente — a fronteira sem-stack do zion é a mesma tese, e as pontes que
"blindam a fronteira em prosa" atacam o vazamento que o mantenedor admite. O zion está **à frente**
em um ponto: preenche o vazio *a montante* do Spec Kit (de onde vem uma boa spec? — descoberta, ADRs,
decomposição), que o Spec Kit não cobre. **Diverge/atrás** em dois: (i) herda os gates advisórios sem
adicionar o que falta a eles (verificação mecânica ou ritual de revisão); (ii) apoia todo o edifício
numa metodologia que se declara experimental e pré-1.0 em rápida mutação (o README já ganhou
`/speckit.converge` desde os primeiros claims desta pesquisa) — o guia zion referencia comandos
específicos do ciclo e envelhecerá junto. **Nenhuma evidência empírica de eficácia do SDD sobreviveu
à verificação** — o campo inteiro opera sobre racionalidade declarada; o zion também.

### 4.2 PRDs enxutos e Amazon Working Backwards / PR-FAQ

**Indústria:** o PR/FAQ substituiu documentos longos por press-release de 6 componentes + FAQ, com a
recomendação explícita de que **"o primeiro rascunho deve levar poucas horas, não dias"** — o
processo é "designed to be lightweight". O rigor vem de outro lugar: **gates de revisão humana
institucionalizados** (leitura silenciosa de 15–20 min, ~40 min de discussão, ciclos escalonados até
go/no-go). Na mesma linha, a SVPG (Cagan) argumenta há anos contra documentos de requisitos pesados
em favor de discovery contínua.

**Zion:** converge no espírito (PRD "enxuta", elaboração progressiva, detalhe fino nas specs) e o
esqueleto de 12 seções com "o que NÃO entra" por seção é um bom guarda-corpo. Diverge em dois pontos:
(i) 6–12 páginas + 12 seções obrigatórias ainda é pesado contra o benchmark "horas, não dias" — e não
há variante mínima (o MADR, ver 4.3, oferece variante mínima do próprio template; o zion não); (ii) a
indústria põe o rigor na **revisão social** do documento; o zion não tem nenhum equivalente — o gate
é o próprio agente que escreveu (F3/H1). Para uso solo isso talvez seja inevitável, mas então a
verificação mecânica vira a única revisão possível — e não existe.

### 4.3 ADRs (Nygard/MADR) e spikes antes da decisão

**Indústria:** consenso raro e forte. Formato Nygard (2011): 5 seções, 1–2 páginas, numeração
sequencial, versionado no repo — motivado por "o novato só pode aceitar cegamente ou reverter
cegamente" decisões não documentadas. ThoughtWorks Radar: anel **Adopt** (sua recomendação máxima).
MADR acrescenta alternativas consideradas explícitas ("Considered Options") e tem como meta de design
minimizar fricção, com **variante mínima** (4.0, 2024) equivalente ao Nygard.

**Zion:** converge quase por inteiro — `zion-adr-new` gera Contexto/Decisão/Consequências/Status
numerado em `docs/adr/`, e os ADRs reais registram opções descartadas (na prática, mais próximos do
MADR que do Nygard puro). O elo **spike→ADR como pré-requisito é síntese própria do zion**: a
pesquisa não encontrou fonte canônica que prescreva spike como condição de ADR (spikes existem como
prática XP independente). Não é demérito — mas o método exige mais do que o cânone e entrega menos do
que exige (F1/H5): a combinação "obrigatório na retórica, inexistente no mecanismo" é o pior dos dois
mundos. Ou vira mecanismo, ou vira recomendação honesta.

### 4.4 Decomposição vertical: INVEST, SPIDR, walking skeleton

**Indústria:** INVEST é de Bill Wake (2003) — seis critérios de qualidade de história; SPIDR é de
Mike Cohn — cinco técnicas para **quebrar** histórias grandes (Spike, Paths, Interfaces, Data,
Rules), com a tese de que "quase toda história pode ser dividida com uma das cinco". Walking skeleton
é de Cockburn (Crystal Clear): "a tiny implementation of the system that performs a small end-to-end
function", ligando os principais componentes arquiteturais. Ponto de debate relevante: Gojko Adzic
("put it on crutches", 2014) critica skeletons que demoram a dar valor de verdade e propõe encolher
ainda mais o primeiro corte.

**Zion:** uso fiel e corretamente posicionado (INVEST valida, SPIDR quebra, skeleton é a fatia zero
— `quality-rules.md:59-70`). O teste "dá uma demo ponta-a-ponta?" é uma destilação melhor que o
acrônimo. Uma nota: o zion usa o "S" de SPIDR (Spike) num sentido e tem "spike" como estágio 2 em
outro — dois conceitos com o mesmo nome no mesmo método; custo cognitivo pequeno mas real. No projeto
real o S0 entregou exatamente um walking skeleton canônico (pipeline inteiro, 1 tipo de diagrama) —
executado como manda o figurino.

### 4.5 Harnesses de codificação agêntica: spec-first × execução autônoma, gates humanos

**Indústria:** o campo converge para spec-first **com humano no loop de planejamento**: o Kiro (AWS)
gera `requirements.md`/`design.md`/`tasks.md` com **approval gates** entre fases (e um modo "Quick
Plan" sem gates para o caso simples); o BMAD-method estrutura agentes de PM/arquiteto/dev com
artefatos de planejamento revisados pelo humano antes da implementação; o ccpm leva o mesmo espírito
para GitHub Issues com agentes paralelos e aprovação humana antes de sincronizar ("cada linha de
código deve rastrear de volta a uma especificação"). Nenhum dos harnesses relevantes advoga autonomia
end-to-end sem checkpoint. Sobre eficácia, a evidência empírica disponível recomenda humildade: o RCT
da METR (2025) com 16 devs experientes em repositórios reais mediu **19% de *lentidão*** com
ferramentas de IA — enquanto os próprios devs estimavam ter sido 20% mais rápidos.

**Zion:** a decisão de parar nas pontes o coloca no lado *mais conservador* do espectro — menos
autônomo que Kiro/ccpm (que executam após aprovação) e nisso coerente com a evidência METR. Está
**à frente** da média em rastreabilidade *de decisão* (nenhum dos citados injeta ADRs como restrição
no plan). Está **atrás** em enforcement: Kiro tem gates de aprovação de verdade (o fluxo não avança
sem o humano aprovar o artefato); os gates do zion nem bloqueiam nem registram que foram vistos. E
compartilha com todo o campo a mesma lacuna: **zero evidência de eficácia** além de relatos — com o
agravante de que no zion o único caso (n=1) é do próprio autor.

---

## 5. Síntese: o que preservar e recomendações priorizadas

### 5.1 O que está bem e deve ser preservado

1. **A fronteira o-quê×como como invariante organizador** — validada pelo alinhamento com o Spec Kit
   e por atacar a limitação que o próprio mantenedor admite (§4.1).
2. **Parar nas pontes** — human-in-the-loop no ponto de maior alavancagem; não regredir para
   autonomia end-to-end (§4.5, METR).
3. **A cadeia ADR → restrição → constitution → "honrar, não re-decidir"** — a contribuição mais
   original do método; no projeto real produziu uma constitution exemplar com princípios decidíveis
   cobertos por testes de contrato (métrica d2).
4. **Walking skeleton como R0 + INVEST/SPIDR** — aplicação fiel do cânone que funcionou (§4.4).
5. **assets→references + sync + hook + CI** — único enforcement mecânico do repo; é o modelo a
   *estender*, não a exceção a manter (§2.1).
6. **Idempotência do write, preflights graciosos, escopo negativo no discovery** — qualidade de
   scaffold acima da média.

### 5.2 Recomendações priorizadas

Ordenadas por (severidade do problema × impacto da correção) ÷ esforço.

| # | Recomendação | Problema (evidência) | Por que importa | Esforço |
|---|--------------|----------------------|-----------------|---------|
| R1 | **Verificação mecânica das regras decidíveis** — um `scripts/check-prd.sh` (denylist de stack na PRD/specify-prompt, NFR sem número, RF fora de épico) que as Fases 4 executam em vez de "conferir em prosa" | "React Flow" na PRD real passou pelo gate (`PRD.md:220`; H1) | As regras já são decidíveis por escrito (`quality-rules.md`); só falta executá-las. O repo já tem o padrão (check-assets.sh). Elimina o modo de falha nº 1 observado | **Baixo** (1 script + 1 linha por skill) |
| R2 | **Rastreabilidade com mecânica, não com promessa** — comando `/zion-prd-trace` que reconcilia a tabela com `specs/*/spec.md` (ou a *gera* de lá), rodável a qualquer momento; ou remoção honesta da promessa "tabela viva" | 17/17 linhas "pendente" com 3 fatias implementadas; PRD com 1 commit na vida (b1; F2/H6) | Rastreabilidade é um dos 6 estágios do método e hoje é o que mais visivelmente não funciona; artefato manual sem dono morre sempre | **Médio** |
| R3 | **Resolver a contradição do spike** — ou `/zion-prd-spike` passa a estruturar spike de código (template `docs/adr/spikes/<slug>/` + critério de evidência mínima no ADR), ou o guia rebaixa "código descartável, não opinião" para "evidência proporcional ao risco (código quando o risco é de execução; pesquisa quando é de conhecimento)" | Skill nunca pede código; Fase 4 cobra "spike real" que o comando não produz; 3 de 4 ADRs reais são pesquisa rotulada de spike (F1/H5) | Coerência interna: prometer rigor sem mecanismo produz teatro de conformidade — pior que a promessa menor cumprida. O elo spike→ADR é síntese própria sem respaldo canônico (§4.3): dimensioná-lo é legítimo | **Médio** |
| R4 | **Mapear RF↔FR na ponte specify** — o prompt montado deve pedir que o `spec.md` liste os `RF-xx` cobertos; `check-prd.sh`/`trace` verificam a presença | spec 001 não cita nenhum RF; cadeia depende só da tabela morta (b2; F5) | Sem esse elo, a rastreabilidade RF↔spec não sobrevive ao handoff — e é a razão de ser do estágio 6 | **Baixo** |
| R5 | **Exigir enforcement no "pronto para codar"** — checklist final passa a exigir CI mínimo que rode os testes que a constitution promete como bloqueantes | Constitution real diz "bloqueia o merge" sem CI nenhum no projeto (d3) | Princípio decidível sem executor é aspiração; o método já induz os testes certos (d2) — falta só exigir o executor | **Baixo** |
| R6 | **Modo leve + critério de "quando não usar"** — seção no guia (produto trivial, protótipo, feature pequena → pular estágios X/Y) e/ou variante mínima do esqueleto de PRD | 14 etapas por fatia; 1,64 linha de processo por linha de código; benchmark da indústria é "horas, não dias" (e1/e2; F4; §4.2) | Right-sizing é o que separa método de cerimônia; MADR e Kiro oferecem variante mínima — o zion não | **Baixo** |
| R7 | **Fixtures de avaliação do harness** — PRDs sintéticas com vazamentos/NFRs sem número/fatias horizontais conhecidos + roteiro que roda as skills e confere os vereditos | Nenhum teste do próprio harness; editar `quality-rules.md` é mexer às cegas (H2) | Sem isso, toda evolução do harness é regressão em potencial; com R1, metade das fixtures vira teste de script (barato) | **Médio** |
| R8 | **Endereçar o dia 2** — o que fazer quando requisito muda pós-release: PRD versionada, ADR "Substituído por", re-decomposição parcial | Processo é greenfield-only (F7); template de ADR prevê supersessão que nenhum estágio usa | O custo dos artefatos só se paga se eles viverem mais que a release 1 | **Médio** |
| R9 | **Contrato explícito com o superpowers** — documentar a interface esperada de `brainstorming` (aceita enquadramento, grava arquivo) e testar no preflight; avaliar pin de versão | Dependência dura sem contrato em 3 estágios (H4) | Falha silenciosa em terceiro é o risco de manutenção mais provável do harness | **Baixo** |

O padrão que atravessa R1–R5: **mover invariantes de prosa para máquina, e promessas sem mecanismo
para promessas menores com mecanismo.** O harness já provou que sabe fazer isso — fez exatamente isso
pelos próprios assets.

---

## 6. Fontes

**Spec Kit / spec-driven development**
- GitHub Spec Kit (repositório oficial): <https://github.com/github/spec-kit>
- GitHub Blog — "Spec-driven development with AI: Get started with a new open source toolkit" (Den Delimarsky, 2025-09-02): <https://github.blog/ai-and-ml/generative-ai/spec-driven-development-with-ai-get-started-with-a-new-open-source-toolkit/>
- Den Delimarsky — "GitHub Spec Kit" (limitações e enquadramento experimental, 2025): <https://den.dev/blog/github-spec-kit/>

**PRD enxuta / Working Backwards**
- Working Backwards (Bryar & Carr) — "The PR/FAQ Process": <https://workingbackwards.com/concepts/working-backwards-pr-faq-process/>
- SVPG (Marty Cagan) — "Discovery vs Documentation": <https://www.svpg.com/discovery-vs-documentation/> · "Revisiting the Product Spec": <https://www.svpg.com/revisiting-the-product-spec/>

**ADRs**
- Michael Nygard — "Documenting Architecture Decisions" (2011): <https://cognitect.com/blog/2011/11/15/documenting-architecture-decisions>
- ThoughtWorks Technology Radar — "Lightweight Architecture Decision Records" (Adopt): <https://www.thoughtworks.com/en-us/radar/techniques/lightweight-architecture-decision-records>
- MADR (site oficial, v4.0): <https://adr.github.io/madr/>
- Olaf Zimmermann — "The MADR Template Primer" (2022): <https://ozimmer.ch/practices/2022/11/22/MADRTemplatePrimer.html>

**Decomposição vertical**
- Bill Wake — "INVEST in Good Stories, and SMART Tasks" (2003): <https://xp123.com/invest-in-good-stories-and-smart-tasks/>
- Mike Cohn — "Five Simple but Powerful Ways to Split User Stories" (SPIDR): <https://www.mountaingoatsoftware.com/blog/five-simple-but-powerful-ways-to-split-user-stories>
- Gojko Adzic — "Forget the walking skeleton – put it on crutches" (2014; contém a definição de Cockburn em Crystal Clear): <https://gojko.net/2014/06/09/forget-the-walking-skeleton-put-it-on-crutches/>

**Harnesses agênticos e evidência de eficácia**
- AWS Kiro — Docs de Specs (approval gates, três artefatos): <https://kiro.dev/docs/specs/>
- BMAD-METHOD (repositório oficial): <https://github.com/bmad-code-org/BMAD-METHOD>
- ccpm (repositório oficial): <https://github.com/automazeio/ccpm>
- METR — "Measuring the Impact of Early-2025 AI on Experienced Open-Source Developer Productivity" (RCT, 19% de lentidão vs 20% de aceleração percebida): <https://metr.org/blog/2025-07-10-early-2025-ai-experienced-os-dev-study/>

---

## 7. Apêndice: método de apuração e limites de validade

**Como as evidências foram levantadas.** (1) Leitura integral do zion-build-prd: os dois guias, as 8
`SKILL.md`, `quality-rules.md`, templates, os 4 shell scripts, o pre-commit hook e o workflow de CI.
(2) Mineração do zion-mermaid-editor-app: `git log` completo com timestamps, diff do commit "test",
histórico por arquivo (`docs/PRD.md` etc.), contagem de LOC (`wc -l`) e de casos de teste (`grep` de
`it(`/`test(`), inspeção de `specs/`, `docs/adr/` (incl. `spikes/`), `.specify/memory/constitution.md`
e `tests/` por categoria. (3) Parte 4: workflow de deep-research com 106 agentes — 24 fontes
buscadas, 114 claims extraídos, 25 verificados adversarialmente por 3 votos cada (24 confirmados,
1 refutado) — complementado por verificação direta das fontes primárias dos temas em que nenhum claim
sobreviveu à rodada (INVEST, SPIDR, walking skeleton, Kiro, BMAD, ccpm, METR). (4) Antes de registrar
cada afirmação forte sobre os repositórios, tentou-se refutá-la (ex.: confirmar que a PRD tem 1 único
commit antes de afirmar "tabela morta desde o dia 1"; confirmar que o commit "test" apagou uma
constitution intermediária, e não a ratificada).

**Limites que o leitor deve carregar consigo.**
- **n=1, mesmo autor, mesmo operador:** o projeto avaliado é do autor do harness, que também escreveu
  os exemplos do `como-usar.md` a partir dele — circularidade total entre método, ferramenta,
  documentação e validação. Métricas de aderência medem o comportamento do autor, não a
  transferibilidade do método.
- **4 dias de projeto:** throughput, sustentabilidade do ritmo e valor dos artefatos no médio prazo
  são inobserváveis.
- **Esforço não mensurável pelo git:** commits agregados (estágios 1–3 num commit; features inteiras
  num `feat:`) impedem medir custo real por etapa; "20h40 até o primeiro código" é relógio de parede,
  não esforço.
- **Sem grupo de controle:** não há como saber se o mesmo projeto, sem o método, teria mais ou menos
  qualidade/velocidade. A única evidência experimental citável do campo (METR) aponta que a percepção
  do próprio desenvolvedor superestima o benefício em ~40 pontos percentuais — recomendando desconto
  ativo sobre qualquer impressão subjetiva de eficácia, inclusive a deste autor e a deste documento.
- **Campo sem evidência empírica:** nenhum claim de eficácia de spec-driven development sobreviveu à
  verificação adversarial; Spec Kit se declara experimento. O zion aposta numa hipótese razoável e
  não validada — e este documento também não a valida.
