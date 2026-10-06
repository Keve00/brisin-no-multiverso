# Brisin — candidata mobile web

Data: 05/10/2026. Branch: `feat/mobile-adaptation`. Base: publicação32.
Estado: implementação pronta para avaliação; aprovação física/visual final pendente.
A publicação atual e a main não foram substituídas.

## Entrega implementada

- Movimento horizontal com zona neutra, multitouch por dedo e arraste entre ações. Input físico preserva intensidade analógica e não é solto por dedos virtuais.
- Pulo completo por toque; altura variável opcional. Dash mantém direção, recarga e limite aéreo. Chip usa um disparo por toque, com repetição opcional a cada0,35s. Pulso continua disponível e recebe rótulo Conectar perto do Nó.
- Assistência separada no tuning: coyote0,16/buffer0,18 para mobile, desligáveis; desktop continua0,12/0,12. Sem alteração de velocidade, gravidade, colisões, fase, inimigos, gemas ou IDs de checkpoint.
- Menu mobile aprovado com ações à esquerda e arte à direita, controles espelhados, tamanhos100/112,5/125% e posições alta/baixa. Fonte, paleta e SVGs existentes. Avatar mobile em escala uniforme2,6 e ilha2,4; desktop2×. HUD separa contador e pausa; avisos trocam teclas por ações de toque.
- Área de toque calculada a partir da escala CSS real. Pulo mira64px CSS; demais ações48px ou mais, com espaço entre controles. Layout recalculado ao mudar viewport.
- Shell16:9 com letterboxing, safe-area-inset e viewport dinâmico. Retrato orienta girar e permite solicitar o menu. Fullscreen não é requisito.
- Pausa com retomada explícita após foco/orientação/aplicativo. Limpeza de dedos em menus, pausa, morte, portal e saída de cena. Interrupção congela também a animação finita de início.
- Tutorial escolhido antes da primeira aventura; pausas apenas na primeira sessão com FAZER TUTORIAL. Nova aventura preserva preferências de tutorial e mobile.
- Save em coleta, checkpoint, conexão, conclusão, preferências e interrupção. Erro de FileAccess informa sem encerrar a partida. Persistência real do browser ainda exige teste.
- Qualidade leve reduz ripples/redraw do fundo e densidade de ecos, mantendo corpos dos ataques e física. Nenhuma promessa de FPS foi inferida de headless.

## Verificação automática

Godot4.5.1.stable.official.f62fdbde1. Cada cena usou dados temporários separados,
`--fixed-fps 60` e `-- --test`. Esse passo fixa a simulação, não mede FPS do aparelho.
Quinze execuções de cenas passaram; logs sem ERROR e exit0. Resultados estruturados
em `mobile_test_results.json`. Total:2305 verificações.

| Perfil / cena | Verificações aprovadas |
|---|---:|
| Desktop — integration |26|
| Desktop — coast_extension |10|
| Desktop — enemy_placement |1811|
| Desktop — checkpoint_totems |27|
| Desktop — menu_animation |28|
| Desktop — portal_transition |23|
| Desktop — tutorial_choice |18|
| Desktop — important_notices |27|
| Desktop — context_hints |34|
| Desktop — combat_svg |36|
| Desktop — ui_integration |43|
| Mobile — mobile_input |120|
| Mobile — mobile_ui |58|
| Mobile — mobile_route |26|
| Mobile — tutorial_choice |18|

`mobile_route` percorreu spawn→vento→inimigo→checkpoint→rail→dash→Nó→expansão→portal
com InputEventScreenTouch enviados ao viewport e física real, sem teleporte na
travessia completa. Suas verificações unitárias anteriores usam posições controladas.
A rota obrigatória chegou ao portal sem precisar modificar encontros. Isso não prova
ergonomia, todas as rotas opcionais por dois polegares ou três partidas por aparelho.

`mobile_input` cobre dois dedos, troca pulo→dash, cancelamento, saída dos botões,
propriedade compartilhada, teclado/analógico, salto, chip repetido, pausa real,
retomada, preferências e migração de save. `mobile_ui` confere botões/menus em
escalas CSS simuladas0,42/0,48/0,67/1,0, tamanho mínimo e ausência de sobreposição;
confere também interrupção da animação e retorno ao título.

O shell foi executado em Chromium headless131, viewport844×390 e390×844, com o
motor substituído por stub para isolar HTML/CSS/JS: canvas679,109×381,984 (16:9),
orientação retrato visível e zero erros JS. Safe areas não tinham recorte físico.
O jogo completo encerrou o Chromium neste ambiente ao carregar Godot; não há
aprovação visual WebGL completa, áudio audível ou medição de desempenho browser.

Exportação: PCK reconstruído; tamanho sincronizado no carregador; SHA256/WASM,
limites por arquivo e loader aprovados. Verificador de áudio confirmou1200 resumes
redundantes sem novas fontes/restarts. ZIP editável e candidata web verificados.

## Reprodução

```sh
python tools/test_mobile.py --godot /caminho/Godot_v4.5.1-stable_linux.x86_64
python tools/export_web.py --godot /caminho/Godot_v4.5.1-stable_linux.x86_64
python tools/package_mobile_candidate.py
```

A candidata executável está em `entregas/Brisin_Mobile_Candidata.zip`. Extraia e
sirva `web` por HTTP; o LEIA-ME explica acesso por celular na mesma rede. O projeto
editável fica em `dist/Brisin_SVGs_e_Interacoes.zip`. Saves pertencem à origem HTTP;
avaliação em localhost/IP não compartilha automaticamente o save do Site publicado.

## Pendências de aceitação

| Alvo | Situação |
|---|---|
| Android entrada/intermediário, Chrome |Não testado fisicamente|
| iPhone compacto/com recorte, Safari |Não testado fisicamente|
| Tablet / fullscreen / barras / notch |Revisão física pendente|
| Três percursos completos por aparelho |Pendente|
| Rotas opcionais com dois polegares |Pendente|
| Sessão15min, aquecimento, FPS/memória |Pendente; metas60/30FPS não medidas|
| Áudio audível e troca de aplicativo/bloqueio |Pendente em aparelhos|
| Persistência IndexedDB/storage negado/reload |Pendente em browsers reais|
| Menu em todas as poses, HUD, portal e totens |Geometria/regressões verificadas; revisão visual final pendente|
| Android/iOS nativos, PWA e lojas |Fora desta primeira candidata|

Os marcos M1–M4 têm implementação verificável. M0 físico e o aceite final de M5
continuam pendentes. A candidata isolada permite executar essa avaliação sem
alterar a versão publicada32.

## Revisão visual aprovada de menu e controles

Implementação das duas imagens aprovadas em05/10. Referências no repositório em
`tools/reference_art/approved-mobile-menu.png` e `approved-mobile-controls.png`.
Menu: principal laranja, segunda ação larga, duas secundárias lado a lado; logo
canônico, personagem acenando e ilha à direita. SVGs de molduras/ícones novos,
fonte original em peso maior e contorno escuro dos títulos.
Controles: Pulo maior, Dash ao lado, Chip/Pulso acima em arco; direcional com
setas preenchidas, pausa isolada e contador faceteado no topo. Recargas e
rótulo Conectar continuam funcionais. Preferências e mecânicas preservadas.

Capturas reais do Godot4.5.1/OpenGL Compatibility (Mesa llvmpipe) em
`docs/mobile_qa/`: menu com progresso, sem progresso, pose de aceno e gameplay.
A cena reproduzível é `godot/tests/mobile_layout_capture.tscn`; usa save isolado.
As2305 verificações passaram em15 execuções, sem ERROR. O teste mobile de
geometria cobre todas as combinações de tamanho, posição e espelhamento nas
quatro escalas CSS. Isso não mede conforto físico dos polegares, FPS, áudio
ou persistência em Android/iPhone; esses itens continuam para teste em aparelho.

## Correção de legibilidade do HUD

Cabeçalho e contador dimensionados pela tinta da fonte na escala CSS; estado
Conectando e total00 /49 completos, sem colisão com Pausa. Zero sem barra interna,
fonte pesada nos textos e avisos com quebra por palavra e frame modular de altura
variável. Tooltip não encobre alvos de toque; confirmação Entendi permanece
legível, sem rodapé branco sobre a fase.

2378 verificações em16 execuções passaram sem ERROR, incluindo73checks novos
de legibilidade, wrapping e limites. Capturas reais484×272 em
`docs/mobile_qa/hud_context_small.png` e `hud_tutorial_small.png`.
