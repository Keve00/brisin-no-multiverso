extends Node
var failures:=0
var checks:=0
func check(ok:bool,message:String)->void:
 checks+=1
 if ok:print("PASS: ",message)
 else:failures+=1;push_error(message)
func frames(count:int)->void:
 for i in count:await get_tree().physics_frame
func _ready()->void:call_deferred("run")
func run()->void:
 WorldState.reset_progress()
 WorldState.connection=WorldState.Connection.ONLINE
 var world=load("res://scenes/world_01/world_01.tscn").instantiate();add_child(world)
 for enemy in world.enemies:enemy.eliminate()
 var totems:Array=[]
 for marker in world.markers:
  if marker.kind=="checkpoint" and marker.id!="brisa_01":totems.append(marker)
 check(totems.size()==5,"five additional checkpoint totems are present")
 for marker in totems:
  check(marker.art and marker.ALIEN_CHECKPOINT_OFF.get_size()==Vector2(128,140) and marker.TOTEM_SCALE==1.0,"totem uses native SVG layers with one uniform scale")
  world.player.position=marker.position+Vector2(0,-3)
  world.player.velocity=Vector2.ZERO;world.player.change_state("IDLE")
  await frames(3)
  check(marker.active and WorldState.checkpoint_id==marker.id and WorldState.checkpoint==marker.position+Vector2(0,-3),"physical approach activates only the correct checkpoint: "+marker.id)
  var original_position:Vector2=WorldState.checkpoint
  var saved:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(WorldState.SAVE_PATH))
  check(saved.checkpoint_id==marker.id and world.point(saved.checkpoint)==original_position and saved.online,"save retains ID, position and Online state")
  world.player.position+=Vector2(0,100)
  world.player.die();await frames(20)
  check(world.player.position.distance_to(original_position)<5 and world.player.state!="RESPAWN","death returns to the activated totem")
  for enemy in world.enemies:enemy.eliminate()
  check(not world.scenery_svg.checkpoint_active,"secondary totem does not change primary checkpoint art")
 var last_id:String=WorldState.checkpoint_id
 var last_position:Vector2=WorldState.checkpoint
 var persisted:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(WorldState.SAVE_PATH))
 world.queue_free();await frames(2)
 WorldState.restore_progress(persisted)
 world=load("res://scenes/world_01/world_01.tscn").instantiate();add_child(world)
 await frames(3)
 var restored:=false
 for marker in world.markers:
  if marker.id==last_id:restored=marker.active
 check(restored and WorldState.checkpoint==last_position and world.player.position.distance_to(last_position)<5,"reloaded scene starts at saved totem with active art")
 print("CHECKPOINT_TOTEMS: %d checks / %d failures"%[checks,failures])
 get_tree().quit(0 if failures==0 else 1)
