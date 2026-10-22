# REFERENCE_NOTES.md — what openblack teaches us

Studied openblack at commit `aab1f8a` (17 Oct 2026). All paths below are relative to `reference/openblack/`. openblack is GPL v3, and so is this project, so code may be ported: start each ported file with a comment naming its openblack source and list ported pieces in `DESIGN.md`.

Set it up with `git clone --recurse-submodules https://github.com/openblack/openblack.git reference/openblack` (it is git-ignored, never built, imported or shipped). Our game never loads, converts or ships the original game's data files. openblack's gameplay is mostly missing, so the creature mind, belief, city building and rival god come from `docs/GAME_SPEC.md`; when openblack and the spec disagree, the spec wins.

The pilot (`docs/pilot/index.html`) already uses two ideas from here: the `ZoomInterpolator` curve (zero-velocity form) for fly-to, and the tree sway near the hand.

**Verdict in one line:** openblack nails the *feel* layer (camera, terrain, sky, water, the 10 Hz turn loop) and documents the original game's *data model* in detail, but almost none of the gameplay exists yet. Hand interactions, miracles, belief, the creature's mind, the rival god and quests must come from our spec.

Before relying on a detail here, re-check it against the current openblack source: the project moves fast. The Phase 0 kickoff asks for exactly that check.

## At a glance

| Our system | openblack status | Port value | Start in |
| --- | --- | --- | --- |
| 1. Hand (camera + input) | Camera complete and tested; hand only follows the cursor | **High**: port the camera nearly as-is | `src/Camera/`, `src/Common/ZoomInterpolator.*` |
| 2. World | Terrain, water, sky rendering complete; no day/night cycle or weather logic | **High**: terrain model, shaders, sky blend | `src/3D/`, `assets/shaders/` |
| 3. Villagers | Wander only; ~251 of 255 states are stubs | Medium: spatial grid, wall-hug movement, data fields | `src/ECS/Systems/Implementations/` |
| 4. Belief and influence | Towns store a belief number; nothing computes it | Medium: design via data tables | `src/InfoConstants.h` |
| 5. Miracles | Not implemented | Medium: miracle catalogue and data shape | `src/Enums.h`, `src/InfoConstants.h` |
| 6. Creature | Mind is an empty struct; base mesh only | Low–medium: desire list, morph targets | `src/Creature/`, `src/3D/CreatureBody.*` |
| 7. Alignment | Only the sky shader uses it | Medium: weight tables | `src/InfoConstants.h`, `assets/shaders/sky.slang` |
| 8. Rival god | Not implemented | None | — |
| 9. Quests | Level-setup scripts work; challenge VM mostly stubs | Medium: command catalogues | `src/LHScriptX/`, `src/CHLApi.cpp` |
| 10. Buildings | Abodes, fields, storage pits placed from scripts | Low–medium: data fields | `src/ECS/Components/`, `src/ECS/Archetypes/` |

---

## Core architecture lessons

- **Fixed game turns at 10 Hz.** `src/Game.h` sets `k_TurnDuration = 100 ms`, with speed multipliers on turn length: slow 2×, normal 1×, fast 0.5×. Each turn in `Game::GameLogicLoop` (`src/Game.cpp`): rebuild the spatial grid → pathfinding → villager/creature actions → scripts. Rendering, physics, camera and the hand run every frame. **Adopt this exact order in `SimClock`.**
- **Units are metres.** Speeds are stored in metres per second (`SpeedState` in `src/Enums.h`). Hand hovers 1.5 m above ground; camera stays ≥ 3 m above terrain.
- **Spatial grid** (`src/ECS/Map.h`, `src/ECS/MapProduction.cpp`): 512 × 512 cells of 10 m. Two sets per cell: *fixed* things (buildings, trees, registered into every cell their bounding circle covers) and *mobile* things (villagers, by position). Rebuilt every turn. This is our witness grid.
- **Service locator** (`src/Locator.h`) gives global access to systems; Godot autoloads play the same role.
- **ECS archetypes** (`src/ECS/Archetypes/`): each entity type is assembled from small components (Transform, Mesh, Fixed/Mobile, Villager, Abode…). In Godot, keep data in plain GDScript classes owned by managers and draw crowds with MultiMesh, rather than one node per villager.
- **Deterministic RNG** (`src/Common/RandomNumberManager*.h`): a production and a testing implementation behind one interface. Our `SimRng` should allow the same swap in tests.
- **Physics** (`src/ECS/Systems/Implementations/DynamicsSystem.cpp`): Bullet world, gravity −10 m/s², terrain as one static triangle mesh per 160 m block (contact stiffness 300, damping 10). Raycasts against it place the hand and drive the camera.

---

## 1. The hand: camera and input

**Files:** `src/Camera/DefaultWorldCameraModel.{h,cpp}`, `src/Camera/Camera.cpp`, `src/Camera/CameraModel.cpp`, `src/Common/ZoomInterpolator.{h,cpp}`, `src/Input/GameActionMap.cpp`, `src/Input/GameActionMapInterface.h`, `src/Game.cpp` (hand placement in `Game::Update`), `src/ECS/Systems/Implementations/HandSystem.cpp`, `test/camera/`, `test/test_interpolator.cpp`.

### How the camera feels smooth

The camera stores **origin** and **focus** as two curves (`ZoomInterpolator3f`). Every frame the camera model proposes a target origin, target focus and duration. The camera then restarts both curves from the *current* position, carrying the *current velocity* into the new curve. Motion never snaps, even when input changes mid-move.

The curve, per axis, with `m0 = v0/(p1−p0)` and `m1 = v1/(p1−p0)`:

```
f(t) = m0·t + (6 − 3·m0 − 3·m1)·t² + (3·m0 + 5·m1 − 8)·t³ + (3 − m0 − 2·m1)·t⁴
position = p0 + f(t)·(p1 − p0),   t ∈ [0, 1]
```

Durations (`ComputeUpdateReturnInfo`): 0.3 s normally, 0.6 s when the camera hit a limit, eased in from 1.5 s during the first 1.5 s of play. Time steps are capped at 100 ms. Flights take 1.5 s via a midpoint.

### Camera modes (`HandleActions` picks one each frame)

| Mode | Trigger | Behaviour |
| --- | --- | --- |
| Cartesian | idle | Focus stays on the land at screen centre |
| Polar | keyboard or zoom | Orbit the focus point; zoom changes distance |
| ArcBall | middle mouse held | Rotate around the ground point under the cursor |
| DraggingLandscape | left mouse held with the hand on land | Pull the world under the hand |
| FlyingToPoint | double-click with the hand on land | Glide to the hand position |

**Limits worth keeping:** pitch −30° to 78.75°; at least 3 m above terrain; at most 30 km altitude; camera origin kept within 5,120 m of the island centre (2560, 2560).

**Fly-to (`UpdateModeFlying`):** final distance from the target is 100, 60, 30 or 15 m depending on how far away it is (distance ÷ 1.5 against those thresholds). It scores 32 candidate headings by terrain clearance plus a bonus for staying near the current heading, and clamps pitch to roughly 22.5°–60°. Long flights (`CameraModel::CharterFlight`) arc through a midpoint raised by 10% of the horizontal distance (or by the terrain height there, if larger), and play a whoosh.

**Known bug:** the landscape-drag maths carries a `FIXME: This whole section is broken`. Port the *idea* (the grabbed ground point stays under the cursor) and write that part fresh: intersect the cursor ray with a horizontal plane at the grab height, and move the camera by the difference.

### The hand itself

- **Placement** (`src/Game.cpp`, inside `Game::Update`): raycast from the mouse to land, or to the water plane at y = 0. Put the hand 1.5 m above the hit along the surface normal, rotated to the normal plus the camera's yaw.
- **Gripping:** while the left or middle button is held, the hand stops following the cursor; the land moves under it instead.
- **Tree sway** (`HandSystem::SwayNearbyEntities`): trees within 5 m lean away from the hand, blending back to natural sway by 10 m. Strength = base × (1 + 6·d⁴), where d goes from 1 at the hand to 0 at 5 m, capped at 10. Cheap, and sells the hand's presence.

### Original controls (default bindings in `GameActionMap.cpp`)

| Input | Action |
| --- | --- |
| Left button | Move / grab (drag the land, pick up) |
| Right button | Action (interact, cast) |
| Left + right drag | **Zoom** |
| Middle drag | Rotate around the point under the cursor |
| Wheel | Zoom |
| Double-click | Fly to point |
| Arrows | Move; with Ctrl: zoom; with Shift: rotate |
| Space / C | Jump to temple / creature |
| L, V, B | Leash on/off, previous/next leash type |
| N, S | Villager names / details |
| Ctrl+S, Ctrl+L | Quick save / load |

### Gaps

No pick-up, drop, throw, gestures, stroke or slap exist. Build those from our spec.

### Port list

1. `ZoomInterpolator` as-is, plus the 102 expected values in `test/test_interpolator.cpp` as a GUT test.
2. The camera model: modes, limits, fly-to scoring, flight midpoint.
3. Camera golden tests: `test/camera/scenarios/*.json` are frame-by-frame camera recordings (they appear to be captured from the original game) for 11 scenarios such as `DoubleClickFlyTo`, `MiddleDragRightUp` and `TwoButtonZoomOutIn`. Replaying them is the best way to prove our camera feels right.
4. Hand placement and tree sway.

---

## 2. The world: terrain, water, sky, weather

**Files:** `src/3D/Implementations/LandIsland.cpp`, `src/3D/LandBlock.cpp`, `components/lnd/include/LNDFile.h`, `assets/shaders/terrain.slang`, `assets/shaders/water.slang`, `assets/shaders/sky.slang`, `src/3D/Implementations/Sky.cpp`, `src/InfoConstants.h` (`GClimateInfo`, `GWeatherInfo`, `GTerrainMaterialInfo`).

### Terrain model

- An island is up to 32 × 32 **blocks**; each block is 16 × 16 **cells** of 10 m, so the maximum island is 5,120 m square.
- Each cell corner stores: altitude (one byte × 0.67 m, so about 171 m max), an RGB tint, a baked light level, a **country** (terrain type, 0–15), water / coastline / deep-water flags, and a flag that flips the cell's diagonal split.
- **Texturing:** each country has a 256-entry table indexed by altitude that picks *two* materials and a blend coefficient (beach low, grass middle, rock high, for example). The altitude is offset by a noise map before the lookup, so the bands get ragged, natural edges.
- **Shader** (`terrain.slang`): blends the three triangle corners' material pairs with barycentric weights, multiplies a large bump texture, adds a fine detail bump within 200 m of the camera, overlays a "footprint" texture, and darkens with time of day: `colour × lerp(0.25, clamp(light × 2, 0.5, 1), sky / 2)`. Coast cells get alpha 0.5; water cells are discarded so the sea shows through.
- **Footprints:** a top-down orthographic render of ground patches under buildings, drawn into one texture laid over the whole island. In Godot, decals or a top-down SubViewport do the same.
- **Watch out:** `LandIsland::GetHeightAt` returns the nearest corner's height (stair-stepped). Use bilinear interpolation in ours.

### Water and sky

- **Water:** a flat plane at y = 0 with planar reflection, texture tiled every 500 m, brightness scaled by time of day. Beyond 3,000 m the texture fades and the reflection takes over.
- **Sky:** a 3 × 3 grid of textures, **time (night, dusk, day) × alignment (evil, neutral, good)**, blended on both axes. Time curve mirrored around noon: full night until 4:30, dusk from 7:00 to 7:30, full day from 8:15. openblack only sets the time from a debug slider; there is no running cycle.

### Weather and climate (data only)

`GClimateInfo` holds per-season min/max rain, temperature and wind. `GWeatherInfo` holds fade in/out time, duration, strength, temperature, wetness, snowfall, overcast and wind. Nothing simulates them yet.

### Port list

1. The cell model for our procedural island generator (altitude, country, water flags).
2. Country × altitude material lookup with the noise offset, written as a Godot spatial shader, with our own textures.
3. The 3 × 3 sky blend: it gives our alignment pillar a free, dramatic payoff.
4. The water shader's ideas: reflection, distance fade, night dimming.

**Skip** the `.lnd` file parser: it only reads the original game's data.

---

## 3. Villagers

**Files:** `src/ECS/Components/Villager.h`, `src/ECS/Components/LivingAction.h`, `src/ECS/Systems/Implementations/LivingActionSystem.cpp`, `src/ECS/Systems/Implementations/PathfindingSystem.cpp`, `src/ECS/Components/WallHug.h`, `src/ECS/Archetypes/VillagerArchetype.cpp`, `src/Enums.h` (`VillagerStates`, `VillagerJob`, `Tribe`), `src/InfoConstants.h` (`GVillagerInfo`, `GJobInfo`, `GLivingInfo`, `IsReacting`), `test/mobile_wall_hug/`.

### What exists

- The original used a **table of 255 villager states**, each with callbacks for run, enter, exit, save, load, validate and transition animation, plus a three-slot state stack (top, final, previous).
- openblack implements only a wandering loop: Created → DecideWhatToDo (pick a random point within 40 m of the town, after a 20-turn pause) → MoveToPos. About 251 states are logged placeholders.
- Our spec's utility AI replaces this table. Use the `VillagerStates` names as a checklist of behaviours worth having (dance, flee, look at, follow, inspect, flying, landed, mourn…).

### Movement: "wall hug"

Villagers walk straight toward their goal. Each turn they scan the 3 × 3 grid cells ahead for fixed obstacles (bounding circles) with a ray–circle test. When blocked, they orbit the circle (angle step = speed ÷ radius per turn) until the goal is clear again. Authored **footpaths** (`Footpath.h`: node lists linking buildings) give preferred routes.

openblack's version is partial: the circle-to-square sweep and circle-to-circle transitions are missing, so villagers abandon some moves. Test scenarios live in `test/mobile_wall_hug/scenarios/`.

**Use it as our fallback:** if Godot navigation agents can't hold 300 villagers at 60 fps on the Mac mini, wall hug on our spatial grid is far cheaper.

### Data worth borrowing

- **Jobs** (`VillagerJob`): fisherman, forester, farmer, shepherd, leader, housewife, trader.
- **Job behaviour** (`GJobInfo`): rest at home after work, number of sub-visits per shift and time at each, maximum turns at a job, an activity per season (nurture, harvest, plan, execute), and which town desire the job satisfies.
- **Reactions** (`IsReacting`, 41 flags): what villagers notice and react to, including flying objects, the hand picking something up, a villager in the hand, being dropped by the hand, a falling tree, a burning house, impressive spells, nice spells, fights and fights won, deaths, the creature, gifts, new buildings, scaffolds, missionaries and town celebrations. **Use this list to seed our `GodAct` types.**
- **Tribes** (`Tribe`): nine in the original. Ours stay original (three invented tribes).

---

## 4. Belief, influence and town desires

**Files:** `src/InfoConstants.h` (`GBeliefInfo`, `GInfluenceInfo`, `GTownInfo`, `GTownDesireInfo`), `src/Enums.h` (`TownDesireInfo`, `ImpressiveType`), `src/ECS/Components/Town.h`, `src/ECS/Systems/Implementations/TownSystem.cpp`.

openblack only stores a belief number per player on each town. The data tables describe how the original worked, but only through field names: the values live in the original game's data file. Treat the points below as design hints, not specs.

- **Town desires drive belief.** 17 desires: food, wood, playtime, protection, mercy, homes, civic building, worship supplies, children, building, rain, sun, repair, workshop supplies, a wonder, relaxation and sleep. Each desire appears as a flag past a threshold, triggers normal and emergency villager actions at higher thresholds, **turns into belief when satisfied** (after a delay, scaled per tribe), **erodes belief when left unmet**, and nudges alignment.
- **Other belief sources:** impressive acts (`ImpressiveType`, including the creature being "not / quite / very impressive"); **flying things**, whose impressiveness wears off as villagers see them and slowly regrows; football matches; villagers dancing around artifacts; and a wonder, which needs a belief threshold to build.
- **Boredom:** `GBeliefInfo.defaultBoredomOfMe` confirms the original decayed belief gains from repeated acts, as our spec plans.
- **Influence:** full strength up to a set percentage of the radius, then a falling gradient (`GInfluenceInfo`), not a hard edge.

---

## 5. Miracles

**Files:** `src/Enums.h` (`MagicType`, `GestureType`, `PowerUpType`, `CastRuleType`, `SpellSeedType`), `src/InfoConstants.h` (`GMagicInfo` and its subtypes, `GSpellSystemInfo`).

Nothing is implemented. The catalogue and data shape are useful:

- **Original miracles:** fireball, lightning, explosion, heal, teleport, forest, food, storm, tornado, shield, physical shield, wood, water, flocks of birds and animals, plus spells cast on creatures (freeze, small, big, weak, strong, fat, thin, invisible, compassion, anger, hunger, fear, tiredness, illness, thirst, itch). Most have one or two power-ups.
- **Per-miracle fields** (`GMagicInfo`): gesture, perceived power (how impressive it is), impressive type, power-up type, cast rule, whether it recharges, whether its seed shows in the hand, and flags marking a one-off spell as *playful, aggressive, compassionate or healing*. The creature reads those flags when learning, so **put the same four flags on our miracle resources**.
- **21 gestures:** spiral, inverse spiral, S, circle, scribble, 3, vertical scribble, star, fork right / up / left / down, heart, R, square spiral, Cyrillic L, E, reverse S, infinity, W and house. Draw our own `$1` templates; this list is a good menu of distinct shapes. Gestures also opened the spell and leash selection menus (`GSpellSystemInfo`).

---

## 6. The creature

**Files:** `src/Creature/CreatureMind.h` (empty), `src/3D/CreatureBody.{h,cpp}`, `src/ECS/Components/Creature.h`, `src/ECS/Archetypes/CreatureArchetype.cpp`, `components/morph/`, `src/Enums.h` (`CreatureDesires`, `CreatureActionKnownAbout`, `CreatureActionLearningType`, `LeashType`, `DiscreteAlignmentValues`), `src/CHLApi.cpp` (creature functions).

- **The mind is a stub.** Build it entirely from our spec.
- **Body:** one base mesh plus six variants (good, evil, strong, weak, fat, thin) blended together. In Godot, that's six **blend shapes** driven by alignment, strength and weight.
- **Desires:** the original had 40, including impress, compassion, anger, play, hunger, fear, curiosity, tiredness, wanderlust, attention-seeking, obeying the player, sadness, staying near home and missing a friend. Milestone 1 uses three needs and six learned opinions; the spec's eight desires for Milestone 2 are a deliberate simplification of the original's 40. **Curiosity, fear, attention and obey** are the best candidates to add later.
- **Learning hints** from the challenge-script API: per-action "times performed" counters, desire values with on/off and maximums, an agenda priority, "knows how to" flags for actions (build, use a field, use a totem, use the storage pit, fish, dance), and "learn a distinction about an object". That last one matches our **opinions** model.
- **Leashes:** plain rope, good (compassion) and evil (aggression). Ours (Learn, Kind, Fierce) line up.
- **Alignment bands:** seven named steps from devilish through evil, bad, neutral, nice and good to angelic. Handy labels for the mind panel.

---

## 7. Alignment

**Files:** `src/InfoConstants.h` (`GAlignmentInfo`, `GPlayerInfo`, alignment fields in `GTownInfo` and `GTownDesireInfo`), `src/Enums.h` (`AlignmentType`, `DeathReason`), `assets/shaders/sky.slang`.

- **Weights by target type:** nice animal, nasty animal, creature, priest, skeleton, villager, building, plant, field, feature, moving object, land, script.
- **A weight per cause of death.**
- **A cap on alignment change per game turn**, so one act can't flip the world.
- **Other moves:** uprooting or planting trees; giving resources to a village versus taking them; making disciples while a village's desire is low counts as cruel.

**Port:** these become our moral-weight table plus the per-turn cap.

---

## 8. The rival god

Not implemented: only player entities exist, plus unimplemented script hooks to enable and move a computer player. `GPlayerInfo.computerPlayerBeliefChangeDecay` hints that the AI's belief gains decayed over time. Build entirely from our spec.

---

## 9. Quests and challenges

**Files:** `src/LHScriptX/` (level setup), `components/ScriptLibrary/` and `components/ScriptLibrary/docs/opcodes.md` (challenge-script VM), `src/CHLApi.cpp`, `test/mock/Scripts/Land1.txt`.

- **Level setup** is a plain list of commands, 106 in all: `CREATE_TOWN`, `SET_TOWN_BELIEF`, `CREATE_ABODE`, `CREATE_TOWN_VILLAGER`, `CREATE_FOREST`, `CREATE_FIELD`, `CREATE_CITADEL`, `CREATE_WORSHIP_SITE`, `START_CAMERA_POS` and so on. **Model our island data the same way:** a JSON list of placement commands the world builder replays.
- **Challenges** ran as compiled scripts on a small VM calling about 465 native functions; roughly 440 are unimplemented in openblack. The function list is a useful **menu for our quest runner:** camera paths and shots, advisor spirits (appear, speak, point at a position or object), dialogue, countdown timers, rewards, highlights, creature learning controls, leash attach and detach, weather changes, game speed and music. Don't port the VM.

---

## 10. Buildings and the temple

**Files:** `src/ECS/Components/{Abode,StoragePit,Field,Footpath,Temple}.h`, `src/ECS/Archetypes/AbodeArchetype.cpp`, `src/InfoConstants.h` (`GAbodeInfo`, `GTownInfo`, `GScaffoldInfo`, `GWorshipSiteInfo`, `GCitadelInfo`).

- **Homes** store food, wood and their inhabitants, up to a per-type maximum.
- **The storage pit** shows stock as five visible wood piles and one food pile. A nice visual idea for our village store.
- **Town rules** (`GTownInfo`): houses at setup, a new building every N turns, profession quotas, wood and scaffolds needed before building starts, the build percentage after which scaffolds can still be added, and the belief needed for a wonder.
- **Temple rooms:** main room, creature cave, challenge room, save room, options, credits and multiplayer.

---

## Skip entirely

These are tied to the original assets or to infrastructure Godot already provides: the file-format readers (`components/l3d`, `anm`, `lnd`, `pack`, `glw`, `morph`), the SDL3 GPU renderer, audio decoding, the `info.dat` parser, the challenge-script VM, and the Android, iOS and WebAssembly builds.

## Port order by phase

Phases as in `docs/BUILD_PLAN.md`:

1. **Phase 0:** turn loop order and speeds, spatial grid, terrain cell model, water, sky blend, `ZoomInterpolator` and its test, the camera model and limits.
2. **Phase 1:** camera golden tests, hand placement, tree sway, throwing feel.
3. **Phase 2:** job fields, wall-hug movement if straight-line walking isn't enough.
4. **Phase 3:** the villager reaction list as `GodAct` types, belief and boredom hints, the miracle data shape and its four flags.
5. **Milestone 2:** the town-desire belief model, influence gradient, alignment weights and per-turn cap, creature blend shapes, the 3 × 3 sky.

## Suggested spec changes (still to ask Alex)

These came out of the first study on 17 Oct and were never answered. The pilot has since settled one and partly settled two more. Ask Alex about the rest during Phase 0.

| # | Suggestion | Status |
| --- | --- | --- |
| 1 | **Left + right drag zooms** (as in the original) instead of rotating | Open. The pilot uses right-drag to rotate and tilt, and the wheel to zoom. |
| 2 | **Belief also grows when a village's desires are met** and erodes when they're ignored, not only from miracles | Partly in. The pilot's villages gain belief while fed and lose it while hungry; the full desire list is open for Milestone 2. |
| 3 | **Influence fades with a gradient** at its edge instead of a hard border | Open, for Milestone 2 (the pilot has no influence limit). |
| 4 | **Thrown and flying objects impress villagers,** with the effect wearing off as they get used to it | Done in the pilot (novelty per kind of spectacle). Keep it. |
| 5 | **Cap alignment change per sim turn** | Open, for Milestone 2. |
| 6 | **The sky reflects alignment** using the 3 × 3 time × alignment blend | Partly in. The pilot blends a kind sky and a cruel sky; the time-of-day axis comes with day and night in Milestone 2. |
