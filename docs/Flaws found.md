# Flaws found (audit of roblox/src at 5c54d68, Nov 23)

This was a read-only code audit, done while the PC chat play-tests 1.7, so no game code was changed. Every finding below was checked against the code. Findings marked **(check in Studio)** look right in the code but need a play-test to confirm.

Also checked, with no problems found:
- Every `Content.*` and `Config.*` key the code uses exists (235 references checked).
- Every `Module.function(...)` call has a matching definition.
- All files compile.

## Top 10 to fix first

1. **The free taxi makes the new ride app and the "walking is slow" idea pointless.** The 🗺 MAP taxi is free, instant and works anywhere every 8 seconds, so nobody needs Hoppr or the bus. The Hoppr screen even says to use the free taxi instead.
2. **Jobs pay even when you don't work.** Every minute, anyone with a job gets paid, wherever they are. This goes against "you have to actually work to get money".
3. **The shift bonus pays you for standing still.** Clock in on time, stand there 60 seconds, clock out: +15 coins every 5 minutes without doing any work.
4. **The bank earns more than the best job.** 2% every 10 minutes, compounding, up to 200 coins per tick. Saving beats working.
5. **The phone-size rules (48 px buttons, 14 pt text) get shrunk again on phones.** The whole UI is scaled down to 70–85% on phones, so buttons end up about 34–40 px and text about 10–12 pt.
6. **On a phone held sideways, real-phone (IQ 120+) app icons are wider than their grid cells,** so they overlap each other. (check in Studio)
7. **Lose-path animals can't use the Lose apps from the phone any more.** The 📱 button now opens the 🐾 menu, and nothing tells them to walk to the four stands in front of the 🛍 Mall.
8. **The Lose path got almost nothing from 1.7.** The rides, shifts and bank are Gain-only, and the plan's dumb travel ladder (free bus, wobbly GPS) and joke jobs are missing.
9. **The Effects slider misses the older glitch effects.** The wobbly tilted buttons and the scrambled reading and conversation text ignore it.
10. **"Skibidi" appears in 8 places,** including a "Skibidi Plushie". It's a trademarked character brand, and Roblox's IP rules forbid using other people's brands.

Count by category: gameplay and economy 7 · UI on phones 5 · runtime and robustness 3 · exploits (client trust) 3 · kid-safety, brands and the "text in Content" rule 2 · performance 2 · plan gaps 9 → **31 total**.

---

## 1. Gameplay and economy

### G1. The free map taxi undercuts Hoppr, shifts and "walking is slow" (high)
- **Where:**
  - `ServerScriptService/Services/GainService.lua:424-460` (`taxi`: free, any place, 8 s cooldown, `Config.TaxiCooldown = 8` at `Config.lua:137`)
  - `Client/Hud.lua:360` (big "🗺 MAP — taxi anywhere" button)
  - `Content.lua:1007` and `Content.lua:1013` (the Hoppr screen says "The free taxi is in 🗺 Maps")
- **What the player sees:** Hoppr costs coins and takes 6–10 s, while the map taxi is free and instant. Nobody uses Hoppr, nobody is ever late for a shift, and walking never matters.
- **Fix:** make the map taxi tier-based.
  - Lose path and low Gain: a free but slow **bus**. It has stops, a 20–40 s wait and only goes to a few places.
  - Cozy and above: the bus plus Hoppr.
  - Teleport pads and the Castle Map stay as rewards.
  - Remove "use the free taxi" from the Hoppr text, and give Hoppr a reason to exist: door-to-door, no waiting for the bus, it takes you to work.

### G2. Jobs pay without working (high)
- **Where:** `GainService.lua:942-951`. Every 60 s, every Gain player with a job gets `coinsPerMinute × level bonus`, wherever they are.
- **What the player sees:** take a job, then go AFK or read in the library. Money keeps coming in. This contradicts the user's rule "you have to actually work and get money".
- **Fix:** pay passive wages only while the player is clocked in (`LifeService` shift) and within `Config.WorkRadius` of the workplace. Otherwise pay only per finished task (`GainService.lua:650`).

### G3. The shift on-time bonus pays for idling (high)
- **Where:** `LifeService.lua:215-266`. `shift_in` only checks the place and time. `clockOut` pays `OnTimeBonus` (15) after `MinShiftSeconds` (60) and never checks whether any task was done or whether you're still at work.
- **What the player sees:** an easy +15 coins every 5 minutes for standing still. A script can farm it.
- **Fix:**
  - Pay the bonus only if `tasks > 0` (the code already computes `data.jobTasksDone - sh.tasksAt`) and the player is still near the workplace at clock-out.
  - Allow one bonus per shift window: store the window number.

### G4. The bank beats working (high)
- **Where:**
  - `LifeService.lua:326-356`
  - `Config.lua:510-512`: `SavingsRatePercent = 2` every `InterestEverySeconds = 600`, capped at `MaxInterestPerTick = 200`
- **What the player sees:**
  - 2% per 10 minutes compounds to about 12.6% per hour.
  - With 10,000 coins saved, the bank pays 200 per tick, which is 20 coins a minute. That equals the best job, the Scientist at 20/min, for doing nothing.
  - Interest is paid on whatever is in savings at the moment of the tick, so moving coins in just before the tick and out just after earns full interest.
- **Fix:**
  - Lower the rate, for example 0.5% per 10 minutes, and the cap, for example 25.
  - Pay interest on the lowest balance since the last tick (track `minSinceTick` in `bank_move`).

### G5. Lose-path animals lose phone access to the Lose apps (medium)
- **Where:**
  - `Client/PhoneOS.lua:259-264`: animals are sent to `AnimalUI`.
  - `Client/AnimalUI.lua:112-130`: the sniff list only has taxi places.
  - `Client/Hud.lua:94-98`: the Lose HUD only has Phone / Vs Mode / Map.
- **What the player sees:** in 1.6 a dog could keep losing cells from the phone apps (BrainTok, ClickNews…). In 1.7 the phone shows 👃 ⚡ 🏠 and nothing else. The four Lose stands in front of the 🛍 Mall still work, but nothing points to them, so a young player can get stuck at "dog".
- **Fix:**
  - Add wordless icons for the four stands (📰 🎮 💬 📱) to the 🐾 menu. Each one sniff-trails to its stand, or opens an emoji-only version of the app (BrainTok swiping needs no reading).

### G6. The Lose path gets almost nothing new in 1.7 (medium; the "both paths matter equally" rule)
- **Where:**
  - `PhoneOS.lua:77-85`: Hoppr, Bank and Shifts appear only on the Gain cozy and real tiers.
  - `LifeService.lua:217`: shifts are Gain-only.
- **What the player sees:** the Lose path only got ads, scrambled labels and a hole.
- **Fix:** add the plan's Lose versions:
  - a free "Brain Bus" app with a wobbly GPS that sometimes takes a funny wrong turn, but always arrives
  - one-button joke jobs (flip a sign, hand out flyers) that pay treats or coins
  - a piggy-bank toy version of Brain Bank

### G7. Bills toast every 10 minutes even when nothing is paid (low)
- **Where:** `LifeService.lua:345-354`. With "harder life" on and 0 coins, the player still gets "paid 0" every tick.
- **Fix:** only toast when `fromCoins + fromSavings > 0`, and say "Bills skipped: you're broke (no debt)" once.

---

## 2. UI on phones

### U1. The 48 px and 14 pt minimums are shrunk by the device scale (high)
- **Where:**
  - `Client/UI.lua:180-191`: device scale `D`, clamped to 0.7–1.35.
  - `UI.lua:372-374`: the button minimum, measured before scaling.
  - `UI.lua:308-315`: the text minimum, also before scaling.
  - `UI.lua:649`: modals get `UIScale = D`.
- **What the player sees:**
  - On a phone held sideways (about 844×390), D is about 0.84, so "48 px" buttons are about 40 px and "14 pt" text is about 12 pt.
  - On small phones D is 0.7, giving about 34 px buttons and about 10 pt text, below Apple's 44 pt and Google's 48 dp.
- **Fix:** use `math.ceil(Config.UI.MinTouch / UI.D)` and `math.ceil(Config.UI.MinPhoneText / UI.D)` in `UI.button` and `UI.textSize`, so the size after scaling is still 48 and 14.

### U2. Real-phone (IQ 120+) app icons overflow their cells on phones (medium) (check in Studio)
- **Where:** `Client/PhoneOS.lua:216, 219, 250, 255`.
  - Grid cells are `0.23` of the content width; icons are a fixed `56` px.
  - The phone frame is about 0.52 × height wide (`UI.lua:634`). On a 390 px-tall phone the content is only about 210–230 px wide, so the cells are about 50 px.
- **What the player sees:** icons overlap their neighbours and the labels get squeezed. The dock has the same problem.
- **Fix:**
  - Size the icon frame with Scale (`UDim2.fromScale(0.86, 0)` plus `UIAspectRatioConstraint` 1), or
  - use 3 columns when `UI.isPhone()`.

### U3. Two status bars on the real phone, and a hard-coded 12 px font (low)
- **Where:**
  - `UI.lua:641`: every phone modal draws "HH:MM … 📶 🔋" at size 12.
  - `PhoneOS.lua:184-186`: the real-phone home adds a second status bar.
- **What the player sees:** the time is shown twice, and the top one is tiny (about 10 px after scaling).
- **Fix:** let `UI.modal` skip its own status bar when `opts.noStatus` is set, pass that from PhoneOS, and use `UI.textSize(14)`.

### U4. The joke ad has two `UIScale`s (low)
- **Where:**
  - `Client/LoseFX.lua:110`: `UI.autoScale(frame)` adds "DeviceScale".
  - `LoseFX.lua:138`: a second `UIScale` for the pop-in animation.
- **What the player sees:** Roblox uses only one `UIScale` per object, so the ad either ignores the phone scale or doesn't pop.
- **Fix:** tween the `DeviceScale` itself, from `0.6 * UI.D` to `UI.D`.

### U5. The bottom-centre bar may sit inside the thumbstick zone on small phones (low) (check in Studio)
- **Where:** `Client/Hud.lua:381`. The bar is a fixed 400 × 112 px, centred at the bottom.
- **What the player sees:** after scaling it's about 336 px wide, starting about 250 px from the left. Roblox's dynamic thumbstick uses roughly the left 40% of the bottom, so the bar can block the joystick.
- **Fix:** check in the device simulator (iPhone SE and iPhone 17 Pro, landscape). If it overlaps, raise the bar or narrow it.

---

## 3. Runtime and robustness

### R1. Hoppr arrival can move you in the middle of a scene or while seated (medium) (check in Studio)
- **Where:** `LifeService.lua:167-180`. After 6–10 s the server always calls `teleport`/`PivotTo`.
- **What the player sees:** if the player sat down, started a conversation, entered the Mean, or rode a rocket while waiting, they get yanked out. A seat weld can drag the seat or fling the player.
- **Fix:** on arrival, reuse the 🆘 Unstuck clean-up in `Main.server.lua:129-151` (end conversations, stand up), or cancel the ride and refund it if the player is busy.

### R2. The speed pass can turn off collision on small parts that need it (low) (check in Studio)
- **Where:** `WorldService.lua:1132-1147`. Every anchored part with all sides ≤ 2 studs loses `CanCollide` (only seats, spawns and parts holding a prompt are skipped).
- **What the player sees:** small steps, stepping stones, small platforms or room props may become walk-through.
- **Fix:** skip parts tagged with a "Solid" attribute, or limit the pass to parts named like decor (Leaf, Lamp, Sill, Bulb…).

### R3. Some text is hard-coded outside `Content.lua` (low; breaks the CLAUDE.md "all text in Content" rule)
- **Where:** `LifeService.lua:90-92` (car colours and models), and `SocialService.lua:62` and `:796` (quiz and election lines).
- **Fix:** move them to `Content.Life.Ride.Cars` / `Content.Social`.

---

## 4. Exploits (the server trusts the client)

All three are low risk because they only help the cheater a little, but they are easy to script.

### E1. Coffee habit
- **Where:** `GainService.lua:822-834`. The client sends `count`; the server only checks that it equals 60.
- **What happens:** an exploiter gets "-35 stress" every time with no counting.
- **Fix:** issue a start time on open, and require at least about 20 s between open and answer.

### E2. Astronaut training
- **Where:** `SpaceService.lua:348-391`. It trusts `d.success == true` (15 s cooldown).
- **Fix:** have the server issue the minigame target (as `habit_nap` does) and check the reply against it.

### E3. Library and cinema return the correct answer
- **Where:** `GainService.lua:96` (`answer = sess.item.answer`), and the same in `theater_answer`.
- **What happens:** with small question pools, a script can memorise every answer for free brain cells.
- **Fix:** don't send the answer index after a wrong answer (show "wrong" only), or grow the pools. Low priority.

---

## 5. Kid safety, brands and honest money

### K1. "Skibidi" brand references (medium)
- **Where:** `Content.lua:53, 93, 563, 567, 579`, `Props.lua:205`, `SocialService.lua:796`. Line 567 is "🧸 Skibidi Plushie".
- **What the problem is:** "Skibidi Toilet" is a trademarked franchise. Roblox's IP guidelines ban using others' brands, and parody is not a defence.
- **Fix:** replace it with an original nonsense word (e.g. "Gloobidi", "Bonkadoo") everywhere.

Honest money otherwise looks good:
- Pass prices and effects are shown before every purchase (`Stations.lua:584-603`, `:1700-1706`).
- Passes with ID 0 show "not set up yet" instead of breaking.
- There are no paid random items.
- The bank never goes into debt.
- Hoppr shows the fare before you confirm.

---

## 6. Performance (minor)

### P1. A rainbow loop runs forever
- **Where:** `Hud.lua:368-376`. It runs every 0.05 s forever, even on looks where it does nothing.
- **Fix:** start and stop it on `UI.onTheme`, or use a single `TweenService` loop.

### P2. The Brain Tower overlaps the "🧠 BRAINVILLE" sign (cosmetic)
- **Where:** `WorldService.lua:1057`. The tower column runs from y=10 to y=66 at the plaza centre. The old statue's sign (`WorldService.lua:494-495`, offset 6 → y≈13) is now drawn inside the column.
- **Fix:** move the sign up to the tower top, or drop it, since the tower already has its own sign.

---

## 7. Plan items missing or weak (from `docs/Brain scaled UI and map design.md`)

1. **Lose travel ladder:** the free bus or scooter and the wrong-turn GPS are missing (see G6).
2. **Lose job ladder:** the one-button joke jobs are missing (see G6).
3. **Effects slider coverage:** `T.wobble` button tilts (`UI.lua:380`, `UI.lua:645`, `Hud.lua:170`) and the server-side text scramble (`Brain.degradeText`, used by `LoseService.lua:104` and `ConversationService.lua:49`) ignore `fxIntensity` and Reduced Motion. Fix: gate the wobble on `UI.effects() > 0 and not UI.reducedMotion()`, and have the server read `data.settings.fxIntensity` before degrading text.
4. **"Warn before every effect":** only ads and brain lag warn first. The brain-lag toast appears at the same moment as the 0.25 s lag, so it's not really a warning.
5. **"Pin a simple HUD" option:** `classicHud` only swaps the phone. The HUD itself is never simplified.
6. **Cozy-tier bus timetable, fancy-tier investing, 200+ hologram HUD:** not built (already listed in CLAUDE.md "Next").
7. **District NPCs:** only the two gate guides exist; there's no NPC per district.
8. **Animal-only secret paths:** none. The one shortcut hole is for every Lose human and animal alike.
9. **Lose-side GPS line, Gain-side clean route line:** neither exists. The plan's "GPS quality follows brain" is missing.
