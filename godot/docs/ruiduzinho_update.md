# Ruídozinho animado

SpriteFrames usa cinco animações em canvas de 48 × 48, com filtro Nearest, escala 2 e pivot na linha de contato dos pés.

- Patrulha: movimento existente e espelhamento na mudança de direção.
- Alerta: breve pausa quando Brisinho se aproxima; retoma a patrulha ao terminar.
- Pulso: reproduz hit, mantém idle enquanto atordoado e retoma patrol.
- Stomp/dash: alive=false imediatamente; hit → defeated → invisible. A derrota lógica e o bounce não esperam a animação.
- Reset: interrompe a sequência em andamento, restaura visibilidade e inicia patrol.

Verificado no Godot 4.5.1: 12 verificações em tests/enemy_animation.tscn e 25 no percurso completo em tests/integration.tscn com --test. A tentativa de captura com Xvfb não teve display X11 disponível; não houve QA visual de uma sessão web nesta atualização.
