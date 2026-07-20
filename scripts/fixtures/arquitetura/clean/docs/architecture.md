# Arquitetura — Produto Fixture

> Fonte da verdade do como/com-quê deste produto (fixture limpa).

## 1. Visão geral

<!-- zion:narrativa-avisos:start -->
_(narrativa em dia)_
<!-- zion:narrativa-avisos:end -->

<!-- zion:narrativa:start adrs=ADR-001 -->
O produto tem um **Recebedor** (entrada de pedidos) e um **Registro** (persistência). O Recebedor
nunca escreve no disco: entrega o pedido ao Registro, dono único do dado gravado.
<!-- zion:narrativa:end -->

## 2. Integrações externas

_(nenhuma integração externa)_

## 3. Decisões estruturantes

<!-- zion:adr-index:start -->
### Persistência
- **[ADR-001 — Banco único](adr/ADR-001-banco-unico.md)**
  fixou: Um banco único.
<!-- zion:adr-index:end -->

## 4. Visão do backlog

<!-- zion:backlog-view:start -->
- `walking-skeleton` — ☐ pendente
<!-- zion:backlog-view:end -->
