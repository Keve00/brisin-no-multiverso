extends Node
var checks:=0
var failures:=0
func check(ok: bool, message: String) -> void:
 checks+=1
 if ok: print("PASS: ",message)
 else: failures+=1;push_error("FAIL: "+message)
func _ready() -> void:
 process_mode=Node.PROCESS_MODE_ALWAYS
 call_deferred("run")
func fits(item: Label) -> bool:
 return item.get_line_count()*item.get_line_height(0)<=item.size.y and item.get_global_rect().end.x<=1128
func run() -> void:
 WorldState.mobile_enabled=true
 var world=load("res://scenes/world_01/world_01.tscn").instantiate()
 add_child(world)
 var hud=world.hud
 hud.resume()
 hud.set_process(false)
 for factor in [0.42,0.48,0.67,1.0]:
  hud.update_mobile_layout(factor)
  world.get_node("MobileControls").layout(factor)
  for state in ["OFFLINE","CONECTANDO","ONLINE"]:
   hud.objective.text="PLANETA • "+state
   hud.counter.text="00 / 49"
   await get_tree().process_frame
   check(fits(hud.objective) and hud.objective.get_theme_font("font").get_string_size(hud.objective.text,HORIZONTAL_ALIGNMENT_LEFT,-1,hud.objective.get_theme_font_size("font_size")).x<=hud.objective.size.x,"complete objective state @ "+str(factor)+" "+state)
  var detail: Label=hud.game_hud.get_node("ObjectiveDetail")
  check(detail.get_theme_font("font").get_string_size(detail.text,HORIZONTAL_ALIGNMENT_LEFT,-1,detail.get_theme_font_size("font_size")).x<=detail.size.x,"objective detail fits its panel @ "+str(factor))
  check(hud.objective.get_theme_font_size("font_size")*factor*0.625>=14 and hud.counter.get_theme_font_size("font_size")*factor*0.625>=16,"objective/count minimum CSS text sizes @ "+str(factor))
  var counter_icon: TextureRect=hud.game_hud.get_node("GemCounterIcon")
  check(counter_icon.get_global_rect().end.x<hud.counter.get_global_rect().position.x and hud.counter.get_global_rect().end.x<world.get_node("MobileControls").areas.pause.position.x,"gem/count/pause separate @ "+str(factor))
  for pair in [["ETZINHO ARMADO","PULSO • BLOQUEIE OS TIROS"],["CONEXÃO RESTABELECIDA","O CAMINHO PARA O PORTAL ESTÁ ABERTO"],["CORRENTE DE VENTO","PULE NA CORRENTE PARA GANHAR ALTURA"],["TRILHA DE SINAL","SALTE NO CABO CIANO PARA DESLIZAR"],["BRISIN","NÃO FOI POSSÍVEL SALVAR NESTE DISPOSITIVO"]]:
   for group in [[hud.context_title,hud.context_text,hud.context_hint],[hud.toast_title,hud.toast,hud.toast_box],[hud.important_title,hud.important_text,hud.important_card]]:
    group[0].text=pair[0]
    group[1].text=pair[1]
    hud.fit_mobile_notice(group[2],group[0],group[1])
    await get_tree().process_frame
    check(fits(group[0]) and fits(group[1]) and group[1].get_theme_font_size("font_size")*factor*0.625>=14,"long notice wraps within readable box @ "+str([factor,group[0].text,group[1].get_line_count(),group[1].get_line_height(0),group[1].size]))
  check(hud.important_button.get_theme_font("font").get_string_size(hud.important_button.text,HORIZONTAL_ALIGNMENT_LEFT,-1,hud.important_button.get_theme_font_size("font_size")).x<=hud.important_button.size.x-24 and hud.important_card.get_rect().end.y<=648,"tutorial card and confirmation fit @ "+str(factor))
 check(hud.context_title.position.x==hud.context_text.position.x and hud.context_text.position.y>=hud.context_title.get_rect().end.y and hud.context_title.horizontal_alignment==HORIZONTAL_ALIGNMENT_LEFT,"mobile notice columns align without overlapping")
 check(hud.mobile_tip("[E / B] PULSO • [F] SOLTA CHIPS")=="PULSO • CHIP LANÇA","mobile labels do not repeat action verbs")
 world.queue_free()
 await get_tree().process_frame
 print("MOBILE_HUD: %d checks / %d failures" % [checks,failures])
 get_tree().quit(0 if failures==0 else 1)
