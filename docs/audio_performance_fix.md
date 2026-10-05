# Áudio e desempenho — 01/10/2026

A reprodução do bug no SampleNode extraído de dist/index.js criou 1.200 fontes e reiniciou o som 1.200 vezes após 1.200 chamadas redundantes de resume. Audio._process enviava esses comandos por frame. A correção envia apenas mudanças de estado e protege também o runtime contra comandos redundantes. O mesmo teste passa com zero fontes novas; pausa e retomada legítimas continuam funcionando. O export_web.py instala e verifica o guard em toda exportação.

O mar tinha frames de superfície a 6 Hz, reflexos a 8 Hz e ondulação a 4 Hz, mas reconstruía seus comandos a cada frame. Agora redesenha apenas quando uma fase visual, câmera ou extensão muda. A câmera em movimento mantém atualização imediata.

Verificação: node tools/verify_web_audio.cjs e suítes Godot menu_music, sea_svg, ui_integration e integration. Estas verificações não medem FPS no dispositivo do usuário nem substituem ouvir o áudio no navegador.
