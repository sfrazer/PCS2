class_name PopBumperPlay
extends StaticBody2D

const BUMPER_FORCE: float = 400.0


func _on_contact_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("ball"):
		var direction: Vector2 = (body.global_position - global_position).normalized()
		(body as RigidBody2D).apply_central_impulse(direction * BUMPER_FORCE)
