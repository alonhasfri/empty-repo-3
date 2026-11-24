# Development queue (Roblox)

The full list from the user (sent through the cloud chat on Nov 24). Work top to bottom, one item at a time.

For each item:
- Test in Studio on phone and PC.
- Text goes in Content.lua, numbers in Config.lua.
- Commit, push, save screenshots to `docs/screens/`, and add a What's new entry per release.

Never publish without the user's OK, never change permission settings, never print the API key. Tick items here as they land.

## Status key
- [x] done and pushed
- [~] partly done
- [ ] not started

## PRIORITY ORDER (user, Nov 24): build in THIS order, not by item number
Credits are low, so finish each one fully (tested, committed, pushed) before starting the next.

**Tier 1: makes the game good to play right now**
1. Item 3/16: finish and test the map, background and styles (already in progress).
2. Item 7 (part): **real music and sounds**. The game is silent now, so this is cheap with a huge effect.
3. Item 11: **Gain path fun.** Job minigames replace the work questions, and quizzes become fun facts (the user's biggest complaint).
4. Item 12: **100+ dialogue lines, with no repeats.**

**Tier 2: memorable moments and a fuller Lose side**
5. Item 10: **brain animations** (the shredder, the 0-cell POOF).
6. Item 9 (part): the **intro cutscene** only (the camera flyover to the doors), with a simple cutscene player.
7. Items 17 and 18: **more Lose places and Lose-path systems.**
8. Item 22: **real thumbnails and icon** (needed before going public).

**Tier 3: nice to have**
9. Item 6: admin panel redesign (only staff see it).
10. Items 7 and 8: townspeople and smart NPCs.
11. Item 14: the secret castle path.
12. Item 13: Perfectly Average horror part 2.

**Tier 4: later**
13. The rest of item 9 (all other cutscenes and the Cutscene Recorder).
14. Item 19 (the rest of the brain plan), item 20 (browser ports), item 21 (castle extras).
15. Item 7's rest: Blender landmarks, the multiplayer test, every phone size, the lag check.

## Queue
1. [x] **Publish** (done Nov 24, 13:35: 1.8 + styles, background, BrainTalks; private) to "brain game" (Cult of the 39) using File → Publish to Roblox As → brain game → Overwrite. Keep it private and change no settings. Take a screenshot to `docs/screens/publish.png`.
   - The user said yes on Nov 24, but the PC was locked. Do it when the user is back and the screen is unlocked.
2. [x] **UI fixes:** phone app labels, UI size, tidy buttons (`docs/UI review.md`), small merged toasts, and the "Fewer notifications" setting.
3. [~] **Map.** Done:
   - River City with Main Street
   - paved ground
   - denser filler buildings
   - realistic sky
   - day-night cycle
   - skyline ring
   - invisible edge walls
   - Low detail hides the far skyline

   - Code done Nov 24 (scheduled run, **NOT tested in Studio yet**): a 4th ring of tall downtown towers, window bands on the towers that glow at night (DayNight.lua), green hills at the back, a raised highway ring with lamps. All no-collision, no shadows, tagged FarSkyline so Low graphics hides them. Left: Studio test (part count and phone FPS), screenshots, maybe moving cars.

   Was left: a **bigger background** (skyscrapers with lit windows at night, hills, a distant highway), with screenshots in 4 directions, day and night.
4. [x] **Styles per brain level** (CLAUDE.md Art style):
   - Code done Nov 24 (scheduled run): `Config.Styles` is the one central table, `Style.lua` applies it (parts, signs, decor, light, toon outlines on the nearest 24 buildings, Low detail = the same style in smooth plastic with no outlines or decor). **NOT tested in Studio yet** (no place was open), no screenshots yet, Config.Version not bumped. Left: Studio test, screenshots, turning Low detail on automatically for weak phones.
   - 5 regular
   - 2 a bit smarter
   - 3 in warm colours for really smart
   - 4 toon for a bit dumber
   - 6 desaturated for really dumb
   - Low detail mode

   One central style table in Style.lua. Screenshots go to `docs/screens/styles/`.
5. [~] (Code done Nov 24, **NOT tested in Studio yet**: `BrainTalksService.lua`, `Stations.braintalks`, a 🎓 BrainTalks app on the Gain phone, `Config.BrainTalks`, `Content.BrainTalks`. The first brainrot watched each session is only a warning.) **BrainTalks** smart scroll for Gain players: skip brainrot, watch smart talks for a big stress drop, plus a combo meter. Server-checked. Lose players get the normal doomscroll; animals can't use it.
6. [ ] **Admin menu redesign:** a sleek dark panel with tabs, inspiration only. Keep the commands and rank checks. Before/after screenshots.
7. [ ] **Features:**
   - real music and sounds
   - townspeople
   - a multiplayer test
   - real thumbnails and an icon
   - every phone size
   - a lag check
   - Blender landmarks (installing Blender needs the user's OK)
8. [ ] **Smart NPCs**, with no live LLM:
   - routines tied to day-night
   - pathfinding
   - reactions to brain level
   - per-player memory
   - hundreds of preset lines
9. [ ] **Cutscenes**, all skippable:
   - the cutscene system
   - a Cutscene Recorder tool and a how-to
   - intro flyover
   - PROMOTED!
   - animal transform
   - IQ 200 ending
   - rocket launch
   - Crossroads Ceremony
   - Average guy turn
10. [ ] **Brain animations:** the brain shredder (confetti and paper strips). At 0 cells, the brain inflates, wobbles and goes POOF (confetti, smoke, stars; never gory), into the death ending.
11. [ ] **Gain path fun:**
    - quizzes become fun facts (books and NPCs, no test, still give cells)
    - many Jack B Movies "AI-looking" obvious-fact clips
    - job minigames replace work questions: cashier, doctor X-ray, teacher grading, scientist colours/pipes, office files (score-based, timed, server-checked)
    - Skill Gates become puzzle minigames
12. [ ] **100+ new dialogue lines,** plus a per-player "seen" history and shuffle bags across all NPCs and boxes. Save it small, with a default for old saves.
13. [ ] **Perfectly Average horror part 2.** Read `web/src/horror.js`, write the outline in `docs/` first, then build it. Kid-safe; jump scares only on Full.
14. [ ] **Secret castle path.** Concept pictures are in `docs/secret_castle/` (git pull first).
    - **Konami code:** ↑↑↓↓←→←→ with arrows, WASD, a D-pad, or 8 swipes in 5 s on phones.
    - **Admin House:** gives no powers; the server checks the rank. A "don't jump" hole in the floor.
    - **Void → White Room:** you can't die in the fall. A "please $1" box takes 1 in-game coin, never Robux, and shows the price first.
    - **Obby:** checkpoints, phone- and animal-friendly.
    - **Giant empty Admin Castle:** only a bed and a lamp. Stay 5 minutes; leaving resets the timer.
    - **Infinite Castle:** walk the rooms in the Konami pattern (2 forward, 2 back, L, R, L, R). A wrong move silently resets it. Hints: a painting and a humming knight.
    - **Secret Admin Room:** the Castle Map teleport and the existing WhereAmI badge.
    - **Rules:**
      - Rename the microbe badge to "Microscopic" and keep its save key.
      - Rewards are given once and checked by the server.
      - Unstuck works at every stage.
      - What's new gets a hint only: "Some castles are bigger on the inside…".

## Added Nov 24 (cloud chat): everything else the user asked for that isn't built yet
16. [ ] **Finish and test what's marked [~]:** the map background (item 3), the styles (item 4, plus screenshots and automatic Low detail), and BrainTalks (item 5). Test each in Studio and take screenshots.
17. [ ] **More free Lose-side places** from `docs/Life Pack and Phone Shop plan.md`. Only 3 of 9 exist so far. Still to build:
    - Fidget Store
    - Brainrot Café (rainbow mystery drinks)
    - Prank Shop
    - Influencer Studio (record dumb videos for "views")
    - Drive-thru
    - Claw Machine Arcade (in-game coins only, exact odds)
18. [ ] **The Lose path's share of the brain-scaled systems** (panel round 1, open item #10):
    - joke jobs
    - a piggy-bank toy bank
    - a wobbly-GPS bus
    - more dumb-only shortcuts
19. [ ] **The rest of the brain-scaled plan** (`docs/Brain scaled UI and map design.md`):
    - a cozy-tier bus timetable
    - investing at fixed, shown rates at the fancy tier (never casino-like)
    - a hologram HUD at IQ 200+
    - a guide NPC per district
20. [ ] **Port the rest of the browser-only features:**
    - the interactive world (`web/src/interact.js`)
    - glasses bought with coins at the Optician
    - any browser job minigames not covered by item 11
21. [ ] **Castle extras from the memory file:**
    - the mirror room
    - the Perfectly Average lobby copy
    - The working time-machine room stays ON HOLD with time travel.
22. [ ] **Real Roblox thumbnails and icon from the game:** after the map and styles are tested, photo-mode shots (day, sunset, both sides) in Roblox sizes, saved to `marketing/`.

## ON HOLD (user)
- **Time travel:** ON HOLD. Don't build the time travel update or expand the Time Machine secret project; the user will design it later. Leave the always-failing "⏳ Time Machine" secret project (the "Maybe Next Time" badge) and the "Pocket Time Machine" rewind gadget as they are.

15. **Needs the user:**
    - Playtester role: already set up by the user. Don't touch group roles.
    - Pass and badge IDs: the user adds them after publishing.
    - Free chat: leave as it is for now.
    - CLAUDE.md edits: ask first.
