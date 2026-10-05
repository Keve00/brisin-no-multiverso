# Ruídozinho — família vetorial 0.2 para expansão

Este pacote oferece três variantes novas do inimigo atual. É uma proposta utilizável de assets; não substitui o Ruídozinho ativo, não altera suas colisões e não adiciona inimigos ou regras à fase publicada.

## Direção e proveniência

A referência é a reconstrução existente em `assets/enemies/ruiduzinho/idle_sheet.png` e os dados de camadas do pacote Ruídozinho 0.1. O novo desenho foi feito manualmente em grade inteira: conserva corpo violeta arredondado, olhos magenta, antena e pés curtos. A paleta de seis cores original foi preservada e recebeu cores de sombra, brilho, metal e sinal para detalhar as novas silhuetas. Não é uma cópia pixel a pixel nem uma imagem ampliada ou esticada.

| Variante | Diferença visual | Uso futuro sugerido, ainda não implementado |
| --- | --- | --- |
| `classic` | Volume em blocos de luz/sombra, rosto legível e antena curva | Patrulha básica |
| `scout` | Antena bifurcada, receptor lateral e pequeno núcleo ciano | Batedor que detecta aproximação |
| `shield` | Armadura compacta violeta/cinza e escudo lateral integrado | Guarda com defesa frontal |

O ciano do batedor pertence ao sinal e ao inimigo. A interface das prévias usa tons quentes conforme `AGENTS.md`; o inimigo não foi recolorido para a paleta da interface.

## Geometria e integração futura

Todos os 120 quadros têm canvas **64 × 64**, `viewBox="0 0 64 64"`, fundo transparente e pivô de chão **(32, 54)**. Cada variante tem seu próprio `spriteframes.tres` e `animations.json`, com os mesmos estados. Os SVGs são paths vetoriais de pixels inteiros e não embutem PNG.

Para um `AnimatedSprite2D` centralizado, use `offset = Vector2(0, -22)` para posicionar o pivô de chão no Node2D e filtro **Nearest**. A escala recomendada de inspeção é `Vector2.ONE`; para outra escala, use a mesma magnitude nos dois eixos. O novo corpo é maior e mais detalhado na grade lógica que o sprite antigo de 48 × 48. Não reutilize automaticamente a escala 2 e o offset -16 do inimigo atual. Revise tamanho visível e colisão separadamente quando uma variante for integrada.

Pés mantêm a mesma linha de chão no repouso; a patrulha eleva alternadamente um pé em 1 pixel. Corpo, antena e olhos movem-se em passos inteiros. Não há squash/stretch, ajuste da caixa por quadro ou normalização independente de poses. Recuo de dano desloca o desenho até 2 pixels em X por poucos quadros, sem alterar seu tamanho.

## Animações

| Estado | Quadros | FPS | Duração | Loop no jogo |
| --- | ---: | ---: | ---: | --- |
| `idle` | 8 | 8 | 1,00 s | Sim |
| `patrol` | 8 | 12 | 0,67 s | Sim |
| `alert` | 6 | 10 | 0,60 s | Não |
| `hit` | 6 | 12 | 0,50 s | Não |
| `defeated` | 12 | 12 | 1,00 s | Não |

Dano mostra olhos contraídos, recuo e pequenas faíscas. Derrota dissolve blocos sem recortá-los e termina com detritos visíveis por três quadros. **Nenhum quadro fica totalmente transparente**. A integração futura deve aguardar `animation_finished` para ocultar/remover o inimigo, preservando a leitura do dano e da derrota.

`animated_preview.svg` usa SMIL para repetir todos os estados, incluindo os finitos, com uma pequena pausa ao final. Esse comportamento serve apenas à inspeção. Godot utiliza os SVGs individuais do recurso SpriteFrames, sem depender de SMIL.

## Reprodução e verificação

Execute `python tools/build_enemy_variants.py` na raiz do repositório. Dependências: Python, Pillow e Inkscape. O script recria somente esta família e os arquivos de prévia.

- 3 variantes × 40 quadros: **120 SVGs de animação**, mais 3 SVGs de repouso, 3 SpriteFrames e 3 JSONs de animação.
- XML de cada quadro validado; nenhum elemento `image`.
- Margens mínimas de 2 pixels verificadas no canvas em todos os quadros; nenhuma antena, pé, faísca ou fragmento cortado.
- Canvas e pivô constantes em todos os estados; bounds por quadro disponíveis em JSON.
- `contact_sheet.png` foi renderizado diretamente de 15 SVGs por **Inkscape**, depois ampliado em escala inteira 3 por nearest-neighbor. Não é apenas a imagem intermediária do gerador.
- Revisão visual da imagem renderizada: identidade violeta/magenta coerente, diferenças de silhueta legíveis, alertas e dano visíveis, fragmentação da derrota dentro da área reservada.
- Importação Godot, leitura dos recursos e reprodução dentro de uma cena devem ser verificadas antes da integração. A prévia não comprova por si só a qualidade no cenário real ou no navegador.

`validation.json` registra as verificações do gerador. A revisão independente deve conferir os assets e não tomar esse registro como aprovação automática.
