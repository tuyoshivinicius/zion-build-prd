# Spec — Harness de orquestração do processo PRD → Spec Kit

> **Data:** 2026-07-11
> **Estado:** desenho aprovado, pronto para plano de implementação.
> **Documento-fonte:** `docs/guia-prd-para-spec-kit.md` (o manual narrativo que este harness executa).

## 1. Problema

O `guia-prd-para-spec-kit.md` descreve um processo de seis estágios (Descoberta → Spikes/ADR →
PRD → Decomposição → Spec Kit por feature → Rastreabilidade), mas é **um manual de leitura**: quem
executa é o usuário, invocando manualmente `superpowers:brainstorming`, `deep-research`, `adr-new`,
`rewrite-prompt` e os `/speckit.*` com os argumentos certos e na ordem certa. Isso é propenso a
erro: pular pré-requisitos, esquecer o "não faz", deixar stack vazar para a PRD, montar um prompt de
`specify` fraco.

**Objetivo:** uma camada de orquestração fina que dirige o fluxo — pergunta o que precisa, valida a
qualidade da entrada e da saída, formata no padrão esperado, e delega à skill real — reduzindo o
processo a poucos comandos, sem reimplementar o que as skills reais já fazem.

## 2. Decisões de design (fixadas no brainstorming)

| Eixo | Decisão | Consequência |
|------|---------|--------------|
| Forma | Um comando fino por estágio (padrão `SKILL.md`) | Usuário conduz a sequência entre estágios; cada comando é autônomo |
| Cobertura | Estágios 1–4 + o construtor do prompt do `specify` | O ciclo `/speckit.*` (5b) fica direto, sem wrapper |
| Validação | Entrada + saída, **aconselhando** (gate mole) | Sempre emite veredito; nunca bloqueia — o usuário decide seguir |
| Estado | Sem estado — derivado dos arquivos no disco | Nada dessincroniza; "passou" é inferido do conteúdo dos artefatos |
| Delegação | Auto-delega a skill real no mesmo turno | Menos passos manuais; o comando orquestra de fato |
| Estrutura | Comandos finos + regras compartilhadas + templates extraídos | Padrão de qualidade e formato têm dono único |

## 3. Arquitetura e layout de arquivos

```
.claude/skills/
  prd-discovery/SKILL.md      # Estágio 1 — Descoberta enxuta
  prd-spike/SKILL.md          # Estágio 2 — Spikes + ADR
  prd-write/SKILL.md          # Estágio 3 — PRD enxuta (o coração)
  prd-decompose/SKILL.md      # Estágio 4 — Épicos → story map → fatias verticais
  prd-specify-prompt/SKILL.md # Ponte p/ 5b — monta o prompt do /speckit.specify

.specify/prd/
  quality-rules.md            # Fonte única: fronteira o-quê/como, critérios de
                              # conclusão por estágio, INVEST/SPIDR, anatomia specify
  templates/
    prd-skeleton.md           # Esqueleto da PRD (12 seções) — extraído do guia
    traceability-table.md     # Tabela RF-xx ↔ specs/###-nome — extraído do guia
```

**Justificativa do layout:**
- Os `SKILL.md` ficam finos e *apontam* para `quality-rules.md` em vez de repetir regras — afinar o
  padrão de qualidade mexe num arquivo só.
- `.specify/prd/` espelha o `.specify/templates/` que o Spec Kit já usa. `prd-write` copia
  `prd-skeleton.md` → `docs/PRD.md` do mesmo jeito que `speckit-specify` copia `spec-template.md`.
- **Sem arquivo de estado**: os comandos leem `docs/discovery.md`, `docs/adr/`, `docs/PRD.md`
  diretamente para inferir se o passo anterior "passou".

## 4. Contrato de execução comum (as 5 fases)

Todos os 5 comandos compartilham o mesmo contrato. O `SKILL.md` de cada um só preenche o que muda.

- **Fase 0 · Pré-requisito (entrada, aconselha).** Inspeciona os artefatos do disco que o estágio
  consome. Faltando algo → **avisa** e pergunta se segue mesmo assim. Não bloqueia.
- **Fase 1 · Validar entrada bruta (aconselha).** Checa o que o usuário digitou contra as regras do
  estágio em `quality-rules.md`. Problema → aponta + sugere; usuário decide.
- **Fase 2 · Formatar / enquadrar.** Transforma a entrada bruta no formato que a skill real espera
  (enquadramento de brainstorming, esqueleto copiado, ou prompt XML).
- **Fase 3 · Auto-delegar (mesmo turno).** Invoca a skill real já com o enquadramento pronto.
- **Fase 4 · Validar saída (aconselha).** Confere o artefato produzido contra o "critério de
  conclusão" do estágio. Desvio → aponta + sugere; não reverte nada.

**Invariantes:**
- **Aconselhar ≠ silenciar.** Toda fase de gate emite veredito explícito (✓ / ⚠ + sugestão).
- **Idempotência.** Reexecutar um comando com o artefato-alvo já existente entra em modo
  *revisar/pressionar*, não sobrescreve do zero (a Fase 0 detecta lendo o arquivo).
- **Fronteira num lugar só.** As Fases 1 e 4 dos comandos que tocam PRD/specify leem a mesma seção
  `#fronteira` de `quality-rules.md`.

## 5. Especificação por comando

### 5.1 `/prd-discovery` — Estágio 1
- **Pré-req:** nenhum. Aceita ideia bruta + URLs de referência.
- **Entrada:** a semente tem problema e persona candidata? Stack colada aqui → avisa que é cedo.
- **Delega:** `superpowers:brainstorming` com enquadramento fixo (visão-1-frase, persona principal,
  quadro faz/não-faz).
- **Saída:** `docs/discovery.md` com visão-1-frase + ≥1 persona nomeada + **"não faz" explícito**.

### 5.2 `/prd-spike` — Estágio 2
- **Pré-req:** `docs/discovery.md` existe.
- **Entrada:** usuário nomeia 2–3 decisões estruturantes (filtro "isso muda a PRD inteira?").
- **Delega:** `deep-research` (trade-offs) → `adr-new` por decisão (dois sub-passos no comando).
- **Saída:** cada decisão vira `docs/adr/ADR-00x-*.md` (contexto/decisão/consequências). Avisa se
  algum ADR não referencia um spike real.

### 5.3 `/prd-write` — Estágio 3 (o coração)
- **Pré-req:** `docs/discovery.md` + `docs/adr/`. Se `docs/PRD.md` existe → modo revisar.
- **Entrada:** trabalha sobre os artefatos, não sobre texto novo.
- **Formata:** copia `prd-skeleton.md` → `docs/PRD.md` (12 seções em branco).
- **Delega:** `superpowers:brainstorming` preenchendo seção a seção, pressionando cada RF-xx/NFR.
- **Saída:** escopo in/out explícito; `RF-xx` por épico (1 frase); NFRs com número; **sem** critério
  de aceite/telas/stack (checagem de fronteira). Desvio → aponta a linha e sugere mover para `plan.md`.

### 5.4 `/prd-decompose` — Estágio 4
- **Pré-req:** `docs/PRD.md` com seção `RF-xx`.
- **Delega:** `superpowers:brainstorming`: agrupa RF-xx em épicos → story map → cortes R0..Rn →
  fatias verticais.
- **Saída:** cada fatia passa no INVEST (teste "dá demo ponta-a-ponta sozinha?"); walking skeleton é
  a fatia zero; copia `traceability-table.md` para a seção 12 da PRD, uma linha por RF-xx in-scope.
  Fatia horizontal → sugere refatiar via SPIDR.

### 5.5 `/prd-specify-prompt` — Ponte para 5b
- **Pré-req:** existe backlog de fatias (saída do decompose). Usuário aponta *qual* fatia.
- **Entrada:** a fatia tem resultado observável? Biblioteca/framework citada → avisa (é do `plan`).
- **Delega:** `rewrite-prompt` montando o prompt XML: `<constraints>` blinda "sem stack",
  `<context>` põe RF-xx/ADR como referência, `<success_criteria>` declara o observável.
- **Saída (handoff):** entrega o `/speckit.specify "..."` pronto para o usuário disparar. **O
  auto-delegar para aqui** — o ciclo speckit é do usuário. Encerra o território do harness.

## 6. Conteúdo dos arquivos compartilhados

### 6.1 `.specify/prd/quality-rules.md` — fonte única de verdade
Estruturado para os comandos citarem por âncora. Quatro blocos:
1. **`#fronteira`** — o-quê/por-quê vs. como: o que pode aparecer na PRD/specify (visão, escopo,
   RF-xx, RN-xx, NFR, restrições) e o que não pode (critério de aceite, telas, stack, contrato de
   API), com exemplos de frase-que-passa vs. frase-que-vaza.
2. **`#criterios-de-conclusao`** — checklist objetiva por estágio, lida pelas Fases 0 e 4.
3. **`#invest` / `#spidr`** — os testes textuais do Passo 4, com "dá demo sozinha?" como
   teste-relâmpago do INVEST e os 4 eixos de corte do SPIDR.
4. **`#anatomia-specify`** — o que vai em `<constraints>`, `<context>` e `<success_criteria>`.

### 6.2 `.specify/prd/templates/prd-skeleton.md`
As 12 seções em branco do "Modelo de esqueleto de PRD" do guia, cada cabeçalho trazendo *o que
entra* e *o que NÃO entra*. Extração fiel do guia para arquivo.

### 6.3 `.specify/prd/templates/traceability-table.md`
A tabela `RF-xx ↔ specs/###-nome` em branco (RF · Descrição · Épico · Feature/Spec · Release ·
Status) + legenda ☐/◐/●.

### 6.4 Migração do guia (dono único)
Hoje o esqueleto e a tabela vivem **dentro** do guia. Ao extrair, o guia **deixa de embutir** os dois
blocos e passa a **linká-los** (`ver .specify/prd/templates/…`). O guia segue sendo o manual
narrativo; os artefatos formatáveis têm dono único. Evita duas cópias divergindo.

## 7. Verificação (cenários de aceitação)

Comandos-skill não têm teste unitário — a verificação é exercitar cada comando num cenário real e
observar o comportamento. Caso de ponta-a-ponta: o próprio **Zion Mermaid Editor** (`docs/index.md`).

1. **Caminho feliz encadeado.** discovery → spike → write → decompose → specify-prompt; cada
   artefato existe e cada Fase 4 dá ✓.
2. **Gate mole dispara e não trava.** `/prd-write` sem `docs/discovery.md` → avisa e pergunta; se
   sim, prossegue.
3. **Detecção de fronteira vazada.** RF com "usar React para…" → Fase 4 aponta a linha e sugere
   mover para `plan.md`, citando `#fronteira`.
4. **Idempotência / revisar.** `/prd-write` com `docs/PRD.md` existente → modo pressionar seção, não
   sobrescreve.
5. **INVEST reprova fatia horizontal.** fatia "só a UI" → aponta falha no "dá demo sozinha?" e
   sugere SPIDR.
6. **Handoff termina o território.** `/prd-specify-prompt` entrega o texto e não dispara `/speckit.*`.

Cada cenário que passar vira evidência observada. Falha → bug no `SKILL.md`, não no processo.

## 8. Fora de escopo (YAGNI)

- Wrappers para o ciclo `/speckit.*` (5b) — os comandos reais já funcionam.
- Arquivo de estado / rastreio de progresso persistente — derivamos dos arquivos.
- Gates duros que bloqueiam — decisão explícita por gate mole.
- Estágio 6 (rastreabilidade viva / commit) — `/git-commit` já cobre; a tabela é injetada no
  decompose.
