extends Node
var failures := 0
var checks := 0
func check(ok: bool, text: String) -> void:
 checks += 1
 if not ok:
  failures += 1
  push_error(text)
func _ready() -> void:
 var resource: SpriteFrames = load("res://assets/player/locomotion_svg/spriteframes.tres")
 var metadata: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/player/animations.json"))
 for animation in ["run", "walk", "jump"]:
  var atlas: Image = load("res://assets/player/"+animation+".png").get_image()
  atlas.convert(Image.FORMAT_RGBA8)
  check(resource.get_frame_count(animation)==metadata[animation].frames, animation+" frame count preserved")
  check(resource.get_animation_speed(animation)==12 and resource.get_animation_loop(animation), animation+" timing and loop preserved")
  for frame in resource.get_frame_count(animation):
   var texture: Texture2D = resource.get_frame_texture(animation,frame)
   check(texture.resource_path.ends_with(".svg") and texture.get_size()==Vector2(144,128),animation+" native SVG canvas "+str(frame))
   var image: Image = texture.get_image()
   image.convert(Image.FORMAT_RGBA8)
   var original: Image = atlas.get_region(Rect2i(frame*144,0,144,128))
   var source := original.get_data()
   var vector := image.get_data()
   var same_alpha := true
   for pixel in range(3,source.size(),4):
    if abs(int(source[pixel])-int(vector[pixel]))>1:
     same_alpha=false
     break
   check(same_alpha and image.get_used_rect()==original.get_used_rect(),animation+" silhouette/alpha/feet unchanged "+str(frame))
 print("LOCOMOTION_SVG_RESULT: ",checks," checks / ",failures," failures")
 get_tree().quit(0 if failures==0 else 1)
