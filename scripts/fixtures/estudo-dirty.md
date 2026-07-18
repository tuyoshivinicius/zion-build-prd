# Estudo — trocar o quadro de tarefas

## 1. Contexto

O time quer um quadro novo porque o atual é lento.

## 2. Edge cases e incertezas

- O que acontece com as tarefas arquivadas?

## 3. Alternativas

1. **Reescrever o quadro com react** — prós: moderno. Contras: reescrita grande.
2. **Otimizar o quadro atual** — prós: menor risco. Contras: teto de ganho.

## 4. ROI

| Alternativa | Impacto | Esforço | Risco | ROI |
|---|---|---|---|---|
| Reescrever (cache em redis) | 4 | 1 | 1 | 2,0 |
| Otimizar o atual | 3 | 4 | 4 | 3,7 |

## 6. Próximo passo sugerido

Se aprovado, rodar `/zion-prd-discovery` com a alternativa escolhida.
