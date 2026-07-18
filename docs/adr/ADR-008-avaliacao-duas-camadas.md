# ADR-008 — Avaliação em duas camadas

- **Status:** Aceito
- **Data:** 2026-07-17
- **Decisores:** autoria do repo
- **Evidência:** docs/superpowers/specs/2026-07-17-r7-fixtures-avaliacao-harness-design.md

## Contexto

O harness não possuía suíte de avaliação de si mesmo (defeito H2): editar `assets/quality-rules.md`, o ponto único de afinação, era mexer às cegas, sem fixture que confirmasse que a Fase 4 do `write` acusa vazamento conhecido ou que o `decompose` reprova uma fatia horizontal. Cerca de metade das regras decidíveis já tinha verificador mecânico (R1 `check-prd.sh`, R2 `trace-prd.sh`, R3 `check-adr.sh`), cada um com fixtures e um `test-*.sh` no CI, mas essas peças estavam espalhadas e cobriam apenas o que é script-verificável; os vereditos que dependem de julgamento do LLM — fatia horizontal, vazamento de tela/aceite fora da denylist, ausência de "não faz" — não tinham nenhuma rede de proteção.

## Decisão

Adotar uma suíte de avaliação de duas camadas com um ponto de entrada unificado: (1) a camada mecânica determinística, já ~90% pronta, consolidada num runner único `scripts/eval.sh` que roda os três self-tests existentes e emite veredito agregado (sai não-zero se qualquer um falhar), rodada no CI a cada push sem nenhuma fixture mecânica nova; e (2) uma camada LLM não-determinística, rodada sob demanda e nunca no CI, com seis fixtures em `scripts/fixtures/skills/` (discovery/write/decompose) onde cada caso é um artefato com defeito plantado exercitado pela lente de validação (Fase 4) da skill e comparado a um sidecar `esperado.md` de frontmatter legível por máquina, sempre com um par `limpa` (entrada boa → aprova) como guarda contra falso-positivo. O julgamento manual segue um roteiro documentado em `docs/avaliacao-harness.md` (as duas camadas, como rodar cada uma, índice de fixtures e interpretação por taxa de acerto), incluindo um procedimento opcional de runner por agentes (subagente por caso + agente-juiz). Foram descartadas as opções de transformar o runner numa skill nova `/zion-prd-eval` e de implementá-lo como script Workflow, ambas adiadas para promoção futura sem reescrita de fixtures; ficaram fora (YAGNI) cobrir as três pontes na camada LLM, rodar a camada LLM no CI, adicionar fixtures mecânicas novas e pinar o superpowers (R9).

## Consequências

A suíte fecha o gap H2 sobre o julgamento das skills criativas com custo de manutenção mínimo — na v1 a camada LLM é só prosa e fixtures, zero superfície de código nova além do `eval.sh`, e o contrato `esperado.md` já serve tanto ao modo manual quanto a uma futura skill `/zion-prd-eval`. Em troca, aceita-se que a camada LLM é não-determinística, custa token, roda apenas sob demanda e reporta taxa de acerto (não verde/vermelho binário), de modo que um erro isolado dispara investigação — mudou a skill, o `quality-rules` derivou ou a fixture está ambígua? — em vez de reprovar o harness; o caso `write/vazamento-tela-aceite` planta de propósito um defeito que o `check-prd.sh` não captura, marcando a fronteira da zona cinzenta entre script e julgamento. Limites conhecidos: matriz de fixtures das três pontes (constitution/specify/plan) fica para v2, a validação de entrega é manual única sobre as seis fixtures, e um `esperado.md` malformado é tratado como erro de suíte, não como falha da skill.

## Status

Aceito.
