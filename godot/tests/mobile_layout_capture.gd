extends Node
# Capture the real renderer, not a CPU reconstruction, using isolated test saves.
func _ready() -> void:
 process_mode=Node.PROCESS_MODE_ALWAYS
 call_deferred("capture")
func shot(name_text: String) -> void:
 for i in 4: await get_tree().process_frame
 await RenderingServer.frame_post_draw
 get_viewport().get_texture().get_image().save_png("res://docs/"+name_text+".png")
func capture() -> void:
 WorldState.mobile_enabled=true
 WorldState.interrupted=false
 WorldState.tutorial_choice_made=true
 WorldState.tutorial_session_active=false
 var world=load("res://scenes/world_01/world_01.tscn").instantiate()
 add_child(world)
 var hud=world.hud
 WorldState.fragments=["f_0"]
 hud.show_menu("intro")
 hud.title_hero.pause()
 hud.title_hero.frame=8
 await shot("mobile_menu_approved")
 hud.title_hero.frame=20
 await shot("mobile_menu_wave")
 WorldState.fragments=[]
 hud.show_menu("intro")
 await shot("mobile_menu_fresh")
 hud.resume()
 world.player.set_physics_process(false)
 world.player.position=Vector2(800,550)
 world.player.camera.reset_smoothing()
 await shot("mobile_controls_approved")
 world.queue_free()
 get_tree().paused=false
 Audio.music.stop()
 Audio.menu_music.stop()
 Audio.menu_music.stream=null
 Audio.online_music.stop()
 Audio.music.stream=null
 Audio.online_music.stream=null
 world=null
 hud=null
 for i in 12: await get_tree().process_frame
 get_tree().quit()
