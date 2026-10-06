extends Node
var world:Node2D
func shot(label:String)->void:
 for i in 4:await get_tree().process_frame
 await RenderingServer.frame_post_draw
 get_viewport().get_texture().get_image().save_png("res://docs/cosmic_qa/portal_alignment_"+label+".png")
func _ready()->void:call_deferred("run")
func run()->void:
 WorldState.reset_progress();WorldState.tutorial_choice_made=true;WorldState.tutorial_session_active=false
 world=load("res://scenes/world_01/world_01.tscn").instantiate();add_child(world)
 world.player.set_physics_process(false);world.scenery_svg.set_process(false)
 world.player.position=world.point(world.level.portal)+Vector2(-95,0)
 world.player.camera.reset_smoothing()
 world.scenery_svg._process(0);await shot("offline")
 WorldState.connection=WorldState.Connection.ONLINE;world.online_blend=1;world.apply_connection()
 for i in 3:
  world.scenery_svg._process(.7 if i else 0)
  await shot("online_"+str(i))
 var frame_transform:Transform2D=world.scenery_svg.portal_frame.global_transform
 var aperture:Vector2=world.scenery_svg.portal_rotor.global_position
 assert(aperture==frame_transform*Vector2(0,-49))
 world.begin_portal_transition("portal_02")
 var effect=world.portal_transition;effect.set_process(false)
 assert(effect.global_position==aperture)
 assert(is_equal_approx(effect.vortex.rotation,world.scenery_svg.portal_core.rotation))
 assert(is_equal_approx(effect.vortex.scale.x,world.scenery_svg.portal_core.scale.x))
 for t in [0.0,.3,.95,1.5]:
  effect.age=t;effect._animate()
  assert(world.scenery_svg.portal_frame.global_transform==frame_transform)
  await shot("entry_"+str(t).replace(".","_"))
 effect.cancel();get_tree().paused=false
 print("PORTAL_ALIGNMENT: registered center, unchanged frame, seamless entry handoff")
 get_tree().quit()
