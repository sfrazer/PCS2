extends Node


const ELEMENTS: Dictionary = {
	"flipper_left":  { "label": "Flipper L", "construct": "res://source/gameplay/elements/flipper/flipper_left_construct.tscn",    "play": "res://source/gameplay/elements/flipper/flipper_left_play.tscn"    },
	"flipper_right": { "label": "Flipper R", "construct": "res://source/gameplay/elements/flipper/flipper_right_construct.tscn",   "play": "res://source/gameplay/elements/flipper/flipper_right_play.tscn"   },
	"launcher":      { "label": "Launcher",  "construct": "res://source/gameplay/elements/launcher/launcher_construct.tscn",       "play": "res://source/gameplay/elements/launcher/launcher_play.tscn"       },
	"pop_bumper":    { "label": "Bumper",    "construct": "res://source/gameplay/elements/pop_bumper/pop_bumper_construct.tscn",   "play": "res://source/gameplay/elements/pop_bumper/pop_bumper_play.tscn"   },
	"drop_target":   { "label": "Target",    "construct": "res://source/gameplay/elements/drop_target/drop_target_construct.tscn", "play": "res://source/gameplay/elements/drop_target/drop_target_play.tscn" },
	"spinner":       { "label": "Spinner",   "construct": "res://source/gameplay/elements/spinner/spinner_construct.tscn",         "play": "res://source/gameplay/elements/spinner/spinner_play.tscn"         },
}


func get_construct_scene(type: String) -> PackedScene:
	return load(ELEMENTS[type]["construct"]) as PackedScene


func get_play_scene(type: String) -> PackedScene:
	return load(ELEMENTS[type]["play"]) as PackedScene


func get_label(type: String) -> String:
	return ELEMENTS[type]["label"] as String


func all_types() -> Array[String]:
	var types: Array[String] = []
	for key: String in ELEMENTS.keys():
		types.append(key)
	return types
