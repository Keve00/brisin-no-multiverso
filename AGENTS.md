# Regras de desenvolvimento — Brisin

## Vento e gemas — conceito aprovado

- Vento usa curvas SVG claras, partículas e folhas animadas pelo motor; não use setas ou chevrons. O movimento segue a força da região e mantém a área de colisão existente.
- Gemas coletáveis são laranja, com facetas douradas, contorno escuro e brilho pulsante. A silhueta tem aproximadamente 24 × 32 pixels lógicos; o canvas de 48 × 56 reserva margem para halo e faíscas.
- O pulso varia suavemente o brilho e a escala uniforme em até 6%, mantendo o pivô fixo. Com flashes reduzidos, usar menor amplitude de escala e luz, preservando a pulsação.
- SVGs são importados como texturas com filtro nearest-neighbor; animação é controlada pelo Godot e deve funcionar no export web.

Estas regras se aplicam ao código-fonte Godot, aos assets e ao carregador web deste projeto. A auditoria que motivou as regras está em `godot/docs/proportion_audit.md`.

## Nome e direção visual da interface

- Use **Brisin** como nome apresentado ao jogador, incluindo logotipo, tela inicial, menus, carregamento, avisos e textos da página do jogo. A grafia do logotipo pode ser `BRISIN`. Não use `Brisinho` em novos textos visíveis; nomes técnicos legados podem permanecer até uma migração específica.
- Tela inicial, menus, HUD, configurações, avisos e conclusão devem seguir a estética 8 bits do jogo: tipografia em pixels legível, bordas escalonadas, ícones na mesma grade e sombras curtas. Preserve as proporções do personagem e dos objetos.
- Priorize **laranja e amarelo na interface**: laranja `#FF7A00` em ações principais, âmbar `#FFB000` em foco/seleção e amarelo `#FFD84D` em contornos, ícones e destaques. Use superfícies escuras quentes (`#241508` / `#3B220C`) e texto creme `#FFF3CD` para contraste.
- A identidade dos controles e avisos deve ser quente e consistente. O ciano existente no mar, nos rails e nas conexões do cenário pode continuar; não o adote como cor dominante de botões, molduras ou demais componentes da interface.
- Diferencie Offline, Conectando e Online por rótulos e ícones, além de variações da paleta. Não dependa somente de cor para comunicar estados ou foco.
- Mantenha HUD e avisos dentro da área segura. Avisos transitórios devem deixar personagem, superfície das plataformas e obstáculos visíveis.
- Corrija e confira grafia, acentos e legibilidade dos textos antes de integrar qualquer conceito gerado como imagem. Imagem conceito não é fonte definitiva para texto de interface.
- O usuário aprovou o conceito com nome Brisin e paleta laranja/amarela em 30/09/2026. Integre essa direção como interface SVG animada, separando camadas para foco dos botões, sinais, entrada/saída de avisos e efeitos de conexão. A opção de reduzir flashes deve manter também o aviso visual de dano sem piscadas rápidas.
- Novas versões e variações de inimigos devem preservar a identidade da família e a escala dos pixels. Todas as poses de uma variante precisam compartilhar canvas, pivô de chão, escala base e margens. Entregue estados de dano e derrota visíveis, duração e loop documentados e confira os frames renderizados antes de integrá-los.
- Separe assets preparados para expansão de inimigos efetivamente usados na fase publicada. Não declare uma variação integrada se ela só estiver no pacote de assets ou na prévia. Subagentes devem devolver arquivos verificáveis; a integração exige revisão independente das proporções, textos, estados e interações relevantes.
- Brisin no menu deve acenar e preparar-se para correr ao iniciar a aventura. Preserve a identidade dos sprites de referência, pivô de chão, escala uniforme e conexão dos braços/pernas ao corpo. A animação de preparação é finita: bloqueie comandos repetidos e mantenha o jogo pausado até concluir uma única transição. Continuar preserva progresso; nova aventura consome o desvio da tela inicial somente uma vez após recarregar.

## Não deformar a arte para caber no cenário

- Preserve a proporção original de cada objeto. A transformação base deve usar a mesma escala nos eixos X e Y; espelhamento horizontal pode inverter somente o sinal, sem alterar a magnitude.
- Não passe largura e altura independentes para `draw_texture_rect` de um objeto inteiro. Calcule uma escala uniforme a partir de uma dimensão ou use `min(largura_disponível/largura_fonte, altura_disponível/altura_fonte)` para caber no espaço.
- Não use a largura da colisão como largura obrigatória de um sprite. Colisões e arte têm responsabilidades distintas. Mantenha a superfície de contato legível e ajuste posicionamento, composição ou geometria do nível quando necessário.
- Plataformas, pontes e rails de comprimento variável devem usar módulos repetidos, recorte com escala uniforme ou geometria procedural. Não alongue a ilha, o cabo ou a jangada completos para cobrir o comprimento.
- Recorte ou repetição intencional deve ser explícito no código e preservar a escala dos pixels e as proporções internas. Recorte não é autorização para cortar pés, antenas, pás, rosto ou partes importantes sem documentação.
- Não corrija um objeto estreito alargando só X, nem um objeto baixo aumentando só Y. Corrija a escala uniforme e o enquadramento.

## Pixel art, camadas e pivôs

- Use filtragem nearest-neighbor para pixel art. Preferir múltiplos inteiros da resolução lógica e coordenadas alinhadas à grade quando forem compatíveis com a apresentação. Escalas fracionárias, quando necessárias, devem continuar uniformes e ter revisão visual de aliasing.
- Não introduza suavização ou escalas diferentes entre camadas de um mesmo objeto. SVGs devem ter `viewBox` coerente e preservar quadrados da grade lógica; sua importação deve usar resolução suficiente para a escala final.
- Estados Offline/Online do mesmo objeto precisam compartilhar tamanho lógico de canvas, pivô, escala e posição. Diferenças de recorte nas fontes precisam ser compensadas por padding/offset antes da integração, nunca por stretch.
- Defina o pivô de pés/base, centro do portal e eixo da turbina em coordenadas documentadas. Camadas extraídas devem manter o sistema de coordenadas ou um offset conhecido. Não centralize cada camada pelo seu bounding box de forma independente.
- Reserve margem para toda a animação, inclusive partículas, rotações, luzes e balanço. A mudança de estado não pode provocar salto de base, oscilação de tamanho ou corte involuntário.
- Para animações extraídas de vídeo, use escala física constante por sequência e pivô de chão constante. Não normalize a altura de cada pose individual para esconder variações de captura: isso pode inflar poses abaixadas. Mudanças de escala entre sequências exigem evidência da referência e revisão visual.
- Deformação de impacto deliberada deve ser curta, limitada, documentada e restaurar a escala base. Não use squash/stretch para disfarçar proporções erradas. Toda nova deformação requer justificativa de animação no código e revisão; a transformação de repouso continua uniforme.
- Exceção existente mantida: Brisinho em LAND usa `Vector2(1.06,0.94)` durante aproximadamente 0,1 s para impacto da aterrissagem. Essa exceção vale somente para a animação, nunca para layout, props, personagens em repouso ou preenchimento de plataformas.

## Apresentação e verificação

- Não desenhe guias verdes de contato sobre a arte das plataformas na apresentação final. Essas guias pertencem apenas ao blockout; mantenha a geometria de colisão independente da aparência.
- Preserve a área lógica de jogo 1152 × 648 (16:9) na configuração do Godot e no canvas web. Ajuste tamanho da tela com escala uniforme e letterboxing; não estique o canvas para preencher uma janela de outra proporção.
- Não altere a proporção no modo fullscreen, em resoluções móveis ou via CSS. O HUD deve permanecer dentro da área segura.
- Antes de publicar alteração visual, compare dimensão fonte, dimensão exibida e `abs(escala_x)/abs(escala_y)`: objetos rígidos devem resultar em 1, dentro da tolerância de arredondamento. Se a razão divergir, corrija ou explique uma exceção de animação específica.
- Capture o início, a turbina/vento, o rail, o Nó Offline, o Nó Online e o portal. Compare os estados lado a lado. Confira pixels, pivôs, base, partículas e alinhamento da arte à superfície jogável.
- Não declare aprovação visual só porque o projeto importou ou os testes de lógica passaram. Registre claramente se a verificação foi por código, imagem renderizada ou navegador, e qualquer limitação.

## Famílias de plataformas e cenário aprovadas

- Preserve as nove famílias de plataformas e seus módulos de chão/decoração. Varie comprimentos por repetição e recorte explícito, com escala uniforme.
- Pedras desmoronáveis precisam avisar antes da queda e recuperar sem aparecer dentro do jogador. Plataformas de sinal devem manter arte e colisão no mesmo movimento e estado de conexão.
- Decorações usam pivô de base, não bloqueiam o percurso e ficam à frente do fundo, atrás das plataformas. Reações à passagem do jogador não deslocam os pés das plantas.
- A coleta dispara um efeito único de anel, fragmentos e faíscas. Gemas continuam laranja e pulsantes; a opção de reduzir flashes limita também os novos efeitos.
- As variações disponíveis no pacote não são todas usadas no percurso. Documente separadamente catálogo, colocação na fase e comportamento efetivamente testado.

## Preflight de percurso, escala e interface — lições de 30/09/2026

Os problemas abaixo foram encontrados ao ampliar a Costa dos Ventos. Use as verificações preventivas antes de integrar uma nova área ou tela:

- **Aviso fora da identidade do HUD:** placas/tutorial usavam fonte de fallback, ciano dominante e retângulo simples. Use a fonte pixelada, cores, moldura e sombra já aprovadas para menu/HUD; confira legibilidade sobre o cenário e mantenha personagem, chão e ameaças visíveis.
- **Coqueiros menores que Brisin:** comparar o valor de escala ou o canvas SVG/PNG não representa o tamanho desenhado. Meça a altura do conteúdo não transparente dos frames do personagem e da decoração, multiplicada pela escala uniforme final; plantas pedidas como maiores devem exceder a silhueta de Brisin e manter o pivô no chão.
- **Ameaças insuficientes ou sem comportamento uniforme:** código que mantém apenas uma referência singular deixa inimigos adicionais fora de pulso, reinício ou respawn. Guarde encontros em coleção e aplique a todos as ações compartilhadas; coloque patrulhas sobre superfícies caminháveis e confira espaçamento, pontos seguros e retorno após dano. Não cubra o salto de entrada ou aterrissagem de uma rota obrigatória com um inimigo sem testar a rota com a resposta de combate disponível. Se a patrulha depende de uma plataforma Online, sincronize visibilidade e simulação com a mesma condição da plataforma.
- **Testes contaminados por progresso salvo:** testes de introdução, reinício e coleta dependem de `user://`; um teste anterior pode deixar o save Online/concluído e causar resultados falsos. Execute suítes de estado com diretório de dados temporário ou salve/restaure o arquivo original; use `--test`/`--fresh` quando a cena exigir progresso vazio.
- **Jangadas e plataformas inalcançáveis:** proximidade visual não garante travessia. Revise cada transição entre superfícies usando velocidades, gravidade, pulo, dash, movimento e estado Offline/Online reais; confirme um caminho contínuo desde spawn/checkpoint até o portal e teste também plataformas opcionais antes de prometer recompensas nelas.
- **Expansão além dos limites do nível:** ao adicionar trechos, alinhe comprimento, limite da câmera, terreno/fundo, portal, colisões, inimigos, vento, placas e coletáveis. Valide que nenhum elemento de jogo necessário fica fora do percurso visível ou dos limites de câmera. Depois de alterar o Godot, regenere `dist/index.pck`, atualize o tamanho em `fileSizes` no carregador HTML e rode `verify-loader.cjs` para não deixar a versão web com conteúdo antigo.

Antes de fechar uma expansão, registre a verificação: (1) validar JSON e coordenadas/limites; (2) testar grafo de alcance com a física atual e estados da fase; (3) medir proporções pelo conteúdo visível na escala final; (4) conferir que HUD, avisos e menu usam a mesma fonte e tokens; (5) confirmar que pulso, dano, reinício e respawn alcançam todas as instâncias. Se o Godot/navegador não puder ser executado, marcar explicitamente os itens verificados por código e os que ainda exigem teste de jogo.

## Correções de contexto e animação — lições de 01/10/2026

- **Patrulhas sem chão ou com limites invertidos:** valide `esquerda < direita` e apoio real em toda a patrulha. O retângulo geral de uma plataforma de degraus não representa sua superfície: use os polígonos/patamares reais ou escolha chão plano. Vincule o inimigo à plataforma de apoio; o pivô dos pés deve coincidir com o chão. Em plataformas móveis, acompanhe a transformação; em plataformas Online, sincronize presença e simulação. Revise também acesso e espaço de aterrissagem do jogador.
- **Rotores sobrepostos a pás pintadas no fundo:** não anime novas pás em cima de rotores já incorporados ao PNG nem esconda partes com discos opacos de céu. Um novo fundo exige aprovação do conceito antes da conversão. Separe céu, mar, ilhas, mastros, rotores e luzes em camadas SVG; documente eixo do rotor e margem de giro. Confira tiles espelhados e parallax. Objetos decorativos do fundo não devem sugerir plataformas ou jangadas acessíveis.
- **Conceito de fundo distante do jogo:** use uma captura/arte atual como referência visual explícita na geração. Compare tamanho aparente dos pixels, contornos, formas, proporções e paleta: detalhe fino, iluminação cinematográfica e paisagem realista não substituem o pixel art de formas grandes já aprovado. A primeira proposta panorâmica de 01/10 foi rejeitada por divergir desse estilo; o usuário aprovou a revisão estendida e autorizou sua conversão SVG nesta rodada.
- **Efeitos pouco legíveis ou fora da direção aprovada:** dash e pulso usam SVGs próprios animados no motor, com direção/pivô claros, duração finita e faíscas, com corpos opacos e cores vivas. A onda visual compartilha a curva de expansão e o alcance de combate; o dash deve acompanhar a direção real. Redução de flashes preserva a leitura da ação sem flashes de tela. Confira disparos consecutivos, respawn e término dos efeitos.
- **Dicas permanentes e fora de contexto:** apresente uma única dica transitória abaixo do HUD, baseada no objeto real próximo e no estado atual da ação. Remova-a ao sair do contexto, concluir a ação ou abrir menus; imponha duração e intervalo de repetição. Dê prioridade ao contexto mais relevante e evite sobreposição com avisos. Não desenhe tutoriais fixos sobre o mundo nem use posições antigas de placas para inferir relevância.
- **Alterações locais que não aparecem no artefato:** edição, exportação e publicação são etapas distintas. Use o checkout do Site associado ao `project_id` existente, preserve o histórico remoto e publique o pacote reconstruído a partir do commit enviado. Atualize o tamanho do PCK e valide o carregador. Só declare a prévia atualizada após confirmação da versão e da publicação; aprovação pendente de um novo conceito não bloqueia publicar as outras correções autorizadas.
- **Falso resultado de testes por menu/progresso:** testes de gameplay devem ser executados com `-- --test` quando usam `OS.get_cmdline_user_args()`. Isolar saves sozinho não dispensa esse argumento. Importação sem erros confirma compilação; teste de lógica e revisão visual são evidências diferentes e devem ser relatadas como tais.

Detalhes confirmados nas soluções desta rodada:

- Amostre a patrulha por um ciclo completo do corpo móvel e pelas duas bordas; posição correta no spawn não prova apoio contínuo. Uma atualização Offline/Online não ressuscita inimigos derrotados. Apoio geométrico não basta: reserve aterrissagem e tempo de reação, e valide o combate durante a travessia. Na plataforma 6500–6750, a patrulha precisou começar em 6630 para deixar 130 px de entrada segura.
- O pulso conserva a origem global do disparo e termina em 0,55 s; seu envelope visual corresponde ao alcance de 140 px. Rastro do dash fica atrás do personagem. Respawn e `DISABLED` limpam pulso, rastro e ecos.
- Dica de superfície desmoronável exige jogador sobre o chão correspondente; uma plataforma acima dele não deve ativar a instrução. O orçamento de leitura só conta quando a faixa está visível; reentrada no mesmo encontro não reinicia os 4,5 s.
- Extensão de cenário acrescenta composição horizontal em vez de esticar o bitmap; preserve grade dos pixels e escala uniforme dos elementos. Aprove o panorama final antes da integração como camadas SVG.
- Conversão vetorial preserva a referência aprovada com geometria SVG real, não com PNG embutido em `<image>`. Guarde fonte e gerador fora dos recursos exportados quando servirem apenas à regeneração; confira pivôs em repouso e rotacionados, margem de giro, posição dos mastros e cobertura nos limites da câmera. O projeto editável entregue no ZIP deve conter também as regras e os novos assets/scripts.


## Combate, atmosfera e transições — prevenção de erros de 01/10/2026

- **Pulso visível sem atingir o inimigo:** teste contra o retângulo do corpo visível, não a distância até o pivô dos pés. A colisão acompanha a mesma origem, curva temporal e raio de 140 px do SVG, incluindo movimento do alvo entre ticks. Cada onda atinge cada inimigo uma vez; registre chegada da onda, atordoamento de 2 s e recuo limitado à patrulha. Diferencie interromper pelo pulso de derrotar por chip, stomp ou dash.
- **Projéteis atravessando alvos/paredes:** chips SIM brancos com contatos dourados têm corpo de 24 × 28 px, velocidade 760 px/s, alcance 500 px e recarga de 0,35 s. Faça varredura do corpo entre ticks, incluindo movimento relativo dos inimigos. A primeira colisão com parede ou alvo prevalece; teste parede fina, obstáculo na origem, ambas as direções e inimigo móvel. Instale F e botão Y de forma idempotente mesmo quando outras ações já existirem e apresente os controles no menu.
- **Dash e pulso apagados por transparência:** os corpos e partículas principais dos ataques usam cores saturadas e alpha 1. A redução de flashes diminui partículas e brilho auxiliar, mantendo leitura da ação; não aplique fade ao corpo principal nem flash de tela. Pausa congela ataques e recargas. RESPAWN e DISABLED limpam ondas/chips/rastros; chamadas externas de dano ou bounce não podem retirar o jogador de DISABLED.
- **Menu com saltos entre poses:** no jogo, SVGs são texturas de frames de AnimatedSprite2D; não dependa de SMIL/CSS dentro do SVG importado. A preparação deve começar exatamente no frame de aceno visível e terminar no primeiro frame de corrida. Preserve mão ligada ao braço, pés/base, escala uniforme e canvas; bloqueie duplo início até concluir a transição finita.
- **Bandeira girando inteira ou só após ativação:** anime continuamente apenas o tecido. Mastro e primeiras colunas de fixação ficam imóveis em todos os frames Offline/Online, com mesmos canvas, pivô e escala; confira diversidade dos frames e ciclo completo. O balanço não altera a colisão.
- **Atmosfera lavando HUD/personagem:** esmaecimento pertence às camadas do fundo. Atenue horizonte e ilhas distantes com bandas alinhadas à grade e preserve céu próximo, silhuetas de jogo, plataformas e HUD legíveis. Não use overlay global nem altere coliders para representar profundidade.
- **Portal concluindo antes de sua animação:** entrada Online válida inicia sequência SVG finita de aproximação, atração e fechamento (1,8 s). Só ao terminar salve conclusão, emita finished e abra a tela final, exatamente uma vez; não confie apenas em callback antecipado. Rejeite ID desconhecido, Offline e RESPAWN sem consumir a trava de entrada. Bloqueie novas entradas, combate e menus durante a sequência.
- **Cancelamento deixando jogador pequeno/deslocado ou inimigos parados:** capture pés, pai/transformação do sprite e estado de simulação individual dos inimigos. Cancelamento, desconexão e remoção direta do efeito devem restaurá-los e liberar a trava. Na saída da cena limpe wrapper e referências sem emitir conclusão. Após cancelar dentro do portal, só rearme o gatilho ao sair do raio de 85 px (entrada em 65 px), evitando reinício automático na mesma posição.
- **Teste esperando efeitos instantâneos:** integração deve aguardar a chegada real da onda e a duração real do portal, verificando também ausência de conclusão antecipada. Combine suítes de colisão/lifecycle com percurso completo por inputs; registre separadamente teste headless, inspeção de frames renderizados e teste em navegador.


## Gesto de lançamento e ensino do chip — 01/10/2026

- O disparo aceito inicia gesto SVG de 0,30 s: soltura, avanço da mão e retorno. Preserve índice e fase da animação de locomoção ao trocar texturas; caminhar, correr e saltar não podem congelar, deslocar pés ou alterar colisão. Mão e corpo compartilham canvas 144 × 128, pivô de fonte 72,120, escala uniforme e direção capturada no disparo; filhos visuais seguem o wrapper do portal.
- Ao extrair pernas de frames existentes, recortar apenas a região inferior pode separar quadris/corpo e apagar tons marrons claros. Preserve os tons da paleta, conecte os quadris às pernas em todos os frames e revise poses de corrida e salto renderizadas. Não embuta PNG no SVG nem normalize cada frame pela altura do bounding box.
- Recarga rejeitada não reinicia gesto nem emite outro chip. Pausa congela gesto; término, RESPAWN e DISABLED removem a mão e restauram os sprites normais. Blockout não exibe a camada SVG isolada.
- A informação **[F] SOLTA CHIPS** aparece no único espaço transitório abaixo do HUD ao encontrar inimigo vivo ao alcance. A dica de longo alcance exige direção correta, altura compatível, recarga pronta e varredura livre do corpo 24 × 28; não basta um raio sem espessura. Pulse/dash/chip compartilham o mesmo ID e orçamento de leitura do encontro, evitando que trocar de opção reinicie os 4,5 s.
- Intensidade maior de atmosfera mantém origem/parallax e atua apenas no Node2D do fundo. A revisão aprovada usa multiplicador 1,35 sobre o perfil original: pico 37,8%, céu alto 3,38%, borda inferior 18,23%. Guarde o perfil original e gerador para evitar multiplicação acumulada ao regenerar.


## Menu, alinhamento, portal e mar — revisão de 01/10/2026

- Avisos e contadores precisam centrar texto na área útil após o ícone, com margens simétricas, não só mudar o alinhamento de uma label estreita. Compense a tinta da fonte bitmap e exclua a sombra inferior da moldura ao centrar verticalmente. Revise títulos, textos longos, contagem 00/25 e 25/25 por imagem e geometria; não use espaços no texto como correção de layout.
- No menu, reutilize a plataforma coastal_0 SVG aprovada em escala uniforme, com contato da superfície y64 e pés ancorados. Use o panorama SVG e seus sistemas animados, evitando duplicar um fundo PNG legado. Aceno, corpo e vela acompanham o gesto sem deslocar pés; todas as entradas/saídas da preparação continuam coincidentes por pixels.
- Moldura do portal fica fixa; núcleo, pistas, túnel e partículas têm pivô comum e movimentos próprios. Compare portal disponível e fases de entrada lado a lado: uma moldura circular detalhada não deve trocar abruptamente por anéis quadrados grossos de outra grade. Preserve sequência finita1,8s e lifecycle. Modo reduzido deve diminuir população, velocidade e amplitude reais. Faíscas douradas usam paleta/asset próprios: multiplicar textura ciano por âmbar gera verde.
- Mar próximo é Node2D decorativo atrás do gameplay e acima do panorama, com superfície y810 e módulos512×224 recortados em escala1:1. A arte cobre atéy1034; perigo físico continua emy>900. Ondas, espuma e reflexos ficam na grade2px; confira seam do último/primeiro frame e bordas x0/9600 em offsets0/±510. Pausa e blockout congelam as camadas; água não cria colisões nem encobre plataformas.
- No mar distante, ondulações SVG pequenas só ocupam regiões cujo envelope completo da animação está dentro da máscara da água aprovada. Não desloque textura inteira do mar nem pinte reflexos sobre ilhas/coqueiros. Névoa é desenhada depois dos reflexos, para não reintroduzir brilho excessivo no fundo esmaecido. A revisão atual eleva também o céu: piso18%, pico55%, água baixa34%. Aplique o mapeamento sempre ao perfil original, sem acumular ganhos ao regenerar.
- README de entrega descreve fase realmente integrada, instalação do Godot4.5.1, controles, execução porHTTP, exportação e testes. Use caminhos absolutos no helper de export para evitar PCK gerado emgodot/dist por engano; preserve compatibilidade do runtime. SnapshotGitHub mantém código/assets/testes/docs e o carregador web; binários de build podem ser reconstruídos pelo helper documentado. CacheGodot, segredos e metadadosSites não pertencem ao repositório portátil.

## Gemas do menu, encontros e entrega privada — 01/10/2026

- **Ornamento parecido com guia de chão:** os traços amarelos sob a ilha vinham de `ui/wave.svg`, não do mar do cenário. Não reutilize linhas de interface para sugerir água quando existe mar SVG aprovado. Gemas decorativas do menu usam os assets laranja existentes, escala uniforme e corpo opaco; revise a órbita inteira, protegendo rosto, mão, botões e rodapé. Reabrir o menu deve reconstruir exatamente cinco gemas, sem instâncias residuais ou coleta/progresso de gameplay.
- Mudança para flashes reduzidos integra a nova velocidade sobre a fase atual, sem recalcular fase como tempo total × nova velocidade (isso faz a órbita saltar). Em uma órbita simétrica com cinco gemas, amostras separadas por um quinto do período parecem iguais; escolha fases distintas para a revisão visual.
- **Arquivo grande bloqueando integração:** mantenha checkpoints de blobs já enviados e forneça progresso entre lotes. Não repita um envio grande travado sem mudar o transporte. Preserve arquivos de código/arte completos e utilizáveis; não fragmente assets Godot para contornar um limite. Builds WASM/PCK/ZIP podem ficar fora do GitHub se houver reconstrução documentada. Verifique hashes do runtime antes de substituir arquivos; download incompleto ou corrompido não pode destruir a versão existente.
- **README copiado sem dependências do helper:** um ZIP editável que inclui instruções de export web precisa incluir também carregador HTML/JS, manifesto WASM, verificador e scripts. Verifique esses nomes no arquivo empacotado; o Godot abrir não prova que os comandos de instalação web documentados funcionam. Omita somente binários que o helper realmente reconstrói.
- **Chave de deploy confundida com código:** chave pública pertence às configurações do repositório, privada ao serviço de deploy, sempre fora de fonte, ZIP e logs. Para clone/update basta leitura. Não declare a chave cadastrada somente porque foi gerada: ferramentas de conteúdo GitHub não implicam suporte à administração de deploy keys.
- **Mais inimigos sem revisar travessia:** quantidade maior exige pisos reais, entrada livre e encontros separados. Evite patrulhas sob uma rota opcional cujo stomp provoque bounce inesperado. Teste a coleção inteira e as respostas disponíveis (chip, pulso, dash, salto), com inputs reais; não dependa apenas de `world.enemy`. Um piloto precisa soltar dash/chip em prazo finito, respeitar recarga e não consumir um salto durante DASH. Reserve distância para combate antes de bordas.
- **Música da fase vazando no menu:** o HUD comunica explicitamente menu/jogo/conclusão ao áudio; mantenha a composição durante preparação e só troque ao terminar a corrida, inclusive no ramo que recarrega a cena. Use loop nativo com emenda inspecionada, ganho sem clipping e composição original regenerável. Volume zero pausa a reprodução e não cria novas vozes SFX; ao liberar um player pausado, despause antes de parar/remover stream para não reter decoders. Verifique a reprodução após gesto do jogador na web.


## Áudio web e travamentos — prevenção de 01/10/2026

- Pause/resume de AudioStreamPlayer só é enviado quando o estado muda; ganhos estáveis não precisam ser reatribuídos a cada frame. No runtime Sample do Godot4.5.1, retomar repetidamente recria AudioBufferSource e reinicia o áudio, produzindo interferência e trabalho acumulado. Preserve o guard idempotente em tools/fix_web_audio_pause.cjs e execute tools/verify_web_audio.cjs em toda exportação. Versão desconhecida exige revisão explícita, nunca substituição silenciosa.
- Testes de áudio precisam cobrir o SampleNode real do JS exportado, além do mix nativo: repetição de comandos não cria fontes, pausa real para uma vez e retomada real inicia uma vez. Loop, mute, SFX e transições de menu continuam funcionando. Não troque o backend web por Stream como tentativa de esconder o problema.
- Texturas SVG importadas não precisam ser redesenhadas em todos os ticks quando suas fases discretas permanecem iguais. O mar invalida por fase visual, câmera, extensão e reativação da arte; movimento da câmera precisa atualizar o recorte imediatamente. Teste fase estável e câmera móvel separadamente. Não declare FPS ou reprodução audível medidos a partir de testes headless.


## Origem da arte, órbita e primeira leitura — 01/10/2026

- Aparência raster não prova arquivo PNG: siga a textura realmente carregada pela cena, confira extensão, geometria e ausência de `<image>`/base64. Farol e portal de `interactive/` já usam paths SVG verdadeiros com estados off/on e pivôs iguais. PNGs legados presentes no catálogo não implicam uso na fase. Uma nova imagem para aprovação é necessária quando a investigação confirma arte raster ou quando o usuário solicita redesign; não refaça silenciosamente um SVG aprovado.
- Remover um ornamento significa remover sua instância e atualização: o traço amarelo deste menu vinha de `ui/wind.svg`, não das gemas. O pacote amarelo também foi retirado. Gemas do menu têm cinco tamanhos base diferentes e escalas uniformes; ao aumentar tamanhos, audite a órbita inteira contra rosto, mão, botões e bordas. A órbita desta revisão usa raios186×174 para proteger as gemas maiores.
- Checkpoint, início de conexão e costa Online têm primeira leitura com pausa e chime original próprio. Todas as dicas contextuais também pausam na primeira leitura; debug continua transitório. Confirmação em Entendi por mouse/Enter/A retoma uma única vez, sem deixar salto/ataque pressionado; leitura mínima0,25s evita confirmação acidental do mesmo frame. Volume de efeitos é respeitado, inclusive zero.
- Registre primeira leitura por tipo semântico apenas ao confirmar, salve com o progresso e limpe em nova aventura. Eventos recebidos atrás de outro menu aguardam na fila com texto original, sem roubar sua pausa. Repetições não empilham nem tocam o som novamente; saída de cena libera somente a pausa que o aviso possui. Mantenha a janela abaixo do HUD e fora da silhueta do personagem.
- Gameplay define PROCESS_MODE_PAUSABLE explicitamente; HUD e áudio continuam ALWAYS. Teste congelamento real de posição, relógio e recarga, incluindo cena embutida num host ALWAYS. Pausa iniciada por marcador físico deve ser agendada para a fase idle. Teste primeira leitura separadamente dos avisos já reconhecidos e atravesse a fase confirmando os novos avisos.
- No Godot4.5.1, retomar SceneTree em callback de física/deferred pode executar step sem flush de queries e gerar `p_elem->_root` duplicado. A confirmação só solicita retomada; o HUD ALWAYS a conclui em `_process`. Verifique também logs nativos do percurso: exit0 e asserts aprovados não bastam se ainda houver ERROR. Não altere registro/disable_mode de colisões para esconder esse erro.
- Sprite recém-criado precisa selecionar uma animação existente antes do primeiro tick. Uma pausa antecipada pode conservar `default` mesmo após remover essa animação; trocar SpriteFrames e restaurar esse nome dispara erro. Inicialize `walk` e só preserve nome/frame quando o destino contém a animação.

## Logo aprovado — 03/10/2026

- Use o logo BRISIN com símbolo de vento do SVG canônico em `tools/reference_art/brisin-logo.svg`. Menu e carregamento web compartilham esse asset, com fundo transparente e escala uniforme. Não regenere o logo a partir da fonte bitmap nem acrescente texto que esteja cortado na referência.
- O logo tem canvas 442 × 209; ajuste a área reservada em cada tela à proporção original, protegendo subtítulo e botões. Mantenha as cópias Godot/web idênticas após gerar ou exportar a interface.

- Subtítulo do menu precisa ter tamanho legível (24 px) e espaço próprio abaixo do logo. Preserve ao menos 14 px entre áreas, 34 px antes do primeiro botão e 20 px entre botões; confira também o estado com quatro ações ao continuar uma aventura.

## Disparo de chips — tecla aprovada em 03/10/2026

- No teclado, chips usam F; no controle, Y. Remova o atalho anterior B ao instalar os inputs. Dicas contextuais, menu de controles, rodapé web e documentação devem indicar F/Y sem duplicar os eventos após reinício.

- Todos os avisos de gameplay, incluindo dicas contextuais, pausam na primeira leitura por tipo semântico. Somente Entendi (mouse/Enter/A) confirma; Esc não dispensa. Confirmações persistem e nova aventura limpa todas.

- Configure TextureRect.EXPAND_IGNORE_SIZE antes da textura e do tamanho para não herdar o mínimo nativo. Confira tamanho efetivo no Godot, além da prévia CPU. Logo termina em y184, subtítulo inicia em y202 e primeira ação em y272. Ao substituir membros, limpe os resíduos da fonte e coloque o ombro dentro do corpo; uma única silhueta conectada não garante uma junção visual limpa.

- Corpo e rosto do Brisin no menu usam a célula original em resolução completa, com padding 16 px, canvas 176 × 160, pivô (88,136), escala uniforme 2 e offset (0,-56). Não reduzir para depois ampliar, pois isso perde detalhes e cria blocos no contorno. Dicas contextuais de chip devem dizer F no teclado; Y é identificado na seção GAMEPAD, sem parecer uma segunda tecla de teclado.

- A lateral esquerda do corpo no menu deve formar uma superfície laranja opaca contínua entre a vela e o ombro. Ao remover braços da fonte, reconstrua o recorte: conectividade da silhueta inteira não detecta concavidades que parecem buracos. Verifique essa área em todas as poses e em render sobre fundo contrastante.

## Tutorial opcional — primeira visita

- Pausas de avisos exigem primeira sessão do jogador e escolha explícita FAZER TUTORIAL. Ofereça FAZER TUTORIAL / PULAR TUTORIAL antes de começar apenas quando tutorial_choice_made for falso.
- Persistir has_played e tutorial_opted_in separadamente do progresso da aventura. Saves legados não comprovam uma decisão explícita: tutorial_choice_made começa falso e exige FAZER / PULAR antes de iniciar, sem ativar pausas automaticamente. Nova aventura não apaga a escolha nem oferece tutorial novamente.
- tutorial_session_active é temporário; carregar um save numa visita posterior não retoma pausas de tutorial. Sem tutorial, eventos e dicas continuam transitórios. Confirmações e fila só pausam se a mesma condição estiver habilitada.

- Não use has_played, checkpoint ou existência do save para suprimir a escolha de tutorial. Persistir tutorial_choice_made somente após o clique em FAZER / PULAR. Testar save legado e save da versão 25 com progresso antes de iniciar; a animação de início não pode começar antes dessa decisão.

- Checkpoints adicionais usam posição e ID próprios no JSON; não reutilizar a coordenada do primeiro checkpoint ao salvar ou retornar. Em expansões, manter IDs existentes das gemas e acrescentar novas entradas ao fim para preservar saves.

- Cada checkpoint adicional precisa ter totem SVG visível, pivô no chão, escala uniforme e estado independente. A arte do checkpoint primário não pode alternar lendo os demais marcadores. Validar ativação física, gravação, morte/respawn e recarga para cada ID, além do percurso até o portal.

## Totem costeiro aprovado — 03/10/2026

- O conceito aprovado em `tools/reference_art/approved-checkpoint.png` substitui as bandeiras de checkpoint. Todos os IDs, inclusive brisa_01, usam pedra costeira, moldura laranja, núcleo âmbar/ciano e pulsos pequenos. Não reintroduzir o mastro/bandeira grande.
- Canvas 80×128, pivô (40,125), escala uniforme 1: corpo visível de aproximadamente105px. Núcleo e sinal têm camadas próprias; só o sinal anima a4fps, com base fixa. Flashes reduzidos mantêm sinal estático. SVG deve conter paths reais, sem PNG/base64.
- Expansão de15% sobre13248 resulta em15235px após arredondamento ao pixel inteiro. Adicionar ilhas ao fim preservando coordenadas, IDs e progresso anteriores; portal acompanha o novo limite.

## Portal e módulos de chão — revisão de 03/10/2026

- Separar vento inteiro da camada modular: um limiar só para ciano claro deixa contornos escuros e folhas no chão, repetindo o efeito em toda a ilha. Verificar ambas as variantes renderizadas em plataformas largas; efeito tem uma instância central e canvas próprio.
- Recortar padding lateral vazio da camada de chão pela faixa de contato, sem stretch. Toda família de piso plano precisa ter arte nos dois extremos e ao longo de toda a superfície; preencher interrupções decorativas do conceito com módulos vizinhos antes de repetir. O recorte não altera colisões ou o tamanho lógico da fase.
- Portal deve iniciar entrada com a mesma textura, pivô, escala e orientação do núcleo visível. Não trocar por outra espiral nem por uma nova moldura. Animação pode acelerar o núcleo durante atração e contrair a abertura no fim; moldura fica imóvel. Conferir amostras dos transforms reais, pausa, cancelamento, modo reduzido e conclusão única em1,8s.

## Lateral esquerda do menu — regressão de 03/10/2026

- Verificar três pontos dentro do torso não prova ausência de um buraco ao lado deles. A região reconstruída agora abrange o recorte completo entre a ponta inferior da vela e o ombro: linhas90–105 do canvas176×160, borda esquerda60+max(0,y−92). Preserve o contorno externo e remova a borda antiga onde ela ficou interna.
- Verificar o interior dessa região transformado em todas as278 poses de aceno, piscada, preparação e corrida. Revisar renders sobre fundo contrastante, incluindo aceno com braço elevado e frames extremos. Silhueta conectada e importação sem erro não bastam. Confirmar também os30 encaixes exatos aceno→preparação e30 encaixes preparação→corrida.

## Menu aprovado compartilhado com a web normal — 05/10/2026

- Por solicitação explícita do usuário, o menu aprovado do mobile também é o menu da web normal. Ação principal larga laranja, Nova Aventura larga quando há progresso, Configurações/Controles lado a lado. Reutilizar os SVGs/fontes de `assets/ui/mobile/` e a referência `tools/reference_art/approved-mobile-menu.png`.
- Avatar escala uniforme2,6, ilha2,4, pés(902,456), pivô original(100,64). Névoa reduzida só no fundo do menu; gameplay conserva atmosfera, física, inputs e progresso. Texto creme com contorno escuro. Logo canônico432×204 em(150,24).
- Manter teclado/gamepad, foco visível, preparação finita e escolha explícita de tutorial. Capturar o menu no renderizador e repetir menu_animation/ui_integration antes de exportar/publicar.

## Conexão de Outro Mundo — aprovação de 05/10/2026

- Nesta branch, as referências em `tools/reference_art/cosmic/` substituem a direção costeira para cenário, plataformas, decoração, objetos e inimigos. Regras anteriores de física, proporção, legibilidade e lifecycle continuam válidas.
- Título: **Brisin — Conexão de Outro Mundo**. Remover a frase de rodapé sobre restabelecer a conexão do planeta; não reincorporar o rodapé da imagem de conceito.
- SVGs contêm paths reais, nunca PNG/base64. Fonte raster e gerador ficam fora dos recursos exportados; preservar o estilo e as nove paletas aprovadas.
- Nove Ruídozinhos com animações de repouso, patrulha, alerta, dano e derrota. Variações são cosméticas nesta entrega; não inventar resistências ou ataques sem um design solicitado.
- Background não contém Brisin, inimigos, gemas, portais ou plataformas de gameplay pintados. Névoa permanece no fundo; todos os efeitos animam no Godot, não via SMIL.
- Progresso do planeta usa arquivo próprio, preservando o save da versão costeira. A geometria do percurso e os controles são mantidos nesta migração.

- Portal: testar entrada real por marcador durante salto, além da chamada direta da transição. A abertura visível deve interceptar o corpo; manter bloqueio Offline, cancelamento e conclusão única persistida.
- Ruídozinhos: não dividir silhuetas variadas numa linha fixa para animar pés. Preservar olhos/boca opacos e quantizar a paleta sem o fundo da prancha. Etzinho é a décima variação cosmética aprovada por solicitação do usuário.

- Animações aprovadas: rig contínuo por mapeamento inverso; passos alternados, respiração/piscada e movimentos distintos nos cinco estados. Etzinho tem100px de altura (~35% maior) e combate60×86; não voltar à translação de uma pose única. Validar as dez variantes em cosmic_animation.

## Adaptação mobile — candidata de 05/10/2026

- Manter a candidata em `feat/mobile-adaptation` até avaliação. A implementação web em paisagem não comprova compatibilidade física, ergonomia, áudio audível ou FPS em Android/iPhone; registrar esses itens como pendentes até medir.
- `GameCommands` combina input físico e donos por dedo sem emitir releases no InputMap. Preservar a intensidade analógica do gamepad. Limpar donos/edges em pausa, interrupção, morte, DISABLED e saída de cena; teclas físicas seguradas ao retomar exigem release antes de voltar a agir.
- Coordenadas de ScreenTouch/ScreenDrag já pertencem ao viewport. Em testes headless usar `Viewport.push_input(event, true)` para coordenadas lógicas; `Input.parse_input_event` aplica a transformação da janela e pode produzir coordenadas inválidas no display headless.
- Medir alvos de toque na escala CSS do canvas ajustado, não no backing store de1152px. Direcional admite zona neutra/arraste; cada dedo é independente. Arrastar entre pulo e dash não exige manter três botões simultaneamente.
- Pulo completo por toque é o padrão provisório; altura variável e repetição de chips são opções. Assistência mobile usa coyote0,16/buffer0,18 no tuning, mantendo os valores desktop. Velocidade, gravidade, recargas, alcance, IDs e mapa são compartilhados.
- Menu mobile usa duas colunas e escala uniforme1,4 para personagem/ilha, sem alterar SVG, canvas ou pivô; desktop conserva a composição2×. Gems usam órbita e escala uniformemente menores. Conferir poses sobre fundo contrastante em aparelho antes da aprovação visual final.
- Shell web respeita safe-area-inset, viewport dinâmico e proporção16:9. Retrato, perda de foco e troca de aplicativo congelam gameplay; retomar exige ação explícita. Interromper também congela a animação finita do título. Não tornar fullscreen/orientation lock obrigatórios.
- Preferências mobile sobrevivem a nova aventura e saves legados recebem defaults. Salvar também coleta e interrupções; falha de FileAccess informa sem encerrar a partida. Não assumir que cache ou virtual FS garante persistência após limpeza de dados do navegador.
- Qualidade leve reduz frequência/ripples do fundo e densidade de ecos, preservando física e corpos dos ataques. Headless não mede ganho de FPS.
- Repetir `mobile_input`, `mobile_ui`, `mobile_route`, tutorial e regressões afetadas com saves isolados e `-- --test`. Examinar logs por ERROR além do exit code. Retomadas de testes após física devem entrar pela fase idle para evitar a regressão nativa já registrada.

## Menu e controles mobile aprovados — 05/10/2026

- Referências canônicas: `tools/reference_art/approved-mobile-menu.png` e `approved-mobile-controls.png`. Menu tem duas ações largas à esquerda (a principal laranja), Configurações/Controles na mesma linha abaixo e personagem/ilha à direita. Não voltar ao grid de quatro ações espalhado sobre a ilustração.
- Controles têm contornos octogonais escalonados, sombra curta, ícones grandes e letras creme com peso maior. Pulo é maior e laranja; Dash fica à esquerda, Chip acima de Dash e Pulso acima de Pulo. Direções separadas no canto inferior esquerdo; pausa isolada no topo direito. Manter margem lógica32px e ampliar alvos pela escala CSS quando necessário.
- SVGs de UI mobile são geometria vetorial real; `tools/build_mobile_ui.py` gera molduras e ícones. A fonte mobile é um peso maior dos glifos originais, com as mesmas métricas relativas, sem substituir a fonte desktop.
- Esta revisão substitui a antiga escala mobile1,4: avatar2,6 e ilha2,4, ambos uniformes, pés em(902,456), ilha com pivô(100,64) em(662,302,4). Aceno/preparação/corrida preservam canvas e offset originais. Menu mobile reduz somente sua névoa decorativa; atmosfera do gameplay e menu desktop conservam os valores anteriores.
- Conferir texto nos estados sem progresso/com progresso e alvos48px CSS, espaçamento e bounds com escalas0,42/0,48/0,67/1,0, preferências100/112,5/125%, espelhamento e posição alta/baixa. A revisão usa capturas reais do Godot; não apresentar conceito gerado como screenshot do jogo.
- Capturas visuais desligam e liberam também Audio.menu_music antes de sair; senão o renderer com áudio Dummy reporta recurso Ogg pendente, mesmo quando as suites headless passam.

## Leitura do HUD mobile — 05/10/2026

- Dimensionar a tinta visível da fonte, não só o tamanho nominal: a fonte original ocupa15/24 da linha. O HUD usa ao menos14px CSS de tinta para objetivos/avisos e16px para contador; texto secundário12px.
- Reservar largura para COSTA • CONECTANDO e contador completo00 /49; configurar fonte/tamanho antes do retângulo para evitar que mínimo da label antiga alargue o novo contador e invada Pausa após resize.
- Avisos usam fonte pesada, quebra de linha por palavras e moldura modular que acompanha o texto real (incluindo mensagens longas de erro). Não esticar a arte inteira de uma placa como imagem; o frame é nine-slice.
- Posicionar dicas sem encobrir o personagem, cabeçalho ou botões de toque. Na leitura pausada, manter Entendi legível e esconder rodapé redundante sobre o cenário. Confirmar continua sendo a única ação que retoma tutorial.
- Contador mobile usa zero sem barra diagonal. Checar Offline/Conectando/Online e textos de conexão, vento, rail e erro de save nas escalas0,42/0,48/0,67/1,0. Usar `mobile_hud.tscn`, save isolado e captura real484×272; nominal14px não prova tinta14px.

## Conexão de Outro Mundo mobile
- Preservar mapa, portal e dez personagens do planeta. Branch feat/planeta-extraterrestre-mobile.
