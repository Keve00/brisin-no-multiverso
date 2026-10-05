extends Node
var failures := 0
func check(ok: bool, message: String) -> void:
 if not ok:
  failures += 1
  push_error(message)
func _ready() -> void:
 call_deferred("run")
func run() -> void:
 WorldState.reset_progress()
 WorldState.tutorial_choice_made = true
 WorldState.tutorial_session_active = false
 var world = load("res://scenes/world_01/world_01.tscn").instantiate()
 add_child(world)
 world.player.set_physics_process(false)
 var portal
 for marker in world.markers:
  if marker.kind == "portal": portal = marker
 # Feet can be well above the ground pivot while the body enters the opening.
 world.player.position = portal.position + Vector2(0,-108)
 portal._physics_process(1.0/60)
 check(not world.portal_transition_active,"offline portal cannot conclude")
 WorldState.connection = WorldState.Connection.ONLINE
 world.apply_connection()
 world.player.position = portal.position + Vector2(-140,-108)
 portal._physics_process(1.0/60)
 check(not world.portal_transition_active,"outside opening cannot start entry")
 world.player.position = portal.position + Vector2(0,-108)
 portal._physics_process(1.0/60)
 check(world.portal_transition_active,"jump through visible portal starts entry")
 if world.portal_transition_active:
  world.portal_transition.set_process(false)
  world.portal_transition._process(1.8)
  check(WorldState.completed and world.hud.menu_kind == "end","entry shows conclusion and saves completion")
 get_tree().paused = false
 world.queue_free()
 print("PORTAL_ENTRY_RESULT: ",failures," failures")
 get_tree().quit(0 if failures == 0 else 1)
