extends Node2D
signal defeated
const ANIMATIONS = preload("res://assets/enemies/ruiduzinho/spriteframes.tres")
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
 sprite.sprite_frames = ANIMATIONS
 sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
 sprite.scale = Vector2(2,2)
 sprite.offset = Vector2(0,-16)
 sprite.animation_finished.connect(_on_animation_finished)
 add_child(sprite)
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
 elif sprite.animation == &"alert":
  _play(&"patrol")
func _physics_process(dt: float) -> void:
 clock += dt
 impact_clock = maxf(0,impact_clock-dt)
 queue_redraw()
 if not _sync_support(): return
 if not alive or not visible: return
 stunned = maxf(0,stunned-dt)
 if player and absf(player.position.x-position.x)>200:
  alerted = false
 if stunned<=0 and sprite.animation not in [&"hit",&"alert"]:
  _play(&"patrol")
  if player and not alerted and player.state not in ["RESPAWN","DISABLED"]:
   var distance := player.position-position
   if absf(distance.x)<150 and absf(distance.y)<85:
    alerted = true
    _play(&"alert")
 if stunned<=0 and sprite.animation == &"patrol":
  position.x += direction*speed*dt
  if position.x>right: position.x=right;direction=-1
  if position.x<left: position.x=left;direction=1
 if stunned>0:
  position.x = clampf(position.x+recoil*dt,left,right)
  recoil = move_toward(recoil,0,600*dt)
 sprite.modulate = Color("FFD84D") if stunned>0 else Color.WHITE
 sprite.flip_h = direction<0
 if player and player.state not in ["RESPAWN","DISABLED"]:
  var delta := player.position-position
  if absf(delta.x)<40 and delta.y<15 and delta.y > -85:
   if player.state == "DASH": eliminate()
   elif player.velocity.y>80 and player.position.y<position.y-25:
    eliminate()
    player.bounce()
   elif stunned<=0: player.hurt()
func combat_bounds() -> Rect2:
 # Actual visible body rather than its ground pivot: 52 x 56 px silhouette.
 return Rect2(global_position+Vector2(-26,-56),Vector2(52,56))
func receive_pulse(origin: Vector2) -> void:
 if not alive or not visible: return
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
 _play(&"patrol",true)
