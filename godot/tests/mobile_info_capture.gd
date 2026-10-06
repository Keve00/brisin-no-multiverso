extends Node
func _ready() -> void: call_deferred("capture")
func capture() -> void:
 WorldState.mobile_enabled=true
 WorldState.tutorial_choice_made=true
 WorldState.tutorial_session_active=false
 var world=load("res://scenes/world_01/world_01.tscn").instantiate()
 add_child(world)
 world.hud.resume()
 var hud=world.hud
 hud.set_process(false)
 hud.update_mobile_layout(0.48)
 world.get_node("MobileControls").layout(0.48)
 world.player.position=Vector2(800,550)
 world.player.set_physics_process(false)
 world.player.camera.reset_smoothing()
 hud.context_title.text="ETZINHO ARMADO"
 hud.context_text.text="PULSO • BLOQUEIE OS TIROS"
 hud.fit_mobile_notice(hud.context_hint,hud.context_title,hud.context_text)
 hud.context_hint.position=hud.mobile_notice_candidates(hud.context_hint)[0]
 hud.context_hint.show()
 for i in 12: await get_tree().process_frame
 await RenderingServer.frame_post_draw
 get_viewport().get_texture().get_image().save_png("res://docs/cosmic_qa/mobile_information.png")
 world.queue_free()
 await get_tree().process_frame
 get_tree().quit()
