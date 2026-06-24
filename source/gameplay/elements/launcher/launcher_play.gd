class_name LauncherPlay
extends Node2D

const MAX_FORCE: float = 1200.0

var _charge: float = 0.0
var _charging: bool = false


func _physics_process(delta: float) -> void:
	if Input.is_action_pressed("launch"):
		_charge = minf(_charge + delta * 2.0, 1.0)
		_charging = true
	elif _charging:
		_charging = false
		_fire()


func _fire() -> void:
	var ball: RigidBody2D = get_tree().get_first_node_in_group("ball") as RigidBody2D
	if ball != null:
		ball.apply_central_impulse(Vector2(0.0, -_charge * MAX_FORCE))
	_charge = 0.0
