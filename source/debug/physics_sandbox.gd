extends Node2D


func _unhandled_input(event: InputEvent) -> void:
	if OS.is_debug_build() and event.is_action_pressed("debug_quit"):
		get_tree().quit()
