extends SceneTree
var samples := []
func _initialize() -> void:
 call_deferred("sample")
func draw_z(node: CanvasItem) -> int:
 var total := node.z_index
 var parent := node.get_parent()
 while node.z_as_relative and parent is CanvasItem:
  node = parent
  total += node.z_index
  parent = node.get_parent()
 return total
func collect(node: Node, center: Vector2, out: Array) -> void:
 if node is CanvasItem and not node.is_visible_in_tree(): return
 if node is Sprite2D:
  var t = node.global_transform
  var r: Rect2 = node.get_rect()
  var color: Color = node.modulate
  out.append({"path":node.texture.resource_path,"rect":[r.position.x,r.position.y,r.size.x,r.size.y],"matrix":[t.x.x,t.x.y,t.y.x,t.y.y,t.origin.x-center.x,t.origin.y-center.y],"z":draw_z(node),"alpha":color.a,"rgb":[color.r,color.g,color.b]})
 for child in node.get_children(): collect(child,center,out)
func sample() -> void:
 await process_frame
 var state = root.get_node("WorldState")
 state.reset_progress()
 state.reduced_flash=false
 state.connection=state.Connection.ONLINE
 var world=load("res://scenes/world_01/world_01.tscn").instantiate()
 root.add_child(world)
 world.player.set_physics_process(false)
 world.scenery_svg.set_process(false)
 world.apply_connection()
 var center: Vector2=world.point(world.level.portal)+Vector2(0,-100.5)
 world.player.position=world.point(world.level.portal)+Vector2(-50,0)
 for seconds in [0.0,1.0,2.0]:
  world.scenery_svg.clock=seconds
  world.scenery_svg.rotation_clock=seconds
  world.scenery_svg._process(0.0)
  var data=[]
  collect(world.scenery_svg.portal_rotor.get_parent(),center,data)
  samples.append({"label":"Disponível %.1fs"%seconds,"layers":data})
 for reduced in [false,true]:
  state.reduced_flash=reduced
  world.begin_portal_transition("portal_02")
  var effect=world.portal_transition
  effect.set_process(false)
  for seconds in [0.0,0.35,0.75,1.2,1.5,1.7]:
   effect.age=seconds
   effect._animate()
   var data=[]
   collect(world.scenery_svg.portal_rotor.get_parent(),center,data)
   collect(effect,center,data)
   samples.append({"label":"%s %.2fs"%["Reduzido" if reduced else "Entrada",seconds],"layers":data})
  effect.cancel()
  await process_frame
 FileAccess.open("/tmp/brisin-portal-samples.json",FileAccess.WRITE).store_string(JSON.stringify(samples))
 world.queue_free()
 await process_frame
 quit()
