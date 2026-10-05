extends Node
func _ready() -> void:
 process_mode=Node.PROCESS_MODE_ALWAYS
 call_deferred("capture")
func capture() -> void:
 WorldState.tutorial_choice_made=true
 WorldState.tutorial_session_active=false
 var world=load("res://scenes/world_01/world_01.tscn").instantiate()
 add_child(world)
 var hud=world.hud
 WorldState.fragments=["f_0"]
 hud.show_menu("intro")
 hud.title_hero.pause()
 hud.title_hero.frame=8
 for i in 5: await get_tree().process_frame
 await RenderingServer.frame_post_draw
 get_viewport().get_texture().get_image().save_png("res://docs/menu_web_approved.png")
 world.queue_free()
 get_tree().paused=false
 for player in [Audio.music,Audio.online_music,Audio.menu_music]:
  player.stream_paused=false
  player.stop()
  player.stream=null
 world=null
 hud=null
 for i in 12: await get_tree().process_frame
 get_tree().quit()
