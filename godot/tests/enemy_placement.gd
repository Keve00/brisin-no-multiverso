extends Node
var failures: Array[String] = []
var checks := 0
func check(ok: bool, label: String) -> void:
 checks += 1
 if not ok: failures.append(label);push_error(label)
func frames(count: int) -> void:
 for index in count: await get_tree().physics_frame
func _ready() -> void:
 call_deferred("run")
func supported(enemy: Node2D) -> bool:
 if not is_instance_valid(enemy.support): return false
 for shape in enemy.support._shapes:
  if shape.disabled or not shape.shape is RectangleShape2D: continue
  var box: RectangleShape2D = shape.shape
  var corner: Vector2 = enemy.support.position+shape.position-box.size/2
  if absf(enemy.position.y-corner.y)<0.25 and enemy.position.x>=corner.x+enemy.FOOT_MARGIN-0.1 and enemy.position.x<=corner.x+box.size.x-enemy.FOOT_MARGIN+0.1:
   return true
 return false
func run() -> void:
 WorldState.reset_progress()
 var world = load("res://scenes/world_01/world_01.tscn").instantiate()
 add_child(world)
 world.player.change_state("DISABLED")
 world.player.set_physics_process(false)
 for enemy in world.enemies:
  check(is_instance_valid(enemy.support),"patrulha encontra colisão real")
  check(enemy.left<=enemy.right,"limites de patrulha ordenados")
 await frames(3)
 var elevated = world.enemies[-1]
 check(not elevated.visible,"inimigo de plataforma Online ausente Offline")
 elevated.pulse(elevated.position)
 check(elevated.stunned==0,"pulso não atinge encontro sem plataforma presente")
 WorldState.connection = WorldState.Connection.ONLINE
 world.apply_connection()
 await frames(3)
 check(elevated.visible and elevated.support.moving,"encontro elevado acompanha sinal móvel Online")
 var moving_y: float = elevated.position.y
 # Sample > one full hover period and enough patrol time to hit both edges.
 for sample in 80:
  await frames(8)
  for enemy in world.enemies:
   check(supported(enemy),"pés e margens sobre colisão durante patrulha: "+str(sample)+" at "+str(enemy.position)+" support "+str(enemy.support.position))
 check(absf(elevated.position.y-moving_y)>0.2,"pivô segue movimento vertical da plataforma")
 elevated.eliminate()
 await frames(120)
 world.apply_connection()
 await frames(2)
 check(not elevated.visible,"sincronizar Online não ressuscita inimigo derrotado")
 world.on_respawn()
 await frames(3)
 check(elevated.alive and elevated.visible and supported(elevated),"respawn restaura encontro sobre a plataforma reiniciada")
 WorldState.connection = WorldState.Connection.OFFLINE
 world.apply_connection()
 await frames(3)
 check(not elevated.visible,"desligar plataforma esconde encontro e suspende contato")
 print("ENEMY_PLACEMENT_RESULT: ",checks," checks, ",failures.size()," failures")
 get_tree().quit(0 if failures.is_empty() else 1)
