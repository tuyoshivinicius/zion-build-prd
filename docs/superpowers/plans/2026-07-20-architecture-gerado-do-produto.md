# `architecture.md` do produto gerado sob ditado e reconciliado (A1+A3) — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fazer o `docs/architecture.md` do produto deixar de ser esqueleto semeado — a §1/§2 passa a nascer sob ditado numa fase final do `/zion-prd-decompose` (com âncora invisível nos ADRs), e a §3 vira um mapa de decisões por área derivado por máquina, com avisos de defasagem reconciliados num bloco adjacente.

**Arquitetura:** Zero script novo, zero skill nova, zero fonte nova no `ASSET_MAP`. Dois scripts existentes ganham capacidade (`trace-arquitetura.sh` reconcilia mais um bloco e enriquece o índice; `check-arquitetura.sh` troca `visao-vazia` por três achados novos), `check-adr.sh` ganha um achado advisório, dois templates mudam (com bump `zion:speckit:v1` → `v2`) e quatro `SKILL.md` ganham prosa. A decisão é registrada no ADR-018, que substitui integralmente o ADR-015.

**Tech Stack:** Bash + awk (POSIX-ish, `set -u`, contrato exit 0/1/2), Markdown, fixtures pareadas em `scripts/fixtures/`, runner `scripts/eval.sh`.

## Global Constraints

- **Fonte única (ADR-001, NFR-03):** `assets/` e alguns `scripts/*.sh` são a fonte; **nunca** edite `skills/*/references/` à mão. Depois de tocar uma fonte, rode `./scripts/sync-assets.sh` antes do `git add` (o pre-commit também roda, mas o commit fica mais limpo).
- **Canonização no mesmo commit (`CLAUDE.md`):** toda mudança de comportamento reflete em `docs/prd.md` e/ou `docs/architecture.md` **no mesmo commit**. O pre-commit roda `./scripts/check-canon.sh` e **bloqueia**.
- **Pre-commit também roda `./scripts/check-adr.sh docs/adr` e bloqueia** — os ADRs deste repo têm de passar em toda alteração do próprio `check-adr.sh`.
- **RN-01 / NFR-05:** nenhum gate no projeto-alvo bloqueia. Todo verificador **aconselha**; exit 1 é conselho lido pela Fase 4 da skill.
- **Contrato de exit dos scripts:** `0` limpo · `1` achados/drift/avisos · `2` erro de uso ou de ambiente.
- **NFR-04:** todo verificador mecânico tem auto-teste com fixture limpa **e** suja. Achado novo ⇒ asserção nova em `scripts/test-*.sh`.
- **NFR-01:** a camada mecânica inteira roda em <60s no CI — o acréscimo aqui é de fixtures, não de scripts.
- **NFR-02:** exatamente 1 dependência externa de skill (`superpowers:brainstorming`). A fase de narrativa **não** delega — é redação sob ditado.
- **Zero comando novo (`RF-19`):** a ajuda segue explicando 12 comandos. A gênese é fase do `/zion-prd-decompose`; a revisão é a flag `--narrativa`.
- **Verificação local (rode antes de cada commit):** `./scripts/check-assets.sh` · `./scripts/check-canon.sh` · `./scripts/eval.sh`.
- **Marcadores canônicos** (strings exatas, usadas por script e por skill):
  - `<!-- zion:narrativa:start adrs=ADR-002,ADR-004 -->` … `<!-- zion:narrativa:end -->` (âncora opcional no atributo `adrs=`, sem espaços)
  - `<!-- zion:narrativa-avisos:start -->` … `<!-- zion:narrativa-avisos:end -->`
  - `<!-- zion:adr-index:start -->` … `<!-- zion:adr-index:end -->` (inalterados)
  - `<!-- zion:backlog-view:start -->` … `<!-- zion:backlog-view:end -->` (inalterados)
  - `<!-- zion:speckit:v2:start -->` … `<!-- zion:speckit:v2:end -->` (bump nesta mudança)
- **Campo novo de ADR:** `- **Área:** <palavra>`, imediatamente **abaixo** da linha `- **Status:**`.
- **Regra de corte citável (copiar verbatim onde o plano pedir):** *se a frase muda ao trocar UMA feature, é `plan`; se muda só ao trocar o produto, é §1.*

---

## File Structure

| Arquivo | Responsabilidade nesta mudança |
|---|---|
| `docs/adr/ADR-018-architecture-gerado-do-produto.md` | **Criar.** A decisão; substitui o ADR-015 integralmente. |
| `docs/adr/ADR-015-integracao-speckit-instalavel.md` | Marcar `Status: Substituído por ADR-018` (simetria). |
| `docs/adr/ADR-0*.md` (todos) | Ganham a linha `- **Área:**` (dogfood; o guard bloqueia sem ela após a Task 2). |
| `docs/architecture.md` | §2: linha do ADR-018 + ADR-015 marcado substituído. §3/§4 inalteradas. |
| `docs/prd.md` | RF-03, RF-05, RF-09, RF-10, RF-11 reescritos; §8 cita ADR-018; §13 ganha uma linha por task. |
| `scripts/check-adr.sh` | Achado `area-ausente` (advisório). |
| `scripts/trace-arquitetura.sh` | §3 vira mapa (área/fixou/specs, substituídos fora); bloco `narrativa-avisos`; argumento `<specs-dir>`. |
| `scripts/check-arquitetura.sh` | Sai `visao-vazia`; entram `narrativa-ausente`, `ancora-ausente`, `integracoes-nao-declaradas`; índice ignora substituídos; `EXPECTED_VERSION=v2`. |
| `scripts/test-check-adr.sh` · `test-trace-arquitetura.sh` · `test-check-arquitetura.sh` | Asserções novas (NFR-04). |
| `scripts/fixtures/adr/**` · `scripts/fixtures/arquitetura/**` | Fixtures pareadas dos achados novos. |
| `assets/templates/architecture-skeleton.md` | §1 com os dois blocos novos; blockquote com a regra de corte. |
| `assets/templates/regras-speckit.md` | Bump `v1`→`v2` + regra de corte §1 × plan. |
| `skills/zion-adr-new/SKILL.md` | Pede a Área no template e no procedimento. |
| `skills/zion-prd-decompose/SKILL.md` | Fase 5 (narrativa) + flag `--narrativa`. |
| `skills/zion-prd-trace/SKILL.md` | Novo argumento do trace + eco dos avisos de narrativa. |
| `skills/zion-prd-evolve/SKILL.md` | Rota de dia 2 para `--narrativa`. |
| `skills/zion-prd-plan-prompt/SKILL.md` | Extração da narrativa pelo marcador + eco dos avisos. |
| `skills/zion-speckit-install/SKILL.md` | Fase 4 aconselha `narrativa-ausente` no lugar de `visao-vazia`. |

---

### Task 1: ADR-018, supersessão do ADR-015 e a Área em todos os ADRs do repo

**Files:**
- Create: `docs/adr/ADR-018-architecture-gerado-do-produto.md`
- Modify: `docs/adr/ADR-015-integracao-speckit-instalavel.md` (linha `- **Status:**`)
- Modify: `docs/adr/ADR-001-*.md` … `docs/adr/ADR-017-*.md` (uma linha nova cada)
- Modify: `docs/architecture.md:26-52` (índice §2)
- Modify: `docs/prd.md:117-124` (§8) e `docs/prd.md` §13
- Test: `scripts/check-adr.sh docs/adr` (simetria) + `scripts/check-canon.sh`

**Interfaces:**
- Consumes: nada (primeira task).
- Produces: o campo `- **Área:** <palavra>` no cabeçalho de todo ADR — a Task 2 passa a cobrá-lo e a Task 3 o consome para agrupar o mapa. O ADR-018 é a decisão citada por todas as tasks seguintes.

- [ ] **Step 1: Criar o ADR-018**

Crie `docs/adr/ADR-018-architecture-gerado-do-produto.md` com exatamente este conteúdo:

```markdown
# ADR-018 — O architecture.md do produto é gerado sob ditado e reconciliado

- **Status:** Aceito
- **Área:** Integração Spec Kit
- **Data:** 2026-07-20
- **Decisores:** autoria do repo
- **Substitui:** ADR-015
- **Evidência:** Decisão dada: o Autor escolheu a composição A1+A3 no estudo `docs/estudos/geracao-do-architecture-do-produto.md` (ADR-006, evidência por decisão dada); o design que a formaliza é `docs/superpowers/specs/2026-07-20-architecture-gerado-do-produto-design.md`.

## Contexto

O ADR-015 fechou o `docs/architecture.md` do produto como documento **semeado**: §1 e §2 são prosa
do Autor "nunca tocada por máquina" (ponto 3), só §3 e §4 derivadas. A dor é comprovada — no
produto conduzido pelo próprio harness, com PRD fechada sobre 10 ADRs e backlog de 19 specs, a §1 e
a §2 seguem com o placeholder literal do esqueleto. A máquina já acusa (`visao-vazia`), o veredito é
advisório (ADR-004, `NFR-05`) e o aviso isolado não moveu o Autor. Enquanto isso a ponte do plan
promete injetar a prosa estrutural (`RF-08`) e injeta vazio.

## Decisão

O documento passa a ser **gerado sob ditado e reconciliado**, compondo duas metades:

1. **Fronteira §1 × plan.** A §1 é **topologia + contratos**: nomeia os componentes de topo e o
   contrato entre eles (quem chama quem, por qual via, quem é dono de qual dado). O interior de cada
   componente é do `plan`. Regra de corte citável: *se a frase muda ao trocar UMA feature, é `plan`;
   se muda só ao trocar o produto, é §1.*
2. **Ditado com lastro.** A §1 e a §2 nascem numa fase final do `/zion-prd-decompose`: a máquina
   redige o rascunho **só sobre o que os ADRs sustentam** — o que não tem lastro vira pergunta ao
   Autor, não prosa — e ele aceita/edita/dita/pula. A prosa **nunca é sobrescrita sem confirmação**;
   é esta cláusula que substitui o "nunca tocada por máquina" do ADR-015.
3. **Âncora invisível.** O marcador de abertura do bloco carrega `adrs=` com os ADRs efetivamente
   usados na redação. Populada pela máquina, zero digitação do Autor, prosa limpa no render.
4. **Mapa no lugar do índice.** A §3 deixa de ser índice plano e vira mapa: decisões agrupadas por
   **área**, com **o que cada uma fixou** e as **specs que a exercitam**. Decisão substituída sai do
   mapa (o mapa é o vigente; o histórico mora nos ADRs). Um dono por pergunta: a §1 responde "como
   conversam", a §3 responde "o que foi decidido e onde vive".
5. **Reconciliação sem invasão.** Um terceiro bloco derivado, adjacente à narrativa, acusa
   supersessão e defasagem da âncora. Ele **nunca escreve dentro da prosa do Autor**; a cura é
   `/zion-prd-decompose --narrativa`, que oferece o rascunho novo sob confirmação.

Reafirmados do ADR-015, sem mudança: a superfície da regra no `CLAUDE.md` entre marcadores
versionados (ponto 1), o dever de origem advisório pela linha `**RF cobertos:**` (ponto 2) e a
fronteira de donos com recorte por passo (ponto 4). Redecidido: o ponto 3.

## Consequências

Zero script novo, zero skill nova, zero fonte nova no `ASSET_MAP`: os dois scripts existentes ganham
capacidade e quatro `SKILL.md` ganham prosa. O bloco de regras do produto sobe para `zion:speckit:v2`
(a cura já existe: `regras-defasadas` → re-rodar `/zion-speckit-install`). Todo ADR passa a carregar
uma **Área** — advisória, com o grupo `Sem área` absorvendo os antigos; a migração em produtos é
oportunista, não big bang. A ponte do plan passa a extrair a narrativa pelo marcador, cumprindo o
`RF-08` que já prometia. Fica fora: gerar a §4, cobertura multi-agente da regra instalada e qualquer
reescrita de prosa sem confirmação do Autor.

## Status

Aceito. Substitui o ADR-015 integralmente.
```

- [ ] **Step 2: Fechar a simetria da supersessão no ADR-015**

Em `docs/adr/ADR-015-integracao-speckit-instalavel.md`, troque a linha de status do cabeçalho:

```markdown
- **Status:** Substituído por ADR-018
```

E, na seção `## Status` do fim do arquivo, troque `Aceito.` por:

```markdown
Substituído por ADR-018 (o ponto 3 — prosa nunca tocada por máquina — foi redecidido; os pontos 1, 2
e 4 seguem valendo, reafirmados no ADR-018).
```

- [ ] **Step 3: Verificar que a simetria fecha**

Run: `./scripts/check-adr.sh docs/adr`
Expected: `check-adr: limpo` (exit 0). Se sair `supersessao-assimetrica`, o `Substitui:` do ADR-018 ou o `Status:` do ADR-015 está com typo.

- [ ] **Step 4: Adicionar a Área a todos os ADRs do repo**

Em cada arquivo, insira a linha `- **Área:** <valor>` **imediatamente abaixo** da linha `- **Status:**`. Use exatamente estes valores (o ADR-018 já nasceu com a dele):

| Arquivo | Área |
|---|---|
| `ADR-001-assets-fonte-unica.md` | Distribuição |
| `ADR-002-distribuicao-dual.md` | Distribuição |
| `ADR-003-prefixo-zion-skills.md` | Distribuição |
| `ADR-004-verificadores-aconselham.md` | Verificação |
| `ADR-005-pontes-spec-kit-prosa.md` | Integração Spec Kit |
| `ADR-006-evidencia-por-risco.md` | Governança |
| `ADR-007-contrato-superpowers.md` | Delegação |
| `ADR-008-avaliacao-duas-camadas.md` | Verificação |
| `ADR-009-unidade-spec.md` | Governança |
| `ADR-010-governanca-canon.md` | Governança |
| `ADR-011-adrs-canonicos.md` | Governança |
| `ADR-012-estagio-0-estudo-pre-discovery.md` | Jornada |
| `ADR-013-estudo-workflow-adaptativo.md` | Jornada |
| `ADR-014-experiencia-nfr-carregado.md` | Jornada |
| `ADR-015-integracao-speckit-instalavel.md` | Integração Spec Kit |
| `ADR-016-skill-ajuda-grounding-vivo.md` | Jornada |
| `ADR-017-delegacao-criativa-classificada.md` | Delegação |

- [ ] **Step 5: Conferir que nenhum ADR ficou sem a linha**

Run: `for f in docs/adr/ADR-*.md; do grep -q '^- \*\*Área:\*\* .' "$f" || echo "SEM ÁREA: $f"; done`
Expected: nenhuma saída.

- [ ] **Step 6: Canonizar — índice §2 do `docs/architecture.md`**

Em `docs/architecture.md`, na tabela da §2, troque a linha do ADR-015 e acrescente a do ADR-018 no fim da tabela:

```markdown
| [ADR-015](adr/ADR-015-integracao-speckit-instalavel.md) | _(substituído por ADR-018)_ Integração instalável com o Spec Kit: regras versionadas no `CLAUDE.md` do produto, `architecture.md` distribuído e autoridade advisória com guard opt-in. |
| [ADR-016](adr/ADR-016-skill-ajuda-grounding-vivo.md) | Skill de ajuda conversacional com grounding vivo nas `SKILL.md` irmãs, sem artefato gravado, avaliada só na camada de julgamento, com o envelhecimento das citações cobrado por C8 no `check-canon.sh`. |
| [ADR-017](adr/ADR-017-delegacao-criativa-classificada.md) | A delegação criativa classifica cada tensão (diagnóstica/propositiva) numa rubrica de fonte única e gateia o prompt montado por `check-delegacao.sh`, sem tocar o contrato externo C1–C3. |
| [ADR-018](adr/ADR-018-architecture-gerado-do-produto.md) | O `architecture.md` do produto é gerado sob ditado (§1–§2 na fase final do decompose, com âncora nos ADRs) e reconciliado (§3 vira mapa por área; avisos de defasagem em bloco adjacente); substitui o ADR-015. |
```

- [ ] **Step 7: Canonizar — §8 da PRD**

Em `docs/prd.md` §8, acrescente ao fim do parágrafo (antes do ponto final da enumeração), de modo que o texto termine assim:

```markdown
(ADR-004), o contrato de capacidades com o executor externo de brainstorming (ADR-007) e a skill de
estudo workflow-adaptativa por persona (ADR-013), a classificação diagnóstica×propositiva na
delegação criativa ao brainstorming (ADR-017) e o documento de arquitetura do produto gerado sob
ditado e reconciliado (ADR-018).
```

- [ ] **Step 8: Canonizar — linha de §13**

Acrescente ao fim da tabela da §13 de `docs/prd.md`:

```markdown
| 2026-07-20 | C3 | Decisão revertida: o `architecture.md` do produto deixa de ser prosa "nunca tocada por máquina" e passa a nascer sob ditado com âncora nos ADRs | o placeholder do esqueleto atravessou uma jornada inteira intacto e a ponte do plan injetava vazio | ADR-018 substitui ADR-015 · docs/architecture.md §2 · docs/prd.md §8 |
```

- [ ] **Step 9: Rodar a verificação completa**

Run: `./scripts/check-adr.sh docs/adr && ./scripts/check-canon.sh && ./scripts/eval.sh`
Expected: `check-adr: limpo`, `check-canon: limpo` (ou a mensagem de sucesso equivalente) e `eval: tudo verde`.

- [ ] **Step 10: Commit**

```bash
git add docs/adr docs/architecture.md docs/prd.md
git commit -m "docs(canon): ADR-018 substitui o ADR-015 e todo ADR passa a carregar Área"
```

---

### Task 2: `area-ausente` no `check-adr.sh` e a Área pedida pelo `/zion-adr-new`

**Files:**
- Modify: `scripts/check-adr.sh` (novo achado)
- Modify: `scripts/test-check-adr.sh` (asserções)
- Modify: `scripts/fixtures/adr/clean/ADR-001-motor.md`, `ADR-002-persistencia.md`, `ADR-003-decisao-dada.md`
- Modify: `scripts/fixtures/adr/superseded-clean/ADR-002-motor-raster.md`, `ADR-005-motor-vetor.md`
- Modify: `skills/zion-adr-new/SKILL.md`
- Modify: `docs/prd.md` (RF-03 + §13)
- Test: `scripts/test-check-adr.sh`

**Interfaces:**
- Consumes: o campo `- **Área:** <palavra>` já presente em todo ADR deste repo (Task 1).
- Produces: o achado `area-ausente` (advisório, conta no exit 1 como qualquer outro achado do `check-adr.sh`) e a garantia de que ADRs novos nascem com Área — insumo do mapa da Task 3.

- [ ] **Step 1: Escrever as asserções que falham**

Em `scripts/test-check-adr.sh`, acrescente uma asserção ao bloco 2 (fixture dirty), logo depois da linha do `decisao-dada-sem-racional`:

```bash
assert_contains "dirty acha area-ausente"             "area-ausente" "$out"
```

E, logo depois do bloco 1 (fixture clean), acrescente:

```bash
assert_contains "clean não acusa area-ausente" "check-adr: limpo" "$out"
```

- [ ] **Step 2: Rodar e ver falhar**

Run: `bash scripts/test-check-adr.sh`
Expected: FALHOU — `FALHOU: dirty acha area-ausente (não achou: area-ausente)`.

- [ ] **Step 3: Dar Área às fixtures limpas**

Em cada um dos cinco arquivos (`scripts/fixtures/adr/clean/ADR-001-motor.md`, `ADR-002-persistencia.md`, `ADR-003-decisao-dada.md`, `scripts/fixtures/adr/superseded-clean/ADR-002-motor-raster.md`, `ADR-005-motor-vetor.md`), insira abaixo da linha `- **Status:**`:

```markdown
- **Área:** Motor
```

As fixtures de `scripts/fixtures/adr/dirty/` e `superseded-dirty/` **ficam sem Área** de propósito — é a fixture suja do achado novo.

- [ ] **Step 4: Implementar o achado no `check-adr.sh`**

Em `scripts/check-adr.sh`, logo abaixo da função `evidence_value()` (linha ~32), acrescente:

```bash
# Valor da primeira linha `- **Área:**`, sem o rótulo (ADR-018). A área agrupa o mapa da §3 do
# architecture.md do produto; ausente, o ADR cai no grupo "Sem área" — o achado é conselho.
area_value() {  # $1 arquivo
  sed -n 's/^[[:space:]]*-[[:space:]]*\*\*Área:\*\*[[:space:]]*//p' "$1" | head -1 | sed 's/[[:space:]]*$//'
}
```

Dentro do primeiro laço `for f in "$DIR"/ADR-*.md`, logo depois de `ev="$(printf '%s' "$ev" | sed 's/[[:space:]]*$//')"`, acrescente:

```bash
  # Área ausente/placeholder → advisório: o ADR ainda entra no mapa, no grupo "Sem área".
  ar="$(area_value "$f")"
  if [ -z "$ar" ] || printf '%s' "$ar" | grep -qE '^<.*>$'; then
    add "$label: area-ausente — sem linha **Área:** (o ADR cai no grupo \"Sem área\" do mapa da §3; conselho, não trava)"
  fi
```

Atualize também o comentário-cabeçalho do script, acrescentando ao bloco numerado:

```bash
#   5. sem linha **Área:** preenchida → area-ausente (advisório; agrupa o mapa da §3 do produto)
```

- [ ] **Step 5: Rodar e ver passar**

Run: `bash scripts/test-check-adr.sh`
Expected: `test-check-adr: tudo verde`.

- [ ] **Step 6: Confirmar que o próprio repo continua limpo**

Run: `./scripts/check-adr.sh docs/adr`
Expected: `check-adr: limpo` (a Task 1 já deu Área a todos).

- [ ] **Step 7: Pedir a Área no `/zion-adr-new`**

Em `skills/zion-adr-new/SKILL.md`, no **Template do arquivo gerado**, acrescente a linha logo abaixo de `- **Status:** Proposto`:

```markdown
- **Área:** <uma palavra: o assunto que a decisão governa — ex.: Persistência, Compilação, Distribuição>
```

E, no **Procedimento**, troque o passo 4 por:

```markdown
4. **Crie o arquivo** `docs/adr/ADR-<n>-<slug>.md` com o conteúdo do template abaixo,
   substituindo `<n>`, `<slug>` e `<título>` pelos valores reais. Deixe `Status: Proposto`
   até a decisão ser aceita; então atualize para `Aceito`. **Preencha a `Área`** — uma palavra que
   nomeia o assunto governado pela decisão (reuse uma área já usada por outro ADR do produto quando
   couber; áreas novas são baratas). É por ela que o mapa da §3 do `docs/architecture.md` agrupa as
   decisões (ADR-018). Área ausente não trava nada: o ADR cai no grupo `Sem área`, no fim do mapa, e
   o `check-adr.sh` acusa `area-ausente` como conselho.
```

- [ ] **Step 8: Canonizar — RF-03 e §13**

Em `docs/prd.md` §6, troque o texto do `RF-03` por:

```markdown
`RF-03` O
  autor registra cada decisão como ADR com contexto, decisão e consequências — inclusive
  substituindo um ADR anterior com referência simétrica —, classificando-a numa área que agrupa o
  mapa de decisões do produto.
```

Acrescente ao fim da tabela da §13:

```markdown
| 2026-07-20 | C2 | `RF-03` alterado: todo ADR carrega uma **área**, que agrupa o mapa de decisões da §3 do documento de arquitetura | o índice plano não respondia "o que foi decidido sobre este assunto" na reorientação meses depois | ADR-018 · skills/zion-adr-new · scripts/check-adr.sh |
```

- [ ] **Step 9: Sincronizar derivados e verificar tudo**

Run: `./scripts/sync-assets.sh && ./scripts/check-assets.sh && ./scripts/check-canon.sh && ./scripts/eval.sh`
Expected: sem drift, `check-canon` limpo, `eval: tudo verde`.

- [ ] **Step 10: Commit**

```bash
git add scripts/check-adr.sh scripts/test-check-adr.sh scripts/fixtures/adr skills docs/prd.md
git commit -m "feat(adr): area-ausente advisório e Área pedida pelo /zion-adr-new"
```

---

### Task 3: A §3 vira mapa — `trace-arquitetura.sh` com área, "fixou" e specs

**Files:**
- Modify: `scripts/trace-arquitetura.sh`
- Modify: `scripts/check-arquitetura.sh` (índice ignora ADR substituído no sentido disco→bloco)
- Modify: `scripts/test-trace-arquitetura.sh`
- Modify: `scripts/fixtures/arquitetura/trace/adr/ADR-001-banco-unico.md`, `ADR-002-fila-simples.md`
- Create: `scripts/fixtures/arquitetura/trace/adr/ADR-003-sem-area.md`, `ADR-004-motor-antigo.md`
- Create: `scripts/fixtures/arquitetura/trace/specs/001-walking-skeleton/spec.md`, `scripts/fixtures/arquitetura/trace/specs/002-historico/spec.md`
- Modify: `scripts/fixtures/arquitetura/clean/docs/architecture.md` (formato novo do bloco)
- Modify: `scripts/fixtures/arquitetura/clean/docs/adr/ADR-001-banco-unico.md`
- Modify: `docs/prd.md` (RF-09 + §13)
- Test: `scripts/test-trace-arquitetura.sh`, `scripts/test-check-arquitetura.sh`

**Interfaces:**
- Consumes: `- **Área:** <palavra>` (Task 1/2); a linha `**ADRs honrados:** ADR-002, ADR-007` do `spec.md` de cada spec (gêmea de `**RF cobertos:**`).
- Produces: `trace-arquitetura.sh <arquitetura> <adr-dir> <backlog-file> [<specs-dir>] [--check]` — o 4º posicional é opcional e, ausente, o mapa sai sem a parte `· specs:`. As funções `adr_field()`, `adr_superseded()` e `block_content()` ficam disponíveis no script para a Task 5 usar.

- [ ] **Step 1: Preparar as fixtures do mapa**

Em `scripts/fixtures/arquitetura/trace/adr/ADR-001-banco-unico.md`, insira abaixo do `- **Status:**`:

```markdown
- **Área:** Persistência
```

Em `scripts/fixtures/arquitetura/trace/adr/ADR-002-fila-simples.md`, insira abaixo do `- **Status:**`:

```markdown
- **Área:** Fluxo
```

Crie `scripts/fixtures/arquitetura/trace/adr/ADR-003-sem-area.md`:

```markdown
# ADR-003 — Sem área declarada

- **Status:** Aceito
- **Data:** 2026-07-20
- **Evidência:** Decisão dada: racional registrado (fixture).

## Contexto

Fixture de teste: ADR sem a linha de Área, para exercitar o grupo "Sem área".

## Decisão

Este ADR não declara área.

## Consequências

Nenhuma.
```

Crie `scripts/fixtures/arquitetura/trace/adr/ADR-004-motor-antigo.md` (a simetria não é exercitada aqui — o `trace` não a verifica):

```markdown
# ADR-004 — Motor antigo

- **Status:** Substituído por ADR-002
- **Área:** Fluxo
- **Data:** 2026-07-20
- **Evidência:** Decisão dada: racional registrado (fixture).

## Contexto

Fixture de teste: decisão substituída, que o mapa não deve mostrar.

## Decisão

Motor antigo, hoje aposentado.

## Consequências

Nenhuma.
```

Crie `scripts/fixtures/arquitetura/trace/specs/001-walking-skeleton/spec.md`:

```markdown
# Spec — walking skeleton (fixture)

**RF cobertos:** RF-01
**ADRs honrados:** ADR-001

Fixture: spec que exercita a decisão de persistência.
```

Crie `scripts/fixtures/arquitetura/trace/specs/002-historico/spec.md`:

```markdown
# Spec — histórico (fixture)

**RF cobertos:** RF-02
**ADRs honrados:** ADR-001, ADR-002

Fixture: spec que exercita persistência e fluxo.
```

- [ ] **Step 2: Escrever as asserções que falham**

Em `scripts/test-trace-arquitetura.sh`, substitua o bloco 1 inteiro (as linhas de `# 1. Reconciliação` até `assert_file_not_re "conteúdo velho dos blocos substituído" ...`) por:

```bash
# 1. Reconciliação: mapa agrupado por área, prosa intacta.
arch="$(fresh "$FIX/architecture.md")"
out="$(bash "$TRACE" "$arch" "$FIX/adr" "$FIX/backlog.md" "$FIX/specs")"; rc=$?
assert_exit "reconciliação sai 0" 0 "$rc"
assert_file_re "mapa abre o grupo da área do ADR-001" "$arch" '^### Persistência$'
assert_file_re "mapa abre o grupo da área do ADR-002" "$arch" '^### Fluxo$'
assert_file_re "mapa tem o grupo Sem área" "$arch" '^### Sem área$'
assert_file_re "mapa linka o ADR-001 em negrito" "$arch" '^- \*\*\[ADR-001 — Banco único\]\(adr/ADR-001-banco-unico\.md\)\*\*$'
assert_file_re "mapa traz o que o ADR-001 fixou" "$arch" '^  fixou: Um banco único\.'
assert_file_re "mapa traz as specs do ADR-001" "$arch" 'specs: `001-walking-skeleton`, `002-historico`'
assert_file_re "mapa traz as specs do ADR-002" "$arch" 'specs: `002-historico`'
assert_file_not_re "ADR substituído sai do mapa" "$arch" 'ADR-004-motor-antigo\.md'
assert_file_re "rodapé conta as substituídas" "$arch" '1 decisão\(ões\) substituída\(s\)'
assert_file_re "visão ganha walking-skeleton com status" "$arch" 'walking-skeleton.*implementada'
assert_file_re "visão ganha historico pendente" "$arch" 'historico.*pendente'
assert_file_re "prosa do Autor preservada" "$arch" 'Prosa que o reconciliador nunca toca'
assert_file_not_re "conteúdo velho dos blocos substituído" "$arch" 'conteúdo velho'
```

E, nos blocos 2, 3 e 4 do mesmo arquivo, acrescente `"$FIX/specs"` como quarto argumento em cada chamada do `$TRACE` (as três chamadas que hoje passam `"$FIX/adr" "$FIX/backlog.md"` — mantenha o `--check` sempre por último). Acrescente ainda, no fim do arquivo, antes do veredito:

```bash
# 10. Ordem estável das áreas: Persistência (ADR-001) antes de Fluxo (ADR-002); "Sem área" por último.
arch="$(fresh "$FIX/architecture.md")"
bash "$TRACE" "$arch" "$FIX/adr" "$FIX/backlog.md" "$FIX/specs" >/dev/null 2>&1
ordem="$(grep -n '^### ' "$arch" | sed 's/:.*### /:/' | tr '\n' ' ')"
case "$ordem" in
  *Persistência*Fluxo*Sem\ área*) echo "ok: ordem das áreas estável" ;;
  *) echo "FALHOU: ordem das áreas inesperada ($ordem)"; fail=1 ;;
esac
rm -f "$arch"

# 11. Sem specs-dir → mapa sai sem a parte de specs, e nada quebra.
arch="$(fresh "$FIX/architecture.md")"
out="$(bash "$TRACE" "$arch" "$FIX/adr" "$FIX/backlog.md")"; rc=$?
assert_exit "sem specs-dir sai 0" 0 "$rc"
assert_file_re "sem specs-dir ainda traz o fixou" "$arch" '^  fixou: Um banco único\.'
assert_file_not_re "sem specs-dir não inventa specs" "$arch" 'specs: `'
rm -f "$arch"
```

- [ ] **Step 3: Rodar e ver falhar**

Run: `bash scripts/test-trace-arquitetura.sh`
Expected: FALHOU — `FALHOU: mapa abre o grupo da área do ADR-001 (regex não casou: ^### Persistência$)`.

- [ ] **Step 4: Implementar o mapa no `trace-arquitetura.sh`**

Troque o cabeçalho de uso (linhas 5–11) por:

```bash
# Uso:
#   trace-arquitetura.sh <arquitetura> <adr-dir> <backlog-file> [<specs-dir>] [--check]
#     <adr-dir> sem ADRs     → índice "_(nenhum ADR ainda)_".
#     <backlog-file> ausente → visão "_(sem backlog ainda)_".
#     <specs-dir> ausente    → o mapa sai sem a coluna de specs (derivação best-effort).
#     --check → não grava; reporta drift/avisos e sai 1.
```

Troque o parser de argumentos (o bloco `ARCH=""; ADR_DIR=""; ...` até o `usage` final) por:

```bash
usage() { echo "uso: trace-arquitetura.sh <arquitetura> <adr-dir> <backlog-file> [<specs-dir>] [--check]" >&2; exit 2; }

ARCH=""; ADR_DIR=""; BACKLOG=""; SPECS_DIR=""; MODE_CHECK=0
for a in "$@"; do
  case "$a" in
    --check) MODE_CHECK=1 ;;
    -*) usage ;;
    *) if [ -z "$ARCH" ]; then ARCH="$a"
       elif [ -z "$ADR_DIR" ]; then ADR_DIR="$a"
       elif [ -z "$BACKLOG" ]; then BACKLOG="$a"
       elif [ -z "$SPECS_DIR" ]; then SPECS_DIR="$a"
       else usage; fi ;;
  esac
done
```

Troque a função `build_adr_index()` inteira (linhas 31–42 do original) por estes helpers + a nova construção:

```bash
# --- Leitura de metadados do ADR (rótulos do template do /zion-adr-new). ---
adr_field() {  # $1 arquivo  $2 rótulo (Status, Área, …) → valor da 1ª ocorrência, trimado
  sed -n "s/^[[:space:]]*-[[:space:]]*\*\*$2:\*\*[[:space:]]*//p" "$1" | head -1 | sed 's/[[:space:]]*$//'
}
adr_superseded() {  # $1 arquivo → 0 (verdadeiro) se o Status declara supersessão
  adr_field "$1" Status | grep -qiE 'Substitu[ií]do por'
}
adr_title() {  # $1 arquivo → título do 1º "# ", ou o basename
  local t; t="$(sed -n '/^# /{s/^# //;p;q;}' "$1")"
  [ -n "$t" ] || t="$(basename "$1" .md)"
  printf '%s' "$t"
}
adr_fixou() {  # $1 arquivo → 1ª linha não-vazia da seção "## Decisão" (derivação best-effort)
  awk '/^## Decisão/ { ins=1; next } ins && /^## / { exit } ins && NF { print; exit }' "$1"
}
adr_specs() {  # $1 id (ADR-002) → "`slug`, `slug`" das specs que o honram, ou vazio
  [ -n "$SPECS_DIR" ] && [ -d "$SPECS_DIR" ] || return 0
  local d slug out=""
  for d in "$SPECS_DIR"/*/; do
    [ -f "$d/spec.md" ] || continue
    sed -n 's/^[[:space:]]*\*\*ADRs honrados:\*\*[[:space:]]*//p' "$d/spec.md" \
      | grep -qE "(^|[^0-9A-Za-z-])$1([^0-9]|$)" || continue
    slug="$(basename "$d")"
    if [ -z "$out" ]; then out="\`$slug\`"; else out="$out, \`$slug\`"; fi
  done
  printf '%s' "$out"
}

# --- Mapa de decisões (§3): decisões VIGENTES agrupadas por área (ADR-018).
#     Área ausente → grupo "Sem área", sempre por último. Substituída sai do mapa e vira rodapé.
build_adr_index() {
  local f id num area title fixou specs tsv nfiles=0 sup=0
  tsv="$(mktemp)"
  for f in "$ADR_DIR"/ADR-*.md; do
    [ -f "$f" ] || continue
    nfiles=$((nfiles+1))
    if adr_superseded "$f"; then sup=$((sup+1)); continue; fi
    id="$(basename "$f" | grep -oE '^ADR-[0-9]+')"
    num="$(printf '%s' "$id" | grep -oE '[0-9]+' | sed 's/^0*//')"
    [ -n "$num" ] || num=0
    area="$(adr_field "$f" 'Área')"
    case "$area" in ''|'<'*'>') area='Sem área' ;; esac
    title="$(adr_title "$f")"
    fixou="$(adr_fixou "$f")"
    specs="$(adr_specs "$id")"
    printf '%s\t%s\t%s\t%s\t%s\t%s\n' \
      "$area" "$num" "$title" "$(basename "$ADR_DIR")/$(basename "$f")" "$fixou" "$specs" >> "$tsv"
  done

  if [ "$nfiles" -eq 0 ]; then
    printf -- '_(nenhum ADR ainda)_\n'; rm -f "$tsv"; return
  fi
  if [ ! -s "$tsv" ]; then
    printf -- '_(nenhuma decisão vigente)_\n'
  else
    awk -F'\t' '
      { a=$1
        if (!(a in minnum) || $2+0 < minnum[a]) minnum[a]=$2+0
        rows[a]=rows[a] $0 "\n" }
      END {
        n=0; for (a in minnum) order[++n]=a
        # áreas pelo menor ADR-n que contêm; "Sem área" sempre por último
        for (i=1;i<=n;i++) for (j=i+1;j<=n;j++) {
          ai=order[i]; aj=order[j]
          ki=(ai=="Sem área")?999999:minnum[ai]
          kj=(aj=="Sem área")?999999:minnum[aj]
          if (kj<ki) { order[i]=aj; order[j]=ai }
        }
        for (i=1;i<=n;i++) {
          a=order[i]; printf "### %s\n", a
          m=split(rows[a], rr, "\n"); cnt=0
          for (k=1;k<=m;k++) if (rr[k]!="") arr[++cnt]=rr[k]
          for (x=1;x<=cnt;x++) for (y=x+1;y<=cnt;y++) {
            split(arr[x],cx,"\t"); split(arr[y],cy,"\t")
            if (cy[2]+0 < cx[2]+0) { t=arr[x]; arr[x]=arr[y]; arr[y]=t }
          }
          for (x=1;x<=cnt;x++) {
            split(arr[x], c, "\t")
            printf "- **[%s](%s)**\n", c[3], c[4]
            det=""
            if (c[5] != "") det = "fixou: " c[5]
            if (c[6] != "") det = (det=="" ? "specs: " c[6] : det " · specs: " c[6])
            if (det != "") printf "  %s\n", det
          }
          for (x=1;x<=cnt;x++) delete arr[x]
        }
      }
    ' "$tsv"
  fi
  [ "$sup" -gt 0 ] && printf -- '_(%d decisão(ões) substituída(s) — veja `%s/`)_\n' "$sup" "$(basename "$ADR_DIR")"
  rm -f "$tsv"
  return 0
}
```

- [ ] **Step 5: Rodar e ver passar**

Run: `bash scripts/test-trace-arquitetura.sh`
Expected: `test-trace-arquitetura: tudo verde`.

- [ ] **Step 6: Escrever a asserção do índice que ignora ADR substituído**

Em `scripts/test-check-arquitetura.sh`, acrescente no fim (antes do veredito):

```bash
# 6. ADR substituído no disco não é cobrado como ausente do bloco (o mapa é o vigente).
sup="$(mktemp -d)"; mkdir -p "$sup/docs/adr"
cp "$FIX/clean/CLAUDE.md" "$sup/CLAUDE.md"
cp "$FIX/clean/docs/architecture.md" "$sup/docs/architecture.md"
cp "$FIX/clean/docs/backlog.md" "$sup/docs/backlog.md"
cp "$FIX/clean/docs/adr/ADR-001-banco-unico.md" "$sup/docs/adr/"
cat > "$sup/docs/adr/ADR-009-aposentado.md" <<'EOF'
# ADR-009 — Aposentado

- **Status:** Substituído por ADR-001
- **Área:** Persistência
- **Data:** 2026-07-20
- **Evidência:** Decisão dada: racional registrado (fixture).

## Decisão

Decisão aposentada.
EOF
out="$(bash "$CHECK" "$sup")"; rc=$?
assert_exit "ADR substituído fora do bloco não acusa" 0 "$rc"
assert_not_contains "não acusa o substituído como defasado" "ADR-009" "$out"
rm -rf "$sup"
```

- [ ] **Step 7: Rodar e ver falhar**

Run: `bash scripts/test-check-arquitetura.sh`
Expected: FALHOU — `FALHOU: ADR substituído fora do bloco não acusa (exit esperado 0, veio 1)`.

- [ ] **Step 8: Excluir os substituídos do sentido disco→bloco**

Em `scripts/check-arquitetura.sh`, dentro de `check_adr_index()`, logo depois de `base="$(basename "$f")"`, acrescente:

```bash
    # Decisão substituída sai do mapa por decisão (ADR-018): não é fantasma, é histórico.
    grep -qE '^[[:space:]]*-[[:space:]]*\*\*Status:\*\*.*Substitu[ií]do por' "$f" && continue
```

Atualize também o comentário da função:

```bash
# 3. Índice de ADRs (bloco zion:adr-index) em dia com docs/adr/ — nos dois sentidos.
#    ADR substituído é ignorado no sentido disco→bloco (o mapa é o vigente — ADR-018).
#    docs/adr/ ausente não engole o sentido bloco→disco: citação vira fantasma e é acusada.
```

- [ ] **Step 9: Atualizar a fixture limpa do check para o formato do mapa**

Em `scripts/fixtures/arquitetura/clean/docs/adr/ADR-001-banco-unico.md`, insira abaixo do `- **Status:**`:

```markdown
- **Área:** Persistência
```

Em `scripts/fixtures/arquitetura/clean/docs/architecture.md`, troque o conteúdo do bloco `zion:adr-index` por:

```markdown
<!-- zion:adr-index:start -->
### Persistência
- **[ADR-001 — Banco único](adr/ADR-001-banco-unico.md)**
  fixou: Um banco único.
<!-- zion:adr-index:end -->
```

- [ ] **Step 10: Rodar e ver passar**

Run: `bash scripts/test-check-arquitetura.sh && bash scripts/test-trace-arquitetura.sh`
Expected: `test-check-arquitetura: tudo verde` e `test-trace-arquitetura: tudo verde`.

- [ ] **Step 11: Canonizar — RF-09 e §13**

Em `docs/prd.md` §6, troque o texto do `RF-09` por:

```markdown
- **Épico E3 — Rastreabilidade:** `RF-09` O autor reconcilia a qualquer momento a tabela de
  rastreabilidade e o backlog a partir das specs existentes, vendo RF órfão, spec intraçável e RF
  descoberto — e reconcilia junto os blocos derivados do documento de arquitetura do produto: o
  mapa de decisões vigentes agrupado por área, com o que cada uma fixou e as specs que a exercitam,
  a visão do backlog e os avisos de defasagem da narrativa estrutural.
```

Acrescente ao fim da tabela da §13:

```markdown
| 2026-07-20 | C2 | `RF-09` alterado: o índice de decisões vira **mapa** por área (o que fixou + specs que exercitam), sem as substituídas | reorientação meses depois pergunta "o que foi decidido sobre isto e onde vive no código" — o índice plano não respondia | ADR-018 · scripts/trace-arquitetura.sh · scripts/check-arquitetura.sh |
```

- [ ] **Step 12: Verificar tudo e commitar**

Run: `./scripts/sync-assets.sh && ./scripts/check-assets.sh && ./scripts/check-canon.sh && ./scripts/eval.sh`
Expected: sem drift, canon limpo, `eval: tudo verde`.

```bash
git add scripts docs/prd.md skills
git commit -m "feat(arquitetura): a §3 vira mapa de decisões por área com fixou e specs"
```

---

### Task 4: Os achados da narrativa no `check-arquitetura.sh` e o esqueleto novo

**Files:**
- Modify: `scripts/check-arquitetura.sh` (sai `visao-vazia`; entram três achados; `EXPECTED_VERSION=v2`)
- Modify: `scripts/test-check-arquitetura.sh`
- Modify: `scripts/fixtures/arquitetura/clean/docs/architecture.md`
- Modify: `scripts/fixtures/arquitetura/clean/CLAUDE.md`
- Modify: `scripts/fixtures/arquitetura/dirty/docs/architecture.md`
- Modify: `assets/templates/architecture-skeleton.md`
- Modify: `assets/templates/regras-speckit.md`
- Modify: `skills/zion-speckit-install/SKILL.md`
- Modify: `docs/prd.md` (RF-11 + §13)
- Test: `scripts/test-check-arquitetura.sh`

**Interfaces:**
- Consumes: o bloco `zion:narrativa` com âncora `adrs=` (produzido pela Task 6) e o bloco `zion:narrativa-avisos` (reconciliado pela Task 5) — aqui só a **verificação** deles entra.
- Produces: os achados `narrativa-ausente`, `ancora-ausente`, `integracoes-nao-declaradas`; a função `block_content()` passa a casar marcador de abertura **por prefixo** (para acomodar o atributo `adrs=`); `EXPECTED_VERSION="v2"`, pareado com `<!-- zion:speckit:v2:start -->` em `assets/templates/regras-speckit.md`.

- [ ] **Step 1: Escrever as asserções que falham**

Em `scripts/test-check-arquitetura.sh`, no bloco 2 (fixture dirty), troque a linha `assert_contains "acha visao-vazia" "visao-vazia" "$out"` por:

```bash
assert_contains "acha narrativa-ausente" "narrativa-ausente" "$out"
assert_contains "acha integracoes-nao-declaradas" "integracoes-nao-declaradas" "$out"
```

E acrescente no fim do arquivo (antes do veredito):

```bash
# 7. Narrativa com prosa mas sem adrs= no marcador → ancora-ausente (e nada de narrativa-ausente).
semanc="$(mktemp -d)"; mkdir -p "$semanc/docs/adr"
cp "$FIX/clean/CLAUDE.md" "$semanc/CLAUDE.md"
cp "$FIX/clean/docs/backlog.md" "$semanc/docs/backlog.md"
cp "$FIX/clean/docs/adr/ADR-001-banco-unico.md" "$semanc/docs/adr/"
sed 's/<!-- zion:narrativa:start adrs=[^>]*-->/<!-- zion:narrativa:start -->/' \
  "$FIX/clean/docs/architecture.md" > "$semanc/docs/architecture.md"
out="$(bash "$CHECK" "$semanc")"; rc=$?
assert_exit "narrativa sem âncora sai 1" 1 "$rc"
assert_contains "acha ancora-ausente" "ancora-ausente" "$out"
assert_not_contains "não confunde com narrativa-ausente" "narrativa-ausente" "$out"
rm -rf "$semanc"

# 8. visao-vazia foi aposentado (ADR-018) — nunca mais aparece.
out="$(bash "$CHECK" "$FIX/dirty")"
assert_not_contains "visao-vazia aposentado" "visao-vazia" "$out"
```

- [ ] **Step 2: Rodar e ver falhar**

Run: `bash scripts/test-check-arquitetura.sh`
Expected: FALHOU — `FALHOU: acha narrativa-ausente (não achou: narrativa-ausente)`.

- [ ] **Step 3: Atualizar as fixtures**

Em `scripts/fixtures/arquitetura/clean/docs/architecture.md`, troque as §1 e §2 por:

```markdown
## 1. Visão geral

<!-- zion:narrativa-avisos:start -->
_(narrativa em dia)_
<!-- zion:narrativa-avisos:end -->

<!-- zion:narrativa:start adrs=ADR-001 -->
O produto tem um **Recebedor** (entrada de pedidos) e um **Registro** (persistência). O Recebedor
nunca escreve no disco: entrega o pedido ao Registro, dono único do dado gravado.
<!-- zion:narrativa:end -->

## 2. Integrações externas

_(nenhuma integração externa)_
```

Em `scripts/fixtures/arquitetura/clean/CLAUDE.md`, troque os dois marcadores de `v1` para `v2`:

```markdown
<!-- zion:speckit:v2:start -->
Regras instaladas (conteúdo de fixture; a versão no marcador é o que o check compara).
<!-- zion:speckit:v2:end -->
```

Substitua `scripts/fixtures/arquitetura/dirty/docs/architecture.md` inteiro por (note: **sem** o cabeçalho `## 4. Visão do backlog` — é ele que dispara `secao-ausente` agora; a §1 não tem bloco de narrativa; a §2 mantém o placeholder do esqueleto):

```markdown
# Arquitetura — Produto Fixture

## 1. Visão geral

_(prosa do Autor ainda não escrita)_

## 2. Integrações externas

_(prosa do Autor: contratos com o mundo de fora — serviços consumidos, eventos, protocolos)_

## 3. Decisões estruturantes

<!-- zion:adr-index:start -->
- **[ADR-099 — Fantasma](adr/ADR-099-fantasma.md)**
<!-- zion:adr-index:end -->

<!-- zion:backlog-view:start -->
- `walking-skeleton` — ☐ pendente
<!-- zion:backlog-view:end -->
```

- [ ] **Step 4: Implementar os achados no `check-arquitetura.sh`**

Troque `EXPECTED_VERSION="v1"` por:

```bash
EXPECTED_VERSION="v2"
```

Troque `block_content()` por (casa o marcador de abertura **por prefixo**, para acomodar `adrs=`):

```bash
# Conteúdo entre os marcadores de um bloco (vazio se marcadores ausentes). O marcador de abertura
# casa por PREFIXO — o bloco zion:narrativa carrega o atributo adrs= na própria linha (ADR-018).
block_content() {  # $1 arquivo  $2 nome-do-bloco
  awk -v start="<!-- zion:$2:start" -v end="<!-- zion:$2:end -->" '
    index($0, start)==1 { inb=1; next }
    $0==end   { inb=0 }
    inb { print }
  ' "$1"
}

# Âncora do bloco de narrativa: os ADRs que a máquina usou ao redigir (vazio se ausente).
narrativa_ancora() {  # $1 arquivo → "ADR-002,ADR-004" ou vazio
  grep -m1 -oE '<!-- zion:narrativa:start[^>]*-->' "$1" \
    | grep -oE 'adrs=[^ >]+' | head -1 | sed 's/^adrs=//' | tr -d ' '
}
```

Troque a função `check_visao_vazia()` inteira por:

```bash
# 2. §1 Visão geral: a narrativa estrutural (bloco zion:narrativa) existe, tem prosa e é ancorada
#    nos ADRs que a sustentam (ADR-018). A prosa é do Autor; o que se cobra é presença e âncora.
check_narrativa() {
  [ -f "$ARCH" ] || return 0
  if ! grep -q '<!-- zion:narrativa:start' "$ARCH"; then
    printf 'docs/architecture.md: narrativa-ausente — a §1 não tem o bloco zion:narrativa (rode /zion-prd-decompose --narrativa)\n'
    return 0
  fi
  local prosa ancora
  prosa="$(block_content "$ARCH" narrativa | grep -vE '^[[:space:]]*$' | grep -vE '^[[:space:]]*_.*_[[:space:]]*$')"
  if [ -z "$prosa" ]; then
    printf 'docs/architecture.md: narrativa-ausente — bloco zion:narrativa sem prosa (rode /zion-prd-decompose --narrativa)\n'
    return 0
  fi
  ancora="$(narrativa_ancora "$ARCH")"
  [ -n "$ancora" ] \
    || printf 'docs/architecture.md: ancora-ausente — narrativa sem adrs= no marcador de abertura (rode /zion-prd-decompose --narrativa)\n'
}

# 2b. §2 Integrações externas: placeholder do esqueleto = integrações nunca declaradas. Declarar
#     "_(nenhuma integração externa)_" é saída válida — a §2 não tem marcadores, por escolha.
check_integracoes() {
  [ -f "$ARCH" ] || return 0
  grep -q '^## 2\. Integrações externas' "$ARCH" || return 0
  awk '
    /^## 2\. Integrações externas/ { insec=1; next }
    insec && /^## /                { insec=0 }
    insec && index($0, "prosa do Autor:") { found=1 }
    END { exit(found?0:1) }
  ' "$ARCH" \
    && printf 'docs/architecture.md: integracoes-nao-declaradas — a §2 ainda tem o placeholder do esqueleto (declare as integrações ou "_(nenhuma integração externa)_")\n'
  return 0
}
```

Troque a chamada na composição de `findings`:

```bash
findings="$(
  check_secoes
  check_narrativa
  check_integracoes
  check_adr_index
  check_backlog_view
  check_regras
)"
```

Atualize o comentário do cabeçalho do script para citar o ADR-018 ao lado do ADR-015:

```bash
# check-arquitetura.sh — verificador do architecture.md do PRODUTO + regra instalada (ADR-015/018).
```

- [ ] **Step 5: Rodar e ver passar**

Run: `bash scripts/test-check-arquitetura.sh`
Expected: `test-check-arquitetura: tudo verde`.

- [ ] **Step 6: Atualizar o esqueleto distribuído**

Substitua `assets/templates/architecture-skeleton.md` inteiro por:

```markdown
# Arquitetura — <NOME DO PRODUTO>

> Fonte da verdade do **como/com-quê** deste produto. O o-quê/por-quê vive em `docs/prd.md`
> (fronteira o-quê/como). A fronteira de donos completa está no bloco de regras do `CLAUDE.md`
> (instalado por `/zion-speckit-install`): constitution = princípios de repo; ADRs = decisões
> pontuais; este documento = topologia e contratos do produto + índices derivados; plan = o como por
> feature. A §1 nasce sob ditado na fase final do `/zion-prd-decompose` e **nunca é sobrescrita sem
> confirmação**; as §3 e §4 e o bloco de avisos são **derivados** — reconciliados por
> `/zion-prd-trace`; não os edite à mão.

## 1. Visão geral

<!-- zion:narrativa-avisos:start -->
_(sem narrativa ainda)_
<!-- zion:narrativa-avisos:end -->

<!-- zion:narrativa:start -->
_(a narrativa estrutural nasce na fase final do `/zion-prd-decompose` — topologia e contratos: quem
chama quem, por qual via, quem é dono de qual dado)_
<!-- zion:narrativa:end -->

## 2. Integrações externas

_(prosa do Autor: contratos com o mundo de fora — serviços consumidos, eventos, protocolos. Sem
nenhuma? declare `_(nenhuma integração externa)_` — declarar é diferente de esquecer.)_

## 3. Decisões estruturantes

<!-- zion:adr-index:start -->
_(nenhum ADR ainda)_
<!-- zion:adr-index:end -->

## 4. Visão do backlog

<!-- zion:backlog-view:start -->
_(sem backlog ainda)_
<!-- zion:backlog-view:end -->
```

- [ ] **Step 7: Bump do bloco de regras para v2, com a regra de corte**

Em `assets/templates/regras-speckit.md`: troque `<!-- zion:speckit:v1:start -->` por `<!-- zion:speckit:v2:start -->` e `<!-- zion:speckit:v1:end -->` por `<!-- zion:speckit:v2:end -->`. Na seção **Fronteira de donos**, troque a linha do `docs/architecture.md` por:

```markdown
- **`docs/architecture.md`** — a **topologia e os contratos** do produto (§1–§2) + índices derivados
  (§3–§4 e o bloco de avisos, reconciliados por `/zion-prd-trace`; não editar à mão). A §1 nasce sob
  ditado na fase final do `/zion-prd-decompose` e nunca é sobrescrita sem confirmação; revise-a com
  `/zion-prd-decompose --narrativa`.
  **Regra de corte §1 × plan:** *se a frase muda ao trocar UMA feature, é `plan`; se muda só ao
  trocar o produto, é §1.*
```

- [ ] **Step 8: Ajustar o conselho da instalação**

Em `skills/zion-speckit-install/SKILL.md`, Fase 4, troque o parágrafo que começa com "Instalação recém-feita costuma sair com `visao-vazia`" por:

```markdown
Instalação recém-feita costuma sair com `narrativa-ausente` e `integracoes-nao-declaradas` — a §1
nasce na fase final do `/zion-prd-decompose` (ou por `/zion-prd-decompose --narrativa`) e a §2 é do
Autor, que pode declarar `_(nenhuma integração externa)_`. Aconselhe; não escreva por ele.
`regras-defasadas` após upgrade do harness → re-rode `/zion-speckit-install`.
```

E, na última linha (**Saída**), troque `bloco de regras v1` por `bloco de regras v2`.

- [ ] **Step 9: Canonizar — RF-11 e §13**

Em `docs/prd.md` §6, troque o texto do `RF-11` por:

```markdown
- **Épico E5 — Qualidade mecânica:** `RF-11` O harness verifica por máquina as regras decidíveis
  dos artefatos (fronteira sem stack, NFR com número, RF por épico, evidência presente por risco,
  âncora de experiência presente quando há superfície de uso, narrativa estrutural do produto
  presente e ancorada nas decisões que a sustentam, integrações externas declaradas, documento de
  arquitetura do produto e regra instalada em dia) e ecoa o veredito nos estágios.
```

Acrescente ao fim da tabela da §13:

```markdown
| 2026-07-20 | C2 | `RF-11` alterado: sai `visao-vazia`, entram narrativa ausente/sem âncora e integrações não declaradas; bloco de regras sobe para `v2` com a regra de corte §1 × plan | mais aviso isolado não movia o Autor: o achado agora aponta o comando que o cura e a fronteira fica instalada no repo do produto | ADR-018 · scripts/check-arquitetura.sh · assets/templates/architecture-skeleton.md · assets/templates/regras-speckit.md |
```

- [ ] **Step 10: Verificar tudo e commitar**

Run: `./scripts/sync-assets.sh && ./scripts/check-assets.sh && ./scripts/check-canon.sh && ./scripts/eval.sh`
Expected: sem drift, canon limpo, `eval: tudo verde`.

```bash
git add scripts assets skills docs/prd.md
git commit -m "feat(arquitetura): achados de narrativa/integrações e esqueleto com blocos ditados"
```

---

### Task 5: O bloco `zion:narrativa-avisos` reconciliado pelo trace

**Files:**
- Modify: `scripts/trace-arquitetura.sh`
- Modify: `scripts/test-trace-arquitetura.sh`
- Modify: `scripts/fixtures/arquitetura/trace/architecture.md`
- Modify: `skills/zion-prd-trace/SKILL.md`
- Test: `scripts/test-trace-arquitetura.sh`

**Interfaces:**
- Consumes: `adr_field()` e `adr_superseded()` (Task 3); os marcadores `zion:narrativa` / `zion:narrativa-avisos`.
- Produces: o conteúdo do bloco `zion:narrativa-avisos`, com três estados exatos — `_(sem narrativa ainda)_`, `_(narrativa em dia)_`, ou uma ou duas linhas `- ⚠ narrativa-superseded: …` / `- ⚠ narrativa-defasada: …`. A invocação canônica do trace passa a ser `trace-arquitetura.sh docs/architecture.md docs/adr docs/backlog.md specs`.

- [ ] **Step 1: Preparar a fixture com a narrativa ancorada**

Em `scripts/fixtures/arquitetura/trace/architecture.md`, troque a §1 por:

```markdown
## 1. Visão geral

<!-- zion:narrativa-avisos:start -->
_(conteúdo velho a ser substituído)_
<!-- zion:narrativa-avisos:end -->

<!-- zion:narrativa:start adrs=ADR-001,ADR-004 -->
O produto tem um **Recebedor** e um **Registro**: o Recebedor entrega ao Registro, dono único do
dado gravado.
<!-- zion:narrativa:end -->
```

(A âncora cita o ADR-004, que a Task 3 criou como substituído, e omite o ADR-002/ADR-003 aceitos — a fixture dispara os dois avisos de uma vez.)

- [ ] **Step 2: Escrever as asserções que falham**

Em `scripts/test-trace-arquitetura.sh`, acrescente ao fim do bloco 1 (depois de `assert_file_not_re "conteúdo velho dos blocos substituído" …`):

```bash
assert_file_re "avisa supersessão na âncora" "$arch" 'narrativa-superseded: ADR-004'
assert_file_re "avisa defasagem da âncora" "$arch" 'narrativa-defasada: ADR-002, ADR-003'
assert_file_re "aviso aponta a cura" "$arch" '/zion-prd-decompose --narrativa'
assert_file_re "prosa da narrativa intocada" "$arch" 'dono único do dado gravado'
assert_file_re "âncora intocada" "$arch" '<!-- zion:narrativa:start adrs=ADR-001,ADR-004 -->'
```

E acrescente no fim do arquivo (antes do veredito):

```bash
# 12. Narrativa em dia: âncora com todos os ADRs vigentes aceitos → "_(narrativa em dia)_".
arch="$(fresh "$FIX/architecture.md")"
sed -i 's/adrs=ADR-001,ADR-004/adrs=ADR-001,ADR-002,ADR-003/' "$arch"
bash "$TRACE" "$arch" "$FIX/adr" "$FIX/backlog.md" "$FIX/specs" >/dev/null 2>&1
assert_file_re "âncora completa vira narrativa em dia" "$arch" '_\(narrativa em dia\)_'
rm -f "$arch"

# 13. Sem prosa na narrativa → "_(sem narrativa ainda)_", sem acusar defasagem.
arch="$(fresh "$FIX/architecture.md")"
awk '/<!-- zion:narrativa:start/ { print "<!-- zion:narrativa:start -->"; skip=1; next }
     /<!-- zion:narrativa:end -->/ { skip=0 }
     !skip { print }' "$FIX/architecture.md" > "$arch"
bash "$TRACE" "$arch" "$FIX/adr" "$FIX/backlog.md" "$FIX/specs" >/dev/null 2>&1
assert_file_re "sem prosa vira sem narrativa ainda" "$arch" '_\(sem narrativa ainda\)_'
assert_file_not_re "sem prosa não acusa defasagem" "$arch" 'narrativa-defasada'
rm -f "$arch"

# 14. Documento sem o bloco de avisos → aviso com a cura certa, arquivo intacto nesse bloco.
arch="$(fresh "$FIX/sem-marcadores.md")"
out="$(bash "$TRACE" "$arch" "$FIX/adr" "$FIX/backlog.md" "$FIX/specs")"; rc=$?
assert_exit "sem bloco de avisos sai 1" 1 "$rc"
assert_contains "avisa a ausência do bloco de avisos" "zion:narrativa-avisos" "$out"
rm -f "$arch"
```

- [ ] **Step 3: Rodar e ver falhar**

Run: `bash scripts/test-trace-arquitetura.sh`
Expected: FALHOU — `FALHOU: avisa supersessão na âncora (regex não casou: narrativa-superseded: ADR-004)`.

- [ ] **Step 4: Implementar o bloco de avisos**

Em `scripts/trace-arquitetura.sh`, logo **acima** de `replace_block()`, acrescente:

```bash
# --- Conteúdo entre os marcadores de um bloco; o de abertura casa por PREFIXO (o bloco
#     zion:narrativa carrega adrs= na própria linha). ---
block_content() {  # $1 arquivo  $2 nome-do-bloco
  awk -v start="<!-- zion:$2:start" -v end="<!-- zion:$2:end -->" '
    index($0, start)==1 { inb=1; next }
    $0==end   { inb=0 }
    inb { print }
  ' "$1"
}

narrativa_ancora() {  # $1 arquivo → "ADR-002,ADR-004" ou vazio
  grep -m1 -oE '<!-- zion:narrativa:start[^>]*-->' "$1" \
    | grep -oE 'adrs=[^ >]+' | head -1 | sed 's/^adrs=//' | tr -d ' '
}

# --- Bloco de avisos (§1): acusa supersessão e defasagem da âncora SEM tocar a prosa do Autor
#     (ADR-018). A cura é sempre /zion-prd-decompose --narrativa, sob confirmação. ---
build_narrativa_avisos() {
  local prosa ancora out="" f id fora=""
  prosa="$(block_content "$ARCH" narrativa | grep -vE '^[[:space:]]*$' | grep -vE '^[[:space:]]*_.*_[[:space:]]*$')"
  if [ -z "$prosa" ]; then printf -- '_(sem narrativa ainda)_\n'; return 0; fi
  ancora="$(narrativa_ancora "$ARCH")"

  # 1. ADR citado na âncora que já foi substituído.
  for id in $(printf '%s' "$ancora" | tr ',' ' '); do
    f="$(ls "$ADR_DIR/$id-"*.md 2>/dev/null | head -1)"
    [ -n "$f" ] || continue
    if adr_superseded "$f"; then
      out="$out- ⚠ narrativa-superseded: $id foi substituído (rode \`/zion-prd-decompose --narrativa\`)
"
    fi
  done

  # 2. ADR aceito e vigente que a âncora não cita.
  for f in "$ADR_DIR"/ADR-*.md; do
    [ -f "$f" ] || continue
    adr_superseded "$f" && continue
    adr_field "$f" Status | grep -qiE '^aceito' || continue
    id="$(basename "$f" | grep -oE '^ADR-[0-9]+')"
    printf '%s' ",$ancora," | grep -qF ",$id," && continue
    if [ -z "$fora" ]; then fora="$id"; else fora="$fora, $id"; fi
  done
  if [ -n "$fora" ]; then
    out="$out- ⚠ narrativa-defasada: $fora aceitos fora da âncora (rode \`/zion-prd-decompose --narrativa\`)
"
  fi

  if [ -z "$out" ]; then printf -- '_(narrativa em dia)_\n'; else printf '%s' "$out"; fi
}
```

Troque `replace_block()` para casar o marcador de abertura por prefixo:

```bash
# --- Substitui o conteúdo entre os marcadores de UM bloco; o resto passa intacto. ---
replace_block() {  # $1 arquivo  $2 nome-do-bloco  $3 arquivo-com-conteudo → stdout
  awk -v start="<!-- zion:$2:start" -v end="<!-- zion:$2:end -->" -v cf="$3" '
    index($0,start)==1 { print; while ((getline l < cf) > 0) print l; close(cf); skip=1; next }
    $0==end   { skip=0 }
    skip { next }
    { print }
  ' "$1"
}
```

Na orquestração, acrescente o terceiro temporário e o terceiro bloco, com aviso próprio:

```bash
TMPA="$(mktemp)"; TMPB="$(mktemp)"; TMPC="$(mktemp)"; NEW="$(mktemp)"; CUR="$(mktemp)"
cleanup() { rm -f "$TMPA" "$TMPB" "$TMPC" "$NEW" "$CUR" 2>/dev/null; }
trap cleanup EXIT

build_adr_index        > "$TMPA"
build_backlog_view     > "$TMPB"
build_narrativa_avisos > "$TMPC"

cp "$ARCH" "$CUR"
for pair in "adr-index:$TMPA" "backlog-view:$TMPB" "narrativa-avisos:$TMPC"; do
  name="${pair%%:*}"; cf="${pair#*:}"
  if grep -qF "<!-- zion:$name:start -->" "$CUR" && grep -qF "<!-- zion:$name:end -->" "$CUR"; then
    replace_block "$CUR" "$name" "$cf" > "$NEW"
    cp "$NEW" "$CUR"
  elif [ "$name" = "narrativa-avisos" ]; then
    add_warning "Marcador ausente: bloco zion:narrativa-avisos sem <!-- zion:narrativa-avisos:start/end --> em $ARCH (a §1 ainda não foi ditada; rode /zion-prd-decompose --narrativa)"
  else
    add_warning "Marcador ausente: bloco zion:$name sem <!-- zion:$name:start/end --> em $ARCH (bloco não reconciliado; restaure os marcadores do esqueleto)"
  fi
done
```

**Atenção:** `build_narrativa_avisos` lê `$ARCH` — chame-a **antes** de qualquer escrita, como no bloco acima (o `cp "$ARCH" "$CUR"` vem depois).

Atualize o comentário do cabeçalho:

```bash
# trace-arquitetura.sh — reconciliador dos blocos derivados do architecture.md do PRODUTO (ADR-018).
# Regenera SÓ o conteúdo entre os marcadores zion:adr-index (§3, mapa por área), zion:backlog-view
# (§4) e zion:narrativa-avisos (§1); a prosa do Autor entre zion:narrativa nunca é tocada.
```

- [ ] **Step 5: Rodar e ver passar**

Run: `bash scripts/test-trace-arquitetura.sh`
Expected: `test-trace-arquitetura: tudo verde`.

- [ ] **Step 6: Atualizar a `SKILL.md` do trace**

Em `skills/zion-prd-trace/SKILL.md`, Fase 2/3, troque o comando do reconciliador de arquitetura e o parágrafo seguinte por:

```markdown
    bash references/trace-arquitetura.sh docs/architecture.md docs/adr docs/backlog.md specs

Ele regenera **só** o conteúdo dos blocos `zion:adr-index` (§3 — o mapa de decisões vigentes por
área, com o que cada uma fixou e as specs que a exercitam), `zion:backlog-view` (§4) e
`zion:narrativa-avisos` (§1 — supersessão e defasagem da âncora). A prosa do Autor entre
`zion:narrativa` **nunca é tocada** (ADR-018). O argumento `specs` é o que permite derivar as specs
de cada decisão pela linha `**ADRs honrados:**` do `spec.md`; spec sem essa linha simplesmente não
aparece no mapa (o dever de origem é advisório). `docs/architecture.md` ausente → aconselhe
`/zion-speckit-install` (informativo; não impede o resto do ritual).
```

E, na Fase 4, troque o bullet `**visao-vazia / secao-ausente**` por:

```markdown
- **narrativa-ausente / ancora-ausente** — a §1 nunca foi ditada, ou a prosa perdeu a âncora nos
  ADRs: aconselhe `/zion-prd-decompose --narrativa` (a prosa é do Autor; nunca a reescreva por ele).
- **narrativa-superseded / narrativa-defasada** (no bloco de avisos que você acabou de reconciliar)
  — a narrativa cita uma decisão substituída, ou decisões aceitas ficaram de fora dela: mesma cura,
  `/zion-prd-decompose --narrativa`, que mostra o rascunho novo lado a lado e só grava sob confirmação.
- **integracoes-nao-declaradas / secao-ausente** — a §2 ainda tem o placeholder do esqueleto, ou o
  documento perdeu uma seção: aconselhe, não corrija por ele (declarar
  `_(nenhuma integração externa)_` é saída válida).
```

E, na **Saída**, troque a primeira frase por:

```markdown
A seção 12 de `docs/PRD.md`, `docs/backlog.md` **e os blocos derivados de `docs/architecture.md`
(mapa de decisões, visão do backlog e avisos de narrativa)** reconciliados + os resumos/avisos e o
quadro de specs ecoados.
```

- [ ] **Step 7: Verificar tudo e commitar**

Run: `./scripts/sync-assets.sh && ./scripts/check-assets.sh && ./scripts/check-canon.sh && ./scripts/eval.sh`
Expected: sem drift, canon limpo, `eval: tudo verde`.

```bash
git add scripts skills
git commit -m "feat(arquitetura): bloco de avisos da narrativa reconciliado pelo trace"
```

---

### Task 6: Fase de narrativa no `/zion-prd-decompose` e a flag `--narrativa`

**Files:**
- Modify: `skills/zion-prd-decompose/SKILL.md` (frontmatter `argument-hint` + Fase 5 nova + Saída)
- Modify: `docs/prd.md` (RF-05 + §13)
- Test: `./scripts/check-canon.sh` + `./scripts/eval.sh` (a skill é prosa; a camada mecânica só cobra canon e drift)

**Interfaces:**
- Consumes: os marcadores `zion:narrativa` / `zion:narrativa-avisos` (Task 4) e o mapa da §3 já reconciliado (Task 3/5).
- Produces: a fase que **grava** a prosa entre `<!-- zion:narrativa:start adrs=… -->` e `<!-- zion:narrativa:end -->` com o atributo `adrs=` preenchido — o insumo que a Task 7 (ponte do plan) extrai.

- [ ] **Step 1: Atualizar o `argument-hint` do frontmatter**

Em `skills/zion-prd-decompose/SKILL.md`, troque a linha `argument-hint:` por:

```yaml
argument-hint: "(sem argumento = modo integral; --epico E<k> = re-fatiar só um épico no dia 2; --narrativa = revisar só a narrativa estrutural da §1–§2)"
```

- [ ] **Step 2: Acrescentar a Fase 5**

Insira, **entre** a Fase 4 e a seção `## Saída`:

```markdown
## Fase 5 — Narrativa estrutural do `docs/architecture.md` (ditado sob lastro)

Roda **depois** da Fase 4, quando ADRs, backlog e §3 já existem — é o momento em que o material
finalmente existe. Escreve a §1 (Visão geral) e a §2 (Integrações externas) do
`docs/architecture.md` do produto **sob ditado**: a máquina propõe, o Autor assina (ADR-018).
`docs/architecture.md` ausente → aconselhe `/zion-speckit-install` e pule a fase (não bloqueie).

**A regra de corte (cite-a ao Autor quando ele hesitar):** a §1 é **topologia + contratos** — os
componentes de topo e o contrato entre eles (quem chama quem, por qual via, quem é dono de qual
dado). O interior de cada componente é do `plan`. *Se a frase muda ao trocar UMA feature, é `plan`;
se muda só ao trocar o produto, é §1.*

**Regra de lastro (dura).** Toda afirmação estrutural do rascunho rastreia a um ADR aceito. O que
não tem lastro **não vira prosa**: vira **pergunta ao Autor** ("os ADRs não dizem quem persiste esse
dado — quem é o dono?"), e a resposta dele entra como prosa dele. Não invente arquitetura para
preencher parágrafo.

1. **Leia** `docs/adr/*.md` aceitos, `docs/backlog.md` e a §3 recém-reconciliada.
2. **Semeie os marcadores** na §1 quando ausentes (produto instalado antes desta versão do harness):
   `<!-- zion:narrativa-avisos:start --> _(sem narrativa ainda)_ <!-- zion:narrativa-avisos:end -->`
   e `<!-- zion:narrativa:start --> … <!-- zion:narrativa:end -->`, nessa ordem, logo abaixo do
   cabeçalho `## 1. Visão geral`. Nada fora deles é tocado.
3. **Redija o rascunho** da §1 sob a regra de corte e a regra de lastro. Liste à parte as perguntas
   sem lastro.
4. **Apresente** ao Autor: `[aceitar]` · `[editar]` · `[ditar do zero]` · `[pular]`. **Pular é
   legítimo** — produto de jornada curta, sem material, sai com a §1 vazia e um aviso, nunca com
   prosa inventada.
5. **Grave** a prosa entre os marcadores e preencha o atributo `adrs=` do marcador de abertura com
   os ADRs que você **de fato usou** ao redigir, separados por vírgula e sem espaços:
   `<!-- zion:narrativa:start adrs=ADR-002,ADR-004 -->`. A âncora é **da máquina** — o Autor nunca a
   digita; ela some no render.
6. **Idem a §2** (Integrações externas), em prosa livre e sem marcadores. `_(nenhuma integração
   externa)_` é **saída válida e declarada** — diferente de esquecer.
7. **Autoverifique** e ecoe o veredito (aconselha, `RN-01`):

       bash references/check-arquitetura.sh .

**Sem delegação nova.** Esta fase é redação sob ditado, não clarificação — não invoque o
`superpowers:brainstorming` aqui (`NFR-02` intacto). Tensão de desenho que apareça segue a rubrica de
`references/delegacao-criativa.md` que esta skill já carrega (`RF-20`).

**Modo revisar — `--narrativa`:** pula as Fases 1–4 (não re-fatia nada) e entra direto nesta fase.
Mostre lado a lado: a **narrativa vigente**, os **avisos** do bloco `zion:narrativa-avisos` e o
**rascunho novo**. **Nunca sobrescreva sem confirmação explícita do Autor** — é essa cláusula que
substitui o "nunca tocada por máquina" do ADR-015. Antes de reconciliar os avisos, rode
`/zion-prd-trace` (dono único dos blocos derivados) ou o `references/trace-arquitetura.sh` direto.
```

- [ ] **Step 3: Atualizar a Saída da skill**

Troque a seção `## Saída` por:

```markdown
## Saída
Lista de épicos, story map, backlog de **specs verticais** priorizadas com linhas de release, o
arquivo **`docs/backlog.md`** semeado por `trace-backlog.sh` (slug/demo/RFs por spec; Pasta/Status por
máquina), a tabela de rastreabilidade **semeada por `trace-prd.sh`** dentro da PRD e a **narrativa
estrutural** da §1–§2 do `docs/architecture.md` gravada sob ditado (ou pulada por escolha do Autor).
**Handoff:** a próxima spec da fila entra em `/zion-prd-specify-prompt`; após cada spec,
`/zion-prd-trace` reconcilia a tabela e os blocos derivados da arquitetura.
```

- [ ] **Step 4: Canonizar — RF-05 e §13**

Em `docs/prd.md` §6, troque o texto do `RF-05` por:

```markdown
`RF-05` O autor
  decompõe a PRD em épicos, story map e specs verticais priorizadas, com o walking skeleton como
  spec zero, ancorando a experiência em ≥1 spec que toca a superfície de uso quando ela existe; ao
  final, dita a narrativa estrutural do produto — os componentes de topo e o contrato entre eles —
  sobre um rascunho que a máquina propõe apoiada só no que as decisões sustentam, e que nunca é
  sobrescrito sem a confirmação dele.
```

Acrescente ao fim da tabela da §13:

```markdown
| 2026-07-20 | C2 | `RF-05` alterado: a decomposição termina ditando a narrativa estrutural da §1–§2 do documento de arquitetura, com âncora nas decisões usadas | o documento era semeado e o placeholder atravessava a jornada inteira; agora nasce onde o material finalmente existe | ADR-018 · skills/zion-prd-decompose (Fase 5 e `--narrativa`) |
```

- [ ] **Step 5: Verificar tudo e commitar**

Run: `./scripts/sync-assets.sh && ./scripts/check-assets.sh && ./scripts/check-canon.sh && ./scripts/eval.sh`
Expected: sem drift, canon limpo, `eval: tudo verde`.

```bash
git add skills docs/prd.md
git commit -m "feat(decompose): fase de narrativa estrutural sob ditado e flag --narrativa"
```

---

### Task 7: Rota do dia 2 e a ponte do plan lendo a narrativa pelo marcador

**Files:**
- Modify: `skills/zion-prd-evolve/SKILL.md`
- Modify: `skills/zion-prd-plan-prompt/SKILL.md`
- Modify: `docs/prd.md` (RF-10 + §13)
- Test: `./scripts/check-canon.sh` + `./scripts/eval.sh`

**Interfaces:**
- Consumes: o bloco `zion:narrativa` com âncora (Task 6) e os achados `narrativa-superseded` / `narrativa-defasada` do bloco de avisos (Task 5).
- Produces: nada consumido por tasks posteriores — é a última.

- [ ] **Step 1: Acrescentar a rota do dia 2 no evolve**

Em `skills/zion-prd-evolve/SKILL.md`, na Fase 2/3, bloco **Delegado**, insira uma rota logo depois da linha do re-fatiamento:

```markdown
- **Narrativa estrutural defasada (C1/C2/C3)** → `/zion-prd-decompose --narrativa`: quando a mudança
  cria/derruba componente ou contrato de topo, ou quando o bloco `zion:narrativa-avisos` do
  `docs/architecture.md` acusa `narrativa-superseded`/`narrativa-defasada`. Revisa **só** a §1–§2,
  sem re-fatiar nada, e nunca sobrescreve a prosa do Autor sem confirmação (ADR-018).
```

E, no C3 dos **Cenários canônicos**, acrescente ao fim da linha:

```markdown
- **C3 — Decisão revertida:** decisão estruturante caiu. Toca ADR novo que substitui o antigo
  (referência cruzada simétrica) + §8 (restrições) + §13 + aviso de revisar a `constitution` + a
  narrativa da §1 quando a decisão caída a sustentava (o bloco de avisos acusa).
```

- [ ] **Step 2: Trocar a extração da narrativa na ponte do plan**

Em `skills/zion-prd-plan-prompt/SKILL.md`, Fase 1, troque o item 1 por:

```markdown
1. Leia o `spec.md` da spec e cruze com `docs/adr/`; se `docs/architecture.md` existir, extraia a
   **narrativa estrutural** pelo marcador — o conteúdo entre `<!-- zion:narrativa:start … -->` e
   `<!-- zion:narrativa:end -->`, **sem** os marcadores — mais a prosa da §2 (Integrações externas).
   Não raspe a §1 inteira: o que está fora do bloco é ruído de esqueleto. Bloco ausente ou só com
   placeholder `_(…)_` → não há narrativa; avise que a §1 nunca foi ditada e aconselhe
   `/zion-prd-decompose --narrativa` (não bloqueie).
```

E acrescente, logo abaixo da **Guarda de suficiência**:

```markdown
**Avisos de defasagem (ecoe, não corrija).** Se o bloco `zion:narrativa-avisos` do
`docs/architecture.md` trouxer `narrativa-superseded` ou `narrativa-defasada`, ecoe-os antes de
montar o prompt: a narrativa que você vai injetar pode estar velha em relação aos ADRs. A cura é
`/zion-prd-decompose --narrativa`; o Autor decide se cura agora ou segue (`RN-01`).
```

Na Fase 2/3, troque o bullet da injeção por:

```markdown
- Injetar a **narrativa estrutural** extraída do bloco `zion:narrativa` mais a §2 do
  `docs/architecture.md` como restrição a honrar: resuma fiel os componentes de topo e os contratos
  externos — não invente estrutura que o documento não tem. O **interior** de cada componente é o
  que o `plan` vai decidir; a §1 só fixa a topologia e os contratos. A injeção é seletiva por passo
  (RN-02): só o plan recebe este documento; specify e clarify nunca.
```

- [ ] **Step 3: Canonizar — RF-10 e §13**

Em `docs/prd.md` §6, troque o texto do `RF-10` por:

```markdown
- **Épico E4 — Dia 2:** `RF-10` O autor classifica uma mudança pós-release nos cenários canônicos
  e é roteado aos comandos donos de cada artefato afetado — inclusive a narrativa estrutural do
  produto quando ela fica defasada —, com o histórico registrado na PRD.
```

Acrescente ao fim da tabela da §13:

```markdown
| 2026-07-20 | C2 | `RF-10` alterado: o dia 2 ganha a rota da narrativa defasada; a ponte do plan passa a extrair a narrativa pelo marcador e a ecoar os avisos | `RF-08` prometia injetar a prosa estrutural e injetava vazio | ADR-018 · skills/zion-prd-evolve · skills/zion-prd-plan-prompt |
```

- [ ] **Step 4: Conferir que o `RF-08` ficou textualmente intacto**

Run: `grep -n 'RF-08' docs/prd.md`
Expected: o texto do `RF-08` na §6 permanece como estava (a promessa era a mesma; só passou a ser cumprida). Só a linha nova da §13 o menciona.

- [ ] **Step 5: Verificar tudo**

Run: `./scripts/sync-assets.sh && ./scripts/check-assets.sh && ./scripts/check-canon.sh && ./scripts/eval.sh && ./scripts/check-adr.sh docs/adr && ./scripts/check-arquitetura.sh .`
Expected: sem drift, canon limpo, `eval: tudo verde`, `check-adr: limpo`. O `check-arquitetura.sh .` **neste repo** vai acusar (este repo não é um produto instalado, não tem os marcadores) — é esperado e informativo, não faz parte dos guards.

- [ ] **Step 6: Commit**

```bash
git add skills docs/prd.md
git commit -m "feat(pontes): rota de narrativa defasada no dia 2 e plan lendo a narrativa pelo marcador"
```

---

## Notas de verificação final (rode depois da Task 7)

- [ ] `./scripts/eval.sh` — todos os auto-testes verdes.
- [ ] `./scripts/check-canon.sh` — sem drift entre canon e implementação.
- [ ] `./scripts/check-assets.sh` — `skills/*/references/` idênticos às fontes.
- [ ] `./scripts/check-adr.sh docs/adr` — evidência, simetria e Área em todos os ADRs.
- [ ] `git log --oneline -7` — sete commits, um por task, cada um com a canonização junto.
