# R5 — Exigir o executor dos gates no "pronto para codar"

> **Origem:** recomendação R5 de `docs/critica-zion-build-prd.md` (§5.2).
> **Data:** 2026-07-17. **Esforço:** Baixo. **Escopo:** doc-only.

## Problema

A constitution gerada pelo método promete princípios decidíveis como **bloqueantes**
("regressão bloqueia o merge"), e no projeto real (`zion-mermaid-editor-app`) esses
princípios de fato viraram testes reais de contrato/perf/roundtrip (métrica d2). Mas o
projeto **não tem CI** (`.github/` ausente — métrica d3): os gates só rodam se alguém
lembrar de rodá-los à mão. **Princípio decidível sem executor é aspiração.** O checklist
final "pronto para codar" (`guia:333-347`) nunca exige o executor — falta só ele.

## Fronteira do harness (restrição que molda a solução)

O harness **para nas pontes** e vive num repositório **diferente** do repositório de
implementação. Constitution, código, testes e CI todos vivem no projeto-alvo, que o
harness nunca toca. Logo, R5 **não pode** ser um gate mecânico estilo `check-prd.sh`
(esses verificam artefatos que o próprio harness produz — PRD, prompt do specify). A
exigência de enforcement só pode viver como **orientação de checklist/guia**, dirigida ao
dev que vai operar o repo de implementação. Continua **advisória** — coerente com "todo
gate aconselha, nunca bloqueia".

## Decisões (discovery)

1. **Escopo: só doc** — checklist + guia. Sem script, sem skill, sem tocar
   `quality-rules.md` nem as Fases 4 das skills. É o mais fiel ao esforço "Baixo" e o
   único lugar onde a exigência pode viver dado que o harness não alcança o CI de baixo.
2. **O que é bloqueante: todo princípio decidível** — regra default simples: todo
   princípio da constitution que tem validador/limiar/teste entra no CI e trava o merge se
   regredir. **Sem campo "bloqueante" novo**; reusa a decidibilidade que
   `/zion-prd-constitution-prompt` já exige e o resultado empírico d2.
3. **Forma: item novo + subseção agnóstica** — uma linha dedicada no checklist E uma
   subseção curta "derivar testes bloqueantes → CI mínimo" **tool-agnóstica** (não cita
   GitHub Actions no corpo da regra). A linha de DoD existente (`guia:346`) fica
   **intacta**.

## Mudanças concretas em `docs/guia-prd-para-spec-kit.md`

Único arquivo tocado.

### M1 — Nova subseção (logo acima de "Checklist final")

```markdown
## Do princípio decidível ao gate que trava o merge

Cada princípio **decidível** da constitution (aquele com validador, limiar numérico ou
teste — a decidibilidade que `/zion-prd-constitution-prompt` já exige) só vira gate de
verdade quando algo o executa a cada mudança. Sem executor, "bloqueia o merge" é
aspiração. Antes da primeira branch de implementação, monte o executor mínimo:

1. **Liste os princípios decidíveis** da constitution — cada um já nasceu com critério
   objetivo.
2. **Ligue cada um a um comando de teste** que falha quando o princípio regride (o teste
   de contrato/perf/roundtrip que a própria constitution induz).
3. **Rode todos num CI a cada PR** e configure a branch para **barrar o merge** se algum
   quebrar. Um único job que roda a suíte já cumpre o mínimo.

O objetivo não é cobertura — é o *executor*: transformar cada princípio decidível num gate
que a máquina cobra, do mesmo jeito que `check-assets.yml` protege os assets deste harness.
```

### M2 — Nova linha no "Checklist final pronto para codar"

Adicionar (a linha de DoD em `guia:346` permanece intacta):

```markdown
- [ ] **CI mínimo em cada PR** roda os testes dos princípios **decidíveis** da constitution
      e **falha o merge** em regressão — o executor que a promessa "regressão bloqueia o
      merge" pressupõe (veja *"Do princípio decidível ao gate que trava o merge"*).
```

### M3 — Toque mínimo no Passo 6 (`guia:265-287`)

O objetivo e o critério de conclusão do Passo 6 passam a mencionar que "pronto para codar"
confirma **o executor** dos gates (o CI que roda os testes bloqueantes), não só que o
checklist está marcado. Uma frase, sem reescrever o passo.

## O que R5 NÃO faz (fronteira do escopo)

- Não cria script (`check-ci.sh`) nem skill — o harness não alcança o repo de
  implementação; verificar CI de baixo está fora do território.
- Não versiona template de CI (`ci-minimo.yml`) — descartado no discovery; manteria o guia
  agnóstico e evitaria over-fit a GitHub Actions no corpo da regra.
- Não adiciona campo "bloqueante" à constitution nem estende a ponte
  `constitution-prompt` — a regra "decidível → bloqueante" dispensa campo novo.
- Não toca `assets/quality-rules.md`, skills, scripts ou `como-usar.md`.

## Verificação

Doc-only: a verificação é revisão de prosa. Conferir que (a) a subseção existe acima do
checklist, (b) o novo item do checklist aponta para ela e a linha de DoD segue intacta, e
(c) o Passo 6 menciona o executor. `./scripts/check-assets.sh` deve continuar limpo (nada
em `assets/` mudou).
