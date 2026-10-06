extends Node2D
const Sweep = preload("res://scripts/player/sim_projectile.gd")
const SPEED := 270.0
const RANGE := 480.0
const SIZE := Vector2(12,10)
var world: Node2D
var combat: Node2D
var owner_id := 0
var velocity := Vector2.ZERO
var travelled := 0.0
var hit_age := -1.0
var blocked := false
var previous_player := Vector2.ZERO
func _ready() -> void:
 process_physics_priority = 30
 texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
 z_index = 6
 previous_player = world.player.global_position
func _physics_process(dt: float) -> void:
 if world.player.state in ["DISABLED","RESPAWN"]:
  queue_free()
  return
 if hit_age>=0:
  hit_age += dt
  if hit_age>=0.18: queue_free()
  queue_redraw()
  return
 var step := velocity.normalized()*minf(velocity.length()*dt,RANGE-travelled)
 var query := PhysicsShapeQueryParameters2D.new()
 var box := RectangleShape2D.new()
 box.size = SIZE
 query.shape = box
 query.transform = Transform2D(0,global_position)
 query.motion = step
 query.collision_mask = 2|4
 var space := get_world_2d().direct_space_state
 var wall := INF
 if not space.intersect_shape(query,1).is_empty(): wall = 0
 else:
  var sweep := space.cast_motion(query)
  if sweep[0]<1: wall = sweep[0]
 var body := Rect2(previous_player+Vector2(-20,-64),Vector2(40,64)).grow_individual(6,5,6,5)
 var player_hit := Sweep.segment_rect_fraction(global_position,step-(world.player.global_position-previous_player),body)
 previous_player = world.player.global_position
 var block: float = combat.pulse_block_fraction(global_position,step,SIZE)
 var fraction := minf(wall,minf(player_hit,block))
 if fraction<=1:
  global_position += step*fraction
  blocked = block<=wall and block<=player_hit
  if blocked: combat.shots_blocked += 1
  elif player_hit<wall: world.player.hurt()
  hit_age = 0
 else:
  global_position += step
  travelled += step.length()
  if travelled>=RANGE: queue_free()
 queue_redraw()
func _draw() -> void:
 if hit_age<0:
  draw_texture(preload("res://assets/enemies/cosmic/alien_shot.svg"),-SIZE/2)
 else:
  for i in 4:
   var point := Vector2.from_angle(TAU*i/4.0)*(6+hit_age*80)
   draw_rect(Rect2(point-Vector2(2,2),Vector2(4,4)),Color("FFD84D" if blocked else "FF7A00"))
