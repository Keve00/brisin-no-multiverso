# Entrada no portal — auditoria

A entrada é uma sequência finita de 1,8 s, controlada pelo Godot com SVGs reais (`ring.svg`, `spiral.svg`, `spark.svg` e, na revisão abaixo, `tunnel.svg`, `arcs.svg`, `spark_amber.svg`). O pivô da abertura coincide com o núcleo em `(0, -100,5)` relativo ao marcador. Os SVGs têm canvas centrado e margem para rotação; o wrapper do sprite preserva a escala original do corpo e da câmera.

## Sequência

- 0–0,35 s: abertura e preparação do sinal; Brisin mantém os pés no ponto de entrada.
- 0,35–1,35 s: atração suave para a abertura; somente o wrapper visual reduz a escala uniformemente.
- 1,35–1,75 s: a abertura fecha depois que o personagem entrou.
- 1,8 s: salvar conclusão, emitir `finished` uma única vez e mostrar o resultado.

Durante toda a sequência o jogador permanece `DISABLED`, a simulação de combate é limpa e os inimigos são suspensos. Dicas são removidas e o menu não interrompe a entrada.

## Erros encontrados e corrigidos

| Erro | Prevenção |
| --- | --- |
| ID desconhecido poderia bloquear o jogador | Aceitar somente um marcador de portal existente |
| Marcador consumido durante respawn | Não ativar em `RESPAWN` ou `DISABLED`; mundo confirma o latch |
| Desconexão deixava jogador atraído para dentro do portal | Restaurar pés, parent do sprite e estado, preservando o processamento anterior dos inimigos |
| Remover efeito diretamente deixava wrapper/latch | Cleanup idempotente na saída da árvore e cancelamento no descarte antecipado |
| Callback antecipado/repetido podia concluir/salvar | Exigir sequência finalizada com idade completa e um latch exclusivo de conclusão |
| Efeito malformado acessava jogador ausente | Validar referências antes de preparar a sequência e liberar com segurança |
| Cancelamento reiniciava a entrada no frame seguinte porque os pés ainda tocavam o marcador | Exigir saída do raio de 85 px antes de rearmar a aproximação automática de 65 px |

## Evidências

`docs/portal_qa/keyframes.png` (fora de `res://`) foi renderizado com Inkscape e inspecionado: quatro instantes (0, 0,7, 1,3 e 1,6 s) das camadas do efeito, mantendo o centro e a margem de rotação. Esse painel verifica os SVGs; não representa uma captura do jogo.

`tests/portal_transition.tscn` exercita a sequência real, guardas, cancelamento, salvamento, singleton, descarte, malformed effect e conclusão. Executado após importação coordenada, em Godot 4.5.1, com dados isolados (`XDG_DATA_HOME=/tmp/brisin-portal-lifecycle`) e `-- --test`: **21 verificações, 0 falhas**, incluindo descarte direto e unload durante atração, sem erros de runtime. `git diff --check` também passou. Esta suíte confirma lógica e ciclo de vida; a revisão visual do jogador entrando no portal requer captura/navegador.

## Revisão visual — portal com profundidade e fluxo contínuo

O núcleo disponível agora tem terraços de profundidade (`tunnel.svg`), pistas escalonadas (`arcs.svg`) girando no sentido oposto ao núcleo existente e oito pequenos pacotes ciano seguindo curvas de fora para dentro. A moldura original e o `portal_rotor` pai permanecem imóveis: girar o pai completo impedia diferenciar a camada rígida do fluxo interno. O centro continua `(0, -100,5)` e a base/pivô do portal não mudam.

Na entrada, o fundo do túnel fica atrás de duas camadas de arcos, do vórtice e dos anéis. A carga do núcleo cresce nos primeiros 0,35 s, sem mover os pés; a atração segue a mesma curva suave com um arco vertical de até 12 px entre os mesmos endpoints. O wrapper continua uniformemente reduzido. Partículas opacas ciano e douradas seguem trajetórias curvas, e a população esvazia durante o fechamento em vez de ressurgir na borda enquanto a abertura desaparece. O tempo permanece exatamente 1,8 s, com os mesmos limites das três fases e a mesma lógica de conclusão/cancelamento.

Erros adicionais encontrados:

- O modo de flashes reduzidos não limitava a animação de entrada: aplicava sempre 14 partículas e a mesma velocidade. Agora há oito partículas nesse modo (18 no normal), contrarrotação mais lenta e menor amplitude auxiliar; não há flash de tela nem fade dos pacotes.
- Colorir uma faísca ciano em dourado por multiplicação gera verde. `spark_amber.svg` tem paleta dourada própria; as faíscas não dependem dessa correção por modulate.
- O teste antigo exigia rotação do pai inteiro. A verificação passou a exigir moldura/pai fixos e movimento das camadas internas Online, com o interior parado Offline.

Para reproduzir a inspeção de keyframes: execute `tools/portal_visual_samples.gd` com o projeto Godot e `-- --test`, depois `python tools/preview_portal_svg.py /tmp/brisin-portal-samples.json docs/portal_qa/keyframes_polished.svg`. O sampler grava transforms dos nós reais nos três instantes do portal disponível e em seis instantes da entrada, nos modos normal e reduzido. O SVG de comparação usa os assets reais, escalas, rotações, posições, alpha e ordem de camadas extraídos do motor. A rasterização via Inkscape é uma composição verificável dos assets do portal, sem renderizar o jogador; não equivale a captura de framebuffer ou validação no navegador.

Evidência desta revisão: `docs/portal_qa/keyframes_polished.png` foi rasterizado e inspecionado em 15 quadros (3 de disponibilidade, 6 de entrada normal e 6 em flashes reduzidos). A primeira renderização mostrou o anel de entrada grosseiro e quadrado diante da moldura circular original: `tools/build_portal_assets.py` passou a gerar anéis, pistas e vórtice em células vetoriais de uma unidade, preservando os canvases/pivôs e o tamanho exibido. A revisão final tem abertura circular em pixels, centro escuro, pistas separadas, partículas pequenas e fechamento progressivo, sem invadir a moldura fixa.

Godot 4.5.1 headless com `--fixed-fps 60`, `-- --test` e dados isolados: lifecycle do portal **23 verificações, 0 falhas** (incluindo redução real da população de partículas e opacidade preservada); cenário **13 verificações, 0 falhas**, incluindo moldura fixa e contrarrotação Online. `git diff --check` passou. A amostragem de nós também rodou sem erros de runtime. A composição não inclui o Brisin e não substitui captura no navegador; a atração/cleanup continuam cobertos por lifecycle.
