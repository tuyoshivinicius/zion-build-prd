# Estudo — CD do zion-build-prd: releases automatizadas por impacto

## Contexto

O mantenedor do zion-build-prd hoje libera releases à mão: edita `plugin.json.version` num commit
`chore: bump` e cria a tag (existem `v1.0.0` e `v2.0.0`), sem `CHANGELOG` e sem um PR que documente
a mudança. O candidato quer que **as releases sejam distribuídas via CI/CD**: o mantenedor continua
implementando pelo fluxo de dev interno (SDD leve via superpowers — `architecture.md §6`,
`ADR-013`), e o processo de CD **abre um PR documentando as mudanças** e **cria tags com a versão
gerada automaticamente conforme o impacto da mudança**, seguindo a semântica de versionamento (SemVer)
já adotada — hoje dirigível pela convenção de commits que o histórico já pratica
(`feat`/`fix`/`chore`…). Isso serve à visão da PRD de uma jornada contínua com fronteira guardada
(`prd.md §1`) e à persona do Autor dogfooding o próprio harness (`prd.md §3`; o marcador
`name: zion-build-prd` do `plugin.json` identifica este repo — `architecture.md §6`). O CD é artefato
de **governança/dev-workflow que não viaja ao usuário** (`architecture.md §6`), e cai no épico de
Distribuição (`prd.md §6`, E6, `RF-14`/`RF-15`). Brownfield: nenhuma alternativa reverte ADR vigente —
todas honram a **distribuição dual por cópia real** (`ADR-002`) e o **canon bloqueante** (`ADR-010`,
`prd.md §RF-13`).

## Edge cases e incertezas

Perguntas que a solução escolhida terá de responder (marcadas **[humano]** as que só o Autor decide).

**Como o impacto vira versão**

1. **[humano]** Fonte-de-verdade do impacto: convenção de commits (`feat`→minor, `fix`→patch,
   `feat!`/`BREAKING CHANGE:`→major) — que o repo já usa — ou labels de PR? E o que `docs/test/chore`
   bumpam (provavelmente nada → PR só de docs não gera release)?
2. **[humano]** Como se declara um **major**? O salto v1→v2 foi manual; falta convenção explícita de
   BREAKING para o automatismo não errar.
3. **[humano]** **Um número para os dois canais ou números divergentes?** `plugin.json.version` é o
   vetor do canal plugin; o canal skills.sh também precisa de versão. `ADR-002` (cópia real) empurra
   para *uma* tag = os dois canais no mesmo número.

**"Abrir PR para documentar" — qual modelo?**

4. **[humano]** O PR é um **release-PR automatizado** (bot acumula changelog+bump num PR aberto;
   mergear cria a tag) ou é a própria feature que o mantenedor abre? "O processo de CD deve abrir PR"
   sugere o primeiro.
5. **[humano]** Nasce um **`CHANGELOG`** (hoje inexistente)? Onde mora e quem o escreve?

**Distribuição dual (ADR-002)**

6. **[humano]** O que "publicar" significa **por canal**? Plugin do Claude Code: basta tag + Release e
   o usuário atualiza? Canal skills.sh: resolve de um git ref/tag ou precisa de índice próprio?
   (Precisa ser confirmado com o mecanismo real de cada canal.)
7. O CD deve rodar sync + guard de drift **antes** de taguear, senão publica derivado com drift
   (fere a autocontenção do `ADR-002`). *(verificável — não depende do Autor)*

**Atrito com a governança bloqueante (ADR-010)**

8. Reescrever `plugin.json.version` é um commit — confirmar que o guard de canon **não** o acusa como
   drift (a versão hoje não está no ASSET_MAP nem no canon). *(verificável)*
9. **[humano]** O próprio CD (workflow + script de release) é artefato novo de governança/dev-workflow
   (não viaja — `architecture.md §6`): vira **RF novo no épico E6 + ADR** da convenção/mecanismo? Ou
   seja, "automação de release" é requisito (o-quê) ou puro como? — decisão de fronteira do Autor.

**Infra, falhas e reversibilidade**

10. **[humano]** Permissões: o token default do CI cria tag/Release e **abre PR** sob main protegida,
    ou precisa de credencial elevada (PAT/app)? Se a main é protegida, o release-PR passa pelo CI
    (drift + auto-testes + canon + adr) antes do merge — reforço bem-vindo.
11. **[humano]** Conserto pós-erro: versão mal-classificada depois de taguear (tags são imutáveis) —
    qual o processo? E commits fora da convenção **falham** o CD ou são ignorados (precisa de gate de
    lint de commits)?
12. Release parcial (tag criada, publicação de um canal falha) → estado inconsistente; o CD precisa
    ser **idempotente/retentável**. *(robustez — registrada como contra nas alternativas)*

## Alternativas

Em nível de **o-quê** (a escolha da ferramenta é "como" — fica para o ADR/spike). Todas honram
`ADR-002` e `ADR-010` (sem supersessão) e, exceto "não fazer", exigem um **ADR novo** da convenção de
versionamento/mecanismo de release + um **RF novo no épico E6** (`prd.md §6`) e linha na tabela de
scripts (`architecture.md §3`) — canonização no mesmo commit (`CLAUDE.md`).

### A — Não fazer (status quo)

Manter o bump manual em `plugin.json` e a tag à mão, como em `v1.0.0`/`v2.0.0`.

- **Prós:** custo zero; nenhum risco novo; nada a canonizar; totalmente reversível (é o presente).
- **Contras:** não resolve a dor do candidato; preserva o risco latente de **erro humano de versão**,
  a **ausência de changelog/rastro** e a possível **divergência de número entre os dois canais** por
  serem editados à mão.
- **ADRs tocados:** nenhum.

### B — Release-PR automatizado por convenção de commits (o que o candidato descreve)

A cada merge na main o CD **mantém um PR de release** que acumula o changelog derivado dos commits e o
**bump calculado por impacto**; **mergear esse PR** cria a tag e publica os dois canais (skills.sh +
`plugin.json.version` no mesmo número). O PR é ao mesmo tempo o **rastro documental** e o **gate
humano** sobre a versão calculada.

- **Prós:** entrega o candidato inteiro (release via CI/CD, PR que documenta, versão automática por
  impacto, dois canais num número só); a aprovação do PR é um gate humano que combina com a cultura
  advisory do harness (`RN-01`) e força a mudança pelo CI (drift + canon + adr) antes de taguear.
- **Contras:** é o **maior esforço** (convenção disciplinada + lint de commits, geração de changelog,
  reescrita de `plugin.json`, publicação dos dois canais, canonização RF+ADR+scripts); exige resolver
  **permissões de bot** para abrir PR/push de tag sob main protegida (edge case 10); depende de o
  mecanismo de cada canal saber **consumir a tag** (edge case 6).
- **ADRs tocados:** honra `ADR-002`/`ADR-010`; exige ADR novo (convenção de versionamento + mecanismo
  de release-PR) e RF novo em E6.

### C — Tag-on-merge direto (sem PR)

Cada merge na main que carrega impacto gera **imediatamente** tag + Release, com o changelog no corpo
da Release, publicando os dois canais.

- **Prós:** mais simples (sem gestão de PR de release aberto); menos infra de permissão (o token
  default costuma criar tag/Release); menos passos até a release.
- **Contras:** **não** entrega o "abrir PR para documentar" do candidato — o rastro vira a Release, não
  um PR revisável; **sem gate humano** antes de taguear (versão errada já publicada e tag é imutável —
  edge case 11); releases mais frequentes e ruidosas.
- **ADRs tocados:** honra `ADR-002`/`ADR-010`; exige ADR novo (convenção) e RF novo em E6.

### D — Semi-automático por disparo manual (sem PR)

O CD **calcula** versão + changelog e os deixa prontos, mas a tag/publicação só dispara por
acionamento manual do mantenedor; nenhum bot abre PR nem faz push autônomo.

- **Prós:** controle total e alta reversibilidade; **menor superfície de permissões** de bot (não abre
  PR nem empurra sozinho); erro barrado antes do disparo.
- **Contras:** **não abre PR** (o candidato pede PR); mantém um **passo manual** (dor só parcialmente
  resolvida); o rastro é o run do CD, não um PR revisável.
- **ADRs tocados:** honra `ADR-002`/`ADR-010`; exige ADR novo (convenção) e RF novo em E6.

## ROI

Três notas por alternativa (Impacto 1–5, 5 = resolve a dor central; Esforço e Risco/reversibilidade
1–5 **invertidos**, 5 = menor esforço / menor risco e mais reversível). ROI = média das três. Tabela
ordenada por ROI decrescente.

| Alternativa | Impacto | Esforço (inv.) | Risco/rev. (inv.) | **ROI** |
|---|---|---|---|---|
| A — Não fazer | 1 | 5 | 5 | **3,67** |
| B — Release-PR automatizado | 5 | 2 | 3 | **3,33** |
| D — Semi-automático (dispatch) | 2 | 3 | 4 | **3,00** |
| C — Tag-on-merge direto | 3 | 3 | 2 | **2,67** |

**Justificativas**

- **A — Não fazer (3,67).** Impacto **1**: não resolve nada e mantém o risco latente de versão manual.
  Esforço **5**: nada a fazer. Risco **5**: nenhum risco de mudança, perfeitamente reversível. O ROI
  alto é artefato de custo/risco zero — impacto 1 é o denunciante de que a dor fica intacta.
- **B — Release-PR automatizado (3,33).** Impacto **5**: é o candidato inteiro. Esforço **2**: o mais
  caro (convenção + lint, changelog, reescrita de versão, dois canais, canonização, permissões).
  Risco **3**: reversível (basta desligar o workflow), risco médio de versão mal-calculada — mitigado
  pelo próprio gate de PR.
- **D — Semi-automático (3,00).** Impacto **2**: automatiza o cálculo mas não abre PR e mantém passo
  manual. Esforço **3**: sem gestão de PR e com menos permissões. Risco **4**: humano dispara, pouca
  permissão de bot, muito reversível.
- **C — Tag-on-merge direto (2,67).** Impacto **3**: automatiza versão+release, mas sem o PR do
  candidato. Esforço **3**: mais simples que B. Risco **2**: sem gate antes de taguear e menos
  reversível por release já publicada.

## Recomendação

**Não vinculante.** Recomendo a **Alternativa B — Release-PR automatizado por convenção de commits**.
"Não fazer" lidera a aritmética apenas por não custar nem arriscar nada (impacto 1 denuncia que a dor
permanece); entre as opções que agem, B é a única que resolve o candidato por inteiro — release via
CI/CD, PR que documenta, versão automática por impacto e os dois canais num número só — e faz isso
**honrando** `ADR-002` e `ADR-010` sem reabrir decisão. Seu maior risco (versão auto-calculada errada)
é neutralizado justamente pelo gate de PR que o candidato pediu, que ainda força a passagem pelo CI
antes de taguear. Se a incerteza de infra (edge case 10 — permissões de bot para abrir PR/push sob main
protegida) se mostrar bloqueante no spike, **D** é o recuo seguro (menos permissões, sem PR) enquanto a
credencial não existe. Antes de fechar, as questões **[humano]** 1–6 e 9–11 precisam de decisão do
Autor — em especial o modelo do PR (4), o número único para os dois canais (3) e se isto vira RF novo
em E6 (9).

## Próximo passo sugerido

Se aprovado, rodar `superpowers:brainstorming` com a alternativa escolhida → `superpowers:writing-plans`
→ `superpowers:executing-plans`. Decisão estruturante nova vira ADR via `/zion-adr-new` e reflete no
canon (`prd.md`/`architecture.md` no mesmo commit — CLAUDE.md).
