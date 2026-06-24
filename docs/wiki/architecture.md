# Architecture Plan

## Folder Structure

```
assets/
  sprites/            # Element sprites, ball sprite
source/
  core/               # Application root scene and autoloads
    autoloads/        # element_registry.gd, save_load_manager.gd
  data/               # Data classes (no Node inheritance)
  gameplay/
    construction/     # construction_scene.tscn (+ .gd), construction_manager.gd
    play/             # play_scene.tscn (+ .gd), table_boundary.tscn
    ball/             # ball.tscn (+ .gd)
    elements/         # One subfolder per element type
      flipper/
      launcher/
      pop_bumper/
      drop_target/
      spinner/
  ui/                 # Palette, toolbar, HUD scenes
  debug/              # Debug-only tools — must not ship
```

Each element subfolder contains two scenes: a construction variant (`*_construct.tscn`) and a play variant (`*_play.tscn`).

---

## Scene Tree

```
Main (Node2D) — process mode: Always
├── ConstructionScene (Node2D) — process mode: Pausable    [construction_scene.gd]
│   ├── ConstructionManager (Node)                          [construction_manager.gd]
│   ├── TableViewportContainer (SubViewportContainer, 560×720)
│   │   └── TableViewport (SubViewport, size 560×720, physics_object_picking: true)
│   │       └── PlacedElements (Node2D)
│   ├── Palette (PanelContainer) — left panel, one button per element type
│   └── Toolbar (HBoxContainer) — top bar: Save, Load, Play, Export
│
└── PlayScene (Node2D) — process mode: Pausable             [play_scene.gd]
    ├── TableViewportContainer (SubViewportContainer, 560×720)
    │   └── TableViewport (SubViewport, size 560×720)
    │       ├── TableBoundary (instance of table_boundary.tscn)
    │       ├── PhysicsElements (Node2D)
    │       └── Ball (RigidBody2D — created at runtime)
    └── HUD (CanvasLayer) — process mode: Always
        └── BackButton
```

The construction-mode script is split across two nodes: `construction_scene.gd` (root) owns the UI shell; `construction_manager.gd` (child `Node` named `ConstructionManager`) owns canvas interaction. A node can hold only one script, so the manager cannot live on the root. The `TableBoundary` is a static enclosure (walls) instantiated in the play scene — without it the ball falls out of the world.

Construction and play scenes are loaded and freed at runtime by the Main coordinator. Only one is active at a time. TableData is the handoff between them.

**Process modes must be set explicitly on every node — never rely on inherited defaults.**

---

## Modules

### TableData (`source/data/table_data.gd`)

Plain GDScript class (`class_name TableData`). Does not extend Node or Resource. Holds the canonical table state.

```gdscript
var elements: Array[Dictionary] = []
```

Each Dictionary contains: `type: String`, `x: float`, `y: float`, `rotation: float`, plus any element-specific keys.

Methods:
- `serialize() -> String` — returns JSON string in save-file format (with `version` wrapper)
- `deserialize(json_string: String) -> bool` — populates `elements`, returns false on parse error
- `to_export_dict() -> Dictionary` — returns clean export structure (no editor metadata)

This is the single source of truth. Both scenes read from and write to it.

### ElementRegistry (`source/core/autoloads/element_registry.gd`) — Autoload

Maps element type strings to their scene paths. Does **not** use `preload()` — scenes are loaded with `load()` at call time to avoid persistent references in a long-lived singleton.

```gdscript
const ELEMENTS: Dictionary = {
    "flipper_left":  { "label": "Flipper L", "construct": "res://source/gameplay/elements/flipper/flipper_left_construct.tscn",  "play": "res://source/gameplay/elements/flipper/flipper_left_play.tscn"  },
    "flipper_right": { "label": "Flipper R", "construct": "res://source/gameplay/elements/flipper/flipper_right_construct.tscn", "play": "res://source/gameplay/elements/flipper/flipper_right_play.tscn" },
    "launcher":      { "label": "Launcher",  "construct": "res://source/gameplay/elements/launcher/launcher_construct.tscn",     "play": "res://source/gameplay/elements/launcher/launcher_play.tscn"     },
    "pop_bumper":    { "label": "Bumper",    "construct": "res://source/gameplay/elements/pop_bumper/pop_bumper_construct.tscn", "play": "res://source/gameplay/elements/pop_bumper/pop_bumper_play.tscn" },
    "drop_target":   { "label": "Target",    "construct": "res://source/gameplay/elements/drop_target/drop_target_construct.tscn","play": "res://source/gameplay/elements/drop_target/drop_target_play.tscn"},
    "spinner":       { "label": "Spinner",   "construct": "res://source/gameplay/elements/spinner/spinner_construct.tscn",       "play": "res://source/gameplay/elements/spinner/spinner_play.tscn"       },
}

func get_construct_scene(type: String) -> PackedScene:
    return load(ELEMENTS[type]["construct"]) as PackedScene

func get_play_scene(type: String) -> PackedScene:
    return load(ELEMENTS[type]["play"]) as PackedScene
```

### SaveLoadManager (`source/core/autoloads/save_load_manager.gd`) — Autoload

- `save(path: String, data: TableData) -> bool`
- `load_table(path: String) -> TableData` — returns null on failure
- `export_artifact(path: String, data: TableData) -> bool`
- `open_save_dialog() -> String` — shows FileDialog, returns chosen path or empty string
- `open_load_dialog() -> String` — same for loading

All file I/O uses `FileAccess.open()`. Dialogs use Godot's built-in `FileDialog` node.

### ConstructionManager (`source/gameplay/construction/construction_manager.gd`)

Attached to a child `Node` named `ConstructionManager` under ConstructionScene (not the root — the root already holds `construction_scene.gd`). Manages all mouse input and keeps TableData in sync with the visual canvas.

It distinguishes two separate selection concepts: `_selected_type` (the palette type queued for placement) and `_selected_index` (the placed element currently selected on the canvas, which rotate and delete act on).

Responsibilities:
- Track `_selected_type: String` (set by palette button press) and `_selected_index: int` (set by clicking a placed element)
- On canvas left-click over empty space with a type selected: instantiate construct scene, place at click position (converted to viewport coordinates), append to TableData
- On placed element left-click-drag: select it, move node, and update TableData entry
- On placed element right-click: remove from PlacedElements, remove from TableData
- On mouse-wheel over a selected element: rotate by ±15°, update TableData
- `rebuild_from_table_data(data: TableData)`: clears PlacedElements, reinstantiates all construct scenes from data — called after a Load

Mouse picking on placed `Area2D`s requires the construction `SubViewport` to set `physics_object_picking = true`.

### Play-scene controller (`source/gameplay/play/play_scene.gd`)

Attached to the PlayScene root. (Earlier drafts called this "PlayManager"; the implementation lives in `play_scene.gd`.) On `_ready()`, reads the TableData passed in before `add_child()`, instantiates all play-variant scenes, and sets up the ball.

Responsibilities:
- Instantiate each element's play scene at the stored position and rotation
- Create and add the Ball to the viewport (the `TableBoundary` enclosure is part of the scene)
- Flipper play scenes poll their own input actions in `_physics_process()`; the controller does not forward input

### Main (`source/core/main.gd`)

Coordinator. Owns scene transitions. Never becomes a god object — it only knows about top-level scene swaps and the TableData handoff.

- `_switch_to_play(data: TableData)`: frees ConstructionScene, instantiates PlayScene, sets `play_scene.table_data = data`, adds to tree
- `_switch_to_construction(data: TableData)`: frees PlayScene, instantiates ConstructionScene, calls `construction_manager.rebuild_from_table_data(data)`

---

## Element Scenes

Each element has a construction variant and a play variant. The construction variant is lightweight (sprite + selection area). The play variant contains full physics.

**Critical rule for flippers:** The right flipper is NOT created by negative X scale on the left flipper. Use `Sprite2D.flip_h = true` for the visual. Define the collision shape explicitly for each variant. Negative X scale propagates to Area2Ds and CollisionShapes in unexpected ways.

**Critical rule for all elements:** Use `Sprite2D.offset` to align art to the physics pivot. Do not adjust `Sprite2D.position` — position is game truth and is inherited by child nodes.

| Element | Play Node | Physics Shape | Behaviour |
|---|---|---|---|
| Flipper L/R | `AnimatableBody2D` (`sync_to_physics`) | `CapsuleShape2D` (80px × 8px radius) | Rotation lerped in `_physics_process` on Shift press/release; imparts momentum to the ball |
| Launcher | `Node2D` (channel walls as `StaticBody2D`) | — | Accumulates force on Space hold; impulse on release |
| Pop Bumper | `StaticBody2D` + inner `Area2D` | `CircleShape2D` (r=20) | Outward impulse on `body_entered` |
| Drop Target | `StaticBody2D` | `RectangleShape2D` | Disables collision + hides on ball contact |
| Spinner | `RigidBody2D` + `PinJoint2D` | `RectangleShape2D` (8×40) | Rotates freely on ball contact |

---

## Data Flow

```
Construction:
  Mouse input → ConstructionManager → mutates TableData → updates PlacedElements visually

Save:
  Toolbar Save → SaveLoadManager.save(path, TableData)

Load:
  Toolbar Load → SaveLoadManager.load_table(path) → TableData
              → ConstructionManager.rebuild_from_table_data(data)

Switch to Play:
  Toolbar Play → Main._switch_to_play(TableData)
              → PlayScene instantiated with TableData
              → play_scene.gd builds the boundary, physics elements + ball

Return to Edit:
  HUD Back → Main._switch_to_construction(TableData)
           → ConstructionScene restored, rebuild_from_table_data called

Export:
  Toolbar Export → SaveLoadManager.export_artifact(path, TableData)
```

---

## JSON Formats

See `json-schema.md` for full annotated schemas.

**Save file** (human-readable, includes editor metadata):
```json
{
  "version": 1,
  "elements": [
    { "type": "flipper_left", "x": 120.0, "y": 380.0, "rotation": 0.0 }
  ]
}
```

**Export artifact** (portable, consumed by other games):
```json
{
  "canvas_width": 560,
  "canvas_height": 720,
  "elements": [
    { "type": "flipper_left", "x": 120.0, "y": 380.0, "rotation": 0.0 }
  ]
}
```
