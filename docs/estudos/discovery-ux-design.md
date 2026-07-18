# Estudo — descoberta que clarifica UX/design quando faz sentido

> Estudo pré-discovery (Estágio 0, `/zion-prd-estudo`). **Aconselha, não decide.** Subsídio para o
> Autor escolher a direção e conduzir ele mesmo `/zion-prd-discovery`. Não altera PRD, ADRs,
> architecture, skills ou assets.

## Contexto

O candidato quer que a descoberta do harness (Estágio 1, `RF-01` em `prd.md §6`) ajude o Autor a
**clarificar aspectos de UX e frontend design quando fizer sentido**, para que o produto final não
saia rico em função e pobre de experiência. A dor: o Autor sente que o backlog decomposto
(`RF-05`) não se preocupa com design, e o app resultante fica difícil de usar. O candidato conversa
direto com a visão da PRD — conduzir a autoria "guardando sempre a fronteira o-quê/como"
(`prd.md §1`) — e com a persona **O Autor**, "dev de produto que quer PRDs enxutas sem virar
burocrata de documento" (`prd.md §3`): qualquer clarificação de UX tem de caber sem inchar o
estágio. As restrições que cercam o candidato (todas citadas das fontes): a fronteira o-quê/como
proíbe tela/wireframe/critério de aceite detalhado na PRD e no prompt do specify — isso é "como" e
vive no `plan.md` (`prd.md §5 RN-02`; `assets/quality-rules.md#fronteira`); todo gate **aconselha,
nunca bloqueia** (`RN-01`, `NFR-05`, `ADR-004`); a descoberta é deliberadamente enxuta — visão +
persona + faz/não-faz (`RF-01`); e o repo admite **exatamente 1 dependência externa de skill**, o
executor de brainstorming (`NFR-02`, `ADR-007`), de modo que depender de uma skill de design
externa custa a supersessão do `ADR-007`. Brownfield: nenhuma alternativa abaixo reverte ADR
vigente sem declarar a supersessão como custo próprio.

## Edge cases e incertezas

Perguntas que a solução escolhida terá de responder. 🔴 = só o humano (Autor/dono do produto)
responde; ⚙️ = o design responde.

**Fronteira o-quê/como**
- ⚙️ Como capturar *intenção* de UX sem virar wireframe? Onde fica a linha — "o usuário conclui a
  tarefa-núcleo em ≤N passos" passa como o-quê, mas descrever o arranjo da tela vaza para o "como".
- ⚙️ UX vira **RF** (a persona consegue X), **NFR** (mensurável: passos, taxa de erro percebida) ou
  **RN**? A denylist barra termos de *stack*, não a palavra "wireframe": o que impede o vazamento
  visual que não é termo de stack?

**Onde no pipeline**
- ⚙️ A dor está no **backlog** (decomposição), mas o candidato mira o **discovery**. O sinal de UX
  capturado no discovery precisa **sobreviver** discovery → PRD → decomposição → specify para chegar
  ao backlog. Qual é o *carregador* (persona enriquecida? NFR? story map?) — e consertar só o
  discovery basta?
- ⚙️ O discovery já nomeia persona e faz/não-faz. UX é **artefato novo** ou **aprofundar a persona**
  (contexto de uso, expectativas, momento)?

**Escopo e "quando fizer sentido"**
- 🔴 O que "UX" abrange: **só apps visuais/frontend**, ou usabilidade ampla (ergonomia de CLI,
  mensagens de erro, APIs)? *Confirmado pelo Autor: usabilidade ampla, foco agudo em frontend;
  não-visual só quando fizer sentido.*
- 🔴 **Acessibilidade** entra (é UX com NFR mensurável — WCAG) ou fica de fora nesta rodada?
  *Confirmado pelo Autor: ângulo opcional de NFR, não forçado.*
- 🔴 Qual é o **gatilho** de "faz sentido"? Pergunta barata que pula UX para produto sem UI, ou
  sempre oferecer?

**O que impede virar burocracia**
- 🔴 Quanto de UX é **suficiente** antes de virar peso morto para a persona que quer PRD enxuta
  (`prd.md §3`)? Como medir que "funcionou" antes do app pronto (indicador antecipado)?
- ⚙️ Como isso **aconselha e não bloqueia** (`RN-01`)? Risco de overcorrection: forçar pergunta de
  UX em todo discovery vira ruído ignorável.

**Dependência**
- 🔴 Vale pagar a **supersessão do `ADR-007`/`NFR-02`** por uma skill de design, ou o brainstorming
  — a dep já existente — cobre a exploração de UX sem dep nova? *Assumido: não pagar — confirmar.*

**Verificação**
- ⚙️ Existe regra **decidível por máquina** para "UX considerada" (padrão E5), ou UX é
  inerentemente prosa/julgamento humano — logo, sem `check-*.sh` novo?

## Alternativas

Todas em nível de o-quê (sem stack), sempre incluindo **não fazer**.

**A0 — Não fazer.** A descoberta segue enxuta; UX permanece implícito.
- Prós: custo zero, fronteira intocada, `NFR-02` intacto, nenhum risco de burocracia.
- Contras: a dor persiste — o backlog continua gerando produtos ricos em função e pobres de
  experiência; o harness fica silencioso justo na lacuna que o Autor sente.
- ADRs tocados: nenhum.

**A1 — Aprofundar a persona no discovery (carregador leve, em prosa).** Um bloco *opcional* no
Estágio 1 enriquece a persona já nomeada com **contexto de uso, expectativas e a qualidade de
experiência que o produto precisa transmitir**, quando fizer sentido (pula produto sem interface).
Sem artefato novo, sem dependência nova; o sinal viaja na própria persona.
- O que a persona passa a conseguir: sair do discovery já tendo articulado, em prosa, o que "bom de
  usar" significa para o *seu* usuário — sem desenhar tela.
- Prós: barato; sem dependência externa (honra `NFR-02`/`ADR-007`); fronteira fácil de guardar em
  prosa ("o usuário percebe X", não "tela Y"); retomável (`RF-01`).
- Contras: sinal fraco — pode evaporar na decomposição se nada o rastreie; "quando fizer sentido"
  depende do julgamento, sem gatilho duro; não garante reflexo no backlog.
- ADRs tocados: nenhum novo (estende `RF-01` sob `ADR-004`).

**A2 — NFR de experiência + elo até o backlog (carregador forte).** Sobre a A1, tornar a qualidade
de experiência um **NFR mensurável** (ex.: tarefa-núcleo concluída em ≤N passos; taxa de erro
percebida abaixo de um limiar) que a PRD carrega na §7 e que a decomposição obriga a distribuir —
cada spec vertical demonstra também a experiência, não só a função.
- O que a persona passa a conseguir: ver o UX **sobreviver** até o backlog, cobrado no INVEST e na
  demo de cada spec.
- Prós: ataca a dor na raiz (o backlog); reaproveita mecânica que já existe (NFR com número); a
  fronteira se mantém (NFR é o-quê mensurável, não tela).
- Contras: mais esforço (mexe em descoberta, escrita e decomposição); risco de virar burocracia se
  todo produto for forçado a ter NFR de experiência; exige disciplina para não vazar para tela;
  pode pedir um verificador novo (padrão E5) — custo de verificação.
- ADRs tocados: honra `ADR-004` (o verificador *aconselharia* "spec sem âncora de experiência", sem
  reabrir decisão); toca `RF-01`, `RF-04`, `RF-05`, `RF-11`.

**A3 — Passo de design com dependência externa.** Exploração de UX apoiada por uma skill de design
externa, invocada quando fizer sentido, trazendo repertório de heurísticas de design que o harness
não tem.
- O que a persona passa a conseguir: provocações de design de qualidade profissional durante a
  descoberta.
- Prós: maior profundidade de UX; repertório ausente hoje.
- Contras: **quebra o `NFR-02` e exige supersessão do `ADR-007`** (deixaria de ser "exatamente 1
  dependência externa") — custo declarado; a dependência some em execução headless/cron; a skill de
  design puxa para o "como" (mira componente e tela), tensionando a fronteira; e ainda assim o sinal
  precisa do carregador da A2 para chegar ao backlog.
- ADRs tocados: **supersede `ADR-007`** (custo declarado desta alternativa).

## ROI

Três notas por alternativa — Impacto na persona (5 = resolve a dor central); Esforço (invertido,
5 = menor esforço); Risco/reversibilidade (invertido, 5 = menor risco, mais reversível). ROI =
média das três. Tabela ordenada por ROI decrescente.

| Alternativa | Impacto | Esforço | Risco/rev. | ROI |
|---|---|---|---|---|
| A1 — Aprofundar persona | 3 | 4 | 5 | 4,00 |
| A0 — Não fazer | 1 | 5 | 5 | 3,67 |
| A2 — NFR de experiência | 5 | 2 | 3 | 3,33 |
| A3 — Dependência de design | 4 | 2 | 1 | 2,33 |

Justificativas:

- **A1 (4,00).** Impacto 3: articula UX na origem, mas o sinal é fraco e pode evaporar antes do
  backlog. Esforço 4: estende um estágio em prosa, sem dependência nova nem verificador. Risco 5:
  aditivo, opcional, aconselha e é trivial de reverter; a fronteira se guarda fácil na prosa da
  persona.
- **A0 (3,67).** Impacto 1: é o próprio baseline da dor — não muda nada. Esforço 5 e Risco 5: não há
  o que fazer nem o que desfazer. (ROI alto engana: o impacto 1 revela que preserva a dor.)
- **A2 (3,33).** Impacto 5: garante que o UX chegue ao backlog e seja cobrado na demo — resolve a
  dor na raiz. Esforço 2: mexe em três estágios, exige canonização e possivelmente um verificador
  novo. Risco 3: risco real de burocracia e de vazamento para tela; reversível, porém com mais
  superfície.
- **A3 (2,33).** Impacto 4: profundidade alta, mas dependente do carregador da A2 para valer no
  backlog. Esforço 2: integrar a skill, o contrato e ainda o carregador. Risco 1: quebra um
  invariante forte do repo (`NFR-02`), supersede o `ADR-007`, a dependência é frágil em headless, e
  a skill de design tende a puxar para o "como".

## Recomendação

**Não vinculante.** Recomendo começar por **A1** — aprofundar a persona no discovery — como primeiro
passo reversível: é o de maior ROI, honra a fronteira e não toca nenhum invariante do repo, então
custa pouco para testar se articular UX na origem já melhora o backlog percebido. Mantenha a **A2**
(NFR de experiência com elo até o backlog) engatilhada como escalonamento: se, depois de rodar A1
em um ou dois produtos, o sinal de UX **evaporar** antes do backlog (a dor central não ceder), a A2
é o carregador forte que fecha a lacuna — e o esforço extra passa a se justificar. **A3** fica
desaconselhada nesta rodada: o ganho de profundidade não compensa quebrar o `NFR-02` e superseder o
`ADR-007`, ainda mais porque a skill de design tende ao "como" e o brainstorming — a dependência que
já temos — cobre a exploração de UX no nível de o-quê. Das três 🔴 de escopo, o Autor já confirmou
duas (usabilidade ampla com foco agudo em frontend; acessibilidade como NFR opcional); resta
confirmar a disposição a pagar a supersessão do `ADR-007` — que só pesa se a A3 voltar à mesa.

## Próximo passo sugerido

Se aprovado, rodar `superpowers:brainstorming` com a alternativa escolhida →
`superpowers:writing-plans` → `superpowers:executing-plans`. Decisão estruturante nova vira ADR via
`/zion-adr-new` e reflete no canon (`prd.md`/`architecture.md` no mesmo commit — CLAUDE.md).
