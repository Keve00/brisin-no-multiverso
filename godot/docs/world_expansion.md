# Expansão costeira — assets vetoriais preparados

**Estado:** quatro famílias prontas como proposta de arte; **não integradas ao nível nem à física**. O pacote não substitui assets publicados. Brisin continua sendo o nome apresentado ao jogador.

## Família e uso previsto

| Família | Origem real | Uso futuro | Canvas lógico | Pivô |
| --- | --- | --- | --- | --- |
| Ilha de cristais | `world_01/small_island.png` | Ilha secundária com vegetação e mineral de conexão, orientando exploração | 160 × 176 | (80, 77), linha de superfície aproximada |
| Ilha de retransmissão | Mesma ilha, mantendo rochedo, raízes e recorte | Apoio de rota com uma pequena antena e bandeira | 160 × 176 | (80, 77) |
| Nó estabilizado | Paths reais de `svg/node_base.svg`, `node_core.svg` e estado Offline | Variante do Nó com pedestal e estabilizadores mais legíveis | 80 × 112 | (40, 104), base |
| PontoBrisa | Haste, bandeira e base do checkpoint em `scripts/interactables/marker.gd` | Checkpoint alternativo de sinal, com símbolo de confirmação ao salvar | 80 × 112 | (29, 106), pé da haste/base |

A paleta preserva rocha coral, vegetação oliva, sombras azuis e sinais ciano existentes no cenário. Laranja/amarelo da interface não foram impostos às conexões do mundo. A bandeira Offline do PontoBrisa mantém o laranja já existente; Online troca o símbolo por confirmação, além da cor.

## Camadas e integração futura

Os arquivos estão em `assets/world_01/expansion/`; `manifest.json` lista as camadas. Todas as camadas de uma família compartilham exatamente o mesmo canvas e pivô. Monte com **offset de camada (0, 0)** em relação ao canto superior esquerdo do canvas; se o Node2D representar o pivô, coloque a origem do desenho em `(-pivot.x, -pivot.y)`. Não centralize cada SVG pelo próprio bounding box.

- Ilhas: `*_base.svg` fixa e `*_signal_off/on.svg` para sinais e brilho.
- Nó: base fixa, `*_core_off/on.svg` sem alteração de escala ou posição, `*_signal_off/on.svg` para indicadores.
- PontoBrisa: base fixa, `*_flag_off/on.svg` para bandeira e símbolo, sinais separados.
- `*_assembled_off/on.svg` e PNGs são composições para revisão; não substituem a montagem por camadas para animação.

Escala inicial sugerida: **2 × uniforme** com nearest-neighbor. A ilha ocupa aproximadamente 244 × 258 pixels de arte no canvas 320 × 352; a diferença é margem transparente, não stretch. A escolha do comprimento de plataformas é trabalho posterior de composição/colisão; não alongar a ilha inteira para preencher superfícies.

Pivôs locais adicionais: núcleo do Nó em **(40, 34)**; antena da ilha em **(92, 35)**; haste/bandeira do PontoBrisa em **(31, 33)**. A prévia move a camada de bandeira inteira somente em Y, ±1 pixel lógico, em passos discretos. Para integração, pode-se fixar a borda de ligação à haste e mover apenas a ponta; nunca deformar o objeto inteiro em X/Y.

## Origem, amostragem e proporção

A ilha usa a fonte 488 × 514 com **um único fator 1/4 nos dois eixos**: amostra fonte `(4x + 2, 4y + 2)`, não cálculo independente por largura/altura. A área lógica resultante é 122 × 129; a última meia linha é margem transparente. Origem da ilha no canvas: **(19, 32)**. O recorte e a silhueta permanecem no sistema de coordenadas da fonte.

A fonte contém restos opacos quase neutros do fundo xadrez nas lacunas das raízes; a reconstrução exclui amostras com diferença entre canais RGB menor que 15 antes de reduzir a paleta a 24 cores. A regra não remove pixels ciano/vegetação/rocha saturados. A inspeção renderizada confirmou que as lacunas voltaram a ser transparentes. Paths vetoriais nativos sem PNG embutido, blur, máscara ou filtro.

## Prévia e validação

- `contact_sheet.svg` / `.png`: Offline e Online lado a lado, ilhas em escala uniforme 2 × e Nó/PontoBrisa em 3 ×, com cada escala indicada. Os rótulos são documentação, não UI final.
- `animated_preview.svg`: prévia SMIL standalone, sinais com opacidade discreta e bandeira ±1 pixel; não é captura do Godot.
- Sinal: loop de 1,2 s com quatro passos de opacidade (1 → 0,65 → 0,85 → 1). Não há strobe nem mudança de escala.
- Os símbolos e formas do estado salvo/ligado permanecem visíveis em repouso. A animação pode ser desligada mantendo o estado Online estático.
- Gerador: `python tools/build_world_expansion.py`. Valida canvas de cada camada e ausência de imagens, filtros e máscaras. PNGs gerados por Inkscape a partir dos SVGs reais.

**Limite:** revisão por arte renderizada e estrutura vetorial. Sem importação Godot, teste de interação ou publicação; essas etapas pertencem à integração futura. Novas ilhas não possuem colisão implementada e os beacons não adicionam mecânica por si só.
