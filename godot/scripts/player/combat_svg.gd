extends Node2D
# One combat simulation owns pulse waves and SIMs. Visual radius and hit radius
# use the same expansion; no instantaneous center-distance hit hidden by a wave.
const Effects = preload("res://scripts/player/action_effects_svg.gd")
const Chip = preload("res://scripts/player/sim_projectile.gd")
var world: Node2D
var waves: Array[Dictionary] = []

func _ready() -> void:
 # Enemy support/patrol commits at priority 10; read its updated body afterward.
 process_physics_priority = 20

static func wave_touches_body(origin: Vector2, before: Rect2, after: Rect2, r0: float, r1: float) -> bool:
 # Substep relative body motion at <= 4 px. This follows the visible ring rather
 # than hitting by ground pivot or retroactively filling its transparent center.
 var steps := maxi(1,int(ceil((before.position.distance_to(after.position)+absf(r1-r0))/4.0)))
 for i in range(steps+1):
  var t := float(i)/steps
  var body := Rect2(before.position.lerp(after.position,t),after.size)
  var radius := lerpf(r0,r1,t)
  var near := Vector2(clampf(origin.x,body.position.x,body.end.x),clampf(origin.y,body.position.y,body.end.y))
  if origin.distance_to(near)>radius: continue
  var far_distance := 0.0
  for corner in [body.position,body.end,Vector2(body.position.x,body.end.y),Vector2(body.end.x,body.position.y)]:
   far_distance = maxf(far_distance,origin.distance_to(corner))
  if far_distance>=radius: return true
 return false

func start_pulse(origin: Vector2) -> void:
 if world.player.state in ["DISABLED","RESPAWN"] or get_tree().paused: return
 var bodies := {}
 for enemy in world.enemies: bodies[enemy.get_instance_id()] = enemy.combat_bounds()
 waves.append({"origin":origin,"age":0.0,"previous_radius":0.0,"hits":{},"bodies":bodies})
 # Start the matching visual here also for scripted/tutorial/test actions.
 world.player.action_effects.start_pulse(origin)

func launch_chip(origin: Vector2, direction: float) -> void:
 if world.player.state in ["DISABLED","RESPAWN"] or get_tree().paused: return
 var chip := Node2D.new()
 chip.set_script(Chip)
 chip.world = world
 chip.position = origin
 chip.direction = direction
 add_child(chip)

func clear() -> void:
 waves.clear()
 for chip in get_children(): chip.queue_free()

func _physics_process(dt: float) -> void:
 if world.player.state in ["DISABLED","RESPAWN"]:
  clear()
  return
 for wave in waves:
  wave.age += dt
  var radius: float = Effects.PULSE_RADIUS*Effects.pulse_expansion(wave.age)
  for enemy in world.enemies:
   if not enemy.alive or not enemy.visible or wave.hits.has(enemy.get_instance_id()): continue
   var body: Rect2 = enemy.combat_bounds()
   var id: int = enemy.get_instance_id()
   var previous: Rect2 = wave.bodies.get(id,body)
   wave.bodies[id] = body
   if wave_touches_body(wave.origin,previous,body,float(wave.previous_radius),radius):
    wave.hits[enemy.get_instance_id()] = true
    enemy.receive_pulse(wave.origin)
  wave.previous_radius = radius
 waves = waves.filter(func(wave: Dictionary) -> bool: return wave.age < Effects.PULSE_DURATION)
