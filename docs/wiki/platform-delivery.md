# Platform & Delivery Plan

## Targets

Desktop only. Godot 4.7 exports Windows, macOS, and Linux from a single project with no per-platform code differences required for this application. No mobile, web, or console targets.

## Project Settings Checklist

Apply all of these before writing gameplay code.

### Resolution & Display
- **Viewport size:** 1280×768. This accommodates the 800×420 table canvas plus palette and toolbar chrome.
- **Stretch mode:** `canvas_items`
- **Stretch aspect:** `keep`
- **Stretch scale mode:** `fractional` (not `integer` — the 800×420 canvas does not cleanly divide into standard desktop resolutions)
- **Minimum window size:** 1024×640
- **Dev window override:** 1280×768 (set in Editor → Editor Settings, not project settings)
- **Note:** The 800×420 table canvas lives inside a `SubViewport` — it is isolated from the window stretch settings. Window settings govern the surrounding UI shell only.

### Physics
- **Physics ticks per second:** 120 (Project Settings → Physics → Common → Physics Ticks Per Second)
- **Default gravity:** 980, vector `(0, 1)` (Project Settings → Physics → 2D). Gravity pulls toward the bottom of the canvas (the flipper edge). This is a primary "feel" parameter — set it explicitly so it is never an accident of Godot's defaults; tune in the integration pass.
- **Physics layer names** (Project Settings → Layer Names → 2D Physics):
  - Layer 1: `Ball`
  - Layer 2: `Table Elements`
- Ball collision mask: Layer 2 only. Table elements collision mask: Layer 1 only. Elements do not collide with each other.
- The play scene is enclosed by a static **table boundary** (walls) so the ball cannot leave the canvas. See `element-specs.md` → Table Boundary.

### Input Map
Define all actions by intent, not by button. Every action must be set here before any script references it.

| Action | Key | Notes |
|---|---|---|
| `flipper_left` | Left Shift | Activates left flipper in play mode |
| `flipper_right` | Right Shift | Activates right flipper in play mode |
| `launch` | Space | Charges and releases the launcher |
| `debug_quit` | Escape | Exits the application in development |

### Versioning
- **Version string:** `0.1.0` (Project Settings → Application → Config → Version)
- Use `major.minor.patch` format throughout development

### Debug Overlay
- Display FPS counter and version string at startup via a debug `CanvasLayer` in `source/debug/`. This overlay must be excluded from export builds: instantiate it only under an `OS.is_debug_build()` guard, and exclude `source/debug/` via the export `exclude_filter`.
- Set `FPS cap` to 60 during development to reduce noise (Project Settings → Application → Run → Max FPS = 60).

### UI
- Set all full-screen `Control` nodes to `Mouse Filter = Ignore` to prevent accidental input capture.

---

## Input

- **Mouse:** All construction mode interaction (place, drag, rotate, delete)
- **Left Shift / Right Shift:** Flipper controls in play mode
- **Space:** Launcher charge/release in play mode
- **Escape:** Quit (debug builds)
- No gamepad, touch, or other input required at MVP

---

## Performance Envelope

Godot 2D physics with fewer than 50 simultaneous bodies. No performance concern on any mid-range desktop from the last decade. No LOD, culling, streaming, or threading considerations needed at MVP.

---

## Distribution

Direct export: zip containing the executable and PCK file. No installer, no app store, no code signing required at MVP. Target one export per platform (Windows `.exe`, macOS `.app`, Linux binary).
