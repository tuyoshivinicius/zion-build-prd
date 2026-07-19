# Design — Classificação diagnóstica×propositiva na delegação criativa

- **Data:** 2026-07-19
- **Origem:** `docs/estudos/discovery-delegacao-brainstorming.md`, alternativa **D** (ROI 4.0)
- **Análise-mãe:** `zion-mermaid-editor-app/docs/analise-brainstorming-no-fluxo-zion.md` (2026-07-19)
- **Estado:** design validado, pronto para plano

## Problema

Três estágios criativos — `discovery`, `write`, `decompose` — delegam a clarificação ao
`superpowers:brainstorming` sob o contrato de capacidades C1–C3 (ADR-007). No **modo
retomar/revisar** essa clarificação **degrada**: o Autor recebe perguntas **diagnósticas** ("qual
dos seus fatos é o verdadeiro?") em vez de **propositivas** ("escolha entre estes desenhos"), sem
recomendação e sem preview que ilustre a escolha.

A análise-mãe mostra que a skill **roda** e cumpre o contrato — mas o contrato é menor do que o nome
sugere, e o harness **delega e pré-resolve ao mesmo tempo**: entrega as tensões ao brainstorming já
redigidas como pergunta, então ele transcreve em vez de refinar. A causa não é uma falha da skill; é
que a **natureza da pergunta** chega errada. No modo do-zero a fachada é até *melhor* que o
brainstorming avulso (12 previews contra 4) — o defeito é localizado no modo revisar e em
`write`/`decompose`.

A alternativa escolhida ataca a raiz — a natureza da pergunta — classificando cada tensão antes de
delegar, e gateando **o prompt que o harness controla** (não o marcador externo do superpowers, o
ponto cego que a análise chamava de E9).

## Escopo

**Decidido com o dono do harness:**

- **Alcance (E10):** os **três estágios** (`discovery`, `write`, `decompose`) no mesmo ciclo — não
  só o discovery. A rubrica e o gate nascem como asset/serviço compartilhado; cada `SKILL.md` liga o
  fluxo.
- **Fronteira (E7):** a liberação do preview conceitual fica **escopada à delegação criativa** — mora
  no asset novo, consumido só pelos três estágios. O `#fronteira` global de `quality-rules.md` fica
  **intacto**: specify/PRD seguem com tela banida. É coerente porque specify/PRD nem produzem
  preview — são prosa; e continua fonte única (`RN-05`), só que no lugar certo.
- **Gate (E9):** **auto-verificar o prompt montado** (molde do `check-prd.sh specify`), não gatear o
  marcador externo (isso era o mecanismo da Alt C, preterido).

**Não toca o contrato externo** (C1–C3, ADR-007): C1–C3 seguem válidos, sem supersessão. `NFR-02`
(exatamente 1 dependência externa de skill) fica **intacto** — o acoplamento com o superpowers não
cresce.

## A rubrica — `assets/delegacao-criativa.md`

Asset novo, **fonte única**, sincronizado para as `references/` das três skills e registrado no
`ASSET_MAP`. Carrega três regras:

### 1. Classificação diagnóstica × propositiva

Torna o E1 **rubrica explícita**, não julgamento cego. A definição de cada tipo e o teste prático:

| Tipo | A tensão pergunta… | Vira |
|---|---|---|
| **Diagnóstica** | *qual dos seus fatos/intenções é o verdadeiro?* | pergunta simples, uma por vez; **sem** recomendação (não há o que recomendar) e **sem** preview (não há artefato a ilustrar) |
| **Propositiva** | *isto admite mais de um desenho?* | 2–3 abordagens com trade-offs + **recomendação explícita** (liderando pela recomendada) + preview conceitual |

Ancorada nos dois exemplos reais da análise-mãe: §5.1 (diagnóstica — "qual momento de uso servir
primeiro", três leituras do que o autor quis dizer) × §5.2 (propositiva — "teclado primeiro × mouse
primeiro", três desenhos com recomendação e mockup). A distinção **não é de formatação, é de tipo de
pergunta**: uma pede informação, a outra propõe uma escolha de design.

### 2. Os dois previews (escopado aqui)

Substitui o banimento em bloco ("nunca 'tela Y', nunca atalho/widget/stack concreto") por duas
categorias, com **teste crítico** passa/vaza — sem ele o pêndulo volta (E6):

| Categoria | Exemplo | Na delegação |
|---|---|---|
| **Preview que ilustra a escolha** | fluxo de dados (`canvas edit ──► reescreve código`), barras de profundidade por tipo, contrato de saída em ✓/✗ | **liberado** — é auxílio de decisão |
| **Preview que desenha tela** | mockup de palette `Ctrl+K`, linha de atalhos sob o nó, arranjo de widget | **proibido** — é do `plan.md` |

Redação-núcleo: *"ilustrar a **consequência** de uma opção (fluxo, comparação, contrato de saída) é
bem-vindo e ajuda a decidir; desenhar **tela** (mockup, atalho, widget, arranjo de UI) fica no
`plan.md`."*

### 3. Condução (endereça a Causa 4)

A checklist do brainstorming não dirige o turno sob a fachada (0 `TaskCreate` em 7/7 sessões). A
rubrica instrui a condução explicitamente: *"conduza pelo seu protocolo — uma pergunta por vez;
quando a tensão for propositiva, 2–3 abordagens com trade-offs e sua recomendação explícita; **crie
uma tarefa por passo** da sua checklist."* É o que a análise (E3) apontou como necessário para R2
"pegar". Efeito não garantido (é prompt, não mecanismo) — declarado como limite, não como promessa.

### Vale nos dois modos

No **do-zero** (que já era melhor que o avulso) a rubrica **codifica** o que dava certo; no
**revisar**, **corrige**. Não há risco de regredir o do-zero — a rubrica é aditiva ali.

## Fluxo de delegação (em cada estágio)

Na fase de delegação (Fase 2/3 de `discovery`/`decompose`, Fase 3 de `write`), guiado por
`references/delegacao-criativa.md`:

1. **Enumerar como observação, não pergunta.** O agente lê o insumo (discovery / PRD / backlog) e
   lista as tensões como *observações do harness* — nunca já redigidas como pergunta. (R2 da análise,
   agora com contrato de forma.)
2. **Classificar cada tensão** diagnóstica/propositiva pela rubrica.
3. **Montar o bloco de delegação** como texto: as observações classificadas + a rubrica (distinção,
   dois previews, condução).
4. **Auto-verificar:** `printf '%s' "<bloco>" | bash references/check-delegacao.sh -`. Ecoa veredito
   (aconselha, `RN-01`); marcador faltando → o agente corrige antes de delegar.
5. **Invocar** `Skill(superpowers:brainstorming, args=<bloco>)` no mesmo turno, como hoje.

A única diferença de comportamento das skills: **materializar o bloco e se autoverificar antes de
invocar** (hoje montam inline). Na `discovery`, a linha antiga de supressão de preview (ramo
surface=sim) passa a **referenciar a rubrica** em vez do banimento em bloco.

## O gate — `check-delegacao.sh`

Novo verificador em shell, contrato comum do harness (**exit 0 limpo · 1 achados · 2 erro de uso**),
lido pela fase de delegação que **aconselha** (ADR-004 / `RN-01`). Lê o bloco montado do **stdin**
(`-`), igual ao `check-prd.sh specify`.

**Marcadores greppados** (tolerantes a reescrita, no molde do contrato C1–C3) — que o bloco carrega:

- a **distinção** pedida (`diagnóstic…` ∧ `propositiv…`);
- **propositiva → 2–3 abordagens + recomendação** (`2–3 abordagens` / `recomenda…`);
- a **regra dos dois previews** (preview conceitual liberado ∧ tela banida);
- a **condução** (`uma pergunta` / `passo a passo` / `tarefa por passo`).

**Auto-teste + fixtures (`NFR-04`):** `scripts/test-check-delegacao.sh` roda um par — bloco **com** a
distinção → exit 0; bloco **sem** → exit 1 citando o marcador ausente. Agregado por `eval.sh`.

### O limite honesto

Declarado no design e no ADR, na mesma candura da Consequência do ADR-007: o gate confirma que o
**prompt pede** a distinção; **não** confirma que o agente *classificou certo* cada tensão, que
*nada* foi pré-mastigado, nem que a *experiência melhorou* — isso segue julgamento. O que ele
**corrige** frente à Alt C é o alvo: gateia **o nosso prompt** (pega drift nas três `SKILL.md` — o
exato modo de falha "a correção só no prompt regride na próxima reescrita"), não o marcador externo
do superpowers (o ponto cego do E9). É um backstop de montagem de prompt, não um medidor de
experiência.

## Decisão estruturante (ADR novo)

**ADR-017 — "Classificação diagnóstica×propositiva na delegação criativa ao brainstorming"**, via
`/zion-adr-new`. Decisão estruturante nova **ao lado** do ADR-007, **sem supersedê-lo** (C1–C3 seguem
válidos → nenhuma referência de supersessão). Evidência: este design doc. Entra no índice §2 do
`architecture.md`.

A decisão em uma linha: a delegação criativa classifica cada tensão (diagnóstica/propositiva) numa
rubrica de fonte única e gateia **o prompt montado** por `check-delegacao.sh`, sem tocar o contrato
externo C1–C3.

## Canonização (mesmo commit — `architecture.md` §5)

| Mudança | Reflete em |
|---|---|
| Comportamento novo da delegação | **RF-20 novo** na §6 (épico E1) de `docs/prd.md` + linha na §12 |
| Script novo `check-delegacao.sh` | RF-11 (§6/§12) ganha o script; tabela de scripts (§3) de `docs/architecture.md` |
| Auto-teste + fixtures | RF-12 (§12) ganha `test-check-delegacao.sh`; tabela §3 de `architecture.md` |
| Fonte nova `assets/delegacao-criativa.md` | `ASSET_MAP` (`scripts/asset-map.sh`) + §4 de `docs/architecture.md` |
| Decisão estruturante | ADR-017 em `docs/adr/` + índice §2 de `docs/architecture.md` + restrição na §8 da PRD |
| Histórico | Linha no §13 de `docs/prd.md`, cenário **C1** (RF-20 novo) |

**RF-20 (o-quê, sem citar script):** *nos estágios que delegam a clarificação, a tensão que admite
desenho vira 2–3 abordagens + recomendação + preview que ilustra a escolha (não pergunta
diagnóstica); o prompt de delegação é verificado por máquina.* Optou-se por **RF novo
cross-cutting** em vez de emendar RF-01/04/05 com uma cláusula cada — mapeia 1:1 ao asset+gate novos.

`check-canon.sh` e `sync-assets.sh` **não** mudam de código — são genéricos; passam a cobrir os
artefatos novos uma vez canonizados. Natureza dos artefatos (§6 de `architecture.md`): o asset e o
`check-delegacao.sh` são **Distribuído** (viajam como reference); o `test-check-delegacao.sh` é
**Dev-workflow**. Já coberto pelo padrão — nenhuma linha nova na §6.

## Entregáveis

1. `assets/delegacao-criativa.md` — a rubrica (classificação + dois previews + condução), mais entrada
   no `ASSET_MAP` e sync para as `references/` de `zion-prd-discovery`, `zion-prd-write`,
   `zion-prd-decompose`.
2. `scripts/check-delegacao.sh` — o gate (stdin, marcadores, contrato de exit), sincronizado como
   reference das três skills.
3. `scripts/test-check-delegacao.sh` + fixtures limpa/suja em `scripts/fixtures/` — `NFR-04`.
4. 3 × `SKILL.md` — prosa da fase de delegação (materializar bloco + self-check + invocar) em
   discovery, write, decompose; na discovery, a supressão de preview passa a referenciar a rubrica.
5. `docs/adr/ADR-017-*.md` — a decisão estruturante acima.
6. Canonização: `docs/prd.md` (§6 RF-20, §12, §13, §8) e `docs/architecture.md` (§2, §3, §4).
7. Fixtures de julgamento (ADR-008): pergunta em modo revisar → resposta esperada carrega a distinção,
   no roteiro de `docs/guias/avaliacao-harness.md`.

## Fora de escopo

- **Tocar o contrato C1–C3 / declarar C4** (Alt C): não gateamos o marcador externo; o acoplamento
  com o superpowers não cresce.
- **Editar o `#fronteira` global** (opção B da fronteira): a regra de preview fica escopada à
  delegação.
- **Garantir a condução por mecanismo:** a instrução "crie uma tarefa por passo" é prompt, não
  garantia; efeito é julgamento.
- **Verificar que a experiência melhorou / que cada tensão foi classificada certo:** o gate cobre o
  decidível (o prompt pede a distinção), não o julgamento.
