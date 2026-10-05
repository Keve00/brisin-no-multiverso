extends Node
signal sector_connected(sector_id: String)
signal checkpoint_reached(checkpoint_id: String)
signal fragment_collected(amount: int)
signal node_activated(node_id: String)
enum Connection { OFFLINE, UNSTABLE, CONNECTING, ONLINE }
var connection: int = Connection.OFFLINE
var checkpoint := Vector2(120, 540)
var checkpoint_id := "spawn"
var fragments: Array = []
var completed := false
var blockout := false
var reduced_flash := true
var music_volume := 0.35
var sfx_volume := 0.55
var seen_important_notices: Array = []
# Player-level preference survives new adventures. Pausing belongs only to the
# first opted-in play session, never restored automatically on later visits.
var has_played := false
var tutorial_choice_made := false
var tutorial_opted_in := false
var tutorial_session_active := false
func choose_first_tutorial(enabled: bool) -> void:
 if tutorial_choice_made: return
 tutorial_choice_made=true
 has_played=true
 tutorial_opted_in=enabled
 tutorial_session_active=enabled
 save_progress()
func tutorial_pauses_enabled() -> bool:
 return tutorial_choice_made and tutorial_opted_in and tutorial_session_active

# One-shot handoff after the title animation; deliberately never saved.
var skip_intro_once := false
const SAVE_PATH = "user://brisinho_v01.json"
func _ready() -> void:
 setup_inputs()
 blockout = "--blockout" in OS.get_cmdline_user_args()
 load_progress()
func setup_inputs() -> void:
 # Explicit controller confirmation also works without an OS-reported device.
 # Install before the gameplay guard so restored InputMaps keep menu support.
 var accept := InputEventJoypadButton.new()
 accept.button_index = JOY_BUTTON_A
 if not InputMap.action_has_event("ui_accept",accept):
  InputMap.action_add_event("ui_accept",accept)
 # Install new actions even when an older complete InputMap already exists.
 if not InputMap.has_action("chip"): InputMap.add_action("chip")
 # Migrate the previous B binding so it cannot remain as an extra shortcut.
 for event in InputMap.action_get_events("chip"):
  if event is InputEventKey and (event.physical_keycode == KEY_B or event.keycode == KEY_B):
   InputMap.action_erase_event("chip",event)
 var chip_key := InputEventKey.new()
 chip_key.physical_keycode = KEY_F
 if not InputMap.action_has_event("chip",chip_key): InputMap.action_add_event("chip",chip_key)
 var chip_pad := InputEventJoypadButton.new()
 chip_pad.button_index = JOY_BUTTON_Y
 if not InputMap.action_has_event("chip",chip_pad): InputMap.action_add_event("chip",chip_pad)
 if InputMap.has_action("move_left"): return
 var bindings = {"move_left":[KEY_A,KEY_LEFT],"move_right":[KEY_D,KEY_RIGHT],"jump":[KEY_SPACE],"dash":[KEY_SHIFT],"pulse":[KEY_E],"pause_game":[KEY_ESCAPE],"debug_hits":[KEY_F1],"debug_speed":[KEY_F2],"debug_state":[KEY_F3],"debug_respawn":[KEY_F4],"debug_reset":[KEY_F5],"debug_art":[KEY_F6],"debug_invincible":[KEY_F7]}
 for action in bindings:
  InputMap.add_action(action)
  for code in bindings[action]:
   var event := InputEventKey.new()
   event.physical_keycode = code
   InputMap.action_add_event(action,event)
 var pad = {"jump":JOY_BUTTON_A,"dash":JOY_BUTTON_X,"pulse":JOY_BUTTON_B,"pause_game":JOY_BUTTON_START,"move_left":JOY_BUTTON_DPAD_LEFT,"move_right":JOY_BUTTON_DPAD_RIGHT}
 for action in pad:
  var event := InputEventJoypadButton.new()
  event.button_index = pad[action]
  InputMap.action_add_event(action,event)
 for action in ["move_left","move_right"]:
  var event := InputEventJoypadMotion.new()
  event.axis = JOY_AXIS_LEFT_X
  event.axis_value = -1.0 if action == "move_left" else 1.0
  InputMap.action_add_event(action,event)
func save_progress() -> void:
 var data = {"checkpoint":[checkpoint.x,checkpoint.y],"checkpoint_id":checkpoint_id,"fragments":fragments,"online":connection == Connection.ONLINE,"completed":completed,"music":music_volume,"sfx":sfx_volume,"reduced_flash":reduced_flash}
 var f := FileAccess.open(SAVE_PATH,FileAccess.WRITE)
 data["seen_important_notices"]=seen_important_notices
 data["has_played"]=has_played
 data["tutorial_opted_in"]=tutorial_opted_in
 data["tutorial_choice_made"]=tutorial_choice_made
 if f: f.store_string(JSON.stringify(data))
func load_progress() -> void:
 if "--test" in OS.get_cmdline_user_args() or "--fresh" in OS.get_cmdline_user_args(): return
 if not FileAccess.file_exists(SAVE_PATH): return
 var data = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
 if not data is Dictionary: return
 restore_progress(data)
func restore_progress(data: Dictionary) -> void:
 # Playing a previous version does not prove the player chose a tutorial.
 has_played=bool(data.get("has_played",true))
 tutorial_choice_made=bool(data.get("tutorial_choice_made",false))
 tutorial_opted_in=bool(data.get("tutorial_opted_in",false))
 tutorial_session_active=false
 var cp = data.get("checkpoint",[120,540])
 checkpoint = Vector2(cp[0],cp[1])
 checkpoint_id = data.get("checkpoint_id","spawn")
 fragments = data.get("fragments",[])
 connection = Connection.ONLINE if data.get("online",false) else Connection.OFFLINE
 completed = data.get("completed",false)
 music_volume = data.get("music",0.35)
 sfx_volume = data.get("sfx",0.55)
 reduced_flash = data.get("reduced_flash",true)
 var seen = data.get("seen_important_notices",[])
 seen_important_notices = seen if seen is Array else []
func reset_progress() -> void:
 checkpoint = Vector2(120,540)
 checkpoint_id = "spawn"
 connection = Connection.OFFLINE
 fragments.clear()
 seen_important_notices.clear()
 completed = false
 save_progress()
