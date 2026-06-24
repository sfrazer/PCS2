class_name PlayScene
extends Node2D

var table_data: TableData = null

signal back_requested

@onready var _physics_elements: Node2D = $TableViewportContainer/TableViewport/PhysicsElements
@onready var _viewport: SubViewport = $TableViewportContainer/TableViewport


func _ready() -> void:
	_build_table()
	_spawn_ball()


func _build_table() -> void:
	for entry: Dictionary in table_data.elements:
		var scene: PackedScene = ElementRegistry.get_play_scene(entry["type"])
		var node: Node2D = scene.instantiate() as Node2D
		node.position = Vector2(entry["x"], entry["y"])
		node.rotation_degrees = entry["rotation"]
		_physics_elements.add_child(node)


func _spawn_ball() -> void:
	var ball_scene: PackedScene = load("res://source/gameplay/ball/ball.tscn") as PackedScene
	var ball: RigidBody2D = ball_scene.instantiate() as RigidBody2D
	ball.position = _find_spawn_position()
	_viewport.add_child(ball)


func _find_spawn_position() -> Vector2:
	for entry: Dictionary in table_data.elements:
		if entry["type"] == "launcher":
			return Vector2(entry["x"], entry["y"] - 40.0)
	return Vector2(530.0, 600.0)


func _on_back_button_pressed() -> void:
	back_requested.emit()
