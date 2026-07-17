---
name: zion-adr-new
description: Cria um Architecture Decision Record em docs/adr/ (Contexto/Decisão/Consequências/Status) a partir de um título. Use no Estágio 2 do harness Zion Build PRD para registrar cada decisão estruturante sustentada por spike, ou sempre que o usuário pedir para "criar/registrar um ADR" ou "documentar uma decisão de arquitetura".
argument-hint: "Título da decisão estruturante (ex.: \"Escolha de biblioteca de estado\")"
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
```

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
- **Evidência:** <um dos dois — o tipo casa com o risco da decisão>
    · execução (só se resolve rodando): `docs/adr/spikes/ADR-<n>-<slug>/` (dir com README.md + artefatos descartáveis)
    · conhecimento (documentável sem rodar): <URL ou caminho do artefato de pesquisa que sustenta a decisão>

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

## Convenção do spike dir (risco de execução)

Quando a decisão é de **risco de execução**, o campo `Evidência` aponta um diretório
`docs/adr/spikes/ADR-<n>-<slug>/` (mesmo número/slug do ADR), que deve conter:

- **`README.md`** (obrigatório) — a pergunta do spike, o que foi rodado e o veredito.
- **Artefatos descartáveis** — o código/medições do spike (livre).

O `zion-adr-new` **não** cria o spike dir: o spike é escrito na Fase 2/3 de `/zion-prd-spike`, antes
ou junto do ADR. O template só documenta a convenção e o campo que a referencia. A presença dessa
evidência é verificada por `check-adr.sh` (rodado pela Fase 4 de `/zion-prd-spike`).

## Saída

Um arquivo `docs/adr/ADR-<n>-<slug>.md` pronto para revisão. Cada ADR aceito vira uma **restrição**
na PRD (seção de restrições) e alimenta a `constitution` do Spec Kit.
