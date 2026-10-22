# Start here

This folder is everything Claude Code needs to build **Hand of the Forgotten** in Godot on your Mac mini: the game spec, the build plan, the playable pilot as a reference, every tuning number, the openblack notes, the art direction, and the prompts to paste. You set things up once, paste one prompt, and from then on your job is to play each build and say what to change.

## 1. Install Godot

1. Go to [godotengine.org/download/macos](https://godotengine.org/download/macos) and download the latest **Godot 4** (4.7.x as of October 2026), the standard version, not .NET.
2. Unzip it and drag **Godot.app** into **Applications**.
3. Open it once. If macOS blocks it, go to System Settings → Privacy & Security and click Open Anyway.

Claude Code expects it at `/Applications/Godot.app`. If you put it somewhere else, tell Claude Code the path on day one.

## 2. Install Claude Code

Open **Terminal** and run:

```bash
curl -fsSL https://claude.ai/install.sh | bash
```

Then open a new Terminal window and check it worked:

```bash
claude --version
```

(With Homebrew you can run `brew install --cask claude-code` instead.) Claude Code needs a Pro or Max plan. It also runs inside the Claude desktop app if you'd rather avoid the terminal; point it at this folder.

If macOS offers to install "command line developer tools" the first time something uses `git`, say yes.

## 3. Open the project

Keep this folder at `~/Code/hand-of-the-forgotten`, then in Terminal:

```bash
cd ~/Code/hand-of-the-forgotten
claude
```

Log in when it asks (first time only).

## 4. Paste the kickoff

Paste the prompt from `prompts/01_kickoff.md` (everything under the line). Claude Code will read the docs, check Godot, clone openblack for reference, and come back with a plan for Phase 0 and some questions. It won't write game code until you say OK.

When it asks to run commands, it will ask permission. Approving Godot and git commands for this project saves a lot of clicks.

## 5. The loop for every phase

1. Claude Code proposes a short plan; you answer its questions and approve.
2. It builds, tests and checks its own screenshots, then gives you a five-line summary and how to try it.
3. You open Godot (or run the game from Terminal as it tells you) and play it. Compare it with the pilot.
4. You give concrete feedback; it fixes; you approve.
5. Type `/clear` and paste the "Start the next phase" prompt from `prompts/02_during_the_build.md`.

There are 7 phases (0–6) before the fun check. After Phase 6 you play for a week, then decide together what Milestone 2 becomes.

## What's in here

| File | For | What it is |
| --- | --- | --- |
| `START_HERE.md` | You | This page |
| `CLAUDE.md` | Claude Code | Its standing instructions; it reads this at the start of every session |
| `docs/GAME_SPEC.md` | Both | The game design, updated with everything the pilot proved |
| `docs/BUILD_PLAN.md` | Both | Milestones and phases, each with a "done when" test |
| `docs/pilot/index.html` | Both | The playable pilot (version 7); open it in a browser to compare |
| `docs/PILOT_GUIDE.md` | Claude Code | Where each system lives in the pilot's code, and what it fakes |
| `docs/tuning_baseline.json` | Claude Code | Every number from the pilot, to seed the game's data |
| `docs/REFERENCE_NOTES.md` | Claude Code | What to study and port from openblack |
| `docs/ART_DIRECTION.md` | Both | Colours, fonts, shapes and the creature's look |
| `prompts/01_kickoff.md` | You | The first message to paste |
| `prompts/02_during_the_build.md` | You | Short messages for each step after that |
| `.gitignore` | Claude Code | Keeps Godot's cache and the openblack clone out of git |

## Good habits

- **Play every phase before approving it.** The pilot proved the toy is fun; your job is to make sure the Godot version feels at least as good.
- **Be specific.** "The hand lags when I drag fast" gets fixed; "feels off" gets guessed at. Drag screenshots into the terminal.
- **One phase per conversation.** `/clear` between phases keeps Claude Code focused; the docs carry the memory.
- **Git is your undo button.** Claude Code commits at every working step, so you can always go back.
- **New ideas go in `IDEAS.md`,** so they don't derail the current phase.
