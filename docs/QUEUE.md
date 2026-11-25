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
4a. **Full Hebrew support** (user, Nov 24; after the UI and map fixes):
    - a language choice in Settings (English / עברית)
    - all of Content.lua in natural, kid-friendly Hebrew, keeping the parody names
    - right-to-left layout: right-aligned text, mirrored phone grid and conversation choices, numbers shown correctly
    - fonts that render Hebrew, and no overflow on phones
    - saved per player: English by default, Hebrew if the player's locale is he
4b. **UI pictures:** screenshots of every screen (HUD, phone tiers, Settings, shop, conversation, animal menu, notifications) in English and Hebrew, at phone landscape and PC sizes, saved to docs/screens/ui-final/.
4c. **Tester feedback: more interactive, clear goals** (Nov 24). The tester wants a button right next to Phone and Library that gives multiple-choice questions and points, and a clear sense of what you're achieving.
    - **⚡ Quick Play button** in the main button block:
      - one tap starts 3–5 multiple-choice questions with big tappable answers, a timer bar, instant ✅/❌ feedback with a short fun fact, then points
      - Gain path: points become brain cells
      - Lose path: the "dumb" answer wins
      - animals: an icon-only version (pick the right picture)
      - optional, and it doesn't replace the fun-facts/minigames plan
      - server-checked, with shuffle bags so questions don't repeat, and Hebrew-ready
    - **Clear progress:**
      - a small always-visible goal line with a progress bar ("Next: IQ 120 → new city look 🏙️", "3/5 to promotion")
      - a streak / daily goals panel (3 simple daily tasks with rewards)
      - a sound and a number pop on every reward
      - no centre banners
    - **Test:** a new player on a phone knows what to press and gets their first points within 30 s. Screenshots go to docs/screens/ui-final/.
4d. **Better tutorial** (user, Nov 24): short, interactive, learn by doing.
    - Under 60–90 s and skippable.
    - One action per step, with an arrow on the real button: pick a door → ⚡ Quick Play (answer one question) → open the Phone → walk to one place → watch the brain counter change.
    - One-line texts, a big friendly guide, Hebrew-ready, a reward at the end.
    - Separate short versions for Lose, Gain and the Life Pack baby start.
    - Teaches the goal line, the progress bar and the daily tasks.
    - Replayable from Settings.
4e. **HUD leftovers** (from docs/screens/fix-1124/hud_after_iq213.jpg):
    - SHOP and MAP become small icon buttons, the same size as the ⚙️/🛠/SOS row.
    - The job/glasses tag moves into the profile card or goes.
    - The bottom "stress • Overflow" line gets slimmer, or hides when it isn't relevant.
    - The Dr. Wrinkles card title is easier to read.
4f. **Player feedback on a phone** (Nov 24):
    - **"Reset my progress" in Settings:**
      - warning text: what resets (cells, path, coins, job, items) and what stays (badges, Robux purchases)
      - press, then hold a red button for 3 s, then an "Are you sure?" step
      - server-side, with a 24 h cooldown and the old save kept as a backup key for 7 days
      - returns the player to the door choice; Hebrew-ready
    - **"UI looks janky":** one design kit everywhere (one font, 2–3 text sizes, one button style, one panel style, 8 px spacing); no cut-off text, no elements touching edges, everything on a grid, no jumpy tweens. Covers HUD, phone, shop, settings, conversations, minigames and admin.
    - **"Pop-ups too big":**
      - modals capped at about 65% of the screen on phones (smaller on PC); full screen only for the phone and cutscenes
      - reward and info pop-ups become toasts
      - no surprise pop-ups while moving; queued, one at a time
      - always a ✕, tap-outside-to-close and back
      - list every pop-up and shrink or convert each one
    - Before/after phone-landscape screenshots go to docs/screens/ui-final/. Keep each publish stable.

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
3. [x] **Map.** (1.8.2: street dressing, pitched roofs, flower boxes, striped awnings, bunting; auto Low detail; tested in Studio on PC; phone size and night screenshots not done) Done:
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

## Publish log
- Nov 24, 13:35: 1.8 + styles, background, BrainTalks (private)
- Nov 24, 14:28: 1.8.3 (1.8.2 Busy Streets + 1.8.3 Tidier screen), private. Save check: only new field settings.lowGraphicsChosen (nil for old saves); no keys renamed or removed.
- Nov 24, 14:40: 1.8.4 Warm Genius Town, private (the user clicked Overwrite; confirmed "Successfully published!"). No save changes.
- Nov 24, 17:20: 1.8.5 Cleaner Screen + Quick Play (the user clicked Overwrite; confirmed by the API). No save changes. Note: brain game became Public at 17:02 (not by Claude), audience "Ages 16+ and trusted friends". Content rating resubmitted (Social Hangout and Free-form set to No; preview Minimal).
- Nov 24, 17:27: 1.8.6 New Staff Panel (public game, Ages 16+). No save changes.
- Nov 24, 17:36: 1.8.7 Phone Fixes (Skill Gate answers, landscape phone, Set Brain Cells back in admin). The user clicked Overwrite; confirmed by the API. No save changes.
- Nov 25, 16:08: 1.8.8 Bigger Town + Unstuck (the user clicked Overwrite; API updateTime 14:08:29Z, before any 1.8.9 edits). No save changes.

## Next (user order, Nov 24)
1. [x] **Admin menu redesign** (item 6, done in 1.8.6) to docs/admin_panel_mockup.png:
   - dark panel with left tabs, search, player cards with rank badges, quick actions, sliders/toggles
   - red confirms for dangerous actions
   - shows only the commands the viewer's rank allows; server checks stay
   - phone landscape; Hebrew-ready
2. **Full phone pass** of every screen (BrainTok/BrainTalks swipe feeds first): touch swipes, 44 px targets, nothing off-screen or under the thumbstick/jump button, touch-scrollable lists. Write docs/Phone check.md with ✅/❌ and screenshots in docs/screens/phone/.
3. **Hotfix 1.8.7** (Skill Gate answers, phone fixes): pushed; publish pending (the user clicks Overwrite).
3a. **Skill Gates become easy fun-fact gates** (user decision, Nov 24; same hotfix as the stuck fix; replaces the "puzzle minigame gates" plan).    - **Format:** 3 short facts per gate, one at a time, each with an emoji and a fun line, then one very easy question about the fact just read, with 2–3 big answer buttons.    - **No pressure:** no timer pressure, no stress added, no cooldown. A wrong answer shows the fact again for a retry.    - **Reward:** a big GATE PASSED moment with the badge and confetti.    - **Content:** keep the tiers with themed facts (body and brain, space, animals, inventions, coding, myths); 40+ new kid-friendly facts in Content.lua, Hebrew-ready, with shuffle bags.    - **Old trivia** moves to Quick Play. Update the tutorial note about "real questions".    - **Ship:** server-checked; test on phone; What's new: "Skill Gates are now fun-fact gates, easy and fun!"
3b. **HIGH PRIORITY: "sometimes you get stuck and can't move"** (phone).    - Audit every movement lock: WalkSpeed/JumpPower 0, anchored root, controls disabled, Sit, PlatformStand, scripted camera.    - Sources to check: stress freeze, conversations, cutscenes, tutorial, seats, Hoppr/bus, school, jail/freeze, animal forms (rock), shifts/minigames, castle, teleports, Quick Play, phone, modals.    - Every lock gets an owner and a timeout, releases on death/respawn/close, and shows why you can't move.    - A client watchdog restores movement if you're stuck outside a known lock; Unstuck clears all locks.    - Reproduce with the phone simulator, then hotfix: "Fixed: sometimes you couldn't move".
    - Start with the Skill Gate: gate_start adds +10 stress and a fail adds +15, so repeated (wrongly marked) fails can freeze the player. Check that every way of closing the gate UI (timer, auto-submit, tap outside) restores movement, check the Exam Hall for traps, and make sure a failed gate can't freeze anyone.
4. **Admin panel on phones + one shared fit helper** (user: "EVERYTHING should fit mobile"):
   - the admin panel clamps to the safe area and collapses the tab bar to an icon rail on small screens; players and actions become one column with a back button
   - add `UI.fitPanel(frame, opts)` (safe-area clamp, phone scaling, scrollable content) and use it for every panel and pop-up
   - fill in docs/Phone check.md with ✅/❌ and screenshots in docs/screens/phone/
4b. **Animations** (user: "Now do the animations"; right after the hotfixes and the mobile fit):    - **3D Brain Shredder for bans:** gears, teeth and glowing lights; the brain slides in, shakes and comes out as confetti and paper strips; keeps the BANNED stamp with the moderator name.    - **0-cell POOF:** the brain swells, wobbles and squeaks, then a cartoon POOF (confetti, smoke, stars, boing; never gory) fades into the existing ending.    - **Intro flyover cutscene** to the two doors, with a skip button, built on a small reusable cutscene player (camera keyframes, letterbox, fade).    - All of them respect the Effects slider and Reduced Motion, are smooth on phones, and get screenshots in docs/screens/animations/.
5. **More debug commands** in the 🧪 Testing tab: pass all gates, set IQ / brain band / style, life stage + Crossroads, job/promote, unlock inventions/projects, test badges, stress/coins/bank, time of day + weather, teleports (buildings, Moon, castle stages, horror spots), horror stage, play cutscene, FPS/part overlay, daily tasks, refill Quick Play, reset seen lines, become an animal. Testers on themselves only; Head Mod+ on others; all server-checked and logged.
6. **💬 Send feedback** button (Roblox's built-in feedback prompt; check the current API before using it; pcall plus a friendly toast if unavailable).
7. **Settings redesign** in the staff-panel style: tabs (Sound, Graphics, Controls & Screen, Notifications, Language, Gameplay, Info, Feedback, Danger zone with hold-to-confirm reset, Help), big toggles, search, remembers the last tab, phone landscape first.
8. **"UI is really bad"** (user, Nov 25; hard to say why, so Claude should find out). Likely causes to check first:
   - mixed styles (cash-grab gradients and thick outlines next to the dark admin style)
   - too many corners and borders
   - inconsistent sizes
   - crowded edges
   - toasts and goal lines competing for the top
   Plan: one calm design kit (like the new admin panel) for the HUD, pop-ups, phone and Settings, with bigger touch targets and text, then before/after screenshots.

## Coded but NOT tested yet (test all of these together after the usage reset, then publish)
- 1.8.9 easy fun-fact Skill Gates (40 facts in Content.GateFacts; gate UI shows the fact above each question; 5-minute timer)
- Phone fit: pop-ups 80% x 88% on phones; staff panel icon rail on phones, rank in the title
- Test commands: Pass ALL Skill Gates, Set IQ
- Delete Player Data fix (no leave-save after the wipe) and Settings → Reset my progress (hold 3 s, once a day, 7-day backup)- POOF animation before the 0-cell ending; Brain Shredder upgrade (gears, teeth, lights, paper strips and confetti)
Before publishing: bump Config.Version to 1.8.9 and add a What's new line ("Skill Gates are now fun-fact gates, easy and fun!").
9. **Gain path redesign** (user idea, Nov 25), full plan in docs/Gain path redesign.md:
   - a clear progress path strip
   - a different real minigame for every job (no maths)
   - "Choose your genius" branches (math, physics, coding, business, chess), each with its own jobs, minigame and storyline
   - random story events from shuffle bags
   This comes right after the UI overhaul.
0. **TOP PRIORITY: real visual quality** (user, Nov 25: "the concept is very good, but the gameplay, map and UI feel really bad"). Root cause: everything is code-built (emoji icons, flat boxes, code-made buildings), with no real art assets.
   1. Pick ONE reference game (Grow a Garden or Pet Simulator 99, for inspiration only) and copy its HUD structure: a currency card top-left, 3–4 big round side buttons, one panel style, big chunky numbers.
   2. Real UI art: one consistent icon pack (a free licensed Creator Store kit, or icons generated with Studio's AI tools), one panel image that stretches to any size, a custom display font.
   3. Cut the HUD to the essentials: brain count, 3–4 buttons and the goal line. Everything else goes in the phone or a menu.
   4. Map: replace the code-made buildings, cars and trees with real 3D models from the Creator Store (scripts stripped), keeping the street layout.
   5. Have the fresh UI judge compare before/after screenshots against the reference game until it says the gap is gone.
   6. **Phone = the main menu** (target look: docs/reference/phone_target.jpg, a life-sim style phone):
      - a tall phone on the right side of the screen, glossy picture icons with a label under every one, a dock at the bottom, a status bar
      - apps: Items (inventory, where ALL gadgets and secret inventions go), Jobs/Shifts, Map/Hoppr, Shop, Settings, BrainTalks/BrainTok, Bank, Badges, Help
      - only a few contextual buttons stay on the screen (things that can't live in the phone, like Unstuck or Quick Play)
      - icons are real images (see "How real art gets in" below), not emoji

### How real art gets in
- **UI icons and panels:** PNG images. The user (or an AI image tool) makes them, and the Creator Store has free licensed UI kits. Claude uploads them with the Open Cloud key (it has asset write access) and wires them in as ImageLabels/ImageButtons. Panels use 9-slice images that stretch to any size.
- **3D models:** Claude searches the Creator Store from Studio (search_asset/insert_asset), strips any scripts, and the town builder places them (houses, shops, cars, trees, lamps) instead of code-made blocks. Blender is optional (needs the user's OK to install).
