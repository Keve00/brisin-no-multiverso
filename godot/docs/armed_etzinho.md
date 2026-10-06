# ETzinho armado — integração aprovada

A referência `tools/reference_art/cosmic/etzinho-armed-approved.png` foi convertida em SVGs com paths reais. `tools/build_armed_etzinho.py` gera corpo, braço/arma, lampejo e sete estados; a regeneração geral chama esse gerador ao final.

Canvas128×128, pés(64,112), altura100px. Ombro(74,80), muzzle(114,73); escala uniforme e espelhamento no motor. Braço e arma acompanham a mira por junta; recuo finito250ms. Dano e derrota usam o corpo inteiro com arma para impedir camada solta. O pulso interrompe ataque, mira e flash.

Verificação: Godot4.5.1 import/export sem erros; alien_attack22 checks por versão; cosmic_animation583 checks por versão; mobile_input120 checks; mobile_route completou o percurso sem teleporte. Capturas reais OpenGL dos sete estados, ambos os sentidos e frames0/2/4 revisadas. Carregadores, WASM e pausa de áudio passaram. A revisão das capturas corrigiu o recorte da coxa e reservou as cores laranja/ciano pequenas durante quantização.

Não houve teste em aparelho Android/iPhone físico nesta rodada.
