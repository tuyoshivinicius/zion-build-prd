> Backlog de specs verticais — a fila de trabalho do harness. Uma linha por spec; **a ordem das
> linhas é a fila de prioridade** (o walking skeleton na frente). Semeado por `/zion-prd-decompose`
> a partir deste template.
>
> **Colunas de máquina (artefato derivado)** — **Pasta** e **Status** são recomputadas por
> `/zion-prd-trace` (`scripts/trace-backlog.sh`), casando `specs/###-<slug>` ⇔ slug por sufixo.
> **Não edite Pasta/Status à mão.** As colunas humanas (Spec/Demo/Âncora de experiência/RFs/Release)
> você preenche e o script preserva. Preencha `Âncora de experiência` só nas specs que **tocam** a
> superfície de uso (≥1, não toda spec; spec de backend puro deixa em branco). A **primeira tabela**
> deste arquivo é a canônica (dono do script); todo o resto
> (notas, story map, texto livre) é preservado intacto.

| Spec (slug) | Demo (1 frase) | Âncora de experiência | RFs | Release | Pasta | Status |
|-------------|----------------|-----------------------|-----|---------|-------|--------|
| walking-skeleton | _(a demo ponta-a-ponta mínima que prova o pipeline inteiro)_ | _(a experiência que esta spec demonstra, se toca a superfície — senão em branco)_ | RF-xx | R0 | — | ☐ pendente |
| spec-exemplo | _(o que o usuário faz/vê ao final desta spec — o teste INVEST)_ | — | RF-xx, RF-yy | R1 | — | ☐ pendente |

Legenda de status: ☐ pendente · ◐ em especificação · ● implementada.
