# Client UI bug hunt (read-only audit)

Scope: `roblox/src/StarterPlayer/StarterPlayerScripts/Client/` (UI, Hud, PhoneOS, Stations, Minigames, Effects, RoomGuide, QoL, Guide) and `StarterPlayerScripts/ClientMain.client.lua`.
Method: code reading only. Nothing was run in Studio, so layout items marked "verify" are calculated from the code (750x380 phone, device scale D = 0.75) and should be confirmed with a screenshot. No game code was changed.
Paths below are relative to `roblox/src/StarterPlayer/StarterPlayerScripts/Client/` unless they start with `ClientMain`.

## HIGH

1. **Un-closable social pop-ups can trap a phone player.** `Stations.lua:1833` (`socialFrame`, `noClose = true`) and `socialWait` (about line 1880, no button at all).
   - What goes wrong: if the partner leaves, or `social_end` never arrives, the dimmed pop-up stays forever. A touch player has no key for M/ButtonY. `Hud.onUnstuck` (`ClientMain.client.lua:98`) and `Watchdog` never call `UI.closeModal`.
   - Fix: add a fallback timeout, for example `task.delay((d.seconds or 15) + 20, function() if m.alive() then m.close() end end)`. Make Unstuck call `UI.closeModal()`. Give `socialWait` a "Leave" button that calls `Remote.call("social_leave")`.

2. **The in-game phone is only about 175 px wide on a 750x380 screen, so its text is tiny.** `UI.lua` modal sizing (`PhoneAspect` 0.5, `PhoneHeight` 0.92 in Config), `PhoneOS.lua` `appGrid` (3 columns) and `appIcon` (label `labelH` 16, `TextScaled`).
   - What goes wrong: height is 0.92 x 380 = 350 px, so width is about 175 px. App labels are 16 px boxes x 0.75, roughly 9-10 px text. Icons are about 35 px. Both are far below the 14 pt and 44 px rules.
   - Fix: on `UI.isPhone()` use 2 columns, a taller label (22) and `UITextSizeConstraint{MinTextSize = 14}`. Or let the phone use a wider aspect (about 0.75) when the screen is wider than 700.

3. **Top-centre HUD stack overlaps the top-right buttons on 750x380 (verify).** `Hud.lua:454` (banner 330 px, lobby only), `Hud.lua:464` (tutorial card 330x82 at y=47), `Hud.lua:546/578` (corner buttons `5*MT+40` wide), `Guide.lua:33` (goal line 420 px), `RoomGuide.lua` `showCard` (card at y=52).
   - What goes wrong: `MT = ceil(42/0.75) = 56`, so the corner row is 320 px wide (x 420-740, y 6-64). The banner (x 210-540, y 2-56) and the tutorial card (y 47-129) sit on top of Settings/Shop/Map. The guide line and the RoomGuide card are stacked in the same strip.
   - Fix: lay these out in one column that starts under the corner row on phones (`y >= corner.AbsolutePosition.Y + corner.AbsoluteSize.Y + 4`), or cap their width to `0.3` scale with a `UISizeConstraint`.

4. **Closing a minigame early still submits the round.** `Minigames.lua:1253-1264` (the timer loop ends when `m.alive()` is false, then falls through to `finish()`), `Minigames.lua:1165`.
   - What goes wrong: tapping X mid-round sends `mg_finish` with the partial score and runs `opts.onResult` on a dead modal. That can open a report card or payslip over whatever the player is doing now, and it fails a round the player simply abandoned.
   - Fix: after the loop, `if not m.alive() then running = false; return end`. Only call `finish()` when the time really ran out. If the server needs a clean-up, send a separate `mg_abort`.

5. **Any new pop-up silently destroys the one on screen.** `UI.modal` calls `UI.closeModal()` first; `PhoneOS.lua:539` (`rideInvite`), `Effects.eureka`, `ClientMain.client.lua` (`death`, `launch`, `voidFall`) also close it.
   - What goes wrong: a friend's ride invite, a quiz or a Eureka cutscene replaces a minigame, bank screen or conversation mid-action. When the invite expires, the original screen is not restored. The same applies to the non-closable death screen if another modal opens.
   - Fix: add `UI.modalIfIdle(title, opts)` for server-pushed pop-ups. If `UI.isModalOpen()` it queues (the way `ClientMain` already queues toasts) or shows a toast. Only `death`, `launch` and `voidFall` should force-close.

6. **Reading pop-up text can shrink below 14 pt, and the "tiny runaway SKIP" is overridden.** `Stations.lua:1318-1405`.
   - The body label is `TextScaled` with `MaxTextSize = 22` and no `MinTextSize`. Its box is only `0.42 x 380 - 80 = about 80 px` high on a phone, so long texts scale down to 8-10 pt.
   - `UI.button` forces a minimum size, so the intended 60x26 SKIP (`Stations.lua:1385`) becomes about 56x56. The "I read it" button (30 px high, `TextSize = 13`) is also resized. The Lose-path joke (tiny runaway skip at high brain) is lost.
   - Fix: add `MinTextSize = 14` and make the frame taller on phones (let it scroll). For the joke button use a plain `UI.new("TextButton")`, or add an `opts.noMinTouch` flag to `UI.button`.

## MEDIUM

7. **`string.format("%d", float)` kills the debug overlay loop.** `Hud.lua:909-910`: `FPS: %d` receives `frames / (os.clock() - last)`, for example 59.8. Luau errors with "number has no integer representation", the `while true` task dies, and the overlay freezes. Staff only. Fix: `math.floor(frames / (os.clock() - last) + 0.5)`.

8. **Sub-44 px touch targets.**
   - `UI.lua:1017` phone home bar 150x40.
   - `UI.lua:1124` slider track 28 px high (knob 26 px).
   - `Hud.lua:477` tutorial close 36x36.
   - `Hud.lua:147` path-strip GO 48x36.
   - `RoomGuide.lua:234` card header (the only fold/unfold control) 32 px high.
   - `Config.lua:797` `MinTouch = 42`, below the 44 rule.
   - Fix: use `UI.minTouch()` for each and raise `MinTouch` to 44.

9. **Text below 14 pt.** `Hud.lua:140` (11 pt step labels), `Hud.lua:142` (TextScaled 8-12), `Hud.lua:339` (activity names 9-13), `Hud.lua:884` (13), `Hud.lua:103/108` (chips `UI.textSize(12)`), `UI.lua:1010` (phone status bar 12 pt), toast text `UI.textSize(13)`, `RoomGuide.lua` lines and buttons (13 on phone), `Config.lua:796` (`MinPhoneText = 12`). `UI.textSize` only raises text on phones, so desktop stays at 11-13. Fix: floor at 14 inside `UI.textSize` (`math.max(size, 14)`), set `MinPhoneText = 14`, and route the hard-coded sizes through it.

10. **`Hud.lua` reads `MT = UI.minTouch()` once (line 53).** `Hud.lua:546/614/636` use it for fixed sizes. The later `UI.onScale` hook (about line 1001) fixes most buttons, but `roundButton` corner radius and the early `bottom` frame keep the old value. If the first `ViewportSize` is wrong (1x1 at load, or a phone rotating), the buttons stay too big or too small. Fix: read `UI.minTouch()` inside the callbacks and compute the corner radius from `b.AbsoluteSize`.

11. **Dock minigame can report twice.** `Stations.lua:2285-2300`: after the third good dock the DOCK button stays live. Another tap calls `reportTraining` again (a win, then a "fail" report). Fix: add `local done = false` and ignore taps once it is set (as `astro_oxygen` and `astro_zerog` already do).

12. **QoL sprint button colour is not reset after respawn.** `QoL.lua` `CharacterAdded` clears `sprinting`/`added`, but the button stays green. Releasing sprint subtracts `added` from `WalkSpeed`, so speed changes made by the server meanwhile (animal forms, admin freeze) are partly lost. Fix: keep a reference to the button, reset its colour on `CharacterAdded`, and restore the speed the server last set.

13. **Toast holder stays at the bottom after a pop-up closes.** `UI.lua:603`: the holder moves to the bottom when `UI.popupOpen`, but only moves back when `#liveToasts == 0`. If a toast is live when the pop-up closes, new toasts keep appearing at the bottom and overlap the bottom bar. Fix: reposition in `UI.closeModal` too.

14. **Double-tap guard can lock a button forever.** `UI.button` `busy` flag resets only when `onClick` returns. If `Remote.call` hangs (`InvokeServer` has no timeout), the button is dead until the pop-up is rebuilt. Fix: reset `busy` with `task.delay(3, ...)` as a safety net.

15. **Bank screen rebuilds the whole modal for every transfer.** `PhoneOS.bank` `move()` calls `PhoneOS.bank()`. That re-runs the open animation, loses scroll position and starts a new countdown task each time (old ones stop because `m.alive()` goes false). Fix: update the labels in place from the `bank_move` reply.

16. **Non-closable modals let taps through to the HUD.** `UI.modal` only sets `backdrop.Active = true` when `not opts.noClose`. The death screen (`Stations.lua:1463`) and the social rounds (`Stations.lua:1833`) are dimmed, but Shop/Map/Settings underneath still react. Fix: set `backdrop.Active = true` whenever `not phone`.

## LOW / STYLE

17. **Style drift between screens.**
    - `Stations.lua` has about 149 hard-coded `Color3.fromRGB` values and mixed `UI.corner` radii (3, 4, 5, 6, 9, 10, 12, 14, 16, 17, 18, 19).
    - It uses `Enum.Font.Gotham*` directly about 30 times and `FredokaOne` in 6 places, instead of `UI.T.font/title/body`.
    - The Hud banner, tutorial and objective lines and `Guide.lua:34` hard-code `FredokaOne`, while `RoomGuide` uses `UI.T.font`. The same kind of top line looks different on each.
    - Fix: add `UI.Colors` tokens and use `UI.T.radius`, then sweep `Stations.lua` buttons and cards.
18. **Emoji newer than Unicode 14.** One hit across the client and Content: `ReplicatedStorage/Shared/Content.lua:1549` `🩷` (pink heart, Unicode 15, shows as a box on older font builds). Fix: use `💗` or `❤️`. (`🩺 🩹 🧑‍🚀 🧑‍💼` are Unicode 12 and fine.)
19. **Hard-coded English in `Stations.lua`.** For example the ClickNews timer ("reading for Ns (10s = smarter!)", about line 160) and many `UI.toast("⛔ ...")` strings. They bypass `Content.lua`.
20. **`UI.shadow` does not follow later moves.** It copies `frame.Position` once. Anything that animates or re-anchors the frame leaves the shadow behind. Fix: parent the shadow to the frame.
21. **Phone status bar uses 40 spaces to push the icons right.** `UI.lua:1011`: not width-safe. Fix: two labels (time left, icons right).
22. **`Effects.fadeOut` only fades `TextLabel` and `Frame`.** Images and buttons pop out at the end. Fix: also tween `ImageTransparency` and button text.
23. **`ClientMain` start loop gives up silently after 20 tries.** `ClientMain.client.lua` (`hello` loop): if every call fails, the HUD stays blank with no message. Fix: show a "Connection problem, retrying" toast and keep trying every 5 s.

## Checked and fine
- RenderStepped uses (`Guide.lua`, `Stations.lua` dock/oxygen/zero-G, the `Hud.lua` FPS counter) are either disconnected when their frame goes away or are a single permanent connection.
- `while true` loops (`Hud.lua:600/900`, `QoL.lua:97`, `Guide.lua:224`, `RoomGuide.lua:333`, `ClientMain.client.lua:239`) are permanent by design and sleep. The shop shimmer loop idles at 1 s when hidden.
- `Remote.call` never returns nil, so `r.ok` indexing is safe everywhere.
- `UI.closeModal` cleanup is sound: the backdrop is destroyed after 0.1 s and the ContextAction binding is removed.
