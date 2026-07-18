# Estudo — exportar o consolidado do painel

## Contexto

A gerente de projetos perde tempo consolidando status à mão fora do painel (prd.md §1). O painel
atual usa typescript por decisão registrada (ADR-001 do projeto). Candidato: permitir que a
gerente exporte o andamento consolidado para compartilhar com a diretoria.

## Edge cases e incertezas

- Tarefas sem responsável entram no consolidado? **(só o humano responde)**
- A exportação respeita o filtro ativo ou sempre o quadro inteiro?

## Alternativas

1. **Não fazer** — a gerente segue consolidando à mão. Prós: custo zero. Contras: a dor da
   consolidação manual permanece. ADRs tocados: nenhum.
2. **Exportar o consolidado** — a gerente gera um arquivo com o andamento agregado e compartilha.
   Prós: resolve a dor central. Contras: mais uma superfície a manter. ADRs tocados: nenhum.
3. **Visão somente-leitura para a diretoria** — a diretoria acompanha o andamento ao vivo. Prós:
   elimina o compartilhamento manual. Contras: exige rever a decisão de acesso único — supersessão
   do ADR-002 do projeto declarada como custo.

## ROI

| Alternativa | Impacto (1–5) | Esforço (1–5, invertido) | Risco (1–5, invertido) | ROI |
|---|---|---|---|---|
| Exportar o consolidado | 4 | 4 | 5 | 4,3 |
| Não fazer | 1 | 5 | 5 | 3,7 |
| Visão somente-leitura | 5 | 2 | 2 | 3,0 |

Justificativa: exportar entrega o valor central com pouco esforço e é reversível; a visão ao vivo
tem o maior impacto mas carrega a supersessão do ADR-002 como custo e o maior esforço.

## Recomendação

Recomendação **não vinculante**: exportar o consolidado — maior ROI, sem tocar ADR vigente. A
decisão é do autor.

## Próximo passo sugerido

Se aprovado, rodar `/zion-prd-discovery` com a alternativa escolhida (e `/zion-prd-spike` se
houver decisão estruturante nova).
