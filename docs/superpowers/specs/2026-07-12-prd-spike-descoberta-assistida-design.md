# Spec — Estágio 2 (`/zion-prd-spike`) com descoberta assistida das decisões estruturantes

> **Data:** 2026-07-12
> **Estado:** desenho refinado no brainstorming, pronto para plano de implementação.
> **Escopo:** apenas o Estágio 2 do harness (`/zion-prd-spike`). Não redesenha os outros estágios.
> **Documentos-fonte:** `docs/superpowers/specs/2026-07-11-harness-prd-spec-kit-design.md`
> (spec do harness) · `.claude/skills/zion-prd-spike/SKILL.md` (contrato atual) ·
> `docs/como-usar-o-harness-prd.md` (guia prático).

## 1. Problema

Hoje a **Fase 1** do `/zion-prd-spike` **exige** que o usuário nomeie as 2–3 decisões
estruturantes (`zion-prd-spike/SKILL.md`, Fase 1: *"O usuário deve nomear 2–3 decisões
estruturantes… aplique o filtro: 'isso muda a PRD inteira?'"*). Na prática isso bloqueia
quem sabe descrever o produto (já tem `docs/discovery.md`) mas ainda **não enxerga** quais
eixos técnicos reorganizam a PRD inteira. A descoberta dessas decisões fica fora do harness,
justamente onde o processo deveria ajudar.

**Objetivo:** tornar a Fase 1 **de mão dupla** — a IA lê o `docs/discovery.md` e *propõe* os
candidatos quando o usuário não os traz, e *aceita* a lista pronta quando o usuário já a
conhece — sem tornar nenhum caminho obrigatório.

**Fato-âncora que autoriza a proposta técnica aqui:** o Estágio 2 é o **lar do "como"**
(guia prático: *"Aqui stack pode e deve aparecer — o ADR é o lar do 'como'"*). Inferir eixos
técnicos nesta fase **não vaza a fronteira o-quê/como** — ela só é guardada em
discovery/PRD/specify, não no spike.

## 2. Invariantes preservados

A mudança respeita os três invariantes do harness (spec 2026-07-11, §4):

1. **Contrato de 5 fases.** Só a Fase 1 muda (reformulada, não substituída); nenhuma 6ª fase.
   A simetria com os outros `/prd-*` se mantém — a Fase 1 continua sendo o gate de "entrada".
2. **Fronteira o-quê/como.** Propor eixos técnicos é legítimo no lar do "como"; o stack
   concreto continua nascendo no ADR (Fases 2/3), sem vazar para `discovery.md` nem PRD.
3. **Gate aconselha, nunca bloqueia.** A guarda de suficiência e a convergência apontam e
   sugerem, mas a lista que o usuário confirma é sempre a que vale.

Um quarto princípio, exigido pelo refinamento: **mão dupla como espectro** — a origem das
decisões não é um interruptor (usuário informa ⊕ IA descobre), e sim um contínuo A↔C↔B.

## 3. Desenho — Fase 1 reformulada

**Fase 1 · Levantar e validar as decisões estruturantes (aconselha).** Substitui a atual
"Validar entrada bruta". O `argument-hint` do `SKILL.md` passa de obrigatório para
**opcional** ("as 2–3 decisões estruturantes, se você já as conhece"). A fase tem quatro
blocos.

### 3.1 Detecção de origem (espectro A↔C↔B)

A IA classifica a entrada pelo número de decisões que o usuário trouxe no argumento:

- **Caminho A — 2–3 decisões dadas.** A IA **não propõe**. Valida cada uma pelo filtro
  *"isso muda a PRD inteira?"*. Se vier uma lista longa de dúvidas pequenas, sugere
  consolidar nas 2–3 realmente estruturantes (comportamento atual preservado).
- **Caminho C — 1–2 decisões dadas (híbrido).** A IA valida as dadas (as trata como
  **fixas**) e **propõe só as faltantes** até fechar 2–3, cada complemento ancorado num
  trecho real do `discovery.md`.
- **Caminho B — 0 decisões dadas.** A IA **propõe as 2–3**, cada uma ancorada.

Em todos os caminhos, cada candidato — dado pelo usuário ou proposto pela IA — passa pelo
filtro *"isso muda a PRD inteira?"* antes de entrar na lista. Candidato que não passa é
descartado ou consolidado, não listado.

### 3.2 Guarda de suficiência do discovery (só em B e C, antes de propor)

Antes de propor, a IA avalia se o `docs/discovery.md` sustenta uma inferência confiável.
O discovery tem três peças (spec do harness: Visão de 1 frase · Persona nomeada · quadro
Faz/Não faz). Se uma peça necessária faltar ou for vaga (ex.: sem quadro Faz/Não faz não há
como isolar uma fronteira de integração), a IA **não fabrica** candidatos para preencher a
cota. Em vez disso:

1. **Aponta qual peça falta e por quê** ela trava a inferência.
2. **Propõe só o(s) candidato(s)** que o texto efetivamente sustenta.
3. **Pede a peça faltante** ao usuário **ou** sugere voltar ao `/zion-prd-discovery` para
   enriquecer o discovery.

É um **gate mole**: não bloqueia. O usuário pode fornecer a peça na hora, mandar a IA propor
mesmo assim, ou seguir com menos de 2–3 decisões — a decisão é dele.

### 3.3 Apresentação enxuta (B/C)

Nos caminhos B e C, a IA entrega as 2–3 (ou o complemento faltante) **já como recomendação
direta**, cada uma com **uma linha de justificativa ancorada** num trecho do discovery
(ex.: um "não faz" que empurra uma fronteira; um requisito de sincronização citado na
Visão). Sem shortlist longa a cortar — prioriza velocidade e baixo ruído. O senso crítico é
exercido na convergência (§3.4), não numa apresentação verbosa.

Formato de apresentação (ilustrativo, não normativo):

```
Proponho estas 3 decisões estruturantes:
 1. <eixo> — <justificativa ancorada no discovery>
 2. <eixo> — <justificativa ancorada no discovery>
 3. <eixo> — <justificativa ancorada no discovery>
 → Confirma / edita / substitui?
```

### 3.4 Convergência (gate aconselha)

Em todos os caminhos, a IA apresenta a lista final e pede ao usuário para:

- **Confirmar** a lista como está;
- **Editar** — trocar uma das decisões;
- **Substituir** — rejeitar todas e ditar as suas.

Se a lista confirmada for fraca (nenhuma passa no filtro, virou 4 dúvidas menores, ou ficou
com **1 decisão só**), a IA **aponta e sugere** — mas **a lista confirmada pelo usuário é a
que vale**. Nunca bloqueia.

### 3.5 Saída da Fase 1

Uma lista de 2–3 decisões estruturantes confirmadas — **mesmo formato de hoje**. Alimenta as
Fases 2/3 (`deep-research` por decisão → `zion-adr-new`) sem qualquer mudança a jusante.

## 4. Fluxo das fases (mini-mapa)

```
Fase 0 · Pré-requisito (aconselha) ..... discovery.md existe? senão avisa; não bloqueia
Fase 1 · Levantar + validar decisões (aconselha)  ◀── ÚNICA MUDANÇA
    ├─ A · usuário deu 2–3 → só valida (filtro "muda a PRD inteira?")
    ├─ C · usuário deu 1–2 → valida as dadas (fixas) + IA propõe só as faltantes
    └─ B · usuário deu 0  → IA propõe as 2–3
         └─(B/C) guarda de suficiência: discovery magro → aponta a lacuna,
                 propõe só o sustentável, pede a peça faltante OU sugere /zion-prd-discovery
    └▶ Convergência · confirma / edita / substitui   (gate aconselha; lista fraca → aponta)
Fase 2/3 · deep-research (trade-offs) → zion-adr-new por decisão ....... (inalterado)
Fase 4 · Validar saída (aconselha) — cada decisão tem ADR c/ spike real  (inalterado)
Saída · docs/adr/ADR-00x-*.md → restrições da PRD §8 + constitution  (inalterado)
```

## 5. Artefatos afetados

- **`.claude/skills/zion-prd-spike/SKILL.md`** — único arquivo com mudança real:
  - `argument-hint` de obrigatório → opcional;
  - texto da **Fase 1** reescrito para os quatro blocos (§3.1–§3.4).
- **`docs/discovery.md`** — ganha um leitor a mais (consumo em B/C; nenhuma escrita).
- **`.specify/prd/quality-rules.md`** — a Fase 4 e o `#criterios-de-conclusao` do spike
  **não mudam**. Opcional: uma nota curta reafirmando o filtro *"muda a PRD inteira?"* como
  âncora compartilhada; não é pré-requisito da mudança.
- **A jusante (Fases 2/3, 4; ADRs; §8 da PRD; constitution)** — inalterado, porque a saída
  da Fase 1 mantém o formato.
- **Nenhum arquivo novo.** Nenhum arquivo de estado (o design segue sem-estado).

## 6. Estratégias consideradas e decisão

O refinamento fechou três pontos abertos da E1 original (spec 2026-07-11 e plano
`role-voc-um-snappy-glacier.md`):

| Ponto | Opções pesadas | Escolha | Motivo |
|---|---|---|---|
| Caso híbrido (usuário traz 1–2) | Cair no B (repropõe tudo) · Cair no A (não completa) · **Caminho C explícito** | **Caminho C** | Preserva o que o usuário trouxe e completa só o que falta; torna a mão dupla um espectro sem reintroduzir ancoragem sobre a decisão dele. |
| Discovery magro | Propor mesmo assim (baixa confiança) · Forçar enriquecer (gate duro) · **Declarar a lacuna e pedir** | **Declarar e pedir** | Não fabrica eixos fracos (protege os ADRs), e mantém o gate mole — o usuário decide seguir. |
| Apresentação (anti-ancoragem) | Hipótese refutável · Shortlist longa a cortar · **Recomendação direta enxuta** | **Recomendação direta** | Prioriza velocidade e baixo ruído; o senso crítico é exercido na convergência (confirma/edita/substitui), não numa apresentação verbosa. |

## 7. Verificação (cenários de aceitação)

Como os demais comandos-skill, a verificação é exercitar a Fase 1 em cenários reais e
observar o comportamento (caso ponta-a-ponta: o próprio Zion Mermaid Editor).

1. **Caminho A (usuário informa).** Usuário passa 3 decisões → IA só valida, não propõe;
   segue para Fases 2/3.
2. **Caminho B (IA descobre).** `/zion-prd-spike` sem argumento, com discovery rico → IA propõe
   3 decisões ancoradas em trechos do discovery e abre a convergência.
3. **Caminho C (híbrido).** Usuário passa 1 decisão → IA a mantém fixa e propõe só 1–2
   faltantes; total fecha em 2–3.
4. **Guarda de suficiência.** Discovery sem quadro Faz/Não faz → IA aponta a lacuna, propõe
   só o sustentável, pede a peça faltante ou sugere `/zion-prd-discovery`; **não bloqueia**.
5. **Convergência com lista fraca.** Usuário substitui por 1 dúvida menor → IA aponta que
   não passa no filtro e sugere, mas aceita a lista confirmada.
6. **Fronteira intacta.** As decisões propostas descrevem eixos; o stack concreto só aparece
   no ADR (Fase 2/3), não vaza para discovery nem PRD.
7. **Downstream inalterado.** A saída da Fase 1 tem o mesmo formato → Fases 2/3 e 4 rodam
   como antes.

Cada cenário que passar vira evidência observada. Falha → bug no `SKILL.md`, não no processo.

## 8. Fora de escopo (YAGNI)

- Redesenho de qualquer outro estágio (`zion-prd-discovery`, `zion-prd-write`, `zion-prd-decompose`,
  `zion-prd-specify-prompt`).
- Catálogo fixo de eixos estruturantes em `quality-rules.md` (estratégia E2 descartada:
  engessa e cria um novo dono de arquivo para manter).
- Nova fase dedicada de descoberta + `deep-research` de varredura antes do filtro
  (estratégia E3 descartada: inverte o funil, duplica a `deep-research` da Fase 2/3 e quebra
  a simetria de 5 fases).
- Qualquer gate duro que bloqueie o avanço.
