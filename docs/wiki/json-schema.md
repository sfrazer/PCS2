# JSON Schema

Two formats are used: the **save file** (editable, includes metadata) and the **export artifact** (portable, consumed by other games).

---

## Save File

Written and read by `SaveLoadManager`. Used for the edit cycle only.

```json
{
  "version": 1,
  "elements": [
    {
      "type": "flipper_left",
      "x": 120.0,
      "y": 380.0,
      "rotation": 0.0
    },
    {
      "type": "flipper_right",
      "x": 680.0,
      "y": 380.0,
      "rotation": 0.0
    },
    {
      "type": "launcher",
      "x": 760.0,
      "y": 300.0,
      "rotation": 0.0
    },
    {
      "type": "pop_bumper",
      "x": 300.0,
      "y": 200.0,
      "rotation": 0.0
    },
    {
      "type": "drop_target",
      "x": 400.0,
      "y": 180.0,
      "rotation": 0.0
    },
    {
      "type": "spinner",
      "x": 250.0,
      "y": 300.0,
      "rotation": 0.0
    }
  ]
}
```

### Field definitions

| Field | Type | Notes |
|---|---|---|
| `version` | integer | Format version. Currently `1`. Increment when the format changes. |
| `elements` | array | Ordered list of placed elements. |
| `elements[].type` | string | One of: `flipper_left`, `flipper_right`, `launcher`, `pop_bumper`, `drop_target`, `spinner` |
| `elements[].x` | float | X position in canvas coordinates (0–560, origin top-left) |
| `elements[].y` | float | Y position in canvas coordinates (0–720, origin top-left) |
| `elements[].rotation` | float | Rotation in degrees. Clockwise positive. |

### Versioning

If the save format changes in a future version, increment `version` and add a migration path in `TableData.deserialize()`. Old files with `version: 1` must still load correctly.

---

## Export Artifact

Written by `SaveLoadManager.export_artifact()`. Intended for consumption by an external game. Contains no editor state.

```json
{
  "canvas_width": 560,
  "canvas_height": 720,
  "elements": [
    {
      "type": "flipper_left",
      "x": 120.0,
      "y": 380.0,
      "rotation": 0.0
    }
  ]
}
```

### Field definitions

| Field | Type | Notes |
|---|---|---|
| `canvas_width` | integer | Always `560`. Allows the importing game to scale or position the table. |
| `canvas_height` | integer | Always `720`. |
| `elements` | array | Same structure as the save file element array. |
| `elements[].type` | string | Same type strings as save file. The importing game must recognise these strings. |
| `elements[].x` | float | Same coordinate space as save file. |
| `elements[].y` | float | Same coordinate space as save file. |
| `elements[].rotation` | float | Same as save file. |

### Notes for the importing game

- `x` and `y` are in the PCS canvas coordinate space (560×720, origin top-left).
- The importing game is responsible for scaling these coordinates to its own coordinate space using `canvas_width` and `canvas_height`.
- Element types are stable strings. Do not rely on ordering or index.
- Additional fields may be added in future versions. The importing game should ignore unknown fields.

---

## Implementation Notes

**In `TableData.serialize()`:**
```gdscript
func serialize() -> String:
    var data: Dictionary = {
        "version": 1,
        "elements": elements.duplicate(true),
    }
    return JSON.stringify(data, "\t")
```

**In `TableData.to_export_dict()`:**
```gdscript
func to_export_dict() -> Dictionary:
    return {
        "canvas_width": 560,
        "canvas_height": 720,
        "elements": elements.duplicate(true),
    }
```

**In `TableData.deserialize()`:**
```gdscript
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
    # Validate all entries before mutating state — clear only after full success
    # so a corrupt file never wipes a pre-existing table.
    var new_elements: Array[Dictionary] = []
    for entry: Variant in data["elements"] as Array:
        if not entry is Dictionary:
            return false
        new_elements.append((entry as Dictionary).duplicate(true))
    elements = new_elements
    return true
```

> Note: deserialize uses atomic validation — it returns `false` and leaves `elements` unchanged if **any** array entry is not a Dictionary. A corrupt file never partially overwrites an existing table.

> GUT gotcha: the empty-string guard and the explicit iterate-and-append are required for tests to pass — see `testing.md` and `../Claude-Godot-Generic.md`.
