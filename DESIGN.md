# Design decisions

Decisions made while building, newest first within each section. The spec (`docs/GAME_SPEC.md`) says what to build; this file says how, and why.

## Status

**Prototype 0** (22 Oct 2026): the first slice of Phase 0. The pilot's island, sky, sea, villages (static) and the full camera, with tests. Not built yet from Phase 0: `SimClock`, `ActBus`, `SimRng`, `SaveSystem`, `Settings`, GUT, the cheat console, the spatial grid, the terrain cell model and openblack's camera golden tests.

## The island

- **Terrain is regenerated, not stored.** `world/pilot_noise.gd` ports the pilot's value noise and fbm bit for bit (32-bit integer hashing like `Math.imul`), and `world/island_layout.gd` ports `rawHeight`, the flats and `heightAt`. A test checks 400 heights against the running pilot to within 1 mm (`tests/fixtures/pilot_heights.json`).
- **Trees, rocks and clouds are placement data** in `data/island.json`, extracted from the running pilot with `tools/pilot/pilot.mjs dump`. That gives the pilot's exact forest without replaying its random sequence, and it is the "layout as placement data" the spec asks for. Two caveats: the pilot picks rock rotations with an unseeded `Math.random`, so those come from one run; cloud x positions are a snapshot (the pilot's clouds drift).
- **Tree tints** come from a hash of each tree's index, in the pilot's range (0.85–1.12); the pilot's own per-tree tints weren't extracted.
- **Rocks are squashed icosahedra** (squash ranges in `data/tuning.json`) instead of the pilot's per-vertex jittered dodecahedra. They read the same from the camera.
- **Villages, fields and the stone circle are static set dressing** built from the pilot's starting numbers (houses, store piles, totem, motes, the prayer pillar at 40 power). Phase 2 replaces them with the real simulation. Cairnhold's starting Granary is left out until buildings exist (Phase 6).
- **Placeholder mesh dimensions live in code** (`world/island.gd`), copied from the pilot's geometry. They are art, not tuning, and the art pass replaces them; colours and every gameplay number are in `data/`.

## Matching the pilot's look

Everything below was calibrated by rendering the pilot (`tools/pilot/pilot.mjs shot`) and our build (`debug/shot.tscn`) from the same camera poses and comparing pixel colours region by region. Grass in sun and shade, mountain, sky and fog now match to within a few levels out of 255.

- **Flat shading:** one shared shader (`world/flat.gdshader`) computes a normal per face from screen-space derivatives, so any mesh looks faceted like the pilot's `flatShading` Lambert. Lambert diffuse, no specular, vertex and instance colours in linear space.
- **Sun:** energy 2.4 / π = 0.764. Three.js divides by π in its Lambert BRDF; Godot multiplies light energy by π, so they cancel only after this. Checked with the sun alone: identical pixels.
- **Ambient:** the pilot's hemisphere light becomes the sky's ambient pass (sky colour above, ground colour below). Godot ignores `Environment.ambient_light_energy` when ambient comes from the sky, so `world/sky.gdshader` scales its ambient pass by `ambient_energy` (0.52, measured with ambient alone).
- **Tone mapping:** both use the same ACES fit, but Three.js scales by 1/0.6 and Godot by 1.8 and then divides by the tone-mapped white. Exposure 1.0 and white 16 reproduce the pilot's 1.08.
- **Sky:** the pilot draws its sky without tone mapping. `world/sky.gdshader` computes the gradient in display colours, as the pilot does, then inverts Godot's ACES so the screen shows the pilot's colours exactly. This depends on Godot's `tonemap_aces` (checked on 4.4.1); if a newer Godot changes it, the horizon colour will drift, and the shader's constants are the place to look.
- **Fog:** depth fog 170–560 m toward the horizon colour, with a curve of 2.5 to approximate the pilot's smoothstep applied after tone mapping.
- **Sea:** the pilot's sea reflects only the sun, so environment reflections are off. Its 90% opacity is approximated by mixing 3% of the seabed colour into an opaque sea, which keeps shadows on the water.

## The camera

- **Pulling the land is 1:1:** the grabbed ground point stays exactly under the cursor (a ray against the horizontal plane at the grab height, written fresh because openblack's version is marked broken). Letting go while moving flings the land, using the pilot's 120 ms window, 160 m/s cap and 3.6/s decay.
- **Everything else eases along openblack's `ZoomInterpolator`.** `hand/eased_value.gd` restarts the curve from the current value *and velocity* whenever the goal changes, as openblack's `Camera::Update` does, so input mid-glide never snaps. This replaces the pilot's exponential smoothing on rotate and zoom. Direct input eases over 0.2 s (openblack uses 0.3 s; the pilot's smoothing had a time constant near 0.08 s), which is tunable.
- **Zoom keeps the ground under the cursor** for the whole glide, not just at the start.
- **Fly-to:** the pilot's 0.95 s and ×0.7 zoom, now on the full interpolator.
- **Trackpad:** two-finger scroll arrives in Godot as pan gestures and slides the map (Option + scroll rotates and tilts); pinch arrives as magnify gestures and zooms. The scale factors are first guesses from Godot's macOS code (pan deltas are scroll points × 0.03) and need a feel check on the Mac.
- **H flies home** to Brightwater: the spec's Home button, on a key until the UI buttons arrive in Phase 1.
- **[ and ] preview alignment** (kind ↔ cruel sky), since nothing sets alignment yet.

## Data and code

- **Tunables are JSON** in `data/` (`tuning.json`, `island.json`, `controls.json`), read through the `Tuning` autoload with dotted paths (`Tuning.num("camera.pitch_min")`). A missing value fails an assert with its path. JSON over `.tres` because it diffs cleanly and matches `docs/tuning_baseline.json`.
- **Key bindings are data:** `Tuning` registers the actions in `data/controls.json` with the input map at startup.
- **Scenes are built in code** from tiny `.tscn` roots (`main.tscn`, `debug/shot.tscn`), so everything is reviewable as text.

## Tests and checks

- **A small test runner stands in for GUT** (`tests/run_tests.gd`, base class `tests/test_case.gd`). GUT is pre-approved, but it downloads from GitHub, which the cloud environment blocks. Test methods use GUT's `test_` naming and assert style so switching is mechanical.
- **Camera tests drive the rig with synthetic mouse events** in a 1280 × 720 viewport: dragging keeps the grabbed point under the cursor, flings, clicks don't fling, zoom keeps its anchor, double-click flies, rotate and tilt respect limits. They caught `set_pose` ignoring the target radius.
- **`tools/check.sh` promotes warnings to errors** for one run, because headless Godot doesn't print GDScript warnings at all. It is how "no errors or warnings" is verified.
- **Engine version:** built and tested on Godot 4.4.1, the only build available in the cloud container (`tools/cloud_godot.sh`). Nothing newer than 4.4 is used, so it opens in 4.7 on the Mac.

## Ported from openblack

| Our file | openblack source | What |
| --- | --- | --- |
| `hand/zoom_interpolator.gd` | `src/Common/ZoomInterpolator.{h,cpp}` | The camera easing curve, position and velocity |
| `tests/test_zoom_interpolator.gd` | `test/test_interpolator.cpp` | The 102 expected values |
| `hand/eased_value.gd` (idea, not code) | `src/Camera/Camera.cpp` (`Camera::Update`) | Restarting the curve with the carried-over velocity, normalised by the new duration |

A finding from porting the test: openblack's expected values are the curve sampled at t = i/100 (computed in 32-bit floats), but its test reads them at t = i/101, which is why it needs a 1e-2 tolerance. Our test checks both: openblack's way, and exactly (1e-5) at the right sample points.
