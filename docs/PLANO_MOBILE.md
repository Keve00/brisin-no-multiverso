# Brisin — plano de adaptação mobile

Data: 04/10/2026. Atualização: 05/10/2026. Status: candidata web implementada; validação física e aprovação visual final pendentes.
Branch: `feat/mobile-adaptation`.
Base: versão publicada 32, commit `885928ed8aadd3394383d9e961fcb606ad052860`.

## Objetivo e primeira entrega

Adaptar o Mundo 1 para jogar confortavelmente com dois polegares em celular, preservando o desafio de plataforma, os chips, a conexão Offline → Online e a identidade visual aprovada. A primeira entrega será uma versão web mobile em paisagem, validada em Android e iPhone. Essa é uma decisão de planejamento, não uma afirmação de compatibilidade já testada.

Usar a mesma base Godot 4.5.1, com perfil mobile e controles próprios, evitando uma cópia divergente do jogo. Depois da validação web, avaliar exportação Android nativa; iOS nativo vem em etapa posterior, dependendo de ambiente Apple, assinatura e distribuição. Instalação/PWA e lojas ficam fora do primeiro protótipo.

O plano inicial foi aprovado para implementação em 05/10/2026. A candidata permanece nesta branch, sem substituir a publicação atual. O relatório `VALIDACAO_MOBILE.md` registra implementação, evidências e pendências; não há aprovação automática de aparelhos físicos.

## Diagnóstico da base

- Mundo 1: 15.235 pixels, 49 gemas, 22 adversários e seis checkpoints. Preservar IDs e progresso.
- Área lógica: 1152 × 648; renderização Compatibility; export web sem threads. Há presets Web e Windows, sem preset mobile nativo.
- `player.gd` consome ações do InputMap; não há camada dedicada de multitouch nos scripts.
- `player_tuning.gd`: corrida 290 px/s; salto −490 px/s; gravidade 1350; coyote e buffer de salto 0,12 s; dash 780 px/s por 0,19 s, recarga 0,40 s. São valores de referência, não metas de alteração automática.
- Chips usam F no teclado e Y no controle. O HTML já bloqueia gestos no canvas com `touch-action:none`, mas isso não cria controles virtuais.
- HUD, tutorial opcional, animação de início, salvamento, áudio web e portal têm regressões registradas no AGENTS.md que precisam continuar cobertas.

## Controles e gameplay propostos

| Ação | Controle mobile | Comportamento planejado |
|---|---|---|
| Movimento | Direcional horizontal fixo à esquerda | Esquerda/direita, zona neutra central, arraste entre direções; sem eixo vertical desnecessário. |
| Pulo | Botão maior à direita | Modo inicial de salto completo por toque para facilitar a troca do polegar para dash; opção de altura variável ao segurar/soltar. Comparar ambos no protótipo antes de fixar o padrão. |
| Dash | Botão próximo ao pulo | Direção do movimento ou última direção válida; indicador de recarga; um dash aéreo por salto. Sem gesto obrigatório de deslizar ou toque duplo. |
| Chips | Botão de ataque à direita | Um disparo por toque; opção de manter pressionado para repetir, respeitando a recarga existente. Não disparar automaticamente só por haver inimigo. |
| Pulso / conectar | Quarto botão menor, em posição fixa | Pulso continua disponível no combate; perto do Nó, muda o rótulo para “Conectar”, mantendo a ação. Não trocar a função do botão de chips. |
| Pausa / Entendi | Botões próprios | Áreas grandes e separadas do combate; confirmação nunca gera salto ou disparo. |

Alvos iniciais de ergonomia: áreas de toque de pelo menos 48 × 48 pixels CSS equivalentes no aparelho, pulo em torno de 64, e separação mínima de 8. São parâmetros de protótipo a medir após escala e safe area, não dimensões fixas no canvas Godot. Oferecer tamanho/posição dos controles e layout espelhado. Sem vibração obrigatória; avaliar feedback tátil apenas onde disponível.

O principal risco é exigir movimento + pulo sustentado + dash no mesmo instante. O protótipo deve resolver isso com salto por toque e troca de botão pelo mesmo polegar, antes de tentar facilitar o mapa inteiro. Coyote e buffer mobile podem ser experimentados em 0,16 s e 0,18 s, respectivamente, mantendo os valores atuais no desktop. Não alterar velocidade, gravidade, alcance do chip ou dash globalmente sem repetir os percursos.

Revisar aterrissagens e tempo para reagir aos Ruídozinhos, especialmente após saltos, em jangadas e plataformas desmoronáveis. Ajustar apenas os encontros comprovadamente problemáticos. Vento, rail e checkpoint mantêm seus gatilhos físicos; saída do rail usa o botão de pulo. Se forem necessárias diferenças no mapa, usar ajustes mobile sobre os IDs atuais, sem duplicar todo o JSON ou invalidar saves.

## Arquitetura e arquivos

| Área | Arquivos existentes | Trabalho previsto |
|---|---|---|
| Input | `godot/scripts/player/player.gd`, `godot/scripts/systems/world_state.gd` | Acrescentar camada de comandos compartilhada, com identificação da origem e limpeza de ações. Teclado, controle e toque não podem soltar ações uns dos outros. |
| Controles | Nova cena `godot/scenes/ui/mobile_controls.tscn` e script próprio | Botões multitouch, identificação de cada dedo, arraste, cancelamento e conversão das coordenadas da tela para o jogo. Os caminhos são propostos e ainda não existem. |
| Ajuste de gameplay | `godot/scripts/player/player_tuning.gd` | Perfil mobile separado, seleção explícita e opções de salto/assistência. |
| Interface | `godot/scripts/systems/hud.gd` | Reposicionar avisos, tutorial, contador, menu e pausa; adaptação ao dispositivo de entrada ativo. |
| Fase e câmera | `godot/scripts/world/world.gd`, `godot/data/world_01.json` | Avaliar campo visível sob os dedos; antecipação moderada da câmera e ajustes pontuais de encontros, condicionados a teste. |
| Save e ciclo de vida | `world_state.gd`, `audio.gd` | Preferências mobile separadas do progresso; pausa por perda de foco; gravação sem depender apenas de fechar a aba. |
| Web | `dist/index.html`, `tools/export_web.py`, `godot/export_presets.cfg` | Layout mobile, safe areas, orientação, áudio por gesto e export reproduzível. Não editar o JS gerado manualmente. |

Usar `TouchScreenButton` ou roteamento equivalente que suporte dedos simultâneos. Ele não usa âncoras de Control, então o layout precisa ser recalculado explicitamente quando a área útil muda. Menus continuam com controles de interface adequados. Evitar duplicação de comandos por emulação de mouse a partir de toque.

Limpar todos os dedos e comandos ao abrir menu, pausar, girar a tela, perder foco, morrer, entrar no portal ou remover a cena. Retomar o jogo somente após ação explícita quando houver interrupção. A camada de menu pode processar durante pausa; ações de gameplay ficam bloqueadas.

## Interface e enquadramento

Preservar 16:9 e escala uniforme. Em paisagem, calcular o canvas na área disponível e usar letterboxing; nunca esticar cenário, Brisin, logo ou totens. Em retrato, apresentar orientação para girar e manter a partida pausada, com opção de voltar ao menu. Não depender de fullscreen ou bloqueio de orientação para funcionar.

Respeitar notch, barra de gestos e barras do navegador. No shell web, considerar safe-area-inset e alterações de viewport; em export nativo, validar a área segura fornecida pela plataforma. HUD fica no topo; avisos ficam abaixo dele e fora dos controles, sem encobrir o Brisin ou a aterrissagem. Reduzir densidade e reposicionar a composição do menu em vez de simplesmente diminuir todas as letras.

Preservar o laranja/amarelo, a fonte pixelada, os SVGs e as proporções do AGENTS.md. Dicas mobile mostram ações/ícones de toque; teclado continua mostrando F. Oferecer FAZER/PULAR TUTORIAL antes de iniciar somente quando não houve escolha. Pausas de tutorial continuam restritas à primeira sessão com escolha explícita; nova aventura não apaga essa preferência.

## Marcos de execução

| Ordem | Entrega | Critério de saída |
|---|---|---|
| M0 — referência | Medições em aparelhos e captura dos trechos críticos | Registrar aparelho, SO, navegador, resolução, FPS/frame time, memória quando mensurável e carregamento frio. Definir baseline real. |
| M1 — toque | Movimento, pulo, dash, chip, pulso e pausa | Completar sequência movimento→pulo→dash e movimento→chip com dois polegares; nenhum comando preso após cancelamento ou troca de dedo. |
| M2 — tela mobile | Menu, HUD, avisos, orientação e safe areas | Todos os comandos acessíveis em celular compacto e tela alongada; nenhuma área crítica sob notch, polegares ou barra do navegador. |
| M3 — gameplay | Perfil mobile e revisão de encontros | Concluir o percurso inteiro até o portal, inclusive rotas opcionais e retorno de cada checkpoint, usando somente toque. Registrar falhas por trecho antes/depois dos ajustes. |
| M4 — robustez e desempenho | Presets de qualidade, áudio e retomada | Sessão real de 15 minutos sem travamento, crescimento contínuo de recursos ou áudio duplicado; preservar save após interrupções. |
| M5 — candidata mobile | Build de avaliação isolada e relatório | Regressões desktop aprovadas e matriz mobile preenchida. Integrar/publicar apenas ao concluir a etapa de implementação e sua avaliação. |

Estimativa inicial: 8–13 dias úteis de implementação e validação, sujeita às medições de M0 e à disponibilidade dos aparelhos. Não é prazo contratado. Dependências: M0→M1→M2→M3; M4 começa com a base jogável e termina após M3; M5 depende de todos. Exportações nativas serão estimadas separadamente.

## Desempenho, carregamento e interrupções

Meta inicial: 60 FPS em aparelho intermediário e modo de qualidade reduzida com pelo menos 30 FPS sustentados no aparelho de entrada selecionado. Medir frame time e aquecimento; não usar testes headless como evidência de FPS ou áudio. Se a meta não for atingida, reduzir partículas, frequência de efeitos de fundo e custo de redraw antes de alterar física ou descaracterizar sprites.

Medir payload WASM/PCK e memória das texturas. SVG é importado como textura no Godot; arquivo vetorial pequeno não garante baixo custo em GPU. Avaliar exclusão de pranchas QA, previews e assets sem uso dos builds; validar dependências para não retirar um recurso carregado por caminho dinâmico. Não prometer um tamanho ou tempo de download antes da medição. Manter verificações de integridade, limites por arquivo e `fileSizes`.

Áudio inicia após gesto, respeita mute, pausa e retomada. Preservar o guard de pause/resume idempotente e o verificador web. Testar bloquear/desbloquear o celular, trocar de aba/aplicativo, recarregar e alternar orientação. Salvar em checkpoint e eventos relevantes, tolerar armazenamento indisponível e informar falha sem encerrar a partida. Cache/PWA não substitui salvamento nem garante persistência após limpeza dos dados do navegador.

## Matriz de validação e aceite

Aparelhos físicos mínimos: Android de entrada (4 GB, se disponível), Android intermediário, iPhone compacto e iPhone com recorte na tela; tablet como complemento. Registrar modelos e versões reais em M0. Usar Chrome Android e Safari iOS; acrescentar navegador alternativo como compatibilidade secundária. Testar com e sem fullscreen, orientação invertida, retrato→paisagem e barras do navegador abertas/fechadas.

- Multitouch: dedos simultâneos, sair do botão, arrastar direcional, tocar UI durante combate, eventos duplicados e interrupção sem evento de release.
- Gameplay: spawn, vento, rail, dash entre ilhas, pulo curto/longo, todos os inimigos, jangadas, desmoronamento, Nó, seis checkpoints e portal.
- Progresso: primeira visita com tutorial aceito/recusado, save legado, nova aventura, retorno após morte e recarga.
- Visual: menu em todas as poses, lateral esquerda do Brisin, HUD, avisos e contadores; totem e portal em ambos os estados; chão sem vazios ou vento duplicado.
- Automação: reaproveitar `integration`, `coast_extension`, `enemy_placement`, `checkpoint_totems`, `menu_animation`, `portal_transition` e verificações web. Acrescentar testes específicos de posse/liberação de toques e conversão de coordenadas, sem confundir simulação com ergonomia real.
- Aceite: três percursos completos com toque por aparelho-alvo, sem bloqueio de progresso ou input preso; zero ERROR nos logs relevantes; save e áudio verificados; desktop sem regressão. Sessões com jogadores devem validar o modo de salto e a disposição dos botões antes de fixar o padrão.

## Referências técnicas

Documentação oficial Godot 4.5 consultada em 04/10/2026:
- https://docs.godotengine.org/en/4.5/classes/class_touchscreenbutton.html — multitouch e diferenças de layout em relação a Control.
- https://docs.godotengine.org/en/4.5/tutorials/export/exporting_for_web.html — WebGL 2, export sem threads, limitações mobile, áudio e persistência.
- https://docs.godotengine.org/en/4.5/classes/class_displayserver.html — consulta de capacidades e área segura; validar o suporte no alvo.

As recomendações de controles, valores experimentais, cronograma e metas são propostas deste plano. Nenhuma validação em aparelho físico foi executada nesta etapa de documentação.


## Resultado da implementação — 05/10/2026

Implementados: roteador multitouch por dedo, comandos compartilhados com intensidade analógica, perfil de coyote/buffer mobile, salto completo por toque e opções de altura variável/repetição, layouts espelhados e tamanho/posição, menu em duas colunas, HUD/dicas de toque, alvos calculados em pixels CSS, safe areas e retrato, pausa explícita após interrupções, congelamento da animação inicial, preferências/saves e qualidade leve.

A fase compartilhada concluiu o percurso obrigatório por eventos de toque no motor, sem precisar alterar a geometria ou adversários. M0 físico, ergonomia, rotas opcionais por dois polegares e sessão térmica de15min seguem pendentes. M1–M4 têm implementação e verificações automáticas; M5 tem pacote isolado para avaliação, sem integração à main. Native Android/iOS e PWA continuam fora desta primeira candidata.
