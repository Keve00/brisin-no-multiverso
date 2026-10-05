extends Node
var failures: Array[String] = []
var passed := 0
var pulse_events := 0
var p: BrisinhoPlayer

func check(ok: bool, label: String) -> void:
 if ok:
  passed += 1
  print("PASS: ",label)
 else:
  failures.append(label)
  push_error("FAIL: "+label)

func frames(n: int) -> void:
 for i in n: await get_tree().physics_frame

func _ready() -> void:
 call_deferred("run")

func run() -> void:
 var floor_body := StaticBody2D.new()
 floor_body.collision_layer = 2
 var floor_shape := CollisionShape2D.new()
 var box := RectangleShape2D.new()
 box.size = Vector2(3000,30)
 floor_shape.shape = box
 floor_shape.position = Vector2(0,15)
 floor_body.add_child(floor_shape)
 add_child(floor_body)
 p = load("res://scenes/player/player.tscn").instantiate()
 p.position = Vector2(200,0)
 add_child(p)
 p.pulsed.connect(func(_origin: Vector2) -> void: pulse_events += 1)
 await frames(8)
 var effects = p.action_effects
 check(effects.dash_texture != null and effects.ring_texture != null and effects.spark_texture != null,"SVGs importados e ligados ao jogador")
 check(effects.z_index < 0 and effects.texture_filter==CanvasItem.TEXTURE_FILTER_NEAREST,"efeitos atras do sprite com filtragem nearest")
 Input.action_press("dash")
 await frames(3)
 Input.action_release("dash")
 check(p.state=="DASH" and p.velocity.x==p.tuning.dash_speed and effects.dash_direction==1.0,"input dash direito dispara SVG sem alterar velocidade")
 check(effects.echoes.size()>0,"dash cria ecos de SVG na trilha")
 await frames(30)
 check(effects.echoes.is_empty() and effects.dash_age>=effects.dash_duration,"dash e ecos terminam sem permanecer no cenario")
 p.cooldown=0
 p.dash_available=true
 p.facing=-1
 Input.action_press("dash")
 await frames(3)
 Input.action_release("dash")
 check(effects.dash_direction==-1 and p.velocity.x==-p.tuning.dash_speed,"SVG espelha somente X para dash esquerdo")
 await frames(22)
 p.velocity=Vector2.ZERO
 Input.action_press("pulse")
 await frames(3)
 Input.action_release("pulse")
 var origin: Vector2 = effects.pulse_origin
 check(pulse_events==1 and effects.pulse_age<effects.PULSE_DURATION,"input pulso emite sinal unico e inicia onda SVG")
 p.position.x += 180
 await frames(3)
 check(effects.pulse_origin==origin,"onda permanece no ponto do disparo quando Brisin se move")
 Input.action_press("pulse")
 await frames(3)
 Input.action_release("pulse")
 check(pulse_events==1,"cooldown impede novo pulso e reinicio visual prematuro")
 WorldState.reduced_flash=true
 check(effects.PULSE_RADIUS==140.0 and p.tuning.dash_duration==0.19,"feedback SVG preserva alcance e duracao da fisica")
 await frames(35)
 check(effects.pulse_age>=effects.PULSE_DURATION,"onda termina em 0,55 segundo mesmo com flashes reduzidos")
 effects.start_pulse(p.global_position)
 effects.start_dash(p.global_position,1,p.tuning.dash_duration)
 p.die()
 await frames(3)
 check(effects.pulse_age>=effects.PULSE_DURATION and effects.echoes.is_empty(),"morte limpa pulso e rastros antes do respawn")
 p.change_state("DISABLED")
 effects.start_pulse(p.global_position)
 await frames(3)
 check(effects.pulse_age>=effects.PULSE_DURATION,"estado DISABLED limpa efeitos de gameplay")
 print("RESULT: ",passed," passed / ",failures.size()," failed")
 get_tree().quit(0 if failures.is_empty() else 1)
