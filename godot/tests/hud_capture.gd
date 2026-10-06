extends Node
func _ready() -> void:
 process_mode=Node.PROCESS_MODE_ALWAYS
 call_deferred("capture")
func shot(name_text: String) -> void:
 for i in 5: await get_tree().process_frame
 await RenderingServer.frame_post_draw
 get_viewport().get_texture().get_image().save_png("res://docs/"+name_text+".png")
func capture() -> void:
 WorldState.mobile_enabled=true
 WorldState.tutorial_choice_made=true
 WorldState.tutorial_session_active=false
 var world=load("res://scenes/world_01/world_01.tscn").instantiate()
 add_child(world)
 var hud=world.hud
 hud.resume()
 world.player.set_physics_process(false)
 world.player.position=Vector2(800,550)
 world.player.camera.reset_smoothing()
 hud.set_process(false)
 hud.update_mobile_layout()
 hud.objective.text="COSTA • CONECTANDO"
 hud.counter.text="00 / 49"
 hud.game_hud.get_node("ObjectiveDetail").text="RESTABELEÇA O NÓ"
 hud.context_title.text="CORRENTE DE VENTO"
 hud.context_text.text="PULE NA CORRENTE PARA GANHAR ALTURA"
 hud.context_hint.position=hud.mobile_notice_candidates(hud.context_hint)[1]
 hud.context_hint.show()
 await shot("hud_readable_context")
 hud.context_hint.hide()
 hud.important_title.text="CONEXÃO RESTABELECIDA"
 hud.important_text.text="O CAMINHO PARA O PORTAL ESTÁ ABERTO"
 hud.fit_mobile_notice(hud.important_card,hud.important_title,hud.important_text)
 hud.important_layer.show()
 get_tree().paused=true
 world.get_node("MobileControls").surface.hide()
 await shot("hud_readable_tutorial")
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
