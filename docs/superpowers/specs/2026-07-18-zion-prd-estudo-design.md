# Design — zion-prd-estudo (Estágio 0: estudo pré-discovery)

> Spec validada em brainstorming (2026-07-18). Origem: prompt one-shot do autor que produz um
> documento de estudo antes do discovery; esta skill traz esse fluxo para dentro da governança do
> harness.

## Problema

Antes de rodar o discovery, o autor às vezes precisa de um **estudo** que oriente a direção: edge
cases, alternativas comparadas, ROI e uma recomendação não vinculante. Hoje isso é feito por um
prompt one-shot fora do harness — sem governança (não lê as fontes canônicas por contrato, não
respeita mecanicamente a fronteira o-quê/como, não é verificável nem distribuível).

## Decisões de design (validadas com o autor)

1. **Posição:** Estágio 0 **formal e opcional** da jornada, antes do discovery. Entra na sequência
   de `assets/process-context.md` e no escopo da PRD.
2. **Interação:** contrato de fases com convergência, no padrão dos irmãos (gates aconselham,
   nunca bloqueiam — RN-01).
3. **Verificação:** verificador mecânico completo `check-estudo.sh` no padrão E5 (fixtures
   limpa/suja + auto-teste, agregado pelo `eval.sh`).
4. **Governança da decisão:** ADR novo (ADR-012) via `/zion-adr-new`, evidência tipo *decisão
   dada* (racional: o prompt one-shot já provou o valor na prática do autor).

## Escopo e posicionamento

- Skill `zion-prd-estudo` (prefixo por ADR-003), comando `/zion-prd-estudo`, argumento: o
  candidato a discovery (2–6 frases: quem sofre, solução imaginada, restrições conhecidas).
- Saída: `docs/estudos/<slug-do-candidato>.md` no projeto-alvo, com 6 seções (abaixo).
- **Aconselha, não decide:** o documento subsidia; o humano escolhe a alternativa e conduz ele
  mesmo discovery → spike/ADR → PRD.
- **Genérica para qualquer projeto-alvo:** lê `docs/prd.md`, `docs/architecture.md` e `docs/adr/`
  do projeto **se existirem** (brownfield: nenhuma alternativa pode contradizer ADR vigente;
  supersessão de ADR é custo declarado da alternativa) e degrada graciosamente no greenfield
  (sem fontes, o estudo ancora só no candidato e declara a ausência). Rodar no próprio
  zion-build-prd é o caso dogfood.
- **Guardas (não faz):** não cria/altera ADRs, PRD, architecture, skills ou assets do
  projeto-alvo; não grava `docs/discovery.md` nem código; a recomendação é sempre marcada como
  não vinculante.

## Contrato de fases

- **Fase 0 — Entrada (aconselha).** Candidato ausente no argumento → colher (quem sofre, solução
  imaginada, restrições). `docs/estudos/<slug>.md` já existe → avisar e perguntar se retoma ou
  sobrescreve. Preflight do superpowers no padrão RF-16: ausente → avisa com o comando de
  instalação e para graciosamente.
- **Fase 1 — Leitura das fontes.** Lê PRD, architecture e ADRs do projeto-alvo (os que existirem)
  e resume em 3–5 linhas o que restringe o candidato, citando fonte (`prd.md §x`, `ADR-xxx`).
  Fontes ausentes → declara greenfield e segue.
- **Fase 2 — Edge cases via brainstorming (convergência).** Usa `superpowers:brainstorming`
  (única dependência externa, contrato C1–C3 do ADR-007) para explorar edge cases e incertezas do
  candidato. Apresenta a lista marcando as perguntas que **só o humano pode responder**; usuário
  confirma/edita. Não bloqueia.
- **Fase 3 — Alternativas + ROI (convergência).** 2–4 alternativas, **sempre incluindo "não
  fazer"**, cada uma em nível de "o quê" (fronteira sem stack — `quality-rules.md#fronteira`),
  com prós, contras, ADRs tocados e supersessões declaradas como custo. ROI por alternativa:
  impacto na persona (1–5), esforço (1–5, invertido), risco/reversibilidade (1–5, invertido);
  ROI = média **justificada em texto**, tabela ordenada. Apresenta para confirmar/editar antes de
  gravar. Não bloqueia.
- **Fase 4 — Gravação + veredito (aconselha).** Grava `docs/estudos/<slug>.md` com as 6 seções:
  1. **Contexto** — candidato em 1 parágrafo, relação com a visão da PRD e a persona (quando
     existirem).
  2. **Edge cases e incertezas** — perguntas que a alternativa vencedora terá de responder;
     marcadas as que só o humano responde.
  3. **Alternativas** — as 2–4 convergidas.
  4. **ROI** — tabela ordenada + justificativas.
  5. **Recomendação** — 1 parágrafo, claramente marcado como não vinculante.
  6. **Próximo passo sugerido** — instrução literal: "se aprovado, rodar `/zion-prd-discovery`
     com a alternativa escolhida (e `/zion-prd-spike` se houver decisão estruturante nova)".

  Roda `references/check-estudo.sh` sobre o arquivo e **ecoa o veredito como conselho**
  (ADR-004). Dever em prosa (indecidível): toda afirmação sobre o estado atual do projeto cita a
  fonte (`prd.md §`, `ADR-xxx`).

## Verificador mecânico — check-estudo.sh

- Contrato comum: exit 0 limpo · 1 achados · 2 erro de uso. Entrada: caminho do arquivo de
  estudo.
- Verifica o **decidível**:
  - As 6 seções obrigatórias presentes.
  - Alternativa "não fazer" presente na seção de alternativas.
  - Denylist de stack (reusada de `assets/quality-rules.md`, mesmo mecanismo do `check-prd.sh`)
    aplicada às seções de Alternativas e ROI.
- Fora do escopo mecânico (fica em prosa na Fase 4): citação de fonte em toda afirmação —
  indecidível por máquina.
- Acompanham: `scripts/test-check-estudo.sh` + fixtures limpa/suja em `scripts/fixtures/`,
  agregados pelo `eval.sh` (NFR-04). Distribuído como reference executável via `ASSET_MAP`.

## Canonização (mesmo commit da implementação)

| Mudança | Reflete em |
|---|---|
| Decisão do Estágio 0 | ADR-012 via `/zion-adr-new` (evidência: decisão dada) + índice §2 do `architecture.md` |
| Skill nova | RF-17 no épico E1 (§6) + linha na §12 da PRD (RF-17 · E1 · skills/zion-prd-estudo) |
| Verificador novo | `check-estudo.sh` somado à linha RF-11 e `test-check-estudo.sh` à RF-12 (§12 da PRD); tabela §3 do `architecture.md`; lista de references executáveis (§4) |
| Jornada muda | Escopo §4 da PRD ganha o estudo; objetivo §2 ajustado (5 estágios + estudo opcional); `assets/process-context.md` ganha o Estágio 0 (derivados regenerados por sync) |

## Fora de escopo

- Executar o discovery ou qualquer estágio seguinte a partir do estudo.
- Ranking automático de candidatos (a skill estuda **um** candidato por vez).
- Persistência de estado entre sessões além do próprio documento gravado.
