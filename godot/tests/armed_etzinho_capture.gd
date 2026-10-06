extends Node2D
const Enemy = preload("res://scripts/enemies/noisezinho.gd")
func _ready() -> void: call_deferred("run")
func run() -> void:
 var background := Polygon2D.new()
 background.polygon = PackedVector2Array([Vector2.ZERO,Vector2(1152,0),Vector2(1152,648),Vector2(0,648)])
 background.color = Color("3b284b")
 background.z_index = -20
 add_child(background)
 var enemies: Array[Node2D] = []
 for i in 2:
  var enemy := Node2D.new()
  enemy.set_script(Enemy)
  enemy.variant = "etzinho"
  enemy.position = Vector2(300+i*540,490)
  enemy.scale = Vector2.ONE*3
  add_child(enemy)
  enemy.set_physics_process(false)
  enemy.direction = 1 if i==0 else -1
  enemies.append(enemy)
 for state in [&"idle",&"patrol",&"alert",&"aim",&"shoot",&"hit",&"defeated"]:
  for frame in [0,2,4]:
   for enemy in enemies:
    enemy.sprite.animation = state
    enemy.sprite.stop()
    enemy.sprite.frame = mini(frame,enemy.sprite.sprite_frames.get_frame_count(state)-1)
    enemy.sprite.flip_h = enemy.direction<0
    enemy.aiming = state in [&"alert",&"aim"]
    enemy.fire_clock = 0.24 if state==&"shoot" and frame==0 else (0.1 if state==&"shoot" else 0.0)
    enemy.aim_direction = Vector2(enemy.direction,-0.3).normalized()
    enemy._sync_weapon_pose()
   for i in 3: await get_tree().process_frame
   await RenderingServer.frame_post_draw
   get_viewport().get_texture().get_image().save_png("res://docs/cosmic_qa/armed_"+str(state)+"_"+str(frame)+".png")
 get_tree().quit()
