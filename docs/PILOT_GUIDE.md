# Pilot guide

`docs/pilot/index.html` is a playable prototype of the toy: one 3,078-line HTML file using Three.js r169, built and played in Oct 2026 (version 7). It is the **behaviour reference** for Milestone 1. Port what it does and how it feels, not how it's written.

## Run it

- Open `docs/pilot/index.html` in a browser (it loads Three.js and fonts from the internet), or ask Alex for the hosted link.
- Click **Begin**. Drag the ground to move; right-drag to rotate; wheel to zoom; double-click to fly. Press on objects with the mouse to pick them up. Drag an orb from the bottom bar to cast. Click the creature for its panel, a village for its panel. The **?** button lists every control.
- To see later systems quickly, play the goals in order: in about 15 minutes you'll have taught the creature, levelled it a few times and built in Brightwater.

## Where each system lives

Line numbers are for the copy in this folder.

| System | Section (line) | Key functions | Port notes |
| --- | --- | --- | --- |
| Noise, island shape | World layout and terrain (399) | `fbm`, `rawHeight`, `exactHeight`, `heightAt`, `FLATS` | Port the shape and placements; regenerate in GDScript. Plots are computed here (`VILLAGES.forEach` after `distToRect`) so trees and rocks avoid them. |
| Camera curve | Math (378) | `zoomCurve` | Already openblack's `ZoomInterpolator` (zero velocity at both ends). Port the full openblack version with velocities. |
| Sky, light, sea | Renderer (464) | `SKY`, sky shader, `updateWorldLook` | Two-colour gradient blended toward the evil palette by player alignment. |
| Terrain colours | Terrain mesh (512) | vertex colour loop | Sand, grass, rock by height and slope; dirt around village centres and the circle. |
| Trees | Trees (622) | `setTreeMatrix`, `burnTree`, `removeTree` | Instanced trunks + pine or oak crowns. Woodcutters set `replantAt`. |
| Villages | Villages (680) | `makeHouse(tier)`, `placeHouse`, `updateStoreVisual`, `ringPoints` | Store piles show stock: one grain per 5 food (max 8), one log per 3 wood (max 6). |
| City building | City building (750) | `BTYPES`, `TIERS`, `placeBuilding`, `workSite`, `assignWoodcutter`, `completeBuilding`, `damageBuilding`, `evolve`, `itemOnBuilding`, `villagerOnBuilding`, `dropInfo` | The whole building system in one place. Buildings face the village centre (local +z = door). |
| Worship circle | Worship circle (1089) | pillar | The pillar's height and opacity follow prayer power. |
| Items | Items (1118) | `addItem`, `ITEM_R`, `spawnSheaf` | Rocks, sheaves (3 food), baskets (12 food), uprooted trees (6 wood), fireballs. |
| Villagers | Villagers (1167), Villager behaviour (1899) | `makeVillager`, `villagerThink`, `walkTo`, `updateVillager` | Task types: fetch, tend, wander, worship, pray, build, chop, mission. States: idle, held, flying, dizzy, flee, grabbed, dead. |
| Creature body | The creature (1196) | `splitColored`, the build block, `animateCreature` | Vertex colours split at x = 0: kind side +x. `C.parts` holds torso, hip, mane, ears and antlers for evolution. |
| Hand | The hand (1282), `updateHand` (2901) | | Scales with zoom, floats higher on touch, tree sway, held object hangs under the fingers. |
| UI helpers, goals | UI helpers (1321) | `toast`, `say`, `GOALS`, `renderGoals`, `completeGoal` | |
| Belief and alignment | Belief, alignment, events (1389) | `addBelief`, `convertVillage`, `witness`, `shiftAlign`, `killVillager`, `deposit` | `witness` is the pilot's stand-in for the act bus: build the real `ActBus` instead. |
| Physics | Physics (1457) | `step`, `crushNear`, `explode`, `landItem` | Hand-rolled ballistic motion, bounce and splash. Use Jolt rigid bodies while airborne. |
| Camera | Camera controller (1512) | `applyCamera`, `updateCamera`, `flyTo`, `clampTarget` | Orbit camera around a target with yaw, pitch and distance. |
| Picking | Picking (1557) | `pickAt`, `screenToGround`, `toScreen` | Screen-space picking with a generous radius; trees get a bonus; the creature is a screen ellipse. |
| Input | Input (1601) | `startHold`, `endHold`, `startTwoFinger`, `moveTwoFinger`, `anchorUnder`, `checkPending`, `endPointer`, `singleTap` | Pointer Events for mouse and touch. Press-and-hold grab, two-finger transform with tilt detection, single vs double tap. |
| Village economy | Village simulation (2057) | `villageTick` | Runs once per second in the pilot; the Godot `SimClock` runs at 10 Hz. Building effects are applied here. |
| Creature brain | Creature brain (2104) | `OPS`, `THOUGHTS`, `creatureDecide`, `creatureUpdate`, `finishAction`, `abortAction` | The decision scoring and action phases. |
| Teaching | Teaching (2348) | `creatureFeedback`, `observe` | The credit rule is in `creatureFeedback`; stroke and slap detection is in the pointer handlers (search `c.rev >= 2` and `c.path / Math.max(1, dur)`). |
| Visual evolution | Visual evolution (2386) | `EVO`, `onTorso`, `onMane`, `curvedHorn`, `shapeTarget`, `updateShape`, `evolveVisual`, `animateEvolution`, `focusCreature`, `showcaseEvolution` | Each talent's `build()` adds parts to a body part's local space; `shapeTarget()` gives scale targets. |
| Levels and talents | Leveling and talents (2586) | `TALENTS`, `gainXP`, `talentStatus`, `learnTalent`, `renderTalents` | |
| Panels | Mind panel (2701), Village sheet (2733) | `renderMind`, `openTown`, `buildTownDom`, `renderTown` | Rebuild as Godot `Control` scenes. |
| Title, finale, save | Title (2827) | `begin`, `showFinale`, `snapshot`, `restore` | `snapshot` is only a hot-reload helper, not a real save system. |
| Frame loop | Frame loop (2887) | `frame` | Also auto-lowers quality if the frame rate is under 34 fps in the first 3.5 s. |

The CSS at the top (lines 6–241) holds the UI's palette, type and layout; `docs/ART_DIRECTION.md` summarises it.

## What the pilot fakes (do these properly in Godot)

- **No act bus.** Systems call each other directly (`witness`, `observe`, `completeGoal` sprinkled through the code). Route everything through `ActBus`.
- **Talent and building effects are inline checks** (`has('hearty') ? .65 : 1`, `hasB(v, 'granary')`). Use the modifier stack from the spec.
- **No navigation.** Villagers walk straight and turn away from water; nothing avoids buildings or the creature's body.
- **Village-level economy.** Food and wood belong to the village, not to villagers; villagers have no personal needs.
- **One god.** Belief is a single number per village; there is no rival.
- **No save.** Only a hot-reload snapshot of some fields.
- **Global state.** Everything lives in module-level variables in one file.
- **Mobile-first input.** The pilot was mostly played on a phone, so touch rules (press-and-hold grab, two-finger tilt, tap delays) are tuned for fingers. On Mac, the mouse grabs immediately and the trackpad maps to the same gestures.
- **Fixed island.** Placements are hard-coded constants; make them data.

## What not to port

Three.js and DOM code, the hot-reload hook, the auto quality switch (replace it with real settings), and the inline SVG icons (redraw them as Godot icons in the same style).
