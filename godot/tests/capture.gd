extends Node
func _ready() -> void:
 call_deferred("capture")
func capture() -> void:
 WorldState.reset_progress()
 var world = load("res://scenes/world_01/world_01.tscn").instantiate()
 add_child(world)
 for frame in 30: await get_tree().process_frame
 for shot in [["spawn",Vector2(120,540)],["vento",Vector2(1780,320)],["vento_pulso",Vector2(1780,320)],["rail",Vector2(2800,270)],["nexo_offline",Vector2(5300,340)],["nexo_online",Vector2(5300,340)],["expansao",Vector2(6860,300)],["portal",Vector2(7670,340)]]:
  world.player.position = shot[1]
  world.player.velocity = Vector2.ZERO
  world.player.change_state("DISABLED")
  world.player.camera.reset_smoothing()
  if shot[0] == "nexo_online":
   WorldState.connection = WorldState.Connection.ONLINE
   world.online_blend = 1
   world.apply_connection()
  for frame in 8: await get_tree().process_frame
  if shot[0] == "vento_pulso": await get_tree().create_timer(0.65).timeout
  await RenderingServer.frame_post_draw
  get_viewport().get_texture().get_image().save_png("res://docs/"+shot[0]+".png")
 Audio.music.stop()
 Audio.online_music.stop()
 Audio.music.stream = null
 Audio.online_music.stream = null
 for frame in 12: await get_tree().process_frame
 get_tree().quit()
