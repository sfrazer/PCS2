extends Node


var _dialog_path: String = ""
var _dialog_done: bool = false


func save(path: String, data: TableData) -> bool:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("SaveLoadManager: cannot open file for writing: " + path)
		return false
	file.store_string(data.serialize())
	file.close()
	return true


func load_table(path: String) -> TableData:
	if not FileAccess.file_exists(path):
		push_error("SaveLoadManager: file not found: " + path)
		return null
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	var content: String = file.get_as_text()
	file.close()
	var data: TableData = TableData.new()
	if not data.deserialize(content):
		push_error("SaveLoadManager: failed to parse file: " + path)
		return null
	return data


func export_artifact(path: String, data: TableData) -> bool:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("SaveLoadManager: cannot open file for export: " + path)
		return false
	file.store_string(JSON.stringify(data.to_export_dict(), "\t"))
	file.close()
	return true


func open_save_dialog() -> String:
	return await _show_dialog(FileDialog.FILE_MODE_SAVE_FILE)


func open_load_dialog() -> String:
	return await _show_dialog(FileDialog.FILE_MODE_OPEN_FILE)


# Returns the chosen path, or "" if the user cancelled. Awaits BOTH the
# file_selected and canceled signals — awaiting only file_selected hangs
# the caller forever when the dialog is dismissed.
func _show_dialog(mode: FileDialog.FileMode) -> String:
	var dialog: FileDialog = FileDialog.new()
	dialog.file_mode = mode
	dialog.filters = ["*.json ; JSON Table Files"]
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	_dialog_path = ""
	_dialog_done = false
	dialog.file_selected.connect(_on_dialog_file_selected)
	dialog.canceled.connect(_on_dialog_canceled)
	get_tree().root.add_child(dialog)
	dialog.popup_centered(Vector2i(800, 600))
	while not _dialog_done:
		await get_tree().process_frame
	dialog.queue_free()
	return _dialog_path


func _on_dialog_file_selected(path: String) -> void:
	_dialog_path = path
	_dialog_done = true


func _on_dialog_canceled() -> void:
	_dialog_path = ""
	_dialog_done = true
