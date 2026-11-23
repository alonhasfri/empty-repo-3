# How to make the game passes and badges (by hand)

You need the Roblox account that owns "brain game", on a computer browser. You can do it on a phone in Chrome, but a PC is easier.
Menu names may look a little different on the site.

## A. Game passes (7 to make)

1. Go to **create.roblox.com** → **Creations** → click **brain game**.
2. On the left: **Monetization → Passes** → **Create a pass**.
3. Fill in:
   - **Image**: a square picture, 512×512. Any simple icon is fine for now.
   - **Name** and **Description**: copy them from the table below.
4. Click **Create pass**.
5. Open the new pass → **Sales** (or "Item for sale") → turn **on** "Item for sale" → type the **price** → **Save**. A new pass is NOT for sale until you do this.
6. Copy the pass's **ID**, the long number in the address bar (…/passes/**123456789**/…).
7. Write the ID next to the pass name in the table below.

| Pass name | Price (Robux) | What it does (description) | ID |
|---|---|---|---|
| Golden Skip Button | 75 | Skip boring text with one golden button (Lose path) | |
| BUY BRAIN 🧠🔥 | 5 | A joke: you buy a brain… and lose more brain cells | |
| Extra Loud Death | 25 | Your 0-brain-cell ending is EXTRA loud | |
| VIP Library Card | 199 | Comfy VIP reading room and nicer books (no Skill Gate help) | |
| Extra Hints | 99 | More hints in puzzles (never answers Skill Gates) | |
| Astronaut Early Access | 100 | Train for the Moon a bit earlier | |
| **Life Pack** (new) | 100 | Grow from baby to grandparent, plus 5 new buildings | |

Check the descriptions against the game (Config.lua → `Config.GamePasses`). Never promise something the pass doesn't do.

## B. Badges (26 in the game)

- **Free limit:** 5 badges per game every 24 hours. After that, each one costs 100 Robux.
- **Tip:** make 5 a day for free, so all 26 take about 6 days. Start with the important ones: Gate1, FirstJob, SmoothBrain, Eureka, Speedrun.

1. create.roblox.com → Creations → **brain game**.
2. On the left: **Engagement → Badges** → **Create a badge**.
3. Upload a **512×512 image** (a round icon looks best). Fill in the **name** and **description** from `roblox/src/ReplicatedStorage/Shared/Badges.lua`. Each line has `name = "…"` and `desc = "…"`.
4. Click **Create badge**, and make sure the badge is **Enabled** (disabled badges can't be earned).
5. Copy the badge **ID** (the number in its address) and write it down next to the badge's short name (e.g. `Gate1`).

## C. Put the IDs into the game

When your Claude usage is back, paste this into the PC chat with your list:

> Here are my pass and badge IDs: [your list]. Put them into Config.lua (Config.GamePasses, the id fields) and Badges.lua (id fields), test a purchase and a badge in Studio, commit and push.

Or do it yourself in Roblox Studio:
- Open **ReplicatedStorage → Shared → Config**, find `Config.GamePasses`, and replace each `id = 0` with the pass ID.
- Do the same in **Badges**.

If Rojo is connected, edit the files on the PC instead (Documents\empty-repo-3\roblox\src\ReplicatedStorage\Shared\), because Rojo copies the files over Studio.

## D. Also useful while you wait
- **Group ID** (`Config.GroupId = 0`): if the game belongs to the "Cult of the 39" community, the group ID is the number in the community page address. It's used for staff ranks in the admin panel.
- **Game icon and thumbnails:** create.roblox.com → brain game → **Places → Thumbnails / Icon**. Upload the pictures from the `marketing/` folder.
