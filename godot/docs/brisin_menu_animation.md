# Brisin — aceno e saída da tela inicial

O personagem do menu preserva a identidade do jogador atual: corpo de vela laranja com ponta superior e cauda lateral, olhos grandes brancos com pupilas azul-escuras e membros marrons finos. A reconstrução parte da primeira célula de `assets/player/walk.png`; `run.png` é referência para os membros na preparação de corrida. O sprite de gameplay não é alterado.

## Construção e pivô

- Célula fonte: 144 × 128. Fonte mantida em 144 × 128, sem redução; padding fixo de 16 pixels nos quatro lados; canvas final 176 × 160.
- Pivô de chão: **(88,136)**, borda inferior dos pés na linha 136. Todos os frames compartilham canvas, pivô e escala; sem normalizar a altura de cada pose.
- Escala recomendada: `(2,2)`, filtro Nearest. Em `AnimatedSprite2D` centralizado, `offset = Vector2(0,-56)` põe o chão no Node2D: `-80 -56 +136 = 0` pixels lógicos.
- SVGs contêm somente paths de retângulos na grade inteira, agrupados em `legs`, `arms`, `body` e `face`. Nenhum SVG incorpora bitmap. O corpo e o rosto vêm da referência; os braços e pernas são poses articuladas na mesma grade.
- A preparação usa rotação rígida progressiva de 0° a 7° em torno de `(88,116)`, com membros conectados aos ombros/quadris. Não há stretch nos eixos. Todas as poses são conferidas após renderização em SVG.

## Estados

| Estado | Frames | FPS | Duração | Loop | Uso |
|---|---:|---:|---:|---|---|
| `wave` | 30 | 10 | 3 s | Sim | Levanta a mão, acena com dedos abertos, abaixa, pisca e descansa antes de repetir. |
| `ready_to_run` | 8 | 12 | 0,667 s | Não | Olha para a direita, recolhe os braços, inclina o corpo e prepara a passada. |
| `ready_middle` | 8 | 12 | 0,667 s | Não | Mesma preparação, partindo da mão na posição intermediária do aceno. |
| `ready_high` | 8 | 12 | 0,667 s | Não | Mesma preparação, abaixando a mão erguida antes da corrida. |
| `run_start` | 8 | 12 | 0,667 s | Não | Primeiras passadas, mantendo um pé em contato com a linha de chão. |

O recurso `assets/player/menu_svg/spriteframes.tres` referencia diretamente **278 SVGs**: 30 quadros de aceno, 30 preparações de oito quadros e oito de corrida. Além das entradas históricas `ready_to_run`, `ready_middle` e `ready_high`, há `ready_from_XX` para os outros quadros de origem. O runtime usa `ready_for_wave_frames` do JSON para selecionar uma preparação que começa exatamente na pose visível quando o jogador confirma. Todas as 30 entradas e saídas foram comparadas por pixels: a entrada coincide com seu quadro de aceno e a saída coincide com `run_start` 0.

O motor controla a reprodução; animações SMIL do preview não são usadas no Godot. A vela superior também oscila por bandas de pixels, sem mover o rosto nem esticar o corpo. A interação de Começar bloqueia cliques repetidos e entrega o controle da fase após a preparação e a corrida finitas.
## Conferência

`python tools/build_brisin_menu_svg.py` reconstrói os arquivos e executa verificações: 278 frames não vazios, margens livres, canvas idêntico, chão constante, coordenadas de path inteiras, ausência de `<image>` e uma única silhueta conectada por frame. Todos os SVGs são renderizados pelo Inkscape; os renders também são verificados quanto à conexão dos membros. `contact_sheet.png` combina os renders reais dos estados, incluindo amostras do aceno, preparação e seus finais comuns. `preview_animated.svg` mostra o ciclo aceno → preparação baixa → corrida como preview vetorial independente.

A revisão inicial encontrou uma piscada com área transparente e uma lacuna no quadril direito; ambas foram corrigidas. As pálpebras cobrem os olhos com laranja, os quadris entram no corpo e resíduos dos membros da fonte são removidos. A validação de UI/fluxo no motor e no navegador pertence à integração, não ao gerador.

## Revisão de 01/10 — aceno, composição e texto

O aceno agora combina três varreduras de mão de 14 px, inclinação rígida de até 2°, subida de 1 px no corpo e vela com desvio de até 2 px. Os pés permanecem em y=68; os quadris e ombros acompanham o corpo. A piscada dura dois frames (0,2 s). As 30 preparações continuam coincidindo exatamente com seus frames de origem e terminam na mesma pose de corrida; o gerador compara os 60 handoffs depois de renderizar os SVGs reais.

A ilha do menu é o recurso aprovado `world_01/platforms/coastal_0.svg`, canvas 200×176, escala uniforme 2, posição (666,328), contato local (100,64); seu chão encontra os pés do avatar em (866,456). A composição usa também o panorama SVG real da fase em vez do PNG legado. A reprodução desse fundo continua durante a pausa do menu.

Avisos e dicas centralizam os dois textos no retângulo útil x=60..496, depois do ícone. O atlas bitmap tem tinta nas linhas 3..9 de um avanço de 12 e um pixel de avanço final sem tinta; a compensação de um pixel centraliza a tinta visível. Molduras têm sombra no canvas: alinhamos o conteúdo ao corpo dourado (centro y=38 nos avisos e y=23 no contador), sem incluir a sombra inferior. Ícone, título e detalhe compartilham esses centros visuais. O contador usa alinhamento central no espaço x=950..1046, ao lado da gema. Nenhuma alteração reinicia o orçamento de 4,5 s da dica.

`tools/render_menu_hud_preview.py` gera uma inspeção CPU com os SVGs e o atlas reais: `menu_hud_alignment_preview.png` e `menu_platform_preview.png`. Essa composição documenta escala, contacto e alinhamento; não é captura do navegador. `contact_sheet.png` reúne os frames SVG rasterizados pelo Inkscape. Os testes `menu_animation` e `ui_integration` verificam também os recursos/pivôs do menu e a centralização.

Regras sugeridas: centralizar tinta dentro do espaço útil depois de ícones, descontar sombra das molduras ao calcular centro visual, não confundir canvas com chão visível; reutilizar plataforma com pivô declarado e escala uniforme; comparar cada entrada de preparação com seu aceno correspondente após qualquer mudança no rig.

Validação headless concluída em 01/10/2026: `menu_animation` **19/19** e `ui_integration` **41/41**, ambos com `-- --test`, 60 FPS fixos e diretórios XDG isolados. Nenhum erro/warning foi emitido nas duas suítes. Inspeção visual: folha de contato Inkscape e previews CPU abertos e revisados; teste em navegador não foi realizado por este agente.

Revisão de 03/10: removidos pixels marrons residuais do braço original à esquerda e ombro esquerdo ancorado em (39,48), dentro do corpo. Todas as preparações compartilham o mesmo ombro e continuam coincidindo com o aceno e a corrida. Canvas, pivô de chão e escalas permanecem iguais.

Revisão de 03/10 — fidelidade: corpo e rosto são vetorizados a partir de todos os pixels da célula original (144 × 128), sem a amostragem de meia resolução que apagava reflexos dos olhos e irregularizava o contorno. O rig de membros continua na grade lógica, com coordenadas duplicadas na saída. Display de 352 × 320 e contato de chão permanecem iguais. As dicas de chips mostram F; Y é descrito apenas na seção de gamepad.

Revisão de 03/10 — recorte esquerdo: a abertura deixada pelo braço original entre a vela e o ombro foi reconstruída como lateral laranja contínua com borda escalonada. Três pontos da área reparada são verificados após rotação/deslocamento em cada uma das 278 poses. SVGs e transições são regenerados; conferência visual usa renders Inkscape sobre o cenário.
