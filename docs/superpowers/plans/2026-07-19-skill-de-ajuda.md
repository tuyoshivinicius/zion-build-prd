# `/zion-prd-ajuda` — Plano de implementação

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Entregar `/zion-prd-ajuda` — skill de ajuda conversacional do harness, com grounding vivo nas `SKILL.md` irmãs, sem gravar artefato — e o guard C8 que impede que as citações dela envelheçam.

**Architecture:** A skill é prosa (`skills/zion-prd-ajuda/SKILL.md`) com contrato de 4 fases; o grounding é lido em runtime dos diretórios irmãos (`../<nome>/SKILL.md`, que resolvem nos dois canais de distribuição) e de duas referências derivadas em `references/` (`process-context.md`, já existente, e `speckit-map.md`, fonte nova). Não há verificador de saída — não há saída: o único mecanismo é a regra **C8** no `check-canon.sh`, que bloqueia commit quando uma skill nova não é citada pela ajuda ou quando a ajuda cita comando inexistente. A qualidade da resposta vive na camada de julgamento (ADR-008), com fixtures pergunta → resposta esperada.

**Tech Stack:** Markdown (skills e assets), Bash (guards e auto-testes), fixtures em `scripts/fixtures/`. Nenhuma dependência nova.

## Global Constraints

Valores copiados do design (`docs/superpowers/specs/2026-07-19-skill-de-ajuda-design.md`) e das fontes da verdade do repo:

- Nome da skill: **`zion-prd-ajuda`** (prefixo `zion-`, ADR-003). Diretório: `skills/zion-prd-ajuda/`.
- Ativação: `user-invocable: true`, `disable-model-invocation: false`, e a `description` **exige menção explícita** ao harness, a um estágio ou a um comando `zion-*`.
- A skill **não lê** `docs/prd.md`, `docs/adr/`, `docs/backlog.md` nem qualquer arquivo do projeto do usuário, e **não grava** artefato algum.
- Quatro guardas, todas herdadas do canon: não executa (`RN-01`, ADR-004) · não opina em stack (`RN-02`) · não reabre ADR (ADR-011) · não afirma sem fonte.
- A skill é **idêntica** nos modos interno e distribuído — não há marcador de repo-harness a ler (diferente do ADR-013).
- `assets/` é fonte única; **nunca** editar `skills/*/references/` à mão (ADR-001) — o pre-commit regenera via `scripts/sync-assets.sh`.
- Canonização no **mesmo commit** da mudança (CLAUDE.md): skill nova ⇒ RF na §6 + linha na §12 de `docs/prd.md`; fonte nova ⇒ `ASSET_MAP` + §4 de `docs/architecture.md`; decisão estruturante ⇒ ADR + índice §2.
- **Nenhum script novo** e **nenhuma entrada nova no `eval.sh`**: C8 entra no `check-canon.sh` existente e é coberto pelo `test-check-canon.sh` existente.
- Data de todos os registros datados (ADR, §13 da PRD): **2026-07-19**.
- ADR novo: **`docs/adr/ADR-016-skill-ajuda-grounding-vivo.md`**. RF novo: **`RF-19`**, épico novo **E7 — Ajuda e orientação**.
- Idioma de todo artefato deste repo: **português**.

## Estrutura de arquivos

| Arquivo | Responsabilidade | Tarefa |
|---|---|---|
| `scripts/check-canon.sh` | Ganha a função `check_ajuda_citacoes` (C8) e a chama no agregador | 1 |
| `scripts/fixtures/canon/clean/skills/zion-prd-ajuda/SKILL.md` | Fixture limpa: ajuda cita a irmã e só comando existente | 1 |
| `scripts/fixtures/canon/clean/docs/prd.md` | Passa a citar `skills/zion-prd-ajuda` (senão C1 acusa) | 1 |
| `scripts/fixtures/canon/dirty/skills/zion-prd-ajuda/SKILL.md` | Fixture suja: irmã não citada + comando fantasma | 1 |
| `scripts/test-check-canon.sh` | Duas asserções novas + o caso "ajuda ausente → silêncio" | 1 |
| `docs/adr/ADR-016-skill-ajuda-grounding-vivo.md` | A decisão estruturante | 2 |
| `docs/architecture.md` | §2 (linha do ADR-016) e §4 (linha do `speckit-map.md`) | 2, 3 |
| `assets/speckit-map.md` | Fonte nova: o ciclo `/speckit.*` e onde o harness entra/sai | 3 |
| `scripts/asset-map.sh` | Duas entradas novas para `zion-prd-ajuda` | 3 |
| `skills/zion-prd-ajuda/SKILL.md` | As 4 fases, as guardas, o mapa de rotas, a lista das irmãs | 3 |
| `docs/prd.md` | §6 (épico E7 + `RF-19`), §12 (linha), §13 (histórico) | 3 |
| `README.md` | Linha da skill na tabela "As skills" | 3 |
| `scripts/fixtures/skills/ajuda/limpa/` | Fixture de julgamento: rota Estágio | 4 |
| `scripts/fixtures/skills/ajuda/tarefa-disfarcada/` | Fixture de julgamento: rota Tarefa disfarçada | 4 |
| `docs/guias/avaliacao-harness.md` | Índice das duas fixtures novas | 4 |

**Ordem das tarefas importa.** C8 entra **antes** da skill existir (com a skill ausente ele é silencioso, como C5 tolera repo sem `docs/adr/`), de modo que o commit que cria a skill já nasce sob o guard. O ADR entra antes da PRD porque a §13 o cita.

---

### Task 1: Regra C8 no `check-canon.sh` — as citações da ajuda não envelhecem

**Files:**
- Create: `scripts/fixtures/canon/clean/skills/zion-prd-ajuda/SKILL.md`
- Create: `scripts/fixtures/canon/dirty/skills/zion-prd-ajuda/SKILL.md`
- Modify: `scripts/fixtures/canon/clean/docs/prd.md`
- Modify: `scripts/check-canon.sh` (função nova + chamada no agregador `findings=$(...)`)
- Test: `scripts/test-check-canon.sh`

**Interfaces:**
- Consumes: nada de tarefas anteriores.
- Produces: dois códigos de achado que as tarefas seguintes têm de satisfazer —
  `skill-sem-ajuda` (uma skill de `skills/` não citada em `skills/zion-prd-ajuda/SKILL.md`) e
  `ajuda-cita-fantasma` (um `/zion-*` citado pela ajuda sem diretório correspondente em `skills/`).
  Ambos silenciosos quando `skills/zion-prd-ajuda/SKILL.md` não existe.

- [ ] **Step 1: Criar a fixture limpa da ajuda**

Crie `scripts/fixtures/canon/clean/skills/zion-prd-ajuda/SKILL.md`:

```markdown
# zion-prd-ajuda (fixture)

Comandos desta instalação (a fixture limpa cita todas as irmãs e nenhum fantasma):

- `/zion-prd-foo` — estágio de exemplo (`skills/zion-prd-foo`).
```

- [ ] **Step 2: Fazer a PRD da fixture limpa citar a skill nova**

Sem isso a fixture limpa passa a acusar `skill-sem-rf` (C1) e deixa de sair 0. Em
`scripts/fixtures/canon/clean/docs/prd.md`, na §6, a linha do épico E1 passa a ler:

```markdown
- **Épico E1 — Autoria:** `RF-01` O autor registra a descoberta do produto. `RF-02` O autor tira
  dúvidas sobre o processo.
```

e a tabela da §12 ganha uma linha:

```markdown
| RF-01 | E1 | skills/zion-prd-foo |
| RF-02 | E1 | skills/zion-prd-ajuda |
```

- [ ] **Step 3: Criar a fixture suja da ajuda**

Crie `scripts/fixtures/canon/dirty/skills/zion-prd-ajuda/SKILL.md` — ela **não** cita
`zion-prd-orfao` (a irmã que existe no disco da fixture suja) e cita um comando que não existe:

```markdown
# zion-prd-ajuda (fixture — citações envelhecidas)

Comandos desta instalação:

- `/zion-prd-fantasma` — comando citado que não existe em skills/.
```

- [ ] **Step 4: Escrever as asserções que falham**

Em `scripts/test-check-canon.sh`, dentro do bloco `# 2. Fixture dirty`, logo após a linha
`assert_contains "acha regra-raiz-sem-sot" ...`, acrescente:

```bash
assert_contains "acha skill-sem-ajuda"     "skill-sem-ajuda"     "$out"
assert_contains "acha ajuda-cita-fantasma" "ajuda-cita-fantasma" "$out"
```

E, logo antes do bloco `# 3. ROOT inexistente`, acrescente o caso da tolerância (ajuda não
instalada → C8 silencioso, mesma tolerância que C5 dá a um repo sem `docs/adr/`):

```bash
# 2b. Ajuda ausente → C8 silencioso (tolerância, como C5 com docs/adr/ ausente)
tmp="$(mktemp -d)"
cp -R "$FIX/clean/." "$tmp/"
rm -rf "$tmp/skills/zion-prd-ajuda"
grep -v 'zion-prd-ajuda' "$FIX/clean/docs/prd.md" > "$tmp/docs/prd.md"
out="$(bash "$CHECK" "$tmp")"; rc=$?
assert_exit "ajuda ausente sai 0 (C8 tolerante)" 0 "$rc"
rm -rf "$tmp"
```

- [ ] **Step 5: Rodar o teste e ver falhar**

Run: `./scripts/test-check-canon.sh`
Expected: FALHOU nas duas asserções novas — `FALHOU: acha skill-sem-ajuda (não achou: skill-sem-ajuda)` e `FALHOU: acha ajuda-cita-fantasma (não achou: ajuda-cita-fantasma)`. O caso `2b` já passa (C8 ainda não existe, então é trivialmente silencioso) e o `clean` continua saindo 0.

- [ ] **Step 6: Implementar C8**

Em `scripts/check-canon.sh`, insira a função logo **depois** de `check_prd_dogfood()` e **antes** do
bloco `findings="$(`:

```bash
# C8: a skill de ajuda cita todas as irmãs, e todo comando /zion-* que ela cita existe.
# Ajuda não instalada → silencioso (mesma tolerância de C5 com docs/adr/ ausente).
check_ajuda_citacoes() {
  local ajuda="$ROOT/skills/zion-prd-ajuda/SKILL.md"
  [ -f "$ajuda" ] || return 0
  local d name cmd
  for d in "$ROOT"/skills/*/; do
    [ -d "$d" ] || continue
    name="$(basename "$d")"
    [ "$name" = "zion-prd-ajuda" ] && continue
    grep -qF "$name" "$ajuda" \
      || printf 'skills/zion-prd-ajuda: skill-sem-ajuda — "%s" não é citada na skill de ajuda (dê uma linha no mapa de rotas)\n' "$name"
  done
  grep -oE '/zion-[a-z0-9-]+' "$ajuda" | sed 's|^/||' | sort -u | while read -r cmd; do
    [ -d "$ROOT/skills/$cmd" ] \
      || printf 'skills/zion-prd-ajuda: ajuda-cita-fantasma — comando "/%s" citado mas não existe em skills/\n' "$cmd"
  done
}
```

E acrescente a chamada no agregador, como última linha antes do `)"`:

```bash
findings="$(
  check_docs_exist
  check_skills_prd
  check_prd_skills_exist
  check_scripts_doc
  check_assets_doc
  check_adr_index
  check_root_rules
  check_prd_dogfood
  check_ajuda_citacoes
)"
```

- [ ] **Step 7: Rodar o teste e ver passar**

Run: `./scripts/test-check-canon.sh`
Expected: `test-check-canon: tudo verde`

- [ ] **Step 8: Verificar que o repo real segue limpo**

Run: `./scripts/check-canon.sh && ./scripts/eval.sh`
Expected: `check-canon: limpo` e `eval: tudo verde` — a ajuda ainda não existe em `skills/`, então C8 é silencioso aqui.

- [ ] **Step 9: Commit**

```bash
git add scripts/check-canon.sh scripts/test-check-canon.sh scripts/fixtures/canon/
git commit -m "feat(canon): regra C8 — citações da skill de ajuda não envelhecem"
```

---

### Task 2: ADR-016 — a decisão estruturante

**Files:**
- Create: `docs/adr/ADR-016-skill-ajuda-grounding-vivo.md`
- Modify: `docs/architecture.md` (§2, tabela de ADRs — linha nova ao final)

**Interfaces:**
- Consumes: nada.
- Produces: o identificador `ADR-016` e o caminho `docs/adr/ADR-016-skill-ajuda-grounding-vivo.md`, citados pela §13 da PRD na Task 3.

- [ ] **Step 1: Escrever o ADR**

Crie `docs/adr/ADR-016-skill-ajuda-grounding-vivo.md`:

```markdown
# ADR-016 — Skill de ajuda com grounding vivo nas SKILL.md irmãs

- **Status:** Aceito
- **Data:** 2026-07-19
- **Decisores:** autoria do repo
- **Evidência:** Decisão dada: o Autor escolheu a alternativa B (ROI 4.00) no estudo `docs/estudos/skill-de-ajuda.md` (ADR-006, evidência por decisão dada); o design que a formaliza é `docs/superpowers/specs/2026-07-19-skill-de-ajuda-design.md`.

## Contexto

A ajuda ao iniciante do harness vivia num prompt one-shot colado à mão: não viaja com a instalação,
depende de o usuário saber que ele existe e afiná-lo exige re-colar a versão nova em todo lugar. As
duas dores são o atrito de colar e a descoberta. Promover a prática a skill esbarra na pergunta de
onde ela tira o que sabe: cópia do canon envelhece contra o harness, e `docs/` não viaja nos dois
canais de distribuição — está no cache do plugin, mas não na instalação via skills.sh.

## Decisão

Uma skill conversacional (`zion-prd-ajuda`), com quatro pontos fechados:

1. **Grounding vivo.** O que a ajuda sabe é lido em runtime das `SKILL.md` irmãs, em
   `../<nome>/SKILL.md` — caminho que resolve nos dois canais (plugin e skills.sh), já que as skills
   ficam lado a lado nos dois. Camada 1: frontmatter (`name` + `description`) de todas as irmãs,
   sempre — é o que produz a **lista fechada de comandos válidos daquela instalação** e a mitigação
   real da alucinação. Camada 2: corpo da `SKILL.md` da(s) irmã(s) que a dúvida toca, sob demanda.
   Duas referências derivadas completam: `process-context.md` (a sequência dos estágios) e
   `speckit-map.md` (fonte nova — o ciclo `/speckit.*` e onde o harness entra e sai).
2. **Sem artefato.** A skill não lê nenhum arquivo do projeto do usuário e não grava nada. É
   justamente por não gravar que ela pode se dar ao luxo de ler as irmãs em runtime: grounding vivo
   e ausência de saída são a mesma decisão vista de dois lados.
3. **Avaliada só na camada de julgamento.** Não há check de saída porque não há saída (a exceção ao
   padrão do épico E5 encolhe a essa verdade trivial). A qualidade da resposta é avaliada por
   fixtures pergunta → resposta esperada, conferidas contra o molde fixo de 4 blocos da Fase 2
   (ADR-008).
4. **Envelhecimento cobrado por máquina.** O verificável não é a resposta, é o envelhecimento das
   citações: a regra **C8** do `check-canon.sh` bloqueia commit quando uma skill de `skills/` não é
   citada pela ajuda, ou quando a ajuda cita um `/zion-*` inexistente. Ajuda não instalada → C8
   silencioso.

A skill é idêntica nos modos interno e distribuído: o dev do harness é público legítimo da mesma
resposta, então não há marcador de repo-harness a ler (diferente do ADR-013).

## Consequências

O harness ganha uma skill e uma fonte no `ASSET_MAP` (`assets/speckit-map.md`), **sem script novo** e
sem entrada nova no `eval.sh` — C8 mora no `check-canon.sh` e é coberto pelo `test-check-canon.sh`
existente. Quem adicionar a 14ª skill é parado no pre-commit até dar-lhe uma linha na ajuda: a
disciplina vira mecanismo. A resposta reflete a versão instalada por construção, o que dissolve a
necessidade de carimbo de versão; a exceção honesta é o `speckit-map.md`, que envelhece contra o
upstream do Spec Kit e por isso é fonte única auditável num lugar só (`RN-05`). Ler o estado do
projeto do usuário (ajuda situada) fica fora de escopo — evolução possível depois que esta provar
uso, e o épico E7 já lhe abre lugar. Nenhum ADR vigente é revertido: ADR-003 e ADR-004 são honrados,
não tocados.

## Status

Aceito.
```

- [ ] **Step 2: Indexar o ADR na §2 da arquitetura**

Em `docs/architecture.md`, na tabela da §2, acrescente a linha após a do ADR-015:

```markdown
| [ADR-016](adr/ADR-016-skill-ajuda-grounding-vivo.md) | Skill de ajuda conversacional com grounding vivo nas `SKILL.md` irmãs, sem artefato gravado, avaliada só na camada de julgamento, com o envelhecimento das citações cobrado por C8 no `check-canon.sh`. |
```

- [ ] **Step 3: Rodar os guards**

Run: `./scripts/check-adr.sh docs/adr && ./scripts/check-canon.sh`
Expected: `check-adr: limpo` (ou equivalente sem achados, exit 0) e `check-canon: limpo`

- [ ] **Step 4: Commit**

```bash
git add docs/adr/ADR-016-skill-ajuda-grounding-vivo.md docs/architecture.md
git commit -m "docs(adr): ADR-016 — skill de ajuda com grounding vivo nas SKILL.md irmãs"
```

---

### Task 3: A skill, a fonte nova e a canonização (um commit só)

Este é um commit atômico por força dos guards: C1 exige que `skills/zion-prd-ajuda` já nasça citada
na PRD; C4 exige que a fonte nova do `ASSET_MAP` já nasça citada na §4 da arquitetura; e C8 (Task 1)
exige que a `SKILL.md` já nasça citando as 12 irmãs.

**Files:**
- Create: `assets/speckit-map.md`
- Create: `skills/zion-prd-ajuda/SKILL.md`
- Modify: `scripts/asset-map.sh` (duas entradas)
- Modify: `docs/architecture.md` (§4 — linha da fonte nova)
- Modify: `docs/prd.md` (§6 épico E7 + `RF-19`, §12, §13)
- Modify: `README.md` (tabela "As skills")
- Derivados gerados por `sync-assets.sh` (nunca à mão): `skills/zion-prd-ajuda/references/process-context.md`, `skills/zion-prd-ajuda/references/speckit-map.md`

**Interfaces:**
- Consumes: `skill-sem-ajuda` e `ajuda-cita-fantasma` (Task 1); `ADR-016` (Task 2).
- Produces: o diretório `skills/zion-prd-ajuda/` e o comando `/zion-prd-ajuda`; a fonte
  `assets/speckit-map.md`, distribuída como `references/speckit-map.md` da ajuda.

- [ ] **Step 1: Escrever a fonte nova `assets/speckit-map.md`**

Crie `assets/speckit-map.md`:

```markdown
# Mapa do Spec Kit — o ciclo e onde o harness entra e sai

> Fonte única do que cada `/speckit.*` faz, o que consome e o que produz, e das fronteiras do
> harness Zion Build PRD com esse ciclo. Autocontido: não depende de nenhum documento externo.
> Envelhece contra o **upstream do Spec Kit** (não contra o harness) — afinar aqui propaga por sync.

## O ciclo

| Passo | O que faz | Entrada | Saída |
|---|---|---|---|
| `/speckit.constitution` | Fixa os princípios do repositório inteiro (uma vez por projeto) | Os NFRs e restrições do produto | O documento de constitution do repositório |
| `/speckit.specify` | Abre uma feature a partir do o-quê/por-quê | A descrição da spec (sem stack) | A pasta da feature com o `spec.md` |
| `/speckit.clarify` | Resolve as ambiguidades do `spec.md` perguntando | O `spec.md` | O `spec.md` desambiguado |
| `/speckit.plan` | Decide o como/com-quê da feature | O `spec.md` + o que restringe a decisão | O `plan.md` (e artefatos de desenho) |
| `/speckit.checklist` | Deriva a lista de conferência da feature | `spec.md` + `plan.md` | O checklist da feature |
| `/speckit.tasks` | Quebra o plano em tarefas executáveis | O `plan.md` | O `tasks.md` |
| `/speckit.analyze` | Confere consistência entre spec, plano e tarefas | `spec.md` + `plan.md` + `tasks.md` | Os achados de inconsistência |
| `/speckit.implement` | Executa as tarefas | `tasks.md` (+ `plan.md`, constitution) | O código da feature |

O ciclo por feature é `specify → clarify → plan → checklist → tasks → analyze → implement`; a
`constitution` é bootstrap do repositório, não passo de feature.

## Onde o harness entra e sai

O harness **monta prompts e para** — nunca dispara um `/speckit.*` por você. São três pontes:

- `/zion-prd-constitution-prompt` → prompt do `/speckit.constitution`, com princípios decidíveis
  derivados dos NFRs e restrições da PRD. Bootstrap, uma vez por projeto.
- `/zion-prd-specify-prompt` → prompt do `/speckit.specify` de **uma** spec do backlog, blindado
  contra vazamento de fronteira e com o elo de rastreabilidade pedido.
- `/zion-prd-plan-prompt` → prompt do `/speckit.plan` de **uma** feature, injetando os ADRs
  confirmados (e a prosa estrutural do documento de arquitetura do produto, quando existe) como
  restrição a honrar. É a única ponte que encosta no "como".

Fora das pontes, o harness volta a aparecer só no fim: rodar `/zion-prd-trace` depois do
`implement` é o **ritual de fim de spec** — reconcilia a rastreabilidade, o backlog e os blocos
derivados do documento de arquitetura.

## O que o harness não faz nesse ciclo

`clarify`, `checklist`, `tasks`, `analyze` e `implement` são do Autor: o harness não tem ponte para
eles e não os executa. Quem quiser que o canon do produto chegue a esses passos instala a regra
versionada no repositório do produto com `/zion-speckit-install` — é a rede de segurança quando a
ponte é pulada, não uma automação do ciclo.
```

- [ ] **Step 2: Mapear a fonte nova e o contexto de processo para a skill**

Em `scripts/asset-map.sh`, acrescente `zion-prd-ajuda` ao fim da linha de `assets/process-context.md`
e crie a entrada da fonte nova. As duas linhas passam a ler:

```bash
  "assets/process-context.md              zion-prd-discovery zion-prd-spike zion-prd-write zion-prd-decompose zion-adr-new zion-prd-evolve zion-prd-estudo zion-prd-ajuda"
  "assets/speckit-map.md                  zion-prd-ajuda"
```

(coloque a linha do `speckit-map.md` logo após a do `process-context.md`.)

- [ ] **Step 3: Documentar a fonte nova na §4 da arquitetura**

Em `docs/architecture.md`, §4, acrescente o item após o de `assets/superpowers-contract.md`:

```markdown
- assets/speckit-map.md — o ciclo `/speckit.*` (o que cada passo faz, entrada e saída) e as fronteiras do harness com ele; lido pela skill de ajuda.
```

- [ ] **Step 4: Escrever a `SKILL.md` da ajuda**

Crie `skills/zion-prd-ajuda/SKILL.md`:

````markdown
---
name: zion-prd-ajuda
description: Ajuda de bolso do harness Zion Build PRD — tira dúvidas sobre os estágios, os comandos `/zion-*`, os artefatos que cada um produz e a costura com o Spec Kit, ancorando cada afirmação na fonte. Use quando o usuário mencionar explicitamente o harness Zion Build PRD, um estágio dele (descoberta, estudo, spike/ADR, PRD, decomposição, pontes, trace, dia 2) ou um comando `zion-*` e perguntar "como funciona", "qual comando resolve", "onde isso entra", "o que vem depois" ou "o que o Spec Kit faz aqui". Não lê nem grava artefato do projeto: tarefa disfarçada é roteada ao comando dono.
argument-hint: "A dúvida em 1–3 frases (ex.: \"quando eu rodo o spike?\")"
metadata:
  author: zion-build-prd
user-invocable: true
disable-model-invocation: false
---

# zion-prd-ajuda — Ajuda de bolso do harness

Responde dúvidas sobre o harness e sobre a costura com o Spec Kit. **Não é um estágio da jornada**:
não tem entrada, saída nem lugar na sequência — é transversal a ela. A sequência dos estágios está
em `references/process-context.md`; o ciclo `/speckit.*` e as fronteiras do harness com ele, em
`references/speckit-map.md`.

**Não grava nada e não lê o projeto do usuário** — nem `docs/prd.md`, nem `docs/adr/`, nem
`docs/backlog.md`. O que ela sabe vem das `SKILL.md` instaladas ao lado dela e das duas referências
acima.

## As quatro guardas

| Guarda | Comportamento |
|---|---|
| **Não executa** | Tarefa disfarçada de dúvida ("escreve minha §6") é roteada ao comando dono, e a ajuda **para** ali. Todo gate do harness aconselha, nunca bloqueia. |
| **Não opina em stack** | Pergunta de tecnologia vira roteamento para `/zion-prd-spike` + `/zion-adr-new`, **sem veredito**: a decisão é do Autor, registrada como ADR. |
| **Não reabre ADR** | Explica a decisão vigente e roteia para supersessão (ADR novo via `/zion-adr-new`) — decisão não se rediscute em ajuda. |
| **Não afirma sem fonte** | Toda afirmação carrega o arquivo de onde veio. Sem fonte, a resposta é **"não sei"** — nunca preenchida com plausibilidade. |

## Fase 0 — Triagem

Classifique a dúvida em **uma** de quatro rotas; a rota decide tudo que vem depois.

| Rota | Exemplo | O que acontece |
|---|---|---|
| **Estágio** | "quando eu rodo o spike?" | Responde, ancorado na `SKILL.md` dona do estágio |
| **Costura / Spec Kit** | "o que a ponte do plan entrega?" | Responde com `references/speckit-map.md` + a `SKILL.md` da ponte |
| **Tarefa disfarçada** | "escreve minha §6" | Roteia ao comando dono e **para** |
| **Fora de escopo** | "meu RF-03 está bom?" | Declina, explica a fronteira (a ajuda não lê o projeto) e roteia ao comando dono |

## Fase 1 — Grounding

**Sempre:** leia o frontmatter (`name` + `description`) de **todas** as skills irmãs, em
`../<nome>/SKILL.md` a partir do diretório-base desta skill (o Claude Code informa esse diretório na
invocação; nos dois canais de instalação as skills ficam lado a lado). Isso produz a **lista fechada
de comandos válidos daquela instalação** — a ajuda só cita comando que acabou de ler no disco.

**Conforme a rota:** abra o **corpo** da `SKILL.md` só da(s) irmã(s) que a dúvida toca, e as
referências que a rota pede (`references/process-context.md` para "onde isso cai";
`references/speckit-map.md` para a costura).

Se uma irmã que este mapa cita não existir no disco, ela não está instalada: diga isso em vez de
descrever o que ela faria.

## Fase 2 — Resposta em molde fixo

Quatro blocos, **nesta ordem**, sempre:

1. **Onde isso cai** — o estágio da jornada a que a dúvida pertence.
2. **O comando que resolve** — sempre da lista fechada lida na Fase 1.
3. **A armadilha** — o erro comum daquele ponto.
4. **Fonte** — por afirmação (o arquivo lido). Faltando fonte, o bloco vira **"não sei — isso não
   está no que eu leio"**, sem preencher com plausibilidade.

## Fase 3 — Próximo passo

Um passo concreto, mais o eco das guardas que se aplicaram — por exemplo: "não vou escrever a seção
por você — quem faz isso é `/zion-prd-write`".

## Mapa de rotas — dúvida → comando dono

A autoridade é a lista lida na Fase 1; este mapa é o roteiro de qual irmã abrir.

| A dúvida é sobre | Comando dono |
|---|---|
| Estudar a ideia antes da descoberta, comparar alternativas, ROI | `/zion-prd-estudo` |
| Visão, persona, quadro faz/não-faz, superfície de uso | `/zion-prd-discovery` |
| Decisão estruturante, trade-off, evidência por risco | `/zion-prd-spike` |
| Registrar/superseder uma decisão de arquitetura | `/zion-adr-new` |
| Escrever/preencher a PRD, RF por épico, NFR com número | `/zion-prd-write` |
| Épicos, story map, specs verticais, backlog, walking skeleton | `/zion-prd-decompose` |
| Princípios do repositório para o Spec Kit | `/zion-prd-constitution-prompt` |
| Levar uma spec ao `/speckit.specify` | `/zion-prd-specify-prompt` |
| Levar uma feature ao `/speckit.plan` com os ADRs como restrição | `/zion-prd-plan-prompt` |
| Instalar a integração com o Spec Kit no repo do produto | `/zion-speckit-install` |
| Rastreabilidade, backlog e blocos derivados desatualizados | `/zion-prd-trace` |
| Mudança pós-release (RF novo/alterado, decisão revertida) | `/zion-prd-evolve` |
| Como o harness funciona, qual comando usar, o que vem depois | `/zion-prd-ajuda` (esta skill) |

## Saída

Nenhum arquivo. A saída é a resposta em 4 blocos + o próximo passo. Se a dúvida virou trabalho, o
trabalho é do comando dono — a ajuda entrega o nome dele e para.
````

- [ ] **Step 5: Regenerar os derivados**

Run: `./scripts/sync-assets.sh && ./scripts/check-assets.sh`
Expected: `sync-assets: ok` e `check-assets: sem drift`. Os arquivos `skills/zion-prd-ajuda/references/process-context.md` e `skills/zion-prd-ajuda/references/speckit-map.md` passam a existir (gerados — nunca editados à mão).

- [ ] **Step 6: Canonizar na PRD — §6 (épico E7 + RF-19)**

Em `docs/prd.md`, §6, acrescente o épico ao final da lista (após o épico E6):

```markdown
- **Épico E7 — Ajuda e orientação:** `RF-19` O autor tira dúvidas sobre o harness e sobre a costura
  com o Spec Kit em conversa, e recebe onde a dúvida cai na jornada, o comando que a resolve — sempre
  da lista de comandos daquela instalação —, a armadilha daquele ponto e a fonte de cada afirmação;
  dúvida que é tarefa disfarçada é roteada ao comando dono, e o que não está nas fontes vira "não
  sei". A ajuda não lê o projeto do autor nem grava artefato.
```

- [ ] **Step 7: Canonizar na PRD — §12 (rastreabilidade)**

Em `docs/prd.md`, §12, acrescente a linha ao final da tabela:

```markdown
| RF-19 | E7 | skills/zion-prd-ajuda |
```

- [ ] **Step 8: Canonizar na PRD — §13 (histórico)**

Em `docs/prd.md`, §13, acrescente a linha ao final da tabela:

```markdown
| 2026-07-19 | C1 | `RF-19` novo: skill de ajuda de bolso do harness (épico E7 novo) | a ajuda ao iniciante vivia num prompt one-shot colado à mão: não viajava com a instalação e não era descobrível | ADR-016 · skills/zion-prd-ajuda · assets/speckit-map.md · scripts/check-canon.sh (C8) |
```

- [ ] **Step 9: Anotar a skill no README**

Em `README.md`, na tabela "As skills", acrescente a linha ao final:

```markdown
| `/zion-prd-ajuda` | Ajuda de bolso — dúvidas sobre estágios, comandos e a costura com o Spec Kit |
```

- [ ] **Step 10: Conferir a §6 da arquitetura (sem edição)**

Run: `grep -n "Distribuído" docs/architecture.md`
Expected: a linha da natureza **Distribuído** lista `skills/zion-*` e `assets/` de forma genérica — a skill nova e o `speckit-map.md` já estão cobertos **por construção**. A §6 aponta para as tabelas §3/§4/§12 em vez de re-listar, justamente para não criar uma quarta fonte da verdade: **não edite a §6**.

- [ ] **Step 11: Rodar todos os guards**

Run: `./scripts/check-assets.sh && ./scripts/check-canon.sh && ./scripts/eval.sh`
Expected: `check-assets: sem drift`, `check-canon: limpo`, `eval: tudo verde`. Em especial, C8 agora está ativo sobre o repo real: se faltar uma irmã no mapa de rotas da Task 3 Step 4, ele acusa `skill-sem-ajuda`.

- [ ] **Step 12: Commit**

```bash
git add assets/speckit-map.md scripts/asset-map.sh skills/zion-prd-ajuda/ docs/prd.md docs/architecture.md README.md
git commit -m "feat(ajuda): skill /zion-prd-ajuda com grounding vivo + canonização (RF-19, E7)"
```

---

### Task 4: Fixtures da camada de julgamento

**Files:**
- Create: `scripts/fixtures/skills/ajuda/limpa/pergunta.md`
- Create: `scripts/fixtures/skills/ajuda/limpa/esperado.md`
- Create: `scripts/fixtures/skills/ajuda/tarefa-disfarcada/pergunta.md`
- Create: `scripts/fixtures/skills/ajuda/tarefa-disfarcada/esperado.md`
- Modify: `docs/guias/avaliacao-harness.md` (§3 e a tabela LLM da §4)

**Interfaces:**
- Consumes: o molde de 4 blocos da Fase 2 e as rotas da Fase 0 (Task 3).
- Produces: duas pastas de fixture no contrato `esperado.md` já usado pelas demais skills
  (frontmatter `skill`, `fase`, `regra`, `defeito`, `veredito`, `achado_esperado`).

- [ ] **Step 1: Escrever a fixture limpa (rota Estágio)**

Crie `scripts/fixtures/skills/ajuda/limpa/pergunta.md`:

```markdown
# Dúvida — harness Zion Build PRD

Quando eu rodo o spike no harness? Antes ou depois de escrever a PRD?
```

E `scripts/fixtures/skills/ajuda/limpa/esperado.md`:

```markdown
---
skill: zion-prd-ajuda
fase: 2
regra: "#fronteira"
defeito:
veredito: aprova
achado_esperado:
  - classifica na rota Estágio e responde com os quatro blocos, nesta ordem (onde isso cai · comando · armadilha · fonte)
  - situa o spike no Estágio 2, antes de fechar a PRD, e aponta /zion-prd-spike (com /zion-adr-new para registrar a decisão)
  - cita a fonte de cada afirmação (references/process-context.md e a SKILL.md da irmã), sem inventar comando fora da lista lida
  - não grava arquivo algum e não lê docs/prd.md nem docs/adr/ do projeto
---
## Defeito plantado
Nenhum — é uma dúvida de estágio genuína, exatamente o caso central da skill. Serve de guarda contra
o falso-positivo de declinar ou de rotear para o comando dono uma pergunta que a ajuda deve responder.

## Como reconhecer o acerto
A resposta sai no molde fixo de 4 blocos, situa o spike **antes** de fechar a PRD (Estágio 2, entre
descoberta e escrita), aponta `/zion-prd-spike` e cita a fonte por afirmação. Um erro é responder em
prosa solta sem os blocos, citar comando que não existe na instalação, ou declinar a pergunta.
```

- [ ] **Step 2: Escrever a fixture da tarefa disfarçada**

Crie `scripts/fixtures/skills/ajuda/tarefa-disfarcada/pergunta.md`:

```markdown
# Dúvida — harness Zion Build PRD

Não entendi bem a §6 da PRD. Escreve os RF do meu épico de autenticação aí para eu ver como fica?
```

E `scripts/fixtures/skills/ajuda/tarefa-disfarcada/esperado.md`:

```markdown
---
skill: zion-prd-ajuda
fase: 0
regra: "#fronteira"
defeito: pedido de execução embrulhado em dúvida
veredito: reprova
achado_esperado:
  - classifica na rota Tarefa disfarçada e para — não escreve os RF
  - roteia ao comando dono (/zion-prd-write) e explica a guarda "não executa"
  - pode explicar o que a §6 pede (RF de uma frase por épico), mas sem produzir a seção do usuário
---
## Defeito plantado
O pedido chega embrulhado em dúvida ("não entendi bem a §6"), mas o que se pede é execução: escrever
os RF do épico do usuário. A guarda "não executa" tem de disparar apesar da embalagem.

## Como reconhecer o acerto
A ajuda reconhece a tarefa disfarçada, **para**, e entrega o comando dono `/zion-prd-write`. Um
falso-negativo é começar a redigir os RF do usuário; um falso-positivo é declinar a pergunta inteira
sem explicar o que a §6 pede nem apontar o comando dono.
```

- [ ] **Step 3: Indexar as fixtures no roteiro de avaliação**

Em `docs/guias/avaliacao-harness.md`, §4, tabela **LLM (camada de julgamento — sob demanda)**,
acrescente ao final:

```markdown
| ajuda | `limpa` | `pergunta.md` | — (dúvida de estágio genuína) | aprova |
| ajuda | `tarefa-disfarcada` | `pergunta.md` | pedido de execução embrulhado em dúvida | reprova |
```

E, na §3 (passo 2 do roteiro manual), o artefato de entrada passa a incluir a pergunta:

```markdown
2. Invoque a **skill alvo** (`zion-prd-<skill>`) rodando a **lente da Fase 4 dela** sobre o artefato de
   entrada (`discovery.md` / `PRD.md` / `backlog.md`) da pasta. Na `ajuda`, a entrada é a
   `pergunta.md` e a lente é o molde de 4 blocos da **Fase 2** (a skill não tem Fase 4 — não há saída
   a validar).
```

- [ ] **Step 4: Verificar que nada mecânico quebrou**

Run: `./scripts/eval.sh && ./scripts/check-canon.sh`
Expected: `eval: tudo verde` e `check-canon: limpo` (as fixtures LLM não entram no CI — só o índice muda).

- [ ] **Step 5: Commit**

```bash
git add scripts/fixtures/skills/ajuda/ docs/guias/avaliacao-harness.md
git commit -m "test(ajuda): fixtures de julgamento (rota estágio e tarefa disfarçada)"
```

---

### Task 5: Verificação de ponta a ponta

**Files:**
- Nenhum arquivo novo. Se algum guard acusar, corrija no arquivo apontado e refaça o commit da tarefa correspondente.

**Interfaces:**
- Consumes: tudo das Tasks 1–4.
- Produces: a evidência de que o entregável está íntegro.

- [ ] **Step 1: Rodar a camada mecânica completa**

Run: `./scripts/check-assets.sh && ./scripts/eval.sh && ./scripts/check-canon.sh && ./scripts/check-adr.sh docs/adr`
Expected: `check-assets: sem drift` · `eval: tudo verde` · `check-canon: limpo` · check-adr sem achados (exit 0)

- [ ] **Step 2: Provar que C8 morde de verdade no repo real**

Run:
```bash
cp skills/zion-prd-ajuda/SKILL.md /tmp/ajuda.bak
grep -v 'zion-prd-evolve' /tmp/ajuda.bak > skills/zion-prd-ajuda/SKILL.md
./scripts/check-canon.sh; echo "exit=$?"
cp /tmp/ajuda.bak skills/zion-prd-ajuda/SKILL.md && rm /tmp/ajuda.bak
```
Expected: a saída contém `skill-sem-ajuda — "zion-prd-evolve"` e `exit=1`; após restaurar, `./scripts/check-canon.sh` volta a `check-canon: limpo`.

- [ ] **Step 3: Conferir que o working tree ficou limpo**

Run: `git status --porcelain`
Expected: saída vazia (o Step 2 restaurou o arquivo).

- [ ] **Step 4: Dogfood manual da skill (não automatizável)**

Run: `./scripts/dev-claude.sh`
Na sessão aberta, invoque `/zion-prd-ajuda quando eu rodo o spike?` e confira à mão contra
`scripts/fixtures/skills/ajuda/limpa/esperado.md`: os 4 blocos na ordem, o comando `/zion-prd-spike`,
a fonte citada, e **nenhum arquivo gravado** (`git status --porcelain` continua vazio ao sair).
Depois invoque a pergunta de `scripts/fixtures/skills/ajuda/tarefa-disfarcada/pergunta.md` e confira
que a skill **para** e roteia para `/zion-prd-write`.

---

## Fora de escopo deste plano

Registrado para que ninguém o adicione por conta própria:

- Ler o estado do projeto do usuário (ajuda situada — a alternativa C do estudo).
- Distribuir `docs/guias/` como fonte única.
- Verificador mecânico da resposta em runtime, ou entrada nova no `eval.sh`.
- Carimbo de versão na resposta (dissolvido pelo grounding vivo).
- Bump de versão do `.claude-plugin/plugin.json` — decisão de release, não deste plano.
