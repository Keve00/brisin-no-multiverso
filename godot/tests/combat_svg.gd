extends Node2D
const Combat = preload("res://scripts/player/combat_svg.gd")
const Chip = preload("res://scripts/player/sim_projectile.gd")
var failures: Array[String] = []
var passed := 0
var fixture: TestWorld
var combat: Node2D
var chip_events: Array[Dictionary] = []
var pulse_events := 0

class TestWorld extends Node2D:
 var player: BrisinhoPlayer
 var enemies: Array[Node2D] = []

class Target extends Node2D:
 var alive := true
 var hits := 0
 func combat_bounds() -> Rect2: return Rect2(global_position+Vector2(-26,-56),Vector2(52,56))
 func receive_pulse(_origin: Vector2) -> void: hits += 1
 func eliminate() -> void: alive = false

func check(ok: bool, label: String) -> void:
 if ok:
  passed += 1
  print("PASS: ",label)
 else:
  failures.append(label)
  push_error("FAIL: "+label)

func frames(n: int) -> void:
 for i in n: await get_tree().physics_frame

func target(pos: Vector2) -> Target:
 var enemy := Target.new()
 enemy.position = pos
 fixture.add_child(enemy)
 fixture.enemies.append(enemy)
 return enemy

func projectile(origin: Vector2, direction: float = 1.0) -> Node2D:
 combat.launch_chip(origin,direction)
 var chip: Node2D = combat.get_child(combat.get_child_count()-1)
 chip.set_physics_process(false)
 return chip

func _ready() -> void: call_deferred("run")

func run() -> void:
 fixture = TestWorld.new()
 add_child(fixture)
 fixture.player = load("res://scenes/player/player.tscn").instantiate()
 fixture.player.position = Vector2(0,0)
 fixture.add_child(fixture.player)
 fixture.player.set_physics_process(false)
 fixture.player.invincible = true
 fixture.player.pulsed.connect(func(_origin: Vector2) -> void: pulse_events += 1)
 fixture.player.chip_launched.connect(func(origin: Vector2, direction: float) -> void: chip_events.append({"origin":origin,"direction":direction}))
 combat = Node2D.new()
 combat.set_script(Combat)
 combat.world = fixture
 fixture.add_child(combat)
 combat.set_physics_process(false)
 var actual := Node2D.new()
 actual.set_script(preload("res://scripts/enemies/noisezinho.gd"))
 actual.position=Vector2(2500,500)
 actual.left=2400
 actual.right=2600
 fixture.add_child(actual)
 actual.set_physics_process(false)
 actual.receive_pulse(Vector2(2450,465))
 check(actual.alive and actual.stunned==2 and actual.pulse_hits==1 and actual.sprite.animation==&"hit" and actual.recoil>0,"inimigo real reage com dano, stun e recoil ao pulso")
 actual.eliminate()
 actual.receive_pulse(Vector2(2450,465))
 check(not actual.alive and actual.pulse_hits==1,"pulso nao ressuscita inimigo derrotado")
 var edge := target(Vector2(160,0)) # body begins 134 px away; pivot is outside range.
 var outside := target(Vector2(167,0)) # body begins 141 px away.
 combat.start_pulse(Vector2(0,-35))
 combat._physics_process(0.02)
 check(edge.hits==0,"pulso distante espera a onda chegar ao corpo")
 combat._physics_process(0.34)
 check(edge.hits==1 and outside.hits==0,"pulso usa silhueta real, atinge borda 134 px e respeita limite 140 px")
 combat._physics_process(0.05)
 check(edge.hits==1,"cada onda causa um unico hit por inimigo")
 fixture.player.position.x=400
 check(combat.waves[0].origin==Vector2(0,-35),"origem do pulso nao acompanha jogador")
 combat._physics_process(0.20)
 check(combat.waves.is_empty(),"pulso termina em 0,55 s")
 check(Combat.wave_touches_body(Vector2.ZERO,Rect2(180,-28,52,56),Rect2(-180,-28,52,56),80,85),"onda detecta corpo movel cruzando entre ticks")
 check(not Combat.wave_touches_body(Vector2.ZERO,Rect2(-10,-10,20,20),Rect2(-10,-10,20,20),100,110),"centro transparente da onda nao causa hit atras da borda")
 fixture.player.position=Vector2.ZERO
 fixture.player.pulse_time=0
 fixture.player.set_physics_process(true)
 Input.action_press("pulse")
 await frames(3)
 Input.action_release("pulse")
 await frames(2)
 Input.action_press("pulse")
 await frames(3)
 Input.action_release("pulse")
 fixture.player.set_physics_process(false)
 check(pulse_events==1,"input de pulso tem cooldown e nao reinicia a onda")
 fixture.player.facing=-1
 check(fixture.player.launch_chip(),"chip pode ser lancado pelo jogador")
 check(chip_events.size()==1 and chip_events[0].direction==-1 and chip_events[0].origin==fixture.player.global_position+Vector2(-24,-35),"SIM branco nasce a frente e acompanha direcao esquerda")
 check(not fixture.player.launch_chip(),"cooldown de 0,35 s bloqueia chips repetidos")
 fixture.player._physics_process(0.34)
 check(not fixture.player.launch_chip(),"chip permanece em cooldown antes dos 0,35 s")
 fixture.player._physics_process(0.02)
 fixture.player.facing=1
 check(fixture.player.launch_chip(),"chip libera disparo apos 0,35 s")
 check(chip_events[1].direction==1,"SIM acompanha direcao direita")
 var legacy_key := InputEventKey.new()
 legacy_key.physical_keycode=KEY_B
 InputMap.action_add_event("chip",legacy_key)
 WorldState.setup_inputs()
 WorldState.setup_inputs()
 check(not InputMap.action_has_event("chip",legacy_key),"migracao remove B sem duplicar F ou Y")
 var bindings := InputMap.action_get_events("chip")
 check(bindings.size()==2 and bindings[0] is InputEventKey and bindings[0].physical_keycode==KEY_F and bindings[1] is InputEventJoypadButton and bindings[1].button_index==JOY_BUTTON_Y,"chip usa F no teclado e Y no controle")
 # Collision tests are offset from player and original wave targets.
 var front := target(Vector2(270,500))
 var farther := target(Vector2(390,500))
 var chip := projectile(Vector2(100,465))
 chip._physics_process(0.40)
 check(not front.alive and farther.alive and chip.hit_age==0,"SIM varre percurso inteiro e atinge somente primeiro inimigo")
 check(chip.global_position.x<=front.position.x-26,"impacto para na primeira borda em vez de teleportar atravessando")
 var left_target := target(Vector2(-220,700))
 var left_chip := projectile(Vector2(-100,665),-1)
 left_chip._physics_process(0.30)
 check(not left_target.alive and left_chip.position.x < -100,"SIM esquerdo usa colisao e movimento espelhados")
 var crossing := target(Vector2(130,1000))
 var crossing_chip := projectile(Vector2(100,1065))
 crossing.position.y=1200
 crossing_chip._physics_process(0.10)
 check(not crossing.alive,"SIM detecta inimigo movel que cruza altura do voo entre ticks")
 var wall := StaticBody2D.new()
 wall.collision_layer=2
 wall.position=Vector2(160,1500)
 var shape := CollisionShape2D.new()
 var box := RectangleShape2D.new()
 box.size=Vector2(4,180)
 shape.shape=box
 wall.add_child(shape)
 fixture.add_child(wall)
 await frames(2)
 var behind_wall := target(Vector2(230,1500))
 var wall_chip := projectile(Vector2(100,1465))
 wall_chip._physics_process(0.40)
 check(behind_wall.alive and wall_chip.hit_age==0 and wall_chip.position.x<160,"parede fina bloqueia SIM sem tunneling ou dano atras dela")
 var embedded := projectile(Vector2(160,1465))
 embedded._physics_process(0.01)
 check(embedded.hit_age==0,"SIM nascendo dentro de parede colide imediatamente")
 var range_chip := projectile(Vector2(3000,0))
 range_chip._physics_process(2.0)
 check(range_chip.position.x==3500 and range_chip.is_queued_for_deletion(),"SIM termina em 500 px mesmo com dt longo")
 var text := FileAccess.get_file_as_string("res://assets/player/effects/sim_chip.svg")
 check(text.contains('fill="#FFFFFF"') and not text.contains('opacity'),"asset do SIM tem corpo branco sem opacidade")
 for asset in ["dash_stream","dash_echo","pulse_ring","pulse_spark"]:
  text=FileAccess.get_file_as_string("res://assets/player/effects/"+asset+".svg")
  check(not text.contains('opacity') and text.contains('#FF7A00'),"SVG "+asset+" usa cores vivas sem opacidade")
 await frames(1)
 combat.clear()
 await frames(1)
 combat.start_pulse(Vector2.ZERO)
 var paused_chip := projectile(Vector2(3000,2000))
 paused_chip.set_physics_process(true)
 combat.set_physics_process(true)
 var old_age: float = combat.waves[0].age
 var old_pos: Vector2 = paused_chip.position
 var old_cd := fixture.player.chip_cooldown
 get_tree().paused=true
 await frames(4)
 check(combat.waves[0].age==old_age and paused_chip.position==old_pos and fixture.player.chip_cooldown==old_cd,"pause congela onda, voo e cooldown")
 check(not fixture.player.launch_chip(),"pause rejeita disparo via metodo")
 get_tree().paused=false
 combat.set_physics_process(false)
 paused_chip.set_physics_process(false)
 fixture.player.change_state("RESPAWN")
 combat._physics_process(0.01)
 await frames(1)
 check(combat.waves.is_empty() and combat.get_child_count()==0,"RESPAWN limpa ondas e SIMs")
 fixture.player.change_state("DISABLED")
 fixture.player.velocity=Vector2.ZERO
 fixture.player.bounce()
 fixture.player.hurt()
 check(fixture.player.state=="DISABLED" and fixture.player.velocity==Vector2.ZERO,"chamadas externas de stomp/dano preservam DISABLED")
 combat.start_pulse(Vector2.ZERO)
 combat.launch_chip(Vector2.ZERO,1)
 check(combat.waves.is_empty() and combat.get_child_count()==0 and not fixture.player.launch_chip(),"DISABLED rejeita ondas e SIMs")
 fixture.player.change_state("IDLE")
 combat.start_pulse(Vector2.ZERO)
 projectile(Vector2(3000,2000))
 fixture.player.change_state("DISABLED")
 combat._physics_process(0.01)
 await frames(1)
 check(combat.waves.is_empty() and combat.get_child_count()==0,"DISABLED limpa combate que ja estava ativo")
 print("RESULT: ",passed," passed / ",failures.size()," failed")
 get_tree().quit(0 if failures.is_empty() else 1)
