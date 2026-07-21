# Estudo — fechar os planos restantes da evolução do `speckit-clarify-loop`

## Contexto

O `tools/speckit-clarify-loop` automatiza o ciclo de clarificação do Spec Kit sob a invariante "uma
rodada = um processo" (`tools/speckit-clarify-loop:1-5`). A evolução dele está descrita em
`docs/superpowers/specs/2026-07-21-speckit-clarify-loop-evolucao-design.md`, que divide o trabalho
em cinco fases mais uma Parte II de mitigação de contaminação, e distribui a entrega em quatro
planos (`D-4`). O **plano 1 — Fase 0 (instrumentação) + Fase 1 (contrato de saída) — está
concluído e verificado**: o cabeçalho do script traz nota datada de 2026-07-21 registrando sentinela
em 4/4 turnos, 3/3 decisões nomeadas no resumo e nenhum falso positivo da guarda de vazamento
(`tools/speckit-clarify-loop:37-52`); o auto-teste fecha com 139 casos. Restam os planos 2, 3 e 4 —
Fase 3 (semântica de parada), Fase 2 em modo narrativo (sensores) e Fase 4 (custo e auditoria) —
mais a Fase 5, que é protocolo de medição e não vira plano (`D-4`).

O candidato deste estudo é **fechar esses três planos**. Quem sofre é o próprio autor **mantendo** o
script: são 1786 linhas num arquivo só — condição de desenho, porque a ferramenta se instala por
cópia e não pode depender de nada ao lado dela (`plano 1, §File Structure`) — e duas verdades
convivem sobre a mesma decisão: a sentinela de estado, que é o contrato, e a heurística de prosa
bilíngue, que o `S-4` congelou mas deixou viva como fallback (`tools/speckit-clarify-loop:249`,
`:290-303`).

**O script está fora do canon do harness.** Não aparece na tabela de scripts do
`docs/architecture.md §3` — que cataloga apenas `scripts/` e cujo guard `check-canon.sh` acusa
script fora dela — nem em RF algum do `docs/prd.md §6`; e o `docs/prd.md §4` põe "não executa o
ciclo do Spec Kit (specify em diante é do autor)" explicitamente no fora-de-escopo. A própria spec
de evolução declara a exclusão: "ferramenta pessoal, instalada por cópia no PATH… o dever de
canonização do `CLAUDE.md` não se aplica a esta mudança"
(`2026-07-21-speckit-clarify-loop-evolucao-design.md:9-11`). **Consequência para este estudo:**
nenhuma alternativa toca `prd.md` ou `architecture.md`, nenhuma cria ou supera ADR, e nenhuma
supersessão entra como custo.

Duas restrições do próprio script governam as alternativas. O `P-4` proíbe ligar sensor antes de
medi-lo, e o `P-6` só admite simplificação que remova duplicação de fonte de verdade. Os limiares
`SENSOR_MIN_YES=2` e `SENSOR_MIN_CHURN=5` são chutes declarados até o `R-24`, que exige ≥10
execuções reais pagas em ≥2 repos (`R-23`) — custo em dólar e em calendário, não em código.

## Edge cases e incertezas

Confirmadas com o autor. **👤** marca as perguntas que só ele pode responder.

**A dor declarada × o que o candidato entrega**

- **E-1** 👤 A dor declarada é custo de manutenção e duas verdades de classificação. Os planos 2–4
  acrescentam sensores, regra de combinação com estado entre rodadas, seletor de três modos, ramo
  dedicado, marca por rodada e sete linhas novas de resumo — e não removem uma única constante da
  heurística. Se a dor é manutenção, o candidato a piora. O que se quer: fechar o escopo prometido,
  ou reduzir o arquivo?
- **E-2** O `S-4` congelou a heurística mas a deixou viva indefinidamente como fallback. Existe
  critério de saída — "sentinela em M/M por 5 execuções ⇒ a heurística sai" — ou o fallback é
  permanente por desenho? Sem esse critério, as duas verdades nunca convergem para uma.

**Acoplamento a montante**

- **E-3** *Verificado durante este estudo.* O ramo que o `M-01` cria,
  `clarify/<dir-do-spec>-<timestamp>`, **passa** na validação do Spec Kit — mas só porque
  `spec_kit_effective_branch_name` descarta exatamente um segmento antes da barra e o nome restante
  começa com o prefixo numérico do diretório de spec
  (`~/projects/personal/zion-test-build-prd/.specify/scripts/bash/common.sh:128-150`). É
  coincidência de estrutura, não contrato: num repo cujo diretório de spec não comece com 3+
  dígitos, a resolução cai no match exato e o preflight recusa **antes de qualquer chamada paga**.
- **E-4** A nota datada registra que "a skill alternou a língua dos marcadores (pt e en)"
  (`tools/speckit-clarify-loop:24-26`) — o script já foi mordido por deriva a montante. A Fase 2
  acopla mais ao formato do spec do que a Fase 1 acoplava. Quanto dos planos 2–4 é aposta na
  estabilidade da versão verificada e da skill?

**A Fase 5 como pré-requisito que pode nunca acontecer**

- **E-5** 👤 O `R-24` só troca o padrão para parada efetiva depois de ≥10 execuções reais pagas em
  ≥2 repos. As execuções registradas custaram de US$ 0,30 a US$ 1,99 cada
  (`tools/speckit-clarify-loop:27-40`). Há apetite de orçamento e de calendário — e quando?
- **E-6** O `R-21` corta o teto de rodadas de 10 para 3 no mesmo pacote que precisa de dados de
  rodadas 4–5 para calibrar. As duas metades do candidato brigam.
- **E-7** Sem a Fase 5, a Fase 2 fica em modo narrativo permanentemente: cinco leituras, a regra de
  combinação e o seletor de três modos narram e nunca decidem. Aceita-se mergear sabendo disso? O
  `P-4` autoriza; o `P-6` reclama.
- **E-8** O `D-1` mediu **0 marcadores `[NEEDS CLARIFICATION]` em 7 de 7 specs reais**, inclusive nos
  dois contra os quais o loop já rodou. Um dos cinco sensores nasce em abstenção permanente nos
  repos do autor. Qual a evidência de que os outros quatro não são igualmente inertes?

**O risco novo — o único risco alto do pacote**

- **E-9** Até hoje o loop escreve num arquivo. Com o `M-01` e o `R-22` ele passa a criar ramo e
  gravar marcas no repo real do projeto-alvo. Um defeito ali deixa de custar dólar e passa a custar
  trabalho. Qual o teste que autoriza isso, dado que o auto-teste é por construção sem repo?
- **E-10** O `D-9` remove o ramo na saída quando não houve marca e o conteúdo não mudou. E se houve
  interrupção no meio, ou o editor está aberto naquele ramo, ou a volta ao ramo base falha por
  sujeira que o próprio loop criou?
- **E-11** 👤 O resumo de decisões (`M-04`) e a linha `revisar:` (`M-05`) existem para o autor ler.
  Ele vai ler? A própria spec admite: "nenhum deles obriga ninguém a ler" (§Risco residual). Se a
  resposta honesta for "não", `M-02`, `M-04` e `M-05` são custo puro.

**Separabilidade do escopo**

- **E-12** O `S-6` é o único item que satisfaz o `P-6` sem reservas: colapsa ~15 linhas de
  ramificação em 3 e faz a verificação do modo de ensaio usar a mesma garantia dos demais caminhos.
  Pode sair sozinho?
- **E-13** A tabela de cinco códigos de saída (`R-20`) pressupõe consumidor programático. Numa
  ferramenta pessoal invocada à mão, quem lê código de saída — ou o resumo na tela já resolve?
- **E-14** 👤 O `M-09` recomenda "rodada 1 à mão, depois no máximo 2 automáticas"; o `R-21` fixa o
  teto em 3; a spec afirma que "o retorno cai forte após a 2ª rodada". O desenho conclui que o loop
  deve rodar de 1 a 2 rodadas automáticas. Vale investir três planos numa ferramenta que a própria
  análise de risco pede para usar menos?
- **E-15** 👤 Custo de oportunidade: o script está fora do canon (`architecture.md §3`,
  `prd.md §6`). Cada hora aqui é uma hora fora do harness, que é o produto.

## Alternativas

Nenhuma delas toca `prd.md` ou `architecture.md`, e **nenhuma toca ADR algum** — pelo que a seção
Contexto estabelece. Não há supersessão a declarar como custo em nenhuma alternativa.

### A — Não fazer

Congelar o loop no estado verificado em 2026-07-21: contrato de saída no ar, decisões nomeadas no
resumo, guarda de vazamento ativa, 139 casos de auto-teste.

- **Prós:** custo zero; nenhum risco novo; o loop continua utilizável hoje. A Fase 1 já colheu a
  maior fatia isolada de valor — ela "encerra a classe de bug mais cara do histórico do arquivo
  (sete comentários datados, >US$ 20 em rodadas boas descartadas por variação de prosa)"
  (`spec de evolução, §Fase 1`).
- **Contras:** a dor declarada fica intacta e permanente. Sobra uma spec de ~730 linhas descrevendo
  três planos que nunca vão existir — dívida documental que se paga por leitura a cada retomada do
  assunto.
- **ADRs tocados:** nenhum.

### B — Só a poda, com rede

Consumar o `S-4` — a heurística de prosa sai, a sentinela fica como caminho único —, com o `R-16`
como rede (turno indeterminado deixa de ser fatal na primeira ocorrência), mais o `S-6` (uma
garantia de "não escreveu" em lugar de duas) e o `M-05` (a linha `revisar:` fecha todo resumo).

- **Prós:** o arquivo termina **menor** do que começou; some a divergência possível entre as duas
  verdades; falha de classificação vira defeito do contrato, com um lugar só para consertar. Tudo é
  função pura, exercitável sem repo e sem custo (`P-3`). Nada toca o repo-alvo.
- **Contras:** o `S-4` exige "sentinela em M/M por 5 execuções reais" e só há **2** verificadas
  (`tools/speckit-clarify-loop:27-52`) — a poda antecipa a evidência. Daí o `R-16` vir junto: sem
  ele, um turno sem sentinela abortaria a rodada paga, regredindo ao defeito que a Fase 1 matou.
  **Custo declarado:** a §Ordem de entrega da spec de evolução deixa de descrever o que existe e
  precisa ser corrigida no mesmo movimento.
- **ADRs tocados:** nenhum.

### C — Poda, parada e contenção, sem os sensores

O `B` inteiro, mais o resto da semântica de parada (estouro do teto de perguntas vira rodada
completa; código de saída distinto quando o conteúdo foi alterado numa rodada abortada) e a
contenção completa: ramo dedicado por padrão, uma marca por rodada, resumo consolidado com as
decisões nomeadas, teto de rodadas honesto e gates a jusante sugeridos. A camada de sensores fica de
fora até existir medição.

- **Prós:** o autor deixa de precisar desfazer contaminação — passa a não aceitá-la; lê 15 linhas de
  decisões em vez de um diff de 200; descarta uma rodada específica em vez do trabalho inteiro.
  Ataca o maior risco declarado pela própria spec — "o modelo continua tomando decisões de produto
  que ninguém leu no momento em que foram tomadas" (§Risco residual) — pelo único ângulo tratável.
- **Contras:** é o ponto em que o loop passa a escrever no histórico do repo-alvo, o único lugar
  onde um defeito custa trabalho e não dólar (`E-9`, `E-10`). Depende de normalização interna do
  Spec Kit que ninguém prometeu estabilizar (`E-3`). O auto-teste, por construção sem repo, não
  cobre a parte nova.
- **ADRs tocados:** nenhum.

### D — Fechar os planos 2, 3 e 4 (o candidato literal)

O `C`, mais a camada de sensores em modo narrativo: cinco leituras da rodada, a regra de combinação
com fadiga persistindo entre rodadas e o seletor de três modos.

- **Prós:** cumpre o escopo prometido pela spec de evolução e honra a ordem de entrega declarada
  (§Ordem de entrega); deixa a decisão de parada pronta para ser ligada no dia em que os números
  existirem.
- **Contras:** entrega código que narra e nunca decide, e continua assim até ≥10 execuções pagas em
  ≥2 repos que ninguém agendou (`R-23`, `E-5`). Um dos cinco sensores nasce inerte: 0 marcadores em
  7 de 7 specs reais (`D-1`, `E-8`). O auto-teste passa de 139 para 200+ casos num arquivo de 1786
  linhas — o oposto da dor declarada (`E-1`).
- **ADRs tocados:** nenhum.

## ROI

Três notas de 1 a 5; **Esforço** e **Risco** são invertidos (5 = menor esforço, menor risco e maior
reversibilidade). ROI é a média das três. Tabela ordenada por ROI decrescente.

| # | Alternativa | Impacto | Esforço | Risco | **ROI** |
|---|---|:-:|:-:|:-:|:-:|
| B | Só a poda, com rede | 4 | 4 | 4 | **4,00** |
| A | Não fazer | 1 | 5 | 4 | **3,33** |
| C | Poda, parada e contenção | 5 | 2 | 2 | **3,00** |
| D | Fechar os planos 2, 3 e 4 | 5 | 1 | 2 | **2,67** |

**B — 4,00.** *Impacto 4:* é a única alternativa que mira a dor nomeada pelo autor, e a única em que
o arquivo termina menor do que começou. Não chega a 5 porque, fora deixar de descartar rodada paga,
não melhora nada operacional. *Esforço 4:* remoção e funções puras; o grosso do trabalho é reescrever
fixtures de teste. *Risco 4:* alto e reversível — se o contrato falhar, o sintoma aparece no resumo
(`sentinela: N/M turnos`, `R-09`) antes de custar caro, e desfazer é um comando, já que a ferramenta
se instala por cópia.

**A — 3,33.** *Impacto 1:* por definição, nada muda. *Esforço 5:* zero. *Risco 4, e não 5:* nada
quebra, mas a spec aberta continua cobrando leitura — a cada retomada se reconstroem ~730 linhas de
contexto, que foi exatamente o custo pago para produzir este estudo.

**C — 3,00.** *Impacto 5:* é o pacote que muda o dia a dia e o único que ataca o risco residual
declarado. *Esforço 2:* dois planos inteiros, e o maior deles. *Risco 2:* o loop deixa de escrever
num arquivo e passa a mexer no histórico do repo-alvo; a limpeza automática do ramo na saída (`D-9`)
age durante uma interrupção, que é a pior hora possível. Reverter o script é trivial; reverter o
repo-alvo não é.

**D — 2,67.** *Impacto 5, com marginal zero sobre C:* o que `D` acrescenta a `C` não decide nada até
a Fase 5 acontecer. *Esforço 1:* o maior escopo dos quatro, e a suíte cresce junto. *Risco 2:* todo o
risco de `C`, mais o de mergear uma camada que pode nunca ser ligada, mais a briga interna do `E-6` —
o corte do teto de rodadas estreita a amostra que a calibração precisaria coletar.

**Sinal a registrar:** "não fazer" pontua acima de duas alternativas, inclusive acima do candidato
literal. É o resultado que a obrigatoriedade dessa alternativa existe para expor.

## Recomendação

**Não vinculante.** A recomendação é a **alternativa B — só a poda, com rede**, e é a única que
responde à dor que o autor efetivamente declarou: ela reduz o arquivo em vez de ampliá-lo, elimina a
possibilidade de divergência entre sentinela e heurística, e sai barata e reversível. `C` é
genuinamente valiosa e continua disponível depois — mas só deveria ser aberta quando o `E-11`
tiver resposta honesta ("eu vou ler o resumo de decisões?"), porque `M-02`, `M-04` e `M-05` são
custo puro se a resposta for não; e quando houver um teste que cubra a escrita no repo-alvo, que o
auto-teste sem repo não alcança (`E-9`). `D` só se justifica **depois** da medição da Fase 5, não
antes: entregar a camada de sensores hoje é escolher limiar no escuro, que é o único erro de ordem
que a própria spec nomeia. Isso inverte a §Ordem de entrega declarada — e essa inversão, se
aceita, precisa ser refletida na spec de evolução no mesmo commit, sob pena de a spec passar a
descrever um plano que ninguém vai seguir.

## Próximo passo sugerido

Se aprovado, rodar `superpowers:brainstorming` com a alternativa escolhida →
`superpowers:writing-plans` → `superpowers:executing-plans`. Decisão estruturante nova vira ADR via
`/zion-adr-new` e reflete no canon (`prd.md`/`architecture.md` no mesmo commit — CLAUDE.md).
