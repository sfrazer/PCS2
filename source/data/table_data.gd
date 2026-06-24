class_name TableData


const VERSION: int = 1

var elements: Array[Dictionary] = []


func serialize() -> String:
	var data: Dictionary = {
		"version": VERSION,
		"elements": elements.duplicate(true),
	}
	return JSON.stringify(data, "\t")


func deserialize(json_string: String) -> bool:
	if json_string.is_empty():
		return false
	var parsed: Variant = JSON.parse_string(json_string)
	if not parsed is Dictionary:
		return false
	var data: Dictionary = parsed as Dictionary
	if not data.has("version") or not data.has("elements"):
		return false
	if not data["elements"] is Array:
		return false
	# Validate all entries before mutating state — clear only after full success
	# so a corrupt file never wipes a pre-existing table.
	var new_elements: Array[Dictionary] = []
	for entry: Variant in data["elements"] as Array:
		if not entry is Dictionary:
			return false
		new_elements.append((entry as Dictionary).duplicate(true))
	elements = new_elements
	return true


func to_export_dict() -> Dictionary:
	return {
		"canvas_width": 560,
		"canvas_height": 720,
		"elements": elements.duplicate(true),
	}


func add_element(type: String, x: float, y: float, rotation_deg: float = 0.0) -> void:
	elements.append({ "type": type, "x": x, "y": y, "rotation": rotation_deg })


func remove_element(index: int) -> void:
	elements.remove_at(index)


func update_element(index: int, x: float, y: float, rotation_deg: float) -> void:
	elements[index]["x"] = x
	elements[index]["y"] = y
	elements[index]["rotation"] = rotation_deg


func clear() -> void:
	elements.clear()
