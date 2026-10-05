extends Node
var world: Node2D
var p: BrisinhoPlayer
var checks: Array[String] = []
var failures: Array[String] = []
func frames(n: int) -> void:
 for i in n:
  if is_instance_valid(world) and world.hud.important_active:
   world.hud.important_age=.3
   world.hud.dismiss_important_notice()
  await get_tree().physics_frame
func check(ok: bool, label: String) -> void:
 if ok: checks.append(label);print("PASS: ",label)
 else: failures.append(label);push_error("FAIL: "+label)
func press(action: String) -> void:
 Input.action_press(action)
func release(action: String) -> void:
 Input.action_release(action)
func reset_at(pos: Vector2) -> void:
 for action in ["move_left","move_right","jump","dash","pulse","chip"]: release(action)
 p.position = pos
 p.velocity = Vector2.ZERO
 p.change_state("IDLE")
 p.dash_time = 0
 p.cooldown = 0
 p.rail_lock = 1
 p.dash_available = true
 p.invulnerability = 0
func _ready() -> void:
 call_deferred("run")
func run() -> void:
 world = load("res://scenes/world_01/world_01.tscn").instantiate()
 add_child(world)
 p = world.player
 await frames(18)
 check(p.is_on_floor(),"spawn seguro no piso")
 press("move_right")
 await frames(16)
 check(absf(p.velocity.x-290)<2,"aceleração até velocidade configurada")
 release("move_right")
 await frames(12)
 check(absf(p.velocity.x)<1,"desaceleração")
 reset_at(Vector2(350,550));await frames(5)
 press("jump");await frames(3)
 check(p.velocity.y<0 and not p.is_on_floor(),"pulo")
 release("jump");await frames(4)
 check(p.velocity.y > -200,"pulo variável ao soltar")
 reset_at(Vector2(609,550));await frames(5)
 press("move_right");await frames(11)
 check(not p.is_on_floor() and p.coyote>0,"janela de coyote depois da borda")
 press("jump");await frames(2)
 check(p.velocity.y < -350,"coyote permite pular depois da borda")
 reset_at(Vector2(400,538));p.velocity.y=250
 press("jump");await frames(10)
 check(p.position.y<530 and p.velocity.y<0,"jump buffer dispara ao aterrissar")
 reset_at(Vector2(400,400));await frames(1)
 press("dash");await frames(3)
 check(p.state=="DASH" and p.velocity.x>700,"dash aéreo")
 release("dash");await frames(14)
 var available := p.dash_available
 press("dash");await frames(2)
 check(not available and p.state!="DASH","somente um dash por salto")
 reset_at(Vector2(1480,680));await frames(32)
 check(p.position.y<640 and p.velocity.y<0,"vento levanta personagem")
 reset_at(Vector2(2480,270));p.rail_lock=0;await frames(5)
 check(p.state=="RAIL","entrada automática no rail")
 press("jump");await frames(3)
 check(p.state!="RAIL" and p.velocity.y<0,"saída do rail por pulo")
 reset_at(Vector2(2450,266));p.rail_lock=0;await frames(95)
 check(p.position.x>3080 and p.state!="RAIL","saída automática segura do rail")
 reset_at(Vector2(2080,315));await frames(12)
 check(WorldState.checkpoint_id=="brisa_01","checkpoint salva posição")
 p.position=Vector2(900,1000);await frames(25)
 check(p.position.distance_to(WorldState.checkpoint)<15,"queda e retorno ao checkpoint")
 world.enemy.reset();reset_at(Vector2(world.enemy.position.x,230));p.velocity.y=300;await frames(12)
 check(not world.enemy.alive,"stomp derrota Ruídozinho")
 world.enemy.reset();reset_at(Vector2(1695,310));await frames(1)
 press("dash");await frames(9)
 check(not world.enemy.alive,"dash derrota Ruídozinho")
 world.enemy.reset();reset_at(Vector2(1750,310));p.invulnerability=1;await frames(4)
 world.on_pulse(p.position+Vector2(0,-35))
 await frames(12)
 check(world.enemy.stunned>0,"onda de pulso alcança e interrompe inimigo")
 reset_at(Vector2(250,530));await frames(5)
 check("f_0" in WorldState.fragments,"coleta fragmento")
 check(world.bridge.collision_layer==0,"ponte desligada antes da conexão")
 reset_at(Vector2(5400,335));await frames(5)
 press("pulse");await frames(3)
 check(WorldState.connection==WorldState.Connection.CONNECTING,"pulso inicia conexão do Nó")
 release("pulse");await frames(90)
 check(WorldState.connection==WorldState.Connection.ONLINE and world.bridge.collision_layer==2,"conexão energiza ponte e portal")
 # Percurso inteiro sem teleporte: mesmas ações que o teclado, no blockout.
 WorldState.reset_progress()
 world.queue_free();await frames(3)
 world=load("res://scenes/world_01/world_01.tscn").instantiate();add_child(world);p=world.player
 await frames(8)
 var route_jumps := [570.0,1010.0,1390.0,2125.0,2580.0,3285.0,3705.0,4400.0,4910.0]
 var next_jump := 0
 var jump_age := 0
 var dash_pending := false
 var route_dead := false
 var route_dash_release_frame := -1
 var route_chip_release_frame := -1
 press("move_right")
 for i in 1800:
  if p.state=="RESPAWN": route_dead=true;break
  if next_jump<route_jumps.size() and p.position.x>=route_jumps[next_jump] and p.is_on_floor():
   press("jump");jump_age=0
   dash_pending=next_jump in [6]
   next_jump+=1
  if Input.is_action_pressed("jump"):
   jump_age+=1
   if dash_pending and jump_age==18: press("dash")
   if jump_age==34: release("jump");release("dash");dash_pending=false
  if route_dash_release_frame==i: release("dash")
  if route_chip_release_frame==i: release("chip")
  for threat in world.enemies:
   if threat.alive and threat.visible and p.chip_cooldown<=0 and threat.position.x-p.position.x>48 and threat.position.x-p.position.x<350 and absf(threat.position.y-p.position.y)<40:
    press("chip")
    route_chip_release_frame=i+2
   if threat.alive and threat.visible and p.dash_available and p.cooldown<=0 and p.state!="DASH" and p.is_on_floor() and absf(p.position.x-threat.position.x)<110:
    press("dash")
    route_dash_release_frame=i+2
  if p.position.x>5300: release("move_right");break
  await frames(1)
 check(not route_dead and p.position.x>5300,"percurso spawn → vento → inimigo → checkpoint → rail → dash → Nó sem teleporte")
 print("ROUTE_POSITION ",p.position," jumps ",next_jump)
 # Final por inputs depois da aproximação ao Nó.
 if p.position.x>5300:
  press("move_right");await frames(14);release("move_right");press("pulse");await frames(2);release("pulse");await frames(95)
  var final_jumps := [6320.0,6690.0,6895.0,7060.0,7990.0,8490.0,8990.0,9550.0,10050.0,10550.0,10990.0,11490.0,11990.0,12490.0,13198.0,13710.0,14210.0,14710.0]
  var final_jump := 0
  var final_jump_age := 0
  var dash_release_frame := -1
  var chip_release_frame := -1
  var brake_for_landing := false
  press("move_right")
  for i in 2600:
   if p.state == "RESPAWN":
    break
   if p.state == "DISABLED": break
   if final_jump < final_jumps.size() and p.position.x >= final_jumps[final_jump] and p.is_on_floor():
    press("jump")
    final_jump_age = 0
    final_jump += 1
   # Land on the narrow platform before starting the next gap jump.
   if final_jump == 3 and p.position.x >= 6990 and not p.is_on_floor():
    release("move_right")
    brake_for_landing = true
   elif brake_for_landing and p.is_on_floor():
    press("move_right")
    brake_for_landing = false
   if Input.is_action_pressed("jump"):
    final_jump_age += 1
    if final_jump_age == 34: release("jump")
   if dash_release_frame == i: release("dash")
   if chip_release_frame == i: release("chip")
   for threat in world.enemies:
    if threat.alive and threat.visible and p.chip_cooldown<=0 and threat.position.x-p.position.x>48 and threat.position.x-p.position.x<350 and absf(threat.position.y-p.position.y)<40:
     press("chip")
     chip_release_frame=i+2
    if threat.alive and threat.visible and p.dash_available and p.cooldown<=0 and p.state!="DASH" and p.is_on_floor() and absf(p.position.x-threat.position.x)<100:
     press("dash")
     dash_release_frame=i+2
   await frames(1)
  release("move_right");release("jump")
  print("EXTENSION_POSITION ",p.position," jumps ",final_jump)
  check(world.portal_transition_active and not WorldState.completed,"portal inicia animação sem concluir instantaneamente")
  await frames(125)
  check(WorldState.completed and p.state=="DISABLED","portal conclui demo após terminar a animação")
 get_tree().paused=false
 var report = {"passed":checks,"failed":failures,"engine":Engine.get_version_info().string,"mode":"blockout" if WorldState.blockout else "art"}
 var f := FileAccess.open("res://docs/test_results.json",FileAccess.WRITE)
 f.store_string(JSON.stringify(report,"  "));f.close()
 print("RESULT: ",checks.size()," passed / ",failures.size()," failed")
 get_tree().quit(0 if failures.is_empty() else 1)
