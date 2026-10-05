# Revisão independente — Brisin animado no menu inicial

Data: 30/09/2026 (horário de São Paulo; rodada final em 01/10/2026 UTC). Escopo: SVGs de aceno e preparação para correr, integração com a tela inicial e preservação dos fluxos de progresso, pausa e configurações. Revisão orientada pelas regras atuais de `AGENTS.md`.

## Referência e critérios

- A referência é o primeiro quadro completo de `assets/player/walk.png`, com canvas 144 × 128, pivô (72,120) e silhueta não transparente de (39,20) a (105,120). Foi inspecionado em ampliação nearest-neighbor: corpo e vela laranja, dois olhos brancos grandes, pupilas escuras e braços/pés curtos marrons.
- O menu anterior mostrava o quadro inteiro em escala uniforme 2, com altura visível de 200 pixels. A nova amostragem deve usar uma única escala 1/2, seguida de escala uniforme 4 na interface, para conservar essa altura física. Canvas comum previsto de 88 × 80, chão (44,68), offset centralizado (0,-28) e base de exibição (866,456).
- Todos os quadros devem conter paths vetoriais reais, sem PNG embutido, preservar a identidade e reservar margem. A mão que acena precisa manter ligação contínua ao braço; base e rosto não podem oscilar por normalização individual.
- O aceno deve continuar com o mundo pausado. Somente a ação de começar/continuar na tela inicial inicia a transição finita; controles ficam desabilitados até o handoff. Cliques repetidos, teclado e gamepad não devem causar múltiplos handoffs.
- Retorno de configurações/controles restaura o aceno sem início pendente. Continuar uma pausa permanece imediato. Continuar progresso salvo preserva os dados; nova aventura precisa resetar e entrar no jogo sem voltar à abertura outra vez.
- A nova animação não deve acrescentar pulsações de opacidade e deve conservar a redução de flashes.

## Inspeção independente dos assets

- Os **60 quadros SVG** finais foram novamente renderizados por Inkscape fora da pasta de trabalho do gerador. Não foi usada uma imagem separadamente desenhada como evidência dos paths.
- Todos os quadros têm canvas 88 × 80, coordenadas inteiras, alpha apenas 0/255, bounds iguais aos metadados, chão em y=68 e margem mínima de 12 pixels. São 13 cores; não há `image`, `filter` ou `mask`.
- A conectividade da silhueta foi medida em todos os renders: **um componente conectado por vizinhança de oito pixels em cada quadro**, sem mãos, pés ou fragmentos de membros soltos.
- A folha final de poses renderizadas foi inspecionada. Corpo/vela laranja, dois olhos, sorriso, cauda e membros curtos preservam a identidade da referência. A mão levantada tem dedos discretos legíveis e permanece ligada ao braço. A piscada apresenta pálpebras fechadas, sem buracos escuros.
- Aceno: 30 quadros a 12 fps, loop de 2,5 s. Preparação: três entradas de oito quadros a 12 fps (0,667 s), para mão baixa, intermediária e alta. As três convergem à mesma pose final. Corrida de saída: seis quadros a 12 fps (0,5 s), sem loop.
- O runtime seleciona a entrada de preparação pelo quadro atual do aceno. Assim, clicar com a mão alta não salta diretamente à pose de mão baixa. O posicionamento mantém escala uniforme e pivô de chão, seguido de deslocamento horizontal curto para iniciar a aventura.

## Achados corrigidos antes da integração

| Achado independente | Correção conferida |
| --- | --- |
| Piscada limpava a camada de olhos e deixava grandes cavidades escuras | Os olhos são cobertos pela pálpebra laranja e recebem linhas escuras de fechamento. Render final inspecionado. |
| Perna direita separada da silhueta na maior parte do aceno e nos primeiros quadros de preparação; pixels órfãos em uma pose de corrida | Ancoragem do quadril corrigida e resíduos removidos. Todos os 60 renders finais têm uma silhueta conectada. |
| Clique com a mão alta entrava diretamente na preparação de mão baixa | Criadas entradas intermediária e alta; metadados associam cada quadro de aceno a uma entrada e os finais coincidem. |
| Nova aventura podia recarregar a cena e mostrar o menu de novo | Integração usa um bypass transitório consumido uma vez pelo HUD recém-criado; recarga real validada pela suíte de integração. |
| `JOY_A` não acionava o botão focado: `ui_accept` carregado continha somente Enter, Enter numérico e Espaço | `setup_inputs()` registra `JOY_BUTTON_A` em `ui_accept` antes do guard de bindings de gameplay. Eventos completos de gamepad passaram depois da correção. |

## Integração e testes

A leitura independente conferiu os guards de `starting`, callbacks das poses finitas, pausa, preservação de checkpoint/fragmentos, seleção de entrada pelo quadro do aceno, retorno de submenus e consumo único de `skip_intro_once`. Esse flag não é serializado. O sprite do menu usa `(4,4)` com filtro nearest, offset `(0,-28)` e pivô fixo; não altera o personagem de gameplay.

Após recuperar Godot 4.5.1 oficial, a revisão executou **11 verificações independentes, todas aprovadas**, em diretório de dados isolado. Um runner externo injetou eventos `InputEventKey`, `InputEventJoypadButton` e `InputEventMouseButton` completos, com press/release, pela entrada do Viewport. Não emitiu diretamente o sinal `Button.pressed`. Foram conferidos:

- abertura pausada com aceno;
- Enter no botão focado → preparação alta;
- tecla repetida e Escape durante preparação → nenhuma interrupção;
- handoff finito e preservação de progresso;
- Enter em Continuar da pausa → retorno imediato;
- `JOY_A` no botão focado → preparação intermediária e handoff finito, sem confirmação vazando para pulo;
- clique do mouse → preparação baixa e handoff finito.

A primeira tentativa independente encontrou ausência de `JOY_A` no mapa `ui_accept`; a mesma execução, após a correção, terminou com `INDEPENDENT INPUT: 11 checked / 0 failed`, exit 0. `ui_up`, `ui_down`, `ui_left` e `ui_right` carregados têm entradas do direcional e eixos analógicos. A injeção por `Input.parse_input_event` isolada não roteava a GUI no headless; foi usado `Viewport.push_input`, preservando o fluxo de input/GUI do motor. Nenhum teste com controle físico foi realizado.

O integrador informou execução adicional das suítes `menu_animation` (16/16) e `ui_integration` (38/38), incluindo recarga real de nova aventura, reset do progresso e restauração do aceno após configurações. Também informou exportação e boot headless do pacote web. Esses resultados pertencem à integração; a revisão independente executou os 11 checks de entrada acima.

Na rodada final, os 60 SVGs foram novamente renderizados por Inkscape em pasta temporária externa. Os bounds coincidem com o JSON; todos usam 88 × 80, 13 cores, alpha binário e base y=68. Cada imagem tem uma única componente de oito vizinhos. A tabela de 30 entradas do aceno referencia animações finitas existentes; os paths finais das três preparações são idênticos. A folha de poses também foi inspecionada visualmente.

Não restaram bugs bloqueantes identificados neste escopo.

## Limites de evidência

A renderização de SVGs e a execução headless conferem frames, pivôs e lógica; não substituem uma captura real do Godot ou do navegador. Esta rodada não executou uma janela nativa nem conferiu o site em navegador. A evidência visual é a dos SVGs renderizados, e a evidência de interação é a do motor em headless com eventos injetados. A composição final e a resposta de dispositivos físicos continuam sem captura nesta revisão.

## Atualização independente — 01/10/2026

A rodada de melhoria solicitada pelo usuário agora contém **278 quadros SVG**. O aceno tem 30 quadros a 10 fps (3 s), a vela superior ondula por deslocamento de bandas na grade lógica, cada um dos 30 quadros de aceno possui uma preparação finita de oito quadros a 12 fps, e a corrida de saída tem oito quadros a 12 fps. Esta atualização substitui os números e o esquema de três aproximações da rodada anterior acima.

A comparação independente da imagem composta de todas as entradas confirmou igualdade exata de pixels entre `wave N` e o primeiro quadro da preparação correspondente. As 30 saídas também coincidem exatamente com `run_start 0`. A folha dos SVGs renderizados foi aberta e inspecionada: mão erguida e dedos legíveis, ligação dos membros ao corpo, identidade do rosto preservada, base estável e preparo inclinado para a corrida. O código mantém a mesma escala uniforme `(4,4)`, offset `(0,-28)`, pausa do mundo e bloqueio de comandos durante a transição finita.

O tecido do checkpoint recebeu 12 quadros por estado, a 8 fps, com fixação invariável nas colunas 64–66. A revisão independente abriu uma folha com os 24 renders do Inkscape e comparou a geometria: as colunas fixas são idênticas à fonte, todos os quadros são distintos e a contagem de células de cada estado permanece constante. O mastro é uma camada separada e não recebe rotação do tecido. A névoa também foi conferida pela prévia SVG renderizada: o horizonte perde contraste e saturação, enquanto céu, lua e formas da costa mantêm os contornos em pixels. A leitura do código confirmou aplicação somente no nó distante `z_index=-10`.

Estas evidências são renderização dos assets e leitura/medição de código. Os resultados atuais das suítes do motor são registrados na integração; esta folha isolada não comprova a composição final no navegador.

Após a importação central, a revisão executou Godot 4.5.1 em headless com diretório de dados temporário próprio para cada suíte e argumento `-- --test`. Resultados: `menu_animation` 16/16, `scenery_svg` 13/13, `checkpoint_wave` 21/21, `background_svg` 17/17 e `ui_integration` 38/38, todos com exit 0 e sem erros de scripts. Estas suítes validam o ciclo finito do menu, preservação/reset de progresso, tecido Offline/Online com pivô fixo, cobertura do fundo e segurança da interface. A composição visual final no navegador continua a cargo da integração.
