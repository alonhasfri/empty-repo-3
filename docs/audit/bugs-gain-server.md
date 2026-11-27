# Bug hunt: Gain path and economy on the server

Read-only audit (no game code changed). Scope: `Main.server.lua`, `GainService`, `LifeService`, `MinigameService`, `EventService`, `BrainService`, `DataService`, `ShopService`, `GeniusService`, plus `BrainTalksService`, `QuickPlayService`, `QoLService` and the Config numbers they use. Skill Gates are off on purpose (`Config.Features.Gates = false`). All paths below are under `roblox/src/`. Nothing here was run in Studio, so treat each item as "found by reading the code".

Ranked by severity (1 = worst).

## HIGH

1. **Job minigames can be finished without playing, with no cooldown (free coins, brain cells, XP, inventions).**
   `ServerScriptService/Services/MinigameService.lua:70-100` and `GainService.lua:589-645, 806-834`.
   `mg_finish` trusts the client's `score`. The only checks are "not faster than `pass / maxPerSecond * 0.6`" and "score <= elapsed * maxPerSecond + 1". A script can call `job_task`, wait about 3 s (cashier: 6 / 1.2 * 0.6 = 3 s), then send `score = pass`, or a bigger score for bonus coins. Each win pays coins, `JobBrainPoints` 2.5, `JobStress`, XP toward promotion and the idea meter (an invention every 6 shifts). Nothing limits how often `job_task` can be called (only the 25 requests per second rate limit). `mg_go` is also never required, and the handler does not re-check that the player is still at work or on shift.
   Fix: (a) per-player, per-job cooldown (for example 12 s from the last payout) in `finishTask` or the `job` handler; (b) require `mg_go` before `mg_finish`, and measure `elapsed` from `mg_go`; (c) re-check `atWork` in the `job` handler; (d) cap bonus coins (`score - pass` limited to a few points); (e) optionally diminishing brain points after N shifts per minute.

2. **Brain cells grow without limit above 140e9, then become infinite and the save breaks.**
   `Config.lua:64` (last `GainMultipliers` entry `mult = 999`), `BrainService.lua:562`, `DataService.lua:129-142`.
   Above `OverflowCells` every gain point adds about `cells * 0.002 * 999`, roughly 2x the current cells per point (a 2.5 point shift is about x6). That gives 1e12 in a few shifts, and `inf` or `NaN` after a few hundred shifts (fewer with bug 1). `UpdateAsync` cannot store inf or NaN, so every save fails (`DataService.save` only warns) and the player silently loses all progress. The load-time repair only fixes `coins` and `bank`, never `cells`. Skill Gates used to cap this and are now off.
   Fix: clamp in `BrainService.gain` (and `setCells`): `data.cells = math.min(data.cells + amount, Config.MaxCells)` with something like 1e15, and treat non-finite cells at load as `Config.OverflowCells`. Consider a flat amount instead of x999 above the overflow line.

3. **Saves are tried only once on leave and on shutdown, so a throttled DataStore loses progress.**
   `DataService.lua:164-189, 251-264`.
   `DataService.save` is a single `pcall(UpdateAsync)`. `release` then deletes the profile whatever happened. If the call fails (throttle, outage), up to a minute of progress is gone, and the session lock stays on this JobId. `BindToClose` has the same single try.
   Fix: retry 3 to 5 times with `task.wait(1, 2, 4...)` inside `save` when `release` is true, and only drop the profile after success (or after the final failure, with a warn).

4. **A paid pass that now does nothing (honest-money break): "Extra Hints".**
   `Config.lua:499-506`, `ShopService.lua:46-61`, `GainService.lua:184` (only use is in `gate_start`).
   `ExtraHints` (99 Robux) gives "+2 hints per Skill Gate attempt". Gates are off, so it has no effect, but `shop_list` still offers it. Also `ShopService.lua:77` still says "Passes never help with Skill Gates." and the `VIPLibrary` desc mentions gates.
   Fix: skip passes whose feature is off in `shop_list` (hide `ExtraHints` when `Features.Gates == false`), or repurpose it (for example extra stress relief). Update the reminder text.

5. **Genius jobs pay uncapped coins per round, anywhere, with no cooldown.**
   `GeniusService.lua:64-101`, `Config.lua:223-243`.
   Pay is `score * 6` coins (up to about 90 to 170 per round) plus brain points, with no workplace, shift, or cooldown, and the score is client-chosen (see bug 1). It out-earns the best job (Scientist about 40 to 50 coins per task). It also opens at IQ 140 for everyone.
   Fix: flat pay per passed round (for example `JobPayPerPoint * pass`), a 15 to 20 s cooldown, and require being in a Genius spot.

6. **Library spam reaches IQ 200 in about 10 minutes now that gates are gone.**
   `GainService.lua:61-95`, `Config.lua:98-99, 62-70`, `Content.lua` (`Content.Library` has only 8 questions, `Theater` 6).
   A right answer is 2 points, read time is 4 s, no cooldown or diminishing returns. From 78e9 to 140e9 is about 250 points, so around 125 answers (about 10 min), faster than any job (2.5 points per 20 to 30 s). That makes careers, promotions and the 200 IQ speedrun board meaningless, and the same 8 questions repeat (answers are also readable by the client in `Content`).
   Fix: shrink points per answer as the same source is used (for example halve after 10 answers per 5 minutes), or add a per-source cooldown. Add more questions, and track "seen" ids so they do not repeat quickly.

7. **Switching jobs silently deletes your career progress (no warning, no confirm).**
   `GainService.lua:288-298, 427-448`, `Client/Stations.lua:1006-1020`.
   `careerOf` makes a fresh career whenever `c.id ~= data.job`. One tap on another job in the Job Board throws away rank, XP and the +50% pay per level. The button text shows only titles and coins per minute.
   Fix: keep one career record per job (`data.careers[job.id]`), or add a confirm modal that says "You will start at the bottom of this ladder".

8. **Shift state never clears, and payslips count unrelated coins.**
   `LifeService.lua:300-371`, `GainService.lua:1147-1175`.
   `OnShift` (and `sess.shift`) is only cleared by pressing clock-out. Taking another job, resetting the path, dying or respawning leave it on. After one clock-in the passive wages (`WagesNeedShift`) are paid for any job at any workplace forever, even while the player is AFK. The payslip `wages = data.coins - sh.coinsAt` also includes bank withdrawals, event coins and daily rewards, and drops when you pay a ride fare.
   Fix: clear the shift on `job_take`, `onPathReset`, `PlayerRemoving`, and when the player leaves `WorkRadius` for more than a minute. Track a `sh.earned` counter in `finishTask` and the wage loop. Skip wages when `player:GetAttribute("AFK")`.

## MEDIUM

9. **Teleports ignore path, building rules and player state.**
   `GainService.lua:451-523` (`taxi`), `LifeService.lua:114-144, 191-235` (Hoppr), `GainService.lua:976-982` (Teleport Remote).
   Any key in `WorldService.Spots` works, not just `Places` for your path. A Gain player can go to Lose buildings (and the reverse), to `lose`/`gain` door spots, to `oddhouse` and `wall` (secrets), and `LifeStageService.doorBlocked` is bypassed. `taxi` with the pad or Castle Map is instant and never checks `BrainService.blocked` or `ConversationService.readyToTravel`, so you can leave a conversation, a school class or a freeze by teleporting.
   Fix: build an allow-list from `WorldService.placeList()` filtered by `p.path` (`Any` or your path), and call the same `readyToTravel` and `blocked` checks in the instant branch.

10. **"Reset progress" backup is never deleted, and data wipes miss it.**
    `DataService.lua:201-238`.
    `<key>_backup` is written with `SetAsync` and `Config.Reset.BackupDays` (7) is never enforced. `DataService.wipe(userId)` (Roblox data-deletion requests) removes only the main key, so the personal data copy stays forever.
    Fix: store `backupTime` and delete expired backups at load (`RemoveAsync`), and make `wipe` remove `key .. "_backup"` too.

11. **"First day at a new job" event can be farmed.**
    `GainService.lua:435-442`, `EventService.lua:54-64, 93-125`.
    Every `job_take` (even the same job) schedules an invite 20 s later if none is pending. Finishing an event gives `DoneCoins` 25, event brain points (up to 2 per minigame), and sometimes a pet. A loop of take, wait 20 s, accept, finish is a coin and brain source that ignores the 5 to 8 minute gap.
    Fix: only schedule `firstday` if `job.id` is a job the player has never held (`data.firstDaySeen[job.id]`), and refuse `job_take` for the current job.

12. **`job_answer` (lawyer, janitor, sweeper) has no thinking time or cooldown.**
    `GainService.lua:535-587, 642-644, 789-803`.
    These jobs still use the old pick-one-of-3/4 task (not in `Config.Minigames.ByJob`). A script can request and answer about 12 times per second, guessing about 25 to 33% correct for 30 coins (lawyer level 1) each plus XP and brain points. Wrong answers cost only +4 stress.
    Fix: add a minimum answer time (for example 1.5 s from `job_task`) and the same per-job payout cooldown as bug 1, or move these jobs onto minigames.

13. **Brain Talks can be re-rolled for free, which defeats the "dodge brainrot" choice.**
    `BrainTalksService.lua:77-84`.
    `talks_next` makes a new clip without counting the old one as skipped or missed. A player can re-roll until a smart title shows (the smart titles are in client-readable `Content.BrainTalks`), and watch only those, keeping the streak bonus (+150% at 10).
    Fix: if `x.clip` is still unresolved, `talks_next` should return the same clip, or count it as `skip`.

14. **Stress "habits" have no cooldown and no place check.**
    `GainService.lua:1007-1056`.
    `habit_nap_start`/`tap` (the delay is sent to the client, so a perfect tap is trivial) removes 30 stress every 3 to 8 s. `habit_coffee` only needs 8 s and a count of 60. Stress is therefore never a limit, and the habits work from anywhere.
    Fix: add a 30 to 60 s cooldown per habit (like pigeons' 45 s) and check the player is near the station.

15. **Late autosave can overwrite a "Reset my progress".**
    `DataService.lua:164-227`.
    An autosave already inside `UpdateAsync` when `resetProgress` runs can land after the `SetAsync(fresh)`, bringing the old save back.
    Fix: set a `resetting[player]` flag in `forget` and have `save` re-check it inside the `UpdateAsync` callback (return `nil` if set).

16. **Session lock is effectively 15 s, not 120 s.**
    `DataService.lua:87-102`.
    After 5 failed attempts (about 15 s of waiting) the sixth attempt forces the lock even if the other server saved a few seconds ago. In a slow teleport or a hung old server this can start two live sessions, and the old server's later saves are then refused (lost progress).
    Fix: when forcing, wait until `os.time() - lock.time >= 120` (or keep retrying up to about 2 minutes) before ignoring the lock.

## LOW

17. **Hoppr quirks.** `LifeService.lua:114-144, 228-235`: the fare is based on the distance at quote time, so quote near the destination and walk away within 60 s for a cheap ride. If the "work" destination has no position at arrival, the fare is kept but no teleport happens. Fix: price at booking time, and refund when `pos` is nil.
18. **Crew cap bug.** `GainService.lua:652-665`: with more than `MaxCrew` (4) people at one workplace, `crewOf` stops early; the requesting player may not be in `crew`, yet gets the teamwork bonus with no role. Fix: always include the requester, then fill the rest.
19. **Client-set AFK flag.** `QoLService.lua:61-64`: any client can mark itself AFK to dodge the school bell and event invites. Fix: also require no movement for the same time on the server.
20. **Stale gate code still reachable.** `Main.server.lua:60` (`gate = "Gain"` station), `GainService.lua:135-254`. The `guard(... "Gates")` blocks `gate_start` with "turned off right now", but the `station` remote for `gate` still returns ok and opens the station if any client UI calls it. Fix: remove `gate` from `STATION_PATH` and drop the gate remotes while gates stay off.
21. **Robot Helper message ignores multipliers.** `GainService.lua:998` prints the pay without `Inv_fusion`, so the toast differs from the real coins. It also skips `BrainService.blocked` and the at-work check, so it is a 180 s cooldown shift anywhere (probably intended; just confirm).
22. **Lazy defaults, no schema version.** `formsSeen`, `career`, `eventsDone`, `eventBag`, `genius`, `geniusStory`, `lastDaily` are created lazily where they are read, and every reader I checked guards `typeof(...) == "table"`. No crash found, but `data.version` is never bumped, so a real migration would have nothing to key on. Suggest bumping `version` when the next field is added.

## Checked and OK (no bug found)
- `Net` forces `data` to a table, so `d.choice`, `d.key` and so on cannot raise nil errors from a bad payload; rate limit is 25 per second.
- `bank_move`: refuses NaN, inf, negatives and amounts above `MaxMove`; `amount > data.coins` and `> savings` checked server-side.
- Stress freeze: always ends after `FreezeSeconds`, guarded by `frozenAt`. Embarrassment hide ends by itself.
- `EventService` and `MinigameService`: a lost round just means pressing accept again; no soft lock. All event minigame ids exist in `Config.Minigames.Games` and `Content.Minigames.Games`.
- Library, theater and gate answers are checked on the server with a read-time check.
- Ride group refunds work when the leader leaves or is in a conversation.
