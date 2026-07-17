# Design — `check-prd.sh`: verificação mecânica das regras decidíveis (R1)

> **Origem:** recomendação R1 de `docs/critica-zion-build-prd.md` §5.2.
> **Data:** 2026-07-17.
> **Escopo:** um verificador em shell que executa as regras decidíveis do harness contra artefatos
> reais, substituindo a prosa interpretada por LLM nas Fases 4 de `zion-prd-write` e
> `zion-prd-specify-prompt`.

---

## 1. Problema

O harness define regras genuinamente decidíveis em `assets/quality-rules.md` (zero stack na
PRD/specify, NFR com número, RF-xx agrupado por épico), mas **toda** verificação é delegada à Fase 4
de cada skill: prosa interpretada pelo mesmo LLM que acabou de escrever o artefato. O resultado
previsível aconteceu no único projeto que usou o método ponta-a-ponta — "React Flow" está na PRD
real (`zion-mermaid-editor-app/docs/PRD.md:220`) e nenhum gate apontou (crítica H1). Um `grep` com a
denylist do próprio `#fronteira` teria pego.

A ironia diagnosticada: o repositório **já tem** o padrão certo de enforcement mecânico
(`scripts/check-assets.sh` + hook + CI) — mas só para proteger os assets do harness, não para
executar as regras de qualidade que são a razão de existir do harness. R1 estende esse padrão às
regras de qualidade.

## 2. Princípio organizador

**Mover invariantes decidíveis de prosa para máquina.** O script **verifica**; o humano **decide**.
Coerente com a filosofia declarada do harness ("gates aconselham, não bloqueiam") e com as Fases 4
que já dizem "não reverta — apenas aconselhe".

## 3. Decisões estruturais (tomadas no discovery)

1. **Distribuição via `references/`.** O script é canônico em `scripts/check-prd.sh` e sincronizado
   para `references/` das skills que o consomem, viajando dentro da skill autocontida — o mesmo
   padrão que já funciona para os assets. (A falha real ocorreu num projeto *consumidor* do harness,
   que não tem este repo; o check precisa rodar lá.)
2. **Detecção híbrida: denylist curada + sinais estruturais de alta precisão.** Baixo falso-positivo,
   aponta linha exata. Denylist mora no `quality-rules.md` (fonte única, já sincronizada).
3. **Advisório, sem supressão.** Exit `0`/`1`, achados ancorados em linha; a Fase 4 reporta o
   veredito com autoridade mas não bloqueia nem reverte. Falso-positivo o humano descarta na hora —
   supressão só importaria se o gate bloqueasse (YAGNI).
4. **Escopo v1 = as 3 regras da R1, arquitetura extensível.** Funções de check independentes com
   modo/alvo, para R4 (RF↔FR) e outras plugarem depois sem retrabalho.

## 4. Arquitetura

### 4.1 Localização e distribuição

- **Canônico:** `scripts/check-prd.sh` — fonte única, ao lado de `check-assets.sh`.
- **Sync:** `scripts/asset-map.sh` ganha uma entrada mapeando `scripts/check-prd.sh` para as skills
  `zion-prd-write` e `zion-prd-specify-prompt`. O `sync-assets.sh` (cp) o copia para
  `skills/<skill>/references/check-prd.sh`; o `check-assets.sh` vigia o drift; o pre-commit hook
  regenera. Nada de novo na infraestrutura — só uma linha no mapa.
- **Runtime do denylist:** o script localiza `quality-rules.md` ao lado de si mesmo (caso
  `references/`), com fallback para `../assets/quality-rules.md` (caso repo). Como ambos são
  sincronizados para o mesmo `references/`, viajam juntos.

### 4.2 Invocação pelas Fases 4

- `zion-prd-write` Fase 4 → `bash references/check-prd.sh prd docs/PRD.md` (roda os 3 checks).
- `zion-prd-specify-prompt` Fase 4 → `bash references/check-prd.sh specify -` (lê o prompt montado
  via stdin; só o check de stack, pois o prompt não é um arquivo em disco).

Invocado com `bash` explícito → o bit de execução da cópia em `references/` é irrelevante.

### 4.3 Risco a verificar antes de fechar

Confirmar que `npx skills` empacota `references/*.sh` (o padrão hoje só exercita `.md`). Se não
empacotar, plano B é embutir o script no próprio `SKILL.md` via heredoc que a Fase 4 escreve e
executa. **Ponto de verificação explícito no plano de implementação.**

## 5. Os três checks

Aterrados no `assets/templates/prd-skeleton.md` (seções numeradas fixas).

### 5.1 Stack (denylist + estrutural) — modos `prd` e `specify`

Para cada linha do alvo, é achado se casar com:
- **Denylist curada** (case-insensitive) — nomes de linguagem/framework/biblioteca extraídos do
  bloco `#denylist` do `quality-rules.md`.
- **Sinais estruturais de alta precisão** — bloco cercado ` ``` `, `npm install` / `pip install` /
  `yarn add`, declaração `import …` / `from … import`, número de versão `x.y.z` adjacente a um nome.

Saída por achado: `PRD.md:220: stack — "React Flow" (mova para o plan.md da feature)`.

Sem tratamento especial da seção 8 (Restrições das ADRs): um ponteiro `docs/adr/ADR-00x` não casa
com nome de stack; se a seção 8 literalmente nomear "React Flow", isso É o vazamento que a crítica
F6 quer expor — e o caráter advisório deixa o humano julgar.

### 5.2 NFR sem número — modo `prd`

Dentro da seção `## 7. NFRs`, toda linha que enuncia um NFR precisa conter ao menos um dígito. Linha
de NFR sem dígito → achado (`PRD.md:31: nfr-sem-numero — "disponibilidade alta" (dê um número)`).

### 5.3 RF fora de épico — modo `prd`

Dentro da seção `## 6. …por épico`, todo `RF-xx` **definido** precisa aparecer sob um agrupamento
`Épico E#`. RF-xx definido solto (fora de um bloco de épico) ou definido fora da seção 6 → achado
(`PRD.md:27: rf-fora-de-epico — "RF-05" sem épico`).

## 6. Denylist — encoding

Nova seção ancorada no `quality-rules.md`:

```
## Denylist de stack {#denylist}

<prosa curta explicando o que é e como afinar>

​```denylist
react
vue
zustand
localstorage
dagre
elk
next.js
postgres
codemirror
...
​```
```

Bloco cercado **legível por humano e parseável por script**: um termo por linha, minúsculo, casado
case-insensitive. O script extrai as linhas entre as cercas sob `#denylist` da sua cópia sincronizada
de `quality-rules.md`. Single-source literal no `quality-rules.md`; parsing robusto (não depende de
interpretar prosa). Afinar a lista = editar um lugar, que o sync propaga.

## 7. Contrato de saída

- Exit `0` limpo · `1` com achados. (Não bloqueia o fluxo — quem lê o exit code é a Fase 4, que
  aconselha.)
- Um achado por linha, formato `arquivo:linha: <regra> — "<trecho>" (<ação sugerida>)`.
- Linha final: `check-prd: N achado(s)` ou `check-prd: limpo`.

**Consumo pela Fase 4:** roda o script, reporta o veredito com autoridade (ecoa os achados com
número de linha), mantém o tom advisório — "corrija ou justifique", **não reverte**. Substitui a
prosa "confira contra o critério… emita veredito por item".

## 8. Auto-teste (semente mínima da R7)

- `scripts/test-check-prd.sh` + `scripts/fixtures/`: 2–3 PRDs sintéticas — uma limpa; uma suja com
  "React Flow", um NFR sem número e um RF fora de épico — que afirmam exit code + achados esperados.
- Novo job no workflow de CI (ou passo adicional em `check-assets.yml`).

Mantém o ethos do harness (verificar por máquina) aplicado às próprias regras de qualidade, e cada
fixture já é metade de uma futura fixture de avaliação da R7 — de graça.

## 9. Superfície de mudança

| Arquivo | Mudança |
|---|---|
| `scripts/check-prd.sh` | **Novo.** O verificador (funções de check independentes + dispatch por modo). |
| `assets/quality-rules.md` | Nova seção `## Denylist de stack {#denylist}`; `#criterios-de-conclusao` aponta que `prd`/`specify` são verificados por `check-prd.sh`. |
| `scripts/asset-map.sh` | Nova entrada: `scripts/check-prd.sh → zion-prd-write zion-prd-specify-prompt`. |
| `skills/zion-prd-write/SKILL.md` | Fase 4 roda `check-prd.sh prd docs/PRD.md` e reporta o veredito. |
| `skills/zion-prd-specify-prompt/SKILL.md` | Fase 4 roda `check-prd.sh specify -` sobre o prompt montado. |
| `scripts/test-check-prd.sh` + `scripts/fixtures/` | **Novo.** Auto-teste com fixtures. |
| `.github/workflows/check-assets.yml` | Job/passo que roda o auto-teste. |
| `docs/como-usar.md`, `README.md` | Menção à verificação mecânica das Fases 4. |
| `skills/*/references/` | Regenerados pelo sync (não editados à mão). |

## 10. Fora de escopo (consciente)

- Supressão inline de falso-positivo (só importaria se bloqueasse).
- Bloqueio / exit gate no fluxo.
- R4 (RF↔FR: `spec.md` listar os RF cobertos) — regra vizinha, outra recomendação.
- Hook / CI no projeto *consumidor* do harness.
- Suíte completa de avaliação do harness (R7) — só a semente de fixtures entra aqui.

A arquitetura de funções independentes deixa R4 e as demais plugarem depois sem retrabalho.
