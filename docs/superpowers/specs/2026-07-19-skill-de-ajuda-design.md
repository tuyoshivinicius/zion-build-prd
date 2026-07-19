# Design — `/zion-prd-ajuda`, skill de ajuda de bolso

- **Data:** 2026-07-19
- **Origem:** `docs/estudos/skill-de-ajuda.md`, alternativa **B** (ROI 4.00)
- **Estado:** design validado, pronto para plano

## Problema

O iniciante do Zion Build PRD tira dúvidas colando à mão um prompt one-shot que assume o papel de
heavy user do harness. O prompt funciona, mas não viaja com a instalação, depende de o usuário já
saber que ele existe, e afiná-lo exige re-colar a versão nova em todo lugar. As duas dores são o
**atrito de encontrar e colar** e a **descoberta**.

A alternativa escolhida promove a prática a skill do próprio harness, com grounding nas `SKILL.md`
das skills irmãs — que já viajam no mesmo pacote — em vez de cópias novas do canon.

## Verificação prévia (questões 3 e 4 do estudo)

O estudo condicionava a recomendação a confirmar que o caminho de instalação é descobrível nos dois
canais; se não fosse, B degradaria para D. **Confirmado a favor de B:**

- O Claude Code informa à skill o seu diretório-base na invocação (`Base directory for this
  skill: …`). Não é preciso descobrir nada por heurística.
- Canal plugin: as skills ficam lado a lado em
  `~/.claude/plugins/cache/zion-build-prd/zion-build-prd/<versão>/skills/zion-*/` (verificado em
  disco).
- Canal skills.sh: lado a lado em `~/.claude/skills/<nome>/` (verificado em disco).

Logo `../<nome>/SKILL.md` resolve nos dois canais.

Achado colateral que corrige uma premissa do estudo: no canal plugin o repositório inteiro é
clonado no cache, então `docs/` **está fisicamente presente** ali. No canal skills.sh não está.
`docs/guias/` segue fora de cogitação como fonte — mas por **assimetria entre canais**, não por
ausência.

## Escopo

**Responde:** dúvidas sobre o harness (estágios, comandos, artefatos, armadilhas) e sobre a costura
com o Spec Kit, incluindo o ciclo `specify → … → implement`.

**Não faz:** não lê nenhum arquivo do projeto do usuário — nem `docs/prd.md`, nem `docs/adr/`, nem
`docs/backlog.md`. Não grava artefato algum. A alternativa C (ajuda situada, que lê o estado do
projeto) fica registrada como evolução possível depois que esta provar uso, não como ponto de
partida.

### Guardas

Quatro, todas herdadas do canon:

| Guarda | Origem | Comportamento |
|---|---|---|
| Não executa | `RN-01`, ADR-004 | Tarefa disfarçada ("escreve minha §6") é roteada ao comando dono, e a ajuda para ali |
| Não opina em stack | `RN-02` | Pergunta de tecnologia vira roteamento para `/zion-prd-spike` + `/zion-adr-new`, sem veredito |
| Não reabre ADR | ADR-011, `architecture.md` §2 | Explica a decisão vigente e roteia para supersessão |
| Não afirma sem fonte | questões 12 e 13 do estudo | Toda afirmação carrega o arquivo de onde veio; sem fonte, a resposta é "não sei" |

### Modo interno × distribuído

A skill é **idêntica nos dois modos**. Diferente do ADR-013, aqui nada muda: o dev do harness é
público legítimo da mesma resposta. Não há marcador de repo-harness a ler nem ramo a manter.

## Grounding

Duas camadas, nesta ordem:

1. **Frontmatter de todas as irmãs** (`name` + `description`), lido de `../<nome>/SKILL.md`. Barato,
   e produz a **lista fechada de comandos válidos daquela instalação** — a mitigação real da
   alucinação: a ajuda só cita comando que acabou de ler no disco.
2. **Corpo da `SKILL.md`**, aberto sob demanda, só da(s) irmã(s) que a dúvida toca.

Duas referências derivadas viajam em `references/`:

- `process-context.md` — a sequência dos estágios (fonte única já existente).
- `speckit-map.md` — **fonte nova**: uma página com o que cada `/speckit.*` faz, entrada, saída, e
  onde o harness entra e sai do ciclo.

O grounding é **vivo**, não cópia congelada do canon: a resposta reflete a versão instalada por
construção. Isso dissolve a questão 2 do estudo — não há carimbo de versão a declarar porque não há
cópia envelhecida para desmentir. A exceção honesta é o `speckit-map.md`, que envelhece contra o
upstream do Spec Kit e não contra o harness; por isso é fonte única auditável e afinável num lugar
só (`RN-05`), em vez de prosa presa dentro de uma skill.

## Contrato de fases

### Fase 0 — Triagem

Classifica a dúvida em quatro rotas; a rota decide tudo que vem depois.

| Rota | Exemplo | O que acontece |
|---|---|---|
| Estágio | "quando eu rodo o spike?" | Responde, ancorado na `SKILL.md` dona |
| Costura / Spec Kit | "o que a ponte do plan entrega?" | Responde com `speckit-map.md` + `SKILL.md` das pontes |
| Tarefa disfarçada | "escreve minha §6" | Roteia ao comando dono e **para** |
| Fora de escopo | "meu RF-03 está bom?" | Declina, explica a fronteira, roteia |

### Fase 1 — Grounding

Frontmatter de todas as irmãs, sempre. Corpo e referências conforme a rota da Fase 0.

### Fase 2 — Resposta em molde fixo

Quatro blocos, nesta ordem:

1. **Onde isso cai** — o estágio da jornada a que a dúvida pertence.
2. **O comando que resolve** — sempre da lista fechada lida na Fase 1.
3. **A armadilha** — o erro comum daquele ponto.
4. **Fonte** — por afirmação. Quando falta fonte, o bloco vira "não sei — isso não está no que eu
   leio", sem preencher com plausibilidade.

### Fase 3 — Próximo passo

Um passo concreto, mais o eco das guardas que se aplicaram ("não vou escrever a seção por você —
quem faz isso é `/zion-prd-write`").

O molde fixo não é formalismo: é o que dá à camada de julgamento algo comparável. Uma fixture
pergunta "como eu começo?" e a resposta esperada é verificável bloco a bloco — estágio certo,
comando existente, fonte real — em vez de julgada por impressão geral.

## Ativação

- `user-invocable: true`
- `disable-model-invocation: false`
- `description` que **exige menção explícita** ao harness, a um estágio ou a um comando `zion-*`.

Dúvida solta de processo, sem essa menção, não casa — é o que ataca a descoberta (questão 17) sem
sequestrar turno das irmãs (questão 18).

## Verificação

**O verificável não é a resposta, é o envelhecimento.** Entra como **C8** no `check-canon.sh`, ao
lado de C1 e C2, que já têm a mesma forma:

- toda skill em `skills/` — exceto a própria ajuda — é citada na `SKILL.md` da ajuda; skill nova sem
  entrada na ajuda **bloqueia o commit**;
- todo comando `/zion-*` citado pela ajuda existe em `skills/` — citação fantasma bloqueia.

Se a ajuda não estiver instalada (`skills/zion-prd-ajuda/SKILL.md` ausente), C8 não acusa nada:
é a mesma tolerância que C5 dá a um repo sem `docs/adr/`.

Isso resolve a questão 22 por máquina em vez de por disciplina: quem adicionar a 14ª skill é parado
no pre-commit. `NFR-04` fica preservado **sem script novo** — o auto-teste é o
`test-check-canon.sh` existente, com um caso de fixture a mais. Nenhuma linha nova na §3 do
`architecture.md`, nenhuma entrada no `eval.sh`.

A exceção ao padrão do épico E5 encolhe para a verdade trivial: **não há check de saída porque não
há saída.** A qualidade da resposta é avaliada só na camada de julgamento (ADR-008), com fixtures de
pergunta → resposta esperada conferidas contra o molde da Fase 2, no roteiro de
`docs/guias/avaliacao-harness.md`.

## Decisão estruturante (ADR novo)

**Um ADR só:** skill de ajuda conversacional — grounding vivo nas `SKILL.md` irmãs, sem artefato
gravado, avaliada só na camada de julgamento, com o envelhecimento das citações cobrado por
`check-canon.sh`.

Grounding vivo e ausência de verificador de saída são a mesma decisão vista de dois lados: é
justamente por não gravar nada que a skill pode se dar ao luxo de ler as irmãs em runtime. Separar
em dois ADRs criaria duas peças que se citam mutuamente sem se sustentar sozinhas.

Nenhum ADR vigente é revertido — não há supersessão neste trabalho. ADR-003 (prefixo `zion-`) e
ADR-004 (aconselha, não bloqueia) são honrados, não tocados.

## Canonização (mesmo commit — `architecture.md` §5)

| Mudança | Reflete em |
|---|---|
| Skill nova | **Épico E7 novo — Ajuda e orientação** + `RF-19` na §6 e linha na §12 de `docs/prd.md` |
| Fonte nova `assets/speckit-map.md` | `ASSET_MAP` (`scripts/asset-map.sh`) + §4 de `docs/architecture.md` |
| Decisão estruturante | ADR novo em `docs/adr/` (via `/zion-adr-new`) + índice §2 de `docs/architecture.md` |
| Regra C8 | `scripts/check-canon.sh` + caso de fixture no `test-check-canon.sh` |
| Natureza do artefato | §6 de `docs/architecture.md`: a ajuda é **Distribuído** |
| Histórico | Linha no §13 de `docs/prd.md`, cenário C1 |

A ajuda ganha épico próprio (E7) porque é **transversal** à jornada, não um passo dela: não tem
entrada, saída nem lugar na sequência. O épico também abre lugar legítimo para a evolução C (ajuda
situada) no futuro, sem forçar E1.

## Entregáveis

1. `skills/zion-prd-ajuda/SKILL.md` — as quatro fases, as guardas, a lista de rotas.
2. `assets/speckit-map.md` — fonte nova, mais entrada no `ASSET_MAP` e sync para
   `skills/zion-prd-ajuda/references/`.
3. `scripts/check-canon.sh` — regra C8, e fixture nova no `test-check-canon.sh`.
4. `docs/adr/ADR-016-*.md` — a decisão estruturante acima.
5. Canonização: `docs/prd.md` (§6 épico E7 + `RF-19`, §12, §13) e `docs/architecture.md` (§2, §4,
   §6).
6. Fixtures de julgamento da ajuda no roteiro de `docs/guias/avaliacao-harness.md`.

## Fora de escopo

- Ler o estado do projeto do usuário (alternativa C).
- Distribuir `docs/guias/` como fonte única (alternativa D e questão 5 do estudo).
- Verificador mecânico da resposta em runtime.
- Carimbo de versão na resposta (dissolvido pelo grounding vivo).
