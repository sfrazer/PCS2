# Godot Conventions

Project-specific conventions for Godot 4.7 / GDScript. All worker agents must read this document before writing any code.

---

## Project Structure

```
assets/
  sprites/
source/
  core/             # Main scene, autoloads
    autoloads/      # element_registry.gd, save_load_manager.gd
  data/             # Data classes (no Node inheritance)
  gameplay/
    construction/
    play/
    ball/
    elements/
      flipper/
      launcher/
      pop_bumper/
      drop_target/
      spinner/
  ui/
  debug/            # Debug-only tools — must not ship in export builds
```

---

## Scene Ownership Rules

- **Main** is the application root and coordinator. It owns scene transitions and the TableData handoff. It must not become a god object.
- **ConstructionScene** and **PlayScene** are the two top-level modes. Only one is active at a time. Main loads and frees them.
- The **Ball** is instantiated by PlayManager and added to the PlayScene viewport — not embedded in a table element scene.
- **UI** (Palette, Toolbar, HUD) lives in `source/ui/` and is added as a child of its respective mode scene, not of Main.
- **Debug tools** (`source/debug/`) must be excluded from export builds.

---

## Scene Tree Layer Order

| Layer | Node | Process Mode |
|---|---|---|
| Root | Main | Always |
| Mode | ConstructionScene / PlayScene | Pausable |
| Overlay | HUD | Always |
| Debug | DebugOverlay | Always |

Set process modes intentionally on every node. Never rely on inherited defaults.

---

## GDScript Conventions

### Static Typing — Mandatory

Always declare variable and return types explicitly. Enable the warning: Project Settings → Debug → GDScript → Untyped Declaration = Warn.

```gdscript
# Correct
var elements: Array[Dictionary] = []
func serialize() -> String:

# Wrong — do not do this
var elements = []
func serialize():
```

### Script Section Order

Every script must follow this order:

1. `class_name` (if applicable)
2. `extends`
3. Signals
4. Enums
5. Constants
6. `@export` variables
7. Regular variables
8. `@onready` variables
9. Built-in overrides (`_ready`, `_process`, `_physics_process`, `_input`, etc.)
10. Public functions
11. Private functions (prefix with `_`)

### Node References

Use `@onready` for all node references. In the editor, Ctrl-drag a node into the script to auto-generate the typed reference.

```gdscript
@onready var _sprite: Sprite2D = $Sprite2D
@onready var _collision: CollisionShape2D = $CollisionShape2D
```

### Autoloads

Do not use `preload()` in autoload singletons for scenes or resources that are not always needed. Use `load()` at call time to avoid persistent references that are never freed.

```gdscript
# Correct — in ElementRegistry
func get_play_scene(type: String) -> PackedScene:
    return load(ELEMENTS[type]["play"]) as PackedScene

# Wrong
const FLIPPER_SCENE: PackedScene = preload("res://source/gameplay/elements/flipper/flipper_left_play.tscn")
```

---

## Key Rules

### Never flip direction with negative X scale

Multiplying a node's `scale.x` by -1 propagates to all children including `Area2D`s, collision shapes, and raycasts. Visible collision shapes will look correct in the editor but physics interactions will be wrong.

- **Do:** Use `Sprite2D.flip_h = true` for the visual. Define a separate collision shape for each mirrored variant.
- **Never:** `scale.x = -1` or `scale = Vector2(-1, 1)`

This applies directly to the right flipper, which must be a separate scene with its own explicitly defined `CapsuleShape2D` — not a scaled copy of the left flipper.

### Use `offset` not `position` for sprite alignment

`Sprite2D.position` is inherited by children (spawn markers, collision shapes, sub-areas). `Sprite2D.offset` only affects the texture.

- **Rule:** Position = game truth. Offset = art alignment.
- When art needs to be nudged to align with the physics pivot, always use `offset`, never `position`.

### Use `set_deferred` to modify physics state during callbacks

Never disable a `CollisionShape2D` directly inside a physics callback (`body_entered`, `area_entered`, `_physics_process`). Use `set_deferred`:

```gdscript
# Correct
$CollisionShape2D.set_deferred("disabled", true)

# Wrong — can cause physics engine errors
$CollisionShape2D.disabled = true
```

### Be careful with `preload` in long-lived nodes

`preload` creates a persistent reference. If a node that never leaves the scene tree preloads a chain of scenes, those assets are never freed. Keep preloads as close as possible to where they are used, or use `load()` at call time.

---

## Autoloads

Registered autoloads for this project:

| Name | Path | Purpose |
|---|---|---|
| `ElementRegistry` | `res://source/core/autoloads/element_registry.gd` | Maps element type strings to scene paths |
| `SaveLoadManager` | `res://source/core/autoloads/save_load_manager.gd` | File I/O for save, load, and export |

Register both in Project Settings → Autoload before any other code references them.

---

## Physics Layers

| Layer # | Name | Used by |
|---|---|---|
| 1 | Ball | Ball RigidBody2D |
| 2 | Table Elements | All element StaticBody2Ds and RigidBody2Ds |

- Ball collision mask: Layer 2 only
- Table element collision mask: Layer 1 only
- Elements do not collide with each other

Set these names in Project Settings → Layer Names → 2D Physics.

---

## Input Actions

All input actions are defined in the Input Map (Project Settings → Input Map). Scripts must reference action names as strings — never hardcode key constants.

| Action | Key | Used by |
|---|---|---|
| `flipper_left` | Left Shift | Flipper left play script |
| `flipper_right` | Right Shift | Flipper right play script |
| `launch` | Space | Launcher play script |
| `debug_quit` | Escape | Main (debug builds only) |

---

## Debug Overlay

A `CanvasLayer` in `source/debug/debug_overlay.tscn` displays FPS and version string. Added as a child of Main only when `OS.is_debug_build()` is true, and `source/debug/` is excluded via the export `exclude_filter`. Use both: the runtime guard protects against an export preset that forgets the filter. (Do not use `Engine.is_editor_hint()` — that is true only inside the editor, not in a running debug build.)

---

## Version Control

Commit the moment a feature works. Compare against last known good state when something breaks after cleanup. Enables confident refactoring.

Version string: `0.1.0` (Project Settings → Application → Config → Version).
