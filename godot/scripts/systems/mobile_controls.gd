extends CanvasLayer
## Equivalent multitouch router: viewport-space coordinates, per-finger owners,
## no synthetic mouse or InputMap mutation. Menus retain normal Godot GUI input.
const VIEW := Vector2(1152,648)
const FONT = preload("res://assets/ui/mobile/brisin_mobile_bold.fnt")
const FRAME = preload("res://assets/ui/mobile/action.svg")
const FOCUS = preload("res://assets/ui/mobile/action_pressed.svg")
const PRIMARY = preload("res://assets/ui/mobile/action_primary.svg")
const PRIMARY_FOCUS = preload("res://assets/ui/mobile/action_primary_pressed.svg")
const DIRECTION = preload("res://assets/ui/mobile/direction.svg")
const DIRECTION_FOCUS = preload("res://assets/ui/mobile/direction_pressed.svg")
const ICONS = {
 "move_left":preload("res://assets/ui/mobile/icon_left.svg"),
 "move_right":preload("res://assets/ui/mobile/icon_right.svg"),
 "jump":preload("res://assets/ui/mobile/icon_jump.svg"),
 "dash":preload("res://assets/ui/mobile/icon_dash.svg"),
 "chip":preload("res://assets/ui/mobile/icon_chip.svg"),
 "pulse":preload("res://assets/ui/mobile/icon_pulse.svg"),
 "pause":preload("res://assets/ui/mobile/icon_pause.svg")
}
var hud: CanvasLayer
var world: Node2D
var surface: Node2D
var areas: Dictionary = {}
var fingers: Dictionary = {}
var enabled := false
var layout_key := ""
var unit := 96.0
var frame_clock := 0.0

func _ready() -> void:
 process_mode = Node.PROCESS_MODE_ALWAYS
 layer = 21
 surface = Node2D.new()
 surface.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
 surface.draw.connect(draw_controls)
 add_child(surface)
 GameCommands.clear()

func layout(css_scale: float = 0.0) -> void:
 # CSS scale comes from the actual fitted canvas, NOT its 1152px backing store.
 var factor: float = css_scale if css_scale>0 else WorldState.mobile_css_scale()
 # Match approved silhouette/spacing at default size, enlarging only when
 # the fitted CSS canvas needs it. Keep independently adjustable safe targets.
 unit = ceilf(maxf(116.0,48.0/factor)*WorldState.control_scale)
 var small := ceilf(maxf(108.0,48.0/factor)*WorldState.control_scale)
 var dash_size := ceilf(maxf(124.0,48.0/factor)*WorldState.control_scale)
 var jump_size := ceilf(maxf(148.0,64.0/factor)*WorldState.control_scale)
 var gap := maxf(20.0,8.0/factor)
 var margin := 32.0
 var floor_y := 616.0-WorldState.control_lift*90.0
 areas.clear()
 areas["move_left"] = Rect2(margin,floor_y-unit,ceilf(unit*1.25),unit)
 areas["move_right"] = Rect2(margin+ceilf(unit*1.25)+gap,floor_y-unit,ceilf(unit*1.25),unit)
 areas["jump"] = Rect2(1152-margin-jump_size,floor_y-jump_size,jump_size,jump_size)
 areas["dash"] = Rect2(areas.jump.position.x-gap-dash_size,floor_y-dash_size,dash_size,dash_size)
 # CHIP above DASH, PULSO above PULO: the approved gently offset thumb arc.
 var upper_y: float = areas.jump.position.y-gap-small
 areas["pulse"] = Rect2(1152-margin-small,upper_y-4,small,small)
 areas["chip"] = Rect2(areas.pulse.position.x-gap-small,upper_y+8,small,small)
 var pause_size := ceilf(maxf(64.0,48.0/factor))
 areas["pause"] = Rect2(1152-20-pause_size,20,pause_size,pause_size)
 if WorldState.controls_mirrored:
  for action in areas:
   if action == "pause": continue
   var rect: Rect2 = areas[action]
   rect.position.x = 1152-rect.end.x
   areas[action] = rect

func clear() -> void:
 fingers.clear()
 GameCommands.clear()

func _process(dt: float) -> void:
 var usable: bool = WorldState.mobile_enabled and not WorldState.mobile_portrait and not WorldState.interrupted and not get_tree().paused and is_instance_valid(world) and is_instance_valid(world.player) and world.player.state not in ["RESPAWN","DISABLED"] and hud.menu_kind.is_empty()
 if usable != enabled:
  enabled = usable
  clear()
 surface.visible = enabled
 var key := str([WorldState.mobile_css_scale(),WorldState.control_scale,WorldState.controls_mirrored,WorldState.control_lift])
 if key != layout_key:
  layout_key = key
  clear()
  layout()
 if enabled and WorldState.chip_repeat and GameCommands.owners.values().has("chip") and world.player.chip_cooldown <= 0:
  GameCommands.presses["chip"] = true
 frame_clock += dt
 if frame_clock >= 1.0/30.0:
  frame_clock = 0
  surface.queue_redraw()

func hit(position: Vector2) -> String:
 for action in areas:
  if areas[action].has_point(position): return action
 return ""

func route(index: int, position: Vector2, down: bool, canceled: bool = false) -> void:
 if not down or canceled:
  fingers.erase(index)
  GameCommands.set_touch(index,"")
  return
 var action := hit(position)
 if action == "pause":
  clear()
  hud.show_menu("pause")
  return
 # Only fingers that started in a control can acquire actions while dragging.
 if action.is_empty(): return
 fingers[index] = true
 GameCommands.set_touch(index,action)

func drag(index: int, position: Vector2) -> void:
 if not fingers.has(index): return
 var action := hit(position)
 GameCommands.set_touch(index,"" if action == "pause" else action)

func _input(event: InputEvent) -> void:
 if not enabled or get_tree().paused: return
 if event is InputEventScreenTouch:
  route(event.index,event.position,event.pressed,event.canceled)
  get_viewport().set_input_as_handled()
 elif event is InputEventScreenDrag:
  drag(event.index,event.position)
  get_viewport().set_input_as_handled()
 elif event is InputEventMouse and event.device == InputEvent.DEVICE_ID_EMULATION:
  get_viewport().set_input_as_handled()

func draw_controls() -> void:
 if not enabled: return
 var names := {"jump":"PULO","dash":"DASH","chip":"CHIP","pulse":"PULSO"}
 if WorldState.connection == WorldState.Connection.OFFLINE and world.player.position.distance_to(world.point(world.level.node))<125:
  names.pulse = "CONECTAR"
 for action in areas:
  var rect: Rect2 = areas[action]
  var active: bool = GameCommands.owners.values().has(action)
  var frame: Texture2D = PRIMARY_FOCUS if active else PRIMARY
  if action != "jump": frame = FOCUS if active else FRAME
  if action in ["move_left","move_right"]: frame = DIRECTION_FOCUS if active else DIRECTION
  # Modular UI frame only. Icons retain their 1:1 aspect ratio.
  surface.draw_texture_rect(frame,rect,false)
  var icon_size := rect.size.y*0.46
  var center := rect.get_center()
  if action in ["move_left","move_right","pause"]:
   icon_size=rect.size.y*0.52
   surface.draw_texture_rect(ICONS[action],Rect2(center-Vector2.ONE*icon_size/2,Vector2.ONE*icon_size),false)
   continue
  var icon_center := center+Vector2(0,-rect.size.y*0.16)
  surface.draw_texture_rect(ICONS[action],Rect2(icon_center-Vector2.ONE*icon_size/2,Vector2.ONE*icon_size),false)
  var font_size := int(maxf(24,14.0/WorldState.mobile_css_scale()))
  var text: String = names[action]
  var size := FONT.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size)
  if size.x>rect.size.x-24:
   font_size = int(font_size*(rect.size.x-24)/size.x)
   size = FONT.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size)
  var baseline := center+Vector2(-size.x/2,rect.size.y*0.27)
  surface.draw_string(FONT,baseline+Vector2(2,2),text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,Color("100a04"))
  surface.draw_string(FONT,baseline,text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,Color("fff3cd"))
  if action in ["dash","chip","pulse"]:
   var ready := 1.0
   if action == "dash": ready = 1.0-clampf(world.player.cooldown/world.player.tuning.dash_cooldown,0,1) if world.player.dash_available else 0.0
   if action == "chip": ready = 1.0-world.player.chip_cooldown/0.35
   if action == "pulse": ready = 1.0-world.player.pulse_time/0.55
   if ready < 0.999:
    surface.draw_rect(Rect2(rect.position+Vector2(28,rect.size.y-23),Vector2((rect.size.x-56)*clampf(ready,0,1),3)),Color("ffd84d"))

func _exit_tree() -> void:
 clear()
