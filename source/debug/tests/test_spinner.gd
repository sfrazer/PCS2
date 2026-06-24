extends GutTest


# --- Construct variant ---

func test_spinner_construct_instantiates() -> void:
	var packed: PackedScene = load("res://source/gameplay/elements/spinner/spinner_construct.tscn")
	var node: Node = add_child_autofree(packed.instantiate())
	assert_not_null(node)
	assert_true(node is Node2D)


func test_spinner_construct_has_area2d() -> void:
	var packed: PackedScene = load("res://source/gameplay/elements/spinner/spinner_construct.tscn")
	var node: Node = add_child_autofree(packed.instantiate())
	var area: Node = node.get_node("Area2D")
	assert_not_null(area)
	assert_true(area is Area2D)


func test_spinner_construct_has_rectangle_shape() -> void:
	var packed: PackedScene = load("res://source/gameplay/elements/spinner/spinner_construct.tscn")
	var node: Node = add_child_autofree(packed.instantiate())
	var col: CollisionShape2D = node.get_node("Area2D/CollisionShape2D") as CollisionShape2D
	assert_not_null(col)
	assert_true(col.shape is RectangleShape2D)


func test_spinner_construct_has_sprite() -> void:
	var packed: PackedScene = load("res://source/gameplay/elements/spinner/spinner_construct.tscn")
	var node: Node = add_child_autofree(packed.instantiate())
	var sprite: Sprite2D = node.get_node("Sprite2D") as Sprite2D
	assert_not_null(sprite)


# --- Play variant ---

func test_spinner_play_instantiates_as_node2d() -> void:
	var packed: PackedScene = load("res://source/gameplay/elements/spinner/spinner_play.tscn")
	var node: Node = add_child_autofree(packed.instantiate())
	assert_not_null(node)
	assert_true(node is Node2D)


func test_spinner_play_has_anchor() -> void:
	var packed: PackedScene = load("res://source/gameplay/elements/spinner/spinner_play.tscn")
	var node: Node = add_child_autofree(packed.instantiate())
	var anchor: Node = node.get_node("Anchor")
	assert_not_null(anchor)
	assert_true(anchor is StaticBody2D)


func test_spinner_play_has_spinner_body() -> void:
	var packed: PackedScene = load("res://source/gameplay/elements/spinner/spinner_play.tscn")
	var node: Node = add_child_autofree(packed.instantiate())
	var body: Node = node.get_node("SpinnerBody")
	assert_not_null(body)
	assert_true(body is RigidBody2D)


func test_spinner_play_spinner_body_collision_layer_and_mask() -> void:
	var packed: PackedScene = load("res://source/gameplay/elements/spinner/spinner_play.tscn")
	var node: Node = add_child_autofree(packed.instantiate())
	var body: RigidBody2D = node.get_node("SpinnerBody") as RigidBody2D
	assert_eq(body.collision_layer, 2)
	assert_eq(body.collision_mask, 1)


func test_spinner_play_spinner_body_physics_settings() -> void:
	var packed: PackedScene = load("res://source/gameplay/elements/spinner/spinner_play.tscn")
	var node: Node = add_child_autofree(packed.instantiate())
	var body: RigidBody2D = node.get_node("SpinnerBody") as RigidBody2D
	assert_eq(body.gravity_scale, 0.0)
	assert_eq(body.linear_damp, 10.0)
	assert_eq(body.angular_damp, 2.0)


func test_spinner_play_has_joint() -> void:
	var packed: PackedScene = load("res://source/gameplay/elements/spinner/spinner_play.tscn")
	var node: Node = add_child_autofree(packed.instantiate())
	var joint: Node = node.get_node("Joint")
	assert_not_null(joint)
	assert_true(joint is PinJoint2D)
