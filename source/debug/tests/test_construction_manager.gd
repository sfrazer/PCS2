extends GutTest


var _scene: Node = null
var _manager: ConstructionManager = null
var _placed_elements: Node2D = null


func before_each() -> void:
	var packed: PackedScene = load("res://source/gameplay/construction/construction_scene.tscn")
	_scene = add_child_autofree(packed.instantiate())
	_manager = _scene.get_node("ConstructionManager") as ConstructionManager
	_placed_elements = _scene.get_node("TableArea/TableViewport/PlacedElements") as Node2D


func test_manager_node_is_construction_manager() -> void:
	assert_not_null(_manager)
	assert_true(_manager is ConstructionManager)


func test_get_table_data_returns_table_data() -> void:
	var data: Variant = _manager.get_table_data()
	assert_not_null(data)
	assert_true(data is TableData)


func test_get_table_data_starts_empty() -> void:
	assert_eq(_manager.get_table_data().elements.size(), 0)


func test_set_selected_type_can_be_called() -> void:
	_manager.set_selected_type("flipper_left")
	# No direct getter for _selected_type; verify no error and table stays empty
	assert_eq(_manager.get_table_data().elements.size(), 0)


func test_rotate_selected_noop_when_nothing_selected() -> void:
	_manager.rotate_selected(15.0)
	assert_eq(_manager.get_table_data().elements.size(), 0)


func test_rebuild_from_table_data_accepts_empty_table() -> void:
	var data: TableData = TableData.new()
	_manager.rebuild_from_table_data(data)
	assert_eq(_placed_elements.get_child_count(), 0)
	assert_eq(_manager.get_table_data().elements.size(), 0)


func test_rebuild_from_table_data_places_nodes() -> void:
	var data: TableData = TableData.new()
	data.add_element("flipper_left", 100.0, 380.0, 0.0)
	data.add_element("pop_bumper", 300.0, 200.0, 0.0)
	_manager.rebuild_from_table_data(data)
	assert_eq(_placed_elements.get_child_count(), 2)


func test_rebuild_from_table_data_restores_position() -> void:
	var data: TableData = TableData.new()
	data.add_element("launcher", 150.0, 300.0, 45.0)
	_manager.rebuild_from_table_data(data)
	var placed: Node2D = _placed_elements.get_child(0) as Node2D
	assert_eq(placed.position.x, 150.0)
	assert_eq(placed.position.y, 300.0)
	assert_eq(placed.rotation_degrees, 45.0)


func test_rebuild_from_table_data_clears_previous_nodes() -> void:
	var data1: TableData = TableData.new()
	data1.add_element("flipper_left", 100.0, 380.0, 0.0)
	data1.add_element("flipper_right", 680.0, 380.0, 0.0)
	_manager.rebuild_from_table_data(data1)

	var data2: TableData = TableData.new()
	data2.add_element("launcher", 760.0, 300.0, 0.0)
	_manager.rebuild_from_table_data(data2)

	assert_eq(_placed_elements.get_child_count(), 1)
	assert_eq(_manager.get_table_data().elements.size(), 1)


func test_rebuild_from_table_data_updates_table_data_reference() -> void:
	var data: TableData = TableData.new()
	data.add_element("spinner", 250.0, 300.0, 0.0)
	_manager.rebuild_from_table_data(data)
	assert_true(_manager.get_table_data() is TableData)
	assert_eq(_manager.get_table_data().elements.size(), 1)
