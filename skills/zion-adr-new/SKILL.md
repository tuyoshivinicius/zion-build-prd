---
name: zion-adr-new
description: Cria um Architecture Decision Record em docs/adr/ (Contexto/Decisão/Consequências/Status) a partir de um título. Use no Estágio 2 do harness Zion Build PRD para registrar cada decisão estruturante sustentada por spike, ou sempre que o usuário pedir para "criar/registrar um ADR" ou "documentar uma decisão de arquitetura".
argument-hint: "Título da decisão (ex.: \"Escolha de estado\"); opcional --dada [\"<racional>\"] ou --substitui ADR-<n> no dia 2"
metadata:
  author: zion-build-prd
user-invocable: true
disable-model-invocation: false
---

# zion-adr-new — criar um Architecture Decision Record

Registra uma decisão estruturante como um ADR em `docs/adr/`, com as seções
**Contexto / Decisão / Consequências / Status**. Use no Estágio 2 do harness (Spikes + ADRs) —
ver `references/process-context.md` — para registrar as 2–3 decisões que mudam a PRD inteira,
sustentadas por **evidência proporcional ao risco** (spike de código para risco de execução; fonte
de pesquisa para risco de conhecimento — ver `#risco-do-spike` em `references/quality-rules.md`).

## Argumento

Um título curto para a decisão, entre aspas. Exemplos:

```text
/zion-adr-new  "Escolha de biblioteca de renderização de diagramas"
/zion-adr-new  "Estratégia de gerenciamento de estado do editor"
/zion-adr-new  "Provider de nuvem" --dada "mandato de infra: reusar o provider já contratado"
/zion-adr-new  "Motor de exportação vetorial" --substitui ADR-002
```

O sufixo opcional `--substitui ADR-<n>` ativa o **modo substituir** (dia 2 — ver abaixo). O sufixo
opcional `--dada [ "<racional inicial>" ]` ativa o **modo decisão dada** (ver abaixo): a decisão já
chegou batida de fora e o lastro é o racional escrito, não um spike nem uma pesquisa. O racional
inicial entre aspas é opcional — se vier, a skill parte dele e sonda só os buracos.

## Procedimento

1. **Garanta o diretório.** Crie `docs/adr/` se ainda não existir.
2. **Determine o próximo número.** Liste `docs/adr/ADR-*.md` e use o maior número existente + 1,
   com três dígitos (`001`, `002`, …). Se não houver nenhum, comece em `001`.
3. **Gere o slug.** Converta o título para *kebab-case* minúsculo, sem acentos
   (ex.: `"Escolha de biblioteca"` → `escolha-de-biblioteca`).
4. **Crie o arquivo** `docs/adr/ADR-<n>-<slug>.md` com o conteúdo do template abaixo,
   substituindo `<n>`, `<slug>` e `<título>` pelos valores reais. Deixe `Status: Proposto`
   até a decisão ser aceita; então atualize para `Aceito`.
5. **Confirme** ao usuário o caminho do arquivo criado.

## Template do arquivo gerado

```markdown
# ADR-<n> — <título>

- **Status:** Proposto
- **Data:** <preencher>
- **Decisores:** <preencher>
- **Substitui:** <só no modo substituir: ADR-<n>; no modo normal, omita esta linha>
- **Evidência:** <uma das três — o tipo casa com o risco da decisão>
    · execução (só se resolve rodando): `docs/adr/spikes/ADR-<n>-<slug>/` (dir com README.md + artefatos descartáveis)
    · conhecimento (documentável sem rodar): <URL ou caminho do artefato de pesquisa que sustenta a decisão>
    · decisão dada (chega batida de fora): Decisão dada: <autoridade/racional — quem decidiu e por quê>

## Contexto

Qual é a força / problema / dúvida estruturante? Que restrições e requisitos (RF-xx / RN-xx / NFRs)
estão em jogo? Que evidência (spike de código ou pesquisa) sustenta a decisão, e qual o risco que
ela endereça?

## Decisão

A decisão tomada, em uma frase clara e decidível. Inclua a opção escolhida e as descartadas.

## Consequências

O que fica mais fácil e o que fica mais difícil a partir daqui. Impactos na PRD (restrições) e na
`constitution`. Trade-offs aceitos e limites conhecidos.

## Status

Proposto → Aceito → (Substituído por ADR-<m>, se for o caso).
```

## Modo substituir (supersessão) — dia 2

Disparado por `/zion-adr-new "<título>" --substitui ADR-<n>` (ou pelo `/zion-prd-evolve` no C3). Além do
modo normal:

1. **No ADR novo (ADR-<m>):** mantenha a linha de cabeçalho `- **Substitui:** ADR-<n>` e escreva o
   **Contexto** explicando por que a decisão anterior caiu.
2. **No ADR antigo (ADR-<n>):** edite o cabeçalho para `- **Status:** Substituído por ADR-<m>` — a
   referência é **cruzada e simétrica** (cada um aponta o outro). O `check-adr.sh` verifica essa simetria
   (achado `supersessao-assimetrica` quando a referência é quebrada ou unilateral).
3. **Restrição na PRD §8:** a restrição correspondente precisa de atualização — quem edita a §8 é o
   `/zion-prd-evolve`, no plano de toque. Aqui, apenas **lembre** (advisório).

## Modo decisão dada

Disparado por `/zion-adr-new "<título>" --dada [ "<racional inicial>" ]` (ou pela Fase 2/3 de
`/zion-prd-spike` quando uma decisão é classificada como *decisão dada*). Não há spike dir nem fonte
de pesquisa: o lastro é o **racional escrito** — quem/que autoridade decidiu e por quê. O campo
`Evidência` recebe o marcador `Decisão dada: <racional>`.

**Micro-diálogo (procedimento compartilhado).** Antes de gravar o ADR, destile o racional com um
brainstorming curto e guiado: **uma pergunta de cada vez**, tom advisório, converge com
**confirmar / editar**. Autocontido — não delega ao `superpowers:brainstorming`. Não bloqueia: se
uma peça faltar, aponte o buraco e siga com o que há. Se o `--dada "..."` (ou a decisão trazida na
Fase 1 do spike) já vier com racional forte, use-o como ponto de partida e sonde **só os buracos** —
não repita o que já veio.

Quatro probes, cada um mapeando numa seção do ADR. Autoridade + restrição são o piso honesto (o "por
que é dada"); preteridas + trade-off enriquecem mas não travam:

| Probe | Pergunta | Alimenta |
|---|---|---|
| **Autoridade/fonte** | Quem ou o quê bateu o martelo? (política da org, contrato, restrição externa, lead) | Evidência + Contexto |
| **Restrição que força** | Por que isso é *dado* e não aberto? O que aconteceria se reabríssemos? | Contexto |
| **Opções preteridas** | Mesmo dada, o que ficou de fora? | Decisão |
| **Trade-off aceito** | O que fica mais difícil por aceitar sem provar? | Consequências |

**Ao gravar:** preencha `Evidência: Decisão dada: <racional destilado>` e as seções
Contexto / Decisão / Consequências com o que o diálogo destilou. **Sem spike dir, sem pesquisa.** O
`check-adr.sh` reconhece o marcador e confere só a **presença** do racional (achado
`decisao-dada-sem-racional` se vier vazio/placeholder) — a qualidade é o que o micro-diálogo produz.

## Convenção do spike dir (risco de execução)

Quando a decisão é de **risco de execução**, o campo `Evidência` aponta um diretório
`docs/adr/spikes/ADR-<n>-<slug>/` (mesmo número/slug do ADR), que deve conter:

- **`README.md`** (obrigatório) — a pergunta do spike, o que foi rodado e o veredito.
- **Artefatos descartáveis** — o código/medições do spike (livre).

O `zion-adr-new` **não** cria o spike dir: o spike é escrito na Fase 2/3 de `/zion-prd-spike`, antes
ou junto do ADR. O template só documenta a convenção e o campo que a referencia. A presença dessa
evidência é verificada por `check-adr.sh` (rodado pela Fase 4 de `/zion-prd-spike`).

> **Decisão dada não tem spike dir.** Quando o modo decisão dada está ativo, o campo `Evidência`
> aponta o racional escrito (`Decisão dada: …`), não um `docs/adr/spikes/…` — não crie diretório de
> spike nesse caso.

## Saída

Um arquivo `docs/adr/ADR-<n>-<slug>.md` pronto para revisão. Cada ADR aceito vira uma **restrição**
na PRD (seção de restrições) e alimenta a `constitution` do Spec Kit.
