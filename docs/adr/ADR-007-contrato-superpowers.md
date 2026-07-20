# ADR-007 — Contrato de capacidades C1–C3 com o superpowers

- **Status:** Aceito
- **Área:** Delegação
- **Data:** 2026-07-17
- **Decisores:** autoria do repo
- **Evidência:** docs/superpowers/specs/2026-07-17-r9-contrato-superpowers-design.md

## Contexto

A skill `superpowers:brainstorming` é o executor de três dos quatro estágios criativos do harness (discovery, write, decompose), mas o contrato entre harness e brainstorming era implícito: espera-se que a skill aceite um enquadramento fixo e grave um arquivo no caminho nomeado, sem pin de versão nem teste de contrato (gap H4 da crítica). O preflight de cada estágio cobria apenas a ausência da skill, não a mudança de comportamento, de modo que uma atualização do superpowers poderia degradar silenciosamente os três estágios centrais sem que nada acusasse. O risco era real e não hipotético — havia duas versões em cache (5.0.7 e 6.1.1, um major bump) e a dependência em `plugin.json` não tinha pin; o major bump chegou a ocorrer e só não quebrou por sorte, já que a única mudança relevante foi o timing da oferta do visual companion. O princípio norteador, herdado de R1/R7 e do padrão assets→references, é mover o invariante de prosa para máquina e trocar a promessa sem mecanismo por uma promessa menor com mecanismo.

## Decisão

Estabelecer um contrato explícito de três capacidades que o harness efetivamente consome do brainstorming — C1: aceitar um enquadramento fixo e refinar ideia em design; C2: gravar o resultado num arquivo cujo caminho nomeamos (sob `docs/`); C3: conduzir diálogo seção a seção / uma pergunta por vez — verificado por dois mecanismos complementares e pareados. Primeiro, um pin semver hard no `plugin.json` (`"version": ">=5 <7"`), que trava a dependência aos dois majors testados e transforma um upstream fora do range em erro visível no load time, não em degradação silenciosa. Segundo, um check estático (`check-superpowers-contract.sh`) que faz grep de marcadores de capacidade tolerantes a reescrita no `SKILL.md` instalado — C1 e C3 satisfeitas por qualquer marcador alternante (OR), C2 exigindo os dois marcadores juntos (escreve doc ∧ caminho sob `docs/`) — rodando apenas na suíte `eval.sh` e coberto por um auto-teste com fixtures (`clean` → exit 0, `drift-c2` → exit 1 citando C2). O contrato vive como asset único em `assets/superpowers-contract.md`, sincronizado para as `references/` das três skills dependentes. Foram descartadas: testar a execução real da skill (é interativa/socrática, não roda headless — daí a opção pela checagem estática análoga ao `check-assets`); rodar o check na Fase 0 (introduziria atrito no uso normal, sendo o drift um problema de manutenção/upgrade); falhar com exit 1 quando o superpowers não é encontrado (quebraria sempre o CI do repo, que não tem o plugin); e checar marcadores fora de escopo como "writing-plans terminal" ou "spec self-review", que virariam ruído a cada refraseado.

## Consequências

O drift dos três estágios centrais passa a ser detectável e o pin torna qualquer major não testado um erro explícito no carregamento, ao custo de manutenção deliberadamente contida (duas fixtures em vez de uma por capacidade, marcadores mínimos de capacidade em vez de diff de frase). A limitação conhecida mais importante é a degradação graciosa: quando nada é localizado, o check emite aviso de "não verificável" e sai 0, de modo que rodar `eval.sh` sem o superpowers instalado — como no CI do repo — não acusa R9; a proteção real depende de rodar no ambiente de quem faz o upgrade, e no CI a lógica é garantida apenas pelo auto-teste contra fixtures. Havendo múltiplas versões em cache, vence a maior (`sort -V`), coerente com o load-time do Claude Code, e o runbook de drift orienta a atualizar o marcador quando a capacidade muda de forma mas persiste, e a não alargar o pin quando ela realmente some. R9 não altera a Fase 0 das skills, não adiciona ritual de revisão humana (F3/R6) e não resolve a retomada da Fase 4 após o brainstorming (H3) — entrega apenas o contrato, o teste e o pin.

## Status

Aceito.
