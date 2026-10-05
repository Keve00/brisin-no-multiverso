extends Node2D
# White, corner-cut nano-SIM SVG with gold contacts. The projectile translates
# without rotating its hitbox. Full segment sweep prevents high-speed tunneling.
const SPEED := 760.0
const RANGE := 500.0
const SIZE := Vector2(24,28)
var world: Node2D
var direction := 1.0
var travelled := 0.0
var hit_age := -1.0
var texture: Texture2D
var spark: Texture2D
var previous_bodies := {}

func _ready() -> void:
 process_physics_priority = 30
 for enemy in world.enemies: previous_bodies[enemy.get_instance_id()] = enemy.combat_bounds()
 texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
 z_index = 6
 texture = preload("res://assets/player/effects/sim_chip.svg")
 spark = preload("res://assets/player/effects/pulse_spark.svg")

static func segment_rect_fraction(start: Vector2, step: Vector2, rect: Rect2) -> float:
 var first := 0.0
 var last := 1.0
 for axis in 2:
  if absf(step[axis])<0.00001:
   if start[axis]<rect.position[axis] or start[axis]>rect.end[axis]: return INF
  else:
   var a: float = (rect.position[axis]-start[axis])/step[axis]
   var b: float = (rect.end[axis]-start[axis])/step[axis]
   first = maxf(first,minf(a,b))
   last = minf(last,maxf(a,b))
   if first>last: return INF
 return first

func _physics_process(dt: float) -> void:
 if world.player.state in ["DISABLED","RESPAWN"]:
  queue_free()
  return
 if hit_age>=0:
  hit_age += dt
  if hit_age>=0.18: queue_free()
  queue_redraw()
  return
 var step := Vector2(direction*minf(SPEED*dt,RANGE-travelled),0)
 var query := PhysicsShapeQueryParameters2D.new()
 var box := RectangleShape2D.new()
 box.size = SIZE
 query.shape = box
 query.transform = Transform2D(0,global_position)
 query.motion = step
 query.collision_mask = 2|4
 var space := get_world_2d().direct_space_state
 var wall_fraction := INF
 if not space.intersect_shape(query,1).is_empty():
  wall_fraction = 0.0
 else:
  var wall := space.cast_motion(query)
  if wall[0]<1.0: wall_fraction = wall[0]
 var first_fraction := wall_fraction
 var target: Node2D
 for enemy in world.enemies:
  if not enemy.alive or not enemy.visible: continue
  # Expand body by SIM half-size: swept rectangle against rectangle.
  var current: Rect2 = enemy.combat_bounds()
  var previous: Rect2 = previous_bodies.get(enemy.get_instance_id(),current)
  previous_bodies[enemy.get_instance_id()] = current
  var body: Rect2 = previous.grow_individual(SIZE.x/2,SIZE.y/2,SIZE.x/2,SIZE.y/2)
  # Relative sweep catches enemies crossing the flight segment between ticks.
  var relative_step := step-(current.position-previous.position)
  var fraction := segment_rect_fraction(global_position,relative_step,body)
  if fraction<first_fraction:
   first_fraction = fraction
   target = enemy
 if first_fraction<=1.0:
  global_position += step*first_fraction
  if target: target.eliminate()
  else: Audio.play("hit")
  hit_age = 0.0
 else:
  global_position += step
  travelled += step.length()
  if travelled>=RANGE: queue_free()
 queue_redraw()

func _draw() -> void:
 if texture==null: return
 if hit_age<0:
  draw_texture(texture,-SIZE/2)
  for i in (1 if WorldState.reduced_flash else 3):
   draw_rect(Rect2(-direction*(20+i*10)-2,-2,4,4),Color("FFFFFF"))
 else:
  # Solid impact fragments travel apart and disappear, without fading the body.
  var count := 4 if WorldState.reduced_flash else 8
  for i in count:
   var offset := Vector2.from_angle(TAU*float(i)/count)*(8+hit_age*160)
   draw_texture(spark,offset-Vector2(10,10))
