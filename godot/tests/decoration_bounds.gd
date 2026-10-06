extends Node
var checks:=0
var failures:=0
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures+=1;push_error(label)
func _ready()->void:call_deferred("run")
func run()->void:
 WorldState.reset_progress();WorldState.tutorial_choice_made=true;WorldState.tutorial_session_active=false
 var world=load("res://scenes/world_01/world_01.tscn").instantiate();add_child(world)
 var env=world.environment_svg
 var supported:=0
 for item in env.items:
  if item.kind in ["palms","vegetation","rocks_sand","ruins","posts"]:
   check(not item.support.is_empty(),"land decoration has platform support: "+item.kind)
   supported+=1
   check(is_equal_approx(item.origin.y,item.support.top),"roots use actual shelf height")
 for tick in 64:
  for item in env.items:item.reaction=.10 if tick%2 else -.10
  env._process(.31)
  for item in env.items:
   if item.support.is_empty():continue
   var sprite:Sprite2D=item.sprite
   var ink:Rect2=Rect2(sprite.texture.get_image().get_used_rect());ink.position+=sprite.offset
   for corner in [ink.position,Vector2(ink.end.x,ink.position.y),ink.end,Vector2(ink.position.x,ink.end.y)]:
    var point:Vector2=sprite.global_transform*corner
    check(point.x>=item.support.left and point.x<=item.support.right,"whole decoration and sway stay inside platform")
   check(is_equal_approx(absf(item.anchor.scale.x),absf(item.anchor.scale.y)),"uniform scale")
 for platform in world.platforms:
  if not platform.decoration_texture or not platform.decoration_enabled:continue
  var layout:Rect2=platform.decoration_layout()
  var factor:float=layout.size.x/platform.decoration_texture.get_width()
  var left:float=layout.position.x+platform.decoration_ink.position.x*factor
  var right:float=left+platform.decoration_ink.size.x*factor
  check(left>=0 and right<=platform.rect.size.x,"embedded foliage stays inside platform")
 for platform in world.platforms:
  if platform.position.y==world.level.portal[1] and platform.position.x<=world.level.portal[0] and platform.position.x+platform.rect.size.x>=world.level.portal[0]:
   check(not platform.decoration_enabled,"no platform palm in front of final portal")
 check(supported>30,"audited the whole level")
 print("DECORATION_BOUNDS: ",checks," checks / ",failures," failures")
 get_tree().paused=false;get_tree().quit(0 if failures==0 else 1)
