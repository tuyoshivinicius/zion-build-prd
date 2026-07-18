# Decisão dada — terceiro tipo de risco no registro de ADR

> **Origem:** pedido do usuário — "ser capaz de adicionar um ADR explicitamente sem passar pelo
> fluxo de spike", com a LLM ajudando a clarificar o racional via brainstorming.
> **Data:** 2026-07-18. **Esforço:** Médio. **Escopo:** um 3º tipo de risco (`decisão dada`)
> costurado em `assets/quality-rules.md` + `scripts/check-adr.sh` (ambos sincronizados aos
> `references/`), no template e no procedimento de `skills/zion-adr-new/SKILL.md`, na Fase 1 e 2/3
> de `skills/zion-prd-spike/SKILL.md`, com fixtures/testes e nota no `docs/como-usar.md`.

## Problema

O harness reconhece hoje **dois** riscos por decisão estrutural, e o risco escolhe o meio da
evidência (`quality-rules.md#risco-do-spike`):

- **Risco de execução** → só se resolve rodando → **spike de código** em `docs/adr/spikes/`.
- **Risco de conhecimento** → documentável sem rodar → **pesquisa com fonte citada**.

Falta o terceiro caso: a decisão que **já chegou batida** — política da org, restrição externa,
padrão já estabelecido. Não há dúvida a provar rodando nem lendo; o que sustenta a decisão é a
**autoridade de quem a tomou**. Hoje o harness não tem vocabulário para isso:

- `/zion-adr-new` já é invocável direto, mas o campo `Evidência` do template só aceita spike dir ou
  URL/fonte — uma decisão dada deixaria o campo vazio, e o `check-adr.sh` acusaria `sem-evidencia`.
- A Fase 1 do `/zion-prd-spike` só classifica em execução/conhecimento — uma decisão estrutural que
  já veio dada não teria como ser marcada como tal, forçando um spike ou uma pesquisa artificiais.

O objetivo não é *furar* a disciplina de evidência, e sim reconhecer que **decisão dada é um lastro
de tipo diferente** (racional escrito: quem/que autoridade decidiu e por quê), preservando o
princípio "evidência proporcional ao risco". E como o racional de uma decisão dada costuma chegar
vago ("é assim porque sim"), a LLM **ajuda a destrinchá-lo** via um brainstorming curto e guiado
antes de gravar o ADR.

## Decisões

1. **Terceiro tipo de risco de 1ª classe**, não escotilha nem exceção. `decisão dada` entra em
   `#risco-do-spike` como par de execução/conhecimento, com forma própria no campo `Evidência`.
   Coerente com a filosofia da casa; evita um buraco no vocabulário entre `/zion-adr-new` e a Fase 1
   do spike. (Alternativas descartadas: flag isolada que *isenta* o ADR do check — furaria o
   princípio; só documentar o caminho manual — deixaria o `check-adr.sh` "mentindo".)
2. **Disponível nos dois pontos de entrada**, sem assimetria: no `/zion-adr-new` direto (flag
   `--dada`) e na classificação de risco da Fase 1 do `/zion-prd-spike`.
3. **A LLM clarifica o racional via micro-diálogo embutido** — brainstorming curto, guiado, uma
   pergunta de cada vez, tom advisório, converge com confirmar/editar; no estilo já usado pelo
   discovery e pela Fase 1 do spike. Autocontido (não delega ao `superpowers:brainstorming`, pesado
   demais para um racional de ADR e fora do estilo self-contained do harness). Não bloqueia: se uma
   peça faltar, aponta o buraco e segue com o que há.
4. **Nome: "decisão dada"**; marcador reconhecível no campo `Evidência`: `Decisão dada: <racional>`.
5. **O `check-adr.sh` continua verificando só presença** (racional não-vazio). A qualidade é o que o
   micro-diálogo produz — mantém o invariante "o script verifica, o humano decide".

## Os probes do micro-diálogo

Quatro perguntas dirigidas, cada uma mapeando numa seção do ADR. Autoridade + restrição são o piso
honesto (o "por que é dada"); preteridas + trade-off enriquecem mas não travam.

| Probe | Pergunta | Alimenta |
|---|---|---|
| **Autoridade/fonte** | Quem ou o quê bateu o martelo? (política da org, contrato, restrição externa, lead) | Evidência + Contexto |
| **Restrição que força** | Por que isso é *dado* e não aberto? O que aconteceria se reabríssemos? | Contexto |
| **Opções preteridas** | Mesmo dada, o que ficou de fora? | Decisão |
| **Trade-off aceito** | O que fica mais difícil por aceitar sem provar? | Consequências |

Se o argumento `--dada "..."` (ou a decisão trazida na Fase 1) já vier com um racional forte, a skill
usa como ponto de partida e sonda **só os buracos** — não repete o que já veio. Convergência:
confirmar / editar. O racional destilado vai para `Evidência: Decisão dada: <racional>`; as respostas
preenchem Contexto/Decisão/Consequências.

## Onde as edições caem

### 1. `assets/quality-rules.md` (canônico; sincronizado a 8 skills)

- **`#risco-do-spike`** ganha o 3º tipo:
  > **Decisão dada** — a escolha **já chegou batida de fora** (política da org, restrição externa,
  > padrão já estabelecido); não há dúvida a resolver rodando nem lendo. **Meio: racional escrito no
  > próprio ADR** — quem/que autoridade decidiu e por quê.

  E a regra prática ganha a terceira cláusula: *se não há dúvida a provar — a decisão vem batida — é
  decisão dada; o lastro é registrar a autoridade, não prová-la.*
- **`#criterios-de-conclusao`** (bullet **spike**): "evidência do tipo certo para seu risco — spike
  de código (execução), fonte de pesquisa (conhecimento) **ou racional escrito (decisão dada)**".

Depois: `./scripts/sync-assets.sh` propaga aos `references/`; `./scripts/check-assets.sh` confirma
zero drift.

### 2. `skills/zion-adr-new/SKILL.md` (editado direto — não é asset derivado)

- **Template**, campo `Evidência`, passa a listar **três** formas; a nova:
  ```
  · decisão dada (chega batida de fora): Decisão dada: <autoridade/racional — quem decidiu e por quê>
  ```
- **Argumento**: documentar a flag `--dada [ "<racional inicial>" ]`, paralela à `--substitui` já
  existente. Exemplo:
  `/zion-adr-new "Provider de nuvem" --dada "mandato de infra: reusar o provider já contratado"`.
- **Procedimento**: no modo decisão-dada, antes de gravar, conduzir o **micro-diálogo** (os quatro
  probes acima, uma pergunta por vez, advisório, confirmar/editar). Preencher `Evidência: Decisão
  dada: <racional>` e as seções Contexto/Decisão/Consequências com o que o diálogo destilou. Sem
  spike dir, sem pesquisa.
- **Nota de convenção**: deixar explícito que a decisão dada **não** tem spike dir (o campo aponta
  racional, não `docs/adr/spikes/...`).

### 3. `skills/zion-prd-spike/SKILL.md` (editado direto)

- **Fase 1 — Classificação por risco** passa a oferecer **três** rótulos (execução / conhecimento /
  **decisão dada**), cada um com uma linha de justificativa ancorada em `#risco-do-spike`. Mesmo
  padrão de convergência (confirmar/editar).
- **Fase 2/3** ganha o ramo **decisão dada**: sem spike, sem `deep-research`; conduzir o **mesmo
  micro-diálogo** (descrito como procedimento compartilhado, para não duplicar o do `zion-adr-new`)
  e então invocar `zion-adr-new` preenchendo `Evidência: Decisão dada: <racional>`.
- **Guarda advisory** (Fase 1): se *todas* as 2–3 decisões forem classificadas como dada — não
  sobrou nada a provar —, apontar que o valor do estágio de spike sumiu e sugerir revisar. Só avisa,
  não bloqueia. Impede a classificação de virar escotilha para pular spikes legítimos.

### 4. `scripts/check-adr.sh` (canônico; sincronizado a zion-prd-spike e zion-prd-evolve)

No loop por ADR, **antes** dos ramos spike e conhecimento, casar o marcador de decisão dada:

- Se `ev` (valor de `Evidência`, já trimado) começa com **`decisão dada`** (case-insensitive; o
  rótulo do template é bytes UTF-8 fixos, como o resto do script já assume): extrair o racional
  após o rótulo/`:`. Racional **vazio ou placeholder `<…>`** → novo achado
  **`decisao-dada-sem-racional`** (aponte a autoridade/racional). Racional presente → limpo, e
  `continue` (não cai nos ramos de spike/URL).
- Ordem importa: por vir antes do ramo de conhecimento (que exige URL/caminho), um racional em prosa
  não é mal-acusado como `evidencia-sem-lastro`.
- O check de topo `sem-evidencia` (campo totalmente vazio ou `<placeholder>`) continua valendo —
  decisão dada ainda precisa do racional; campo em branco segue erro.

### 5. Fixtures + testes

- **Clean:** `scripts/fixtures/adr/clean/ADR-003-decisao-dada.md` com `Evidência: Decisão dada: <…
  racional preenchido …>`. A fixture `clean` segue exit 0 / limpo.
- **Dirty:** `scripts/fixtures/adr/dirty/ADR-006-decisao-dada-sem-racional.md` com o marcador e
  racional vazio/placeholder → dispara `decisao-dada-sem-racional`.
- **`scripts/test-check-adr.sh`:** acrescentar assert de que `clean` segue limpo com o novo ADR e de
  que `dirty` acusa `decisao-dada-sem-racional`.

### 6. `docs/como-usar.md`

Documentar, na seção dos gates/estágios: criar um ADR de decisão dada **direto** (`/zion-adr-new
"…" --dada`) com o micro-diálogo, e **via Fase 1 do spike** (classificar como decisão dada). Deixar
claro que o lastro é o racional escrito, não um spike.

## Escopo — o que **não** muda (YAGNI)

- Sem novo script; o `check-adr.sh` ganha um ramo, não um arquivo.
- Sem delegar ao `superpowers:brainstorming`; o micro-diálogo é embutido.
- O `check-adr.sh` não julga qualidade do racional — só presença.
- Sem tocar em `check-prd.sh`, `trace-prd.sh` nem no fluxo do dia 2 (`/zion-prd-evolve`) além do
  `check-adr.sh` que ele já embarca via sync.
- O ADR de decisão dada vira **restrição** na PRD como qualquer outro ADR aceito — nenhuma mudança
  no downstream (PRD §8, constitution).

## Verificação

- `./scripts/test-check-adr.sh` verde (clean segue limpo; dirty acusa `decisao-dada-sem-racional`).
- `./scripts/check-assets.sh` passa (sem drift após `sync-assets.sh`).
- `./scripts/eval.sh` verde (suíte mecânica completa).
- Releitura das SKILLs: `zion-adr-new` conduz o micro-diálogo no modo `--dada` e grava o marcador; a
  Fase 1 do spike oferece os três rótulos; a Fase 2/3 roda o ramo de decisão dada sem spike/pesquisa;
  a guarda advisory dispara quando tudo vira dada.
- Roteiro manual: uma decisão dada com racional forte no argumento (sonda só buracos) e uma com
  racional vago (micro-diálogo completo) — ambas produzem ADR que passa no `check-adr.sh`.
