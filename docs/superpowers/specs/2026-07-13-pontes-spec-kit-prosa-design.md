# Design — Pontes Spec Kit autocontidas em prosa (remoção do `zion-rewrite-prompt`)

> **Data:** 2026-07-13
> **Estágio do harness afetado:** Passo 5 (pontes `constitution` / `specify` / `plan`).
> **Resumo:** As três pontes deixam de delegar ao `zion-rewrite-prompt` e passam a montar,
> cada uma no seu próprio escopo, um prompt em **linguagem natural (prosa)** para o
> `/speckit.*` correspondente — sem impor formato de saída. A skill `zion-rewrite-prompt`
> é removida. Preserva-se o handoff (entrega o comando pronto e **para**) e a fronteira
> o-quê/como.

---

## 1. Problema

As pontes `zion-prd-constitution-prompt`, `zion-prd-specify-prompt` e `zion-prd-plan-prompt`
delegam, na Fase 2/3, ao `zion-rewrite-prompt`, que embrulha o prompt gerado em tags XML
(`<context>`, `<constraints>`, `<instructions>`, `<success_criteria>`). Os guias vivos hoje
mostram literalmente saídas como `/speckit.constitution "<context>…</context><instructions>…"`.

Dois motivos para mudar:

1. **Requisito do usuário:** remover a skill `zion-rewrite-prompt` e fazer cada ponte assumir
   o próprio escopo, sem delegar; e o prompt gerado **não deve impor formato de saída** (nada de
   forçar tags/estrutura do artefato), porque o `/speckit.*` correspondente já define o formato.
2. **Evidência da pesquisa (ver §2):** o esqueleto XML é justamente o que o Spec Kit **não** quer
   na entrada. Manter o XML e remover a skill seria contraditório.

## 2. Pesquisa — boas práticas do GitHub Spec Kit por etapa

Fonte primária: repositório `github/spec-kit` — `README.md`, `spec-driven.md`, os templates de
comando (`templates/commands/{constitution,specify,plan}.md`) e os templates de artefato
(`spec-template.md`, `plan-template.md`, `constitution-template.md`). O site de docs
(`github.github.io/spec-kit`) só resume e não contradiz.

**Achado transversal que sustenta tudo:** cada comando **carrega um template pré-escrito e apenas
preenche placeholders**, preservando ordem de seções e cabeçalhos. O comando é dono da estrutura do
artefato; **o prompt do usuário é conteúdo, não formato**. E **todo exemplo oficial é prosa em
linguagem natural — nenhuma fonte recomenda tags XML** (é o oposto da orientação genérica
Anthropic/OpenAI de prompt estruturado; XML seria escolha de harness, não recomendação do Spec Kit).

Orientação acionável consolidada, por etapa:

### 2.1 `constitution`
- **Propósito da entrada:** fornecer os princípios/valores/inegociáveis do projeto para popular o
  `constitution-template.md`. Roda uma vez (bootstrap).
- **O prompt DEVE carregar:** princípios derivados dos NFRs e restrições (ADRs) da PRD, cada um
  **decidível/testável** (critério objetivo: validador, limiar numérico ou teste) e **rastreável** à
  sua origem; nomear categorias (qualidade, teste, performance, segurança…). *(Exemplo do README:
  "Create principles focused on code quality, testing standards, user experience consistency, and
  performance requirements.")*
- **NÃO deve:** ditar seções/versionamento/layout do `constitution.md` (o template deriva
  `[PRINCIPLE_NAME]`, `CONSTITUTION_VERSION`, governança, Sync Impact Report); princípios genéricos.

### 2.2 `specify`
- **Propósito da entrada:** descrever a feature — o **o-quê e o por-quê** — que o comando transforma
  em spec estruturada.
- **O prompt DEVE carregar:** necessidade do usuário, jornada e **resultado observável**, em prosa;
  RF-xx/ADR como contexto (referência, não requisito). *(Exemplo do README: "Build an application
  that can help me organize my photos in separate photo albums…")*
- **NÃO deve:** citar **stack/linguagem/framework/biblioteca** — o README é explícito ("Do not focus
  on the tech stack at this point") e o `spec-driven.md` reforça (✅ WHAT/WHY ❌ HOW: no tech stack,
  APIs, code structure); nem ditar cabeçalhos do `spec.md`.

### 2.3 `plan`
- **Propósito da entrada:** fornecer o **como** — stack e arquitetura — depois que o `spec.md` existe.
- **O prompt DEVE carregar:** stack, arquitetura, restrições e metas técnicas que realizam o
  `spec.md` **dentro** das decisões dos ADRs confirmados. *(Exemplo do README: "The application uses
  Vite with minimal number of libraries. Use vanilla HTML, CSS, and JavaScript as much as possible.")*
- **NÃO deve:** repetir os requisitos (o comando já carrega o `spec.md` como fonte da verdade);
  reabrir o que um ADR fixou; ditar as seções do `plan.md` (o comando prescreve Summary/Technical
  Context/Constitution Check/… e as saídas das Fases 0/1).

### 2.4 Princípios transversais
- **Prompt = conteúdo, não formato.** Nunca fazer o prompt ditar a estrutura do artefato.
- **Prosa, não XML.** É a convenção demonstrada em todas as fontes oficiais.
- **Fronteira o-quê/por-quê → como é dura e escalonada.** WHAT/WHY em `constitution`/`spec`; HOW só
  no `plan`.

Fontes: `github/spec-kit` (README, `spec-driven.md`, `templates/commands/*`, `templates/*-template.md`).

## 3. Decisão de design

Cada ponte, na Fase 2/3, **monta ela mesma** o prompt em **prosa**, seguindo sua âncora
`#anatomia-*` reescrita — sem delegar ao `zion-rewrite-prompt`, sem tags XML, sem ditar o formato do
artefato. As guardas específicas viram **conteúdo em prosa** dentro do próprio prompt.

Alternativa considerada e descartada: manter o esqueleto XML internamente (só cortando a delegação).
Descartada porque a pesquisa e as restrições do usuário ("não impor formato", "copiável e executável
na skill Spec Kit") apontam para prosa; o XML é justamente o que o Spec Kit não espera.

**Inalterado (preservado de propósito):**
- Contrato de fases 0 (pré-requisito) / 1 (validar entrada) / 4 (validar saída + handoff).
- Guardas por etapa: `specify` = sem-stack + resultado observável; `constitution` = decidível +
  rastreável, sem genérico; `plan` = honrar cada ADR confirmado, não re-decidir.
- **Handoff:** entrega o `/speckit.* "..."` pronto e **PARA** — nenhuma ponte dispara `/speckit.*`.
- Fronteira o-quê/como (a ponte `plan` segue sendo a única que cruza, presa aos ADRs).

## 4. Arquivos afetados

| Arquivo | Mudança |
|---|---|
| `assets/quality-rules.md` (canônico) | Reescrever as 3 âncoras `#anatomia-*`: remover moldura XML e "auto-delegar"; descrever o **conteúdo** de cada prompt (guardas em prosa) + nota do idioma Spec Kit ("conteúdo, não formato; prosa, não XML"). `#criterios-de-conclusao` já é baseado em conteúdo → mantém. |
| `skills/zion-prd-constitution-prompt/SKILL.md` | Fase 2/3: remover "Invoque `zion-rewrite-prompt`"; passar a "montar você mesmo o prompt em prosa" seguindo `#anatomia-constitution`. Fases 0/1/4 + PARE preservadas. |
| `skills/zion-prd-specify-prompt/SKILL.md` | Idem, mantendo guarda sem-stack + resultado observável. |
| `skills/zion-prd-plan-prompt/SKILL.md` | Idem, mantendo honrar-ADRs. |
| `skills/zion-rewrite-prompt/` | **Remover** a skill inteira. |
| `README.md` | Remover a linha da tabela de **Dependências** que cita `zion-rewrite-prompt` (a tabela de skills não a lista). Nenhuma contagem numérica no README. |
| `docs/como-usar.md` | Coluna "Depende" (linhas ~41–43) troca `zion-rewrite-prompt` por "própria (prosa)"; seções das pontes (~199/231/262) trocam exemplos XML por prosa; acertar a contagem de skills (verificar que fica **8**). |
| `docs/guia-prd-para-spec-kit.md` | P5b (~193–200) deixa de tratar `zion-rewrite-prompt` como "peça central"; menção do plan e a linha da tabela de skills (~272) reescritas para a montagem em prosa autocontida. |
| `scripts/asset-map.sh` | **Sem mudança** — `zion-rewrite-prompt` não tem `references/`, não está no mapa. |
| `docs/superpowers/specs|plans` (datados) | **Intactos** — registro histórico fiel (decisão do usuário: só guias vivos). |

Após editar `assets/quality-rules.md`: rodar `./scripts/sync-assets.sh` (regenera os `references/`
das 7 skills consumidoras) e `./scripts/check-assets.sh` (falha se houver drift).

## 5. Exemplos do prompt gerado (novo formato — prosa)

**constitution:**
```text
/speckit.constitution "Crie princípios derivados destes NFRs e restrições da PRD: NFR-01
(render < 100ms ao digitar), NFR-02 (persistência sobrevive a reload); ADR-001 (motor de
render), ADR-003 (persistência local). Cada princípio deve ser decidível — com um critério
objetivo (validador, limiar numérico ou teste) — e rastreável ao NFR ou ADR de origem.
Evite princípios genéricos como 'código limpo' ou 'boa cobertura'."
```

**specify:**
```text
/speckit.specify "O usuário abre o editor, digita um diagrama mermaid e vê a prévia renderizar
ao digitar; ao recarregar a página, o diagrama e a prévia continuam lá. Contexto: RF-01
(prévia ao digitar), RF-05 (persistência entre sessões); vale a restrição da ADR-003.
Não inclua linguagem, framework ou bibliotecas — a stack fica no plan."
```

**plan:**
```text
/speckit.plan "Realize o spec.md desta feature (prévia ao digitar + persistência entre sessões)
honrando estas decisões já fechadas, sem reabri-las: ADR-001 (motor de render escolhido),
ADR-003 (persistência local escolhida). Descreva a stack, a arquitetura e as restrições técnicas
que decorrem dessas decisões e realizam o resultado observável do spec.md."
```

## 6. Critérios de sucesso / verificação

- `grep -rn "zion-rewrite-prompt\|rewrite-prompt"` em `skills/`, `assets/`, `README.md`,
  `docs/como-usar.md`, `docs/guia-prd-para-spec-kit.md`, `scripts/` → **zero** ocorrências.
- `find skills -maxdepth 1 -mindepth 1 -type d | wc -l` → **8** (sem `zion-rewrite-prompt`).
- Cada uma das 3 pontes: sem "Invoque `zion-rewrite-prompt`"; contém "PARE AQUI"; monta prosa própria.
- Nenhum exemplo de prompt gerado (skills + guias vivos) usa tags XML nem dita a estrutura do artefato.
- `./scripts/check-assets.sh` → "sem drift".
- Os `docs/superpowers/specs|plans` datados permanecem inalterados.
