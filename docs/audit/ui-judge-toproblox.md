# UI judge: vs top Roblox games (phone, 784x360 captures)

Reviewed: the 35 screenshots in docs/screens/ui-audit/ (INDEX.md plus the 20 most telling images viewed in full, rest by INDEX description). Patterns only; no real game names or assets.

## Scores /10 (top games = 9)

| Area | Score | One-line verdict |
|---|---|---|
| HUD layout | 4 | Left column is 4 stacked mini-widgets with 7 to 9 px text; centre banner and bottom meter fight the 3D view |
| Phone-as-main-menu | 3 | Fine as a flavour prop, wrong as the only door: 3 taps to anything, 40% of the screen eaten, 2 apps per row of dead black |
| Minigames | 3 | A plain dialog on top of the world; no timer pressure, no juice, instant fail text |
| Reward feedback | 2 | Rewards are small beige strips of 10 pt text; no number pop-ups, no fly-to-counter, no sound-and-screen moment |
| Shop | 3 | Wall of text, flat green buttons, no item art, stale Skill Gates copy |
| Settings | 5 | Tabs and sliders are decent; labels are long sentences and the tab strip is cut off |
| First impression | 4 | Good world, good counter; then text banners and a quiz-style UI make it feel like an educational app, not a game |

## 12 biggest gaps, ranked

1. **Text is far too small and too long.** HUD sub-lines (career, "Work shifts 2/4 + Server +50%") are about 7 to 9 px. Top games use 16 to 24 px bold for anything always on screen, with 1 to 3 words.
2. **The left HUD is 4 widgets stacked** (counter card, job chip, career/progress card, Quick button). Cluttered, and the progress card duplicates the objective banner. Pick one number-row plus one icon rail.
3. **No side button rail.** Everything (Store, Jobs, Items, Map, Settings) hides behind the phone. Top games put 4 to 6 big rounded icon buttons with a tiny label on a rail, one tap to open.
4. **Phone covers about 40% of the screen and shows 8 tiny icons with big empty black below.** Apps are about 34 px with 9 px labels. Under the 48 px minimum your own rules set. Black is dead space.
5. **Reward feedback is near zero.** No "+50" floating numbers, no coins or brain flying to the counter, no counter bounce, no confetti, no big banner for a level-up or promotion. A birthday toast reads like a log line.
6. **Toasts are tiny beige strips in the top middle**, stacking over the objective banner and overlapping dialogs (screens 15, 26, 29). Needs one toast lane with a queue, bigger text, colour by type.
7. **Pop-ups are walls of cream paragraph text.** Passes, Jobs, Library, Vs Mode: 3 to 5 lines of explanation before a button. Top games show a card grid with an icon, one price and one button.
8. **Shop has no item pictures, a pushed-off Buy button (cut at the bottom), and old Skill Gates text** (removed feature). Looks unfinished and breaks the honest-money promise of a clear price and effect.
9. **Minigame shell is a dialog, not a game.** Dish duty: tiny timer, plain brown tiles, no combo, no scrub animation, the world blurred behind. Result "Not quite 0 of 6" with no stars, no partial reward, no retry hype. Needs full-width play area and big reward screen.
10. **Visual inconsistency across kits.** Navy settings, cream/red popups, black phone, tan quiz buttons. Top games use one rounded kit with one outline and one colour per button purpose (green = go, yellow = buy, red = close).
11. **Close buttons and tap targets inconsistent.** The X is a big red circle in some screens and a small brown one in others; locked labels in Vs Mode are cut off; Settings tab strip is clipped. Cut-off text reads as a bug.
12. **Always-on objective banner plus stress meter** run across the centre-top and bottom centre and cover gameplay. The stress bar (bottom centre, 190 px wide) sits right where thumbs and the character are. Banner should be a small pill, tappable to expand.

## What already works

- The brain counter with big "70.0B" is a good hero stat, readable and on-brand.
- Quick Play lightning button is a good one-tap idea; Phone icon on the right is readable.
- Settings tabs, effects slider and reduce-flashing toggle are good accessibility.
- Lose-path look (outlines, bright colours) is distinctive and has real personality.

## Phone as main menu: verdict

Keep the phone as a prop for story and per-brain-tier flavour (apps, BrainTok, scrambled labels) but **stop making it the only route**. Add a right-side or left-side button rail for the 5 things players need in under 2 seconds: Shop, Jobs, Map/Bus, Items, Settings. Phone then holds the social/story apps (BrainTok, ClickNews, Invites, Vs Mode, Badges, Help). Shrink the phone to a bottom-right sheet at 300 px wide, full height only when open, and bigger icons (64 px).

## Recommended HUD for phone (784x360, safe margin 12 px)

Always on screen:
- **Top-left, 12,10: Brain counter card, 190x56.** Brain icon 40 px, number at 28 px bold, IQ chip under it at 16 px. Coins chip right of it, 100x36 at 208,14 with 20 px text. Nothing else stacked under it.
- **Top-centre, y=10: Objective pill, 300x34**, 16 px, one line, tap to expand into a card. Auto-hides after 8 s of no change; a small "!" bubble 36x36 replaces it.
- **Top-right, right edge x=736: rail of 4 round buttons, 56x56, 10 px gap** (Shop, Jobs, Map, Settings), icon 32 px and 12 px label under. Starts y=10; ends about y=270 including a fifth (Items). Keep SOS inside Settings or a small 40 px button below.
- **Right, bottom: Phone button 64x64** at (708, 232) next to jump (88x88 at 660,262 shifted, stay clear of the thumb zone).
- **Left, y=100: Quick Play 56x56** only; career/job progress moves into the Jobs panel, and shows as a thin 6 px bar under the counter card.
- **Bottom-left: joystick area (150x150) clear.** **Bottom-centre: stress/emotion meter shrinks to 160x10 at y=340, 14 px label, appears only when above 50%.**
- **Toast lane: centre-right x=450 to 730, y=60 to 140, max 2 toasts, 18 px text, 300x48 each**, never over dialogs (queue until the dialog closes).
- **Pop-ups (shop, jobs, minigame)**: 560x300 centred, 18 pt body, grid of 2 to 3 cards of 160x120 with icon, one price line and a 48 px-tall button; close X 44x44 top-right outside the card edge.
- **Reward pop**: big "+N" 36 px floating up from the character, 3 to 6 icons flying to the counter, counter bounces 1.15x; level-up and promotion get a 1.5 s full-width banner 784x80.
