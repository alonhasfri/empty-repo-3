# UI judge (10-year-old on a phone + impatient older sibling)

Source: 35 captures in `docs/screens/ui-audit/` (784x360 phone landscape, v1.9.2). Harsh on purpose.

## Scores

| # | Screen | /10 | One-line verdict |
|---|---|---|---|
| 01 | hud-rest | 5 | Top-left stack is tiny and dense; "Job > Shift > Promotion > Next job" micro text unreadable; objective banner thin |
| 02 | phone-home | 5 | Phone fills the right third and hides the world; icons OK but labels tiny; dock cut off at bottom edge |
| 03 | phone-more-top | 4 | Page is cut off at the bottom, 3rd row half hidden, scroll bar is a thin pink line |
| 04 | phone-more-bottom | 4 | Same; empty grey slots, no clear "end" |
| 05 | app-store | 3 | Still says "Skill Gates" (feature removed), real-money buttons with tiny text, last button cut off |
| 06 | toast-birthday | 6 | Readable but sits on top of the objective banner |
| 07 | work-notatwork | 4 | 70% of the pop-up is empty cream space, tiny text, one button |
| 08 | ebooks-library | 4 | Answer buttons faded (disabled look) and last one cut off; timer text tiny |
| 09 | braintalks | 5 | Hint toast covers the character; Skip/Watch buttons are clear |
| 10 | admin-panel | 2 | Owner panel opened by a stray tap on a kid-facing screen; developer-looking |
| 11 | items | 4 | Mostly empty, tiny text, big icons for no info |
| 12 | home | 4 | Tiny text in a narrow phone, long scrolling list of "Buy 25" |
| 13 | settings-top | 5 | Tabs cut off at the edge, 4 big near-identical buttons, no icons that differ |
| 14 | settings-graphics | 5 | Fine, but the white selection box is harsh and text is small |
| 15 | settings-controls | 3 | A toast sits right on top of a setting row, hiding it |
| 16 | settings-gameplay | 3 | Skill Gates setting still there; "Horror: Full" is the default on a kids' game; toast overlaps |
| 17 | settings-help | 5 | Text-heavy help; ok |
| 18 | bus-map | 4 | Map is a small cluster of tiny pins you cannot tell apart; real list is below the fold |
| 19 | jobs | 4 | Wall of small text, arrows and abbreviations ("Bagger -> ... -> Store Manager") |
| 20 | jackb | 5 | Quiz buttons OK; question text small; 5 s forced wait |
| 21 | vsmode | 3 | Lock labels cut off ("needs IQ 120+ or the right job"), long text, brown-on-brown |
| 22 | town | 4 | Plain text list, no pictures, "nobody yet" repeated |
| 23 | badges | 4 | List of grey text; hard to see what you can do |
| 24 | help | 5 | Duplicate of Settings Help |
| 25 | quickplay | 7 | Best pop-up: clear question, 4 big buttons, progress bar |
| 26 | dish-intro | 3 | Toast lands on the instruction text; half the box is empty; unreadable intro |
| 27 | dish-playing | 7 | Big readable buttons and timer. Nothing says which to tap first or that plates need several taps |
| 28 | dish-result-fail | 4 | "Not quite 0 (goal 6)" is a flat failure with tiny hint; half empty box |
| 29 | stacked-toasts | 4 | Two toasts stack over the objective banner and each other |
| 30 | invites | 5 | Clear Go now / Later; world behind is odd |
| 31 | event-orderup | 5 | Good START button; intro text tiny and gold-on-dark |
| 32 | lose-hud-place-card | 4 | Place card covers the middle of the screen with tiny text; a crowd of avatars blocks the view |
| 33 | lose-phone-home | 3 | BRAIN DROP toast, huge chat names (665gg) and phone all fight; "Steal A" label cut off |
| 34 | lose-braintok | 4 | Video content is tiny, Share/like icons overlap the text; SWIPE button is the only clear thing |
| 35 | dog-shop-modal | 2 | Modal text covers a SKIP button behind it, 5 s forced wait, white box does not match any other style |

Average: about 4.3 / 10.

## 15 worst UI problems (worst first)

1. **35-dog-hud-shop-welcome-modal.jpg**: A plain white box with a red SKIP button hidden behind the text and a "5s" lock. A dog (or any kid) sees a wall of text with two overlapping buttons and cannot tell what to press. Fix: use the same dark/cream modal style as everything else, one big "OK" button, no overlapped controls, no forced wait, 1 to 2 short lines.
2. **10-app-items-opened-admin-panel.jpg**: An owner/admin panel can be opened over the phone by a stray close tap. Fix: admin panel must never open from a normal close button; put it behind a long-press or a separate key, and only for staff.
3. **Tiny text everywhere (01, 07, 11, 12, 19, 21, 23)**: Most body text is about 8 to 10 px at this size. A 10-year-old cannot read it without squinting. Fix: 14 pt minimum for body, 18 pt for buttons, and cut the words in half.
4. **26-minigame-dish-intro.jpg and 15/16 settings**: Toasts land on top of instructions and settings, hiding the text you need. Fix: put toasts in a fixed lane at the top, block them while a modal or minigame is open, and queue them.
5. **29-toasts-stacked-invite.jpg and 06**: Toasts pile on the objective banner and each other, and cover the middle of the screen. Fix: one toast at a time, max 2 s, stacked below the banner, tap to dismiss.
6. **05-app-store.jpg and 16-settings-gameplay.jpg**: Both still mention Skill Gates, which was removed. Looks broken and confuses. Fix: remove the strings, the gates setting and the "Extra Hints" product.
7. **02, 03, 04 phone pages**: The phone covers a third of the screen, its bottom edge is cut off, and the rows are chopped. Fix: shrink the phone's frame to fit the 360 px height, show a full 3x3 page with a visible page dot, remove the empty grey slots.
8. **33-lose-phone-home.jpg**: Loud overlapping clutter (BRAIN DROP toast, giant player name tags, phone, tutorial banner). Fix: hide other players' name tags while the phone is open; limit the toast size; fix the cut-off "Steal A" label.
9. **32-lose-hud-place-card.jpg**: The place card covers the view with tiny text and a lone button that looks like a text box. Fix: smaller card at the side, big "Go" button, a clear icon for what tapping does.
10. **21-app-vsmode.jpg**: Lock labels cut off, brown text on brown buttons, long reading. Fix: wrap the labels, use a lock icon plus short "IQ 120", and a brighter disabled style.
11. **18-app-bus-map.jpg**: The map pins are tiny and overlap, so a kid cannot pick a place. Fix: enlarge the map or show a list of big place buttons first, with the map as optional.
12. **07-app-work-notatwork.jpg and 12/11 (mostly empty boxes)**: Pop-ups are 70% empty space with tiny text. Fix: shrink the pop-up to fit its content and enlarge the text and button inside.
13. **28-minigame-dish-result-fail.jpg**: "Not quite. 0 (goal 6)" with a tiny hint. A kid who scored zero will feel bad and not know why. Fix: show a big friendly face, say what to do ("Tap each plate 3 times"), and make "Another shift" the main button.
14. **08-app-ebooks-library.jpg**: Answer buttons look greyed-out (disabled) during the 3 s read wait and the last one is cut off. Fix: show a clear countdown button, and make all four answers fit on screen.
15. **13 to 17 Settings**: The tab bar cuts off at the edge, with eight tabs; options read like one long list of identical buttons, and "Horror: Full" is the default. Fix: use icon-only tabs that fit, group toggles with ON/OFF switches, and default Horror to a safe level.

## Cross-cutting notes

- Two visual languages: dark navy modals (Settings, minigames) and cream/brown parchment modals (Store, Jobs, Badges). Pick one, like top Roblox games do.
- The top-left HUD stack (brain, job, progress, objective) is four small strips, not one clear block. Pick the one thing a kid cares about and make it big.
- Buttons that matter (GO, Quick, Phone) are small and have different shapes and colors. Make the primary action always the same color and at least 48 px.
