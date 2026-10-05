#!/usr/bin/env python3
"""Integrate the approved cosmic theme without changing the authored physics."""
from pathlib import Path
import json
ROOT=Path(__file__).resolve().parents[1]
def edit(path,changes):
 p=ROOT/path;s=p.read_text()
 for before,after in changes:s=s.replace(before,after)
 p.write_text(s)

def main():
 edit('godot/scripts/systems/hud.gd',[
  ('texture(title_screen,"logo",','texture(title_screen,"cosmic_logo",'),
  ('COSTA DOS VENTOS CONECTADOS','CONEXÃO DE OUTRO MUNDO'),
  ('COSTA DOS VENTOS','PLANETA ALIENÍGENA'),
  ('A COSTA ESPERA POR VOCÊ','O PLANETA ESPERA POR VOCÊ'),
  ('CONECTANDO A COSTA','CONECTANDO O PLANETA'),
  ('COSTA RECONECTADA','PLANETA RECONECTADO'),
  ('COSTA •','PLANETA •'),
  ('BrisinMenuCoastalPlatform','BrisinMenuCosmicPlatform')])
 edit('godot/scripts/world/world.gd',[
  ('CONECTANDO A COSTA','CONECTANDO O PLANETA'),('COSTA ONLINE','PLANETA ONLINE'),
  ('COSTA RECONECTADA','PLANETA RECONECTADO'),('CONCLUIR A COSTA','CONCLUIR A MISSÃO'),
  ('COSTA DOS VENTOS','PLANETA ALIENÍGENA'),
  ('portal_transition.position = point(level.portal) + Vector2(0,-100.5)','portal_transition.position = point(level.portal) + Vector2(0,-81.0)'),
  ('patrol.player = player','patrol.player = player\n  patrol.variant = str(level.get("enemy_variants",["cristal"])[enemies.size()%level.get("enemy_variants",["cristal"]).size()])')])
 edit('godot/scripts/enemies/noisezinho.gd',[
  ('var left :=','var variant := "cristal"\nvar left :='),
  ('sprite.sprite_frames = ANIMATIONS','sprite.sprite_frames = load("res://assets/enemies/cosmic/"+variant+"/spriteframes.tres")'),
  ('sprite.scale = Vector2(2,2)','sprite.scale = Vector2.ONE'),
  ('sprite.offset = Vector2(0,-16)','sprite.offset = Vector2(0,-48)'),
  ('sprite.modulate = Color("FFD84D") if stunned>0 else Color.WHITE','sprite.modulate = Color.WHITE')])
 edit('godot/scripts/systems/scenery_svg.gd',[
  ('node_pos+Vector2(0,-75)','node_pos+Vector2(0,-50)'),
  ('Vector2(0,-100.5)','Vector2(0,-81.0)')])
 edit('godot/scripts/interactables/marker.gd',[
  ('var kind :=','const ALIEN_CHECKPOINT_OFF = preload("res://assets/world_01/interactive/checkpoint_base_off.svg")\nconst ALIEN_CHECKPOINT_ON = preload("res://assets/world_01/interactive/checkpoint_base_on.svg")\nconst ALIEN_FLAG_OFF = preload("res://assets/world_01/interactive/checkpoint_flag_off.svg")\nconst ALIEN_FLAG_ON = preload("res://assets/world_01/interactive/checkpoint_flag_on.svg")\nvar kind :=')])
 p=ROOT/'godot/scripts/interactables/marker.gd';s=p.read_text()
 start=s.index('    # All checkpoints share');end=s.index('    return',start)
 s=s[:start]+'''    var bounds:=Rect2(Vector2(-54,-134),Vector2(128,140))
    draw_texture_rect(ALIEN_CHECKPOINT_ON if active else ALIEN_CHECKPOINT_OFF,bounds,false)
    # A cloth-only stepped shear keeps the flag attachment and mast fixed.
    var flag: Texture2D = ALIEN_FLAG_ON if active else ALIEN_FLAG_OFF
    var shift := 0.0 if WorldState.reduced_flash else snappedf(sin(time*2.0)*0.04,0.01)
    draw_set_transform_matrix(Transform2D(Vector2(1,0),Vector2(shift,1),Vector2(-54,-120)))
    draw_texture(flag,Vector2.ZERO)
    draw_set_transform(Vector2.ZERO)
''' +s[end:];p.write_text(s)
 # The panorama has no static foreground gameplay objects or rotating towers.
 (ROOT/'godot/scripts/systems/background_svg.gd').write_text('''extends Node2D
## Alien panorama: approved art as real SVG paths, one shared coordinate system.
const SIZE := Vector2(2172,724)
const VIEW := Vector2(1152,648)
const PANORAMA = preload("res://assets/background_svg/cosmic_panorama.svg")
const ATMOSPHERE = preload("res://assets/background_svg/atmosphere.svg")
var world: Node2D
var clock := 0.0
var artwork_enabled := true
var atmosphere_strength := 1.0
func _ready() -> void:
 texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
 z_index=-10
func set_art(enabled: bool) -> void:
 artwork_enabled=enabled
 visible=enabled
func panorama_rect(camera_center: Vector2,level_length: float=9600.0) -> Rect2:
 var travel:=maxf(1.0,level_length-VIEW.x)
 var progress:=clampf((camera_center.x-VIEW.x*0.5)/travel,0.0,1.0)
 return Rect2(camera_center-VIEW*0.5-Vector2(progress*(SIZE.x-VIEW.x),(SIZE.y-VIEW.y)*0.5),SIZE)
func camera_center() -> Vector2:
 if is_instance_valid(world) and is_instance_valid(world.player):
  return world.player.camera.get_screen_center_position()
 # Show the planet in the title's right half without moving UI or avatar.
 return Vector2(576,324)
func _process(dt: float) -> void:
 clock+=dt
 queue_redraw()
func _draw() -> void:
 if not artwork_enabled:return
 var length:=15235.0
 var blend:=0.0
 if is_instance_valid(world):
  length=float(world.level.length)
  blend=world.online_blend
 var rect:=panorama_rect(camera_center(),length)
 draw_texture(PANORAMA,rect.position,Color(0.76,0.8,0.94).lerp(Color.WHITE,blend))
 draw_texture(ATMOSPHERE,rect.position,Color(1,1,1,atmosphere_strength*0.72))
''')
 levelpath=ROOT/'godot/data/world_01.json';level=json.loads(levelpath.read_text())
 level['theme']='Conexão de Outro Mundo'
 level['enemy_variants']=['cristal','esporo','magnetico','escavador','plasma','satelite','corrompido','sentinela','orbital']
 for placement in level.get('environment',[]):
  if placement[0]=='palms':placement[4]=max(float(placement[4]),1.5)
 levelpath.write_text(json.dumps(level,ensure_ascii=False,indent=2)+'\n')
 edit('godot/project.godot',[('config/name="Brisin — Costa dos Ventos Conectados"','config/name="Brisin — Conexão de Outro Mundo"'),('config/custom_user_dir_name="godot/app_userdata/Brisinho — Costa dos Ventos Conectados"','config/custom_user_dir_name="godot/app_userdata/Brisin — Conexão de Outro Mundo"')])
 edit('godot/scripts/systems/world_state.gd',[('user://brisinho_v01.json','user://brisin_cosmic_v01.json')])
 edit('dist/index.html',[('Costa dos Ventos Conectados','Conexão de Outro Mundo'),('Conectando a Costa dos Ventos','Conectando outro mundo'),('logo.svg?v=18','logo.svg?v=cosmic1')])
 (ROOT/'dist/logo.svg').write_text((ROOT/'godot/assets/ui/cosmic_logo.svg').read_text())
 # Tutorial recognition keys follow the updated visible semantic titles.
 for p in (ROOT/'godot/tests').glob('*.gd'):
  s=p.read_text().replace('COSTA DOS VENTOS','PLANETA ALIENÍGENA').replace('COSTA RECONECTADA','PLANETA RECONECTADO')
  p.write_text(s)
 with (ROOT/'AGENTS.md').open('a') as f:
  f.write('''\n## Conexão de Outro Mundo — aprovação de 05/10/2026\n\n- Nesta branch, as referências em `tools/reference_art/cosmic/` substituem a direção costeira para cenário, plataformas, decoração, objetos e inimigos. Regras anteriores de física, proporção, legibilidade e lifecycle continuam válidas.\n- Título: **Brisin — Conexão de Outro Mundo**. Remover a frase de rodapé sobre restabelecer a conexão do planeta; não reincorporar o rodapé da imagem de conceito.\n- SVGs contêm paths reais, nunca PNG/base64. Fonte raster e gerador ficam fora dos recursos exportados; preservar o estilo e as nove paletas aprovadas.\n- Nove Ruídozinhos com animações de repouso, patrulha, alerta, dano e derrota. Variações são cosméticas nesta entrega; não inventar resistências ou ataques sem um design solicitado.\n- Background não contém Brisin, inimigos, gemas, portais ou plataformas de gameplay pintados. Névoa permanece no fundo; todos os efeitos animam no Godot, não via SMIL.\n- Progresso do planeta usa arquivo próprio, preservando o save da versão costeira. A geometria do percurso e os controles são mantidos nesta migração.\n''')
 print('Cosmic theme integrated.')
if __name__=='__main__':main()
