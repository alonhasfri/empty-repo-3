# Saving, admin and security audit (Nov 27, roblox-reviewer agent, read-only)

High
1. DataService.lua:85-105: the loaded save is not cleared between load retries, so a save read on a failed try can be accepted later without owning the session lock (lost progress or rollback). Fix: reset `loaded`/`locked` every try; accept only when the call succeeded and the lock is ours.
2. DataService.lua:120-124: if loading fails, the player silently plays a fresh save that is never saved. Fix: kick with "Couldn't load your save, please rejoin" (or a clear banner).

Medium
3. DataService.lua:219-226: "Reset my progress" forgets the profile before the delete write; if the write fails the player is in a never-save state. Fix: restore the profile on failure.
4. AdminService.lua:1016-1028 + DataService.lua:214: wipedata leaves the `_backup` key forever (right-to-erasure gap) and another server's leave-save can write data back. Fix: delete `_backup` too and tell every server first (MessagingService).
5. ShopService.lua:64, Stations.lua:690/698: the Robux price shown comes from Config, not the real price. Fix: read PriceInRobux with GetProductInfo (cached) on the server.
6. Config.lua:695-696 + AdminService.lua:425-436: Testers can run golden/schoolbell on any normal player (farming for friends). Fix: selfBelow = 3 and mark adminTouched.
7. AdminService.lua:890-908: a wrong quiz answer doesn't use up the turn; a script can try all answers. Fix: one answer per player per quiz.
8. DataService.lua:170-182: saves are never retried (leave/shutdown can lose up to 60 s). Fix: 3 tries with backoff.

Low
9. Admin logs only in memory, refusals not logged. 10. Chat commands match the first name prefix (`;kick a`). 11. manualRank is saved forever. 12. Pass granted without re-checking UserOwnsGamePassAsync; the purchase pause is client-only. 13. Save `version = 1` is never read (no migration step for renamed fields).

Clean: Net.lua validation and rate limit; bank transfers; ride fares and shift pay on the server; minigame score capped by time; cells clamped (NaN, 1e15); admin ranks server-side with target-rank checks. No developer products (ProcessReceipt not needed yet).
