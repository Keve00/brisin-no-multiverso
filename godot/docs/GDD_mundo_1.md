# GDD — Brisinho: Conexão Entre Mundos
## Mundo 1 — Costa dos Ventos Conectados

**Versão:** 1.0  
**Status:** Documento de produção para vertical slice / primeira fase jogável  
**Engine recomendada:** Godot 4.x  
**Formato alvo inicial:** Desktop + Web  
**Gênero:** Plataforma 2D/2.5D de aventura  
**Duração alvo do Mundo 1 completo:** 15–25 minutos  
**Duração alvo do primeiro vertical slice:** 3–6 minutos  

---

# 1. Objetivo deste documento

Este GDD define tudo o que é necessário para produzir o **Mundo 1 — Costa dos Ventos Conectados** como uma fase jogável completa e como base técnica para os mundos seguintes.

O objetivo é que o Mundo 1 funcione simultaneamente como:

1. introdução ao universo do Brisinho;
2. tutorial natural das mecânicas principais;
3. apresentação da fantasia de “restaurar conexões”;
4. prova visual da direção artística;
5. vertical slice técnico para validar personagem, câmera, física, animações, parallax, UI, VFX, áudio, inimigos e checkpoints;
6. base reutilizável para o Mundo 2 e Mundo 3.

O jogo não deve parecer um advergame simples. A marca e a ideia de conectividade devem existir dentro das regras do mundo e das próprias mecânicas.

---

# 2. Visão do Mundo 1

## 2.1 Nome

**Costa dos Ventos Conectados**

## 2.2 Fantasia

Um litoral fantástico inspirado visualmente no Nordeste brasileiro, onde vento, mar, jangadas, faróis e estruturas de telecomunicação fazem parte do mesmo ecossistema.

Linhas de sinal luminosas atravessam falésias e ilhas suspensas. Faróis funcionam como repetidores. Correntes de vento transportam energia. Jangadas percorrem rotas impossíveis entre mar e céu.

Após a Grande Interferência, o fluxo de conexão do lugar parou.

Faróis ficaram offline.  
Cabos de sinal se romperam.  
Turbinas perderam sincronização.  
Tempestades de ruído começaram a surgir.  
Partes do cenário ficaram isoladas.

Brisinho chega à costa para restaurar o primeiro grande Nexo de Conexão.

---

# 3. Objetivos de experiência

O jogador deve sentir:

- controle responsivo;
- velocidade sem perder precisão;
- curiosidade pelo cenário;
- satisfação visual ao restaurar áreas;
- progressão constante;
- sensação de que o mundo “volta à vida”;
- identidade regional sem caricatura;
- conectividade representada de maneira lúdica;
- uma aventura de verdade, não uma demonstração técnica.

---

# 4. Pilares do gameplay

## 4.1 Movimento prazeroso

O personagem deve ser divertido mesmo em uma sala vazia.

O controle precisa ter:

- aceleração;
- desaceleração;
- pulo variável;
- coyote time;
- jump buffer;
- air control;
- feedback de aterrissagem;
- pequenas animações de antecipação e recuperação.

## 4.2 Conexão transforma o cenário

Ativar um ponto de conexão deve alterar o mundo.

Exemplos:

- luzes acendem;
- cabos passam a pulsar;
- plataformas se ativam;
- vento começa a circular;
- faróis voltam a funcionar;
- música ganha novas camadas;
- áreas antes frias ganham cor;
- partículas surgem.

## 4.3 Tecnologia integrada à natureza

Nada deve parecer colocado apenas para comunicar “telecom”.

Antenas, cabos, faróis, vento, ilhas e mar devem parecer parte da mesma fantasia.

## 4.4 Ritmo

A fase deve alternar:

**exploração → plataforma → velocidade → descanso → puzzle → desafio → recompensa**

---

# 5. Estrutura narrativa

## 5.1 Entrada

Brisinho atravessa um portal defeituoso e chega à Costa dos Ventos Conectados.

A região parece bonita, mas parcialmente sem energia.

Ao fundo, alguns faróis piscam irregularmente.

O primeiro objetivo aparece:

> **RESTABELEÇA O PRIMEIRO NÓ DE SINAL**

## 5.2 Descoberta

Ao avançar, Brisinho encontra:

- cabos desligados;
- turbinas paradas;
- zonas de interferência;
- criaturas formadas por ruído;
- o primeiro Ponto Brisa.

## 5.3 Escalada

Cada Nexo menor restaurado aumenta a energia do mundo.

O jogador começa perto do nível do mar e progride para falésias, ilhas suspensas e estruturas mais altas.

## 5.4 Clímax

Uma tempestade artificial cobre o grande farol central.

A tempestade funciona como o boss do mundo.

Brisinho precisa usar as habilidades aprendidas para chegar ao núcleo da interferência.

## 5.5 Conclusão

Após restaurar o farol central:

- a tempestade desaparece;
- todos os faróis se conectam;
- linhas luminosas atravessam a costa;
- o oceano ganha reflexos de energia;
- o portal para o próximo mundo é ativado.

---

# 6. Estrutura do Mundo 1

O Mundo 1 é dividido em cinco setores.

## Setor A — Praia do Primeiro Sinal

**Função:** onboarding.

Ensina:

- movimento;
- pulo;
- coletáveis;
- interação básica;
- primeiro checkpoint.

Elementos:

- praia;
- dunas;
- plataformas baixas;
- pequena jangada;
- primeiro cabo sem energia;
- primeiro Ponto Brisa.

Duração alvo: **3–4 min**

---

## Setor B — Falésias do Vento

**Função:** ensinar verticalidade e correntes de ar.

Novas mecânicas:

- correntes de vento;
- plataformas móveis;
- saltos maiores;
- primeiro inimigo.

Elementos:

- falésias;
- turbinas;
- plantas;
- pequenos túneis;
- saltos sobre o mar.

Duração alvo: **4–5 min**

---

## Setor C — Trilhas de Sinal

**Função:** introduzir velocidade.

Novas mecânicas:

- rail de sinal;
- dash;
- sequências rápidas;
- rotas alternativas.

Elementos:

- cabos luminosos;
- ilhas flutuantes;
- boosts;
- coletáveis em linhas;
- obstáculos rítmicos.

Duração alvo: **4–5 min**

---

## Setor D — Farol Quebrado

**Função:** puzzle + tensão.

Novas mecânicas:

- Pulso de Conexão;
- ativação de nós;
- pequenas sequências de roteamento;
- inimigos combinados.

Objetivo:

Restaurar três repetidores para acessar o farol principal.

Duração alvo: **4–6 min**

---

## Setor E — Olho da Tempestade

**Função:** boss.

O jogador usa:

- salto;
- dash;
- vento;
- rail;
- pulso.

Duração alvo: **3–5 min**

---

# 7. Personagem — Brisinho

## 7.1 Estados principais

A máquina de estados inicial deve contemplar:

```text
IDLE
RUN
TURN
JUMP_START
JUMP_UP
FALL
LAND
DASH
RAIL
HIT
RESPAWN
INTERACT
CELEBRATE
DISABLED
```

Estados futuros podem ser adicionados sem quebrar a arquitetura.

---

# 8. Controles

## Teclado

| Ação | Tecla |
|---|---|
| Mover | A/D ou Setas |
| Pular | Espaço |
| Dash | Shift |
| Pulso de Conexão | E |
| Interagir | E |
| Pausar | Esc |

## Gamepad

| Ação | Controle |
|---|---|
| Mover | Analógico esquerdo / D-pad |
| Pular | A / Cross |
| Dash | X / Square |
| Pulso | B / Circle |
| Pausar | Start |

O sistema de input deve usar o **Input Map do Godot**, nunca teclas hardcoded.

---

# 9. Física do personagem

Valores abaixo são ponto de partida, não valores finais.

```text
Walk Speed: 180–220 px/s
Run Speed: 260–320 px/s
Acceleration: 1500–2200 px/s²
Deceleration: 1800–2600 px/s²
Jump Velocity: -430 a -520 px/s
Gravity: 1200–1600 px/s²
Fall Gravity Multiplier: 1.15–1.35
Coyote Time: 0.10–0.15 s
Jump Buffer: 0.10–0.15 s
Dash Duration: 0.15–0.25 s
Dash Cooldown: 0.3–0.6 s
```

A sensação final deve ser validada por playtest.

---

# 10. Mecânicas principais

## 10.1 Pulo variável

Soltar o botão antes do ápice reduz a altura.

Objetivo:

dar precisão sem tornar o jogo excessivamente difícil.

---

## 10.2 Coyote Time

Depois de sair de uma plataforma, o jogador ainda pode pular por aproximadamente 0,12 s.

---

## 10.3 Jump Buffer

Se o jogador apertar pulo ligeiramente antes de pousar, o comando deve ser executado assim que tocar o chão.

---

## 10.4 Dash de Sinal

Brisinho vira momentaneamente um fluxo luminoso.

### Funções

- atravessar pequenas lacunas;
- alcançar plataformas;
- destruir interferências frágeis;
- criar sequências rápidas;
- complementar o rail.

### Regras

- uma utilização por salto;
- recarrega ao tocar o chão ou checkpoint;
- não atravessa paredes sólidas;
- pode gerar afterimage e partículas.

---

## 10.5 Pulso de Conexão

O jogador emite uma onda curta.

### Pode

- ativar nodes;
- ligar repetidores;
- revelar objetos;
- interromper inimigos simples;
- disparar pequenas reações do cenário.

### Não deve

virar um tiro tradicional.

A ideia é interação e conexão, não combate armado.

---

## 10.6 Correntes de vento

Áreas invisíveis ou semitransparentes aplicam força ao personagem.

Tipos:

- vertical;
- horizontal;
- diagonal;
- pulsante;
- forte;
- fraca.

Devem ter feedback visual claro.

---

## 10.7 Rail de sinal

Cabos energizados funcionam como trilhos.

Ao encostar no rail:

1. Brisinho entra no estado `RAIL`;
2. trava parcialmente no caminho;
3. ganha velocidade;
4. pode saltar;
5. pode trocar de rail em pontos específicos.

O rail deve possuir:

- entrada clara;
- direção;
- velocidade;
- saída segura.

---

# 11. Sistema de Conexão

Cada setor possui um estado.

```text
OFFLINE
UNSTABLE
CONNECTING
ONLINE
```

## OFFLINE

- iluminação reduzida;
- props sem energia;
- menos partículas;
- música simplificada.

## UNSTABLE

- luzes piscam;
- cabos falham;
- vento irregular.

## CONNECTING

Sequência de ativação.

- pulse;
- shader;
- som;
- partículas;
- objetos começam a responder.

## ONLINE

- iluminação plena;
- cabos energizados;
- música completa;
- cenário mais vivo;
- caminhos opcionais podem abrir.

---

# 12. Pontos de conexão

## 12.1 Nó de Sinal

Objeto menor.

Ao receber Pulso de Conexão:

- muda de estado;
- energiza elemento próximo;
- atualiza progresso.

## 12.2 Repetidor

Objeto intermediário.

Pode exigir:

- múltiplos nodes;
- pequena sequência;
- chave de energia.

## 12.3 Nexo

Objetivo principal do setor.

Ativá-lo modifica grande parte do cenário.

---

# 13. Checkpoint — Ponto Brisa

## Comportamento

Ao tocar:

- salva posição;
- restaura estado necessário;
- reproduz pulso visual;
- toca feedback sonoro;
- acende permanentemente.

## Respawn

Ao morrer:

1. fade rápido;
2. retorno ao checkpoint;
3. restauração das plataformas essenciais;
4. perda mínima ou nenhuma perda de progresso.

Para o Mundo 1, evitar penalidade severa.

---

# 14. Coletáveis

## 14.1 Fragmento de Conexão

Coletável padrão.

Objetivos:

- incentivar exploração;
- ensinar rotas;
- criar linhas visuais de movimento.

Formato recomendado:

pequeno fragmento luminoso.

### Uso inicial

- score;
- desbloqueios futuros;
- feedback de conclusão.

## 14.2 Memória de Sinal

Coletável raro.

Quantidade sugerida no Mundo 1: **3**

Pode desbloquear:

- lore;
- arte conceitual;
- pequena mensagem narrativa.

---

# 15. Inimigos

O Mundo 1 deve começar com poucos inimigos bem legíveis.

## 15.1 Ruídozinho

### Papel

Inimigo básico.

### Comportamento

- patrulha pequena área;
- vira nas bordas;
- pode ser eliminado por stomp ou dash.

### Estados

```text
IDLE
PATROL
ALERT
HIT
DEFEATED
```

---

## 15.2 Gaivota de Interferência

### Papel

Inimigo aéreo.

### Comportamento

- paira;
- detecta o jogador;
- mergulha;
- volta à posição.

Serve para ensinar leitura de timing.

---

## 15.3 Nuvem de Ruído

### Papel

Hazard/inimigo estacionário.

### Comportamento

- carrega eletricidade;
- emite descarga em intervalos;
- pode temporariamente ser desativada pelo Pulso.

---

# 16. Hazards

Mundo 1 pode conter:

- mar profundo;
- espinhos naturais estilizados;
- rajada forte;
- onda;
- plataforma quebrável;
- cabo energizado instável;
- queda;
- descarga da tempestade.

Todos precisam de telegraph visual.

---

# 17. Sistema de dano

Para o primeiro build:

```text
Vida máxima: 3
Dano padrão: 1
Invulnerabilidade após dano: 1.0–1.5 s
```

Feedback:

- squash ou recoil;
- flash;
- partículas;
- som;
- breve invulnerabilidade visual.

Cair no vazio pode causar:

- perda de 1 vida e respawn;
ou
- respawn direto.

Recomendação para o protótipo: **respawn direto sem sistema de vidas**.

---

# 18. Boss — Olho da Tempestade

## 18.1 Conceito

Uma tempestade de interferência formada ao redor do grande farol.

O jogador não luta contra uma criatura tradicional, mas contra a própria falha da rede.

## 18.2 Arena

Elementos:

- farol ao fundo;
- duas turbinas laterais;
- rails;
- plataformas móveis;
- vento;
- núcleo no centro da tempestade.

---

## 18.3 Fase 1

Objetivo:

sobreviver e ativar duas turbinas.

Ataques:

- rajadas;
- relâmpagos marcados no chão;
- ondas de interferência.

---

## 18.4 Fase 2

Com turbinas ativas:

- rails aparecem;
- jogador ganha acesso vertical;
- núcleo fica parcialmente exposto.

Objetivo:

usar rail + dash para atingir nós elevados.

---

## 18.5 Fase 3

Núcleo exposto.

O jogador precisa:

1. evitar ataques;
2. usar corrente de vento;
3. alcançar o núcleo;
4. aplicar Pulso de Conexão.

Repetir sequência três vezes.

---

## 18.6 Vitória

Sequência:

- tempestade congela;
- grande pulso ciano;
- nuvens se dissipam;
- farol acende;
- rede inteira do mundo liga;
- câmera abre mostrando a costa;
- portal do Mundo 2 aparece.

---

# 19. Level Design

## 19.1 Regra de introdução de mecânicas

Usar padrão:

**mostrar → ensinar → testar → combinar**

Exemplo para vento:

1. jogador vê partículas subindo;
2. entra em corrente sem perigo;
3. usa corrente para atravessar gap;
4. combina vento + inimigo;
5. combina vento + dash.

---

## 19.2 Linguagem visual

Verde/seguro:
- superfícies estáveis;
- pontos de descanso.

Ciano:
- conexão;
- caminhos interativos;
- rails;
- nodes.

Magenta/roxo corrompido:
- interferência;
- perigo tecnológico.

Vermelho/laranja:
- ambiente natural das falésias.

---

# 20. Câmera

Sistema:

`Camera2D`

Recursos desejados:

- smoothing;
- look-ahead horizontal;
- pequena antecipação vertical;
- limites por setor;
- camera zones;
- shake controlado;
- enquadramento especial em Nexo/Boss.

Evitar câmera excessivamente flutuante.

---

# 21. Parallax

Camadas mínimas:

```text
Layer 0 — Sky
Layer 1 — Far Horizon
Layer 2 — Distant Cliffs
Layer 3 — Midground Structures
Layer 4 — Gameplay
Layer 5 — Near Foreground
Layer 6 — Foreground Silhouettes
```

O personagem deve permanecer sempre legível contra o fundo.

---

# 22. Direção de arte

## 22.1 Estilo

Pixel art moderna.

Não usar visual 8-bit.

Características:

- pixels deliberados;
- alta legibilidade;
- silhuetas fortes;
- iluminação atmosférica;
- emissivos;
- partículas;
- animações fluidas.

## 22.2 Paleta

Base:

- azul profundo;
- turquesa;
- ciano;
- terracota;
- verde costeiro.

Interferência:

- violeta;
- magenta.

## 22.3 Regra de consistência

Após aprovar o concept principal do Mundo 1, ele deve ser usado como referência para:

- tiles;
- props;
- enemies;
- checkpoints;
- portals;
- VFX;
- boss.

---

# 23. Assets necessários

## 23.1 Cenário

Obrigatórios:

- sky;
- lua;
- nuvens;
- horizonte oceânico;
- falésias distantes;
- midground cliffs;
- gameplay cliffs;
- foreground vegetation;
- mar;
- espuma;
- dunas;
- pedras;
- vegetação;
- ilhas flutuantes.

## 23.2 Tiles

- ground center;
- left edge;
- right edge;
- inner corner;
- outer corner;
- slope up;
- slope down;
- isolated platform;
- thin platform;
- cracked tile;
- sand transition;
- grass transition.

## 23.3 Props

- farol;
- turbina;
- jangada;
- poste de sinal;
- boia;
- pequenas antenas;
- pedras;
- arbustos;
- coqueiros;
- cabos;
- caixas/estruturas tecnológicas sutis;
- repetidores;
- portal.

## 23.4 Interativos

- Ponto Brisa;
- Nó de Sinal;
- Nexo;
- rail emitter;
- vento emitter;
- plataforma móvel;
- plataforma quebrável;
- botão/node;
- porta de energia.

## 23.5 Coletáveis

- Fragmento de Conexão;
- Memória de Sinal;
- Núcleo do Mundo.

## 23.6 Inimigos

- Ruídozinho;
- Gaivota de Interferência;
- Nuvem de Ruído;
- boss components.

---

# 24. Animações necessárias do Brisinho

## Prioridade P0

Essenciais para um build jogável:

- Idle;
- Run;
- Jump Start;
- Jump Up;
- Fall;
- Land;
- Dash;
- Hit.

## Prioridade P1

- Turn;
- Interact;
- Pulse;
- Rail;
- Celebrate;
- Respawn.

## Prioridade P2

- Idle Variation;
- Look Up;
- Look Down;
- Skid;
- Near Edge;
- Portal Enter;
- Portal Exit.

---

# 25. Pipeline dos vídeos do Brisinho

Cada vídeo deve passar por:

1. extração de frames;
2. remoção de frames repetidos;
3. definição de FPS útil;
4. recorte;
5. remoção/normalização de fundo;
6. estabilização;
7. alinhamento por pivot;
8. normalização de escala;
9. verificação de consistência;
10. montagem de sprite sheet;
11. geração de metadata;
12. importação no Godot.

## Pivot recomendado

O pivot principal deve ser próximo ao ponto de contato do personagem com o chão.

Isso evita “tremor” ao alternar animações.

---

# 26. VFX

Necessários:

- poeira ao correr;
- impacto ao aterrissar;
- dash trail;
- afterimage;
- pulse ring;
- fragment pickup;
- checkpoint activation;
- Nexo activation;
- rail sparks;
- wind particles;
- water splash;
- enemy hit;
- player hit;
- boss lightning;
- world reconnect pulse.

VFX devem reforçar ações, não esconder gameplay.

---

# 27. Áudio

## 27.1 Música

Camadas sugeridas:

### Offline
- ambiente;
- vento;
- mar;
- base musical simples.

### Online
Adicionar:
- percussão;
- melodia;
- textura energética.

Isso permite que conexão também seja percebida pelo som.

## 27.2 SFX do jogador

- jump;
- land;
- dash;
- pulse;
- hit;
- pickup;
- rail enter;
- rail loop;
- rail exit.

## 27.3 SFX do mundo

- wind;
- waves;
- lighthouse;
- turbine;
- checkpoint;
- node activation;
- connection pulse;
- portal.

## 27.4 SFX inimigos

Sons separados para:

- idle;
- attack;
- hit;
- defeat.

---

# 28. UI / HUD

HUD inicial deve ser mínimo.

Elementos:

- energia/vida;
- contador de Fragmentos;
- ícone de dash quando necessário;
- objetivo contextual;
- indicador de conexão do setor.

Evitar elementos permanentes que não sejam essenciais.

---

# 29. Telas

Necessárias para primeira versão:

- splash;
- menu principal;
- seleção/continuar;
- pause;
- settings;
- gameplay HUD;
- tela de conclusão do Mundo 1.

Para vertical slice interno, splash/menu podem ser simples.

---

# 30. Acessibilidade mínima

Implementar desde o início:

- volume separado música/SFX;
- intensidade de screen shake;
- remapeamento de controles quando viável;
- contraste suficiente entre jogador e fundo;
- evitar depender apenas de cor;
- opção de reduzir flashes intensos;
- textos legíveis.

---

# 31. Arquitetura Godot

Estrutura recomendada:

```text
res://
├── assets/
│   ├── player/
│   ├── world_01/
│   ├── enemies/
│   ├── ui/
│   ├── audio/
│   └── vfx/
│
├── scenes/
│   ├── player/
│   │   └── player.tscn
│   ├── world_01/
│   │   ├── world_01.tscn
│   │   ├── sector_a.tscn
│   │   ├── sector_b.tscn
│   │   ├── sector_c.tscn
│   │   ├── sector_d.tscn
│   │   └── boss_arena.tscn
│   ├── enemies/
│   ├── interactables/
│   ├── ui/
│   └── vfx/
│
├── scripts/
│   ├── player/
│   ├── enemies/
│   ├── systems/
│   ├── interactables/
│   └── world/
│
├── data/
└── autoload/
```

---

# 32. Player Scene

Estrutura sugerida:

```text
Player (CharacterBody2D)
├── VisualRoot
│   ├── AnimatedSprite2D
│   ├── Effects
│   └── Trail
├── CollisionShape2D
├── GroundCheck
├── InteractionArea
├── Hurtbox
├── StateMachine
├── Audio
└── Timers
```

---

# 33. Sistemas globais

Autoloads sugeridos:

## GameManager

Responsável por:

- estado de jogo;
- troca de cenas;
- pause.

## SaveManager

Responsável por:

- checkpoints;
- progresso;
- configurações;
- coletáveis importantes.

## AudioManager

Responsável por:

- música;
- SFX globais;
- transições de layers.

## WorldState

Responsável por:

- nodes restaurados;
- conexão do setor;
- boss derrotado;
- alterações persistentes.

---

# 34. Interações via Signals

Usar signals para reduzir acoplamento.

Exemplos:

```gdscript
signal node_activated(node_id)
signal checkpoint_reached(checkpoint_id)
signal fragment_collected(amount)
signal sector_connected(sector_id)
signal player_damaged(amount)
signal boss_phase_changed(phase)
```

---

# 35. Dados configuráveis

Sempre que possível, evitar valores espalhados em scripts.

Criar Resources para:

- player tuning;
- enemy stats;
- collectible values;
- audio settings;
- level parameters.

Isso facilita ajustes sem alterar código central.

---

# 36. Colisões

Layers sugeridas:

```text
1 Player
2 World
3 OneWayPlatform
4 Enemy
5 Hazard
6 PlayerAttack/Pulse
7 Interactable
8 Collectible
9 Trigger
10 Rail
```

Manter collision matrix documentada.

---

# 37. Save e progresso

Salvar no mínimo:

- último checkpoint;
- Fragmentos coletados relevantes;
- Memórias de Sinal;
- Nexos ativados;
- boss derrotado;
- settings.

Não é necessário salvar posição exata do jogador a cada frame.

---

# 38. Performance

Meta inicial:

**60 FPS**

Resoluções base sugeridas:

- viewport interno coerente com pixel art;
- upscale inteiro quando possível;
- teste em 1920×1080.

Boas práticas:

- atlases;
- reduzir overdraw;
- limitar partículas;
- pooling para efeitos repetidos;
- evitar centenas de nodes ativos fora da câmera;
- usar visibility/enabling por setor quando necessário.

---

# 39. Debug Tools

Implementar cedo:

- F1: mostrar hitboxes;
- F2: mostrar velocidade;
- F3: mostrar estado do player;
- F4: teleporte para checkpoint;
- F5: reiniciar setor;
- comando para ativar/desativar invencibilidade;
- painel simples com FPS.

Isso acelera muito o desenvolvimento.

---

# 40. Métricas úteis de playtest

Registrar manualmente ou via debug:

- mortes por área;
- tempo por setor;
- checkpoints alcançados;
- colecionáveis perdidos;
- pontos onde jogador para sem entender;
- falhas em tutorial;
- dificuldade do boss.

---

# 41. Vertical Slice 0.1

O primeiro teste não precisa conter o Mundo 1 inteiro.

## Conteúdo obrigatório

```text
Spawn
→ Movimento
→ Primeiro Fragmento
→ Pulo
→ Corrente de vento
→ Ruídozinho
→ Checkpoint
→ Rail
→ Dash
→ Nó de Sinal
→ pequena transformação do cenário
→ Portal/Fim
```

Duração:

**3–6 minutos**

---

# 42. Assets mínimos para o Vertical Slice

## Player

- Idle;
- Run;
- Jump;
- Fall;
- Land;
- Dash.

## Cenário

- background;
- midground;
- foreground;
- tileset básico;
- 5–8 props.

## Gameplay

- Fragmento;
- Ponto Brisa;
- Nó;
- rail;
- vento;
- plataforma móvel.

## Enemy

- Ruídozinho.

## VFX

- pickup;
- dash;
- checkpoint;
- node activation;
- wind.

## Audio

- jump;
- land;
- dash;
- pickup;
- checkpoint;
- ambient;
- música.

---

# 43. Critérios de pronto — Vertical Slice

O build só é considerado aprovado quando:

- Brisinho responde bem ao controle;
- não existem saltos impossíveis;
- câmera não causa desconforto;
- colisões são previsíveis;
- sprite não “treme” entre animações;
- checkpoint funciona;
- morte/respawn funciona;
- conexão altera claramente o cenário;
- rail funciona sem prender o jogador;
- não existem softlocks conhecidos;
- FPS permanece estável;
- início e final da demo são claros.

---

# 44. Critérios de pronto — Mundo 1 completo

O Mundo 1 está pronto quando:

- os cinco setores estão jogáveis;
- todas as mecânicas possuem introdução;
- três inimigos estão implementados;
- boss completo;
- três Memórias de Sinal escondidas;
- checkpoints equilibrados;
- áudio completo;
- VFX essenciais;
- estado offline/online funcionando;
- progresso salva corretamente;
- transição para o próximo mundo funciona;
- playtest completo sem blocker.

---

# 45. Ordem recomendada de implementação

## Sprint 1 — Character Controller

1. Player scene;
2. movimento;
3. pulo;
4. coyote time;
5. jump buffer;
6. dash;
7. animações básicas;
8. câmera.

## Sprint 2 — Ambiente

1. tiles;
2. colisões;
3. parallax;
4. foreground;
5. água;
6. props.

## Sprint 3 — Core Loop

1. Fragmentos;
2. Nodes;
3. Ponto Brisa;
4. respawn;
5. conexão offline/online.

## Sprint 4 — Mecânicas

1. vento;
2. rail;
3. plataformas móveis;
4. Pulso de Conexão.

## Sprint 5 — Enemy

1. Ruídozinho;
2. Gaivota;
3. Nuvem.

## Sprint 6 — Polish

1. VFX;
2. SFX;
3. música dinâmica;
4. camera shake;
5. UI.

## Sprint 7 — Boss

1. arena;
2. ataques;
3. fases;
4. vitória;
5. sequência final.

---

# 46. Riscos principais

## Arte gerada sem consistência

Mitigação:

usar sempre concept aprovado como referência.

## Animação com jitter

Mitigação:

normalizar pivot e escala antes da importação.

## Cenário bonito mas ruim para jogar

Mitigação:

construir blockout antes da arte final.

## Escopo crescer demais

Mitigação:

aprovar primeiro o Vertical Slice 0.1.

## Mecânica de conexão ser apenas cosmética

Mitigação:

fazer conexão alterar caminhos e sistemas de gameplay.

---

# 47. Regra de produção de fase

A ordem correta deve ser:

```text
Blockout
→ Teste de movimento
→ Teste de câmera
→ Teste de dificuldade
→ Mecânicas
→ Colisões finais
→ Arte
→ VFX
→ Áudio
→ Polish
```

Evitar construir a fase diretamente em cima de uma imagem pronta.

A arte deve servir ao level design, não substituir o level design.

---

# 48. Checklist de arquivos para começar a implementação

## Brisinho

- [ ] vídeos de Idle;
- [ ] vídeos de Run;
- [ ] vídeos de Jump;
- [ ] vídeos de Fall;
- [ ] vídeos de Land;
- [ ] vídeo de Dash;
- [ ] vídeo de Hit;
- [ ] referência oficial do personagem.

## Mundo 1

- [ ] concept principal;
- [ ] background;
- [ ] midground;
- [ ] foreground;
- [ ] tiles;
- [ ] farol;
- [ ] turbina;
- [ ] jangada;
- [ ] checkpoint;
- [ ] node;
- [ ] portal;
- [ ] rail;
- [ ] coletável;
- [ ] Ruídozinho.

## Áudio

- [ ] música;
- [ ] ambience;
- [ ] jump;
- [ ] dash;
- [ ] pickup;
- [ ] checkpoint.

Itens ausentes podem usar placeholders.

---

# 49. Definition of Done técnica

Cada feature deve ter:

- funcionamento;
- feedback visual;
- feedback sonoro quando aplicável;
- tratamento de edge cases;
- integração com respawn;
- teste em teclado;
- teste em gamepad quando aplicável;
- ausência de erro no console;
- parâmetros expostos para tuning.

---

# 50. Próximo passo recomendado

Com os assets e vídeos disponíveis, o próximo passo deve ser produzir:

**Brisinho — Mundo 1 Vertical Slice 0.1**

Escopo:

```text
1 pequeno trecho jogável
1 checkpoint
1 inimigo
1 corrente de vento
1 rail
1 Nó de Conexão
1 transformação offline → online
1 portal de saída
```

Esse build será a referência para todas as decisões seguintes de:

- escala do personagem;
- velocidade;
- tamanho das plataformas;
- câmera;
- densidade visual;
- tamanho dos tiles;
- FPS das animações;
- intensidade dos VFX;
- dificuldade.

Depois de validar esse trecho, o restante do Mundo 1 deve ser produzido sobre a mesma base técnica.
