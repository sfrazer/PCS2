# Build Plan

Tasks are ordered by dependency. Each task is scoped for a single worker agent session. Before starting any task, read `godot-conventions.md`. Before any task touching serialization or scene structure, also read `architecture.md` and `json-schema.md`. Before writing any test, read `testing.md`.

Mark each task complete in this file when done.

---

## Testing Gate (applies to every task)

This project is test-gated. Read `testing.md` for conventions and patterns.

**A task is not complete — and its code does not go to review — until its tests exist and the full GUT suite passes headlessly (`scripts/run_tests.sh` exits 0).** This is the first step of the Pre-PR Checklist in `../Claude-git-workflow.md`: tests are green *before* the code review step, never after.

Per task:
- Tasks with deterministic GDScript logic carry an explicit **Tests:** acceptance criterion below. That criterion must be met before the task is marked done.
- Tasks that are primarily scenes/physics (elements, ball, boundary, play scene) require at minimum a **smoke test** — the scene instantiates without error and exposes its expected API — plus unit tests for any pure helper logic they introduce. Physics *behaviour* is verified manually via each task's **Verify** section; see the table in `testing.md`.
- GUT itself is set up in **Task 1B** before any logic task ships tests.

---

## Task 1 — Project Scaffold

**Status:** DONE

**Goal:** Create the Godot 4.7 project and configure all project settings before any gameplay code is written.

**Steps:**

1. Create a new Godot 4.7 project named `PCS`.

2. Create the folder structure:
   ```
   assets/sprites/
   source/core/autoloads/
   source/data/
   source/gameplay/construction/
   source/gameplay/play/
   source/gameplay/ball/
   source/gameplay/elements/flipper/
   source/gameplay/elements/launcher/
   source/gameplay/elements/pop_bumper/
   source/gameplay/elements/drop_target/
   source/gameplay/elements/spinner/
   source/ui/
   source/debug/
   ```

3. Apply Project Settings:
   - **Display → Window → Size → Viewport Width:** 1280
   - **Display → Window → Size → Viewport Height:** 768
   - **Display → Window → Size → Minimum Width:** 1024
   - **Display → Window → Size → Minimum Height:** 640
   - **Display → Window → Stretch → Mode:** `canvas_items`
   - **Display → Window → Stretch → Aspect:** `keep`
   - **Display → Window → Stretch → Scale Mode:** `fractional`
   - **Physics → Common → Physics Ticks Per Second:** 120
   - **Physics → 2D → Default Gravity:** 980
   - **Physics → 2D → Default Gravity Vector:** `(0, 1)` (gravity pulls toward the bottom of the canvas — the flipper edge)
   - **Application → Run → Max FPS:** 60
   - **Application → Config → Version:** `0.1.0`
   - **Debug → GDScript → Untyped Declaration:** Warn

   Default Gravity is a primary "feel" parameter and will be tuned in Task 16. Setting it explicitly here means the value is never an accident of Godot's defaults.

4. Set physics layer names (Project Settings → Layer Names → 2D Physics):
   - Layer 1: `Ball`
   - Layer 2: `Table Elements`

5. Define Input Map actions (Project Settings → Input Map):
   - `flipper_left` → Left Shift
   - `flipper_right` → Right Shift
   - `launch` → Space
   - `debug_quit` → Escape

6. Register Autoloads (Project Settings → Autoload):
   - Name: `ElementRegistry`, Path: `res://source/core/autoloads/element_registry.gd`
   - Name: `SaveLoadManager`, Path: `res://source/core/autoloads/save_load_manager.gd`
   Create stub files for both (empty `extends Node` with a comment).

7. Create a stub `source/core/main.tscn` with a `Node2D` root named `Main`. Set its process mode to `Always`.

8. Create a minimal `source/debug/debug_overlay.tscn`: a `CanvasLayer` with a `Label` that displays `Engine.get_frames_per_second()` and the version string from `ProjectSettings.get("application/config/version")`. Update the label in `_process()`.

9. Add the debug overlay as a child of Main, **guarded so it never ships in release builds**:
   ```gdscript
   if OS.is_debug_build():
       add_child(load("res://source/debug/debug_overlay.tscn").instantiate())
   ```
   Additionally, exclude `source/debug/` via the export `exclude_filter` when export presets are created. The runtime guard and the export filter are both required — the guard protects against an export preset that forgets the filter.

**Verify:** Project opens, runs without errors, displays FPS and version string. Running an exported (non-debug) build shows no overlay.

---

## Task 1B — Test Harness (GUT) Setup

**Status:** DONE

**Goal:** Install and configure GUT so that every subsequent task ships with passing unit tests, and establish the headless runner that gates code review.

This is conceptually "Task 0," but GUT cannot be installed until the Godot project exists, so it runs immediately after the scaffold and before any logic task (Task 2 onward). Read `testing.md` first.

**Steps:**

1. Vendor **GUT 9.x** (Godot 4.x line) into `addons/gut/` at a pinned version and commit it. Enable it in Project Settings → Plugins.

2. Create the test directory `source/debug/tests/`. Tests live here, mirroring the source they cover (e.g. `source/debug/tests/test_table_data.gd`). Because `source/debug/` is already excluded from export builds, tests never ship — no extra export filter is needed. See `testing.md`.

3. Create `.gutconfig.json` at the project root pointing GUT at the test dir (confirm key names against the installed GUT version):
   ```json
   {
     "dirs": ["res://source/debug/tests"],
     "include_subdirs": true,
     "log_level": 1,
     "should_exit": true,
     "should_exit_on_success": true
   }
   ```

4. Create `scripts/run_tests.sh` (the authoritative pre-review runner; mark it executable). It imports first — required before the first headless run — then runs the suite via `gut_cmdln.gd` (which extends `SceneTree`; `gut_cli.gd` extends `Node` and cannot be driven by `-s`):
   ```bash
   #!/usr/bin/env bash
   set -euo pipefail
   GODOT="${GODOT:-godot}"
   "$GODOT" --headless --import
   "$GODOT" --headless -s res://addons/gut/gut_cmdln.gd
   ```
   GUT reads `.gutconfig.json` at the project root and must exit non-zero when any test fails.

5. Write a smoke test `source/debug/tests/test_smoke.gd` proving the harness runs:
   ```gdscript
   extends GutTest

   func test_harness_runs() -> void:
       assert_true(true)
   ```

6. Add a regression-proof of the gate: temporarily add a failing assertion, run `scripts/run_tests.sh`, confirm it exits non-zero, then remove it. (This proves the gate can actually fail a build, not just pass.)

7. **Enforcement hook (recommended):** add a git `pre-commit` hook (or document it for the user to install) that runs `scripts/run_tests.sh` and blocks the commit on failure. The hook is the automated backstop for the manual gate; CI may replace it later.

8. Update `.gitignore` so GUT's runtime output (e.g. `.gut_editor_config.json`, result temp files) is not committed, while keeping `addons/gut/` itself tracked.

**Verify:** `scripts/run_tests.sh` runs headless, the smoke test passes, and the script exits 0. A deliberately failing test makes it exit non-zero.

---

## Task 2 — TableData Class

**Status:** DONE

**Goal:** Implement the canonical data model for a table.

**File:** `source/data/table_data.gd`

**Implementation:**

```gdscript
class_name TableData

const VERSION: int = 1

var elements: Array[Dictionary] = []

func serialize() -> String:
    var data: Dictionary = {
        "version": VERSION,
        "elements": elements.duplicate(true),
    }
    return JSON.stringify(data, "\t")

func deserialize(json_string: String) -> bool:
    if json_string.is_empty():  # empty string makes JSON.parse_string emit an engine error
        return false
    var parsed: Variant = JSON.parse_string(json_string)
    if not parsed is Dictionary:
        return false
    var data: Dictionary = parsed as Dictionary
    if not data.has("version") or not data.has("elements"):
        return false
    if not data["elements"] is Array:
        return false
    # JSON.parse_string returns an untyped Array; it cannot be assigned to
    # Array[Dictionary] directly. Iterate and append each entry explicitly.
    elements.clear()
    for entry: Variant in data["elements"] as Array:
        if entry is Dictionary:
            elements.append((entry as Dictionary).duplicate(true))
    return true

func to_export_dict() -> Dictionary:
    return {
        "canvas_width": 800,
        "canvas_height": 420,
        "elements": elements.duplicate(true),
    }

func add_element(type: String, x: float, y: float, rotation_deg: float = 0.0) -> void:
    elements.append({ "type": type, "x": x, "y": y, "rotation": rotation_deg })

func remove_element(index: int) -> void:
    elements.remove_at(index)

func update_element(index: int, x: float, y: float, rotation_deg: float) -> void:
    elements[index]["x"] = x
    elements[index]["y"] = y
    elements[index]["rotation"] = rotation_deg

func clear() -> void:
    elements.clear()
```

**Tests:** `source/debug/tests/test_table_data.gd` covering: serialize → deserialize round-trip preserves elements; `serialize()` output contains `version` and `elements`; `to_export_dict()` has `canvas_width`/`canvas_height`/`elements` and no `version`; `add_element`/`remove_element`/`update_element`/`clear` mutate state correctly; `deserialize()` returns `false` on non-JSON input, on a JSON non-Dictionary, and on a Dictionary missing `version` or `elements`. Suite green via `scripts/run_tests.sh`.

**Verify:** Manually call `serialize()` on a populated instance and confirm the output is valid JSON matching the save file schema in `json-schema.md`. Call `deserialize()` on that string and confirm `elements` is restored.

---

## Task 3 — SaveLoadManager

**Status:** DONE

**Goal:** Implement the file I/O autoload singleton.

**File:** `source/core/autoloads/save_load_manager.gd`

```gdscript
extends Node

var _dialog_path: String = ""
var _dialog_done: bool = false

func save(path: String, data: TableData) -> bool:
    var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
    if file == null:
        push_error("SaveLoadManager: cannot open file for writing: " + path)
        return false
    file.store_string(data.serialize())
    file.close()
    return true

func load_table(path: String) -> TableData:
    if not FileAccess.file_exists(path):
        push_error("SaveLoadManager: file not found: " + path)
        return null
    var file: FileAccess = FileAccess.open(path, FileAccess.READ)
    if file == null:
        return null
    var content: String = file.get_as_text()
    file.close()
    var data: TableData = TableData.new()
    if not data.deserialize(content):
        push_error("SaveLoadManager: failed to parse file: " + path)
        return null
    return data

func export_artifact(path: String, data: TableData) -> bool:
    var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
    if file == null:
        push_error("SaveLoadManager: cannot open file for export: " + path)
        return false
    file.store_string(JSON.stringify(data.to_export_dict(), "\t"))
    file.close()
    return true

func open_save_dialog() -> String:
    return await _show_dialog(FileDialog.FILE_MODE_SAVE_FILE)

func open_load_dialog() -> String:
    return await _show_dialog(FileDialog.FILE_MODE_OPEN_FILE)

# Returns the chosen path, or "" if the user cancelled. Awaits BOTH the
# file_selected and canceled signals — awaiting only file_selected hangs
# the caller forever when the dialog is dismissed.
func _show_dialog(mode: FileDialog.FileMode) -> String:
    var dialog: FileDialog = FileDialog.new()
    dialog.file_mode = mode
    dialog.filters = ["*.json ; JSON Table Files"]
    dialog.access = FileDialog.ACCESS_FILESYSTEM
    _dialog_path = ""
    _dialog_done = false
    dialog.file_selected.connect(_on_dialog_file_selected)
    dialog.canceled.connect(_on_dialog_canceled)
    get_tree().root.add_child(dialog)
    dialog.popup_centered(Vector2i(800, 600))
    while not _dialog_done:
        await get_tree().process_frame
    dialog.queue_free()
    return _dialog_path

func _on_dialog_file_selected(path: String) -> void:
    _dialog_path = path
    _dialog_done = true

func _on_dialog_canceled() -> void:
    _dialog_path = ""
    _dialog_done = true
```

The member-variable + poll pattern is used deliberately: GDScript lambdas capture outer locals by value, so a closure cannot write the chosen path back into a local. Member vars and real callback methods avoid that pitfall. This assumes one dialog open at a time, which is always true for this app.

**Tests:** `source/debug/tests/test_save_load_manager.gd` covering: `save()` then `load_table()` on a `user://` temp path restores elements (round-trip); `load_table()` returns `null` for a missing file and for a file with malformed JSON; `export_artifact()` writes a file whose parsed JSON matches the export schema. Use unique `user://` paths and delete them at the end of each test. The FileDialog flow is exercised manually, not unit-tested. Suite green via `scripts/run_tests.sh`.

**Verify:** From a test scene, create a `TableData`, call `save()`, confirm the file exists with correct JSON, call `load_table()` on the same path, confirm elements are restored. Open a dialog and press Cancel — confirm the caller resumes with an empty string rather than hanging.

---

## Task 4 — ElementRegistry

**Status:** DONE

**Goal:** Implement the element type registry autoload and create placeholder scenes for all 12 element variants.

**File:** `source/core/autoloads/element_registry.gd`

```gdscript
extends Node

const ELEMENTS: Dictionary = {
    "flipper_left":  { "label": "Flipper L", "construct": "res://source/gameplay/elements/flipper/flipper_left_construct.tscn",   "play": "res://source/gameplay/elements/flipper/flipper_left_play.tscn"   },
    "flipper_right": { "label": "Flipper R", "construct": "res://source/gameplay/elements/flipper/flipper_right_construct.tscn",  "play": "res://source/gameplay/elements/flipper/flipper_right_play.tscn"  },
    "launcher":      { "label": "Launcher",  "construct": "res://source/gameplay/elements/launcher/launcher_construct.tscn",      "play": "res://source/gameplay/elements/launcher/launcher_play.tscn"      },
    "pop_bumper":    { "label": "Bumper",    "construct": "res://source/gameplay/elements/pop_bumper/pop_bumper_construct.tscn",  "play": "res://source/gameplay/elements/pop_bumper/pop_bumper_play.tscn"  },
    "drop_target":   { "label": "Target",    "construct": "res://source/gameplay/elements/drop_target/drop_target_construct.tscn","play": "res://source/gameplay/elements/drop_target/drop_target_play.tscn" },
    "spinner":       { "label": "Spinner",   "construct": "res://source/gameplay/elements/spinner/spinner_construct.tscn",        "play": "res://source/gameplay/elements/spinner/spinner_play.tscn"        },
}

func get_construct_scene(type: String) -> PackedScene:
    return load(ELEMENTS[type]["construct"]) as PackedScene

func get_play_scene(type: String) -> PackedScene:
    return load(ELEMENTS[type]["play"]) as PackedScene

func get_label(type: String) -> String:
    return ELEMENTS[type]["label"] as String

func all_types() -> Array[String]:
    var types: Array[String] = []
    for key: String in ELEMENTS.keys():
        types.append(key)
    return types
```

Create placeholder `.tscn` files for all 12 scene paths. Each placeholder is a scene with a root `Node2D` and no children — just enough for the file to exist and load without errors. Real content will be added in Tasks 8–12.

**Tests:** `source/debug/tests/test_element_registry.gd` covering: `all_types()` returns the six expected type strings; for every type, `get_construct_scene()` and `get_play_scene()` return a non-null loadable `PackedScene` that instantiates without error; `get_label()` returns the expected label for each type. Suite green via `scripts/run_tests.sh`.

**Verify:** All 12 scene paths load without errors via `get_construct_scene()` and `get_play_scene()` in a test script.

---

## Task 5 — Construction Scene Layout

**Status:** DONE

**Goal:** Build the construction scene's visual structure and wire button signals to stub handlers.

**File:** `source/gameplay/construction/construction_scene.tscn` + `construction_scene.gd`

**Scene structure:**
```
ConstructionScene (Node2D) — process mode: Pausable  [construction_scene.gd]
├── ConstructionManager (Node)                       [construction_manager.gd — added in Task 6]
├── Toolbar (HBoxContainer) — anchored top, full width
│   ├── SaveButton (Button, text: "Save")
│   ├── LoadButton (Button, text: "Load")
│   ├── ExportButton (Button, text: "Export")
│   └── PlayButton (Button, text: "Play")
├── Palette (VBoxContainer) — anchored left, below toolbar
│   └── (populated at runtime from ElementRegistry)
└── TableArea (SubViewportContainer) — fills remaining space, size 800×420
    └── TableViewport (SubViewport, size 800×420, handle_input_locally: false,
                       physics_object_picking: true)
        └── PlacedElements (Node2D)
```

**Script ownership:** `construction_scene.gd` (on the root) owns the UI — palette, toolbar, and the `play_requested` signal. `construction_manager.gd` (Task 6) is attached to a **child `Node` named `ConstructionManager`**, not the root — a node can hold only one script, so the manager cannot also live on the root. The root holds a reference: `@onready var _construction_manager: Node = $ConstructionManager`.

**SubViewport input:** Mouse picking on placed-element `Area2D`s only works when the SubViewport has `physics_object_picking = true`. Set it in the scene. The construction canvas must convert mouse positions from `SubViewportContainer`-local space into viewport space before placement; the manager handles this in Task 6.

In `construction_scene.gd`:
- In `_ready()`: iterate `ElementRegistry.all_types()`, create a `Button` for each, set text to `ElementRegistry.get_label(type)`, add to Palette, connect `pressed` signal to a handler that calls `_construction_manager.set_selected_type(type)`
- Stub handlers for toolbar buttons: `_on_save_pressed()`, `_on_load_pressed()`, `_on_export_pressed()`, `_on_play_pressed()` — print a message for now (`_on_play_pressed` will later emit `play_requested` with `_construction_manager.get_table_data()`)
- Expose a signal: `signal play_requested(data: TableData)`

**Verify:** Scene opens and displays the palette with six labelled buttons and four toolbar buttons. No errors.

---

## Task 6 — ConstructionManager

**Status:** DONE

**Goal:** Implement all construction mode mouse interaction. At the end of this task, elements can be placed, moved, rotated, and deleted, and TableData stays in sync.

**File:** `source/gameplay/construction/construction_manager.gd` — attach to the `ConstructionManager` child node created in Task 5.

Read `architecture.md` (ConstructionManager section) and `element-specs.md` (Shared Rules) before implementing.

**Two distinct selection concepts — do not conflate them:**
- `_selected_type` — the *palette* type queued for the next placement (set by palette buttons).
- `_selected_index` — the *placed element* currently selected on the canvas (set by clicking an existing element). Rotate and delete operate on this. `-1` means nothing selected.

**State variables:**
```gdscript
var _table_data: TableData = TableData.new()
var _selected_type: String = ""
var _selected_index: int = -1            # currently selected PLACED element
var _placed_nodes: Array[Node2D] = []    # parallel array to _table_data.elements
var _drag_node: Node2D = null
var _drag_index: int = -1
var _drag_offset: Vector2 = Vector2.ZERO
```

**Key methods:**
- `set_selected_type(type: String)` — called by palette buttons
- `_on_canvas_input(event: InputEvent)` — connected to the SubViewport (or a transparent Control overlaying it). Handles left-click (place / select / begin drag), left-drag (move), right-click (delete), mouse-wheel (rotate selected). Convert event positions to viewport coordinates before use.
- `rebuild_from_table_data(data: TableData)` — clears PlacedElements and `_placed_nodes`, reinstantiates all construct scenes from `data.elements`, resets `_selected_index` to `-1`
- `get_table_data() -> TableData` — returns current `_table_data`
- `rotate_selected(delta_degrees: float)` — rotates the element at `_selected_index` and updates its TableData entry

**Placement:** On left-click over empty canvas with `_selected_type` set, call `ElementRegistry.get_construct_scene(_selected_type).instantiate()`, set position to the click position in viewport coordinates, add to PlacedElements, append entry to `_table_data`, and set `_selected_index` to the new element.

**Select / Drag:** On left-press over an existing element's Area2D, set `_selected_index` to that element and begin drag. On mouse move during drag, update the node position and the matching `_table_data.elements` entry. On left-release, end drag.

**Delete:** On right-click over an existing element's Area2D, `queue_free()` the node, remove from `_placed_nodes` and `_table_data.elements` at the same index, and clear `_selected_index` if it pointed at the removed element (adjust indices above it).

**Rotation:** Mouse-wheel up/down over the canvas rotates the selected element by ±15° via `rotate_selected()`. (Rotation uses mouse input directly rather than an Input Map action, keeping the Input Map limited to play-mode controls.)

**Verify:** Place one of each element type, drag two to new positions, rotate one with the mouse wheel, delete one, save and reload — confirm canvas restores exactly (positions and rotations).

> **Note:** Select / drag / delete / rotate-on-selection require construct scenes to have an `Area2D` (per `element-specs.md`). Task 4 placeholders are bare `Node2D` roots with no children, so only placement can be exercised until Tasks 8–12 replace them with real construct scenes. Full Verify deferred to after Task 12.

---

## Task 7 — Ball, Table Boundary & Physics Sandbox

**Status:** DONE

**Goal:** Create the ball, the playfield enclosure, and a debug sandbox so the element play-variants (Tasks 8–12) can be verified before the full play scene exists. Without a boundary the ball falls straight out of the world and no physics can be observed.

**Files:**
- `source/gameplay/ball/ball.tscn` + `ball.gd`
- `source/gameplay/play/table_boundary.tscn`
- `source/debug/physics_sandbox.tscn` + `physics_sandbox.gd` (debug only — excluded from export)

**Ball** (`ball.tscn`):
- Root: `RigidBody2D`
- `CollisionShape2D`: `CircleShape2D`, radius 10
- `Sprite2D`: placeholder circle, `offset` for alignment
- Physics layer: `Ball` (1). Mask: `Table Elements` (2).
- `continuous_cd = CCD_MODE_CAST_SHAPE` — the ball is small and fast; continuous collision detection prevents tunnelling through thin walls, flippers, and the spinner.
- `ball.gd`:
  ```gdscript
  extends RigidBody2D

  func _ready() -> void:
      add_to_group("ball")
  ```

**Table Boundary** (`table_boundary.tscn`):
- Root: `StaticBody2D`, physics layer `Table Elements` (2), mask `Ball` (1)
- Four `CollisionShape2D` children (`RectangleShape2D`) forming left, right, top, and bottom walls just outside the 0–800 × 0–420 canvas rectangle.
- **MVP uses a closed bottom wall** so the ball stays in play during testing. There is no ball-loss/respawn handling at MVP, so an open drain would simply lose the ball with no recovery. When scoring/ball-loss is added later, the bottom wall is replaced with a drain sensor.

**Physics Sandbox** (`physics_sandbox.tscn`, in `source/debug/`):
- A `SubViewportContainer` + `SubViewport` (800×420) containing an instance of `table_boundary`, an instance of `ball`, and room to drop element play scenes by hand.
- Used as a scratch harness for Tasks 8–12. Lives in `source/debug/` and is excluded from export.

**Tests:** `source/debug/tests/test_ball_boundary.gd` — smoke tests: `ball.tscn` instantiates without error, is a `RigidBody2D`, joins group `"ball"` on `_ready`, and has its `Ball`/`Table Elements` layer/mask configured; `table_boundary.tscn` instantiates without error as a `StaticBody2D` with four collision shapes. Ball-containment behaviour is the manual Verify below, not a unit test. Suite green via `scripts/run_tests.sh`.

**Verify:** Run the sandbox. The ball falls under gravity and comes to rest against the bottom wall. The ball never escapes the canvas rectangle.

---

## Task 8 — Flipper Elements

**Status:** DONE

**Goal:** Implement all four flipper scenes (left/right × construct/play).

Read `element-specs.md` (Flipper section) and `godot-conventions.md` (Never flip with negative X scale) before starting.

**Left construct** (`flipper_left_construct.tscn`):
- `Node2D` root
- `Sprite2D`: placeholder coloured rectangle 80×16px, `offset = Vector2(40, 0)` to align left edge to origin (hinge)
- `Area2D` + `CollisionShape2D` (`RectangleShape2D`, size 80×16, `position = Vector2(40, 0)`)

**Right construct** (`flipper_right_construct.tscn`):
- Same structure. `Sprite2D.flip_h = true`. CollisionShape positioned identically — do NOT use negative scale.

**Left play** (`flipper_left_play.tscn`):
- `AnimatableBody2D` root (physics layer: Table Elements, mask: Ball), `sync_to_physics = true`
- `CollisionShape2D`: `CapsuleShape2D` length 80, radius 8, `position = Vector2(40, 0)`
- `Sprite2D`: same art, `offset = Vector2(40, 0)`
- Script (`flipper_left_play.gd`):

```gdscript
extends AnimatableBody2D

const REST_OFFSET: float = 30.0      # degrees, relative to placement rotation
const RAISED_OFFSET: float = -30.0
const LERP_SPEED: float = 25.0       # higher = snappier flip
const ACTION: String = "flipper_left"

var _base_rotation: float = 0.0      # placement rotation from TableData

func _ready() -> void:
    _base_rotation = rotation_degrees
    sync_to_physics = true

func _physics_process(delta: float) -> void:
    var pressed: bool = Input.is_action_pressed(ACTION)
    var offset: float = RAISED_OFFSET if pressed else REST_OFFSET
    var target: float = _base_rotation + offset
    rotation_degrees = lerp(rotation_degrees, target, clampf(LERP_SPEED * delta, 0.0, 1.0))
```

**Why `AnimatableBody2D`, not `StaticBody2D`:** A `StaticBody2D` rotated by setting `rotation_degrees` has no physics velocity, so it cannot transfer momentum to the ball — the ball tunnels or is shoved weakly. `AnimatableBody2D` with `sync_to_physics = true` derives velocity from its motion, giving the flipper a real "kick." Move it in `_physics_process` by setting `rotation_degrees` directly — do **not** drive it with a `Tween`, which fights the physics interpolation `sync_to_physics` relies on.

**Why `_base_rotation`:** The play scene sets the node's `rotation_degrees` to the placement rotation before `_ready`. Capturing it as `_base_rotation` and treating REST/RAISED as offsets preserves any rotation the user applied in construction. Hard-coding `±30` would silently discard it.

**Right play** (`flipper_right_play.tscn`):
- Same structure. `Sprite2D.flip_h = true`. CollisionShape explicitly positioned — no scale mirroring.
- Script uses `ACTION = "flipper_right"`, `REST_OFFSET = -30.0`, `RAISED_OFFSET = 30.0`.

**Verify:** Drop both play variants into the physics sandbox. Confirm left flipper raises on Left Shift, right on Right Shift, and that a flipper sweeping into the ball launches it (momentum transfer). Confirm `flip_h` is correct and CollisionShape2D positions are correct in the Remote inspector during play. Place a flipper at a non-zero rotation and confirm it is preserved in play.

---

## Task 9 — Launcher Element

**Status:** TODO

**Goal:** Implement launcher construct and play scenes.

Read `element-specs.md` (Launcher section) before starting.

**Construct** (`launcher_construct.tscn`):
- `Node2D` root
- `Sprite2D`: vertical rectangle 12×60px
- `Area2D` + `CollisionShape2D` (`RectangleShape2D`, 12×60)

**Play** (`launcher_play.tscn`):
- `Node2D` root
- Two `StaticBody2D` children: left wall and right wall, each ~6×60px, positioned to form a channel (physics layer: Table Elements, mask: Ball)
- Script (`launcher_play.gd`):

```gdscript
extends Node2D

const MAX_FORCE: float = 1200.0

var _charge: float = 0.0
var _charging: bool = false

func _physics_process(delta: float) -> void:
    if Input.is_action_pressed("launch"):
        _charge = minf(_charge + delta * 2.0, 1.0)
        _charging = true
    elif _charging:
        _charging = false
        _fire()

func _fire() -> void:
    var ball: RigidBody2D = get_tree().get_first_node_in_group("ball") as RigidBody2D
    if ball != null:
        ball.apply_central_impulse(Vector2(0.0, -_charge * MAX_FORCE))
    _charge = 0.0
```

**Verify:** In the physics sandbox, hold Space — ball launches upward with force proportional to hold duration.

---

## Task 10 — Pop Bumper Element

**Status:** TODO

**Goal:** Implement pop bumper construct and play scenes.

Read `element-specs.md` (Pop Bumper section) before starting. Note use of `set_deferred` if modifying physics state in a callback.

**Construct** (`pop_bumper_construct.tscn`):
- `Node2D` root
- `Sprite2D`: circle ~40px diameter
- `Area2D` + `CollisionShape2D` (`CircleShape2D`, radius 20)

**Play** (`pop_bumper_play.tscn`):
- `StaticBody2D` root (physics layer: Table Elements, mask: Ball)
- `CollisionShape2D`: `CircleShape2D`, radius 20
- `Sprite2D`: circle art, `offset` for alignment
- `Area2D` (named `ContactArea`) + `CollisionShape2D`: `CircleShape2D`, radius 24
- Connect `ContactArea.body_entered` signal to script

```gdscript
extends StaticBody2D

const BUMPER_FORCE: float = 400.0

func _on_contact_area_body_entered(body: Node2D) -> void:
    if body.is_in_group("ball"):
        var direction: Vector2 = (body.global_position - global_position).normalized()
        (body as RigidBody2D).apply_central_impulse(direction * BUMPER_FORCE)
```

**Verify:** In the physics sandbox, ball striking the bumper is repelled outward regardless of approach angle.

---

## Task 11 — Drop Target Element

**Status:** TODO

**Goal:** Implement drop target construct and play scenes.

Read `element-specs.md` (Drop Target section) before starting. The body collision shape must be disabled with `set_deferred`.

**Construct** (`drop_target_construct.tscn`):
- `Node2D` root
- `Sprite2D`: horizontal rectangle 40×12px
- `Area2D` + `CollisionShape2D` (`RectangleShape2D`, 40×12)

**Play** (`drop_target_play.tscn`):
- `StaticBody2D` root (physics layer: Table Elements, mask: Ball)
- `CollisionShape2D` (named `BodyShape`): `RectangleShape2D`, 40×12
- `Sprite2D`: same art, `offset` for alignment
- `Area2D` (named `ContactArea`) + `CollisionShape2D`: `RectangleShape2D`, 40×12
- Connect `ContactArea.body_entered` signal

The body shape and the contact area shape are two separate `CollisionShape2D`s. Name the body shape `BodyShape` so the script can disable it unambiguously — leaving both named `CollisionShape2D` causes Godot to auto-rename one and makes `$BodyShape` brittle.

```gdscript
extends StaticBody2D

var _dropped: bool = false

func _on_contact_area_body_entered(body: Node2D) -> void:
    if body.is_in_group("ball") and not _dropped:
        _dropped = true
        $BodyShape.set_deferred("disabled", true)
        $Sprite2D.visible = false
```

**Verify:** In the physics sandbox, the ball drops the target on contact; the target hides and the ball passes through it on subsequent approaches. Target stays down for the session.

---

## Task 12 — Spinner Element

**Status:** TODO

**Goal:** Implement spinner construct and play scenes.

Read `element-specs.md` (Spinner section) before starting. The `PinJoint2D` setup is the most complex part.

**Construct** (`spinner_construct.tscn`):
- `Node2D` root
- `Sprite2D`: thin rectangle 8×40px
- `Area2D` + `CollisionShape2D` (`RectangleShape2D`, 8×40)

**Play** (`spinner_play.tscn`):

```
Node2D (root — static anchor parent)
├── Anchor (StaticBody2D — no collision needed)
├── SpinnerBody (RigidBody2D)
│   ├── CollisionShape2D (RectangleShape2D, 8×40)
│   └── Sprite2D (thin rectangle art)
└── Joint (PinJoint2D)
```

`PinJoint2D` configuration:
- `node_a` = path to `Anchor`
- `node_b` = path to `SpinnerBody`
- Position = `Vector2(0, 0)` (centre of the spinner)

`SpinnerBody` (RigidBody2D) settings:
- `gravity_scale = 0.0`
- `linear_damp = 10.0`
- `angular_damp = 2.0`
- Physics layer: Table Elements, mask: Ball

**Verify:** In the physics sandbox, ball strikes the spinner and causes it to rotate. Rotation decays. Spinner does not translate.

---

## Task 13 — Play Scene

**Status:** TODO

**Goal:** Implement the play scene that consumes TableData and runs the physics simulation, using the ball and table boundary from Task 7.

**Files:** `source/gameplay/play/play_scene.tscn` + `play_scene.gd`

**Scene structure:**
```
PlayScene (Node2D) — process mode: Pausable        [play_scene.gd]
├── TableViewportContainer (SubViewportContainer, 800×420)
│   └── TableViewport (SubViewport, 800×420)
│       ├── TableBoundary (instance of table_boundary.tscn)
│       ├── PhysicsElements (Node2D)
│       └── Ball (RigidBody2D — created at runtime)
└── HUD (CanvasLayer) — process mode: Always
    └── BackButton (Button, text: "← Edit")
```

**`play_scene.gd`** (this script fills the role described as "PlayManager" in `architecture.md`):

```gdscript
extends Node2D

var table_data: TableData = null  # set by Main before add_child()

signal back_requested

@onready var _physics_elements: Node2D = $TableViewportContainer/TableViewport/PhysicsElements
@onready var _viewport: SubViewport = $TableViewportContainer/TableViewport

func _ready() -> void:
    _build_table()
    _spawn_ball()

func _build_table() -> void:
    for entry: Dictionary in table_data.elements:
        var scene: PackedScene = ElementRegistry.get_play_scene(entry["type"])
        var node: Node2D = scene.instantiate() as Node2D
        node.position = Vector2(entry["x"], entry["y"])
        node.rotation_degrees = entry["rotation"]
        _physics_elements.add_child(node)

func _spawn_ball() -> void:
    var ball_scene: PackedScene = load("res://source/gameplay/ball/ball.tscn") as PackedScene
    var ball: RigidBody2D = ball_scene.instantiate() as RigidBody2D
    ball.position = _find_spawn_position()
    _viewport.add_child(ball)

func _find_spawn_position() -> Vector2:
    for entry: Dictionary in table_data.elements:
        if entry["type"] == "launcher":
            return Vector2(entry["x"], entry["y"] - 40.0)
    return Vector2(760.0, 350.0)

func _on_back_button_pressed() -> void:
    back_requested.emit()
```

`ball.tscn` and `table_boundary.tscn` already exist from Task 7 — instance them, do not recreate. The `TableBoundary` instance is part of the scene tree above; the ball is spawned at runtime above the launcher (or at the default position).

**Tests:** `source/debug/tests/test_play_scene.gd` — instantiate `play_scene.tscn` with a `TableData` containing one of each element type plus a launcher; after `_ready`, assert `PhysicsElements` has the expected child count, a `TableBoundary` is present, exactly one node in group `"ball"` exists, and `_find_spawn_position()` returns the above-launcher position when a launcher is present and the default otherwise. Use `add_child_autofree`. Suite green via `scripts/run_tests.sh`.

**Verify:** Switch to the play scene with a populated TableData. All element types appear in correct positions, the boundary keeps the ball in play, the ball spawns above the launcher, and the ball collides with elements.

---

## Task 14 — Scene Coordinator & Mode Switching

**Status:** TODO

**Goal:** Wire Main to handle switching between construction and play scenes, passing TableData correctly in both directions. Also wire `debug_quit`.

**File:** `source/core/main.gd` (attached to `source/core/main.tscn`)

```gdscript
extends Node2D

const CONSTRUCTION_SCENE: String = "res://source/gameplay/construction/construction_scene.tscn"
const PLAY_SCENE: String = "res://source/gameplay/play/play_scene.tscn"

var _current_scene: Node = null
var _construction_manager: Node = null  # cached ref after load

func _ready() -> void:
    _load_construction(TableData.new())

func _unhandled_input(event: InputEvent) -> void:
    if OS.is_debug_build() and event.is_action_pressed("debug_quit"):
        get_tree().quit()

func _load_construction(data: TableData) -> void:
    if _current_scene:
        _current_scene.queue_free()
        await get_tree().process_frame
    var scene: PackedScene = load(CONSTRUCTION_SCENE) as PackedScene
    var node: Node = scene.instantiate()
    add_child(node)
    _current_scene = node
    _construction_manager = node.get_node("ConstructionManager")
    node.connect("play_requested", _on_play_requested)
    if data.elements.size() > 0:
        _construction_manager.rebuild_from_table_data(data)

func _on_play_requested(data: TableData) -> void:
    if _current_scene:
        _current_scene.queue_free()
        await get_tree().process_frame
    var scene: PackedScene = load(PLAY_SCENE) as PackedScene
    var node: Node = scene.instantiate()
    node.set("table_data", data)
    add_child(node)
    _current_scene = node
    node.connect("back_requested", _on_back_requested.bind(data))

func _on_back_requested(data: TableData) -> void:
    _load_construction(data)
```

`ConstructionManager` is the child node defined in Task 5 — `node.get_node("ConstructionManager")` resolves it. Set `main.tscn` as the main scene in Project Settings → Application → Run → Main Scene.

**Verify:** Launch app → construction scene. Click Play → play scene with physics. Click Back → construction scene restored with same elements. In a debug build, Escape quits.

---

## Task 15 — Toolbar Wiring (Save / Load / Export)

**Status:** TODO

**Goal:** Connect the toolbar Save, Load, and Export buttons to SaveLoadManager.

In `construction_scene.gd`, replace the stub handlers (`_construction_manager` is the `@onready` reference to the `ConstructionManager` child):

```gdscript
func _on_save_pressed() -> void:
    var path: String = await SaveLoadManager.open_save_dialog()
    if path.is_empty():
        return
    SaveLoadManager.save(path, _construction_manager.get_table_data())

func _on_load_pressed() -> void:
    var path: String = await SaveLoadManager.open_load_dialog()
    if path.is_empty():
        return
    var data: TableData = SaveLoadManager.load_table(path)
    if data == null:
        return
    _construction_manager.rebuild_from_table_data(data)

func _on_export_pressed() -> void:
    var path: String = await SaveLoadManager.open_save_dialog()
    if path.is_empty():
        return
    SaveLoadManager.export_artifact(path, _construction_manager.get_table_data())
```

**Verify:** Place elements, save to file, clear canvas, load file — canvas restores. Cancelling a dialog leaves the canvas untouched. Export produces a valid JSON file matching the export artifact schema in `json-schema.md`.

---

## Task 16 — Integration Pass & Physics Tuning

**Status:** TODO

**Goal:** Verify the complete user flow end-to-end, tune physics feel, and fix any integration issues.

**Precondition:** `scripts/run_tests.sh` is green. The entire unit + integration suite accumulated across Tasks 1B–15 must pass before this manual pass begins; fix any red tests first.

**Test sequence:**
1. Launch app — blank construction canvas with palette and toolbar
2. Place one of each element type (flipper L, flipper R, launcher, pop bumper, drop target, spinner)
3. Drag two elements to new positions; rotate one with the mouse wheel
4. Save to `test_table.json` — verify file content matches save schema
5. Delete two elements, load `test_table.json` — verify canvas restores to six elements at correct positions and rotations
6. Click Play — verify the boundary holds the ball, all six element physics variants appear in correct positions
7. Hold Space — verify ball launches
8. Test Left Shift / Right Shift — verify flippers raise, lower, and impart momentum to the ball
9. Drive ball into pop bumper — verify repulsion impulse
10. Drive ball into drop target — verify it disappears and ball passes through
11. Drive ball into spinner — verify it rotates
12. Click Back — verify construction canvas is unchanged
13. Click Export — verify output JSON matches export artifact schema

**Physics tuning:** With the full table running, tune the feel parameters together — Default Gravity, `BUMPER_FORCE` (400), launcher `MAX_FORCE` (1200), flipper `LERP_SPEED` (25), spinner damping, and ball mass/bounce. The success criterion is "ball physics feel correct for pinball"; the per-element constants are starting points, not final values.

14. Update `build-plan.md` with all task statuses.

Fix any issues found. Do not add features not in the MVP scope.
