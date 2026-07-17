> Tabela de rastreabilidade `RF-xx ↔ specs/###-nome`. Uma linha por requisito funcional in-scope.
> Mantida dentro da PRD (`docs/PRD.md`, seção 12).
>
> **Artefato derivado** — regenerada por `/zion-prd-trace` (`scripts/trace-prd.sh`) a partir da §6 da
> PRD e das `specs/*/spec.md`. **Não edite Status/Feature/Spec à mão** (o `trace` os recomputa); só a
> coluna **Release** é preenchida por você e preservada entre reconciliações. Este bloco é apenas a
> forma inicial semeada pelo bootstrap.

| RF | Descrição | Épico | Feature / Spec | Release | Status |
|----|-----------|-------|----------------|---------|--------|
| RF-01 | _(o quê, em uma frase)_ | E1 | `specs/001-nome` | R0 | ☐ pendente |
| RF-02 | _…_ | E1 | `specs/002-nome` | R1 | ☐ pendente |
| RF-xx | _…_ | E_n_ | `specs/###-nome` | R_n_ | ☐ pendente |

Legenda de status: ☐ pendente · ◐ em spec · ● implementada.
