class_name BrisinhoPlayer
extends CharacterBody2D
signal pulsed(origin: Vector2)
signal chip_launched(origin: Vector2, direction: float)
signal respawned
signal state_changed(next_state: String)
@export var tuning: PlayerTuning = preload("res://data/player_tuning.tres")
var state := "IDLE"
var facing := 1.0
var coyote := 0.0
var buffer := 0.0
var dash_time := 0.0
var cooldown := 0.0
var dash_available := true
var wind := Vector2.ZERO
var pulse_time := 0.0
var chip_cooldown := 0.0
const CHIP_GESTURE_DURATION := 0.30
const CHIP_BODY = preload("res://assets/player/chip_gesture_svg/body_frames.tres")
const CHIP_HANDS = [preload("res://assets/player/chip_gesture_svg/hand_00.svg"),preload("res://assets/player/chip_gesture_svg/hand_01.svg"),preload("res://assets/player/chip_gesture_svg/hand_02.svg"),preload("res://assets/player/chip_gesture_svg/hand_03.svg"),preload("res://assets/player/chip_gesture_svg/hand_04.svg"),preload("res://assets/player/chip_gesture_svg/hand_05.svg")]
var chip_gesture_time := 0.0
var chip_gesture_facing := 1.0
var locomotion_frames: SpriteFrames
var chip_hand: Sprite2D
var invulnerability := 0.0
var invincible := false
var rail_start := Vector2.ZERO
var rail_end := Vector2.ZERO
var rail_progress := 0.0
var rail_lock := 0.0
var respawn_time := 0.0
var land_time := 0.0
var was_floor := false
const ActionEffectsSVG = preload("res://scripts/player/action_effects_svg.gd")
var action_effects: Node2D
var visual: AnimatedSprite2D
var camera: Camera2D
var art := false
func _ready() -> void:
 collision_layer = 1
 collision_mask = 2 | 4
 var shape := CollisionShape2D.new()
 var box := RectangleShape2D.new()
 box.size = Vector2(32,68)
 shape.shape = box
 shape.position.y = -34
 add_child(shape)
 visual = AnimatedSprite2D.new()
 visual.position.y = -56
 # Native SVG frames keep the atlas canvas/feet and the existing 12fps timing.
 visual.sprite_frames = preload("res://assets/player/locomotion_svg/spriteframes.tres")
 visual.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
 # A first-reading pause may occur before the first locomotion tick.
 if visual.sprite_frames.has_animation("walk"): visual.animation="walk"
 add_child(visual)
 locomotion_frames = visual.sprite_frames
 chip_hand = Sprite2D.new()
 chip_hand.name = "ChipThrowHandSVG"
 chip_hand.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
 chip_hand.visible = false
 visual.add_child(chip_hand)
 action_effects = Node2D.new()
 action_effects.set_script(ActionEffectsSVG)
 action_effects.player = self
 add_child(action_effects)
 camera = Camera2D.new()
 camera.position = Vector2(100,-120)
 camera.position_smoothing_enabled = true
 camera.position_smoothing_speed = 7.0
 camera.limit_left = 0
 camera.limit_top = -80
 camera.limit_bottom = 920
 camera.limit_right = 6400
 add_child(camera)
 set_art(not WorldState.blockout)
func set_art(enabled: bool) -> void:
 art = enabled
 visual.visible = enabled
func change_state(next: String) -> void:
 if state != next:
  if next == "DISABLED": GameCommands.clear()
  state = next
  state_changed.emit(next)
func begin_rail(start: Vector2, finish: Vector2) -> void:
 if rail_lock > 0 or state in ["RAIL","RESPAWN","DISABLED"]: return
 rail_start = start
 rail_end = finish
 rail_progress = 0
 position = start
 velocity = Vector2.ZERO
 change_state("RAIL")
 Audio.play("rail")
func jump() -> void:
 velocity.y = tuning.jump_velocity
 coyote = 0
 buffer = 0
 change_state("JUMP_UP")
 Audio.play("jump")
func die() -> void:
 if state in ["RESPAWN","DISABLED"]: return
 GameCommands.clear()
 change_state("RESPAWN")
 respawn_time = 0.28
 velocity = Vector2.ZERO
 Audio.play("hit")
func launch_chip() -> bool:
 if state in ["RESPAWN","DISABLED"] or get_tree().paused or chip_cooldown>0: return false
 chip_cooldown = 0.35
 chip_gesture_time = CHIP_GESTURE_DURATION
 chip_gesture_facing = facing
 chip_launched.emit(global_position+Vector2(facing*24,-35),facing)
 Audio.play("pulse")
 return true
func hurt() -> void:
 if state in ["RESPAWN","DISABLED"]: return
 if invulnerability > 0 or invincible: return
 die()
func bounce() -> void:
 if state in ["RESPAWN","DISABLED"]: return
 velocity.y = -370
 dash_available = true
 change_state("JUMP_UP")
func _physics_process(dt: float) -> void:
 pulse_time = maxf(0,pulse_time-dt)
 chip_cooldown = maxf(0,chip_cooldown-dt)
 chip_gesture_time = 0.0 if state in ["RESPAWN","DISABLED"] else maxf(0,chip_gesture_time-dt)
 cooldown = maxf(0,cooldown-dt)
 rail_lock = maxf(0,rail_lock-dt)
 invulnerability = maxf(0,invulnerability-dt)
 land_time = maxf(0,land_time-dt)
 if state == "DISABLED":
  animate(dt)
  return
 if state == "RESPAWN":
  respawn_time -= dt
  if respawn_time <= 0:
   global_position = WorldState.checkpoint
   velocity = Vector2.ZERO
   dash_available = true
   dash_time = 0
   chip_cooldown = 0
   pulse_time = 0
   rail_lock = 0.5
   invulnerability = 1.2
   change_state("IDLE")
   camera.reset_smoothing()
   respawned.emit()
  animate(dt)
  return
 var attack_axis := GameCommands.axis()
 if attack_axis != 0: facing = signf(attack_axis)
 if GameCommands.just_pressed("chip"):
  launch_chip()
 if GameCommands.just_pressed("pulse") and pulse_time <= 0:
  pulse_time = 0.55
  action_effects.start_pulse(global_position+Vector2(0,-35))
  pulsed.emit(global_position+Vector2(0,-35))
  Audio.play("pulse")
 if state == "RAIL":
  if GameCommands.just_pressed("jump"):
   rail_lock = 0.4
   velocity.x = tuning.speed
   jump()
  else:
   rail_progress += tuning.rail_speed*dt/rail_start.distance_to(rail_end)
   position = rail_start.lerp(rail_end,minf(1,rail_progress))
   if rail_progress >= 1:
    rail_lock = 0.5
    velocity = Vector2(300,-150)
    dash_available = true
    change_state("FALL")
   animate(dt)
   return
 var axis := GameCommands.axis()
 if axis != 0: facing = signf(axis)
 if GameCommands.just_pressed("jump"): buffer = (tuning.mobile_jump_buffer if WorldState.mobile_enabled and WorldState.mobile_assist else tuning.jump_buffer)
 else: buffer = maxf(0,buffer-dt)
 if is_on_floor():
  coyote = (tuning.mobile_coyote_time if WorldState.mobile_enabled and WorldState.mobile_assist else tuning.coyote_time)
  dash_available = true
 else: coyote = maxf(0,coyote-dt)
 if GameCommands.just_pressed("dash") and dash_available and cooldown <= 0:
  dash_available = false
  dash_time = tuning.dash_duration
  cooldown = tuning.dash_cooldown
  velocity = Vector2(facing*tuning.dash_speed,0)
  change_state("DASH")
  action_effects.start_dash(global_position+Vector2(0,-35),facing,tuning.dash_duration)
  Audio.play("dash")
 if dash_time > 0:
  dash_time -= dt
  velocity = Vector2(facing*tuning.dash_speed,0)
  if is_on_wall(): dash_time = 0
 else:
  velocity.x = move_toward(velocity.x,axis*tuning.speed,(tuning.acceleration if axis else tuning.deceleration)*dt)
  velocity.y += tuning.gravity*(tuning.fall_multiplier if velocity.y > 0 else 1.0)*dt
  velocity += wind*dt
  velocity.y = maxf(velocity.y,-560)
  if buffer > 0 and coyote > 0: jump()
  if GameCommands.just_released("jump") and velocity.y < -170 and not (GameCommands.last_touch_jump and WorldState.mobile_enabled and not WorldState.variable_jump): velocity.y *= 0.48
 move_and_slide()
 if not was_floor and is_on_floor():
  land_time = 0.10
  Audio.play("land")
 was_floor = is_on_floor()
 if dash_time <= 0:
  if not is_on_floor(): change_state("JUMP_UP" if velocity.y < 0 else "FALL")
  elif land_time > 0: change_state("LAND")
  elif absf(velocity.x)>15: change_state("RUN")
  else: change_state("IDLE")
 if global_position.y > 900: die()
 animate(dt)
func animate(_dt: float) -> void:
 # Preserve the current locomotion phase when swapping to modular throw SVGs.
 var throwing := art and chip_gesture_time>0 and state not in ["RESPAWN","DISABLED"]
 var frames_to_use: SpriteFrames = CHIP_BODY if throwing else locomotion_frames
 if visual.sprite_frames != frames_to_use:
  var old_animation := visual.animation
  var old_frame := visual.frame
  var old_progress := visual.frame_progress
  visual.sprite_frames = frames_to_use
  if frames_to_use.has_animation(old_animation):
   visual.animation = old_animation
   visual.set_frame_and_progress(old_frame,old_progress)
  else:
   visual.animation = "walk"
   visual.set_frame_and_progress(0,0.0)
 chip_hand.visible = throwing
 if throwing:
  var phase := mini(5,int((CHIP_GESTURE_DURATION-chip_gesture_time)/CHIP_GESTURE_DURATION*6.0))
  chip_hand.texture = CHIP_HANDS[phase]
 var visual_facing := chip_gesture_facing if throwing else facing
 chip_hand.flip_h = visual_facing < 0
 visual.flip_h = visual_facing < 0
 visual.modulate = Color("fff3cd") if state == "DASH" else (Color(1,0.84,0.62) if state == "RAIL" else Color.WHITE)
 # Reduced flashes keeps the damage cue steady instead of rapidly blinking.
 visual.modulate.a = (0.65 if WorldState.reduced_flash else (0.4 if int(invulnerability*12)%2 else 1.0)) if invulnerability > 0 else 1.0
 visual.scale = Vector2(1.06,0.94) if state == "LAND" else Vector2.ONE
 if art and visual.sprite_frames.has_animation("run"):
  if state == "RUN": visual.play("run")
  elif state in ["JUMP_UP","FALL"]:
   visual.play("jump")
   visual.frame = 3 if state == "JUMP_UP" else 10
   visual.pause()
  elif state in ["DASH","RAIL"]: visual.play("run")
  else:
   visual.play("walk")
   visual.frame = 0
   visual.pause()
 camera.position.x = lerpf(camera.position.x,facing*95,0.035)
 camera.position.y = lerpf(camera.position.y,-120+clampf(velocity.y*0.1,-45,45),0.05)
 queue_redraw()
func _draw() -> void:
 if not art:
  draw_style_box(make_box(),Rect2(-16,-68,32,68))
  draw_circle(Vector2(facing*9,-49),4,Color.WHITE)
 if state == "RESPAWN": draw_circle(Vector2(0,-35),35,Color(1,0.75,0.35,0.2))
func make_box() -> StyleBoxFlat:
 var box := StyleBoxFlat.new()
 box.bg_color = Color("ee8d22")
 box.corner_radius_top_left = 8
 box.corner_radius_top_right = 8
 return box
