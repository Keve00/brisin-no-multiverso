extends Node2D
# Approved objects: each source layer is editable vector pixel art. Rotations are
# frame-grid stepped; every sprite retains equal x/y scale and a fixed pivot.
const ROOT = "res://assets/world_01/interactive/"
var world: Node2D
var clock := 0.0
var rotation_clock := 0.0
var portal_motion := 0.0
var rotor: Node2D
var turbine_base: Sprite2D
var turbine_blades: Sprite2D
var lighthouse: Sprite2D
var beams: Array[Node2D] = []
var lamp: Sprite2D
var rail_packets: Array[Sprite2D] = []
var bridge_packets: Array[Sprite2D] = []
var node_core: Sprite2D
var node_halo: Sprite2D
var node_frame: Sprite2D
var node_signal: Sprite2D
var node_particles: Array[Sprite2D] = []
var node_panels: Array[Sprite2D] = []
const NODE_SCALE := 0.7
const NODE_PIVOT := Vector2(80,212)
const NODE_CORE := Vector2(80,117)
var portal_frame: Sprite2D
var portal_rotor: Node2D
var portal_core: Sprite2D
var portal_tunnel: Sprite2D
var portal_lanes: Sprite2D
var portal_packets: Array[Sprite2D] = []
var checkpoint_active := false
var rail_root: Node2D
var rail_posts: Array[Sprite2D] = []
var rail_segments: Array[Sprite2D] = []
var textures: Dictionary = {}
var last_online := false
func texture(key: String) -> Texture2D:
 if not textures.has(key): textures[key] = load(ROOT+key+".svg")
 return textures[key]
func piece(parent: Node, key: String, pos: Vector2, factor: float = 1.0) -> Sprite2D:
 var sprite := Sprite2D.new()
 sprite.texture = texture(key)
 sprite.position = pos
 sprite.scale = Vector2.ONE*factor
 sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
 parent.add_child(sprite)
 return sprite
func at_pivot(parent: Node, key: String, pos: Vector2, pivot: Vector2, factor: float) -> Sprite2D:
 var sprite := piece(parent,key,pos,factor)
 sprite.centered=false
 sprite.offset=-pivot
 return sprite
func _ready() -> void:
 var turbine_ground := Vector2(world.wind_rect.position.x-35,world.level.platforms[2][1])
 turbine_base=at_pivot(self,"turbine_base_off",turbine_ground,Vector2(64,156),2.0)
 rotor=Node2D.new();rotor.position=turbine_ground+Vector2(0,-202);add_child(rotor)
 turbine_blades=piece(rotor,"turbine_rotor_off",Vector2.ZERO,2.0)
 var lighthouse_ground: Vector2= world.point(world.level.node)+Vector2(-180,0)
 lighthouse=at_pivot(self,"lighthouse_base_off",lighthouse_ground,Vector2(63,153),1.5)
 var light_origin := lighthouse_ground+Vector2(1,-113)*1.5
 lamp=piece(self,"lighthouse_lamp_off",light_origin,1.5)
 for side in [-1,1]:
  var beam := Node2D.new();beam.position=light_origin;add_child(beam)
  var image := at_pivot(beam,"lighthouse_beam",Vector2.ZERO,Vector2(0,24),1.5)
  if side<0: image.flip_h=true;image.offset=Vector2(-192,-24)
  beam.z_index=-1
  beams.append(beam)
 build_rail()
 for i in 8: rail_packets.append(piece(self,"rail_packet",Vector2.ZERO))
 for i in 4:
  var packet := piece(self,"rail_packet",Vector2.ZERO)
  packet.z_index=2
  bridge_packets.append(packet)
 var node_pos: Vector2= world.point(world.level.node)
 node_frame=at_pivot(self,"node_frame_off",node_pos,NODE_PIVOT,NODE_SCALE)
 node_core=piece(self,"node_core_off",node_pos+(NODE_CORE-NODE_PIVOT)*NODE_SCALE,NODE_SCALE)
 node_halo=piece(self,"node_halo",node_core.position,NODE_SCALE)
 node_signal=at_pivot(self,"node_signal",node_pos,NODE_PIVOT,NODE_SCALE)
 node_signal.z_index=2
 for i in 6:
  var spark := piece(self,"node_spark",node_core.position,0.28)
  spark.z_index=3
  node_particles.append(spark)
 for x in [-26.0,26.0]:
  var panel := piece(self,"node_panel_fill",node_pos+Vector2(x,-36)*NODE_SCALE,NODE_SCALE)
  panel.z_index=2
  node_panels.append(panel)
 node_frame.z_index=1;node_core.z_index=1;node_halo.z_index=2
 var portal := Node2D.new();portal.position=world.point(world.level.portal);add_child(portal)
 portal.z_index=1
 portal_frame=at_pivot(portal,"portal_frame_off",Vector2.ZERO,Vector2(80,152),1.5)
 portal_frame.z_index=2
 portal_rotor=Node2D.new();portal_rotor.position=Vector2(0,-73.5);portal.add_child(portal_rotor)
 portal_tunnel=Sprite2D.new()
 portal_tunnel.texture=load("res://assets/world_01/portal_transition/tunnel.svg")
 portal_tunnel.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
 portal_tunnel.scale=Vector2.ONE*.67
 portal_tunnel.z_index=-2
 portal_rotor.add_child(portal_tunnel)
 portal_core=piece(portal_rotor,"portal_core_off",Vector2.ZERO,1.5)
 portal_lanes=Sprite2D.new()
 portal_lanes.texture=load("res://assets/world_01/portal_transition/arcs.svg")
 portal_lanes.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
 portal_lanes.scale=Vector2.ONE*.55
 portal_rotor.add_child(portal_lanes)
 for i in 8:
  var packet := Sprite2D.new()
  packet.texture=load("res://assets/world_01/portal_transition/spark.svg")
  packet.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
  packet.scale=Vector2.ONE*.26
  portal_rotor.add_child(packet)
  portal_packets.append(packet)
 set_online(WorldState.connection==WorldState.Connection.ONLINE)
func build_rail() -> void:
 # Repeat 24px cable modules and crop only the final module. Never resize a rail.
 rail_root=Node2D.new();rail_root.position=world.rail_a+Vector2(0,10)
 rail_root.rotation=(world.rail_b-world.rail_a).angle();add_child(rail_root)
 var length: float=world.rail_a.distance_to(world.rail_b)
 for x in range(0,int(ceil(length)),24):
  var segment := at_pivot(rail_root,"rail_segment_off",Vector2(x,0),Vector2(0,9),1.0)
  segment.region_enabled=true
  segment.region_rect=Rect2(0,0,minf(24,length-x),18)
  rail_segments.append(segment)
 for endpoint in [world.rail_a,world.rail_b]:
  # Endcaps remain upright; cables rotate as a rigid strip along the physical path.
  var post := at_pivot(self,"rail_post_off",endpoint+Vector2(0,10),Vector2(30,24),1.0)
  rail_posts.append(post)
 rail_posts[1].flip_h=true;rail_posts[1].offset=Vector2(-12,-24)
func set_online(online: bool) -> void:
 last_online=online
 var suffix := "on" if online else "off"
 turbine_base.texture=texture("turbine_base_"+suffix)
 turbine_blades.texture=texture("turbine_rotor_"+suffix)
 lighthouse.texture=texture("lighthouse_base_"+suffix)
 lamp.texture=texture("lighthouse_lamp_"+suffix)
 node_frame.texture=texture("node_frame_"+suffix)
 node_core.texture=texture("node_core" if online else "node_core_off")
 portal_frame.texture=texture("portal_frame_"+suffix)
 portal_core.texture=texture("portal_core" if online else "portal_core_off")
 for post in rail_posts: post.texture=texture("rail_post_"+suffix)
 for segment in rail_segments: segment.texture=texture("rail_segment_"+suffix)
func set_checkpoint(active: bool) -> void:
 # Visuals now belong to marker.gd for every checkpoint, including brisa_01.
 checkpoint_active=active

func _process(dt: float) -> void:
 clock+=dt
 var online := WorldState.connection==WorldState.Connection.ONLINE
 var connecting := WorldState.connection==WorldState.Connection.CONNECTING
 if online!=last_online: set_online(online)
 for marker in world.markers:
  if marker.kind=="checkpoint" and marker.id=="brisa_01" and marker.active!=checkpoint_active:
   set_checkpoint(marker.active)
 var mix_value: float=world.online_blend
 lamp.modulate=Color(.38,.28,.24).lerp(Color.WHITE,mix_value)
 if online: rotation_clock+=dt
 var tick := floorf(clock*12)/12
 rotor.rotation=snappedf(rotation_clock*1.5,TAU/48)
 for i in beams.size():
  beams[i].rotation=snappedf(sin(tick*.65+i*0.7)*.15,TAU/96)
  beams[i].modulate.a=mix_value*(0.55+0.08*sin(tick*2))
 for i in rail_packets.size():
  var phase := fposmod(tick*.3+float(i)/rail_packets.size(),1.0)
  rail_packets[i].position=(world.rail_a.lerp(world.rail_b,phase)+Vector2(0,10)).round()
  rail_packets[i].rotation=(world.rail_b-world.rail_a).angle()
  # Rail is available Offline too; its small moving packets communicate usability.
  rail_packets[i].modulate.a=lerpf(0.3,0.9,mix_value)
 for i in bridge_packets.size():
  bridge_packets[i].visible=online
  var phase := fposmod(tick*.45+float(i)/bridge_packets.size(),1.0)
  bridge_packets[i].position=Vector2(world.level.bridge[0]+phase*world.level.bridge[2],world.level.bridge[1]+3).round()
  bridge_packets[i].modulate.a=mix_value*.75
 var node_animated := online or connecting
 # Charging runs a faster traveling sequence; Online settles into a soft pulse.
 # Only light intensity/phase changes: the existing rotation/scale envelopes stay.
 var energy_phase := tick*(3.6 if connecting else 2.4)
 # Stone, cradle and ground pivot never move. Only the contained energy layers
 # animate, sharing one authored core center and uniform scale.
 var amplitude := .012 if WorldState.reduced_flash else .025
 node_core.rotation=0.0
 node_core.scale=Vector2.ONE*NODE_SCALE*(1.0+sin(energy_phase)*amplitude if node_animated else 1.0)
 node_halo.visible=node_animated
 node_halo.rotation=snappedf(tick*(.25 if WorldState.reduced_flash else .65),TAU/72) if node_animated else 0.0
 node_halo.modulate=Color.WHITE
 node_signal.visible=node_animated
 node_signal.modulate.a=.65 if WorldState.reduced_flash else (.65+.25*sin(energy_phase))
 for i in node_panels.size():
  node_panels[i].visible=node_animated
  var light := .85 if WorldState.reduced_flash else .72+.28*sin(energy_phase-i*1.4)
  node_panels[i].modulate=Color(light,light,light,1)
 for i in node_particles.size():
  var spark := node_particles[i]
  var phase := tick*(.35 if WorldState.reduced_flash else .8)+TAU*float(i)/node_particles.size()
  var radius := 27.0+sin(phase*2.0)*2.0
  spark.position=node_core.position+Vector2(cos(phase),sin(phase))*radius
  spark.modulate.a=.72 if WorldState.reduced_flash else .65+.25*sin(energy_phase+i*1.1)
  spark.visible=node_animated and (not WorldState.reduced_flash or i%3==0)
 if online: portal_motion+=dt*(.5 if WorldState.reduced_flash else 1.0)
 # The rigid frame and center stay fixed. Depth terraces, contra-rotating
 # lanes and inward packets animate only inside the existing portal opening.
 portal_rotor.rotation=0.0
 portal_core.rotation=portal_motion*.7
 portal_core.modulate.a=lerpf(.45,1.0,mix_value)
 var portal_amp := .01 if WorldState.reduced_flash else .025
 portal_core.scale=Vector2.ONE*1.5*(1.0+sin(portal_motion*2)*portal_amp if online else 1.0)
 portal_tunnel.visible=online
 portal_lanes.visible=online
 portal_lanes.rotation=-portal_motion*.9
 for i in portal_packets.size():
  var packet := portal_packets[i]
  var progress := fposmod(portal_motion*.24+float(i)/portal_packets.size(),1.0)
  var radius := lerpf(38.0,10.0,progress)
  var angle := float(i)*TAU/portal_packets.size()-portal_motion*.55-progress*1.25
  packet.position=(Vector2(cos(angle),sin(angle))*radius).round()
  # Packets brighten toward the opening center without growing beyond its mask.
  packet.modulate.a=.7 if WorldState.reduced_flash else lerpf(.4,1.0,sin(progress*PI))
  packet.visible=online and (not WorldState.reduced_flash or i%2==0)
