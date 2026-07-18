# Design — Dogfooding local das skills via `--plugin-dir`

> Spec de brainstorming. Permite ao **dev do harness** usar as próprias skills do working tree
> (inclusive as ainda não publicadas) no terminal, sem republicar no GitHub nem reinstalar o plugin.

## Problema

O plugin `zion-build-prd` está instalado a partir do marketplace do GitHub. O Claude Code **copia**
plugins de marketplace para o cache (`~/.claude/plugins/cache/.../1.0.0`) — nunca serve a árvore de
trabalho. O cache atual é um snapshot do commit `34c4c61` (14/jul), que congela 8 skills e **não
enxerga** `zion-prd-estudo`, `zion-prd-evolve` e `zion-prd-trace`, criadas depois no working tree.

Consequência: o dev do harness edita `skills/*/SKILL.md` no repo, mas o terminal serve a versão
congelada. Toda skill nova fica invisível até publicar no GitHub e reinstalar — o atrito de
dogfooding que impede usar o próprio harness para desenvolvê-lo. Sintoma reportado: `/zion-prd-estudo`
não existe no terminal.

## Restrições das fontes canônicas

Greenfield para esta mudança quanto a decisões estruturantes — nenhum ADR vigente trata de
desenvolvimento local. Precedente relevante: `scripts/setup-hooks.sh` é um **script de dev** que vive
na tabela de scripts (`architecture.md §3`) **sem RF em `prd.md`** e **sem auto-teste** (não é
verificador com contrato exit 0/1/2). Este design segue esse precedente. A distribuição dual do
plugin é o ADR-002 — não é reaberta aqui; o dogfooding é ortogonal à distribuição.

## Mecanismo (fundamentado na doc do Claude Code)

`claude --plugin-dir <repo-root>` é o modo de dev **oficialmente documentado** ("test your plugins
locally"): carrega o plugin direto da fonte, **sem cache**, e edições em `SKILL.md` entram na sessão
com `/reload-plugins`.

O ponto que o usuário pediu para resolver — o **comando duplicado** com a cópia já instalada do
marketplace — é resolvido pelo próprio `--plugin-dir`, por regra documentada:

> "When a `--plugin-dir` plugin has the same name as an installed marketplace plugin, the local copy
> takes precedence for that session. […] The exception is plugins that managed settings force-enable
> or force-disable: `--plugin-dir` cannot override those."

Ou seja, a cópia local **sombreia** a cópia instalada de mesmo nome, **por sessão**. Não há
duplicata, não há necessidade de `/plugin disable`, `/plugin uninstall` nem de versionar
`.claude/settings.json`. A única exceção (managed settings force-disable) não se aplica ao setup do
autor.

## Alternativas consideradas

Três formas de tornar as skills do working tree vivas no terminal:

- **Marketplace local** (`/plugin marketplace add ./`) — **rejeitada.** A doc é explícita: o Claude
  Code **copia** plugins de marketplace para o cache mesmo quando a fonte é um caminho local. Continua
  congelado; não resolve.
- **Symlink skills-dir** (`ln -s <repo> ~/.claude/skills/zion-build-prd`) — **rejeitada.** Funciona
  (o repo tem `.claude-plugin/plugin.json`, então carrega como plugin `@skills-dir` com edições ao
  vivo), mas polui o estado global do `~/.claude` (vale em todo projeto), muda a invocação para um
  namespace `@skills-dir`, e exige um `dev-unlink.sh` para reverter.
- **`--plugin-dir` via wrapper versionado** — **escolhida.** Modo oficial, isolado por sessão, sem
  estado global, resolve o duplicado por precedência documentada, e o wrapper é um artefato de repo
  real (canonizável na §3). Reversível fechando a sessão.

Uma quarta forma — reinstalar o plugin do working tree a cada edição — foi descartada por impor um
loop lento e ritualístico.

## Componentes

### 1. `scripts/dev-claude.sh` (novo, executável)

Wrapper fino que abre uma sessão do Claude Code servindo o working tree:

- Resolve a **raiz do repo** a partir do próprio caminho do script (funciona chamado de qualquer
  diretório).
- Valida que `.claude-plugin/plugin.json` existe na raiz; erro acionável se não (não é a raiz do
  harness).
- Valida que `claude` está no `PATH`; erro acionável se não (Claude Code não instalado/não no PATH).
- Imprime **uma linha** avisando que a sessão sombreia a cópia instalada do marketplace (transparência
  do "duplicado resolvido").
- `exec claude --plugin-dir "$ROOT" "$@"` — repassa argumentos extras para o `claude`.

Contrato de erro: falha de validação sai com status ≠ 0 e mensagem que diz o que corrigir. Não muta
nada no `~/.claude`.

### 2. README — seção "Desenvolvimento"

Subseção nova de dogfooding, com:

- Rode `./scripts/dev-claude.sh` para abrir uma sessão servindo o working tree ao vivo.
- `--plugin-dir` tem **precedência** sobre a cópia do marketplace **naquela sessão** — comando único,
  sem desinstalar nada.
- Após editar um `SKILL.md`, rode `/reload-plugins` para aplicar; mudanças em `hooks/`, `agents/` e
  afins exigem reabrir a sessão.
- Escopo: vale só para sessões **abertas pelo wrapper** — não retroage à sessão atual (o
  `--plugin-dir` é resolvido no start do `claude`).

## Fronteira e guardas (não faz)

- Não altera estado global do `~/.claude`, não mexe no plugin instalado, não escreve
  `.claude/settings.json` nem `.claude/settings.local.json`. Tudo é per-session e reversível fechando
  a sessão.
- Não republica no GitHub, não reinstala nem sincroniza cache.
- Não vira gate: é conveniência de dev, opcional.

## Canonização (mesmo commit)

- **`docs/architecture.md` §3** — linha nova na tabela de scripts:
  `scripts/dev-claude.sh` — *Abre uma sessão do Claude Code servindo o working tree via `--plugin-dir`
  (dogfooding local das skills).*
- **`docs/prd.md`** — **sem RF novo.** É ferramenta de dev (precedente `setup-hooks.sh`), não feature
  do Autor. A jornada do produto não muda.
- **ADR** — **nenhum.** Não é decisão estruturante de build/distribuição; segue o precedente de
  `setup-hooks.sh` (script de dev sem ADR). A proveniência (as três alternativas e o porquê) fica
  registrada neste design doc.
- **Auto-teste** (`test-*.sh`) — **nenhum.** `dev-claude.sh` não é verificador (sem contrato exit
  0/1/2), então NFR-04 não se aplica.

O `scripts/check-canon.sh` exige apenas a presença da linha na §3 — o design honra isso. O guard não
deve acusar drift.

## Critérios de aceite

- `./scripts/dev-claude.sh` chamado de qualquer diretório abre o `claude` com `--plugin-dir` apontando
  para a raiz do repo.
- Numa sessão aberta pelo wrapper, `/zion-prd-estudo` (e as demais skills novas do working tree) está
  disponível, sem duplicata das skills do marketplace.
- Editar um `SKILL.md` + `/reload-plugins` reflete a mudança na mesma sessão.
- Chamado fora da raiz do harness ou sem `claude` no PATH: erro acionável, status ≠ 0, sem abrir sessão.
- `scripts/check-canon.sh` passa (linha da §3 presente); `scripts/check-assets.sh` e `scripts/eval.sh`
  não regridem.
