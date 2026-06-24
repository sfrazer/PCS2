extends GutTest


func test_serialize_contains_version_and_elements() -> void:
	var data: TableData = TableData.new()
	data.add_element("flipper_left", 120.0, 380.0, 0.0)
	var json: String = data.serialize()
	var parsed: Variant = JSON.parse_string(json)
	assert_true(parsed is Dictionary)
	var d: Dictionary = parsed as Dictionary
	assert_true(d.has("version"))
	assert_true(d.has("elements"))


func test_serialize_deserialize_round_trip() -> void:
	var data: TableData = TableData.new()
	data.add_element("flipper_left", 120.0, 380.0, 0.0)
	data.add_element("pop_bumper", 300.0, 200.0, 45.0)
	var restored: TableData = TableData.new()
	assert_true(restored.deserialize(data.serialize()))
	assert_eq(restored.elements.size(), 2)
	assert_eq(restored.elements[0]["type"], "flipper_left")
	assert_eq(restored.elements[0]["x"], 120.0)
	assert_eq(restored.elements[0]["y"], 380.0)
	assert_eq(restored.elements[0]["rotation"], 0.0)
	assert_eq(restored.elements[1]["type"], "pop_bumper")
	assert_eq(restored.elements[1]["rotation"], 45.0)


func test_to_export_dict_has_required_keys() -> void:
	var data: TableData = TableData.new()
	data.add_element("spinner", 400.0, 200.0, 0.0)
	var d: Dictionary = data.to_export_dict()
	assert_true(d.has("canvas_width"))
	assert_true(d.has("canvas_height"))
	assert_true(d.has("elements"))
	assert_false(d.has("version"))
	assert_eq(d["canvas_width"], 800)
	assert_eq(d["canvas_height"], 420)
	assert_eq(d["elements"].size(), 1)


func test_add_element_appends_entry() -> void:
	var data: TableData = TableData.new()
	data.add_element("launcher", 50.0, 300.0, 0.0)
	assert_eq(data.elements.size(), 1)
	assert_eq(data.elements[0]["type"], "launcher")
	assert_eq(data.elements[0]["x"], 50.0)
	assert_eq(data.elements[0]["y"], 300.0)


func test_remove_element_removes_at_index() -> void:
	var data: TableData = TableData.new()
	data.add_element("flipper_left", 100.0, 380.0, 0.0)
	data.add_element("flipper_right", 700.0, 380.0, 0.0)
	data.remove_element(0)
	assert_eq(data.elements.size(), 1)
	assert_eq(data.elements[0]["type"], "flipper_right")


func test_update_element_mutates_position_and_rotation() -> void:
	var data: TableData = TableData.new()
	data.add_element("drop_target", 200.0, 150.0, 0.0)
	data.update_element(0, 250.0, 180.0, 90.0)
	assert_eq(data.elements[0]["x"], 250.0)
	assert_eq(data.elements[0]["y"], 180.0)
	assert_eq(data.elements[0]["rotation"], 90.0)


func test_clear_empties_elements() -> void:
	var data: TableData = TableData.new()
	data.add_element("flipper_left", 100.0, 380.0, 0.0)
	data.add_element("flipper_right", 700.0, 380.0, 0.0)
	data.clear()
	assert_eq(data.elements.size(), 0)


func test_deserialize_rejects_json_non_dictionary() -> void:
	# Uses valid JSON values that are not Dictionaries — avoids engine push_error
	# from JSON.parse_string on malformed input while still exercising the guard.
	var data: TableData = TableData.new()
	assert_false(data.deserialize("null"))
	assert_false(data.deserialize("42"))
	assert_false(data.deserialize("true"))


func test_deserialize_rejects_empty_string() -> void:
	var data: TableData = TableData.new()
	assert_false(data.deserialize(""))


func test_deserialize_rejects_json_array() -> void:
	var data: TableData = TableData.new()
	assert_false(data.deserialize("[1, 2, 3]"))


func test_deserialize_rejects_missing_version() -> void:
	var data: TableData = TableData.new()
	assert_false(data.deserialize('{"elements": []}'))


func test_deserialize_rejects_missing_elements() -> void:
	var data: TableData = TableData.new()
	assert_false(data.deserialize('{"version": 1}'))


func test_serialize_does_not_share_reference_with_elements() -> void:
	var data: TableData = TableData.new()
	data.add_element("flipper_left", 100.0, 380.0, 0.0)
	var _json: String = data.serialize()
	data.elements[0]["x"] = 999.0
	var restored: TableData = TableData.new()
	restored.deserialize(_json)
	assert_eq(restored.elements[0]["x"], 100.0)
