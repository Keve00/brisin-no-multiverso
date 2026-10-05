extends Node
var checks:=0
var failures:=0
func check(ok:bool,message:String)->void:
 if not ok:
  failures+=1
  push_error(message)
 checks+=1
func _ready()->void:call_deferred("run")
func run()->void:
 WorldState.reset_progress()
 WorldState.tutorial_choice_made=true
 WorldState.tutorial_session_active=false
 var manifest:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://docs/cosmic_assets_manifest.json"))
 for asset in manifest.assets:
  var path:String="res://"+String(asset.path).trim_prefix("godot/")
  var content:=FileAccess.get_file_as_string(path)
  check(("<path" in content or path.ends_with("_deco.svg")) and not "<image" in content and not "base64" in content,"vector geometry: "+path)
  var texture:Texture2D=load(path)
  check(texture.get_size()==Vector2(asset.canvas[0],asset.canvas[1]),"canvas matches metadata: "+path)
 var world=load("res://scenes/world_01/world_01.tscn").instantiate()
 add_child(world)
 var variants:Dictionary={}
 for enemy in world.enemies:
  variants[enemy.variant]=true
  check(enemy.sprite.sprite_frames.resource_path.contains("/cosmic/"),"actual encounter uses new art")
  check(enemy.sprite.scale==Vector2.ONE and enemy.sprite.offset==Vector2(0,-48),"enemy keeps physical size and ground pivot")
  for state in ["idle","patrol","alert","hit","defeated"]:
   check(enemy.sprite.sprite_frames.has_animation(state),"encounter has complete state lifecycle")
 check(variants.size()==9,"all nine approved palettes appear in reachable encounters")
 for marker in world.markers:
  if marker.kind!="checkpoint":continue
  check(marker.alien_flags.off.size()==8 and marker.alien_flags.on.size()==8,"checkpoint has both cloth animation states")
  check(marker.ALIEN_CHECKPOINT_OFF.get_size()==marker.ALIEN_CHECKPOINT_ON.get_size(),"checkpoint cannot jump size on activation")
 for x in [576.0,2500.0,7600.0,14659.0]:
  var center:=Vector2(x,324)
  check(world.background_svg.panorama_rect(center,15235).encloses(Rect2(center-Vector2(576,324),Vector2(1152,648))),"panorama covers camera bounds")
 world.hud.show_menu("intro")
 check(world.hud.title_screen.get_node("TitleSubtitle").text=="CONEXÃO DE OUTRO MUNDO","title is the approved phrase")
 for child in world.hud.title_screen.get_children():
  if child is Label:check(not child.text.to_upper().contains("CONEXÃO DO PLANETA"),"removed footer is absent")
 get_tree().paused=false
 world.queue_free()
 await get_tree().process_frame
 print("COSMIC_ASSETS: ",checks," checks / ",failures," failures")
 get_tree().quit(0 if failures==0 else 1)
