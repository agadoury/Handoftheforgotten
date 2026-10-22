# Changelog

## Prototype 0 — 22 Oct 2026

The first playable slice of Phase 0: the pilot's island in Godot, and a camera to fly around it.

**Done**
- The pilot's island, regenerated from its own noise (heights match the pilot to within 1 mm), with its 170 trees, 34 rocks and 7 clouds placed exactly where the pilot puts them.
- Brightwater and Cairnhold as they stand at the start (houses, totems and flags, storehouses with their piles, influence motes), the three wheat fields, and the stone circle with its prayer pillar. Static for now.
- Sky, sun, ambient light, fog and sea calibrated against renders of the pilot; [ and ] preview the sky turning cruel.
- Camera: pull the land with a fling, rotate and tilt, zoom toward the cursor, double-click to fly, trackpad scroll, pinch and Option-scroll, keyboard, H to fly home. All motion except the 1:1 land pull eases along openblack's `ZoomInterpolator`.
- HUD: title, controls panel (?), debug readout (F3).
- 16 headless tests: openblack's interpolator values, terrain against the pilot, camera controls with synthetic input.
- Tools: `tools/check.sh` (no errors or warnings, tests pass), `debug/shot.tscn` (render poses to PNG), `tools/pilot/pilot.mjs` (render the pilot from the same poses), `tools/cloud_godot.sh` (Godot for cloud sessions).

**Next (rest of Phase 0)**
- Autoloads: `SimClock`, `ActBus`, `SimRng`, `SaveSystem`, `Settings`.
- GUT in place of the stand-in runner, once it can be downloaded.
- The spatial grid, the terrain cell model, the debug console, openblack's camera golden tests.
- A feel check of the trackpad on the Mac, and 60 fps confirmed there.

**Open questions**
- The camera split between Phase 0 and Phase 1, smoothing, left + right drag zoom, the 0.5× speed, and the open spec suggestions (asked at kickoff).
