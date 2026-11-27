# Fun judge, Nov 27 (read from code, git log and screenshots; not a live play-test)

Lens: 10-year-old on a phone, then a designer vs top Roblox games.

## Scores /10
| Area | Kid | Designer | Why |
|---|---|---|---|
| First 5 minutes | 5 | 4 | Nice town, but the HUD has 5 buttons + rail + goal strip + phone + 2 round buttons, and the first goal is "read at the Library" (homework). Daily toast and tutorial add more reading. |
| Core loop | 5 | 4 | Minigames now end at the goal (better), but still phone taps. Jobs are still menus, not the avatar's hands. |
| Rewards | 6 | 5 | Floating numbers and coin fly-in help. Numbers are still abstract (72.0B vs IQ 74 vs 923 coins: three currencies on screen). |
| Progression | 5 | 5 | Skill gates removed (good), so IQ no longer blocks anything; the next step is a text line on a small strip. |
| Social | 3 | 3 | Name tags, Vs lobby, boards. Nothing needs a friend. |
| Reasons to return | 4 | 4 | Daily reward exists (Config DailyCoins); no daily quests, no event you can miss. |
| Lose vs Gain | 6 | 5 | Lose is funnier (goo, balloons, animals, ooga-booga). Gain feels like school. Lose still lacks a real decision loop. |

## Still boring / confusing / pointless
- Gain: "Read at the School Library" as the first objective. Reading = lowest-fun action.
- HUD clutter: Quick Play, Store, Items, Vs Mode, Phone, tools, SOS, goal strip, stress bar, pop-ups, all at once.
- Machines (teleporter etc.): the trace-mode shot says "BLOCKED!" against a wall; a fiddly steer-a-ghost UI with 3 buttons is hard for a 10-year-old. Eureka machines are cool but gated by chance and a cooldown.
- Town mood is a one-way visual treat; it changes nothing to do.
- Phone still hosts everything; the world is scenery.

## Too many systems: cut or merge
1. Merge Quick Play into the Phone/Work app (or into a single "Play" button). It duplicates the minigames.
2. Merge Items + Gadgets + Machines into ONE hotbar/inventory (already half done).
3. Merge Vs Mode into Invites (one social button).
4. Cut the stress bar and the pink/blue extra HUD chips from the default HUD (show only when it matters).
5. Cut or hide Store from the rail until minute 10 (honest-money rule still met).
6. Freeze new services: 44 service files for one game. No more systems until loops improve.

## Top 10 improvements (impact / effort)
1. First objective = a short, physical, rewarding thing (collect 5 golden brains, ride the bus, pop a bubble) not reading. Files: Config.PathStrip, Content.Steps, Tutorial.lua, GoldenBrainService.lua.
2. Hide the HUD until needed: first 3 minutes show only brain counter, goal and Phone. Unlock Quick Play/Store/Items/Vs one by one. Hud.lua.
3. Pickups along streets with magnet, streak chip and sound (copy GoldenBrainService). WorldService + Hud.
4. One currency in the main display: show brain cells big, IQ small, coins only after first spend. Hud.lua.
5. Stars (1-3) and combo on minigame results, with more pay per star. Minigames.lua, MinigameService.lua.
6. Daily quests (3 simple tasks) with a red dot on the phone, on top of the existing daily coins. QoLService.lua, Content.lua.
7. Make 2 jobs physical (cashier prompt, courier parcel). GainService.lua, Rooms.lua, Props.lua.
8. Lose path decision loop: "Brainrot Rush" with decoys and a combo; swipes pay less when spammed. LoseJobService.lua, Minigames.lua.
9. Shared server goal ("Brain Storm" bar filled by everyone's shifts) plus visible stage titles. EventService.lua.
10. Simplify the machine UI: auto-aim teleporter (tap a place on the map, not a ghost), no "BLOCKED" dead end. Machines.lua, MachineService.lua.

Bottom line: the look is now strong; the fun per minute is not. Remove clutter, add physical collecting, and give every reward a moment.
