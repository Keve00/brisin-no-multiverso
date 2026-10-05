extends Node
var failures := 0
var checks := 0
func check(value: bool, message: String) -> void:
 checks+=1
 if value: print("PASS: ",message)
 else:
  failures+=1
  push_error(message)
func _ready() -> void:
 process_mode=Node.PROCESS_MODE_ALWAYS
 call_deferred("run")
func frames(count: int) -> void:
 for i in count: await get_tree().process_frame
func run() -> void:
 WorldState.has_played=true
 WorldState.tutorial_choice_made=true
 WorldState.tutorial_session_active=false
 var world=load("res://scenes/world_01/world_01.tscn").instantiate()
 get_tree().root.add_child(world)
 get_tree().current_scene=world
 var hud=world.hud
 hud.show_menu("intro")
 await frames(2)
 check(hud.title_hero.animation=="wave" and hud.title_hero.sprite_frames.get_animation_loop("wave"),"title starts friendly looping wave")
 check(Audio._menu_active,"title owns menu music routing")
 var confirm := InputEventJoypadButton.new()
 confirm.button_index=JOY_BUTTON_A
 check(InputMap.action_has_event("ui_accept",confirm),"controller A confirms focused menu actions")
 check(hud.title_hero.sprite_frames.get_frame_texture("wave",0).get_size()==Vector2(176,160) and hud.title_hero.scale==Vector2(2.6,2.6) and hud.title_hero.offset==Vector2(0,-56),"SVG canvas and uniform scale preserve authored ground pivot")
 check(hud.title_platform.texture.resource_path.ends_with("platforms/coastal_0.svg") and hud.title_platform.scale==Vector2.ONE*2.4,"menu reuses approved coastal SVG at uniform source scale")
 check(hud.title_platform.position+Vector2(100,64)*hud.title_platform.scale==hud.title_hero.position,"menu feet share the platform's documented contact pivot")
 check(hud.title_screen.has_node("BrisinMenuPanorama") and hud.title_screen.get_node("BrisinMenuPanorama").process_mode==Node.PROCESS_MODE_ALWAYS,"menu shares animated SVG panorama while gameplay is paused")
 check(hud.title_gems.size()==5 and hud.title_gems.all(func(gem): return gem.texture.resource_path.ends_with("gem_orange.svg") and gem.modulate.a==1.0),"menu uses five opaque approved gems")
 var sizes: Dictionary={}
 for gem in hud.title_gems:
  sizes[snappedf(gem.scale.x,.01)]=true
 check(sizes.size()==5 and hud.title_gems.all(func(gem): return is_equal_approx(gem.scale.x,gem.scale.y)),"menu gems have five distinct sizes with uniform proportions")
 var ornaments= hud.title_screen.get_children().filter(func(child): return child is TextureRect and child.texture.resource_path.ends_with("wind.svg"))
 check(ornaments.is_empty(),"yellow stepped wind ornament is removed from title")
 var gem_position: Vector2=hud.title_gems[0].position
 hud.update_title_gems(1.0)
 check(hud.title_gems[0].position!=gem_position and get_tree().paused,"decorative gems orbit while gameplay remains paused")
 var orbit_phase:float=hud.title_gem_phase
 var reduced_before:bool=WorldState.reduced_flash
 WorldState.reduced_flash=not reduced_before
 hud.update_title_gems(0.0)
 check(is_equal_approx(hud.title_gem_phase,orbit_phase),"changing reduced flashes preserves the current orbital phase")
 WorldState.reduced_flash=reduced_before
 var position: Vector2=world.player.position
 WorldState.checkpoint_id="brisa_01"
 WorldState.fragments=["f_0"]
 hud.show_menu("intro")
 hud.buttons[0].pressed.emit()
 check(hud.starting and hud.start_stage=="ready" and hud.title_hero.animation=="ready_to_run" and get_tree().paused,"start/continue plays readiness while world remains paused")
 check(hud.buttons.all(func(button): return button.disabled and button.focus_mode==Control.FOCUS_NONE),"all title controls lock during the finite handoff")
 hud.begin_adventure(true)
 hud.settings()
 hud.controls()
 hud.show_menu("pause")
 hud.resume()
 var event:=InputEventAction.new()
 event.action="pause_game";event.pressed=true
 hud._unhandled_input(event)
 check(not hud.start_new_adventure and hud.menu_kind=="intro" and hud.submenu.is_empty() and get_tree().paused,"repeated clicks, submenus and Escape cannot restart or skip readiness")
 var limit:=Time.get_ticks_msec()+4000
 while hud.start_stage=="ready" and Time.get_ticks_msec()<limit: await frames(1)
 check(hud.start_stage=="run" and hud.title_hero.animation=="run_start" and get_tree().paused,"finite readiness automatically hands over to running pose")
 check(world.player.position==position,"menu animation never moves the actual gameplay character")
 while hud.starting and Time.get_ticks_msec()<limit: await frames(1)
 check(not hud.starting and not get_tree().paused and hud.game_hud.visible and not hud.title_screen.visible,"running pose finishes before a single gameplay handoff")
 check(not Audio._menu_active,"gameplay music resumes only after the title handoff")
 check(WorldState.checkpoint_id=="brisa_01" and WorldState.fragments==["f_0"],"continue preserves checkpoint and collected fragments")
 hud.show_menu("pause")
 hud.buttons[0].pressed.emit()
 check(not get_tree().paused and not hud.starting,"pause continue stays immediate")
 hud.show_menu("intro")
 hud.settings();hud.back_menu()
 check(hud.title_hero.animation=="wave" and hud.title_screen.modulate.a==1 and not hud.starting,"returning from title settings rebuilds the wave without a stale transition")
 var gem_nodes:=0
 for child in hud.title_screen.get_children():
  if child.name.begins_with("BrisinMenuGem"): gem_nodes+=1
 check(gem_nodes==5 and hud.title_gems.size()==5,"returning from settings replaces gems without duplicates")
 # Runner is a persistent root sibling, so this exercises the real scene reload.
 hud.begin_adventure(true)
 check(hud.start_new_adventure and get_tree().paused,"new adventure also enters the animated preparation")
 var before=world
 limit=Time.get_ticks_msec()+4000
 while (get_tree().current_scene==before or get_tree().current_scene==null) and Time.get_ticks_msec()<limit: await frames(1)
 world=get_tree().current_scene
 check(world!=before and not WorldState.skip_intro_once and not get_tree().paused and world.hud.game_hud.visible and not world.hud.title_screen.visible,"real new-adventure reload consumes intro bypass exactly once")
 check(not Audio._menu_active,"new-adventure reload cannot retain menu music")
 check(WorldState.checkpoint_id=="spawn" and WorldState.fragments.is_empty() and world.player.position.distance_to(WorldState.checkpoint)<10,"new adventure enters the fresh spawn with progress reset")
 world.hud.show_menu("intro")
 check(world.hud.title_hero.animation=="wave" and get_tree().paused,"later title openings still show the greeting")
 get_tree().paused=false
 print("MENU ANIMATION: ",checks," checked / ",failures," failed")
 get_tree().quit(0 if failures==0 else 1)
