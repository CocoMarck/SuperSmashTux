class_name PersonConfig
extends RefCounted

# Identity
var id: StringName
var character_name: StringName
var model: String
var position_offset: Vector3

# Momentum
var ground_acceleration: float
var ground_friction: float
var air_acceleration: float
var knockback_friction: float

# Horizontal movement
var walking_speed: int
var running_speed: int

# Vartical movement
var jump_impulse: int 

# Intervals
var walk_step_interval: float
var run_step_interval: float
var crouch_move_step_interval: float

# Duration of anims
var air_jump_duration: float