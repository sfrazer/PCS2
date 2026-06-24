extends Node2D

signal play_requested(data: TableData)

@onready var _construction_manager: ConstructionManager = $ConstructionManager
@onready var _palette: VBoxContainer = $Palette


func _ready() -> void:
	for type: String in ElementRegistry.all_types():
		var btn: Button = Button.new()
		btn.text = ElementRegistry.get_label(type)
		_palette.add_child(btn)
		btn.pressed.connect(_on_palette_button_pressed.bind(type))


func _on_palette_button_pressed(type: String) -> void:
	_construction_manager.set_selected_type(type)


func _on_save_pressed() -> void:
	print("Save pressed — stub")


func _on_load_pressed() -> void:
	print("Load pressed — stub")


func _on_export_pressed() -> void:
	print("Export pressed — stub")


func _on_play_pressed() -> void:
	print("Play pressed — stub")
