# Música do menu — Brisa de Partida

Composição instrumental original do projeto: chiptune em Dó maior, 128 BPM,
4/4, 16 compassos e 30 segundos. Melodia de pulso, arpejos, baixo triangular
e percussão sintetizada com variações e uma cadência de retorno. Não contém
amostras nem melodias de terceiros. O gerador usa seed fixa.

`assets/audio/menu_theme.ogg` usa Vorbis qualidade 5 (261.989 bytes), loop
nativo e uma suavização de 2,5 ms na emenda. A decodificação apresentou pico
−2,85 dBFS, RMS −16,59 dBFS e zero amostras saturadas; a diferença entre fim e
início foi −58,05 dBFS. Não há fade musical longo dentro do loop.

O HUD informa `Audio.set_menu_active()` ao abrir menus, concluir a fase ou
retomar a aventura. A faixa permanece durante aceno/preparação e só sai
quando a corrida de entrada termina, inclusive ao recarregar uma nova
aventura. A transição para ambiente/Online dura 450 ms. Abrir um menu silencia
as camadas da fase. Volume zero pausa a voz efetivamente; efeitos também
obedecem ao controle separado. No navegador, o áudio depende da primeira
interação do jogador, conforme a política de reprodução do navegador.

Regeneração: `python tools/generate_menu_theme.py`, com NumPy e FFmpeg no PATH.
O WAV intermediário é temporário; somente OGG e métricas ficam no projeto.

Verificação: importação Godot 4.5.1, 12 verificações de stream/loop/roteamento,
mute e transição; menu testado com início, continuar e recarga real. O teste
encontrou decoders retidos quando players eram destruídos pausados: liberação
agora despausa antes de parar e remover o stream. Testes headless e métricas
de áudio não substituem escuta no navegador.
