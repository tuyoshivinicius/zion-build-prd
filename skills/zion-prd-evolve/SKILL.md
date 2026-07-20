---
name: zion-prd-evolve
description: Ponto de entrada único do dia 2 do harness Zion Build PRD — endereça mudanças pós-release (RF novo, RF alterado/removido, decisão revertida) versionando a PRD (§13 changelog), roteando supersessão de ADR e re-decomposição parcial, e parando nas pontes. Use quando um requisito muda depois da release 1, ou o usuário disser "mudou o escopo", "reverter uma decisão" ou "evoluir a PRD".
argument-hint: "A mudança pós-release em linguagem natural (ex.: \"exportar PNG saiu; entrou exportar SVG\")"
metadata:
  author: zion-build-prd
user-invocable: true
disable-model-invocation: false
---

# zion-prd-evolve — o dia 2 do harness (mudança pós-release)

Ponto de entrada único para mudar um artefato **depois** da release 1: um RF novo, um RF alterado ou
removido, ou uma decisão estruturante revertida. Versiona a PRD (changelog na §13), roteia para os
comandos donos de cada artefato **parando em cada gate**, e termina nas pontes — o ciclo `/speckit.*`
é do usuário. Sequência e fronteira em `references/process-context.md`; regras do dia 2 em
`references/quality-rules.md` `#dia-2`. Contrato de 5 fases; gates aconselham, nunca bloqueiam.

## Cenários canônicos (uma mudança pode combinar mais de um)
- **C1 — RF novo:** requisito que não existia. Toca §6 (RF no épico certo ou épico novo) + §13 +
  re-decomposição parcial do épico + tabela (§12 via trace).
- **C2 — RF alterado ou removido:** requisito muda de significado ou sai de escopo. Toca §6 + §13 +
  specs do épico afetado + tabela; spec já com `spec.md` → contexto de re-specify montado pela ponte.
- **C3 — Decisão revertida:** decisão estruturante caiu. Toca ADR novo que substitui o antigo
  (referência cruzada simétrica) + §8 (restrições) + §13 + aviso de revisar a `constitution` + a
  narrativa da §1 quando a decisão caída a sustentava (o bloco de avisos acusa).

## Fase 0 — Pré-requisito (aconselha)
`docs/PRD.md` deve existir — o dia 2 pressupõe o dia 1. Faltando → avise ("recomendo `/zion-prd-write`
antes") e pare graciosamente.

## Fase 1 — Validar entrada e classificar
O argumento é a descrição da mudança em linguagem natural. Classifique-a em **C1/C2/C3** (pode ser mais
de um). Descrição vaga demais para classificar → **pergunte** em vez de adivinhar (ex.: "essa mudança
cria um requisito novo, altera um existente, ou derruba uma decisão de arquitetura?"). Cuidado com a
decisão que cai **disfarçada de requisito** (parece C2, é C3): se a mudança só se resolve **trocando uma
decisão estruturante já registrada num ADR**, é C3. **Confirme a classificação com o usuário antes de
tocar qualquer arquivo.**

## Fase 2/3 — Plano de toque + execução roteada
Monte e **mostre o plano de toque**: a lista ordenada dos artefatos afetados e o comando dono de cada um.
Execute inline só o que é **barato e local**; para o resto, **pare e delegue com handoff explícito, um
gate por vez** — não encadeie tudo num turno só.

**Inline (você mesmo):**
- **§13 (changelog)** — acrescente uma linha na tabela da §13 da PRD, no formato de `#dia-2`: `Data`,
  `Cenário` (só C1/C2/C3), `Mudança`, `Motivo`, `Artefatos afetados`. O evolve é o dono da escrita do
  changelog.
- **Edição pontual da §6/§8** — o RF novo/alterado na §6 (no épico certo) ou a restrição na §8.

**Delegado (pare em cada gate):**
- **Supersessão de decisão (C3)** → `/zion-adr-new "<título>" --substitui ADR-<n>`: cria o ADR novo com
  `Substitui: ADR-<n>` e marca o antigo `Status: Substituído por ADR-<m>` (referência simétrica).
- **Re-fatiamento do épico afetado (C1/C2)** → `/zion-prd-decompose --epico E<k>`: re-fatia **apenas** o
  épico indicado; specs já implementadas são intocáveis.
- **Narrativa estrutural defasada (C1/C2/C3)** → `/zion-prd-decompose --narrativa`: quando a mudança
  cria/derruba componente ou contrato de topo, ou quando o bloco `zion:narrativa-avisos` do
  `docs/architecture.md` acusa `narrativa-superseded`/`narrativa-defasada`. Revisa **só** a §1–§2,
  sem re-fatiar nada, e nunca sobrescreve a prosa do Autor sem confirmação (ADR-018).
- **Reconciliação da tabela (§12)** → `/zion-prd-trace`: dono único da tabela.
- **Spec já especificada (C2)** → `/zion-prd-specify-prompt` em enquadramento **re-specify**: revê a
  spec existente contra a mudança, com a linha da §13 como contexto.
- **ADR substituído alimentava a `constitution` (C3)** → aconselhe rodar `/zion-prd-constitution-prompt`
  de novo (não edita a `constitution`).

## Fase 4 — Validar saída (aconselha)
Rode os verificadores do `references/` e ecoe o veredito por item — não reverta:

    bash references/check-prd.sh prd docs/PRD.md
    bash references/check-adr.sh docs/adr

`check-prd.sh` confere a §13 (todo `RF-xx`/`ADR-xxx` citado existe, ou a linha o declara "removido";
Cenário só C1/C2/C3) e a §8 (restrição apontando ADR substituído → `restricao-morta`). `check-adr.sh`
confere a **simetria** da supersessão. Scripts ausentes (instalação parcial) → degrade para conferência
em prosa contra `#dia-2`, com aviso — como as demais skills.

## Saída
A PRD versionada (§13), os artefatos afetados atualizados pelos comandos donos e — quando a mudança toca
uma spec já especificada — o prompt de re-specify pronto para o usuário disparar. **PARE nas pontes:** o
ciclo `/speckit.*` é do usuário.
