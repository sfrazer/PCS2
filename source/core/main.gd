extends Node2D


func _ready() -> void:
	if OS.is_debug_build():
		add_child(load("res://source/debug/debug_overlay.tscn").instantiate())
