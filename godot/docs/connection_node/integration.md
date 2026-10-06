# Nó detalhado e revisão de franjas escuras

SVGs com paths reais, estrutura fixa, núcleo pulsante, arcos giratórios, sinal, painéis sequenciais e partículas. Canvas160×224, pivô(80,212), núcleo(80,117), escala uniforme0,7. Arte registrada com a abertura real, mantendo física, pulso, posição de apoio e progresso.

Máscara remove navy e resíduos nos espaços internos; a extração do núcleo exclui azul dos arcos. A revisão global rasterizou44 camadas de luz no Godot. Corrigiu6 recursos com franjas escuras (1837 pixels na primeira auditoria). Auditoria final:44 camadas, zero franjas escuras segundo a máscara de borda; sombras internas permanecem. O export repete a revisão para não reintroduzir contornos escuros após regeneração.

scenery_svg passou em web/mobile, incluindo conexão por pulso, pivô, uniformidade, emissões Offline/Online, pausa e flashes reduzidos. mobile_route passou sem teleporte. portal_transition23 checks/0 falhas. Capturas reais do Godot revisadas. Nenhum teste em Android/iPhone físico nesta rodada.
