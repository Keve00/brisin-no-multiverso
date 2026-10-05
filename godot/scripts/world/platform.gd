extends AnimatableBody2D
## Modular vector platforms. All visual scaling is uniform; only middle spans tile.
var rect := Rect2()
var moving := false
var home := Vector2.ZERO
var travel := Vector2(160,0)
var clock := 0.0
var art := false
var texture: Texture2D
var bridge := false
var variant := ""
var variation := 0
var player: CharacterBody2D
var crumble := false
var one_way := false
var online_only := false
var online := false
var ground_texture: Texture2D
var decoration_texture: Texture2D
var wind_texture: Texture2D
var _shapes: Array[CollisionShape2D] = []
var _crumble_state := "intact"
var _state_time := 0.0
var _visual_offset := Vector2.ZERO

func configure(r: Rect2, is_moving: bool, is_bridge: bool = false) -> void:
 rect = Rect2(Vector2.ZERO,r.size)
 position = r.position
 home = position
 moving = is_moving
 bridge = is_bridge
 one_way = moving
 collision_layer = 4 if moving else 2
 collision_mask = 0
 _build_collisions()
 sync_to_physics = moving

func configure_variant(kind: String, alternate: int = 0) -> void:
 var allowed := ["coastal","sand","steps","thin","cracked","raft","wood_bridge","signal","wind_island"]
 if kind not in allowed:
  push_warning("Unknown platform variant: "+kind)
  return
 variant = kind
 variation = clampi(alternate,0,1)
 crumble = kind == "cracked"
 var base := "res://assets/world_01/platforms/"+variant+"_"+str(variation)
 texture = load(base+".svg")
 ground_texture = load(base+"_ground.svg")
 decoration_texture = load(base+"_deco.svg")
 wind_texture = load(base+"_wind.svg") if kind == "wind_island" else null
 _build_collisions()
 queue_redraw()

func configure_optional(enabled: bool = true) -> void:
 one_way = enabled
 _build_collisions()

func sync_online(enabled: bool) -> void:
 online = enabled
 _apply_presence()
 queue_redraw()

func _new_shape(size: Vector2, point: Vector2) -> void:
 var shape := CollisionShape2D.new()
 var box := RectangleShape2D.new()
 box.size = size
 shape.shape = box
 shape.position = point+size/2
 shape.one_way_collision = one_way
 shape.one_way_collision_margin = 6.0
 add_child(shape)
 _shapes.append(shape)

func _build_collisions() -> void:
 for shape in _shapes:
  remove_child(shape)
  shape.queue_free()
 _shapes.clear()
 if variant == "steps" and ground_texture:
  var factor := rect.size.x/ground_texture.get_width()
  # The three independent tops match the source concept's shelves.
  if variation == 0:
   _new_shape(Vector2(68*factor,20),Vector2(5*factor,34*factor))
   _new_shape(Vector2(61*factor,20),Vector2(32*factor,0))
   _new_shape(Vector2(61*factor,20),Vector2(75*factor,11*factor))
  else:
   _new_shape(Vector2(47*factor,20),Vector2(2*factor,39*factor))
   _new_shape(Vector2(57*factor,20),Vector2(10*factor,0))
   _new_shape(Vector2(60*factor,20),Vector2(34*factor,20*factor))
 else:
  _new_shape(Vector2(rect.size.x,20 if one_way or moving else rect.size.y),Vector2.ZERO)
 _apply_presence()

func set_art(enabled: bool) -> void:
 art = enabled
 if enabled and variant == "":
  texture = load("res://assets/world_01/rail.png" if bridge else ("res://assets/world_01/raft.png" if moving else "res://assets/world_01/island.png"))
 queue_redraw()

func _standing_on_platform() -> bool:
 if not is_instance_valid(player) or not player.is_on_floor(): return false
 for index in range(player.get_slide_collision_count()):
  var contact := player.get_slide_collision(index)
  if contact.get_collider() == self and contact.get_normal().y < -0.5: return true
 return false

func _player_overlaps() -> bool:
 if not is_instance_valid(player): return false
 var safety := Rect2(global_position,Vector2(rect.size.x,maxf(32.0,rect.size.y))).grow(12)
 return safety.has_point(player.global_position) or safety.has_point(player.global_position+Vector2(0,-36))

func _apply_presence() -> void:
 var absent := _crumble_state == "absent" or (online_only and not online)
 for shape in _shapes: shape.set_deferred("disabled",absent)
 visible = not absent

func reset_state() -> void:
 _crumble_state = "intact"
 _state_time = 0.0
 _visual_offset = Vector2.ZERO
 clock = 0.0
 position = home
 modulate = Color.WHITE
 _apply_presence()
 queue_redraw()

func _physics_process(dt: float) -> void:
 clock += dt
 if moving:
  # Signal hover moves the body and its collision in the same physics tick.
  position = home+Vector2(0,sin(clock*1.8)*6.0) if variant == "signal" else home+travel*sin(clock*0.8)
 if crumble:
  if _crumble_state == "intact" and _standing_on_platform():
   _crumble_state = "telegraph"
   _state_time = 0.0
  elif _crumble_state != "intact":
   _state_time += dt
   if _crumble_state == "telegraph":
    _visual_offset.x = roundf(sin(_state_time*40)*2)
    if _state_time >= 0.6:
     _crumble_state = "absent"
     _state_time = 0.0
     _visual_offset = Vector2.ZERO
     _apply_presence()
   elif _crumble_state == "absent" and _state_time >= 1.8 and not _player_overlaps():
    _crumble_state = "recover"
    _state_time = 0.0
    _apply_presence()
   elif _crumble_state == "recover" and _state_time >= 2.0:
    _crumble_state = "intact"
    _state_time = 0.0
 queue_redraw()

func _draw_modular() -> void:
 if not ground_texture: return
 var size := ground_texture.get_size()
 var width := rect.size.x
 var cap := minf(24.0,size.x/3.0)
 var middle := size.x-cap*2
 # Deliberate cap crop + repeated middle; square source pixels stay square.
 if width < cap*2:
  var uniform := width/size.x
  draw_texture_rect(ground_texture,Rect2(Vector2.ZERO,size*uniform),false)
 else:
  draw_texture_rect_region(ground_texture,Rect2(0,0,cap,size.y),Rect2(0,0,cap,size.y))
  draw_texture_rect_region(ground_texture,Rect2(width-cap,0,cap,size.y),Rect2(size.x-cap,0,cap,size.y))
  var cursor := cap
  while cursor < width-cap:
   var span := minf(middle,width-cap-cursor)
   draw_texture_rect_region(ground_texture,Rect2(cursor,0,span,size.y),Rect2(cap,0,span,size.y))
   cursor += span
 # Decoration is a single fixed-size layer, rather than repeated tall palms.
 if decoration_texture:
  draw_texture(decoration_texture,Vector2(width/2-100,-64))

func _draw() -> void:
 draw_set_transform(_visual_offset)
 if art and texture:
  if variant == "steps":
   var factor := rect.size.x/ground_texture.get_width()
   draw_texture_rect(texture,Rect2(Vector2(rect.size.x/2-100*factor,-64*factor),texture.get_size()*factor),false)
  elif variant != "":
   _draw_modular()
   if variant == "signal":
    var strength := 0.55+sin(clock*2.5)*0.15
    draw_circle(Vector2(rect.size.x/2,48),8,Color(0.25,0.9,1,strength))
   elif variant == "wind_island":
    if wind_texture:
     var wind_tint := Color(1,1,1,0.75+sin(clock*2)*0.15)
     draw_texture(wind_texture,Vector2(rect.size.x/2-100+roundf(sin(clock*1.4)*3),-64+roundf(cos(clock*1.1)*2)),wind_tint)
    for index in range(4):
     var phase := fmod(clock*0.7+index*0.25,1.0)
     draw_rect(Rect2(rect.size.x/2-50+phase*100,36+sin(phase*TAU)*12,2,2),Color(0.55,1,0.92,sin(phase*PI)*0.8))
   if bridge:
    draw_rect(Rect2(0,5,rect.size.x,2),Color(0.3,0.85,1,0.35+0.15*sin(clock*2)))
  elif bridge:
   draw_rect(Rect2(0,0,rect.size.x,24),Color("173d51"))
   draw_rect(Rect2(0,18,rect.size.x,4),Color("2b7284"))
  elif moving:
   var raft_size := texture.get_size()*(130.0/texture.get_height())
   draw_texture_rect(texture,Rect2(Vector2(rect.size.x/2-raft_size.x/2,-113),raft_size),false)
  else:
   var factor := 0.5
   var width := rect.size.x+16
   var height: float = texture.get_height()
   var cap := 160.0
   var left_cap := Rect2(0,0,cap,height)
   var right_cap := Rect2(texture.get_width()-cap,0,cap,height)
   draw_texture_rect_region(texture,Rect2(Vector2(-8,-57),left_cap.size*factor),left_cap)
   draw_texture_rect_region(texture,Rect2(Vector2(-8+width-cap*factor,-57),right_cap.size*factor),right_cap)
   var cursor := cap*factor
   var end := width-cap*factor
   var source_width: float = texture.get_width()-cap*2
   while cursor<end:
    var piece_width := minf(source_width*factor,end-cursor)
    var source := Rect2(cap,0,piece_width/factor,height)
    draw_texture_rect_region(texture,Rect2(Vector2(-8+cursor,-57),source.size*factor),source)
    cursor += piece_width
 else:
  draw_rect(rect,Color("324659") if bridge else Color("9b543b"))
 if _crumble_state == "telegraph":
  var progress := _state_time/0.6
  var crack := PackedVector2Array([Vector2(rect.size.x*0.38,0),Vector2(rect.size.x*0.46,8),Vector2(rect.size.x*0.42,18),Vector2(rect.size.x*0.55,28*progress)])
  draw_polyline(crack,Color("4b203e"),3.0,false)
  draw_rect(Rect2(0,0,rect.size.x,3),Color(1,0.62,0.15,progress*0.65))
 elif _crumble_state == "recover":
  draw_rect(Rect2(0,0,rect.size.x,2),Color(1,0.8,0.35,0.4*(1-_state_time/2)))
 if not art:
  draw_rect(Rect2(0,0,rect.size.x,7),Color("60e4b3") if not bridge else Color("44ddff"))
 draw_set_transform(Vector2.ZERO)
