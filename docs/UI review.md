# UI review (Nov 24)

You said the UI is "too big and the buttons are all over the place". This is what was measured, what four reviewers thought, and what was changed.

## What was measured (PC, 1350×536 game view)

- **16 buttons on screen at once**, in 4 different styles:
  - 9 square activity tiles in a 2-wide grid that ran off the bottom of the screen
  - 3 round buttons top-right
  - 2 big gradient pills (SHOP, MAP)
  - 2 pass pills at the bottom
- **A permanent title banner** ("GAIN A BRAIN CELL") took the top middle, with the goal line and notifications under it.
- **Notifications** were big, stayed 4 s, and stacked without limit.
- **Phone app names** sat under the wrong icons, lining up with the next row.

## The four reviewers

| Reviewer | Verdict |
|---|---|
| Mobile UX designer | Too many targets compete for the thumb. The activity grid falls off small screens. The bottom passes sit right where thumbs rest. |
| Top-Roblox-game designer | Popular games show 3–5 HUD buttons and put the rest in one menu. Four button styles look amateur, and a permanent title banner is wasted space. |
| An 8-year-old | "Which one do I press?" The banner and passes are noise. The phone names were confusing (🚀 said "eBooks"). |
| "Less is more" critic | Hide the passes in the Shop, keep at most 4 activities with a "More" button, show the title only in the lobby, and keep notifications small and few. |

## Ranked problems → status

1. Too many buttons (16) → **9**. Activities show at most 4 (Gain: Phone, Work, Library, ☰ More); the rest are in "More". `Config.UI.HudMaxButtons`.
2. Pass buttons on the HUD → **only in the 🛒 Shop**. Price and effect are still shown before buying. `Config.UI.HudPassButtons = false`.
3. Permanent title banner → **lobby only** ("pick a path").
4. UI too big → **smaller**: 42 px / 12 pt minimums after the phone shrink, and the UI stops growing at 100% on big screens.
5. Phone names under the wrong icons → **fixed**: each icon and its name share one column.
6. Notifications → **small and calm**: about 3 s, at most 3, repeats merged ("×4"), and "Fewer notifications" (on by default) hides routine news.
7. Still open:
   - The floating "Scientist • Galaxy Glasses" line on the right could move into the phone.
   - The Vs Mode sign in the plaza is a world sign, not HUD, but it is bright. It might become smaller and more muted in the new styles.

## Clean layout (now)

```
PC and phone (landscape)
┌──────────────────────────────────────────────────────────┐
│ 🧠 counter (IQ, coins)                 ⚙️ 🆘 (🛠 admin)  │
│ [📱][🛠]                               [ 🛒 SHOP ]       │
│ [📚][☰ ]          goal line           [ 🗺 MAP  ]       │
│                   notifications (≤3)                     │
│                                                          │
│ (thumbstick)                                    (jump)   │
│                 [ brain bar: IQ / gate ]                 │
└──────────────────────────────────────────────────────────┘
```

## Screens

- `screens/ui/hud_pc_before.jpg` → `screens/ui/hud_pc_after.jpg`
- `screens/ui/hud_phone_smaller.jpg` (iPhone 17 Pro, after the size fix)
- `screens/ui/phone_labels_fixed.jpg`
