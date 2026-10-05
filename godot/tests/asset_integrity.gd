extends SceneTree
# Verifies that the expansion resources load in Godot, beyond XML inspection.
func _initialize() -> void:
 var failures := 0
 var checks := 0
 for variant in ["classic","scout","shield"]:
  var frames := load("res://assets/enemies/ruiduzinho_v2/"+variant+"/spriteframes.tres") as SpriteFrames
  if frames == null:
   push_error("Unable to load variant: "+variant)
   failures += 1
   continue
  for state in ["idle","patrol","alert","hit","defeated"]:
   var valid := frames.has_animation(state)
   if valid:
    valid = frames.get_animation_loop(state) == (state in ["idle","patrol"])
    for i in frames.get_frame_count(state):
     var texture := frames.get_frame_texture(state,i)
     valid = valid and texture != null and texture.get_size() == Vector2(64,64)
   checks += 1
   if not valid:
    push_error("Invalid animation resource: "+variant+"/"+state)
    failures += 1
 var path := "res://assets/world_01/expansion/"
 var data = JSON.parse_string(FileAccess.get_file_as_string(path+"manifest.json"))
 if not data is Dictionary:
  push_error("Expansion manifest cannot be read")
  failures += 1
 # Loading every layered texture catches import/path errors in future-use assets.
 for file in DirAccess.get_files_at(path):
  if file.ends_with(".svg") and not file in ["contact_sheet.svg","animated_preview.svg"]:
   var texture := load(path+file) as Texture2D
   checks += 1
   if texture == null or texture.get_width() <= 0 or texture.get_height() <= 0:
    push_error("Invalid world texture: "+file)
    failures += 1
 print("ASSET INTEGRITY: ",checks," checked / ",failures," failed")
 quit(0 if failures == 0 else 1)
