extends GutTest


# --- Construct variants ---

func test_left_construct_instantiates() -> void:
	var packed: PackedScene = load("res://source/gameplay/elements/flipper/flipper_left_construct.tscn")
	var node: Node = add_child_autofree(packed.instantiate())
	assert_not_null(node)
	assert_true(node is Node2D)


func test_right_construct_instantiates() -> void:
	var packed: PackedScene = load("res://source/gameplay/elements/flipper/flipper_right_construct.tscn")
	var node: Node = add_child_autofree(packed.instantiate())
	assert_not_null(node)
	assert_true(node is Node2D)


func test_left_construct_has_area2d() -> void:
	var packed: PackedScene = load("res://source/gameplay/elements/flipper/flipper_left_construct.tscn")
	var node: Node = add_child_autofree(packed.instantiate())
	var area: Node = node.get_node("Area2D")
	assert_not_null(area)
	assert_true(area is Area2D)


func test_right_construct_has_area2d() -> void:
	var packed: PackedScene = load("res://source/gameplay/elements/flipper/flipper_right_construct.tscn")
	var node: Node = add_child_autofree(packed.instantiate())
	var area: Node = node.get_node("Area2D")
	assert_not_null(area)
	assert_true(area is Area2D)


func test_construct_area2d_has_rectangle_shape() -> void:
	var packed: PackedScene = load("res://source/gameplay/elements/flipper/flipper_left_construct.tscn")
	var node: Node = add_child_autofree(packed.instantiate())
	var col: CollisionShape2D = node.get_node("Area2D/CollisionShape2D") as CollisionShape2D
	assert_not_null(col)
	assert_true(col.shape is RectangleShape2D)


func test_right_construct_sprite_is_flipped() -> void:
	var packed: PackedScene = load("res://source/gameplay/elements/flipper/flipper_right_construct.tscn")
	var node: Node = add_child_autofree(packed.instantiate())
	var sprite: Sprite2D = node.get_node("Sprite2D") as Sprite2D
	assert_true(sprite.flip_h)


func test_left_construct_sprite_not_flipped() -> void:
	var packed: PackedScene = load("res://source/gameplay/elements/flipper/flipper_left_construct.tscn")
	var node: Node = add_child_autofree(packed.instantiate())
	var sprite: Sprite2D = node.get_node("Sprite2D") as Sprite2D
	assert_false(sprite.flip_h)


# --- Play variants ---

func test_left_play_instantiates_as_animatable_body() -> void:
	var packed: PackedScene = load("res://source/gameplay/elements/flipper/flipper_left_play.tscn")
	var node: Node = add_child_autofree(packed.instantiate())
	assert_not_null(node)
	assert_true(node is AnimatableBody2D)


func test_right_play_instantiates_as_animatable_body() -> void:
	var packed: PackedScene = load("res://source/gameplay/elements/flipper/flipper_right_play.tscn")
	var node: Node = add_child_autofree(packed.instantiate())
	assert_not_null(node)
	assert_true(node is AnimatableBody2D)


func test_left_play_collision_layer_and_mask() -> void:
	var packed: PackedScene = load("res://source/gameplay/elements/flipper/flipper_left_play.tscn")
	var flipper: AnimatableBody2D = add_child_autofree(packed.instantiate()) as AnimatableBody2D
	assert_eq(flipper.collision_layer, 2)
	assert_eq(flipper.collision_mask, 1)


func test_right_play_collision_layer_and_mask() -> void:
	var packed: PackedScene = load("res://source/gameplay/elements/flipper/flipper_right_play.tscn")
	var flipper: AnimatableBody2D = add_child_autofree(packed.instantiate()) as AnimatableBody2D
	assert_eq(flipper.collision_layer, 2)
	assert_eq(flipper.collision_mask, 1)


func test_left_play_script_constants() -> void:
	var packed: PackedScene = load("res://source/gameplay/elements/flipper/flipper_left_play.tscn")
	var flipper: FlipperLeftPlay = add_child_autofree(packed.instantiate()) as FlipperLeftPlay
	assert_eq(flipper.REST_OFFSET, 30.0)
	assert_eq(flipper.RAISED_OFFSET, -30.0)
	assert_eq(flipper.ACTION, "flipper_left")


func test_right_play_script_constants() -> void:
	var packed: PackedScene = load("res://source/gameplay/elements/flipper/flipper_right_play.tscn")
	var flipper: FlipperRightPlay = add_child_autofree(packed.instantiate()) as FlipperRightPlay
	assert_eq(flipper.REST_OFFSET, -30.0)
	assert_eq(flipper.RAISED_OFFSET, 30.0)
	assert_eq(flipper.ACTION, "flipper_right")


func test_left_play_base_rotation_zero_at_default_placement() -> void:
	var packed: PackedScene = load("res://source/gameplay/elements/flipper/flipper_left_play.tscn")
	var flipper: FlipperLeftPlay = add_child_autofree(packed.instantiate()) as FlipperLeftPlay
	assert_eq(flipper._base_rotation, 0.0)


func test_left_play_has_capsule_collision_shape() -> void:
	var packed: PackedScene = load("res://source/gameplay/elements/flipper/flipper_left_play.tscn")
	var node: Node = add_child_autofree(packed.instantiate())
	var col: CollisionShape2D = node.get_node("CollisionShape2D") as CollisionShape2D
	assert_not_null(col)
	assert_true(col.shape is CapsuleShape2D)


func test_right_play_sprite_is_flipped() -> void:
	var packed: PackedScene = load("res://source/gameplay/elements/flipper/flipper_right_play.tscn")
	var node: Node = add_child_autofree(packed.instantiate())
	var sprite: Sprite2D = node.get_node("Sprite2D") as Sprite2D
	assert_true(sprite.flip_h)
