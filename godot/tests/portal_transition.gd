extends Node
var failures: Array[String] = []
var checks := 0
var finishes := 0
func check(ok: bool, label: String) -> void:
 checks += 1
 if not ok:
  failures.append(label)
  push_error(label)
func _ready() -> void:
 call_deferred("run")
func run() -> void:
 WorldState.reset_progress()
 var previous_reduced_flash: bool = WorldState.reduced_flash
 WorldState.reduced_flash = false
 var world = load("res://scenes/world_01/world_01.tscn").instantiate()
 add_child(world)
 world.player.set_physics_process(false)
 world.finished.connect(func(_elapsed: float, _fragments: int) -> void: finishes += 1)
 world.begin_portal_transition("portal_02")
 check(not world.portal_transition_active,"portal Offline rejects entry")
 WorldState.connection = WorldState.Connection.ONLINE
 world.apply_connection()
 world.begin_portal_transition("bad_id")
 check(not world.portal_transition_active,"unknown marker cannot lock gameplay")
 var original_foot: Vector2 = world.point(world.level.portal)+Vector2(-50,0)
 world.player.position = original_foot
 world.player.change_state("RESPAWN")
 world.begin_portal_transition("portal_02")
 check(not world.portal_transition_active,"respawn rejects entry without latching marker")
 world.player.change_state("IDLE")
 var save_before: String = FileAccess.get_file_as_string(WorldState.SAVE_PATH)
 world.begin_portal_transition("portal_02")
 var transition = world.portal_transition
 transition.set_process(false)
 check(world.portal_transition_active and world.player.state=="DISABLED","entry locks player while playing finite animation")
 check(world.hud.menu_kind!="end" and not WorldState.completed and finishes==0,"entry does not show conclusion or save completed")
 var full_particles: int = transition.particles.size()
 var singleton_id: int = transition.get_instance_id()
 world.begin_portal_transition("portal_02")
 check(world.portal_transition.get_instance_id()==singleton_id,"duplicate entry reuses singleton without restart")
 world._finish_portal_transition()
 check(not WorldState.completed and finishes==0,"premature finish callback cannot complete")
 transition._process(0.3)
 check(world.player.position==original_foot and transition.visual_wrap.scale==Vector2.ONE,"approach prepares opening before attraction")
 transition._process(0.65)
 check(world.player.position.distance_to(original_foot)>5 and transition.visual_wrap.scale.x<1 and transition.visual_wrap.scale.x==transition.visual_wrap.scale.y,"attraction moves body and shrinks visual uniformly")
 check(FileAccess.get_file_as_string(WorldState.SAVE_PATH)==save_before,"progress is unchanged during animation")
 WorldState.connection = WorldState.Connection.OFFLINE
 transition._process(0.01)
 check(not world.portal_transition_active and world.portal_transition==null,"disconnect cancels and clears entry latch")
 check(world.player.position==original_foot and world.player.visual.get_parent()==world.player and world.player.state=="IDLE","cancel restores feet visual parent and gameplay state")
 check(world.scenery_svg.portal_rotor.visible,"cancel restores original portal core")
 check(world.enemies[0].is_physics_processing(),"cancel restores enemy simulation")
 await get_tree().process_frame
 WorldState.connection = WorldState.Connection.ONLINE
 world.player.change_state("IDLE")
 WorldState.reduced_flash = true
 world.begin_portal_transition("portal_02")
 transition = world.portal_transition
 transition.set_process(false)
 check(transition.particles.size() < full_particles,"reduced flash mode decreases entry particle population")
 check(transition.root_ring.modulate.a == 1 and transition.particles[0].modulate.a == 1,"reduced mode preserves opaque portal lanes and packets")
 transition.queue_free()
 await get_tree().process_frame
 await get_tree().process_frame
 check(not world.portal_transition_active and world.player.visual.get_parent()==world.player,"removing effect directly also releases wrapper and lock")
 WorldState.reduced_flash = false
 world.begin_portal_transition("portal_02")
 transition = world.portal_transition
 transition.set_process(false)
 transition._process(1.6)
 check(not WorldState.completed and transition.root_ring.scale.x<0.78,"closing ring precedes completion")
 transition._process(0.2)
 check(WorldState.completed and finishes==1 and world.hud.menu_kind=="end","complete and conclusion occur only after full 1.8 seconds")
 var completed_save = JSON.parse_string(FileAccess.get_file_as_string(WorldState.SAVE_PATH))
 check(completed_save.completed,"completion persists at end of animation")
 world._finish_portal_transition()
 transition._process(2.0)
 check(finishes==1,"completion cannot emit twice")
 get_tree().paused = false
 world.queue_free()
 await get_tree().process_frame
 await get_tree().process_frame
 WorldState.completed = false
 var unloading_world = load("res://scenes/world_01/world_01.tscn").instantiate()
 add_child(unloading_world)
 unloading_world.begin_portal_transition("portal_02")
 var unloading_transition = unloading_world.portal_transition
 unloading_transition._process(0.8)
 unloading_world.queue_free()
 await get_tree().process_frame
 await get_tree().process_frame
 check(not is_instance_valid(unloading_world) and not is_instance_valid(unloading_transition) and not WorldState.completed,"unloading an active entry cleans up without completing or retaining nodes")
 var malformed = Node2D.new()
 malformed.set_script(load("res://scripts/systems/portal_transition_svg.gd"))
 add_child(malformed)
 await get_tree().process_frame
 check(not is_instance_valid(malformed),"malformed transition safely frees without player or world")
 WorldState.reduced_flash = previous_reduced_flash
 print("PORTAL_TRANSITION_RESULT: ",checks," checks / ",failures.size()," failures")
 get_tree().quit(0 if failures.is_empty() else 1)
