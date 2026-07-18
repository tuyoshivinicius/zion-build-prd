# ADR-004 — Verificadores aconselham no projeto-alvo

- **Status:** Aceito
- **Data:** 2026-07-17
- **Decisores:** autoria do repo
- **Evidência:** docs/superpowers/specs/2026-07-17-check-prd-verificacao-mecanica-design.md

## Contexto

O harness Zion Build PRD define regras genuinamente decidíveis em `assets/quality-rules.md` — zero stack na PRD e no specify, todo NFR com número, cada RF-xx agrupado por épico — mas delega **toda** a verificação à Fase 4 de cada skill, ou seja, a prosa interpretada pelo mesmo LLM que acabou de escrever o artefato. A falha previsível se materializou no único projeto que usou o método ponta-a-ponta: "React Flow" vazou para a PRD real (`zion-mermaid-editor-app/docs/PRD.md:220`) e nenhum gate apontou, embora um simples `grep` contra a denylist da própria fronteira o pegasse. A ironia é que o repositório já possui o padrão certo de enforcement mecânico (`scripts/check-assets.sh` + hook + CI), porém só para proteger os assets do harness, não para executar as regras de qualidade que justificam sua existência — e a falha real ocorre no projeto *consumidor*, que não tem este repo, logo o check precisa viajar junto e rodar lá.

## Decisão

Adotar um verificador em shell, `scripts/check-prd.sh`, que executa mecanicamente as três regras decidíveis da R1 contra os artefatos reais e **aconselha no projeto-alvo** sem nunca bloquear o autor: o script apenas verifica (exit `0` limpo / `1` com achados ancorados em `arquivo:linha`), enquanto o humano decide — quem lê o exit code é a Fase 4 das skills `zion-prd-write` (`check-prd.sh prd docs/PRD.md`) e `zion-prd-specify-prompt` (`check-prd.sh specify -` via stdin), que reporta o veredito com autoridade mas não reverte. A detecção é híbrida (denylist curada, case-insensitive, encodada num bloco cercado `denylist` de fonte única no `quality-rules.md`, mais sinais estruturais de alta precisão: blocos de código, `npm/pip/yarn`, `import`, versão `x.y.z`); a distribuição reaproveita o padrão já existente — canônico em `scripts/`, sincronizado para `references/` via `asset-map.sh`/`sync-assets.sh`, vigiado por `check-assets.sh` e regenerado pelo hook. Foram conscientemente descartadas: a supressão inline de falso-positivo e o bloqueio/exit gate (YAGNI — só importariam se o gate barrasse; o humano descarta um falso-positivo na hora); tratamento especial da seção 8 de ADRs (um nome de stack ali É o vazamento a expor); e, como plano B caso o `npx skills` não empacote `references/*.sh`, embutir o script no `SKILL.md` via heredoc.

## Consequências

O harness passa a aplicar às próprias regras de qualidade o enforcement mecânico que já usava para os assets, com baixo falso-positivo e achados que apontam a linha exata, mantendo a filosofia "gates aconselham, não bloqueiam"; a arquitetura de funções de check independentes com dispatch por modo deixa R4 (RF↔FR) e outras regras plugarem depois sem retrabalho, e cada fixture do auto-teste (`test-check-prd.sh` + `fixtures/`, mais um job de CI) já é metade de uma futura fixture de avaliação da R7. Os limites conhecidos e assumidos: continua fora de escopo a supressão inline, o bloqueio de fluxo, a regra R4, o hook/CI dentro do projeto consumidor e a suíte completa de avaliação (R7, da qual só entra a semente de fixtures); a robustez depende de curar bem a denylist e resta o ponto de verificação explícito sobre o empacotamento de `references/*.sh` pelo `npx skills`, com o heredoc no `SKILL.md` como contingência.

## Status

Aceito.
