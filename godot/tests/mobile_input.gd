extends Node
var failures := 0
var checks := 0
var world: Node2D
var controls: CanvasLayer
func check(ok: bool, title: String) -> void:
 checks += 1
 if ok: print("PASS: ",title)
 else: failures += 1;push_error("FAIL: "+title)
func frames(n: int) -> void:
 for i in n: await get_tree().physics_frame
func touch(id: int, action: String, down: bool = true, cancel: bool = false) -> void:
 var event := InputEventScreenTouch.new()
 event.index=id
 event.position=controls.areas[action].get_center()
 event.pressed=down
 event.canceled=cancel
 get_viewport().push_input(event,true)
func drag(id: int, pos: Vector2) -> void:
 var event := InputEventScreenDrag.new()
 event.index=id
 event.position=pos
 get_viewport().push_input(event,true)
func _ready() -> void:
 process_mode=Node.PROCESS_MODE_ALWAYS
 call_deferred("run")
func run() -> void:
 WorldState.mobile_enabled=true
 WorldState.interrupted=false
 world=load("res://scenes/world_01/world_01.tscn").instantiate()
 add_child(world)
 controls=world.get_node("MobileControls")
 await frames(10)
 touch(0,"move_right");touch(1,"jump")
 await frames(3)
 check(world.player.velocity.x>0 and world.player.velocity.y<0,"two fingers move and jump together")
 drag(1,controls.areas.dash.get_center())
 await frames(2)
 check(world.player.state=="DASH" and world.player.facing==1,"same thumb slides jump to dash")
 touch(1,"dash",false);touch(0,"move_right",false)
 await frames(2)
 check(GameCommands.owners.is_empty(),"release outside controls clears ownership")
 Input.action_press("move_right")
 touch(2,"move_right");touch(2,"move_right",false)
 check(GameCommands.pressed("move_right"),"touch release preserves held keyboard")
 Input.action_release("move_right")
 Input.action_press("move_right",0.45)
 check(absf(GameCommands.axis()-0.45)<0.001,"physical analog strength remains proportional")
 touch(2,"move_right");touch(2,"move_right",false)
 check(absf(GameCommands.axis()-0.45)<0.001,"touch release restores analog strength")
 Input.action_release("move_right")
 touch(2,"move_left");touch(3,"move_left")
 touch(2,"move_left",false)
 check(GameCommands.pressed("move_left"),"one finger cannot release a second owner")
 touch(3,"move_left",true,true)
 check(not GameCommands.pressed("move_left"),"canceled touch clears final owner")
 touch(2,"move_left")
 drag(2,Vector2(500,300))
 check(not GameCommands.pressed("move_left"),"dragging out releases movement")
 drag(2,controls.areas.move_right.get_center())
 check(GameCommands.axis()==1,"direction pad supports dragging across neutral zone")
 world.hud.show_menu("pause")
 await get_tree().process_frame
 await get_tree().process_frame
 check(GameCommands.owners.is_empty() and not controls.enabled,"pause clears every finger and hides gameplay controls")
 touch(4,"chip")
 check(GameCommands.owners.is_empty(),"menu tap cannot fire chip")
 Input.action_press("jump")
 world.hud.resume()
 await get_tree().process_frame
 check(not GameCommands.pressed("jump"),"held confirmation key suppressed until release")
 Input.action_release("jump")
 await frames(2)
 world.player.position=Vector2(400,550)
 world.player.velocity=Vector2.ZERO
 world.player.change_state("IDLE")
 world.player.dash_time=0
 await frames(12)
 touch(0,"jump");await frames(2);touch(0,"jump",false);await frames(2)
 var full_speed: float=world.player.velocity.y
 check(full_speed< -300,"tap jump retains full height by default")
 world.player.position=Vector2(400,550);world.player.velocity=Vector2.ZERO
 await frames(45)
 WorldState.variable_jump=true
 touch(0,"jump");await frames(2);touch(0,"jump",false);await frames(2)
 check(world.player.velocity.y>full_speed+100,"optional hold/release reduces jump height")
 WorldState.variable_jump=false
 touch(5,"move_right")
 WorldState.request_interruption("TESTE")
 await get_tree().process_frame
 var position: Vector2=world.player.position
 await frames(8)
 check(get_tree().paused and world.player.position==position and GameCommands.owners.is_empty(),"focus interruption freezes physics and clears commands")
 WorldState.mobile_portrait=true
 check(not WorldState.resume_mobile(),"portrait cannot resume gameplay")
 WorldState.mobile_portrait=false
 check(WorldState.resume_mobile(),"landscape permits explicit resume")
 await get_tree().process_frame
 world.hud.interruption_layer.hide();world.hud.resume()
 await frames(2)
 # Default is one chip per tap; repeat is an explicit setting and uses cooldown.
 var shots := [0]
 world.player.chip_launched.connect(func(_origin, _direction): shots[0]+=1)
 world.player.position=Vector2(400,550);world.player.velocity=Vector2.ZERO
 world.player.invincible=true
 world.player.change_state("IDLE")
 await frames(8)
 WorldState.chip_repeat=false
 touch(3,"chip");await frames(60);touch(3,"chip",false)
 check(shots[0]==1,"holding chip fires once by default")
 WorldState.chip_repeat=true
 touch(3,"chip");await frames(60);touch(3,"chip",false)
 check(shots[0]>=3 and shots[0]<=5,"optional chip repeat respects 0.35s cooldown")
 WorldState.chip_repeat=false
 # CSS-to-logical targets are checked over compact and tall landscape canvases.
 for factor in [0.42,0.48,0.67,1.0]:
  for mirrored in [false,true]:
   WorldState.controls_mirrored=mirrored
   for scale in [1.0,1.125,1.25]:
    for lift in [0.0,1.0]:
     WorldState.control_scale=scale
     WorldState.control_lift=lift
     controls.layout(factor)
     var valid:=true
     for action in controls.areas:
      var rect: Rect2=controls.areas[action]
      valid=valid and rect.size.x*factor>=48 and rect.size.y*factor>=48 and Rect2(Vector2.ZERO,Vector2(1152,648)).encloses(rect)
      for other in controls.areas:
       if other!=action: valid=valid and not rect.intersects(controls.areas[other])
     check(valid,"CSS targets >=48 and no overlaps @ "+str([factor,mirrored,scale,lift]))
     check(controls.areas.jump.size.y>controls.areas.dash.size.y and controls.areas.chip.get_center().y<controls.areas.dash.position.y and controls.areas.pulse.get_center().y<controls.areas.jump.position.y,"primary jump and upper attacks keep approved thumb hierarchy")
 WorldState.controls_mirrored=true;WorldState.control_scale=1.125;WorldState.control_lift=1
 WorldState.chip_repeat=true;WorldState.low_quality=true
 var saved_checkpoint:=WorldState.checkpoint_id
 WorldState.save_progress()
 var saved: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(WorldState.SAVE_PATH))
 WorldState.controls_mirrored=false;WorldState.low_quality=false
 WorldState.restore_progress(saved)
 check(WorldState.controls_mirrored and WorldState.low_quality and WorldState.control_scale==1.125 and WorldState.checkpoint_id==saved_checkpoint,"mobile preferences round-trip without changing progress")
 WorldState.reset_progress()
 check(WorldState.controls_mirrored and WorldState.chip_repeat and WorldState.control_lift==1,"new adventure preserves mobile preferences")
 WorldState.restore_progress({"checkpoint_id":"brisa_01","fragments":["f_0"]})
 check(WorldState.control_scale==1 and WorldState.fragments==["f_0"] and not WorldState.variable_jump,"legacy saves receive mobile defaults and preserve collectible IDs")
 world.queue_free();get_tree().paused=false
 await get_tree().process_frame
 check(GameCommands.owners.is_empty(),"removing scene releases commands")
 print("MOBILE_INPUT: %d checks / %d failures" % [checks,failures])
 get_tree().quit(0 if failures==0 else 1)
