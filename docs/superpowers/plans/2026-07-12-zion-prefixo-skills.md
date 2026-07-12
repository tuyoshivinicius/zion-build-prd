# Prefixo `zion-` nas 8 skills — Plano de Implementação

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Renomear as 8 skills internas adicionando o prefixo `zion-` e refletir a mudança em todos os guias, assets, scripts e no histórico de design, preservando a semântica de processo.

**Architecture:** Uma substituição segura por `perl` (ancorada nos 8 tokens exatos, com lookbehind/lookahead que impedem duplo-prefixo e corrupção de nomes de arquivo históricos) faz a parte mecânica em todos os arquivos-alvo; um passe manual do skill-creator afia as `description` das 8 SKILL.md; `git mv` renomeia os diretórios; `sync-assets.sh`/`check-assets.sh` garantem os `references/` derivados sem drift.

**Tech Stack:** Bash, git, perl, os scripts do repo (`sync-assets.sh`, `check-assets.sh`, `asset-map.sh`).

---

## Convenção: o comando de substituição segura

Vários passos usam **o mesmo** comando `perl`. Ele é a única forma autorizada de trocar tokens
neste plano (nada de `sed` cego). Definição canônica:

```bash
# SAFE_REPLACE <arquivo...>
# Prefixa com "zion-" cada um dos 8 tokens de skill, SEM:
#  - duplo-prefixar (token precedido por "-", como em "zion-prd-x", não casa)
#  - tocar nomes de arquivo históricos (precedidos pelo "-" da data, ou seguidos de "-design"/"-descoberta", não casam)
#  - tocar "zion-build-prd", "superpowers", "deep-research", "speckit" (não contêm os tokens)
perl -i -pe 's/(?<![-\w])(prd-discovery|prd-spike|prd-write|prd-decompose|prd-constitution-prompt|prd-specify-prompt|adr-new|rewrite-prompt)(?![-\w])/zion-$1/g' "$@"
```

Por que é seguro (invariante que os testes deste plano verificam):
- `(?<![-\w])` bloqueia match quando o token é precedido por `-` (ex.: `zion-prd-spike`, ou o `-` da data em `2026-07-12-prd-spike-...`) ou por letra/dígito.
- `(?![-\w])` bloqueia match quando o token é seguido por `-` ou letra/dígito (ex.: `prd-spike-descoberta`, `prd-constitution-prompt-design`).
- Resultado: só casam usos "isolados" do token (`/prd-write`, `` `prd-write` ``, `prd-write ` em prosa, e a linha `name: prd-write`).

---

## Task 1: Branch de trabalho

**Files:** nenhum arquivo — só git.

- [ ] **Step 1: Criar e entrar no branch**

```bash
cd /home/tuyoshi/projects/personal/zion-build-prd
git switch -c feat/zion-prefix-skills
```

- [ ] **Step 2: Verificar branch e árvore limpa**

Run: `git branch --show-current && git status --porcelain`
Expected: imprime `feat/zion-prefix-skills` e nenhuma linha de status (árvore limpa; o design já foi commitado).

---

## Task 2: Renomear os 8 diretórios de skill

**Files:**
- Rename: `skills/prd-discovery` → `skills/zion-prd-discovery` (e as outras 7)

- [ ] **Step 1: `git mv` das 8 pastas**

```bash
cd /home/tuyoshi/projects/personal/zion-build-prd
for s in prd-discovery prd-spike prd-write prd-decompose prd-constitution-prompt prd-specify-prompt adr-new rewrite-prompt; do
  git mv "skills/$s" "skills/zion-$s"
done
```

- [ ] **Step 2: Verificar que existem 8 pastas `zion-*` e nenhuma antiga**

Run: `ls skills`
Expected: exatamente `zion-adr-new  zion-prd-constitution-prompt  zion-prd-decompose  zion-prd-discovery  zion-prd-specify-prompt  zion-prd-spike  zion-prd-write  zion-rewrite-prompt` (8 itens, todos com prefixo).

- [ ] **Step 3: Commit**

```bash
git add -A
git commit -m "refactor(skills): renomear diretórios das 8 skills com prefixo zion-"
```

---

## Task 3: Substituição mecânica dos tokens nas SKILL.md

Troca `name:`, títulos H1 e todas as referências cruzadas internas nas 8 SKILL.md (agora em
`skills/zion-*/`). A `description` é afiada depois, na Task 4.

**Files:**
- Modify: `skills/zion-*/SKILL.md` (as 8)

- [ ] **Step 1: Rodar o SAFE_REPLACE nas 8 SKILL.md**

```bash
cd /home/tuyoshi/projects/personal/zion-build-prd
perl -i -pe 's/(?<![-\w])(prd-discovery|prd-spike|prd-write|prd-decompose|prd-constitution-prompt|prd-specify-prompt|adr-new|rewrite-prompt)(?![-\w])/zion-$1/g' skills/zion-*/SKILL.md
```

- [ ] **Step 2: Verificar `name:` coerente com a pasta em cada skill**

Run:
```bash
for d in skills/zion-*/; do printf "%s -> " "$d"; grep -m1 '^name:' "$d/SKILL.md"; done
```
Expected: cada linha casa a pasta, ex.: `skills/zion-prd-discovery/ -> name: zion-prd-discovery`, ..., `skills/zion-rewrite-prompt/ -> name: zion-rewrite-prompt`.

- [ ] **Step 3: Verificar que sobrou zero token sem prefixo nos corpos**

Run:
```bash
grep -REn '(?<![-\w])(prd-discovery|prd-spike|prd-write|prd-decompose|prd-constitution-prompt|prd-specify-prompt|adr-new|rewrite-prompt)(?![-\w])' -P skills/zion-*/SKILL.md || echo "OK: nenhum token sem prefixo"
```
Expected: `OK: nenhum token sem prefixo`.

- [ ] **Step 4: Verificar que tokens externos ficaram intactos**

Run: `grep -REn 'superpowers:brainstorming|deep-research|speckit' skills/zion-*/SKILL.md | wc -l`
Expected: número > 0 (as menções externas continuam presentes; nenhuma virou `zion-`).

- [ ] **Step 5: Commit**

```bash
git add skills/zion-*/SKILL.md
git commit -m "refactor(skills): prefixar tokens de skill nos corpos das SKILL.md"
```

---

## Task 4: Passe skill-creator nas `description` das 8 skills

Afia cada `description` (triggering "pushy" + "quando usar"), mantendo a semântica. As 7 abaixo
recebem descrição nova; `zion-rewrite-prompt` já tem descrição de qualidade skill-creator e só teve
o token `/rewrite-prompt` prefixado na Task 3 — não muda aqui.

**Files:**
- Modify: `skills/zion-prd-discovery/SKILL.md`, `skills/zion-prd-spike/SKILL.md`, `skills/zion-prd-write/SKILL.md`, `skills/zion-prd-decompose/SKILL.md`, `skills/zion-prd-constitution-prompt/SKILL.md`, `skills/zion-prd-specify-prompt/SKILL.md`, `skills/zion-adr-new/SKILL.md`

- [ ] **Step 1: `zion-prd-discovery` — substituir a linha `description:`**

Nova linha (substitui a atual por completo):
```yaml
description: Estágio 1 do harness Zion Build PRD — conduz a descoberta enxuta de produto (visão em 1 frase, persona nomeada, quadro faz/não-faz) e grava docs/discovery.md. Use ao iniciar um produto/feature a partir de uma ideia bruta, antes de qualquer PRD ou stack, sempre que o usuário quiser "começar a descoberta", "destrinchar a ideia" ou "definir visão e escopo".
```

- [ ] **Step 2: `zion-prd-spike` — substituir a linha `description:`**

```yaml
description: Estágio 2 do harness Zion Build PRD — pesquisa os trade-offs das 2–3 decisões estruturantes e registra ADRs em docs/adr/ antes de fechar a PRD. Use após a descoberta, sempre que houver decisões que mudam a PRD inteira a provar com spike, ou quando o usuário mencionar "decisões estruturantes", "trade-offs" ou "ADRs".
```

- [ ] **Step 3: `zion-prd-write` — substituir a linha `description:`**

```yaml
description: Estágio 3 do harness Zion Build PRD — copia o esqueleto da PRD e conduz o preenchimento seção a seção (RF-xx por épico, NFRs com número, restrições das ADRs), guardando a fronteira o-quê/como. Use para "escrever a PRD", "preencher a PRD" ou revisar uma PRD existente, depois da descoberta e dos spikes.
```

- [ ] **Step 4: `zion-prd-decompose` — substituir a linha `description:`**

```yaml
description: Estágio 4 do harness Zion Build PRD — transforma os RF-xx da PRD em épicos, story map e fatias verticais validadas por INVEST, e injeta a tabela de rastreabilidade. Use para "decompor a PRD", "fatiar em histórias/épicos" ou "montar o backlog vertical" depois que a PRD estiver escrita.
```

- [ ] **Step 5: `zion-prd-constitution-prompt` — substituir a linha `description:`**

```yaml
description: Ponte do harness Zion Build PRD para o Spec Kit (bootstrap, uma vez por projeto) — monta o prompt do /speckit.constitution derivando princípios decidíveis e rastreáveis dos NFRs/restrições da PRD, entrega pronto e para. Use quando for iniciar a constitution do Spec Kit a partir de uma PRD; não dispara o /speckit.* por você.
```

- [ ] **Step 6: `zion-prd-specify-prompt` — substituir a linha `description:`**

```yaml
description: Ponte do harness Zion Build PRD para o Spec Kit — monta o prompt do /speckit.specify de UMA fatia vertical, blindando a fronteira sem-stack, entrega pronto e para. Use para levar uma fatia do backlog ao Spec Kit; não dispara o /speckit.* por você.
```

- [ ] **Step 7: `zion-adr-new` — substituir a linha `description:`**

```yaml
description: Cria um Architecture Decision Record em docs/adr/ (Contexto/Decisão/Consequências/Status) a partir de um título. Use no Estágio 2 do harness Zion Build PRD para registrar cada decisão estruturante sustentada por spike, ou sempre que o usuário pedir para "criar/registrar um ADR" ou "documentar uma decisão de arquitetura".
```

- [ ] **Step 8: Verificar que as 8 descrições estão presentes e sem token cru**

Run:
```bash
for d in skills/zion-*/; do printf "%s: " "$d"; grep -c '^description:' "$d/SKILL.md"; done
grep -REn -P '(?<![-\w])(prd-discovery|prd-spike|prd-write|prd-decompose|prd-constitution-prompt|prd-specify-prompt|adr-new|rewrite-prompt)(?![-\w])' skills/zion-*/SKILL.md || echo "OK: nenhum token sem prefixo"
```
Expected: cada skill imprime `1`; e `OK: nenhum token sem prefixo`.

- [ ] **Step 9: Commit**

```bash
git add skills/zion-*/SKILL.md
git commit -m "docs(skills): passe skill-creator nas descriptions das 7 skills do harness"
```

---

## Task 5: Assets canônicos

Ajusta os únicos assets que citam skills. Os `references/` derivados serão regenerados na Task 6.

**Files:**
- Modify: `assets/process-context.md` (7 refs), `assets/templates/prd-skeleton.md` (1 ref)

- [ ] **Step 1: Rodar o SAFE_REPLACE nos dois assets**

```bash
cd /home/tuyoshi/projects/personal/zion-build-prd
perl -i -pe 's/(?<![-\w])(prd-discovery|prd-spike|prd-write|prd-decompose|prd-constitution-prompt|prd-specify-prompt|adr-new|rewrite-prompt)(?![-\w])/zion-$1/g' assets/process-context.md assets/templates/prd-skeleton.md
```

- [ ] **Step 2: Verificar refs prefixadas e nada cru**

Run:
```bash
grep -nE 'zion-prd-|zion-adr-new' assets/process-context.md assets/templates/prd-skeleton.md
grep -REn -P '(?<![-\w])(prd-discovery|prd-spike|prd-write|prd-decompose|prd-constitution-prompt|prd-specify-prompt|adr-new|rewrite-prompt)(?![-\w])' assets/ || echo "OK: assets sem token cru"
```
Expected: as invocações aparecem como `zion-prd-…`/`zion-adr-new`; e `OK: assets sem token cru`.

- [ ] **Step 3: Commit**

```bash
git add assets/process-context.md assets/templates/prd-skeleton.md
git commit -m "refactor(assets): prefixar zion- nas referências de skill"
```

---

## Task 6: `asset-map.sh` + regenerar `references/` + guard de drift

**Files:**
- Modify: `scripts/asset-map.sh`
- Regenera (via script): `skills/zion-*/references/*.md`

- [ ] **Step 1: Rodar o SAFE_REPLACE no manifesto**

```bash
cd /home/tuyoshi/projects/personal/zion-build-prd
perl -i -pe 's/(?<![-\w])(prd-discovery|prd-spike|prd-write|prd-decompose|prd-constitution-prompt|prd-specify-prompt|adr-new|rewrite-prompt)(?![-\w])/zion-$1/g' scripts/asset-map.sh
```

- [ ] **Step 2: Conferir o manifesto**

Run: `grep -n 'zion-' scripts/asset-map.sh`
Expected: as 4 entradas do `ASSET_MAP` agora listam nomes `zion-*` (ex.: `zion-prd-discovery zion-prd-spike zion-prd-write zion-prd-decompose zion-prd-constitution-prompt zion-prd-specify-prompt`; `... zion-prd-write`; `... zion-prd-decompose`; `... zion-adr-new`). Nenhum caminho de asset foi alterado (os basenames `prd-skeleton.md`, `quality-rules.md` etc. não são tokens).

- [ ] **Step 3: Regenerar os references derivados**

Run: `./scripts/sync-assets.sh`
Expected: imprime `sync-assets: ok` (copia os assets para `skills/zion-*/references/`).

- [ ] **Step 4: Guard de drift (o "teste")**

Run: `./scripts/check-assets.sh`
Expected: imprime `check-assets: sem drift` e sai 0.

- [ ] **Step 5: Confirmar que não sobrou pasta de references órfã**

Run: `find skills -type d -name references | sort`
Expected: exatamente 7 pastas — as sob `skills/zion-*/references` que o mapa alimenta (`zion-adr-new`, `zion-prd-constitution-prompt`, `zion-prd-decompose`, `zion-prd-discovery`, `zion-prd-specify-prompt`, `zion-prd-spike`, `zion-prd-write`); nenhuma pasta com nome antigo (sem prefixo). `zion-rewrite-prompt` **não** tem `references/` (não consome asset) — correto que não apareça.

- [ ] **Step 6: Commit**

```bash
git add scripts/asset-map.sh skills/zion-*/references
git commit -m "build(assets): asset-map aponta para skills zion-* e regenera references"
```

---

## Task 7: Guias vivos (README + docs)

**Files:**
- Modify: `README.md`, `docs/guia-prd-para-spec-kit.md`, `docs/como-usar.md`

- [ ] **Step 1: Rodar o SAFE_REPLACE nos guias**

```bash
cd /home/tuyoshi/projects/personal/zion-build-prd
perl -i -pe 's/(?<![-\w])(prd-discovery|prd-spike|prd-write|prd-decompose|prd-constitution-prompt|prd-specify-prompt|adr-new|rewrite-prompt)(?![-\w])/zion-$1/g' README.md docs/guia-prd-para-spec-kit.md docs/como-usar.md
```

- [ ] **Step 2: Verificar README (tabela de skills e dependências)**

Run: `grep -nE 'zion-(prd-|adr-new|rewrite-prompt)' README.md`
Expected: a tabela de skills lista `/zion-prd-discovery`, `/zion-prd-spike`, `/zion-prd-write`, `/zion-prd-decompose`, `/zion-prd-constitution-prompt`, `/zion-prd-specify-prompt`, `/zion-adr-new`; a tabela de dependências cita `zion-rewrite-prompt`, `zion-adr-new`. O nome do plugin `zion-build-prd` e o comando `/plugin install zion-build-prd@zion-build-prd` permanecem inalterados.

- [ ] **Step 3: Verificar que nada cru sobrou nos guias e que externos ficaram intactos**

Run:
```bash
grep -REn -P '(?<![-\w])(prd-discovery|prd-spike|prd-write|prd-decompose|prd-constitution-prompt|prd-specify-prompt|adr-new|rewrite-prompt)(?![-\w])' README.md docs/guia-prd-para-spec-kit.md docs/como-usar.md || echo "OK: guias sem token cru"
grep -nE 'zion-build-prd' README.md | head
```
Expected: `OK: guias sem token cru`; e `zion-build-prd` continua aparecendo intacto (não virou `zion-zion-...`).

- [ ] **Step 4: Commit**

```bash
git add README.md docs/guia-prd-para-spec-kit.md docs/como-usar.md
git commit -m "docs: refletir prefixo zion- nas skills no README e guias"
```

---

## Task 8: Histórico de design (specs + plans)

Atualiza o **conteúdo** dos registros históricos; **nomes de arquivo mantidos** (o SAFE_REPLACE não
toca nos nomes de arquivo referenciados na prosa — eles são precedidos pelo `-` da data ou seguidos de
`-design`/sufixos). Exclui os dois documentos novos deste trabalho (design + este plano), que contêm
propositalmente os nomes antigos em tabelas "Antes/Depois".

**Files:**
- Modify: `docs/superpowers/specs/*.md` e `docs/superpowers/plans/*.md`, **exceto**
  `docs/superpowers/specs/2026-07-12-zion-prefixo-skills-design.md` e
  `docs/superpowers/plans/2026-07-12-zion-prefixo-skills.md`

- [ ] **Step 1: Montar a lista de alvos excluindo os dois novos**

```bash
cd /home/tuyoshi/projects/personal/zion-build-prd
mapfile -t HIST < <(ls docs/superpowers/specs/*.md docs/superpowers/plans/*.md \
  | grep -v 'zion-prefixo-skills')
printf '%s\n' "${HIST[@]}"
```
Expected: lista os 7 specs históricos + 7 plans históricos (14 arquivos), sem os dois `zion-prefixo-skills*`.

- [ ] **Step 2: Rodar o SAFE_REPLACE só nesses alvos**

```bash
perl -i -pe 's/(?<![-\w])(prd-discovery|prd-spike|prd-write|prd-decompose|prd-constitution-prompt|prd-specify-prompt|adr-new|rewrite-prompt)(?![-\w])/zion-$1/g' "${HIST[@]}"
```

- [ ] **Step 3: Verificar que os nomes de arquivo em prosa NÃO foram corrompidos**

Run: `grep -rnE '20[0-9]{2}-[0-9]{2}-[0-9]{2}-zion-(prd|adr)' docs/superpowers || echo "OK: nenhum nome de arquivo histórico prefixado"`
Expected: `OK: nenhum nome de arquivo histórico prefixado` (nenhuma referência a filename ganhou `zion-`).

- [ ] **Step 4: Verificar que sobrou zero token cru no histórico-alvo**

Run: `grep -REn -P '(?<![-\w])(prd-discovery|prd-spike|prd-write|prd-decompose|prd-constitution-prompt|prd-specify-prompt|adr-new|rewrite-prompt)(?![-\w])' "${HIST[@]}" || echo "OK: histórico sem token cru"`
Expected: `OK: histórico sem token cru`.

- [ ] **Step 5: Verificar que o design/plano novos ficaram intactos (Antes/Depois preservado)**

Run: `grep -c '| \`prd-discovery\`' docs/superpowers/specs/2026-07-12-zion-prefixo-skills-design.md`
Expected: `1` (a coluna "Antes" ainda tem o nome antigo — não foi tocada).

- [ ] **Step 6: Commit**

```bash
git add docs/superpowers/specs docs/superpowers/plans
git commit -m "docs(history): atualizar tokens de skill nos specs/plans, mantendo nomes de arquivo"
```

---

## Task 9: Verificação final e limpeza

**Files:** nenhum — só verificação.

- [ ] **Step 1: Guard de drift dos assets (de novo, após tudo)**

Run: `./scripts/check-assets.sh`
Expected: `check-assets: sem drift`.

- [ ] **Step 2: Varredura global — zero token cru no repo inteiro (fora os dois docs novos)**

Run:
```bash
cd /home/tuyoshi/projects/personal/zion-build-prd
grep -REn -P '(?<![-\w])(prd-discovery|prd-spike|prd-write|prd-decompose|prd-constitution-prompt|prd-specify-prompt|adr-new|rewrite-prompt)(?![-\w])' \
  --include='*.md' --include='*.sh' --include='*.json' . \
  | grep -v '/\.git/' \
  | grep -v 'zion-prefixo-skills' \
  || echo "OK: repo sem token de skill sem prefixo"
```
Expected: `OK: repo sem token de skill sem prefixo`.

- [ ] **Step 3: Confirmar que a marca e os externos permaneceram intactos**

Run:
```bash
grep -rn 'zion-zion-' . --include='*.md' --include='*.sh' --include='*.json' | grep -v '/\.git/' || echo "OK: nenhum duplo-prefixo"
grep -rn 'zion-build-prd' .claude-plugin README.md | head
grep -rEn 'superpowers:brainstorming|deep-research|speckit' skills/zion-*/SKILL.md | wc -l
```
Expected: `OK: nenhum duplo-prefixo`; `zion-build-prd` presente e íntegro; contagem de externos > 0.

- [ ] **Step 4: Sanidade das 8 skills (pasta == name)**

Run:
```bash
for d in skills/zion-*/; do n=$(grep -m1 '^name:' "$d/SKILL.md" | awk '{print $2}'); b=$(basename "$d"); [ "$n" = "$b" ] && echo "OK $b" || echo "MISMATCH $b != $n"; done
```
Expected: 8 linhas `OK zion-...`, nenhuma `MISMATCH`.

- [ ] **Step 5: `.claude-plugin` inalterado**

Run: `git diff --name-only main -- .claude-plugin`
Expected: vazio (o nome do plugin/marketplace `zion-build-prd` não muda).

- [ ] **Step 6: Commit final (se algo pendente) e resumo**

```bash
git status --porcelain
# se houver pendências de limpeza (ex.: remoção de references órfã da Task 6):
git add -A && git commit -m "chore: limpeza final do rebranding zion-" || echo "nada a commitar"
git log --oneline main..HEAD
```
Expected: o log mostra a sequência de commits do rebranding; árvore limpa.

---

## Notas de execução

- **Idempotência:** o SAFE_REPLACE é seguro de re-rodar — o lookbehind impede duplo-prefixo. Se um passe for interrompido, rodar de novo no mesmo alvo não corrompe.
- **Hook de pre-commit:** se `core.hooksPath` estiver ativo (`scripts/setup-hooks.sh` já rodado), cada commit dispara `sync-assets.sh` + `git add skills/*/references/` automaticamente. Isso é compatível com este plano; após a Task 6 os references já batem, então o hook vira no-op.
- **Não editar `skills/*/references/*.md` à mão** em nenhum passo — são derivados; só a Task 6 os regenera via `sync-assets.sh`.
