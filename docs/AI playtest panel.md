# AI playtest panel (1.7, Nov 24 2026)

Four pretend players tried the Roblox game in Studio (iPhone 17 Pro size and PC size).

**Note about screenshots:** the Studio game window was minimized and screen control was declined, so screenshots came back blank this time. The flows below were run live through the game's own remotes and their real results were read back. The screenshots from the 1.7 morning test (phone layout, Hoppr, toy phone, animal menu) still apply.

## The panel

| Persona | Who | Rating | Best moment | Worst moment |
|---|---|---|---|---|
| Mia | 8, phone, Lose path, reads slowly | 3.5 / 5 | Toy phone with silly icons, the joke ads | Small text on the phone; once she becomes a dog, the phone only shows 👃 ⚡ 🏠 and she can't find the Lose apps again |
| Leo | 13, PC, Gain path, wants coins fast | 3 / 5 | Promotions and report cards | Found he gets paid for doing nothing: job wages while AFK, an idle shift bonus, and the bank beats every job. The free map taxi makes Hoppr pointless |
| Pip | a dog (1B cells), on the phone | 3 / 5 | The bark and smell trail | Nothing to do as a dog except sniff to places; no way back to the stands that change cells |
| Sam | a parent checking safety and money | 4 / 5 | Prices and odds shown before paying, no debt, preset text only | "Skibidi" (a real brand) appears in 7 places, including a "Skibidi Plushie" |

## What the panel proved live

- **Wages while idle (Leo):** took the Cashier job, stood 300+ studs from work, not clocked in. Coins went from 51 to 63 in one minute. (Audit G2: confirmed.)
- **Shift with zero tasks (Leo):** clocked in at the Supermarket, did nothing for 62 s, clocked out. Payslip: 0 tasks, 6 coins wages. The code also pays the +15 on-time bonus with 0 tasks. (Audit G3: confirmed.)
- **Bank (Leo):** 2% every 10 minutes, shown honestly, but it compounds and pays on whatever is saved at the moment of the tick. (Audit G4: confirmed in code.)
- **Clock-in far from work** is refused correctly.
- **Dog menu (Pip):** the sniff list only has map places, not the four Lose stands. (Audit G5: confirmed.)
- **Brand words (Sam):** `Content.lua` lines 53, 93, 563, 567, 579; `Props.lua:205`; `SocialService.lua:796`. (Audit K1: confirmed.)

## One merged list, most severe first

Panel findings merged with `docs/Flaws found.md` (31 audit items). Status is updated as fixes land.

| # | Flaw | From | Severity | Status |
|---|---|---|---|---|
| 1 | "Skibidi" brand in 7 places (Roblox IP rules) | K1, Sam | High (moderation risk) | Fixed |
| 2 | Job wages paid while not working | G2, Leo | High | Fixed |
| 3 | Shift on-time bonus pays for idling | G3, Leo | High | Fixed |
| 4 | Bank beats working; move-in-before-tick trick | G4, Leo | High | Fixed |
| 5 | Phone minimum sizes (48 px / 14 pt) shrunk by device scale | U1, Mia | High | Fixed |
| 6 | Free instant map taxi makes Hoppr and walking pointless | G1, Leo | High | Fixed |
| 7 | Dogs lose access to the Lose stands | G5, Pip, Mia | Medium | Fixed |
| 8 | Hoppr arrival yanks you out of a seat or conversation | R1 | Medium | Fixed (seat tested live; conversation case checked in code only) |
| 9 | Effects slider misses the wobble and text scramble | Plan 3 | Medium | Fixed |
| 10 | Lose path got almost nothing in 1.7 (bus, joke jobs, piggy bank) | G6 | Medium | Open (feature work) |
| 11 | Bills toast "paid 0" every tick | G7 | Low | Fixed |
| 12 | Joke ad has two UIScales | U4 | Low | Fixed |
| 13 | Text outside Content.lua (car names, quiz/election lines) | R3 | Low | Fixed |
| 14 | Coffee / astronaut / quiz trust the client | E1–E3 | Low | E1, E2 fixed. E3 kept on purpose: showing the right answer after a wrong one helps kids learn |
| 15 | Rainbow loop runs forever | P1 | Low | Fixed (idles when not shown) |
| 16 | Old BRAINVILLE sign inside the Brain Tower | P2 | Cosmetic | Fixed (removed) |
| 17 | Thumbstick-zone bar check, speed-pass collision check | U5, R2 | Low (check in Studio) | Open: needs the Studio window visible |
| 18 | Plan gaps: GPS lines, district NPCs, animal-only paths, hologram HUD, investing, timetable | Plan 4–9 | Feature work | Open |

U2 (icons wider than cells) and U3 (two status bars) were already fixed in the 1.7 morning test.

## How each fix was tested (Nov 24)

All in Studio play mode, reading real results back from the game. The Studio window was minimized, so there are no screenshots and on-screen buttons couldn't be pressed.

- **Wages:** away from work and not clocked in, coins stayed 69 → 69 for a minute. Clocked in at the Supermarket: 69 → 75.
- **Shift bonus:** clocked in on time, did 0 tasks, clocked out after 62 s. Bonus 0 (used to be +15).
- **Bank:** the rate shows 0.5%, and saving and taking out still work. The interest tick itself (every 10 min) was not waited for.
- **Phone sizes:** at phone scale 0.70, buttons are 69 px before the shrink (48 on screen) and text is 20 (14 on screen).
- **Bus:** the first tap says 20 s, a second tap shows the countdown, the player arrives 140 studs away after 20 s, then there's an 8 s cooldown.
- **Seat:** called the bus while seated. The player stood up and travelled, and the chair stayed in place.
- **Animals:** as a dog, the 🐾 menu shows 👃 🛍 🏠. The trail to the 📰 stand points at the right spot. All four stands were found.
- **Effects slider:** checked scramble levels at full, half and off. Full: "welcom 2?". Half: "welcom 2 da library u are readin 4 fun". Off: normal text.
- **Coffee:** sending 60 without opening, or instantly, gives no relief. After 9 s it works.
- **Output:** no red errors after any fix. The code checker is at its usual baseline (2 old errors, 43 warnings).

## Still open

- **#10 Lose path for 1.7:** joke jobs, a piggy-bank toy bank, and a wobbly-GPS bus. This is feature work, not a fix (the free bus now serves both paths).
- **#17:** needs the Studio window visible to check.
- **#18:** plan gaps (GPS lines, district NPCs, animal-only paths, hologram HUD, investing, bus timetable).
- **Conversation + Hoppr refund:** checked in code only. Starting a conversation needs the window visible.
