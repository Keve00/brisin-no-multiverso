extends Node2D
signal defeated
const ANIMATIONS = preload("res://assets/enemies/ruiduzinho/spriteframes.tres")
var variant := "cristal"
var left := 1740.0
var right := 1940.0
var speed := 65.0
var direction := 1.0
var alive := true
var stunned := 0.0
var recoil := 0.0
var impact_clock := 0.0
var pulse_hits := 0
var player: BrisinhoPlayer
var clock := 0.0
var sprite: AnimatedSprite2D
var alerted := false
var aiming := false
var aim_time := 0.0
var shot_cooldown := 0.0
var aim_direction := Vector2.RIGHT
var shots_fired := 0
var weapon: Sprite2D
var muzzle_flash: Sprite2D
var fire_clock := 0.0
const SHOULDER := Vector2(10,-32)
const MUZZLE_FROM_SHOULDER := Vector2(40,-7)
const SIGHT_RANGE := 360.0
const AIM_DURATION := 0.65
const FOOT_MARGIN := 26.0
var support: AnimatableBody2D
var support_left := 0.0
var support_right := 0.0
var support_top := 0.0
var support_required := false
var defeat_finished := false
func _ready() -> void:
 process_physics_priority = 10
 sprite = AnimatedSprite2D.new()
 sprite.name = "RuiduzinhoSprite"
 sprite.sprite_frames = load("res://assets/enemies/cosmic/"+variant+"/spriteframes.tres")
 sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
 sprite.scale = Vector2.ONE
 sprite.offset = Vector2(0,-48)
 sprite.animation_finished.connect(_on_animation_finished)
 add_child(sprite)
 if variant == "etzinho":
  weapon = Sprite2D.new()
  weapon.texture = preload("res://assets/enemies/cosmic/etzinho/armed_arm.svg")
  weapon.offset = Vector2(-10,-16)
  weapon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
  add_child(weapon)
  muzzle_flash = Sprite2D.new()
  muzzle_flash.texture = preload("res://assets/enemies/cosmic/etzinho/muzzle_flash.svg")
  muzzle_flash.offset = Vector2(-4,0)
  muzzle_flash.scale = Vector2.ONE*0.55
  muzzle_flash.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
  muzzle_flash.hide()
  add_child(muzzle_flash)
  _sync_weapon_pose()
 _bind_support()
 _play(&"patrol")
func _bind_support() -> void:
 # Authoring uses world coordinates. Bind against actual collision shelves,
 # including stepped surfaces, then keep patrol coordinates local to the body.
 var world := get_parent()
 if not world.has_method("add_platform"): return
 support_required = true
 if right < left:
  push_error("Ruídozinho: patrol limits are inverted")
  visible = false
  return
 for body in world.platforms:
  for shape in body._shapes:
   if not shape.shape is RectangleShape2D: continue
   var box: RectangleShape2D = shape.shape
   var top_left: Vector2 = body.position+shape.position-box.size/2
   if absf(top_left.y-position.y)>0.5: continue
   if left<top_left.x+FOOT_MARGIN or right>top_left.x+box.size.x-FOOT_MARGIN: continue
   support = body
   support_left = left-body.position.x
   support_right = right-body.position.x
   support_top = position.y-body.position.y
   position.x = clampf(position.x,left,right)
   return
 push_error("Ruídozinho: patrol has no supporting collision surface at "+str(position))
 visible = false
func _sync_support() -> bool:
 if not support_required: return true
 if not is_instance_valid(support):
  visible = false
  return false
 var present: bool = support.visible and (not support.online_only or support.online)
 if not present:
  visible = false
  return false
 var local_x := position.x-left
 left = support.position.x+support_left
 right = support.position.x+support_right
 position = Vector2(clampf(left+local_x,left,right),support.position.y+support_top)
 visible = not defeat_finished
 return true
func _process(_dt: float) -> void:
 # AnimatableBody2D commits its synchronized transform after the physics tick.
 # Refresh the visual pivot before drawing, as well as before contact logic.
 _sync_support()
func _play(animation: StringName, restart: bool = false) -> void:
 if restart: sprite.stop()
 if sprite.animation != animation or not sprite.is_playing():
  sprite.play(animation)
func _on_animation_finished() -> void:
 if not alive:
  if sprite.animation == &"hit": _play(&"defeated")
  elif sprite.animation == &"defeated":
   defeat_finished = true
   visible = false
 elif sprite.animation == &"hit":
  _play(&"idle" if stunned>0 else &"patrol")
 elif sprite.animation in [&"alert",&"shoot"]:
  _play(&"aim" if aiming else &"patrol")
func _physics_process(dt: float) -> void:
 clock += dt
 impact_clock = maxf(0,impact_clock-dt)
 fire_clock = maxf(0,fire_clock-dt)
 queue_redraw()
 if not _sync_support():
  aiming = false
  aim_time = 0
  fire_clock = 0
  if muzzle_flash: muzzle_flash.hide()
  return
 if not alive or not visible: return
 stunned = maxf(0,stunned-dt)
 shot_cooldown = maxf(0,shot_cooldown-dt)
 _update_attack(dt)
 if player and absf(player.position.x-position.x)>200:
  alerted = false
 if stunned<=0 and not aiming and sprite.animation not in [&"hit",&"alert",&"shoot"]:
  _play(&"patrol")
  if player and not alerted and player.state not in ["RESPAWN","DISABLED"]:
   var distance := player.position-position
   if absf(distance.x)<150 and absf(distance.y)<85:
    alerted = true
    _play(&"alert")
 if stunned<=0 and not aiming and sprite.animation == &"patrol":
  position.x += direction*speed*dt
  if position.x>right: position.x=right;direction=-1
  if position.x<left: position.x=left;direction=1
 if stunned>0:
  position.x = clampf(position.x+recoil*dt,left,right)
  recoil = move_toward(recoil,0,600*dt)
 sprite.modulate = Color.WHITE
 sprite.flip_h = direction<0
 _sync_weapon_pose()
 if player and player.state not in ["RESPAWN","DISABLED"]:
  var delta := player.position-position
  if absf(delta.x)<40 and delta.y<15 and delta.y > -85:
   if player.state == "DASH": eliminate()
   elif player.velocity.y>80 and player.position.y<position.y-25:
    eliminate()
    player.bounce()
   elif stunned<=0: player.hurt()
func combat_bounds() -> Rect2:
 # The larger alien's torso/head remain hittable by chips and pulse.
 if variant == "etzinho": return Rect2(global_position+Vector2(-30,-86),Vector2(60,86))
 return Rect2(global_position+Vector2(-26,-56),Vector2(52,56))
func receive_pulse(origin: Vector2) -> void:
 if not alive or not visible: return
 aiming = false
 aim_time = 0
 fire_clock = 0
 if muzzle_flash: muzzle_flash.hide()
 if weapon: weapon.hide()
 shot_cooldown = 1.0
 stunned = 2.0
 pulse_hits += 1
 impact_clock = 0.22
 recoil = 160.0 * (-1.0 if origin.x>global_position.x else 1.0)
 _play(&"hit",true)
 Audio.play("hit")
func pulse(origin: Vector2) -> void:
 # Compatibility helper for direct scripted hits; wave owns gameplay timing.
 var body := combat_bounds()
 var nearest := Vector2(clampf(origin.x,body.position.x,body.end.x),clampf(origin.y,body.position.y,body.end.y))
 if origin.distance_to(nearest)<=140.0: receive_pulse(origin)
func _draw() -> void:
 if aiming and alive:
  draw_rect(Rect2(-3,-114,6,15),Color("FFD84D"))
  draw_rect(Rect2(-3,-96,6,6),Color("FF7A00"))
 if stunned<=0 or not alive: return
 # Stable saturated stun indicators; orbit replaces flash/blink animation.
 for i in (2 if WorldState.reduced_flash else 3):
  var angle := clock*2.4+TAU*float(i)/3.0
  var point := Vector2(cos(angle)*25,-72+sin(angle)*6)
  draw_rect(Rect2(point-Vector2(4,4),Vector2(8,8)),Color("FF7A00"))
  draw_rect(Rect2(point-Vector2(2,2),Vector2(4,4)),Color("FFFFFF"))
 if impact_clock>0:
  draw_line(Vector2(-30,-50),Vector2(-42,-60),Color("FFD84D"),4)
  draw_line(Vector2(30,-50),Vector2(42,-60),Color("FFD84D"),4)
func eliminate() -> void:
 if not alive: return
 alive = false
 aiming = false
 fire_clock = 0
 if muzzle_flash: muzzle_flash.hide()
 if weapon: weapon.hide()
 defeat_finished = false
 stunned = 0
 _play(&"hit",true)
 Audio.play("hit")
 defeated.emit()
func reset() -> void:
 alive = true
 defeat_finished = false
 visible = true
 _sync_support()
 position.x = clampf(left+30,left,right)
 stunned = 0
 recoil = 0
 impact_clock = 0
 sprite.modulate = Color.WHITE
 direction = 1
 alerted = false
 aiming = false
 aim_time = 0
 shot_cooldown = 0.5
 fire_clock = 0
 if muzzle_flash: muzzle_flash.hide()
 if weapon: weapon.show()
 _play(&"patrol",true)
 _sync_weapon_pose()

func can_see_player() -> bool:
 if variant != "etzinho" or not player or not alive or not visible: return false
 if player.state in ["RESPAWN","DISABLED"]: return false
 var target := player.global_position+Vector2(0,-35)
 var origin := global_position+Vector2(0,-32)
 if absf(target.x-origin.x)>SIGHT_RANGE or absf(target.y-origin.y)>160: return false
 var query := PhysicsRayQueryParameters2D.create(origin,target,2|4)
 return get_world_2d().direct_space_state.intersect_ray(query).is_empty()

func _update_attack(dt: float) -> void:
 if not weapon: return
 if stunned>0 or not can_see_player():
  aiming = false
  aim_time = 0
 elif not aiming and shot_cooldown<=0 and sprite.animation != &"shoot":
  aiming = true
  aim_time = AIM_DURATION
  direction = 1.0 if player.global_position.x>=global_position.x else -1.0
  aim_direction = (player.global_position+Vector2(0,-35)-(global_position+SHOULDER*Vector2(direction,1))).normalized()
  _play(&"alert",true)
 elif aiming:
  # Track Brisin throughout the tell; barrel and projectile share one heading.
  direction = 1.0 if player.global_position.x>=global_position.x else -1.0
  aim_direction = (player.global_position+Vector2(0,-35)-(global_position+SHOULDER*Vector2(direction,1))).normalized()
  aim_time -= dt
  if aim_time<=0:
   _sync_weapon_pose()
   var combat = get_parent().get("combat")
   if combat and combat.has_method("launch_enemy_shot"):
    combat.launch_enemy_shot(_muzzle_position(),aim_direction,get_instance_id())
    shots_fired += 1
    fire_clock = 0.25
   aiming = false
   shot_cooldown = 1.6
   _play(&"shoot",true)
 if aiming and sprite.animation != &"alert": _play(&"aim")

func _muzzle_position() -> Vector2:
 return weapon.to_global(MUZZLE_FROM_SHOULDER)

func _sync_weapon_pose() -> void:
 if not weapon: return
 weapon.visible = alive and visible and sprite.animation not in [&"hit",&"defeated"]
 var joint := SHOULDER
 var phase := TAU*float(sprite.frame)/float(maxi(1,sprite.sprite_frames.get_frame_count(sprite.animation)))
 var upper := smoothstep(0.0,1.0,0.32)
 var recoil_angle := 0.0
 if sprite.animation in [&"idle",&"aim"]:
  var breathe := sin(phase)*0.025
  joint = Vector2((10+sin(phase)*upper*1.5)*(1+breathe),-32*(1+breathe))
 elif sprite.animation == &"patrol":
  joint += Vector2(sin(phase)*upper*2.5,-absf(sin(phase))*upper*2)
 elif sprite.animation == &"alert":
  var lean := [0.0,-2.0,-4.0,-3.0,-1.0,0.0]
  var stretch := [1.0,1.02,1.06,1.05,1.02,1.0]
  joint = Vector2(10+lean[sprite.frame]*upper,-32*stretch[sprite.frame])
 elif sprite.animation == &"shoot":
  var angles := [0.0,-9.0,5.0,-3.0,1.0]
  recoil_angle = -deg_to_rad(angles[mini(sprite.frame,4)])
  joint = joint.rotated(recoil_angle)
 weapon.scale = Vector2(direction,1)
 var heading := aim_direction.angle()-(PI if direction<0 else 0.0)
 weapon.rotation = heading+recoil_angle*direction if aiming or fire_clock>0 else sin(phase)*0.035
 weapon.position = joint*Vector2(direction,1)
 if fire_clock>0: weapon.position -= aim_direction*2.0*sin((0.25-fire_clock)/0.25*PI)
 muzzle_flash.visible = weapon.visible and fire_clock>0.17 and not WorldState.reduced_flash
 if muzzle_flash.visible:
  muzzle_flash.global_position = _muzzle_position()
  muzzle_flash.rotation = aim_direction.angle()
