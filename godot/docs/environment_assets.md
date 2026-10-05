# Cenário e efeitos — conceitos aprovados

A prancha aprovada em 30/09/2026 originou **27 variações em nove famílias**,
mais três camadas de iluminação separadas dos postes. SVGs têm paths reais;
não contêm imagens raster, textos da prancha, molduras ou fundo incorporados.

| Família | Variações | Uso visual |
|---|---|---|
| `palms` | 0 compacto, 1 alto, 2 inclinado | Coqueiros; balanço no pivô de chão |
| `vegetation` | 0 capim, 1 arbusto, 2 flores | Reação suave à passagem do jogador |
| `rocks_sand` | 0 rochas altas, 1 baixas, 2 duna | Estáticos e sem bloqueio |
| `ruins` | 0 coluna, 1 arco, 2 totem | Estáticas e sem bloqueio |
| `posts` | 0 madeira, 1 terminal, 2 antena | Camada `_lamp` responde a Offline/Online |
| `water_props` | 0 boia, 1 estaca, 2 onda | Boia e estaca oscilam; espuma em ciclo |
| `wind` | 0 fluxo horizontal, 1 vertical, 2 espiral | Trails orgânicos com folhas; sem setas |
| `gems` | 0 média, 1 grande, 2 compacta | Laranja, facetas douradas, pulso uniforme |
| `pickup` | 0 anel, 1 fragmentos, 2 faíscas | Sequência de coleta de 0,48 segundo |

## Escalas, canvases e integração

`assets/world_01/environment/manifest.json` informa cada arquivo, canvas e
pivô. Os dezoito objetos foram extraídos com a mesma amostragem espacial
1/3 em ambos os eixos, grade de pixels quadrados e 28 cores por objeto.
Vento, gemas e coleta foram reconstruídos em grade lógica com paths.
Cada decoração reserva cinco pixels de margem nos quatro lados.

Gemas usam canvas **48 × 56**, pivô **(24,28)** e silhuetas de até **24 × 32**.
Os três frames `pickup_0.svg`, `pickup_1.svg` e `pickup_2.svg` compartilham
canvas **64 × 64** e centro **(32,32)**: anel 0–0,12 s, fragmentos 0,12–0,28 s,
faíscas 0,28–0,48 s. Dissipar alfa no fim. A opção reduzir flashes limita
o halo/pulso; não repetir a sequência a cada frame nem tocar áudio extra.

`environment_svg.gd` recebe `world` antes de `_ready()`, lê
`world.level.environment` como `[kind, variant, x, y, scale]`. `(x,y)` é a
base/pivô documentada, e `scale` é uniforme e positiva. `set_art(enabled)`
alterna a camada em blockout; `add_decoration(placement)` aceita novos
itens. O array vazio significa nenhuma decoração, sem posições ocultas.
Essa camada tem `z_index=1`, à frente do fundo e atrás das plataformas
(`z_index=2`), filtro nearest, nenhuma colisão e nenhum
evento de coleta. Não sobrepor decorações altas a saltos/obstáculos.

O balanço não muda os pés: rotação pequena ao redor do pivô de origem.
Proximidade da velocidade horizontal do jogador induz uma inclinação
temporária com restauração exponencial. Objetos de água usam deslocamento
de até dois pixels lógicos do mundo e rotação de 0,015 radianos; espuma
usa alfa lento. Lâmpadas dos postes passam de 14% de alfa em Offline
para brilho suave Online, com menor amplitude em reduzir flashes.

Vento/gemas/coleta estão disponíveis também no pacote, mas as suas
interações de gameplay continuam sob responsabilidade das regiões de
vento e marcadores existentes. Instanciar uma gema decorativa não cria
um fragmento coletável nem modifica seu progresso.

## Reprodução e verificação

`python tools/build_environment_assets.py --source CAMINHO --render`
regenera os SVGs, manifest e renders PNG usando Inkscape. A fonte padrão
é a prancha `exec-54a086db-33d8-4bf6-9fc3-26ebb47c10e4.png` em
`../generated_images`. `contact_sheet.png` apresenta todos os 27 objetos
com uma única escala de 3×, permitindo conferir proporção e ausência de
restos das molduras/textos. PNGs são evidência de render, não fontes
usadas pelo motor. `animated_preview.svg` demonstra em navegador os
movimentos e transição das lâmpadas em ciclo. As animações do jogo são
controladas pelo Godot, compatíveis com export web; não dependem de
animações SMIL do SVG da prévia.
