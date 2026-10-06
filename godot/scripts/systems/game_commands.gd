extends Node
## Touch owns its own state. It never calls Input.action_release(), so releasing
## one finger cannot release a physical key/controller or another finger.
const ACTIONS := ["move_left","move_right","jump","dash","pulse","chip"]
var owners: Dictionary = {}
var presses: Dictionary = {}
var releases: Dictionary = {}
var suppressed: Dictionary = {}
var last_touch_jump := false

func _ready() -> void:
 process_mode = Node.PROCESS_MODE_ALWAYS
 process_physics_priority = 1000 # Consume edges after the player's physics tick.

func set_touch(owner: int, action: String) -> void:
 var previous: String = owners.get(owner,"")
 if previous == action: return
 if not previous.is_empty():
  owners.erase(owner)
  if not owners.values().has(previous): releases[previous] = true
 if not action.is_empty():
  if not owners.values().has(action): presses[action] = true
  owners[owner] = action
  if action == "jump": last_touch_jump = true

func clear() -> void:
 owners.clear()
 presses.clear()
 releases.clear()
 for action in ACTIONS:
  if Input.is_action_pressed(action): suppressed[action] = true

func physical(action: String) -> bool:
 if suppressed.has(action):
  if not Input.is_action_pressed(action): suppressed.erase(action)
  else: return false
 return Input.is_action_pressed(action)

func pressed(action: String) -> bool:
 return owners.values().has(action) or physical(action)

func just_pressed(action: String) -> bool:
 var native := physical(action) and Input.is_action_just_pressed(action)
 if native and action == "jump": last_touch_jump = false
 return presses.has(action) or native

func just_released(action: String) -> bool:
 return releases.has(action) or (not suppressed.has(action) and Input.is_action_just_released(action))

func strength(action: String) -> float:
 return maxf(1.0 if owners.values().has(action) else 0.0,Input.get_action_strength(action) if physical(action) else 0.0)

func axis() -> float:
 return strength("move_right")-strength("move_left")

func _physics_process(_dt: float) -> void:
 presses.clear()
 releases.clear()
 for action in suppressed.keys(): physical(action)
