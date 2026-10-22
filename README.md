# Hand of the Forgotten

An original god game in Godot 4. *Your followers decide what you become.*

This is **prototype 0**: the pilot's island rebuilt in Godot, with the god's-eye camera. Nothing lives on the island yet; villages, the hand, miracles and the creature come phase by phase (`docs/BUILD_PLAN.md`).

## Play it

1. Open Godot 4 (4.4 or newer; 4.7 on the Mac mini).
2. In the Project Manager, click **Import**, pick this folder's `project.godot`, then **Import & Edit**.
3. Press **F5** (or the ▶ button at the top right).

Or from Terminal: `/Applications/Godot.app/Contents/MacOS/Godot --path .`

## Controls

| Do | Mouse | Trackpad | Keys |
| --- | --- | --- | --- |
| Move | Drag the ground (let go while moving to fling) | Two-finger scroll, or click-drag | WASD or arrows |
| Rotate and tilt | Right-drag or middle-drag | Option + two-finger scroll | Q / E rotate |
| Zoom | Wheel, toward the cursor | Pinch | R / F (or + / −) |
| Fly somewhere | Double-click the ground | Double-click | H flies home to Brightwater |

**[** and **]** preview the sky turning cruel and back. **?** hides the controls; **F3** shows frame rate and camera numbers.

## For development

- `CLAUDE.md` is the standing brief, `START_HERE.md` the setup guide, `DESIGN.md` the decisions so far.
- `GODOT=/path/to/godot tools/check.sh` checks the project loads with no errors or warnings and runs the tests.
- `debug/shot.tscn` renders the game from the poses in `debug/shot_poses.json`; `tools/pilot/pilot.mjs` renders the pilot from the same poses for comparison.
