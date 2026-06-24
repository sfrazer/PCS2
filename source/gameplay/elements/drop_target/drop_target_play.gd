class_name DropTargetPlay
extends StaticBody2D

var _dropped: bool = false


func _on_contact_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("ball") and not _dropped:
		_dropped = true
		$BodyShape.set_deferred("disabled", true)
		$Sprite2D.visible = false
