extends Node
var samples:Array=[]
var world:Node2D
func layer(sprite:Sprite2D,center:Vector2)->Dictionary:
 var t:=sprite.global_transform
 t.origin-=center
 var r:=sprite.get_rect()
 return {"path":sprite.texture.resource_path,"matrix":[t.x.x,t.x.y,t.y.x,t.y.y,t.origin.x,t.origin.y],"rect":[r.position.x,r.position.y,r.size.x,r.size.y],"rgb":[sprite.modulate.r,sprite.modulate.g,sprite.modulate.b],"alpha":sprite.modulate.a,"z":sprite.z_index}
func sample(label:String,transition:Node2D=null)->void:
 var center:Vector2=world.point(world.level.portal)+Vector2(0,-100.5)
 var layers:Array=[]
 layers.append(layer(world.scenery_svg.portal_frame,center))
 layers[0].z=4
 var sprites:Array=[]
 if transition:
  sprites=[transition.tunnel,transition.root_ring,transition.inner_ring,transition.vortex]+transition.depth_arcs+transition.particles
 else:
  sprites=[world.scenery_svg.portal_tunnel,world.scenery_svg.portal_core,world.scenery_svg.portal_lanes]+world.scenery_svg.portal_packets
 for sprite in sprites:
  if sprite.is_visible_in_tree():layers.append(layer(sprite,center))
 samples.append({"label":label,"layers":layers})
func _ready()->void:call_deferred("run")
func run()->void:
 WorldState.reset_progress()
 world=load("res://scenes/world_01/world_01.tscn").instantiate();add_child(world)
 world.player.set_physics_process(false);world.scenery_svg.set_process(false)
 world.scenery_svg._process(0);sample("Offline")
 WorldState.connection=WorldState.Connection.ONLINE;world.apply_connection();world.online_blend=1
 world.scenery_svg._process(0);sample("Online 0s")
 world.scenery_svg._process(1);sample("Online 1s")
 world.scenery_svg._process(2);sample("Online 3s")
 world.player.position=world.point(world.level.portal)+Vector2(-50,0)
 world.begin_portal_transition("portal_02")
 var effect=world.portal_transition;effect.set_process(false)
 assert(effect.vortex.texture==world.scenery_svg.portal_core.texture)
 assert(is_equal_approx(effect.vortex.rotation,world.scenery_svg.portal_core.rotation))
 assert(is_equal_approx(effect.vortex.scale.x,world.scenery_svg.portal_core.scale.x))
 sample("Entrada 0s",effect)
 for dt in [.3,.65,.65,.2]:
  effect._process(dt)
  sample("Entrada %.2fs"%effect.age,effect)
 var f:=FileAccess.open("res://docs/portal_review_samples.json",FileAccess.WRITE)
 f.store_string(JSON.stringify(samples));f.close()
 print("PORTAL_REVIEW: same core, scale and orientation at handoff; 9 actual transform samples")
 get_tree().paused=false;get_tree().quit()
