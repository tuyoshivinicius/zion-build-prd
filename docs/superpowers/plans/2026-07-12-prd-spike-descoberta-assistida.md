# zion-prd-spike com descoberta assistida — Plano de Implementação

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Tornar a Fase 1 do `/zion-prd-spike` bidirecional — a IA propõe as 2–3 decisões estruturantes lendo `docs/discovery.md` quando o usuário não as traz, e aceita a lista pronta quando ele já as conhece — sem quebrar nenhum invariante do harness.

**Architecture:** Mudança confinada a **um único arquivo de prompt**, `.claude/skills/zion-prd-spike/SKILL.md`. Ajusta o `argument-hint` (obrigatório → opcional) e reescreve a seção "Fase 1" em quatro blocos (detecção de origem A/C/B · guarda de suficiência do discovery · apresentação enxuta · convergência). Fases 0, 2/3, 4 e a Saída ficam intactas, e a saída da Fase 1 mantém o formato — então nada a jusante muda.

**Tech Stack:** Markdown com front-matter YAML (formato de skill do Claude Code / superpowers). Não há framework de teste: comandos-skill são verificados **exercitando o comando** num cenário real e observando o comportamento (spec §7). O caso ponta-a-ponta é o próprio Zion Mermaid Editor (`docs/index.md`).

**Spec-fonte:** `docs/superpowers/specs/2026-07-12-prd-spike-descoberta-assistida-design.md`.

---

## File Structure

- **Modify:** `.claude/skills/zion-prd-spike/SKILL.md`
  - linha 4 — `argument-hint`;
  - linhas 20–23 — seção `## Fase 1 — Validar entrada bruta (aconselha)` → reescrita.
- Nenhum arquivo criado. Nenhum arquivo de estado. `.specify/prd/quality-rules.md` **não** é tocado (a Fase 4 e o `#criterios-de-conclusao` do spike não mudam).

**Nota sobre estilo:** o `SKILL.md` é terso e direto (frases imperativas, blocos curtos). O texto novo mantém essa voz — não introduza prosa longa nem exemplos de stack concreto (o stack só nasce no ADR, Fases 2/3).

---

## Task 1: Tornar o `argument-hint` opcional

**Files:**
- Modify: `.claude/skills/zion-prd-spike/SKILL.md:4`

- [ ] **Step 1: Editar a linha do front-matter**

Substituir a linha 4 exatamente:

De:
```yaml
argument-hint: "As 2–3 decisões estruturantes que mudam a PRD inteira"
```

Para:
```yaml
argument-hint: "Opcional: as 2–3 decisões estruturantes, se você já as conhece"
```

- [ ] **Step 2: Verificar o front-matter**

Run: `sed -n '1,9p' .claude/skills/zion-prd-spike/SKILL.md`
Expected: bloco YAML válido (abre e fecha com `---`), `argument-hint` agora começa com `"Opcional:`, demais chaves (`name`, `description`, `metadata`, `user-invocable`, `disable-model-invocation`) inalteradas.

- [ ] **Step 3: Commit**

```bash
git add .claude/skills/zion-prd-spike/SKILL.md
git commit -m "feat(zion-prd-spike): argument-hint opcional para a Fase 1 bidirecional"
```

---

## Task 2: Reescrever a Fase 1 em quatro blocos

**Files:**
- Modify: `.claude/skills/zion-prd-spike/SKILL.md:20-23`

- [ ] **Step 1: Substituir a seção da Fase 1**

Substituir integralmente as linhas 20–23 (o cabeçalho `## Fase 1 — Validar entrada bruta (aconselha)` e seu parágrafo) por:

```markdown
## Fase 1 — Levantar e validar as decisões estruturantes (aconselha)
As **2–3 decisões estruturantes** são as que mudam a PRD inteira, não dúvidas menores. Detecte a
origem pelo que o usuário trouxe no argumento e aplique a cada candidata — dada ou proposta — o
filtro "isso muda a PRD inteira?"; candidata que não passa, descarte ou consolide.

- **Caminho A — 2–3 decisões dadas:** não proponha; valide cada uma pelo filtro. Lista longa de
  dúvidas pequenas → sugira consolidar nas 2–3 realmente estruturantes.
- **Caminho C — 1–2 decisões dadas (híbrido):** trate as dadas como fixas e proponha **só as
  faltantes** até fechar 2–3, cada complemento ancorado num trecho de `docs/discovery.md`.
- **Caminho B — 0 decisões dadas:** proponha as 2–3, cada uma ancorada num trecho do discovery.

**Guarda de suficiência (só em B/C, antes de propor).** O discovery tem três peças: visão em 1
frase, persona nomeada, quadro Faz/Não faz. Se uma peça necessária faltar ou for vaga (ex.: sem o
quadro Faz/Não faz não há como isolar uma fronteira de integração), **não fabrique** candidatas para
preencher a cota: aponte qual peça falta e por quê ela trava a inferência, proponha só o que o texto
sustenta, e peça a peça faltante ou sugira rodar `/zion-prd-discovery`. Não bloqueie.

**Apresentação (B/C).** Entregue as 2–3 (ou só o complemento faltante) como recomendação direta e
enxuta, cada uma com uma linha de justificativa ancorada no discovery. Sem shortlist longa.

**Convergência (aconselha).** Peça ao usuário para **confirmar**, **editar** (trocar uma) ou
**substituir** (rejeitar todas e ditar as suas). Lista fraca — nenhuma passa no filtro, virou 4
dúvidas menores, ou ficou com 1 decisão só → aponte e sugira, mas a lista confirmada pelo usuário é a
que vale. Não bloqueie.
```

- [ ] **Step 2: Verificar a estrutura do arquivo**

Run: `grep -n '^## Fase' .claude/skills/zion-prd-spike/SKILL.md`
Expected: quatro cabeçalhos de fase, na ordem:
```
Fase 0 — Pré-requisito (aconselha)
Fase 1 — Levantar e validar as decisões estruturantes (aconselha)
Fase 2/3 — Formatar e auto-delegar
Fase 4 — Validar saída (aconselha)
```
(cinco fases preservadas; só o título e o corpo da Fase 1 mudaram).

- [ ] **Step 3: Verificar que a Saída e as demais fases não foram tocadas**

Run: `sed -n '/^## Fase 2\/3/,$p' .claude/skills/zion-prd-spike/SKILL.md`
Expected: as seções `Fase 2/3`, `Fase 4` e `Saída` idênticas ao original (delegação `deep-research` → `zion-adr-new`; critério `#criterios-de-conclusao`; ADRs viram restrição na §8).

- [ ] **Step 4: Commit**

```bash
git add .claude/skills/zion-prd-spike/SKILL.md
git commit -m "feat(zion-prd-spike): Fase 1 bidirecional (caminhos A/C/B + guarda + convergência)"
```

---

## Task 3: Verificação por cenários (exercitar o comando)

Sem teste unitário — exercite o `/zion-prd-spike` em cenários reais e observe. Use o Zion como caso
ponta-a-ponta. Para os cenários que dependem de `docs/discovery.md`, use o exemplo do guia prático
(`docs/como-usar-o-harness-prd.md`) como discovery de referência.

- [ ] **Step 1: Caminho A (usuário informa)**

Invoque `/zion-prd-spike` passando 3 decisões no argumento.
Expected: a IA **não propõe**; valida cada uma pelo filtro "isso muda a PRD inteira?" e segue para a
convergência. Nenhuma leitura de proposta.

- [ ] **Step 2: Caminho B (IA descobre)**

Invoque `/zion-prd-spike` **sem argumento**, com um `docs/discovery.md` rico (visão + persona + Faz/Não
faz).
Expected: a IA propõe 3 decisões, cada uma com uma linha de justificativa ancorada num trecho do
discovery, e abre a convergência (confirma/edita/substitui).

- [ ] **Step 3: Caminho C (híbrido)**

Invoque `/zion-prd-spike` passando **1 decisão**.
Expected: a IA mantém a decisão dada como fixa e propõe **só 1–2 faltantes**, fechando em 2–3.

- [ ] **Step 4: Guarda de suficiência (discovery magro)**

Invoque `/zion-prd-spike` sem argumento, com um `docs/discovery.md` **sem** o quadro Faz/Não faz.
Expected: a IA **aponta a lacuna** ("sem Faz/Não faz não isolo a fronteira de X"), propõe só o que o
texto sustenta, e pede a peça faltante ou sugere `/zion-prd-discovery`. **Não bloqueia** — se o usuário
mandar seguir, prossegue.

- [ ] **Step 5: Convergência com lista fraca**

Nos cenários acima, na convergência, **substitua** por uma dúvida menor (não estrutural).
Expected: a IA aponta que não passa no filtro e sugere consolidar, **mas aceita** a lista confirmada
pelo usuário.

- [ ] **Step 6: Fronteira intacta + downstream inalterado**

Em qualquer caminho, siga da Fase 1 para as Fases 2/3.
Expected: as decisões descrevem **eixos** (o-quê estrutural); o stack concreto só aparece no ADR
gerado por `zion-adr-new` (Fase 2/3), não no discovery nem em texto de PRD. As Fases 2/3 e 4 rodam sem
mudança — a saída da Fase 1 tem o mesmo formato de antes.

- [ ] **Step 7: Registrar evidência**

Para cada cenário que passar, anote a observação (uma linha) como evidência. Falha em qualquer
cenário → bug no texto do `SKILL.md`, corrija e reexercite o cenário.

---

## Self-Review (preenchido)

**1. Cobertura da spec:**
- §3.1 detecção A/C/B → Task 2, Step 1 (três bullets) + Task 3, Steps 1–3.
- §3.2 guarda de suficiência → Task 2, Step 1 (bloco "Guarda") + Task 3, Step 4.
- §3.3 apresentação enxuta → Task 2, Step 1 (bloco "Apresentação").
- §3.4 convergência → Task 2, Step 1 (bloco "Convergência") + Task 3, Step 5.
- §3 `argument-hint` opcional → Task 1.
- §2 invariantes (5 fases / fronteira / gate mole) → Task 2, Steps 2–3 + Task 3, Step 6.
- §5 quality-rules **não** tocado → afirmado em File Structure; nenhuma task o modifica.
- §7 cenários de aceitação → Task 3 (mapeamento 1:1).

**2. Placeholders:** nenhum "TBD/TODO". O texto da Fase 1 está completo e literal; os `<eixo>`
ilustrativos ficaram fora do texto do arquivo (só na spec, marcados como ilustrativos).

**3. Consistência de nomes:** títulos de fase batem entre Task 2 Step 1, Step 2 e o fluxo da spec
§4. "Caminho A/B/C", "guarda de suficiência", "convergência" usados de forma idêntica em spec e
plano.
