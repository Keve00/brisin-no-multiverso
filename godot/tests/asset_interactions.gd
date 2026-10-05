extends Node
var failures: Array[String] = []
var passed := 0
func check(ok: bool, label: String) -> void:
 if ok:
  passed += 1
  print("PASS: ",label)
 else:
  failures.append(label)
  push_error(label)
func frames(count: int) -> void:
 for i in count: await get_tree().physics_frame
func _ready() -> void:
 call_deferred("run")
func run() -> void:
 WorldState.reset_progress()
 var world = load("res://scenes/world_01/world_01.tscn").instantiate()
 add_child(world)
 var player: CharacterBody2D = world.player
 await frames(6)
 check(world.environment_svg.items.size()==world.level.environment.size(),"todas as decorações da fase instanciadas")
 check(world.environment_svg.z_index>0 and player.z_index>world.environment_svg.z_index,"cenário fica acima do fundo e abaixo do jogador")
 var online_patrol:Node2D=world.enemies[-1]
 check(online_patrol.get_meta("online_only") and not online_patrol.visible,"Ruídozinho da plataforma Online fica oculto Offline")
 var kinds: Dictionary = {}
 var cracked: Node2D
 var hover: Node2D
 for body in world.platforms:
  kinds[body.variant]=true
  if body.crumble: cracked=body
  if body.variant=="signal" and body.moving: hover=body
 check(kinds.size()==9,"nove famílias de plataformas presentes na fase")
 check(is_instance_valid(hover) and not hover.visible and hover.collision_layer==0,"plataforma de sinal não colide Offline")
 player.position=Vector2(250,530)
 player.velocity=Vector2.ZERO
 player.change_state("IDLE")
 await frames(8)
 check(WorldState.fragments.count("f_0")==1,"gema registra coleta uma vez")
 var effects := 0
 for child in world.get_children():
  if child.get_script()==load("res://scripts/systems/pickup_svg.gd"): effects+=1
 check(effects==1,"coleta cria um único efeito em SVG")
 await frames(40)
 effects=0
 for child in world.get_children():
  if child.get_script()==load("res://scripts/systems/pickup_svg.gd"): effects+=1
 check(effects==0 and WorldState.fragments.count("f_0")==1,"efeito termina sem repetir coleta")
 player.position=Vector2(cracked.position.x+60,cracked.position.y-6)
 player.velocity=Vector2(0,100)
 player.change_state("IDLE")
 player.rail_lock=1
 await frames(12)
 check(cracked._crumble_state=="telegraph" and cracked.visible,"pisar na pedra inicia aviso antes da queda")
 await frames(36)
 check(cracked._crumble_state=="absent" and not cracked.visible,"pedra cai após o aviso e desativa sua superfície")
 player.position=Vector2(7350,335)
 player.velocity=Vector2.ZERO
 await frames(130)
 check(cracked.visible,"pedra retorna quando jogador saiu da área")
 cracked.reset_state()
 await frames(2)
 check(cracked._crumble_state=="intact" and cracked.position==cracked.home,"respawn restaura pedra e pivô originais")
 WorldState.connection=WorldState.Connection.ONLINE
 world.apply_connection()
 check(online_patrol.visible,"conexão revela o Ruídozinho na plataforma Online")
 await frames(4)
 check(hover.visible and hover.collision_layer!=0,"conexão ativa plataforma de sinal e colisão")
 var before: Vector2=hover.position
 await frames(12)
 check(hover.position!=before and absf(hover.position.y-hover.home.y)<=6.01,"hover move corpo e colisão com amplitude limitada")
 var stepped: Node2D
 for body in world.platforms:
  if body.variant=="steps": stepped=body;break
 check(stepped._shapes.size()==3,"plataforma em degraus tem três superfícies físicas")
 check(world.extra_wind_nodes[0].visible,"conexão ativa corrente de vento da rota extra")
 check(world.enemies.size()==5,"cinco Ruídozinhos instanciados para o desafio")
 var added_patrol: Node2D=world.enemies[2]
 world.on_pulse(added_patrol.position+Vector2(0,-25))
 check(added_patrol.stunned>0,"pulso alcança os Ruídozinhos adicionais")
 added_patrol.reset()
 # Reach the first bonus island by actual inputs from the lower safe path.
 var entry: Node2D
 for body in world.platforms:
  if body.crumble and body.variation==0: entry=body;break
 entry.reset_state()
 player.position=Vector2(6540,339)
 player.velocity=Vector2.ZERO
 player.change_state("IDLE")
 await frames(5)
 Input.action_press("jump");Input.action_press("move_right")
 await frames(14)
 Input.action_release("move_right")
 Input.action_release("jump")
 var reached_entry := false
 # Cracked platforms start falling shortly after landing; record the first contact
 # instead of checking after the full telegraph could already have elapsed.
 for i in 24:
  await frames(1)
  if entry._standing_on_platform(): reached_entry = true
 check(reached_entry,"rota de gemas alcançável por salto a partir do caminho seguro")
 world.on_respawn()
 await frames(2)
 check(cracked._crumble_state=="intact" and hover.visible,"retorno ao checkpoint restaura plataformas e mantém conexão")
 print("ASSET_INTERACTIONS_RESULT: ",passed," passed / ",failures.size()," failed")
 get_tree().quit(0 if failures.is_empty() else 1)
