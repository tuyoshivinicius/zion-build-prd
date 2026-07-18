# R9 — Contrato explícito com o superpowers

> **Origem:** recomendação R9 de `docs/critica-zion-build-prd.md` (§5.2, gap H4).
> **Data:** 2026-07-17. **Esforço:** Baixo. **Escopo:** 1 asset novo (contrato) sincronizado
> para 3 skills + 1 script de check + 1 auto-teste + fixtures + entrada no `eval.sh` +
> pin de versão no `plugin.json` + linha em `avaliacao-harness.md`.

## Problema

`superpowers:brainstorming` é o executor de três dos quatro estágios criativos do harness
(discovery, write, decompose). O preflight de cada um cobre **ausência** da skill, mas não
**mudança de comportamento**: o contrato entre o harness e o brainstorming é implícito
(espera-se que ele aceite um enquadramento fixo e grave um arquivo no caminho que nomeamos),
sem pin de versão nem teste de contrato (H4). Uma atualização do superpowers pode degradar
silenciosamente os três estágios centrais, e nada acusaria.

Evidência de que o risco é real, não hipotético: há **duas versões do superpowers em cache**
(5.0.7 e 6.1.1 — um major bump) e a dependência em `plugin.json` **não tinha pin**. O major
bump chegou a acontecer; só não mordeu porque, por sorte, a única mudança no `brainstorming`
entre as versões foi o *timing* da oferta do visual companion — tudo que o harness depende
sobreviveu intacto. Sem mecanismo, essa estabilidade é sorte verificada uma vez, não garantia.

O princípio que atravessa a correção é o mesmo de R1/R7 e do padrão assets→references:
**mover o invariante de prosa para máquina, e a promessa sem mecanismo para uma promessa
menor com mecanismo.**

## Decisões (discovery)

1. **Checagem estática do texto da skill, não teste de execução.** `brainstorming` é uma
   skill interativa/socrática — não roda headless num shell script. Portanto "testar o
   contrato" é fazer `grep` de marcadores de capacidade no `SKILL.md` instalado, análogo ao
   `check-assets` — não exercitar o comportamento.
2. **Roda só na suíte de avaliação (`eval.sh`), não na Fase 0.** Zero atrito no uso normal
   dos três estágios; a proteção é na manutenção/upgrade, que é quando o drift entra.
3. **Hard-pin no `plugin.json`.** O campo `version` da entrada de dependência aceita ranges
   semver (confirmado na doc oficial de plugin dependencies). Pin = os majors testados.
4. **Marcadores mínimos, de capacidade — não de redação.** O objetivo é detectar quebra de
   contrato, não diff de frase. Um marcador robusto por capacidade; some 0 → drift.
5. **Contrato é um asset sincronizado.** Fonte única em `assets/`, derivado para as
   `references/` das 3 skills dependentes, coberto pelo sync+hook+CI já existentes.

## As três capacidades do contrato (C1–C3)

O harness não depende de todo o comportamento do `brainstorming` — depende de três
capacidades. O check verifica que **cada uma tem ≥1 marcador presente**; marcadores são
frases de capacidade (tolerantes a reescrita), não trechos exatos.

| # | Capacidade que o harness usa | Onde é usada | Marcador (grep, tolerante) |
|---|------------------------------|--------------|----------------------------|
| C1 | Aceita um **enquadramento fixo** e refina ideia → design | os 3 estágios injetam um prompt fixo | `turn ideas into.*designs` \| `refine the idea` |
| C2 | **Grava o resultado num arquivo** cujo caminho nomeamos | discovery→`discovery.md`, write→`PRD.md` | `Write design doc` **∧** `save to.*docs/` |
| C3 | Conduz diálogo **seção a seção / uma pergunta por vez** | write preenche a PRD "seção a seção" | `one question at a time` \| `Present design.*section` |

Notas:
- Os padrões acima são a **especificação**; a lista canônica e afinável vive em
  `assets/superpowers-contract.md`, que o script referencia como fonte da verdade.
- C2 exige os **dois** marcadores juntos (capacidade "gravar em arquivo nomeado" =
  "escreve um doc" ∧ "num caminho sob `docs/`"); C1 e C3 aceitam qualquer um dos alternantes.
- **Fora de escopo deliberado:** marcadores de "writing-plans terminal", "spec self-review"
  etc. — o harness *redireciona* a saída do brainstorming e não depende do terminal padrão
  dele; checá-los viraria ruído a cada refraseado (o gate que a crítica quer evitar).

## Componentes

### 1. `assets/superpowers-contract.md` (parte a — documentar a interface)

Prosa curta, fonte única. Conteúdo:
- As três capacidades C1–C3, cada uma com **o porquê** (qual estágio quebraria sem ela).
- Os marcadores de cada capacidade (a lista que o script consome conceitualmente).
- `testado-contra: 5.0.7, 6.1.1`.
- **Runbook de drift:** "ao `eval.sh` acusar `⚠ C_x`, faça: (1) leia o `SKILL.md` da nova
  versão; (2) se a capacidade mudou de forma mas continua existindo, atualize o marcador
  aqui e no script; (3) se sumiu de verdade, não alargue o pin — trate o estágio afetado."

Registrado em `scripts/asset-map.sh`, sincronizado por `sync-assets.sh` para as
`references/` de `zion-prd-discovery`, `zion-prd-write` e `zion-prd-decompose`.

### 2. `scripts/check-superpowers-contract.sh` (parte b — o check real)

**Localização do `brainstorming/SKILL.md` (primeira que existir vence):**
1. `--skill <caminho>` explícito → usado pelo auto-teste (aponta para fixture).
2. Plugin cache: `~/.claude/plugins/cache/superpowers-marketplace/superpowers/*/skills/brainstorming/SKILL.md`
   — havendo mais de uma versão, escolhe a **maior** (`sort -V`), coerente com o que o
   Claude Code carrega dentro do range.
3. `npx skills`: `~/.claude/skills/brainstorming/SKILL.md` (fallback).

**Lógica:** cada capacidade tem uma **regra de satisfação** própria — C1 e C3 são satisfeitas
por **qualquer** um de seus marcadores alternantes (OR); C2 exige os **dois** conjuntos
(`Write design doc` **∧** `save to.*docs/`), então falta de qualquer um já é drift de C2.
Capacidade não satisfeita → drift; emitir `⚠ C_x: <capacidade> sumiu do brainstorming
v<versão> — revalidar o contrato (ver superpowers-contract.md)`.

**Degradação graciosa (decisão-chave):** se **nada** for localizado, **não falha** — emite
`∅ superpowers não instalado localmente — contrato não verificável aqui (ok em CI)` e sai
**0**. O CI do repo não tem o superpowers; quem garante a lógica no CI é o auto-teste com
fixtures. O valor do check real é no ambiente de quem faz o upgrade.

**Códigos de saída:** `0` = contrato intacto **ou** não verificável; `1` = encontrado mas
≥1 capacidade sumiu (drift real); `2` = uso.

**Consequência explícita:** rodar `eval.sh` sem o superpowers instalado **não** acusa R9
(sai verde por "não verificável"). A proteção real depende de rodar no ambiente que tem o
plugin. A alternativa (`1` quando não encontra) foi rejeitada: quebraria o CI do repo sempre.

### 3. `scripts/test-check-superpowers-contract.sh` + fixtures (parte b — auto-teste)

**Fixtures** (`scripts/fixtures/superpowers/`):
- `clean/SKILL.md` — cópia enxuta com as 3 capacidades presentes → check deve dar **0**.
- `drift-c2/SKILL.md` — igual, mas sem o marcador de C2 → check deve dar **1** e citar `C2`.

Duas fixtures bastam (uma limpa + um drift representativo): o mecanismo de "capacidade
faltando" é o mesmo para C1/C2/C3 — uma por capacidade seria YAGNI.

O auto-teste roda o check com `--skill` em cada fixture e afirma exit-code **e** que a
mensagem de drift nomeia a capacidade certa. Exit 0 se ambos os casos batem.

### 4. `scripts/eval.sh` (integração)

```bash
[contract]="scripts/test-check-superpowers-contract.sh"
ORDER=(prd adr trace contract)
```

Assim o auto-teste roda no CI (contra fixtures, portável) e o check real fica disponível
para o dia do upgrade.

### 5. `plugin.json` (parte c — pin de versão)

```json
"dependencies": [
  { "name": "superpowers", "marketplace": "superpowers-marketplace", "version": ">=5 <7" }
]
```

Range = os dois majors testados (5.x, 6.x). Um 7.x futuro fica bloqueado até o eval rodar
contra ele e alguém alargar o range. **O pin trava a porta; o check-de-contrato diz se pode
alargar** — os dois formam um par. Nuance confirmada: para fonte npm-backed a checagem do
range é no *load time* (a dependência falha ao carregar se cair fora), então um upstream
fora do range vira **erro visível**, não degradação silenciosa — o que H4 pedia.

### 6. `docs/avaliacao-harness.md` (doc da suíte)

Uma linha/seção descrevendo a nova camada `contract` do `eval.sh` e apontando para
`superpowers-contract.md`.

## Erros e edge cases

- **Múltiplas versões em cache** → maior vence (`sort -V`), coerente com o load-time do
  Claude Code.
- **Marcador ambíguo** (grep casando em comentário/exemplo) → marcadores são frases de
  capacidade, baixa probabilidade; a fixture `clean` guarda contra regressão do próprio grep.
- **Novo asset e sync** → `sync-assets.sh`/hook/CI existentes passam a cobrir
  `superpowers-contract.md` automaticamente; `check-assets` garante que as `references/` não
  derivam da fonte.

## Fronteira de escopo (o que R9 NÃO faz)

- Não altera a Fase 0 das skills (nenhum atrito novo no uso).
- Não adiciona ritual de revisão humana (isso é F3/R6).
- Não resolve a retomada da Fase 4 após o brainstorming (H3) — só o contrato + teste + pin.

## Critério de conclusão

- `assets/superpowers-contract.md` existe, registrado no `asset-map.sh` e sincronizado para
  as 3 skills; `check-assets` verde.
- `check-superpowers-contract.sh`: `0` intacto/não-verificável, `1` no drift (cita a
  capacidade), localiza via cache e via fallback `npx skills`.
- `test-check-superpowers-contract.sh` verde nas duas fixtures; entrada `contract` no
  `eval.sh`; `eval.sh` verde.
- `plugin.json` com `"version": ">=5 <7"` na dependência do superpowers.
- `avaliacao-harness.md` descreve a camada `contract`.
