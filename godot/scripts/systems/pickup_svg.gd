extends Node2D
# A single collection event produces three readable SVG phases, then frees itself.
var textures: Array[Texture2D] = []
var age := 0.0
var duration := 0.48
func _ready() -> void:
 texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
 z_index = 8
 for i in 3: textures.append(load("res://assets/world_01/environment/pickup_%d.svg" % i))
func _process(dt: float) -> void:
 age += dt
 if age >= duration:
  queue_free()
  return
 queue_redraw()
func _draw() -> void:
 if textures.size() != 3: return
 var phase := 0 if age<0.12 else (1 if age<0.28 else 2)
 var alpha := 1.0 if age < duration*0.65 else (duration-age)/(duration*0.35)
 # Reduced flashes preserve a slower, dimmer effect instead of hiding feedback.
 if WorldState.reduced_flash: alpha *= 0.65
 draw_texture_rect(textures[phase],Rect2(Vector2(-32,-32),Vector2(64,64)),false,Color(1,1,1,alpha))
