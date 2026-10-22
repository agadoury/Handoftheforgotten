# Art direction

Placeholder art for Milestones 1 and 2: low-poly, flat-shaded, bright and readable from a high camera, built in code or CSG. Everything here comes from the pilot, so the Godot build should look like it on day one. Keep all colours in a theme resource and a materials resource so the later art pass is a swap, not a rewrite.

## Mood

A warm, sunlit island at golden hour that turns red-violet and ominous as the god turns cruel. Mythic but light-hearted. The UI looks like gold-inlaid tablets of dark wood floating at the edges of the world.

## UI palette and type

| Token | Value | Use |
| --- | --- | --- |
| umber | `#17110d` | Page background, text on gold |
| panel | `rgba(26,19,14,.76)` with blur | Floating HUD pieces |
| panel-solid | `#1d1611` | Sheets, toasts, lists |
| line | `rgba(232,182,76,.26)` | Hairline borders |
| parchment | `#f3e6c8` | Main text |
| dim | `rgba(243,230,200,.66)` | Secondary text |
| gold | `#e8b64c` | Accents, kind, buttons, belief rings of your villages |
| gold-light | `#f6d78c` | Headings, highlights |
| gold-deep | `#7a4e12` | Title shadow, orb shading |
| ember | `#e0533a` | Cruel, warnings, slap, Fireball |
| ember-deep | `#5e1a10` | Fireball orb shading |
| moss | `#9cc25d` | Body branch, ticked requirements |
| slate | `#9fb4cf` | Neutral villages |

- **Display type:** Cinzel 600–700 (titles, panel headings, small caps labels with wide letter spacing).
- **Body type:** Alegreya Sans 400–700.
- Both are free Google Fonts under the SIL Open Font License: fine to bundle; record them in `CREDITS.md`.
- Shapes: pills and rounded rectangles (12–20 px radius), round 42 px icon buttons, 60 px miracle orbs with radial gradients and a cost badge.

## World palette

| Thing | Colour |
| --- | --- |
| Sky, kind | top `#4c7cb6`, horizon `#f3c890`, sun `#ffd9a0` |
| Sky, cruel | top `#38192a`, horizon `#c4583c`, sun `#ff7448` |
| Sea | `#2b6f88`, glossy, gently swelling |
| Sand (wet, dry) | `#bfa36a`, `#e4cf96` |
| Grass (light, dark) | `#9fc25c`, `#5e8f3e` |
| Rock, peak | `#8d8270`, `#c4baa9` |
| Packed dirt (village centres) | `#b99a68` |
| Trees | pine `#3f7a3a` cones, oak `#74a546` icosahedra, trunks `#6b4a2b` |
| Houses | walls `#eadfc6`, roofs `#b88a40` four-sided cones, doors `#4a3324` |
| Grain, sheaves, wheat | `#f5c94f` (slightly emissive), `#e2b64a`, field `#c9b04a` |
| Stone circle and temple | `#b7ae9c` |
| Flags | gold `#e8b64c` (yours), slate `#7d8fa6` (neutral) |
| Villagers | capsule body + sphere head; farmers brown `#8a6a44`, priests white `#f1ead8`, folk in muted blue, red, green, ochre or violet |

## The hand

A soft, glowing, cream-white hand (`#fff3dc`, gold emissive) with a faint halo and a coloured ring on each finger: thumb ember `#ff6a2a`, index blue `#6aa8ff`, middle green `#7fd35a`, ring gold `#f2c14e`, little white `#e8e2d0`. Its glow turns red-orange as the god turns cruel. The rings become relic slots in Version 2.

## The creature

A giant lion-stag, split down the spine:

- **Kind side (its left, +x when it faces +z):** moss green to straw gold, three glowing gold arc markings on the flank, a brown antler tipped with green leaf clusters, a gold eye, small pink and white blossoms near the mane.
- **Cruel side (its right):** dark umber to near-black, six glowing ember cracks on the flank, a charred black antler with glowing ember tips, an ember eye.
- Big mane, boxy head and snout, four sturdy legs with dark hooves, a tufted tail. Markings glow brighter as its alignment moves toward their side.
- Talent evolution adds blossoms, moss, a gold collar and bell, a halo, stone plates, a third eye, spikes, claws and fangs, molten veins and a crown of horns (see the spec's table). Kind additions lean gold and green; cruel ones black and ember.

## Buildings

Each building faces the village centre with its door. Lodge: log cabin with a log stack and an axe in a stump. Granary: banded round silo with a small hut and grain sacks. Nursery: peach clay house, red roof, round gold window, chimney smoke, picket fence. Temple: stone steps, six white columns, gold roof, floating glowing orb. Watchtower: four log legs, braced platform, pointed roof, bell, gold pennant. Creature Pen: tall log arch with antler ornaments, a long trough, a half-ring fence. Wonder: four tapering stone tiers with gold bands and a floating crystal (gold for the Sun Spire, ember for the Ember Spire) under a beam of light. Scaffolds are log frames the building rises out of.

## For the later art pass

Use AI image tools for concept art and turnarounds of the hand, the creature (one sheet per form), the temple and a village set, then turn them into models. Alex already has a poster and a mock gameplay image generated in this style; ask him for them as reference. Record every generated or third-party asset in `CREDITS.md`.
