extends Node2D
## Near sea hazard artwork: native SVG tiles, 1:1 scale, no collision shapes.
## It lives above the panorama and behind gameplay, and follows world position.
const TILE_SIZE := Vector2(512,224)
const WATER_Y := 810.0
const FRAME_COUNT := 12
const FPS := 6.0
const ROOT := "res://assets/sea_svg/"
const REFLECTIONS = preload("res://assets/sea_svg/reflections.svg")
const SWELL = preload("res://assets/sea_svg/swell.svg")
var world: Node2D
var clock := 0.0
var artwork_enabled := true
var surface_frames: Array[Texture2D] = []
var _draw_valid := false
var _draw_phase := Vector3i.ZERO
var _draw_view := Rect2()
var _draw_length := 0.0

func _ready() -> void:
 process_mode = Node.PROCESS_MODE_PAUSABLE
 texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
 z_index = -3
 for i in FRAME_COUNT:
  surface_frames.append(load(ROOT+"surface_%02d.svg"%i))

func set_art(enabled: bool) -> void:
 artwork_enabled = enabled
 visible = enabled
 _draw_valid = false

func _process(dt: float) -> void:
 if not artwork_enabled: return
 clock += dt
 var length := 9600.0
 if is_instance_valid(world): length = float(world.level.get("length",9600))
 if refresh_needed(camera_rect(), length): queue_redraw()

func refresh_needed(view: Rect2, length: float) -> bool:
 var phase := Vector3i(frame_index(), int(reflection_offset()), int(swell_offset()))
 if _draw_valid and phase == _draw_phase and view == _draw_view and length == _draw_length:
  return false
 _draw_valid = true
 _draw_phase = phase
 _draw_view = view
 _draw_length = length
 return true

func frame_index() -> int:
 return int(floor(clock*FPS))%FRAME_COUNT

func reflection_offset() -> float:
 return fmod(floor(clock*8.0)*2.0,TILE_SIZE.x)

func swell_offset() -> float:
 return -fmod(floor(clock*4.0)*2.0,TILE_SIZE.x)

func coverage_rect(level_length: float) -> Rect2:
 return Rect2(0,WATER_Y,level_length,TILE_SIZE.y)

func camera_rect() -> Rect2:
 if is_instance_valid(world) and is_instance_valid(world.player):
  return Rect2(world.player.camera.get_screen_center_position()-Vector2(576,324),Vector2(1152,648))
 return Rect2(0,600,1152,648)

# Each texture's 512px period is preserved. Edge tiles are cropped, never resized.
# Public for coverage/seam tests; destination and source always share dimensions.
func tile_regions(view: Rect2, level_length: float, offset: float = 0.0) -> Array[Dictionary]:
 var regions: Array[Dictionary] = []
 var sea := coverage_rect(level_length)
 if not sea.intersects(view): return regions
 var first := int(floor((maxf(0.0,view.position.x)-offset)/TILE_SIZE.x))
 var last := int(floor((minf(level_length,view.end.x)-offset)/TILE_SIZE.x))
 for index in range(first,last+1):
  var origin := index*TILE_SIZE.x+offset
  var left := maxf(0.0,origin)
  var right := minf(level_length,origin+TILE_SIZE.x)
  if right<=left: continue
  var size := Vector2(right-left,TILE_SIZE.y)
  regions.append({"destination":Rect2(Vector2(left,WATER_Y),size),
   "source":Rect2(Vector2(left-origin,0),size)})
 return regions

func draw_layer(texture: Texture2D, view: Rect2, length: float, offset: float) -> void:
 for region in tile_regions(view,length,offset):
  draw_texture_rect_region(texture,region.destination,region.source)

func _draw() -> void:
 if not artwork_enabled or surface_frames.is_empty(): return
 var length := 9600.0
 if is_instance_valid(world): length=float(world.level.get("length",9600))
 var view := camera_rect()
 if not coverage_rect(length).intersects(view): return
 draw_layer(surface_frames[frame_index()],view,length,0.0)
 draw_layer(REFLECTIONS,view,length,reflection_offset())
 draw_layer(SWELL,view,length,swell_offset())
