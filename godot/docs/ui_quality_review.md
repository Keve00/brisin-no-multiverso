# Revisão independente — interface Brisin e assets de expansão

Data: 30/09/2026. Escopo: resultados dos agentes de interface e assets, comparados às regras vigentes de `AGENTS.md`. A revisão não modifica a lógica de jogo.

## Evidência e limites

- Código final da interface, fonte bitmap, geradores SVG, recursos SpriteFrames e testes de interação foram lidos independentemente.
- A integração principal informou ainda 39 recursos de expansão carregados no Godot sem falhas e 25 verificações da rota completa aprovadas. São resultados da integração, distintos da inspeção de imagens e da reexecução independente dos 38 testes de interface.
- Logotipo SVG e composições de tela inicial, configurações e HUD foram renderizados por Inkscape e inspecionados. As composições usam os assets e as coordenadas do código, mas **não são capturas do Godot**: não reproduzem integralmente o tema, o nine-slice, a câmera ou a interação.
- A captura nativa foi tentada. Godot não encontrou display X11/Wayland; Xvfb não conseguiu criar seus sockets locais. Portanto, **não houve aprovação visual no Godot nem no navegador nesta revisão**.
- `contact_sheet.png` dos inimigos, renderizado dos SVGs reais, foi inspecionado. Além disso, todos os **120 quadros SVG** foram novamente renderizados por Inkscape nesta revisão, independentemente do gerador: canvas 64 × 64, quadros não vazios, margem mínima de 2 pixels, bounds iguais aos metadados e ausência de pixels com alpha intermediário.

## Interface

- Nome visível `Brisin`/`BRISIN` conferido no HUD, título do projeto, carregamento, cabeçalho, descrição e acessibilidade da página. Nomes técnicos legados não são tratados como texto de interface.
- Botões, molduras, ícones e tipografia usam laranja, âmbar, amarelo e creme sobre superfícies escuras quentes. O ciano do cenário permanece separado da identidade da interface.
- Logotipo inteiro e legível, sem cortes. Fonte original em pixels contém os acentos de `MÚSICA`, `CONFIGURAÇÕES`, `CONEXÃO`, `NÓ` e `Ç`. Acentos superiores e cedilha cabem nas células de 12 pixels; a mesma geometria é usada na fonte TTF do carregador web.
- Texturas de objetos/personagem preservam aspecto. O personagem da abertura usa o quadro completo 144 × 128 em escala uniforme 2; seu pivô (72,120) chega à base (866,456). Nine-slice é explicitamente limitado a molduras modulares da interface.
- O portal de conclusão separa frame e core em canvases 64 × 64. O core gira em passos sobre o centro (32,32), com escala uniforme; essa geometria e a mudança de rotação foram verificadas na suíte de interface.
- Estados de conexão têm rótulos próprios. Os avisos de checkpoint, conectando e conexão restabelecida usam ícones e texto, preservam duração de leitura ao pausar e têm entrada/saída.
- A suíte de interface contém verificações relevantes de foco inicial, eventos de teclado/gamepad e navegação circular, progresso novo/salvo, sliders e persistência, retorno dos submenus ao menu pai, pausa, conclusão, replay, acentos, largura de texto e limites da área lógica. Foi executada novamente nesta revisão com dados de usuário isolados: **38 passaram, 0 falharam**. Testes de lógica não substituem a revisão de uma imagem real do jogo.

## Achados encaminhados e correções

| Achado | Encaminhamento e estado |
| --- | --- |
| Seta de foco com escala 0,8 produzia geometria fracionária | Gerador corrigido para path inteiro no canvas 16 × 16. |
| CheckButton usava nomes de ícones de CheckBox | Interface corrigida para `on`, `off`, `on_disabled`, `off_disabled`. |
| Recorte quadrado da pose da abertura não seguia seu canvas/pivô documentado | Pose passou a usar 144 × 128 completos, escala uniforme e base alinhada à ilha. |
| Invulnerabilidade piscava rapidamente mesmo com reduzir flashes ativado | Opacidade do personagem passa a permanecer em 0,65 nessa opção. Pulsações de opacidade dos novos elementos da interface ficam constantes. |
| Dica flutuante do Nó terminava 94 pixels acima do chão, enquanto o topo do personagem pode alcançar 100 pixels acima | Corrigido: bounds completos do sprite, transformados pela câmera, recebem margem de 12 px. Dica usa posições alternativas sem interseção; testes de personagem no chão e em salto passaram. Avisos também reposicionam ou aguardam espaço seguro, preservando duração de leitura. |
| Destaque de hover do slider poderia continuar com tema padrão | `grabber_area_highlight` também recebeu o estilo quente. |

## Família Ruídozinho 0.2

- Três silhuetas inspecionadas: clássico mantém a antena curva; batedor usa antena bifurcada e receptor ciano; blindado integra armadura e escudo sem alongar o corpo.
- Corpo violeta, olhos magenta, antena e pés curtos mantêm a identidade da referência. As diferenças não dependem apenas de recoloração.
- Cada variante tem 40 quadros em cinco estados. Todos compartilham canvas 64 × 64 e pivô de chão (32,54). Offset centralizado (0,-22) confere matematicamente com esse pivô.
- Os 120 XMLs e todas as referências de cada SpriteFrames foram conferidos independentemente: paths válidos, sem imagens raster embutidas, repouso/patrulha em loop e alerta/dano/derrota finitos.
- Dano tem recuo, olhos contraídos e faíscas visíveis; derrota deixa detritos nos últimos quadros. Nenhum quadro final totalmente vazio. A futura integração deve esperar a animação terminar antes de ocultar o inimigo.
- São assets preparados para expansão. Não há afirmação de que as três variantes já foram adicionadas como inimigos jogáveis à fase publicada.

## Assets costeiros para expansão

- Imagens efetivamente renderizadas de `contact_sheet.png` e `source_comparison.png` foram inspecionadas: ilha de cristais, ilha de retransmissão, Nó estabilizado e PontoBrisa. As ilhas preservam rochedo, topo de grama e raízes da fonte existente; as novas peças têm leitura clara na grade do jogo.
- A amostragem da ilha usa uma única escala 1/4 nos dois eixos e padding, sem ajustar largura e altura separadamente. O comparativo com a fonte foi apresentado em escalas físicas equivalentes e preserva a silhueta.
- Foram conferidas independentemente as **16 camadas SVG** do manifesto: mesmos canvases entre estados, sem `image`, `filter` ou `mask`. As oito composições Offline/Online renderizadas mantêm tamanho de canvas e margens; a base comum não muda de posição entre estados.
- Pivôs documentados: ilhas (80,77), Nó (40,104), checkpoint (29,106). O core original 32 × 32 do Nó é reutilizado sem stretch. O checkpoint muda também seu símbolo, além de cor.
- Animações de sinal e bandeira são prévias de preparação. Antes de integrar, ligar os estados ao jogo, aplicar redução de flashes, revisar contato físico/escala e reproduzir em cena. Estes assets não ampliaram ainda a fase publicada.

## Pendências de validação visual

Conferir a interface dentro do jogo e do navegador quando houver display: tema e estados de hover/foco, câmera, dica do Nó e avisos durante salto/vento, fullscreen e leitura em janelas menores. As variantes novas precisam de revisão de escala física, colisão e comportamento ao serem integradas à fase; o pacote de assets não altera essas regras por si só.

## Conferência final da integração principal

- A publicação concorrente de vento SVG e gemas laranja foi incorporada à mesma versão, preservando seu código e suas regras no `AGENTS.md`.
- Após essa combinação, as 38 verificações de interface e as 25 da rota completa passaram novamente. O carregador web e a abertura do PCK exportado em modo headless também passaram; isso continua sem substituir captura visual no navegador.
- O nome visível mudou para Brisin, mantendo o caminho nativo anterior de progresso por configuração explícita. Os caminhos antigo e novo foram comparados no motor e resultaram no mesmo diretório de dados. O nome técnico legado continua permitido pelas regras do projeto.
