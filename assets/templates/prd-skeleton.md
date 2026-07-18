# PRD — <NOME DO PRODUTO>

> Template do Passo 3. Preencha seção a seção com `superpowers:brainstorming`, a partir de
> `docs/discovery.md` + ADRs. Se começar a escrever critérios de aceite, telas ou stack, parou no
> lugar errado → isso vive no `spec.md`/`plan.md` da feature.

## 1. Visão
Uma frase: para <persona>, que <problema>, o <produto> é um <categoria> que <benefício central>.

## 2. Objetivos & métricas
Objetivos de negócio/produto, cada um com uma métrica numérica (ex.: "reduzir X de A para B").

## 3. Personas
1–2 personas nomeadas (do discovery). Sem detalhamento de jornada — isso é do story map (P4).

## 4. Escopo (in / out)
- **Faz (in):** capacidades desta release.
- **Não faz (out):** escopo negativo explícito (costuma valer mais que o positivo).

## 5. Regras de negócio (RN-xx)
`RN-01`, `RN-02`… — restrições de domínio invariáveis. Uma frase cada.

## 6. Requisitos funcionais por épico (RF-xx)
Agrupados por épico. Uma frase por `RF-xx` — o-quê/por-quê, NUNCA como.
- **Épico E1 — <nome>:** `RF-01` …; `RF-02` …
- **Épico E2 — <nome>:** `RF-03` …

## 7. NFRs (com números)
Superfície de uso: não

> `sim/não` carregado do `docs/discovery.md`. Vira `sim` quando o produto opera uma superfície de
> uso (tela, CLI, API que alguém maneja). Quando `sim`, inclua ≥1 NFR de experiência tagueado e
> machine-legível — `NFR-0x` (experiência): a tarefa-núcleo é concluída em ≤N passos. É NFR
> mensurável, nunca tela (veja `quality-rules.md` `#fronteira`).

Requisitos não-funcionais mensuráveis (performance, disponibilidade, segurança) — sempre com número.

## 8. Restrições (das ADRs)
Decisões estruturantes já fechadas nos ADRs (P2), que limitam as specs. Aponte para `docs/adr/ADR-00x`.

## 9. Glossário
Termos do domínio com definição única, para specs não divergirem.

## 10. Riscos
Riscos de produto/técnicos e mitigação prevista.

## 11. Questões abertas
`[NEEDS CLARIFICATION]` que ainda não são bloqueantes — resolvidos até o gate `/speckit.clarify` (P5b).

## 12. Rastreabilidade
Tabela de rastreabilidade RF → épico → spec, injetada por `/zion-prd-decompose` e mantida dentro desta PRD.

## 13. Histórico de mudanças
> Vazia no dia 1. Preenchida por `/zion-prd-evolve` a partir da primeira mudança pós-release — uma linha
> por mudança. Regras do formato em `quality-rules.md` `#dia-2`; edição manual continua possível.

| Data | Cenário | Mudança | Motivo | Artefatos afetados |
|------|---------|---------|--------|--------------------|
