# Design — `architecture.md` do produto gerado sob ditado e reconciliado (A1+A3)

> Spec de mudança do **harness** (não de produto do usuário). Nasce da composição **A1+A3** do
> estudo `docs/estudos/geracao-do-architecture-do-produto.md`, escolhida pelo Autor. Sujeita ao
> dever de canonização (`CLAUDE.md`): toda mudança de comportamento reflete em `docs/prd.md` e
> `docs/architecture.md` no mesmo commit. Supersede o ADR-015.

## Problema

O `docs/architecture.md` do produto é **semeado, não gerado**: `/zion-speckit-install` copia um
esqueleto cuja §1 (visão geral) e §2 (integrações externas) são prosa do Autor nunca tocada por
máquina (ADR-015 ponto 3). Só a §3 (índice de ADRs) e a §4 (visão do backlog) são derivadas.

A dor é comprovada. No `zion-mermaid-editor-app` — produto conduzido pelo próprio harness, PRD
fechada sobre 10 ADRs, backlog decomposto em 19 specs — a §1 e a §2 seguem com o placeholder
literal do esqueleto. A máquina já acusa (`check-arquitetura.sh` emite `visao-vazia`), o veredito é
advisório (ADR-004, `NFR-05`) e o placeholder atravessou a jornada inteira intacto: mais aviso,
isolado, não moveu o Autor. Enquanto isso a ponte do plan promete injetar "a prosa estrutural do
documento de arquitetura, quando existe" (`RF-08`) e injeta vazio.

## Decisão

Compor as duas metades que o estudo separou:

- **Derivar** (A3) o que os ADRs já respondem — a §3 deixa de ser índice plano e vira **mapa**:
  decisões agrupadas por área, com o que cada uma fixou e as specs que a exercitam.
- **Ditar** (A1) o que nenhum derivado expressa — como os componentes conversam. A §1 e a §2 passam
  a ser redigidas numa fase final do `/zion-prd-decompose`, onde a máquina propõe o rascunho e o
  Autor assina, **nunca sobrescritas sem confirmação**.
- **Reconciliar** — a narrativa carrega uma âncora invisível com os ADRs que a sustentam; o trace
  acusa supersessão e defasagem num bloco derivado adjacente, e o modo `--narrativa` oferece o
  rascunho novo.

Decisões fechadas no brainstorming (todas do Autor):

1. **Fronteira §1 × plan (edge 3)** — a §1 é **topologia + contratos**: nomeia os componentes de
   topo e o contrato entre eles (quem chama quem, por qual via, quem é dono de qual dado). O
   interior de cada componente é do `plan`. Regra de corte citável: *se a frase muda ao trocar UMA
   feature, é `plan`; se muda só ao trocar o produto, é §1.*
2. **Âncora (edge 11)** — **invisível por bloco**, no marcador de abertura, populada pela máquina
   com os ADRs que ela de fato usou ao redigir. Prosa 100% limpa no render; zero digitação do Autor.
3. **Dia 2 (edge 10)** — a máquina **marca no bloco derivado adjacente e propõe reescrita sob
   confirmação**. Nunca escreve dentro da prosa do Autor.
4. **Gatilho (edge 14/16)** — **fase final do `/zion-prd-decompose`** para a gênese, e flag
   `--narrativa` para revisar, no padrão do `--epico E<k>` que a skill já tem. **Zero comando
   novo**: a ajuda (`RF-19`) segue explicando 12 comandos.
5. **Mapa (edges 21/23)** — a **§3 evolui** para o mapa; nenhum bloco novo na §1. Um dono por
   pergunta: §1 responde "como conversam", §3 responde "o que foi decidido e onde vive". Zero
   duplicação de ADR no mesmo documento.
6. **Riqueza do mapa** — área + o que fixou + specs. É o elo das specs que responde "onde essa
   decisão vive no código", a pergunta da reorientação meses depois.
7. **Supersessão** — **ADR-018 substitui o ADR-015 integralmente**, reafirmando no próprio texto os
   pontos 1, 2 e 4 e redecidindo o ponto 3. Satisfaz a simetria que o `check-adr.sh` já cobra, sem
   contrato de verificação novo.

### Verificado no código, não suposto

O **edge 19 já é não-problema**: `check-arquitetura.sh` não carrega a denylist de stack de
`quality-rules.md`. Nomear tecnologia na §1 nunca gerou falso positivo e nada precisa ser feito.

## O artefato resultante

```markdown
## 1. Visão geral

<!-- zion:narrativa-avisos:start -->                          <!-- DERIVADO (trace) -->
_(narrativa em dia)_
<!-- zion:narrativa-avisos:end -->

<!-- zion:narrativa:start adrs=ADR-002,ADR-004,ADR-007 -->    <!-- DITADO (decompose) -->
O produto é um editor local-first: **Canvas** (edição direta), **Compilador**
(texto ↔ grafo) e **Store** (persistência). O Canvas nunca toca o texto: emite
intenções ao Compilador, única fonte de verdade do documento. O Store observa o
Compilador e persiste; nada lê o Store direto.
<!-- zion:narrativa:end -->

## 2. Integrações externas

_(nenhuma integração externa)_                                <!-- estado declarável -->

## 3. Decisões estruturantes

<!-- zion:adr-index:start -->                                 <!-- DERIVADO, agrupado -->
### Persistência
- **[ADR-002](adr/ADR-002-local-first.md)** — local-first, sem servidor
  fixou: o disco do autor é a fonte da verdade · specs: `01-walking-skeleton`, `07-export`
### Compilação
- **[ADR-004](adr/ADR-004-texto-canonico.md)** — texto é o formato canônico
  fixou: o grafo é derivado, nunca persistido · specs: `02-parser`, `03-render`
<!-- zion:adr-index:end -->

## 4. Visão do backlog                                        <!-- inalterada -->
```

**A §2 não recebe marcadores, por escolha.** A máquina só precisa distinguir "declarado" de
"placeholder do esqueleto", e as duas strings já são diferentes. `_(nenhuma integração externa)_`
passa a ser conteúdo válido — `visao-vazia` nunca cobriu a §2 mesmo.

**A âncora nunca é escrita pelo Autor.** Se ele reescrever a prosa à mão sem mexer na âncora, o
pior caso é um aviso a mais, nunca um aviso a menos.

## Componentes

### 1. Fase de narrativa — `/zion-prd-decompose`, Fase 5 (nova)

Roda depois da Fase 4 (validação), quando ADRs, backlog e §3 já existem — o momento em que o
material finalmente existe (edges 6 e 7).

1. **Lê** `docs/adr/*.md` aceitos, `docs/backlog.md` e a §3 recém-reconciliada.
2. **Redige o rascunho** na regra de corte (topologia e contratos), sob **regra de lastro dura**:
   toda afirmação estrutural rastreia a um ADR. O que não tem lastro **não vira prosa** — vira uma
   pergunta ao Autor ("os ADRs não dizem quem persiste esse dado — quem é o dono?"), e a resposta
   dele entra como prosa dele. É o que fecha o risco do edge 2 (a máquina inventar arquitetura).
3. **Semeia os marcadores** `zion:narrativa` e `zion:narrativa-avisos` na §1 quando ausentes — é o
   que torna produtos já instalados atendíveis sem migração manual, já que o
   `/zion-speckit-install` nunca sobrescreve documento existente.
4. **Apresenta** `[aceitar]` `[editar]` `[ditar do zero]` `[pular]`. Pular é legítimo: produto de
   jornada curta sem material (edge 8) sai com a §1 vazia e um aviso, não com prosa inventada.
5. **Grava** entre os marcadores, com `adrs=` preenchido pelos ADRs efetivamente usados.
6. **Idem §2**, com `_(nenhuma integração externa)_` como saída válida.
7. **Autoverifica** com `check-arquitetura.sh` e ecoa o veredito — aconselha, `RN-01`.

**Sem delegação nova ao `superpowers:brainstorming`.** O decompose já delega na Fase 2/3; esta fase
é redação sob ditado, não clarificação. Tensão de desenho que apareça segue a rubrica de
`assets/delegacao-criativa.md` que a skill já carrega (`RF-20`). `NFR-02` intacto.

**`--narrativa`** pula as Fases 1–4 (não re-fatia nada) e entra direto aqui em modo revisar: mostra
a narrativa vigente, os avisos de defasagem e o rascunho novo lado a lado. Nunca sobrescreve sem
confirmação — é essa cláusula que substitui o "nunca tocada por máquina" do ADR-015.

### 2. Mapa da §3 — `trace-arquitetura.sh`

| Elemento | Vem de | Contrato |
|---|---|---|
| **área** | `- **Área:** <palavra>` no cabeçalho do ADR | `/zion-adr-new` passa a pedir; `check-adr.sh` ganha `area-ausente` (advisory) |
| **fixou** | 1ª frase da seção `## Decisão` do ADR | nenhum — derivação pura, best-effort |
| **specs** | `**ADRs honrados:** ADR-002, ADR-007` na `spec.md` | gêmeo do `**RF cobertos:**` que o `trace-prd.sh` já parseia |

Bordas, todas necessárias para o bloco ser determinístico (o `--check` de drift depende disso):

- **ADR sem `Área:`** cai no grupo `Sem área`, no fim. Nunca some do mapa — a migração dos ADRs
  existentes é gradual e advisória, não big bang.
- **Ordenação**: áreas pelo menor `ADR-n` que cada uma contém (estável e cronológica); ADRs dentro
  da área por número.
- **ADR substituído sai do mapa**, com rodapé `_(N decisões substituídas — veja `docs/adr/`)_`. O
  mapa é o vigente; o histórico mora nos ADRs e na §2 do canon.
- **Spec sem a linha de ADRs honrados** não aparece no mapa, sem achado novo — o dever de origem já
  é advisório (ADR-015 ponto 2, reafirmado no ADR-018).
- **Produto sem ADR algum** mantém `_(nenhum ADR ainda)_`.

`trace-arquitetura.sh` ganha um argumento `<specs-dir>` para derivar a coluna de specs.

### 3. Bloco de avisos — `zion:narrativa-avisos`

Terceiro bloco derivado, reconciliado pelo mesmo script. Ele **nunca escreve dentro de
`zion:narrativa`** — a prosa do Autor segue intocada, e é isso que sustenta a cláusula nova.

| Achado | Condição |
|---|---|
| `narrativa-superseded` | ADR citado na âncora tem `Status: Substituído por` |
| `narrativa-defasada` | existem ADRs aceitos fora da âncora (lista quais) |
| em dia | bloco vira `_(narrativa em dia)_` |

### 4. Rota do dia 2 — `/zion-prd-evolve`

A Fase 2/3 ganha uma rota ao lado das existentes:
**Narrativa defasada (C1/C2/C3) → `/zion-prd-decompose --narrativa`**.

### 5. Ponte do plan — `/zion-prd-plan-prompt`

Passa a extrair a narrativa pelo marcador `zion:narrativa` (conteúdo, sem os marcadores) mais a §2,
em vez de raspar prosa da §1 inteira, e ecoa os avisos de defasagem quando existirem. `RF-08` fica
textualmente intacto: a promessa era a mesma, só passa a ser cumprida.

## Fronteira e regra de corte instalada

A regra de corte §1 × plan entra na §4 do ADR-018 **e** no bloco de regras do `CLAUDE.md` do
produto (`assets/templates/regras-speckit.md`), o que obriga bump `zion:speckit:v1` → `v2`. O bump é
de graça: `check-arquitetura.sh` já acusa `regras-defasadas` por versão de marcador, e a cura já é
re-rodar `/zion-speckit-install`.

## Verificadores e testes

`check-arquitetura.sh`:

- **sai** `visao-vazia`;
- **entram** `narrativa-ausente` (bloco ausente ou vazio), `ancora-ausente` (prosa presente sem
  `adrs=`), `integracoes-nao-declaradas` (§2 ainda com o placeholder do esqueleto);
- a checagem bidirecional do índice **passa a excluir ADRs substituídos** — senão o sentido
  disco→bloco acusa como fantasma justamente o que o mapa decidiu não mostrar.

`check-adr.sh`: ganha `area-ausente`, advisory.

Fixtures pareadas limpa/suja para cada achado novo, em `test-check-arquitetura.sh`,
`test-check-adr.sh` e `test-trace-arquitetura.sh` (`NFR-04`). O acréscimo ao CI é de fixtures, não
de scripts — `NFR-01` folgado.

## Canonização — mesmo commit

**Zero script novo, zero skill nova, zero fonte nova no `ASSET_MAP`.** O `check-canon.sh` não ganha
tabela nenhuma para cobrar.

- `docs/prd.md` — `RF-03` (ADR carrega a área), `RF-05` (decompose grava a narrativa da §1–§2),
  `RF-09` (trace reconcilia o mapa e os avisos), `RF-10` (rota do dia 2), `RF-11` (achados novos)
  alterados; §8 passa a citar ADR-018 no lugar do ADR-015; §13 ganha as linhas C2/C3. §12 sem linha
  nova. `RF-08` intacto.
- `docs/architecture.md` — §2 ganha ADR-018 e marca o ADR-015 como substituído. §3 (scripts) e §4
  (assets) inalteradas.
- `docs/adr/` — ADR-018 com `Substitui: ADR-015` + `Status: Substituído por ADR-018` recíproco no
  ADR-015.
- Alterados: `assets/templates/architecture-skeleton.md`, `assets/templates/regras-speckit.md`,
  `skills/zion-adr-new`, `skills/zion-prd-decompose`, `skills/zion-prd-evolve`,
  `skills/zion-prd-plan-prompt` — `sync-assets.sh` regenera os `references/`.

## Fora de escopo

Gerar a §4 (segue derivada como hoje) · cobertura multi-agente da regra instalada · qualquer
reescrita da prosa sem confirmação do Autor · migrar em lote os ADRs existentes para ter `Área:`
(o grupo `Sem área` absorve; a migração é oportunista).

## Riscos

- **A máquina inventa arquitetura** (edge 2) → mitigado pela regra de lastro dura: sem ADR que
  sustente, vira pergunta ao Autor, não prosa.
- **A §1 invade o `plan`** (edge 3) → mitigado pela regra de corte citável, instalada no
  `CLAUDE.md` do produto e reafirmada na §4 do ADR-018.
- **Mais aviso não move o Autor** (edge 20) → mitigado por não ser mais só aviso: o aviso vive no
  artefato que ele lê, e o caminho de correção é uma flag no comando que ele já roda.
- **A âncora fica unilateral quando o Autor edita à mão** → o pior caso é ruído (aviso a mais),
  nunca silêncio.
