# Mar de gameplay em SVG

A faixa de perigo contínua de y810 passa a usar módulos SVG reais de 512×224,
na escala 1:1 e filtro nearest. A água cobre x0–9600 até y1034, inclusive o limite
inferior da câmera (y920). Não adiciona colisões: o perigo de queda continua na
física existente do jogador. O Node2D está em z=-3, entre o panorama (z=-10) e
as plataformas/personagens. Não se move junto da câmera, para não sugerir uma
superfície jogável em profundidade.

- Superfície: 12 frames a 6fps, ciclo de 2s. Espuma curta segue duas ondas
  periódicas na grade de 2px; profundidade formada por bandas azuis opacas.
- Reflexos: textura de brilho quebrado, translada em passos de 2px a 16px/s,
  ciclo de 32s. Não pisca, não alterna alpha e não usa iluminação branca global.
- Ondas internas: cristas escalonadas movem-se em sentido contrário, 8px/s,
  ciclo de 64s. As camadas têm o mesmo canvas, tile e escala.

Cada borda parcial usa `draw_texture_rect_region` com tamanho de origem igual
ao destino. O gerador envolve retângulos que cruzam a borda modular, portanto
não há cortes indevidos nem intervalos ao movimentar os reflexos. Renderização
é limitada à faixa visível; os dados do mundo definem o comprimento total.

Gerador: `python tools/build_gameplay_sea_svg.py`. O manifesto registra grade,
canvas, duração, linha d’água, camadas e ordem de renderização. Os recursos não
embutem imagens raster e não dependem de animação SMIL dentro do SVG.

`sea_svg.tscn` verifica frames, ordem de camadas, ausência de física, cobertura
dos extremos e interiores do nível em offsets positivos/negativos, módulos
recortados sem deformação, retorno de loop, quantização, blockout e pausa.
Prévia renderizada é uma evidência visual separada do teste headless.
