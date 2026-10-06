extends SceneTree
var count := 0
var output := ""
func _initialize() -> void: call_deferred("run")
func run() -> void:
 output=ProjectSettings.globalize_path("res://docs/light_edges/rasters")
 DirAccess.make_dir_recursive_absolute(output)
 scan("res://assets")
 print("LIGHT_LAYERS_RASTERIZED: ",count)
 quit()
func scan(folder: String) -> void:
 for name in DirAccess.get_directories_at(folder): scan(folder+"/"+name)
 for name in DirAccess.get_files_at(folder):
  if not name.ends_with(".svg") or "_off" in name: continue
  var selected := false
  for key in ["glow","halo","spark","core","lamp","beam","packet","signal","arcs","tunnel","shot"]:
   if key in name: selected=true
  if not selected or "/platforms" in folder or "/menu_svg" in folder or "/ui/mobile" in folder:continue
  var path := folder+"/"+name
  var image := Image.new()
  var error := image.load_svg_from_string(FileAccess.get_file_as_string(path))
  if error != OK:push_error(path);continue
  var filename := path.trim_prefix("res://").replace("/","__")+".png"
  image.save_png(output+"/"+filename)
  count+=1
