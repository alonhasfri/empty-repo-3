# Lose a Brain Cell / Gain a Brain Cell

A Roblox game with two paths, plus a browser version you can play without Roblox:

- **Lose path:** start with 86 billion brain cells and get as dumb as possible, down to 0.
- **Gain path:** start at IQ 80 and get smarter through reading, jobs, Skill Gates, inventions, space, and the World's Smartest title.

The game is published on Roblox as **"brain game"** under the **Cult of the 39** community.

**Core loop:** players do things that change their brain cells: books, jobs and inventions to get smarter, or clickbait and brainrot to get dumber. The town, their body and the gameplay change with them, unlocking new places, secrets and endings.

## What's in this repo

| Folder | What it is |
|---|---|
| `roblox/` | The Roblox game: the Luau source (`src/`), the builder (`tools/build_rbxlx.py`), the ready place files (`LoseABrainCell_v1.4.rbxlx` is the latest) and the guide `HOW_TO_USE.md`. |
| `web/` | The browser version: `lose-a-brain-cell-web.html` (the built game, one file) and `src/` (its source modules). |
| `web/tests/` | Playwright play-tests (run `node web/tests/test10.js` and the rest; screenshots go to `web/tests/shots/`). |
| `marketing/` | Game icon (512×512) and three 1920×1080 thumbnails. |
| `pictures/` | Mockups, map and UI pictures, and test screenshots. |
| `START_HERE_ON_PC.md` | Setting up a PC: Claude app, Roblox Studio, connecting Claude to Studio so it can play-test, and Rojo. |
| `CLAUDE.md` | Rules, style and structure for any AI working on this project. Read it first. |
| `.claude/skills/ship-browser-update/` | The step-by-step release recipe (build, test, publish, push, document). |

## Roblox version (updates 1.0 to 1.4)

1. In Roblox Studio: **File → Open from File** → `roblox/LoseABrainCell_v1.4.rbxlx`.
2. **Home → Game Settings → Security → Enable Studio Access to API Services**.
3. **File → Publish to Roblox As** → "brain game" → **Overwrite**.

The town is built by code when you press Play. Game pass, sound and badge IDs are still `0` in `ReplicatedStorage → Shared → Config` and `Badges`.

To rebuild the place file from source:

```
python3 roblox/tools/build_rbxlx.py LoseABrainCell_v1.4.rbxlx
```

## Browser version (has updates 1.5, 1.6 and more)

Open `web/lose-a-brain-cell-web.html` in a browser. It is a 3D (three.js) single-player copy of the game with:

- **1.5:** walk-in rooms and conversation scenes.
- **1.6:** careers, school and animal forms.
- Random events, job minigames, the interactive world, and the secret horror side story **"The Average Files"**.

Saves are kept in the browser, with a backup copy in case a save breaks.

The polish pack (from a video of AI game-making tips) adds:
- a fun action in the first 10 seconds
- a sound kit
- triple feedback on every action (sound, shake, number)
- every balance number in one table (Admin → 🎚 Tuning)
- odds shown at the wishing fountain
- a clean photo camera that hides the UI and your character

`web/src/game.src.html` is the base page. The other files in `web/src/` are the modules that were spliced into it over time. `build.py` injects the game text (`content.json`, exported from the Roblox `Content.lua`) and writes the final HTML.

## Not done yet

- Test 1.4 in Roblox Studio.
- Bring the browser-only features (1.5, 1.6, the horror story) into the Roblox file.
- Update 1.7 (time travel) and 2.0 (creator update).
- Upload `marketing/` to the Roblox game page. These are made from the browser version; real Studio screenshots would match the Roblox game better.
- Real sounds for the Roblox file (all sound IDs are still 0).
