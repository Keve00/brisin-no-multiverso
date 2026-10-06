extends Node
var failures:=0
var checks:=0
func check(ok: bool, title: String) -> void:
 checks+=1
 if ok: print("PASS: ",title)
 else: failures+=1;push_error("FAIL: "+title)
func _ready() -> void:
 process_mode=Node.PROCESS_MODE_ALWAYS
 call_deferred("run")
func validate(hud: CanvasLayer, factor: float, page: String) -> void:
 hud.update_mobile_layout(factor)
 var valid:=true
 for button in hud.buttons:
  var rect: Rect2=button.get_global_rect()
  valid=valid and Rect2(Vector2.ZERO,Vector2(1152,648)).encloses(rect) and rect.size.y*factor>=48
  for other in hud.buttons:
   if other!=button: valid=valid and not rect.intersects(other.get_global_rect())
 for button in hud.buttons:
  var font: Font=button.get_theme_font("font")
  valid=valid and font.get_string_size(button.text,HORIZONTAL_ALIGNMENT_LEFT,-1,button.get_theme_font_size("font_size")).x<=button.size.x-24
 check(valid,page+" touch targets, bounds and spacing @ "+str(factor))
func run() -> void:
 WorldState.mobile_enabled=true
 WorldState.interrupted=false
 var world=load("res://scenes/world_01/world_01.tscn").instantiate()
 add_child(world)
 var hud=world.hud
 for factor in [0.42,0.48,0.67,1.0]:
  WorldState.fragments=[]
  hud.show_menu("intro");validate(hud,factor,"intro fresh")
  check(hud.title_hero.scale.x==hud.title_hero.scale.y and hud.title_platform.scale.x==hud.title_platform.scale.y,"menu artwork keeps uniform scale")
  WorldState.fragments=["f_0"]
  hud.show_menu("intro");validate(hud,factor,"intro continue")
  check(hud.buttons[0].size.x==hud.buttons[1].size.x and hud.buttons[2].position.y==hud.buttons[3].position.y and hud.buttons[2].get_rect().end.x<hud.buttons[3].position.x,"approved title hierarchy: two wide actions, two secondary actions")
  check(hud.title_platform.position+Vector2(100,64)*hud.title_platform.scale==hud.title_hero.position,"mobile menu feet stay on island contact pivot")
  check(hud.title_screen.get_node("TitleSubtitle").get_rect().end.y<hud.buttons[0].position.y,"subtitle leaves a gap before primary action")
  hud.offer_first_tutorial(false);validate(hud,factor,"tutorial choice")
  hud.show_menu("pause");validate(hud,factor,"pause")
  hud.settings();validate(hud,factor,"audio")
  check(hud.settings_sliders.all(func(slider):return slider.size.y*factor>=48),"audio sliders have touch-sized tracks")
  hud.mobile_settings();validate(hud,factor,"mobile")
  hud.mobile_advanced();validate(hud,factor,"advanced")
  hud.mobile_quality();validate(hud,factor,"visual")
  hud.mobile_layout_settings();validate(hud,factor,"layout")
 hud.show_menu("intro")
 WorldState.tutorial_choice_made=true
 hud.begin_adventure()
 await get_tree().process_frame
 WorldState.request_interruption("TESTE")
 await get_tree().process_frame
 await get_tree().process_frame
 var entry_frame: int=hud.title_hero.frame
 for i in 15: await get_tree().process_frame
 check(hud.starting and not hud.title_hero.is_playing() and entry_frame==hud.title_hero.frame,"interruption freezes finite title animation")
 hud.return_to_mobile_menu()
 check(hud.menu_kind=="intro" and not hud.starting and GameCommands.owners.is_empty(),"interruption can return to title without starting gameplay")
 world.queue_free();get_tree().paused=false
 await get_tree().process_frame
 print("MOBILE_UI: %d checks / %d failures" % [checks,failures])
 get_tree().quit(0 if failures==0 else 1)
