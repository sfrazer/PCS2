extends GutTest


func _temp_path() -> String:
	return "user://test_slm_%d.json" % Time.get_ticks_usec()


func _cleanup(path: String) -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func test_save_load_round_trip() -> void:
	var path: String = _temp_path()
	var data: TableData = TableData.new()
	data.add_element("flipper_left", 120.0, 380.0, 0.0)
	data.add_element("pop_bumper", 300.0, 200.0, 45.0)

	assert_true(SaveLoadManager.save(path, data))

	var loaded: TableData = SaveLoadManager.load_table(path)
	assert_not_null(loaded)
	assert_eq(loaded.elements.size(), 2)
	assert_eq(loaded.elements[0]["type"], "flipper_left")
	assert_eq(loaded.elements[0]["x"], 120.0)
	assert_eq(loaded.elements[1]["type"], "pop_bumper")
	assert_eq(loaded.elements[1]["rotation"], 45.0)

	_cleanup(path)


func test_load_table_returns_null_for_missing_file() -> void:
	var path: String = "user://does_not_exist_%d.json" % Time.get_ticks_usec()
	var result: TableData = SaveLoadManager.load_table(path)
	assert_null(result)
	assert_push_error_count(1)


func test_load_table_returns_null_for_malformed_content() -> void:
	# Write valid JSON that is not a Dictionary so JSON.parse_string won't emit
	# an engine error, but TableData.deserialize will still return false.
	var path: String = _temp_path()
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	file.store_string("null")
	file.close()

	var result: TableData = SaveLoadManager.load_table(path)
	assert_null(result)
	assert_push_error_count(1)

	_cleanup(path)


func test_export_artifact_matches_export_schema() -> void:
	var path: String = _temp_path()
	var data: TableData = TableData.new()
	data.add_element("spinner", 400.0, 210.0, 30.0)

	assert_true(SaveLoadManager.export_artifact(path, data))

	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	assert_not_null(file)
	var content: String = file.get_as_text()
	file.close()

	var parsed: Variant = JSON.parse_string(content)
	assert_true(parsed is Dictionary)
	var d: Dictionary = parsed as Dictionary
	assert_true(d.has("canvas_width"))
	assert_true(d.has("canvas_height"))
	assert_true(d.has("elements"))
	assert_false(d.has("version"))
	assert_eq(d["canvas_width"], 800.0)
	assert_eq(d["canvas_height"], 420.0)
	assert_eq((d["elements"] as Array).size(), 1)

	_cleanup(path)


func test_save_creates_file_with_valid_json() -> void:
	var path: String = _temp_path()
	var data: TableData = TableData.new()
	data.add_element("launcher", 760.0, 350.0, 0.0)

	SaveLoadManager.save(path, data)
	assert_true(FileAccess.file_exists(path))

	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	var content: String = file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(content)
	assert_true(parsed is Dictionary)

	_cleanup(path)
