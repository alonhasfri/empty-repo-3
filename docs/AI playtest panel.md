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

---

# Panel 2 (Nov 24): 10 players in 3 rounds

The Studio window was still minimized, and screen control was declined twice, so screenshots couldn't be taken. Every player was run through the game's own remotes, and the real results were read back. Ratings are fun / looks / ease / clarity (1–5). Looks are rated from the earlier 1.7 screenshots and the code.

## Round 1: everyday players and phone checks

| Player | Fun | Looks | Ease | Clarity | Best moment | Worst moment |
|---|---|---|---|---|---|---|
| Mia, 8, phone, Lose | 4 | 4 | 3 | 3 | Wobbly cash-grab HUD and joke ads | ⚙️ 🛠 🆘 buttons were 34 px and the pass buttons 28 px on a small phone: hard to hit |
| Leo, 13, PC, coins fast | 3 | 4 | 4 | 4 | Promotions and payslips now feel earned | Found conversation scenes paid 30–40 coins every time with a 3 s wait (~70/min, more than any job) |
| Sam, parent | 4 | 4 | 4 | 4 | Prices on every pass button, no debt, 0.5% bank rate shown | Roblox's free-typing chat is on, which conflicts with the "preset text only" rule (see decision below) |
| Cheap-phone player | 3 | 3 | 3 | 3 | Light map: 4,300 parts, no shadow-casting lights, every billboard has a draw distance | HUD buttons too small (same as Mia). The IQ chip text was about 8 px |

**Measured:** at the smallest phone scale (0.70), 11 HUD buttons were under 44 px and 1 label was under 14 px. After the fix, 0 and 0.

**Fixed in round 1:**
- HUD buttons (⚙️ 🛠 🆘, activity icons, 🛒 SHOP / 🗺 MAP, pass buttons) and the IQ/coin chips are sized so they're still 48 px and 14 pt after the phone shrink.
- Conversation scenes pay coins at most once per scene every 10 minutes. Brain-cell rewards are unchanged.

**Decision for the user, not changed:** Roblox's own chat (free typing, filtered by Roblox) is on, and the game has an admin mute for it. CLAUDE.md says "preset text only". Turning chat off is a product decision, so it's left as is.

**Players' ideas:** Mia wants a big "what do I do now?" arrow. Leo wants a weekly pay leaderboard. The cheap-phone player wants a "low graphics" toggle that turns off the street lights.
