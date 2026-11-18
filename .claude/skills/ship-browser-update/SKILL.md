---
name: ship-browser-update
description: Release recipe for the browser version of "Lose a Brain Cell / Gain a Brain Cell". Use whenever a change to web/src is finished and should go live. It builds, play-tests on phone and PC sizes, publishes the artifact, commits and pushes to GitHub, and updates CLAUDE.md and the memory file.
---

# Ship a browser update

Run every step in order. Don't skip testing, and don't report "done" until every test passes.

1. **Back up first.** If the change is big, commit the current state before editing (`git commit -am "backup before <change>"`).
2. **Build.** Run `python3 web/src/build.py`. It writes `web/lose-a-brain-cell-web.html`.
3. **Syntax check.** Pull the last `<script>` block out of the built HTML into a temporary `.js` file and run `node --check` on it.
4. **Play-test.** Run each test in `web/tests/`: `node web/tests/test10.js` (core), `test14` (content), `test15` (interactive world), `test16` (horror story), `test18` (polish pack), `test19` (save edge cases).
   - Every test must end with `no errors` (test19: every line must say `PASS`).
   - If a test fails because a feature changed on purpose, update the test. Otherwise fix the game.
   - Look at the screenshots in `web/tests/shots/` at phone size (420×820).
5. **Publish.** Publish `web/lose-a-brain-cell-web.html` with the Artifact tool to the existing URL https://claude.ai/artifact/9dkh8TK9DFDEPFX8KX2uku, so the link stays the same.
6. **Save to GitHub.** Commit with a clear message and push the branch.
7. **Write it down.** Update `CLAUDE.md` (versions, files, rules) and the memory file Claude Doc ("Memory File: Lose a Brain Cell / Gain a Brain Cell") with what changed and why.
8. **Tell the user** what changed, in plain words, and what to try first.
