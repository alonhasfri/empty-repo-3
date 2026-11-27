# Cutscene research: real in-engine cutscenes with real avatars

Research only. No game code was changed. Written Nov 27 2026.

Where we are now (read from the repo):
- `Client/Cutscene.lua` is a camera-keyframe player: `Cutscene.play(shots, opts)`, shots are `{ pos, look, t, text }` offsets from the player (or `opts.origin`). It has letterbox bars, one caption line, a fade, and Skip (button, Backspace, gamepad B). It honours Reduced Motion / Effects 0 by dropping camera moves. It hides `UI.gui` and restores it. Used by the intro flyover, `Effects.lua` (World's Smartest / GeniusEnd, `Config.GeniusEnd.Shots`) and `InventionHall.lua`.
- It has NO actors, no animations, no sound cues, no per-shot actions, no shot types. The "explosion" and "brain" are emojis/UI.
- `Conversation.lua` (`vsStart`, around line 551) already does a cinematic Vs Mode: bars, camera cuts between "you" and "the other side" (the partner's real character if within 40 studs, else a spot 7 studs in front), typed lines, choices bottom-left, OBJECTION slam. It anchors your root part and hides the HUD. SocialService runs the session. `Config.VsCutscene = true`.
- So the plan is to extend, not rebuild: keep `Cutscene.lua` as the low-level player and add a `CutsceneDirector` layer on top (actors + actions), and let `Conversation.vs*` ask the director for its shots.

---

## 1. How good game cutscenes are made

### 1.1 Shot list and storyboard first
Professional game cinematics start with a storyboard / shot list: one row per shot with shot type, camera move, subject, length, what happens, sound. Game-specific extra: say where the player character stands and faces at the trigger point, and whether the scene stays in the player's perspective. (Sources below.)

### 1.2 Camera language (what each shot is for)
From Boords' guide:
- Establishing shot: wide, shows where we are. Open every scene with one.
- Full shot: whole body, shows movement and body language (use for the walk-out and dances).
- Medium shot: knees up, gestures plus background.
- Close-up: face fills the frame, for emotion and reactions. Extreme close-up: one small detail (an eye, the brain), use sparingly.
- Low angle (up shot): makes the subject big / powerful. High angle (down shot): small / powerless. Good for smart vs dumb framing.
- Over-the-shoulder (OTS): camera behind one character, framing the other; the staple of dialogue and debates.
- Two shot: both in frame, placement shows equality or hierarchy.
- POV: what a character sees.
Reaction shot (standard film practice, not covered by Boords): cut to a listener's face while someone else talks or something happens. It is cheap and carries most of the comedy.
Epic's Fortnite cinematics docs add: tight framing feels claustrophobic but immersive; a tracking shot follows the subject.

### 1.3 Pacing rules of thumb (for our kid audience)
- Whole cutscene 10 to 30 s. Anything over about 20 s needs a clear reason, and every cutscene needs Skip from the first frame.
- Shots: 1.5 to 4 s each; hold a reaction 1 to 1.5 s; the "big moment" (the explosion) gets a quick cut or camera shake, not a long hold.
- Rhythm: wide, medium, close, payoff, wide. Cut on action (cut at the moment the character starts moving).
- Letterbox bars (the repo already does 11% bars) tell the player "this is a movie, you cannot move". Always give the controls back with a fade.
- Never trap the player: a Skip that always works, a failsafe timeout, and restore camera/humanoid state in one `finish()` even on error.
- Keep text short and read by 7 year olds; captions at the bottom bar (already done); every spoken joke also appears as a caption.

### 1.4 In-engine vs pre-rendered
- Pre-rendered (video) gives film look but Roblox cannot play arbitrary video cheaply (VideoFrame only with uploaded, moderated assets), cannot show the player's own avatar and costs production time. Not suitable.
- In-engine real-time cutscenes use the live world, the player's real avatar and outfit, and cost nothing to store. This is what almost every Roblox game does. Downsides: must work on weak phones and with unpredictable streaming and ping.

### 1.5 How popular Roblox games do it
The DevForum thread "How should I handle cutscenes like Outlaster does?" gives the common architecture: one Cutscene controller script plus one ModuleScript per cutscene (cutscenes are mostly stored CFrame data), a `PlayCutscene(name, props)` that requires the module, camera moved with TweenService, playback on the client, triggered by a RemoteEvent (client listens with OnClientEvent). Other threads agree: set `CameraType = Scriptable`, tween the camera CFrame, chain shots, then restore `CameraType.Custom`. Known pitfalls from the same threads: tweens that stutter if the camera is also being driven by the default camera script, chained tweens failing intermittently (so drive shots from a single loop with explicit timing, as our `Cutscene.lua` does), and forgetting to restore the camera. A "CutsceneService" with Bezier curves exists on the DevForum for smooth paths; a nice-to-have, not needed.

### Sources for section 1 (title, URL)
- Boords, "Storyboard shot types and camera moves": https://boords.com/blog/storyboard-shot-types-and-camera-moves
- Epic Games, "Making Cinematics 3: Camera Movement and Framing in Unreal Editor for Fortnite": https://dev.epicgames.com/documentation/en-us/uefn/making-cinematics-3-camera-movement-and-framing-in-unreal-editor-for-fortnite
- Epic Games, "Making Cinematics 1: Composition Techniques": https://dev.epicgames.com/documentation/en-us/uefn/making-cinematics-1-composition-techniques-in-unreal-editor-for-fortnite
- Toon Boom, "Camera shots": https://learn.toonboom.com/modules/storyboard-concepts/topic/camera-shots
- Game Developer, "How to build a better cutscene": https://gamedeveloper.com/art/how-to-build-a-better-cutscene
- DevForum, "How should I handle cutscenes like Outlaster does?": https://devforum.roblox.com/t/how-should-i-handle-cutscenes-like-outlaster-does/1770927
- DevForum, "How to Create Camera Cutscenes": https://devforum.roblox.com/t/how-to-create-camera-cutscenes/1629318
- DevForum, "How do you make a cutscene w/ Tweening?": https://devforum.roblox.com/t/how-do-you-make-a-cutscene-w-tweening/224739
- DevForum, "CutsceneService - Smooth cutscenes using Bezier curves": https://devforum.roblox.com/t/718571

Honesty note: I read the Boords, Outlaster and Roblox docs pages. The Game Developer / Epic / Toon Boom items came from search snippets, and the pacing numbers in 1.3 are my own working rules, not quotes.

---

## 2. Roblox techniques (checked against create.roblox.com where the page said so)

"Verified" = stated on the docs page I read. "Unverified" = the docs page did not cover it; test in Studio before relying on it.

### 2.1 Making an actor that looks like the player
- Best option for the local player's own cutscene: `Players:CreateHumanoidModelFromDescriptionAsync(description, rigType, assetTypeVerification)` returns a fresh Model with a Humanoid (yields; the non-Async version is deprecated). Verified. Get the description with `Players:GetHumanoidDescriptionFromUserIdAsync(userId)` (appears in the docs sample; client/server access not stated, so test; if the client cannot call it, have the server send the description, or just clone the character).
- Alternative: `character:Clone()`. Works only if `Archivable` is true; if false, `Clone()` returns nil (verified). The docs do not say what a player's character defaults to, so set `character.Archivable = true` before cloning, in a pcall, and fall back to the description route if it still returns nil.
- Clone approach captures exactly what the player is wearing now (including our animal forms from `AnimalForms.lua`, welded blocky bodies). The description approach gives a clean avatar. For "your Roblox character explodes" use the clone so it is visibly the same character.
- Rig type: use R15 for the description route (the docs sample uses `Enum.HumanoidRigType.R15`). Clone keeps whatever the player has.
- Rules for actors: set `Anchored = true` on `HumanoidRootPart` while posing (or `PlatformStand`), set `Humanoid.DisplayDistanceType = None` and `HealthDisplayDistance = 0` (no name or health bars), `Humanoid.EvaluateStateMachine = false` if you do not want the state machine fighting animations (unverified; test), remove or disable the cloned `Animate` and any scripts (`for _, d in actor:GetDescendants() do if d:IsA("LuaSourceContainer") then d:Destroy() end end`), put actors in a folder `workspace.CutsceneActors` (client-only, see 2.8).
- Hide the real character during the scene: set each BasePart's `LocalTransparencyModifier = 1` (client only, no replication, and it undoes itself cleanly) or move nothing and just leave the real one anchored off-camera. Do not teleport the real character far away (streaming and fall damage).
- Stage position: cloned actor is placed with `actor:PivotTo(cf)`. Use a staging CFrame stored by the director (a "set" Model with named `Marker` Parts: `Podium_A`, `Podium_B`, `Judge`, `CamA`). This is how we reuse the existing courtroom/stage props from Rooms.

### 2.2 Animations
- Load: `humanoid:FindFirstChildOfClass("Animator")` (create one if missing), `Animation.AnimationId = "rbxassetid://..."`, `animator:LoadAnimation(anim)` returns an `AnimationTrack`, then `track:Play(fadeTime, weight, speed)`. Verified (docs "Using animations"). The Animator page marks LoadAnimation as "Simulation Access". `LoadStreamAnimation` was not on the page, so ignore it.
- Animation events: `track:GetMarkerReachedSignal("Name")` fires when a marker in the animation is reached (verified). Great for syncing "BOOM" to the exact frame the character leaps.
- Free-to-use animation IDs: the docs only say "catalog animations or your own". Animations are permissioned: an animation asset only plays in a game if Roblox owns it or the experience/group owns it or it is public to that experience. Roblox's own default R15 animations (the ones used by the `Animate` script: idle, walk, run, jump, fall, climb, wave, point, cheer, laugh, dance 1 to 3, sit) are usable by every game. Commonly cited emote IDs (unverified here, confirm in Studio with `animator:LoadAnimation` and the Output): wave 507770239, point 507770453, cheer 507770677, laugh 507770818, dance1 507771019, dance2 507776043, dance3 507777268. Idle R15 507766666, walk 507777826, run 507767714, jump 507765000, fall 507767968, sit 2506281703 (all unverified).
- Our own animations: the repo has `generate_animation` in the Studio MCP (not used in this research task) and the Animation Editor. Anything we make ourselves must be uploaded and owned by the game's creator account/group; we cannot upload from here. The wrong-owner case fails silently with a warning in Output, so every action must tolerate "animation failed to load" (just skip it, never block the scene).
- Procedural fallback (no asset IDs needed, the safest for "brain explodes"): drive `Motor6D.Transform` or `Motor6D.C0` with TweenService on the actor for simple poses (arms up, head back, shake). Or build a `KeyframeSequence` in code, then `KeyframeSequenceProvider:RegisterKeyframeSequence(seq)` returns a content id that you put in an `Animation.AnimationId`. The docs page says the provider is "Not Replicated", so register on the same client that plays it. Playing runtime-registered sequences on a client Animator is consistent with that page but not explicitly documented: test it. Keep procedural poses to a small helper library (`Poses.armsUp`, `Poses.wobble`).
- Priority: set `track.Priority = Enum.AnimationPriority.Action` (or Action4) so emotes override idle; the cloned `Animate` script must be removed or it will fight (see 2.1).
- Phone budget: animation tracks are cheap; keep to a few simultaneous tracks per actor.

### 2.3 Scripted camera
- `camera.CameraType = Enum.CameraType.Scriptable`, set `camera.CFrame` each shot; tween CFrame with `TweenService:Create(camera, TweenInfo.new(t, Sine, InOut), {CFrame = cf, FieldOfView = fov})`. Camera has `CFrame`, `FieldOfView` (verified). `Focus` exists (affects some effects).
- Restore: set the type back to `Custom` and `CameraSubject = humanoid` in `finish()` (already done in `Cutscene.lua`). Tip from the repo's CLAUDE.md: `execute_luau` resets Scriptable to Custom in tests.
- Camera language in code (suggested constructors, all return a CFrame given actor positions):
  - `Cam.wide(center, dist, height, yaw)`
  - `Cam.close(actor, "head", dist)` (looks at `Head`)
  - `Cam.ots(from, to, shoulder, dist)` = camera behind `from`'s shoulder looking at `to`
  - `Cam.two(a, b, dist)`, `Cam.low(actor, dist)`, `Cam.orbit(center, r, a0, a1)`
- Shake: add a small random offset per RenderStepped for 0.3 s (skip when Reduced Motion). Depth of field: add a `DepthOfFieldEffect` to `Lighting` for close-ups, destroy at the end (do not use on low detail mode).
- Field of view: 70 default; 40 to 50 telephoto for close-ups, 85 to 100 for wides and "dumb" fisheye jokes.
- Smooth moves: a single `RunService.RenderStepped` loop that interpolates between two shot CFrames beats chaining `Tween.Completed`, which the DevForum threads report as flaky. The existing player uses one tween per shot plus `task.wait(shot.t)`, fine for now.

### 2.4 Breaking a character apart (cartoon, kid-safe)
Hard rule from CLAUDE.md: kid-safe, no gore. So do NOT break joints and fling limbs with realistic physics. Preferred cartoon approach, in order:
1. "Poof": hide the actor (LocalTransparencyModifier 1 / `Transparency = 1`) the instant a big white-yellow cartoon cloud `ParticleEmitter:Emit(n)` and confetti burst fire. The audience reads this as an explosion with no body parts at all.
2. "Pop apart": spawn 6 to 8 colourful chunky stand-in parts (the actor's own body parts cloned, `CanCollide = false`, small `ApplyImpulse` upward and out, `Transparency` fade over 1.2 s, then `Debris:AddItem`). They look like cartoon pieces / stars / stuffing. `BasePart:ApplyImpulse(Vector3)` works on unanchored parts; clone parts into the client-only folder so nothing replicates.
3. Avoid `Humanoid:BreakJoints()` / `BreakJointsOnDeath` on a real character: it kills the real avatar (and would trigger our real death/respawn logic). Only use on a cloned actor if wanted, and still hide it quickly. Breaking joints on a clone is safe for gameplay but looks more violent than the poof.
- `Explosion` instances: we do not want the damage or force. Docs: `BlastPressure = 0` (no push), `DestroyJointRadiusPercent = 0` (no joint breaking), `ExplosionType = NoCraters`, `Visible = false` if using our own visuals, never connect `Hit`. Verified from the Explosion docs page. Even so, an Explosion created on the client has no effect on others; recommended: skip `Explosion` and use particles only, so there is no way to hurt a player.
- Particles: `ParticleEmitter` with `Rate = 0` and `:Emit(count)` for a one-shot burst. Phone-friendly numbers: 30 to 60 particles per burst, lifetime under 1.5 s, one or two emitters. Reduced Motion: replace shake and flash with a simple fade and caption.

### 2.5 A brain character with legs that walks away
- Build once as a `Model` in ReplicatedStorage/Assets (or a code-built blocky one like `AnimalForms.lua`): a big pink brain (a MeshPart with a brain mesh, or a Sphere with wavy ridges; the repo has no brain mesh yet, and Studio MCP's mesh tools were not used here), two eyes, two little legs and arms as Parts.
- Make it a real rig so it walks: `Humanoid` + `HumanoidRootPart` + `Motor6D`s, `RigType = R6` style 6-part rig (Torso = the brain, Head hidden or tiny, two legs, two arms) so the stock R6 walk animation and `Humanoid:MoveTo()` just work. R6 default walk id is 180426354 (unverified). Alternative without assets: leg swing via tweening hip Motor6D `C0` angles in a loop while the model slides along a path using `MoveTo` or a CFrame tween.
- Walking: `humanoid:MoveTo(target)`; wait for `MoveToFinished` or `task.wait(duration)`. For a short scripted walk of 8 to 15 studs a straight `MoveTo` or a CFrame tween is fine, no pathfinding needed. Unanchored actors on a client-only folder: network ownership is local, so physics is smooth.
- Keep it silly and readable: big eyes, tiny shoes, a bandage if it is the Lose ending.

### 2.6 Sound sync
- Use `SoundService` or a `Sound` parented to the actor/camera part; our `Config` already holds sound IDs (many are still 0, so every sound cue must be a no-op if the id is 0).
- Sync sound to action with animation markers (`GetMarkerReachedSignal`) or simply by the director's timeline (each action has an `at` time within its shot).
- Duck the background music with a SoundGroup volume tween while a cutscene plays.
- Also show a caption for every sound-carried joke (accessibility and muted phones).

### 2.7 Letterbox, skip, Reduced Motion (already in Cutscene.lua; keep)
- Bars and skip exist. Add: a skip button that appears immediately and a "hold to skip" is not needed. Backspace / ButtonB bound. Add a "seen before" flag so repeat plays of the Lose/Gain endings show a smaller Skip prompt and are skipped after the first time if the player chose "Always skip cutscenes" in Settings.
- Reduced Motion / Effects = 0 (`UI.reducedMotion()`, `UI.effects()`): no camera flight, no shake, no flashes, no particles above 10, static camera shots cut (not tween) every shot, actors still act (animations are fine) or the scene falls back to caption-only.
- Photosensitivity: no flashing white faster than 3 flashes a second; the "explosion" flash is one 0.15 s fade, not a strobe.

### 2.8 Client-only vs server-replicated, and multiplayer
- Cutscenes should be CLIENT-SIDE: actors are created locally in a local folder (`workspace.CutsceneActors`, name it with the player's UserId), the server never sees them, nothing replicates, nothing can hurt anyone, and an exploit cannot affect others. This is the same approach as the Outlaster thread (server fires a RemoteEvent, client plays).
- The server only sends a tiny message `{ scene = "VsDebate", seed, t0 = workspace:GetServerTimeNow(), who = {userIdA, userIdB}, args }`.
- Both players in Vs Mode: each client builds the same scene from the same message and starts at `t0` (use `workspace:GetServerTimeNow()` to line up within a few 100 ms). Each client builds its OWN clones of both avatars (use `CreateHumanoidModelFromDescriptionAsync` with each player's description, which each client can fetch by userId, or the server includes the HumanoidDescription is not needed). Shots are identical, only the "you" camera flips so you are always the near side.
- Interactive Vs Mode: the choices are decided on the server (SocialService stays the authority). Each decision's outcome arrives as a message that the director appends as new shots ("round N: A speaks, B reacts, judge nods"). Do not run the debate as one long pre-timed film; run short director "beats" of 3 to 6 s per round, each triggered by the server.
- Real characters: the real characters stay where they are, anchored (as `Conversation.vsStart` does), and are hidden locally while their actors perform. Restore on finish.
- StreamingEnabled: the set (courtroom, stage) must be in the player's streamed radius or built locally as a client-only prop set; put the stage far above/away from the town and teleport nothing. Use `workspace:RequestStreamAroundAsync(position)` before the cutscene if the stage is a real map location, and fall back to a client-built set if the request times out.
- Phone performance: max 3 actors + 1 props set, <= 100 parts for props, no more than 2 emitters active, no shadows from our own lights, no DepthOfField when `Low detail` is on, cap `FieldOfView` tweens, destroy everything in `finish()`, and preload with `ContentProvider:PreloadAsync({animations, sounds})` while the screen is faded to black (cap at 3 s then start anyway).
- Failure safety: wrap each action in `pcall`; a 45 s watchdog calls `finish()`; if the character dies/leaves mid-scene call `finish()`.

### Sources for section 2
- Roblox Docs, Players (CreateHumanoidModelFromDescriptionAsync, CreateHumanoidModelFromUserIdAsync): https://create.roblox.com/docs/reference/engine/classes/Players
- Roblox Docs, Using animations (Animator:LoadAnimation, markers): https://create.roblox.com/docs/animation/using
- Roblox Docs, Animator: https://create.roblox.com/docs/reference/engine/classes/Animator
- Roblox Docs, KeyframeSequenceProvider: https://create.roblox.com/docs/reference/engine/classes/KeyframeSequenceProvider
- Roblox Docs, HumanoidDescription: https://create.roblox.com/docs/reference/engine/classes/HumanoidDescription
- Roblox Docs, Instance (Archivable / Clone): https://create.roblox.com/docs/reference/engine/classes/Instance
- Roblox Docs, Explosion (BlastPressure, DestroyJointRadiusPercent, Visible): https://create.roblox.com/docs/reference/engine/classes/Explosion
- Roblox Docs, Camera (CFrame, FieldOfView, Focus): https://create.roblox.com/docs/reference/engine/classes/Camera
- DevForum threads listed in section 1 sources.

Not checked (flag for the Studio session): animation id permissions, `RequestStreamAroundAsync` behaviour, client use of `GetHumanoidDescriptionFromUserIdAsync`, runtime KeyframeSequence playback on clients, default `Archivable` of a character, `EvaluateStateMachine` use.

---

## 3. Design: CutsceneDirector

### 3.1 Goals
- Same low-level player (`Cutscene.lua`: bars, fade, skip, caption, HUD hide, Reduced Motion). The director adds ACTORS, per-shot ACTIONS, camera shot constructors, sound, and cleanup.
- Data-driven: each scene is a ModuleScript returning a table, like the DevForum "one module per cutscene" pattern. Scenes live in `ReplicatedStorage/Shared/Scenes/*.lua` so server and clients agree.
- Backwards compatible: old `Cutscene.play(shots, opts)` keeps working. Internally the director can call `Cutscene.play` with a generated shot list, or `Cutscene.playScene(scene, args)` wraps it.

### 3.2 Scene format

```lua
-- ReplicatedStorage/Shared/Scenes/BrainExplodes.lua
return {
  id = "BrainExplodes",
  maxSeconds = 28,           -- watchdog
  skippable = true,          -- always true; false is not allowed
  music = "Sad_Tuba",        -- optional Config sound key, ducks the HUD music
  set = "SelfStage",         -- name of a prop-set builder in Scenes/Sets (client-built)

  actors = {                 -- who is in the scene
    me    = { kind = "player", userId = "$local", at = "Mark_Me" },     -- cloned real avatar
    brain = { kind = "rig", model = "BrainWalker", at = "Mark_Me", hidden = true },
    judge = { kind = "rig", model = "Judge",       at = "Mark_Judge" },
  },

  captions = { "Oh no...", "BOOM!", "Your brain gets up. It walks out." },

  shots = {
    { name = "wide", cam = { type = "wide", target = "me", dist = 22, height = 7, fov = 70 },
      move = { type = "dolly", dist = -4 }, t = 3.0, caption = 1,
      actions = {
        { at = 0.0, actor = "me", do_ = "anim", id = "idle" },
        { at = 1.0, actor = "me", do_ = "pose", pose = "wobble" },
      } },
    -- ...
  },
  onEnd = { restore = true },  -- always: show real character, camera back to Custom, HUD back
}
```

Action verbs (`do_`; trailing underscore because `do` is reserved):
- `anim { id | key, loop, speed, fade }`, `stop`, `pose { pose, t }` (procedural Motor6D poses), `move { to = Vector3|marker, t | speed }` (MoveTo/tween), `face { target }`, `show`, `hide`, `swap { from, to }` (hide one actor and show another at the same spot, used for "brain walks out"),
- `burst { emitter = "Poof"|"Confetti"|"Stars", at = actor|marker, count }`, `shatter { actor, pieces, impulse }` (cartoon pieces, section 2.4), `flash { t }`, `shake { amount, t }`,
- `sound { key, vol }`, `say { actor, text }` (speech bubble BillboardGui + caption),
- `prop { spawn = "Newspaper", n, path, t }` (flying props), `emote { actor, "cheer" | "laugh" ... }`,
- `wait` (pure timing).
Every action has `at` (seconds from the start of the shot). Unknown ids/verbs are skipped with a warning, never errors.

### 3.3 Module API

```lua
local Director = require(Client.CutsceneDirector)

Director.register(sceneModule)            -- usually auto from Shared/Scenes
Director.play(sceneId, args, opts) -> handle
   -- args: { me = player, other = player?, seed, t0 = serverTime, result = "win"|"lose",
   --         extra = {...} } ; opts: { onDone, onSkip, startAt }
handle:skip()                  -- same as the player pressing Skip
handle:append(shots)           -- add shots at runtime (Vs Mode beats from the server)
handle:setCaption(text)
handle.Finished                -- BindableEvent-like signal (Connect/Wait)
Director.isPlaying() -> boolean   -- includes Cutscene.isPlaying()
Director.stopAll()                -- on death/leave/teleport

-- building blocks (usable by Conversation.vs* too)
Director.Cam.wide/close/ots/two/low/orbit(...)    -- return CFrames (section 2.3)
Director.Actors.fromPlayer(player) / fromRig(name) / fromDescription(desc)
Director.Poses.get(name)                          -- procedural poses
Director.Fx.burst / shatter / confetti / shake / flash
```

Internals (one run loop, all on the client):
1. Fade to black, preload (3 s cap), build `set` and actors into `workspace.CutsceneActors_<userId>` (hide real character via LocalTransparencyModifier, anchor real root, as `Conversation.vsStart` does).
2. Hand the camera and bars to `Cutscene` (extend it with `Cutscene.begin(opts)` / `Cutscene.cut(cf, fov, t, easing)` / `Cutscene.setCaption(text)` / `Cutscene.finish()` instead of the monolithic `play`; keep `play` as a thin wrapper).
3. For each shot: set camera (cut or tween), schedule its actions with `task.delay(at)`, wait `t` (or until the skip flag), cancel pending tasks.
4. `finish()` in a `pcall`/`xpcall` finally-style: destroy actors/set/fx, un-hide the real character, un-anchor, restore camera and HUD, fade up, `onDone`.
5. Reduced Motion / Effects 0 / Low detail: cut instead of tween, no shake/flash, bursts capped at 10, no DepthOfField; scene still plays with captions (actors still act).
6. Network: the server fires `Net.send(player, "scene", { id, args })`. The server validates that the scene can be triggered (ending reached, session active) and never trusts client "scene finished" messages for gameplay results; the gameplay result was decided by the server before the scene starts.

### 3.4 How it fits the repo
- `Cutscene.lua`: split into `begin/cut/setCaption/finish` plus the existing `play` wrapper (shots with `pos/look/t/text`) so `Config.Cutscenes.Intro` and `Config.GeniusEnd.Shots` keep working with no data changes.
- `Config.Cutscenes`: add `ShotDefaults`, `ShakeMax`, `ParticleCap`, `Watchdog`.
- `Content.Cutscenes`: new captions per scene (preset text only, kid-safe).
- `Effects.lua`: the 0-cell ending calls `Director.play("BrainExplodes")` and falls back to the old emoji ending if the director or assets fail (so nothing regresses).
- `Conversation.lua` `vsStart`: keeps its choice UI; replace its ad-hoc `shot("wide")` camera spots with director cameras and add real actors.
- Settings: "Skip cutscenes after the first time" toggle, uses `UI.reducedMotion()`.
- Test plan (Studio, per CLAUDE.md): play each scene on PC and phone size, press Skip at every shot, die/leave mid-scene, run twice in a row, run with Reduced Motion, and check Output for red errors. Test Vs Mode with two clients (Studio local server with 2 players).

---

## 4. Shot lists

Conventions: times are seconds from the scene start; cam = type (target, distance); FOV in brackets. All visuals are cartoon, no gore, no horror unless the player chose Full horror.

### (a) The 0-cell "brain explodes" ending (about 22 s)
Story: the player hits 0 cells. Their avatar slumps, wobbles, goes POOF into confetti and cartoon stars. A little pink brain with tiny legs and big eyes stands where they were, looks around, shrugs, gets up, and walks out of the town gate while the camera lets it go. Fade to the existing ending card. Meant to be funny, not scary.

Actors: `me` (cloned real avatar), `brain` (hidden R6-style brain rig), `crowd` (optional 3 NPC pedestrians). Set: the player's current street, a plain stage ring (client-built floor decal and two lamp posts).

| # | Time | Shot / camera | Action | Sound | Caption |
|---|------|---------------|--------|-------|---------|
| 1 | 0.0-3.0 | Establishing wide, high angle, 22 studs back, FOV 70, slow dolly in 4 studs | `me` stands, idle, then sways (pose `wobble`) | low tuba wobble | "Brain cells: 0." |
| 2 | 3.0-5.0 | Medium front on `me` from chest height, FOV 55 | `me` looks up, eyes wide (emote), arms flail | rising whistle | "Uh oh." |
| 3 | 5.0-6.5 | Extreme close-up on `me` head, FOV 40, tiny shake | head puffs up (scale tween Head 1 to 1.6), pose `puffed` | riser to a stop | "" |
| 4 | 6.5-8.5 | Fast wide, low angle, 15 studs back, FOV 85, hard cut | action: `flash` (0.15 s soft white), `burst` Poof + Confetti + Stars at `me`, `shatter me` into 6 cartoon pieces fading out, `shake 0.6` | BOOM (cartoon pop) | "BOOM!" |
| 5 | 8.5-11.0 | Wide stays, no move; confetti falls | pieces fade; `brain` appears (`swap`) with a "pop" scale-in from 0 to 1; `brain` looks around, pose `shrug` | tiny "boing" | "..." |
| 6 | 11.0-13.0 | Close-up on `brain` face, FOV 45 | eyes blink twice, `say` "Huh?" bubble | squeaky "huh?" | "Your brain is still here." |
| 7 | 13.0-15.0 | Medium side on `brain`, FOV 60 | stands up straight (pose `stand`), stretches, a bandage-style plaster slaps on (cute) | stretch squeak | "It gets up." |
| 8 | 15.0-20.0 | Tracking shot beside `brain` (full shot), FOV 65, camera moves with it, then slowly pulls back | `brain` walks 12 studs toward the gate, leg animation (R6 walk or `leg swing` pose), waves bye over its shoulder at 17.5 s; `crowd` stare | cheerful marching ukulele | "It walks out." |
| 9 | 20.0-22.0 | Final wide from behind, brain small in the distance, FOV 70 | `brain` exits through the gate and fades | music out | (fade to existing ending card) |

Respawn handling: real character stays anchored, hidden locally and is restored in `finish()`; the server still owns death/respawn and the "comeback" cutscene already in LoseService (`comebackCutscene`). Reduced Motion: shots 3 to 4 become cuts with no shake or flash, a 0.3 s fade replaces `flash`; keep the burst at 10 confetti pieces.

### (b) Vs Mode debate scene (about 8 to 10 s of setup, then 4 to 6 s beats per round, about 25 s for 3 rounds)
Story: two avatars at podiums in a courtroom/debate hall, smart vs dumb (the existing Vs Mode pairs), a judge NPC on a high bench with a gavel, a small crowd. Each round: the server decides who "argues" and the director shows the turn; reaction shots cover the other side. Winner celebration at the end.

Actors: `A` and `B` (cloned avatars of the two players, each client builds both), `judge` (NPC rig with a wig/hat), `crowd` x4 (cheap rigs, reuse the existing Rooms NPC kit). Set: `DebateHall` built from existing Rooms parts or client-built (two podiums, a bench, banners "SMART" / "DUMB").
Camera rule: "you" are always the near side for each client (flip A/B per client); the choice UI stays bottom-left as `Conversation.lua` does now.

Setup (once):
| # | Time | Shot | Action | Sound |
|---|------|------|--------|-------|
| 1 | 0-3 | Establishing wide of the hall from the back, high angle, slow push-in, FOV 70 | crowd murmurs (looped emote), judge enters bench | murmur loop |
| 2 | 3-5 | Two shot: both podiums from the side, FOV 55 | `A` and `B` step to podiums (`move`), face each other | footsteps |
| 3 | 5-7 | Low-angle on judge, FOV 50 | gavel strike (`pose gavel`) | bang (cartoon) |
| 4 | 7-8.5 | Caption card: "SMART vs DUMB" in the bars | slam text with `shake 0.2` | stinger |

Per-round beat (repeat; the server sends who and what, the director appends it):
| # | Length | Shot | Action |
|---|--------|------|--------|
| R1 | 2.0 | Over-the-shoulder from behind `B` onto `A` (A is the speaker), FOV 50 | speaker `A` does `emote` (point/gesture) while the typed line appears as a speech bubble and caption |
| R2 | 1.2 | Reaction close-up on `B` (listener), FOV 45 | face reaction: eyebrow pose / `emote` shock or smug; crowd `Oooh` |
| R3 | 1.0 | Cut-away to judge medium, FOV 55 | judge nods or shakes head, taps desk; if the line is an OBJECTION, quick low-angle slam shot of `B` pointing, camera push-in + letters (reuse `objection()` from Conversation.lua) |
| R4 | 0.8 | Wide hold | meter bar changes (Vs meter from SocialService); crowd gasps or laughs |
(Round order alternates the OTS direction so the audience sees both sides; choices appear after R4.)

Verdict (about 8 s):
| # | Time | Shot | Action |
|---|------|------|--------|
| V1 | 2 | Close-up on judge, FOV 45 | reads verdict (caption), gavel bang |
| V2 | 2 | Two shot, FOV 55 | winner `emote cheer` + confetti, loser `emote` sad/slump (cartoon wobble) |
| V3 | 3 | Hero low-angle wide on winner, slow orbit 40 degrees, FOV 65 | crowd cheer, trophy prop appears, stars burst |
| V4 | 1 | Fade out | server result (brain cells, rewards) was already decided and is shown in the existing result card |

Rules: both clients start at `t0`; server fixes the winner BEFORE the verdict plays; leaving (Backspace) closes only your own cutscene (matches `vsOff`); if the partner leaves mid-scene, the director plays a short "forfeit" verdict beat. Choices keep their 1/2/3 keys and bottom-left layout. Smart/dumb flavour: the smart avatar's podium is clean with books, the dumb avatar's is messy; dumb side lines can show scrambled letters (never scrambled prices or confirm buttons, per the repo rules). For "the lawsuit" variant swap the set for a courtroom (bench, jury box) and add the big OBJECTION slam beat.

### (c) The World's Smartest moment (about 20 s)
Story: IQ 200+ finale (existing GeniusEnd/Genius ceremony). The player's avatar stands on a stage, spotlight on, newspapers fly past in 3D with their face on the cover, crowd cheers, camera crane finishes on a wide of the town.

Actors: `me` (clone), `crowd` x6 (rigs, cheap, `emote cheer`/`clap` loops), `reporter` x2 with flashbulb props (no real flashing: a soft pop sprite). Set: stage with curtain, spotlight Part with a `SpotLight`/`SurfaceLight` (one light only), banner "WORLD'S SMARTEST".

| # | Time | Shot / camera | Action | Sound | Caption |
|---|------|---------------|--------|-------|---------|
| 1 | 0-3 | Crane-down establishing from sky to stage, FOV 70 | town lights come on; curtain closed | rising orchestral hit | "Somewhere in town..." |
| 2 | 3-5 | Medium on curtain then reveal: curtain parts | `me` walks to centre mark, spotlight fades in | spotlight "thunk" | "The World's Smartest." |
| 3 | 5-8 | Low-angle hero shot on `me`, FOV 55, slow push-in | `me` plays `emote pose` / arms-up, glasses glint (Fx) | fanfare | "" |
| 4 | 8-12 | Tracking shot from the crowd's POV; newspapers fly across the lens left to right (`prop Newspaper` x10 with `Spin`, path curves, headline texture "GENIUS!"), parallax with foreground blur | `me` seen between papers; reporters pose | whoosh x3, flash pop sounds | "Extra! Extra!" |
| 5 | 12-14.5 | Reaction cutaways: crowd close-ups (3 quick 0.8 s shots, two different avatars), judge/mayor NPC claps | crowd `cheer`, hats thrown | crowd cheer | "" |
| 6 | 14.5-17 | Over-the-shoulder from behind `me` toward the cheering crowd (the audience in front), FOV 60 | `me` waves (`emote wave`), confetti cannon burst | confetti pop | "Thank you!" |
| 7 | 17-20 | Slow crane up and back to a wide of the stage and town, FOV 75; fireworks (cap 2 emitters) | newspapers settle, spotlight stays on `me` | music swell, ends | (then the existing ceremony card/ending UI) |

Reduced Motion: papers appear as a static collage frame, no whoosh, no crane (cuts), fireworks reduced to confetti 10. Phone: 6 crowd rigs shown only in wide shots, pooled and re-used for the cutaways (move the same 2 close-up actors), 10 newspaper parts max, no shadows.

---

## 5. Suggested build order (one feature at a time, per CLAUDE.md)
1. Split `Cutscene.lua` into begin/cut/setCaption/finish (+ keep `play`); test the intro and GeniusEnd still work.
2. `CutsceneDirector` core: actors from player clone, camera shot constructors, actions `anim`/`pose`/`burst`/`hide`/`swap`, watchdog and cleanup. Test with a 3-shot dummy scene.
3. Build the BrainWalker rig and the Poof/Confetti/Stars emitters; ship scene (a) behind a flag, fallback to the old ending.
4. World's Smartest (c): reuse actors, add crowd rigs and newspaper prop action.
5. Vs Mode (b): run on two clients in Studio, then move `Conversation.vs*` over to director cameras and actors.
6. Verify animation ids and permission in Studio; replace any that fail with procedural poses.
