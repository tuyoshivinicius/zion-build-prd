---
name: zion-speckit-install
description: Instala a integração do harness Zion Build PRD com o Spec Kit no repositório do PRODUTO — grava o bloco versionado de regras de fonte canônica no CLAUDE.md, semeia docs/architecture.md de esqueleto e oferece um guard de pre-commit opt-in. Idempotente e re-rodável, substitui só o bloco marcado e nunca sobrescreve documento existente. Use para "instalar a integração com o Spec Kit", "declarar o canon no repo do produto" ou para atualizar o bloco de regras após upgrade do harness.
argument-hint: "(sem argumento — instala no repo atual)"
metadata:
  author: zion-build-prd
user-invocable: true
disable-model-invocation: false
---

# zion-speckit-install — Integração instalável com o Spec Kit (ADR-015)

Configura o repositório do PRODUTO para que o ciclo `/speckit.*` reconheça o canon zion sem
depender de prompt colado: as pontes RF-06/07/08 seguem como caminho rico (curam o recorte por
passo); a regra instalada é a **rede de segurança** quando o Autor pula a ponte. Contrato de
fases; os gates **aconselham** — a única coisa bloqueante é o guard da Fase 3, que o Autor
**escolhe** instalar.

**Guardas (não faz):** não dispara `/speckit.*` (ADR-005); não instala automação de reconciliação
no repo do produto — o gatilho é ritual humano (fim de implementação → `/zion-prd-trace`; RF
descoberto → `/zion-prd-evolve`); não toca o que o Autor escreveu fora dos marcadores.

## Fase 0 — Preflight (aconselha; um caso para)

1. **`docs/prd.md` ausente no repo atual** → a jornada zion vem antes desta instalação. Avise
   ("recomendo `/zion-prd-discovery` → `/zion-prd-write` primeiro") e **pare graciosamente** —
   sem PRD não há canon a declarar.
2. **Spec Kit não inicializado** (sem diretório `.specify/`) → avise que a regra vale desde já e
   o Spec Kit chega depois; **instale mesmo assim**.
3. `CLAUDE.md` já com bloco `<!-- zion:speckit:` → é re-execução/upgrade (informativo; siga).

## Fase 1 — Gravar o bloco de regras no CLAUDE.md do produto

O conteúdo canônico do bloco é `references/regras-speckit.md` (marcadores incluídos). Grave-o no
`CLAUDE.md` da raiz do repo:

- **CLAUDE.md não existe** → crie-o contendo só o conteúdo de `references/regras-speckit.md`.
- **Existe sem bloco `zion:speckit`** → acrescente o bloco ao final, separado por uma linha em
  branco.
- **Existe com bloco `<!-- zion:speckit:vN:start --> … <!-- zion:speckit:vN:end -->`** (qualquer
  versão) → substitua da linha do marcador start até a do marcador end, **inclusive**, pelo
  conteúdo novo. **Nada fora dos marcadores é tocado** — preserve byte a byte o que o Autor
  escreveu antes e depois do bloco.

## Fase 2 — Semear docs/architecture.md do produto

- **Não existe** → copie `references/architecture-skeleton.md` para `docs/architecture.md`,
  trocando `<NOME DO PRODUTO>` pelo nome do produto (do título da §1 Visão de `docs/prd.md`).
- **Já existe** → **não sobrescreva** (semeadura retomável, padrão do discovery). Siga direto
  para a reconciliação.
- Em ambos os casos, reconcilie os blocos derivados (índice de ADRs + visão do backlog):

      bash references/trace-arquitetura.sh docs/architecture.md docs/adr docs/backlog.md

  `docs/adr/` ou `docs/backlog.md` ainda ausentes → o script semeia os blocos com
  "(nenhum … ainda)" — normal em repo recém-começado. Documento existente sem os marcadores → o
  script avisa e não toca nada; ofereça ao Autor acrescentar as §3/§4 do esqueleto (ele decide).

## Fase 3 — Guard de pre-commit (opt-in; default NÃO instalar)

Se `.zion/check-arquitetura.sh` **já existe** no repo (re-execução/upgrade), o opt-in já foi
exercido antes: **atualize a cópia incondicionalmente**, sem re-perguntar — um guard de versão
velha passaria a bloquear todo commit após o upgrade do bloco de regras. A pergunta abaixo é só
para instalação nova.

Pergunte ao Autor se quer o guard **bloqueante** de drift de arquitetura no próprio repo — o
enforcement do harness (ADR-010) exportado **por escolha**. Sem resposta afirmativa clara, **não
instale** (RN-01 intacto). Se ele aceitar:

1. Copie `references/check-arquitetura.sh` para `.zion/check-arquitetura.sh` no repo do produto
   (cópia real — autocontenção, ADR-002).
2. Descubra o diretório de hooks ativo: `git config core.hooksPath` (se vazio, `.git/hooks`).
   Sobre o arquivo `pre-commit` desse diretório:
   - **Não existe** → crie com o conteúdo abaixo e dê permissão de execução (`chmod +x`):

         #!/usr/bin/env bash
         # zion-speckit guard (opt-in) — bloqueia commit com drift de arquitetura (ADR-015)
         bash .zion/check-arquitetura.sh . || exit 1

   - **Existe e é shell script** → **nunca sobrescreva**: acrescente ao final as duas linhas
     (o comentário e a chamada `bash .zion/check-arquitetura.sh . || exit 1`).
   - **Existe noutro formato** (gerenciado por outra ferramenta, não-shell) → não toque; instrua
     o Autor a acrescentar `bash .zion/check-arquitetura.sh .` ao mecanismo dele e **pare** esta
     fase.

## Fase 4 — Validar saída (aconselha)

Rode e ecoe o veredito, em tom advisório — o Autor decide:

    bash references/check-arquitetura.sh .

Instalação recém-feita costuma sair com `visao-vazia` — a prosa da §1 é do Autor; aconselhe
escrevê-la. `regras-defasadas` após upgrade do harness → re-rode `/zion-speckit-install`.
**Handoff:** a jornada segue normal — próxima spec via `/zion-prd-specify-prompt`; fim de
implementação → `/zion-prd-trace` (o ritual reconcilia também os blocos derivados do
architecture.md).

## Saída

`CLAUDE.md` com o bloco de regras v1, `docs/architecture.md` semeado/reconciliado, guard opt-in
instalado (se o Autor escolheu) e o veredito do verificador ecoado.
