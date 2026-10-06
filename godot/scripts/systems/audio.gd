extends Node

# Menu owns its own composition; ambient/online belong only to gameplay.
const MUSIC_TRANSITION_SECONDS := 0.45
const ONLINE_TRANSITION_SECONDS := 0.5
var music: AudioStreamPlayer
var online_music: AudioStreamPlayer
var menu_music: AudioStreamPlayer
var sounds: Dictionary = {}
var _menu_active := true
var _menu_gain := 1.0
var _game_gain := 0.0
var _online_gain := 0.0

func _ready() -> void:
 process_mode = Node.PROCESS_MODE_ALWAYS
 # Autoload precedes the HUD: do not briefly start gameplay music behind title.
 _menu_active = not "--test" in OS.get_cmdline_user_args() and not WorldState.skip_intro_once
 _menu_gain = 1.0 if _menu_active else 0.0
 _game_gain = 0.0 if _menu_active else 1.0
 _online_gain = 1.0 if WorldState.connection == WorldState.Connection.ONLINE else 0.0
 if DisplayServer.get_name() == "headless": return
 for key in ["jump","land","dash","pulse","hit","pickup","checkpoint","node","rail","portal","notice","alien_shot"]:
  var path = "res://assets/audio/"+key+".wav"
  if ResourceLoader.exists(path): sounds[key] = load(path)
 music = _loop_player("res://assets/audio/ambient.wav", "GameplayAmbient")
 online_music = _loop_player("res://assets/audio/online.wav", "GameplayOnline")
 menu_music = _loop_player("res://assets/audio/menu_theme.ogg", "MenuTheme")
 _apply_mix()

func _loop_player(path: String, player_name: String) -> AudioStreamPlayer:
 var player := AudioStreamPlayer.new()
 player.name = player_name
 add_child(player)
 if ResourceLoader.exists(path):
  # Duplicate resource so loop settings do not mutate a cached shared stream.
  var stream := load(path).duplicate() as AudioStream
  if stream is AudioStreamOggVorbis:
   stream.loop = true
  elif stream is AudioStreamWAV:
   stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
   stream.loop_begin = 0
   stream.loop_end = int(roundf(stream.get_length() * stream.mix_rate))
  player.stream = stream
 return player

func set_menu_active(active: bool) -> void:
 if _menu_active == active: return
 _menu_active = active
 if active:
  # A newly shown menu must never inherit ambient/online, even on saved Online.
  _game_gain = 0.0
  _menu_gain = 0.0
  if menu_music and menu_music.stream:
   menu_music.stop()
 _apply_mix()

func _process(dt: float) -> void:
 if not music: return
 var step := maxf(0.0, dt) / MUSIC_TRANSITION_SECONDS
 _menu_gain = move_toward(_menu_gain, 1.0 if _menu_active else 0.0, step)
 _game_gain = move_toward(_game_gain, 0.0 if _menu_active else 1.0, step)
 var online_target := 1.0 if WorldState.connection == WorldState.Connection.ONLINE else 0.0
 _online_gain = move_toward(_online_gain, online_target, maxf(0.0, dt) / ONLINE_TRANSITION_SECONDS)
 _apply_mix()
 # Existing effects obey a slider adjustment, including exact silence at zero.
 var sfx_gain := clampf(WorldState.sfx_volume, 0.0, 1.0)
 for child in get_children():
  if child is AudioStreamPlayer and child.is_in_group("brisin_sfx"):
   _set_gain(child, maxf(sfx_gain, 0.0001))
   _set_paused(child, sfx_gain <= 0.0)

func _apply_mix() -> void:
 var volume := clampf(WorldState.music_volume, 0.0, 1.0)
 _apply_player(menu_music, volume * _menu_gain)
 _apply_player(music, volume * _game_gain)
 _apply_player(online_music, volume * _game_gain * _online_gain)

func _apply_player(player: AudioStreamPlayer, gain: float) -> void:
 if not player or not player.stream: return
 # Pausing guarantees exact zero; -80 dB alone is only quiet, not mute.
 if gain <= 0.0:
  _set_paused(player, true)
  return
 _set_gain(player, gain)
 if not player.playing:
  player.play()
 _set_paused(player, false)

func _set_paused(player: AudioStreamPlayer, paused: bool) -> void:
 # Web Sample playback must receive transitions, never resume on every frame.
 if player.stream_paused != paused:
  player.stream_paused = paused

func _set_gain(player: AudioStreamPlayer, gain: float) -> void:
 var target := linear_to_db(gain)
 if not is_equal_approx(player.volume_db, target):
  player.volume_db = target

func play(key: String) -> void:
 if not sounds.has(key) or WorldState.sfx_volume <= 0.0: return
 var sound := AudioStreamPlayer.new()
 sound.stream = sounds[key]
 sound.volume_db = linear_to_db(clampf(WorldState.sfx_volume, 0.0, 1.0))
 add_child(sound)
 sound.add_to_group("brisin_sfx")
 sound.finished.connect(sound.queue_free)
 sound.play()

func _exit_tree() -> void:
 for child in get_children():
  if child is AudioStreamPlayer:
   _set_paused(child, false)
   child.stop()
   child.stream = null
 sounds.clear()
