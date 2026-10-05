extends Node2D
func _ready() -> void:
 call_deferred("run")
func run() -> void:
 var data=JSON.parse_string(FileAccess.get_file_as_string("res://data/world_01.json"))
 var sprites:Array[AnimatedSprite2D]=[]
 for i in data.enemy_variants.size():
  var name:String=data.enemy_variants[i]
  var sprite:=AnimatedSprite2D.new()
  sprite.sprite_frames=load("res://assets/enemies/cosmic/"+name+"/spriteframes.tres")
  sprite.position=Vector2(120+(i%5)*220,170+(i/5)*250)
  sprite.scale=Vector2.ONE*1.8
  sprite.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
  add_child(sprite);sprites.append(sprite)
  var label:=Label.new();label.text=name.to_upper();label.position=sprite.position+Vector2(-55,115);add_child(label)
 for state in ["idle","patrol","alert","hit","defeated"]:
  for sprite in sprites:
   sprite.animation=state;sprite.frame=2 if state=="defeated" else 3
  for i in 3:await get_tree().process_frame
  await RenderingServer.frame_post_draw
  get_viewport().get_texture().get_image().save_png("res://docs/cosmic_qa/revised_enemies_"+state+".png")
 get_tree().quit()
