# `check-prd.sh` — verificação mecânica das regras decidíveis (R1) — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Substituir a prosa interpretada por LLM nas Fases 4 de `zion-prd-write` e `zion-prd-specify-prompt` por um verificador em shell (`scripts/check-prd.sh`) que executa mecanicamente as 3 regras decidíveis da R1 (zero-stack, NFR-com-número, RF-agrupado-por-épico) contra artefatos reais.

**Architecture:** O script é canônico em `scripts/check-prd.sh` (ao lado de `check-assets.sh`) e viaja para dentro de cada skill via o padrão de sync já existente (`asset-map.sh` → `sync-assets.sh` → `references/`). Ele **verifica** (exit `0`/`1`, achados ancorados em linha); o humano **decide** — a Fase 4 ecoa o veredito mas não bloqueia nem reverte. Detecção híbrida: denylist curada (bloco ` ```denylist ` do `quality-rules.md`, fonte única já sincronizada) + sinais estruturais de alta precisão. Funções de check independentes com dispatch por modo, para R4 e outras regras plugarem depois sem retrabalho.

**Tech Stack:** Bash (POSIX-portável: `grep -niwoF/-nE`, `awk` sem extensões gawk), `git`. Fixtures Markdown. Sem código de aplicação. A infraestrutura de sync/CI já existe — só ganha uma linha no mapa e um passo no workflow.

**Spec:** `docs/superpowers/specs/2026-07-17-check-prd-verificacao-mecanica-design.md`

---

## Mapa de arquivos

| Arquivo | Responsabilidade | Ação |
|---|---|---|
| `scripts/check-prd.sh` | O verificador: funções de check independentes + dispatch por modo | **Criar** |
| `scripts/test-check-prd.sh` | Auto-teste contra fixtures (semente da R7) | **Criar** |
| `scripts/fixtures/prd-clean.md` | PRD que passa nos 3 checks (exit 0) | **Criar** |
| `scripts/fixtures/prd-dirty.md` | PRD com stack + NFR sem número + RF fora de épico (exit 1) | **Criar** |
| `scripts/fixtures/specify-dirty.txt` | Prompt de specify com vazamento de stack (exit 1, via stdin) | **Criar** |
| `assets/quality-rules.md` | Fonte única: nova seção `## Denylist de stack {#denylist}` + nota nos critérios | Editar → `sync` |
| `scripts/asset-map.sh` | Mapa asset→skills | Nova entrada `scripts/check-prd.sh → zion-prd-write zion-prd-specify-prompt` |
| `skills/zion-prd-write/SKILL.md` | Estágio 3 | Fase 4 roda `check-prd.sh prd docs/PRD.md` |
| `skills/zion-prd-specify-prompt/SKILL.md` | Ponte 5b | Fase 4 roda `check-prd.sh specify -` sobre o prompt montado |
| `.github/workflows/check-assets.yml` | CI | Novo passo: roda `test-check-prd.sh` |
| `README.md`, `docs/como-usar.md` | Guias vivos | Menção à verificação mecânica |
| `skills/*/references/` | Cópias derivadas | Regeneradas por `sync-assets.sh` (nunca editar à mão) |

**Não tocar à mão:** qualquer `skills/*/references/*` — são artefatos derivados; o sync os gera.

---

## Task 0: Verificar que `npx skills` empacota `references/*.sh` (gate da spec §4.3)

O plano assume o caminho `references/check-prd.sh`. A spec exige confirmar que o empacotamento do `npx skills` (hoje exercitado só com `.md`) inclui `.sh`. **Se falhar, PARE e reporte** — o Plano B (embutir o script via heredoc no `SKILL.md`) muda o desenho e está fora destas tasks.

**Files:**
- (nenhum — verificação)

- [ ] **Step 1: Inspecionar o comportamento de empacotamento do skills.sh**

Rode, num diretório temporário fora do repo:

```bash
cd "$(mktemp -d)"
npx --yes skills add tuyoshivinicius/zion-build-prd 2>&1 | tee /tmp/skills-add.log || true
find . -path '*zion-prd-write/references/*' -name '*.sh' -o -path '*references*' -name '*.md' | head
```

Expected: a instalação copia o diretório `references/` de cada skill. Se já houver `.md` em `references/`, o mecanismo copia o diretório inteiro (não filtra por extensão) → `.sh` viajará junto após a Task 6.

- [ ] **Step 2: Registrar o veredito**

- Se `references/` é copiado como diretório (sem filtro de extensão) → **prossiga** com o plano como escrito.
- Se `npx skills` filtra e só leva `.md` → **PARE**. Reporte ao usuário: "empacotamento não leva `.sh`; ativar Plano B (heredoc no SKILL.md), que está fora do escopo destas tasks e precisa de novo design."

> Nota: a verificação definitiva exige o repo publicado no GitHub. Se a rede/publicação não estiver disponível nesta sessão, inspecione a CLI (`npx --yes skills add --help`) e o comportamento observado com os `.md` já existentes, e registre a suposição explicitamente no relatório da task.

---

## Task 1: Adicionar a seção `#denylist` ao `quality-rules.md` (fonte única)

**Files:**
- Modify: `assets/quality-rules.md`

- [ ] **Step 1: Anexar a seção `## Denylist de stack {#denylist}` ao fim do arquivo**

Edit em `assets/quality-rules.md`. Acrescente ao **final** do arquivo (após a âncora `#anatomia-plan`):

````markdown

## Denylist de stack {#denylist}

Termos de linguagem/framework/biblioteca que **não** podem aparecer na PRD nem no prompt do
`/speckit.specify` (vivem no `plan.md` da feature). O `check-prd.sh` extrai o bloco cercado abaixo e
casa cada termo **palavra inteira, case-insensitive** contra o alvo. Afinar a lista = editar aqui (o
sync propaga para os `references/`). Um termo por linha, minúsculo.

```denylist
react
react flow
vue
angular
svelte
zustand
redux
localstorage
dagre
elk
next.js
node.js
codemirror
tailwind
postgres
mysql
mongodb
redis
sqlite
prisma
graphql
django
flask
fastapi
express
webpack
vite
d3
three.js
typescript
```
````

- [ ] **Step 2: Anotar nos critérios de conclusão que `prd`/`specify` são verificados por máquina**

Edit em `assets/quality-rules.md`, dentro de `{#criterios-de-conclusao}`. Localize a linha:

```
- **prd** (`docs/PRD.md`): escopo in/out explícito ∧ `RF-xx` agrupados por épico (1 frase cada) ∧
  NFRs com número ∧ **zero** stack / critério de aceite / tela.
```

Substitua por:

```
- **prd** (`docs/PRD.md`): escopo in/out explícito ∧ `RF-xx` agrupados por épico (1 frase cada) ∧
  NFRs com número ∧ **zero** stack / critério de aceite / tela. As três regras decidíveis
  (zero-stack, NFR-com-número, RF-por-épico) são verificadas por `check-prd.sh` — a Fase 4 roda o
  script e ecoa o veredito.
```

Localize a linha:

```
- **specify-prompt**: o prompt gerado declara resultado observável ∧ não cita stack ∧ RF-xx/ADR
  entram como contexto (referência), não como requisito.
```

Substitua por:

```
- **specify-prompt**: o prompt gerado declara resultado observável ∧ não cita stack ∧ RF-xx/ADR
  entram como contexto (referência), não como requisito. O zero-stack é verificado por
  `check-prd.sh specify -` sobre o prompt montado.
```

- [ ] **Step 3: Sincronizar os `references/` e conferir**

Run:
```bash
./scripts/sync-assets.sh && ./scripts/check-assets.sh
```
Expected: `sync-assets: ok` seguido de `check-assets: sem drift`.

- [ ] **Step 4: Commit**

```bash
git add assets/quality-rules.md skills/*/references/quality-rules.md
git commit -m "feat(quality-rules): denylist de stack como fonte única do check-prd"
```

---

## Task 2: Esqueleto do `check-prd.sh` + plumbing de stdin (passa na fixture limpa)

Cria o script com dispatch, parsing de argumentos, localização do `quality-rules.md`, normalização de alvo (arquivo ou `-`/stdin) e o contrato de saída — **com os checks ainda vazios**. Uma PRD limpa deve sair `0` / `check-prd: limpo`.

**Files:**
- Create: `scripts/check-prd.sh`
- Create: `scripts/fixtures/prd-clean.md`
- Create: `scripts/test-check-prd.sh`

- [ ] **Step 1: Escrever a fixture limpa**

Create `scripts/fixtures/prd-clean.md`:

```markdown
# PRD — Painel de Tarefas

## 1. Visão
Para a gerente de projetos, que perde tempo consolidando status, o Painel reúne o andamento das tarefas numa tela só.

## 2. Objetivos & métricas
- Reduzir o tempo de consolidação de status de 60 para 10 minutos por semana.

## 3. Personas
1. Gerente de projetos — acompanha o time.

## 4. Escopo (in / out)
- **Faz (in):** ver e atualizar o status das tarefas.
- **Não faz (out):** controle de horas e faturamento.

## 5. Regras de negócio (RN-xx)
- RN-01 Uma tarefa pertence a exatamente um responsável.

## 6. Requisitos funcionais por épico (RF-xx)
- **Épico E1 — Acompanhamento:** RF-01 a gerente vê o status agregado do time; RF-02 a gerente filtra por responsável.
- **Épico E2 — Atualização:** RF-03 o responsável marca uma tarefa como concluída.

## 7. NFRs (com números)
- A tela carrega em até 2 segundos com 500 tarefas.
- Disponibilidade de 99,9% ao mês.

## 8. Restrições (das ADRs)
- Ver docs/adr/ADR-001 para a decisão de arquitetura.

## 9. Glossário
- Tarefa: unidade de trabalho atribuída a um responsável.

## 10. Riscos
- Adoção baixa se a atualização for trabalhosa; mitigar com fluxo de um clique.

## 11. Questões abertas
- [NEEDS CLARIFICATION] limite de tarefas por projeto.

## 12. Rastreabilidade
| RF | Épico | Fatia |
|----|-------|-------|
| RF-01 | E1 | R0 |
```

- [ ] **Step 2: Escrever o auto-teste (só o caso limpo, por ora)**

Create `scripts/test-check-prd.sh`:

```bash
#!/usr/bin/env bash
# Auto-teste do check-prd.sh contra fixtures. Semente da suíte de avaliação (R7).
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
CHECK="scripts/check-prd.sh"
FIX="scripts/fixtures"
fail=0

assert_exit() {  # desc  exit_esperado  exit_veio
  if [ "$2" != "$3" ]; then echo "FALHOU: $1 (exit esperado $2, veio $3)"; fail=1
  else echo "ok: $1"; fi
}
assert_contains() {  # desc  agulha  palheiro
  if printf '%s' "$3" | grep -qi -- "$2"; then echo "ok: $1"
  else echo "FALHOU: $1 (não achou: $2)"; fail=1; fi
}

# 1. PRD limpa → exit 0 / limpo
out="$(bash "$CHECK" prd "$FIX/prd-clean.md")"; rc=$?
assert_exit "prd limpa sai 0" 0 "$rc"
assert_contains "prd limpa reporta limpo" "check-prd: limpo" "$out"

if [ "$fail" -eq 0 ]; then echo "test-check-prd: tudo verde"; else echo "test-check-prd: FALHOU"; exit 1; fi
```

- [ ] **Step 3: Rodar o teste para vê-lo falhar (script ainda não existe)**

Run:
```bash
bash scripts/test-check-prd.sh; echo "rc=$?"
```
Expected: FALHA — `bash: scripts/check-prd.sh: No such file or directory`, `FALHOU: prd limpa sai 0`, `rc=1`.

- [ ] **Step 4: Escrever o esqueleto do `check-prd.sh` (checks vazios)**

Create `scripts/check-prd.sh`:

```bash
#!/usr/bin/env bash
# check-prd.sh — verificador mecânico das regras decidíveis do harness (R1).
# Verifica; NÃO bloqueia. Exit 0 = limpo, 1 = achados, 2 = erro de uso/ambiente.
# Quem lê o exit é a Fase 4, que aconselha (não reverte).
#
# Uso:
#   check-prd.sh prd     <arquivo>    # stack + nfr-sem-numero + rf-fora-de-epico
#   check-prd.sh specify <arquivo|->  # só stack (prompt do specify; - lê do stdin)
#
# Denylist: bloco ```denylist do quality-rules.md ao lado do script (references/)
# ou, no repo, em ../assets/quality-rules.md.
set -u

usage() { echo "uso: check-prd.sh <prd|specify> <arquivo|->" >&2; exit 2; }

mode="${1:-}"; target="${2:-}"
[ -n "$mode" ] && [ -n "$target" ] || usage
case "$mode" in prd|specify) ;; *) usage ;; esac

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
if [ -f "$SCRIPT_DIR/quality-rules.md" ]; then
  QR="$SCRIPT_DIR/quality-rules.md"                 # caso references/
elif [ -f "$SCRIPT_DIR/../assets/quality-rules.md" ]; then
  QR="$SCRIPT_DIR/../assets/quality-rules.md"       # caso repo
else
  echo "check-prd: quality-rules.md não encontrado (denylist indisponível)" >&2
  exit 2
fi

# Normaliza o alvo para um arquivo real (com line numbers) + rótulo de exibição.
TMPIN=""
cleanup() { [ -n "$TMPIN" ] && rm -f "$TMPIN"; }
trap cleanup EXIT
if [ "$target" = "-" ]; then
  TMPIN="$(mktemp)"; cat > "$TMPIN"; SRC="$TMPIN"; LABEL="specify"
else
  [ -f "$target" ] || { echo "check-prd: arquivo não encontrado: $target" >&2; exit 2; }
  SRC="$target"; LABEL="$(basename "$target")"
fi

# --- checks (preenchidos nas próximas tasks) ---
check_stack() { :; }
check_nfr()   { :; }
check_rf()    { :; }

case "$mode" in
  prd)     findings="$(check_stack; check_nfr; check_rf)" ;;
  specify) findings="$(check_stack)" ;;
esac

if [ -n "$findings" ]; then
  printf '%s\n' "$findings"
  count="$(printf '%s\n' "$findings" | grep -c .)"
  echo "check-prd: $count achado(s)"
  exit 1
else
  echo "check-prd: limpo"
  exit 0
fi
```

- [ ] **Step 5: Rodar o teste para vê-lo passar**

Run:
```bash
bash scripts/test-check-prd.sh; echo "rc=$?"
```
Expected: `ok: prd limpa sai 0`, `ok: prd limpa reporta limpo`, `test-check-prd: tudo verde`, `rc=0`.

- [ ] **Step 6: Commit**

```bash
git add scripts/check-prd.sh scripts/test-check-prd.sh scripts/fixtures/prd-clean.md
git commit -m "feat(check-prd): esqueleto do verificador + auto-teste do caso limpo"
```

---

## Task 3: Check de stack (denylist + sinais estruturais) — modos `prd` e `specify`

**Files:**
- Modify: `scripts/check-prd.sh`
- Create: `scripts/fixtures/prd-dirty.md`
- Create: `scripts/fixtures/specify-dirty.txt`
- Modify: `scripts/test-check-prd.sh`

- [ ] **Step 1: Escrever as fixtures sujas de stack**

Create `scripts/fixtures/prd-dirty.md`:

```markdown
# PRD — Editor de Diagramas

## 1. Visão
Para o analista, que precisa desenhar fluxos, o Editor é uma ferramenta de diagramação.

## 4. Escopo (in / out)
- **Faz (in):** editar diagramas.
- RF-09 exportar o diagrama em imagem.

## 6. Requisitos funcionais por épico (RF-xx)
- RF-07 o analista cria um nó solto.
- **Épico E1 — Edição:** RF-01 o analista edita o diagrama; RF-02 vê a prévia.

## 7. NFRs (com números)
- Disponibilidade alta.
- A tela carrega em até 2 segundos.

## 8. Restrições (das ADRs)
Vamos usar React Flow e Zustand; instalar com npm install react-flow.
```

Create `scripts/fixtures/specify-dirty.txt`:

```text
Como usuário, quero editar o diagrama e ver a prévia atualizar ao digitar.
Implementar com React e CodeMirror, salvando no localStorage.
```

- [ ] **Step 2: Acrescentar as asserções de stack ao auto-teste**

Edit em `scripts/test-check-prd.sh`. Localize a linha final:

```
if [ "$fail" -eq 0 ]; then echo "test-check-prd: tudo verde"; else echo "test-check-prd: FALHOU"; exit 1; fi
```

Insira **antes** dela:

```bash
# 2. PRD suja → exit 1 + achado de stack
out="$(bash "$CHECK" prd "$FIX/prd-dirty.md")"; rc=$?
assert_exit "prd suja sai 1" 1 "$rc"
assert_contains "prd suja acha stack" "stack" "$out"
assert_contains "prd suja acha termo react" "react" "$out"

# 3. specify sujo via stdin → exit 1 + stack
out="$(bash "$CHECK" specify - < "$FIX/specify-dirty.txt")"; rc=$?
assert_exit "specify sujo sai 1" 1 "$rc"
assert_contains "specify sujo acha stack" "stack" "$out"

# 4. specify limpo via stdin → exit 0
out="$(printf 'O usuário edita o diagrama e vê a prévia atualizar ao digitar.\n' | bash "$CHECK" specify -)"; rc=$?
assert_exit "specify limpo sai 0" 0 "$rc"
```

- [ ] **Step 3: Rodar o teste para vê-lo falhar (check_stack ainda é no-op)**

Run:
```bash
bash scripts/test-check-prd.sh; echo "rc=$?"
```
Expected: FALHA — `FALHOU: prd suja sai 1 (exit esperado 1, veio 0)` (e as asserções de stack), `rc=1`. (O caso 4, limpo, já passa.)

- [ ] **Step 4: Implementar `extract_denylist` e `check_stack`**

Edit em `scripts/check-prd.sh`. Substitua a linha:

```bash
check_stack() { :; }
```

por:

```bash
# Extrai os termos do bloco ```denylist do quality-rules.md (um por linha, minúsculo).
extract_denylist() {
  awk '
    /^```denylist[[:space:]]*$/ { inblock=1; next }
    inblock && /^```/           { inblock=0; next }
    inblock && NF               { print tolower($0) }
  ' "$QR"
}

check_stack() {
  local denyfile; denyfile="$(mktemp)"
  extract_denylist > "$denyfile"

  # Denylist: palavra inteira, case-insensitive; -o imprime o termo casado, -n a linha.
  if [ -s "$denyfile" ]; then
    grep -niwoF -f "$denyfile" "$SRC" 2>/dev/null | while IFS=: read -r n term; do
      printf '%s:%s: stack — "%s" (mova para o plan.md da feature)\n' "$LABEL" "$n" "$term"
    done
  fi
  rm -f "$denyfile"

  # Sinais estruturais de alta precisão.
  grep -niEo 'npm install|pip install|yarn add' "$SRC" 2>/dev/null | while IFS=: read -r n m; do
    printf '%s:%s: stack — "%s" (comando de instalação; vai no plan.md)\n' "$LABEL" "$n" "$m"
  done
  grep -nE '^[[:space:]]*(import |from [^ ]+ import )' "$SRC" 2>/dev/null | while IFS=: read -r n rest; do
    printf '%s:%s: stack — "%s" (código; vai no plan.md)\n' "$LABEL" "$n" "$(printf '%s' "$rest" | sed 's/^[[:space:]]*//')"
  done
  grep -nE '^[[:space:]]*```' "$SRC" 2>/dev/null | while IFS=: read -r n _; do
    printf '%s:%s: stack — "bloco de código" (detalhe técnico; vai no plan.md)\n' "$LABEL" "$n"
  done
  grep -niEo '[A-Za-z][A-Za-z0-9._-]*[[:space:]]+v?[0-9]+\.[0-9]+\.[0-9]+' "$SRC" 2>/dev/null | while IFS=: read -r n m; do
    printf '%s:%s: stack — "%s" (versão de dependência; vai no plan.md)\n' "$LABEL" "$n" "$m"
  done
}
```

- [ ] **Step 5: Rodar o teste para vê-lo passar**

Run:
```bash
bash scripts/test-check-prd.sh; echo "rc=$?"
```
Expected: `ok: prd suja sai 1`, `ok: prd suja acha stack`, `ok: prd suja acha termo react`, `ok: specify sujo sai 1`, `ok: specify sujo acha stack`, `ok: specify limpo sai 0`, `test-check-prd: tudo verde`, `rc=0`.

- [ ] **Step 6: Sanidade — a fixture limpa continua limpa**

Run:
```bash
bash scripts/check-prd.sh prd scripts/fixtures/prd-clean.md; echo "rc=$?"
```
Expected: `check-prd: limpo`, `rc=0`.

- [ ] **Step 7: Commit**

```bash
git add scripts/check-prd.sh scripts/test-check-prd.sh scripts/fixtures/prd-dirty.md scripts/fixtures/specify-dirty.txt
git commit -m "feat(check-prd): check de stack (denylist + sinais estruturais)"
```

---

## Task 4: Check de NFR sem número — modo `prd`

Dentro da seção `## 7.`, toda linha de item de NFR (bullet `-`/`*` ou id `NFR-`) precisa conter ao menos um dígito. Sem dígito → achado. Heurística por item de lista para manter falso-positivo baixo (linhas de prosa introdutória não são cobradas).

**Files:**
- Modify: `scripts/check-prd.sh`
- Modify: `scripts/test-check-prd.sh`

- [ ] **Step 1: Acrescentar a asserção de NFR ao auto-teste**

Edit em `scripts/test-check-prd.sh`. Localize o bloco `# 2. PRD suja` e, logo após a asserção `assert_contains "prd suja acha termo react" ...`, adicione:

```bash
assert_contains "prd suja acha nfr sem numero" "nfr-sem-numero" "$out"
```

(A variável `$out` ainda contém a saída de `check-prd prd prd-dirty.md`.)

- [ ] **Step 2: Rodar o teste para vê-lo falhar (check_nfr ainda é no-op)**

Run:
```bash
bash scripts/test-check-prd.sh; echo "rc=$?"
```
Expected: FALHA — `FALHOU: prd suja acha nfr sem numero (não achou: nfr-sem-numero)`, `rc=1`.

- [ ] **Step 3: Implementar `check_nfr`**

Edit em `scripts/check-prd.sh`. Substitua a linha:

```bash
check_nfr()   { :; }
```

por:

```bash
# Seção 7: item de NFR (bullet ou id NFR-) sem nenhum dígito → achado.
check_nfr() {
  awk -v label="$LABEL" '
    /^## / { n=$2; sub(/\./,"",n); sect=(n=="7"); next }
    sect && /^[[:space:]]*([-*]|NFR-)/ && $0 !~ /[0-9]/ {
      line=$0
      sub(/^[[:space:]]*[-*][[:space:]]*/,"",line)
      printf "%s:%d: nfr-sem-numero — \"%s\" (dê um número)\n", label, NR, line
    }
  ' "$SRC"
}
```

- [ ] **Step 4: Rodar o teste para vê-lo passar**

Run:
```bash
bash scripts/test-check-prd.sh; echo "rc=$?"
```
Expected: `ok: prd suja acha nfr sem numero`, `test-check-prd: tudo verde`, `rc=0`.

- [ ] **Step 5: Sanidade — a fixture limpa não gera falso-positivo de NFR**

Run:
```bash
bash scripts/check-prd.sh prd scripts/fixtures/prd-clean.md; echo "rc=$?"
```
Expected: `check-prd: limpo`, `rc=0` (os dois NFRs limpos têm dígito: `2 segundos`, `99,9%`).

- [ ] **Step 6: Commit**

```bash
git add scripts/check-prd.sh scripts/test-check-prd.sh
git commit -m "feat(check-prd): check de NFR sem número"
```

---

## Task 5: Check de RF fora de épico — modo `prd`

Dentro da seção `## 6.`, todo `RF-xx` que aparece **antes** do primeiro agrupamento `Épico E#` → achado. Fora da seção 6, `RF-xx` em linha de bullet que não seja de tabela (`|`) → achado (definição solta; a tabela de rastreabilidade da seção 12 é excluída por começar com `|`).

**Files:**
- Modify: `scripts/check-prd.sh`
- Modify: `scripts/test-check-prd.sh`

- [ ] **Step 1: Acrescentar a asserção de RF ao auto-teste**

Edit em `scripts/test-check-prd.sh`. Logo após `assert_contains "prd suja acha nfr sem numero" ...`, adicione:

```bash
assert_contains "prd suja acha rf fora de epico" "rf-fora-de-epico" "$out"
```

- [ ] **Step 2: Rodar o teste para vê-lo falhar (check_rf ainda é no-op)**

Run:
```bash
bash scripts/test-check-prd.sh; echo "rc=$?"
```
Expected: FALHA — `FALHOU: prd suja acha rf fora de epico (não achou: rf-fora-de-epico)`, `rc=1`.

- [ ] **Step 3: Implementar `check_rf`**

Edit em `scripts/check-prd.sh`. Substitua a linha:

```bash
check_rf()    { :; }
```

por:

```bash
# Seção 6: RF-xx antes do primeiro "Épico E#" → solto. Fora da seção 6: RF-xx
# em bullet não-tabela → definição fora do lugar. (match 2-arg = POSIX, portável.)
check_rf() {
  awk -v label="$LABEL" '
    /^## / { n=$2; sub(/\./,"",n); sect=n; if (n=="6") epic=0; next }
    {
      if (sect=="6" && $0 ~ /pico[[:space:]]+[Ee][0-9]/) epic=1
      if ($0 ~ /RF-[0-9]+/) {
        match($0, /RF-[0-9]+/); rf=substr($0, RSTART, RLENGTH)
        if (sect=="6") {
          if (epic==0)
            printf "%s:%d: rf-fora-de-epico — \"%s\" (agrupe sob um Épico E#)\n", label, NR, rf
        } else if ($0 ~ /^[[:space:]]*[-*]/ && $0 !~ /^[[:space:]]*\|/) {
          printf "%s:%d: rf-fora-de-epico — \"%s\" (definido fora da seção 6)\n", label, NR, rf
        }
      }
    }
  ' "$SRC"
}
```

- [ ] **Step 4: Rodar o teste para vê-lo passar**

Run:
```bash
bash scripts/test-check-prd.sh; echo "rc=$?"
```
Expected: `ok: prd suja acha rf fora de epico`, `test-check-prd: tudo verde`, `rc=0`.

- [ ] **Step 5: Sanidade — inspecionar os achados da fixture suja**

Run:
```bash
bash scripts/check-prd.sh prd scripts/fixtures/prd-dirty.md; echo "rc=$?"
```
Expected: entre os achados, `prd-dirty.md:9: rf-fora-de-epico — "RF-09" (definido fora da seção 6)` (linha da seção 4) e `prd-dirty.md:12: rf-fora-de-epico — "RF-07" (agrupe sob um Épico E#)` (antes do épico), além dos achados de stack e NFR; `rc=1`. (Os números de linha podem variar — confira o tipo de achado, não o número exato.)

- [ ] **Step 6: Sanidade — a fixture limpa continua limpa**

Run:
```bash
bash scripts/check-prd.sh prd scripts/fixtures/prd-clean.md; echo "rc=$?"
```
Expected: `check-prd: limpo`, `rc=0` (RF-01/02/03 sob épicos; RF-01 da tabela da seção 12 excluído por começar com `|`).

- [ ] **Step 7: Commit**

```bash
git add scripts/check-prd.sh scripts/test-check-prd.sh
git commit -m "feat(check-prd): check de RF fora de épico"
```

---

## Task 6: Distribuir o script para os `references/` via o mapa de sync

**Files:**
- Modify: `scripts/asset-map.sh`

- [ ] **Step 1: Adicionar a entrada ao `ASSET_MAP`**

Edit em `scripts/asset-map.sh`. Localize:

```bash
ASSET_MAP=(
  "assets/quality-rules.md                zion-prd-discovery zion-prd-spike zion-prd-write zion-prd-decompose zion-prd-constitution-prompt zion-prd-specify-prompt zion-prd-plan-prompt"
  "assets/templates/prd-skeleton.md       zion-prd-write"
  "assets/templates/traceability-table.md zion-prd-decompose"
  "assets/process-context.md              zion-prd-discovery zion-prd-spike zion-prd-write zion-prd-decompose zion-adr-new"
)
```

Adicione uma linha ao final da lista (antes do `)`):

```bash
  "scripts/check-prd.sh                   zion-prd-write zion-prd-specify-prompt"
```

- [ ] **Step 2: Sincronizar e conferir**

Run:
```bash
./scripts/sync-assets.sh && ./scripts/check-assets.sh
```
Expected: `sync-assets: ok`, `check-assets: sem drift`. Agora existem `skills/zion-prd-write/references/check-prd.sh` e `skills/zion-prd-specify-prompt/references/check-prd.sh`.

- [ ] **Step 3: Verificar que a cópia em `references/` acha o `quality-rules.md` ao lado dela**

Run (exercita o caminho `references/`, não o do repo):
```bash
bash skills/zion-prd-write/references/check-prd.sh prd scripts/fixtures/prd-dirty.md; echo "rc=$?"
```
Expected: os mesmos achados de stack/NFR/RF da Task 5 e `rc=1` — provando que a cópia em `references/` localiza `references/quality-rules.md` (a denylist viajou junto).

- [ ] **Step 4: Commit**

```bash
git add scripts/asset-map.sh skills/zion-prd-write/references/check-prd.sh skills/zion-prd-specify-prompt/references/check-prd.sh
git commit -m "feat(sync): distribuir check-prd.sh para os references das skills consumidoras"
```

---

## Task 7: Ligar as Fases 4 das duas skills ao script

**Files:**
- Modify: `skills/zion-prd-write/SKILL.md`
- Modify: `skills/zion-prd-specify-prompt/SKILL.md`

- [ ] **Step 1: Reescrever a Fase 4 de `zion-prd-write`**

Edit em `skills/zion-prd-write/SKILL.md`. Substitua **todo** o bloco:

```
## Fase 4 — Validar saída (aconselha) — GUARDA DE FRONTEIRA
Confira contra o critério **prd** de `quality-rules.md` `#criterios-de-conclusao`: escopo in/out
explícito ∧ `RF-xx` por épico (1 frase) ∧ NFRs com número ∧ **zero** stack / critério de aceite /
tela. Para o zero-stack, aplique o teste de vazamento de `#fronteira`: se alguma linha cita
linguagem/framework/biblioteca/tela/contrato de API, **aponte a linha exata** e sugira movê-la para o
`plan.md` da feature. Emita veredito por item. Não reverta — apenas aconselhe.
```

por:

```
## Fase 4 — Validar saída (aconselha) — GUARDA DE FRONTEIRA
As três regras decidíveis são verificadas por máquina. Rode:

    bash references/check-prd.sh prd docs/PRD.md

O script executa zero-stack (denylist + sinais estruturais), NFR-com-número e RF-por-épico, e imprime
cada achado ancorado em `arquivo:linha`. **Ecoe o veredito com autoridade** — reproduza os achados
com número de linha — e para cada um sugira mover a linha para o `plan.md` da feature (stack) ou
corrigir/justificar (NFR, RF). Exit `1` = há achados; exit `0` = limpo.

Complemente com o que o script não decide: os itens **prd** de `quality-rules.md`
`#criterios-de-conclusao` que dependem de julgamento (escopo in/out explícito, critério de aceite ou
tela vazando em prosa) — aplique o teste de vazamento de `#fronteira` e aponte a linha.

Não reverta — apenas aconselhe. Falso-positivo o humano descarta na hora.
```

- [ ] **Step 2: Reescrever a Fase 4 de `zion-prd-specify-prompt`**

Edit em `skills/zion-prd-specify-prompt/SKILL.md`. Substitua **todo** o bloco:

```
## Fase 4 — Validar saída e handoff (aconselha)
Confira contra o critério **specify-prompt** de `#criterios-de-conclusao`: declara observável ∧ sem
stack ∧ RF-xx/ADR como contexto. Então **entregue o comando pronto** para o usuário disparar, por
exemplo:

    /speckit.specify "<prompt montado>"
```

por:

```
## Fase 4 — Validar saída e handoff (aconselha)
Verifique o zero-stack por máquina, passando o prompt montado ao script via stdin:

    printf '%s' "<prompt montado>" | bash references/check-prd.sh specify -

O script casa o prompt contra a denylist e os sinais estruturais e imprime cada achado com o número
da linha do prompt. **Ecoe o veredito** — para cada achado, lembre que a stack fica no `plan`, não no
`specify`. Complemente com o julgamento que o script não faz: o prompt declara um resultado
observável ∧ cita `RF-xx`/ADR como contexto (referência), não como requisito. Não bloqueie.

Então **entregue o comando pronto** para o usuário disparar, por exemplo:

    /speckit.specify "<prompt montado>"
```

- [ ] **Step 3: Verificar que as edições não tocaram `references/` derivados**

Run:
```bash
./scripts/check-assets.sh
```
Expected: `check-assets: sem drift` (os `SKILL.md` não são assets sincronizados; nada regenera).

- [ ] **Step 4: Commit**

```bash
git add skills/zion-prd-write/SKILL.md skills/zion-prd-specify-prompt/SKILL.md
git commit -m "feat(skills): Fases 4 rodam check-prd.sh e ecoam o veredito"
```

---

## Task 8: Rodar o auto-teste no CI

**Files:**
- Modify: `.github/workflows/check-assets.yml`

- [ ] **Step 1: Adicionar o passo do auto-teste ao workflow**

Edit em `.github/workflows/check-assets.yml`. Substitua:

```yaml
      - name: Verifica drift de assets derivados
        run: ./scripts/check-assets.sh
```

por:

```yaml
      - name: Verifica drift de assets derivados
        run: ./scripts/check-assets.sh
      - name: Auto-teste do check-prd
        run: bash scripts/test-check-prd.sh
```

- [ ] **Step 2: Rodar o auto-teste localmente uma última vez (proxy do CI)**

Run:
```bash
bash scripts/test-check-prd.sh; echo "rc=$?"
```
Expected: `test-check-prd: tudo verde`, `rc=0`.

- [ ] **Step 3: Commit**

```bash
git add .github/workflows/check-assets.yml
git commit -m "ci: rodar o auto-teste do check-prd no workflow"
```

---

## Task 9: Menção nos guias vivos

**Files:**
- Modify: `docs/como-usar.md`
- Modify: `README.md`

- [ ] **Step 1: Anotar a verificação mecânica na Fase 4 do `zion-prd-write` (como-usar)**

Edit em `docs/como-usar.md`. Localize:

```
**Fase 4 — guarda de fronteira.** Confere: escopo in/out ✓, `RF-xx` por épico (1 frase) ✓, NFRs
com número ✓, **zero stack/critério de aceite/tela**. Se uma linha vazar (veja o exemplo de gate
abaixo), ela aponta a linha exata e sugere mover para o `plan.md`.
```

Substitua por:

```
**Fase 4 — guarda de fronteira.** As três regras decidíveis (zero-stack, `RF-xx` por épico, NFR com
número) são verificadas **por máquina** — a skill roda `references/check-prd.sh prd docs/PRD.md` e
ecoa o veredito com o número da linha de cada achado. O julgamento subjetivo (critério de aceite ou
tela vazando em prosa) fica com o LLM. Se uma linha vazar, aponta a linha exata e sugere mover para o
`plan.md`. Gate aconselha, não bloqueia.
```

- [ ] **Step 2: Anotar a verificação na linha da ponte specify (como-usar)**

Edit em `docs/como-usar.md`. Localize a linha da tabela:

```
| `/zion-prd-specify-prompt` | Ponte p/ 5b | backlog de fatias | prompt do `/speckit.specify` | *(monta em prosa; sem delegação)* |
```

Substitua por:

```
| `/zion-prd-specify-prompt` | Ponte p/ 5b | backlog de fatias | prompt do `/speckit.specify` | *(monta em prosa; zero-stack verificado por `check-prd.sh`)* |
```

- [ ] **Step 3: Anotar o `check-prd.sh` na seção Desenvolvimento (README)**

Edit em `README.md`. Localize:

```
O CI roda `./scripts/check-assets.sh` como guard de drift (backstop para `--no-verify`
ou quem não rodou o `setup-hooks.sh`). Para checar/sincronizar à mão:

```bash
./scripts/sync-assets.sh   # regenera references/ a partir de assets/
./scripts/check-assets.sh  # falha se algum references/ divergir
```
```

Substitua por:

````
O CI roda `./scripts/check-assets.sh` como guard de drift (backstop para `--no-verify`
ou quem não rodou o `setup-hooks.sh`) e `bash scripts/test-check-prd.sh` como auto-teste do
verificador de regras. Para checar/sincronizar/testar à mão:

```bash
./scripts/sync-assets.sh       # regenera references/ a partir de assets/
./scripts/check-assets.sh      # falha se algum references/ divergir
bash scripts/test-check-prd.sh # auto-teste do check-prd.sh contra as fixtures
```

As Fases 4 de `/zion-prd-write` e `/zion-prd-specify-prompt` rodam `scripts/check-prd.sh` (sincronizado
para o `references/` de cada uma) para verificar mecanicamente as regras decidíveis (zero-stack,
NFR-com-número, RF-por-épico). A denylist de stack é curada em `assets/quality-rules.md` (`#denylist`).
````

- [ ] **Step 4: Verificar que nada de `references/` mudou**

Run:
```bash
./scripts/check-assets.sh
```
Expected: `check-assets: sem drift`.

- [ ] **Step 5: Commit**

```bash
git add docs/como-usar.md README.md
git commit -m "docs: mencionar a verificação mecânica das Fases 4"
```

---

## Verificação final (o plano inteiro)

- [ ] **Rodar a suíte completa e as sanidades de ponta a ponta**

Run:
```bash
./scripts/sync-assets.sh && ./scripts/check-assets.sh && bash scripts/test-check-prd.sh
bash scripts/check-prd.sh prd scripts/fixtures/prd-clean.md; echo "limpa rc=$?"
bash scripts/check-prd.sh prd scripts/fixtures/prd-dirty.md; echo "suja rc=$?"
bash skills/zion-prd-write/references/check-prd.sh prd scripts/fixtures/prd-dirty.md >/dev/null; echo "references rc=$?"
```
Expected: `sync-assets: ok`, `check-assets: sem drift`, `test-check-prd: tudo verde`, `limpa rc=0`, `suja rc=1`, `references rc=1`.

---

## Notas de design (para quem executa)

- **Advisório, sem supressão.** Exit `1` não interrompe o fluxo — quem lê o exit é a Fase 4, que aconselha. Falso-positivo o humano descarta na hora; supressão inline seria YAGNI (só importaria se bloqueasse). Fora de escopo: bloqueio/gate, R4 (RF↔FR), hook/CI no projeto consumidor, suíte completa da R7.
- **Portabilidade.** O `awk` usa só recursos POSIX (`match` 2-arg + `substr`, sem `match(...,arr)` do gawk). `grep -niwoF`/`-nE` funcionam em GNU e BSD. Sem `set -e` no `check-prd.sh` de propósito: um `grep` sem casar retorna `1` legitimamente (arquivo limpo) e não deve abortar o script; o exit final vem da presença de achados.
- **Heurísticas conscientes (falso-positivo baixo > recall).** NFR: só cobra linhas de item (bullet/`NFR-`), não prosa introdutória. RF fora de épico: dentro da seção 6, cobra RF antes do primeiro `Épico E#`; fora da seção 6, só bullets não-tabela (a tabela de rastreabilidade começa com `|` e fica de fora). A arquitetura de funções independentes deixa apertar essas regras ou plugar R4 depois sem retrabalho.
- **Fonte única da denylist.** Editar a lista = editar `assets/quality-rules.md` (`#denylist`); o sync propaga para os `references/`. Nunca editar `references/` à mão.
