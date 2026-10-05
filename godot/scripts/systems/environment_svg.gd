extends Node2D
## Approved coastal decorations. Geometry is entirely visual: zero collision,
## no collection triggers and no replacement of existing gameplay regions.
## Placements: [kind, variant, base_x, base_y, uniform_scale].
const ROOT := "res://assets/world_01/environment/"
var world: Node2D
var clock := 0.0
var metadata: Dictionary = {}
var textures: Dictionary = {}
var items: Array[Dictionary] = []

func texture(id: String) -> Texture2D:
 if not textures.has(id):
  textures[id] = load(ROOT + id + ".svg")
 return textures[id]

func layer(parent: Node2D, id: String, pivot: Vector2) -> Sprite2D:
 var sprite := Sprite2D.new()
 sprite.texture = texture(id)
 sprite.centered = false
 sprite.offset = -pivot
 sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
 parent.add_child(sprite)
 return sprite

func _ready() -> void:
 # Draw above the world's background, beneath platforms and the player.
 z_index = 1
 var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ROOT + "manifest.json"))
 for entry in manifest.get("assets", []):
  metadata[String(entry.id)] = entry
 # Empty placements intentionally means no decorations; the level author
 # controls positions and clear sight lines rather than hidden fallback art.
 for placement in world.level.get("environment", []):
  add_decoration(placement)

func add_decoration(placement: Array) -> void:
 if placement.size() < 5:
  push_warning("Environment placement requires kind, variant, x, y, scale")
  return
 var kind := String(placement[0])
 var variant := int(placement[1])
 var id := kind + "_" + str(variant)
 if not metadata.has(id):
  push_warning("Unknown environment SVG: " + id)
  return
 var entry: Dictionary = metadata[id]
 var factor := float(placement[4])
 if factor <= 0.0:
  return
 var origin := Vector2(float(placement[2]), float(placement[3]))
 var pivot := Vector2(float(entry.pivot[0]), float(entry.pivot[1]))
 var anchor := Node2D.new()
 anchor.position = origin
 anchor.scale = Vector2.ONE * factor
 add_child(anchor)
 var sprite := layer(anchor, id, pivot)
 var lamp: Sprite2D = null
 if kind == "posts":
  lamp = layer(anchor, id + "_lamp", pivot)
  # The cyan layer is dimmed in Offline and lit in Online; its canvas and
  # pivot are exactly the same as the source post, so states never jump.
  sprite.modulate = Color(0.82, 0.84, 0.9)
 items.append({"kind":kind, "variant":variant, "origin":origin,
  "factor":factor, "anchor":anchor, "sprite":sprite, "lamp":lamp,
  "phase":float(items.size()) * 1.618, "reaction":0.0,
  "height":float(entry.canvas[1]) * factor})

func set_art(enabled: bool) -> void:
 visible = enabled
 set_process(enabled)

func _process(dt: float) -> void:
 clock += dt
 var tick := floorf(clock * 12.0) / 12.0
 var blend: float = world.online_blend
 var reduced: bool = WorldState.reduced_flash
 for item in items:
  var anchor: Node2D = item.anchor
  var sprite: Sprite2D = item.sprite
  var kind: String = item.kind
  var phase: float = item.phase
  var origin: Vector2 = item.origin
  var factor: float = item.factor
  match kind:
   "palms", "vegetation":
    var reaction_target := 0.0
    if is_instance_valid(world.player):
     var delta: Vector2 = world.player.global_position - to_global(origin)
     var horizontal_distance := absf(delta.x)
     var passage_radius := 54.0 if kind == "vegetation" else 65.0
     if horizontal_distance < passage_radius and delta.y < 40.0 and delta.y > -item.height - 24.0:
      var speed: float = world.player.velocity.x
      var strength := clampf(absf(speed) / 300.0, 0.0, 1.0)
      # Lean about the source ground pivot, never deform X/Y or move roots.
      reaction_target = signf(speed) * strength * (1.0 - horizontal_distance / passage_radius) * 0.085
    item.reaction = lerpf(float(item.reaction), reaction_target, 1.0-exp(-dt*8.0))
    var sway := sin(tick * 1.1 + phase) * (0.014 if kind == "palms" else 0.026)
    anchor.rotation = snappedf(sway + float(item.reaction), 0.006)
   "posts":
    var lamp: Sprite2D = item.lamp
    var amplitude := 0.035 if reduced else 0.1
    lamp.modulate.a = lerpf(0.14, 0.85 + amplitude * sin(tick * 2.1 + phase), blend)
    sprite.modulate = Color(0.76, 0.79, 0.87).lerp(Color.WHITE, blend)
   "water_props":
    if int(item.variant) == 2:
     # Continuous foam loop uses a slow opacity cycle and 1px translation.
     anchor.position = origin + Vector2(roundf(sin(tick + phase)), 0)
     sprite.modulate.a = 0.68 + 0.18 * sin(tick * 1.8 + phase)
    else:
     anchor.position = origin + Vector2(0, roundf(sin(tick * 1.25 + phase) * 2.0))
     anchor.rotation = snappedf(sin(tick * 0.9 + phase) * 0.015, 0.005)
   "gems":
    var amount := 0.025 if reduced else 0.06
    var pulse := sin(tick * 3.0 + phase)
    anchor.scale = Vector2.ONE * factor * (1.0 + amount * pulse)
    sprite.modulate.a = 0.92 + (0.025 if reduced else 0.075) * pulse
   "wind":
    anchor.position = origin + Vector2(roundf(fposmod(tick * 10.0 + phase, 24.0)-12.0), 0)
    sprite.modulate.a = 0.55 + 0.15 * sin(tick + phase)
