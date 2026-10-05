extends SceneTree
var failed := false

func _initialize() -> void:
 call_deferred("run")

func check(condition: bool, label: String) -> void:
 if not condition:
  failed = true
  push_error(label)
  return
 print("PASS: " + label)

func run() -> void:
 # Build players manually because production deliberately skips device setup
 # with DisplayServer=headless. Each mock uses the real newly imported Ogg.
 var manager := root.get_node("Audio")
 var state := root.get_node("WorldState")
 manager.music = manager._loop_player("res://assets/audio/menu_theme.ogg", "GameplayAmbient")
 manager.online_music = manager._loop_player("res://assets/audio/menu_theme.ogg", "GameplayOnline")
 manager.menu_music = manager._loop_player("res://assets/audio/menu_theme.ogg", "MenuTheme")
 check(manager.menu_music.stream is AudioStreamOggVorbis, "Vorbis loaded by Godot 4.5.1")
 check(manager.menu_music.stream.loop, "native gapless looping enabled")
 check(absf(manager.menu_music.stream.get_length() - 30.0) < 0.001, "native stream duration 30 s")
 state.connection = state.Connection.ONLINE
 manager._online_gain = 1.0
 manager._menu_active = true
 manager._menu_gain = 1.0
 manager._game_gain = 0.0
 manager._apply_mix()
 check(manager.menu_music.playing and not manager.menu_music.stream_paused, "title plays menu composition")
 check((not manager.music.playing or manager.music.stream_paused) and (not manager.online_music.playing or manager.online_music.stream_paused), "saved Online cannot leak into menu")
 manager.set_menu_active(false)
 manager._process(0.225)
 check(absf(manager._menu_gain - 0.5) < 0.001 and absf(manager._game_gain - 0.5) < 0.001, "mid-transition gains crossfade in 450 ms")
 manager._process(0.225)
 check(manager.menu_music.stream_paused and not manager.music.stream_paused, "gameplay owns music after transition")
 manager.set_menu_active(true)
 check(manager.music.stream_paused and manager.online_music.stream_paused, "opening pause mutes both gameplay layers immediately")
 manager._process(0.45)
 state.music_volume = 0.0
 manager._process(0.1)
 check(manager.menu_music.stream_paused and manager.music.stream_paused and manager.online_music.stream_paused, "music volume zero is exact silence on every player")
 state.music_volume = 0.35
 manager._process(0.1)
 check(not manager.menu_music.stream_paused and manager.music.stream_paused, "unmute restores only menu")
 manager.sounds["jump"] = manager.menu_music.stream
 state.sfx_volume = 0.0
 var count := manager.get_child_count()
 manager.play("jump")
 check(count == manager.get_child_count(), "SFX zero creates no voice")
 state.sfx_volume = 0.5
 manager.play("jump")
 var effect := manager.get_child(manager.get_child_count() - 1)
 state.sfx_volume = 0.0
 manager._process(0.1)
 check(effect.stream_paused, "SFX slider zero mutes an existing voice")
 effect.stream_paused=false
 effect.stop()
 effect.queue_free()
 manager._exit_tree()
 # Dummy audio driver still owns decoder playbacks until the audio mix tick.
 # Allow its worker to release them before terminating the test process.
 await create_timer(0.3).timeout
 await process_frame
 await process_frame
 quit(1 if failed else 0)
