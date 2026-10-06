extends Node2D
signal finished(elapsed: float, fragments: int)
@export_file("*.json") var level_path := "res://data/world_01.json"
const PlayerScene = preload("res://scenes/player/player.tscn")
const Platform = preload("res://scripts/world/platform.gd")
const Marker = preload("res://scripts/interactables/marker.gd")
const Enemy = preload("res://scripts/enemies/noisezinho.gd")
const HUD = preload("res://scripts/systems/hud.gd")
const ScenerySVG = preload("res://scripts/systems/scenery_svg.gd")
const WindSVG = preload("res://scripts/systems/wind_svg.gd")
const EnvironmentSVG = preload("res://scripts/systems/environment_svg.gd")
const PickupSVG = preload("res://scripts/systems/pickup_svg.gd")
const CombatSVG = preload("res://scripts/player/combat_svg.gd")
var combat: Node2D
const PortalTransitionSVG = preload("res://scripts/systems/portal_transition_svg.gd")
const BackgroundSVG = preload("res://scripts/systems/background_svg.gd")
const SeaSVG = preload("res://scripts/systems/sea_svg.gd")
var sea_svg: Node2D
var portal_transition_active := false
var portal_transition: Node2D
var portal_transition_completed := false
var portal_patrol_processing: Dictionary = {}
var background_svg: Node2D
var environment_svg: Node2D
var wind_svg: Node2D
var extra_wind_nodes: Array[Node2D] = []
var scenery_svg: Node2D
var level: Dictionary
var player: BrisinhoPlayer
var enemy: Node2D
var enemies: Array[Node2D] = []
var platforms: Array = []
var markers: Array = []
var bridge: AnimatableBody2D
var wind_rect := Rect2()
var wind_force := Vector2.ZERO
var rail_a := Vector2.ZERO
var rail_b := Vector2.ZERO
var clock := 0.0
var elapsed := 0.0
var deaths := 0
var online_blend := 0.0
var connection_timer := 0.0
var hud: CanvasLayer
var show_hits := false
var debug_speed := false
var debug_state := false
func point(a: Array) -> Vector2: return Vector2(a[0],a[1])
func _ready() -> void:
 # Gameplay must pause even when embedded under an always-processing UI host.
 process_mode=Node.PROCESS_MODE_PAUSABLE
 level = JSON.parse_string(FileAccess.get_file_as_string(level_path))
 background_svg = Node2D.new()
 background_svg.set_script(BackgroundSVG)
 background_svg.world = self
 add_child(background_svg)
 sea_svg=Node2D.new()
 sea_svg.set_script(SeaSVG)
 sea_svg.world=self
 add_child(sea_svg)
 wind_rect = Rect2(level.wind[0],level.wind[1],level.wind[2],level.wind[3])
 wind_force = point(level.wind_force)
 wind_svg = Node2D.new()
 wind_svg.set_script(WindSVG)
 wind_svg.region = wind_rect
 wind_svg.force = wind_force
 wind_svg.z_index = 3
 add_child(wind_svg)
 for spec in level.get("extra_winds",[]):
  var stream := Node2D.new()
  stream.set_script(WindSVG)
  stream.region = Rect2(spec.rect[0],spec.rect[1],spec.rect[2],spec.rect[3])
  stream.force = point(spec.force)
  stream.z_index = 3
  stream.set_meta("online_only",bool(spec.get("online_only",false)))
  add_child(stream)
  extra_wind_nodes.append(stream)
 rail_a = point(level.rail_start)
 rail_b = point(level.rail_end)
 scenery_svg=Node2D.new()
 scenery_svg.set_script(ScenerySVG)
 scenery_svg.world=self
 scenery_svg.z_index=1
 add_child(scenery_svg)
 for i in level.platforms.size():
  var body := add_platform(level.platforms[i],false)
  if level.has("platform_styles") and i<level.platform_styles.size():
   body.configure_variant(str(level.platform_styles[i][0]),int(level.platform_styles[i][1]))
  body.crumble = false
 var moving_body := add_platform(level.moving_platform,true)
 moving_body.configure_variant("raft",0)
 bridge = add_platform(level.bridge,false,true)
 bridge.configure_variant("wood_bridge",0)
 for spec in level.get("extra_platforms",[]):
  var body := add_platform(spec.rect,bool(spec.get("moving",false)))
  body.configure_variant(str(spec.kind),int(spec.get("variant",0)))
  body.set_meta("online_only",bool(spec.get("online_only",false)))
  body.online_only = bool(spec.get("online_only",false))
  body.set_meta("bonus",true)
  body.crumble = bool(spec.get("crumble",false))
  if body.has_method("configure_optional"): body.configure_optional()
 player = PlayerScene.instantiate()
 player.position = WorldState.checkpoint
 add_child(player)
 player.z_index=5
 for body in platforms: body.player = player
 player.camera.limit_right = int(level.length)
 combat = Node2D.new()
 combat.set_script(CombatSVG)
 combat.world = self
 add_child(combat)
 player.chip_launched.connect(combat.launch_chip)
 player.pulsed.connect(on_pulse)
 player.respawned.connect(on_respawn)
 # Keep `enemy` as the first instance for existing debug tools and tests;
 # authored patrol groups let the level add reachable, platform-bound threats.
 var enemy_specs: Array = level.get("enemies", [level.get("enemy_bounds", [1740,1940,320])])
 for spec in enemy_specs:
  var patrol: Node2D = Node2D.new()
  patrol.set_script(Enemy)
  patrol.left = float(spec[0])
  patrol.right = float(spec[1])
  patrol.position = Vector2(patrol.left+30,float(spec[2]))
  patrol.player = player
  patrol.variant = str(level.get("enemy_variants",["cristal"])[enemies.size()%level.get("enemy_variants",["cristal"]).size()])
  if spec.size()>4: patrol.variant = str(spec[4])
  var online_only_enemy: bool = spec.size()>3 and bool(spec[3])
  patrol.set_meta("online_only",online_only_enemy)
  patrol.visible = not online_only_enemy or WorldState.connection==WorldState.Connection.ONLINE
  add_child(patrol)
  patrol.z_index=5
  enemies.append(patrol)
 if not enemies.is_empty(): enemy = enemies[0]
 add_marker("checkpoint","brisa_01",point(level.checkpoint))
 for extra in level.get("extra_checkpoints",[]):
  add_marker("checkpoint",str(extra.id),point(extra.position))
 add_marker("node","nexo_01",point(level.node))
 add_marker("portal","portal_02",point(level.portal))
 for i in level.fragments.size(): add_marker("fragment","f_"+str(i),point(level.fragments[i]))
 environment_svg = Node2D.new()
 environment_svg.set_script(EnvironmentSVG)
 environment_svg.world = self
 add_child(environment_svg)
 hud = CanvasLayer.new()
 hud.set_script(HUD)
 hud.world = self
 add_child(hud)
 var touch = preload("res://scenes/ui/mobile_controls.tscn").instantiate()
 touch.hud = hud
 touch.world = self
 add_child(touch)
 set_art(not WorldState.blockout)
 apply_connection()
 online_blend = 1 if WorldState.connection == WorldState.Connection.ONLINE else 0
func add_platform(r: Array, moving: bool, is_bridge: bool = false) -> AnimatableBody2D:
 var body := AnimatableBody2D.new()
 body.set_script(Platform)
 body.configure(Rect2(r[0],r[1],r[2],r[3]),moving,is_bridge)
 body.z_index=2
 add_child(body)
 platforms.append(body)
 return body
func add_marker(kind: String, id: String, pos: Vector2) -> void:
 var marker := Node2D.new()
 marker.set_script(Marker)
 marker.configure(kind,id,pos)
 marker.z_index=4
 marker.player = player
 if kind == "fragment" and id in WorldState.fragments:
  marker.active = true
  marker.visible = false
 if kind == "checkpoint" and WorldState.checkpoint_id == id: marker.active = true
 if kind == "node" and WorldState.connection == WorldState.Connection.ONLINE: marker.active = true
 marker.activated.connect(on_marker)
 add_child(marker)
 markers.append(marker)
func set_art(enabled: bool) -> void:
 WorldState.blockout = not enabled
 scenery_svg.visible=enabled
 environment_svg.set_art(enabled)
 background_svg.set_art(enabled)
 sea_svg.set_art(enabled)
 for p in platforms: p.set_art(enabled)
 for m in markers: m.set_art(enabled)
 player.set_art(enabled)
 queue_redraw()
func apply_connection() -> void:
 var online := WorldState.connection == WorldState.Connection.ONLINE
 bridge.visible = online
 bridge.collision_layer = 2 if online else 0
 for stream in extra_wind_nodes: stream.visible = online or not stream.get_meta("online_only",false)
 for body in platforms:
  if body.has_method("sync_online"): body.sync_online(online)
  if body.get_meta("online_only",false):
   body.visible = online
   body.collision_layer = (4 if body.moving else 2) if online else 0
 for patrol in enemies:
  patrol._sync_support()
func on_pulse(origin: Vector2) -> void:
 for marker in markers: marker.pulse(origin)
 combat.start_pulse(origin)
func on_marker(kind: String, id: String) -> void:
 if portal_transition_active: return
 match kind:
  "fragment":
   if id in WorldState.fragments: return
   WorldState.fragments.append(id)
   WorldState.save_progress()
   WorldState.fragment_collected.emit(1)
   Audio.play("pickup")
   for marker in markers:
    if marker.id == id:
     var effect := Node2D.new()
     effect.set_script(PickupSVG)
     effect.position = marker.position+Vector2(0,-22)
     add_child(effect)
     break
  "checkpoint":
   var checkpoint_position: Vector2=point(level.checkpoint)
   for extra in level.get("extra_checkpoints",[]):
    if str(extra.id)==id: checkpoint_position=point(extra.position)
   WorldState.checkpoint = checkpoint_position+Vector2(0,-3)
   WorldState.checkpoint_id = id
   WorldState.checkpoint_reached.emit(id)
   player.dash_available = true
   Audio.play("checkpoint")
   WorldState.save_progress()
   hud.notice("PONTO BRISA • Progresso salvo")
  "node":
   if WorldState.connection != WorldState.Connection.OFFLINE: return
   WorldState.connection = WorldState.Connection.CONNECTING
   connection_timer = 1.3
   WorldState.node_activated.emit(id)
   Audio.play("node")
   hud.notice("CONECTANDO O PLANETA…")
  "portal":
   begin_portal_transition(id)
func begin_portal_transition(id: String) -> void:
 if not is_inside_tree() or not is_instance_valid(player) or not is_instance_valid(hud): return
 if portal_transition_active or player.state in ["DISABLED","RESPAWN"] or WorldState.connection != WorldState.Connection.ONLINE: return
 var entry: Node2D
 for marker in markers:
  if is_instance_valid(marker) and marker.kind == "portal" and marker.id == id:
   entry = marker
   break
 if not is_instance_valid(entry): return
 portal_transition_active = true
 portal_transition_completed = false
 entry.active = true
 player.velocity = Vector2.ZERO
 player.change_state("DISABLED")
 portal_patrol_processing.clear()
 for patrol in enemies:
  portal_patrol_processing[patrol] = patrol.is_physics_processing()
  patrol.set_physics_process(false)
 combat.clear()
 hud.reset_context_hints()
 Audio.play("portal")
 portal_transition = Node2D.new()
 portal_transition.set_script(PortalTransitionSVG)
 portal_transition.world = self
 portal_transition.player = player
 portal_transition.position = point(level.portal) + Vector2(0,-81.0)
 portal_transition.completed.connect(_finish_portal_transition)
 portal_transition.cancelled.connect(_cancel_portal_transition)
 add_child(portal_transition)
func _finish_portal_transition() -> void:
 if not portal_transition_active or portal_transition_completed or not is_inside_tree(): return
 if not is_instance_valid(portal_transition) or not portal_transition.done or portal_transition.age < PortalTransitionSVG.DURATION: return
 portal_transition_completed = true
 # Keep input/menu lock through the conclusion handoff. Save only now.
 WorldState.completed = true
 WorldState.save_progress()
 finished.emit(elapsed,WorldState.fragments.size())
 hud.conclusion()
func _cancel_portal_transition() -> void:
 if is_instance_valid(portal_transition) and not portal_transition.done:
  # Direct restart/debug cancellation must use the same visual cleanup path.
  portal_transition.cancel()
  return
 portal_transition_active = false
 portal_transition_completed = false
 for marker in markers:
  if is_instance_valid(marker) and marker.kind == "portal":
   marker.active = false
   marker.portal_rearm_needed = true
 for patrol in portal_patrol_processing:
  if is_instance_valid(patrol): patrol.set_physics_process(portal_patrol_processing[patrol])
 portal_patrol_processing.clear()
 if is_instance_valid(player) and player.state == "DISABLED":
  player.velocity = Vector2.ZERO
  player.change_state("IDLE")
 portal_transition = null
func _exit_tree() -> void:
 if is_instance_valid(portal_transition):
  # The transition also restores its wrapper if a scene is removed directly.
  portal_transition.restore_visual()
 portal_transition_active = false
 portal_patrol_processing.clear()
func on_respawn() -> void:
 combat.clear()
 deaths += 1
 hud.reset_context_hints()
 for patrol in enemies: patrol.reset()
 for p in platforms:
  if p.has_method("reset_state"): p.reset_state()
  if p.moving:
   p.clock = 0
   p.position = p.home
 apply_connection()
func _physics_process(_dt: float) -> void:
 player.wind = wind_force if wind_rect.has_point(player.position+Vector2(0,-30)) else Vector2.ZERO
 for stream in extra_wind_nodes:
  if stream.visible and stream.region.has_point(player.position+Vector2(0,-30)): player.wind += stream.force
 if player.state != "RAIL" and player.rail_lock <= 0 and player.state not in ["RESPAWN","DISABLED"]:
  var nearest := Geometry2D.get_closest_point_to_segment(player.position,rail_a,rail_b)
  if player.position.distance_to(nearest)<26 and player.position.x<rail_b.x-35:
   player.begin_rail(nearest,rail_b)
func _process(dt: float) -> void:
 clock += dt
 if player.state != "DISABLED": elapsed += dt
 if WorldState.connection == WorldState.Connection.CONNECTING:
  connection_timer -= dt
  if connection_timer<=0:
   WorldState.connection = WorldState.Connection.ONLINE
   WorldState.sector_connected.emit(level.id)
   apply_connection()
   WorldState.save_progress()
   hud.notice("PLANETA ONLINE • Ponte e portal ativados")
 online_blend = move_toward(online_blend,1.0 if WorldState.connection == WorldState.Connection.ONLINE else 0.0,dt*0.65)
 queue_redraw()
# Contexts follow current gameplay objects, not decorative tutorial sign coordinates.
# One candidate wins by priority; the HUD owns visibility and reading budgets.
func context_tip() -> Dictionary:
 if player.state in ["RESPAWN","DISABLED","DASH"]: return {}
 var pos := player.position
 if WorldState.connection == WorldState.Connection.OFFLINE and player.pulse_time<=0 and pos.distance_to(point(level.node))<125:
  return {"id":"node", "title":"NÓ DE SINAL", "text":"[E / B] PULSO • RESTABELEÇA A CONEXÃO", "icon":"signal"}
 for i in enemies.size():
  var patrol: Node2D = enemies[i]
  if not patrol.visible or not patrol.alive or patrol.stunned>0: continue
  var delta: Vector2 = pos-patrol.position
  if absf(delta.x)<200 and absf(delta.y)<95:
   if player.pulse_time<=0 and (pos+Vector2(0,-35)).distance_to(patrol.position+Vector2(0,-25))<140:
    return {"id":"enemy_"+str(i), "title":"RUÍDOZINHO", "text":"[E / B] PULSO • [F] SOLTA CHIPS" if player.chip_cooldown<=0 else "[E / B] PULSO • INTERROMPA O INIMIGO", "icon":"signal"}
   if player.dash_available and player.cooldown<=0:
    return {"id":"enemy_"+str(i), "title":"RUÍDOZINHO", "text":"[SHIFT / X] DASH • [F] SOLTA CHIPS" if player.chip_cooldown<=0 else "[SHIFT / X] DASH OU PULE SOBRE ELE", "icon":"bolt"}
 # Teach chips only when a live target is ahead and the flight path is clear.
 for i in enemies.size():
  var target: Node2D = enemies[i]
  if not target.visible or not target.alive or player.chip_cooldown>0: continue
  var delta: Vector2 = target.global_position-player.global_position
  if delta.x*player.facing<=0 or absf(delta.x)>450 or absf(delta.y)>35: continue
  var shot_origin: Vector2 = player.global_position+Vector2(player.facing*24,-35)
  var aim: Vector2 = target.global_position+Vector2(0,-35)
  var query := PhysicsShapeQueryParameters2D.new()
  var shape := RectangleShape2D.new()
  shape.size = Vector2(24,28)
  query.shape = shape
  query.transform = Transform2D(0,shot_origin)
  query.motion = aim-shot_origin
  query.collision_mask = 2|4
  var space := get_world_2d().direct_space_state
  if not space.intersect_shape(query,1).is_empty() or space.cast_motion(query)[0]<1.0: continue
  return {"id":"enemy_"+str(i), "title":"LANÇAR CHIP", "text":"[F] SOLTA CHIPS • ATINJA O RUÍDOZINHO", "icon":"bolt"}
 if player.state == "RAIL":
  return {"id":"rail_exit", "title":"TRILHA DE SINAL", "text":"[ESPAÇO / A] PULE PARA SAIR DO CABO", "icon":"bolt"}
 var nearest := Geometry2D.get_closest_point_to_segment(pos,rail_a,rail_b)
 if pos.distance_to(nearest)<160 and player.rail_lock<=0 and pos.x<rail_b.x-35:
  return {"id":"rail_enter", "title":"TRILHA DE SINAL", "text":"SALTE NO CABO CIANO PARA DESLIZAR", "icon":"bolt"}
 if wind_rect.grow(40).has_point(pos+Vector2(0,-30)):
  return {"id":"wind", "title":"CORRENTE DE VENTO", "text":"PULE NA CORRENTE PARA GANHAR ALTURA", "icon":"signal"}
 for i in extra_wind_nodes.size():
  var stream: Node2D = extra_wind_nodes[i]
  if stream.visible and stream.region.grow(32).has_point(pos+Vector2(0,-30)):
   return {"id":"wind_"+str(i), "title":"CORRENTE DE VENTO", "text":"PULE NA CORRENTE PARA GANHAR ALTURA", "icon":"signal"}
 for i in platforms.size():
  var body = platforms[i]
  if not body.visible or body.collision_layer==0: continue
  var above: bool = pos.x>=body.position.x-16 and pos.x<=body.position.x+body.rect.size.x+16 and pos.y<=body.position.y+12 and pos.y>=body.position.y-90
  if above and body.crumble:
   return {"id":"crumble_"+str(i), "title":"PEDRA RACHADA", "text":"SALTE ANTES QUE A PLATAFORMA CAIA", "icon":"bolt"}
  # Teach dash only at a real gap, facing it, with the ability available.
  var edge: float = body.position.x+body.rect.size.x
  if above and player.facing>0 and pos.x>edge-90 and player.dash_available and player.cooldown<=0 and pos.x<=edge+16:
   for next in platforms:
    if not next.visible or next.collision_layer==0: continue
    var gap: float = next.position.x-edge
    if gap>90 and gap<350 and absf(next.position.y-body.position.y)<100:
     return {"id":"gap_"+str(i), "title":"DASH DE SINAL", "text":"[ESPAÇO / A] PULE • [SHIFT / X] DASH", "icon":"bolt"}
 if pos.distance_to(point(level.portal))<260:
  if WorldState.connection == WorldState.Connection.ONLINE:
   return {"id":"portal", "title":"PLANETA RECONECTADO", "text":"ENTRE NO PORTAL PARA CONCLUIR A MISSÃO", "icon":"signal"}
  return {"id":"portal_offline", "title":"PORTAL SEM SINAL", "text":"ATIVE O NÓ DE SINAL COM [E / B] PARA ABRIR O PORTAL", "icon":"signal"}
 if WorldState.checkpoint_id=="spawn" and elapsed<8 and absf(pos.x-float(level.spawn[0]))<220 and absf(pos.y-float(level.spawn[1]))<100:
  return {"id":"move", "title":"PLANETA ALIENÍGENA", "text":"[A / D] MOVER • [ESPAÇO / A] PULAR", "icon":"bolt"}
 return {}
func _draw() -> void:
 if WorldState.blockout:
  draw_rect(Rect2(0,-150,float(level.get("length",6400)),1150),Color("101c35").lerp(Color("123552"),online_blend))
 # Blockout retains only the hazard reference; artwork uses the SVG sea node.
 if WorldState.blockout:
  draw_rect(Rect2(0,810,float(level.get("length",6400)),100),Color("073b59"))
  for x in range(0,int(level.get("length",6400)),55): draw_line(Vector2(x,817+sin(clock+x)*4),Vector2(x+24,817+sin(clock+x)*4),Color("37a8be"),2)
 if WorldState.blockout:
  draw_line(rail_a+Vector2(0,10),rail_b+Vector2(0,10),Color(0.1,0.8,1,0.20),18)
  draw_line(rail_a+Vector2(0,10),rail_b+Vector2(0,10),Color("70ffff"),4)
  draw_circle(rail_a+Vector2(0,10),11,Color("4ee1ff"))
  draw_circle(rail_b+Vector2(0,10),11,Color("4ee1ff"))
 # The physical wind region is unchanged; SVG curves show its airflow.
 if WorldState.blockout: draw_rect(wind_rect,Color(0.15,0.85,0.8,0.09))
 if online_blend>0:
  draw_line(Vector2(5400,210),Vector2(6080,205),Color(0.25,1,1,online_blend*0.7),3)
  for i in 16: draw_circle(Vector2(5400+i*44,205+sin(clock*2+i)*10),2,Color(0.3,1,1,online_blend*0.6))
 if WorldState.connection == WorldState.Connection.CONNECTING:
  var radius := (1.3-connection_timer)*500
  draw_arc(point(level.node)+Vector2(0,-45),radius,0,TAU,80,Color(0.3,1,1,0.35 if WorldState.reduced_flash else 0.7),4)
 if show_hits:
  for p in platforms:
   if p.visible: draw_rect(Rect2(p.position,Vector2(p.rect.size.x,20)),Color(1,0.3,0.4,0.6),false,2)
  draw_rect(Rect2(player.position+Vector2(-16,-68),Vector2(32,68)),Color.YELLOW,false,2)
func debug_action(action: String) -> void:
 match action:
  "debug_hits": show_hits = not show_hits
  "debug_speed": debug_speed = not debug_speed
  "debug_state": debug_state = not debug_state
  "debug_respawn": player.die()
  "debug_reset":
   WorldState.reset_progress()
   get_tree().paused = false
   get_tree().reload_current_scene()
  "debug_art": set_art(WorldState.blockout)
  "debug_invincible":
   player.invincible = not player.invincible
   hud.notice("Invencibilidade: "+str(player.invincible))
