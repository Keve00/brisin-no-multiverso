extends CanvasLayer
# Logical UI coordinates stay within 1152×648; texture helpers always preserve aspect.
const UI := "res://assets/ui/"
const MOBILE_FONT = preload("res://assets/ui/mobile/brisin_mobile_bold.fnt")
const CREAM := Color("fff3cd")
const AMBER := Color("ffb000")
const YELLOW := Color("ffd84d")
var world: Node2D
var root: Control
var game_hud: Control
var objective: Label
var counter: Label
var dash_counter: Label
var debug: Label
var toast: Label
var toast_title: Label
var toast_icon: TextureRect
var toast_box: Control
var panel: Control
var panel_box: Control
var title_screen: Control
const MENU_GEM_CENTER := Vector2(866,346)
const MENU_GEM_RADIUS := Vector2(186,174)
const MENU_GEM_COUNT := 5
const MENU_GEM_SCALES := [1.05, 1.65, 1.25, 1.85, 1.4]
var title_gems: Array[Sprite2D] = []
var title_gem_clock := 0.0
var title_gem_phase := 0.0
var title_platform: Sprite2D
var title_hero: AnimatedSprite2D
var starting := false
var start_stage := ""
var start_elapsed := 0.0
var start_new_adventure := false
var tutorial_new_adventure := false
var ready_for_wave_frames: Array = []
var portal_icon: TextureRect
var context_hint: Control
var context_title: Label
var context_text: Label
var context_icon: TextureRect
var context_key := ""
var context_read_time: Dictionary = {}
const CONTEXT_LIFETIME := 4.5
var timer := 0.0
var menu_kind := ""
var submenu := ""
var clock := 0.0
var toast_state := "checkpoint"
var important_layer: Control
var important_card: Control
var important_title: Label
var important_text: Label
var important_icon: TextureRect
var important_button: Button
var important_active := false
var important_key := ""
var important_age := 0.0
var important_resume_pending := false
var important_queue: Array[Dictionary] = []
signal important_notice_shown(key: String)
var ui_font: Font
var buttons: Array[Button] = []
var settings_sliders: Array[HSlider] = []
var menu_request := 0
var interruption_layer: Control
var interruption_text: Label
var pause_button: Button
var mobile_layout_key := ""
var flash_check: CheckButton
func _ready() -> void:
 process_mode = Node.PROCESS_MODE_ALWAYS
 layer = 20
 ui_font = load(UI+"brisin_pixel.fnt")
 root = Control.new()
 root.name = "BrisinInterface"
 root.size = Vector2(1152,648)
 root.mouse_filter = Control.MOUSE_FILTER_IGNORE
 root.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
 add_child(root)
 build_hud()
 title_screen = Control.new()
 title_screen.size = root.size
 root.add_child(title_screen)
 title_screen.hide()
 panel = Control.new()
 panel.position = Vector2(296,64)
 panel.size = Vector2(560,520)
 root.add_child(panel)
 texture(panel,"menu_panel",Vector2.ZERO,panel.size)
 panel_box = Control.new()
 panel_box.position = Vector2(40,28)
 panel_box.size = Vector2(480,464)
 panel.add_child(panel_box)
 panel.hide()
 build_important_notice()
 build_interruption()
 WorldState.save_failed.connect(func(): notice("NÃO FOI POSSÍVEL SALVAR NESTE DISPOSITIVO"))
 if WorldState.skip_intro_once:
  WorldState.skip_intro_once=false
  resume()
 elif not "--test" in OS.get_cmdline_user_args(): show_menu("intro")
func texture(parent: Node, asset: String, pos: Vector2, bounds: Vector2) -> TextureRect:
 var image := TextureRect.new()
 image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
 image.texture = load(UI+asset+".svg")
 image.position = pos
 image.size = bounds
 image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 image.mouse_filter = Control.MOUSE_FILTER_IGNORE
 parent.add_child(image)
 return image
func label(parent: Node, value: String, pos: Vector2, bounds: Vector2, font_size: int = 24, centered: bool = false) -> Label:
 var item := Label.new()
 item.text = value
 item.position = pos
 item.size = bounds
 item.add_theme_font_override("font",ui_font)
 item.add_theme_font_size_override("font_size",font_size)
 item.add_theme_color_override("font_color",CREAM)
 item.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if centered else HORIZONTAL_ALIGNMENT_LEFT
 item.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
 item.mouse_filter = Control.MOUSE_FILTER_IGNORE
 parent.add_child(item)
 return item
func centered_pixel_label(parent: Node, value: String, pos: Vector2, bounds: Vector2, font_size: int = 24) -> Label:
 # Atlas ink occupies rows 3..9 of a 12 px line and leaves 1 px trailing advance.
 # Center the visible ink in the useful rectangle, not just the font's line box.
 var optical := roundf(float(font_size)/24.0)
 return label(parent,value,pos+Vector2(optical,-optical),bounds,font_size,true)
func style(asset: String) -> StyleBoxTexture:
 var box := StyleBoxTexture.new()
 box.texture = load(UI+asset+".svg")
 # Nine-slice applies only to modular UI frames, never to characters or world art.
 for side in [SIDE_LEFT,SIDE_TOP,SIDE_RIGHT,SIDE_BOTTOM]:
  box.set_texture_margin(side,12)
  box.set_content_margin(side,12)
 return box
func add_button(parent: Node, title: String, pos: Vector2, callback: Callable, bounds: Vector2 = Vector2(360,60)) -> Button:
 if WorldState.mobile_enabled and bounds == Vector2(360,60):
  bounds = Vector2(420,maxf(88,ceilf(48.0/WorldState.mobile_css_scale())))
  pos.x -= 30
 var btn := Button.new()
 btn.text = title
 btn.position = pos
 btn.size = bounds
 btn.add_theme_font_override("font",ui_font)
 btn.add_theme_font_size_override("font_size",36 if WorldState.mobile_enabled else 24)
 for state in ["normal","hover","pressed","focus"]:
  btn.add_theme_stylebox_override(state,style("button_pressed" if state=="pressed" else ("button_focus" if state in ["hover","focus"] else "button")))
 for state in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]: btn.add_theme_color_override(state,CREAM)
 btn.pressed.connect(callback)
 parent.add_child(btn)
 var arrow := texture(btn,"focus_arrow",Vector2(16,22),Vector2(16,16))
 arrow.name="FocusArrow"
 arrow.hide()
 btn.focus_entered.connect(func(): arrow.show())
 btn.focus_exited.connect(func(): arrow.hide())
 buttons.append(btn)
 return btn
func focus_buttons() -> void:
 if buttons.is_empty(): return
 # Explicit wrapping makes keyboard and controller navigation deterministic.
 for i in buttons.size():
  buttons[i].focus_neighbor_top = buttons[(i-1+buttons.size())%buttons.size()].get_path()
  buttons[i].focus_neighbor_bottom = buttons[(i+1)%buttons.size()].get_path()
 buttons[0].grab_focus()
func build_hud() -> void:
 game_hud = Control.new()
 game_hud.size = Vector2(1152,648)
 game_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
 root.add_child(game_hud)
 texture(game_hud,"objective_frame",Vector2(24,20),Vector2(360,72)).name="ObjectiveFrame"
 texture(game_hud,"signal",Vector2(40,40),Vector2(24,24)).name="ObjectiveSignal"
 objective = label(game_hud,"PLANETA • OFFLINE",Vector2(80,24),Vector2(288,28),24)
 label(game_hud,"RESTABELEÇA O NÓ DE SINAL",Vector2(80,54),Vector2(288,20),12).name="ObjectiveDetail"
 texture(game_hud,"counter_frame",Vector2(906,20),Vector2(160,54)).name="GemCounterFrame"
 texture(game_hud,"diamond",Vector2(918,31),Vector2(24,24)).name="GemCounterIcon"
 counter = centered_pixel_label(game_hud,"00/00",Vector2(950,25),Vector2(96,36),24)
 texture(game_hud,"bolt",Vector2(968,80),Vector2(24,24)).name="DashIcon"
 dash_counter = label(game_hud,"DASH PRONTO",Vector2(998,76),Vector2(132,28),12)
 var pause := Button.new()
 pause_button = pause
 pause.position=Vector2(1072,20)
 pause.size=Vector2(56,54)
 pause.tooltip_text="PAUSA • ESC / START"
 for state in ["normal","hover","pressed","focus"]: pause.add_theme_stylebox_override(state,style("button_focus" if state in ["hover","focus"] else "button"))
 pause.pressed.connect(func(): show_menu("pause"))
 game_hud.add_child(pause)
 texture(pause,"pause",Vector2(16,14),Vector2(24,24))
 toast_box=Control.new()
 toast_box.position=Vector2(316,112)
 toast_box.size=Vector2(520,84)
 toast_box.mouse_filter=Control.MOUSE_FILTER_IGNORE
 game_hud.add_child(toast_box)
 texture(toast_box,"toast_frame",Vector2.ZERO,toast_box.size)
 toast_icon=texture(toast_box,"flag",Vector2(22,26),Vector2(24,24))
 toast_title=centered_pixel_label(toast_box,"",Vector2(60,9),Vector2(436,32),24)
 toast=centered_pixel_label(toast_box,"",Vector2(60,41),Vector2(436,28),12)
 toast_box.hide()
 context_hint=Control.new()
 context_hint.position=Vector2(316,112)
 context_hint.size=Vector2(520,84)
 context_hint.mouse_filter=Control.MOUSE_FILTER_IGNORE
 game_hud.add_child(context_hint)
 texture(context_hint,"toast_frame",Vector2.ZERO,context_hint.size)
 context_icon=texture(context_hint,"signal",Vector2(22,26),Vector2(24,24))
 context_title=centered_pixel_label(context_hint,"",Vector2(60,9),Vector2(436,32),24)
 context_title.add_theme_color_override("font_color",YELLOW)
 context_text=centered_pixel_label(context_hint,"",Vector2(60,41),Vector2(436,28),12)
 context_hint.hide()
 debug=label(game_hud,"",Vector2(24,610),Vector2(1104,24),12)
func clear_menu() -> void:
 for child in panel_box.get_children():
  panel_box.remove_child(child)
  child.queue_free()
 buttons.clear()
 settings_sliders.clear()
 flash_check=null
 portal_icon=null
func has_progress() -> bool:
 return WorldState.checkpoint_id!="spawn" or not WorldState.fragments.is_empty() or WorldState.completed or WorldState.connection==WorldState.Connection.ONLINE
func show_menu(kind: String) -> void:
 if important_active or starting or (is_instance_valid(world) and bool(world.get("portal_transition_active"))): return
 GameCommands.clear()
 menu_kind=kind
 Audio.set_menu_active(true)
 submenu=""
 get_tree().paused=true
 game_hud.hide()
 clear_menu()
 if kind=="intro":
  panel.hide()
  build_title()
 else:
  title_screen.hide()
  panel.show()
  label(panel_box,"PAUSA",Vector2(0,4),Vector2(480,44),36,true)
  label(panel_box,"O PLANETA ESPERA POR VOCÊ",Vector2(0,52),Vector2(480,28),12,true)
  add_button(panel_box,"CONTINUAR",Vector2(60,98),resume)
  add_button(panel_box,"RECOMEÇAR",Vector2(60,174),restart)
  add_button(panel_box,"CONFIGURAÇÕES",Vector2(60,250),settings)
  add_button(panel_box,"CONTROLES",Vector2(60,326),controls)
  label(panel_box,"ESC / START • VOLTAR AO JOGO",Vector2(0,416),Vector2(480,24),12,true).name="PauseHint"
 focus_buttons()
func build_title() -> void:
 title_gems.clear()
 title_gem_clock=0.0
 title_gem_phase=0.0
 for child in title_screen.get_children():
  title_screen.remove_child(child)
  child.queue_free()
 title_screen.show()
 title_screen.modulate=Color.WHITE
 # Reuse the actual layered panorama instead of the legacy raster menu backdrop.
 var background := Node2D.new()
 background.set_script(load("res://scripts/systems/background_svg.gd"))
 background.name="BrisinMenuPanorama"
 background.atmosphere_strength=0.0
 background.process_mode=Node.PROCESS_MODE_ALWAYS
 title_screen.add_child(background)
 var shade := ColorRect.new()
 shade.color=Color(0.07,0.025,0.005,0.0)
 shade.size=Vector2(1152,648)
 shade.mouse_filter=Control.MOUSE_FILTER_IGNORE
 title_screen.add_child(shade)
 texture(title_screen,"cosmic_logo",Vector2(150,24),Vector2(432,204)).name="TitleLogo"
 label(title_screen,"CONEXÃO DE OUTRO MUNDO",Vector2(84,236),Vector2(564,32),28,true).name="TitleSubtitle"
 # Approved coastal platform, original canvas 200×176 / contact pivot (100,64).
 # Its 2× uniform scale places ground at y=456 and shares the avatar's logical pixels.
 title_platform=Sprite2D.new()
 title_platform.name="BrisinMenuCosmicPlatform"
 title_platform.texture=load("res://assets/world_01/platforms/cosmic_menu.svg")
 title_platform.centered=false
 title_platform.z_index=1
 title_platform.position=Vector2(662,302.4)
 title_platform.scale=Vector2.ONE*2.4
 title_platform.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
 title_screen.add_child(title_platform)
 # SVG textures are advanced by AnimatedSprite2D (SMIL/CSS is not used by Godot).
 # Full-resolution source silhouette: 176×160 with padded pivot(88,136).
 # Uniform2× preserves source detail and the same physical display size.
 title_hero=AnimatedSprite2D.new()
 title_hero.name="BrisinMenuAvatar"
 title_hero.z_index=2
 title_hero.sprite_frames=load("res://assets/player/menu_svg/spriteframes.tres")
 var animation_meta=JSON.parse_string(FileAccess.get_file_as_string("res://assets/player/menu_svg/animations.json"))
 ready_for_wave_frames=animation_meta.get("ready_for_wave_frames",[]) if animation_meta is Dictionary else []
 title_hero.position=Vector2(902,456)
 title_hero.scale=Vector2.ONE*2.6
 title_hero.offset=Vector2(0,-56)
 title_hero.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
 title_hero.process_mode=Node.PROCESS_MODE_ALWAYS
 title_screen.add_child(title_hero)
 title_hero.animation_finished.connect(_on_title_animation_finished)
 title_hero.play("wave")
 var y:=272.0
 title_screen.move_child(title_hero,title_screen.get_child_count()-1)
 build_title_gems()
 add_button(title_screen,"CONTINUAR" if has_progress() else "COMEÇAR AVENTURA",Vector2(112,y),begin_adventure)
 if has_progress():
  y+=100 if WorldState.mobile_enabled else 80
  add_button(title_screen,"NOVA AVENTURA",Vector2(112,y),func(): begin_adventure(true))
 y+=100 if WorldState.mobile_enabled else 80
 add_button(title_screen,"CONFIGURAÇÕES",Vector2(112,y),settings)
 y+=100 if WorldState.mobile_enabled else 80
 add_button(title_screen,"CONTROLES",Vector2(112,y),controls)
 if WorldState.mobile_enabled:
  update_mobile_layout()
func build_title_gems() -> void:
 # Reuse the orange faceted gameplay gem; the body is always opaque.
 # The ellipse wraps the avatar outside the face/hand and away from menu labels.
 for index in MENU_GEM_COUNT:
  var gem := Sprite2D.new()
  gem.name="BrisinMenuGem%02d" % index
  gem.texture=load("res://assets/world_01/svg/gem_orange.svg")
  gem.scale=Vector2.ONE*MENU_GEM_SCALES[index]
  gem.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
  var glow := Sprite2D.new()
  glow.name="GemHalo"
  glow.texture=load("res://assets/world_01/svg/gem_glow.svg")
  glow.z_index=-1
  gem.add_child(glow)
  title_screen.add_child(gem)
  title_gems.append(gem)
 update_title_gems(0.0)
func update_title_gems(dt: float) -> void:
 # Independent menu clock keeps re-opened greetings deterministic and never
 # changes the finite readiness/run animation or the gameplay gem collection.
 title_gem_clock+=dt
 var speed := 0.26 if WorldState.reduced_flash else 0.42
 title_gem_phase+=dt*speed
 for index in title_gems.size():
  var gem: Sprite2D=title_gems[index]
  if not is_instance_valid(gem): continue
  var phase:=title_gem_phase+TAU*float(index)/float(MENU_GEM_COUNT)-PI*0.5
  var orbit:=Vector2(cos(phase)*MENU_GEM_RADIUS.x,sin(phase)*MENU_GEM_RADIUS.y)
  gem.position=(Vector2(902,322)+orbit*1.02).round()
  # Upper arc sits behind the avatar; lower arc sits in front of the island.
  gem.z_index=3 if sin(phase)>=0.0 else 1
  var pulse := 0.015 if WorldState.reduced_flash else 0.05
  gem.scale=Vector2.ONE*MENU_GEM_SCALES[index]*0.9*(1.0+pulse*sin(title_gem_clock*1.6+index))
  gem.get_node("GemHalo").modulate.a=0.12 if WorldState.reduced_flash else 0.25+0.05*sin(title_gem_clock*1.6+index)
func resume() -> void:
 if starting or important_active: return
 Audio.set_menu_active(false)
 GameCommands.clear()
 get_tree().paused=false
 panel.hide()
 title_screen.hide()
 game_hud.show()
 menu_kind=""
 submenu=""
func offer_first_tutorial(new_adventure: bool) -> void:
 tutorial_new_adventure=new_adventure
 submenu="tutorial"
 submenu_base("TUTORIAL")
 label(panel_box,"QUER APRENDER A JOGAR?",Vector2(24,76),Vector2(432,36),24,true)
 label(panel_box,"O TUTORIAL PAUSA O JOGO\nPARA EXPLICAR AS AÇÕES.",Vector2(24,126),Vector2(432,56),12,true)
 add_button(panel_box,"FAZER TUTORIAL",Vector2(60,210),func(): choose_tutorial(true))
 add_button(panel_box,"PULAR TUTORIAL",Vector2(60,290),func(): choose_tutorial(false))
 focus_buttons()
func choose_tutorial(enabled: bool) -> void:
 if submenu!="tutorial" or WorldState.tutorial_choice_made: return
 WorldState.choose_first_tutorial(enabled)
 submenu=""
 panel.hide()
 clear_menu()
 build_title()
 begin_adventure(tutorial_new_adventure,true)
func begin_adventure(new_adventure: bool = false, tutorial_just_chosen: bool = false) -> void:
 if starting or menu_kind!="intro" or not title_screen.visible: return
 if not WorldState.tutorial_choice_made:
  offer_first_tutorial(new_adventure)
  return
 if new_adventure and not tutorial_just_chosen: WorldState.tutorial_session_active=false
 starting=true
 start_stage="ready"
 start_elapsed=0.0
 start_new_adventure=new_adventure
 # Lock mouse, keyboard and controller controls until the finite poses finish.
 for item in buttons:
  item.disabled=true
  item.focus_mode=Control.FOCUS_NONE
 get_viewport().gui_release_focus()
 var entry: String="ready_to_run"
 if title_hero.frame<ready_for_wave_frames.size(): entry=ready_for_wave_frames[title_hero.frame]
 title_hero.play(entry)
func _on_title_animation_finished() -> void:
 if not starting: return
 if start_stage=="ready" and title_hero.animation.begins_with("ready"):
  start_stage="run"
  start_elapsed=0.0
  title_hero.play("run_start")
 elif start_stage=="run" and title_hero.animation=="run_start":
  starting=false
  start_stage=""
  Audio.set_menu_active(false)
  # A confirms UI and jumps in-game; prevent that same held press becoming a jump.
  GameCommands.clear()
  Input.action_release("jump")
  if start_new_adventure:
   WorldState.reset_progress()
   WorldState.skip_intro_once=true
   get_tree().reload_current_scene()
  else: resume()
func reset_adventure() -> void:
 WorldState.reset_progress()
 resume()
func restart() -> void:
 reset_adventure()
 get_tree().reload_current_scene()
func submenu_base(name_text: String) -> void:
 clear_menu()
 title_screen.hide()
 panel.show()
 label(panel_box,name_text,Vector2(0,4),Vector2(480,44),36,true)
func settings() -> void:
 if starting: return
 submenu="settings"
 submenu_base("CONFIGURAÇÕES")
 for i in 2:
  var kind: String="MÚSICA" if i==0 else "EFEITOS"
  label(panel_box,kind,Vector2(24,76+i*90),Vector2(180,28),24)
  var amount:=label(panel_box,"",Vector2(334,76+i*90),Vector2(120,28),24)
  var slider:=HSlider.new()
  slider.name="MusicVolume" if i==0 else "EffectsVolume"
  slider.position=Vector2(24,114+i*90)
  slider.size=Vector2(432,32)
  slider.min_value=0
  slider.max_value=1
  slider.step=0.05
  slider.value=WorldState.music_volume if i==0 else WorldState.sfx_volume
  amount.text="%d%%" % roundi(slider.value*100)
  slider.add_theme_stylebox_override("slider",style("button"))
  slider.add_theme_stylebox_override("grabber_area",style("button_focus"))
  slider.add_theme_stylebox_override("grabber_area_highlight",style("button_focus"))
  slider.add_theme_icon_override("grabber",load(UI+"diamond.svg"))
  slider.add_theme_icon_override("grabber_highlight",load(UI+"diamond.svg"))
  slider.value_changed.connect(func(value:float):
   if i==0: WorldState.music_volume=value
   else: WorldState.sfx_volume=value
   amount.text="%d%%" % roundi(value*100)
   WorldState.save_progress())
  panel_box.add_child(slider)
  settings_sliders.append(slider)
 flash_check=CheckButton.new()
 flash_check.text="REDUZIR FLASHES"
 flash_check.position=Vector2(24,282)
 flash_check.size=Vector2(432,44)
 flash_check.add_theme_font_override("font",ui_font)
 flash_check.add_theme_font_size_override("font_size",24)
 flash_check.add_theme_color_override("font_color",CREAM)
 flash_check.add_theme_icon_override("on",load(UI+"signal.svg"))
 flash_check.add_theme_icon_override("off",load(UI+"pause.svg"))
 flash_check.add_theme_icon_override("on_disabled",load(UI+"signal.svg"))
 flash_check.add_theme_icon_override("off_disabled",load(UI+"pause.svg"))
 flash_check.add_theme_stylebox_override("focus",style("button_focus"))
 flash_check.button_pressed=WorldState.reduced_flash
 flash_check.toggled.connect(func(value:bool): WorldState.reduced_flash=value;WorldState.save_progress())
 panel_box.add_child(flash_check)
 label(panel_box,"MENOS PULSOS DE LUZ E BRILHO",Vector2(24,334),Vector2(432,28),12).name="FlashHint"
 var back:=add_button(panel_box,"MOBILE" if WorldState.mobile_enabled else "VOLTAR",Vector2(60,392),mobile_settings if WorldState.mobile_enabled else back_menu)
 settings_sliders[0].focus_neighbor_bottom=settings_sliders[1].get_path()
 settings_sliders[1].focus_neighbor_top=settings_sliders[0].get_path()
 settings_sliders[1].focus_neighbor_bottom=flash_check.get_path()
 flash_check.focus_neighbor_top=settings_sliders[1].get_path()
 flash_check.focus_neighbor_bottom=back.get_path()
 back.focus_neighbor_top=flash_check.get_path()
 back.focus_neighbor_bottom=settings_sliders[0].get_path()
 settings_sliders[0].focus_neighbor_top=back.get_path()
 settings_sliders[0].grab_focus()
func controls() -> void:
 if WorldState.mobile_enabled:
  mobile_settings()
  return
 if starting: return
 submenu="controls"
 submenu_base("CONTROLES")
 label(panel_box,"TECLADO",Vector2(24,76),Vector2(432,30),24)
 label(panel_box,"A / D OU SETAS • MOVER\nESPAÇO • PULAR    SHIFT • DASH\nE • PULSO    F • CHIP    ESC • PAUSA",Vector2(24,114),Vector2(432,100),12)
 label(panel_box,"CONTROLE",Vector2(24,242),Vector2(432,30),24)
 label(panel_box,"DIRECIONAL / ANALÓGICO • MOVER\nA • PULAR    X • DASH    B • PULSO\nY • CHIP    START • PAUSA",Vector2(24,280),Vector2(432,84),12)
 add_button(panel_box,"VOLTAR",Vector2(60,392),back_menu)
 focus_buttons()
func back_menu() -> void:
 if menu_kind=="end": conclusion()
 else: show_menu("intro" if menu_kind=="intro" else "pause")
func conclusion() -> void:
 menu_kind="end"
 Audio.set_menu_active(true)
 submenu=""
 get_tree().paused=true
 game_hud.hide()
 title_screen.hide()
 clear_menu()
 panel.show()
 var portal_frame:=texture(panel_box,"portal_frame",Vector2(208,0),Vector2(64,64))
 portal_frame.name="PortalFrame"
 portal_icon=texture(panel_box,"portal_core",Vector2(208,0),Vector2(64,64))
 portal_icon.pivot_offset=Vector2(32,32)
 label(panel_box,"PLANETA RECONECTADO",Vector2(0,78),Vector2(480,44),24,true)
 label(panel_box,"UM NOVO CAMINHO ENTRE MUNDOS",Vector2(0,122),Vector2(480,28),12,true)
 label(panel_box,"FRAGMENTOS  %02d / %02d\nTEMPO       %02d:%02d\nRETORNOS    %02d" % [WorldState.fragments.size(),world.level.fragments.size(),int(world.elapsed)/60,int(world.elapsed)%60,world.deaths],Vector2(60,182),Vector2(360,124),24)
 label(panel_box,"MUNDO 1 • VERTICAL SLICE 0.1",Vector2(0,332),Vector2(480,28),12,true)
 add_button(panel_box,"JOGAR NOVAMENTE",Vector2(60,392),restart)
 focus_buttons()
func notice(message: String) -> void:
 var value:=message.to_upper()
 var first_key := ""
 if "PONTO BRISA" in value:
  first_key="checkpoint"
  toast_state="checkpoint"
  toast_title.text="CHECKPOINT ATIVADO"
  toast.text="PONTO BRISA • PROGRESSO SALVO"
 elif "CONECTANDO" in value:
  first_key="connecting"
  toast_state="connecting"
  toast_title.text="CONECTANDO O PLANETA…"
  toast.text="O SINAL ESTÁ VOLTANDO AO MUNDO"
 elif "ONLINE" in value:
  first_key="online"
  toast_state="online"
  toast_title.text="CONEXÃO RESTABELECIDA"
  toast.text="O CAMINHO PARA O PORTAL ESTÁ ABERTO"
 else:
  toast_state="checkpoint"
  toast_title.text="BRISIN"
  toast.text=value
 toast_icon.texture=load(UI+("flag" if toast_state=="checkpoint" else "signal")+".svg")
 timer=3.5
 toast_box.show()
 if WorldState.tutorial_pauses_enabled() and not first_key.is_empty() and not first_key in WorldState.seen_important_notices:
  if first_key != important_key and not important_queue.any(func(item): return item.key == first_key):
   important_queue.append({"key":first_key,"title":toast_title.text,"text":toast.text,"icon":"flag" if first_key=="checkpoint" else "signal"})
  # Marker callbacks can run inside the physics flush. Pause in the idle phase.
  try_important_notice.call_deferred()

func build_important_notice() -> void:
 important_layer=Control.new()
 important_layer.name="FirstImportantNotice"
 important_layer.size=root.size
 important_layer.mouse_filter=Control.MOUSE_FILTER_STOP
 root.add_child(important_layer)
 important_card=Control.new()
 important_card.position=Vector2(316,112)
 important_card.size=Vector2(520,196)
 important_layer.add_child(important_card)
 var plate:=Control.new()
 plate.size=Vector2(520,84)
 important_card.add_child(plate)
 texture(plate,"toast_frame",Vector2.ZERO,plate.size)
 important_icon=texture(plate,"signal",Vector2(22,26),Vector2(24,24))
 important_title=centered_pixel_label(plate,"",Vector2(60,9),Vector2(436,32),24)
 important_text=centered_pixel_label(plate,"",Vector2(60,41),Vector2(436,28),12)
 important_button=add_button(important_card,"ENTENDI • CONTINUAR",Vector2(80,96),dismiss_important_notice)
 buttons.erase(important_button)
 for side in ["focus_neighbor_top","focus_neighbor_bottom","focus_neighbor_left","focus_neighbor_right","focus_next","focus_previous"]:
  important_button.set(side,important_button.get_path())
 label(important_card,"PAUSADO • CONFIRME EM ENTENDI",Vector2(0,168),Vector2(520,24),12,true)
 important_layer.hide()

func try_important_notice() -> void:
 if not WorldState.tutorial_pauses_enabled():
  important_queue.clear()
  return
 if important_active or important_queue.is_empty() or not menu_kind.is_empty() or get_tree().paused: return
 if is_instance_valid(world) and bool(world.get("portal_transition_active")): return
 var item: Dictionary=important_queue.pop_front()
 if item.key in WorldState.seen_important_notices: return
 important_key=item.key
 important_title.text=item.title
 important_text.text=item.text
 important_icon.texture=load(UI+item.icon+".svg")
 fit_mobile_notice(important_card,important_title,important_text)
 important_active=true
 important_age=0.0
 toast_box.hide()
 context_hint.hide()
 important_layer.show()
 if is_instance_valid(world) and is_instance_valid(world.player):
  var candidates: Array[Vector2]=[Vector2(316,112),Vector2(24,112),Vector2(608,112),Vector2(316,360),Vector2(24,360),Vector2(608,360)]
  if WorldState.mobile_enabled: candidates=mobile_notice_candidates(important_card)
  position_without_player(important_card,candidates,Rect2(24,112,1104,512))
 GameCommands.clear()
 get_tree().paused=true
 Audio.play("notice")
 important_button.grab_focus()
 important_notice_shown.emit(important_key)

func dismiss_important_notice() -> void:
 if not important_active or important_age<0.25: return
 # Input/signal/deferred callbacks can fall between physics flush and step.
 # Commit resume only from the always-processing HUD's idle _process.
 important_resume_pending=true

func finish_important_notice() -> void:
 important_resume_pending=false
 if not important_key in WorldState.seen_important_notices:
  WorldState.seen_important_notices.append(important_key)
  WorldState.save_progress()
 important_key=""
 important_active=false
 important_layer.hide()
 important_button.release_focus()
 timer=0.0
 GameCommands.clear()
 for action in ["jump","dash","pulse","chip"]: Input.action_release(action)
 get_tree().paused=false

func _exit_tree() -> void:
 # An interrupted first reading must not leave the next scene paused.
 if important_active:
  get_tree().paused=false
 important_queue.clear()
# Full authored frame bounds are conservative: alpha margins are protected too.
# This also accounts for facing, camera, and the documented LAND deformation.
func player_screen_rect() -> Rect2:
 var sprite:AnimatedSprite2D=world.player.visual
 if not sprite.sprite_frames.has_animation(sprite.animation):
  # Blockout hides the sprite and draws the player procedurally instead.
  var base:Vector2=world.player.get_global_transform_with_canvas().origin
  return Rect2(base+Vector2(-20,-64),Vector2(40,64))
 var frame:Texture2D=sprite.sprite_frames.get_frame_texture(sprite.animation,sprite.frame)
 var frame_size:=frame.get_size()
 var origin:=sprite.offset-frame_size/2 if sprite.centered else sprite.offset
 var transform:=sprite.get_global_transform_with_canvas()
 var corners: Array[Vector2]=[transform*origin,transform*(origin+Vector2(frame_size.x,0)),transform*(origin+frame_size),transform*(origin+Vector2(0,frame_size.y))]
 var minimum:=corners[0]
 var maximum:=corners[0]
 for corner in corners:
  minimum=minimum.min(corner)
  maximum=maximum.max(corner)
 return Rect2(minimum,maximum-minimum)
func position_without_player(control: Control, candidates: Array[Vector2], safe: Rect2) -> bool:
 var protected:=player_screen_rect().grow(12)
 for candidate in candidates:
  var position:=Vector2(roundf(candidate.x),roundf(candidate.y))
  var bounds:=Rect2(position,control.size)
  var controls_clear := true
  if WorldState.mobile_enabled and control in [toast_box,context_hint]:
   var touch_controls=world.get_node_or_null("MobileControls")
   if touch_controls!=null:
    for area in touch_controls.areas.values():
     if bounds.intersects(area.grow(8)): controls_clear=false
  if safe.encloses(bounds) and not protected.intersects(bounds) and controls_clear:
   control.position=position
   return true
 return false
func reset_context_hints() -> void:
 context_read_time.clear()
 context_key=""
 context_hint.hide()
func update_context_hint(dt: float) -> void:
 context_hint.hide()
 context_key=""
 # Event notifications and tutorials share one slot below the HUD.
 # Menus, blocked placement and event notices do not consume tutorial reading time.
 if not menu_kind.is_empty() or timer>0: return
 var tip: Dictionary = world.context_tip()
 if not tip.is_empty() and WorldState.mobile_enabled:
  tip=tip.duplicate()
  tip.text=mobile_tip(str(tip.text))
 if tip.is_empty(): return
 var key: String = tip.id
 # All gameplay tutorials use the same acknowledgement lifecycle as milestones.
 # Title is semantic: identical instructions on different platforms pause once.
 var first_key: String = "tip:"+str(tip.title)
 if key in ["rail_enter","rail_exit"]: first_key+="/"+key
 if WorldState.tutorial_pauses_enabled() and not first_key in WorldState.seen_important_notices:
  if first_key != important_key and not important_queue.any(func(item): return item.key == first_key):
   important_queue.append({"key":first_key,"title":tip.title,"text":tip.text,"icon":tip.icon})
  try_important_notice()
  return
 var age: float = float(context_read_time.get(key,0.0))
 if age>=CONTEXT_LIFETIME: return
 context_key=key
 context_title.text=tip.title
 context_text.text=tip.text
 context_icon.texture=load(UI+tip.icon+".svg")
 fit_mobile_notice(context_hint,context_title,context_text)
 var candidates: Array[Vector2]=[Vector2(316,112),Vector2(24,112),Vector2(608,112)]
 if WorldState.mobile_enabled: candidates=mobile_notice_candidates(context_hint)
 context_hint.visible=position_without_player(context_hint,candidates,Rect2(24,112,1104,260 if WorldState.mobile_enabled else 84))
 if context_hint.visible:
  context_read_time[key]=minf(CONTEXT_LIFETIME,age+dt)
  context_hint.visible=float(context_read_time[key])<CONTEXT_LIFETIME
func _process(dt: float) -> void:
 update_mobile_layout()
 if update_interruption(): return
 clock+=dt
 var tick:=floorf(clock*12)/12.0
 if starting:
  start_elapsed+=dt
  if start_stage=="run":
   var duration:=float(title_hero.sprite_frames.get_frame_count("run_start"))/title_hero.sprite_frames.get_animation_speed("run_start")
   var fraction:=clampf(start_elapsed/duration,0,1)
   title_hero.position.x=902+roundf(fraction*40)
   title_screen.modulate.a=1.0-clampf((fraction-0.7)/0.3,0,1)
 if title_screen.visible:
  update_title_gems(dt)
 for btn in buttons:
  if is_instance_valid(btn) and btn.has_focus():
   btn.get_node("FocusArrow").position.x=16+roundf(sin(tick*4))*2
 if is_instance_valid(portal_icon):
  portal_icon.rotation=snappedf(tick*0.8,TAU/32)
  portal_icon.modulate.a=1.0 if WorldState.reduced_flash else 0.85+0.15*sin(tick*3)
 if not is_instance_valid(world) or not is_instance_valid(world.player): return
 if important_resume_pending: finish_important_notice()
 try_important_notice()
 if important_active:
  important_age+=dt
  toast_box.hide()
  context_hint.hide()
  return
 # Gameplay notices retain their full reading duration when a menu interrupts them.
 var previous_timer:=timer
 if menu_kind.is_empty(): timer=maxf(0,timer-dt)
 toast_box.visible=timer>0
 if timer>0:
  var age:=floorf((3.5-timer)*12)/12.0
  fit_mobile_notice(toast_box,toast_title,toast)
  var remaining:=floorf(timer*12)/12.0
  var visibility:=minf(1,minf(age/0.25,remaining/0.25))
  var notice_y:=112-roundf((1-visibility)*12)
  var body:=player_screen_rect()
  var above_y:=body.position.y-96
  var candidates: Array[Vector2]=[Vector2(316,notice_y),Vector2(24,notice_y),Vector2(608,notice_y),Vector2(316,above_y),Vector2(24,above_y),Vector2(608,above_y)]
  if WorldState.mobile_enabled: candidates=mobile_notice_candidates(toast_box,maxf(128,game_hud.get_node("ReadableObjective").get_rect().end.y+20)-roundf((1-visibility)*12))
  var fits:=position_without_player(toast_box,candidates,Rect2(24,100,1104,320 if WorldState.mobile_enabled else 192))
  toast_box.visible=fits
  if not fits: timer=previous_timer # Hold the reading duration until a safe space opens.
  toast_box.modulate.a=visibility
  toast_icon.modulate.a=1.0 if WorldState.reduced_flash or toast_state!="connecting" else 0.75+0.25*sin(tick*4)
 var state:=WorldState.connection
 var status:="ONLINE" if state==WorldState.Connection.ONLINE else ("CONECTANDO" if state==WorldState.Connection.CONNECTING else "OFFLINE")
 objective.text="PLANETA • "+status
 game_hud.get_node("ObjectiveDetail").text="ALCANCE O PORTAL" if state==WorldState.Connection.ONLINE else ("RESTABELEÇA O NÓ" if WorldState.mobile_enabled else "RESTABELEÇA O NÓ DE SINAL")
 counter.text=("%02d / %02d" if WorldState.mobile_enabled else "%02d/%02d") % [WorldState.fragments.size(),world.level.fragments.size()]
 dash_counter.text="DASH PRONTO" if world.player.dash_available else "DASH EM RECARGA"
 update_context_hint(dt)
 debug.text=""
 if world.debug_speed: debug.text="V: "+str(world.player.velocity.round())
 if world.debug_state: debug.text+="  "+world.player.state+"  FPS: "+str(Engine.get_frames_per_second())
func _unhandled_input(event: InputEvent) -> void:
 if important_active:
  if not event.is_echo() and (event.is_action_pressed("ui_accept")):
   dismiss_important_notice()
  get_viewport().set_input_as_handled()
  return
 if starting or (is_instance_valid(world) and bool(world.get("portal_transition_active"))): return
 if event.is_action_pressed("pause_game"):
  if not submenu.is_empty(): back_menu()
  elif menu_kind=="end" or menu_kind=="intro": return
  elif panel.visible: resume()
  else: show_menu("pause")
  get_viewport().set_input_as_handled()
 for action in ["debug_hits","debug_speed","debug_state","debug_respawn","debug_reset","debug_art","debug_invincible"]:
  if event.is_action_pressed(action): world.debug_action(action)


func mobile_tip(text: String) -> String:
 return text.replace("[SHIFT / X] DASH","DASH").replace("SOLTA CHIPS","LANÇA").replace("RESTABELEÇA A CONEXÃO","CONECTE O NÓ").replace("PULE PARA SAIR DO CABO","SAI DO CABO").replace("[A / D]","← →").replace("[ESPAÇO / A] PULE","PULO").replace("[ESPAÇO / A] PULAR","PULO").replace("[ESPAÇO / A]","PULO").replace("[SHIFT / X]","DASH").replace("[E / B] PULSO","PULSO").replace("[E / B]","PULSO").replace("[F]","CHIP")

func update_mobile_layout(css_scale: float = 0.0) -> void:
 if not WorldState.mobile_enabled: return
 var factor:=css_scale if css_scale>0 else WorldState.mobile_css_scale()
 var key := str([factor,title_screen.visible,starting,menu_kind,submenu,buttons.map(func(btn): return btn.get_instance_id())])
 if key==mobile_layout_key: return
 mobile_layout_key=key
 if title_screen.visible and not starting:
  title_hero.position=Vector2(902,456)
  title_hero.scale=Vector2.ONE*2.6
  title_platform.position=Vector2(662,302.4)
  title_platform.scale=Vector2.ONE*2.4
  title_platform.z_index=0
  var secondary := maxf(80,ceilf(48.0/factor))
  var primary := maxf(120,ceilf(48.0/factor))
  var spacing := maxf(20,ceilf(8.0/factor))
  var primary_y := minf(272,616-primary-secondary*2-spacing*2)
  var logo_height := minf(204,primary_y-68)
  title_screen.get_node("TitleLogo").position=Vector2(150,24)
  title_screen.get_node("TitleLogo").size=Vector2(432,logo_height)
  title_screen.get_node("TitleSubtitle").position=Vector2(84,24+logo_height+8)
  for i in buttons.size():
   var btn := buttons[i]
   var bottom_row := i >= buttons.size()-2
   var y := primary_y if i==0 else primary_y+primary+spacing
   if bottom_row: y=primary_y+primary+spacing+(secondary+spacing if buttons.size()==4 else 0.0)
   btn.position=Vector2(84+((i-(buttons.size()-2))*((564+spacing)/2) if bottom_row else 0.0),y)
   btn.size=Vector2((564-spacing)/2 if bottom_row else 564,secondary if bottom_row or i>0 else primary)
   # Equal secondary actions share one row; only the main action is orange.
   btn.add_theme_font_override("font",MOBILE_FONT)
   btn.add_theme_font_size_override("font_size",32 if bottom_row else 44 if i>0 else 64)
   btn.add_theme_color_override("font_shadow_color",Color("100a04"))
   btn.add_theme_constant_override("shadow_offset_x",2)
   btn.add_theme_constant_override("shadow_offset_y",3)
   for state in ["normal","hover","pressed","focus"]:
    btn.add_theme_stylebox_override(state,style("mobile/menu"+("_primary" if i==0 else "")+("_pressed" if state=="pressed" else "")))
   btn.z_index=4
   btn.get_node("FocusArrow").hide()
   for ink in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]: btn.add_theme_color_override(ink,Color.TRANSPARENT)
   var caption: Node2D=btn.get_node_or_null("MobileCaption")
   if caption==null:
    caption=Node2D.new()
    caption.name="MobileCaption"
    btn.add_child(caption)
    caption.draw.connect(draw_mobile_caption.bind(caption,btn))
   caption.queue_redraw()
 panel.position=Vector2(256,24)
 panel.size=Vector2(640,600)
 panel.get_child(0).size=panel.size
 panel_box.position=Vector2(80,28)
 panel_box.size=Vector2(480,544)
 layout_readable_mobile_hud(factor)
 if title_screen.has_node("TitleSubtitle"): title_screen.get_node("TitleSubtitle").add_theme_font_override("font",MOBILE_FONT)
 dash_counter.hide()
 game_hud.get_node("DashIcon").hide()
 pause_button.hide() # The touch router owns the larger, CSS-sized pause target.
 var target:=maxf(88,ceilf(48.0/factor))
 var spacing:=maxf(16,ceilf(8.0/factor))
 var step:=target+spacing
 for btn in buttons:
  if btn.get_parent()==panel_box: btn.size.y=target
 if menu_kind=="pause" and submenu.is_empty():
  for i in buttons.size(): buttons[i].position.y=64+i*step
  if panel_box.has_node("PauseHint"): panel_box.get_node("PauseHint").hide()
 if submenu in ["mobile_advanced","mobile_quality"]:
  for i in buttons.size(): buttons[i].position.y=64+i*step
 if submenu=="mobile":
  for i in buttons.size():
   buttons[i].position.y=64+mini(i,3)*step
   buttons[i].size.y=target
 if submenu=="mobile_layout":
  for i in buttons.size(): buttons[i].position.y=188+i*step
 if submenu=="tutorial":
  for i in buttons.size(): buttons[i].position.y=198+i*step
 if submenu=="settings":
  for i in settings_sliders.size():
   settings_sliders[i].position.y=104+i*160
   settings_sliders[i].size.y=target
  # Audio controls keep their labels directly above the enlarged touch track.
  var labels: Array[Label]=[]
  for child in panel_box.get_children():
   if child is Label and child.position.y>=76 and child.position.y<=166: labels.append(child)
  for item in labels:
   item.position.y=64 if item.position.y<120 else 224
  flash_check.hide()
  panel_box.get_node("FlashHint").hide()
  for btn in buttons: btn.position.y=424
 layout_readable_mobile_notices(factor)

func readable_frame(parent: Control, bounds: Vector2, asset: String) -> void:
 var frame: Panel=parent.get_node_or_null("ReadableFrame")
 if frame==null:
  frame=Panel.new()
  frame.name="ReadableFrame"
  frame.mouse_filter=Control.MOUSE_FILTER_IGNORE
  frame.add_theme_stylebox_override("panel",style(asset))
  parent.get_child(0).hide()
  parent.add_child(frame)
  parent.move_child(frame,0)
 frame.size=bounds

func layout_readable_mobile_hud(factor: float) -> void:
 var main_size := int(maxf(28,ceilf(14.0/(0.625*factor))))
 var detail_size := int(maxf(24,ceilf(12.0/(0.625*factor))))
 var width := ceilf(maxf(320,MOBILE_FONT.get_string_size("PLANETA • CONECTANDO",HORIZONTAL_ALIGNMENT_LEFT,-1,main_size).x+40))
 var header := game_hud.get_node_or_null("ReadableObjective") as Panel
 if header==null:
  header=Panel.new()
  header.name="ReadableObjective"
  header.mouse_filter=Control.MOUSE_FILTER_IGNORE
  header.add_theme_stylebox_override("panel",style("objective_frame"))
  game_hud.add_child(header)
  game_hud.move_child(header,0)
 header.position=Vector2(24,20)
 header.size=Vector2(width,main_size+detail_size+24)
 game_hud.get_node("ObjectiveFrame").hide()
 game_hud.get_node("ObjectiveSignal").hide()
 objective.add_theme_font_override("font",MOBILE_FONT)
 objective.add_theme_font_size_override("font_size",main_size)
 objective.position=Vector2(44,27)
 objective.size=Vector2(width-40,main_size+4)
 objective.add_theme_font_override("font",MOBILE_FONT)
 objective.add_theme_font_size_override("font_size",main_size)
 var detail: Label=game_hud.get_node("ObjectiveDetail")
 detail.add_theme_font_override("font",MOBILE_FONT)
 detail.add_theme_font_size_override("font_size",detail_size)
 detail.position=Vector2(44,31+main_size)
 detail.size=Vector2(width-40,detail_size+4)
 detail.add_theme_font_override("font",MOBILE_FONT)
 detail.add_theme_font_size_override("font_size",detail_size)
 game_hud.get_node("GemCounterFrame").hide()
 var count_size := int(maxf(32,ceilf(16.0/(0.625*factor))))
 var count_width := ceilf(MOBILE_FONT.get_string_size("00 / 49",HORIZONTAL_ALIGNMENT_LEFT,-1,count_size).x+12)
 var pause_size := ceilf(maxf(64,48.0/factor))
 var right := 1152-20-pause_size-24
 counter.add_theme_font_override("font",MOBILE_FONT)
 counter.add_theme_font_size_override("font_size",count_size)
 counter.position=Vector2(right-count_width,28)
 counter.size=Vector2(count_width,count_size+12)
 counter.add_theme_font_override("font",MOBILE_FONT)
 counter.add_theme_font_size_override("font_size",count_size)
 var icon_size := ceilf(maxf(44,28.0/factor))
 var gem: TextureRect=game_hud.get_node("GemCounterIcon")
 gem.position=Vector2(counter.position.x-12-icon_size,24)
 gem.size=Vector2(icon_size,icon_size)
 gem.texture=load("res://assets/world_01/svg/gem_orange.svg")

func layout_readable_mobile_notices(factor: float) -> void:
 var title_size := int(maxf(28,ceilf(14.0/(0.625*factor))))
 var body_size := int(maxf(24,ceilf(14.0/(0.625*factor))))
 var width := ceilf(minf(780,maxf(640,300.0/factor)))
 var height := float(title_size+body_size*2+36)
 var icon_size := ceilf(maxf(32,20.0/factor))
 var column_x := icon_size+36
 for group in [[toast_box,toast_title,toast,toast_icon],[context_hint,context_title,context_text,context_icon],[important_card.get_child(0),important_title,important_text,important_icon]]:
  var card: Control=group[0]
  card.size=Vector2(width,height)
  readable_frame(card,card.size,"toast_frame")
  var heading: Label=group[1]
  var body: Label=group[2]
  var icon: TextureRect=group[3]
  heading.position=Vector2(column_x,12)
  heading.size=Vector2(width-column_x-24,title_size+6)
  body.position=Vector2(column_x,title_size+20)
  body.size=Vector2(width-column_x-24,body_size*2+8)
  for item in [heading,body]:
   item.add_theme_font_override("font",MOBILE_FONT)
   item.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
   item.add_theme_font_size_override("font_size",title_size if item==heading else body_size)
   item.clip_text=false
  icon.position=Vector2(16,(height-icon_size)/2)
  icon.size=Vector2(icon_size,icon_size)
 important_card.size=Vector2(width,height+maxf(88,ceilf(48.0/factor))+76)
 important_card.position=Vector2((1152-width)/2,maxf(128,game_hud.get_node("ReadableObjective").get_rect().end.y+20))
 important_button.size=Vector2(width-100,maxf(88,ceilf(48.0/factor)))
 important_button.position=Vector2(50,height+16)
 important_button.add_theme_font_override("font",MOBILE_FONT)
 important_button.add_theme_font_size_override("font_size",int(maxf(28,ceilf(16.0/(0.625*factor)))))
 var footer: Label=important_card.get_child(2)
 footer.position=Vector2(0,important_button.get_rect().end.y+16)
 footer.size=Vector2(width,maxf(24,ceilf(12.0/(0.625*factor)))+8)
 footer.add_theme_font_override("font",MOBILE_FONT)
 footer.add_theme_font_size_override("font_size",int(maxf(24,ceilf(12.0/(0.625*factor)))))
 footer.hide()

func fit_mobile_notice(card: Control, heading: Label, body: Label) -> void:
 if not WorldState.mobile_enabled: return
 var title_size := heading.get_theme_font_size("font_size")
 var body_size := body.get_theme_font_size("font_size")
 var body_height := ceilf(maxf(body_size*2,MOBILE_FONT.get_multiline_string_size(body.text,HORIZONTAL_ALIGNMENT_CENTER,body.size.x,body_size).y))
 body.size.y=body_height+8
 var height := float(title_size)+body_height+36
 var plate: Control=card.get_child(0) if card==important_card else card
 plate.size.y=height
 plate.get_node("ReadableFrame").size.y=height
 if card==important_card:
  important_button.position.y=height+16
  card.size.y=height+important_button.size.y+32
 else:
  card.size.y=height

func mobile_notice_candidates(card: Control, top: float = -1.0) -> Array[Vector2]:
 if top<0: top=maxf(128,game_hud.get_node("ReadableObjective").get_rect().end.y+20)
 return [Vector2((1152-card.size.x)/2,top),Vector2(24,top),Vector2(1128-card.size.x,top)]

func draw_mobile_caption(caption: Node2D, button: Button) -> void:
 var font_size := button.get_theme_font_size("font_size")
 var value := button.text
 var text_size := MOBILE_FONT.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size)
 var baseline := button.size/2+Vector2(-text_size.x/2,float(font_size)/3.0)
 # The approved title has opaque cream letters and a chunky short dark edge.
 var outline := 3.0 if font_size<40 else 4.0
 for offset in [Vector2(-outline,0),Vector2(outline,0),Vector2(0,-outline),Vector2(0,outline),Vector2(-outline,outline),Vector2(outline,outline+2)]:
  caption.draw_string(MOBILE_FONT,baseline+offset,value,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,Color("100a04"))
 caption.draw_string(MOBILE_FONT,baseline,value,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,CREAM)

func mobile_toggle(title: String, y: float, key: String, callback: Callable) -> void:
 var value: bool = WorldState.get(key)
 add_button(panel_box,title+" • "+("SIM" if value else "NÃO"),Vector2(60,y),func():
  WorldState.set(key,not bool(WorldState.get(key)))
  WorldState.save_progress()
  callback.call())

func mobile_settings() -> void:
 submenu="mobile"
 submenu_base("MOBILE")
 mobile_toggle("ESPELHAR",64,"controls_mirrored",mobile_settings)
 mobile_toggle("SALTO VARIÁVEL",176,"variable_jump",mobile_settings)
 mobile_toggle("REPETIR CHIPS",288,"chip_repeat",mobile_settings)
 add_button(panel_box,"MAIS",Vector2(0,416),mobile_advanced,Vector2(224,100))
 add_button(panel_box,"VOLTAR",Vector2(256,416),back_menu,Vector2(224,100))
 focus_buttons()

func mobile_advanced() -> void:
 submenu="mobile_advanced"
 submenu_base("MOBILE")
 mobile_toggle("AJUDA DE SALTO",64,"mobile_assist",mobile_advanced)
 add_button(panel_box,"VISUAL / QUALIDADE",Vector2(60,164),mobile_quality)
 add_button(panel_box,"POSIÇÃO / TAMANHO",Vector2(60,264),mobile_layout_settings)
 add_button(panel_box,"VOLTAR",Vector2(60,424),mobile_settings)
 focus_buttons()

func mobile_quality() -> void:
 submenu="mobile_quality"
 submenu_base("VISUAL")
 mobile_toggle("QUALIDADE LEVE",64,"low_quality",mobile_quality)
 mobile_toggle("REDUZIR FLASHES",198,"reduced_flash",mobile_quality)
 add_button(panel_box,"VOLTAR",Vector2(60,424),mobile_advanced)
 focus_buttons()

func mobile_layout_settings() -> void:
 submenu="mobile_layout"
 submenu_base("CONTROLES DE TOQUE")
 label(panel_box,"MOVA COM O DIRECIONAL.
PULO, DASH, CHIP E PULSO À DIREITA.
ARRASTE ENTRE BOTÕES PARA TROCAR.",Vector2(24,70),Vector2(432,96),16)
 add_button(panel_box,"TAMANHO • %d%%" % roundi(WorldState.control_scale*100),Vector2(60,188),func():
  WorldState.control_scale=1.0 if WorldState.control_scale>=1.25 else WorldState.control_scale+0.125
  WorldState.save_progress()
  mobile_layout_settings())
 add_button(panel_box,"POSIÇÃO • "+("ALTA" if WorldState.control_lift>0 else "BAIXA"),Vector2(60,292),func():
  WorldState.control_lift=0.0 if WorldState.control_lift>0 else 1.0
  WorldState.save_progress()
  mobile_layout_settings())
 add_button(panel_box,"VOLTAR",Vector2(60,416),mobile_advanced)
 focus_buttons()

func build_interruption() -> void:
 interruption_layer=Control.new()
 interruption_layer.name="MobileInterruption"
 interruption_layer.size=root.size
 interruption_layer.mouse_filter=Control.MOUSE_FILTER_STOP
 root.add_child(interruption_layer)
 var shade:=ColorRect.new()
 shade.size=root.size
 shade.color=Color("241508")
 interruption_layer.add_child(shade)
 interruption_text=label(interruption_layer,"",Vector2(176,144),Vector2(800,96),32,true)
 add_button(interruption_layer,"CONTINUAR",Vector2(396,290),func():
  if not WorldState.resume_mobile(): return
  interruption_layer.hide()
  GameCommands.clear()
  if starting: title_hero.play()
  if menu_kind.is_empty() and not important_active: resume(),Vector2(360,96))
 buttons.erase(buttons.back())
 add_button(interruption_layer,"VOLTAR AO MENU",Vector2(396,410),func():
  return_to_mobile_menu(),Vector2(360,96))
 buttons.erase(buttons.back())
 interruption_layer.hide()

func update_interruption() -> bool:
 var requested := int(WorldState.host_state.get("menuRequest",0))
 if requested != menu_request:
  menu_request=requested
  return_to_mobile_menu()
 if not WorldState.interrupted: return false
 # Do not force an extra resume when focus was lost in the existing menu.
 if not WorldState.mobile_portrait and not menu_kind.is_empty() and not interruption_layer.visible and not starting:
  WorldState.interrupted=false
  return false
 GameCommands.clear()
 if starting: title_hero.pause()
 get_tree().paused=true
 interruption_text.text=WorldState.interruption_reason+"\nTOQUE EM CONTINUAR PARA RETOMAR"
 interruption_layer.show()
 return true


func return_to_mobile_menu() -> void:
 GameCommands.clear()
 if important_active:
  important_queue.push_front({"key":important_key,"title":important_title.text,"text":important_text.text,"icon":important_icon.texture.resource_path.get_file().get_basename()})
  important_key=""
  important_active=false
  important_resume_pending=false
  important_layer.hide()
 if bool(world.get("portal_transition_active")): world._cancel_portal_transition()
 starting=false
 start_stage=""
 # A portrait player can request the menu even though rotating is still required.
 WorldState.interrupted=WorldState.mobile_portrait
 interruption_layer.hide()
 show_menu("intro")
