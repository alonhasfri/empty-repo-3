# Bug hunt: changes since 2026-11-26 20:00 (read-only review)

Scope: `git diff 01918aa HEAD -- roblox/src` plus uncommitted changes (Gadgets rename, giveGadgetTools, perk buffs). Nothing was run; all findings come from reading code. Paths are under `roblox/src/`.

No hard nil crash was found in the new code. The real problems are broken player flows (tutorial, leftovers) and a few logic gaps. Ranked worst first.

## HIGH

1. **Both tutorials send players to phone apps that no longer exist.**
   `StarterPlayer/StarterPlayerScripts/Client/Tutorial.lua:146-149,155` (SEQ) and `Client/Hud.lua:490-498` (TUTORIAL list). `Config.UI.PhoneApps` (Config.lua ~820) removed ClickNews, Steal A, Comments (Lose) and Jobs, Jack B, eBooks (Gain) from the phone. The steps still say "Open Phone -> ClickNews / Steal A / Comments / Jobs" with `target = "phone"`, and `library` / `work` targets point at Hud buttons that are not on the rail (`Hud.targets.library` is nil, so no arrow).
   Player effect: a new Lose player cannot finish the clickbait, steal and comments steps from the phone (those are now town stations: Newsstand, Arcade, Internet Cafe). A new Gain player cannot find Jobs (Job Board is a town station). The tutorial stalls until they press Skip.
   Fix: rewrite those steps to "Walk to the Clickbait Newsstand / Steal A Arcade / Internet Cafe / Job Board / Library" and use the Guide arrow (`Guide.lua`) as the target, or make the events complete from the station. Update Hud.lua TUTORIAL text the same way.

## MEDIUM

2. **Lose path loses its core actions from the phone and the rail.**
   `Config.lua` PhoneApps.Lose has only map, scroller, jokejobs, events, home, camera, badges, settings. ClickNews, Steal A and Comments are only reachable by walking to town (`WorldService.lua:639-641`). The Hud rail only has Quick Play, Store, Items, Vs Mode. Not a crash, but it conflicts with the Lose loop in CLAUDE.md (clickbait and brainrot). Also check that animal-stage Lose players still have a way to the places. Fix: confirm this is intended; if not, add the three apps back into PhoneApps.Lose and PhoneFirst.Lose.

3. **Pending "wedding" invite blocks all future life events.**
   `ServerScriptService/Services/EventService.lua:41-50` maps wedding to surprise only inside `draw()`. An old save with `data.eventInvite = "wedding"` (or `eventsDone` containing it) keeps a truthy `eventInvite`; line 207 (`not data.eventInvite`) then never sends a new invite, and `event_get` (line 139) shows no invite because `TE.Events["wedding"]` is nil. Fix: in the invite/`event_get` path do `if data.eventInvite == "wedding" then data.eventInvite = "surprise" end` (same for `data.eventsDone` entries and `active` ids).

4. **Duck gadget can push the idea meter past its max.**
   `GainService.lua:~957` `data.ideaMeter = (data.ideaMeter or 0) + 1` has no cap. `ConversationService.lua:192` caps at `EurekaTasks - 1` on purpose. UI shows "5/4", and the Eureka only fires on the next job task. Fix: `math.min(..., Config.EurekaTasks - 1)`.

5. **Toast hold queue also waits for the Lose joke ads.**
   `ClientMain.client.lua:219-232` (`screenBusy`) counts any visible Frame with ZIndex >= 60 under `UI.gui`. `LoseFX.lua:106` JokeAd is ZIndex 60, so on Lose path server news (cells lost, events) waits until the ad is closed, up to 30 s. Fix: skip frames named `JokeAd`, or use an attribute (`Overlay=true`) on the cutscene frames only.

6. **Queued toasts can be overtaken.** `ClientMain.client.lua:234-240`: when not busy, a new toast shows immediately while older ones still wait in `toastQueue`, so order is not kept. Fix: if `#toastQueue > 0`, append instead of showing.

## LOW

7. **Release notes and version not bumped.** `Config.lua:7` still `"1.9.2"`; `Content.Updates` has no 1.9.3 entry (CLAUDE.md rule). Fix: add the entry and bump.

8. **Calm start only refreshes once.** `Hud.lua:1278-1284` runs after 10 s using `UI.state or {}`. If `UI.state` is nil it hides the grid until the next `Hud.update` (usually soon). Also the calm timer starts at script load, not when the player picks a path, so a player who spends 10 s on the door picker sees no calm period. Fix: start the timer on first state with a path.

9. **Leftover gate references (dead but visible if a gate is ever re-enabled, or visible in admin).**
   - `Config.lua:817` `PhoneDock` (the dock is gone).
   - `Config.lua:492-498` ExtraHints pass text "+2 hints per Skill Gate attempt" (hidden by ShopService only when `Features.Gates == false`; `Hud.lua:655` still has an ExtraHints pass chip).
   - `Content.lua:2055` `GainGate` + `Guide.lua:114` (never true now; `BrainService.nextGate` returns nil when the feature is off, so safe).
   - `Badges.lua:17-20` Gate1-4 badges can never be earned (visible in the Badges app as locked). Hide them or give them a different unlock.
   - Admin commands `skipgate`, `passallgates`, `resetgates` still listed (Config.lua:728-730).
   - `Rooms.lua:560` University lecture hall is still laid out around the Skill Gate position; the stand is gone, so check the room is not empty.
   - `Content.lua` 1.8.x "What's new" entries still mention gates (fine as history).

10. **Spawn restore raycast ignores CanCollide.** `Main.server.lua:~337-345` casts 60 studs up with default params, so an invisible or non-colliding part above you (sky wall, trigger zone, tree canopy, awning) skips the restore and sends you to the plaza. Harmless but may surprise returning players. Fix: set `params.RespectCanCollide = true` and filter `Transparency == 1` hits.

11. **Gadget tools only wired for players present at script start via a loop.** `GainService.lua:~1073-1080`: players already in game when the script loads get tools once but have no `CharacterAdded` hook, so after respawn they lose their hotbar tools (Studio-only, but it will confuse testing). Fix: wrap the connection in a function and call it for existing players too.

12. **Pigeon tip does not push state.** `GainService.lua` pigeons branch adds `data.coins` without `BrainService.push`; the coin counter updates late. Fix: `BrainService.push(player)`.

13. **Icon preload cost.** `UI.lua` (~1250) preloads every `Config.Icons` and `Config.IconsMono` id at startup; on weak phones that is a burst of requests. Fix: preload only after the calm start, or only icons for the current look.

## Checked and OK

- `Content.Inventions` to `Content.Gadgets`: all gadget uses (GainService, AdminService) were renamed; remaining `Content.Inventions` hits are the world-invention tables (ProjectService, InventionHall, Stations road/tour), which is correct. `Config.Inventions` is a separate table.
- `Config.Features.Gates = false`: `BrainService.feature("Gates")` returns false, so `nextGate`, `gateCap`, `atGate` return nil/false; no IQ cap. `Hud.progress` falls through to the IQ bar. Stand removal and phone gate app guarded.
- Minigame auto-finish: `finish()` is idempotent (`finished` flag); `MinPassFactor` check uses `def.maxPerSecond` which every game has (job games and the genius games). One nit: if the player closes the pop-up in the 0.8 s after reaching the goal, the win is still sent (harmless).
- `MaxCells` clamp and NaN guard in `BrainService.gain/setCells`: correct.
- `LifeStageService` age cap: stops at `LegacyAge`, old over-age saves stay quiet (`age > lastYear` never true), round-birthday filter is right.
- Brain Kit `PopStyles`: removed fields (`bg2`, `face`, `font`, `bgT`, `outlineTitle`, `outlineButtons`) are all nil-guarded in `UI.lua` (lines 657, 804-830, 890-897, 959-1009).
- `PhoneApps` filter: every key in the lists exists in `appsFor`; `PhoneOS.more` / `appGrid` are defined before use; `Stations.gadgets` exists for the Teleport Remote tool.
- Left rail: 4 non-phone buttons equals `HudMaxButtons`, so no "More" overflow; `shop`, `items`, `together` all route correctly in `Hud.onStation`.
- `DuckCalm`, `GateExtraTimeMultiplier`, `MaxCells`, `CrossroadsTo`, `LegacyAge` all exist in Config.
