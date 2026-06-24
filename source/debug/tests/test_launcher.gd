extends GutTest


# --- Construct variant ---

func test_launcher_construct_instantiates() -> void:
	var packed: PackedScene = load("res://source/gameplay/elements/launcher/launcher_construct.tscn")
	var node: Node = add_child_autofree(packed.instantiate())
	assert_not_null(node)
	assert_true(node is Node2D)


func test_launcher_construct_has_area2d() -> void:
	var packed: PackedScene = load("res://source/gameplay/elements/launcher/launcher_construct.tscn")
	var node: Node = add_child_autofree(packed.instantiate())
	var area: Node = node.get_node("Area2D")
	assert_not_null(area)
	assert_true(area is Area2D)


func test_launcher_construct_area2d_has_rectangle_shape() -> void:
	var packed: PackedScene = load("res://source/gameplay/elements/launcher/launcher_construct.tscn")
	var node: Node = add_child_autofree(packed.instantiate())
	var col: CollisionShape2D = node.get_node("Area2D/CollisionShape2D") as CollisionShape2D
	assert_not_null(col)
	assert_true(col.shape is RectangleShape2D)


func test_launcher_construct_has_sprite() -> void:
	var packed: PackedScene = load("res://source/gameplay/elements/launcher/launcher_construct.tscn")
	var node: Node = add_child_autofree(packed.instantiate())
	var sprite: Sprite2D = node.get_node("Sprite2D") as Sprite2D
	assert_not_null(sprite)


# --- Play variant ---

func test_launcher_play_instantiates_as_node2d() -> void:
	var packed: PackedScene = load("res://source/gameplay/elements/launcher/launcher_play.tscn")
	var node: Node = add_child_autofree(packed.instantiate())
	assert_not_null(node)
	assert_true(node is Node2D)


func test_launcher_play_has_left_wall() -> void:
	var packed: PackedScene = load("res://source/gameplay/elements/launcher/launcher_play.tscn")
	var node: Node = add_child_autofree(packed.instantiate())
	var wall: Node = node.get_node("LeftWall")
	assert_not_null(wall)
	assert_true(wall is StaticBody2D)


func test_launcher_play_has_right_wall() -> void:
	var packed: PackedScene = load("res://source/gameplay/elements/launcher/launcher_play.tscn")
	var node: Node = add_child_autofree(packed.instantiate())
	var wall: Node = node.get_node("RightWall")
	assert_not_null(wall)
	assert_true(wall is StaticBody2D)


func test_launcher_play_walls_collision_layer_and_mask() -> void:
	var packed: PackedScene = load("res://source/gameplay/elements/launcher/launcher_play.tscn")
	var node: Node = add_child_autofree(packed.instantiate())
	var left: StaticBody2D = node.get_node("LeftWall") as StaticBody2D
	var right: StaticBody2D = node.get_node("RightWall") as StaticBody2D
	assert_eq(left.collision_layer, 2)
	assert_eq(left.collision_mask, 1)
	assert_eq(right.collision_layer, 2)
	assert_eq(right.collision_mask, 1)


func test_launcher_play_script_max_force() -> void:
	var packed: PackedScene = load("res://source/gameplay/elements/launcher/launcher_play.tscn")
	var launcher: LauncherPlay = add_child_autofree(packed.instantiate()) as LauncherPlay
	assert_eq(launcher.MAX_FORCE, 1200.0)


func test_launcher_play_charge_starts_at_zero() -> void:
	var packed: PackedScene = load("res://source/gameplay/elements/launcher/launcher_play.tscn")
	var launcher: LauncherPlay = add_child_autofree(packed.instantiate()) as LauncherPlay
	assert_eq(launcher._charge, 0.0)


func test_launcher_play_charging_starts_false() -> void:
	var packed: PackedScene = load("res://source/gameplay/elements/launcher/launcher_play.tscn")
	var launcher: LauncherPlay = add_child_autofree(packed.instantiate()) as LauncherPlay
	assert_false(launcher._charging)
