
[37mPreparing Pi...[0m
[37mChecking Pi installation...[0m
[37mChecking Pi web search package...[0m

[37mLaunching Pi...[0m

I've reviewed the full source tree, scenes, tests, project settings, and cross-checked against the wiki specs. The GUT suite passes (113/113). Here are my findings, grouped by severity.

## Bugs / correctness risks

### 1. Left and Right Shift input actions may both fire on either Shift key
`project.godot` defines `flipper_left` and `flipper_right` with the **same `physical_keycode` (4194325 = KEY_SHIFT)**, distinguished only by `location: 1` vs `location: 2`. Action matching on `physical_keycode` does not reliably distinguish left/right modifiers in all Godot builds — if location isn't honored, pressing either Shift triggers *both* flippers. This needs a manual Verify (Tasks 8/16) with the real keyboard. If it misbehaves, switch to `keycode` with `KEY_SHIFT` plus explicit left/right scancodes, or use `physical_keycode` only on one and a different binding for the other. High risk because the flippers are core interaction.

### 2. Launcher impulse ignores element rotation
`source/gameplay/elements/launcher/launcher_play.gd` fires with a hardcoded world-space vector:
```gdscript
ball.apply_central_impulse(Vector2(0.0, -_charge * MAX_FORCE))
```
The launcher's walls rotate with the node (TableData stores `rotation`), but the impulse is always straight up. A rotated launcher will shoot the ball out of its channel / into a wall. This matches the spec's literal example, but the spec didn't consider rotation. Either honor `rotation_degrees` (`Vector2.UP.rotated(deg_to_rad(rotation_degrees)) * -...` — note the sign), or document that the launcher must be placed at rotation 0. Worth deciding before Task 16.

### 3. Right flipper's collision shape extends the wrong way
`flipper_right_play.tscn` places `CollisionShape2D` at `position = Vector2(40, 0)` — identical to the left flipper — so the physics capsule extends from the hinge **to the right** for both. A right flipper hinged on the right should extend to the **left** (negative X). The `flip_h = true` only mirrors the sprite, not the physics. This follows the letter of `element-specs.md` ("CollisionShape explicitly positioned — no scale mirroring"), but the spec's wording doesn't actually mirror the shape either, so both spec and code may share the same latent geometry bug. Verify in the sandbox (Task 8) that the right flipper's kick direction is correct; if it looks wrong, the right variant's collision shape should sit at `Vector2(-40, 0)` (and the construct selection area likewise, for picking consistency).

### 4. `ConstructionManager._get_element_at` returns arbitrary order on overlap
`intersect_point` results are not distance-sorted, so when two elements overlap the selected one is nondeterministic. Low impact for MVP (elements rarely overlap), but easy to fix: sort results by distance to the query point, or iterate and pick the closest Area2D.

## Spec deviations (doc/code drift)

### 5. `TableData.deserialize` is stricter than the documented schema
`docs/wiki/json-schema.md` and `build-plan.md` show a `deserialize` that *silently skips* non-Dictionary entries and returns `true`. The implemented version (and `test_deserialize_rejects_mixed_type_elements_array`) returns `false` and preserves prior state if **any** entry is invalid. The implementation is *better* (atomic validation before mutation — see commit `f42080e`), but the two spec docs still describe the old behavior. Update `json-schema.md` and `build-plan.md` Task 2 listing to match the shipped code so future tasks don't "fix" it back.

### 6. `main.gd` is still a stub
`source/core/main.gd` only instantiates the debug overlay. Task 14 (scene coordinator / mode switching / `debug_quit`) is TODO, so launching the app shows a blank screen — the construction scene is never loaded. This is expected per the build plan, but note `debug_quit` currently only works inside `physics_sandbox.gd`, not from the real app.

## Project settings gaps (Task 1 acceptance criteria)

### 7. Missing stretch settings
`project.godot` has `window/stretch/mode="canvas_items"` but is missing:
- `window/stretch/aspect` (spec: `"keep"`)
- `window/stretch/scale_mode` (spec: `"fractional"`)

Without these, resizing the window will stretch the canvas non-uniformly (default aspect = `ignore`).

### 8. Default gravity not explicitly set
The `[physics]` section only sets `common/physics_ticks_per_second=120`. Task 1 requires explicitly setting `2d_physics/default_gravity=980` and `default_gravity_vector=(0,1)`. Godot's defaults happen to match, but the spec's whole point was "the value is never an accident of Godot's defaults." Add them explicitly.

## Test coverage gaps

### 9. No tests for ConstructionManager mutation logic
`test_construction_manager.gd` only covers structural/rebuild behavior. The pure logic in `rotate_selected` (rotates selected element + writes back to TableData) and the index bookkeeping in `_delete_element` (adjusting `_selected_index`/`_drag_index` for elements above the deleted one) are deterministic and testable, but have no coverage. The `_delete_element` index-adjustment branches are easy to break silently. Consider unit tests that drive these methods directly (they're public-ish) or via simulated `InputEventMouseButton` on `gui_input`.

### 10. No test that `rebuild_from_table_data` instantiates the *correct* element type
`test_rebuild_from_table_data_places_nodes` asserts child count only. A regression where every entry instantiates `flipper_left` regardless of `entry["type"]` would pass. Assert the scene's script/class on each placed node for at least two distinct types.

## Minor / style

- **Private state accessed in tests**: `test_flipper.gd`, `test_launcher.gd`, `test_drop_target.gd` read `_dropped`/`_charge`/`_charging`/`_base_rotation` directly. Acceptable in GUT, but if you intend these as encapsulated, add minimal getters or test through behavior.
- **`ElementRegistry.get_*_scene` crash on unknown type**: `ELEMENTS[type]` throws on a bad key. All call sites pass validated types, but a defensive `assert` or `push_error` + `return null` would make misuse debuggable.
- **`construction_manager.gd` uses `node.free()` in `rebuild_from_table_data` but `queue_free()` in `_delete_element`**: both correct in context, but the inconsistency is worth a one-line comment.
- **Multiple launchers would all fire the same ball**: `launcher_play.gd` queries the `"ball"` group globally; N launchers each apply impulse on release. Unlikely in MVP, but `MAX_FORCE` tuning in Task 16 assumes one launcher.
- **`PopBumperPlay`/`DropTargetPlay` contact Area2Ds rely on default layer/mask (1/1)** to detect the ball (layer 1). It works, but it's implicit — set `collision_mask = 1` explicitly on `ContactArea` so the dependency is visible.
- **`sync_to_physics = true` set twice** for flippers (in the `.tscn` and again in `_ready()`). Harmless redundancy.

## What's solid

- The non-obvious rules from `CLAUDE.md` are correctly honored: no negative-X mirroring (right flipper uses `flip_h` + explicit shapes), `Sprite2D.offset` used for art alignment, `set_deferred` used in `drop_target_play.gd`'s physics callback, `load()` (not `preload()`) in autoloads.
- `TableData` atomic-deserialize + the regression test for it is genuinely good.
- `SaveLoadManager` dialog awaits both `file_selected` and `canceled` (avoids the classic hang) and uses member vars for the closure-write-back pitfall — exactly as spec'd.
- Static typing is consistent; `untyped_declaration = warn` is enabled; script section order follows the convention.
- Physics layers/masks are correct and consistent across ball, boundary, and all play variants.

**Top priorities before Task 13–16:** verify the Shift-key location matching (#1) and the right flipper geometry (#3) in the sandbox, decide on launcher rotation behavior (#2), and fill the two stretch/gravity project settings (#7, #8).
