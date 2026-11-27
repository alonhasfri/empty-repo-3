# Audit: cutscenes, camera and player-control takeovers

Read-only bug hunt, Nov 27 2026. Nothing was edited or play-tested; every item comes from reading the code (so confirm in Studio before fixing). Paths are under `roblox/src/`. Short names: CS = `StarterPlayer/StarterPlayerScripts/Client/Cutscene.lua`, CV = `.../Client/Conversation.lua`, FX = `.../Client/Effects.lua`, TU = `.../Client/Tutorial.lua`, CM = `.../ClientMain.client.lua`.

## The root cause (read this first)
There is no single owner for "the player is in a scene". Cutscene, Conversation (NPC scenes and Vs Mode), Photo mode, the Tutorial flyover, `Effects.death` and `Effects.worldsSmartest` each set `camera.CameraType`, `UI.gui.Enabled` and (Conversation only) `TouchControlsEnabled` on their own, each saving a private snapshot ("hudWas", "camWas", "oldType") and restoring it later. Whenever two overlap, the one that finishes last restores a stale snapshot. The Watchdog (`Client/Watchdog.lua`) is a good safety net for movement but does not look at `UI.gui.Enabled`, letterbox GUIs or leftover tweens.

## Ranked bugs

### 1. HUD can stay hidden for good after overlapping scenes (HIGH)
- CS:57-58 and CS:77, CV:357-359, CV:475-477, CV:600-602, `PhotoMode.lua:33/155-157`. Each saves `UI.gui.Enabled` when it starts and writes it back when it ends.
- Example: a Conversation is open (HUD already off) and the Invention tour or genius finale starts a Cutscene. The Cutscene saves `hudWas = false`. The conversation closes and sets the HUD on. The Cutscene ends and sets it back to `false`. The kid now has no HUD, no phone, no Unstuck button. `Watchdog.held()` (Watchdog.lua:35) never checks `UI.gui.Enabled`, so it never frees them. Only a rejoin helps.
- Same pattern for Photo mode, and `Watchdog.freeNow` (Watchdog.lua:67-69) turns the HUD on in the middle of a Photo shot or cutscene.
- Fix: one counter in UI.lua: `UI.lockHud(owner)` / `UI.unlockHud(owner)` (a set of owners). `UI.gui.Enabled = next(owners) == nil`. Nobody stores "was". Add `UI.gui.Enabled == false and no active scene` to Watchdog `held()`.

### 2. Nothing stops two scenes from running at once, on server or client (HIGH)
- Server starts scenes with no knowledge of each other: `ConversationService.start` (ConversationService.lua:85-149) does not check Vs Mode `inSession`, a Cutscene, the death state of a pending tour, or Photo mode. `GainService.promote` (GainService.lua:714-726) sends `promoted` and (after TourDelay) `inventionTour`; `ProjectService.lua:598/759` sends `prize` and `inventionTour`; `SocialService` matches asynchronously (SocialService.lua:568, `social_start` can arrive at any moment).
- Client has only `Cutscene.isPlaying()` as a guard, and only `InventionHall.tour` and `geniusFinale` use it (InventionHall.lua:110, FX:1025). `Conversation.open` (CV:437), `vsStart` (CV:551), `Effects.death` (FX:82), `worldsSmartest` (FX:755), `Tutorial.startFlyover` (TU:283) check nothing.
- Effects: Conversation opened during a cutscene hides the HUD, tweens the camera, then `close()` forces `CameraType = Custom` while the cutscene still thinks it is running. A Tutorial "town" note flyover runs a `RenderStepped` loop (TU:287) that overwrites the camera every frame, so a conversation or cutscene cut is invisible, and its restore (TU:298) fights whoever owns the camera. ProximityPrompts keep working during a Cutscene (see #9), so this is easy to trigger.
- Fix: a small `Scene` module (client) plus an attribute `InScene` set by the server. `Scene.request(name, priority)` returns a token or nil. Priority: death > ban > genius finale > prize > promoted > tour > Vs > NPC conversation > tutorial note > Photo. Lower priority is refused or queued, higher priority aborts the lower one through its `abort()`. Server checks `player:GetAttribute("InScene")` before `conv_open`, `social_start`, `inventionTour`, `prize`, `launch`, `worldsSmartest`; if busy, queue or retry 3 s later.

### 3. Death ending can be invisible, unskippable and overlapped (HIGH)
- CM:268-274 only closes a modal; it does not close an open Conversation, Cutscene or Photo mode. `Effects.death` draws into `UI.gui` (FX:93-134), which is disabled during those, so the kid hears AirHorn, RecordScratch, DeathBoom (6 sounds, up to 1.5 volume with ExtraLoudDeath, FX:147-155) with nothing on screen, then `Stations.deathScreen` appears.
- FX:87 sets `Scriptable` and FX:177 sets `Custom` blindly (no restore of what it was, no `CameraSubject`), which also breaks an overlapping Cutscene.
- `LoseService.death` kills the character after 5 s (LoseService.lua:420-426) but the client sequence lasts about 5.8 s, so the death is cut short by the respawn and the camera aims at a stale Head CFrame. The whole sequence cannot be skipped.
- Fix: in the `death` handler call `Conversation.close()`, `Cutscene.skip()`, `PhotoMode.close()` first. Draw death/ban/launch/etc. in their own `ScreenGui` (`DisplayOrder` 100, `ResetOnSpawn = false`, `IgnoreGuiInset = true`, `ScreenInsets = None`), not `UI.gui`. Add a Skip (Backspace / ButtonB, same as Cutscene). Make the server kill delay `Config.Death.KillDelay` > client length (or kill after the client sends `death_done`).

### 4. Vs Mode scene is not closed on death, respawn or Reset (HIGH on phones)
- CV:551-618 `vsStart` starts a scene but the server only ends *NPC* conversations on respawn (`ConversationService.start`, ConversationService.lua:285-300); `SocialService` has no CharacterAdded hook and the client has none either.
- After a respawn the client still has `cur` set: `TouchControlsEnabled = false` (CV:606-608), HUD hidden, bars up, camera Scriptable at the old position, new character not anchored (only the old root was). `Watchdog.isLocked` returns true because `Conversation.isOpen()` (CM:44), so the Watchdog will never free the player. Only the Leave button gets them out. If the death overlay or a modal is on top, even that can be hidden.
- Fix: in Conversation, bind `player.CharacterAdded` and the Humanoid `Died` to `close()` for any `cur`. In SocialService also end the session for that role on `CharacterAdded` (send `social_end` once).

### 5. Vs Mode starts while the player is busy (MED-HIGH)
- `social_start` arrives whenever the matchmaker finds a partner (SocialService.lua:568, NPC after `NPC_WAIT`). `Conversation.vsStart` (CV:551-618) calls `UI.closeModal()` (kills a minigame/purchase confirm the kid is in), anchors the root even if the kid is seated or on a Hoppr/bus ride (no `Rooms.standUp` like ConversationService.lua:132), and ignores Cutscene and Photo mode.
- `ConversationService.readyToTravel` (ConversationService.lua:251, used by LifeService.lua:199/222 and GainService.lua:515) only looks at NPC conversation sessions, not Vs `inSession`. A bus or Hoppr teleport can move the player in the middle of a Vs scene; the camera uses frozen CFrames from `vsStart` (CV:562-573) so it then films an empty place.
- Fix: `readyToTravel` also returns false when `SocialService.active(player)`. On the client, if a modal/minigame/Cutscene is up, answer `social_start` with a decline (new remote) or fall back to the old pop-up (`Stations.socialStart`). Call `standUp` before anchoring.

### 6. Vs Mode timer is out of sync with the server (MED)
- Server gives each step `STEP_SECONDS + 1` from the moment it sends `social_step` (SocialService.lua:587-597). The client runs the step inside a serial queue (`vsRun`, CV:505-522): the previous line must finish typing first, and then the prompt types out (CV:630) before the 15 s deadline starts (CV:635). On a slow queue the client shows choices after the server already picked randomly. The kid taps, the client types "You: ..." (CV:649) but `social_answer` is rejected (`sess.waiting` is nil, SocialService.lua:717) and nobody tells them.
- Fix: send `deadline = workspace:GetServerTimeNow() + seconds` and show a countdown from that; if the queue is behind, skip the typewriter (set `c.skip = true`). Show a "too slow, they picked for you" line when the answer is rejected.

### 7. Vs Mode partner leaves or is far away (MED)
- CV:564-571: partner position is frozen at start (`npc = oroot.CFrame`). If the partner walks off, resets or leaves, the "over their shoulder" shot (CV:176-182) looks at an empty spot. The server swaps to an NPC silently for the rest of the steps (SocialService.lua:580-596) while the transcript/`partnerName` still shows the old display name (`p.DisplayName` of a removed player).
- `social_wait` text never changes to "X left, an NPC took over".
- Fix: server sends `partnerLeft = true`; client sets `c.alone = true` and uses wide shots. Re-read partner root each shot (`Players:GetPlayerByUserId(partnerId)`), falling back to the last CFrame.

### 8. Cutscene `finish()` uses stale character and camera (MED)
- CS:33-34 and CS:73-76: `char` is captured at start. If the player respawns during a cutscene (death, admin reset, Unstuck, fall into the void), `finish()` sets `cam.CameraSubject` to the old destroyed Humanoid, so the camera does not follow the new character.
- CS:120-125: after the last shot the thread waits for the fade then calls `finish()`. `playing` is a module-wide flag, not per run. If the player presses Skip during that 0.5 s fade and another cutscene starts at once, the old thread's late `finish()` cancels the NEW cutscene (it only checks `playing`).
- CS:98-126: no `pcall`. Any error (`shots[1]` nil, camera replaced) leaves a black screen (the fade frame starts opaque, CS:52) and `playing = true`, which also blocks every later cutscene and tells the Watchdog it is a deliberate lock. Skip still works, but nothing recovers by itself.
- Fix: re-read `player.Character` and `workspace.CurrentCamera` inside `finish`; use a `runId` token; wrap the thread in `xpcall` with `finish` in the handler; add a hard time limit (sum of shot times + 5 s).

### 9. Cutscene leaves the player free to walk and use prompts; news and Lose effects leak through (MED)
- CS never disables controls, so the kid can walk, jump and press ProximityPrompts (talk to an NPC, ride the bus, start a minigame) while the camera is far away and the HUD is hidden. Intro flyover (CM:181-186) happens on first join, exactly when kids mash buttons.
- `screenBusy()` (CM:220-232) does not know about a Cutscene, so server toasts that arrive during one go into the hidden `UI.gui` and are lost. (It only waits for Effects overlays inside `UI.gui`.)
- `LoseFX.isBusy` is set to `Conversation.isOpen()` only (CM:27-29) although the comment in `LoseFX.lua:18` says "conversation or cutscene": brain lag and joke ads can pop during a Cutscene and Photo mode.
- Fix: in `Cutscene.play` disable controls (`require(player.PlayerScripts.PlayerModule):GetControls():Disable()`, re-enable in `finish`), set `ProximityPromptService.Enabled = false` and restore, add Cutscene to `screenBusy` and `LoseFX.isBusy`.

### 10. Effects overlays are long, unskippable and do not block input (MED)
- `comeback` about 11 s (FX:509-560), `prize` about 20 s before any button (FX:588-660, also needs the kid to wait through credits), `worldsSmartest` about 20 s with the title picker only at the very end and no timeout (FX:755-852), `launch` about 9 s (FX:719-753), `death` about 6 s, `voidFall` and `castleEnter` short. None has Skip, none sets `Active = true` on the overlay, so taps and the thumbstick still go through and the kid walks around blind.
- `worldsSmartest` has no timeout: if the player never taps Man/Woman/Person the overlay stays; and it is also in `UI.gui`, so a hidden HUD hides the picker.
- `Effects.banCutscene` never removes its overlay and its gear/light loop (FX:216-230) runs at 20 Hz until the kick (`AdminService.lua:327` waits 4.5 s then `BanAsync`). If the ban call fails (rank, Studio) it spins forever.
- Fix: shared helper `Effects.scene(name, builder)` that creates the own ScreenGui, `Active` blocker, a Skip button (hold-to-skip), a max lifetime and `Destroy()` in a finally. Skipping jumps to the end state, it does not abort the reward.

### 11. Scene overlays call `UI.closeModal()` and kill whatever the kid was doing (MED)
- FX:368 (eureka), 510 (comeback), 589 (prize), 756 (worldsSmartest), 891 (promoted), CM:411 (launch), CM:419 (voidFall), CV:441 and CV:555. Eureka and promoted fire from job tasks, so a kid in the middle of a purchase confirm or minigame loses it. At least queue the scene until the modal closes unless it is a death/ban.

### 12. Conversation camera tween is not cancelled on close (LOW-MED)
- CV:156-161 `tweenCam` creates a TweenService tween on `workspace.CurrentCamera` and never stores it. `close()` (CV:346-353) sets `CameraType = Custom` but the tween keeps writing `CFrame` for up to `CC.CameraTween` seconds, so the camera jerks after closing. Store the tween in `cur` and `:Cancel()` it in `close`; same for `Effects.death` (FX:90) and `worldsSmartest`.
- CV:46-62 `hideFriends` collects friend parts once at open: a friend that spawns during the scene stays visible in the shot.

### 13. Tutorial interplay (LOW-MED)
- TU:831-845: `Tutorial.moment` sets `momentBusy = true` and only the note's `onDone` clears it. `Tutorial.stop()` (TU:777-790, called on death or path change) destroys the stage without calling `onDone`, so the three "moment" notes (flashy, stress, money) never show again until rejoin.
- TU:283-300: flyover `RenderStepped` (see #2). `Tutorial.stop` sets Custom only when `camConn` exists, and `stopCam` is not called when the stage is destroyed externally.
- TU:704-720 (`runStep`): "wait a moment and retry" comment but the dead check simply `return`s, so the sequence only resumes on the next state change. It also never checks `Cutscene.isPlaying()` or `Conversation.isOpen()`.
- TU stage lives in `UI.gui` (ZIndex 100): any scene that hides the HUD also hides the tutorial card but the music duck (TU:246) and blur (TU:263) stay on until the note closes.

### 14. Intro flyover uses a missing character position (LOW)
- CM:181-186 + CS:34-35: the first `state` can arrive before `player.Character` exists; origin falls back to `(0,5,0)`. The shots are offsets from the plaza spawn so it looks fine today, but if the spawn moves the flyover films the wrong place. Wait for the character (`player.CharacterAdded:Wait()` with a timeout) or use an absolute `origin` in `Config.Cutscenes.Intro`.
- `introSeen` is saved only in `onDone`; a kid who quits at second 3 sees it again. Fine, but note it for the rewrite.

### 15. Server-side gaps (LOW-MED)
- `ConversationService` only stops a session on CharacterAdded (ConversationService.lua:285-300); there is no timeout. If the client's `conv_close` is lost, the player is "Busy" until respawn (ConversationService.lua:91-94).
- `LoseService.death` (LoseService.lua:408-425) does not stop an open conversation or Vs session; the dead player stays in the scene for ~5 s and Unstuck (Main.server.lua:176) refuses (`hum.Health <= 0`).
- `SocialService.PlayerRemoving` (SocialService.lua:951-955) clears queues but `runSession` keeps running if both humans leave (harmless but burns task time; add `if not (a or b alive) then break`).

### 16. Performance and memory (LOW-MED, phones)
- `worldsSmartest` (FX:769-793): 36 Parts, each with its own `SurfaceGui` + `TextLabel` (`TextScaled`) + a tween, all with Fabric material, parented to `workspace`. TextScaled on 36 SurfaceGuis is the most expensive thing in the whole scene on a phone. Use one `Part` template cloned with a static Decal/Texture or a `BillboardGui` pool of about 12, and cap by `UI.isPhone()`. If the scene errors midway the parts leak (no `pcall`/Debris).
- `Effects.confetti` (FX:57-77) spawns 70 frames + 70 tweens each call, and is called twice in a row in several scenes (inventionUnlocked, makeover, prize, geniusFinale). Cap to about 40 on phones, reuse a pool; it also keeps running when `UI.gui` is hidden.
- `Effects.launch` 60 star tweens + `rays` (12 rotated frames, 900x900) rotating at 30 Hz (FX:358-363) are fine on PC; on a weak phone use `UI.effects()` and `LowGraphics` to halve them.
- `InventionHall.lua:57` keeps a `RenderStepped` connection for the whole session even with no tooltip; connect only while `tip` exists.
- `Conversation.vsOff` (CV:503) grows per Vs session. Trivial.

## What a rewrite as real 3D cutscenes must take care of
(See `docs/Cutscene research.md` for the wanted look.) Build it as ONE runner, not more one-off scripts.

1. One scene owner and one cleanup. A `Scene` module with `Scene.play(def)` that takes a token, binds the camera with `RunService:BindToRenderStep("BrainScene", Enum.CameraRenderPriority.Camera.Value + 1)` and always releases in a finally (`xpcall`). Save and restore `CameraType`, `CameraSubject`, `FieldOfView`, `CameraOffset`, `Lighting` effects (blur, DoF, color correction), ducked music, HUD owners (see #1), controls, ProximityPromptService, `LocalTransparencyModifier` on the real character.
2. Abort paths: Skip (Backspace, ButtonB, on-screen button at 48 px), CharacterAdded, Humanoid.Died, PlayerRemoving of a Vs partner, death/ban from the server, a hard max duration, and the Watchdog (it must know a Scene is active and must be able to call `Scene.abort()`).
3. Server awareness: `InScene` attribute, so server systems (conversations, Vs matching, bus/Hoppr travel, minigame start, tours, prizes) wait. Rewards must be given by the server at the START of the scene, not at the end, so Skip or a disconnect never loses them (today `prize`, `inventionUnlocked`, Vs rewards are all granted before the show, keep it that way).
4. Cloned avatars. `Players:GetHumanoidDescriptionFromUserId` + `Players:CreateHumanoidModelFromDescription` are async and can fail: cache per user, time out after 3 s, fall back to a default R15/blocky model. Build clones client-side in a local `Folder` (never replicated), anchor, strip scripts, set `HumanoidDisplayDistanceType = None`, `NameDisplayDistance = 0`, and hide the real character with `LocalTransparencyModifier` (as `hideFriends` does, CV:46-74) and restore it afterwards. The clone must match the CURRENT body: Gain/Lose outfits, work vest, uniform (`applyUniform`), and the blocky animal forms from `Services/AnimalForms.lua` (the animal parts are welded server-side, so the clone has to rebuild them or the animal path shows a human). Hide friends/pets (`FriendName` models) and billboards (CV:49-58). Vs partners: use their UserId, or a neutral NPC model when alone.
5. Animations: the sound/animation asset IDs are still 0 in Config, so do not depend on uploaded animations. Use Motor6D pose tweens (nod, wave, point, slump) as the baseline and let real `AnimationTrack`s override when an ID is set. If assets are used: `ContentProvider:PreloadAsync`, owned by the group/creator, stop and `Destroy()` tracks at the end.
6. Camera shots as data: `{ cframe or (subject, offset), fov, t, ease, text }`, a `clearSpot` wall check like CV:142-154, raycast against `Town` only. Honour `UI.reducedMotion()` and `UI.effects()` (hold still frames, no shake/flash), `reduceFlashing`.
7. World state: the scene stage must exist on the client. There is no StreamingEnabled today (checked), so far shots are safe; if streaming is ever enabled, call `player:RequestStreamAroundAsync(pos)` before a shot far from the character.
8. Perf budget on phones (80 percent of players): at most 3 clones, no `SurfaceGui` with `TextScaled`, no per-frame allocations in the render step (preallocate CFrames), cap particles (`Rate` <= 20, `Lifetime` <= 1.5), `Debris`/janitor for every spawned instance, fewer props in Low detail mode, captions in a plain `TextLabel` with `MaxVisibleGraphemes`.
9. UI: own `ScreenGui` per scene (`DisplayOrder` high, `ResetOnSpawn = false`, `ScreenInsets = None` for bars, and a safe-area-aware caption), never `UI.gui`. Letterbox size from `Config.Cutscenes.Letterbox`. Choices bottom-left with 1/2/3 and controller select, as now.
10. Rules from CLAUDE.md: kid-safe (cartoon POOF, no gore, no jump scares unless "Full" horror), preset text only, never scramble prices/odds/confirm buttons (LoseFX should stay off during a scene), Lose-path text degradation must still apply to choice text (server already does it via `Brain.degradeText`), animals get animal noises, and every scene works on both paths.
11. Testing hooks: an admin command per scene (`/scene <name>`), a test that fires two scenes back to back and one that respawns the player mid-scene, then asserts: camera Custom + subject = new Humanoid, `UI.gui.Enabled`, `TouchControlsEnabled`, no leftover `ScreenGui` named Cutscene/ConversationBars, no stray Parts in workspace.
