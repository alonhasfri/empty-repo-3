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
| 8 | Hoppr arrival yanks you out of a seat or conversation | R1 | Medium | Fixed |
| 9 | Effects slider misses the wobble and text scramble | Plan 3, U-list | Medium | Fixed |
| 10 | Lose path got almost nothing in 1.7 (bus, joke jobs, piggy bank) | G6 | Medium | Open (feature work) |
| 11 | Bills toast "paid 0" every tick | G7 | Low | Fixed |
| 12 | Joke ad has two UIScales | U4 | Low | Fixed |
| 13 | Text outside Content.lua (car names, quiz/election lines) | R3 | Low | Open |
| 14 | Coffee / astronaut / quiz trust the client | E1–E3 | Low | Open |
| 15 | Rainbow loop runs forever | P1 | Low | Open |
| 16 | Old BRAINVILLE sign inside the Brain Tower | P2 | Cosmetic | Open |
| 17 | Thumbstick-zone bar check, speed-pass collision check | U5, R2 | Low (check in Studio) | Open |
| 18 | Plan gaps: GPS lines, district NPCs, animal-only paths, hologram HUD, investing, timetable | Plan 4–9 | Feature work | Open |

U2 (icons wider than cells) and U3 (two status bars) were already fixed in the 1.7 morning test.
