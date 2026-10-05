# Objetos interativos SVG — conceito aprovado em 30/09/2026

Todos os seis objetos da prancha aprovada estão em `assets/world_01/interactive/`.
São **29 SVGs vetoriais editáveis**, mais `manifest.json`, sem `<image>`, bitmaps,
fundo navy, moldura ou rótulos da prancha. `tools/build_interactive_assets.py`
recebe o caminho da prancha como primeiro argumento e reconstrói os pixels como
paths agrupados por cor. A grade é 1 pixel lógico para 2 pixels da referência;
a quantização usa 40 cores por estado. Nenhum objeto inteiro é esticado.

## Camadas e pivôs

Valores no canvas lógico; todos os pares Offline/Online compartilham o canvas.
As camadas centradas de rotação preservam a posição do eixo da arte original.

| Família / camada | Canvas | Pivô | Escala no jogo |
| --- | --- | --- | --- |
| Turbina / torre | 128 × 160 | base (64,156) | 2 uniforme |
| Turbina / rotor | 128 × 128 | eixo (64,64) | 2 uniforme |
| Farol / corpo | 116 × 156 | chão (63,153) | 1,5 uniforme |
| Farol / lâmpada | 20 × 20 | centro (10,10) | 1,5 uniforme |
| Farol / feixe | 192 × 48 | origem (0,24) | 1,5 uniforme |
| Checkpoint / base | 128 × 140 | chão (54,134) | 1 uniforme |
| Checkpoint / bandeira | 128 × 128 | fixação (64,64) | 1 uniforme |
| Checkpoint / lâmpada | 24 × 24 | centro (12,12) | 1 uniforme |
| Nó / estrutura | 120 × 130 | chão (63,127) | 1 uniforme |
| Nó / núcleo | 64 × 64 | eixo (32,32) | 1 uniforme; pulso ≤ 4% |
| Nó / halo | 80 × 80 | centro (40,40) | 1 uniforme |
| Portal / estrutura | 128 × 140 | chão (62,136) | 1,5 uniforme |
| Portal / núcleo | 80 × 80 | eixo (40,40) | 1,5 uniforme; pulso ≤ 2,5% |
| Rail / terminal | 42 × 52 | cabo (30,24) | 1 uniforme |
| Rail / módulo de cabo | 24 × 18 | início (0,9) | 1 uniforme |
| Rail / pacote | 12 × 12 | centro (6,6) | 1 uniforme |

A bandeira tem margem de 64 pixels em volta da fixação: a cauda completa cabe
no canvas durante o balanço. O rotor ocupa até aproximadamente 56 pixels de
raio no canvas de 128. Nenhuma lâmina é recortada durante rotação. Vegetação e
pedras fazem parte das bases; correntes de vento ao redor dos objetos são
representadas pelo sistema de vento existente, sem duplicar trechos da prancha.

## Animações e interações

`scenery_svg.gd` usa passos de 12 fps e rotações quantizadas; a filtragem é
nearest-neighbor. Rotação não muda a proporção dos sprites. Pulsos usam a mesma
escala nos eixos X/Y; com flashes reduzidos, Nó fica limitado a 1,5% e portal a 1%.

- **Turbina:** rotor parado Offline; após a conexão, torre e rotor passam para
  Online e o rotor gira continuamente (1,5 rad/s). A região de vento física
  permanece sob responsabilidade de `world.gd`.
- **Farol:** duas camadas de feixe dourado giram lentamente com amplitude de
  0,15 rad; alpha é exatamente zero Offline. Corpo e lâmpada trocam de estado;
  a lâmpada Offline fica escurecida e aumenta a luz durante `online_blend`.
  A posição fica 180 px à esquerda do Nó para as novas bases não se sobreporem.
- **Ponto Brisa:** presença do jogador ativa o marker já existente. A arte lê
  `marker.active`, troca as três camadas de estado, acende a lâmpada e faz a
  bandeira balançar por 1,4 s (até 0,055 rad), sem squash/stretch. Um checkpoint
  salvo também usa a arte ativa quando a fase é retomada.
- **Nó:** estrutura estática; núcleo roda e pulsa durante Conectando/Online.
  O halo gira somente nesses estados. Offline mantém o núcleo roxo parado.
  O teste legacy continua usando `texture("node_core")` para o estado Online.
- **Portal:** estrutura estática; abertura Offline tem espiral roxa discreta.
  O núcleo ciano gira somente Online (0,8 rad/s), com pulso lento. Posição usa
  `world.level.portal`, portanto acompanha a extensão da fase. A conclusão por
  contato continua no marker e depende da conexão Online.
- **Rail:** terminais e módulos seguem `world.rail_a`/`rail_b`. O cabo repete
  módulos rígidos de 24 px; somente o último módulo usa recorte explícito para
  terminar exatamente no comprimento físico. Não há stretch. Os terminais
  permanecem verticais. Pacotes quadrados percorrem o cabo, sem setas. O rail
  continua utilizável Offline, por isso preserva fluxo mais discreto; Online
  usa os módulos luminosos aprovados. Os pacotes da ponte só aparecem Online.

A arte procedural antiga do checkpoint e rail deve aparecer apenas no blockout.
A collision layer, checkpoint salvo, processo de conexão e portal final ficam
nos sistemas existentes do jogo. Estes assets não adicionam mecânicas falsas.

## Verificação

Os 29 arquivos foram renderizados com Inkscape e os seis objetos comparados
lado a lado em uma composição Offline/Online via PIL. Foram conferidos base,
contorno, rotor inteiro, abertura de portal, bandeira inteira e ausência de papel,
bordas e títulos. Corrigimos a margem da bandeira e removemos vestígios das
correntes de vento da torre. A composição de revisão fica no scratch do trabalho.
Na integração foram executados importação e testes Godot. A captura do jogo
integrado não ficou disponível neste ambiente; ver `asset_integration.md`.
