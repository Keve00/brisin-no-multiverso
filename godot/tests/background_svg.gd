extends Node
const BackgroundSVG = preload("res://scripts/systems/background_svg.gd")
func _ready() -> void:
 var backdrop := Node2D.new()
 backdrop.set_script(BackgroundSVG)
 add_child(backdrop)
 var passed := 0
 for length in [9600.0,15235.0]:
  for x in [576.0,1800.0,length/2,length-576]:
   for y in [280.0,324.0,520.0]:
    var centre:=Vector2(x,y)
    var rect: Rect2=backdrop.panorama_rect(centre,length)
    assert(rect.encloses(Rect2(centre-Vector2(576,324),Vector2(1152,648))),"panorama covers camera across level")
    assert(rect.size==BackgroundSVG.SIZE,"background keeps uniform native scale")
    passed+=2
 assert(BackgroundSVG.PANORAMA.get_size()==BackgroundSVG.SIZE)
 assert(BackgroundSVG.ATMOSPHERE.get_size()==BackgroundSVG.SIZE)
 assert(backdrop.z_index<0 and backdrop.atmosphere_strength==1.0)
 var svg:=FileAccess.get_file_as_string("res://assets/background_svg/cosmic_panorama.svg")
 assert(not "<image" in svg and not "base64" in svg,"panorama contains only vector paths")
 var haze:=FileAccess.get_file_as_string("res://assets/background_svg/atmosphere.svg")
 assert("#d6a58e" in haze and 'fill-opacity="0.1800"' in haze,"warm haze preserves approved opacity bands")
 print("WARM BACKGROUND: ",passed+5," checks passed")
 get_tree().quit()
