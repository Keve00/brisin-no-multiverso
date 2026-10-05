extends Node
const BackgroundSVG = preload("res://scripts/systems/background_svg.gd")
func _ready() -> void:
 var backdrop := Node2D.new()
 backdrop.set_script(BackgroundSVG)
 add_child(backdrop)
 var passed := 0
 for camera_x in [576.0,1800.0,4500.0,7000.0,9024.0]:
  var centre := Vector2(camera_x,324)
  var rect: Rect2 = backdrop.panorama_rect(centre,9600)
  var viewport := Rect2(centre-Vector2(576,324),Vector2(1152,648))
  assert(rect.encloses(viewport),"Approved panorama must cover every camera boundary")
  assert(is_equal_approx(rect.size.x/2172.0,rect.size.y/724.0),"Backdrop cannot stretch")
  passed+=2
 for i in BackgroundSVG.ROTORS.size():
  var rotor: Texture2D = BackgroundSVG.ROTORS[i]
  assert(rotor.get_width()==rotor.get_height(),"Rotor padding must be square about its measured pivot")
  passed+=1
 assert(BackgroundSVG.PIVOTS.size()==3)
 assert(BackgroundSVG.SPEEDS.min()>0)
 passed+=2
 assert(BackgroundSVG.ATMOSPHERE.get_size()==BackgroundSVG.SIZE,"Atmosphere must share the approved canvas to cover camera bounds without stretch")
 assert(backdrop.z_index<0,"Atmosphere must remain behind the gameplay plane")
 passed+=2
 assert(backdrop.ripple_positions.size()==19,"Far sea ripples occupy approved sea-only regions")
 assert(BackgroundSVG.RIPPLE.get_size()==Vector2(64,12),"Ripple is a small vector module, not a scaled panorama")
 passed+=2
 print("BACKGROUND SVG PASS %d/19" % passed)
 get_tree().quit()
