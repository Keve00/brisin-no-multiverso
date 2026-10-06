extends Node2D
func _ready() -> void: call_deferred("run")
func run() -> void:
 var families=["coastal","sand","steps","thin","cracked","raft","wood_bridge","signal","wind_island"]
 for page in 3:
  var nodes:Array[Node]=[]
  for row in 3:
   var kind:String=families[page*3+row]
   for v in 2:
    var platform=load("res://scripts/world/platform.gd").new()
    var width:= (240 if v==0 else 130) if kind=="steps" else 460
    platform.configure(Rect2(45+v*560,135+row*175,width,100),false)
    platform.configure_variant(kind,v)
    platform.set_art(true)
    platform.set_physics_process(false)
    add_child(platform);nodes.append(platform)
    var label=Label.new();label.text=kind+" / "+str(v);label.position=Vector2(45+v*560,220+row*175);add_child(label);nodes.append(label)
  for i in 3:await get_tree().process_frame
  await RenderingServer.frame_post_draw
  get_viewport().get_texture().get_image().save_png("res://docs/cosmic_qa/platforms_page_"+str(page)+".png")
  for n in nodes:n.queue_free()
  await get_tree().process_frame
 get_tree().quit()
