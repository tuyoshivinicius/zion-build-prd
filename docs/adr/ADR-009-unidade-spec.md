# ADR-009 — A unidade de trabalho chama-se spec

- **Status:** Aceito
- **Data:** 2026-07-18
- **Decisores:** autoria do repo
- **Evidência:** docs/superpowers/specs/2026-07-18-rename-fatia-spec-design.md

## Contexto

O harness carregava três nomes para granularidades vizinhas — "fatia" (a unidade vertical do backlog), "épico" (agrupador de RFs) e "spec" (o artefato do Spec Kit) —, e como cada fatia vira exatamente uma spec no Spec Kit (o slug da fatia já é o nome da pasta `specs/###-<slug>` e da branch), manter dois nomes para a mesma unidade gerava atrito de vocabulário; o escopo foi confirmado com o usuário no sentido de renomear apenas "fatia", preservando "épico", que ocupa outra granularidade ao agrupar RFs na §6 e conter várias specs (hierarquia RF → épico → spec).

## Decisão

A unidade de trabalho passa a chamar-se **spec** (feminino, "a spec"), convergindo com a nomenclatura do Spec Kit e consolidando a hierarquia RF → épico → spec em toda a superfície: o verbo permanece ("fatiar", "fatiamento", "refatiar" seguem nomeando o ato de cortar por INVEST/SPIDR), a migração é total e sem retrocompatibilidade (o parser do `trace-backlog.sh` só aceita o formato novo, casando coluna humana por `slug` e coluna de máquina por `pasta`), o backlog canônico troca `Fatia (slug)`→`Spec (slug)` e a coluna de máquina `Spec`→`Pasta` para eliminar colisão, a legenda `◐ em spec`→`◐ em especificação`, e a renomeação percorre assets canônicos, as 9 SKILL.md zion, docs, README, fixtures e testes, com desambiguação frente ao Spec Kit ("spec" = unidade; "`spec.md`" e "pasta `specs/###-<slug>`" = seus artefatos); foram descartadas as opções de manter os dois nomes (o problema original), renomear também "épico" (fora de granularidade) e oferecer retrocompatibilidade no parser (rejeitada explicitamente pelo usuário).

## Consequências

O vocabulário fica alinhado ao Spec Kit e sem duplicidade, ao custo de uma quebra deliberada: backlogs existentes deixam de ser reconhecidos pelo parser e exigem migração manual (renomear dois cabeçalhos, uma linha cada), documentada em `docs/como-usar.md`; ficam intocados o histórico datado (`plans/*`, `specs/*`, críticas e avaliações), o `trace-prd.sh` e a tabela §12 (já usam `Feature / Spec`), os nomes de diretórios de fixture de teste (apenas seu conteúdo muda se citar a unidade) e o conceito e nome "épico", com validação garantida por `test-trace-backlog.sh`, `test-check-prd.sh` e `check-assets.sh` verdes e por grep final assegurando que "fatia" só sobrevive como verbo/ato, nunca como substantivo da unidade.

## Status

Aceito.
