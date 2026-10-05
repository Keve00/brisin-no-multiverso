extends Node2D
## The approved 2172x724 panorama traced to real SVG geometry. All layers share
## one canvas, scale and far-plane parallax, so their coastlines never separate.
## Rigid turbine masts are a separate fixed layer; only the isolated rotors rotate.
const SIZE := Vector2(2172,724)
const VIEW := Vector2(1152,648)
const SKY = preload("res://assets/background_svg/sky.svg")
const SEA = preload("res://assets/background_svg/sea.svg")
const COAST = preload("res://assets/background_svg/coast.svg")
const MASTS = preload("res://assets/background_svg/masts.svg")
const GLINTS = preload("res://assets/background_svg/sea_glints.svg")
const RIPPLE = preload("res://assets/background_svg/ripple.svg")
var ripple_positions: Array = []
const ATMOSPHERE = preload("res://assets/background_svg/atmosphere.svg")
const BEACON = preload("res://assets/background_svg/beacon_glow.svg")
const ROTORS = [preload("res://assets/background_svg/rotor_0.svg"),preload("res://assets/background_svg/rotor_1.svg"),preload("res://assets/background_svg/rotor_2.svg")]
const PIVOTS = [Vector2(1318,270),Vector2(1364,339),Vector2(1418,317)]
const SPEEDS = [0.26,0.32,0.23]
const BEACONS = [Vector2(949,397),Vector2(1255,315),Vector2(1610,396)]
var world: Node2D
var clock := 0.0
var artwork_enabled := true
var atmosphere_strength := 1.0

func _ready() -> void:
 texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
 z_index = -10
 ripple_positions = JSON.parse_string(FileAccess.get_file_as_string("res://assets/background_svg/ripple_positions.json"))

func set_art(enabled: bool) -> void:
 artwork_enabled = enabled
 visible = enabled

# Public for coverage tests. No stretch, tiling or horizontal reflection.
func panorama_rect(camera_center: Vector2, level_length: float = 9600.0) -> Rect2:
 var travel := maxf(1.0,level_length-VIEW.x)
 var progress := clampf((camera_center.x-VIEW.x*0.5)/travel,0.0,1.0)
 var offset_x := progress*(SIZE.x-VIEW.x)
 return Rect2(camera_center-VIEW*0.5-Vector2(offset_x,(SIZE.y-VIEW.y)*0.5),SIZE)

func camera_center() -> Vector2:
 if is_instance_valid(world) and is_instance_valid(world.player):
  return world.player.camera.get_screen_center_position()
 return VIEW*0.5

func _process(dt: float) -> void:
 clock += dt
 queue_redraw()

func _draw() -> void:
 if not artwork_enabled: return
 var length := 9600.0
 var blend := 0.0
 if is_instance_valid(world):
  length = float(world.level.get("length",9600))
  blend = world.online_blend
 var rect := panorama_rect(camera_center(),length)
 var tint := Color(0.84,0.88,1.0).lerp(Color.WHITE,blend)
 # Full-size textures in shared coordinates: the 1:1 ratio is deliberate.
 draw_texture(SKY,rect.position,tint)
 draw_texture(SEA,rect.position,tint)
 draw_texture(COAST,rect.position,tint)
 draw_texture(MASTS,rect.position,tint)
 # Move no shore pixels. Reflections modulate only their extracted bright cells.
 var light_amplitude := 0.035 if WorldState.reduced_flash else 0.10
 var sea_alpha := 0.05+light_amplitude*(0.5+0.5*sin(clock*1.25))
 draw_texture(GLINTS,rect.position,Color(1,1,1,sea_alpha))
 for i in ROTORS.size():
  var rotor: Texture2D = ROTORS[i]
  var pivot: Vector2 = rect.position+PIVOTS[i]
  draw_set_transform(pivot,clock*float(SPEEDS[i]))
  draw_texture(rotor,-rotor.get_size()*0.5,tint)
 draw_set_transform(Vector2.ZERO)
 # These are translucent SVG halos on approved beacon positions, never flash.
 var beacon_amplitude := 0.08 if WorldState.reduced_flash else 0.22
 for i in BEACONS.size():
  var alpha := 0.18+beacon_amplitude*(0.5+0.5*sin(clock*0.85+i*1.2))
  draw_texture(BEACON,rect.position+BEACONS[i]-BEACON.get_size()*0.5,Color(1,1,1,alpha))

 # Tiny real SVG wavelets drift only inside authored, padded sea-only regions.
 for i in ripple_positions.size():
  var cell: Array = ripple_positions[i]
  var sway := Vector2(snappedf(sin(clock*0.6+i*1.7)*6,2),snappedf(sin(clock*0.45+i)*2,2))
  var intensity := 0.23 if WorldState.reduced_flash else 0.28+0.05*sin(clock*0.7+i*0.9)
  draw_texture(RIPPLE,rect.position+Vector2(cell[0],cell[1])+sway-RIPPLE.get_size()*0.5,Color(1,1,1,intensity))
 # The mist belongs only to this far-plane node (z=-10). Its stepped gradient
 # follows the shared panorama; foreground platforms, player and HUD stay crisp.
 # The horizon is softened more than the lower sea; no blur or global overlay.
 draw_texture(ATMOSPHERE,rect.position,Color(1,1,1,atmosphere_strength))
