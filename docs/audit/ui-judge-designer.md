# UI judge (designer): why the UI looks "all over the place"

Source: 35 captures in `docs/screens/ui-audit/` (784x360) plus `Client/UI.lua`.

## 1. Diagnosis

Root cause: the 1.9 "one kit" fix only unified the **themes** (`UI.Themes` all overwritten by `KIT`). It did NOT unify the **pop-up skins**. `UI.modal` picks a second, independent system, `UI.PopStyles` (clean / glass / storybook / bubbly / neon), and the phone is a third (black bezel, `Color3.fromRGB(14,14,18)`, radius 34). So three surface systems coexist, and a fourth for the HUD cards.

Distinct styles counted:

| Thing | Variants seen | Where |
|---|---|---|
| Surface / pop-up skin | 4: (a) cream storybook, red header plate, brown buttons (05, 07, 08, 18, 19, 21, 23, 25); (b) dark navy "clean" with cyan underline header (13-17, 26-28); (c) black phone OS (02-04, 09, 11, 22, 33, 34); (d) dark owner/admin panel (10); plus translucent HUD cards (01, 32) and a bare white-on-grey modal (35) | `UI.PopStyles`, `UI.modal`, `PhoneOS.lua`, `Hud.lua` |
| Header | 5: centred red ribbon (cream), left-aligned title + cyan rule (navy), left title on black with pink X (phone), admin title with search, no header (35) | `UI.modal` branches per P |
| Close button | 4: brown circle (cream), pink-red circle (navy), pink-red circle on phone, red square (admin) | same |
| Primary button | green (Buy, Start, Another shift), yellow-gold (Bus to work, Job board), brown (cream list rows and quiz answers), blue (Watch), dark-navy outline (settings rows), grey-beige at 50% (Library answers look disabled) | `UI.button` + per-call colour overrides |
| Fonts | Gotham Bold/Medium/Black plus Fredoka plus a serif (Merriweather-style) in storybook via `FontFace`; emoji in every label as a 5th "font" | `PopStyles.*.face`, `Hud.lua` |
| Corner radius | 34 (phone), 28/16/14/12/9/6 (kit, themes, skins) | `UI.corner(frame, N)` scattered |
| Borders | 5 px black (bubbly), 2 px white 12% (kit), 8 px black (phone), brown line (storybook), cyan 3 px (neon), white 4 px selection box | |
| Icons | emoji only; app tiles use gradient squares with emoji; HUD uses brain PNG, gold lock-coin chip and a hammer icon in a pink circle | |

Hierarchy / spacing / contrast problems:
- Body text is 10-12 pt in the cream pop-ups (07, 08, 19, 21, 23) and 9 pt in the HUD job card (01: "Work shifts 2/4" is unreadable). Against the 14 pt minimum in CLAUDE.md these fail. Caption grey on cream (23 locked badges) is about 2.5:1.
- Huge empty areas: 07 (Not at work) is 60 percent empty; 25 Quick Play and 26 Dish intro ditto; meanwhile 05, 08, 19, 21 crop content at the bottom with no scroll hint.
- Cropped controls: Vs Mode lock labels cut ("Needs IQ 120+ or the right job", 21); Library 4th answer cut (08); Store buy button cut (05); settings tabs run off the edge with no fade (13).
- Toasts (cream pill, orange border) collide with content: over the settings list (15), over Dish text (26), stacked over the HUD banner (29). They are a 5th colour language (cream/orange) that matches no surface.
- Phone: tiny 10 pt app labels, "Steal A" truncated (33), a pink X overlapping the title (34 "BrainTok", 22 "Town"), a half-hidden Home bar. Brain-tok screen has text overlapping icons (34).
- Dish minigame (27) uses a third button colour (tan) at 18 pt in a navy shell: sizes are 3x the rest.
- Lose HUD (32, 33) shows pink GO button vs cyan GO (Gain), fine as tier tint, but the pink is not the accent used anywhere else.
- Stale content: Skill Gates mentioned (05, 16), admin panel opened by a stray close (10), "Horror: Full" default (16).
- Selection ring: thick white 4 px focus box appears on random elements (14, 15, 25, 33); leaked gamepad focus.

Conclusion: not "bad taste", but **4 surface systems x 6 button colours x 3 type families x 7 radii**. Consistency has to be enforced by one component set that every screen must call.

## 2. Design system ("Brain Kit")

Principle: ONE structure and ONE type scale for every tier. Tiers change only **tokens** (accent, radius, stroke, motion, fx), never layout, sizes or component anatomy.

**Palette (base, every tier)**
- Surface `#1B2030`, Card `#2A3147`, Raised `#343C58`
- Text `#F5F6FA`, Muted `#A8B0C8` (min 4.5:1 on surface)
- Primary `#34C46B` (green: go, buy, start, confirm; the ONLY green)
- Secondary `#3E4A6B` with 1.5 px `#FFFFFF` at 15 percent
- Danger `#F0485A` (close, delete, leave)
- Info/Link `#4DA8FF`, Warning/Money `#FFC83D`
- Tier accent (used for header underline, progress bars, selected tab, focus ring): Lose-low `#FF4FA3`, Lose-mid `#FF8A3D`, Average `#9A6BFF`, Smart `#4DA8FF`, Genius `#FFC83D`.
- Retire cream/storybook pop-ups and the red ribbon header, gold-on-brown buttons, tan answer buttons, neon and glass.

**Fonts (2)**: Titles and numbers `Enum.Font.FredokaOne`; everything else `Enum.Font.GothamMedium` (bold labels use `GothamBold`). Emoji allowed as ONE leading icon per header/button, never inside body sentences.

**Sizes (phone-first, never below 14)**
- Title 24, Section 18, Body 16, Caption 14, Button 18, HUD number 28. Min touch 48 px. Genius tier: same sizes, tighter tracking only.

**Buttons (height 48, radius 12)**: Primary = green fill, dark text `#0E1A12`. Secondary = Card fill, white text, 1.5 px stroke. Danger = red fill, white text. All: pressed scale 0.96, no gradient, no white outline. Disabled = 40 percent opacity PLUS a lock icon and the reason as text (fixes the Library look).

**Pop-up anatomy** (one function, `UI.modal`): 
1. Header, 56 px, Surface fill, left Title (24, Fredoka) with one emoji icon, right Close (48 px red circle, X glyph, same position everywhere), 3 px tier-accent underline.
2. Body, ScrollingFrame, 16 px padding, 12 px gap, bottom fade gradient 24 px so cropping reads as "scroll".
3. Footer, 64 px sticky, only when there are actions; max one Primary plus one Secondary. Never place the primary mid-scroll.
Width 560 max (phone landscape: 70 percent), radius 16, border 2 px white 12 percent, backdrop dim 0.5. The phone shell is a frame inside the same system (same header, same buttons), only the bezel differs.

**Spacing scale**: 4 / 8 / 12 / 16 / 24 (nothing else). **Radius**: 12 controls, 16 cards and pop-ups, 999 pills/chips (phone bezel 34 is the one exception). **Icons**: emoji at 24 px in a 40 px rounded tile (Card fill) for apps and rows; no PNG/emoji mixing in one row.

**Toasts**: Raised fill, 4 px left accent bar (green/amber/red), 16 pt text, docked top-centre below the objective banner, max 2 visible, queue the rest; never over a modal (show inside the modal footer or delay).

**Tier variation (inside the consistency rules)**

| Tier | Token changes | Allowed extras |
|---|---|---|
| Dumb (Lose-low) | accent pink/orange, radius 20, stroke 3 px accent, titles +2 pt, button press bounce 1.1, ad strips in a reserved footer slot | scramble labels (never prices/odds/confirm), shake, joke ad pop-ups that use the same modal |
| Average | defaults above | none |
| Smart/Genius | accent blue/gold, radius 10, stroke 1 px, titles -0 pt, no bounce, hairline dividers | extra info row (rates, charts) in the same body slot, subtle fade-in |
Layout, sizes, positions, button colours and anatomy never change. Do not recolour Primary/Danger by tier.

## 3. Implementation plan (UI.lua terms)

1. Tokens: replace `KIT` + per-theme tables with one `UI.Tokens` (palette, type scale, spacing, radius) and `UI.Tier` overrides {accent, radius, strokeW, bounce, fx}; keep `UI.T` as a merged view so old callers still work. Add `UI.S = {4,8,12,16,24}`.
2. Delete `UI.PopStyles`, `UI.popupStyle()`, the storybook/bubbly/neon branches in `UI.modal`, the `FontFace`/serif patching (lines ~786-809), and Settings option for pop-up style. Remove `opts.noSkin/big` skin forks.
3. Rewrite `UI.modal` to the header/body/footer anatomy; return `{frame, body, footer, close}`. Add `UI.modalFooter(modal, primaryText, onPrimary, secondaryText, onSecondary)`. Phone shell reuses header + body.
4. `UI.button(parent, text, onClick, {kind="primary"|"secondary"|"danger"})`: kind sets colours, remove the generic white gradient, remove per-call `BackgroundColor3` overrides (grep the 11 files that call `UI.new("TextButton"` directly: Hud, Minigames, Stations, Tutorial, Effects etc. and move to `UI.button`).
5. `UI.textSize` -> `UI.type.title/body/caption/button` and clamp to 14 minimum; fix 9-12 pt labels in `Hud.lua` (job card), `PhoneOS.lua` (app labels), `Content` rich text.
6. Add `UI.body(modal)` scroll fade and `UI.empty(msg, action)` to stop dead space; make short pop-ups auto-size (`AutomaticSize.Y` with max height).
7. `UI.toast`: new anatomy and queue rules (max 2, dock under the banner, defer while a modal is open).
8. Reapply Settings tabs as a scrolling segmented bar with edge fade; clear `GuiService.SelectedObject` on mouse/touch input to stop stray white focus boxes (pass `SelectionImageObject` to a thin accent ring).
9. Migrate screens in this order: Settings, Store, Quick Play/Library (answer buttons = Secondary, correct = Primary), Jobs/Work/Map/Vs Mode/Badges, minigame shells, then Hud cards and PhoneOS apps, then admin panel.
10. Screenshot regression: re-run the 35-capture set at 784x360 and 420x820, check min text 14, no cropping without a fade, one header style.
11. Content fixes found on the way: remove Skill Gates strings (05, 16), default Horror off per kid-safe rule, guard the close button so it cannot hit the admin panel.
