# Estudo — recuperar a clarificação propositiva na delegação criativa ao brainstorming

## Contexto

O harness conduz a autoria da PRD em estágios, guardando a fronteira o-quê/como (`prd.md` §1),
e três estágios criativos — discovery, `write` e `decompose` — delegam a clarificação ao
`superpowers:brainstorming` sob o contrato de capacidades C1–C3 (ADR-007, `prd.md` §8). A análise
`zion-mermaid-editor-app/docs/analise-brainstorming-no-fluxo-zion.md` (2026-07-19) mostra que, no
**modo retomar/revisar**, essa clarificação **degrada**: o Autor (`prd.md` §3) recebe perguntas
**diagnósticas** ("qual dos seus fatos é o verdadeiro?") em vez de **propositivas** ("escolha entre
estes desenhos"), sem recomendação explícita e sem preview que ilustre a escolha. A análise atribui
isso a quatro causas estruturais do harness — o contrato nunca declarou a capacidade "propor
abordagens + recomendação"; o harness pré-mastiga as tensões como perguntas prontas no modo revisar;
a fronteira o-quê/como suprime o preview em bloco; e a `SKILL.md` aninhada do brainstorming não
dirige o turno (0 `TaskCreate` em 7/7 sessões). O candidato deste estudo é **resolver essa
degradação** — a solução imaginada na análise é o trio R1 (declarar C4 no contrato), R2 (parar de
pré-mastigar) e R3 (liberar preview conceitual mantendo proibido o de tela). O estudo relaciona-se
diretamente à visão do harness (`prd.md` §1) e à dor da persona O Autor, que hoje sai da fachada com
clarificação pior do que teria com o brainstorming avulso — exceto no modo do-zero, onde a fachada
entrega clarificação **melhor** que a avulsa (análise §6).

## Edge cases e incertezas

Perguntas que a alternativa escolhida terá de responder. 👤 marca as que **só o dono do harness
pode responder** (julgamento de produto/governança, não derivável do código ou das fontes).

**Sobre declarar C4 (a capacidade "propor abordagens + recomendação"):**

- **E1 — 👤 Quando a recomendação é *certa* e quando a ausência dela é *defeito*?** A Causa 2 da
  análise diz que no modo revisar a ausência de recomendação é **correta** — a pergunta pede revelar
  intenção, não escolher desenho. C4 não pode forçar recomendação onde não há o que recomendar. A
  distinção é regra checável ou julgamento do agente?
- **E2 — 👤 A alavanca real é o marcador no contrato ou o prompt?** Declarar C4 muda o que o *check*
  cobra, não o comportamento do superpowers (o marcador `Propose 2-3 approaches` já existe na
  `SKILL.md` dele — análise, Causa 1). O comportamento muda pelo **prompt** (os `args`). A análise
  diz "R1 é o maior retorno, sem ele o resto regride" — mas sem R2, C4 sozinho não muda nada.
- **E9 — O check de C4 dá confiança falsa?** Ele verifica que o marcador existe *no superpowers
  instalado* — não que o *prompt do harness pede*, nem que a *experiência melhorou*. O verde pode
  conviver com experiência degradada (NFR-04 pede fixture limpa/suja de qualquer modo).

**Sobre parar de pré-mastigar as tensões (R2):**

- **E3 — O problema da `SKILL.md` aninhada (Causa 4) derrota R2?** A checklist do brainstorming não
  dirige o turno sob a fachada (0 `TaskCreate` em 7/7). R2 assume que pedir "investigue pelo seu
  protocolo" faz o brainstorming conduzir — mas a Causa 4 diz que estruturalmente não conduz. A
  solução tem de endereçar a **condução** (ex.: instruir "crie uma tarefa por passo"), senão R2 não
  pega.
- **E4 — Onde fica a linha entre "observação do harness" e "pergunta pré-mastigada"?** Enumerar
  tensões tem valor real (o modo do-zero foi *melhor* que o avulso — análise §6). O defeito é
  entregá-las já como pergunta. Precisa de um exemplo trabalhado / regra que preserve o valor sem
  pré-resolver.
- **E5 — 👤 Que fração do atrito do modo revisar é defeito, e que fração é comportamento correto?**
  A pergunta de `907f042e` ("qual dos seus dois fatos é o dominante?") é irredutivelmente
  diagnóstica. Isso dimensiona o problema — e decide se vale mexer.

**Sobre liberar preview conceitual (R3):**

- **E6 — Onde fica a linha entre preview conceitual (liberado) e preview de tela (proibido)?** A
  supressão é *julgamento*, não denylist (`quality-rules.md#fronteira`: detectar "tela" vazando
  continua julgamento humano). R3 é reescrita de prosa. Sem um teste crítico (tabela passa/vaza),
  o pêndulo volta e mockup de tela entra disfarçado de "conceitual".
- **E7 — 👤 R3 edita a fronteira global ou só o turno de clarificação?** A
  `quality-rules.md#fronteira` é fonte única consumida por muitos estágios (specify, `write`, a PRD,
  a própria skill de estudo). Afrouxar preview para a clarificação pode vazar para o specify/PRD,
  onde arranjo de tela tem de continuar banido.

**Transversais (as incômodas):**

- **E8 — 👤 C4 é ADR novo ou emenda ao ADR-007?** Decisão não se reabre (CLAUDE.md); estender um
  contrato com capacidade nova é ADR novo *complementar* ou edição das Consequências do ADR-007?
  Governança + dever de canonização no mesmo commit.
- **E10 — 👤 Alcance: discovery só, ou os três estágios?** R1/R2 valem para discovery, `write` e
  `decompose` (análise §7). Corrigir só discovery deixa os outros degradados; corrigir os três
  multiplica a superfície e o custo de canon. Walking-skeleton (discovery primeiro) ou tudo de uma
  vez?
- **E11 — 👤 Vale a pena, dado que C3 é a única capacidade consumida com força e ela funciona?** O
  "degradado" concentra-se no modo revisar, que é diagnóstico por natureza. O ganho justifica mexer
  no contrato + fronteira + três skills + canon — ou o fix honesto é menor que o trio?

## Alternativas

Nenhuma reverte ADR vigente — C4 *estende* o ADR-007 (C1–C3 seguem válidos), então não há
supersessão a declarar como custo. Todas em nível de o-quê; o "como" técnico fica para o plano de
implementação.

### Alt A — Não fazer

O Autor continua recebendo, no modo revisar, clarificação diagnóstica sem recomendação nem preview;
a análise vira registro.

- **Prós:** custo zero, risco zero; honra a leitura de que C3 (o diálogo incremental) é a única
  capacidade consumida com força — e ela funciona (E11).
- **Contras:** a perda sentida (o passo de propor abordagens e o de aprovar por seção) persiste;
  `write`/`decompose` seguem degradados; nenhuma das quatro causas é endereçada.
- **ADRs tocados:** nenhum.

### Alt B — Só o prompt (R2+R3, sem tocar o contrato)

O Autor passa a receber perguntas **propositivas quando a tensão admite desenho** (2–3 abordagens +
recomendação) e preview **conceitual** de volta, porque o harness reescreve os `args` que passa ao
brainstorming (tensões como *observações*, não perguntas prontas) e a linha de fronteira (distinguir
preview de escolha × preview de tela). Não mexe no contrato nem no check de contrato.

- **Prós:** ataca a **alavanca real** — o prompt (E2) — sem inflar o acoplamento com o superpowers
  (E9); resolve E1 no próprio prompt (o agente decide diagnóstico×propositivo pela natureza da
  tensão); reversível (é prosa).
- **Contras:** **sem gate, regride** na próxima reescrita — é o risco que R1 existe para conter (E2);
  muda a fronteira global fonte-única, com risco de vazar para specify/PRD se não escopar (E7); só
  pega a Causa 4 (condução) se o prompt incluir a instrução de conduzir passo a passo.
- **ADRs tocados:** nenhum; afina `quality-rules.md#fronteira` (RN-05, fonte única) e os `SKILL.md`
  — reflete no canon como texto de RF, sem ADR novo.

### Alt C — Trio completo da análise (C4 no contrato + prompt + fronteira, com gate no marcador externo)

A solução literal da análise (R1+R2+R3): declara C4 no `superpowers-contract.md`, espelha os
marcadores no `check-superpowers-contract.sh` (fixture limpa/suja, NFR-04), reescreve os prompts dos
três estágios e a fronteira.

- **Prós:** o gate impede regressão (E2); cobre as quatro causas incluindo a condução (E3); alcance
  nos três estágios de uma vez.
- **Contras:** **o gate verifica a coisa errada** — que o marcador existe *no superpowers instalado*,
  não que o *prompt do harness pede* nem que a experiência melhorou (E9); aumenta o acoplamento com
  versões futuras do superpowers (pin `>=5 <7`: se o superpowers 7 renomear o marcador, o check
  quebra); maior superfície de canon (contrato + check + fixtures + fronteira + três `SKILL.md` no
  mesmo commit); depende da governança E8.
- **ADRs tocados:** **ADR-007 estendido** com C4 — decisão de governança (E8): emenda às
  Consequências ou ADR novo *complementar* (não supersede: C1–C3 seguem).

### Alt D — Reframe: classificar o *tipo* da tensão no prompt + gate no prompt do harness

O Autor recebe clarificação certa **por construção**: para cada tensão enumerada, o harness marca se
é **diagnóstica** (revela intenção → pergunta simples) ou **propositiva** (admite desenho → 2–3
abordagens + recomendação + preview conceitual), passa isso como observação ao brainstorming, e um
**check leve verifica que o *prompt gerado* pede essa distinção** (análogo ao `check-prd.sh specify`,
que checa o prompt montado, não a skill externa).

- **Prós:** ataca a **causa-raiz real** — a *natureza* da pergunta —, tornando E1 explícito em vez de
  julgamento cego; o gate verifica **o que de fato controlamos** (o prompt do harness), corrigindo o
  ponto cego do E9; **não** toca o contrato externo, então não aumenta o acoplamento com o
  superpowers; reversível; resolve E4 (a observação carrega o *tipo*, não a pergunta pronta).
- **Contras:** introduz um conceito novo (classificação de tensão) a manter nos três prompts; mais
  sofisticado que "declarar C4"; ainda muda a fronteira (E7) e ainda precisa da instrução de condução
  à parte (Causa 4).
- **ADRs tocados:** **ADR novo** ("classificação diagnóstica×propositiva na delegação criativa") —
  decisão estruturante nova ao lado do ADR-007, sem supersedê-lo.

## ROI

Impacto na persona (5 = resolve a dor central) · Esforço (invertido, 5 = menor esforço) ·
Risco/reversibilidade (invertido, 5 = menor risco, mais reversível). ROI = média. Ordenada por ROI
decrescente.

| Alternativa | Impacto | Esforço | Risco/rev. | ROI |
|---|:---:|:---:|:---:|:---:|
| **D** — Reframe (tipo de tensão + gate no prompt) | 5 | 3 | 4 | **4.0** |
| **B** — Só o prompt (observações + fronteira) | 4 | 4 | 3 | **3.67** |
| **A** — Não fazer | 1 | 5 | 5 | **3.67** |
| **C** — Trio da análise (C4 + gate no marcador externo) | 4 | 2 | 3 | **3.0** |

- **D (4.0)** — Impacto **5**: é a única que ataca a natureza da pergunta (E1) e gateia o que
  controlamos (E9), tornando a correção *durável*. Esforço **3**: conceito novo + check leve nos três
  prompts, menos que C (não mexe no contrato externo nem nas fixtures dele). Risco **4**: não acopla
  mais ao superpowers, gate sob nosso controle, reversível.
- **B (3.67)** — Impacto **4**: devolve perguntas propositivas e preview conceitual — a dor sentida —
  pela alavanca certa. Esforço **4**: reescrever prosa de três prompts + a fronteira, sem
  contrato/check/fixtures. Risco **3**: reversível, mas sem gate regride (E2) e mexe na fronteira
  global (E7).
- **A (3.67)** — empata com B por Esforço **5** e Risco **5** (é o status quo), mas Impacto **1**:
  não resolve nada. Fica **abaixo de B no desempate**: a ROI igual esconde que B move a persona e A
  não.
- **C (3.0)** — Impacto **4** (gate contra regressão, alcance nos três estágios), mas Esforço **2**
  (canon pesado) e Risco **3** (o gate no marcador externo guarda a coisa errada — E9 — e acopla a
  versões futuras). O trio literal da análise fica **abaixo** de D e B: paga o custo de um gate que
  verifica o prompt errado.

## Recomendação

> **Não vinculante** — subsídio para o dono do harness decidir; a escolha e a condução são humanas.

Lean em **D**, possivelmente **sequenciado a partir de B**: rodar B como *walking skeleton* (discovery
primeiro) para validar barato e reversível o fix da dor sentida — perguntas propositivas e preview
conceitual de volta — e então enxertar o classificador de tensão + o gate no prompt do harness (D)
para tornar a correção durável e estendê-la a `write`/`decompose`. O ponto onde este estudo vai
**além da análise** (que recomendava C) é E9: o gate no marcador externo do superpowers verifica que
o marcador *existe na skill instalada*, não que o *prompt do harness pede a distinção* nem que a
experiência melhorou — então convém **rejeitar o gate externo de C** e gatear o prompt do harness (D),
a menos que a governança (E8) decida o contrário. As perguntas 👤 (E1, E2, E5, E7, E8, E10, E11)
continuam abertas e são pré-condição da escolha final.

## Próximo passo sugerido

Se aprovado, rodar `superpowers:brainstorming` com a alternativa escolhida →
`superpowers:writing-plans` → `superpowers:executing-plans`. Decisão estruturante nova vira ADR via
`/zion-adr-new` e reflete no canon (`prd.md`/`architecture.md` no mesmo commit — CLAUDE.md).
