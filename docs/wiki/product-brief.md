# Product Brief

## What It Is

A desktop application built in Godot 4.7 that remakes the 1983 Bill Budge Pinball Construction Set. The player uses a construction interface to place pinball elements on a fixed 560×720 pixel canvas, then switches to play mode to experience the table using real 2D physics. The visual style is utilitarian and 2D sprite-based, faithful to the original. UI for construction, save, load, and export uses modern conventions without departing from the original's functional aesthetic.

## Who It Is For

The sole developer is the primary user during development and play. The exported table artifact is also designed for consumption by a separate, currently undefined game — the export format is a first-class deliverable.

## Success Criteria

- All five MVP elements (flipper, launcher, pop bumper, drop target, spinner) are placeable in construction mode and physically active in play mode.
- Save, load, and edit cycle is stable and lossless.
- Left Shift and Right Shift control flippers; ball physics feel correct for pinball.
- A table can be exported as a self-contained JSON artifact parseable by a future game without access to this application.
- The project compiles and runs on desktop without errors.

## MVP Scope

**In scope:**
- Five table elements: flipper (left and right variants), launcher, pop bumper, drop target, spinner
- Construction mode: place, move, rotate, delete elements on an 560×720 canvas
- Save/load/edit cycle using human-readable JSON
- Play mode with 2D physics and shift-key flipper controls
- Export of a portable JSON table artifact

**Out of scope at MVP:**
- Scoring system
- Multiple balls
- Undo/redo
- Sound effects
- Any networked or multiplayer features
