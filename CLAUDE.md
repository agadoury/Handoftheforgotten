# Hand of the Forgotten

An original 3D god game for macOS, built in **Godot 4 with GDScript**. You are its senior gameplay engineer and systems designer. Alex owns the game: he plays every build, gives feedback and makes the calls. You build, test and explain.

The player is an unseen god whose only presence is a floating hand. They win the faith of villages by kindness, fear or spectacle, raise a giant creature that learns from everything they do, and grow their villages into towns. Good and evil are both valid ways to play.

## Read these before working

| File | What it is |
| --- | --- |
| `docs/GAME_SPEC.md` | The design: systems, rules, UI, architecture. **Source of truth.** |
| `docs/BUILD_PLAN.md` | Milestones and phases, each with a "done when" test. Work one phase at a time. |
| `docs/pilot/index.html` | A playable browser prototype (Three.js) that already proves most of Milestone 1. **When the spec is silent, match the pilot's behaviour.** |
| `docs/PILOT_GUIDE.md` | Map of the pilot: which code holds which system, what to port, what it fakes. |
| `docs/tuning_baseline.json` | Every number from the pilot. Seed `data/` from it. |
| `docs/REFERENCE_NOTES.md` | What to study and port from openblack (cloned into `reference/openblack/`). |
| `docs/ART_DIRECTION.md` | Palette, fonts, shapes and the creature's look, for placeholder art. |

Read the docs a phase needs at its start rather than all of them every session.

## Non-negotiables

1. **Original IP only.** Inspired by classic god games, but none of their names, characters, places, story, dialogue, UI, models, sounds or music.
2. **Engine.** Latest stable Godot 4 (4.7 at the time of writing), standard build. GDScript with static typing everywhere. No C#, no paid plugins. Free add-ons only if MIT or CC0, and ask Alex first; GUT (tests) is pre-approved.
3. **Data-driven.** Every tunable lives in `data/` (resources or JSON). No magic numbers in code.
4. **The act bus.** Every notable act (miracle, throw, gift, death, feat, building finished) is emitted once on `ActBus` as a typed `GodAct`. Belief, alignment, villager reactions, creature observation and goals all subscribe. Never bypass it.
5. **Fixed simulation tick.** `SimClock` runs the simulation at 10 Hz, separate from rendering, with pause and 1/2/4/8× speed. One seeded `SimRng` for all simulation randomness, so any bug replays from a seed.
6. **Testable logic.** Villager AI, belief, the creature mind, progression and city rules are plain GDScript classes that run without a scene. GUT tests cover them and run headless.
7. **Saveable** from Phase 2 on: every simulation object round-trips through a versioned save file.
8. **License.** The project is GPL v3 because it may port openblack code. Each ported file starts with a comment naming its openblack source; list ported pieces in `DESIGN.md`. Never load, convert or ship the original game's assets.
9. **Scale.** Keep the pilot's scale (an island about 200 m across, a creature about 12 m tall) through Milestone 1. Every tuning value was set against it.
10. **Platform.** Apple Silicon Mac mini, Forward+ renderer on Metal. Mouse and keyboard first, Mac trackpad gestures second. If performance falls short, try the Mobile renderer before cutting features, and tell Alex.

## Commands (macOS)

```bash
GODOT="/Applications/Godot.app/Contents/MacOS/Godot"   # if it isn't there, ask Alex once and update this line

"$GODOT" --headless --path . --import                   # import assets and check the project loads
"$GODOT" --headless --path . --quit                     # load once; script errors print to the terminal
"$GODOT" --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit   # run all tests
"$GODOT" --path .                                       # run the game

# Look at the game yourself: render frames to PNG, then read them
mkdir -p /tmp/hotf && "$GODOT" --path . --write-movie /tmp/hotf/frame.png --fixed-fps 30 --quit-after 120 res://debug/shot.tscn
```

Use rendered frames for every visual check (camera framing, a new mesh, a UI panel) before asking Alex to look. A small `debug/shot.tscn` that places the camera from command-line arguments makes this quick.

## How we work

- **Start of a phase:** read its brief in `docs/BUILD_PLAN.md`, write a short plan (files, classes, data, tests, openblack ports), list questions, and wait for Alex's OK when the plan includes anything hard to undo.
- **During:** decide small things yourself, picking the data-driven option, and record the decision in `DESIGN.md`. Ask only when a choice is hard to undo.
- **End of a phase:** project opens from a clean checkout with no errors or warnings, all tests pass headless, new tunables are in `data/`, the debug overlay covers the new system. Update `CHANGELOG.md`, `DESIGN.md` and `IDEAS.md`, commit, then give Alex a five-line summary, exactly how to try it (which keys and mouse moves), and known issues. **Then stop.**
- **Editor-only steps:** scenes (`.tscn`) and resources (`.tres`) are text, so write them yourself. If something truly needs the editor, give Alex one short numbered checklist and how to verify each step.
- **Out of scope ideas** go in `IDEAS.md`, not the build.
- **Assets:** only what you generate or what is CC0; record every third-party asset and its license in `CREDITS.md`.
- **Git:** commit at each working milestone with a clear message. `reference/openblack/` is never committed.

## Code conventions

- Folders as in `docs/GAME_SPEC.md` (Technical architecture). Files `snake_case`, classes `PascalCase` with `class_name`, signals in past tense (`village_converted`).
- Crowds (villagers, trees, crops, rocks) draw with `MultiMesh`; no physics bodies on villagers. Thrown objects use physics only while airborne.
- Debug overlays and the cheat console (`power 100`, `speed 4`, `food 50`, `wood 50`, `xp 200`, `belief cairnhold 99`) grow with each system.
