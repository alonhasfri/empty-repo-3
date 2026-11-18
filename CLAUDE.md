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
  - `roblox/tools/build_rbxlx.py` builds the place file.
- `web/lose-a-brain-cell-web.html`: the built browser game. It is published as a private Claude artifact at https://claude.ai/artifact/9dkh8TK9DFDEPFX8KX2uku.
- `web/src/game.src.html`: the browser source. All balance numbers are in `TUNE` (also editable in Admin → 🎚 Tuning).
  - The other files in `web/src/` are the modules that were spliced in: `render3d`, `rooms` (1.5), `v16` (1.6), `content2`, `interact`, `horror`, `polish`.
- `web/tests/`: Playwright play-tests.
- `marketing/`: game icon and thumbnails.
- `.claude/skills/ship-browser-update/`: the release recipe (tip 10).

## Versions
- **Roblox file:** 1.0 to 1.4. Not yet play-tested in Studio after 1.4. Pass, sound and badge IDs are still 0.
- **Browser only:**
  - 1.5 real places and conversations.
  - 1.6 careers, school and animal forms.
  - The content pack and the interactive world.
  - "The Average Files" horror side plot.
  - The polish pack (first-10-seconds hook, sound kit, triple feedback, tuning table, odds, save backup, clean photo camera).
- **Next:**
  - Port the browser features to Roblox.
  - 1.7 time travel.
  - 2.0 creator update.

## Workflow
1. Back up first: commit before big changes. In Roblox Studio, use **File → Version History** before big edits.
2. Build: `python3 web/src/build.py` (browser) or `python3 roblox/tools/build_rbxlx.py <name>.rbxlx` (Roblox).
3. Test: run the play-tests (`node web/tests/<test>.js`). For Roblox, press Play in Studio and paste any red Output errors.
4. Check phone size (420×820) and PC size. About 80% of Roblox players are on phones.
5. Publish, commit, push, and update this file and the memory file.

## Saving
- **Roblox:** DataStore with session locking.
- **Browser:** `localStorage` key `lbc_save`, plus a backup copy `lbc_save_backup` written at most once a minute and used if the main save is unreadable. Never change the save format without migrating old saves.
