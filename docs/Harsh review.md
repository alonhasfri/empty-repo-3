# Harsh review (play-test at phone size, Studio, v1.9.2)

Screens are in `docs/screens/review/`. Scope was limited: one pass, about 20 screenshots. Not tested: other jobs besides Dish duty, a full dish run, animal powers beyond looking at the HUD, most interiors, Studio's emulated phone is a short landscape viewport (784x360), so some of the cramping below is partly that.

## Summary

| Area | Score | Worst problem |
|---|---|---|
| First 10 seconds / HUD | 4/10 | You spawn inside a restaurant, with 5+ overlapping HUD pieces, and no clear first action |
| Pop-ups and UI kit | 4/10 | Newspaper plus gender picker stack on top of each other and cut off; two different UI kits |
| Icons | 6/10 | Fine on the phone; HUD uses plain emoji next to real icons |
| Phone home + apps | 6/10 | Map is tiny; phone is cut off at the bottom; lots of apps with unclear names |
| Job minigames | 5/10 | Needs fast spam-tapping of 3 identical-looking cards; fail screen is a dead end; goal text hidden behind a toast |
| Quick Play | 5/10 | Different look from everything else; a toast covers the bottom of it |
| Skill Gates | 4/10 | Question's answer is printed right above it; hint costs 1% of brain (3B at 300B) |
| Map and buildings | 6/10 | Street and river look nice; plaza is bland; HUD hides half the view |
| Lose path | 5/10 | Crowd of name tags fills the screen so you cannot see your own character |
| Animals (dog) | 5/10 | Bark button sits on top of the sprint button; toasts pile up |
| Gain path | 6/10 | Newspaper scene is great but blocks you with a picker that is off-screen |

## Problems, worst first

1. **Newspaper ending + "Man / Woman / Person" picker overlap and run off the screen.** Reaching 300B brings up a stack of 3-4 newspaper pages, a gold title ("The World's Smartest...") drawn through them, and three big buttons, the third cut off at the bottom. It never cleared by itself (waited about 12 s). Why it matters: a kid sees a broken pile and is stuck until they guess to tap a cut-off button. Fix: show the newspaper first, then the picker as its own card centred in a scroll area; make the picker optional and auto-skip. Never show both. Screens: `10-newspaper.jpg`, `11-newspaper-gender-overlap.jpg`.

2. **The first screen is a cluttered room with no one clear action.** You spawn inside the burger restaurant facing a wall. The screen has: stats box, job box, Quick button, objective banner, "Where to go" tag, a customer bubble, SOS, tools, phone, sprint, and a giant yellow smiley at the right edge. About 40% of the view is HUD. Fix: on the first 10 s show only brain count, one big arrow/objective and the phone. Spawn in the open plaza. Fade other things in. Screen: `01-first-10-seconds-hud.jpg`.

3. **Toasts and banners pile on top of the objective banner and each other.** "Happy birthday! You're 132!" covered the dish duty rules text (`03-dish-duty-intro.jpg`); "A Golden Brain appeared nearby" sits on top of the Quick Play footer; the dog power toast sits on the objective banner (`09-dog-stage.jpg`). Fix: one toast lane at the top, queued, never over a pop-up; hold toasts while a modal is open.

4. **Skill Gate gives the answer away and charges a lot for a hint.** The gate shows "You blink 15 to 20 times every minute to keep your eyes wet." and directly under it "Why do you blink? To keep your eyes wet". Hints cost 1% of your brain cells, which is 3 billion at 300B. Also the gate text says "you need 100 IQ" while the HUD shows IQ 20164. Fix: show the fact AFTER the answer, make hints cost a small fixed amount, and show the player's IQ against the requirement. The modal is also half empty on the intro (`13-skill-gate-intro.jpg`) and needs scrolling on the question (`14-skill-gate-question.jpg`).

5. **Dish duty is a reflex test with identical cards, and a fail is a dead end.** Three cards named "Crumby plate", "Crumby plate", "Sticky bowl" and each needs several taps within 20 s. I could not clear it with taps at human speed through the tool, which suggests it is harsh for a young child on a phone. Fail screen says "Not quite" with no tip, no score of how close. Fix: lower taps per card to 2, make the first shift easy (10 s extra), show what to do differently on a fail, give a small consolation coin. Screens: `04-dish-duty-playing.jpg`.

6. **Two different UI kits at the same time.** Quick Play is cozy brown with a red ribbon; Dish duty, Skill Gate and the phone are dark navy; the Brainville newspaper is a third style. Fix: pick the kit for the brain tier and use it for every modal (the CLAUDE.md rule). Screens: `05-quick-play.jpg` vs `03-dish-duty-intro.jpg`.

7. **Lose path: nameplates fill the screen.** At 40B the plaza is full of other players' huge names (e.g. "39Doomday39") and the camera sits behind a crowd, so the player cannot see their own character or where to go. Fix: cap nameplate size and distance (about 30 studs), hide nameplates for NPCs, clamp the camera so it does not sit inside crowds. Screens: `08-lose-path-crowd.jpg`, `09-dog-stage.jpg`.

8. **Dog Bark button covers the sprint button.** Both are at the bottom right and overlap (`09-dog-stage.jpg`). Fix: put animal powers above the sprint button, or swap sprint for the power.

9. **Phone is cropped and the map is tiny.** The Home bar at the bottom of the phone is cut off, the Brainville map shows about a quarter of the town and the legend is tiny text (`07-phone-map.jpg` shows the Lose/Gain legend, 8 px). Fix: let the phone be taller on short screens, and make the map full screen with big pins. The apps page has too many items; "Items", "Jack B", "Gate", "Vs Mode", "Coffee" mean nothing to a new player (`16-phone-more-apps.jpg`).

10. **Gain HUD at the start says "Pick a job" in a grey disabled-looking box with a gold GO button.** Unclear what GO does and the card is hard to read on a bright background (`12-gain-hud.jpg`).

11. **Plaza looks bland.** Big flat stone square, one fountain, a sign you cannot read. Compare to the street along the river (`15-gain-street.jpg`), which is nicer: lampposts, brick pavement, grass, water. Fix: add benches, planters, stalls and people in the plaza; it is the first thing players see.

12. **Console is not clean.** Three lines of "ContentId: rbxassetid://203785492 failed due to: Asset type does not match requested type" at start (a wrong asset id is used somewhere, probably as an image or sound). No red script errors seen.

13. **Fonts and text are small.** Phone legend, job box ("Work shifts: 2/4 - Server (+50%)") and hint text look below the 14 pt minimum on the 360 px-high viewport. Kids will not read them. Fix: cut those lines and show one number.

14. **IQ number is confusing.** The same game shows "IQ: 74" at 72B, "IQ: -12" at 40B and "IQ: banana" for the dog. Funny, but at 300B it is 20,164, which does not match "100 IQ to pass the gate". Fix: cap the display or use a separate "Brain level" for gates.

## What is good

- The brain-tier change is real and visible: desaturated world on Lose, warm brick street on Gain, wordless dog HUD.
- The "Where to go" tag, the objective banner text, and the burger interior (menu board, customers) feel alive.
- Phone opens quickly and the "Work" app launches the minigame in one tap.
- Newspaper idea is charming, if it were not broken.
