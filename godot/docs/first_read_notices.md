# Primeira leitura de avisos

Na primeira entrada, COMEÇAR AVENTURA oferece FAZER TUTORIAL e PULAR TUTORIAL. Avisos e dicas só pausam na primeira apresentação quando o jogador escolhe FAZER TUTORIAL nessa primeira sessão. O botão ENTENDI • CONTINUAR recebe foco; clique, Enter ou A confirmam depois de 0,25 s. Esc não dispensa a leitura.

A confirmação é salva por tipo de instrução, inclusive movimento, combate, chips, vento, rail, pedra, dash, nó e portal. Dicas iguais em outras plataformas não pausam novamente; os avisos reconhecidos conservam o comportamento transitório. Nova aventura limpa as confirmações da fase, mas preserva a escolha e o registro de que o jogador já jogou; não oferece tutorial novamente. Visitas posteriores não ativam pausas. Saves legados sem tutorial_choice_made precisam decidir antes de iniciar; o progresso existente é preservado. Sem tutorial, dicas e eventos permanecem transitórios.

A fila preserva os avisos recebidos atrás de menus. Gameplay fica congelado, HUD e som do aviso continuam ativos, e a retomada limpa inputs de salto e ataques.

Validação: testes Godot headless de primeira leitura, pausa física, fila, confirmação, persistência, Esc e dicas reconhecidas; controles F/Y e remoção de B no teclado. Layout reutiliza os assets do HUD/menu existentes. Não foi realizada inspeção visual em navegador nesta revisão.

A escolha usa tutorial_choice_made/tutorial_opted_in persistidos, independente de has_played, com tutorial_session_active temporário. Carregar progresso desativa a sessão tutorial. Os testes tutorial_choice cobrem os dois botões, primeiro jogador, jogador recorrente, nova aventura, persistência e migração de saves legados.
