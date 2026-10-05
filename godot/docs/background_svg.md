# Panorama SVG — fundo aprovado em 01/10/2026

## Fonte, conversão e camadas

Fonte aprovada: `tools/reference_art/approved-background.png`, 2172 × 724. O gerador reproduzível `tools/trace_background_svg.py` transforma pixels amostrados em células vetoriais de 2 × 2, mescla retângulos adjacentes e usa uma paleta compartilhada de 256 cores (192 gerais, 64 reservadas para as pequenas pás). Execute na raiz do repositório:

```sh
python tools/trace_background_svg.py tools/reference_art/approved-background.png
```

Os SVGs **não contêm `<image>`, PNG nem data URI**. A conversão mantém composição, proporções, lua, coqueiros, faróis, costa e mar da referência; a redução à grade/paleta é explícita. A referência raster é entrada da ferramenta, fica fora de `godot/` e não é camada de execução.

Camadas em `godot/assets/background_svg/`: `sky.svg`, `sea.svg`, `coast.svg`, `masts.svg`, `sea_glints.svg`, `rotor_0.svg`, `rotor_1.svg`, `rotor_2.svg`, `beacon_glow.svg`. Céu, costa, mar, mastros e reflexos compartilham canvas 2172 × 724 e a mesma origem. As máscaras são complementares: a separação não duplica pixels de pás. Rotação e animação ocorrem no motor, permitindo exportação web; SVG não usa SMIL.

## Pivôs e comportamento

| Turbina | Eixo no panorama | Canvas do rotor | Centro local | Giro |
| --- | --- | --- | --- | --- |
| 0 | 1318, 270 | 92 × 92 | 46, 46 | 0,26 rad/s |
| 1 | 1364, 339 | 64 × 64 | 32, 32 | 0,32 rad/s |
| 2 | 1418, 317 | 76 × 76 | 38, 38 | 0,23 rad/s |

As pás foram isoladas na arte aprovada; o céu em sua posição antiga foi reconstruído a partir da mesma linha, preservando o mastro. Não há rotor estático desenhado sob outro rotor, nem círculo opaco de céu como remendo. Cada canvas quadrado tem 5 px de margem radial. O eixo é medido na referência, não recalculado pelo bounding box.

`background_svg.gd` desenha o panorama uma única vez, com escala uniforme 1:1. O movimento da câmera ao longo dos 9600 px percorre somente os 1020 px excedentes do panorama de 2172 px em relação à vista de 1152 px. A altura de 724 cobre a vista 648 com 38 px de reserva em cada borda. Todas as camadas mantêm o mesmo parallax distante para não abrir fendas no horizonte. Não há espelho, repetição abrupta ou plataforma/jangada/gema nova desenhada no fundo. Ilhas luminosas presentes na referência continuam distantes e decorativas.

Reflexos do mar modulam a opacidade de células claras extraídas, sem deslocar pixels do litoral. Halos nos três faróis variam suavemente; `reduced_flash` reduz a amplitude. Não há flashes de tela.

## Integração e evidência

Crie `Node2D`, aplique o script, configure `.world = self`, adicione ao mundo e chame `set_art(enabled)` junto ao restante da arte. O node usa `z_index = -10`. O preenchimento opaco e o antigo desenho PNG no `_draw` do mundo devem permanecer somente no modo blockout; caso contrário encobrem o panorama novo. A água de perigo jogável continua independente do fundo.

- Importação Godot 4.5.1: concluída sem erros de SVG.
- `godot/tests/background_svg.tscn`: **15/15**, cobrindo cinco posições de câmera, proporção uniforme e três canvases de rotor.
- Renderização SVG com Sharp/librsvg: panorama inteiro e recortes de turbinas em 0 s e 12 s inspecionados. Mastros permanecem fixos, somente os rotores mudam ângulo; não há pás antigas por baixo.
- Prévia SVG independente: `docs/background_svg_preview.svg`, fora dos recursos exportados.
- A importação e renderização acima não substituem a revisão do jogo publicado em navegador.

## Atmosfera e profundidade — revisão de 01/10/2026

`atmosphere.svg` acrescenta névoa azul suave (`#95B4D6`) exclusivamente ao panorama distante. Compartilha canvas 2172 × 724, origem e parallax das outras camadas; é desenhado por último no próprio Node2D do fundo em `z_index = -10`. Assim personagem, plataformas jogáveis, efeitos de combate e HUD permanecem com suas cores e contraste próprios. Não há filtro de tela ou escurecimento global.

O véu usa faixas horizontais de 2 px na mesma grade lógica, sem blur: 2,5% no céu alto, até 28% no horizonte/mar distante e 13,5% na borda inferior. A interpolação suave entre as faixas evita linhas perceptíveis, preserva formas, silhuetas e composição aprovadas e recupera parte do contraste na água mais próxima. A névoa é estática; não adiciona brilho pulsante nem flashes.

Prévia da mesma composição: `docs/background_atmosphere_preview.svg`. Comparação renderizada antes/depois foi inspecionada: paleta distante fica menos saturada e com contraste menor no horizonte, enquanto estrelas/lua e contornos pixelados continuam legíveis. A renderização independente confirma a aparência do panorama, não a revisão do jogo no navegador. O teste `background_svg.tscn` agora confere também canvas da atmosfera e ordem atrás do gameplay (17 verificações).

Validação desta revisão:

- Godot 4.5.1 importou `atmosphere.svg` sem erros.
- `background_svg.tscn`: **17/17**.
- Amostra da faixa do horizonte (y 380–470): saturação RGB média caiu de 0,611 para 0,489; contraste local horizontal caiu de 0,075 para 0,055. No céu alto a saturação ficou 0,447 → 0,441. Medição da renderização SVG com a mesma composição e resolução, sem redimensionamento.
- Comparação antes/depois renderizada e inspecionada; o esmaecimento é mais forte na faixa distante e mantém a grade de pixels.


### Intensidade ampliada a pedido do usuário

Multiplicador 1,35 do perfil anterior, mantendo cada faixa de 2 px e posição.
Pico de névoa 28% → 37,8%; céu alto 2,5% → 3,38%; borda inferior 13,5% → 18,23%.
Gerador `tools/build_atmosphere_svg.py` lê o perfil base preservado fora do res://,
evitando ganho cumulativo em execuções repetidas. Somente o fundo é afetado.


### Esmaecimento e ondulações — nova revisão

O perfil original é remapeado com piso18% e ganho1,45 acima de0,025:
pico55%, céu18% e borda inferior34%. Isso esmaece também o céu atrás do HUD,
em vez de concentrar toda a mudança no horizonte.
Névoa segue apenas o panorama. Ondulações são SVGs pequenos64×12 em19 posições
selecionadas pela máscara real do mar, com envelope80×20 inteiramente coberto
pela água, mesmo com deslocamento6×2px. Nenhuma ilha é lavada por reflexos.
As ondulações são desenhadas antes da névoa e respeitam flashes reduzidos.
O menu reutiliza o mesmo fundo SVG, sem conversão paraPNG.
