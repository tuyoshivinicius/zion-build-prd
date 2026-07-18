# R8 — Endereçar o dia 2 (`/zion-prd-evolve`)

> **Origem:** recomendação R8 de `docs/critica-zion-build-prd.md` (§5.2, gap F7).
> **Data:** 2026-07-17. **Esforço:** Médio. **Escopo:** 1 skill nova + modos em 3 skills
> existentes + checks novos em 2 scripts + fixtures + guia/como-usar/README.

## Problema

O processo é greenfield-only (F7): nenhum estágio diz o que fazer quando um requisito muda
**pós-release**. O template de ADR prevê `Substituído por ADR-<m>` que nenhum comando
dispara; a PRD real congelou com 1 único commit em toda a história (métrica b1); não há
caminho para re-decompor um épico quando um RF muda. **O custo dos artefatos só se paga se
eles viverem mais que a release 1** — e um método cuja tese é "artefatos-guia versionados"
precisa dizer como os artefatos evoluem. A lição de F2 se aplica: fluxo sem dono e sem
gatilho morre; o dia 2 precisa de um comando com dono, não de prosa no guia.

## Decisões (discovery)

1. **As três frentes num fluxo único** — PRD versionada + supersessão de ADR +
   re-decomposição parcial são um problema só ("mudança pós-release"), tratadas por um
   único ponto de entrada.
2. **Cenários hipotéticos canônicos** — o design é validado contra C1/C2/C3 (abaixo), sem
   depender de caso real.
3. **Termina na ponte** — quando a mudança toca fatia já especificada/implementada, o
   harness monta o prompt de re-specify e **para**; o ciclo `/speckit.*` é do usuário
   (coerente com "parar nas pontes", §5.1 da crítica).
4. **PRD versionada = changelog dentro da PRD** — nova seção "Histórico de mudanças";
   sem número de versão semântico; git continua versionando o arquivo.
5. **Abordagem C (roteadora + modos mínimos)** — a skill nova é ponto de entrada com dono,
   mas roteia para os comandos existentes com **parada em cada gate**, em vez de executar
   uma cadeia longa num turno só (evita o modo de falha H3) ou de deixar a coreografia
   inteira a cargo do usuário (evita o modo de falha F2).

## Cenários canônicos

Uma mudança real pode combinar mais de um cenário; a classificação admite múltiplos.

| # | Cenário | O que toca |
|---|---------|-----------|
| C1 | **RF novo** — requisito que não existia | PRD §6 (RF no épico certo ou épico novo) + §13 changelog + re-decomposição parcial do épico + tabela (§12 via trace) |
| C2 | **RF alterado ou removido** — requisito muda de significado ou sai de escopo | PRD §6 + §13 + fatias do épico afetado + tabela; fatia já com spec → contexto de re-specify montado pela ponte |
| C3 | **Decisão revertida** — decisão estruturante caiu | ADR novo que substitui o antigo (referência cruzada simétrica) + PRD §8 (restrições) + §13 + aviso advisório de revisar a constitution via ponte |

## A skill nova: `/zion-prd-evolve`

10ª skill, ponto de entrada único do dia 2, no contrato de 5 fases da casa. Gates
aconselham, nunca bloqueiam.

- **Fase 0 — Pré-requisito (aconselha):** `docs/PRD.md` deve existir — dia 2 pressupõe
  dia 1. Faltando → avise ("recomendo `/zion-prd-write` antes") e pare graciosamente.
- **Fase 1 — Validar entrada:** o argumento é a descrição da mudança em linguagem natural
  (ex.: `/zion-prd-evolve "exportar PNG saiu de escopo; entrou exportar SVG"`). Classifique
  em C1/C2/C3 (pode ser mais de um). Descrição vaga demais para classificar → pergunte em
  vez de adivinhar. **Confirme a classificação com o usuário antes de tocar qualquer
  arquivo.**
- **Fase 2/3 — Plano de toque + execução roteada:** monte e mostre o **plano de toque** —
  lista ordenada de artefatos afetados e o comando responsável por cada um. Execute inline
  só o que é **barato e local**: a entrada na §13 (changelog) e a edição pontual da §6/§8.
  Para o resto, **pare e delegue com handoff explícito, um gate por vez**:
  - supersessão de decisão → `zion-adr-new` em modo substituir;
  - re-fatiamento do épico afetado → `/zion-prd-decompose` em modo parcial;
  - reconciliação da tabela → `/zion-prd-trace`;
  - fatia já especificada → `/zion-prd-specify-prompt` (enquadramento re-specify);
  - ADR substituído alimentava princípio da constitution → aconselhe rodar
    `/zion-prd-constitution-prompt` de novo (não edita constitution).
- **Fase 4 — Validar saída (aconselha):** rode `check-prd.sh` e `check-adr.sh` (com os
  checks novos abaixo) e emita veredito por item. Scripts ausentes (instalação parcial) →
  degrade para conferência em prosa com aviso, como as demais skills.

## Mudanças nos artefatos e comandos existentes

### Changelog na PRD (nova seção 13 do esqueleto)

`assets/templates/prd-skeleton.md` ganha a seção **"13. Histórico de mudanças"**, vazia no
dia 1, com linha de instrução: "preenchida por `/zion-prd-evolve` a partir da primeira
mudança pós-release". Formato tabular, uma linha por mudança:

```markdown
| Data | Cenário | Mudança | Motivo | Artefatos afetados |
|------|---------|---------|--------|--------------------|
| 2026-08-02 | C2 | `RF-07` alterado: exportar SVG em vez de PNG | feedback de usuários | ADR-002 → ADR-005 · fatia S4 re-especificada |
```

Regras decidíveis do formato (vivem em `quality-rules.md` `#dia-2` e no `check-prd.sh`):
todo `RF-xx`/`ADR-xxx` citado existe nos artefatos, ou a linha o declara "removido"; a
coluna Cenário usa só C1/C2/C3. O evolve é o dono da escrita; edição manual continua
possível.

### Supersessão no `zion-adr-new` (modo substituir)

Disparo por argumento (`/zion-adr-new "Novo título" --substitui ADR-002`) ou pelo evolve.
Além do modo normal: (1) cria o ADR novo com campo **`Substitui: ADR-002`** no cabeçalho e
Contexto obrigatoriamente explicando por que a decisão anterior caiu; (2) edita o ADR
antigo: `Status: Substituído por ADR-<m>` — referência **cruzada e simétrica** nos dois
arquivos; (3) lembra (advisório) que a restrição correspondente na PRD §8 precisa de
atualização — quem edita a §8 é o evolve, no plano de toque.

### Re-decomposição parcial no `/zion-prd-decompose` (modo parcial)

Novo modo com escopo: `/zion-prd-decompose --epico E2` (ou invocado pelo evolve com o
épico afetado). Re-fatia **apenas** o épico indicado via `superpowers:brainstorming`,
aplicando INVEST/SPIDR como hoje. Fatias já implementadas do épico são **intocáveis** —
viram restrição do re-fatiamento (as novas fatias partem do que já existe). Não mexe na
§12 à mão: ao final manda rodar `/zion-prd-trace`, dono único da tabela, que reconcilia
sem duplicar. O modo integral continua o default e ganha uma frase de idempotência: "se a
PRD já tem backlog decomposto, prefira o modo parcial".

### Pontes (mudança mínima)

`/zion-prd-specify-prompt` ganha enquadramento de **re-specify**: quando a fatia apontada
já tem `specs/<n>-*/spec.md`, o prompt montado diz "revise a spec existente contra a
mudança X" (com a entrada da §13 como contexto) em vez de "especifique do zero" — fronteira
sem-stack blindada igual, `check-prd.sh` verifica igual. `/zion-prd-constitution-prompt`
não muda; no C3 o evolve apenas aconselha rodá-la de novo.

## Verificação mecânica (checks novos)

Padrão da casa: regra decidível → script; prosa só aconselha.

- **`check-prd.sh`** — sobre a §13: todo `RF-xx` citado no changelog existe na §6 **ou** a
  linha o declara "removido"; todo `ADR-xxx` citado existe em `docs/adr/`; coluna Cenário
  só aceita C1/C2/C3. Check cruzado novo sobre a §8: restrição apontando para ADR com
  status "Substituído por" → acusa (restrição morta). PRD sem §13 (pré-R8 ou dia 1) → os
  checks da §13 não disparam (compatível com PRDs existentes).
- **`check-adr.sh`** — simetria da supersessão: ADR com `Status: Substituído por ADR-<m>`
  exige que ADR-m exista e contenha `Substitui: ADR-<n>`, e vice-versa. Referência
  quebrada ou unilateral → acusa.

Ambos rodam na Fase 4 do evolve e nos pontos onde já rodam hoje — os checks novos
beneficiam também quem edita à mão.

## Fixtures de avaliação (padrão R7)

- **Camada mecânica** (entram em `eval.sh` e nos auto-testes `test-check-*.sh` que o CI já
  roda): PRD com changelog citando RF inexistente; PRD com §8 apontando ADR substituído;
  par de ADRs com supersessão assimétrica — e as fixtures limpas correspondentes.
- **Camada LLM** (formato das fixtures LLM existentes): uma fixture de classificação do
  evolve — descrição de mudança que parece C2 mas é C3 (decisão caiu disfarçada de
  requisito) — e uma limpa.

## Documentação

- **`docs/guia-prd-para-spec-kit.md`** — novo **"Passo 7 — O dia 2"**: cenários C1–C3, o
  fluxo pelo evolve, e a tese explícita de que artefato-guia que não evolui congela.
- **`docs/como-usar.md`** — seção do `/zion-prd-evolve` com exemplo; linha nova no mapa
  rápido; nó novo no diagrama mermaid; contagens de skills atualizadas (9→10), corrigindo
  de passagem o drift "7 comandos" (H7) nos trechos tocados.
- **`README.md`** — lista de skills atualizada.
- **`assets/quality-rules.md`** — âncora nova `#dia-2` com as regras do changelog e da
  supersessão (ponto único de afinação, como hoje).

## Infra de distribuição

A skill nova entra no `scripts/asset-map.sh` com as references de que precisa
(`process-context.md`, `quality-rules.md`, `check-prd.sh`, `check-adr.sh`);
`sync-assets.sh` gera as cópias; o CI `check-assets` já cobre drift e auto-testes. Nada de
mecanismo novo — só entradas no mapa.

## O que R8 NÃO faz (fronteira do escopo)

- Não orquestra o ciclo `/speckit.*` — termina na ponte (decisão 3).
- Não edita a constitution — só aconselha a ponte `/zion-prd-constitution-prompt`.
- Não introduz número de versão semântico na PRD — só o changelog (decisão 4).
- Não detecta drift por histórico de git nem cria auditoria contínua — `/zion-prd-audit`
  é o gap H8, fora desta recomendação.
- Não bloqueia mudanças feitas por fora do evolve — gates aconselham, nunca bloqueiam; os
  checks mecânicos acusam inconsistência independente de quem editou.

## Verificação

- Auto-testes: `./scripts/test-check-prd.sh` e `./scripts/test-check-adr.sh` verdes com as
  fixtures novas; `./scripts/eval.sh` (camada mecânica) verde; `./scripts/check-assets.sh`
  limpo após o sync das references novas.
- Manual: rodar `/zion-prd-evolve` contra os três cenários canônicos num projeto de
  brinquedo — C1 termina em decompose parcial + trace; C2 com spec existente termina no
  prompt de re-specify; C3 termina com par de ADRs simétrico, §8 atualizada e aviso da
  constitution.
