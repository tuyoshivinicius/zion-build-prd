# Design — `docs/backlog.md`: escopo e estado das fatias por máquina

> **Origem:** pedido do usuário — visibilidade do escopo de cada fatia após o decompose,
> rastreado por mecanismo determinístico; visibilidade de quais fatias já foram implementadas;
> spec do Spec Kit nascendo com o nome da fatia; e uma skill de fim de implementação que
> atualiza o estado da fatia.
> **Data:** 2026-07-18.
> **Escopo:** um artefato novo `docs/backlog.md` (backlog de fatias, semeado pelo
> `/zion-prd-decompose`), um reconciliador novo `scripts/trace-backlog.sh` (espelho do
> `trace-prd.sh`, no grão da fatia), slug cunhado no decompose e carregado até o
> `/speckit.specify` pela ponte, e o `/zion-prd-trace` estendido para reconciliar os dois
> artefatos — tornando "rodar `/zion-prd-trace`" o ritual de fim de fatia.

---

## 1. Problema

Depois do `/zion-prd-decompose`, as fatias existem só como **saída de conversa**: o brainstorming
produz o backlog no chat e nada o persiste. O único rastreio determinístico do harness é a §12 da
PRD, que é **orientada a RF** (`RF-xx ↔ specs/###`, reconciliada por `trace-prd.sh`). A fatia — a
unidade real de trabalho, a que vira spec, branch e demo — não tem:

- **escopo persistido** (quais RFs cobre, qual a demo ponta-a-ponta que a define);
- **nome canônico** — quem batiza a spec é o `/speckit.specify` (`specs/###-nome`), sem vínculo
  garantido com a fatia que a originou;
- **status próprio** — "quais fatias já foram implementadas?" só se responde inferindo pela §12,
  RF a RF, de trás para frente;
- **gatilho de atualização no fim da implementação** — o guia manda rodar `/zion-prd-trace` após
  cada fatia, mas o trace só enxerga RFs.

O padrão para resolver já existe no repositório: artefato **derivado**, com **dono único** de
máquina, reconciliável a qualquer momento (`trace-prd.sh` ↔ §12). Falta aplicá-lo à fatia.

## 2. Princípio organizador

**A fatia vira artefato de primeira classe, com o mesmo contrato da §12:** um arquivo versionado
(`docs/backlog.md`), colunas humanas preenchidas na decomposição e preservadas pelo script,
colunas de máquina (Spec, Status) recomputadas por um reconciliador de dono único
(`trace-backlog.sh`). O elo fatia↔spec é **determinístico por construção**: o decompose cunha o
slug, a ponte do specify instrui o Spec Kit a usá-lo, e o reconciliador casa
`specs/###-<slug>` ⇔ slug por sufixo.

Gates continuam aconselhando: divergências viram **avisos**, o git é o desfazer, `--check` é a
leitura read-only para CI e Fases 4.

## 3. Decisões estruturais (tomadas no brainstorming)

1. **Backlog em arquivo próprio** `docs/backlog.md` — não incha a PRD; a §12 segue RF-orientada.
2. **Slug sem número:** o decompose cunha `preview-ao-vivo`; o Spec Kit prefixa seu contador
   (`specs/003-preview-ao-vivo`); o casamento é por sufixo. Não briga com o contador do Spec Kit.
3. **A skill de fim de implementação é o `/zion-prd-trace` estendido** — status derivado por
   máquina (do `tasks.md`), zero estado declarado à mão. Nenhuma skill nova.
4. **Reconciliador separado** `trace-backlog.sh` (abordagem A) — um script, um artefato;
   `trace-prd.sh` intocado; testável isoladamente.

## 4. O artefato — `docs/backlog.md`

Template novo em `assets/templates/backlog.md`. O arquivo tem **uma tabela canônica** — a
**primeira tabela** do arquivo — da qual o script é dono. Todo o resto do arquivo (notas, story
map, texto livre) é preservado intacto pelo reconciliador.

```markdown
| Fatia (slug) | Demo (1 frase) | RFs | Release | Spec | Status |
|--------------|----------------|-----|---------|------|--------|
| preview-ao-vivo | Digitar mermaid, ver prévia, recarregar e continuar | RF-01, RF-05 | R0 | `specs/001-preview-ao-vivo` | ● implementada |
| erros-sintaxe | Erro de sintaxe apontado sem perder a prévia | RF-02 | R1 | — | ☐ pendente |
```

- **Colunas humanas** (preenchidas pelo decompose/humano; **preservadas** pelo script): Fatia,
  Demo, RFs, Release. A **ordem das linhas é a fila de prioridade** — o script nunca reordena.
- **Colunas de máquina** (recomputadas; nunca editadas à mão): Spec e Status.
- **Status por fatia** (mesma derivação do `spec_status()` do `trace-prd.sh`, no grão da fatia):
  - `☐ pendente` — nenhum diretório em `specs/` casa com o slug;
  - `◐ em spec` — a spec existe; `tasks.md` ausente ou com ao menos um `- [ ]` aberto;
  - `● implementada` — `tasks.md` existe e nenhum `- [ ]` aberto.
- A coluna **Demo (1 frase)** *é* o escopo visível da fatia — literalmente o teste INVEST
  ("esta fatia, sozinha, dá uma demo ponta-a-ponta?").
- Slug: kebab-case, curto, estável (ele vira o nome da spec e da branch do Spec Kit).

## 5. O reconciliador — `scripts/trace-backlog.sh`

Espelho do `trace-prd.sh` em interface e contrato:

### 5.1 Interface

```
trace-backlog.sh <backlog-file> <specs-dir> [--check]
```

- `<backlog-file>` — normalmente `docs/backlog.md`.
- `<specs-dir>` — normalmente `specs/`. Ausente ou vazio → bootstrap (Spec `—`, tudo ☐).
- `--check` — read-only: reporta drift/avisos e sai `1` sem gravar; sem a flag, reconcilia e
  grava (git é o desfazer).

### 5.2 Casamento fatia↔spec

Um diretório `specs/D` casa com a fatia de slug `S` quando `D` termina em `-S` precedido do
prefixo numérico do Spec Kit (`###-S`) — ou é exatamente `S` (spec criada sem contador). Cada
diretório casa com **no máximo uma** fatia (o slug inteiro, não substring: `preview` não casa
`specs/001-preview-ao-vivo`).

### 5.3 Fontes por coluna (conciliação in-place)

| Coluna | Fonte de verdade | Comportamento |
|---|---|---|
| Fatia (slug) | humano/decompose | preservada |
| Demo | humano/decompose | preservada |
| RFs | humano/decompose | preservada |
| Release | humano/decompose | preservada |
| Spec | diretório casado em `specs/` | recomputada (`—` se nenhum) |
| Status | `tasks.md` da spec casada | recomputada |

### 5.4 Avisos (advisórios; exit `1`)

- **Fatia sem spec** — informativo; permanece ☐ pendente.
- **Spec órfã** — diretório `specs/###-nome` que não casa com nenhum slug do backlog: ou o slug
  divergiu (typo), ou a spec nasceu fora do backlog → registre a fatia ou renomeie.
- **Divergência de escopo** — os RFs declarados na linha da fatia ≠ o conjunto da linha
  `**RF cobertos:**` do `spec.md` casado: corrija a spec ou o backlog (o humano decide qual).
- **Slug duplicado** no backlog — a primeira linha vence; as demais são ignoradas com aviso.
- **Colisão de casamento** — dois diretórios casando com o mesmo slug: o de menor prefixo
  numérico vence, com aviso.

### 5.5 Contrato de saída

- Exit `0` (limpo) · `1` (drift/avisos) · `2` (erro de uso/ambiente: arquivo inexistente,
  backlog sem tabela canônica — mensagem acionável apontando o template).
- Resumo legível: linhas atualizadas, transições de status (`preview-ao-vivo: ◐ → ●`), avisos, e
  o **quadro de fatias**: contagem `●/◐/☐` + a próxima fatia `☐` da fila (primeira pendente na
  ordem do arquivo).

## 6. `/zion-prd-decompose` — cunha o slug e semeia o backlog

- **Fase 2/3:** o brainstorming, ao fatiar, passa a **cunhar um slug kebab-case por fatia**,
  junto da demo de 1 frase e dos RFs cobertos.
- **Fase 4:** além de semear a §12 via `trace-prd.sh` (como hoje), grava `docs/backlog.md` a
  partir de `references/backlog.md` (template) com as linhas humanas preenchidas, e roda
  `bash references/trace-backlog.sh docs/backlog.md specs` em bootstrap. Backlog **já existente**
  → não sobrescreve: atualiza as linhas humanas via conversa e deixa a reconciliação com o script
  (idempotência, como nos demais estágios).
- **Modo `--epico E<k>` (dia 2):** fatias `●` implementadas continuam **intocáveis** (restrição do
  re-fatiamento, como hoje); só as linhas do épico afetado mudam; ao final, mandar rodar
  `/zion-prd-trace` (que reconcilia §12 **e** backlog).

## 7. `/zion-prd-specify-prompt` — carrega o slug até o Spec Kit

- **Fase 1:** resolve a fatia pedida **contra o backlog**: o usuário pode pedir em prosa
  ("a fatia do preview"); a skill localiza a linha, confirma slug/demo/RFs. Fatia fora do
  backlog → avisa ("registre no backlog via `/zion-prd-decompose` ou adicione a linha") e
  pergunta se segue — não bloqueia.
- **Fase 2/3:** o prompt montado ganha duas instruções novas, além das atuais:
  - **nome da feature = slug** — "use `<slug>` como nome curto da feature/branch" (a spec nasce
    `specs/###-<slug>`, fechando o elo por construção);
  - a linha `**RF cobertos:**` (já existente hoje) é preenchida com **os RFs da linha da fatia**
    — fechando o elo de escopo dos dois lados.
- Como hoje, instruímos via prompt e parseamos o que aterrissa: se o Spec Kit batizar diferente,
  o `trace-backlog.sh` acusa **spec órfã** + **fatia sem spec** e o humano renomeia.

## 8. `/zion-prd-trace` — a skill do fim da implementação

- **Fase 0:** passa a aconselhar também sobre `docs/backlog.md` ausente ("recomendo
  `/zion-prd-decompose` antes"); backlog ausente **não** impede a reconciliação da §12 (e
  vice-versa: PRD ausente não impede a do backlog).
- **Fase 2/3:** roda **os dois** reconciliadores:
  `bash references/trace-prd.sh docs/PRD.md specs` e
  `bash references/trace-backlog.sh docs/backlog.md specs`.
- **Fase 4:** ecoa os resumos/avisos de ambos e o **quadro de fatias** (`●/◐/☐` + próxima da
  fila) — a visibilidade pedida, num comando só.
- **Ritual de fim de fatia:** rodar `/zion-prd-trace` após `/speckit.implement`/`converge` passa
  a ser documentado como o fechamento da fatia (guia Passo 6, como-usar, saída das pontes).

## 9. Distribuição (padrão assets/sync)

- **Canônicos:** `scripts/trace-backlog.sh` e `assets/templates/backlog.md`.
- **`scripts/asset-map.sh`:**
  - `scripts/trace-backlog.sh → zion-prd-trace zion-prd-decompose`;
  - `assets/templates/backlog.md → zion-prd-decompose`.

  A ponte `zion-prd-specify-prompt` só **lê** `docs/backlog.md` (arquivo do projeto consumidor) —
  não precisa do script.
- Sync/check/pre-commit hook: nada de novo na infraestrutura — entradas novas no mapa.

## 10. Auto-teste + fixtures

`scripts/test-trace-backlog.sh` + `scripts/fixtures/backlog/`, no CI ao lado dos testes
existentes. Casos:

- bootstrap sem `specs/` → Spec `—`, tudo ☐;
- casamento por sufixo (`specs/003-preview-ao-vivo` ⇔ `preview-ao-vivo`), inclusive slug que é
  sufixo de outro (não casa por substring);
- spec com `tasks.md` completo → `●`; com `- [ ]` aberto → `◐`; sem spec → `☐`;
- spec órfã → aviso; divergência RFs fatia × `**RF cobertos:**` → aviso; slug duplicado → aviso;
- preservação das colunas humanas, da ordem das linhas e do texto fora da tabela canônica;
- `--check` read-only: exit `1` com drift, `0` em dia, arquivo intocado;
- backlog sem tabela canônica → exit `2` com mensagem acionável.

## 11. Superfície de mudança

| Arquivo | Mudança |
|---|---|
| `scripts/trace-backlog.sh` | **Novo.** Reconciliador do backlog (casamento por sufixo, status por `tasks.md`, avisos, `--check`). |
| `assets/templates/backlog.md` | **Novo.** Template do backlog (tabela canônica + nota de dono único). |
| `skills/zion-prd-decompose/SKILL.md` | Fase 2/3 cunha slug por fatia; Fase 4 semeia `docs/backlog.md` e roda `trace-backlog.sh`; `--epico` preserva fatias `●`. |
| `skills/zion-prd-specify-prompt/SKILL.md` | Fase 1 resolve a fatia contra o backlog; prompt instrui nome-da-feature = slug e RFs da fatia na linha `**RF cobertos:**`. |
| `skills/zion-prd-trace/SKILL.md` | Roda os dois reconciliadores; ecoa quadro de fatias; documenta o ritual de fim de fatia. |
| `assets/quality-rules.md` | `#anatomia-specify` (instrução do slug) + `#criterios-de-conclusao` do decompose (backlog semeado por máquina). |
| `scripts/asset-map.sh` | Entradas novas (trace-backlog.sh, templates/backlog.md). |
| `scripts/test-trace-backlog.sh` + `scripts/fixtures/backlog/` | **Novo.** Auto-teste com fixtures. |
| `.github/workflows/check-assets.yml` | Passo que roda o auto-teste do trace-backlog. |
| `docs/guia-prd-para-spec-kit.md` | Passo 4 (backlog como artefato de saída), Passo 5b (slug no specify), Passo 6 (trace reconcilia os dois; ritual de fim de fatia). |
| `docs/como-usar.md`, `README.md`, `assets/process-context.md` | Backlog no mapa de comandos/estágios; exemplo do Zion com slugs. |
| `skills/*/references/` | Regenerados pelo sync (não editados à mão). |

## 12. Fora de escopo (consciente)

- Forçar o **número** da spec (`###`) — o contador é do Spec Kit; o elo é pelo sufixo/slug.
- Skill nova de encerramento (`/zion-prd-done`) — descartada no brainstorming; o ritual é o
  `/zion-prd-trace`.
- Status declarado à mão (ex.: "aceita", "em QA") — só os 3 estados mecânicos derivados do
  `tasks.md`.
- Sincronizar §12 ↔ backlog entre si (ex.: derivar a coluna Feature/Spec da §12 a partir do
  backlog) — cada reconciliador lê `specs/` diretamente; a fonte comum é o filesystem.
- Automação no projeto consumidor (hook/CI rodando `--check` lá) — o comando existe; instalar é
  decisão do consumidor.
