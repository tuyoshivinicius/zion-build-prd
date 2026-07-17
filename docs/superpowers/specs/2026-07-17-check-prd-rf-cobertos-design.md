# Design — `check-prd.sh`: verificar o pedido de `**RF cobertos:**` na ponte specify (R4)

> **Origem:** recomendação R4 de `docs/critica-zion-build-prd.md` §5.2.
> **Data:** 2026-07-17.
> **Escopo:** fechar a lacuna do `check-prd.sh` no modo `specify` — verificar por máquina que o prompt
> montado pede a linha `**RF cobertos:**`, o elo forward RF↔spec que a Fase 4 hoje só confere em prosa.

---

## 1. Problema

R4 pede duas coisas: (i) que a ponte specify peça ao `spec.md` para listar os `RF-xx` cobertos, e
(ii) que `check-prd.sh`/`trace` verifiquem a presença desse elo. **A parte (i) e metade da (ii) já
foram entregues** no commit `40c98ea` (junto do trabalho de rastreabilidade R2):

- A skill `zion-prd-specify-prompt` já manda o prompt pedir a linha `**RF cobertos:**`
  (`SKILL.md:33-36`), e `quality-rules.md` `#anatomia-specify` a descreve (`:105-108`).
- O `trace-prd.sh` já grepa `RF cobertos:` em cada `spec.md` e emite o aviso **"Spec intraçável:
  specs/… sem linha **RF cobertos:**"** quando falta (`trace-prd.sh:96,111-113`).

**O que falta:** o `check-prd.sh` **não** verifica esse elo. Hoje o modo `specify` só roda
`check_stack` (`check-prd.sh:110`) — não confere se o *prompt montado* de fato pede a linha
`**RF cobertos:**`. Sem isso, uma ponte que esquece de pedir a linha passa limpa no gate, e a falha
só aparece muito depois, no `trace`, quando as specs já existem (crítica F5/b2: a spec 001 real não
citou nenhum RF).

## 2. Princípio organizador

**Mover o elo RF↔spec de prosa para máquina, no ponto mais barato da cadeia.** O `check-prd.sh` roda
na Fase 4 da ponte, *antes* do handoff ao Spec Kit — pega o prompt malformado quando corrigir ainda é
trivial. O script **verifica**; o humano **decide** (advisório, como todo o resto).

## 3. Divisão de responsabilidade (complementar, não redundante)

| Verificador | Quando roda | O que garante |
|---|---|---|
| **`check-prd.sh specify`** | Fase 4 da ponte, **antes** do handoff | o *prompt montado* pede a linha `**RF cobertos:**` |
| **`trace-prd.sh`** | depois, quando as specs existem | o *`spec.md` resultante* tem a linha (aviso "Spec intraçável") |

Os dois grepam o **mesmo padrão** (`RF cobertos:`, case-insensitive), então concordam sobre o que é
"o elo". O `check-prd` protege a montagem do prompt; o `trace` protege o artefato final.

## 4. A checagem

Nova função `check_rf_cobertos` no `check-prd.sh`, **simétrica ao `check_stack`**, ligada **apenas no
modo `specify`**:

- Grepa o alvo por `RF cobertos:` (`grep -iE 'RF cobertos:'` — mesmo padrão do `trace`).
- **Presente** → nada. **Ausente** → um achado.
- Slug: **`rf-cobertos-ausente`**. Como é uma *ausência*, não há linha para ancorar — formato sem
  número de linha:

  ```
  specify: rf-cobertos-ausente — o prompt não pede a linha **RF cobertos:** (elo forward RF↔spec; veja quality-rules #anatomia-specify)
  ```
- **Advisório**: soma ao `findings`, exit `1`, não bloqueia — igual a todo o resto.

Wiring (`check-prd.sh:110`): `specify) findings="$(check_stack; check_rf_cobertos)" ;;`

O modo `prd` **não muda**: a linha `**RF cobertos:**` é artefato do `spec.md` (pedido *via* prompt do
specify), não da PRD.

### 4.1 Gatilho: só o pedido da linha

O achado dispara **apenas** pela ausência do pedido da linha — nunca por não haver um `RF-xx`
concreto nomeado no prompt. Motivo: no projeto real a fatia **walking skeleton (spec 001)
legitimamente não cobre nenhum RF** — é a fatia-zero de infraestrutura. Exigir um `RF-xx` nomeado
daria falso-positivo justamente nela. Pedir a *linha* é sempre correto: mesmo o skeleton a declara
como `**RF cobertos:** (nenhum)`, tornando explícita a cobertura vazia em vez de silenciosa.

## 5. Auto-teste (semente da R7)

`scripts/test-check-prd.sh` + `scripts/fixtures/`:

- **Corrigir o teste #4** (`test-check-prd.sh:37-39`): o prompt "limpo" atual **não** contém
  `RF cobertos:` e passaria a (corretamente) acusar. O prompt limpo passa a incluir o pedido da
  linha. Isso é esperado — o significado de "specify limpo" muda: agora um prompt só é limpo se
  também pedir o elo RF.
- **Novo teste #5**: fixture `scripts/fixtures/specify-sem-rf.txt` — resultado observável, zero stack,
  **sem** o pedido de RF → afirma exit `1` + achado `rf-cobertos-ausente`.
- Testes #1–#3 (PRD limpa/suja, specify sujo/stack) permanecem intactos.

## 6. Prosa ↔ mecanismo (manter alinhados)

- **`skills/zion-prd-specify-prompt/SKILL.md` Fase 4**: hoje diz "Verifique o zero-stack por máquina".
  Passa a mencionar que o `check-prd.sh specify` também verifica que o prompt pede a linha
  `**RF cobertos:**`.
- **`assets/quality-rules.md` `#anatomia-specify`**: nota curta de que esse elo agora é verificado por
  máquina (não só recomendado em prosa).

## 7. Superfície de mudança

| Arquivo | Mudança |
|---|---|
| `scripts/check-prd.sh` | Nova função `check_rf_cobertos`; wire no modo `specify`. |
| `scripts/test-check-prd.sh` | Corrige teste #4 (prompt limpo inclui o pedido de RF); novo teste #5. |
| `scripts/fixtures/specify-sem-rf.txt` | **Novo.** Prompt sem o pedido de RF → achado. |
| `skills/zion-prd-specify-prompt/SKILL.md` | Fase 4 menciona a checagem do pedido de `**RF cobertos:**`. |
| `assets/quality-rules.md` | `#anatomia-specify`: o elo é verificado por máquina. |
| `skills/*/references/` | Regenerados pelo sync (não editados à mão). |

**Sync:** `check-prd.sh` já é asset derivado (`asset-map.sh:13` → `zion-prd-write
zion-prd-specify-prompt`). O `sync-assets.sh` propaga para `references/`, o hook regenera e o
`check-assets.yml` roda o auto-teste. Nenhuma entrada nova no mapa — só re-sincronizar.

## 8. Fora de escopo (consciente)

- **Modo `prd`** — a linha `**RF cobertos:**` não é artefato da PRD.
- **Verificar o `spec.md` final** — já é trabalho do `trace-prd.sh` (aviso "Spec intraçável");
  duplicá-lo no `check-prd` seria redundante.
- **Exigir `RF-xx` concreto nomeado** — protegeria mal o walking skeleton (decisão da §4.1).
- **Mapear RF↔FR-xxx** (correspondência com os FR internos do Spec Kit) — seria a variante "mais
  forte" do R4, descartada no discovery; R4 literal é só o elo RF↔spec.
- **Bloqueio / exit gate** — o contrato do harness é advisório.
