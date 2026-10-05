# Gesto SVG do chip

O gesto é modular: 64 corpos SVG mantêm os frames das pernas de walk/run/jump;
6 SVGs de mão, ligados ao mesmo ombro, fazem soltura, avanço e retorno em 0,30 s.
Corpo e mão usam canvas 144 × 128 e o mesmo centro do sprite atual; pés de fonte
72,120. Escala base 1:1, sem mudança de colisão, velocidade ou alcance do chip.
A paleta e rig são os do menu aprovado, obtidos do mesmo walk.png original.

O primeiro frame solta o chip imediatamente e os seguintes fazem follow-through;
a recarga de 0,35 s permanece. Ambas as camadas espelham a direção do disparo.
Ao terminar, sprites normais retornam preservando o frame de locomoção.
Pausa congela; respawn/portal removem a mão. SVGs são geometria real; Godot controla
os frames, sem SMIL. Gerador: tools/build_chip_gesture.py.

A primeira extração deixou pernas desconectadas e retirou tons marrons claros.
Corrigimos a classificação pela paleta e a ligação dos quadris antes da integração.
Prancha composta revisada: qa/chip_gesture_contact_sheet.png. Revisão por imagem
renderizada e testes headless, sem alegação de revisão no navegador.

Dica abaixo do HUD: [F] SOLTA CHIPS. Disparos de longo alcance são ensinados
apenas para alvo vivo à frente, em altura alcançável e com percurso livre para
o retângulo do chip. O ID do encontro é compartilhado com pulse/dash.


Verificação final Godot 4.5.1, dados isolados e `-- --test`: gesto 16/16,
dicas 34/34 (inclui direção, altura, recarga e obstáculo que intercepta a espessura
do chip), combate 35/35, atmosfera 17/17 e percurso completo 26/26.
Prancha dos caminhos SVG reais renderizada com Inkscape; o gerador verifica todos
os 64 corpos para evitar membros separados e remove apenas fragmentos isolados
pequenos do contorno original. Não houve revisão de movimento no navegador.
