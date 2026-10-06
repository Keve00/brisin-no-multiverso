# SVGs e animações na paleta quente

A seleção de contraste conserva17 conceitos iniciais e usa20 revisões. As cores são transferidas para os desenhos já corrigidos no jogo, em vez de importar o fundo ou fragmentos das pranchas. `tools/build_warm_assets.py` aplica as amostras por família e registra hashes de geometria e cores em `assets/warm_palette_manifest.json`. Geometria, transparência, canvases e pivôs existentes são preservados. Exportações repetidas não aquecem as cores uma segunda vez. A regeneração geral e o export aplicam a transferência.

Brisin:64 frames SVG para corrida (24), caminhada (24) e salto (16),12 fps, canvas 144×128 e pés (72,120); o atlas original fica como fonte reproduzível. Texturas nearest-neighbor, mesma escala e offset do motor. Os10 inimigos preservam todos os estados; ETzinho mantém mira, recuo e mão/arma conectadas.

Luzes: brilho âmbar/creme, estruturas ameixa/cobre e cores procedurais compatíveis. Nó usa sequência de luz na carga e pulso mais lento Online, com moldura/pivô fixos. Portal usa brilho progressivo das partículas que entram na abertura; entrada finita1,8 s e envelope existentes. Flashes reduzidos mantêm leitura sem piscadas rápidas.

As referências raster ficam fora do export do jogo. O ZIP editável contém a seleção e as amostras exatas em JSON para reproduzir a paleta; as pranchas PNG completas não são duplicadas no download.

## Verificação desta integração

Subagentes independentes conferiram geometria e animações. Os 1.184 SVGs anteriores mantêm paths/alpha/viewBox; 64 SVGs novos de locomoção não contêm raster. A migração foi comparada contra alpha e silhueta dos atlas em 134 verificações por versão.

Web e mobile passaram cosmic_animation(583), scenery_svg, portal_transition(23), menu_animation(33), chip_gesture(16), action_effects_svg(13) e decoration_bounds(13.251). O percurso mobile passou 26 verificações, incluindo 18 saltos e conclusão após a animação do portal. Saves isolados.

A auditoria renderizada das 44 camadas emissivas não encontrou pixels de borda escuros conectados à transparência. Capturas reais do Godot/OpenGL verificam início, vento, Nó Offline/Online, portal em 3 ângulos e entrada em 0/0,3/0,95/1,5 s; nove famílias de plataforma nas duas variantes. A captura automatizada não representa teste em aparelho físico.
