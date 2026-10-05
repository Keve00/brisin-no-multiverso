extends Node2D
## Alien panorama: approved art as real SVG paths, one shared coordinate system.
const SIZE := Vector2(2172,724)
const VIEW := Vector2(1152,648)
const PANORAMA = preload("res://assets/background_svg/cosmic_panorama.svg")
const BEACON = preload("res://assets/background_svg/beacon_glow.svg")
const RELAYS = [Vector2(203,110),Vector2(384,216),Vector2(697,191),Vector2(974,269),Vector2(1086,376),Vector2(1253,390)]
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
 if not is_instance_valid(world):rect.position.x=-430.0
 draw_texture(PANORAMA,rect.position,Color(0.76,0.8,0.94).lerp(Color.WHITE,blend))
 for index in RELAYS.size():
  var strength:=0.04+(0.08 if WorldState.reduced_flash else 0.14)*(0.5+0.5*sin(clock*0.8+index))
  draw_texture(BEACON,rect.position+RELAYS[index]-Vector2(32,32),Color(1,0.65,0.35,strength*(0.3+blend*0.7)))
 draw_texture(ATMOSPHERE,rect.position,Color(1,1,1,atmosphere_strength*0.72))
