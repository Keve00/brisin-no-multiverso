extends Node
const Enemy = preload("res://scripts/enemies/noisezinho.gd")
var failures := 0
var checks := 0
func check(ok: bool, message: String) -> void:
 checks += 1
 if not ok: failures += 1;push_error(message)
func _ready() -> void:
 call_deferred("run")
func run() -> void:
 var data=JSON.parse_string(FileAccess.get_file_as_string("res://data/world_01.json"))
 var enemies:Array[Node2D]=[]
 for name in data.enemy_variants:
  var enemy:=Node2D.new();enemy.set_script(Enemy);enemy.variant=name;add_child(enemy);enemies.append(enemy)
  var frames:SpriteFrames=enemy.sprite.sprite_frames
  for state in ["idle","patrol","alert","hit","defeated"]:
   var unique:Dictionary={}
   for i in frames.get_frame_count(state):
    var texture=frames.get_frame_texture(state,i)
    unique[FileAccess.get_file_as_string(texture.resource_path).hash()]=true
    check(texture.get_size()==Vector2(128,128),name+" canvas stays fixed")
   check(unique.size()>=4,name+" "+state+" has distinct poses")
   check(frames.get_animation_loop(state)==(state in ["idle","patrol"]),name+" finite/loop lifecycle")
  var body:Rect2=enemy.combat_bounds()
  check(body.end.y==enemy.global_position.y,name+" hitbox ends at ground")
  if name=="etzinho":check(body.size.y==86,"larger alien has matching combat area")
  enemy.receive_pulse(enemy.position)
 await get_tree().create_timer(.65).timeout
 for enemy in enemies:check(enemy.alive and enemy.sprite.animation==&"idle",enemy.variant+" recovers hit into animated stun idle")
 await get_tree().create_timer(1.5).timeout
 for enemy in enemies:
  check(enemy.sprite.animation==&"patrol",enemy.variant+" resumes walk")
  enemy.eliminate()
 await get_tree().create_timer(.65).timeout
 for enemy in enemies:check(enemy.visible and enemy.sprite.animation==&"defeated",enemy.variant+" death plays before hiding")
 await get_tree().create_timer(1).timeout
 for enemy in enemies:
  check(not enemy.visible,enemy.variant+" finite death hides")
  enemy.reset()
  check(enemy.visible and enemy.alive and enemy.sprite.animation==&"patrol",enemy.variant+" reset restores walking")
 print("COSMIC_ANIMATION_RESULT: ",checks," checks / ",failures," failures")
 get_tree().quit(0 if failures==0 else 1)
