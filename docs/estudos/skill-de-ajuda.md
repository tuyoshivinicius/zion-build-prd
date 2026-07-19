# Estudo — skill de ajuda do próprio harness para dúvidas de iniciante

## Contexto

O usuário iniciante do Zion Build PRD tira dúvidas hoje colando à mão um prompt one-shot que
assume o papel de heavy user do harness: ancora a resposta na jornada de estágios, cita o artefato
canônico, fecha com próximo passo e alerta para uma armadilha comum. O candidato é promover essa
prática a uma skill do próprio harness, para melhorar a experiência e a aderência de quem está
começando.

O que restringe o candidato, com fonte:

- O harness não tem runtime próprio — toda lógica é prosa de `SKILL.md` mais verificação em script
  (`architecture.md §1`); uma skill de ajuda seria mais uma `SKILL.md`, com prefixo `zion-`
  obrigatório (`ADR-003`).
- Cada skill é autocontida e carrega em `references/` o que consome, derivado da fonte única
  (`ADR-001`, `ADR-002`, `prd.md RF-15`).
- Os guias e o canon deste repo **não viajam** ao usuário: só `skills/` é empacotado, e `docs/` é
  natureza Governança/Dev-workflow (`architecture.md §6`). No repositório do usuário, `docs/prd.md`
  é a PRD **do produto dele** — o prompt one-shot atual confunde as duas.
- Exatamente uma dependência externa de skill é tolerada, o executor de brainstorming
  (`prd.md NFR-02`); a ajuda não pode acrescentar outra.
- Todo gate aconselha e nunca bloqueia (`prd.md RN-01`, `ADR-004`), e a fronteira o-quê/como vale
  em todo artefato (`prd.md RN-02`).
- Skill nova exige canonização no mesmo commit: RF na §6 e linha na §12 de `docs/prd.md`
  (`architecture.md §5`).

## Edge cases e incertezas

Marcadas com **[H]** as perguntas que só o humano responde; as demais são decidíveis por evidência
no repo.

**Grounding — de onde a ajuda tira a verdade**

1. No repositório do usuário, `docs/prd.md` é a PRD do produto dele. Se a ajuda "lê a fonte da
   verdade", qual fonte? Carregar uma cópia própria do canon do harness em `references/` cria mais
   um derivado a sincronizar (`ADR-001`) — quanto cabe ali sem inchar o pacote?
2. **[H]** Cópia do canon que viaja envelhece junto com a versão instalada: resposta correta na
   v2.0.0 vira mentira para quem não atualizou. A ajuda deve declarar sua versão na resposta?
3. As `SKILL.md` das outras skills já viajam no mesmo pacote. A ajuda pode lê-las em tempo de
   execução como fonte primária, em vez de carregar cópias? Depende do caminho de instalação, que
   difere entre os dois canais (`ADR-002`) — como a skill descobre onde ela mesma está instalada?
4. **[H]** O prompt atual manda "leia a SKILL.md dela", mas num dos canais as skills ficam num cache
   versionado fora do repositório do usuário. O caminho é descobrível de forma robusta ou é preciso
   um fallback?
5. **[H]** `docs/guias/como-usar.md` e `guia-prd-para-spec-kit.md` são o material didático mais rico
   que existe e não viajam (`architecture.md §6`). Promovê-los a fonte única distribuída muda a
   natureza deles de Governança para Distribuído — vale o custo de manutenção?

**Escopo — que dúvida a ajuda atende e qual ela recusa**

6. **[H]** "Como uso o harness?" e "o que escrevo no meu RF-03?" são dúvidas diferentes. A ajuda
   responde sobre o harness ou também sobre o produto do usuário? Onde fica a linha?
7. A ajuda responde dúvida sobre o Spec Kit, que é ferramenta de terceiro? O harness declara que não
   executa aquele ciclo (`prd.md §4`) — mas explicar não é executar.
8. Se a dúvida é tarefa disfarçada ("me ajuda a escrever a §6"), a ajuda roteia para o comando dono
   ou começa a fazer? `RN-01` diz aconselha, não decide — onde exatamente ela para?
9. **[H]** A ajuda deve ler o estado do projeto do usuário para responder, ou responder só de
   conhecimento genérico? Ler dá resposta muito melhor e é o maior diferencial contra o prompt
   one-shot, mas amplia a superfície e o risco de afirmação errada.

**Qualidade e verificação — o padrão do épico E5**

10. **[H]** Toda skill do harness tem verificador mecânico e auto-teste (`prd.md NFR-04`, `RF-11`,
    `RF-12`). Uma resposta conversacional não grava artefato, logo não há o que verificar. A ajuda
    seria a primeira skill sem check — isso é aceitável?
11. Sem artefato, como se avalia a ajuda? Fixtures de perguntas com resposta esperada na camada de
    julgamento (`ADR-008`)? Quem mantém esse conjunto?
12. **[H]** Afirmação inventada é o risco central e é silenciosa: a ajuda cita uma skill ou seção
    inexistente e o iniciante, que por definição não sabe distinguir, segue. O prompt atual mitiga
    com "diga não sei" — prosa basta, ou é preciso mecanismo (lista fechada de comandos válidos
    carregada como reference)?
13. A ajuda deve citar a fonte de cada afirmação, como a Fase 1 desta skill exige? Isso torna o erro
    auditável pelo próprio usuário sem custo de máquina.

**Fronteira e governança**

14. A `RN-02` vale para a resposta da ajuda? Se o usuário pergunta se pode usar determinada
    tecnologia, a ajuda opina ou roteia para `/zion-prd-spike` e `/zion-adr-new` sem opinar?
15. A ajuda pode reabrir uma decisão de ADR ao explicar? O prompt atual proíbe e roteia para
    supersessão — isso é regra de prosa ou merece marcador?
16. **[H]** Sendo skill, ela é RF novo no épico E1 ou merece épico novo? Ela não é um estágio — não
    tem entrada, saída nem lugar na sequência. Onde mora na §6?

**Descoberta e uso**

17. **[H]** O iniciante sabe que a ajuda existe? Skill só é invocada por descrição casada ou comando
    explícito; se ele não sabe o nome, o problema de descoberta mudou de lugar em vez de sumir.
18. **[H]** O que aciona a ajuda: o comando explícito, ou a descrição casando com perguntas soltas?
    Descrição agressiva sequestra turnos de outras skills; tímida nunca dispara.
19. **[H]** Hoje o usuário cola o prompt e funciona. Qual é a dor medível — o atrito de encontrar e
    colar, ou a qualidade da resposta? Se for só o atrito, a solução mais barata talvez não seja uma
    skill.
20. **[H]** Quantos usuários iniciantes existem hoje? Se a resposta for "um", o ROI de skill nova
    mais canonização mais avaliação muda de figura.

**Custo permanente**

21. Skill nova obriga RF na §6, linha na §12 e, se houver decisão estruturante, ADR e índice
    (`architecture.md §5`). Quanto disso é obrigatório aqui e quanto já está coberto por ADR
    existente?
22. A ajuda precisa saber de si mesma e a lista de comandos que ela cita cresce a cada skill nova.
    Como evitar que ela envelheça? `check-canon.sh` consegue cobrar isso ou é dever de prosa?
23. A ajuda fica inerte no modo interno, como o ramo do `ADR-013`, ou o dev do harness também é
    público dela?

## Alternativas

Todas em nível de o-quê. **Nenhuma exige reverter ADR vigente** — logo nenhuma carrega supersessão
como custo.

### A — Não fazer (manter o prompt one-shot fora do harness)

O usuário continua colando o prompt à mão quando tem dúvida.

- **A persona passa a conseguir:** nada de novo.
- **Prós:** custo zero; nenhuma superfície nova a envelhecer; o prompt já funciona e é editável na
  hora, sem release.
- **Contras:** o prompt não viaja com a instalação, então quem instala pelo canal público não o tem;
  a dúvida do iniciante continua dependendo de ele já saber que o prompt existe; afinação exige
  re-colar a versão nova em todo lugar.
- **ADRs tocados:** nenhum.

### D — Distribuir o prompt como fonte única versionada (sem skill nova)

O prompt vira asset da fonte única, viaja no pacote e é citado no README e no guia. Continua sendo
colado, só que sempre em dia e sempre disponível.

- **A persona passa a conseguir:** achar o prompt junto da instalação, na versão correta, sem caçar
  em conversa antiga.
- **Prós:** custo baixíssimo; nenhuma skill nova, logo nenhum RF novo na §6 e §12; o mecanismo de
  fonte única já existe e cobre drift de graça.
- **Contras:** não resolve a descoberta (questão 17) — quem não sabe que o arquivo existe continua
  sem ajuda; mantém o atrito de copiar e colar, que é provavelmente a dor real (questão 19); o
  prompt não pode se ancorar no estado do projeto.
- **ADRs tocados:** `ADR-001` (fonte nova no mapa), `ADR-002` (autocontenção).

### B — Skill de ajuda de bolso, autocontida e sem ler o projeto

`/zion-prd-ajuda` responde dúvidas sobre o harness: em que estágio a dúvida cai, qual comando
resolve, qual armadilha evitar, com fonte citada. Grounding nas `SKILL.md` das skills irmãs, que já
viajam no mesmo pacote, em vez de cópias novas do canon. Não lê a PRD do produto do usuário.

- **A persona passa a conseguir:** perguntar em linguagem natural, dentro da sessão, sem colar nada
  — e a skill é encontrável pelo próprio mecanismo de descrição, que é o que de fato ataca a
  questão 17.
- **Prós:** grounding sempre em dia e sem derivado novo, já que a fonte são as skills instaladas e
  não uma cópia do canon que envelhece (resolve 1, 2 e 3 de uma vez); zero dependência externa nova,
  honra `NFR-02`; aconselha e roteia sem executar, honra `RN-01` naturalmente; escopo pequeno o
  bastante para caber numa `SKILL.md` sem infraestrutura.
- **Contras:** primeira skill sem artefato gravado, logo sem verificador mecânico — quebra o padrão
  do épico E5 e obriga decisão explícita sobre como avaliá-la (questões 10 e 11); risco de afirmação
  inventada mitigado só por prosa e citação de fonte (12 e 13); exige descrição calibrada, sob pena
  de sequestrar turnos de outras skills (18); e ela mesma envelhece a cada skill nova (22).
- **ADRs tocados:** `ADR-003` (prefixo), `ADR-004` (aconselha). **Decisão estruturante nova a
  registrar:** skill conversacional sem artefato é avaliada só na camada de julgamento (`ADR-008`),
  sem verificador mecânico próprio.

### C — Skill de ajuda situada (lê o estado do projeto do usuário)

Como B, mas antes de responder lê a PRD, os ADRs e o backlog do produto e ancora a resposta em onde
o autor está de fato.

- **A persona passa a conseguir:** resposta sob medida, com diagnóstico do próprio projeto — de
  longe o maior salto de aderência.
- **Prós:** diferencial mais forte contra o prompt atual; aproveita os verificadores existentes para
  dar veredito real em vez de conselho genérico.
- **Contras:** superfície muito maior e mais sujeita a erro, porque passa a afirmar coisas sobre o
  projeto do usuário, onde errar custa caro; pressiona a fronteira (6 e 14) e a linha aconselha/faz
  (8) exatamente onde elas são mais frágeis; sobrepõe-se ao `/zion-prd-trace`, que já é dono do
  diagnóstico por máquina (`prd.md RF-09`); esforço e risco desproporcionais a uma dor ainda não
  medida (19 e 20).
- **ADRs tocados:** os de B, mais decisão nova sobre a ajuda ler o canon do produto, e uma fronteira
  a negociar com `RF-09` para não duplicar dono.

## ROI

| # | Alternativa | Impacto | Esforço (inv.) | Risco (inv.) | ROI |
|---|---|:--:|:--:|:--:|:--:|
| B | Skill de ajuda de bolso | 4 | 4 | 4 | **4.00** |
| D | Prompt distribuído como fonte única | 2 | 5 | 4 | 3.67 |
| A | Não fazer | 1 | 5 | 5 | 3.67 |
| C | Skill de ajuda situada | 5 | 2 | 2 | 3.00 |

**B — 4/4/4.** Impacto 4: resolve as duas dores declaradas (atrito de colar e descoberta) sem
resolver a terceira, que ninguém pediu ainda (diagnóstico do projeto). Esforço 4: uma `SKILL.md`,
mais RF novo na §6 e §12, mais fixtures de julgamento; sem script, sem fonte nova, sem dependência.
Risco 4: a skill só fala — nunca grava nem reverte; o pior caso é uma resposta errada, mitigável por
citação de fonte obrigatória. O contrapeso honesto é a exceção ao padrão do épico E5, que precisa
ser decisão consciente e não descuido.

**D — 2/5/4.** Impacto 2: entrega versionamento e disponibilidade, mas deixa intactos o copiar/colar
e a descoberta — melhora o que já funciona em vez de remover o atrito. Esforço 5: um arquivo no mapa
de fontes, nada mais. Risco 4: baixíssimo, com a ressalva de que material distribuído e pouco usado
apodrece calado.

**A — 1/5/5.** Impacto 1: mantém o estado atual; só não é zero porque o prompt comprovadamente
funciona para quem o tem. Esforço 5 e Risco 5: ambos nulos por construção — é a linha de base contra
a qual as outras se justificam.

**C — 5/2/2.** Impacto 5: única que ataca a aderência no ponto onde o iniciante realmente trava.
Esforço 2: exige negociar fronteira com `/zion-prd-trace`, definir o que é lido e como se cita, e
provavelmente ADR próprio. Risco 2: afirmar coisas erradas sobre o projeto do usuário é o modo de
falha mais caro do harness, e esta alternativa o multiplica antes de haver evidência de demanda.

O empate entre D e A é real e informativo: as duas opções baratas valem quase o mesmo, o que reforça
que a escolha verdadeira é entre fazer direito (B) e não mexer (A).

## Recomendação

**Não vinculante.** A alternativa **B** lidera: entrega o ganho de aderência que motivou o candidato
pelo caminho mais barato que também resolve a descoberta, e faz isso sem criar derivado novo, porque
o grounding vem das `SKILL.md` que já viajam no pacote. Antes de conduzir a decisão, valem duas
verificações que podem mudar o veredito: confirmar que o caminho de instalação é descobrível nos
dois canais (questões 3 e 4) — se não for, B degrada na direção de D — e responder a questão 19, se
a dor real é o atrito ou a qualidade da resposta, já que dor só de atrito reduz B ao valor de D. A
exceção ao padrão do épico E5 (skill sem verificador mecânico) é o único ponto estruturante de B e
deve ser decidida explicitamente, não por omissão. **C** fica registrada como evolução possível
depois que B provar uso, não como ponto de partida.

## Próximo passo sugerido

Se aprovado, rodar `superpowers:brainstorming` com a alternativa escolhida →
`superpowers:writing-plans` → `superpowers:executing-plans`. Decisão estruturante nova vira ADR via
`/zion-adr-new` e reflete no canon (`prd.md`/`architecture.md` no mesmo commit — CLAUDE.md).
