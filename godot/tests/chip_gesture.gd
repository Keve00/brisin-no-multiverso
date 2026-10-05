extends Node
var checks := 0
var failures := 0
var p: BrisinhoPlayer
func check(ok: bool, label: String) -> void:
 if ok: checks+=1;print("PASS: ",label)
 else: failures+=1;push_error("FAIL: "+label)
func frames(n: int) -> void:
 for i in n: await get_tree().physics_frame
func _ready() -> void:call_deferred("run")
func run() -> void:
 var world:Node2D=load("res://scenes/world_01/world_01.tscn").instantiate()
 world.process_mode=Node.PROCESS_MODE_PAUSABLE
 add_child(world);p=world.player;p.invincible=true;p.set_art(true)
 await frames(18)
 var events:Array=[]
 p.chip_launched.connect(func(origin:Vector2,direction:float):events.append([origin,direction]))
 var foot:=p.position
 var collision:CollisionShape2D=p.get_child(0)
 var collision_size:Vector2=collision.shape.size
 check(p.launch_chip(),"launch accepts chip action")
 await frames(1)
 check(events.size()==1 and p.chip_hand.visible and p.visual.sprite_frames==p.CHIP_BODY,"accepted shot starts visible SVG hand/body in the same physics tick")
 check(p.position.distance_to(foot)<1 and collision.shape.size==collision_size and p.visual.position==Vector2(0,-56),"gesture preserves feet anchor and collision geometry")
 check(not p.launch_chip() and events.size()==1,"rejected cooldown input does not restart gesture or shoot")
 var first:Texture2D=p.chip_hand.texture
 await frames(5)
 check(p.chip_hand.texture!=first,"hand follows through visibly across release poses")
 var timer:float=p.chip_gesture_time
 get_tree().paused=true
 for i in 4:await get_tree().process_frame
 check(is_equal_approx(p.chip_gesture_time,timer),"pause freezes hand gesture alongside chip simulation")
 get_tree().paused=false
 await frames(20)
 check(not p.chip_hand.visible and p.visual.sprite_frames==p.locomotion_frames,"finite throw restores native locomotion without persistent extra hand")
 p.set_physics_process(false);p.state="RUN";p.animate(0);p.visual.set_frame_and_progress(7,0.4)
 p.facing=-1;check(p.launch_chip(),"new shot can face left after cooldown")
 p.animate(0)
 check(p.visual.animation==&"run" and p.visual.frame==7 and absf(p.visual.frame_progress-0.4)<0.01,"running animation keeps current foot phase when entering SVG gesture")
 check(p.visual.flip_h and p.chip_hand.flip_h and events.back()[1]==-1,"body and attached hand mirror with chip direction")
 p.facing=1;p.animate(0)
 check(p.visual.flip_h and p.chip_hand.flip_h,"brief follow-through keeps launch direction when movement reverses")
 p.state="JUMP_UP";p.animate(0)
 check(p.visual.animation==&"jump" and p.visual.frame==3 and p.chip_hand.visible,"airborne throw keeps jump pose and attached hand")
 p.state="DISABLED";p.animate(0)
 check(not p.chip_hand.visible and p.visual.sprite_frames==p.locomotion_frames,"portal Disabled immediately removes throw override")
 p._physics_process(0.01)
 check(p.chip_gesture_time==0 and not p.launch_chip(),"Disabled clears gesture and rejects new release")
 p.state="RESPAWN";p.chip_gesture_time=0.25;p._physics_process(0.01)
 check(p.chip_gesture_time==0 and not p.chip_hand.visible,"respawn clears gesture without leaving a floating hand")
 p.state="IDLE";p.chip_cooldown=0;p.set_art(false);p.launch_chip();p.animate(0)
 check(not p.chip_hand.visible and not p.visual.visible,"blockout does not leak SVG hand into placeholder player")
 print("CHIP GESTURE RESULT: ",checks," passed / ",failures," failed")
 get_tree().quit(0 if failures==0 else 1)
