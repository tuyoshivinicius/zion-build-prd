---
name: adr-new
description: Cria um Architecture Decision Record em docs/adr/ a partir de um título
argument-hint: "Título da decisão estruturante (ex.: \"Escolha de biblioteca de estado\")"
metadata:
  author: zion-build-prd
user-invocable: true
disable-model-invocation: false
---

# adr-new — criar um Architecture Decision Record

Registra uma decisão estruturante como um ADR em `docs/adr/`, com as seções
**Contexto / Decisão / Consequências / Status**. Use no Estágio 2 do harness (Spikes + ADRs) —
ver `references/process-context.md` — para registrar as 2–3 decisões que mudam a PRD inteira,
sustentadas por um spike que você de fato rodou.

## Argumento

Um título curto para a decisão, entre aspas. Exemplos:

```text
/adr-new  "Escolha de biblioteca de renderização de diagramas"
/adr-new  "Estratégia de gerenciamento de estado do editor"
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

## Contexto

Qual é a força / problema / dúvida estruturante? Que restrições e requisitos (RF-xx / RN-xx / NFRs)
estão em jogo? Que spike foi rodado para sustentar a decisão?

## Decisão

A decisão tomada, em uma frase clara e decidível. Inclua a opção escolhida e as descartadas.

## Consequências

O que fica mais fácil e o que fica mais difícil a partir daqui. Impactos na PRD (restrições) e na
`constitution`. Trade-offs aceitos e limites conhecidos.

## Status

Proposto → Aceito → (Substituído por ADR-<m>, se for o caso).
```

## Saída

Um arquivo `docs/adr/ADR-<n>-<slug>.md` pronto para revisão. Cada ADR aceito vira uma **restrição**
na PRD (seção de restrições) e alimenta a `constitution` do Spec Kit.
