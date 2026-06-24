class_name FlipperRightPlay
extends AnimatableBody2D

const REST_OFFSET: float = -30.0
const RAISED_OFFSET: float = 30.0
const LERP_SPEED: float = 25.0
const ACTION: String = "flipper_right"

var _base_rotation: float = 0.0


func _ready() -> void:
	_base_rotation = rotation_degrees
	sync_to_physics = true


func _physics_process(delta: float) -> void:
	var pressed: bool = Input.is_action_pressed(ACTION)
	var offset: float = RAISED_OFFSET if pressed else REST_OFFSET
	var target: float = _base_rotation + offset
	rotation_degrees = lerp(rotation_degrees, target, clampf(LERP_SPEED * delta, 0.0, 1.0))
