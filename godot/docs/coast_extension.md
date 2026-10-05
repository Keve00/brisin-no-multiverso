# Costa estendida — 03/10/2026

Comprimento de 9.600 para 11.040 px (+15%). Três ilhas continuam o percurso, com lacunas de 140 px e variação de altura de 30 px. Portal em (10910,280). Novo checkpoint em (9340,280), antes da extensão, preserva o estado Online.

Quatro patrulhas novas em dois encontros têm entrada livre de pelo menos 150 px e chão plano (16 inimigos ao todo); o portal fica sem patrulha sobreposta. Duas plataformas opcionais (pedra rachada e jangada móvel Online) usam pivôs e assets SVG existentes. Sete novas gemas elevam o total a 32. Coqueiros mantêm escala uniforme maior que o personagem.

Câmera, mar e parallax recebem o comprimento do JSON; não há stretch das texturas. Teste de percurso atravessa a fase por inputs de movimento, pulo e chip até o portal, e testa também plataformas opcionais e o checkpoint novo.

Validação Godot 4.5.1 headless: percurso completo por inputs 26/26; extensão, opcionais e checkpoint 7/7; patrulhas sobre colisões reais durante ciclos de movimento 1319/1319. Nenhum ERROR nos logs. As plataformas opcionais foram baixadas para y210 após conferir a altura de pulo real. Assets SVG existentes preservados; esta revisão não incluiu captura em navegador.
