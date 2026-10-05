# Plataformas vetoriais — conceitos aprovados

56 SVGs editáveis reais em `assets/world_01/platforms/`, sem raster embutido:
18 plataformas completas, 18 camadas de decoração, 18 módulos de chão e 2 camadas de vento.
As 9 famílias (`coastal`, `sand`, `steps`, `thin`, `cracked`, `raft`,
`wood_bridge`, `signal`, `wind_island`) têm variações 0 e 1.

`tools/build_platform_assets.py` recorta a prancha aprovada, remove navy externo,
quantiza para 48 cores e converte runs horizontais em paths de pixels quadrados.
Usa fator uniforme 1/2 na fonte. Canvas completo/decoração/vento: 200 × 176;
pivô superior de contato: (100,64). `manifest.json` registra crops e módulos.
Ground tem tamanho nativo individual e superfície de contato em y=0.

## API e montagem

- `configure(rect, moving, bridge=false)` continua aceitando chamadas antigas.
- `configure_variant(kind, variation=0)` carrega os assets novos e configura
  três colisões distintas em steps. Cracked habilita crumble por padrão; o
  chamador pode pôr `crumble=false` para usar pedra estável com a mesma arte.
- `configure_optional(true)` torna todos os shapes one-way com profundidade 20.
- `player` recebe o CharacterBody2D. Somente colisão de piso com a plataforma
  exata inicia a rachadura; proximidade lateral não dispara.
- `reset_state()` restaura presença, relógio, home e crumble no respawn.
- `online_only=true` e `sync_online(bool)` controlam plataformas de conexão.

Todos os desenhos preservam escala uniforme. Ground usa caps de 24 pixels e
repetição explícita de middle, recortando somente a última repetição. Não se
alonga uma jangada ou ilha inteira. A decoração é desenhada uma só vez, no
centro da plataforma; plataformas ficam antes do jogador na árvore de desenho.
Steps usa o SVG completo em escala uniforme `rect.width / ground.width` e
colisões independentes, sem repetir um degrau como uma plataforma plana.

## Interações e tempos

- Raft moving preserva `home + travel*sin(clock*0.8)` e transporte por
  AnimatableBody2D. A variação 1 representa jangada com pontas elevadas.
- Signal moving usa bob vertical ±6 a 1.8 rad/s no corpo e na colisão juntos;
  luz inferior pulsa a 2.5 rad/s sem mover o pivô da plataforma.
- Cracked: 0.6 s de tremor/rachadura, 1.8 s ausente, retorno adiado se jogador
  ocupa o volume, 2 s de recuperação antes de poder colapsar novamente.
- Wind_island: camada de curvas de vento se desloca ±3 x/±2 y e pulsa alpha;
  quatro partículas fluem continuamente. Força de vento pertence ao sistema
  regional do mundo e não é aplicada em duplicidade aqui.
- Wood_bridge quando bridge=true recebe linha de energia ciano baixa pulsante.

Steps0: ground 137 px; superfícies (x,width,y): (5,68,34), (32,61,0),
(75,61,11). Steps1: ground 102 px; (2,47,39), (10,57,0), (34,60,20).
Multiplique x,width,y por `rect.width/ground.width`; altura de cada collider=20.
One-way é recomendado para variantes em rotas opcionais acima do caminho.

## Verificação

As 18 texturas completas foram efetivamente renderizadas pelo Inkscape e
inspecionadas em contact sheet; silhuetas, folhas, rochas laranja, cordas,
plataformas de sinal e vento mantêm a direção visual aprovada. Camadas são paths
SVG nativos, sem texto de prancha, molduras ou navy. Resíduos mínimos nos cantos
da prancha foram removidos por componentes conectados. Pivôs compartilhados e
pixels quadrados foram verificados por dimensão e código. A verificação de
interações no Godot/export web pertence à integração do mundo.
