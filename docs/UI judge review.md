# UI judge review (Nov 25)

The user said the UI "feels really bad" but couldn't say why. A fresh reviewer that had never seen the game judged seven screenshots (`docs/screens/ui-judge/`) harshly, against clean popular Roblox games.

## Root causes (worst first)
1. **No design system.** Each screen has its own panels, corners, outlines, gradients and fonts.
2. **Colour as decoration.** Every button is a different saturated colour, so nothing shows what matters.
3. **Backwards visual weight.** The biggest, brightest things (gradients, a second IQ bar, pink panels) aren't the important ones.
4. **Wrong text scale for phones.** Small text sits in huge buttons, and black outlines on small text make it mushy.
5. **Not built for landscape phones.** Buttons are cut off, overlays are off-centre, and tooltips cover the buttons.
6. **Duplicated, scattered information.** IQ shows twice, status lines float, and name tags overlap.
7. **Unfinished details.** Missing glyphs (boxes), emoji icons at random sizes, and tiles that change order.

## The design kit (now in UI.lua as `KIT`)
- **Font:** Gotham (Black for titles, Bold for buttons, Medium for body text).
- **Text sizes:** 28 / 18 / 14 px, nothing smaller.
- **Corners:** 12 px everywhere (circles only for the top-right icon row).
- **Panel:** #1B2030 at about 90%. Buttons are #2A3147.
- **Outline:** 2 px white at 12%. Black text outlines only on big text over the 3D world.
- **Accent:** one per brain look (gold for genius). Green and red only for right/wrong and gain/loss.
- **Spacing:** 8 px unit, 16 px panel padding, 48 px touch targets (56 for HUD icons).

## Done in 1.9 (code only, not tested yet)
- [x] One kit for every look: no gradients, shine, wobble or thick outlines, with the accent kept per look.
- [x] Activity tiles: one neutral dark tile with a thin coloured stripe, plus a fixed 13 px label.
- [x] Counter card: the kit panel with a thin light outline.
- [x] Quick Play answers start neutral (follows from the kit).

## Still to do (ranked by the judge)
- [ ] Remove the bottom IQ bar (IQ is already on the counter card); "All gates passed" becomes a toast.
- [ ] One chip row under the counter for status and career; remove the "Overflow ×999 (…)" joke text.
- [ ] Settings in sections with headers, and a volume slider instead of − / + buttons.
- [ ] Full-screen dim behind every pop-up (never a partial rectangle).
- [ ] Scroll areas: 16 px bottom padding, nothing cut in half.
- [ ] Phone app: labels under every icon, and no clock card in landscape (done in 1.8.7).
- [ ] Tooltips: anchored under their target, max 280 px, never over buttons.
- [ ] NPC bubble: kit panel with the name in the accent colour, a fixed slot, auto-hide after 6 s.
- [ ] Glyph audit: replace emoji-as-icons with one icon set and fix any missing glyphs.
