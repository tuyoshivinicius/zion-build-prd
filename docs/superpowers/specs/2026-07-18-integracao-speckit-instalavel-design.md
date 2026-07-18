# Design — Integração instalável com o Spec Kit e architecture.md distribuído (A3)

> Spec de mudança do **harness** (não de produto do usuário). Nasce da alternativa **A3** do estudo
> `docs/estudos/integracao-speckit-fonte-canonica.md`, sob as três condições de desenho da
> recomendação. Sujeita ao dever de canonização (`CLAUDE.md`): toda mudança de comportamento
> reflete em `docs/prd.md` e `docs/architecture.md` no mesmo commit.

## Problema

O canon do produto (`docs/prd.md`, `docs/adr/`, backlog) chega ao Spec Kit **apenas** pelas três
pontes manuais (RF-06/07/08): clarify e implement rodam sem canon, spec nascida fora do fluxo só
aparece quando o Autor lembra do trace, e o reconhecimento canônico depende de colar prompt. Além
disso, o Autor definiu (edge 18 do estudo) que sente falta de **prosa estrutural com autoridade
própria** — um documento de arquitetura do produto que os ADRs pontuais, a constitution e o plan
por feature não acomodam.

## Decisão

Uma skill instaladora nova e idempotente — **`zion-speckit-install`** — configura o repositório do
produto: grava um bloco de regras versionado no `CLAUDE.md` do produto declarando os artefatos
zion como fonte canônica, semeia o `docs/architecture.md` do produto de template distribuído, e
oferece um guard de canonização **opt-in**. O trace ganha a reconciliação dos blocos derivados do
documento; a ponte do plan injeta o documento ao lado dos ADRs; um verificador novo no padrão E5
sustenta a autoridade por conselho.

Decisões fechadas no brainstorming (todas do Autor):

1. **Enforcement (edge 6)** — o "sempre iniciam do fluxo" é dever **advisório** (RN-01/NFR-05
   intactos, ADR-004 não superseded), com guard de pre-commit **opt-in** para quem quiser os
   dentes do ADR-010 no próprio repo.
2. **Superfície (edge 9)** — a regra mora **só no `CLAUDE.md` do produto** (agente único, Claude
   Code). Nada de patch em templates do Spec Kit (crítica da A4) nem N cópias por agente.
3. **Pontes (edge 11)** — **convivência**: as pontes RF-06/07/08 seguem como caminho rico (curam o
   recorte por passo); a regra instalada é a rede de segurança quando o Autor pula a ponte.
4. **Reconciliação (edge 12)** — gatilho é **ritual humano** declarado na regra instalada
   (implementação termina → `/zion-prd-trace`; RF descoberto → `/zion-prd-evolve`). Zero automação
   instalada no repo do produto (ADR-005 preservado).
5. **Forma (B1)** — ciclo único: uma skill instaladora nova + extensões em trace/plan-prompt +
   verificador E5 + templates no `ASSET_MAP`; um spec, um plano, um ADR.

## Componentes

| Componente | Natureza | Papel |
|---|---|---|
| `skills/zion-speckit-install` (nova) | Distribuído | Instala a integração no repo do produto: bloco de regras, semeadura do documento, oferta do guard opt-in. Idempotente e re-rodável. |
| `assets/templates/regras-speckit.md` (novo) | Fonte única | Conteúdo do bloco de regras gravado no `CLAUDE.md` do produto; no `ASSET_MAP` (RN-05). |
| `assets/templates/architecture-skeleton.md` (novo) | Fonte única | Esqueleto do `docs/architecture.md` do produto, análogo ao `prd-skeleton.md` (ADR-002). |
| `scripts/check-arquitetura.sh` (novo) | Distribuído | Verificador advisório padrão E5 do documento + drift da regra instalada. |
| `scripts/trace-arquitetura.sh` (novo) | Distribuído | Semeia/reconcilia os blocos derivados do documento no ritual do trace (RN-04). |
| `scripts/test-check-arquitetura.sh` · `scripts/test-trace-arquitetura.sh` + fixtures (novos) | Dev-workflow | Auto-testes com fixture limpa e suja (NFR-04), agregados no `eval.sh`. |
| `zion-prd-trace` (alterada) | Distribuído | Ritual passa a rodar também `trace-arquitetura.sh` e ecoar `check-arquitetura.sh`. |
| `zion-prd-plan-prompt` (alterada) | Distribuído | Injeta a prosa estrutural do architecture.md do produto ao lado dos ADRs (RF-08). |

## A regra instalada

Vive entre marcadores versionados no `CLAUDE.md` do produto:

```
<!-- zion:speckit:v1:start -->
… conteúdo derivado de assets/templates/regras-speckit.md …
<!-- zion:speckit:v1:end -->
```

Re-rodar a instalação substitui **só** o bloco marcado, preservando o que o Autor escreveu fora
dele (edge 8). O marcador de versão é o que `check-arquitetura.sh` compara para acusar bloco
defasado após upgrade do harness (edge 13). Conteúdo em cinco partes:

1. **Canon declarado** — `docs/discovery.md`, `docs/prd.md`, `docs/adr/`, `docs/backlog.md` e
   `docs/architecture.md` são as fontes canônicas de produto e arquitetura do repo.
2. **Fronteira de donos (edge 17)** — constitution guarda princípios de repo inteiro (ponte
   RF-06); ADRs guardam decisões pontuais de repo inteiro; `architecture.md` guarda estrutura e
   prosa do Autor + índices derivados; plan guarda o como por feature (ponte RF-08). Um dono por
   pergunta, sem território sobreposto.
3. **Recorte por passo (RN-02, edge 10)** — specify e clarify leem PRD e backlog (o-quê), nunca
   ADRs nem architecture.md; plan lê ADRs + architecture.md; implement lê plan + constitution.
4. **Dever advisório de origem (edge 6)** — spec nasce do fluxo zion (`/zion-prd-specify-prompt`)
   com elo de rastreabilidade; spec sem elo será acusada pelo trace. Conselho, nunca trava.
5. **Ritual de fim de spec (edge 12)** — implementação termina → `/zion-prd-trace`; RF descoberto
   no caminho → `/zion-prd-evolve`.

## O architecture.md do produto

Esqueleto (`assets/templates/architecture-skeleton.md`), espelhando o que o harness dogfooda:

- **Cabeçalho** — declara-se fonte da verdade do como/com-quê do produto; aponta a fronteira
  (o-quê vive na PRD) e a fronteira de donos da regra instalada.
- **§1 Visão geral** — prosa do Autor: componentes e como conversam.
- **§2 Integrações externas** — prosa do Autor: contratos com o mundo de fora.
- **§3 Decisões estruturantes** — **derivada**: índice dos ADRs de `docs/adr/`, entre marcadores
  `<!-- zion:adr-index:start/end -->`.
- **§4 Visão do backlog** — **derivada**: recorte de `docs/backlog.md` (specs e status), entre
  marcadores `<!-- zion:backlog-view:start/end -->`.

A prosa é do Autor e nunca é tocada por máquina; só os dois blocos derivados sincronizam
(edge 16 — nenhuma maquinaria além do ritual do trace). Semeadura retomável no padrão do discovery
(RF-01): documento existente **não é sobrescrito** — só os blocos derivados reconciliam.

## Marcador de origem e reconciliação

- **Gramática do elo (edges 5 e 7)** — o elo de rastreabilidade que o prompt do specify já pede
  (RF-07) ganha formato formal machine-legível na spec: linha `**Elo:** RF-xx`. O formato exato
  deve ser confirmado contra o parser atual de `trace-prd.sh` na fase de plano — a gramática
  formalizada é a que o parser já reconhece, não uma segunda. Elo presente = spec nascida do
  fluxo; ausente = `zion-prd-trace` acusa como intraçável (mecanismo RF-09 existente). Nenhum elo
  novo entre os territórios de spec: reforça-se o existente.
- **Reconciliação dos derivados** — `trace-arquitetura.sh` regenera os dois blocos derivados; o
  ritual do `zion-prd-trace` roda-o junto de `trace-prd.sh` e `trace-backlog.sh`.

## Injeção na ponte do plan

O prompt montado por `zion-prd-plan-prompt` carrega, além dos ADRs confirmados, a prosa
estrutural do architecture.md do produto como restrição a honrar (RF-08 alterado). Specify e
clarify **não** recebem o documento (RN-02) — a injeção é seletiva por passo, como as pontes já
fazem.

## Verificador e guard opt-in

`check-arquitetura.sh` (contrato comum: exit 0 limpo · 1 achados · 2 erro de uso; advisório — a
skill ecoa, o Autor decide). Acusa:

1. Índice de ADRs defasado contra `docs/adr/` (condição 3 do estudo);
2. Seção obrigatória ausente no architecture.md do produto (as quatro seções do esqueleto) ou
   §1 Visão geral vazia — prosa das demais é do Autor e não se cobra conteúdo;
3. Bloco de regras ausente ou de versão defasada no `CLAUDE.md` do produto (edge 13);
4. Visão do backlog defasada contra `docs/backlog.md`.

Viaja como reference da skill instaladora (mesmo padrão do `check-prd.sh`).

**Guard opt-in (edges 6 e 15)** — ao fim da instalação, a skill oferece gravar um hook de
pre-commit no repo do produto que roda `check-arquitetura.sh` **bloqueando** commit com drift — o
ADR-010 exportado por escolha. Default: não instalar (RN-01 intacto).

## Erros e bordas

- **Preflight (padrão RF-16)** — sem `docs/prd.md` no repo-alvo, a skill avisa que a jornada zion
  vem antes e para graciosamente. Sem Spec Kit inicializado, avisa e instala mesmo assim (a regra
  vale desde já; o Spec Kit chega depois).
- **Idempotência** — re-rodar substitui o bloco marcado do `CLAUDE.md`, nunca o resto; documento
  existente nunca é sobrescrito, só blocos derivados reconciliam.
- **CLAUDE.md ausente no produto** — a skill o cria contendo só o bloco marcado.
- **Hook de pre-commit já existente no produto** — o guard opt-in nunca sobrescreve: acrescenta a
  chamada ao hook existente ou, se o formato não permitir, instrui o Autor e para.

## Testes

Fixtures limpa/suja para `check-arquitetura.sh` e `trace-arquitetura.sh` em `scripts/fixtures/`,
auto-testes `test-*.sh` agregados no `eval.sh` (NFR-04), dentro do orçamento de 60s do NFR-01.

## Canonização (mesmo commit)

- **ADR-015 novo** (via `/zion-adr-new`) — integração instalável com o Spec Kit: superfície
  (`CLAUDE.md`/agente único), semântica do marcador de origem, natureza e autoridade do
  architecture.md distribuído (advisório + guard opt-in), fronteira de donos. Evidência: o estudo
  `docs/estudos/integracao-speckit-fonte-canonica.md`.
- **`docs/prd.md`** — `RF-18` novo no E2, retitulado "Pontes e integração com o Spec Kit"
  (instalar a integração); `RF-08` alterado (injeta também
  o architecture.md do produto); `RF-09` alterado (trace reconcilia os blocos derivados do
  documento); `RF-11` alterado (verificador novo na lista); §12 com as linhas novas; §13 changelog
  (C1 para RF-18, C2 para os alterados).
- **`docs/architecture.md`** — ADR-015 no índice §2; scripts novos na §3; assets novos na §4.

## Fora de escopo

- Patch nos templates de comando do Spec Kit (A4 — rejeitada no estudo).
- Automação de reconciliação instalada no repo do produto (edge 12 — ritual humano).
- Cobertura multi-agente da regra instalada (edge 9 — ampliável depois sem quebrar nada).
- Supersessão de ADR-004/RN-01 (edge 6 — enforcement segue advisório por default).
