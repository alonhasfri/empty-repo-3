# UI review (Nov 27): merged from 3 UI judges, 4 bug hunts and 35 phone screenshots

Sources: `docs/audit/ui-judge-kid.md`, `ui-judge-designer.md`, `ui-judge-toproblox.md`, `bugs-client-ui.md`,
`bugs-gain-server.md`, `bugs-lose-animals.md`, `gameplay-critique.md`; screenshots in `docs/screens/ui-audit/`.

## Scores
Kid on a phone: about 4.3/10 average over 35 screens. Versus top Roblox games: HUD 4, phone menu 3, minigames 3,
rewards 2, shop 3, settings 5, first impression 4. Gameplay: Gain loop 4, Lose loop 3, retention 3.

## Why it looks "all over the place" (all three judges agree)
1. **Four different looks at once.** Cream storybook pop-ups with a red ribbon (Store, Work, Library, Map, Jobs,
   Vs Mode, Badges, Quick Play), dark navy pop-ups (Settings, minigames), the black phone, and the dark admin panel.
   Cause: `UI.modal` still picks a style from `UI.PopStyles` (clean / glass / storybook / bubbly / neon) on top of the
   one kit, and many screens hard-code their own colours (~149 hard-coded colours in Stations.lua).
2. **Text far too small.** HUD and body text is 8-12 px on a phone. Minimum should be 14, buttons 18.
3. **No consistent controls.** 4 kinds of close button, ~6 button colours, corner radii from 6 to 34, 3 fonts + a serif.
4. **Too much text, too little feedback.** Walls of text in pop-ups; rewards are just numbers (no "+N", no coin
   burst, no bounce).
5. **Clipping.** Vs Mode lock labels, the 4th Library answer, the Store buy button, the Settings tab strip, "Steal A".
6. **Everything is behind the phone.** Each action takes 3 taps; the phone covers 40% of the screen with ~9 px labels.

## Fixed already (this round, tested in Studio)
Skill Gates removed; Extra Hints pass no longer sold; toasts wait while a pop-up is open; title picker; map pop-up;
dog Bark button; calm first screen; name tags smaller; dish duty easier; minigames end at the goal; brain-cell cap;
birthday toast spam; "HOT SINGLES" and "free Robux" texts replaced; emoji that showed as boxes.

## Plan: "Brain Kit" (one design system), in this order
1. **Tokens** (`UI.Tokens`): one palette (surface #1B2030, card #2A3147, text #F5F6FA, muted #A8B0C8, primary green
   #34C46B, secondary #3E4A6B, danger #F0485A), FredokaOne for titles and numbers, Gotham for the rest; sizes title 24 /
   body 16 / min 14 / buttons 18; radius 12 (controls) and 16 (cards); touch targets 48. Brain tier only changes the
   accent colour, radius and motion, never the layout (dumb = pink/orange, chunky; smart = blue/gold, calm).
2. **One pop-up** (`UI.modal`): 56 px header with the title on the left and the same red close button in the same place,
   a scrolling body, an optional sticky footer with at most one main and one second button. Remove `PopStyles`.
3. **Buttons** (`UI.button` kinds: primary / secondary / danger) and move hand-made buttons onto it.
4. **Text minimum 14** everywhere, fewer words.
5. **HUD**: brain card + coins top-left with big numbers, one objective pill top-centre, a right-side rail of round
   buttons (Shop, Jobs, Map, Items, Settings) so common things are 1 tap, phone stays for everything else.
6. **Rewards**: a floating "+N" and coins flying to the counter with a bounce, a level-up banner.
7. Migrate screens: Settings, Store, Library quiz, Jobs, other apps, minigames, Hud, phone, admin. Re-run the screenshots.

## Open bugs to fix after the UI pass (from the audits)
- Social round pop-ups can trap a phone player if the partner leaves (no close, no timeout).
- Pop-ups can wipe each other (a ride invite or Eureka closes an open minigame/bank screen).
- Minigame score is trusted from the client: needs a per-job cooldown and an at-work check.
- Octopus / microbe / tardigrade stages have no animal body.
- Conversations can be interrupted by death / school teleports; `sued_accept` and `act.setup` can leave players stuck.
- Leave/shutdown saves have no retry; the reset backup key never expires.
- Library alone reaches IQ 200 in ~10 min now that gates are gone (needs diminishing returns).
- Store and Settings text still mention Skill Gates.
