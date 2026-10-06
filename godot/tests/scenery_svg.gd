extends Node
var failures: Array[String] = []
func check(ok: bool, text: String) -> void:
 if ok: print("PASS: ",text)
 else: failures.append(text);push_error(text)
func uniform(node: Node) -> bool:
 if node is Sprite2D and not is_equal_approx(absf(node.scale.x),absf(node.scale.y)): return false
 for child in node.get_children():
  if not uniform(child): return false
 return true
func _ready() -> void:
 call_deferred("run")
func run() -> void:
 WorldState.reset_progress()
 WorldState.seen_important_notices=["checkpoint", "connecting", "online", "tip:PLANETA ALIENÍGENA", "tip:NÓ DE SINAL", "tip:RUÍDOZINHO", "tip:LANÇAR CHIP", "tip:TRILHA DE SINAL/rail_enter", "tip:TRILHA DE SINAL/rail_exit", "tip:CORRENTE DE VENTO", "tip:PEDRA RACHADA", "tip:DASH DE SINAL", "tip:PLANETA RECONECTADO"]
 var world=load("res://scenes/world_01/world_01.tscn").instantiate()
 add_child(world)
 var scenery=world.scenery_svg
 for key in ["lighthouse_base_off","lighthouse_base_on","lighthouse_lamp_off","lighthouse_lamp_on","lighthouse_beam","portal_frame_off","portal_frame_on","portal_core_off","portal_core"]:
  var source := FileAccess.get_file_as_string(scenery.ROOT+key+".svg")
  check(source.begins_with("<svg") and not "<image" in source and ("<path" in source or "<rect" in source),key+" contém geometria SVG real sem raster embutido")
 check(scenery.texture("lighthouse_base_off").get_size()==scenery.texture("lighthouse_base_on").get_size(),"farol conserva canvas e pivô entre estados")
 check(scenery.texture("portal_frame_off").get_size()==scenery.texture("portal_frame_on").get_size(),"portal conserva canvas e pivô entre estados")
 await get_tree().create_timer(.2).timeout
 check(uniform(scenery),"todas as camadas SVG usam escala uniforme")
 check(scenery.rotor.rotation==0 and scenery.portal_core.rotation==0 and not scenery.portal_lanes.visible,"turbina e interior do portal param Offline")
 check(scenery.beams[0].modulate.a==0,"farol não emite feixe Offline")
 check(not scenery.bridge_packets[0].visible,"ponte permanece sem fluxo Offline")
 check(scenery.texture("turbine_base_on").get_size()==scenery.texture("turbine_base_off").get_size(),"base da turbina mantém canvas entre estados")
 check(scenery.texture("turbine_rotor_on").get_size()==scenery.texture("turbine_rotor_off").get_size(),"rotor mantém canvas entre estados")
 for key in ["node_frame_off","node_frame_on","node_core","node_core_off","node_halo","node_signal","node_panel_fill","node_spark"]:
  var source := FileAccess.get_file_as_string(scenery.ROOT+key+".svg")
  check("<path" in source and not "<image" in source,key+" usa paths reais")
 var node_image: Image=scenery.texture("node_frame_on").get_image()
 check(node_image.get_pixel(0,0).a==0 and node_image.get_pixel(80,117).a==0,"fundo e abertura do Nó transparentes")
 check(scenery.node_frame.offset==Vector2(-80,-212) and scenery.node_frame.scale==Vector2.ONE*0.7,"base do Nó usa pivô fixo e escala uniforme")
 check(scenery.node_core.position==world.point(world.level.node)+Vector2(0,-66.5),"núcleo alinhado à abertura registrada")
 check(not scenery.node_halo.visible and not scenery.node_signal.visible and not scenery.node_particles[0].visible,"Offline sem emissões ou resíduos de partículas")
 check(scenery.texture("node_core").get_size()==scenery.texture("node_core_off").get_size(),"Nó mantém canvas entre estados")
 world.on_pulse(world.point(world.level.node)+Vector2(0,-35))
 await get_tree().create_timer(2).timeout
 check(WorldState.connection==WorldState.Connection.ONLINE,"Pulso reconecta o cenário")
 check(scenery.rotor.rotation!=0 and scenery.portal_core.rotation!=0 and scenery.portal_lanes.rotation!=0 and scenery.portal_rotor.rotation==0 and scenery.portal_frame.rotation==0,"turbina e interior do portal animam Online com moldura fixa")
 check(scenery.beams[0].modulate.a>0 and scenery.bridge_packets[0].visible,"farol e ponte ativam luz e fluxo Online")
 check(scenery.node_core.texture==scenery.texture("node_core"),"Nó usa camada Online correta")
 check(scenery.node_core.rotation==0 and scenery.node_frame.rotation==0 and scenery.node_halo.rotation!=0,"Online anima arcos mantendo moldura e centro fixos")
 check(scenery.node_signal.visible and scenery.node_particles[0].visible and scenery.node_panels[0].visible,"Online ativa sinal, partículas e painéis")
 var node_clock: float=scenery.clock
 get_tree().paused=true
 await get_tree().create_timer(.15,true).timeout
 check(scenery.clock==node_clock,"pausa congela animação do Nó")
 get_tree().paused=false
 WorldState.reduced_flash=true
 scenery._process(.1)
 check(scenery.node_particles[0].visible and not scenery.node_particles[1].visible,"flashes reduzidos limitam partículas sem apagar sinal")
 world.set_art(false)
 check(not scenery.visible,"blockout esconde camadas de arte")
 world.set_art(true)
 check(scenery.visible,"retorno à arte restaura cenário SVG")
 print("SCENERY_SVG_RESULT: ",failures.size()," failures")
 get_tree().quit(0 if failures.is_empty() else 1)
