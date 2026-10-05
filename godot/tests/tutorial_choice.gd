extends Node
var failures:=0
var checks:=0
func check(ok: bool, message: String) -> void:
 checks+=1
 if ok: print("PASS: ",message)
 else: failures+=1;push_error(message)
func frames(count: int) -> void:
 for i in count: await get_tree().process_frame
func fresh_world() -> Node2D:
 WorldState.has_played=false
 WorldState.tutorial_choice_made=false
 WorldState.tutorial_opted_in=false
 WorldState.tutorial_session_active=false
 WorldState.reset_progress()
 var world=load("res://scenes/world_01/world_01.tscn").instantiate()
 add_child(world)
 world.hud.show_menu("intro")
 return world
func _ready() -> void:
 process_mode=Node.PROCESS_MODE_ALWAYS
 call_deferred("run")
func run() -> void:
 var world=fresh_world()
 var hud=world.hud
 hud.notice("PONTO BRISA • Progresso salvo")
 check(hud.important_queue.is_empty() and not hud.important_active,"no tutorial pause before explicit choice")
 hud.begin_adventure()
 check(hud.submenu=="tutorial" and not hud.starting and get_tree().paused,"first start offers tutorial before animation/gameplay")
 check(hud.buttons.size()==2 and hud.buttons[0].text=="FAZER TUTORIAL" and hud.buttons[1].text=="PULAR TUTORIAL","both tutorial choices are explicit and focused")
 hud.buttons[1].pressed.emit()
 check(WorldState.has_played and not WorldState.tutorial_pauses_enabled() and hud.starting,"skip is saved and starts normal adventure")
 await frames(100)
 hud.notice("CONECTANDO A COSTA…")
 hud._process(.1)
 check(not get_tree().paused and not hud.important_active and hud.important_queue.is_empty(),"skipping leaves notices transient without pause")
 var skipped: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(WorldState.SAVE_PATH))
 check(skipped.has_played and skipped.tutorial_choice_made and not skipped.tutorial_opted_in,"choice persists independently of level progress")
 WorldState.reset_progress()
 check(WorldState.has_played and not WorldState.tutorial_pauses_enabled(),"new adventure does not offer first-player tutorial again")
 hud.show_menu("intro");hud.begin_adventure()
 check(hud.starting and hud.submenu.is_empty(),"returning player starts without tutorial choice")
 world.queue_free();get_tree().paused=false
 await frames(2)
 world=fresh_world();hud=world.hud
 hud.begin_adventure();hud.buttons[0].pressed.emit()
 check(WorldState.tutorial_pauses_enabled() and hud.starting,"first player opting in enables tutorial pauses")
 await frames(100)
 check(hud.important_active and get_tree().paused and hud.important_key=="tip:PLANETA ALIENÍGENA","opted-in first gameplay pauses on movement tutorial")
 hud.important_age=.3;hud.dismiss_important_notice();hud._process(0)
 hud.notice("PONTO BRISA • Progresso salvo");hud._process(.3)
 check(hud.important_active and get_tree().paused,"opted-in milestone also pauses")
 hud.dismiss_important_notice();hud._process(0)
 var opted: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(WorldState.SAVE_PATH))
 WorldState.restore_progress(opted)
 hud.notice("CONECTANDO A COSTA…");hud._process(.1)
 check(WorldState.has_played and WorldState.tutorial_opted_in and not WorldState.tutorial_pauses_enabled() and not get_tree().paused and not hud.important_active,"later visit never resumes tutorial pauses even after opt-in")
 WorldState.reset_progress()
 check(WorldState.has_played and WorldState.tutorial_opted_in and not WorldState.tutorial_session_active,"reset keeps returning-player choice and inactive tutorial")
 WorldState.restore_progress({"checkpoint_id":"spawn"})
 check(WorldState.has_played and not WorldState.tutorial_choice_made and not WorldState.tutorial_pauses_enabled(),"legacy save does not invent an explicit tutorial decision")
 WorldState.restore_progress({"has_played":true,"tutorial_opted_in":false,"checkpoint_id":"brisa_01"})
 check(not WorldState.tutorial_choice_made,"version 25 save also requires a recorded explicit decision")
 hud.show_menu("intro");hud.begin_adventure(true)
 check(hud.submenu=="tutorial" and not hud.starting and get_tree().paused,"legacy player must decide before gameplay starts")
 hud.buttons[0].pressed.emit()
 check(WorldState.tutorial_choice_made and WorldState.tutorial_pauses_enabled() and hud.starting,"legacy player can explicitly opt in on first tutorial decision")
 var saved_choice: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(WorldState.SAVE_PATH))
 WorldState.restore_progress(saved_choice)
 check(WorldState.tutorial_choice_made and not WorldState.tutorial_session_active,"return visit remembers real choice without reactivating pauses")
 world.queue_free();get_tree().paused=false
 await frames(2)
 print("TUTORIAL_CHOICE: %d checks / %d failures"%[checks,failures])
 get_tree().quit(0 if failures==0 else 1)
