# Mudança pós-release — Painel de Tarefas

Os usuários pediram que a exportação do quadro passe a sair em **vetor** (hoje sai em imagem
rasterizada). Isso muda o RF-06 (exportar imagem). O motor de exportação atual, escolhido na ADR-002,
só produz raster — para entregar vetor teríamos que trocar o motor.
