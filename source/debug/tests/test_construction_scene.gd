extends GutTest


var _scene: Node = null


func before_each() -> void:
	var packed: PackedScene = load("res://source/gameplay/construction/construction_scene.tscn")
	_scene = add_child_autofree(packed.instantiate())


func test_scene_instantiates_as_node2d() -> void:
	assert_not_null(_scene)
	assert_true(_scene is Node2D)


func test_scene_exposes_play_requested_signal() -> void:
	assert_true(_scene.has_signal("play_requested"))


func test_palette_populated_with_six_buttons() -> void:
	var palette: Node = _scene.get_node("Palette")
	assert_not_null(palette)
	assert_eq(palette.get_child_count(), 6)


func test_palette_button_labels_match_registry() -> void:
	var palette: Node = _scene.get_node("Palette")
	var expected_labels: Array[String] = []
	for type: String in ElementRegistry.all_types():
		expected_labels.append(ElementRegistry.get_label(type))
	for i: int in range(palette.get_child_count()):
		var btn: Button = palette.get_child(i) as Button
		assert_true(expected_labels.has(btn.text),
				"Unexpected palette button label: %s" % btn.text)


func test_toolbar_has_four_buttons() -> void:
	var toolbar: Node = _scene.get_node("Toolbar")
	assert_not_null(toolbar)
	assert_eq(toolbar.get_child_count(), 4)


func test_table_viewport_is_subviewport() -> void:
	var viewport: Node = _scene.get_node("TableArea/TableViewport")
	assert_not_null(viewport)
	assert_true(viewport is SubViewport)


func test_placed_elements_node_exists() -> void:
	var placed: Node = _scene.get_node("TableArea/TableViewport/PlacedElements")
	assert_not_null(placed)
	assert_true(placed is Node2D)


func test_construction_manager_node_exists() -> void:
	var manager: Node = _scene.get_node("ConstructionManager")
	assert_not_null(manager)
