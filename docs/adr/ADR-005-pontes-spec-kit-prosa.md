# ADR-005 — Pontes para o Spec Kit montam prompts em prosa

- **Status:** Aceito
- **Data:** 2026-07-13
- **Decisores:** autoria do repo
- **Evidência:** docs/superpowers/specs/2026-07-13-pontes-spec-kit-prosa-design.md

## Contexto

As três pontes do harness para o Spec Kit — `zion-prd-constitution-prompt`, `zion-prd-specify-prompt` e `zion-prd-plan-prompt` — delegavam a montagem final do prompt à skill `zion-rewrite-prompt`, que embrulhava o texto em um esqueleto XML (`<context>`, `<constraints>`, `<instructions>`, `<success_criteria>`), produzindo saídas como `/speckit.constitution "<context>…</context>…"`. Isso conflitava com dois pontos: o requisito do usuário de remover a skill `zion-rewrite-prompt`, fazer cada ponte assumir o próprio escopo sem delegar e não impor formato de saída (o `/speckit.*` já define o formato do artefato); e a pesquisa no repositório `github/spec-kit` (README, `spec-driven.md`, templates de comando e de artefato), que evidenciou que cada comando carrega um template pré-escrito e apenas preenche placeholders — logo o prompt do usuário é conteúdo, não formato — e que todos os exemplos oficiais são prosa em linguagem natural, sem tags XML. Manter o XML e remover a skill seria contraditório.

## Decisão

Cada ponte, nas Fases 2/3, passa a montar ela mesma o prompt do `/speckit.*` correspondente em prosa (linguagem natural), como conteúdo e não formato, sem delegar ao `zion-rewrite-prompt` (skill removida por inteiro), sem tags XML e sem ditar a estrutura do artefato, transformando as guardas de cada etapa em conteúdo em prosa: `constitution` deriva princípios decidíveis/testáveis e rastreáveis dos NFRs e ADRs, sem genéricos; `specify` descreve o o-quê/por-quê com resultado observável e blindagem sem-stack; `plan` fornece o como honrando os ADRs confirmados sem reabri-los; preservam-se o contrato de fases 0/1/4, a fronteira o-quê/como (só `plan` a cruza, presa aos ADRs) e o handoff no qual a ponte entrega o comando pronto e PARA — nenhuma ponte dispara `/speckit.*`. A alternativa de manter internamente o esqueleto XML cortando apenas a delegação foi considerada e descartada, porque tanto a pesquisa quanto as restrições do usuário apontam para prosa e o XML é justamente o que o Spec Kit não espera na entrada.

## Consequências

Os prompts gerados ficam alinhados à convenção oficial do Spec Kit (prosa, conteúdo em vez de formato), copiáveis e executáveis diretamente na skill correspondente, e o harness perde uma dependência inteira (`zion-rewrite-prompt`), simplificando a superfície de skills para 8; em contrapartida, exige reescrever as três âncoras `#anatomia-*` em `assets/quality-rules.md` (removendo a moldura XML e o auto-delegar, descrevendo o conteúdo de cada prompt e a nota de idioma) e propagar a mudança via `sync-assets.sh`/`check-assets.sh` para as skills e guias vivos (`README.md`, `docs/como-usar.md`, `docs/guia-prd-para-spec-kit.md`), enquanto os specs/plans datados permanecem intactos como registro histórico. O trade-off assumido é que a qualidade e a consistência de cada prompt deixam de ser garantidas por um wrapper central e passam a depender de cada ponte seguir fielmente sua âncora em prosa; a fronteira sem-stack no `specify` e o honrar-ADRs no `plan` continuam sendo guardas verificáveis, e a verificação inclui zero ocorrências de `zion-rewrite-prompt`, ausência de XML nos exemplos e ausência de drift de assets.

## Status

Aceito.
