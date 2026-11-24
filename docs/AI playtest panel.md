# AI playtest panel (1.7, Nov 24 2026)

Four pretend players tried the Roblox game in Studio (iPhone 17 Pro size and PC size).

**Note about screenshots:** the Studio game window was minimized and screen control was declined, so screenshots came back blank this time. The flows below were run live through the game's own remotes and their real results were read back. The screenshots from the 1.7 morning test (phone layout, Hoppr, toy phone, animal menu) still apply.

## The panel

| Persona | Who | Rating | Best moment | Worst moment |
|---|---|---|---|---|
| Mia | 8, phone, Lose path, reads slowly | 3.5 / 5 | Toy phone with silly icons, the joke ads | Small text on the phone; once she becomes a dog, the phone only shows 👃 ⚡ 🏠 and she can't find the Lose apps again |
| Leo | 13, PC, Gain path, wants coins fast | 3 / 5 | Promotions and report cards | Found he gets paid for doing nothing: job wages while AFK, an idle shift bonus, and the bank beats every job. The free map taxi makes Hoppr pointless |
| Pip | a dog (1B cells), on the phone | 3 / 5 | The bark and smell trail | Nothing to do as a dog except sniff to places; no way back to the stands that change cells |
| Sam | a parent checking safety and money | 4 / 5 | Prices and odds shown before paying, no debt, preset text only | "Skibidi" (a real brand) appears in 7 places, including a "Skibidi Plushie" |

## What the panel proved live

- **Wages while idle (Leo):** took the Cashier job, stood 300+ studs from work, not clocked in. Coins went from 51 to 63 in one minute. (Audit G2: confirmed.)
- **Shift with zero tasks (Leo):** clocked in at the Supermarket, did nothing for 62 s, clocked out. Payslip: 0 tasks, 6 coins wages. The code also pays the +15 on-time bonus with 0 tasks. (Audit G3: confirmed.)
- **Bank (Leo):** 2% every 10 minutes, shown honestly, but it compounds and pays on whatever is saved at the moment of the tick. (Audit G4: confirmed in code.)
- **Clock-in far from work** is refused correctly.
- **Dog menu (Pip):** the sniff list only has map places, not the four Lose stands. (Audit G5: confirmed.)
- **Brand words (Sam):** `Content.lua` lines 53, 93, 563, 567, 579; `Props.lua:205`; `SocialService.lua:796`. (Audit K1: confirmed.)

## One merged list, most severe first

Panel findings merged with `docs/Flaws found.md` (31 audit items). Status is updated as fixes land.

| # | Flaw | From | Severity | Status |
|---|---|---|---|---|
| 1 | "Skibidi" brand in 7 places (Roblox IP rules) | K1, Sam | High (moderation risk) | Fixed |
| 2 | Job wages paid while not working | G2, Leo | High | Fixed |
| 3 | Shift on-time bonus pays for idling | G3, Leo | High | Fixed |
| 4 | Bank beats working; move-in-before-tick trick | G4, Leo | High | Fixed |
| 5 | Phone minimum sizes (48 px / 14 pt) shrunk by device scale | U1, Mia | High | Fixed |
| 6 | Free instant map taxi makes Hoppr and walking pointless | G1, Leo | High | Fixed |
| 7 | Dogs lose access to the Lose stands | G5, Pip, Mia | Medium | Fixed |
| 8 | Hoppr arrival yanks you out of a seat or conversation | R1 | Medium | Fixed (seat tested live; conversation case checked in code only) |
| 9 | Effects slider misses the wobble and text scramble | Plan 3 | Medium | Fixed |
| 10 | Lose path got almost nothing in 1.7 (bus, joke jobs, piggy bank) | G6 | Medium | Open (feature work) |
| 11 | Bills toast "paid 0" every tick | G7 | Low | Fixed |
| 12 | Joke ad has two UIScales | U4 | Low | Fixed |
| 13 | Text outside Content.lua (car names, quiz/election lines) | R3 | Low | Fixed |
| 14 | Coffee / astronaut / quiz trust the client | E1–E3 | Low | E1, E2 fixed. E3 kept on purpose: showing the right answer after a wrong one helps kids learn |
| 15 | Rainbow loop runs forever | P1 | Low | Fixed (idles when not shown) |
| 16 | Old BRAINVILLE sign inside the Brain Tower | P2 | Cosmetic | Fixed (removed) |
| 17 | Thumbstick-zone bar check, speed-pass collision check | U5, R2 | Low (check in Studio) | Open: needs the Studio window visible |
| 18 | Plan gaps: GPS lines, district NPCs, animal-only paths, hologram HUD, investing, timetable | Plan 4–9 | Feature work | Open |

U2 (icons wider than cells) and U3 (two status bars) were already fixed in the 1.7 morning test.

## How each fix was tested (Nov 24)

All in Studio play mode, reading real results back from the game. The Studio window was minimized, so there are no screenshots and on-screen buttons couldn't be pressed.

- **Wages:** away from work and not clocked in, coins stayed 69 → 69 for a minute. Clocked in at the Supermarket: 69 → 75.
- **Shift bonus:** clocked in on time, did 0 tasks, clocked out after 62 s. Bonus 0 (used to be +15).
- **Bank:** the rate shows 0.5%, and saving and taking out still work. The interest tick itself (every 10 min) was not waited for.
- **Phone sizes:** at phone scale 0.70, buttons are 69 px before the shrink (48 on screen) and text is 20 (14 on screen).
- **Bus:** the first tap says 20 s, a second tap shows the countdown, the player arrives 140 studs away after 20 s, then there's an 8 s cooldown.
- **Seat:** called the bus while seated. The player stood up and travelled, and the chair stayed in place.
- **Animals:** as a dog, the 🐾 menu shows 👃 🛍 🏠. The trail to the 📰 stand points at the right spot. All four stands were found.
- **Effects slider:** checked scramble levels at full, half and off. Full: "welcom 2?". Half: "welcom 2 da library u are readin 4 fun". Off: normal text.
- **Coffee:** sending 60 without opening, or instantly, gives no relief. After 9 s it works.
- **Output:** no red errors after any fix. The code checker is at its usual baseline (2 old errors, 43 warnings).

## Still open

- **#10 Lose path for 1.7:** joke jobs, a piggy-bank toy bank, and a wobbly-GPS bus. This is feature work, not a fix (the free bus now serves both paths).
- **#17:** needs the Studio window visible to check.
- **#18:** plan gaps (GPS lines, district NPCs, animal-only paths, hologram HUD, investing, bus timetable).
- **Conversation + Hoppr refund:** checked in code only. Starting a conversation needs the window visible.

---

# Panel 2 (Nov 24): 10 players in 3 rounds

The Studio window was still minimized, and screen control was declined twice, so screenshots couldn't be taken. Every player was run through the game's own remotes, and the real results were read back. Ratings are fun / looks / ease / clarity (1–5). Looks are rated from the earlier 1.7 screenshots and the code.

## Round 1: everyday players and phone checks

| Player | Fun | Looks | Ease | Clarity | Best moment | Worst moment |
|---|---|---|---|---|---|---|
| Mia, 8, phone, Lose | 4 | 4 | 3 | 3 | Wobbly cash-grab HUD and joke ads | ⚙️ 🛠 🆘 buttons were 34 px and the pass buttons 28 px on a small phone: hard to hit |
| Leo, 13, PC, coins fast | 3 | 4 | 4 | 4 | Promotions and payslips now feel earned | Found conversation scenes paid 30–40 coins every time with a 3 s wait (~70/min, more than any job) |
| Sam, parent | 4 | 4 | 4 | 4 | Prices on every pass button, no debt, 0.5% bank rate shown | Roblox's free-typing chat is on, which conflicts with the "preset text only" rule (see decision below) |
| Cheap-phone player | 3 | 3 | 3 | 3 | Light map: 4,300 parts, no shadow-casting lights, every billboard has a draw distance | HUD buttons too small (same as Mia). The IQ chip text was about 8 px |

**Measured:** at the smallest phone scale (0.70), 11 HUD buttons were under 44 px and 1 label was under 14 px. After the fix, 0 and 0.

**Fixed in round 1:**
- HUD buttons (⚙️ 🛠 🆘, activity icons, 🛒 SHOP / 🗺 MAP, pass buttons) and the IQ/coin chips are sized so they're still 48 px and 14 pt after the phone shrink.
- Conversation scenes pay coins at most once per scene every 10 minutes. Brain-cell rewards are unchanged.

**Decision for the user, not changed:** Roblox's own chat (free typing, filtered by Roblox) is on, and the game has an admin mute for it. CLAUDE.md says "preset text only". Turning chat off is a product decision, so it's left as is.

**Players' ideas:** Mia wants a big "what do I do now?" arrow. Leo wants a weekly pay leaderboard. The cheap-phone player wants a "low graphics" toggle that turns off the street lights.

## Round 2: the breakers

| Player | Fun | Looks | Ease | Clarity | Best moment | Worst moment |
|---|---|---|---|---|---|---|
| Speedrunner | 3 | 4 | 3 | 3 | Skill Gates stop runaway gains, so there's no cheap IQ 200 skip | The fastest route is repeating the same conversation scene for brain cells (3 s wait). Coins are capped now, cells are not |
| Hacker | 2 | 4 | 3 | 3 | Every remote is rate-limited (25/s), wrapped in pcall, and non-table args are thrown away; 254 quiz spams gave +0 cells | **Infinite money:** `bank_move` with NaN, then 1e308, gave NaN coins and 1e308 savings |
| Completionist | 4 | 4 | 3 | 3 | All 23 badges have code that awards them (Gate1–4 included) | Badge IDs are still 0, so nothing shows on the Roblox badge page yet |

**Hacker run (live):** 68 remotes were each hit with 6 bad payloads: nil, a string, a number, negative and huge values, NaN with a 5,000-letter key, and 1e308. Results:
- No server errors.
- Brain cells unchanged.
- Only the bank broke.

**Fixed in round 2:**
- The bank refuses NaN, infinity and amounts over 1e9 (`Config.Life.Bank.MaxMove`).
- Settings refuse NaN and infinity (an `isNum` check in `Main.server.lua`).
- Saves already broken by this exploit are repaired on load (NaN or huge coins and savings become 0). The test account was repaired from NaN coins to 0.
- Retested: 12 bank attacks (NaN, 1e308, -5, infinity, "9e999", 1e10, each save and take) were all refused. Coins and savings stayed 0.

**Still open:** conversation scenes still give brain cells on every repeat (the speedrunner route). It's a design choice: cells for talking is learning, but a 10-minute limit like the coins one would stop the loop.

**Players' ideas:** the speedrunner wants an in-game speedrun timer with a "Speedrun" badge leaderboard. The completionist wants a badge checklist in Settings that shows locked badges with hints.

## Round 3: content and social

(The "YouTuber playthrough" player was dropped at the user's request. The Brainrot YouTuber also answers its two questions.)

| Player | Fun | Looks | Ease | Clarity | Best moment | Worst moment |
|---|---|---|---|---|---|---|
| Brainrot YouTuber ("I SPENT 10,000 ROBUX TO BECOME A GENIUS!") | 3 | 4 | 4 | 4 | Every pass shows "R$ price for: effect" before the purchase prompt. Passes are jokes or small boosts and never help with Skill Gates | There's nothing to spend 10,000 Robux on: every pass ID is still 0, so the video can't happen. Not pay-to-win, which is good |
| Horror fan | 2 | 3 | 3 | 2 | The Perfectly Average guy's "exactly 86,000,000,000" line | The whole "Average Files" story is still browser-only. In Roblox he was one line under a big name sign that spoiled the secret |
| Friends (2–3 players) | – | – | – | – | Not run | Studio's multi-player test (Clients and Servers) can't be started from the tools, and the window is minimized |

**Brainrot YouTuber:**
- **Rating for keeping viewers in the first 10 minutes:** 3/5.
- **"Wow" and clip moments:**
  - The door choice (smart vs dumb).
  - Turning into a dog and seeing the world from dog height.
  - The loud death ending at 0 cells.
  - The rocket launch to the Moon.
  - A 🛍 smell trail as a dog.
  - Getting PROMOTED!
- **Thumbnail:** the player half human, half dog in front of the Brain Tower, with "I LOST 86 BILLION BRAIN CELLS".
- **What would keep viewers:** a faster first "wow" (the first 2 minutes are mostly reading), and a visible brain-cell counter that drops in big jumps.

**Horror fan:**
- **Creepiness:** 1/5 before, 2/5 now.
- **Kid-safety:** 5/5. Nothing gory, no jump scares.

**Friends:** checked in code only.
- Hoppr is one rider per car (no group rides).
- Vs Mode and activities use preset choices only.
- The real multi-player desync test still needs the user to press Test → Clients and Servers with the window open.

**Fixed in round 3:**
- The Perfectly Average guy has no name sign any more: he's a plain grey "Someone".
- Each visit he says the next of six slowly creepier lines (`Content.AverageGuy`, kid-safe).
- Tested: the prompt exists, no spoiler sign is left, no errors. The lines themselves need the window visible to trigger the prompt.

**Players' ideas:**
- The YouTuber wants a "first 60 seconds" hook (an instant mini brain-drop or brain-boost on spawn) and a big on-screen counter during drops.
- The horror fan wants the browser's "Average Files" side plot ported next.
- The friends want group Hoppr rides and a two-player Vs Mode lobby sign.

## Panel 2 summary

**Ratings (fun / looks / ease / clarity):**

| Player | Fun | Looks | Ease | Clarity |
|---|---|---|---|---|
| Mia | 4 | 4 | 3 | 3 |
| Leo | 3 | 4 | 4 | 4 |
| Sam | 4 | 4 | 4 | 4 |
| Cheap phone | 3 | 3 | 3 | 3 |
| Speedrunner | 3 | 4 | 3 | 3 |
| Hacker | 2 | 4 | 3 | 3 |
| Completionist | 4 | 4 | 3 | 3 |
| Brainrot YouTuber | 3 | 4 | 4 | 4 |
| Horror fan | 2 | 3 | 3 | 2 |
| Friends | not run | | | |

**Fixed (1.7.2):**
- Thumb-sized HUD on small phones.
- Conversation coins once per 10 minutes.
- The NaN/infinity bank exploit, plus repair of broken saves.
- NaN-proof settings.
- The secret Perfectly Average guy.

**Left:**
- Free chat vs the "preset text only" rule (the user's decision).
- Conversation brain-cell repeats.
- Badge and pass IDs are still 0.
- Port the horror side plot.
- The friends/desync test.
- The 1.7 Lose-path features.
- The plan gaps.

---

# Round 1 ideas built (1.7.3 work)

- **"What do I do now?" guide:** a goal line at the top plus a glowing arrow over your head pointing to the next useful place. It covers each path, IQ, job, shift and animal stage. Settings → 🧭 to hide it.
  - Tested: Gain → Library or work, Lose → Mall stands, dog → Mall stands, OFF hides both.
- **Low graphics (Settings → 🥔):** turns off 119 lights, global shadows and 216 non-solid decor parts (lamp heads, leaves), and restores them exactly.
  - Solid lamp poles stay visible, so there are no invisible walls.
- **Weekly pay board** (left of spawn): coins from real work (wages, task pay, shift bonus). A new OrderedDataStore key each week. Display names only. Shows "resting" if the store is down.
  - Tested: a 2-minute shift showed up on the board within 2 minutes.

# Map feedback (all players)

Sources: the cloud chat's measured analysis (`docs/Why the map feels off.md`) plus each player's run. Overlaps were confirmed live in Studio.

| Player | Likes (why) | Dislikes (why) | Suggestion |
|---|---|---|---|
| Mia (8, phone) | The Brain Tower: you can see it from anywhere | "Where do I go?" Every corner looks the same | Arrows (now built) |
| Leo | The Job Center and workplaces are close to spawn | Walking is faster than the 20 s bus | A shorter bus wait (done: 6 s) |
| Sam (parent) | The plaza is calm and readable | Trees poking through shop walls looked broken | Clean the plaza (done) |
| Cheap phone | The town is small, so it loads fast | 119 street lights | Low graphics (done) |
| Speedrunner | Short routes (15 s across) | Nothing to route around: flat grid | Shortcuts that need skill (steps, rooftops) |
| Hacker | Closed houses are really closed (solid doors) | Lookouts overlapped the rocket pad and the castle house | Fix the overlaps (done) |
| Completionist | The lookouts at street ends | Side ring roads dead-end in grass | Join the ring roads into a loop |
| Brainrot YouTuber | The plaza boards and tower make a good thumbnail backdrop | Tall skinny buildings with slot doors look odd on camera | Undo the sideways squash |
| Horror fan | The odd house alone at the end of a road | The lookout was built on top of it, which killed the mood | Give the odd house its own lonely path and a lamp |
| Casual player | Bright colours, quick to walk anywhere | The Lose half is mostly locked houses | Turn some houses into Lose places (arcade, TV shop) |

**Ranked map problems** (from the analysis and the players):
1. The Lose half is mostly locked houses (both paths should matter equally). **Open.** Feature work: new Lose places.
2. Widths shrunk to 55% but heights not (skinny buildings, 4.4-stud doors, thin roads). **Open.** Big rebuild: `S` for positions only.
3. Mirror grid, so every street looks the same. **Open.** Landmark shapes per district.
4. Plaza trees inside the Mall, School and Supermarket. **Fixed.** Trees are on open ground, checked in Studio.
5. Lookout on the rocket pad and on the castle house. **Fixed.** Moved beside the road ends, checked clear in Studio.
6. A 20 s bus in a 15-second town. **Fixed.** `Config.Bus.WaitSeconds = 6`.
7. Café and Job Center 2.8 studs into the sidewalk. **Open** (small).
8. Doors facing grass, and ring roads that dead-end. **Open.**

# Round 3 addition: the Casual player

A kid who stumbles on the game and just wants fun. Simulated through the game's code: the first stretch played step by step, then admin jumps to sample a two-hour session (Lose 86B → 60B → dog; Gain 70B → job → shifts). No screenshots, because the window was minimized.

| Fun | Looks | Ease | Clarity |
|---|---|---|---|
| 3 | 3 | 4 | 3 |

- **First 15 minutes:** the door choice is instantly fun. Before 1.7.3 there was a lot of reading before the first big moment. The new arrow tells them where to go, which is the biggest help.
- **30–60 minutes:** turning into a dog is the high point. The 🛍 sniff trail keeps them going.
- **Gain side:** the job → clock in → task → payslip loop is clear, but it feels like real work for a casual kid.
- **Keep playing or leave?** They'd keep playing for about 45 minutes. They'd leave on the Gain side after the second payslip if nothing new unlocks, because the next IQ step is a Skill Gate they don't want to study for.
- **To keep them:** more silly Lose places on the empty west side, and a surprise every 10 minutes (a random event in the plaza).

---

# 1.7.3: "Fix everyone's problem" (built and tested Nov 24)

Each item was tested in Studio play mode through the game's code. There were no screenshots: Studio stayed minimized, and screen control was declined.

| Player / idea | What was built | How it was tested |
|---|---|---|
| Speedrunner: chat repeat loop | The same scene again within 10 min gives no coins and 10% of the brain cells ("You already talked about this") | Code-checked. Starting a chat needs the window visible |
| Speedrunner: timer + board | ⏱ Settings toggle. A server-timed "fastest to IQ 200" plaza board. Admin-set brains never count | The timer showed 9:11. The board showed the run, then the test entry was removed |
| Completionist: checklist | 🏅 Badges (got/total) in Settings. Locked ones are greyed, secret ones show a kid-friendly hint | 25 rows, 22 greyed for the test save |
| YouTuber: faster first wow | 20 s into a new run: 💥 BRAIN DROP (−4%) or ✨ BRAIN BOOST. Any brain change of 2% or more shows a big animated number | −3.6B drop, big counter and title seen |
| Friends: group Hoppr | Up to 3 nearby friends get an invite with the fare. Each pays their own. Refunded if busy at arrival | Solo checks only (own or bogus invite refused, solo booking OK). **The two-player test needs Test → Clients and Servers with the window open** |
| Friends: Vs lobby sign | A sign behind spawn shows who's waiting in Vs Mode, for which side | The sign renders "Nobody waiting yet" |
| Horror fan: Average Files part 1 | 8 beige notes (browser text), stages 0–3, far-away silent sightings, Settings → 😐 Horror Off/Spooky/Full. Animals get a "smells average" note | Stage 1 after 3.5 min. Exactly notes 1, 2, 3 and 8 show up. Off hides all of them |
| User: map, too dark | Clear sky-blue air instead of grey fog, warmer and brighter in every look, more saturation. "Nonsense" stays strange but not dark | Values checked live (cashgrab: brightness 3, haze 0, saturation 0.25). **Not checked by eye** |
| User: uncanny grass | Terrain grass is now a natural bright green (104, 178, 70), with grass blades where allowed | Value checked. **Not checked by eye** |
| User: uncanny interiors | Warm ceiling lamps (soft SurfaceLights) in a grid in every furnished room (51 lamps) | Count checked. **Not checked by eye**. Materials, baseboards and windows are still to do |

**Still open:**
- **Horror part 2:** the phone call, The Mean, the final talk and 3 endings.
- **Interior materials:** baseboards, windows and room sizes.
- **Bigger map layout:** waiting for the user to pick a layout option.
- **For the user:** the free chat decision, real pass and badge IDs, and the friends desync test.

---

# Round 4 (1.7.4): breakers, horror fan, speedrunner and castle explorer

The PC's screen was locked (Windows lock screen), so Studio couldn't draw anything and there are no screenshots. The Studio window was restored and maximized, but rendering only comes back once the screen is unlocked. Every run below went through the game's own code, live in Studio.

| Player | Fun | Looks | Ease | Clarity | Best moment | Worst moment |
|---|---|---|---|---|---|---|
| Hacker A (server/economy) | 2 | – | 3 | 3 | Nothing broke: 76 remotes × 7 bad payloads (nil, string, number, bool, NaN, inf, ±huge, wrong types, 10,000-letter strings) gave 0 errors. Coins, savings and cells unchanged. 6 parallel bank takes and 6 parallel clock-outs did nothing. 189 of 200 spam calls were refused | There's no way to fake a leaderboard time (the server measures it), so nothing to report |
| Hacker B (movement/world) | 3 | – | 3 | 3 | The dumb-only hole refuses smart players. Closed houses are solid | **Players could push each other and block doorways** (fixed: a "Players" collision group). **No wall at the map edge**, so you could walk off into the void (fixed: invisible edge walls, tested: stopped at x = 278) |
| Horror fan | 3 | – | 3 | 3 | Notes appear one by one. The sightings are far away and silent | Part 2 (the phone call, The Mean, the endings) isn't built yet. Off/Spooky/Full works and Off hides everything |
| Speedrunner | 3 | – | 3 | 3 | The ⏱ timer and the IQ 200 board | The chat repeat loop is gone (10% after the first time). The fastest route is now the Library plus jobs and the Skill Gates. No skips found |
| Castle explorer | 4 | – | 3 | 4 | The hole → white room drop works. Falling into the void catches you (health 100). The rhyming hints match the route. The route resets on a wrong turn and when you leave by the back door. The treasure is once per season | **Bug:** a player who hadn't picked a door could open the chest, get nothing, and use up that season's treasure (fixed: it now waits for them). Box/door prompts and Unstuck inside the castle couldn't be pressed with the screen locked |

**Map feedback (round 4):**
- Hacker B likes that the town is small and solid, dislikes the void edge (fixed), and suggests a fence or hedge at the edge so the wall can be seen.
- The castle explorer loves the odd house standing alone, and wants a single creepy lamp by it, as the map analysis also suggests.

**Fixed in 1.7.4:**
- Player collision group: no pushing, no door-blocking.
- Invisible edge walls.
- Castle chest without a path no longer uses up the season's treasure.

**Still open:**
- Horror part 2.
- Pressing the castle prompts and checking it at phone size, once the screen is unlocked.
- Choosing a map layout.
