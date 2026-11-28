# Handoff (Nov 26, 10:50 PM): phone bug fixes after the 1.9.2 publish

## Nov 28 status (read first)
- 1.9.4 is committed and pushed, NOT published (user said not yet): Genius cutscene pop-up, Work+Shifts merged, Hoppr and brain bits removed, icons show at once + preload, admin menu fits phones, no tap-outside-to-close, red dot on the app tile, staff bug sweep (admin `sweep`), AutoTexture pass.
- To do next: admin menu restyled like Settings; check AutoTexture in the realistic and toon looks; real-player feedback ideas (analytics, phone playtests, annoyance rule list).
- Usage-saving mode until ~Dec 3; the Keep building routine is paused.

The old chat got too long (expensive), so this work moves to a fresh chat. Read CLAUDE.md and the memory files first.

## How to work (the user wants this chat to work EXACTLY like the old one)
- **Open the chat in `C:\Users\hasfr\Documents\empty-repo-3`** (not Documents): the Roblox Studio MCP, Rojo and
  Blender connections only exist there. If `list_roblox_studios` isn't available, say so in one line and stop.
- Keep a task list (update_plan) and end every turn with wrap_up. Plain, simple words; short replies (credits).
- **Every change gets tested in Studio before "done"**, never code-only:
  1. Edit `roblox/src` (Rojo on port 34872 syncs it; check `curl -s http://localhost:34872/api/rojo`). If Studio
     shows "Are you still there?", click Try connecting, then Rojo → Connect (computer-use, Roblox Studio app).
  2. `cd roblox && selene src` → 0 parse errors.
  3. `start_stop_play` → `execute_luau` (Client/Server) to set up the situation (admin remote:
     `Remotes.Request:InvokeServer("admin", {cmd=..., target=userId, arg=...})`: setcells, setpath, passallgates,
     golden, schoolbell, eventinvite…) → `screen_capture` to SEE it → `get_console_output`: fix every red error.
  4. Check both paths (Gain and Lose) and animals when the feature touches them. Restore the test account after.
  5. Phone check: the device simulator didn't accept device names last time; at least reason about 844x390.
  6. Stop the playtest, commit (`git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, ending with
     the Co-Authored-By line), push, tick it in docs/QUEUE.md, save key screenshots to docs/screens/.
- Studio testing tips (simulated keys/mouse don't reach the game; `require()` from execute_luau gives a separate
  module copy; trigger prompts with `InputHoldBegin/End`; pin the camera with a BindToRenderStep loop): see
  CLAUDE.md "Testing in Roblox Studio" and memory `roblox-port-status.md`.
- Send the user screenshots of results (SendUserFile). Use subagents for broad read-only bug hunts when asked.
- When done with a batch: bump `Config.Version` + "What's new" entry, test, then ASK the user before publishing
  (route: File → Publish As → Cult of the 39 → Lose/Gain a Brain Cell → Overwrite; see memory).
- Rules: kid-safe, honest money, parodies only, text in Content.lua, numbers in Config.lua, never commit .mcp.json,
  never print the ROBLOX_API_KEY, don't edit CLAUDE.md without the user's OK.

## State
- Live game is now named **"Lose/Gain a Brain Cell"** (renamed in Creator Hub, confirmed). Public, universe 10775683039,
  place 114531583535398, owner group "Cult of the 39". Live version = **1.9.3 "Brain Bits Update"** (published Nov 28, 3:18 PM, by Claude at the user's request). Usage-saving mode until ~Dec 3: only bugs; the "Keep building" routine is paused.
- Maturity questionnaire: filled in by the user, waiting for Roblox review.
- Dev copy open in Studio (placeId 134289559505471), Rojo synced on port 34872. Studio MCP ids change after a
  reconnect: call `list_roblox_studios` first.
- Thumbnails: `marketing/thumbnails-v2/` (#1 split town = user's favourite; #2-#5 white background + real brain
  model, credit in `marketing/CREDITS.md`). Not uploaded to the game page yet.
- Test account: Gain path, 70B cells. Restore it after any admin change.
- Publish route and gotchas: memory file `roblox-port-status.md`. Ask before every publish.

## The user's bug report (from playing the live game on a phone)
Screenshot: huge "[Owner]" and "💼 Dishwasher" tags over your own head, a bright yellow neon bar beside them, a
"19 m" label at top centre, the Vs Mode sign floating over the right of the screen, the sprint button floating
mid-right, the objective banner colliding with all of it.

**Progress (Nov 26, late chat):** items 1-4 are CODED (selene clean) but NOT Studio-tested yet: that chat had no
Studio MCP (it was opened in Documents, not empty-repo-3). Test 1-4 first. Item 3 cause: `Main.server.lua` onWork
compared the job place "restaurant" with the desk key, so Restaurant Workers got "This isn't your workplace" at
every restaurant. Item 4: `Minigames.lua` shows Next ⏭ once score >= goal and MinShare of the round has passed.

To do (one at a time, test each in Studio, phone size + PC):
1. **Overlapping UI on phones.** Causes found by a read-only agent (verify each):
   - Own name tags: `BrainService.lua:256` (Overhead, 8x1.4 studs) and `GainService.lua:348-351` (JobTitle,
     5x0.8 studs, offset 3.2, overlaps Overhead at 2.4+1.4). Fix: `PlayerToHideFrom = player` on both (others still
     see them), and stack them so they don't overlap (JobTitle StudsOffset ~3.8).
   - Yellow neon bar + "19 m": the **Guide arrow**, `Client/Guide.lua:58-73, 203`. Shaft/diamond are Neon at
     root+(0,4.2,0), right in the name-tag band; label is a fixed 120x34 offset BillboardGui with AlwaysOnTop.
     Fix: put the arrow at waist height in front of the player (root + (0,-1.2,0) + dir*3), SmoothPlastic, slight
     transparency; label 70x22, AlwaysOnTop = false.
   - Vs Mode sign: `SocialService.lua:892-894`, offset-sized 220x100 BillboardGui, MaxDistance 60. Fix: size in
     studs `UDim2.new(12,0,5,0)` and MaxDistance ~35 (or a SurfaceGui on a real board).
   - Sprint button: `Client/QoL.lua:64-68`, `Config.QoL.SprintButtonRight = 150 / SprintButtonUp = 160` puts it at
     mid-screen. Fix: ~100 / 30 (just left of the jump button) and use the HUD's auto-scale + min touch size.
   - Phone button / power (🛠) button / narrator bubble crowd the right third: `Hud.lua:286-292, 1035, 1080`.
     Add `phoneSlot` and `powerBtn` to the autoScale list (~Hud.lua:985); hide the narrator bubble while a modal is open.
   - Objective banner `Hud.lua:808-812`: add `UITextSizeConstraint MaxTextSize = 16`.
2. **Can't walk while the phone is open.** `UI.lua:1050-1064, 826-836`: `UI.modal(..., {phone=true})` makes a
   full-screen Active `ModalBackdrop` and "tap outside closes" — it eats the thumbstick touch. Fix: for `phone`,
   make the backdrop non-Active/invisible (or only cover the right half) and skip tap-outside-to-close; keep the
   X / home button and ButtonB to close.
3. **"Even if you go to a restaurant it says it's your workplace."** Not investigated yet. Look at
   `WorldService.workPos / restaurantAt`, `Rooms.lua` room-guide zones, `LifeService` shift clock-in, and the
   restaurant job (GainService crewOf / restaurant menus). Likely a restaurant counts as "your workplace" for any
   restaurant worker or for everyone.
4. **Next button for work shifts.** Shifts make you wait ~30 s. Add a "Next ⏭" button that ends the wait once the
   minigame round is done — server-validated (server decides when the round is finished; no free pay).
   Look at `LifeService.lua` (shifts), `MinigameService.lua`, `Client/Minigames.lua`.
5. **More bug hunting** (the user asked for "a lot of agents"). Four read-only hunts were stopped unfinished to save
   credits: jobs/shifts/restaurants, Lose path + animals + Golden Brains, Gain path/social/events, map/world/phone
   performance. Re-run them only if credits allow (cheaper model), then fix what they find.
7. **New from the user (Nov 26, late):** too many buttons on the phone (trim / group the HUD on touch screens);
   building interiors feel janky; cutscenes are just emojis moving: they must be real cutscenes with animated
   characters and real assets.
   The admin menu still doesn't fit on phones and is very hard to use (AdminPanel.lua): redesign it.
6. Bump `Config.Version` to 1.9.3 + a "What's new" entry, test, commit, push, ask the user before publishing.
