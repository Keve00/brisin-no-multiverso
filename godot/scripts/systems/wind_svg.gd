extends Node2D
# SVG wisps rasterize to small textures, then move on the pixel grid in-engine.
# Each whole asset keeps uniform scale. No arrows or chevrons in either mode.
const WISP = preload("res://assets/world_01/svg/wind_wisp.svg")
const LEAF = preload("res://assets/world_01/svg/wind_leaf.svg")
var region := Rect2()
var force := Vector2.UP
var clock := 0.0
var wisps: Array[Sprite2D] = []
var leaves: Array[Sprite2D] = []
func _ready() -> void:
 texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
 position = region.position
 for i in 7:
  var sprite := Sprite2D.new()
  sprite.texture = WISP
  sprite.scale = Vector2.ONE * (0.8 + float(i % 3) * 0.1)
  add_child(sprite)
  wisps.append(sprite)
 for i in 5:
  var sprite := Sprite2D.new()
  sprite.texture = LEAF
  add_child(sprite)
  leaves.append(sprite)
func travel(phase: float, lane: float, margin: float) -> Vector2:
 var along := lerpf(margin, region.size.y - margin, phase)
 var across := lerpf(margin, region.size.x - margin, lane)
 if absf(force.x) > absf(force.y):
  return Vector2(lerpf(margin, region.size.x-margin, phase if force.x>0 else 1.0-phase), lerpf(margin,region.size.y-margin,lane))
 return Vector2(across, along if force.y>0 else region.size.y-along)
func _process(dt: float) -> void:
 clock += dt
 var tick := floorf(clock * 24.0) / 24.0
 var direction_angle := force.angle() + PI / 2.0
 for i in wisps.size():
  var phase := fposmod(tick * 0.31 + float(i)/wisps.size(), 1.0)
  var lane := 0.5 + sin(float(i)*2.4 + tick*0.7)*0.32
  wisps[i].position = travel(phase, lane, 58.0).round()
  wisps[i].rotation = direction_angle
  wisps[i].flip_h = i % 2 == 1
  wisps[i].modulate.a = sin(phase*PI)*0.75
 for i in leaves.size():
  var phase := fposmod(tick * 0.39 + float(i)/leaves.size(), 1.0)
  var lane := 0.5 + sin(float(i)*3.7+tick)*0.36
  leaves[i].position = travel(phase,lane,18.0).round()
  leaves[i].rotation = snappedf(tick*1.3+float(i),TAU/16.0)
  leaves[i].modulate.a = sin(phase*PI)*0.7
 queue_redraw()
func _draw() -> void:
 for i in 18:
  var phase := fposmod(clock*0.36+float(i)/18.0,1.0)
  var lane := fposmod(float(i)*0.381,1.0)
  var p := travel(phase,lane,8.0).round()
  draw_rect(Rect2(p,Vector2.ONE*(2 if i%3 else 3)),Color(1,0.9,0.7,sin(phase*PI)*0.45))
