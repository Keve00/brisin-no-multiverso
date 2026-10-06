class_name PlayerTuning
extends Resource
@export var speed := 290.0
@export var acceleration := 1900.0
@export var deceleration := 2200.0
@export var jump_velocity := -490.0
@export var gravity := 1350.0
@export var fall_multiplier := 1.2
@export var coyote_time := 0.12
@export var jump_buffer := 0.12
@export var dash_speed := 780.0
@export var dash_duration := 0.19
@export var dash_cooldown := 0.40
@export var rail_speed := 470.0

# Touch assistance is a separate profile; desktop parameters remain unchanged.
@export var mobile_coyote_time := 0.16
@export var mobile_jump_buffer := 0.18
