extends GutTest


const EXPECTED_TYPES: Array[String] = [
	"flipper_left", "flipper_right", "launcher", "pop_bumper", "drop_target", "spinner"
]

const EXPECTED_LABELS: Dictionary = {
	"flipper_left":  "Flipper L",
	"flipper_right": "Flipper R",
	"launcher":      "Launcher",
	"pop_bumper":    "Bumper",
	"drop_target":   "Target",
	"spinner":       "Spinner",
}


func test_all_types_returns_six_types() -> void:
	var types: Array[String] = ElementRegistry.all_types()
	assert_eq(types.size(), 6)


func test_all_types_contains_expected_keys() -> void:
	var types: Array[String] = ElementRegistry.all_types()
	for expected: String in EXPECTED_TYPES:
		assert_true(types.has(expected), "Missing type: %s" % expected)


func test_get_label_returns_correct_label() -> void:
	for type: String in EXPECTED_TYPES:
		assert_eq(ElementRegistry.get_label(type), EXPECTED_LABELS[type],
				"Wrong label for type: %s" % type)


func test_get_construct_scene_returns_packed_scene() -> void:
	for type: String in EXPECTED_TYPES:
		var scene: PackedScene = ElementRegistry.get_construct_scene(type)
		assert_not_null(scene, "Null construct scene for type: %s" % type)
		assert_true(scene is PackedScene, "Not a PackedScene for type: %s" % type)


func test_get_play_scene_returns_packed_scene() -> void:
	for type: String in EXPECTED_TYPES:
		var scene: PackedScene = ElementRegistry.get_play_scene(type)
		assert_not_null(scene, "Null play scene for type: %s" % type)
		assert_true(scene is PackedScene, "Not a PackedScene for type: %s" % type)


func test_construct_scenes_instantiate_without_error() -> void:
	for type: String in EXPECTED_TYPES:
		var scene: PackedScene = ElementRegistry.get_construct_scene(type)
		var node: Node = add_child_autofree(scene.instantiate())
		assert_not_null(node, "Failed to instantiate construct scene for: %s" % type)


func test_play_scenes_instantiate_without_error() -> void:
	for type: String in EXPECTED_TYPES:
		var scene: PackedScene = ElementRegistry.get_play_scene(type)
		var node: Node = add_child_autofree(scene.instantiate())
		assert_not_null(node, "Failed to instantiate play scene for: %s" % type)
