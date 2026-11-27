# Gameplay critique (harsh, v1.9.2+, read from code, config and earlier reviews; not a fresh play-test)

Lens: a 10-year-old on a phone, compared with top Roblox games. The map and idea are good. The problem is that the player spends most of the time tapping menus and reading, not moving through the world and doing things.

## Scores

| Area | /10 | One-line reason |
|---|---|---|
| Core loop (Gain) | 4 | Pick job, open phone, play a 20 s tap game, read a toast, repeat. The world is only a doorway to the phone. |
| Core loop (Lose) | 3 | Swipe BrainTok / pop bubbles. One button, no skill, no choices. |
| Minigames | 4 | 10 tiny tap games, all "tap the right thing fast". No escalation, no combo, no boss round. |
| Rewards and feedback | 4 | Numbers move, but a +0.6 IQ pop, a toast and a few coins do not feel like winning. |
| Goals and progression | 5 | Good skeleton (job ladder, animal strip), but long flat stretches between unlocks. |
| Moving around the world | 3 | Almost nothing needs you to walk, carry, dodge or race. The bus and phone replace exploring. |
| Social / co-op | 3 | Name tags, leaderboards, a Vs lobby. No shared goal that needs other players. |
| Retention (back tomorrow) | 3 | No daily reward, streak or daily quest. Saves just persist. |
| Pacing / first 10 minutes | 5 | Better after the 1.9.1 pass, but still menu-heavy. |
| UI clarity | 4 | Two UI kits, stacked toasts, unnamed phone apps (see Harsh review.md). |

## What a kid does, minute by minute (from the code)

**Gain, 0 to 10 min:** spawn, tutorial cards with quizzes, read library texts (Config.LibraryReadSeconds 4 s, small pool that repeats), pick a job at the counselor, walk to the workplace, open the phone, Work app, play one 20 to 30 s tap minigame (Config.Minigames.Games), see a result card, repeat. Report card every 3 shifts (Config.Careers.ReportEvery). Promotion XP is 4 / 10 / 18 tasks. By minute 10 the kid has played roughly 8 to 12 identical rounds of ONE game and read some text.

**Lose, 0 to 10 min:** open the phone, BrainTok swipe (Stations.scroller), tap SWIPE again and again, maybe bubble wrap / memes / sign (Config.LoseJobs). Brain drops, UI gets laggy and scrambled (LoseFX). First animal form at about 3 minutes. The most efficient play is mashing one button, so the game teaches mashing.

## The 10 biggest problems, worst first

### 1. The game is played inside the phone, not in the world
Every activity (work, scroll, quick play, bank, rides, shifts) is a screen. The 3D town is scenery. Top Roblox games put the fun in the avatar's hands: carry, deliver, dodge, jump.
**Fix:** make 2 to 3 jobs physical using the existing workplaces and the `Rooms.lua` furniture kit. Cashier: a ProximityPrompt scanner at the counter with queued customers (NpcReact / Props). Courier: `GAMES.dash` in Minigames.lua becomes a real parcel Part the player carries to a marked door against a timer. Keep the tap games as the easy mode. Server: `GainService.lua` already pays per task, so add a ProximityPrompt task source.

### 2. One game per job, no escalation, so every shift is the same shift
Each job has one game with a fixed goal. Promotion only takes 4 s off the timer and adds 1 to the goal (Config.Minigames.LevelFaster). Nothing new appears.
**Fix:** use the per-level list the `server` job already has (`ByJob.server = { "dishes", "serve", ... }`) for every job: 2 to 3 variants plus a mutator per level (rush hour, double customers) via `ctx.level` in `Minigames.play`.

### 3. Rewards are numbers, not moments
Brain counts are huge, gains are tiny, a good shift is a toast and a few coins. Toasts also stack and hide the objective (Harsh review #3). Kids need burst, sound and a screen-filling flash.
**Fix:** one `Effects.reward(kind, amount)` in `Effects.lua`: coins fly to the HUD counter, screen pulse, chunky "NICE!" text, a sound from Config.Sounds. Call it from the minigame result, Library and Quick Play. Add 1 to 3 stars on the result (score vs pass, already known from Config.Minigames) with more pay per star.

### 4. The Lose loop is a one-button mash with nothing to decide
`Stations.scroller` is a SWIPE button. It is easy to grind, boring in 60 seconds, and pays no coins.
**Fix:** a "Brainrot Rush" game in `Minigames.lua` (tap the dumbest clip, decoys that are smart, combos, rising speed). Make swipes pay less after many in a row. Give Lose coins to spend on silly cosmetics (Config.LoseJobs already pays 4 to 6 coins).

### 5. Dead time between actions
Walking to work (Config.WorkRadius 45), animal-stage gaps and timer-based events are empty. Nothing to pick up on the way.
**Fix:** respawning coins, golden brains and snacks along streets, copying `GoldenBrainService.lua`, with a magnet pull, ping sound and a streak chip on the HUD ("7 in a row"). This uses the map you already like.

### 6. No reason to come back tomorrow
No daily chest, quest, streak or visible limited-time event.
**Fix:** new small `DailyService.lua`: save `lastClaim` and `streak` (old saves still fine via DataService), a plaza chest with a countdown, 3 daily quests from existing actions ("3 shifts", "pop 50 bubbles"), a red dot on the phone. Text in Content.lua, numbers in Config.lua.

### 7. Text instead of play (library, quick play, conversations, tutorial)
Facts then a multiple-choice answer, long tutorial cards, text conversation choices, and a small pool that repeats. It feels like homework.
**Fix:** cut the Gain tutorial to about 5 steps (`Tutorial.lua`); make Quick Play a timed streak with a visible multiplier and rising speed; picture-first facts; shuffle bags so nothing repeats until the pool is used.

### 8. The middle of the game is flat
Gain multipliers fall from x999 to x1.01 (Config.GainMultipliers): a huge first minute, then a long crawl between 86B and 140B. Career level 4 needs 18 tasks of the same game.
**Fix:** a visible reward every ~3 minutes (outfit piece, room opening, pet, title over the head) shown as the next step on the path strip (`Config.PathStrip`, `Content.Steps`), not only a bigger multiplier.

### 9. Nothing needs a friend, nothing to show off
Other players are name tags. Vs mode is a lobby sign. Boards exist (Config.Boards).
**Fix:** a server event in `EventService.lua`: "Brain Storm", everyone's shifts fill one shared bar for a prize. Visible stage titles over heads (Dog, Rock, Genius). A 2-player pair job (one scans, one bags) reusing the two halves of `GAMES.scan`.

### 10. Difficulty is a cliff, not a ramp
Dish duty was too many fast taps (Harsh review #5); goals are fixed and the server rejects wins that are too fast (MinPassFactor). A young child fails, sees "Not quite", and learns nothing.
**Fix:** adaptive goal in `MinigameService.begin`: after 2 fails lower `pass` by 1 and show a one-line tip, after 3 wins in a row raise it; always pay a small consolation. `Config.Minigames.Games` stays the base value.

## 5 quick wins (each under a day)

1. **Combo and stars in `Minigames.play`:** x2/x3 combo counter, big "+1" pop at the tap point, 1 to 3 stars, a sound on every tap (sounds exist in Config.Sounds now).
2. **One queued toast lane** (Harsh review #3) so reward text is never hidden.
3. **Coin burst to the HUD counter** on every payout (`Effects.lua`).
4. **Walk-to collectables** along the main street with a streak chip, copying `GoldenBrainService.lua`.
5. **Daily gift chest** in the plaza with a countdown (tiny `DailyService.lua`, 2 save fields).

## Bottom line
There are many systems and very little hands-on play. Fix the feel first (juice, combo and stars, toast lane), then move two jobs into the world, then add the daily hook. Do not add more phone apps until then.
