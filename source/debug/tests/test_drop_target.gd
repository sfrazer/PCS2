extends GutTest


# --- Construct variant ---

func test_drop_target_construct_instantiates() -> void:
	var packed: PackedScene = load("res://source/gameplay/elements/drop_target/drop_target_construct.tscn")
	var node: Node = add_child_autofree(packed.instantiate())
	assert_not_null(node)
	assert_true(node is Node2D)


func test_drop_target_construct_has_area2d() -> void:
	var packed: PackedScene = load("res://source/gameplay/elements/drop_target/drop_target_construct.tscn")
	var node: Node = add_child_autofree(packed.instantiate())
	var area: Node = node.get_node("Area2D")
	assert_not_null(area)
	assert_true(area is Area2D)


func test_drop_target_construct_has_rectangle_shape() -> void:
	var packed: PackedScene = load("res://source/gameplay/elements/drop_target/drop_target_construct.tscn")
	var node: Node = add_child_autofree(packed.instantiate())
	var col: CollisionShape2D = node.get_node("Area2D/CollisionShape2D") as CollisionShape2D
	assert_not_null(col)
	assert_true(col.shape is RectangleShape2D)


func test_drop_target_construct_has_sprite() -> void:
	var packed: PackedScene = load("res://source/gameplay/elements/drop_target/drop_target_construct.tscn")
	var node: Node = add_child_autofree(packed.instantiate())
	var sprite: Sprite2D = node.get_node("Sprite2D") as Sprite2D
	assert_not_null(sprite)


# --- Play variant ---

func test_drop_target_play_instantiates_as_static_body() -> void:
	var packed: PackedScene = load("res://source/gameplay/elements/drop_target/drop_target_play.tscn")
	var node: Node = add_child_autofree(packed.instantiate())
	assert_not_null(node)
	assert_true(node is StaticBody2D)


func test_drop_target_play_collision_layer_and_mask() -> void:
	var packed: PackedScene = load("res://source/gameplay/elements/drop_target/drop_target_play.tscn")
	var node: StaticBody2D = add_child_autofree(packed.instantiate()) as StaticBody2D
	assert_eq(node.collision_layer, 2)
	assert_eq(node.collision_mask, 1)


func test_drop_target_play_has_body_shape() -> void:
	var packed: PackedScene = load("res://source/gameplay/elements/drop_target/drop_target_play.tscn")
	var node: Node = add_child_autofree(packed.instantiate())
	var shape: CollisionShape2D = node.get_node("BodyShape") as CollisionShape2D
	assert_not_null(shape)
	assert_true(shape.shape is RectangleShape2D)


func test_drop_target_play_has_contact_area() -> void:
	var packed: PackedScene = load("res://source/gameplay/elements/drop_target/drop_target_play.tscn")
	var node: Node = add_child_autofree(packed.instantiate())
	var area: Node = node.get_node("ContactArea")
	assert_not_null(area)
	assert_true(area is Area2D)


func test_drop_target_play_dropped_starts_false() -> void:
	var packed: PackedScene = load("res://source/gameplay/elements/drop_target/drop_target_play.tscn")
	var target: DropTargetPlay = add_child_autofree(packed.instantiate()) as DropTargetPlay
	assert_false(target._dropped)
