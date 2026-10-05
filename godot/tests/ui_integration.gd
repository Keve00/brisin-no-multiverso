extends Node
var passed: Array[String]=[]
var failed: Array[String]=[]
var world: Node2D
var hud: CanvasLayer
var original_save: String
var save_existed: bool
func check(value: bool, title: String) -> void:
 if value: passed.append(title);print("PASS: ",title)
 else: failed.append(title);push_error("FAIL: "+title)
func _ready() -> void:
 call_deferred("run")
func escape() -> void:
 var event:=InputEventAction.new()
 event.action="pause_game"
 event.pressed=true
 hud._unhandled_input(event)
func visible_bounds(node: Node) -> bool:
 if node is Control and node.is_visible_in_tree():
  var r:Rect2=node.get_global_rect()
  if r.position.x < -1 or r.position.y < -1 or r.end.x >1153 or r.end.y >649:
   push_error("OUTSIDE UI "+str(node.get_path())+" "+str(r));return false
 for child in node.get_children():
  if not visible_bounds(child): return false
 return true
func glyphs_valid(node: Node) -> bool:
 if node is Label or node is Button:
  var font:Font=node.get_theme_font("font")
  for c in node.text:
   if c!="\n" and not font.has_char(c.unicode_at(0)): push_error("MISSING GLYPH "+c);return false
 for child in node.get_children():
  if not glyphs_valid(child): return false
 return true
func text_fits(node: Node) -> bool:
 if node is Label and node.is_visible_in_tree():
  var font:Font=node.get_theme_font("font")
  var size:int=node.get_theme_font_size("font_size")
  for line in node.text.split("\n"):
   if font.get_string_size(line,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x>node.size.x+1:
    push_error("TEXT OVERFLOW "+line+" "+str(node.size));return false
 for child in node.get_children():
  if not text_fits(child): return false
 return true
func run() -> void:
 WorldState.has_played=true
 WorldState.tutorial_choice_made=true
 WorldState.tutorial_session_active=false
 # Exercise already acknowledged transient notices; first-read lifecycle has its own suite.
 WorldState.seen_important_notices=["checkpoint", "connecting", "online", "tip:COSTA DOS VENTOS", "tip:NÓ DE SINAL", "tip:RUÍDOZINHO", "tip:LANÇAR CHIP", "tip:TRILHA DE SINAL/rail_enter", "tip:TRILHA DE SINAL/rail_exit", "tip:CORRENTE DE VENTO", "tip:PEDRA RACHADA", "tip:DASH DE SINAL", "tip:COSTA RECONECTADA"]
 save_existed=FileAccess.file_exists(WorldState.SAVE_PATH)
 if save_existed: original_save=FileAccess.get_file_as_string(WorldState.SAVE_PATH)
 var music:float=WorldState.music_volume
 var sfx:float=WorldState.sfx_volume
 var reduced:bool=WorldState.reduced_flash
 world=load("res://scenes/world_01/world_01.tscn").instantiate()
 add_child(world)
 hud=world.hud
 hud.show_menu("intro")
 await get_tree().process_frame
 var menu_logo: TextureRect
 var menu_subtitle: Label
 for item in hud.title_screen.get_children():
  if item is TextureRect and item.texture.resource_path.ends_with("/logo.svg"): menu_logo=item
  if item is Label and item.text=="COSTA DOS VENTOS CONECTADOS": menu_subtitle=item
 check(menu_logo.size==Vector2(432,204) and menu_subtitle.position.y-menu_logo.get_rect().end.y>=8,"actual logo bounds leave at least 8 px before subtitle")
 check(hud.buttons[0].position.y-menu_subtitle.get_rect().end.y>=4,"subtitle keeps its own space before the primary action")
 check(hud.counter.horizontal_alignment==HORIZONTAL_ALIGNMENT_CENTER and hud.counter.position==Vector2(951,24),"gem count centers visible bitmap ink in the useful area beside its icon")
 check(hud.context_title.horizontal_alignment==HORIZONTAL_ALIGNMENT_CENTER and hud.context_text.horizontal_alignment==HORIZONTAL_ALIGNMENT_CENTER and hud.toast_title.horizontal_alignment==HORIZONTAL_ALIGNMENT_CENTER and hud.toast.horizontal_alignment==HORIZONTAL_ALIGNMENT_CENTER,"context and event labels use centered alignment consistently")
 check(hud.context_title.position==hud.toast_title.position and hud.context_text.position==hud.toast.position and hud.context_title.size==Vector2(436,32),"tips and notices share safe text columns and pixel optical offsets")
 check(get_tree().paused and hud.title_screen.visible and not hud.panel.visible,"intro pauses gameplay with fullscreen title")
 check(hud.buttons.size()==3 and hud.buttons[0].text=="COMEÇAR AVENTURA","fresh adventure has start/settings/controls without false continue")
 check(get_viewport().gui_get_focus_owner()==hud.buttons[0],"intro initial keyboard/gamepad focus is start")
 check(hud.buttons[0].focus_neighbor_top==hud.buttons[-1].get_path(),"menu keyboard/gamepad focus wraps deterministically")
 var down:=InputEventKey.new()
 down.keycode=KEY_DOWN
 down.pressed=true
 get_viewport().push_input(down)
 await get_tree().process_frame
 check(get_viewport().gui_get_focus_owner()==hud.buttons[1],"keyboard arrow moves focus to next title action")
 down.pressed=false
 get_viewport().push_input(down)
 var pad:=InputEventJoypadButton.new()
 pad.button_index=JOY_BUTTON_DPAD_DOWN
 pad.pressed=true
 get_viewport().push_input(pad)
 await get_tree().process_frame
 check(get_viewport().gui_get_focus_owner()==hud.buttons[2],"controller D-pad moves focus to controls action")
 pad.pressed=false
 get_viewport().push_input(pad)

 check(visible_bounds(hud.root) and text_fits(hud.root),"intro fits logical safe area with readable text")
 WorldState.checkpoint_id="brisa_01"
 hud.show_menu("intro")
 check(hud.buttons.size()==4 and hud.buttons[0].text=="CONTINUAR" and hud.buttons[1].text=="NOVA AVENTURA","saved progress offers continue and explicit new adventure")
 check(visible_bounds(hud.root) and text_fits(hud.root),"saved-progress title fits safe area")
 hud.settings()
 check(hud.submenu=="settings" and get_tree().paused,"settings keeps world paused")
 check(get_viewport().gui_get_focus_owner()==hud.settings_sliders[0],"settings focuses music slider and links controller navigation")
 hud.settings_sliders[0].value=0.7
 hud.settings_sliders[1].value=0.2
 hud.flash_check.button_pressed=not reduced
 var save:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(WorldState.SAVE_PATH))
 check(is_equal_approx(WorldState.music_volume,0.7) and is_equal_approx(WorldState.sfx_volume,0.2) and is_equal_approx(float(save.music),0.7) and is_equal_approx(float(save.sfx),0.2) and save.reduced_flash==not reduced and save.checkpoint_id=="brisa_01","settings persist both volumes/reduced flash without losing checkpoint")
 check(visible_bounds(hud.root) and text_fits(hud.root),"settings controls fit safe area")
 escape()
 check(hud.menu_kind=="intro" and hud.submenu.is_empty() and get_tree().paused and hud.title_screen.visible,"Escape from title settings returns to title")
 hud.controls()
 check(hud.submenu=="controls" and glyphs_valid(hud.root) and text_fits(hud.root),"controls have valid accented glyphs and readable instructions")
 escape()
 check(hud.menu_kind=="intro" and get_tree().paused,"Escape from title controls returns to title")
 hud.resume()
 check(not get_tree().paused and not hud.panel.visible and not hud.title_screen.visible and hud.game_hud.visible,"start/continue resumes gameplay and shows HUD")
 escape()
 check(hud.menu_kind=="pause" and hud.panel.visible and get_tree().paused,"Escape opens pause menu")
 hud.settings();escape()
 check(hud.menu_kind=="pause" and hud.panel.visible and get_tree().paused,"Escape from paused settings preserves pause parent")
 hud.controls();escape()
 check(hud.menu_kind=="pause" and get_tree().paused,"Escape from paused controls preserves pause parent")
 check(visible_bounds(hud.root) and text_fits(hud.root),"pause menu fits safe area")
 hud.notice("PONTO BRISA • Progresso salvo")
 var remaining:float=hud.timer
 hud._process(0.5)
 check(hud.timer==remaining and hud.toast_state=="checkpoint","checkpoint notice timer freezes during pause")
 hud.resume();hud._process(0.3)
 check(hud.timer<remaining and hud.toast_title.text=="CHECKPOINT ATIVADO" and hud.toast_box.modulate.a==1,"checkpoint notice enters and receives reading duration during play")
 hud.notice("CONECTANDO A COSTA…");hud._process(0.3)
 check(hud.toast_state=="connecting" and hud.toast_icon.texture.resource_path.ends_with("signal.svg"),"connecting notice carries distinct label and signal icon")
 WorldState.reduced_flash=true
 hud._process(0.1)
 check(hud.toast_icon.modulate.a==1,"reduced flashes disables connection opacity pulse")
 hud.notice("COSTA ONLINE • Ponte e portal ativados");hud._process(0.3)
 check(hud.toast_state=="online" and hud.toast_title.text=="CONEXÃO RESTABELECIDA","online notice communicates activated route")
 check(hud.toast_box.get_global_rect().end.y<208 and visible_bounds(hud.root),"notice stays above gameplay region and visible HUD remains within viewport")
 hud._process(4)
 check(not hud.toast_box.visible,"notice exits after full lifetime")
 var player_position:Vector2=world.player.position
 var node_position:=Vector2(world.level.node[0],world.level.node[1])
 WorldState.connection=WorldState.Connection.OFFLINE
 world.player.position=node_position
 world.player.camera.reset_smoothing()
 world.player.camera.force_update_scroll()
 hud._process(0)
 check(hud.context_hint.visible and not hud.context_hint.get_global_rect().intersects(hud.player_screen_rect().grow(12)),"grounded node prompt stays below HUD and clear of player")
 world.player.position=node_position+Vector2(0,-80)
 world.player.camera.reset_smoothing()
 world.player.camera.force_update_scroll()
 hud._process(0)
 check(hud.context_hint.visible and not hud.context_hint.get_global_rect().intersects(hud.player_screen_rect().grow(12)),"jumping near node keeps prompt below HUD and clear of player")
 hud.notice("CONECTANDO A COSTA…")
 hud._process(0.3)
 check(not hud.toast_box.visible or not hud.toast_box.get_global_rect().intersects(hud.player_screen_rect().grow(12)),"notice repositions or holds when player occupies its area")
 world.player.position=player_position
 world.player.camera.reset_smoothing()
 world.player.camera.force_update_scroll()
 var invulnerability:float=world.player.invulnerability
 var flash_flag:bool=WorldState.reduced_flash
 WorldState.reduced_flash=true
 world.player.invulnerability=1.1
 world.player.animate(0)
 var first_alpha:float=world.player.visual.modulate.a
 world.player.invulnerability=0.9
 world.player.animate(0)
 check(is_equal_approx(first_alpha,0.65) and is_equal_approx(world.player.visual.modulate.a,0.65),"reduced flashes keeps invulnerability feedback stable across blink phases")
 world.player.invulnerability=0
 world.player.animate(0)
 check(world.player.visual.modulate.a==1,"invulnerability ending restores player full opacity")
 world.player.invulnerability=invulnerability
 WorldState.reduced_flash=flash_flag
 world.player.animate(0)

 WorldState.fragments=["f_0"]
 WorldState.completed=true
 WorldState.connection=WorldState.Connection.ONLINE
 world.elapsed=125
 world.deaths=3
 hud.conclusion()
 check(hud.menu_kind=="end" and get_tree().paused and hud.buttons[0].text=="JOGAR NOVAMENTE","completion offers replay and pauses gameplay")
 hud._process(0.1)
 var portal_frame:TextureRect=hud.panel_box.get_node("PortalFrame")
 check(hud.portal_icon.pivot_offset==Vector2(32,32) and hud.portal_icon.size==Vector2(64,64) and portal_frame.size==hud.portal_icon.size and portal_frame.position==hud.portal_icon.position and hud.portal_icon.scale==Vector2.ONE and portal_frame.rotation==0,"portal core rotates around shared center within fixed proportional frame")

 check(glyphs_valid(hud.root) and text_fits(hud.root) and visible_bounds(hud.root),"completion statistics are readable and inside safe area")
 hud.reset_adventure()
 check(WorldState.checkpoint_id=="spawn" and WorldState.fragments.is_empty() and not WorldState.completed and WorldState.connection==WorldState.Connection.OFFLINE and not get_tree().paused,"replay resets progress and resumes before scene reload")
 check(hud.ui_font.has_char("Ç".unicode_at(0)) and hud.ui_font.has_char("Ã".unicode_at(0)) and glyphs_valid(hud.root),"bitmap font includes Portuguese accents and all active UI glyphs")
 WorldState.music_volume=music
 WorldState.sfx_volume=sfx
 WorldState.reduced_flash=reduced
 if save_existed:
  var file:=FileAccess.open(WorldState.SAVE_PATH,FileAccess.WRITE)
  file.store_string(original_save)
 else: DirAccess.remove_absolute(ProjectSettings.globalize_path(WorldState.SAVE_PATH))
 get_tree().paused=false
 print("UI RESULT: ",passed.size()," passed / ",failed.size()," failed")
 get_tree().quit(0 if failed.is_empty() else 1)
