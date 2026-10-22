# Hand of the Forgotten: game spec

Version 2 of the spec, 22 Oct 2026. It replaces the "God Game Build Prompt" doc of 17 Oct and folds in everything the playable pilot (`docs/pilot/index.html`) proved since then: the controls, the economy, the creature's learning model, creature levels, talents and visual evolution, and city building.

**Tagline:** *Your followers decide what you become.*

## How to read this spec

- **Milestone tags.** Each feature is tagged **[M1]** (the toy: port and improve the pilot), **[M2]** (the first version) or **[V2]** (the RPG layer). Build only what the current phase in `docs/BUILD_PLAN.md` asks for, but leave room for the later tags.
- **The pilot is the behaviour reference.** It is a working single-file prototype Alex has played, mostly on his phone. When this spec is silent or vague, do what the pilot does. When the pilot and this spec disagree, this spec wins.
- **Numbers live in `docs/tuning_baseline.json`.** This spec quotes the important ones; the JSON has all of them.
- **openblack is the feel reference** for camera, terrain, water, sky and the 10 Hz turn loop. See `docs/REFERENCE_NOTES.md`. When openblack and this spec disagree, this spec wins.

## Design pillars

Every feature serves at least one pillar; anything that serves none goes in `IDEAS.md`.

1. **The hand is the interface.** You grab the land to move, grab things to move them, and drop things on places to make things happen. The HUD stays small: a goal tablet, the miracle altar, and panels that open only when asked.
2. **Every act is judged.** Villagers, the creature and the world react to whether you are kind or cruel. Both paths can win.
3. **The creature is your mirror.** It learns from your feedback and by watching you. The best moment in the game is it doing something you taught it, unprompted.
4. **Belief is the economy.** Faith becomes prayer power, power becomes miracles, miracles and gifts earn more faith.
5. **Your choices show.** The creature's body, your villages and the sky all visibly change with what you choose.
6. **Readable systems.** Labels, panels and debug overlays show needs, opinions and belief, so we tune by looking, not guessing.

## Ground rules

- **Original IP only.** Invent every name, character, place, line of dialogue, model, sound and piece of music.
- **Engine.** Latest stable Godot 4 (4.7.x as of Oct 2026), standard build, statically typed GDScript. Jolt is the default 3D physics engine for new projects since Godot 4.6; keep it.
- **Hardware.** Apple Silicon Mac mini. Forward+ on Metal; fall back to the Mobile renderer before cutting features.
- **Performance.** 60 fps at 1080p. Milestone 1 target: the pilot's world (about 70 villagers, 170 trees, 1 creature, 13 buildings). Milestone 2 target: 300 villagers, 2 creatures, 2,000 trees.
- **Input.** Mouse and keyboard first. Mac trackpad second: two-finger scroll slides the map, pinch zooms, Option + two-finger scroll rotates and tilts, click-drag pulls the land (Godot reports trackpad pan and pinch gestures but not rotation). Touch devices are an open choice (see the end of this spec); the pilot's touch scheme is documented below for when they come.
- **Art.** Placeholder low-poly meshes built in code or CSG, flat-shaded, bright and readable, following `docs/ART_DIRECTION.md`. All colours and materials come from theme resources so art can be swapped later.
- **Data-driven, deterministic, saveable, tested.** As in `CLAUDE.md`.

## 1. The hand: camera and input [M1]

The pilot's controls are proven; port them, then improve the feel with openblack's camera model.

### Camera

| Input | Mouse | Trackpad | Pilot touch equivalent |
| --- | --- | --- | --- |
| Move | Left-drag the ground: the grabbed point stays under the cursor | Click-drag the ground, or two-finger scroll to slide | One-finger drag |
| Fling | Release while moving: the land glides and slows | Same | Same |
| Rotate and tilt | Right-drag or middle-drag (horizontal rotates, vertical tilts) | Option + two-finger scroll, or two-finger-click drag | Two-finger twist; two fingers up or down |
| Zoom | Wheel, toward the cursor | Pinch, toward the fingers | Pinch, anchored under the midpoint |
| Fly to | Double-click the ground | Double-click | Double-tap |
| Zoom out a step | (none) | (none) | Two-finger tap |
| Keys | WASD or arrows move, Q/E rotate, R/F or +/− zoom | | |
| Reset view | Compass button (also shows north) | | |
| Home | House button flies to Brightwater | | |

- **Limits:** pitch 0.32 to 1.36 rad, distance 20 to 210 m, camera target kept within 110 m of the island centre, camera at least 4 m above the ground under it.
- **Smoothing:** port openblack's `ZoomInterpolator` for fly-to and every camera transition (see `docs/REFERENCE_NOTES.md`). The pilot already uses its curve for fly-to; extend it to all camera motion so nothing snaps.
- **Anchoring:** zoom and two-finger gestures keep the world point under the cursor (or the fingers' midpoint) fixed on screen.

### The hand

- A glowing 3D hand with a coloured ring on each finger (ember, blue, green, gold, white from thumb to little finger; the five rings become relic slots in V2) follows the cursor, projected onto the ground and floating above it.
- **Size:** scale = clamp(camera distance × 0.02, 1, 3.8), so it reads the same on screen at any zoom. On touch it floats higher so the finger doesn't hide it, and fades out 0.6 s after the finger lifts.
- **Poses:** open while idle, half-closed while dragging the land, closed while carrying.
- **Tree sway:** trees within 10 m lean away from the hand (openblack's `HandSystem` idea).
- **Alignment tint:** the glow shifts from warm gold (kind) to red-orange (cruel). [M2: the hand's shape also shifts, soft to clawed.]

### Grab, drop, throw

- **Mouse:** pressing on a loose object or villager grabs it immediately (a hover ring shows the target first). Pressing on a tree and holding uproots it. Pressing on the ground always moves the land.
- **Touch** (for a future iPad version, and as an optional setting for trackpads): a drag always moves the land. To grab, press and hold on the object until a gold ring fills (280 ms); moving more than 10 px first cancels the grab. This fixed the pilot's biggest complaint on a phone ("I keep picking stuff up while moving").
- **Throwing:** release while moving to throw, with velocity from the last 140 ms of motion; release while still to drop gently. Thrown things bounce up to twice, crush villagers when they land fast, and splash in the sea.
- **Villagers** can be picked up and dropped. A thrown villager dies if it lands faster than 17 m/s (32 m/s if just dropped); otherwise it lands dizzy.
- **Drop hints:** while you hold something over a building or storehouse, a label and a ring show what will happen there ("+6 wood for the Granary", "Becomes a priest", "Fire will wreck the Temple"). Red means it won't work or will do harm.

### Clicking things

- **Creature:** click or tap to open its panel. Rub it slowly (back and forth) to **stroke**; flick across it fast to **slap**. Thresholds are in the tuning file. A drag that starts on the creature and moves steadily one way becomes a land drag.
- **Village, its label, or a building:** opens the village panel, with that building highlighted.
- **A single click waits about 0.35 s** to make sure it isn't the first half of a double-click.

## 2. The world [M1]

- **Island:** generated from noise, matching the pilot's layout: a warped round island about 200 m across with beaches, rolling grass, a mountain about 30 m high, Brightwater on the lowland, Cairnhold on a hill about 80 m away, a stone circle (the worship site) near Brightwater, three wheat fields, about 170 trees in clumps and about 30 loose rocks. Flatten the ground under villages, fields and the circle. Model the layout as placement data (openblack's level-setup idea), so islands can be authored later.
- **Terrain:** a heightmap mesh with vertex colours (wet sand, sand, grass, rock on slopes and peaks, packed dirt around village centres) and a matching collision shape; bilinear height lookups. Port openblack's country-by-altitude material blend when real textures arrive.
- **Sea:** a gently swelling water plane; things that fall in sink, villagers drown.
- **Sky:** a gradient sky dome with a sun glow. Its colours, the fog and the light blend from warm daylight toward a red-violet dusk as the player turns cruel (up to 85%). [M2: openblack's 3 × 3 sky blend of time of day × alignment.]
- **Clouds** drift slowly overhead.
- [M2] Day and night (default 12 real minutes per day) and weather (clear, rain, storm); rain grows crops faster.
- [M2] Land inside your influence reacts to alignment: lusher when kind, darker and dying when cruel.

## 3. Villagers and villages [M1]

### Villages

- Each village has a **totem** with a flag (gold when it worships you, slate when not), a **storehouse** whose food and wood piles visibly grow and shrink, **houses** on a ring of 8 slots, a ring of glowing **influence motes**, its **fields**, and up to six **building plots** (section 10).
- **A floating label** over each village shows its name, a belief ring with the percentage, a line of text (tier and population if it worships you, belief and population if not), and need icons (wheat when hungry, a log when it needs wood).
- **Economy** (village level, as in the pilot): each villager eats 0.025 food per second from the store. At zero food a villager starves to death every 50 s. Below 5 food the village is hungry and its belief in you falls. Wheat ripens in fields and appears as sheaves; farmers carry them to the store. Wood comes from you (uprooted trees, 6 wood each) or from woodcutters.
- **Births:** every 34 s (17 s with a Nursery), if the store has at least 18 food, there are two adults and a free bed. A birth costs 3 food. Children grow up in 90 s.
- **Houses:** when wood allows (12, or 9 with a Lodge) and the village is nearly full, it builds a house by itself, up to 8. House capacity depends on the village tier.

### Villagers

- **Roles** (one `role` field): `farmer`, `folk`, `priest`. Tasks layered on top: fetch food, tend a field, wander, worship at the stone circle, build, chop wood, pray at the temple, preach as a missionary.
- **States:** idle (running a task), held, flying, dizzy, fleeing, grabbed by the creature, dead.
- **Reactions:** villagers who witness something impressive stop and bounce, facing it. Villagers near a death or the hunting creature flee.
- **Movement:** walk straight toward the goal and turn away from water, as in the pilot; [M2] navmesh or openblack's wall-hug on the spatial grid when buildings need avoiding.
- [M2] Per-villager needs (hunger, rest, faith, social), more jobs (forester, fisher, breeder) and tribes, as in the original spec.

## 4. Belief and prayer power [M1]

- **Belief** is 0–100 per village. At 100 a neutral village converts: its flag and ring turn gold, it joins you, and its villagers pray for you too.
- **Witnessing:** each act on the `ActBus` reaches villages within 50 m: gain = base × novelty × (1 − distance / 50 × 0.5), × 0.35 for villages that already worship you. Bases: Harvest 5, fireball blast 7, thrown object's first bounce 1.8, splash 1.2, lifting a villager 0.4, throwing one 0.6.
- **Novelty:** each kind of spectacle (throw, miracle, fire) loses 0.18 of its effect per use, down to 0.2, and recovers 0.035 per second. Doing something new impresses more than repeating it.
- **Gifts:** food or wood dropped on a storehouse adds +3 belief to your own village or +8 to a neutral one (×1.4 for a Harvest basket). The creature's deliveries count too.
- **Drift:** your villages gain 0.06 per second while fed and lose 0.1 while hungry; neutral villages lose 0.02 per second.
- **Harm:** each villager you kill costs 7 belief (10 in a neutral village); each one the creature eats costs 9 (12).
- **Prayer power** (0–100, starts at 40): villagers kneel at the stone circle and each adds 0.55 per second. How many go depends on Brightwater's belief (1 to 4). A second village that worships you adds 0.35 per second; temples and priests add more (section 10). A glowing pillar at the circle grows with your power and is mirrored in the altar's meter.
- [M2] **Influence:** you can only grab and cast inside a radius around your villages and temple, with a soft gradient edge. **Fear vs love:** belief earned through fear decays faster than belief earned through care.

## 5. Miracles

- **[M1] The altar:** a pill-shaped bar at the bottom of the screen holds miracle orbs and the prayer meter. Drag an orb into the world: it appears in the hand and falls where you let go. Dropping it back on the altar cancels for free. An orb you can't afford is greyed out and shakes.
- **[M1] Harvest (25 power):** a basket of 12 food. Witness base 5, alignment +0.02.
- **[M1] Fireball (35 power):** explodes on landing. Kills villagers within 7 m, burns trees within 8 m (they fall after 14 s), destroys food within 6 m, wrecks buildings within 6 m of their edge, leaves a scorch mark. Witness base 7, alignment −0.04.
- **[M2]** Timber, Rain and Heal, completing the first version's five. **Gestures:** hold the right mouse button and draw a shape to cast without the altar ($1 Unistroke recognizer, templates in `data/gestures/`).
- **[M2] Charging:** hold longer for a stronger, costlier version.
- **Morality comes from the outcome, not the miracle:** a fireball on an empty hill is spectacle; on a village it is cruelty.
- Later miracle ideas (Shield, Forest, Lightning, Gale, Meteor) stay in `IDEAS.md`. Give every miracle resource openblack's four flags (playful, aggressive, compassionate, healing) for the creature to read later.

## 6. The creature [M1]

### Body

- One creature in Milestone 1: a giant **lion-stag** about 12 m tall, **split down the spine**. Its kind side (its left, the +x side as it faces +z) is moss-green and gold with glowing gold arc markings and a leafy antler; its cruel side (its right) is dark umber with glowing ember cracks and a charred antler. One gold eye, one ember eye. The markings glow brighter as it leans kind or cruel.
- It walks on four legs with a simple gait, lies down to rest, rears, flinches when slapped, wags and bounces when happy, eats with a head dip, carries things and villagers in its mouth, and turns its head toward the hand when it is close.
- A **thought bubble** above it shows what it's thinking ("Hungry… that villager looks tasty.", "I brought food to Brightwater!"), tinted gold for kind thoughts and ember for cruel ones.
- [M2] Three original starter species to choose from; six blend shapes (good, evil, strong, weak, fat, thin) driven by alignment, strength and weight; leashes (Learn, Kind, Fierce) to lead it and tie it to a post.

### Needs and actions

- **Needs** (0–1): hunger +0.0075 per second, play +0.006, tiredness +0.0032.
- **Actions it can choose:** eat food, feed a village (carry food to a storehouse that needs it), eat a villager, eat a tree, eat a rock, throw a rock, eat from a pen's trough, rest, wander. Each action walks to its target, then plays out in steps (take, chew or deliver or aim).
- **Choosing:** every few seconds it scores each available action and takes the best:
  - score = need × learned opinion × proximity(distance), where proximity = 1 / (1 + distance / 26), with a few per-action factors (in the tuning file) and up to 0.05 of noise;
  - feeding a village uses 0.55 × opinion × proximity × how badly the nearest store needs food;
  - resting is only an option when tiredness is above 0.55; wandering always scores 0.1 and heads home if it strayed more than 55 m.
- **Consequences teach too:** eating a rock tastes awful and halves its opinion of rocks; meals reduce hunger by set amounts.

### The learning model (the heart of the game)

Six learned **opinions**, one per action it can be taught about: eat food, eat villagers, eat trees, eat rocks, feed villages, throw rocks. Each is 0.02–0.98 and starts from the tuning file (it begins slightly inclined to eat villagers and not to feed villages).

1. **Stroke and slap.** A stroke moves the credited opinion toward 1, a slap toward 0, by a learning rate of 0.5 × strength (gesture strength from how long or fast you rubbed or flicked; the panel buttons use 0.8). Slapping it during an action aborts that action.
2. **Credit assignment.** Credit the action it is visibly doing (past its first 2.5 s or past the approach); if it only just started something new, credit the action it finished in the last 4.5 s; failing that, the one finished in the last 8 s; failing that, nothing ("That feels nice. What did I do?"). This rule fixed the pilot's worst teaching bug: stroking it right after it fed a village used to reward whatever it started next.
3. **Observation.** Within sight of it (50–60 m), your own acts nudge its opinions: killing a villager raises "eat villagers" by 0.06, feeding a village raises "feed villages" by 0.1, uprooting a tree raises "eat trees" by 0.02, throwing a rock raises "throw rocks" by 0.04 (each as amount × (1 − opinion)).
4. **The trough.** Food dropped in a Creature Pen's trough draws it from up to 150 m; each meal there raises "feed villages" and lowers "eat villagers" a little.
5. **Its words.** Every learning moment produces a line in the thought bubble ("Eating villagers is bad. I won't.") and pulses the opinion's bar in the panel.
6. **Persistence.** The whole learned state saves and loads.

The pilot shows this model is learnable: three slaps took "eat villagers" from 0.42 to about 0.17, and a handful of strokes after deliveries took "feed villages" to about 0.98, after which it fed villages unprompted. Reproduce those numbers in GUT tests.

[M2] Grow toward the original spec's fuller model: desires as weighted sums of features (hunger, rest, play, help, destroy, impress, obey, explore), opinions keyed by target attributes (type, owner, alignment, size, distance), and learning miracles by watching them.

### Its panel

A sheet that rises from the bottom (a side panel on wide screens) with a level bar and two tabs:

- **Mind:** its current thought, an alignment bar (Kind · word · Cruel, using Angelic, Kind, Torn, Cruel, Devilish), "What it has learned" (the six opinions as bars), "How it feels" (hunger, wants to play, tiredness), and Stroke and Slap buttons, with a line explaining the hand gestures.
- **Talents:** the talent tree, the selected talent's details (effect, what it changes about its look, requirement) and a Learn button.

## 6b. Creature growth: levels, talents and forms [M1]

Alex asked for this after playing: the creature levels up and gains talents, and every talent changes how it looks.

### Levels

- XP from what it does: feeding a village 30, eating a villager 15, eating food 10, throwing a rock 10, eating a tree 6, eating a rock 2, each credited stroke or slap 5, each observation 3. It needs 30 + 20 × level XP for the next level, up to level 10.
- Each level: one talent point, and the creature grows 3.5% larger (its reach grows with it).
- Measured pace in the pilot: level 3 after about a minute, level 10 after about nine minutes of active kind play. Nine points in total, so it can never have all twelve talents.

### The talent tree

Three branches of four tiers. Each talent needs the one above it; the last talent of Grove needs a kind creature (alignment ≥ 0.3), the last of Ember a cruel one (≤ −0.3).

| Branch | Tier 1 | Tier 2 | Tier 3 | Tier 4 |
| --- | --- | --- | --- | --- |
| **Grove** | Gentle Giant: its food deliveries give 50% more belief | Green Thumb: nearby fields ripen twice as fast | Shepherd: each delivery impresses nearby villages like a miracle | Herald of the Hand: gathers prayer near your circle and villages |
| **Body** | Hearty: hungry 35% more slowly | Long Stride: walks 25% faster | Quick Learner: learns 50% more from everything | Colossus: 15% larger, deeds count 50% more |
| **Ember** | Dread: eating a villager frightens neutral villages into belief | Hunter: chases 35% faster and doesn't give up | Earthshaker: throws much farther, landings awe villages | Tyrant: looming over neutral villages wins them by fear; your own resent it |

### Visual evolution

Every talent adds parts to the body or reshapes it. New parts grow in with a springy overshoot.

| Talent | What changes |
| --- | --- |
| Gentle Giant | Pink and white blossoms along its back and mane; petals drift off it |
| Green Thumb | Moss and leaf tufts over shoulders and back; leaves sprout on both antlers; green sparks where it walks |
| Shepherd | A golden collar with a swinging bell |
| Herald of the Hand | A slowly turning ring of golden light above its head; gold motes rise; kind markings blaze |
| Hearty | Broader chest and mane, thicker legs |
| Long Stride | Longer legs (the body rises with them), fur tufts at the ankles, a longer tail |
| Quick Learner | A glowing third eye on its brow; taller ears; larger eyes |
| Colossus | Stone plates on shoulders, back and forelegs; huge antlers |
| Dread | A row of black spikes down the spine and mane, trailing smoke |
| Hunter | Bone claws on every foot; two fangs |
| Earthshaker | Glowing molten veins on legs and hide; rocky knees; dust and embers where it steps |
| Tyrant | A crown of curved black horns with ember tips; larger burning eyes; embers rise from it |

- **Forms:** the branch with the most talents names it: Grovekin → Grove Warden → Grove Herald, Stonekin → Stone Titan → Stone Colossus, Emberkin → Ember Fiend → Ember Tyrant (at 1–2, 3 and 4 talents). A tie makes it a Wildling; none, a Young Beast. Its whole hide shifts subtly toward its branch (greener, stonier, or darker and warmer). The form shows under the level bar.
- **The transformation moment:** pressing Learn closes the panel, the camera glides to frame the creature, it stops, turns three-quarters toward you (kind flank for Grove and Body, cruel flank for Ember) and rears; a burst of light in the branch colour, a small shake, and the new parts grow in. A message names the change; a new form gets its own line ("I am a Grove Warden now. Look at me!"). If points remain, the panel returns after about 4 s unless you touch the world first.
- [V2] Villagers craft armour and totems for it; forms are displayed in its cave at the temple.

## 7. Alignment [M1 core, M2 the rest]

- **[M1]** The player and the creature each have an alignment from −1 (cruel) to +1 (kind), tracked separately. Player shifts: killing a villager −0.07, throwing one −0.02, giving food +0.04, casting Harvest +0.02, a fireball −0.06 in total. Creature shifts: delivering food +0.04, eating a villager −0.12. In M1 it shows in the sky, the hand's glow, the creature's markings and the talent capstones it can learn.
- **[M2]** Moral weights by target and outcome with a cap per sim turn (openblack's tables), the land, temple and creature body shifting, villagers reacting with love or fear, and two original advisors (a kind conscience and a cruel one) who comment, teach the controls and argue.

## 8. The rival god [M2]

An AI god with its own temple, villages, creature and prayer power, playing by the same rules; difficulty changes multipliers, never rules. It impresses neutral villages, defends its own and attacks yours when stronger. **Win:** every village on the island worships you. **Lose:** you lose all of yours.

## 9. Goals and quests

- **[M1] The goal tablet** (top left) shows the current goal and, when opened, the full list with a hint for the current one. Completing a goal flashes the tablet and shows a message. Ten goals teach the toy in order: drag the land; throw a rock; cast Harvest; feed Brightwater; have Brightwater build something; tap the creature; teach it (slap cruelty, stroke kindness); let it feed a village on its own; grow Brightwater into a Village; win over Cairnhold. Goals can be completed out of order. When all are done, the title card returns as a finale with stats (the creature's form and alignment, what it likes and avoids most, your way, miracles cast, gifts given, Brightwater's tier, buildings raised) and a Keep playing button.
- **[M2]** 3–5 main quests and 6–10 side challenges defined in data (triggers, conditions, rewards, a kind or cruel choice), shown as in-world markers.

## 10. City building [M1]

Villages that worship you grow from **Hamlet** to **Village** to **Town**, and you choose what they build.

### Tiers

| Tier | Building plots | People per house | Needs |
| --- | --- | --- | --- |
| Hamlet | 2 | 3 | (start) |
| Village | 4 | 4 | 12 people and 2 finished buildings |
| Town | 6 | 5 | 20 people, 4 finished buildings and a Temple |

Growing up happens by itself when the needs are met: every house rebuilds in the new style with a pop-up animation (Village houses gain a chimney and a lit window; Town houses become two storeys with a timber band), the totem gains a gold ring and then a crown, the village gains belief, and a message says what it unlocked. Only villages that worship you grow or take plans. Brightwater has room for five plots, so even a Town can't hold every building type: you choose.

### Building

- Open the **village panel** by clicking a village, its label, one of its buildings, or the columns button (top right; it opens the village nearest the camera).
- The panel shows a tier chip; People (current / capacity), Food, Wood and Belief; what it needs to grow, as ticked chips; its buildings (effect, what to drop on it, or a progress bar with Cancel); and "Build here": every building type with its wood cost, effect, and a Build button or the reason it can't be built yet.
- **Build** puts a scaffold on the next free plot (clearing trees there). Up to three builders walk over and each turns 0.35 wood per second from the storehouse into progress. With no wood they wait, the village label shows the log icon, and a message tells you once. **Dropping an uprooted tree on a scaffold** adds its wood directly. The building rises out of the scaffold as it progresses and pops into place when done (+4 belief).
- One building under construction at a time per village. Cancel refunds its wood.
- **Fire** wrecks a finished building into a half-built ruin that villagers rebuild with wood; a scaffold loses 40% of its progress.
- Each building has a small floating name label when you zoom in close.

### Building types

| Building | Cost (wood) | Unlocks at | What it does | Drop on it |
| --- | --- | --- | --- | --- |
| Woodcutter's Lodge | 8 | Hamlet | Woodcutters fell nearby trees for wood (+4 a trip) and the trees regrow; houses and buildings cost 25% less wood | A tree is sawn into 9 wood instead of 6 |
| Granary | 10 | Hamlet | The village eats 30% less | Food is worth 50% more |
| Nursery | 10 | Hamlet | Children are born twice as often | Food makes a child be born at once, if there's a free bed |
| Temple | 14 | Hamlet | +0.3 prayer per second and a slow belief rise | A villager becomes a priest who kneels and prays (+0.25 per second, up to 3) |
| Watchtower | 12 | Village | Neutral villages within 130 m slowly start to believe; its villagers spot the creature from 22 m instead of 12 and get away | A villager becomes a missionary: walks to the nearest neutral village, preaches 40 s (+0.45 belief per second), then settles there |
| Creature Pen | 16 | Village | Nearby, the creature gets hungry and tired 40% more slowly and earns 25% more XP | Food goes in the trough and calls the creature; each meal there teaches it to share food |
| Wonder | 30 | Town | Becomes the Sun Spire (kind player) or Ember Spire (cruel) when finished: a beam of light, +1 prayer per second, and every village on the island believes more | (nothing) |

Cairnhold starts with its own Granary. The pilot measured Brightwater reaching Town in about five minutes of game time with generous gifts; expect longer in normal play.

## UI [M1]

The pilot's layout, rebuilt as Godot `Control` scenes with a shared theme:

- **Top left:** the goal tablet (step "3/10" + current goal); tap to expand the list.
- **Top right:** a column of round buttons: Help (controls), Compass (reset view, shows north), Home (fly to Brightwater), Village (opens the village panel).
- **Bottom centre:** the altar (Harvest orb, prayer number with meter, Fireball orb). It hides while the creature or village panel is open.
- **Middle top:** up to three messages ("toasts") at a time, each fading after about 3.5 s; red dot for bad news.
- **Panels:** creature, village and help panels rise as a sheet from the bottom (on screens wider than 760 px, a 390 px panel on the right). Only one is open at a time. Escape closes them.
- **In the world:** village labels, the creature's thought bubble, building name labels when zoomed in, drop hints and target rings while holding something.
- **Title card:** title, tagline, one line about what you do, Begin. The same card returns as the finale.
- **Feedback:** sparkles for gifts, faith motes when belief jumps, dust puffs for landings, a light screen shake for impacts. Respect a reduced-motion setting.
- [V2] Move as much of this as possible into the world (see "Keep it in the world").

## Technical architecture

```
res://
  autoload/    sim_clock, act_bus, sim_rng, save_system, settings, tuning
  data/        tuning (from docs/tuning_baseline.json), miracles/, buildings/, tiers/, talents/,
               creature/, goals/, island/ (placement commands), gestures/ [M2], quests/ [M2]
  hand/        camera rig (+ ZoomInterpolator), hand, input mapping (mouse, trackpad, touch-ready)
  world/       island generator, terrain, sea, sky, clouds, trees, rocks, items
  sim/         villagers/, villages/, belief/, prayer/, alignment/, city/ (tiers, plots, buildings, construction)
  miracles/    definitions, altar casting, effects
  creature/    body/ (procedural model, gait, evolution parts)  mind/ (needs, decisions, opinions, learning)
               growth/ (xp, levels, talents, forms)
  goals/       goal runner [M1]; quests/ [M2]
  ui/          theme, goal tablet, altar, toasts, creature panel, village panel, help, labels, title
  debug/       overlays, cheat console, shot.tscn (scripted screenshots)
  tests/       GUT tests
```

- **The act bus.** `ActBus` carries typed `GodAct` records: actor (player, creature, villager, rival), type, target, position, magnitude, novelty kind. Use openblack's villager reaction list to seed the types. Belief, alignment, villager reactions, creature observation and goals all subscribe; nothing calls them directly.
- **Autoloads:** `SimClock` (10 Hz turns in openblack's order: spatial grid → movement → villager and creature actions → village economy), `ActBus`, `SimRng`, `SaveSystem`, `Settings`, `Tuning` (loads `data/`). Belief, alignment and city managers live in the world scene so they reset with it.
- **Witness queries:** a spatial hash grid answers "who saw this?" for villages and villagers.
- **Modifiers:** talents, buildings and (in V2) relics and domains change numbers through one modifier stack per stat (`hunger_rate`, `walk_speed`, `deed_belief`, `food_use`, `birth_rate`…), never through scattered `if has_talent` checks. The pilot used direct checks; don't copy that.
- **Crowds:** villagers, trees, wheat and rocks draw with `MultiMesh`; villagers are plain data objects updated by a manager.
- **Saves:** versioned JSON. Everything in the simulation round-trips, including the creature's opinions, level, talents and evolution parts, village tiers and buildings.
- **Debug:** toggleable overlays (village food and wood, belief per village, creature needs, opinions and action scores, plots and building states, witness radius) and a cheat console.
- **Tests:** GUT tests for the learning updates and credit rule, belief and novelty math, village economy, tier rules and building effects, XP and talent requirements, and the ZoomInterpolator's expected values from openblack. They run headless.

## Version 2: the RPG layer [V2]

After Milestone 2, the game becomes a god RPG: a fallen god whose priests level them up, relics on the hand, and a creature with its own build. Don't build any of this before then, but keep the hooks in mind from the start.

- **A fallen god's story.** You start as a forgotten god with almost no power. Each island is a region to reclaim; each rival god is a multi-phase boss guarding a shard of your old power, and defeating one unlocks a new domain.
- **Divine level and domains.** Belief becomes divine XP. Each level grants a point in a domain: Flame, Storm, Life, Harvest or Death (working names). Miracles scale with their domain's level; hybrid builds unlock combined effects (Flame + Life: healing fire that also burns enemies). Kind and cruel paths are the two halves of each domain's tree.
- **Priests level you up.** This is what Alex asked for: your followers decide what kind of god you become, and you steer them rather than spend points yourself. Priests (ordained at a temple, already in M1) each pray toward a favoured domain chosen from their job and life; their devotion fills that domain's bar. Bless a priest to speed their domain up, or overrule them at a cost in belief and their faith. Priests hold rites and festivals, preach, go on pilgrimages that bring back relics, and rise from novice to elder to high priest. Zealots push cruel rites and healers kind ones, so priests pull your alignment too.
- **Five rings.** The hand's five finger rings become relic slots, filled from ruins, challenges, pilgrimages and defeated rivals. Relics roll bonuses ("Fireball leaves burning ground", "+20% belief from children") and are swapped at the temple.
- **The creature's build.** Extends M1's talents and forms: more forms, villager-crafted armour and totems, abilities. The creature stays autonomous; the player never controls it directly.
- **Anointed champions.** A villager champion you bless and send on background expeditions (raids, scouting) who returns with relics and stories, or doesn't.
- **Keep it in the world.** The domain tree as a constellation in the temple's sky, relics on the hand, creature forms in its cave, devotion glowing at worship sites.

**Hooks to build now:** miracle strength = base × a modifier stack; effects through a modifier pipeline (so a relic can add "on fireball impact, spawn burning ground"); one `role` field on villagers (`folk`, `farmer`, `priest`, later `champion`); belief income logged per source (worship, gift, act, building), so devotion can later be split by domain; creature body parts, talents and forms fully data-driven.

## Open choices

Defaults the build uses; Alex can change them once the core is playable, so keep them easy to swap.

| Choice | Default now | Alternatives |
| --- | --- | --- |
| Title | Hand of the Forgotten | Your pick |
| Casting miracles | Drag orbs from the altar [M1], gestures added [M2] | Gestures only (purer to the original), orbs only |
| Island scale | The pilot's small island in M1 | The original spec's 2 × 2 km island for M2 |
| Creature | One lion-stag in M1 | Three starter species [M2], unlockable forms |
| Platform | Mac, mouse and trackpad (Windows export later) | iPad and phone (the pilot proves the touch controls), VR, controller |
| Who levels up the god in V2 | Priests only | Priests plus the player spending some points directly |
| Tone | Light humour | Dark and mythic |
| Morality | One kind ↔ cruel axis | Two axes (order ↔ chaos too) |
| Rival gods | One AI god [M2] | Several, or none (sandbox) |
| Multiplayer | None | Skirmish against friends |
