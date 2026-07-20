# ADR-002 — Distribuição dual com autocontenção por cópia

- **Status:** Aceito
- **Área:** Distribuição
- **Data:** 2026-07-12
- **Decisores:** autoria do repo
- **Evidência:** docs/superpowers/specs/2026-07-12-distribuicao-dual-plugin-deps-design.md

## Contexto

O repositório `zion-build-prd` já vinha empacotado no padrão comunitário `npx skills` (skills.sh) — origem detalhada no doc irmão `2026-07-12-zion-build-prd-npx-skills-design.md`, que estabeleceu a árvore única `skills/<name>/SKILL.md`, a fonte canônica em `assets/` sincronizada para o `references/` de cada skill (via `sync-assets.sh`/`check-assets.sh`) e a autocontenção por caminho relativo que permite `npx skills add owner/repo` sem setup. Sobre essa base surgiu a necessidade de entregar o mesmo repositório em dois formatos simultâneos e sem duplicar arquivos — (A) `npx skills`/skills.sh e (B) plugin + marketplace do Claude Code — com o objetivo central de garantir que as dependências das skills sejam resolvidas automaticamente na instalação via plugin (B), sabendo que o skills.sh (A) não possui mecanismo algum de dependência. A auditoria das skills revelou que, após tratar os casos internos, a única dependência externa que exige resolução é `superpowers:brainstorming` (publicada em `obra/superpowers-marketplace`), pois `zion-rewrite-prompt` é skill pessoal não publicada e `deep-research` é built-in do harness sem fonte em disco.

## Decisão

Adotar distribuição dual sobre uma única árvore `skills/` ("uma árvore, dois porteiros"): o `npx skills` lê `skills/*/SKILL.md` direto e o plugin lê os manifestos em `.claude-plugin/`, com zero duplicação por formato. A autocontenção se faz por cópia real — `zion-rewrite-prompt` é vendorizada como 8ª skill first-party (cópia verbatim, `metadata.author: zion-build-prd`, sob a licença MIT do repo, resolvida por nome sem mudança de caminho nas pontes que a invocam); `deep-research` não é vendorizada (built-in sem fonte) e passa a degradar graciosamente em `zion-prd-spike`; e `superpowers` é declarada como dependência cross-marketplace no `plugin.json` (sem pin de versão) mais `allowCrossMarketplaceDependenciesOn` no `marketplace.json` para (B), somada a garantia defensiva dupla em (A) via preflight advisory nas três skills que a usam (discovery, decompose, write) e seção Dependências no README. Ficaram descartadas: vendorizar `deep-research` (fabricar sem fonte), pinar a versão do `superpowers` (YAGNI), auto-registrar o marketplace no install (impossível pela doc — só o consumidor adiciona marketplaces), redistribuir o Spec Kit e renomear slash-commands.

## Consequências

A garantia entregue é honesta e assimétrica entre formatos. No plugin (B), a dependência `superpowers` é imposta pelo próprio Claude Code: o install não falha em silêncio, mas bloqueia com erro acionável `dependency-unsatisfied` (mostra o comando exato) quando o marketplace-raiz não está registrado localmente por nome, e resolve automaticamente por auto-instalação transitiva assim que `/plugin marketplace add obra/superpowers-marketplace` foi feito — ou seja, não é 100% zero-setup (exige o pré-requisito de uma linha), mas é enforced em vez de quebrar em runtime; `zion-rewrite-prompt` e `zion-adr-new` viajam no próprio plugin e `deep-research` é built-in. No `npx skills` (A) não há resolução automática alguma, então a lacuna é coberta apenas defensivamente por preflight que avisa e para graciosamente mais o README, aceitando que o consumidor instale o `superpowers` manualmente. A vendorização por cópia mantém os scripts de sync inalterados (a 8ª skill não usa assets canônicos), ao custo de assumir a responsabilidade de manter a cópia alinhada à origem, e o Spec Kit permanece fora de escopo — as pontes só emitem prompts.

## Status

Aceito.
