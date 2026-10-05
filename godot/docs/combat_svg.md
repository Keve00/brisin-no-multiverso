# Combate SVG — 01/10/2026

## Contrato integrado

- Pulso: onda centrada no ponto do disparo `(Brisin.x, Brisin.y - 35)`, duração 0,55 s e raio máximo 140 px. A expansão usada pelo combate é a mesma da camada SVG. O contato usa o corpo visível do Ruídozinho (52 × 56 px), não o pivô no chão. A onda aplica um único hit por encontro, com reação `hit`, recuo e atordoamento de 2 s; dash, stomp e chips derrotam o inimigo. Movimentos entre ticks são amostrados em passos relativos de até 4 px para não atravessar a borda da onda.
- Dash e pulso: geometria SVG em laranja/amarelo/branco, preenchimentos opacos; o interior sem geometria do anel permanece transparente. Os ecos encolhem e desaparecem em vez de perder saturação por alpha. Flashes reduzidos diminuem densidade de faíscas, mantendo cores e alcance.
- Chip: nano-SIM de 24 × 28 px, corpo branco e contatos dourados. `B` no teclado, `Y` no controle. Nasce 24 px à frente e 35 px acima do pivô dos pés, segue a direção atual, voa a 760 px/s e termina em até 500 px. Intervalo entre disparos: 0,35 s. O primeiro contato entre parede e inimigo interrompe o voo e produz fragmentos por 0,18 s.
- Colisão SIM: varredura da caixa inteira pelo segmento, consulta das camadas de chão/sinal `2 | 4`, interseção relativa ao movimento dos inimigos. O teste inclui parede fina, nascimento sobreposto, ambos os sentidos e alvo que cruza a altura do voo entre ticks.
- Pausa congela onda, voo e cooldown. Respawn/Disabled removem ataques ativos e rejeitam novos; `bounce()`/`hurt()` não alteram Disabled. Respawn reinicia cooldowns de pulso e chip.

## Erros encontrados e prevenção

1. Distância ao pivô dos pés excluía inimigos cuja silhueta já estava na onda, e o hit imediato não acompanhava a animação. Centralizar a expansão e testar alcance pelo corpo, tempo de chegada e reação visual.
2. Consultar somente o retângulo atual do inimigo pode perder um alvo que atravessou o segmento entre ticks. Usar varredura relativa ao corpo anterior e ordenar a simulação depois da patrulha/superfície.
3. Fade/alpha dos preenchimentos apagava a identidade dos ataques. Manter preenchimentos saturados em alpha 1; acessibilidade altera quantidade de partículas, sem flash de tela.
4. Métodos externos de stomp podiam retirar o jogador de Disabled durante a entrada do portal. Proteger ações de combate e movimento nos estados Disabled/Respawn.

## Verificação

Suíte dedicada: `res://tests/combat_svg.tscn`, execução com `-- --test` e diretório de dados isolado. Resultado em Godot 4.5.1: **35/35 verificações passaram**, com dados isolados. A suíte existente `action_effects_svg.tscn` também passou **13/13**, cobrindo SVGs carregados, direções do dash, duração finita, origem fixa do pulso e limpeza dos efeitos.

Prévia dos assets renderizada com Inkscape e revisada em `qa/combat_svg_preview.png`: corpo branco do SIM, bordas e faíscas saturadas, transparência somente na região sem geometria e proporções originais. Essa revisão é estática; a apresentação em movimento no navegador faz parte da integração final.

Importação/compilação, testes de colisão e revisão de imagem são evidências distintas.
