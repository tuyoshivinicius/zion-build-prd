# ADR-006 — Evidência de ADR proporcional ao risco

- **Status:** Aceito
- **Área:** Governança
- **Data:** 2026-07-17
- **Decisores:** autoria do repo
- **Evidência:** docs/superpowers/specs/2026-07-17-spike-evidencia-por-risco-design.md

## Contexto

O Estágio 2 do harness carregava uma contradição embarcada: o guia prometia responder às 2–3 decisões estruturantes com "código descartável (não com opinião)" e cobrava, na Fase 4, um "spike real que você de fato rodou", mas a skill `/zion-prd-spike` apenas levantava trade-offs via `deep-research` e registrava o ADR — nunca produzia código. No único projeto que usou o método ponta-a-ponta, só 1 dos 4 ADRs tinha spike de código real; os demais rotulavam execuções de pesquisa como "spike", exatamente a "opinião com citações" que o guia dizia evitar — teatro de conformidade. Como a própria crítica registra que o elo spike→ADR é síntese do zion, sem respaldo canônico, cabia dimensioná-lo em vez de mantê-lo como dogma. Este ADR complementa-se com o doc irmão `2026-07-18-adr-decisao-dada-design.md`, que introduz um terceiro tipo de risco — a "decisão dada" (a escolha que já chega batida de fora, sustentada pela autoridade de quem a tomou) — fechando o vocabulário de riscos aberto aqui.

## Decisão

A evidência de cada ADR passa a ser proporcional ao risco da decisão, com o tipo de risco escolhendo o meio da evidência: risco de execução (a dúvida só se resolve rodando algo) exige spike de código descartável em `docs/adr/spikes/ADR-00x-<slug>/` com `README.md` obrigatório (pergunta + o que foi rodado + veredito); risco de conhecimento (trade-off documentável sem rodar) exige pesquisa com fonte citada (URL ou caminho de artefato); e o risco de decisão dada exige racional escrito no próprio ADR (quem/que autoridade decidiu e por quê). O ADR ganha um campo obrigatório `Evidência`, a Fase 1 da skill classifica cada decisão por uma heurística decidível ancorada em `#risco-do-spike` (skill propõe, usuário confirma), e a presença — não a qualidade — do lastro é verificada mecanicamente por um novo `scripts/check-adr.sh`, no mesmo molde de `check-prd.sh`/`trace-prd.sh` (fixtures, auto-teste, sync via `asset-map.sh`, passo no CI). Descartaram-se o "código sempre" (força código onde o risco é de conhecimento), o "pesquisa sempre" (o teatro atual), estender o `check-prd.sh` em vez de um script próprio (preocupações distintas) e o bloqueio por gate (mantém-se advisório).

## Consequências

O harness deixa de mentir sobre rigor: fecha as fragilidades F1/H5 fazendo a promessa casar com o mecanismo, correlaciona ADR↔spike automaticamente pelo número/slug (sem elo manual a quebrar) e mantém a filosofia advisória (exit `0`/`1`/`2`; a Fase 4 ecoa o veredito com autoridade mas não reverte). Em contrapartida, o verificador confere apenas presença do lastro apontável, não a qualidade do spike ou da fonte — o julgamento fica com a Fase 4/humano; a classificação de risco depende da confirmação do usuário e pode ser mal-calibrada; e ficam conscientemente fora de escopo a auditoria retroativa de ADRs antigos (território de H8/R8), a colisão de nome "spike" com o S de SPIDR, o bloqueio por gate e a suíte completa de avaliação do harness (entra só a semente de fixtures do `check-adr`).

## Status

Aceito.
