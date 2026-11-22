# CLAUDE.md: rules for working on "Lose a Brain Cell / Gain a Brain Cell"

Read this first in every session, and update it whenever a feature, rule or file changes.

## The game in two sentences (core loop)
Players do things that change their brain cells: books, jobs and inventions to get smarter, or clickbait and brainrot to get dumber. The town, their body and the gameplay change with them, unlocking new places, secrets and endings.

## Hard rules
- **Kid-safe.** Preset text only (no free typing), cartoon or creepy but never gory, and no jump scares unless the player picks "Full" horror.
- **Honest money.** Show the price and effect before every purchase, and nothing paid is required to finish. Show exact odds for anything random that costs something (the fountain shows them).
- **Use parodies, never copies.** Jack B Movies, "Steal A [word]", Noble Prize, Albert Zweistein, BigReactz. Take style inspiration only; never copy other games' assets, characters or layouts.
- **Both paths matter equally.** Every feature must make sense on the Lose path, the Gain path, and for animal-stage players.
- **Being dumb changes the gameplay, not only the look** (ads, brain lag, scrambled text, animal limits). Being smart makes things smoother.
- **Do one feature at a time,** then test, then the next.
- **Never say "done" without testing** (see Workflow).

## Art style (locked)
Blocky Roblox look. The town style follows brain level:
- **Lobby and start of Lose:** cute, with cash-grab signs.
- **Lose:** cash grab, then nonsense below 45B.
- **Gain:** cash grab (IQ 80–95), then cozy (95–120), realistic (120–135), fancy (135–200), and futuristic (200+).

The UI uses one themed kit per look (UI.lua themes in Roblox, `LOOKS`/`UIS` in the browser).

## Where things are
- `roblox/src/`: Luau source.
  - `ReplicatedStorage/Shared/Config.lua` holds every number, pass, sound and admin setting (tip 23).
  - `Content.lua` holds all text and questions.
  - `Badges.lua` holds the badge list.
  - `Content.Updates` is the "What's new" list shown in Settings (it shows `Config.Version`). Every update: add an entry at the top and bump `Config.Version`.
  - 1.5 port: `ServerScriptService/Services/Rooms.lua` (room layouts, furniture kit, seats, conversation spots, exit doors), `Services/ConversationService.lua` (server side of the conversation scenes), `StarterPlayerScripts/Client/Conversation.lua` (the cinematic: bars, camera cuts, choices bottom-left). The Unstuck handler is in `Main.server.lua`, its 🆘 button in `Hud.lua`. Text: `Content.Rooms`, `Content.Conversations`, `Content.ConvUI`, `Content.Unstuck`. Numbers: `Config.Rooms`, `Config.Conversations` (one `{meter, brain}` pair per choice), `Config.Unstuck`.
  - 1.6 port: careers live in `GainService.lua` (ladders, XP, promotions, report cards, the work vest), `Services/SchoolService.lua` (Lose-path school bell, truant officer, class), `Services/AnimalForms.lua` (blocky animal bodies welded on, avatar hidden; called from `BrainService.applyCharacter`), `Services/AnimalService.lua` (animal powers: Bark, Buzz up, Dig). The objective banner and power button are in `Hud.lua`; the PROMOTED! and "You are now: 🐶 Dog" screens in `Effects.lua`. Text: `Content.Careers`, `Content.School`, `Content.Animals`. Numbers: `Config.Careers`, `Config.School`, `Config.Animals`. Admin command `schoolbell` rings the bell for one player. Saves gain `career` (made on demand, so old saves are fine).
  - 1.7 (brain-scaled UI and life systems): `Client/PhoneOS.lua` (the phone per brain tier: toy / cozy / real OS with swipe pages and dock; Hoppr, Brain Bank and Shifts screens), `Services/LifeService.lua` (server for rides, shifts and payslips, bank and interest), `Client/LoseFX.lua` (Lose-path scrambled app labels, brain lag, joke ads), `Client/AnimalUI.lua` (wordless animal menu and smell trail). Map polish is `buildPolish()` in `WorldService.lua` (Brain Tower, district gates with guides, lookouts, dumb-only shortcut hole, phone speed pass) plus pilasters and sills in `building()`. `Style.lua` sets LightingStyle per look. `UI.lua` has `UI.isPhone()`, `UI.effects()`, `UI.reducedMotion()` and the 48 px / 14 pt minimums. Text: `Content.Life`, `Content.Map`, `Content.Settings17`. Numbers: `Config.UI`, `Config.PhoneTiers`, `Config.Life`, `Config.LoseFX`, `Config.Map`. Saves gain `bank` and settings `fxIntensity`, `hardLife`, `classicHud` (filled in automatically for old saves).
  - `roblox/tools/build_rbxlx.py` builds the place file.
  - `roblox/default.project.json` is the Rojo project (same layout as the builder). `rokit.toml` pins Rojo and Selene; `selene.toml` sets up the code checker.
- `START_HERE_ON_PC.md`: the PC setup guide (Claude app, Git, Studio, the Studio MCP connection, Rojo).
- `web/lose-a-brain-cell-web.html`: the built browser game. It is published as a private Claude artifact at https://claude.ai/artifact/9dkh8TK9DFDEPFX8KX2uku.
- `web/src/game.src.html`: the browser source. All balance numbers are in `TUNE` (also editable in Admin → 🎚 Tuning).
  - The other files in `web/src/` are the modules that were spliced in: `render3d`, `rooms` (1.5), `v16` (1.6), `content2`, `interact`, `horror`, `polish`.
- `web/tests/`: Playwright play-tests.
- `marketing/`: game icon and thumbnails.
- `.claude/skills/ship-browser-update/`: the release recipe (tip 10).

## Versions
- **Roblox:** 1.0 to 1.7 (`Config.Version = "1.7"`). **1.7 was written in the cloud overnight and is NOT play-tested yet**: test it in Studio before trusting it (see the morning checklist in the memory file). 1.5 = real places, conversation scenes, exit doors and Unstuck. 1.6 = career ladders, school for the Lose path, physical animal forms. Both ported from the browser and play-tested in Studio on PC and phone size (Nov 2026). `roblox/LoseABrainCell_v1.7.rbxlx` is the latest place file (built in the cloud session, since the PC has no Python). Rojo keeps Studio in sync with `roblox/src` while working. Pass, sound and badge IDs are still 0.
- **Browser only:**
  - (1.5 real places and conversations: now also in Roblox.)
  - (1.6 careers, school and animal forms: now also in Roblox.)
  - The content pack and the interactive world.
  - "The Average Files" horror side plot.
  - The polish pack (first-10-seconds hook, sound kit, triple feedback, tuning table, odds, save backup, clean photo camera).
- **Next:**
  - Port the rest of the browser features to Roblox (still browser-only: the horror side plot, job minigames, the interactive world, glasses at the Optician).
  - **Brain-scaled UI, systems and map**: first pass is 1.7 (untested). Still to do from the plan: a cozy-tier bus timetable, investing at the fancy tier, a hologram HUD at 200+, more dumb-only shortcuts, per-district NPCs beyond the two gate guides. Follow `docs/Brain scaled UI and map design.md`. Brain level changes the look, the rules and the tools: low brain = loud, chunky, glitchy cash-grab UI with simple rules and dumb-only shortcuts; high brain = calm, realistic phone OS with original parody apps, ride-hail, shifts and paychecks, a bank. Lock the map and UI skeleton first. Never use real brand names or look-alike logos. Add an Effects intensity slider. Never scramble prices, odds or confirm buttons.
  - 1.7 time travel.
  - 2.0 creator update.

## Working with the user
- **Always offer to do it for them.** Whenever the user is about to do something by hand (installing, clicking through settings, copying messages between chats, starting a chat, checking on a chat), do it yourself or offer a one-click way: a suggested task card for jobs that need the PC (Studio, play-testing, Rojo), a scheduled check-in on other chats, a ready-to-paste message or a link. Only hand it to the user when it truly needs them (signing in, clicking Allow, publishing, spending money), and say exactly what to click.
- Ask first before anything hard to undo or outside-facing: deleting, making something public, emails, private info, money.
- Explain things in plain, simple words.

## Workflow
1. Back up first: commit before big changes. In Roblox Studio, use **File → Version History** before big edits.
2. Build: `python3 web/src/build.py` (browser) or `python3 roblox/tools/build_rbxlx.py <name>.rbxlx` (Roblox).
3. Test: run the play-tests (`node web/tests/<test>.js`). For Roblox, press Play in Studio and paste any red Output errors.
4. Check phone size (420×820) and PC size. About 80% of Roblox players are on phones.
5. Publish, commit, push, and update this file and the memory file.

## Testing in Roblox Studio (on the PC)
When Claude Code runs on the PC with Studio's MCP server connected (see `START_HERE_ON_PC.md`):
1. Run `list_roblox_studios` and pick the Studio that has the game open.
2. Edit the files in `roblox/src` (the main copy). With `rojo serve` running, changes sync into Studio. Without Rojo, rebuild the place file and reopen it.
3. Run `selene src` in `roblox/` and fix real problems.
4. Use `start_stop_play` to play. Use `get_console_output` to read the Output and fix every red error. Use `screen_capture` to check the look. Use `character_navigation` and keyboard/mouse input to try both doors.
5. Check phone size with Studio's device emulator.
6. Stop the playtest. Commit only when Output has no red errors.

Tips learned while porting 1.5:
- A `rojo serve` may already be running (port 34872) with Studio connected. Check with `curl -s http://localhost:34872/api/rojo` before starting another one.
- Studio test saves persist (DataStore access is on), so your path, cells and position carry over between playtests. Use the admin commands through the remote (`Request:InvokeServer("admin", {cmd = "setpath" or "setcells", target = userId, arg = ...})`) to switch path or brain level.
- The tutorial now has a "Skip tutorial ⏭" button, types fast, and shows NEXT as soon as the text is typed. Skipping counts as done and marks every note as seen (replay from Settings). Use the admin `resettutorial` command to see it again. While testing you can still hide `BrainUI.TutorialStage` from the client.
- Simulated mouse clicks on GUI buttons usually miss. Trigger prompts with `ProximityPrompt:InputHoldBegin()/InputHoldEnd()` from the client. To press any GUI button, set `GuiService.SelectedObject` to it from the client, then send the Return key. Keyboard shortcuts also work (conversation: 1/2/3 to choose, Backspace to leave; M = Settings; F = animal power).
- `execute_luau` on the client resets a Scriptable camera to Custom. To see a scripted camera, press a key first, then `screen_capture`.
- Phone check: set the device with `StudioDeviceSimulatorService` (iPhone 17 Pro) before pressing Play, and call `StopSimulationAsync()` afterwards.
- No real Python on this PC (only the Store alias), so `build_rbxlx.py` and `web/src/build.py` can't run here.
- To test an animal form or school, change brain cells with the admin `setcells` command (dog = 1000000000, fly = 100000, worm = 250) and put them back afterwards (70000000000). Avoid 0 on your own test account: it plays the death ending. The school bell needs the player OUTSIDE the School when it rings, or it counts as already in class.

Don't edit scripts directly in Studio (`multi_edit`) unless Rojo is off, or the files and Studio drift apart. Never run `save_place` over the published game without the user's okay.

## Saving
- **Roblox:** DataStore with session locking.
- **Browser:** `localStorage` key `lbc_save`, plus a backup copy `lbc_save_backup` written at most once a minute and used if the main save is unreadable. Never change the save format without migrating old saves.
