extends GutTest


# --- Ball ---

func test_ball_instantiates_as_rigid_body() -> void:
	var packed: PackedScene = load("res://source/gameplay/ball/ball.tscn")
	var ball: Node = add_child_autofree(packed.instantiate())
	assert_not_null(ball)
	assert_true(ball is RigidBody2D)


func test_ball_joins_group_on_ready() -> void:
	var packed: PackedScene = load("res://source/gameplay/ball/ball.tscn")
	var ball: Node = add_child_autofree(packed.instantiate())
	assert_true(ball.is_in_group("ball"))


func test_ball_collision_layer_is_ball() -> void:
	var packed: PackedScene = load("res://source/gameplay/ball/ball.tscn")
	var ball: RigidBody2D = add_child_autofree(packed.instantiate()) as RigidBody2D
	assert_eq(ball.collision_layer, 1)


func test_ball_collision_mask_is_table_elements() -> void:
	var packed: PackedScene = load("res://source/gameplay/ball/ball.tscn")
	var ball: RigidBody2D = add_child_autofree(packed.instantiate()) as RigidBody2D
	assert_eq(ball.collision_mask, 2)


func test_ball_has_circle_collision_shape() -> void:
	var packed: PackedScene = load("res://source/gameplay/ball/ball.tscn")
	var ball: Node = add_child_autofree(packed.instantiate())
	var col: CollisionShape2D = ball.get_node("CollisionShape2D") as CollisionShape2D
	assert_not_null(col)
	assert_true(col.shape is CircleShape2D)


func test_ball_circle_radius_is_10() -> void:
	var packed: PackedScene = load("res://source/gameplay/ball/ball.tscn")
	var ball: Node = add_child_autofree(packed.instantiate())
	var col: CollisionShape2D = ball.get_node("CollisionShape2D") as CollisionShape2D
	assert_eq((col.shape as CircleShape2D).radius, 10.0)


func test_ball_uses_cast_shape_ccd() -> void:
	var packed: PackedScene = load("res://source/gameplay/ball/ball.tscn")
	var ball: RigidBody2D = add_child_autofree(packed.instantiate()) as RigidBody2D
	assert_eq(ball.continuous_cd, RigidBody2D.CCD_MODE_CAST_SHAPE)


# --- Table Boundary ---

func test_boundary_instantiates_as_static_body() -> void:
	var packed: PackedScene = load("res://source/gameplay/play/table_boundary.tscn")
	var boundary: Node = add_child_autofree(packed.instantiate())
	assert_not_null(boundary)
	assert_true(boundary is StaticBody2D)


func test_boundary_has_four_collision_shapes() -> void:
	var packed: PackedScene = load("res://source/gameplay/play/table_boundary.tscn")
	var boundary: Node = add_child_autofree(packed.instantiate())
	var count: int = 0
	for child: Node in boundary.get_children():
		if child is CollisionShape2D:
			count += 1
	assert_eq(count, 4)


func test_boundary_collision_layer_is_table_elements() -> void:
	var packed: PackedScene = load("res://source/gameplay/play/table_boundary.tscn")
	var boundary: StaticBody2D = add_child_autofree(packed.instantiate()) as StaticBody2D
	assert_eq(boundary.collision_layer, 2)


func test_boundary_collision_mask_is_ball() -> void:
	var packed: PackedScene = load("res://source/gameplay/play/table_boundary.tscn")
	var boundary: StaticBody2D = add_child_autofree(packed.instantiate()) as StaticBody2D
	assert_eq(boundary.collision_mask, 1)


func test_boundary_all_shapes_are_rectangles() -> void:
	var packed: PackedScene = load("res://source/gameplay/play/table_boundary.tscn")
	var boundary: Node = add_child_autofree(packed.instantiate())
	for child: Node in boundary.get_children():
		if child is CollisionShape2D:
			assert_true((child as CollisionShape2D).shape is RectangleShape2D,
					"%s should have RectangleShape2D" % child.name)
