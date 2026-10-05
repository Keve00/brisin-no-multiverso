# Auditoria de apoio dos Ruídozinhos — 01/10/2026

## Erros encontrados

| Encontro | Erro | Correção |
| --- | --- | --- |
| Terceiro | Patrulha 6900–7090 em y340 usava a caixa nominal de `steps_0`; a colisão real possui três patamares com alturas distintas. Os pés não estavam sobre uma superfície. | Patrulha 6630–6718 em y340, sobre a plataforma plana 6500–6750; reserva 130 px desde a borda esquerda para aterrissagem e reação. |
| Quinto | Limites invertidos 8220–7440 em y100, sem superfície nessa posição; o código alternava entre dois extremos desconectados. | Patrulha 8240–8310 em y205, sobre a plataforma de sinal 8210–8340, disponível Online. |
| Movimento / presença | Inimigos guardavam y fixo e não conheciam o corpo de apoio, permitindo flutuação e contato sem plataforma. | Cada patrulha resolve uma colisão real e usa limites e altura locais ao corpo. Movimento, ausência Offline e recuperação acompanham o apoio. |
| Derrota / conexão | Uma atualização de presença Online podia tornar uma derrota concluída visível. | O inimigo conserva o estado de animação concluída e corrige presença sem ressuscitar até reinício. |

A primeira correção geométrica em 6530–6718 passou nos testes de apoio, mas falhou no percurso completo: o jogador aterrissava diretamente no contato do inimigo na borda da plataforma, antes de conseguir acionar dash no chão. A patrulha foi recuada para 6630–6718. O desafio foi mantido, sem alterar o piloto de testes nem teleportar o jogador.

## Pivô e margens

O sprite usa frames 48 × 48, escala uniforme 2 e offset (0, −16). Nas animações vivas o conteúdo termina em y40: `(40 − 24 − 16) × 2 = 0`, portanto os pés coincidem com a posição da instância. A silhueta horizontal ocupa x12–35: sua meia largura máxima é 24 px na escala final. A margem de patrulha é 26 px em relação às bordas da colisão, preservando 2 px de folga.

A vinculação compara as superfícies dos `CollisionShape2D`, não a caixa nominal do nível, especialmente em plataformas com degraus. Uma patrulha inválida no mundo gera erro e permanece invisível, evitando um inimigo flutuando com dano ativo.

## Validação executada

- `godot/tests/enemy_placement.tscn`, Godot 4.5.1 headless com dados temporários e `-- --test`: **417 verificações, zero falhas**.
- Cinco encontros amostrados por 640 ticks de física, cobrindo mais de um ciclo de movimento da plataforma de sinal e as duas bordas das patrulhas.
- Conferidos os limites ordenados, apoio real, margem horizontal, pivô vertical, ausência Offline, pulso sem presença, derrota após sincronização Online e reinício junto à plataforma.
- Tolerância vertical de 0,25 px apenas para a leitura imediatamente anterior ao tick de física: `AnimatableBody2D` aplica o transform sincronizado no fim do tick. A posição visual é sincronizada novamente em `_process`, antes do desenho.
- `godot/tests/integration.tscn`, `--fixed-fps 60 -- --test`: **25 verificações, zero falhas**; travessia completa até o portal por inputs, sete saltos na extensão e posição final (9306,78; 279,93).
- Caixas de conteúdo dos sprites foram medidas pela transparência dos PNGs. Esta auditoria comprova geometria e estados por execução headless; a revisão visual no navegador pertence à integração final.

## Regras preventivas propostas

1. Validar limites `left <= right` e pés sobre uma superfície real de colisão, com margem baseada na silhueta visível. Plataformas com degraus não equivalem ao retângulo nominal do JSON.
2. Associar o encontro ao corpo de apoio; usar coordenadas locais para plataformas móveis e sincronizar simulação/presença com Offline, Online e ausência temporária.
3. Não reativar um encontro derrotado ao atualizar a presença da plataforma; somente um reinício explícito recupera vida e animação.
4. Reservar espaço de aterrissagem e reação em entradas obrigatórias. Validar a travessia com combate disponível, sem colocar dano instantâneo no primeiro contato com o chão.
5. Testar apoio ao longo de um ciclo inteiro de movimento e nas bordas, além de spawn, derrota e reinício. Não considerar uma posição inicial correta como prova de toda a patrulha.
