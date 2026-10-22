# Prompts for the rest of the build

Short messages to paste at each step. Swap in the phase number. Start a fresh conversation for each phase (type `/clear`); Claude Code re-reads `CLAUDE.md` every time, and the docs carry everything else.

## Approve a plan

> Plan approved. Go ahead with Phase N. Match the pilot wherever the spec is silent, check your work with rendered frames, and finish with tests, docs, a commit and the end-of-phase report.

## Start the next phase (fresh conversation)

> Phase N−1 is approved. Update "Current phase" in `docs/BUILD_PLAN.md`, read the Phase N brief and the docs it needs, look at how the pilot does it, then give me a short plan and your questions before building.

## Give feedback after playing

> I played Phase N. What worked: … What felt wrong: … Bugs: … Fix these before we move on, and tell me what you changed.

Be concrete: "the hand lags behind the cursor when I drag fast" helps more than "the hand feels off". A screenshot dragged into the terminal helps even more.

## Compare with the pilot

> Open the pilot's code for [system] and compare it with ours. List every behaviour or number that differs, say which differences are improvements, and fix the rest.

## Ask for a tuning change

> Make [thing] [faster / rarer / stronger] by about [amount]. Change only `data/`, tell me the old and new values, and add the reason to `DESIGN.md`.

## When something breaks

> [What I did] → [what I expected] → [what happened]. Reproduce it with a test or a seed first, then fix it, then show me the test passing.

## When a session runs long

> Summarise where we are in this phase in `CHANGELOG.md` (done, in progress, next steps, open questions) and commit, so the next conversation can pick it up.

## The fun check (after Phase 6)

> Milestone 1 is done. I'm going to play for a week. Make me a one-page `PLAYTEST.md` checklist of what to try and what to notice, based on the pillars in the spec. Then stop.

And after the week:

> Here are my playtest notes: … Propose what to cut, change or double down on for Milestone 2, update `docs/GAME_SPEC.md` and `docs/BUILD_PLAN.md` once I agree, and log the decisions in `DESIGN.md`.
