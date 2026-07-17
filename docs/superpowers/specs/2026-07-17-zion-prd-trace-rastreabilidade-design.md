# Design — `/zion-prd-trace`: rastreabilidade com mecânica (R2)

> **Origem:** recomendação R2 de `docs/critica-zion-build-prd.md` §5.2 (absorve o núcleo da R4).
> **Data:** 2026-07-17.
> **Escopo:** um comando `/zion-prd-trace` + `scripts/trace-prd.sh` que reconcilia a tabela de
> rastreabilidade da PRD (seção 12) a partir das `specs/*/spec.md`, rodável a qualquer momento,
> substituindo a promessa "tabela viva" mantida à mão por um artefato derivado por máquina.

---

## 1. Problema

O Passo 4 injeta a tabela `RF-xx ↔ specs/###` na PRD e o Passo 6 promete mantê-la "viva"
(`guia-prd-para-spec-kit.md:264`), mas **nenhum estágio, skill ou checklist tem a tarefa de
atualizá-la**. Um artefato manual sem dono e sem gatilho morre — e morreu: no único projeto que usou
o método ponta-a-ponta (`zion-mermaid-editor-app`), a tabela nasceu com **17/17 linhas "☐ pendente"**
e a PRD foi tocada em **exatamente 1 commit** em toda a história, com 3 fatias já implementadas
(crítica métrica b1; F2/H6).

Duas causas estruturais:

- **Sem mecânica de manutenção** (F2/H6): existe skill para *injetar* a tabela (`decompose`), nenhuma
  para *reconciliá-la* com `specs/` depois. É o único artefato do método que exige manutenção
  contínua e o único sem comando.
- **Sem elo RF↔spec legível por máquina** (F5, alvo da R4): as specs reais não declaram quais RF
  cobrem de forma parseável — a spec 001 não cita nenhum RF; a 002 só menciona "RF-15" solto na
  prosa. A cadeia RF→spec depende exclusivamente da tabela manual — o artefato que morre.

Como "specs são a fonte da tabela", a reconciliação **precisa** desse elo. Portanto este design
**absorve o núcleo da R4** (a spec declarar seus RF numa linha parseável) como fundação de R2 —
sem ele, o `trace` não tem em que se ancorar.

A ironia diagnosticada vale de novo: o repositório **já tem** o padrão de enforcement mecânico
(`check-assets.sh` + hook + CI, e agora `check-prd.sh` da R1) — falta aplicá-lo à rastreabilidade.

## 2. Princípio organizador

**A tabela é um artefato derivado, não um documento mantido à mão.** Regenerada por comando a partir
da fonte de verdade — o mesmo relacionamento que `references/` tem com `assets/`. A "tabela viva"
passa a significar *"viva enquanto você roda `/zion-prd-trace`"*, não viva por magia: cumpre a
promessa **e** a rebaixa honestamente ao mesmo tempo.

O `trace` **verifica e reconcilia**; o humano **decide**. Coerente com "gates aconselham, não
bloqueiam" — mesmo sendo a única peça do harness que escreve num artefato humano, o git é o desfazer
e o modo `--check` oferece a leitura read-only.

## 3. Decisões estruturais (tomadas no discovery)

1. **Construir a mecânica** (não só rebaixar a promessa): `/zion-prd-trace` + script, e ajustar o
   texto do guia para prometer só o que a ferramenta cumpre.
2. **Specs são a fonte; a tabela é derivada.** Cada `spec.md` declara os RF que cobre; o `trace`
   varre as specs e reconcilia a tabela a partir daí. Rastreabilidade forward mora ao lado do que ela
   descreve.
3. **Status em 3 estados mecânicos via `tasks.md`** — o artefato que o próprio Spec Kit gera.
4. **Conciliação in-place:** RF/Descrição/Épico são regeneradas da §6, Feature/Spec e Status das
   specs; só Release (sem fonte de máquina) é preservada da tabela existente. Idempotente.
5. **Convenção RF na spec = linha rotulada** `**RF cobertos:** RF-xx, ...` no corpo (visível,
   greppável, fácil de instruir no prompt do specify).
6. **`trace` é o dono único da tabela**; `decompose` o invoca para semear (corrige o H6).
7. **Escrita in-place + resumo; modo `--check` read-only** para Fases 4 de outras skills e CI.

## 4. A convenção RF↔spec (núcleo da R4, absorvido)

Cada `spec.md` declara os RF cobertos numa linha rotulada no corpo:

```
**RF cobertos:** RF-04, RF-05, RF-06
```

- **Quem produz:** a ponte `zion-prd-specify-prompt` (Fase 2/3) passa a **pedir essa linha no
  prompt** do specify — *"inclua uma linha `**RF cobertos:** ...` com os RF que esta fatia cobre"*.
  O `spec.md` é gerado pelo `/speckit.specify`, que **o usuário roda** (o harness para na ponte);
  não controlamos o template interno do Spec Kit — só instruímos via prompt e parseamos o que
  aterrissa. A linha rotulada é tolerante: o `trace` a acha onde quer que ela caia.
- **Quem consome:** o `trace` grepa `RF cobertos:` seguido de um ou mais `RF-\d+` em
  `specs/*/spec.md`, montando o mapa `spec → [RF]`.
- **Fronteira preservada:** declarar *quais RF* a fatia cobre é o-quê/rastreabilidade, não stack —
  não fere a fronteira sem-stack do specify.

## 5. `scripts/trace-prd.sh` — o reconciliador

Script **separado** do `check-prd.sh`: aquele só lê e aconselha; este **escreve** na PRD. A
separação read-only × mutação é a razão de não ser um modo do `check-prd`.

### 5.1 Interface

```
trace-prd.sh <prd-file> <specs-dir> [--check]
```

- `<prd-file>` — normalmente `docs/PRD.md`.
- `<specs-dir>` — normalmente `specs/`. Ausente ou vazio → bootstrap (tudo pendente).
- `--check` — read-only: reporta drift/avisos e sai `1` sem gravar; sem a flag, reconcilia e grava.

### 5.2 Fontes por coluna (conciliação in-place)

| Coluna | Fonte de verdade | Comportamento do trace |
|---|---|---|
| RF | seção 6 da PRD | regenerada (§6 é a fonte) |
| Descrição | seção 6 da PRD | regenerada |
| Épico | seção 6 da PRD | regenerada |
| Feature / Spec | specs declarando o RF | recomputada |
| Status | `tasks.md` da spec | recomputada |
| Release | tabela existente (§12) | **preservada** (sem fonte de máquina) |

O parsing da seção 6 (RF-xx agrupado por Épico E#) reaproveita a lógica que o `check-prd.sh` já tem
(`check_rf`). Release é preservada casando o `RF-xx` na tabela existente; RF novo sem Release entra
em branco para o humano preencher.

### 5.3 Status (3 estados mecânicos)

- **☐ pendente** — nenhuma spec declara o RF.
- **◐ em spec** — existe spec declarando o RF, mas `specs/###/tasks.md` está ausente ou tem ao menos
  uma tarefa `- [ ]` aberta.
- **● implementada** — `specs/###/tasks.md` existe e **todas** as tarefas estão marcadas `- [x]`
  (nenhuma `- [ ]`).

Quando mais de uma spec cobre o mesmo RF, a coluna Feature/Spec lista as specs e o status assume a
menos avançada (conservador).

### 5.4 Modos e saída

- **Padrão (reconcilia + grava):** reescreve a seção 12 e imprime um resumo — linhas adicionadas,
  transições de status (`RF-04: ◐ → ●`), e os avisos abaixo. O git é o desfazer.
- **`--check` (read-only):** computa o que *seria* a tabela; se difere da atual ou há avisos, imprime
  o delta e sai `1`; senão sai `0`. Não toca no arquivo. Consumível por Fases 4 e CI.

### 5.5 Avisos (o valor de reconciliação além de escrever)

- **RF órfão:** spec declara um `RF-xx` que não existe na seção 6 da PRD (typo ou decisão perdida).
- **Spec intraçável:** `spec.md` sem a linha `**RF cobertos:**` — não entra na cadeia.
- **RF descoberto:** RF in-scope na §6 sem nenhuma spec — informativo, permanece pendente.

### 5.6 Contrato de saída

- Exit `0` (sem drift/avisos no `--check`; gravação limpa no modo padrão) · `1` (drift/avisos) ·
  `2` (erro de uso/ambiente: PRD sem seção 12/6, arquivo inexistente).
- Resumo legível ao final: `trace-prd: N linha(s) atualizada(s), M aviso(s)` ou `trace-prd: em dia`.

## 6. A skill `/zion-prd-trace` (nova — 9ª skill)

Wrapper fino no contrato de 5 fases, user-invocable, **rodável a qualquer momento**:

- **Fase 0 (aconselha):** `docs/PRD.md` deve existir com a seção 6 (e idealmente a 12). Faltando →
  avisa e pergunta se segue.
- **Fase 1:** sem texto novo — trabalha sobre `docs/PRD.md` + `specs/`.
- **Fase 2/3:** roda `bash references/trace-prd.sh docs/PRD.md specs`.
- **Fase 4 (aconselha):** ecoa o resumo/avisos com autoridade; tom advisório ("reconcilie ou
  justifique os órfãos"), sem reverter. Aponta a próxima ação (rodar de novo após a próxima fatia).

## 7. Dono único: `decompose` delega

`zion-prd-decompose` Fase 4 **para de injetar a tabela à mão** e passa a rodar
`bash references/trace-prd.sh docs/PRD.md specs` para semear a tabela. Na hora do `decompose` ainda
não há specs → o bootstrap produz a tabela semente (RF/Descrição/Épico da §6, tudo pendente,
Feature/Spec em branco). Um único caminho de código cria e atualiza a tabela → **idempotente**
(corrige o H6: um segundo `decompose` reconcilia em vez de duplicar). Release é preenchida pelo
humano/brainstorming após o bootstrap.

`trace-prd.sh` é sincronizado para `references/` de **ambas** as skills (`zion-prd-trace` e
`zion-prd-decompose`) para que o `decompose` rode o script diretamente, sem depender da cadeia de
auto-delegação skill→skill (evita o modo de falha do H3).

## 8. Distribuição (padrão R1/assets)

- **Canônico:** `scripts/trace-prd.sh`, ao lado de `check-prd.sh` e `check-assets.sh`.
- **Sync:** `scripts/asset-map.sh` ganha `scripts/trace-prd.sh → zion-prd-trace zion-prd-decompose`.
  O `sync-assets.sh` copia para `skills/<skill>/references/trace-prd.sh`; `check-assets.sh` vigia o
  drift; o pre-commit hook regenera. Nada de novo na infraestrutura — só uma linha no mapa.
- **Sem dependência de `quality-rules.md`:** o `trace` não usa denylist; depende só da PRD e de
  `specs/`, ambos no projeto consumidor onde ele roda.

## 9. Auto-teste + fixtures (semente da R7)

- `scripts/test-trace-prd.sh` + `scripts/fixtures/trace/`: uma PRD sintética (com §6 e §12) + uma
  árvore `specs/` com casos conhecidos:
  - uma spec com `tasks.md` 100% `[x]` → esperado ● implementada;
  - uma spec com `tasks.md` com tarefa aberta → esperado ◐ em spec;
  - um RF in-scope sem spec → esperado ☐ pendente;
  - uma spec declarando um RF fora da §6 → esperado aviso "RF órfão";
  - uma spec sem a linha `**RF cobertos:**` → esperado aviso "intraçável";
  - preservação da coluna Release entre reconciliações.
- Afirma a tabela resultante + exit code, em modo padrão e `--check`.
- Novo job/passo no workflow de CI (`.github/workflows/check-assets.yml`), ao lado do
  `test-check-prd`.

Cada fixture já é metade de uma futura fixture de avaliação da R7 — de graça.

## 10. Superfície de mudança

| Arquivo | Mudança |
|---|---|
| `scripts/trace-prd.sh` | **Novo.** O reconciliador (parse §6 + varredura de specs + escrita da §12; modos padrão/`--check`). |
| `skills/zion-prd-trace/SKILL.md` | **Nova skill** (9ª): wrapper de 5 fases sobre o script. |
| `skills/zion-prd-decompose/SKILL.md` | Fase 4 roda `trace-prd.sh` (semeia) em vez de injetar a tabela à mão. |
| `skills/zion-prd-specify-prompt/SKILL.md` | Fase 2/3: o prompt do specify pede a linha `**RF cobertos:**`. |
| `assets/quality-rules.md` | `#anatomia-specify` (a linha RF) + `#criterios-de-conclusao` (a tabela é reconciliada por `trace`). |
| `assets/templates/traceability-table.md` | Nota: tabela **derivada**, regenerada por `/zion-prd-trace`; não editar Status/Feature à mão. |
| `scripts/asset-map.sh` | Nova entrada: `scripts/trace-prd.sh → zion-prd-trace zion-prd-decompose`. |
| `scripts/test-trace-prd.sh` + `scripts/fixtures/trace/` | **Novo.** Auto-teste com fixtures. |
| `.github/workflows/check-assets.yml` | Job/passo que roda o auto-teste do trace. |
| `docs/guia-prd-para-spec-kit.md` | Passo 6: promessa "tabela viva" reenquadrada como "viva enquanto você roda `/zion-prd-trace`"; nova skill na tabela de skills. |
| `docs/como-usar.md`, `README.md` | Menção ao `/zion-prd-trace`; contagem de skills 8 → 9. |
| `skills/*/references/` | Regenerados pelo sync (não editados à mão). |

## 11. Fora de escopo (consciente)

- Suíte completa de avaliação do harness (R7) — só a semente de fixtures entra aqui.
- Dia 2 / evolução pós-release (R8): PRD versionada, ADR substituído, re-decomposição parcial.
- Mapear RF↔**FR-interno** do Spec Kit (os `FR-xxx` que cada spec gera) — mapeamos RF↔**spec**, não
  os FR internos.
- Hook / CI no projeto *consumidor* do harness (o `trace` roda lá, mas não instalamos automação lá).
- Detecção de "implementada" por merge de branch / análise de git — `tasks.md` é o sinal escolhido.
