# Dicas contextuais — 01/10/2026

## Erros encontrados e correções

| Erro | Correção integrada no fonte | Regra preventiva sugerida |
| --- | --- | --- |
| Placas de tutorial desenhadas permanentemente sobre o mundo | `world.gd` não desenha `level.signs`; `context_tip()` calcula a dica a partir dos objetos e do estado atuais | Tutorial aparece somente quando a ação é relevante, disponível e próxima; esconder imediatamente ao sair ou concluir |
| Prompt do Nó acompanhava o personagem e mudava de posição vertical | Faixa SVG em uma região segura de 112–196 px, abaixo do HUD | Todas as dicas usam um único espaço sob o HUD; menus e avisos de evento têm prioridade |
| Instruções antigas podiam descrever inimigos invisíveis, derrotados ou ações em recarga | Dicas verificam inimigo vivo/visível, estado Offline/Online, cooldown e disponibilidade reais | Elegibilidade deve compartilhar condições da mecânica, não só distância a uma placa |
| Dicas permanentes ou repetidas poluem a tela | Orçamento acumulado de 4,5 s por contexto; reentrada não reinicia; respawn restabelece as dicas pertinentes | Tempo é limitado e só conta enquanto visível; não repetir dicas no mesmo encontro |
| Hélices procedurais recobriam rotores que já estavam pintados no fundo | Removido loop de círculos/linhas sobre o PNG; fundo anterior continua estático | Não animar objeto pintado sobrepondo nova geometria sem separar e remover a camada original; aprovar novo conceito antes de substituir o fundo |

## Contextos implementados

Prioridades: Nó Offline acionável; inimigo vivo próximo; saída/entrada no rail; corrente de vento; pedra desmoronável; lacuna real com dash pronto; portal Online próximo; controles iniciais no spawn.

A dica some durante dash, respawn e conclusão. Dicas de inimigos somem ao derrotar/atordoar/esconder a ameaça. Instrução do Nó some ao conectar ou entrar em cooldown. Nenhuma nova imagem de fundo foi integrada; esta revisão apenas remove o tratamento de turbinas rejeitado.

## Verificação

- Godot 4.5.1 headless, `--fixed-fps 60`, diretórios `XDG_DATA_HOME` isolados e `-- --test`.
- `context_hints.tscn`: 25 verificações passaram; 0 falharam. Inclui proximidade, saída, conclusão, cooldown, estados ocultos, prioridade de notificações, pausa, tempo máximo, ausência de repetição, respawn, posição abaixo do HUD, rail, lacuna real, plataforma acima do jogador, inimigo atordoado e portal Offline/Online.
- `ui_integration.tscn`: 38 verificações passaram; 0 falharam.
- Verificação por lógica e geometria do HUD; prévia composta usa SVGs e fonte bitmap reais, mas não substitui captura do jogo no navegador.
