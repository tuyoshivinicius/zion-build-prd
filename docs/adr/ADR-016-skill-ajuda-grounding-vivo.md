# ADR-016 — Skill de ajuda com grounding vivo nas SKILL.md irmãs

- **Status:** Aceito
- **Área:** Jornada
- **Data:** 2026-07-19
- **Decisores:** autoria do repo
- **Evidência:** Decisão dada: o Autor escolheu a alternativa B (ROI 4.00) no estudo `docs/estudos/skill-de-ajuda.md` (ADR-006, evidência por decisão dada); o design que a formaliza é `docs/superpowers/specs/2026-07-19-skill-de-ajuda-design.md`.

## Contexto

A ajuda ao iniciante do harness vivia num prompt one-shot colado à mão: não viaja com a instalação,
depende de o usuário saber que ele existe e afiná-lo exige re-colar a versão nova em todo lugar. As
duas dores são o atrito de colar e a descoberta. Promover a prática a skill esbarra na pergunta de
onde ela tira o que sabe: cópia do canon envelhece contra o harness, e `docs/` não viaja nos dois
canais de distribuição — está no cache do plugin, mas não na instalação via skills.sh.

## Decisão

Uma skill conversacional (`zion-prd-ajuda`), com quatro pontos fechados:

1. **Grounding vivo.** O que a ajuda sabe é lido em runtime das `SKILL.md` irmãs, em
   `../<nome>/SKILL.md` — caminho que resolve nos dois canais (plugin e skills.sh), já que as skills
   ficam lado a lado nos dois. Camada 1: frontmatter (`name` + `description`) de todas as irmãs,
   sempre — é o que produz a **lista fechada de comandos válidos daquela instalação** e a mitigação
   real da alucinação. Camada 2: corpo da `SKILL.md` da(s) irmã(s) que a dúvida toca, sob demanda.
   Duas referências derivadas completam: `process-context.md` (a sequência dos estágios) e
   `speckit-map.md` (fonte nova — o ciclo `/speckit.*` e onde o harness entra e sai).
2. **Sem artefato.** A skill não lê nenhum arquivo do projeto do usuário e não grava nada. É
   justamente por não gravar que ela pode se dar ao luxo de ler as irmãs em runtime: grounding vivo
   e ausência de saída são a mesma decisão vista de dois lados.
3. **Avaliada só na camada de julgamento.** Não há check de saída porque não há saída (a exceção ao
   padrão do épico E5 encolhe a essa verdade trivial). A qualidade da resposta é avaliada por
   fixtures pergunta → resposta esperada, conferidas contra o molde fixo de 4 blocos da Fase 2
   (ADR-008).
4. **Envelhecimento cobrado por máquina.** O verificável não é a resposta, é o envelhecimento das
   citações: a regra **C8** do `check-canon.sh` bloqueia commit quando uma skill de `skills/` não é
   citada pela ajuda, ou quando a ajuda cita um `/zion-*` inexistente. Ajuda não instalada → C8
   silencioso.

A skill é idêntica nos modos interno e distribuído: o dev do harness é público legítimo da mesma
resposta, então não há marcador de repo-harness a ler (diferente do ADR-013).

## Consequências

O harness ganha uma skill e uma fonte no `ASSET_MAP` (`assets/speckit-map.md`), **sem script novo** e
sem entrada nova no `eval.sh` — C8 mora no `check-canon.sh` e é coberto pelo `test-check-canon.sh`
existente. Quem adicionar a 14ª skill é parado no pre-commit até dar-lhe uma linha na ajuda: a
disciplina vira mecanismo. A resposta reflete a versão instalada por construção, o que dissolve a
necessidade de carimbo de versão; a exceção honesta é o `speckit-map.md`, que envelhece contra o
upstream do Spec Kit e por isso é fonte única auditável num lugar só (`RN-05`). Ler o estado do
projeto do usuário (ajuda situada) fica fora de escopo — evolução possível depois que esta provar
uso, e o épico E7 já lhe abre lugar. Nenhum ADR vigente é revertido: ADR-003 e ADR-004 são honrados,
não tocados.

## Status

Aceito.
