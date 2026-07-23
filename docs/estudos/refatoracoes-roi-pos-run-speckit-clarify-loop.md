# Estudo — refatorações de alto ROI que o run do sentinela licencia no `speckit-clarify-loop`

## Contexto

O estudo `docs/estudos/sentinela-execucao-zion-mermaid-editor-app.md` mediu o contrato de estado
(`SENTINEL_PROMPT`) na **única execução real** cujos logs sobreviveram, contra o
`zion-mermaid-editor-app`: **35/35 turnos, 100% de adesão, 0 sondas, 0 abortos**
(`sentinela-execucao-…:39-59`). Essa medição é exatamente o tipo de evidência que o desenho do
próprio script exige antes de mexer — o `P-4` proíbe ligar sensor antes de medi-lo, e o `R-24`/`R-23`
só trocam o padrão de parada depois de ≥10 execuções reais pagas em ≥2 repos
(`refatoracao-final-speckit-clarify-loop.md:34-36`). Este estudo lê aquele run como o gatilho: **o que
a execução real agora licencia — ou revela como necessário — no `tools/speckit-clarify-loop`?**

**Nota de canon.** O `speckit-clarify-loop` é ferramenta pessoal **fora do canon**: não está na
tabela de scripts (`docs/architecture.md §3`) nem em RF do `docs/prd.md §6`, que põe "não executa o
ciclo do Spec Kit" no fora-de-escopo (`docs/prd.md §4`). **Consequência:** nenhuma alternativa toca
`prd.md` ou `architecture.md`, nenhuma cria ou supera ADR, nenhuma supersessão entra como custo — o
mesmo que a seção Contexto do irmão estabelece (`refatoracao-final-…:23-31`).

O run expõe três sinais, todos verificados nos logs e no código:

1. **A execução foi cara de medir porque a ferramenta descarta o próprio agregado.** O bloco
   `—— resumo ——` é `printf`'ado só para stdout e nunca gravado
   (`tools/speckit-clarify-loop:1058-1078`); os locais por rodada (`ROUND_YES/SENT/TURNS/COST/
   DECISIONS`) são dobrados em totais e jogados fora (`:995-1001`). Toda a seção **Reprodução** do
   estudo do run — `jq` arqueológico sobre `round-NN.jsonl` — existe **só** por causa disso
   (`sentinela-execucao-…:112-134`). Pior: R7 foi **interrompida externamente** e o `main_loop`
   morreu antes do `printf` do resumo (`sentinela-execucao-…:99-110`), então nem um agregado no fim
   teria sobrevivido.
2. **A família `CLARIFY_DECISION` é a de menor adesão e ninguém a mede.** `yes` (29) > decisões
   nomeadas (27): dois turnos responderam sem emitir a linha bem-formada e caíram no fallback
   "texto indisponível — contrato não aderiu" (`tools/speckit-clarify-loop:260-267`,
   `sentinela-execucao-…:76-80`). A adesão da **sentinela** aparece no resumo (`sentinela em N/M
   turnos`, `:1064`); a das **decisões**, não.
3. **A rede de recuperação (sonda/aborto) só é provada por leitura e por um hack descartável.** Como
   a sentinela nunca faltou, `indeterminada`/`miss_action` nunca dispararam em run real
   (`sentinela-execucao-…:92-97`). O único exercício ponta-a-ponta foi "com o `SENTINEL_PROMPT`
   neutralizado num experimento local **não commitado**" (`tools/speckit-clarify-loop:68-85`).

## Edge cases e incertezas

Derivadas da leitura do run e do código. **👤** marca as que só o Autor pode responder.

- **E-1** 👤 O run que motiva este estudo aderiu em 100%. Persistir o agregado vale por si — evitar a
  arqueologia `jq` a cada execução isolada — ou só como insumo da Fase 5 (≥10 runs) que ninguém
  agendou? Se a Fase 5 nunca acontecer, o registro ainda se paga?
- **E-2** R7 foi cortada externamente e o `main_loop` morreu **antes** do resumo
  (`sentinela-execucao-…:99-110`). Um `tee` do resumo final não teria pego R7 — só persistência
  **incremental por rodada** recupera um run interrompido. Confirma-se que o registro precisa ser
  por-rodada, não só no fim?
- **E-3** 👤 A adesão da família de decisões (27/29) é baixa por variação do modelo ou por o prompt
  não ser específico o bastante? Medir mostra o número; ninguém decidiu se a resposta muda o prompt —
  e mexer no prompt reabre, de leve, a classe de bug que a sentinela matou
  (`tools/speckit-clarify-loop:148-153`).
- **E-4** O ramo sonda/aborto só roda com o `SENTINEL_PROMPT` neutralizado. Um caminho test-only sob
  `--dry-run` prova a **decisão** (`miss_action`) e o **envio** (`REPLY_PROBE`) — mas **não** prova a
  propriedade que separa a sonda do `yes` seco: não poder ser lida como aprovação quando NÃO houve
  pergunta (`tools/speckit-clarify-loop:77-82`). Essa propriedade segue intestável sem um run real
  com pergunta ausente.
- **E-5** 👤 A ferramenta é pessoal, invocada à mão. Um agregado machine-legível pressupõe consumidor
  programático (a agregação da Fase 5). Sem a Fase 5 agendada, o resumo legível basta e o formato
  estruturado é custo? (espelha o `E-13` do irmão sobre a tabela de códigos de saída,
  `refatoracao-final-…:98-99`.)
- **E-6** Capturar interrupção externa depende de um trap `INT`/`TERM` que dispare a tempo de gravar
  — e o run foi morto por `TERM` aos 898 s no passado (`tools/speckit-clarify-loop:96-106`). O trap
  grava a tempo, ou o processo já foi? A instrumentação de interrupção pode ser mais frágil do que o
  ROI aparente.
- **E-7** 👤 Custo de oportunidade: o script está fora do canon. Cada hora aqui é uma hora fora do
  harness, que é o produto (`refatoracao-final-…:104-105`). O registro é barato o bastante para não
  disputar; a rede e a interrupção são?

## Alternativas

Nenhuma toca `prd.md`, `architecture.md` ou ADR algum — pelo que a seção Contexto estabelece. Sem
supersessão a declarar como custo.

### A — Não fazer

Congelar o loop no estado pós-poda verificado em 2026-07-21: sentinela como caminho único, guarda de
vazamento ativa, rede de recuperação no ar, auto-teste em 143 casos
(`tools/speckit-clarify-loop:51-67`).

- **Prós:** custo zero, nenhum risco novo, o loop segue utilizável hoje. O run confirmou que o
  contrato aderiu em 100% — a fatia mais cara de valor já foi colhida.
- **Contras:** cada execução futura repete a reconstrução arqueológica que este estudo pagou; a
  Fase 5 (≥10 runs) fica cara de agregar, o que perpetua os sensores narrando sem decidir.
- **ADRs tocados:** nenhum.

### B — Só o registro persistente

O run passa a deixar o próprio agregado em disco: um registro **por rodada, incremental** (turnos,
sentinela, `yes`, decisões, custo, delta), mais o resumo consolidado ao fim — em forma legível e em
forma estruturada, no diretório da execução ao lado dos logs que já existem.

- **Prós:** o analista deixa de reconstruir; um run interrompido deixa dados até o corte (o caso R7);
  destrava a agregação barata da Fase 5. É o menor risco de todos — anexa ao diretório da execução,
  nunca toca o repo-alvo nem o spec. Enabler barato das alternativas seguintes.
- **Contras:** sozinho não melhora a adesão do contrato nem prova a rede.
- **ADRs tocados:** nenhum.

### C — Registro + instrumentar as adesões fracas

O `B` inteiro, mais a adesão da **família de decisões** no resumo (`decisões nomeadas N/yes M`),
espelhando a linha que a sentinela já tem. Fecha o ponto cego que este run expôs.

- **Prós:** o contrato mais fraco passa a ser visível a cada execução, sem mudar comportamento; o
  esforço marginal sobre `B` é baixo, porque a leitura pega carona no que já foi coletado.
- **Contras:** visibilidade não é correção — medir 27/29 mostra a lacuna, não a fecha.
- **ADRs tocados:** nenhum.

### D — Registro + rede + interrupção

O `C`, mais um caminho **versionado e repetível** que força sonda/aborto sob `--dry-run` (hoje só um
hack não commitado o exercita), e a captura de interrupção externa como desfecho de 1ª classe (um
trap grava a parada no resumo em vez de o run sumir).

- **Prós:** a rede de recuperação deixa de depender de um experimento descartável; o caso R7
  auto-documenta em vez de exigir perícia no log.
- **Contras:** o maior escopo. O caminho forçado **não** prova a propriedade central da sonda
  (`E-4`); a captura de interrupção depende de um trap confiável no pior momento possível — a própria
  interrupção — que `E-6` põe em dúvida.
- **ADRs tocados:** nenhum.

## ROI

Três notas de 1 a 5; **Esforço** e **Risco** invertidos (5 = menor esforço, menor risco, mais
reversível). ROI é a média. Tabela ordenada por ROI decrescente.

| # | Alternativa | Impacto | Esforço | Risco | **ROI** |
|---|---|:-:|:-:|:-:|:-:|
| B | Só o registro persistente | 4 | 5 | 5 | **4,67** |
| C | Registro + instrumentar adesões | 4 | 4 | 5 | **4,33** |
| A | Não fazer | 1 | 5 | 4 | **3,33** |
| D | Registro + rede + interrupção | 5 | 2 | 2 | **3,00** |

**B — 4,67.** *Impacto 4:* mata a reconstrução arqueológica, recupera runs interrompidos (o caso R7
real) e torna barata a coleta da Fase 5 — hoje o maior bloqueio declarado para ligar a semântica de
parada dos sensores. Não chega a 5 porque, fora medir, não melhora nada operacional. *Esforço 5:* os
valores já estão computados como locais; é um redirecionamento mais um pequeno registro estruturado.
*Risco 5:* anexa ao diretório da execução, nunca toca o repo-alvo — não há como corromper um spec.

**C — 4,33.** *Impacto 4:* torna visível, a cada execução, o contrato que este run mostrou ser o mais
fraco. *Esforço 4:* um contador e uma linha, sobre `B`. *Risco 5:* medir uma linha de exibição não é
sinal de controle — não reabre a classe de bug que a sentinela matou.

**A — 3,33.** *Impacto 1:* por definição, nada muda. *Esforço 5:* zero. *Risco 4, não 5:* nada
quebra, mas a dívida de medição continua sendo paga — cada run isolado repete a reconstrução que
custou este estudo.

**D — 3,00.** *Impacto 5:* prova a rede e auto-documenta a interrupção, os dois sinais que o run
deixou em aberto. *Esforço 2:* o maior escopo, e cresce o auto-teste junto. *Risco 2:* é onde o loop
ganha um trap que precisa disparar no pior momento (`E-6`) e uma afordância test-only que, mal
gateada, é footgun; e ainda assim a propriedade central da sonda segue intestável (`E-4`).

**Sinal a registrar:** "não fazer" (3,33) pontua **acima** do pacote máximo `D` (3,00). O run
licencia forte o enabler barato (`B`/`C`), mas ainda **não** licencia a rede cara sobre só congelar —
porque a propriedade que separa a sonda do `yes` seco segue intestável (`E-4`) e o trap é frágil sob
`TERM` (`E-6`). É o mesmo formato do irmão, e o mesmo motivo de a alternativa "não fazer" ser
obrigatória (`refatoracao-final-…:208-209`).

## Recomendação

**Não vinculante.** A recomendação é a **alternativa B — só o registro persistente** como primeiro e
único passo: é o maior ROI, o menor risco, e o enabler que destrava a agregação barata da Fase 5,
hoje o bloqueio declarado para um dia *ligar* a decisão de parada (`R-24`/`R-23`). Ele precisa ser
**incremental por rodada**, não só no fim — senão não cobre o caso R7, que foi cortado antes do
resumo (`E-2`, `sentinela-execucao-…:99-110`). A **alternativa C** (somar a instrumentação da adesão
das decisões) é o seguimento natural e barato — a leitura pega carona em `B` — e fecha o ponto cego
que este run expôs; abra-a assim que `B` estiver no ar. A **alternativa D** só se justifica **depois**
de (a) um run real com pergunta ausente que prove a propriedade central da sonda (`E-4`) e (b) o trap
de interrupção medido sob `TERM` (`E-6`); antes disso, `D` não bate "não fazer". Nada toca canon: o
script está fora dele (`docs/architecture.md §3`, `docs/prd.md §6`).

## Próximo passo sugerido

Se aprovado, rodar `superpowers:brainstorming` com a alternativa escolhida →
`superpowers:writing-plans` → `superpowers:executing-plans`. Decisão estruturante nova vira ADR via
`/zion-adr-new` e reflete no canon (`prd.md`/`architecture.md` no mesmo commit — CLAUDE.md).
