# Element Specifications

Each element has a construction variant and a play variant. Construction variants are lightweight (sprite + selection area). Play variants contain full physics.

Read `godot-conventions.md` before implementing any element scene.

---

## Shared Rules (Apply to All Elements)

- Use `Sprite2D.offset` to align art to the physics pivot point. Do not adjust `Sprite2D.position` — position is the game-truth origin and is inherited by child nodes.
- Never flip direction using negative X scale. Use `Sprite2D.flip_h` for visual mirroring. Define physics shapes explicitly per variant.
- All scripts use static typing. See `godot-conventions.md`.
- Construction variants respond to mouse input via their `Area2D`. They do not use physics.
- Play variants are instantiated by PlayManager and must not contain any construction-specific logic.

---

## Flipper (Left & Right)

### Scene paths
- `source/gameplay/elements/flipper/flipper_left_construct.tscn`
- `source/gameplay/elements/flipper/flipper_right_construct.tscn`
- `source/gameplay/elements/flipper/flipper_left_play.tscn`
- `source/gameplay/elements/flipper/flipper_right_play.tscn`

### Construction variant
- Root: `Node2D`
- `Sprite2D` — coloured rectangle, ~80×16px. Right variant: `flip_h = true`.
- `Area2D` + `CollisionShape2D` (`RectangleShape2D`, sized to sprite) — for selection and drag hit detection

### Play variant
- Root: `AnimatableBody2D` with `sync_to_physics = true`
- `CollisionShape2D` — `CapsuleShape2D`, length 80px, radius 8px
- `Sprite2D` — same art as construct. Right variant: `flip_h = true`. Use `offset` to align to pivot.
- Script lerps rotation in `_physics_process` on input action

**Why `AnimatableBody2D`, not `StaticBody2D`:** A `StaticBody2D` whose `rotation_degrees` is animated has no physics velocity and cannot transfer momentum to the ball — the ball tunnels or is shoved weakly. `AnimatableBody2D` with `sync_to_physics = true` derives velocity from its motion, giving the flipper a real kick. Move it by setting `rotation_degrees` directly in `_physics_process`; do **not** drive it with a `Tween`, which fights the physics interpolation `sync_to_physics` relies on.

**Flipper angle offsets (relative to placement rotation):**

| Variant | Rest offset | Raised offset |
|---|---|---|
| Left | +30° | -30° |
| Right | -30° | +30° |

Pivot point is the thick end of the flipper (the hinge). The body's position is placed at the hinge. The play scene sets `rotation_degrees` to the placement rotation before `_ready`, so the script captures it as `_base_rotation` and treats rest/raised as offsets — preserving any rotation applied in construction. Hard-coding `±30` would discard it.

**Input handling (play variant script):**
```gdscript
const REST_OFFSET: float = 30.0      # Right variant: -30.0
const RAISED_OFFSET: float = -30.0   # Right variant: 30.0
const LERP_SPEED: float = 25.0
const ACTION: String = "flipper_left"  # Right variant: "flipper_right"

var _base_rotation: float = 0.0

func _ready() -> void:
    _base_rotation = rotation_degrees
    sync_to_physics = true

func _physics_process(delta: float) -> void:
    var pressed: bool = Input.is_action_pressed(ACTION)
    var offset: float = RAISED_OFFSET if pressed else REST_OFFSET
    var target: float = _base_rotation + offset
    rotation_degrees = lerp(rotation_degrees, target, clampf(LERP_SPEED * delta, 0.0, 1.0))
```

### JSON representation
```json
{ "type": "flipper_left", "x": 120.0, "y": 380.0, "rotation": 0.0 }
{ "type": "flipper_right", "x": 680.0, "y": 380.0, "rotation": 0.0 }
```

`rotation` is in degrees. `x`, `y` are the hinge position on the 560×720 canvas.

---

## Launcher

### Scene paths
- `source/gameplay/elements/launcher/launcher_construct.tscn`
- `source/gameplay/elements/launcher/launcher_play.tscn`

### Construction variant
- Root: `Node2D`
- `Sprite2D` — vertical rectangle, ~12×60px
- `Area2D` + `CollisionShape2D` (`RectangleShape2D`) — selection hit detection

### Play variant
- Root: `Node2D`
- Two `StaticBody2D` children forming the launch lane walls (left and right sides, ~6px wide, 60px tall)
- Script handles charge and release

**Behaviour:**
- While `Input.is_action_pressed("launch")`: increment `_charge` each frame, cap at 1.0
- On action release: find ball via group (`get_tree().get_first_node_in_group("ball") as RigidBody2D`), null-check it, call `ball.apply_central_impulse(Vector2(0.0, -_charge * MAX_FORCE))`, reset `_charge`
- `MAX_FORCE: float = 1200.0`
- Ball spawn position is just above the launcher opening on scene entry

### JSON representation
```json
{ "type": "launcher", "x": 760.0, "y": 300.0, "rotation": 0.0 }
```

---

## Pop Bumper

### Scene paths
- `source/gameplay/elements/pop_bumper/pop_bumper_construct.tscn`
- `source/gameplay/elements/pop_bumper/pop_bumper_play.tscn`

### Construction variant
- Root: `Node2D`
- `Sprite2D` — circle, ~40px diameter
- `Area2D` + `CollisionShape2D` (`CircleShape2D`, radius 20) — selection hit detection

### Play variant
- Root: `StaticBody2D`
- `CollisionShape2D` — `CircleShape2D`, radius 20 (on physics layer `Table Elements`)
- `Sprite2D` — same circle art, use `offset` for alignment
- Inner `Area2D` (named `ContactArea`) + `CollisionShape2D` — `CircleShape2D`, radius 24 (slightly larger than the body shape to catch the ball on entry)
- Connect `ContactArea.body_entered` signal

**Impulse handler** (cast to `RigidBody2D` — `Node2D` has no `apply_central_impulse`, so the un-cast call fails under mandatory static typing):
```gdscript
const BUMPER_FORCE: float = 400.0

func _on_contact_area_body_entered(body: Node2D) -> void:
    if body.is_in_group("ball"):
        var direction: Vector2 = (body.global_position - global_position).normalized()
        (body as RigidBody2D).apply_central_impulse(direction * BUMPER_FORCE)
```

### JSON representation
```json
{ "type": "pop_bumper", "x": 300.0, "y": 200.0, "rotation": 0.0 }
```

---

## Drop Target

### Scene paths
- `source/gameplay/elements/drop_target/drop_target_construct.tscn`
- `source/gameplay/elements/drop_target/drop_target_play.tscn`

### Construction variant
- Root: `Node2D`
- `Sprite2D` — horizontal rectangle, ~40×12px
- `Area2D` + `CollisionShape2D` (`RectangleShape2D`) — selection hit detection

### Play variant
- Root: `StaticBody2D`
- `CollisionShape2D` (named `BodyShape`) — `RectangleShape2D`, 40×12px — the physical blocker
- `Sprite2D` — same rectangle art, use `offset` for alignment
- `Area2D` (named `ContactArea`) + `CollisionShape2D` (same size) — contact detection, separate from the body shape
- Connect `ContactArea.body_entered` signal

Name the body shape `BodyShape` (not `CollisionShape2D`) so it is unambiguous to disable: the contact area also contains a `CollisionShape2D`, and two same-named siblings under different parents make `$CollisionShape2D` brittle.

**Contact handler:**
```gdscript
var _dropped: bool = false

func _on_contact_area_body_entered(body: Node2D) -> void:
    if body.is_in_group("ball") and not _dropped:
        _dropped = true
        $BodyShape.set_deferred("disabled", true)
        $Sprite2D.visible = false
```

Use `set_deferred` to disable the collision shape — never disable it directly during a physics callback. The `_dropped` guard makes the drop idempotent.

Target stays down for the session (no reset at MVP).

### JSON representation
```json
{ "type": "drop_target", "x": 400.0, "y": 180.0, "rotation": 0.0 }
```

---

## Spinner

### Scene paths
- `source/gameplay/elements/spinner/spinner_construct.tscn`
- `source/gameplay/elements/spinner/spinner_play.tscn`

### Construction variant
- Root: `Node2D`
- `Sprite2D` — thin vertical rectangle, ~8×40px
- `Area2D` + `CollisionShape2D` (`RectangleShape2D`) — selection hit detection

### Play variant
The spinner must rotate freely when struck. Implement using a `RigidBody2D` constrained to rotation only via a `PinJoint2D`.

Scene structure:
- Root: `Node2D` (static anchor, does not move)
  - `Anchor` (`StaticBody2D`, no collision shape needed — just a physics anchor)
  - `SpinnerBody` (`RigidBody2D`)
    - `CollisionShape2D` — `RectangleShape2D`, 8×40px
    - `Sprite2D` — thin rectangle art, use `offset` for alignment
  - `Joint` (`PinJoint2D`) — set `node_a` to `Anchor`, `node_b` to `SpinnerBody`, position at the spinner's centre

**RigidBody2D settings:**
- `gravity_scale: 0.0`
- `linear_damp: 10.0` (prevents drifting)
- `angular_damp: 2.0` (slows spin gradually)

The `PinJoint2D` allows rotation around the anchor point only. The spinner rotates freely when the ball strikes it.

### JSON representation
```json
{ "type": "spinner", "x": 250.0, "y": 300.0, "rotation": 0.0 }
```

---

## Ball

The ball is not a table element and is not stored in TableData. It is created by the play-scene controller (`play_scene.gd`). It is built in Task 7 alongside the table boundary.

- Node: `RigidBody2D`
- Group: `"ball"` (added via `add_to_group("ball")` in `_ready()`)
- `CollisionShape2D` — `CircleShape2D`, radius 10
- `Sprite2D` — circle sprite, use `offset` for alignment
- Physics layer: `Ball` (layer 1). Mask: `Table Elements` (layer 2).
- `continuous_cd = CCD_MODE_CAST_SHAPE` — the ball is small and fast; continuous collision detection prevents it tunnelling through thin walls, flippers, and the spinner.
- Spawn position: above the launcher if one exists in TableData, otherwise `Vector2(530.0, 600.0)`.

## Table Boundary

Not a table element and not stored in TableData. A `StaticBody2D` enclosure (`source/gameplay/play/table_boundary.tscn`) instantiated by the play scene with four `RectangleShape2D` walls just outside the 560×720 canvas. Without it the ball falls straight out of the world. MVP uses a closed bottom wall (no ball-loss handling yet); it becomes a drain sensor when scoring is added. Physics layer `Table Elements` (2), mask `Ball` (1).
