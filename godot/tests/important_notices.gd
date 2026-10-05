extends Node
var failures := 0
var passed := 0
var shown: Array[String] = []
func check(ok: bool, message: String) -> void:
 if ok: passed+=1; print("PASS: ",message)
 else: failures+=1; push_error(message)
func _ready() -> void:
 process_mode=Node.PROCESS_MODE_ALWAYS
 call_deferred("run")
func run() -> void:
 WorldState.reset_progress()
 WorldState.has_played=true
 WorldState.tutorial_choice_made=true
 WorldState.tutorial_opted_in=true
 WorldState.tutorial_session_active=true
 WorldState.seen_important_notices.append("tip:COSTA DOS VENTOS")
 var world=load("res://scenes/world_01/world_01.tscn").instantiate()
 add_child(world)
 var hud=world.hud
 hud.important_notice_shown.connect(func(key): shown.append(key))
 Audio.sounds["notice"]=load("res://assets/audio/notice.wav")
 WorldState.sfx_volume=.55
 WorldState.seen_important_notices.erase("tip:COSTA DOS VENTOS")
 hud.resume();hud._process(.1)
 check(hud.important_active and get_tree().paused and hud.important_key=="tip:COSTA DOS VENTOS","first movement tutorial pauses and requires acknowledgement")
 var escape:=InputEventAction.new()
 escape.action="pause_game";escape.pressed=true
 hud.important_age=.3;hud._unhandled_input(escape);hud._process(0)
 check(hud.important_active and get_tree().paused,"Escape does not bypass Entendi")
 hud.dismiss_important_notice();hud._process(0)
 check("tip:COSTA DOS VENTOS" in WorldState.seen_important_notices and not get_tree().paused,"Entendi saves tutorial acknowledgement and resumes")
 hud._process(.1)
 check(not hud.important_active,"acknowledged tutorial does not pause again")
 var node_position: Vector2=world.point(world.level.node)
 var original_position: Vector2=world.player.position
 world.player.position=node_position
 world.player.pulse_time=0
 hud.timer=0;hud._process(.1)
 check(hud.important_active and hud.important_key=="tip:NÓ DE SINAL" and get_tree().paused,"first contextual action also pauses with original instruction")
 hud.important_age=.3;hud.dismiss_important_notice();hud._process(0)
 WorldState.load_progress()
 check("tip:NÓ DE SINAL" in WorldState.seen_important_notices,"contextual acknowledgement survives loading saved progress")
 world.player.position=original_position
 WorldState.seen_important_notices.erase("tip:NÓ DE SINAL")
 shown.clear();hud.timer=0
 hud.notice("PONTO BRISA • Progresso salvo")
 hud.try_important_notice()
 check(hud.important_active and get_tree().paused and hud.important_layer.visible,"first milestone pauses gameplay and displays confirmation")
 check(not hud.toast_box.visible and not hud.context_hint.visible,"first notice owns the single message slot")
 check(get_viewport().gui_get_focus_owner()==hud.important_button,"keyboard and controller focus confirmation")
 check(hud.important_card.get_global_rect().position.y>=112 and not hud.important_card.get_global_rect().intersects(hud.player_screen_rect().grow(12)),"notice fits below HUD and clears character")
 var effects=Audio.get_children().filter(func(child): return child is AudioStreamPlayer and child.is_in_group("brisin_sfx"))
 check(effects.any(func(effect): return effect.playing and effect.stream.resource_path.ends_with("notice.wav")),"exclusive attention chime plays while scene is paused")
 var position: Vector2=world.player.position
 var elapsed: float=world.elapsed
 var cooldown: float=world.player.chip_cooldown
 hud.notice("PONTO BRISA • Progresso salvo")
 check(shown.size()==1 and hud.important_queue.is_empty(),"repeated event cannot stack notice or replay chime")
 hud.dismiss_important_notice()
 check(hud.important_active,"same-frame confirmation cannot accidentally dismiss notice")
 hud.show_menu("pause");hud.resume()
 check(hud.important_active and get_tree().paused and hud.menu_kind.is_empty(),"pause/resume cannot take ownership away from important notice")
 for i in 20: await get_tree().physics_frame
 check(world.player.position==position and world.elapsed==elapsed and world.player.chip_cooldown==cooldown,"player, elapsed time and cooldown freeze during reading")
 Input.action_press("jump");Input.action_press("chip")
 var event:=InputEventAction.new()
 event.action="ui_accept";event.pressed=true
 hud._unhandled_input(event)
 hud._process(0)
 check(not hud.important_active and not get_tree().paused and not Input.is_action_pressed("jump") and not Input.is_action_pressed("chip"),"confirmation resumes without leaking a jump or attack")
 var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(WorldState.SAVE_PATH))
 check("checkpoint" in WorldState.seen_important_notices and "checkpoint" in data.seen_important_notices,"acknowledged notice persists with progress")
 hud.notice("PONTO BRISA • Progresso salvo")
 check(not hud.important_active and not get_tree().paused and shown.size()==1,"later checkpoint remains a transient notice without pausing")
 hud.show_menu("pause")
 hud.notice("CONECTANDO A COSTA…")
 hud.notice("COSTA ONLINE • Ponte e portal ativados")
 check(not hud.important_active and hud.important_queue.size()==2 and get_tree().paused,"events behind a menu wait without replacing its pause")
 hud.resume();hud._process(.3)
 check(hud.important_active and hud.important_key=="connecting" and hud.important_title.text=="CONECTANDO A COSTA…","queued notices preserve their original text and order")
 hud.dismiss_important_notice();hud._process(.3)
 check(hud.important_active and hud.important_key=="online","next unseen milestone opens after acknowledging previous one")
 hud.dismiss_important_notice();hud._process(0)
 check(WorldState.seen_important_notices.size()==4 and shown.size()==3,"each milestone pauses once")
 hud.notice("Invencibilidade: true")
 check(not hud.important_active and not get_tree().paused,"debug message does not become important milestone")
 WorldState.reset_progress()
 WorldState.has_played=true
 WorldState.tutorial_choice_made=true
 WorldState.tutorial_opted_in=true
 WorldState.tutorial_session_active=true
 WorldState.seen_important_notices.append("tip:COSTA DOS VENTOS")
 check(WorldState.seen_important_notices==["tip:COSTA DOS VENTOS"],"new adventure clears acknowledgements")
 hud.notice("PONTO BRISA • Progresso salvo");hud._process(.3)
 check(hud.important_active and shown.size()==4,"new adventure can teach the first milestone again")
 hud.dismiss_important_notice()
 await get_tree().create_timer(.8).timeout
 WorldState.reset_progress()
 WorldState.has_played=true
 WorldState.tutorial_choice_made=true
 WorldState.tutorial_opted_in=true
 WorldState.tutorial_session_active=true
 WorldState.seen_important_notices.append("tip:COSTA DOS VENTOS")
 WorldState.sfx_volume=0.0
 var voice_count := Audio.get_child_count()
 hud.notice("PONTO BRISA • Progresso salvo");hud._process(.3)
 check(hud.important_active and Audio.get_child_count()==voice_count,"muted effects still pause for reading without creating sound")
 world.queue_free()
 await get_tree().process_frame
 await get_tree().process_frame
 check(not get_tree().paused and WorldState.seen_important_notices==["tip:COSTA DOS VENTOS"],"interrupted scene releases its pause without marking unread notice")
 # Dummy headless audio does not finish voices on fixed simulation time.
 for voice in Audio.get_children():
  if voice is AudioStreamPlayer and voice.is_in_group("brisin_sfx"):
   voice.stream_paused=false
   voice.stop()
   voice.stream=null
   voice.queue_free()
 Audio.sounds.clear()
 OS.delay_msec(100)
 await get_tree().process_frame
 await get_tree().process_frame
 print("IMPORTANT_NOTICES_RESULT: %d passed, %d failures"%[passed,failures])
 get_tree().quit(0 if failures==0 else 1)
