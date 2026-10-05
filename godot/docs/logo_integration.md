# Logo BRISIN — integração de 03/10/2026

O logo fornecido pelo usuário substitui a palavra construída pela fonte bitmap.
Símbolo de vento amarelo e letras creme/laranja são geometria SVG real, com
fundo transparente. Canvas: 442 × 209; nenhum PNG/base64 foi embutido.

- Fonte canônica: `tools/reference_art/brisin-logo.svg`.
- Menu Godot: `godot/assets/ui/logo.svg`, KEEP_ASPECT_CENTERED no retângulo
  (76,16,432,168). A escala é 168/209 nos dois eixos; dimensão desenhada
  aproximadamente 355,3 × 168. O subtítulo usa (76,202,432,36), fonte 24 px, antes do botão y272.
- Carregamento web: `dist/logo.svg`, mesmo conteúdo; dimensão HTML 442 × 209,
  largura CSS limitada a 360 px/50vw e altura automática. Linha do h1 sem sobra
  de baseline; referência versionada evita reutilizar o logo anterior em cache.
- O gerador da interface copia o SVG canônico, preservando a aprovação.

Verificação: importação/exportação no Godot 4.5.1 sem erros; teste existente
ui_integration: 41/41 aprovado. PCK reconstruído, tamanho atualizado,
verify-loader e verify_web_audio aprovados. Revisão visual do menu por composição
CPU renderizada dos mesmos assets e posições, não por captura do navegador.

Revisão de espaçamento: 18 px livres entre a área do logo e a do subtítulo;
34 px entre o subtítulo e o primeiro botão. Botões de 60 px com intervalo
de 20 px, inclusive ao exibir Nova aventura.

Revisão: EXPAND_IGNORE_SIZE é aplicado antes de carregar textura e definir tamanho. Caso contrário, o mínimo nativo de 442 × 209 podia aumentar o retângulo do logo, causando sobreposição. UI headless verifica a área efetiva; prévia CPU verifica a composição.
