extends Node2D
const CHECKPOINT_BASE = preload("res://assets/world_01/checkpoint_coastal/base.svg")
const CHECKPOINT_CORE_OFF = preload("res://assets/world_01/checkpoint_coastal/core_off.svg")
const CHECKPOINT_CORE_ON = preload("res://assets/world_01/checkpoint_coastal/core_on.svg")
const CHECKPOINT_SIGNALS = [
 preload("res://assets/world_01/checkpoint_coastal/signal_00.svg"),
 preload("res://assets/world_01/checkpoint_coastal/signal_01.svg"),
 preload("res://assets/world_01/checkpoint_coastal/signal_02.svg"),
 preload("res://assets/world_01/checkpoint_coastal/signal_03.svg"),
 preload("res://assets/world_01/checkpoint_coastal/signal_04.svg"),
 preload("res://assets/world_01/checkpoint_coastal/signal_05.svg"),
 preload("res://assets/world_01/checkpoint_coastal/signal_06.svg"),
 preload("res://assets/world_01/checkpoint_coastal/signal_07.svg")]
const TOTEM_SCALE := 1.0
const TOTEM_PIVOT := Vector2(40,125)
const GEM = preload("res://assets/world_01/svg/gem_orange.svg")
const GEM_GLOW = preload("res://assets/world_01/svg/gem_glow.svg")
const GEM_SPARKLE = preload("res://assets/world_01/svg/gem_sparkle.svg")
signal activated(kind: String, id: String)
const ALIEN_CHECKPOINT_OFF = preload("res://assets/world_01/interactive/checkpoint_base_off.svg")
const ALIEN_CHECKPOINT_ON = preload("res://assets/world_01/interactive/checkpoint_base_on.svg")
const ALIEN_FLAG_OFF = preload("res://assets/world_01/interactive/checkpoint_flag_off.svg")
const ALIEN_FLAG_ON = preload("res://assets/world_01/interactive/checkpoint_flag_on.svg")
var alien_flags: Dictionary = {}
func _ready() -> void:
 for state_name in ["off","on"]:
  alien_flags[state_name]=[]
  for index in 8: alien_flags[state_name].append(load("res://assets/world_01/interactive/checkpoint_flag_%s_%02d.svg"%[state_name,index]))
var kind := "fragment"
var id := ""
var active := false
var portal_rearm_needed := false
const PORTAL_OPENING := Rect2(-58,-157,116,150)
func overlaps_portal() -> bool:
 var body := Rect2(player.position-position+Vector2(-26,-56),Vector2(52,56))
 return PORTAL_OPENING.intersects(body)
var player: BrisinhoPlayer
var time := 0.0
var art := false
func configure(type: String, key: String, point: Vector2) -> void:
 kind = type
 id = key
 position = point
func set_art(enabled: bool) -> void:
 art = enabled
 queue_redraw()
func _physics_process(dt: float) -> void:
 time += dt
 if not is_instance_valid(player) or player.state in ["DISABLED","RESPAWN"]: return
 var distance := player.position.distance_to(position)
 if kind == "portal" and portal_rearm_needed and not overlaps_portal():
  portal_rearm_needed = false
 if kind == "fragment" and not active and distance<48:
  active = true
  visible = false
  activated.emit(kind,id)
 if kind == "checkpoint" and not active and distance<60:
  active = true
  activated.emit(kind,id)
 if kind == "portal" and not active and not portal_rearm_needed and WorldState.connection == WorldState.Connection.ONLINE and overlaps_portal():
  # The world accepts and latches the entry; failed/blocked calls remain usable.
  activated.emit(kind,id)
 queue_redraw()
func pulse(origin: Vector2) -> void:
 if kind == "node" and not active and origin.distance_to(position+Vector2(0,-35))<125:
  active = true
  activated.emit(kind,id)
func _draw() -> void:
 var cyan := Color("43e9ee")
 match kind:
  "fragment":
   var phase := time * 2.4 + float(id.hash() % 100) * 0.0628
   var pulse_value := (sin(phase) + 1.0) * 0.5
   # Slow continuous 6% breathing, centered on the same pivot on both axes.
   # Reduced-flash mode preserves the pulse with lower brightness amplitude.
   var factor := 1.0 + pulse_value * (0.025 if WorldState.reduced_flash else 0.06)
   var center := Vector2(0,roundf(sin(time*2.4)*3)-22)
   if art:
    var size := GEM.get_size()*factor
    var rect := Rect2(center-size/2.0,size)
    var glow_alpha := 0.55+pulse_value*(0.15 if WorldState.reduced_flash else 0.4)
    draw_texture_rect(GEM_GLOW,rect,false,Color(1,1,1,glow_alpha))
    draw_texture_rect(GEM,rect,false)
    draw_texture_rect(GEM_SPARKLE,rect,false,Color(1,1,1,0.2+pulse_value*0.5))
   else:
    draw_colored_polygon(PackedVector2Array([center+Vector2(0,-16)*factor,center+Vector2(12,0)*factor,center+Vector2(0,16)*factor,center+Vector2(-12,0)*factor]),Color("ff921b"))
  "checkpoint":
   if art:
    var bounds:=Rect2(Vector2(-54,-134),Vector2(128,140))
    draw_texture_rect(ALIEN_CHECKPOINT_ON if active else ALIEN_CHECKPOINT_OFF,bounds,false)
    var frame:=0 if WorldState.reduced_flash else int(time*5.0)%8
    var state_name:="on" if active else "off"
    draw_texture_rect(alien_flags[state_name][frame],bounds,false)
    return
   draw_rect(Rect2(-20,-7,40,7),Color("32506a"))
   draw_line(Vector2(0,-8),Vector2(0,-82),cyan if active else Color("b0bacc"),5)
   draw_colored_polygon(PackedVector2Array([Vector2(2,-82),Vector2(40,-65),Vector2(2,-48)]),cyan if active else Color("e69d4a"))
   if active: draw_arc(Vector2(0,-30),45,0,TAU,32,Color(0.2,1,1,0.3),2)
  "node":
   if art: return
   draw_rect(Rect2(-23,-32,46,32),Color("344d66"))
   draw_circle(Vector2(0,-50),24,cyan if active else Color("ad65c8"))
   draw_circle(Vector2(0,-50),12,Color("102941"))
   draw_arc(Vector2(0,-50),35,time,time+TAU*0.75,24,cyan,3)
  "portal":
   if art: return
   var online := WorldState.connection == WorldState.Connection.ONLINE
   draw_arc(Vector2(0,-70),60,0,TAU,40,cyan if online else Color("615473"),15)
   if not online: draw_line(Vector2(-35,-100),Vector2(35,-35),Color("cf7bdd"),4)
