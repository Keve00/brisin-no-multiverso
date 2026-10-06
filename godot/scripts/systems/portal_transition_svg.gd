extends Node2D
## Finite 1.8s entry: approach / attraction / sealing, no screen flash.
## Source SVG pivots are centered; player shrink is uniform on a visual wrapper.
signal completed
signal cancelled
const DURATION := 1.8
const SPIRAL = preload("res://assets/world_01/interactive/portal_core.svg")
const TUNNEL = preload("res://assets/world_01/portal_transition/tunnel.svg")
const ARCS = preload("res://assets/world_01/portal_transition/arcs.svg")
const SPARK = preload("res://assets/world_01/portal_transition/spark.svg")
const AMBER_SPARK = preload("res://assets/world_01/portal_transition/spark_amber.svg")
var world: Node2D
var player: BrisinhoPlayer
var age := 0.0
var done := false
var start_foot := Vector2.ZERO
var root_ring: Sprite2D
var inner_ring: Sprite2D
var vortex: Sprite2D
var tunnel: Sprite2D
var depth_arcs: Array[Sprite2D] = []
var particles: Array[Sprite2D] = []
var visual_wrap: Node2D
var original_parent: Node
var original_position := Vector2.ZERO
var original_core_visible := true
var visual_restored := false
var prepared := false
var initial_rotation := 0.0
var initial_scale := 1.5
var initial_lanes_rotation := 0.0

func piece(image: Texture2D, factor: float) -> Sprite2D:
 var sprite := Sprite2D.new()
 sprite.texture = image
 sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
 sprite.scale = Vector2.ONE * factor
 add_child(sprite)
 return sprite

func _ready() -> void:
 if not is_instance_valid(player) or not is_instance_valid(world) or not is_instance_valid(player.visual):
  cancel()
  return
 z_index = 7
 start_foot = player.global_position
 prepared = true
 tunnel = piece(TUNNEL, 0.67)
 tunnel.z_index = -2
 for factor in [0.55, 0.35]:
  var arc := piece(ARCS, factor)
  arc.z_index = -1
  depth_arcs.append(arc)
 root_ring = piece(ARCS, 0.55)
 inner_ring = piece(ARCS, 0.40)
 vortex = piece(SPIRAL, 1.5)
 for i in (8 if WorldState.reduced_flash else 18):
  particles.append(piece(AMBER_SPARK if i % 4 == 0 else SPARK, 0.32 if i % 3 else 0.5))
 # Wrapping keeps Player.animate's native sprite scale and modulation intact;
 # body collision and Camera2D retain their original scale and position.
 original_parent = player.visual.get_parent()
 original_position = player.visual.position
 visual_wrap = Node2D.new()
 visual_wrap.name = "PortalVisualShrink"
 player.add_child(visual_wrap)
 player.visual.reparent(visual_wrap, false)
 player.visual.position = original_position
 if is_instance_valid(world.scenery_svg) and is_instance_valid(world.scenery_svg.portal_rotor):
  initial_rotation=world.scenery_svg.portal_core.rotation
  initial_scale=world.scenery_svg.portal_core.scale.x
  initial_lanes_rotation=world.scenery_svg.portal_lanes.rotation
  original_core_visible = world.scenery_svg.portal_rotor.visible
  world.scenery_svg.portal_rotor.hide()
 _animate()

func _process(dt: float) -> void:
 if done: return
 if not is_instance_valid(player) or not is_instance_valid(world):
  cancel()
  return
 if WorldState.connection != WorldState.Connection.ONLINE:
  cancel()
  return
 age = minf(age + dt, DURATION)
 _animate()
 if age >= DURATION:
  done = true
  set_process(false)
  completed.emit()

func _animate() -> void:
 var attraction := clampf((age - 0.35) / 1.0, 0.0, 1.0)
 var ease := attraction * attraction * (3.0 - 2.0 * attraction)
 var target_foot := global_position + Vector2(0, 35)
 # A shallow curved approach communicates attraction, while fixed endpoints and
 # the original 0.35s preparation keep entry/cleanup behavior unchanged.
 player.global_position = start_foot.lerp(target_foot, ease) + Vector2(0, -sin(ease * PI) * 12.0)
 player.velocity = Vector2.ZERO
 visual_wrap.scale = Vector2.ONE * lerpf(1.0, 0.08, ease)
 visual_wrap.modulate.a = 1.0 - clampf((attraction - 0.68) / 0.32, 0.0, 1.0)
 var seal := clampf((age - 1.35) / 0.4, 0.0, 1.0)
 var opening := 1.0 - seal * seal
 var tick := age
 var charge := smoothstep(0.0, 0.35, age)
 var drift := 0.65 if WorldState.reduced_flash else 1.0
 root_ring.scale = Vector2.ONE * (0.55 * opening)
 inner_ring.scale = Vector2.ONE * (lerpf(0.35, 0.40, charge) * opening)
 vortex.scale = Vector2.ONE * (lerpf(initial_scale, 1.52, charge) * opening)
 tunnel.scale = Vector2.ONE * (0.67 * opening)
 root_ring.rotation = initial_lanes_rotation-tick * 0.9 * drift
 inner_ring.rotation = tick * 1.2 * drift
 vortex.rotation = initial_rotation + tick * 0.7 * drift + ease * ease * 2.0 * drift
 # Keep the opening dark enough to read depth; opaque separated lanes make the
 # counter-rotation visible without an additive glow or a screen-sized flash.
 vortex.modulate = Color.WHITE
 root_ring.visible = opening > 0.04
 inner_ring.visible = root_ring.visible
 vortex.visible = root_ring.visible
 tunnel.visible = root_ring.visible
 for i in depth_arcs.size():
  var arc := depth_arcs[i]
  var breathe := 0.012 if WorldState.reduced_flash else 0.028
  arc.scale = Vector2.ONE * ((0.55 if i == 0 else 0.35) * opening * (1.0 + sin(tick * 4.0 + i * PI) * breathe))
  arc.rotation = tick * (-1.25 if i == 0 else 1.8) * drift
  arc.visible = root_ring.visible
 # Opaque pixel packets follow curved inbound paths. Their visible population
 # drains during sealing instead of jumping back out as the opening collapses.
 for i in particles.size():
  var packet := particles[i]
  var progress := fposmod(age * (0.45 if WorldState.reduced_flash else 0.85) + float(i) / particles.size(), 1.0)
  var radius := lerpf(40.0, 8.0, progress) * opening
  var angle := float(i) * TAU / particles.size() - tick * 1.4 * drift - progress * 1.6
  packet.position = (Vector2(cos(angle), sin(angle)) * radius).round()
  packet.rotation = snappedf(angle, TAU / 32.0)
  packet.modulate = Color.WHITE
  packet.visible = age < 1.7 and opening > 0.08 and progress > seal

func restore_visual() -> void:
 if visual_restored: return
 visual_restored = true
 if is_instance_valid(player) and is_instance_valid(visual_wrap) and is_instance_valid(player.visual) and is_instance_valid(original_parent):
  player.visual.reparent(original_parent, false)
  player.visual.position = original_position
  visual_wrap.queue_free()
 if is_instance_valid(world) and is_instance_valid(world.scenery_svg) and is_instance_valid(world.scenery_svg.portal_rotor):
  world.scenery_svg.portal_rotor.visible = original_core_visible

func cancel() -> void:
 if done: return
 done = true
 set_process(false)
 if prepared and is_instance_valid(player):
  player.global_position = start_foot
  player.velocity = Vector2.ZERO
 restore_visual()
 cancelled.emit()
 queue_free()
func _exit_tree() -> void:
 restore_visual()
 if not done:
  done = true
  if prepared and is_instance_valid(player): player.global_position = start_foot
  cancelled.emit()
