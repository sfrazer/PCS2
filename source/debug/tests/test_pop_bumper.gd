extends GutTest


# --- Construct variant ---

func test_pop_bumper_construct_instantiates() -> void:
	var packed: PackedScene = load("res://source/gameplay/elements/pop_bumper/pop_bumper_construct.tscn")
	var node: Node = add_child_autofree(packed.instantiate())
	assert_not_null(node)
	assert_true(node is Node2D)


func test_pop_bumper_construct_has_area2d() -> void:
	var packed: PackedScene = load("res://source/gameplay/elements/pop_bumper/pop_bumper_construct.tscn")
	var node: Node = add_child_autofree(packed.instantiate())
	var area: Node = node.get_node("Area2D")
	assert_not_null(area)
	assert_true(area is Area2D)


func test_pop_bumper_construct_has_circle_shape() -> void:
	var packed: PackedScene = load("res://source/gameplay/elements/pop_bumper/pop_bumper_construct.tscn")
	var node: Node = add_child_autofree(packed.instantiate())
	var col: CollisionShape2D = node.get_node("Area2D/CollisionShape2D") as CollisionShape2D
	assert_not_null(col)
	assert_true(col.shape is CircleShape2D)


func test_pop_bumper_construct_has_sprite() -> void:
	var packed: PackedScene = load("res://source/gameplay/elements/pop_bumper/pop_bumper_construct.tscn")
	var node: Node = add_child_autofree(packed.instantiate())
	var sprite: Sprite2D = node.get_node("Sprite2D") as Sprite2D
	assert_not_null(sprite)


# --- Play variant ---

func test_pop_bumper_play_instantiates_as_static_body() -> void:
	var packed: PackedScene = load("res://source/gameplay/elements/pop_bumper/pop_bumper_play.tscn")
	var node: Node = add_child_autofree(packed.instantiate())
	assert_not_null(node)
	assert_true(node is StaticBody2D)


func test_pop_bumper_play_collision_layer_and_mask() -> void:
	var packed: PackedScene = load("res://source/gameplay/elements/pop_bumper/pop_bumper_play.tscn")
	var node: StaticBody2D = add_child_autofree(packed.instantiate()) as StaticBody2D
	assert_eq(node.collision_layer, 2)
	assert_eq(node.collision_mask, 1)


func test_pop_bumper_play_has_contact_area() -> void:
	var packed: PackedScene = load("res://source/gameplay/elements/pop_bumper/pop_bumper_play.tscn")
	var node: Node = add_child_autofree(packed.instantiate())
	var area: Node = node.get_node("ContactArea")
	assert_not_null(area)
	assert_true(area is Area2D)


func test_pop_bumper_play_script_bumper_force() -> void:
	var packed: PackedScene = load("res://source/gameplay/elements/pop_bumper/pop_bumper_play.tscn")
	var bumper: PopBumperPlay = add_child_autofree(packed.instantiate()) as PopBumperPlay
	assert_eq(bumper.BUMPER_FORCE, 400.0)
