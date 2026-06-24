# Testing

This project uses **GUT (Godot Unit Test)** for automated testing. Tests are written alongside the code they cover, not after the fact, and they gate code review (see *The Gate* below).

Read this document before writing any test or any code that has a `Tests:` acceptance criterion in `build-plan.md`.

---

## The Gate (non-negotiable)

**No task is "done" and no code goes to review until its tests exist and the full suite passes headlessly.**

This is the first step of the Pre-PR Checklist in `../Claude-git-workflow.md`: the GUT suite runs and must be green *before* the code review step. A red suite blocks review. Mark a task complete in `build-plan.md` only after `scripts/run_tests.sh` exits 0.

Order, every time:
1. Write/extend the task's tests.
2. `scripts/run_tests.sh` → exit 0 (all green).
3. *Then* code review.
4. *Then* PR.

---

## Framework & Layout

- **GUT 9.x** (Godot 4.x line), vendored under `addons/gut/` and committed to the repo at a pinned version. Enabled via Project Settings → Plugins.
- Tests live under **`source/debug/tests/`**, mirroring the source they cover (e.g. a test for `source/data/table_data.gd` is `source/debug/tests/test_table_data.gd`). This directory sits under `source/debug/`, which is already excluded from export builds — so tests never ship, with no extra export filter needed.
- Test files are named `test_*.gd` and extend `GutTest`.
- Test methods are named `test_*`.
- Config lives in `.gutconfig.json` at the project root, pointing GUT at `res://source/debug/tests`.

See `../Claude-Godot-Generic.md` → *Unit Testing (GUT)* for the broader generic conventions and the full GUT gotcha list; this document holds the PCS-specific gate, coverage expectations, and patterns.

---

## Running Tests

**From the editor:** the GUT bottom panel (after enabling the plugin).

**Headless / CI / pre-review (the authoritative path):**
```bash
scripts/run_tests.sh
```
which imports first (required before the first headless run), then runs the suite:
```bash
godot --headless --import
godot --headless -s res://addons/gut/gut_cmdln.gd
```
Use `gut_cmdln.gd`, **not** `gut_cli.gd`: `gut_cli.gd` extends `Node` and cannot be driven by `-s`; `gut_cmdln.gd` extends `SceneTree` and works. GUT reads `.gutconfig.json` at the project root and exits non-zero if any test fails. Treat a non-zero exit as a hard stop.

---

## What to Unit-Test vs. Verify Manually

GDScript logic is unit-tested. Physics *feel* is not — it is verified manually per each task's **Verify** section. The split:

| Code | Coverage expectation |
|---|---|
| `TableData` | Full: serialize/deserialize round-trip, export dict shape, add/remove/update/clear, malformed-JSON and missing-key failure paths. |
| `SaveLoadManager` | File save → load round-trip (use `user://` temp paths), export artifact shape, missing-file and unwritable-path failure paths. The FileDialog flow is exercised manually, not unit-tested. |
| `ElementRegistry` | Every type resolves to a loadable construct and play scene; labels and `all_types()` are correct. |
| Element scenes, ball, boundary | **Smoke test only:** each `.tscn` instantiates without error and exposes its expected API/exported members. Collision/impulse *behaviour* is manual (the Verify sections). |
| Construction/Play/Main coordination | Integration tests where feasible (e.g. TableData survives a construction → play → construction round-trip); scene-transition timing is verified manually. |

Rule of thumb: **if it is deterministic GDScript, it has a unit test; if it is physics behaviour or input feel, it has a manual Verify step.** Both are required — neither replaces the other.

---

## Patterns

**Pure data classes** — instantiate directly, no tree needed:
```gdscript
extends GutTest

func test_serialize_round_trip() -> void:
    var data: TableData = TableData.new()
    data.add_element("flipper_left", 120.0, 380.0, 0.0)
    var restored: TableData = TableData.new()
    assert_true(restored.deserialize(data.serialize()))
    assert_eq(restored.elements.size(), 1)
    assert_eq(restored.elements[0]["type"], "flipper_left")

func test_deserialize_rejects_garbage() -> void:
    var data: TableData = TableData.new()
    assert_false(data.deserialize("not json"))
    assert_false(data.deserialize("{}"))  # missing required keys
```

**File I/O** — always write to `user://` temp paths and clean up:
```gdscript
func test_save_load_round_trip() -> void:
    var path: String = "user://test_table_%d.json" % Time.get_ticks_usec()
    var data: TableData = TableData.new()
    data.add_element("pop_bumper", 300.0, 200.0, 0.0)
    assert_true(SaveLoadManager.save(path, data))
    var loaded: TableData = SaveLoadManager.load_table(path)
    assert_not_null(loaded)
    assert_eq(loaded.elements.size(), 1)
    DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
```

**Autoloads** (`SaveLoadManager`, `ElementRegistry`) are available by name inside tests — they are loaded with the project.

**Scene smoke tests** — instantiate and free automatically so the test tree stays clean:
```gdscript
func test_pop_bumper_play_instantiates() -> void:
    var scene: PackedScene = ElementRegistry.get_play_scene("pop_bumper")
    var node: Node = add_child_autofree(scene.instantiate())
    assert_not_null(node)
```

---

## Gotchas (see `../Claude-Godot-Generic.md` for the full list)

These bite this codebase specifically:

- **`push_error` during a test fails it.** GUT treats any `push_error` in a test frame as an unexpected error, even if all assertions pass. `SaveLoadManager` and `TableData` call `push_error` on failure paths — assert on the return value (`null` / `false`), do not drive a test through the `push_error` branch, or capture/expect it per GUT's API.
- **`JSON.parse_string()` returns an untyped `Array`.** You cannot assign it to `Array[Dictionary]`. `TableData.deserialize()` must iterate the parsed array and append each `Dictionary` explicitly — not `(... as Array).duplicate(true)`.
- **Empty string to `JSON.parse_string()` throws an engine error** that GUT flags. `deserialize()` guards with `if json_string.is_empty(): return false` before parsing.

## Visual Verification (optional)

For tasks needing visual confirmation that a scene renders, the screenshot helper documented in `../Claude-Godot-Generic.md` (`source/debug/tests/godot_screenshot.sh`) launches a scene headlessly, captures it, and fails on `ERROR`/`SCRIPT ERROR` log lines. Useful for the construction/play scene-layout tasks. This is a manual aid, not part of the automated gate.

## Notes

- Exact `.gutconfig.json` keys and CLI flags vary slightly across GUT versions — confirm against the installed version's docs when setting it up in the GUT task.
- Keep tests deterministic. Do not assert on frame-rate, wall-clock timing, or exact post-physics positions.
- A bug fix gets a regression test that fails before the fix and passes after.
