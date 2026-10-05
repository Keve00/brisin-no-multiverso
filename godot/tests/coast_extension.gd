extends Node
var failures:=0
var checks:=0
var world:Node2D
func check(ok:bool,message:String)->void:
 checks+=1
 if ok:print("PASS: ",message)
 else:failures+=1;push_error(message)
func frames(count:int)->void:
 for i in count:await get_tree().physics_frame
func reset_at(pos:Vector2)->void:
 var p=world.player
 for action in ["move_left","move_right","jump","dash","chip"]:Input.action_release(action)
 p.position=pos;p.velocity=Vector2.ZERO;p.change_state("IDLE")
func _ready()->void:call_deferred("run")
func run()->void:
 WorldState.reset_progress()
 WorldState.connection=WorldState.Connection.ONLINE
 world=load("res://scenes/world_01/world_01.tscn").instantiate();add_child(world)
 world.player.invincible=true
 for enemy in world.enemies:enemy.eliminate()
 check(world.level.length==15235 and world.player.camera.limit_right==15235,"length and camera cover the extension")
 check(world.level.fragments.size()==49 and world.enemies.size()==22,"49 gems and 22 adversaries instantiated")
 var cracked:Node2D
 var raft:Node2D
 for body in world.platforms:
  if body.home.x==9660:cracked=body
  if body.home.x==10160:raft=body
 reset_at(Vector2(9510,277));await frames(4)
 Input.action_press("move_right");await frames(8);Input.action_press("jump")
 var landed_cracked:=false
 for i in 65:
  await frames(1)
  for contact in world.player.get_slide_collision_count():
   if world.player.get_slide_collision(contact).get_collider()==cracked and world.player.is_on_floor():landed_cracked=true
  if world.player.position.x>9750:Input.action_release("move_right")
 Input.action_release("jump");Input.action_release("move_right")
 check(landed_cracked,"optional cracked platform is reached by normal jump inputs")
 reset_at(Vector2(10340,247));await frames(4)
 raft.clock=PI/(2*.8)
 await frames(1)
 Input.action_press("jump")
 var landed_raft:=false
 var raft_start:Vector2=raft.position
 for i in 65:
  await frames(1)
  for contact in world.player.get_slide_collision_count():
   if world.player.get_slide_collision(contact).get_collider()==raft and world.player.is_on_floor():landed_raft=true
 Input.action_release("jump")
 check(landed_raft and raft.position!=raft_start,"moving raft can be boarded while its real motion runs")
 # New optional route: actual jumps and real moving-raft simulation.
 for spec in [[11100,Vector2(10950,277),true],[11610,Vector2(11790,247),false],[12110,Vector2(11950,247),true]]:
  var target:Node2D
  for body in world.platforms:
   if body.home.x==spec[0]:target=body
  reset_at(spec[1]);await frames(4)
  if target.moving:
   target.clock=PI/(2*.8);await frames(1)
  if spec[2]:Input.action_press("move_right");await frames(8)
  Input.action_press("jump")
  var boarded:=false
  for i in 65:
   await frames(1)
   for contact in world.player.get_slide_collision_count():
    if world.player.get_slide_collision(contact).get_collider()==target and world.player.is_on_floor():boarded=true
   if spec[2] and world.player.position.x>target.position.x+90:Input.action_release("move_right")
  Input.action_release("jump");Input.action_release("move_right")
  check(boarded,"new optional platform accessible via inputs at "+str(spec[0]))
 world.on_marker("checkpoint","brisa_02")
 check(WorldState.checkpoint==Vector2(9340,277) and WorldState.checkpoint_id=="brisa_02","new checkpoint saves its own location")
 var saved:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(WorldState.SAVE_PATH))
 check(world.point(saved.checkpoint)==Vector2(9340,277) and saved.online,"checkpoint preserves Online progress")
 check(world.sea_svg.coverage_rect(world.level.length).end.x==15235,"sea covers the entire new area without stretching")
 print("COAST_EXTENSION: %d checks / %d failures"%[checks,failures])
 get_tree().quit(0 if failures==0 else 1)
