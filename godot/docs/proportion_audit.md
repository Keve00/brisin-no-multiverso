# Auditoria de proporções — Mundo 1

Data: 30/09/2026. Auditoria independente realizada em paralelo à integração dos elementos SVG. Este documento registra a linha de base observada antes das correções dessa integração; não certifica que os achados continuam presentes após mudanças posteriores.

## Método e evidência

Foram lidos `scripts/world/world.gd`, `scripts/world/platform.gd`, `scripts/interactables/marker.gd`, `scripts/player/player.gd`, `scripts/enemies/noisezinho.gd`, `project.godot`, as cenas player/world, `data/world_01.json`, `assets/player/animations.json`, `tools/build_scene_svg.py` e `dist/index.html`. As dimensões dos PNGs foram medidas diretamente nos arquivos, incluindo bounding boxes alfa. Inspeção visual: `docs/vento.png`, `docs/nexo_online.png`, `assets/world_01/portal.png` e `assets/world_01/raft.png`. As capturas de docs são evidência histórica do visual existente, não uma nova captura da integração em andamento.

O indicador de deformação é `k = (largura_destino/largura_fonte) / (altura_destino/altura_fonte)`. `k=1` preserva a proporção; `k<1` comprime horizontalmente; `k>1` alonga horizontalmente em relação à altura. Percentuais abaixo são alteração da razão largura/altura, não redução absoluta da largura.

## Achados específicos da linha de base

| Elemento / chamada | Fonte PNG | Destino | k | Impacto |
|---|---:|---:|---:|---|
| Turbina Offline, `world.gd` | 380 × 638 | 130 × 300 | 0,728 | 27,2% mais estreita; pás e torre deformadas |
| Turbina Online, `world.gd` | 382 × 635 | 130 × 300 | 0,720 | 28,0% mais estreita; proporção também varia ao trocar estado |
| Farol Offline, `world.gd` | 264 × 650 | 115 × 320 | 0,885 | 11,5% mais estreito |
| Farol Online, `world.gd` | 329 × 647 | 115 × 320 | 0,707 | 29,3% mais estreito; mesmo destino aplicado a canvases distintos |
| Portal, `marker.gd` | 600 × 501 | 170 × 178 | 0,797 | 20,3% mais estreito; o círculo vira elipse vertical |
| Ilha pequena, `world.gd` | 488 × 514 | 160 × 140 | 1,204 | 20,4% mais larga |
| Rail de percurso, `world.gd` | 650 × 95 | 670 × 35 | 2,798 | 179,8% mais largo relativo à altura; detalhes achatados |
| Ponte Online, `platform.gd` | 650 × 95 | 240 × 28 | 1,253 | 25,3% mais larga |
| Jangada móvel, `platform.gd` | 614 × 457 | 170 × 130 | 0,973 | Desvio pequeno, porém evitável: 2,7% mais estreita |

### Ilhas/plataformas: maior problema sistemático

`platform.gd` desenhava a mesma ilha de 582 × 441 em `Rect2(-8,-57,rect.size.x+16,230)`. Todas as plataformas recebem altura fixa de 230, enquanto a largura varia com a colisão. Isso altera a proporção de cada instância, mesmo usando o mesmo asset.

| X no nível | Destino artístico | k |
|---:|---:|---:|
| 0 | 636 × 230 | 2,095 |
| 760 | 316 × 230 | 1,041 |
| 1160 | 296 × 230 | 0,975 |
| 1690 | 496 × 230 | 1,634 |
| 2290 | 346 × 230 | 1,140 |
| 2920 | 436 × 230 | 1,436 |
| 3500 | 276 × 230 | 0,909 |
| 4030 | 446 × 230 | 1,469 |
| 4600 | 386 × 230 | 1,272 |
| 5080 | 476 × 230 | 1,568 |
| 5780 | 616 × 230 | 2,029 |

A plataforma inicial alonga a ilha a mais de duas vezes a proporção da fonte. A área do Ruídozinho também recebe alongamento de 63,4%. A solução recomendada é composição modular/tile ou recorte da arte em escala uniforme, mantendo a faixa de contato explícita. A colisão não exige que uma ilha inteira seja deformada para ocupar a largura.

### Rail fora da trajetória

O percurso jogável vai de (2450,266) a (3080,375), inclinado aproximadamente 9,82°. A imagem do rail era desenhada em retângulo horizontal com 35 px de altura, ancorado no início. No fim do trajeto há 109 px de diferença vertical. Além da deformação XY, a arte não acompanha a linha que leva o jogador. Recomenda-se linha procedural alinhada aos endpoints e partículas/pacotes em SVG que percorrem essa mesma linha.

### Personagens

- Ruídozinho: escala `Vector2(2,2)` e nearest-neighbor; nenhuma deformação XY base detectada. Offset de (0,-16) em escala 2 deve manter o pivô/base das células constante em todas as animações.
- Brisinho: células 144 × 128, sem deformação base. Pivô registrado em (72,120); `visual.position.y=-56` combinado com centragem vertical de 64 coloca o pivô em y=0. Boa consistência de chão.
- Brisinho em LAND: `Vector2(1.06,0.94)` por cerca de 0,1 s produz razão 1,128. É squash deliberado de aterrissagem, não deformação de enquadramento. A integração mantém essa exceção breve como feedback de impacto compatível com a direção do GDD (que menciona squash/recoil no sistema de dano, sem especificar estes valores de LAND); ela está documentada em `AGENTS.md` e não autoriza deformar layout ou props.
- Metadados de vídeo e PNGs: altura visível de todos os frames é normalizada a 100 px. Run tem largura visível 67–78 px; walk 63–67; jump 82–110. Isso não prova stretch XY, pois as poses originais mudam, mas normalizar altura por frame pode ampliar artificialmente a pose abaixada. Não ajustar novamente apenas a largura; revisar escala constante de extração quando a animação do jogador for trabalhada.
- Colisão do Brisinho (32 × 68) menor que a arte visível é uma escolha de gameplay e não comprova erro de proporção. A diferença deve ser julgada por contato percebido e justiça da colisão.

### Fundo e apresentação web

- Fundo 1536 × 857 desenhado em 1536 × 857: proporção preservada. Espelhamento/repetição de parallax é intencional, sem stretch.
- `dist/index.html`: stage com `aspect-ratio:16/9`, canvas 1152 × 648 e fullscreen com largura limitada pela altura; preserva proporção. Escala CSS fracionária pode variar a nitidez dos pixels, mas não é deformação geométrica.
- `project.godot` usa overrides 1152 × 648 e `canvas_items`, porém não declara explicitamente viewport lógico e política de aspecto. Recomenda-se explicitar 1152 × 648 e `keep`, para evitar dependência de defaults em exportações futuras.

## Critérios para a integração SVG em andamento

1. Substituir dimensões independentes por escala uniforme em turbina, farol, portal e ilha pequena.
2. Combinar Offline/Online com canvas e pivô iguais antes de trocar a textura; não compensar largura diferente com stretch.
3. Rotor gira em torno do eixo da turbina; núcleo gira em torno do centro do portal. Margens das camadas precisam comportar o arco completo.
4. O rail usa os mesmos endpoints da lógica. Objetos que viajam nele preservam sua razão e tamanho.
5. Plataformas e ponte precisam de composição/recorte proporcional; converter props a SVG não corrige o stretch das ilhas.
6. SVGs amostrados de PNG têm arredondamento de grade: turbina 64 × 106 vs fonte 380 × 638 (diferença de aspecto 1,37%) e portal 100 × 84 vs fonte 600 × 501 (-0,60%). A escala uniforme da integração preserva a nova grade; revisar visualmente essa discretização, sem tentar ajustar cada eixo separadamente.
7. Renderizar e revisar as mesmas posições do nível depois da integração. Testes de lógica não substituem a inspeção de proporção.

As regras permanentes foram registradas em `AGENTS.md` na raiz do projeto. Nenhum código funcional foi alterado por este agente; os achados foram enviados ao agente principal para correção e validação.

## Revisão após as correções

Foi realizada uma segunda leitura dos scripts efetivamente alterados pelo agente principal: `systems/scenery_svg.gd`, `world/world.gd`, `world/platform.gd`, `interactables/marker.gd` e `project.godot`. Os resultados abaixo são verificação estática das transformações e âncoras implementadas. Eles não equivalem a aprovação visual da nova versão no motor ou navegador.

| Achado anterior | Implementação revisada | Resolução |
|---|---|---|
| Turbina deformada | Base 64 × 106 e rotor 128 × 128 com `Vector2.ONE*3`; mesmos canvases/pivôs Offline/Online | Stretch XY corrigido; rotação controlada pelo motor |
| Farol deformado / mudança de tamanho Online | Um único `lighthouse_base.svg` de 64 × 126 com escala 2; estado alterado por modulação e luz | Stretch e troca de canvas corrigidos |
| Luz fora do eixo do farol durante integração | Origem inicialmente em (5338,125), corrigida para (5356,129), correspondente ao centro luminoso lógico (41,23) da arte | Desalinhamento detectado e corrigido antes da entrega |
| Portal achatado | Moldura 100 × 84 com escala 2; núcleo 64 × 64 com escala 2 | Stretch XY corrigido |
| Ilha pequena larga | Tamanho calculado como `texture.get_size()*(140/texture.get_height())`, aproximadamente 132,92 × 140 | Proporção corrigida; base preservada em y=770 |
| Rail achatado e fora da inclinação | PNG removido da renderização do percurso; linha liga os endpoints reais; pacotes SVG interpolam a mesma linha e giram em seu ângulo | Stretch e alinhamento corrigidos |
| Ponte alongada | Faixas de geometria procedural no lugar do PNG esticado | Corrigido sem deformar arte |
| Jangada levemente estreita | Altura 130 com largura proporcional de aproximadamente 174,66; centrada na colisão | Stretch corrigido; base artística y=17 relativa à plataforma mantida |
| Ilhas com larguras deformadas | Caps de 160 px fonte e módulos centrais recortados; todos os destinos usam `source.size*0.5` | Stretch corrigido, escala uniforme nas 11 plataformas |
| Política de viewport implícita | Viewport 1152 × 648 e `window/stretch/aspect="keep"` explícitos | Corrigido |

### Âncoras e consistência verificadas

- As peças criadas por `piece()` usam a mesma magnitude de escala X/Y e nearest-neighbor. Turbina usa fator 3; farol, beams, moldura/núcleo do portal e halo usam fator 2; demais efeitos usam fator 1 ou 1,5, sempre uniforme.
- Portal: o centro extraído do núcleo é (49,43) na moldura 100 × 84. A moldura centralizada em (0,-84) e escala 2 transforma esse centro em (-2,-82), exatamente o pivô usado pelo rotor. Não há salto geométrico na ativação.
- Turbina: base centrada em (1395,311), canvas 64 × 106, fator 3; ponto lógico (32,38) transforma-se em (1395,266), igual à origem do rotor. A camada do rotor converte esse ponto para (64,64) no canvas 128 × 128. As camadas coincidem estruturalmente em repouso. A origem física do cubo na fonte foi aproximada; possível diferença de cerca de 1 px lógico / 3 px exibidos permanece como item de inspeção visual de rotação, não erro confirmado.
- Farol: centro luminoso lógico (41,23) no canvas 64 × 126, fator 2 e centro (5338,209), resulta em (5356,129). Lâmpada e beams compartilham esse ponto. O brilho não salta ao ativar porque o canvas da base não muda.
- Nó: base em `node+(0,-32)` termina em y=0; núcleo tem canvases 32 × 32 iguais nos dois estados. O movimento vertical de 2 px e halo giratório são deliberados, sem escala XY variável.
- Plataformas: caps exibidos com 80 px de largura cada; todas as larguras artísticas atuais têm pelo menos 276 px, portanto não há sobreposição dos caps. Os módulos centrais usam o trecho da fonte proporcional ao destino, inclusive no último módulo parcial. A altura visual passa a 220,5 px uniformes. Não foram alteradas as colisões.
- Rail: efeitos têm offset visual constante de (0,10), igual ao traço renderizado. Essa separação é intencional em relação à trajetória física, não divergência de inclinação.

### Limitações e próximos pontos de QA

- As animações de vídeo do Brisinho não foram alteradas. Permanece o risco já identificado de normalização da altura por frame. O squash de LAND permanece como exceção breve documentada.
- Os SVGs são reconstruções em paleta de 24 cores e grade reduzida. Preservam a proporção da grade escolhida, mas não reproduzem cada detalhe dos PNGs de alta resolução. A discretização pequena de aspecto das fontes foi documentada acima.
- Fator 1,5 do núcleo do Nó e fator 0,5 dos PNGs das ilhas são uniformes, porém fracionários; a nitidez precisa ser julgada em render final. Rotações são quantizadas para limitar tremulação, mas exigem inspeção dos passos em movimento.
- Tiles centrais das ilhas preservam a proporção, mas repetem texturas e cabos. A continuidade estética nas emendas precisa de revisão em imagem atual; não houve alegação de que a composição modular seja invisível.
- O agente principal informou indisponibilidade do renderer de captura Godot por falha de inicialização X11/Wayland. As capturas antigas continuam apenas como referência da linha de base. Testes da lógica e composições de SVG fora do motor não comprovam renderização correta dentro do jogo.
- A aprovação visual final deve verificar os renders atualizados das posições listadas nos critérios de integração e conferir se há wobble do rotor, emendas de plataforma, recorte do portal e partículas fora de margem.
