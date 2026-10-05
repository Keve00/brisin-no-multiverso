extends Node2D
# SVGs use a 4 px grid. Effects never create collision or change combat range.
# The detached canvas stores world-space positions: a pulse stays at its origin.
const PULSE_DURATION := 0.55
const PULSE_RADIUS := 140.0
const ECHO_DURATION := 0.14

static func pulse_expansion(age: float) -> float:
 return lerpf(0.15,1.0,clampf(age/(PULSE_DURATION*0.65),0.0,1.0))
var player: CharacterBody2D
var dash_texture: Texture2D
var echo_texture: Texture2D
var ring_texture: Texture2D
var spark_texture: Texture2D
var pulse_age := PULSE_DURATION
var pulse_origin := Vector2.ZERO
var dash_age := 1.0
var dash_duration := 0.19
var dash_origin := Vector2.ZERO
var dash_direction := 1.0
var echoes: Array[Dictionary] = []
var echo_clock := 0.0

func _ready() -> void:
 top_level = true
 global_position = Vector2.ZERO
 texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
 # Behind the sprite, above the surfaces: the wake cannot cover Brisin's face.
 z_index = -1
 dash_texture = load("res://assets/player/effects/dash_stream.svg")
 echo_texture = load("res://assets/player/effects/dash_echo.svg")
 ring_texture = load("res://assets/player/effects/pulse_ring.svg")
 spark_texture = load("res://assets/player/effects/pulse_spark.svg")

func start_dash(origin: Vector2, direction: float, duration: float) -> void:
 dash_origin = origin
 dash_direction = direction
 dash_duration = duration
 dash_age = 0.0
 echo_clock = 0.0

func start_pulse(origin: Vector2) -> void:
 pulse_origin = origin
 pulse_age = 0.0

func _process(dt: float) -> void:
 if is_instance_valid(player) and player.state in ["RESPAWN","DISABLED"]:
  pulse_age = PULSE_DURATION
  dash_age = dash_duration
  echoes.clear()
  queue_redraw()
  return
 pulse_age = minf(PULSE_DURATION,pulse_age+dt)
 dash_age += dt
 if is_instance_valid(player) and dash_age < dash_duration:
  if player.state != "DASH":
   dash_age = dash_duration
  else:
   dash_origin = player.global_position+Vector2(0,-35)
   dash_direction = player.facing
   echo_clock -= dt
   if echo_clock <= 0:
    echoes.append({"position":dash_origin,"age":0.0,"direction":dash_direction})
    echo_clock = 0.070 if WorldState.reduced_flash else 0.035
 for echo in echoes: echo.age += dt
 echoes = echoes.filter(func(echo: Dictionary) -> bool: return echo.age < ECHO_DURATION)
 queue_redraw()

func _draw() -> void:
 if ring_texture == null: return
 var spark_count := 4 if WorldState.reduced_flash else 8
 for echo in echoes:
  # Solid sparks shrink and despawn; accessibility changes density, not color.
  var size: float = lerpf(0.7,0.25,float(echo.age)/ECHO_DURATION)
  draw_set_transform(echo.position,0,Vector2(float(echo.direction),1)*size)
  draw_texture(echo_texture,Vector2(-32,-32),Color.WHITE)
 if dash_age < dash_duration:
  # Full-opacity body persists only during the real dash.
  draw_set_transform(dash_origin,0,Vector2(dash_direction,1))
  draw_texture(dash_texture,Vector2(-160,-48),Color.WHITE)
  draw_texture(spark_texture,Vector2(14,-10),Color.WHITE)
 if pulse_age < PULSE_DURATION:
  var expansion := pulse_expansion(pulse_age)
  draw_set_transform(pulse_origin,0,Vector2.ONE*expansion)
  draw_texture(ring_texture,Vector2(-140,-140),Color.WHITE)
  # Sparks travel with the wave inside its rim, preserving the 140 px envelope.
  for i in spark_count:
   var direction := Vector2.from_angle(TAU*float(i)/float(spark_count))
   var spark_position := pulse_origin+direction*(PULSE_RADIUS*expansion-10.0)
   draw_set_transform(spark_position,0,Vector2.ONE)
   draw_texture(spark_texture,Vector2(-10,-10),Color.WHITE)
 draw_set_transform(Vector2.ZERO)
