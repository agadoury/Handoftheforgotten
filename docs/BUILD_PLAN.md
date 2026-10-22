# Build plan

Two milestones, then an art pass, then Version 2. **Milestone 1 rebuilds the pilot in Godot and makes it feel better; Milestone 2 turns it into a small complete game.** Work one phase at a time. Don't start a phase until Alex approves the previous one, and don't start Milestone 2 until the fun check passes.

Every phase ends the same way: the project opens from a clean checkout with no errors or warnings, all GUT tests pass headless, new tunables are in `data/`, the debug overlay covers the new system, rendered frames confirm it looks right, the docs are updated, the work is committed, and Alex gets a five-line summary, exactly how to try it, and known issues.

**Current phase:** Phase 0, in progress (update this line as phases are approved). Prototype 0 is built: the pilot's island, sky, sea and the full camera, with tests. Still to build for Phase 0: the `SimClock`, `ActBus`, `SimRng`, `SaveSystem` and `Settings` autoloads, GUT, the spatial grid, the terrain cell model, the debug console and openblack's camera golden tests.

## Milestone 1: the toy, rebuilt in Godot (Phases 0–6)

The pilot already proves the toy is fun on a phone. This milestone reaches the same moments in Godot, with better feel and real architecture underneath: pull the land, throw things, convert a village, teach the creature to feed a village instead of eating it, watch it evolve, and grow Brightwater into a town.

### Phase 0: Foundation

- Godot project, folder layout from the spec, GPL v3 `LICENSE`, `.gitignore` (already in the folder), `DESIGN.md`, `CHANGELOG.md`, `IDEAS.md`, `CREDITS.md`.
- Clone openblack into `reference/openblack/`; re-check `docs/REFERENCE_NOTES.md` against it and report what changed.
- Autoloads: `SimClock` (10 Hz, pause, 1/2/4/8×), `ActBus`, `SimRng`, `SaveSystem` (stub), `Settings`, `Tuning` (loads `data/`, seeded from `docs/tuning_baseline.json`).
- Island generator reproducing the pilot's layout (village, field and circle placement as data), terrain mesh with vertex colours and collision, sea, sky dome with alignment blend, clouds, trees and rocks as MultiMesh.
- Camera rig with mouse, keyboard and trackpad controls from the spec, openblack's `ZoomInterpolator` driving every transition, and its expected values as a GUT test.
- GUT installed; `debug/shot.tscn` for scripted screenshots.
- **Done when:** Alex can fly around the island at 60 fps with mouse and trackpad, and it looks like the pilot's island (compare rendered frames with the pilot side by side).

### Phase 1: The hand

- Hand cursor with poses, scaling with zoom, alignment tint, tree sway.
- Pull-to-pan with fling, rotate and tilt, zoom to cursor, double-click fly-to, compass and home buttons.
- Pick up, drop and throw rocks; uproot trees and carry them; pick up and drop villagers (stand-in capsules for now); bounces, splashes, sinking, crushing; hover ring.
- Touch-style press-and-hold grab implemented behind a setting (for trackpad tap-drag now, touch later).
- **Done when:** Alex can throw a rock into the sea and it splashes, uproot a tree and drop it, and says the hand feels at least as good as the pilot's.

### Phase 2: Villages

- Brightwater and Cairnhold: totems and flags, storehouses with visible piles, houses on slots, influence motes, fields with wheat and sheaves.
- Villagers as MultiMesh-drawn data: farmers, folk, priests; tasks (fetch, tend, wander, worship placeholder), states (held, flying, dizzy, fleeing, dead), reactions.
- Village economy: food use, hunger, starvation, births, children growing up, houses built from wood.
- Village labels (name, belief ring, line of text, need icons).
- Save and load of everything so far.
- **Done when:** Brightwater runs 30 minutes with no input without starving or stalling and fills its houses, as the same numbers do in the pilot; a save made mid-game reloads exactly.

### Phase 3: Belief, prayer and miracles

- `GodAct` types on the `ActBus`; witness grid; belief gains with distance falloff and novelty; gifts on storehouses; drift; harm; conversion.
- Stone circle with kneeling worshippers, prayer power and the growing pillar.
- The altar UI with Harvest and Fireball orbs, casting by dragging, the fireball's blast (deaths, burning trees, scorch, shake).
- Player alignment and its effect on the sky and the hand.
- UI shell: goal tablet with the first goals, toasts, help panel, title card.
- **Done when:** Alex can convert Cairnhold using only gifts and miracles in about 15 minutes, and Cairnhold's belief drifts back down when ignored.

### Phase 4: The creature

- Procedural lion-stag body split kind/cruel, gait, rest, rear, flinch, joy, eating, carrying, head tracking the hand, thought bubble.
- Needs, actions with their step phases, the decision scoring, consequences.
- Learning: stroke and slap gestures on the creature plus panel buttons, the credit rule, observation, persistence.
- Creature panel, Mind tab.
- **Done when:** in under 10 minutes Alex can teach it to feed a village and not eat villagers, and it then does both unprompted. GUT tests reproduce the pilot's numbers (three slaps take "eat villagers" from 0.42 to about 0.17; strokes after deliveries take "feed villages" above 0.9) and cover every branch of the credit rule.

### Phase 5: Creature growth

- XP, levels, size growth, talent points; the twelve talents as data with effects through the modifier stack; capstone alignment requirements.
- Talents tab; level bar; form line.
- Visual evolution: every talent's parts and reshaping, grow-in animation, hide tint by form, the transformation moment with camera framing and the panel returning.
- **Done when:** the level pace matches the pilot (level 3 at about 1 minute, level 10 at about 9 minutes of kind play in a headless run); each talent's effect has a test; rendered frames of a full Grove, Body and Ember creature look clearly different from each other and from the starting creature.

### Phase 6: City building

- Tiers, plots, the seven building types as data, scaffolds, builders and construction, woodcutters and regrowth, fire damage and rebuilding.
- Drop interactions for each building, drop hints and target rings, temple priests, missionaries, the pen's trough, the Wonder's two versions.
- Village panel, the Village button, clicking villages, labels and buildings; building name labels; houses and totems evolving with the tier.
- The remaining goals and the finale screen.
- **Done when:** in normal play Brightwater reaches Village and then Town; each building's effect and drop interaction has a test; a save with buildings mid-construction reloads exactly.

### Fun check

After Phase 6, stop building. Alex plays the Godot build (and the pilot for comparison) for a week. Then decide together what to cut, change or double down on, and update the spec and this plan before Milestone 2.

## Milestone 2: the first version (Phases 7–10)

Scope: one island, three villages, one rival god, one creature, five miracles (Harvest, Timber, Rain, Heal, Fireball). More tribes and miracles wait in `IDEAS.md`. Adjust these phases after the fun check.

7. **Alignment and advisors.** Moral weights by outcome with a per-turn cap (openblack's tables); the land, temple and creature body shifting (blend shapes); villagers reacting with love or fear; the two advisors. *Done when:* 15 minutes of pure kindness and 15 of pure cruelty produce visibly different worlds.
8. **Rival god.** An AI god with its own villages, creature and prayer, competing for neutral villages; win and lose. *Done when:* an idle player loses villages to the rival within 30 minutes on normal difficulty.
9. **Content.** A third village; Timber, Rain and Heal; gesture casting; influence limits; day and night and weather; leashes; 3 main quests and 4–6 side challenges. *Done when:* the island plays start to finish.
10. **Polish.** Settings, a tutorial through the advisors, placeholder audio, the 300-villager performance pass, save reliability. *Done when:* the performance target holds and a mid-game save reloads exactly.

## After Milestone 2

An art pass (AI-generated concept art and models for the hand, creature, temple and villages, plus CC0 packs, all recorded in `CREDITS.md`), then Version 2: the RPG layer in `docs/GAME_SPEC.md`.
