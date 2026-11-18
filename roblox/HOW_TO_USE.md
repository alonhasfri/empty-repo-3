# How to use LoseABrainCell_v1.4.rbxlx

One Roblox place file with updates **1.0, 1.1, 1.2, 1.3 and 1.4** inside.

## 1. Open it
1. Get the file onto the computer (WhatsApp Web, email, or claude.ai on the computer).
2. Roblox Studio → **File → Open from File…** → pick `LoseABrainCell_v1.4.rbxlx`.
3. The world looks empty in Studio. That's normal: **the town is built by code when you press Play.**

## 2. One-time settings (important for the "real" look)
1. (Skip if your Studio has no "Technology" setting: newer Studio uses the best lighting automatically.)
2. **Home → Game Settings → Security → Enable Studio Access to API Services → ON** (saving + friend avatars in Studio).

## 3. Publish under Cult of the 39
Already published "brain game"? Then: **File → Publish to Roblox As… → pick "brain game" → Overwrite.** (First time: Create new game → Creator: Cult of the 39.)
Staff ranks come from community ranks (255 Owner, 100+ Head Moderator, 50+ Moderator, 10+ Tester), in Studio too, **after** the game is published under the community.

## 4. Play
- Bottom bar: pick **LOSE** or **GAIN**. Then the bar opens every activity from anywhere.
- 🗺 **Map**: taxi to any building in town.
- Brain counter is in the top-left. **⚙️ Settings** lets you move it to another corner, **drag it anywhere**, or make it bigger.
- If something breaks: **View → Output**, screenshot the red text and send it to Claude.

## What's new in this file
**Town:** plaza, Brainrot Mall, Microwave Diner, Wall Alley, Supermarket, School, University, Jack B Cinema, Beethoven's Café, Hospital, Office Tower, Job Center, Courthouse, Science Lab, Park, houses, roads, cars, street lights, real terrain grass + water, clouds.

**Real people:** your NPC friends are built from **your actual Roblox friends' avatars and names** (or default people if that can't load). The Perfectly Average Guy is a real avatar too.

**Jobs:** get one at the Job Center, then work at the real place (School, Hospital, Courthouse, Lab…). 🚕 taxi to work.

**Secret inventions:** work job tasks → the 💡 idea meter fills → **EUREKA cutscene** → pick 1 of 3 inventions → **SECRET INVENTION UNLOCKED!** Use them from 🎒 Gadgets (Rubber Duck, Infinite Coffee, Pigeon Launcher, Brain Rain, Anti-Gravity Boots, Teleport Remote, Focus Goggles, Pocket Time Machine, Robot Helper).

**BrainTok:** the scroller is now a phone with 7 animated videos (swipe up on phones).

**Update 1.1, Comeback:** brain-chase cutscene, start at 1 brain cell, janitor/street sweeper jobs, bandage "scars", friends visit to apologize, Complete Makeover before/after.

**Update 1.2, Smart vs Dumb (🎭 button):** Classroom, Courtroom (you can get sued!), Debate Show, Doctor, Therapist, Animal Experiments, Journalist (your clickbait shows up for dumb players), and an **Election** every 20 minutes. NPCs fill in when nobody else joins.

**Balance:** losing brain cells is about half as fast as before.

## Add your IDs anytime
`ReplicatedStorage → Shared → Config` (sounds, music, game passes) and `Shared → Badges` (badge IDs). 0 = not set up yet.

## Use real 3D models from the Toolbox (optional)
The game builds its own detailed props (microwaves, cars, desks, arcade machines, bookshelves, vending machines…). To swap any of them for a real model:
1. In Studio, open **View → Toolbox** and search, e.g. "microwave".
2. Drag the model into the world, then in **Explorer** drag it into **ServerStorage**. If there's no **Props** folder there, right-click ServerStorage → Insert Object → **Folder**, name it `Props`, and put the model inside.
3. Rename the model to one of: `Car`, `Microwave`, `Desk`, `ArcadeMachine`, `Newsstand`, `PhoneDisplay`, `ShopCounter`, `Bookshelf`, `TicketBooth`, `BulletinBoard`, `CafeCounter`, `LabBench`, `HospitalBed`, `VendingMachine`, `Bench`.
4. Press Play: every one of those props in town now uses your model (resized to fit). Scripts inside Toolbox models are deleted automatically for safety.

## New in 1.3
- **📱 Phone button**: BrainTok, ClickNews, Steal A, Comments, Vs Mode, Maps, Store and Settings are apps on your phone (Gain path: Jack B, eBooks, Jobs, Work, Projects, Gadgets…).
- **The whole UI scales to your screen** (phone, tablet, PC).
- **🗺 Maps app**: a drawn town map, tap any pin (Microwave Diner, Wall Alley, School…) to take the taxi.
- **🔬 Major Projects** (Scientists or IQ 135+): grant proposal → research → peer review → test day → **Noble Prize ceremony** → the fake ending. Inventions change the world (teleport pads, rocket, brighter lights, food stands, faster walking, robots…) in your server until it closes and **in every server for 1 hour (+15 min for each extra inventor)**. The **first player ever** gets a badge and a statue in the **Hall of Inventors**. Plus the secret Time Machine that always fails.
- **More admin commands**: private message, spectate, jail, respawn, walk speed, jump power, size, coins, stress, embarrassment, give gadget, pass a gate, reset tutorial, bring everyone, mute everyone, global invention hour, server quiz, clear junk.

## New in 1.4: Space and secrets (+ the guided tutorial and the town styles)
- **📖 Guided tutorial (both paths).** The first time you pick a path, it takes over the screen: black bars, the camera flies over town, "⚠️ IMPORTANT" slams in, Dr. Wrinkles talks and the text types itself out. NEXT only shows up once you've had time to read. Some notes have a quick question (wrong answer = watch it again). Then "STEP X OF Y" cards with a bouncing arrow on the real button. It can't be skipped the first time. **Settings → 📖 Replay the tutorial** plays it again (skippable).
- **The town changes style with your brain** (on your screen only): lobby + start of Lose = cute town with loud cash-grab signs → Lose below 70B = full cash grab → below 45B = falling apart. Gain: IQ 80–95 cash grab → 95–120 cozy → 120–135 realistic → 135+ fancy → 200+ fancy + futuristic.
- **🚀 Astronaut + Space Lab.** Gain path, IQ 160, and someone (anyone, ever) has invented Space Travel. Launch Pad is east of town → rocket cutscene → the Moon (low gravity, Earth in the sky). Space Lab: 3 training minigames (docking, oxygen, zero-G), Space Gates, and 3 space-only projects (Space Farming, Asteroid Mining, Mars Habitat). 📱 Phone → **Space** shows where you stand.
- **Astronaut Early Access (100 R$)** is only offered at IQ 160 while nobody has invented Space Travel, and the screen says clearly that it becomes free for everyone once anyone invents it. Add its ID in `Config → GamePasses → AstronautEarly`.
- **👑 World's Smartest (IQ 200):** books fly off the library shelves with your name in them, newspapers, breaking news, then you pick Man / Woman / Person. Badge + statue in the Hall of Inventors + Retired Genius (people walk up and ask you questions).
- **Overflow zone:** past ~200 IQ your head grows bigger and bigger. Elephant joke at 257B. Badge "Too Much Brain" at 1 trillion.
- **🏰 The Endless Castle (secret):** a plain grey house with a red roof just outside town (south). Step on the hole… The route changes every season. Rewards: big bonus + 2× speed for 30 minutes (Lose path: big loss + 2× loss speed), the Castle Map (taxi never waits), badge "Lost and Found". Secret rooms: the Upside-Down Room, the Gallery, the Clickbait Room, the Royal Chicken, Credits, the Box Room, and a door only worms fit through.
- **New sound slots** in `Config → Sounds`: `Whoosh`, `TypeTick`, `ImportantSlam`.
- Admin **resettutorial** now resets the new tutorial instantly.
