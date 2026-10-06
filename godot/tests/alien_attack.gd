extends Node2D
const Combat = preload("res://scripts/player/combat_svg.gd")
const Enemy = preload("res://scripts/enemies/noisezinho.gd")
const Shot = preload("res://scripts/enemies/alien_projectile.gd")
var checks := 0
var failures := 0
class Fixture extends Node2D:
 var player: BrisinhoPlayer
 var enemies: Array[Node2D] = []
 var combat: Node2D
func check(ok: bool, message: String) -> void:
 checks += 1
 if not ok: failures += 1; push_error(message)
 else: print("PASS: ",message)
func _ready() -> void: call_deferred("run")
func run() -> void:
 var fixture := Fixture.new()
 add_child(fixture)
 fixture.player = load("res://scenes/player/player.tscn").instantiate()
 fixture.player.position = Vector2(0,300)
 fixture.add_child(fixture.player)
 fixture.player.set_physics_process(false)
 fixture.combat = Node2D.new()
 fixture.combat.set_script(Combat)
 fixture.combat.world = fixture
 fixture.add_child(fixture.combat)
 fixture.combat.set_physics_process(false)
 var enemy := Node2D.new()
 enemy.set_script(Enemy)
 enemy.variant = "etzinho"
 enemy.position = Vector2(300,300)
 enemy.left = 250
 enemy.right = 350
 enemy.player = fixture.player
 fixture.add_child(enemy)
 fixture.enemies.append(enemy)
 enemy.set_physics_process(false)
 check(enemy.sprite.sprite_frames.has_animation("aim") and enemy.sprite.sprite_frames.has_animation("shoot"),"armed SVG has aim and finite fire states")
 check(enemy.weapon.texture.resource_path.ends_with("etzinho/armed_arm.svg"),"approved hand and weapon use one articulated SVG layer")
 check(enemy.sprite.sprite_frames.get_frame_count("shoot")==5 and not enemy.sprite.sprite_frames.get_animation_loop("shoot"),"recoil completes once in 250ms")
 check(enemy.can_see_player(),"Etzinho sees active Brisin within 360px")
 enemy._physics_process(0.01)
 check(enemy.aiming and fixture.combat.get_child_count()==0 and enemy.direction<0,"faces Brisin and telegraphs before firing")
 enemy._physics_process(0.3)
 check(fixture.combat.get_child_count()==0,"no immediate shot during aim")
 enemy._physics_process(0.36)
 check(fixture.combat.get_child_count()==1 and enemy.shot_cooldown>1,"fires after telegraph, then cooldown")
 var shot = fixture.combat.get_child(0)
 shot.set_physics_process(false)
 check(enemy.sprite.animation==&"shoot" and enemy.fire_clock>0,"fire synchronizes SVG recoil with projectile")
 check(shot.global_position.distance_to(enemy._muzzle_position())<3.0,"projectile begins at the animated barrel")
 check(shot.velocity.x<0 and absf(shot.velocity.length()-270)<0.01,"shot travels at dodgeable fixed velocity")
 fixture.combat.clear()
 await get_tree().process_frame
 enemy.shot_cooldown=0
 enemy._physics_process(0.01)
 enemy.receive_pulse(fixture.player.global_position)
 check(enemy.fire_clock==0 and not enemy.muzzle_flash.visible and not enemy.weapon.visible,"pulse cancels recoil/flash and switches to complete damage pose")
 enemy._physics_process(0.7)
 check(not enemy.aiming and fixture.combat.get_child_count()==0,"pulse stun cancels aimed attack")
 enemy.stunned=0
 enemy.shot_cooldown=0
 fixture.player.position.x=800
 check(not enemy.can_see_player(),"out-of-range player is not targeted")
 fixture.player.position.x=0
 var wall := StaticBody2D.new()
 wall.collision_layer=2
 var collision := CollisionShape2D.new()
 var rectangle := RectangleShape2D.new()
 rectangle.size=Vector2(20,150)
 collision.shape=rectangle
 wall.position=Vector2(150,240)
 wall.add_child(collision)
 fixture.add_child(wall)
 await get_tree().physics_frame
 await get_tree().physics_frame
 check(not enemy.can_see_player(),"wall blocks sight")
 fixture.combat.launch_enemy_shot(Vector2(220,265),Vector2.LEFT,enemy.get_instance_id())
 shot=fixture.combat.get_child(0)
 shot.set_physics_process(false)
 shot._physics_process(0.5)
 check(shot.hit_age==0 and fixture.player.state!="RESPAWN","wall intercepts shot before Brisin")
 wall.queue_free()
 fixture.combat.clear()
 await get_tree().physics_frame
 await get_tree().physics_frame
 fixture.combat.start_pulse(Vector2(0,265))
 fixture.combat._physics_process(0.3)
 fixture.combat.launch_enemy_shot(Vector2(170,265),Vector2.LEFT,99)
 shot=fixture.combat.get_child(0)
 shot.set_physics_process(false)
 shot._physics_process(0.3)
 check(shot.blocked and fixture.combat.shots_blocked==1 and fixture.player.state!="RESPAWN","visible pulse ring neutralizes incoming shot")
 fixture.combat.clear()
 await get_tree().process_frame
 fixture.player.invincible=false
 fixture.player.invulnerability=0
 fixture.combat.launch_enemy_shot(Vector2(80,265),Vector2.LEFT,99)
 shot=fixture.combat.get_child(0)
 shot.set_physics_process(false)
 shot._physics_process(0.3)
 check(fixture.player.state=="RESPAWN","unprotected Brisin receives damage")
 fixture.combat._physics_process(0.01)
 await get_tree().process_frame
 check(fixture.combat.get_child_count()==0 and fixture.combat.waves.is_empty(),"respawn removes all hostile shots")
 fixture.player.change_state("IDLE")
 fixture.player.position.x=600
 enemy.reset()
 enemy.shot_cooldown=0
 enemy._physics_process(0.01)
 check(enemy.aiming and enemy.direction>0,"mirrored aim works to the right")
 var before: float=enemy.aim_time
 get_tree().paused=true
 await get_tree().process_frame
 check(enemy.aim_time==before,"pause freezes the telegraph")
 get_tree().paused=false
 enemy.variant="cristal"
 check(not enemy.can_see_player(),"other aliens retain existing patrol behavior")
 fixture.combat.launch_enemy_shot(Vector2(500,0),Vector2.RIGHT,99)
 shot=fixture.combat.get_child(0)
 shot.set_physics_process(false)
 shot._physics_process(2)
 await get_tree().process_frame
 check(fixture.combat.get_child_count()==0,"shot expires at bounded range")
 if DisplayServer.get_name() != "headless":
  enemy.variant="etzinho"
  enemy.position=Vector2(620,430)
  fixture.player.position=Vector2(880,430)
  enemy.left=600;enemy.right=680
  enemy.aiming=false;enemy.shot_cooldown=0
  enemy._physics_process(0.01)
  var background := Polygon2D.new()
  background.polygon=PackedVector2Array([Vector2(0,0),Vector2(1152,0),Vector2(1152,648),Vector2(0,648)])
  background.color=Color("3b284b")
  background.z_index=-20
  add_child(background)
  fixture.player.camera.enabled=false
  for i in 4: await get_tree().process_frame
  await RenderingServer.frame_post_draw
  get_viewport().get_texture().get_image().save_png("res://docs/cosmic_qa/alien_attack.png")
 fixture.queue_free()
 await get_tree().process_frame
 print("ALIEN_ATTACK: %d checks / %d failures" % [checks,failures])
 get_tree().quit(0 if failures==0 else 1)
