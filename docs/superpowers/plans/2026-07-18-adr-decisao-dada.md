# Decisão dada — 3º tipo de risco no registro de ADR — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Adicionar `decisão dada` como terceiro tipo de risco de 1ª classe no harness, com marcador próprio no campo `Evidência`, ramo dedicado no `check-adr.sh`, micro-diálogo guiado nas skills e cobertura por fixtures/testes.

**Architecture:** Um novo ramo no `check-adr.sh` casa o marcador `Decisão dada: <racional>` **antes** dos ramos de spike/conhecimento e verifica só presença do racional (achado `decisao-dada-sem-racional`). Os assets canônicos (`assets/quality-rules.md`, `scripts/check-adr.sh`) são editados na raiz e propagados aos `references/` das skills via `sync-assets.sh`; `check-assets.sh` garante zero drift. As skills `zion-adr-new` e `zion-prd-spike` ganham o vocabulário e o micro-diálogo (definido uma vez em `zion-adr-new`, referenciado pela `zion-prd-spike`).

**Tech Stack:** Bash (POSIX-ish, compatível BSD/GNU como o resto dos scripts), Markdown (skills + docs), fixtures `.md`, suíte `eval.sh`.

---

## File Structure

Arquivos criados/modificados, por responsabilidade:

- **`scripts/check-adr.sh`** (canônico) — ganha o ramo `decisão dada`. Sincronizado a `zion-prd-spike` e `zion-prd-evolve`.
- **`scripts/fixtures/adr/clean/ADR-003-decisao-dada.md`** (novo) — ADR de decisão dada com racional preenchido; a fixture `clean` segue exit 0.
- **`scripts/fixtures/adr/dirty/ADR-006-decisao-dada-sem-racional.md`** (novo) — marcador com racional placeholder; dispara `decisao-dada-sem-racional`.
- **`scripts/test-check-adr.sh`** — novo assert de que `dirty` acusa `decisao-dada-sem-racional` (o `clean` já é coberto pelos asserts de "limpo" existentes, agora exercendo o ADR-003).
- **`assets/quality-rules.md`** (canônico) — `#risco-do-spike` ganha o 3º tipo e a 3ª cláusula da regra prática; `#criterios-de-conclusao` (bullet spike) cita racional escrito. Sincronizado a 8 skills.
- **`skills/zion-adr-new/SKILL.md`** (editado direto) — template (`Evidência` com 3 formas), `argument-hint` + flag `--dada`, seção "Modo decisão dada" com os 4 probes, nota de convenção (sem spike dir).
- **`skills/zion-prd-spike/SKILL.md`** (editado direto) — Fase 1 com 3 rótulos + guarda advisory (tudo dada), Fase 2/3 com ramo decisão dada referenciando o micro-diálogo de `zion-adr-new`.
- **`docs/como-usar.md`** — nota no Estágio 2 sobre criar ADR de decisão dada direto (`--dada`) e via Fase 1 do spike.

---

## Task 1: Fixtures + teste que falha para o ramo `decisão dada`

**Files:**
- Create: `scripts/fixtures/adr/clean/ADR-003-decisao-dada.md`
- Create: `scripts/fixtures/adr/dirty/ADR-006-decisao-dada-sem-racional.md`
- Modify: `scripts/test-check-adr.sh:34` (após o último assert do bloco `dirty`)
- Test: `scripts/test-check-adr.sh` (é o próprio harness de teste)

- [ ] **Step 1: Criar a fixture clean (racional preenchido)**

Create `scripts/fixtures/adr/clean/ADR-003-decisao-dada.md` — racional em prosa, **sem** URL/caminho (para que, antes da mudança no script, o ramo de conhecimento a acuse como `evidencia-sem-lastro`; depois da mudança, o novo ramo a reconhece como limpa):

```markdown
# ADR-003 — Provider de nuvem

- **Status:** Aceito
- **Data:** 2026-07-18
- **Decisores:** time de plataforma
- **Evidência:** Decisão dada: mandato de infraestrutura da organização — reusar o provider de nuvem já contratado, decidido pelo time de plataforma

## Contexto

Decisão dada: a escolha chegou batida de fora. A restrição que força é o contrato de infraestrutura
já vigente; reabrir exigiria renegociar o contrato corporativo.

## Decisão

Reusar o provider de nuvem já contratado. Preterido: avaliar provedores alternativos por conta.

## Consequências

Aceito o trade-off de não otimizar por preço/feature específicos; ganha-se alinhamento com o
mandato de infra e zero atrito de aprovação.

## Status

Aceito.
```

- [ ] **Step 2: Criar a fixture dirty (racional placeholder)**

Create `scripts/fixtures/adr/dirty/ADR-006-decisao-dada-sem-racional.md` — marcador presente, racional é placeholder `<…>`:

```markdown
# ADR-006 — Decisão dada sem racional

- **Status:** Proposto
- **Data:** 2026-07-18
- **Decisores:** time
- **Evidência:** Decisão dada: <autoridade/racional — quem decidiu e por quê>

## Contexto

Marcador de decisão dada presente, mas o racional não foi destilado.

## Decisão

Uma decisão qualquer.

## Consequências

Trade-offs.

## Status

Proposto.
```

- [ ] **Step 3: Acrescentar o assert do novo achado ao bloco `dirty`**

In `scripts/test-check-adr.sh`, adicione a linha abaixo logo após o assert `evidencia-sem-lastro` (atual linha 34). O bloco `dirty` agora tem 6 asserts de achado:

```bash
assert_contains "dirty acha decisao-dada-sem-racional" "decisao-dada-sem-racional" "$out"
```

Contexto do trecho após a edição:

```bash
assert_contains "dirty acha spike-sem-readme"     "spike-sem-readme" "$out"
assert_contains "dirty acha evidencia-sem-lastro" "evidencia-sem-lastro" "$out"
assert_contains "dirty acha decisao-dada-sem-racional" "decisao-dada-sem-racional" "$out"
```

> Nota: o assert existente `"clean reporta limpo"` (linha 22) passa a cobrir a fixture clean nova, então não é preciso um assert clean adicional.

- [ ] **Step 4: Rodar o teste e confirmar que FALHA**

Run: `bash scripts/test-check-adr.sh`
Expected: FALHA. O novo assert `dirty acha decisao-dada-sem-racional` falha (o script ainda não emite esse achado), **e** o assert `clean reporta limpo` também falha — sem o ramo novo, o ADR-003 clean cai no ramo de conhecimento e vira `evidencia-sem-lastro`, quebrando o "limpo". Saída termina com `test-check-adr: FALHOU`.

- [ ] **Step 5: Commit**

```bash
git add scripts/fixtures/adr/clean/ADR-003-decisao-dada.md scripts/fixtures/adr/dirty/ADR-006-decisao-dada-sem-racional.md scripts/test-check-adr.sh
git commit -m "test(check-adr): fixtures e assert do achado decisao-dada-sem-racional"
```

---

## Task 2: Implementar o ramo `decisão dada` no `check-adr.sh`

**Files:**
- Modify: `scripts/check-adr.sh:13-17` (comentário-cabeçalho) e `scripts/check-adr.sh:65-67` (inserir o ramo antes do `case`)
- Test: `scripts/test-check-adr.sh`

- [ ] **Step 1: Atualizar o comentário-cabeçalho para listar o novo achado**

In `scripts/check-adr.sh`, substitua o bloco de comentário (linhas 13-17):

```bash
# Para cada <dir>/ADR-*.md (glob de filhos diretos → ignora spikes/):
#   1. sem linha **Evidência:** preenchida (vazia ou placeholder <…>) → sem-evidencia
#   2. Evidência aponta docs/adr/spikes/<seg>/ (risco de execução):
#        <dir>/spikes/<seg> ausente        → spike-dir-ausente
#        <dir>/spikes/<seg> vazio          → spike-dir-vazio
#        <dir>/spikes/<seg> sem README.md  → spike-sem-readme
#   3. Evidência de conhecimento sem URL nem caminho → evidencia-sem-lastro
```

por:

```bash
# Para cada <dir>/ADR-*.md (glob de filhos diretos → ignora spikes/):
#   1. sem linha **Evidência:** preenchida (vazia ou placeholder <…>) → sem-evidencia
#   2. Evidência "Decisão dada: <racional>" com racional vazio/placeholder → decisao-dada-sem-racional
#   3. Evidência aponta docs/adr/spikes/<seg>/ (risco de execução):
#        <dir>/spikes/<seg> ausente        → spike-dir-ausente
#        <dir>/spikes/<seg> vazio          → spike-dir-vazio
#        <dir>/spikes/<seg> sem README.md  → spike-sem-readme
#   4. Evidência de conhecimento sem URL nem caminho → evidencia-sem-lastro
```

- [ ] **Step 2: Inserir o ramo de decisão dada antes do `case "$ev" in`**

In `scripts/check-adr.sh`, entre o `fi` que fecha o bloco `sem-evidencia` (linha 65) e o `case "$ev" in` (linha 67), insira:

```bash

  # Decisão dada: o lastro é o racional escrito no próprio ADR (quem/que autoridade decidiu e por
  # quê). Casa ANTES dos ramos de spike/conhecimento para que um racional em prosa não seja
  # mal-acusado como evidencia-sem-lastro. O rótulo "Decisão dada" é bytes UTF-8 fixos do template.
  if printf '%s' "$ev" | grep -qiE '^decisão dada[[:space:]]*:'; then
    rac="$(printf '%s' "$ev" | sed 's/^[^:]*:[[:space:]]*//')"
    rac="$(printf '%s' "$rac" | sed 's/[[:space:]]*$//')"
    if [ -z "$rac" ] || printf '%s' "$rac" | grep -qE '^<.*>$'; then
      add "$label: decisao-dada-sem-racional — marcador \"Decisão dada:\" sem racional (aponte a autoridade/racional — quem decidiu e por quê)"
    fi
    continue
  fi
```

Contexto do trecho após a edição (do `fi` do `sem-evidencia` ao `case`):

```bash
  # Vazia ou placeholder <…> → sem evidência.
  if [ -z "$ev" ] || printf '%s' "$ev" | grep -qE '^<.*>$'; then
    add "$label: sem-evidencia — nenhuma linha **Evidência:** preenchida (aponte o spike dir ou a fonte de pesquisa)"
    continue
  fi

  # Decisão dada: o lastro é o racional escrito no próprio ADR (quem/que autoridade decidiu e por
  # quê). Casa ANTES dos ramos de spike/conhecimento para que um racional em prosa não seja
  # mal-acusado como evidencia-sem-lastro. O rótulo "Decisão dada" é bytes UTF-8 fixos do template.
  if printf '%s' "$ev" | grep -qiE '^decisão dada[[:space:]]*:'; then
    rac="$(printf '%s' "$ev" | sed 's/^[^:]*:[[:space:]]*//')"
    rac="$(printf '%s' "$rac" | sed 's/[[:space:]]*$//')"
    if [ -z "$rac" ] || printf '%s' "$rac" | grep -qE '^<.*>$'; then
      add "$label: decisao-dada-sem-racional — marcador \"Decisão dada:\" sem racional (aponte a autoridade/racional — quem decidiu e por quê)"
    fi
    continue
  fi

  case "$ev" in
```

> Por que funciona: `sed 's/^[^:]*:[[:space:]]*//'` remove o rótulo até o **primeiro** `:` (o do marcador), preservando racional que contenha `:`. Racional vazio (`Decisão dada:`) vira string vazia → achado. Placeholder (`<…>`) casa `^<.*>$` → achado. Racional em prosa → limpo, e `continue` evita o ramo de conhecimento (que exigiria URL/caminho).

- [ ] **Step 3: Rodar o teste e confirmar que PASSA**

Run: `bash scripts/test-check-adr.sh`
Expected: PASS. Todos os asserts verdes, incluindo `dirty acha decisao-dada-sem-racional` e `clean reporta limpo`. Saída termina com `test-check-adr: tudo verde`.

- [ ] **Step 4: Propagar o asset canônico aos references/**

Run: `bash scripts/sync-assets.sh`
Expected: `sync-assets: ok`. Copia `scripts/check-adr.sh` para `skills/zion-prd-spike/references/` e `skills/zion-prd-evolve/references/`.

- [ ] **Step 5: Confirmar zero drift**

Run: `bash scripts/check-assets.sh`
Expected: `check-assets: sem drift`.

- [ ] **Step 6: Commit**

```bash
git add scripts/check-adr.sh skills/zion-prd-spike/references/check-adr.sh skills/zion-prd-evolve/references/check-adr.sh
git commit -m "feat(check-adr): ramo decisao-dada verifica presença do racional"
```

---

## Task 3: `#risco-do-spike` e `#criterios-de-conclusao` em `quality-rules.md`

**Files:**
- Modify: `assets/quality-rules.md:43-46` (bullet spike) e `assets/quality-rules.md:66-78` (`#risco-do-spike`)

- [ ] **Step 1: Adicionar o 3º tipo de risco em `#risco-do-spike`**

In `assets/quality-rules.md`, após o bullet **Risco de conhecimento** (linhas 73-74) e antes da linha `Regra prática:` (linha 76), insira o novo bullet:

```markdown
- **Decisão dada** — a escolha **já chegou batida de fora** (política da org, restrição externa,
  padrão já estabelecido); não há dúvida a resolver rodando nem lendo. **Meio: racional escrito no
  próprio ADR** — quem/que autoridade decidiu e por quê.
```

- [ ] **Step 2: Adicionar a 3ª cláusula da regra prática**

In `assets/quality-rules.md`, substitua a primeira frase de `Regra prática:` (linhas 76-77):

```markdown
Regra prática: se você decide lendo docs/benchmarks de terceiros, é **conhecimento**; se precisa do
*seu* caso rodando para confiar, é **execução**. A presença da evidência do tipo certo é verificada
```

por (acrescenta a cláusula de decisão dada, mantendo a frase de verificação):

```markdown
Regra prática: se você decide lendo docs/benchmarks de terceiros, é **conhecimento**; se precisa do
*seu* caso rodando para confiar, é **execução**; se não há dúvida a provar — a decisão vem batida —
é **decisão dada**, e o lastro é registrar a autoridade, não prová-la. A presença da evidência do
tipo certo é verificada
```

- [ ] **Step 3: Citar racional escrito no critério spike de `#criterios-de-conclusao`**

In `assets/quality-rules.md`, substitua o parêntese do bullet **spike** (linhas 44-46):

```markdown
  Consequências ∧ o ADR carrega **evidência do tipo certo para seu risco** (spike de código para
  risco de execução; fonte de pesquisa para risco de conhecimento — ver `#risco-do-spike`). A
  presença da evidência é verificada por `check-adr.sh` — a Fase 4 roda o script e ecoa o veredito.
```

por:

```markdown
  Consequências ∧ o ADR carrega **evidência do tipo certo para seu risco** (spike de código para
  risco de execução; fonte de pesquisa para risco de conhecimento; racional escrito para decisão
  dada — ver `#risco-do-spike`). A presença da evidência é verificada por `check-adr.sh` — a Fase 4
  roda o script e ecoa o veredito.
```

- [ ] **Step 4: Propagar e confirmar zero drift**

Run: `bash scripts/sync-assets.sh && bash scripts/check-assets.sh`
Expected: `sync-assets: ok` seguido de `check-assets: sem drift`.

- [ ] **Step 5: Commit**

```bash
git add assets/quality-rules.md skills/*/references/quality-rules.md
git commit -m "docs(quality-rules): decisão dada como 3º tipo de risco do spike"
```

---

## Task 4: `zion-adr-new/SKILL.md` — flag `--dada`, template e micro-diálogo

**Files:**
- Modify: `skills/zion-adr-new/SKILL.md:4` (argument-hint), `:19-29` (Argumento), `:52-54` (template Evidência), e inserir "Modo decisão dada" após o "Modo substituir" (após linha 87)

- [ ] **Step 1: Estender o `argument-hint` com `--dada`**

In `skills/zion-adr-new/SKILL.md`, substitua a linha 4:

```yaml
argument-hint: "Título da decisão (ex.: \"Escolha de estado\"); opcional --substitui ADR-<n> no dia 2"
```

por:

```yaml
argument-hint: "Título da decisão (ex.: \"Escolha de estado\"); opcional --dada [\"<racional>\"] ou --substitui ADR-<n> no dia 2"
```

- [ ] **Step 2: Documentar a flag `--dada` na seção Argumento**

In `skills/zion-adr-new/SKILL.md`, substitua o final da seção **Argumento** — o bloco de exemplos e a linha do `--substitui` (linhas 23-29):

```markdown
```text
/zion-adr-new  "Escolha de biblioteca de renderização de diagramas"
/zion-adr-new  "Estratégia de gerenciamento de estado do editor"
/zion-adr-new  "Motor de exportação vetorial" --substitui ADR-002
```

O sufixo opcional `--substitui ADR-<n>` ativa o **modo substituir** (dia 2 — ver abaixo).
```

por (acrescenta exemplo e parágrafo do `--dada`):

```markdown
```text
/zion-adr-new  "Escolha de biblioteca de renderização de diagramas"
/zion-adr-new  "Estratégia de gerenciamento de estado do editor"
/zion-adr-new  "Provider de nuvem" --dada "mandato de infra: reusar o provider já contratado"
/zion-adr-new  "Motor de exportação vetorial" --substitui ADR-002
```

O sufixo opcional `--substitui ADR-<n>` ativa o **modo substituir** (dia 2 — ver abaixo). O sufixo
opcional `--dada [ "<racional inicial>" ]` ativa o **modo decisão dada** (ver abaixo): a decisão já
chegou batida de fora e o lastro é o racional escrito, não um spike nem uma pesquisa. O racional
inicial entre aspas é opcional — se vier, a skill parte dele e sonda só os buracos.
```

- [ ] **Step 3: Template — `Evidência` passa a listar três formas**

In `skills/zion-adr-new/SKILL.md`, substitua as linhas 52-54 do template:

```markdown
- **Evidência:** <um dos dois — o tipo casa com o risco da decisão>
    · execução (só se resolve rodando): `docs/adr/spikes/ADR-<n>-<slug>/` (dir com README.md + artefatos descartáveis)
    · conhecimento (documentável sem rodar): <URL ou caminho do artefato de pesquisa que sustenta a decisão>
```

por:

```markdown
- **Evidência:** <uma das três — o tipo casa com o risco da decisão>
    · execução (só se resolve rodando): `docs/adr/spikes/ADR-<n>-<slug>/` (dir com README.md + artefatos descartáveis)
    · conhecimento (documentável sem rodar): <URL ou caminho do artefato de pesquisa que sustenta a decisão>
    · decisão dada (chega batida de fora): Decisão dada: <autoridade/racional — quem decidiu e por quê>
```

- [ ] **Step 4: Inserir a seção "Modo decisão dada" (com os 4 probes)**

In `skills/zion-adr-new/SKILL.md`, imediatamente após a seção **## Modo substituir (supersessão) — dia 2** (que termina na linha 87, no bullet 3 sobre a §8) e antes de **## Convenção do spike dir (risco de execução)** (linha 89), insira:

```markdown
## Modo decisão dada

Disparado por `/zion-adr-new "<título>" --dada [ "<racional inicial>" ]` (ou pela Fase 2/3 de
`/zion-prd-spike` quando uma decisão é classificada como *decisão dada*). Não há spike dir nem fonte
de pesquisa: o lastro é o **racional escrito** — quem/que autoridade decidiu e por quê. O campo
`Evidência` recebe o marcador `Decisão dada: <racional>`.

**Micro-diálogo (procedimento compartilhado).** Antes de gravar o ADR, destile o racional com um
brainstorming curto e guiado: **uma pergunta de cada vez**, tom advisório, converge com
**confirmar / editar**. Autocontido — não delega ao `superpowers:brainstorming`. Não bloqueia: se
uma peça faltar, aponte o buraco e siga com o que há. Se o `--dada "..."` (ou a decisão trazida na
Fase 1 do spike) já vier com racional forte, use-o como ponto de partida e sonde **só os buracos** —
não repita o que já veio.

Quatro probes, cada um mapeando numa seção do ADR. Autoridade + restrição são o piso honesto (o "por
que é dada"); preteridas + trade-off enriquecem mas não travam:

| Probe | Pergunta | Alimenta |
|---|---|---|
| **Autoridade/fonte** | Quem ou o quê bateu o martelo? (política da org, contrato, restrição externa, lead) | Evidência + Contexto |
| **Restrição que força** | Por que isso é *dado* e não aberto? O que aconteceria se reabríssemos? | Contexto |
| **Opções preteridas** | Mesmo dada, o que ficou de fora? | Decisão |
| **Trade-off aceito** | O que fica mais difícil por aceitar sem provar? | Consequências |

**Ao gravar:** preencha `Evidência: Decisão dada: <racional destilado>` e as seções
Contexto / Decisão / Consequências com o que o diálogo destilou. **Sem spike dir, sem pesquisa.** O
`check-adr.sh` reconhece o marcador e confere só a **presença** do racional (achado
`decisao-dada-sem-racional` se vier vazio/placeholder) — a qualidade é o que o micro-diálogo produz.
```

- [ ] **Step 5: Nota de convenção — decisão dada não tem spike dir**

In `skills/zion-adr-new/SKILL.md`, na seção **## Convenção do spike dir (risco de execução)**, acrescente ao final da seção (após a linha 99, antes de `## Saída`) o parágrafo:

```markdown
> **Decisão dada não tem spike dir.** Quando o modo decisão dada está ativo, o campo `Evidência`
> aponta o racional escrito (`Decisão dada: …`), não um `docs/adr/spikes/…` — não crie diretório de
> spike nesse caso.
```

- [ ] **Step 6: Releitura e commit**

Releia `skills/zion-adr-new/SKILL.md` conferindo: `argument-hint` cita `--dada`; template lista três formas de `Evidência`; a seção "Modo decisão dada" conduz o micro-diálogo (4 probes) e grava o marcador; a nota deixa claro que não há spike dir.

```bash
git add skills/zion-adr-new/SKILL.md
git commit -m "feat(zion-adr-new): modo --dada com micro-diálogo de decisão dada"
```

---

## Task 5: `zion-prd-spike/SKILL.md` — 3 rótulos, ramo decisão dada, guarda advisory

**Files:**
- Modify: `skills/zion-prd-spike/SKILL.md:46-50` (Classificação por risco), `:52-66` (Fase 2/3), e a guarda advisory na Fase 1

- [ ] **Step 1: Fase 1 — Classificação por risco oferece três rótulos**

In `skills/zion-prd-spike/SKILL.md`, substitua o parágrafo **Classificação por risco (aconselha)** (linhas 46-50):

```markdown
**Classificação por risco (aconselha).** Fechadas as 2–3 decisões, **classifique cada uma** como
*risco de execução* ou *risco de conhecimento*, cada classificação com **uma linha de justificativa**
ancorada na heurística `#risco-do-spike` de `references/quality-rules.md`. Peça para **confirmar ou
editar** — mesmo padrão de convergência. Não bloqueie. O risco confirmado escolhe o meio da evidência
na Fase 2/3.
```

por (três rótulos + guarda advisory quando tudo vira dada):

```markdown
**Classificação por risco (aconselha).** Fechadas as 2–3 decisões, **classifique cada uma** em um de
**três** rótulos — *risco de execução*, *risco de conhecimento* ou *decisão dada* —, cada
classificação com **uma linha de justificativa** ancorada na heurística `#risco-do-spike` de
`references/quality-rules.md`. *Decisão dada* é a escolha que já chegou batida de fora (política da
org, restrição externa, padrão já estabelecido): não há dúvida a resolver rodando nem lendo, e o
lastro é o racional escrito. Peça para **confirmar ou editar** — mesmo padrão de convergência. Não
bloqueie. O risco confirmado escolhe o meio da evidência na Fase 2/3.

**Guarda advisory (aconselha).** Se **todas** as 2–3 decisões forem classificadas como *decisão
dada* — não sobrou nada a provar rodando nem lendo —, aponte que o valor do estágio de spike sumiu e
sugira revisar (talvez a lista não seja realmente estruturante, ou uma decisão dada esconda uma
dúvida). Só avisa, não bloqueia. Impede a classificação de virar escotilha para pular spikes
legítimos.
```

- [ ] **Step 2: Fase 2/3 — ramo decisão dada**

In `skills/zion-prd-spike/SKILL.md`, na seção **## Fase 2/3**, após o bullet **Risco de execução** (que termina na linha 64) e antes da linha `O número do ADR é conhecido na criação…` (linha 66), insira o terceiro bullet:

```markdown
- **Decisão dada** → sem spike, sem `deep-research`. Conduza o **micro-diálogo** de decisão dada — o
  procedimento compartilhado descrito em `zion-adr-new` (seção "Modo decisão dada"): quatro probes
  (autoridade, restrição que força, opções preteridas, trade-off aceito), uma pergunta por vez, tom
  advisório, converge com confirmar/editar; se a decisão já veio com racional forte, sonde só os
  buracos. Então invoque `zion-adr-new` com o título da decisão e preencha o campo **Evidência** com
  `Decisão dada: <racional destilado>`.
```

- [ ] **Step 3: Releitura e commit**

Releia `skills/zion-prd-spike/SKILL.md` conferindo: a Fase 1 oferece os três rótulos com justificativa ancorada em `#risco-do-spike`; a guarda advisory dispara quando tudo vira dada; a Fase 2/3 roda o ramo de decisão dada sem spike/pesquisa e delega a `zion-adr-new`.

```bash
git add skills/zion-prd-spike/SKILL.md
git commit -m "feat(zion-prd-spike): rótulo decisão dada na Fase 1 e ramo sem spike na 2/3"
```

---

## Task 6: Nota no `docs/como-usar.md`

**Files:**
- Modify: `docs/como-usar.md:149-152` (final do Estágio 2, após o parágrafo da Fase 4)

- [ ] **Step 1: Acrescentar o parágrafo de decisão dada ao Estágio 2**

In `docs/como-usar.md`, após o parágrafo da **Fase 4** do Estágio 2 (que termina na linha 152, `Cada ADR aceito vira **restrição** na seção 8 da PRD.`) e antes de `### Estágio 3` (linha 154), insira:

```markdown
**Decisão dada.** Nem toda decisão estruturante tem dúvida a provar: às vezes ela já chega batida de
fora (política da org, restrição externa, padrão já estabelecido). Aí o lastro é o **racional
escrito**, não um spike. Dois caminhos:

- **Direto:** `/zion-adr-new "Provider de nuvem" --dada` — a skill conduz um **micro-diálogo** curto
  (quem bateu o martelo, que restrição força, o que ficou de fora, que trade-off você aceita) e grava
  `Evidência: Decisão dada: <racional>`. Se você já passar o racional (`--dada "mandato de infra…"`),
  ela sonda só os buracos.
- **Via Fase 1 do spike:** classifique a decisão como *decisão dada* (o terceiro rótulo, ao lado de
  execução e conhecimento); a Fase 2/3 roda o mesmo micro-diálogo e registra o ADR sem spike nem
  pesquisa.

O `check-adr.sh` reconhece o marcador `Decisão dada:` e cobra só a **presença** do racional (não a
qualidade) — campo em branco segue erro.
```

- [ ] **Step 2: Commit**

```bash
git add docs/como-usar.md
git commit -m "docs(como-usar): documenta ADR de decisão dada (direto e via spike)"
```

---

## Task 7: Verificação final

**Files:** nenhum (só execução).

- [ ] **Step 1: Suíte mecânica de ADR verde**

Run: `bash scripts/test-check-adr.sh`
Expected: `test-check-adr: tudo verde` (clean segue limpo com o ADR-003; dirty acusa `decisao-dada-sem-racional`).

- [ ] **Step 2: Zero drift de assets**

Run: `bash scripts/check-assets.sh`
Expected: `check-assets: sem drift`.

- [ ] **Step 3: Suíte mecânica completa verde**

Run: `bash scripts/eval.sh`
Expected: roda prd → adr → trace → contract e termina com `eval: tudo verde`.

- [ ] **Step 4: Roteiro manual de releitura das skills**

Confirme, relendo:
- `zion-adr-new` conduz o micro-diálogo no modo `--dada` e grava `Evidência: Decisão dada: <racional>`.
- A Fase 1 do spike oferece os três rótulos (execução / conhecimento / decisão dada).
- A Fase 2/3 roda o ramo de decisão dada sem spike/pesquisa, delegando a `zion-adr-new`.
- A guarda advisory dispara quando **todas** as decisões viram dada.

- [ ] **Step 5: Roteiro manual de comportamento (2 casos)**

Simule mentalmente (ou com um turno de teste) os dois casos da spec:
1. Decisão dada com **racional forte no argumento** → a skill sonda só os buracos → ADR passa no `check-adr.sh`.
2. Decisão dada com **racional vago** → micro-diálogo completo → ADR passa no `check-adr.sh`.

Ambos devem produzir um ADR cujo `Evidência: Decisão dada: <racional>` tem racional não-vazio e não-placeholder.

---

## Self-Review

**Cobertura da spec:**
- Decisão 1 (3º tipo de 1ª classe em `#risco-do-spike`) → Task 3 Steps 1-2.
- Decisão 2 (dois pontos de entrada, sem assimetria: `--dada` e Fase 1) → Task 4 (flag) + Task 5 (Fase 1).
- Decisão 3 (LLM clarifica via micro-diálogo embutido, autocontido, não bloqueia) → Task 4 Step 4 (seção Modo decisão dada) + Task 5 Step 2 (referência compartilhada).
- Decisão 4 (nome "decisão dada"; marcador `Decisão dada: <racional>`) → Task 4 Step 3 (template) + Task 2 (script casa o marcador).
- Decisão 5 (check só presença) → Task 2 Step 2 (racional vazio/placeholder → achado; senão limpo).
- Os 4 probes → Task 4 Step 4 (tabela idêntica à da spec).
- §1 quality-rules (`#risco-do-spike` + `#criterios-de-conclusao`) → Task 3.
- §2 zion-adr-new (template, argumento, procedimento, nota de convenção) → Task 4.
- §3 zion-prd-spike (Fase 1 três rótulos, Fase 2/3 ramo, guarda advisory) → Task 5.
- §4 check-adr.sh (ramo antes de spike/conhecimento, `decisao-dada-sem-racional`, `sem-evidencia` continua) → Task 2.
- §5 fixtures + testes → Task 1.
- §6 docs/como-usar.md → Task 6.
- Verificação (test-check-adr, check-assets, eval, releitura, roteiro manual) → Task 7.
- YAGNI (sem novo script, sem delegar ao brainstorming, sem tocar check-prd/trace-prd/dia-2 além do sync do check-adr) → respeitado: nenhuma task cria script novo nem edita `check-prd.sh`/`trace-prd.sh`; a propagação do `check-adr.sh` a `zion-prd-evolve/references/` é só o sync já existente (Task 2 Step 4).

**Consistência de nomes:** achado `decisao-dada-sem-racional` (ASCII, sem acento — como os demais achados do script) usado consistentemente no script, no comentário-cabeçalho, no assert e na fixture; marcador `Decisão dada:` (com acento/maiúscula) idêntico no template, na fixture, no ramo do script (casado case-insensitive) e nas skills.

**Sem placeholders:** cada step de código traz o conteúdo real; os edits de prosa trazem o markdown final.
