extends Node
func _ready() -> void:
 process_mode=Node.PROCESS_MODE_ALWAYS
 call_deferred("run")
func run() -> void:
 WorldState.reset_progress()
 WorldState.tutorial_choice_made=true
 WorldState.tutorial_session_active=false
 var world=load("res://scenes/world_01/world_01.tscn").instantiate()
 add_child(world)
 world.player.change_state("DISABLED")
 world.player.set_physics_process(false)
 for shot in [["spawn",world.point(world.level.spawn)],["wind",Vector2(1780,320)],["node_off",world.point(world.level.node)],["node_on",world.point(world.level.node)],["portal",world.point(world.level.portal)]]:
  world.player.position=shot[1]+Vector2(-100,-3)
  world.player.camera.reset_smoothing()
  if shot[0]=="node_on":
   WorldState.connection=WorldState.Connection.ONLINE
   world.online_blend=1
   world.apply_connection()
  for i in 12:await get_tree().process_frame
  await RenderingServer.frame_post_draw
  get_viewport().get_texture().get_image().save_png("res://docs/cosmic_qa/game_"+shot[0]+".png")
 world.queue_free()
 for audio_player in [Audio.music,Audio.online_music,Audio.menu_music]:
  audio_player.stream_paused=false
  audio_player.stop()
  audio_player.stream=null
 for i in 12:await get_tree().process_frame
 get_tree().quit()
