extends Node
# Isolated UI/eligibility regression tests; authored objects are held still so
# timer, state and placement checks do not depend on simulated traversal speed.
var world: Node2D
var hud: CanvasLayer
var passes := 0
var failures := 0
func check(ok: bool, message: String) -> void:
 if ok: passes+=1; print("PASS: ",message)
 else: failures+=1; push_error("FAIL: "+message)
func place(pos: Vector2, state: String = "IDLE") -> void:
 world.player.position=pos
 world.player.state=state
 world.player.camera.reset_smoothing()
 world.player.camera.force_update_scroll()
func _ready() -> void:
 call_deferred("run")
func run() -> void:
 # Exercise already acknowledged transient notices; first-read lifecycle has its own suite.
 WorldState.seen_important_notices=["checkpoint", "connecting", "online", "tip:PLANETA ALIENÍGENA", "tip:NÓ DE SINAL", "tip:RUÍDOZINHO", "tip:LANÇAR CHIP", "tip:TRILHA DE SINAL/rail_enter", "tip:TRILHA DE SINAL/rail_exit", "tip:CORRENTE DE VENTO", "tip:PEDRA RACHADA", "tip:DASH DE SINAL", "tip:PLANETA RECONECTADO"]
 world=load("res://scenes/world_01/world_01.tscn").instantiate()
 add_child(world)
 world.set_process(false)
 world.set_physics_process(false)
 world.player.set_physics_process(false)
 hud=world.hud
 hud.set_process(false)
 hud.resume()
 world.elapsed=20
 for enemy in world.enemies: enemy.set_physics_process(false); enemy.set_process(false); enemy.visible=false
 var node: Vector2=world.point(world.level.node)
 place(node)
 hud._process(0.2)
 check(hud.context_hint.visible and hud.context_key=="node","near Offline node offers available pulse")
 var hint: Rect2=hud.context_hint.get_global_rect()
 check(hint.position.y==112 and hint.end.y<=196 and not hint.intersects(hud.player_screen_rect().grow(12)),"context hint fits one slot below HUD and clears character")
 check(hud.context_title.get_theme_font("font")==hud.ui_font and hud.context_icon.texture.resource_path.ends_with("signal.svg"),"context uses HUD font and vector icon")
 place(node+Vector2(0,-80))
 hud._process(0)
 check(hud.context_hint.visible and hud.context_hint.position.y==112,"prompt remains below HUD while player jumps nearby")
 place(node+Vector2(250,0))
 hud._process(0)
 check(not hud.context_hint.visible,"leaving node context immediately hides prompt")
 place(node)
 WorldState.connection=WorldState.Connection.CONNECTING
 hud._process(0)
 check(not hud.context_hint.visible,"completing node action hides Offline instruction")
 WorldState.connection=WorldState.Connection.OFFLINE
 world.player.pulse_time=0.3
 check(world.context_tip().is_empty(),"pulse hint is absent during unavailable pulse cooldown")
 world.player.pulse_time=0
 hud.reset_context_hints()
 hud._process(0.2)
 var read_time:float=hud.context_read_time.node
 hud.notice("PONTO BRISA • Progresso salvo")
 hud._process(1)
 check(not hud.context_hint.visible and hud.context_read_time.node==read_time,"event notice replaces tutorial without consuming its read time")
 hud.timer=0
 hud.show_menu("pause")
 hud._process(1)
 check(not hud.context_hint.visible and hud.context_read_time.node==read_time,"pause hides tutorial and preserves its reading duration")
 hud.resume()
 hud._process(5)
 check(not hud.context_hint.visible,"remaining in one context never leaves permanent tutorial")
 place(node+Vector2(250,0)); hud._process(0)
 place(node); hud._process(0.1)
 check(not hud.context_hint.visible,"reentering read context does not spam the tutorial")
 hud.reset_context_hints(); hud._process(0.1)
 check(hud.context_hint.visible,"respawn reset makes relevant instructions available again")
 place(Vector2(1000,800)); hud._process(0)
 check(not hud.context_hint.visible and world.context_tip().is_empty(),"no fixed signs or unrelated instruction away from mechanics")
 place(node,"RESPAWN"); hud._process(0)
 check(not hud.context_hint.visible,"respawn animation suppresses all gameplay hints")
 place(world.rail_a.lerp(world.rail_b,0.5),"RAIL")
 check(world.context_tip().get("id","")=="rail_exit","rail state offers exit instruction instead of generic movement")
 place(Vector2(590,560))
 check(world.context_tip().get("id","").begins_with("gap_"),"dash tutorial corresponds to real nearby gap")
 world.player.dash_available=false
 check(world.context_tip().is_empty(),"gap tutorial never requests unavailable dash")
 world.player.dash_available=true
 var enemy:Node2D=world.enemies[0]
 enemy.visible=true; enemy.alive=true; enemy.stunned=0
 place(enemy.position+Vector2(-100,0))
 check(world.context_tip().get("id","")=="enemy_0","near live enemy offers combat instruction")
 check(world.context_tip().get("text", "").contains("[F] SOLTA CHIPS"),"close combat tip explicitly teaches F chips below HUD")
 place(enemy.position+Vector2(-300,0))
 world.player.facing=1
 check(world.context_tip().get("id", "")=="enemy_0" and world.context_tip().get("title", "")=="LANÇAR CHIP","ranged enemy ahead offers chip instruction")
 hud.reset_context_hints();hud.timer=0;hud._process(0.1)
 check(hud.context_hint.visible and hud.context_text.text.contains("SOLTA CHIPS") and hud.context_hint.position.y==112,"F chips tip uses the single transient slot below HUD")
 world.player.facing=-1
 check(world.context_tip().get("title", "")!="LANÇAR CHIP","target behind player does not offer firing instruction")
 world.player.facing=1;world.player.chip_cooldown=0.2
 check(world.context_tip().get("title", "")!="LANÇAR CHIP","chip cooldown suppresses ranged firing advice")
 world.player.chip_cooldown=0
 place(enemy.position+Vector2(-520,0))
 check(world.context_tip().get("title", "")!="LANÇAR CHIP","enemy beyond chip range produces no chip tutorial")
 place(enemy.position+Vector2(-300,60))
 check(world.context_tip().get("title", "")!="LANÇAR CHIP","target at incompatible height produces no ranged chip instruction")
 place(enemy.position+Vector2(-300,0))
 var obstacle:=StaticBody2D.new()
 obstacle.collision_layer=2
 obstacle.position=enemy.position+Vector2(-150,-18)
 var obstacle_shape:=CollisionShape2D.new()
 var rectangle:=RectangleShape2D.new()
 rectangle.size=Vector2(6,10)
 obstacle_shape.shape=rectangle
 obstacle.add_child(obstacle_shape);world.add_child(obstacle)
 for tick in 2:await get_tree().physics_frame
 check(world.context_tip().get("title", "")!="LANÇAR CHIP","obstacle clipping chip thickness suppresses advice even when center ray is clear")
 obstacle.queue_free()
 for tick in 2:await get_tree().physics_frame
 check(world.context_tip().get("id", "")=="enemy_0","clearing real flight path restores same encounter context ID")
 place(enemy.position+Vector2(-100,0))
 enemy.stunned=1
 check(not world.context_tip().get("text", "").contains("PULSO"),"stunned enemy no longer asks for another pulse")
 enemy.stunned=0
 enemy.alive=false
 check(not world.context_tip().get("id","").begins_with("enemy_"),"defeated enemy no longer produces combat tutorial")
 enemy.alive=true; enemy.visible=false
 check(not world.context_tip().get("id","").begins_with("enemy_"),"hidden enemy never produces tutorial")
 for body in world.platforms:
  if body.crumble and body.visible:
   place(body.position+Vector2(body.rect.size.x/2,0))
   check(world.context_tip().get("id","").begins_with("crumble_"),"crumbling platform warns only near its reachable surface")
   place(body.position+Vector2(body.rect.size.x/2,60))
   check(not world.context_tip().get("id","").begins_with("crumble_"),"platform above player does not trigger unrelated collapse tutorial")
   break
 WorldState.connection=WorldState.Connection.ONLINE
 place(world.point(world.level.portal)+Vector2(-150,0))
 check(world.context_tip().get("id","")=="portal","portal tutorial appears only near Online exit")
 WorldState.connection=WorldState.Connection.OFFLINE
 check(world.context_tip().get("id","")!="portal","Offline portal never offers completion instruction")
 print("CONTEXT HINTS: ",passes," passed / ",failures," failed")
 get_tree().paused=false
 get_tree().quit(0 if failures==0 else 1)
