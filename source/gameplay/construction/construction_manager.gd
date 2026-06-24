class_name ConstructionManager
extends Node


var _table_data: TableData = TableData.new()
var _selected_type: String = ""
var _selected_index: int = -1
var _placed_nodes: Array[Node2D] = []
var _drag_node: Node2D = null
var _drag_index: int = -1
var _drag_offset: Vector2 = Vector2.ZERO

@onready var _placed_elements: Node2D = $"../TableArea/TableViewport/PlacedElements"
@onready var _table_area: SubViewportContainer = $"../TableArea"
@onready var _table_viewport: SubViewport = $"../TableArea/TableViewport"


func _ready() -> void:
	_table_area.gui_input.connect(_on_canvas_input)


func set_selected_type(type: String) -> void:
	_selected_type = type
	_selected_index = -1


func get_table_data() -> TableData:
	return _table_data


func rebuild_from_table_data(data: TableData) -> void:
	for node: Node2D in _placed_nodes:
		node.free()
	_placed_nodes.clear()
	_table_data = data
	_selected_index = -1
	_drag_node = null
	_drag_index = -1
	for entry: Dictionary in data.elements:
		var scene: PackedScene = ElementRegistry.get_construct_scene(entry["type"])
		var node: Node2D = scene.instantiate() as Node2D
		node.position = Vector2(entry["x"], entry["y"])
		node.rotation_degrees = entry["rotation"]
		_placed_elements.add_child(node)
		_placed_nodes.append(node)


func rotate_selected(delta_degrees: float) -> void:
	if _selected_index < 0:
		return
	var node: Node2D = _placed_nodes[_selected_index]
	node.rotation_degrees += delta_degrees
	_table_data.update_element(_selected_index,
			node.position.x, node.position.y, node.rotation_degrees)


func _on_canvas_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		_handle_mouse_button(event as InputEventMouseButton)
	elif event is InputEventMouseMotion:
		_handle_mouse_motion(event as InputEventMouseMotion)


func _handle_mouse_button(event: InputEventMouseButton) -> void:
	var pos: Vector2 = event.position

	if event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			var hit: int = _get_element_at(pos)
			if hit >= 0:
				_selected_index = hit
				_drag_index = hit
				_drag_node = _placed_nodes[hit]
				_drag_offset = _drag_node.position - pos
			elif _selected_type != "":
				_place_element(pos)
		else:
			_drag_node = null
			_drag_index = -1
			_drag_offset = Vector2.ZERO

	elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		var hit: int = _get_element_at(pos)
		if hit >= 0:
			_delete_element(hit)

	elif event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
		rotate_selected(15.0)

	elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
		rotate_selected(-15.0)


func _handle_mouse_motion(event: InputEventMouseMotion) -> void:
	if _drag_node == null:
		return
	var new_pos: Vector2 = event.position + _drag_offset
	_drag_node.position = new_pos
	_table_data.update_element(_drag_index,
			new_pos.x, new_pos.y, _drag_node.rotation_degrees)


func _place_element(pos: Vector2) -> void:
	var scene: PackedScene = ElementRegistry.get_construct_scene(_selected_type)
	var node: Node2D = scene.instantiate() as Node2D
	node.position = pos
	_placed_elements.add_child(node)
	_placed_nodes.append(node)
	_table_data.add_element(_selected_type, pos.x, pos.y, 0.0)
	_selected_index = _placed_nodes.size() - 1


func _delete_element(index: int) -> void:
	_placed_nodes[index].queue_free()
	_placed_nodes.remove_at(index)
	_table_data.remove_element(index)
	if _selected_index == index:
		_selected_index = -1
	elif _selected_index > index:
		_selected_index -= 1
	if _drag_index == index:
		_drag_node = null
		_drag_index = -1
		_drag_offset = Vector2.ZERO
	elif _drag_index > index:
		_drag_index -= 1


func _get_element_at(pos: Vector2) -> int:
	var space_state: PhysicsDirectSpaceState2D = _table_viewport.get_world_2d().direct_space_state
	var params: PhysicsPointQueryParameters2D = PhysicsPointQueryParameters2D.new()
	params.position = pos
	params.collision_mask = 0xFFFFFFFF
	var results: Array[Dictionary] = space_state.intersect_point(params)
	for result: Dictionary in results:
		var collider: Object = result["collider"]
		if collider is Area2D:
			var parent: Node2D = (collider as Node).get_parent() as Node2D
			if parent != null:
				var idx: int = _placed_nodes.find(parent)
				if idx >= 0:
					return idx
	return -1
