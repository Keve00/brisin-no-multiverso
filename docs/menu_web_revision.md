# Menu aprovado na web normal

Aplicação do menu mobile aprovado em05/10, sem migrar os controles de toque
ou alterar a gameplay da publicação desktop. Cores, SVGs, tipografia pesada,
logo, posições, escala uniforme do avatar/ilha e órbita seguem a referência.
Os estados sem/com progresso conservam seus comandos; teclado/gamepad, tutorial
e transição finita para corrida continuam disponíveis.

Verificação:2083 checks em11 cenas, logs sem ERROR. Captura real em
`docs/menu_qa/menu_web_approved.png` (Godot4.5.1/OpenGL Compatibility, llvmpipe).
Isso não representa medição de FPS ou áudio físico.

O pacote editável ZIP é gerado por `tools/package_svg_delivery.py`, fica disponível no build publicado e não é duplicado no histórico de código.
