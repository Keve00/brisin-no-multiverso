# Revisão do portal e das plataformas — 03/10/2026

O anexo de plataformas mostrou contornos do vento ainda presentes na camada de chão: o filtro anterior retirava somente ciano claro. A nova separação preserva o vento completo numa única camada central. As 16 variantes de piso plano tiveram padding lateral recortado e interrupções da faixa de contato recompostas por colunas vizinhas, sem alongamento. Não mudaram colisões, patrulhas ou coordenadas da fase.

O núcleo do portal gira continuamente, com pulsação discreta e partículas em trajetórias de pixel inteiro. O modo reduzido desacelera o relógio integrado. A entrada usa a mesma textura, escala, pivô e orientação do núcleo existente; acelera gradualmente, atrai o personagem e contrai a abertura no fim. A moldura aprovada permanece fixa. A sequência conserva1,8s, cancelamento e conclusão única.

Validação: percurso completo26/26, patrulhas1811/1811, extensão10/10, lifecycle do portal23/23. Sampler nativo confirma textura, escala e orientação idênticas no início e registra nove poses em `portal_review_samples.json`. `verify_platform_layers.py` verifica extremos e superfície de16 variantes. Revisão visual por render/composição dos SVGs e transforms Godot via Inkscape; não é captura do navegador nem medição de FPS ou áudio audível.
