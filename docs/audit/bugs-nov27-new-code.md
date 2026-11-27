# Bug hunt: code added since 75b2aef (Nov 27)

Read-only review. Nothing was run or tested. Paths are under `roblox/src/`. Ranked by impact x likelihood.

## HIGH

### 1. Machines work while another system holds you still, and they undo that hold
- `StarterPlayer/StarterPlayerScripts/Client/Machines.lua:133, 231, 253` (also `jetpack()` 316, bounce 374)
- The Trace Teleporter sets `root.Anchored = true`, and CANCEL / end of zoom sets it back to `false`. `Conversation.lua:479,613` and `VsStage.lua:90` also anchor the root. Nothing stops the hotbar tool during those scenes, a minigame, a pop-up, school class, or while dead.
- Impact: the player leaves a conversation or Vs stage and the scene breaks (camera Scriptable, thumbstick hidden). The teleporter also walks a Lose-path player out of school class.
- `Watchdog.isLocked` now returns true while `Machines.isBusy()`. If `busy` ever sticks, the Watchdog will not rescue you.
- Fix: in the tool's Activated handler refuse (toast "Not now") if `Watchdog.isLocked()`, a modal is open, `UI.state.dead`, or `root.Anchored` is already true. Only set `Anchored = false` if this script set it.

### 2. Double-tap starts two Trace sessions (busy flag set too late)
- `Machines.lua:117-132`
- `busy = true` is set after `Remote.call("machine_check")` yields. Two quick taps both pass the `if busy` check: two ghosts, two GUIs, two RenderStepped loops. CANCEL on one unanchors the body while the other ghost still drives.
- GO has a similar race (`:233-253`). `finished` is checked before the yielding `machine_use`, not after. A Cancel or death during the call still runs `zoomAlong` afterwards.
- Fix: set `busy = true` first (before `Remote.call`) and clear it on every early return. Re-check `finished` after `machine_use` returns.

### 3. Teleporter validation is unthrottled, and gives false security
- `Services/MachineService.lua:173-239`
- A failed `machine_use` does not start the cooldown. An exploiter can spam it, and each call does up to 200 server raycasts. That is a cheap lag attack.
- The server never moves the player and never checks where they end up. The client owns its character, so a cheater can ignore the machine and set their own CFrame. The path check is only a courtesy. Jetpack and bounce power are also client-side effects.
- Fix: throttle every `machine_use` / `machine_check` call per player (about 0.5 s) before doing any work. If real anti-teleport matters, add a server speed / distance sanity check elsewhere.

## MEDIUM

### 4. "Until they leave" is not implemented, so machines stay for the whole server life
- `MachineService.lua:23, 110` (`serverGrant[key] = true` is never cleared). The header comment and the toast both say the grant lasts "until they leave".
- Once anyone invents a machine, every current and future player in that server keeps it until the server closes. This makes the Eureka reward meaningless in long servers.
- Fix: store the inventor's userId, clear on `PlayerRemoving` of the inventor (unless another player owns it), then `refreshAll()`.

### 5. Guide.lua searches the whole workspace every frame when a target is missing
- `Client/Guide.lua:160-181` (`findTarget`), and `:205` (`line.Text = ...` inside RenderStepped)
- `workspace:FindFirstChild(name, true)` is recursive and retried every frame while the part does not exist. "Work_restaurant" tries four names per frame. `line.Text` is reassigned every frame (AutomaticSize relayout). Phone cost.
- Fix: cache misses for 1-2 s, only set `line.Text` when the string changes, and hoist the `RaycastParams`.

### 6. Icon watcher can mark good icons as broken for the whole session
- `Client/UI.lua:1229-1260` (`UI.watchIcon`)
- "On screen" only checks `ScreenGui.Enabled`, not parent frames' `Visible`. Icons inside a closed phone or hidden pop-up count as shown. On a slow connection `IsLoaded` can stay false, and after 10 s `UI.badIcons[id] = true` is set globally, so that icon is an emoji everywhere from then on.
- Every `buildGrid` or phone rebuild also spawns another polling thread per icon (they end only when the image is destroyed).
- Fix: require every GuiObject ancestor to be `Visible`, and do not make the bad flag permanent (cache for about 60 s).

### 7. Brain glasses: the "rim" is a solid disc that covers the eyes
- `Services/BrainService.lua:339-363`
- The rim is an opaque cylinder (radius r, transparency 0). The lens (radius 0.8 r, transparency 0.55) sits 0.01 stud in front of it. You see a translucent lens over an opaque coloured disc, so the eyes are hidden. Z-fight risk as well.
- Fix: make the rim a thin ring (a few small bars, or a ring mesh), or make the rim fully transparent with only frame bars.

### 8. Second UIScale on the HUD counter
- `Client/Hud.lua:1176` (`counterScale`) while `top` already has `topScale` (`Hud.lua:73`, used at 945, 1083, 1339).
- Two UIScale children under one parent: only one applies. The bounce probably overrides the big-counter / device scale (counter snaps to 1.0), or does nothing. Unverified, test in Studio.
- Fix: bounce `topScale` itself (like line 1339 already does) or wrap the counter in another Frame.

### 9. Bounce pad placement and spam
- `MachineService.lua:247-256`
- The ground raycast has no filter. It can hit the player, another player, or a roof, so the pad can end up on a head or a roof. There is no wall check between the player and the spot 6 studs ahead, so the pad can spawn inside a wall.
- Fix: exclude all characters (as `pathOk` does) and check the short ray for walls.

### 10. TownMood is built once and can be built before the map exists
- `Client/TownMood.lua:84-86` (`ground`), `:200-218` (`apply`), `Style.lua:482-489`
- `ground()` raycasts without a filter (hits roofs, trees, awnings, characters). If the map is not ready it falls back to y = 0.5. `apply` only reruns when the style changes, so wrong placement stays. `PLAZA` is hard-coded to (0,0,0).
- Fix: wait for a known landmark (for example `Station_library`) before building, filter characters, and rebuild when the map finishes.

### 11. floatDelta ignores the effects setting and uses the long number format
- `Client/Hud.lua:1177-1231`
- Uses `Brain.formatNumber`, so a 1e15 change is a 26-character label in a 200 px box (the counter itself uses `shortNumber`). `UI.effects() == 0` does not stop the float or bounce (only coins check it). It fires on every push where cells changed, so a passive Lose-path drain makes a label every tick.
- Fix: use `Brain.shortNumber`, skip when `abs(d) < 1` or effects are off, and debounce to one label per about 0.5 s.

## LOW / notes

### 12. Gadget Tools (GainService)
- `Services/GainService.lua:1040-1115`
- The tool name is rewritten every second during a cooldown. That replicates and relayouts the hotbar each second per gadget. Use `ToolTip` or a client-side countdown instead.
- The `CharacterAdded` hook only exists for players who joined after the script loaded. Fine on live servers, wrong for Studio tests with a player already present.
- Rubber Duck now adds +1 `ideaMeter` per use (`:985`) and Pigeons add coins (`:1000`). Both are bounded only by their cooldown, so tapping the hotbar all day farms Eureka progress and coins. Check cooldown values.
- Robot Helper runs `finishTask` twice with no "at the workplace" check (existing behaviour, doubled).

### 13. Eureka machine card
- `GainService.lua:681-728`
- `cardFor` can return nil (machine removed in a later version), leaving a hole in `cards` sent to the client. Guard it.
- Picking is validated against `data.eurekaChoices` (`:915`), so a client cannot invent a machine by sending `m:teleporter`. Good.

### 14. DataService
- `Services/DataService.lua:88-137, 176-198` reads correct. The kick only happens when all tries error, and code still continues for that player (harmless). Release save retries up to 3 times with 2 s / 4 s waits. BindToClose runs players in parallel with a 25 s cap, so it is safe. Normal autosave still has one try (fine).

### 15. Animals and Lose path
- Machines are granted to everyone, including animal stages and Lose-path players, via server grant or borrowing. Teleporter and Jetpack let a worm / fly / dog skip animal limits. Decide: block `machine_use` for non-human stages, or accept it and note it in CLAUDE.md.
- `Main.server.lua:338-346`: any CanQuery part above the saved position (awning, tree, bridge, invisible zone) sends a returning player to the default spawn instead of their saved spot.
- Hotbar lift polls every second forever (cheap, fine).

### 16. Checked and fine
- Machine cooldown check and set have no yields between them, so no race. `cooldowns[player]` is cleared on leave.
- `machine_use` rejects non-machine keys (`CM["GlobalMinutes"]` has no `def`).
- `Remote.call` never returns nil, so `check.ok` cannot nil-error.
- `Content.Gadgets` rename: no leftover users of the old list (the `Content.Inventions` at Content.lua:2437 is a separate text table).
- `BrainService.gain` / `setCells` clamping prevents NaN or infinity reaching a save.
- Eureka choice validation (see 13).
