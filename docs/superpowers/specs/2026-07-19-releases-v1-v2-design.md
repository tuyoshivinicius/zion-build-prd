# Design — Releases v1.0.0 e v2.0.0 do zion-build-prd

**Data:** 2026-07-19
**Status:** aprovado em brainstorming

## Problema

O repositório do harness não tem nenhuma tag nem release. Duas versões precisam ficar
distinguíveis no GitHub:

- **v1.0.0** — o estado do harness usado para implementar o `zion-mermaid-editor-app`.
- **v2.0.0** — o estado atual da branch `main`.

## Evidência da âncora da v1.0.0

O ciclo do mermaid app correu de 2026-07-13 18:03 (`832b29a`, Initial commit) a 2026-07-17
08:07 (`e82cbcd`, último commit de feature). O histórico do harness tem um vazio exatamente
nessa janela: o último commit de 07-13 é **`34c4c61`** às 21:47 ("merge: pontes Spec Kit
autocontidas em prosa; remoção do zion-rewrite-prompt") e o próximo só chega em 07-17 às
13:14 (`76dedfd`), *depois* do fim da implementação do app. Logo, `34c4c61` é o estado do
harness que construiu o app. Decisão confirmada pelo Autor.

Nota: o PRD/discovery do app foram commitados às 20:50 de 07-13, uma hora antes de
`34c4c61`; a constitution (22:01) e todo o restante usaram o estado de `34c4c61`. Não há
commit intermediário do harness que o app tenha usado.

## Decisões

1. **Âncora v1.0.0 = `34c4c61`.** Tag anotada direto nele; o `plugin.json` desse commit já
   declara `"version": "1.0.0"`, então nenhum commit novo é necessário.
2. **v2.0.0 nasce de um commit de bump.** O `plugin.json` do HEAD ainda declara `1.0.0`;
   um commit `chore(plugin): bump versão 2.0.0` altera só o campo `version` de
   `.claude-plugin/plugin.json` para `"2.0.0"`, e a tag anotada `v2.0.0` aponta para ele.
   O `marketplace.json` não tem campo de versão e fica intocado.
3. **Sem branches de release.** O harness evolui linearmente; não há plano de backport
   para a linha 1.x (YAGNI). Só tags anotadas + GitHub Releases.
4. **Notas temáticas em pt-BR**, redigidas na execução a partir do log real de cada
   intervalo (ver seção Notas).

## Mecânica

1. Tag anotada `v1.0.0` em `34c4c61`.
2. Commit de bump em `main` (pre-commit roda normalmente; se `check-canon.sh` acusar
   drift, parar e investigar — nunca `--no-verify`). O bump não dispara o dever de
   canonização: não é skill, script nem asset novo.
3. Tag anotada `v2.0.0` no commit de bump.
4. `git push origin main --follow-tags` — publica todos os commits locais pendentes
   (12 no momento do design, mais esta spec, o plano e o bump) e as duas tags.
5. Criar as duas GitHub Releases via API REST
   (`POST /repos/tuyoshivinicius/zion-build-prd/releases`, uma por tag), com token lido do
   `hosts.yml` do gh — o `gh` desta máquina é um abridor de browser, não o CLI real.
6. Verificar via `GET` que as duas releases existem e reportar as URLs.

## Notas de release

- **v1.0.0 — a era do mermaid app.** Descreve o harness como era: pipeline
  discovery → spike/ADR → PRD → decompose → pontes Spec Kit autocontidas em prosa
  (constitution/specify/plan), remoção do `zion-rewrite-prompt`.
- **v2.0.0 — o que mudou de `34c4c61` a HEAD+bump.** Temas: verificação mecânica
  (check-prd, check-adr, suíte de avaliação R1–R9), rastreabilidade (`/zion-prd-trace`),
  dia 2 (`/zion-prd-evolve`), contrato explícito com o superpowers, governança canônica
  (PRD/architecture do próprio harness + ADR-001..015 + check-canon), Estágio 0
  (`/zion-prd-estudo`), carregador de experiência (NFR), integração instalável com o
  Spec Kit (`/zion-speckit-install`) e a renomeação fatia→spec. O major justifica-se por
  mudanças de contrato: skills novas e removidas e a unidade de trabalho renomeada.

## Erros e verificação

- Push rejeitado (remote divergiu), token sem escopo `repo`, ou pre-commit bloqueando o
  bump ⇒ parar e reportar; nada é forçado.
- Sucesso = duas releases visíveis na aba Releases do GitHub, apontando para `v1.0.0` e
  `v2.0.0`, confirmadas por `GET` na API.

## Fora de escopo

- Branches de manutenção (`release/1.x`).
- Qualquer mudança em skills, scripts, assets, PRD ou architecture do harness.
- Releases no repositório do produto (`zion-mermaid-editor-app`).
