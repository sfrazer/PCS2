extends GutTest


func _make_play_scene(data: TableData) -> PlayScene:
	var packed: PackedScene = load("res://source/gameplay/play/play_scene.tscn")
	var node: PlayScene = packed.instantiate() as PlayScene
	node.table_data = data
	add_child_autofree(node)
	return node


func _full_table() -> TableData:
	var data: TableData = TableData.new()
	data.add_element("flipper_left", 100.0, 580.0, 0.0)
	data.add_element("flipper_right", 460.0, 580.0, 0.0)
	data.add_element("launcher", 530.0, 600.0, 0.0)
	data.add_element("pop_bumper", 200.0, 200.0, 0.0)
	data.add_element("drop_target", 300.0, 300.0, 0.0)
	data.add_element("spinner", 150.0, 400.0, 0.0)
	return data


func test_play_scene_instantiates_as_node2d() -> void:
	var scene: PlayScene = _make_play_scene(TableData.new())
	assert_not_null(scene)
	assert_true(scene is Node2D)


func test_play_scene_exposes_back_requested_signal() -> void:
	var scene: PlayScene = _make_play_scene(TableData.new())
	assert_true(scene.has_signal("back_requested"))


func test_play_scene_builds_all_elements_from_table_data() -> void:
	var scene: PlayScene = _make_play_scene(_full_table())
	var elements: Node2D = scene.get_node("TableViewportContainer/TableViewport/PhysicsElements") as Node2D
	assert_eq(elements.get_child_count(), 6)


func test_play_scene_has_table_boundary() -> void:
	var scene: PlayScene = _make_play_scene(TableData.new())
	var boundary: Node = scene.get_node("TableViewportContainer/TableViewport/TableBoundary")
	assert_not_null(boundary)
	assert_true(boundary is StaticBody2D)


func test_play_scene_ball_in_group_after_ready() -> void:
	var scene: PlayScene = _make_play_scene(TableData.new())
	var balls: Array[Node] = get_tree().get_nodes_in_group("ball")
	assert_eq(balls.size(), 1)


func test_find_spawn_position_above_launcher() -> void:
	var data: TableData = TableData.new()
	data.add_element("launcher", 200.0, 400.0, 0.0)
	var scene: PlayScene = _make_play_scene(data)
	assert_eq(scene._find_spawn_position(), Vector2(200.0, 360.0))


func test_find_spawn_position_default_when_no_launcher() -> void:
	var data: TableData = TableData.new()
	data.add_element("flipper_left", 100.0, 580.0, 0.0)
	var scene: PlayScene = _make_play_scene(data)
	assert_eq(scene._find_spawn_position(), Vector2(530.0, 600.0))
