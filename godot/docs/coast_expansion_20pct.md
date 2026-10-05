# Expansão de 20% e totens — 03/10/2026

Comprimento 11.040 → 13.248 px, exatamente +20%. Quatro ilhas novas com lacunas de 140 px, alturas variando em até 30 px e três plataformas opcionais. Portal em (13010,260). Total: 42 gemas e 19 Ruídozinhos. Entradas livres de pelo menos 160 px nas novas patrulhas.

O checkpoint original foi preservado; quatro marcadores adicionais têm totens SVG próprios: brisa_relay (5170,340), brisa_02 (9340,280), brisa_03 (10820,280), brisa_04 (12240,280). O último está em área livre antes da patrulha.

Totens reutilizam o checkpoint_beacon aprovado da expansão: camadas vetoriais reais, canvas 80 × 112, pivô (29,106), escala (2,2), sem colisão que bloqueie o jogador. Cores/forma mostram estados inativo e ativo. Mastro e base ficam fixos; sinal pulsante respeita flashes reduzidos. Arte primária acompanha somente brisa_01; os demais têm estado independente.

Validação: percurso completo por inputs, apoio dos inimigos ao longo de ciclos, acesso às plataformas opcionais, ativação física dos totens, save, morte/respawn e restauração após recarga. Render SVG dos dois estados conferido em checkpoint_totems_preview.png. Câmera e mar usam comprimento do JSON; parallax mantém escala. Não foi realizada captura em navegador.
