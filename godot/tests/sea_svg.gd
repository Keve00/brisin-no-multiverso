extends Node
const SeaSVG = preload("res://scripts/systems/sea_svg.gd")
var failures: Array[String] = []
var passed := 0

func check(ok: bool, label: String) -> void:
 if ok: passed+=1
 else: failures.append(label);push_error(label)

func _ready() -> void:
 process_mode=Node.PROCESS_MODE_ALWAYS
 call_deferred("run")

func run() -> void:
 var sea := Node2D.new()
 sea.set_script(SeaSVG)
 add_child(sea)
 sea.set_process(false)
 check(sea.surface_frames.size()==12,"doze frames SVG importados")
 check(sea.z_index==-3,"mar à frente do panorama e atrás do gameplay")
 check(sea.texture_filter==CanvasItem.TEXTURE_FILTER_NEAREST,"filtro preserva pixels")
 check(sea.scale==Vector2.ONE,"mar usa escala uniforme 1:1")
 check(sea.get_child_count()==0,"mar visual não introduz física")
 var seen: Dictionary={}
 for i in SeaSVG.FRAME_COUNT:
  var texture: Texture2D=sea.surface_frames[i]
  check(texture.get_size()==SeaSVG.TILE_SIZE,"canvas estável %d"%i)
  sea.clock=float(i)/SeaSVG.FPS+0.001
  seen[sea.frame_index()]=true
 check(seen.size()==12,"todos os frames são alcançados")
 sea.clock=2.0
 check(sea.frame_index()==0,"loop de superfície retorna sem frame vazio")
 check(sea.coverage_rect(9600).end==Vector2(9600,1034),"mar cobre nível e queda até além do limite inferior da câmera")
 for centre in [576.0,1800.0,4500.0,7000.0,9024.0]:
  var view:=Rect2(centre-576,600,1152,648)
  for offset in [0.0,2.0,510.0,-2.0,-510.0]:
   var regions: Array[Dictionary]=sea.tile_regions(view,9600,offset)
   var left: float=regions[0].destination.position.x
   var right: float=regions[-1].destination.end.x
   var contiguous:=left<=view.position.x and right>=view.end.x
   var unstretched:=true
   for i in regions.size():
    var destination: Rect2=regions[i].destination
    var source: Rect2=regions[i].source
    unstretched=unstretched and destination.size==source.size and source.position.x>=0 and source.end.x<=512
    if i>0: contiguous=contiguous and is_equal_approx(regions[i-1].destination.end.x,destination.position.x)
   check(contiguous and unstretched,"cobertura sem frestas ou stretch x%d offset%d"%[int(centre),int(offset)])
 check(sea.tile_regions(Rect2(0,0,1152,648),9600).is_empty(),"água fora da câmera não gera tiles")
 sea.clock=0
 check(sea.reflection_offset()==0 and sea.swell_offset()==0,"origem do ciclo estável")
 sea.clock=32
 check(sea.reflection_offset()==0,"reflexo fecha seu período de 32s")
 sea.clock=64
 check(sea.swell_offset()==0,"onda fecha seu período de 64s")
 sea.clock=1.234
 check(fmod(sea.reflection_offset(),2.0)==0 and fmod(sea.swell_offset(),2.0)==0,"movimento preso à grade de 2px")
 var stationary := Rect2(0,600,1152,648)
 var redraws := 0
 for tick in 120:
  sea.clock = float(tick)/120.0
  if sea.refresh_needed(stationary,9600): redraws += 1
 check(redraws <= 16,"120 ticks estacionários redesenham apenas fases diferentes")
 check(sea.refresh_needed(Rect2(20,600,1152,648),9600),"câmera móvel atualiza recorte no mesmo frame")
 check(not sea.refresh_needed(Rect2(20,600,1152,648),9600),"fase e câmera iguais não redesenham")
 check(sea.refresh_needed(Rect2(20,600,1152,648),9800),"mudança de extensão invalida cobertura")
 sea.set_art(false)
 var frozen: float=sea.clock
 sea._process(.4)
 check(not sea.visible and sea.clock==frozen,"blockout esconde e congela o mar SVG")
 sea.set_art(true)
 sea.set_process(true)
 get_tree().paused=true
 await get_tree().process_frame
 await get_tree().process_frame
 check(sea.clock==frozen,"pausa congela superfície e reflexos")
 get_tree().paused=false
 await get_tree().process_frame
 await get_tree().process_frame
 check(sea.clock>frozen,"retomar continua o mesmo ciclo")
 print("SEA_SVG_RESULT: %d passed, %d failures"%[passed,failures.size()])
 get_tree().quit(0 if failures.is_empty() else 1)
