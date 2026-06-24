# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

A Godot 4.7 / GDScript remake of the 1983 Bill Budge Pinball Construction Set. Players design a pinball table on a 560×720 canvas using five element types (flipper L/R, launcher, pop bumper, drop target, spinner), then switch to a physics-driven play mode.

The Godot project has not been created yet. All implementation work is driven by the build plan.

## Wiki

All architecture, design, and implementation specifications live in `docs/wiki/`. Read the relevant documents before starting any task — they contain Godot-specific implementation details that are not obvious from the code.

| Document | When to read |
|---|---|
| `architecture.md` | Before touching scene structure, module boundaries, or data flow |
| `godot-conventions.md` | Before writing any GDScript |
| `element-specs.md` | Before implementing any element scene |
| `json-schema.md` | Before touching serialization |
| `build-plan.md` | To find the current task and its acceptance criteria |
| `platform-delivery.md` | Before touching Project Settings |
| `testing.md` | Before writing any test, and to understand the testing gate |

## Non-obvious rules (violations cause silent physics bugs)

**Never flip a node's direction using negative X scale.** It propagates to Area2Ds and CollisionShapes — visible shapes look right in the editor but physics interactions are wrong. Use `Sprite2D.flip_h` for visual mirroring. Define collision shapes explicitly per variant. This applies directly to the right flipper scene.

**Use `Sprite2D.offset` for art alignment, not `Sprite2D.position`.** Position is game truth and is inherited by child nodes including collision shapes and spawn markers. Offset only affects the texture.

**Use `set_deferred` to modify CollisionShape2D state inside physics callbacks.** Directly setting `disabled = true` inside `body_entered` or `_physics_process` can crash the physics engine.

**Use `load()` in autoloads, not `preload()`.** Autoloads never leave the scene tree; preloaded assets in them are never freed. Call `load()` at the use site instead.

## GDScript conventions

- Static typing is mandatory everywhere. Enable `untyped declaration = warn` in Project Settings → Debug → GDScript.
- Script section order: `class_name`, `extends`, signals, enums, constants, `@export` vars, regular vars, `@onready` vars, built-in overrides, public functions, private functions (prefixed `_`).
- Use `@onready` for all node references.

## Testing (test-gated project)

- This project uses **GUT** (set up in Task 1B). Tests live under `source/debug/tests/` (auto-excluded from export); see `testing.md`.
- **A task is not done and code does not go to review until its tests exist and `scripts/run_tests.sh` exits 0.** Deterministic GDScript gets unit tests; physics behaviour is verified manually per each task's Verify section. The GUT suite is green *before* the code review step of the Pre-PR Checklist in `docs/Claude-git-workflow.md`.

## Intended project structure (to be created in Task 1)

```
assets/sprites/
source/
  core/autoloads/    # element_registry.gd, save_load_manager.gd
  data/              # table_data.gd
  gameplay/
    construction/    # construction_scene.tscn, construction_manager.gd
    play/            # play_scene.tscn (+ play_scene.gd), table_boundary.tscn
    ball/
    elements/        # flipper/, launcher/, pop_bumper/, drop_target/, spinner/
  ui/
  debug/             # must not ship in export builds
```

## Key architecture facts

- **TableData** (`source/data/table_data.gd`) is the single source of truth for the table. Both construction and play scenes read from it. It is never a Node or Resource — plain `class_name TableData`.
- **Main** (`source/core/main.gd`) is the sole coordinator for scene transitions. It owns the TableData handoff between construction and play modes.
- **ElementRegistry** (autoload) maps type strings like `"flipper_left"` to scene paths. Both the palette UI and the play scene use it as the single lookup.
- Each element type has two scenes: a construction variant (sprite + Area2D for selection) and a play variant (full physics). Play variants are instantiated by `play_scene.gd` from TableData on scene entry.
- Two JSON formats: save file (includes `version` wrapper, for the edit cycle) and export artifact (adds `canvas_width`/`canvas_height`, no editor metadata, for use by external games).
- Physics layers: Layer 1 = Ball, Layer 2 = Table Elements. Elements do not collide with each other.
- Input actions: `flipper_left` (Left Shift), `flipper_right` (Right Shift), `launch` (Space), `debug_quit` (Escape).
