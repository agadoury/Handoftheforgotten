# Kickoff prompt

Paste everything below the line as your first message to Claude Code (or type: *Read prompts/01_kickoff.md and do what it says.*).

---

We're building **Hand of the Forgotten**, an original god game for my Mac, in Godot 4 with GDScript. Everything you need is in this folder.

1. Read `CLAUDE.md`, `docs/GAME_SPEC.md`, `docs/BUILD_PLAN.md` and `docs/PILOT_GUIDE.md`. Skim `docs/tuning_baseline.json`, `docs/ART_DIRECTION.md` and `docs/REFERENCE_NOTES.md`. Open `docs/pilot/index.html` and read the parts the guide points to: it's a playable prototype of the toy I've already played, and it's your behaviour reference.
2. Check the tools: print Godot's version from the path in `CLAUDE.md`, and check `git` works. If Godot isn't there, tell me and wait.
3. Run `git init` if this isn't a repository yet, and confirm `.gitignore` covers `.godot/` and `reference/openblack/`.
4. Clone openblack: `git clone --recurse-submodules https://github.com/openblack/openblack.git reference/openblack`. Re-check `docs/REFERENCE_NOTES.md` against the current source and tell me what changed.
5. Propose the Phase 0 plan: folder layout, autoloads, how `docs/tuning_baseline.json` becomes `data/`, the island generator, camera rig, the openblack pieces you'll port this phase, the tests, and how you'll take screenshots to check your work.
6. List your questions for me, including the open suggested spec changes at the end of `docs/REFERENCE_NOTES.md`.

Don't write game code yet. Wait for my OK on the plan.
