# ADR-015 — Integração instalável com o Spec Kit e architecture.md distribuído

- **Status:** Aceito
- **Data:** 2026-07-18
- **Decisores:** autoria do repo
- **Evidência:** Decisão dada: o Autor escolheu a alternativa A3 no estudo `docs/estudos/integracao-speckit-fonte-canonica.md` (ADR-006, evidência por decisão dada); o design que a formaliza é `docs/superpowers/specs/2026-07-18-integracao-speckit-instalavel-design.md`.

## Contexto

O canon do produto (`docs/prd.md`, `docs/adr/`, backlog) chega ao Spec Kit apenas pelas três
pontes manuais (RF-06/07/08): clarify e implement rodam sem canon, spec nascida fora do fluxo só
aparece quando o Autor lembra do trace, e o reconhecimento canônico depende de colar prompt. Além
disso o Autor definiu (edge 18 do estudo) que sente falta de prosa estrutural com autoridade
própria — um documento de arquitetura do produto que os ADRs pontuais, a constitution e o plan por
feature não acomodam.

## Decisão

Uma skill instaladora idempotente (`zion-speckit-install`) configura o repositório do produto.
Quatro pontos fechados:

1. **Superfície** — a regra mora só no `CLAUDE.md` do produto (agente único, Claude Code), entre
   marcadores versionados `<!-- zion:speckit:v1:start/end -->`; re-rodar substitui só o bloco
   marcado. Nada de patch nos templates de comando do Spec Kit (A4, rejeitada no estudo).
2. **Marcador de origem** — o elo de rastreabilidade formalizado é a linha `**RF cobertos:** RF-xx`
   que o parser de `trace-prd.sh` já reconhece; elo ausente = spec acusada como intraçável pelo
   trace (mecanismo RF-09 existente). Dever de origem advisório — conselho, nunca trava (RN-01,
   ADR-004 não superseded).
3. **architecture.md distribuído** — semeado de `assets/templates/architecture-skeleton.md`
   (análogo ao prd-skeleton, ADR-002): prosa do Autor (§1–§2) nunca tocada por máquina + dois
   blocos derivados (§3 índice de ADRs, §4 visão do backlog) reconciliados só pelo ritual do trace
   (RN-04, zero automação instalada — ADR-005 preservado). Autoridade **advisória** sustentada por
   `check-arquitetura.sh` (padrão E5), com guard de pre-commit **opt-in** — o ADR-010 exportado por
   escolha do Autor; default é não instalar.
4. **Fronteira de donos** — constitution: princípios de repo inteiro; ADRs: decisões pontuais de
   repo inteiro; architecture.md: estrutura e prosa do Autor + índices derivados; plan: o como por
   feature. Um dono por pergunta. Recorte por passo: specify/clarify leem PRD e backlog; plan lê
   ADRs + architecture.md; implement lê plan + constitution.

As pontes RF-06/07/08 seguem como caminho rico (curam o recorte por passo); a regra instalada é a
rede de segurança quando o Autor pula a ponte.

## Consequências

O harness ganha dois scripts distribuídos (`check-arquitetura.sh`, `trace-arquitetura.sh`) com
auto-testes e fixtures pareadas (NFR-04, dentro do orçamento do NFR-01), dois templates novos no
ASSET_MAP e uma skill a mais para manter. O ritual do trace passa a reconciliar também os blocos
derivados do documento; a ponte do plan injeta a prosa estrutural ao lado dos ADRs — specify e
clarify nunca recebem o documento (RN-02). Upgrade do harness que mude o bloco de regras é acusado
por versão de marcador (`regras-defasadas`), resolvido re-rodando a instalação. Cobertura
multi-agente da regra fica fora de escopo (ampliável depois sem quebrar nada).

## Status

Aceito.
