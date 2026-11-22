# Start here on your PC

This guide sets up your computer so Claude can work on the game **and test it in Roblox Studio itself**: press Play, read the red errors, take screenshots and fix things.

You need about 20–30 minutes. Steps 1–4 are required. Step 5 (Rojo) is recommended.

---

## 1. Install the programs

1. **Claude desktop app:** download it from https://claude.ai/download and sign in. It includes Claude Code (the **Code** tab).
2. **Git:** download it from https://git-scm.com/downloads and keep the default options. Claude Code uses it to save and back up your work.
3. **Roblox Studio:** download it from https://create.roblox.com and sign in with the account that owns "brain game". Make sure it's up to date, because the Claude connection only exists in new versions.

## 2. Get the game files

Pick one:

- **Easiest:** open the Claude app → **Code** tab → choose a folder (for example `Documents`), then type:
  > Clone https://github.com/alonhasfri/empty-repo-3 and check out the branch ccr-1a024e9a-2cwl5b, then open that folder.
- **By hand:** open https://github.com/alonhasfri/empty-repo-3/tree/ccr-1a024e9a-2cwl5b → green **Code** button → **Download ZIP**, then unzip it into `Documents`.

The folder has everything:

- `roblox/`: the game code and the place file `LoseABrainCell_v1.5.rbxlx`
- `web/`: the browser version
- `CLAUDE.md`: the rules Claude reads first

## 3. Turn on Studio's Claude connection (MCP)

1. Open Roblox Studio, then **File → Open from File** → `roblox/LoseABrainCell_v1.5.rbxlx`.
2. **Home → Game Settings → Security** → turn on **Enable Studio Access to API Services** → **Save**.
3. Open the **Assistant** panel → click **…** → **Manage MCP Servers**.
4. Turn on **Enable Studio as MCP server**.
5. Under **Quick connect**, turn on **Claude Code**. If Claude Code isn't listed, close Studio, make sure the Claude app is installed, and open Studio again.

**If Quick connect doesn't work,** open a terminal and add the connection by hand:

- **Windows** (Command Prompt):
  ```
  claude mcp add --transport stdio Roblox_Studio -- cmd.exe /c %LOCALAPPDATA%\Roblox\mcp.bat
  ```
- **Mac:**
  ```
  claude mcp add --transport stdio Roblox_Studio -- /Applications/RobloxStudio.app/Contents/MacOS/StudioMCP
  ```

**Safety:** a connected app can read and change your open Roblox places. Only connect Claude.

## 4. Check that it works

1. Keep Studio open with the game.
2. In the Claude app → **Code** tab → open the game folder, then type:
   > Check that you can see Roblox Studio. List the connected Studio, press Play, wait 10 seconds, read the Output, take a screenshot, then stop.
3. In Studio, **Assistant → … → Manage MCP Servers** should show a **green dot** with "1 connected".

What Claude can do in Studio once connected:

- start and stop Play
- read the Output (red errors)
- take screenshots
- walk the character and press keys
- read and edit scripts
- inspect parts
- save the place

## 5. Recommended: Rojo, to keep files and Studio in sync

Without Rojo, changes Claude makes to the files on disk don't appear in Studio until you rebuild the place file. With Rojo they sync live, and GitHub stays the main copy.

1. Install **Rokit** (the tool installer) from https://github.com/rojo-rbx/rokit (see "Installation" there).
2. In a terminal, inside the `roblox` folder, run:
   ```
   rokit install
   ```
   This installs Rojo and Selene, the code checker.
3. In Studio, install the **Rojo** plugin: run `rojo plugin install`, or get it from the Creator Store.
4. Run `rojo serve` in the `roblox` folder, then click **Rojo → Connect** in Studio.

Or just ask Claude: *"Set up Rojo for the roblox folder and connect it to Studio."* It can run these steps for you.

## 6. First real job to give Claude

> Read CLAUDE.md. Then play-test version 1.4 in Roblox Studio: press Play, try the Lose door and the Gain door, read every red error in Output, fix them in roblox/src, test again until there are no red errors, and check the phone size with the device emulator. Commit when it's clean.

After that:

> Port the browser features (1.5 rooms and conversations first) into the Roblox game, one feature at a time, testing each in Studio.

---

### Notes

- Claude asks before running commands or changing files. To get fewer prompts, choose a mode like **Accept edits** in the mode menu next to the message box.
- Before big changes, in Studio, use **File → Version History** (or ask Claude to commit to GitHub first).
- The GitHub repo is public. To hide it: GitHub → the repo → **Settings** → **Change visibility** → **Private**.
