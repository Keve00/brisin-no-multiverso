extends Node
var checks:=0
var failures:=0
func check(ok:bool,label:String)->void:
 checks+=1
 if ok:print("PASS: ",label)
 else:failures+=1;push_error(label)
func _ready()->void:call_deferred("run")
func run()->void:
 WorldState.reset_progress()
 var world=load("res://scenes/world_01/world_01.tscn").instantiate();add_child(world)
 var marker:Node2D
 for candidate in world.markers:
  if candidate.id=="brisa_01":marker=candidate
 check(marker.CHECKPOINT_BASE.get_size()==Vector2(80,128) and marker.TOTEM_SCALE==1.0,"primary uses approved compact coastal totem")
 var seen:Dictionary={}
 for texture in marker.CHECKPOINT_SIGNALS:
  seen[texture.resource_path]=true
  check(texture.get_size()==Vector2(80,128),"signal frames preserve canvas and pivot")
 check(seen.size()==8,"eight real SVG animation frames")
 marker.active=true
 var before:float=marker.time
 await get_tree().physics_frame;await get_tree().physics_frame
 check(marker.time>before,"signal animation clock progresses with gameplay")
 get_tree().paused=true;before=marker.time
 for i in 4:await get_tree().process_frame
 check(marker.time==before,"pause freezes checkpoint animation")
 get_tree().paused=false
 WorldState.reduced_flash=true
 check(marker.TOTEM_PIVOT==Vector2(40,125),"ground pivot fixed across active and reduced-flash states")
 print("CHECKPOINT_WAVE: %d checks / %d failures"%[checks,failures])
 get_tree().quit(0 if failures==0 else 1)
