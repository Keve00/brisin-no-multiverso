extends Node
const Enemy = preload("res://scripts/enemies/noisezinho.gd")
var failures: Array[String] = []
func check(ok: bool, message: String) -> void:
 if ok: print("PASS: ",message)
 else: failures.append(message);push_error(message)
func wait(seconds: float) -> void:
 await get_tree().create_timer(seconds).timeout
func _ready() -> void:
 call_deferred("run")
func run() -> void:
 var enemy = Node2D.new()
 enemy.set_script(Enemy)
 enemy.position = Vector2(enemy.left+30,320)
 add_child(enemy)
 check(enemy.sprite.animation==&"patrol","patrulha usa sprite animado")
 enemy.pulse(enemy.position+Vector2(0,-25))
 check(enemy.alive and enemy.sprite.animation==&"hit","pulso mostra dano sem eliminar")
 await wait(0.6)
 check(enemy.sprite.animation==&"idle" and enemy.stunned>0,"dano termina em espera durante atordoamento")
 await wait(1.6)
 check(enemy.sprite.animation==&"patrol","patrulha retoma depois do atordoamento")
 enemy.eliminate()
 check(not enemy.alive and enemy.visible and enemy.sprite.animation==&"hit","eliminação desativa contato mas mantém dano visível")
 await wait(0.6)
 check(enemy.visible and enemy.sprite.animation==&"defeated","desintegração aparece antes de esconder")
 await wait(1.0)
 check(not enemy.visible,"esconde somente após animação de derrota")
 enemy.reset()
 check(enemy.alive and enemy.visible and enemy.sprite.animation==&"patrol","reset recupera vida, visibilidade e animação")
 enemy.eliminate()
 await wait(0.2)
 enemy.reset()
 await wait(1.4)
 check(enemy.alive and enemy.visible and enemy.sprite.animation==&"patrol","reset interrompe derrota pendente")
 enemy.direction=-1
 await get_tree().physics_frame
 await get_tree().physics_frame
 check(enemy.sprite.flip_h,"sprite acompanha direção da patrulha")
 var player = load("res://scenes/player/player.tscn").instantiate()
 add_child(player)
 player.set_physics_process(false)
 player.position = enemy.position+Vector2(-100,0)
 player.change_state("IDLE")
 enemy.player = player
 enemy.alerted = false
 await get_tree().physics_frame
 await get_tree().physics_frame
 check(enemy.sprite.animation==&"alert","aproximação do jogador mostra alerta")
 await wait(0.8)
 check(enemy.sprite.animation==&"patrol","alerta termina e patrulha continua")
 print("ENEMY_ANIMATION_RESULT: ",failures.size()," failures")
 get_tree().quit(0 if failures.is_empty() else 1)
