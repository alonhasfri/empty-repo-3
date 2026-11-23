# Life Pack (100 Robux) and Phone Shop: plan

## Roblox rules that shape this plan (checked Nov 2026)
- **No dating or romance.** Roblox bans pursuing romantic relationships, flirting, and depicting romantic events such as dates, weddings and honeymoons, along with kissing and hand-holding animations. This applies even with NPCs and even behind a pass. See [Rules of Conduct](https://en.help.roblox.com/hc/en-us/articles/203313410-Roblox-Rules-of-Conduct) and the [Aug 2025 policy update](https://about.roblox.com/newsroom/2025/08/extending-roblox-policy-on-romantic-and-sexual-content). The "relationship" feature is therefore **friends, best friends, family and pets**, never dating.
- **No adult settings.** Bars, clubs, bedrooms and bathrooms as hangouts make an experience 17+ only. The Party Center is a **kids' party hall** (birthday cake, bouncy castle, party games), not a club.
- **Honest money (CLAUDE.md).** The pass shows its price and contents before purchase. The base game can still be finished without it.
- **No real brands.** Phones get original parody names and original logos only.

## Life Pack, a 100 Robux game pass

### Life stages (from baby to grandparent)
| Stage | Age | What you do | Brain |
|---|---|---|---|
| 👶 Baby | 0–2 | Crawl (slow, low camera), rattle, baby-talk preset bubbles, crib nap, first word ("brain!") | Neutral. No path yet; small cell changes from toys |
| 🧸 Kindergarten kid | 3–5 | Kindergarten: finger painting, blocks, nap time, show-and-tell, the playground | Neutral, with a "curious" or "silly" score that hints at a path |
| 🎒 Kid | 6–12 | School (it already exists), recess, the first phone from the Phone Shop | **Choose your path at any age from 8 to 20**: the Crossroads Ceremony at the fountain, Lose or Gain |
| 🛹 Teen | 13–19 | High school, a first part-time job, the Party Center | On your chosen path |
| 💼 Adult | 20–64 | Careers, Hoppr, Brain Bank, a house | Normal game |
| 👴 Grandparent | 65+ | Retirement Home: bingo, knitting, rocking chair, long stories, feeding pigeons | Gain: "wisdom" quizzes. Lose: "where are my glasses?" moments |
| 🌅 Legacy | end | Retire and pick one heirloom, then start a new baby who **inherits a small bonus** | A replay loop (like a rebirth) |

- **Aging:** 1 year is about 2 minutes of play (Config), and you can pause aging in Settings. A birthday pops up each year, with a cake at the Party Center.
- **Non-owners** start as now (pick a door right away), and adults stay adults.

### DLC buildings (other players only see normal houses)
For Life Pack owners, some plain houses turn into new buildings. The change is drawn only for the owner, so other players still see plain houses:
- 🧸 **Kindergarten** (with a playground)
- 👴 **Retirement Home**
- 🎉 **Party Center**, open to both paths:
  - **Lose path:** "act dumb" games (cake face-plant, silly dance-off, balloon head) **lose brain cells**.
  - **Gain path:** **no brain cells**, but it **lowers stress a lot**.
- 🍼 **Daycare** (where baby players spawn) and a 🧸 **Toy Store**.
- A non-owner who walks up to a DLC door sees an honest card: "Life Pack, R$100: grow from baby to grandparent, + 5 new buildings." There's also a **free 2-minute preview tour**.

### "Relationships" (Life Pack only, kid-safe)
- **Friends meter** with NPCs and players: high-fives, sharing snacks, playing tag, all preset actions. Levels go Friend → Good friend → Best friend 🤝.
- **Family:** NPC parents raise you as a baby. As a grandparent, NPC grandkids visit you. Shown as a family tree.
- **Pets:** adopt a dog, cat or goldfish that grows up with you.
- **Mentor and rival:** a smart mentor (Gain) or a silly best buddy (Lose) who reacts to your choices.
- No dating, crushes, weddings or kissing, ever (Roblox rules).

## Phone Shop (free, mainly for the Lose path)
- **Phones** with parody names, from a 📟 "BrickFone 1" up to an "iBrainz 99 Ultra Pro Max Fold" (original logos). The price is always shown before buying.
- **Case maker:**
  - Choose colours, glitter and stickers (rubber duck, rainbow skull, googly eyes, a "67" sticker, sparkle cat…).
  - A **"Brainrot meter"** on the case: the louder, brighter and dumber the stickers, the more cells you lose when you show it off. Gain players can make a calm, minimal case instead.
- **The scam stall:**
  - "Totally Real Phones 👍" outside the shop sells an "iBrainz 99 MEGA" for an insane price. It's actually a calculator with a sticker.
  - Using it loses brain cells every time (notification spam, fake apps).
  - **Gain players** see red flags (a misspelled logo, "no refunds!!!") and can **report the scammer** to the police for brain cells. This teaches kids to spot scams.
- **Cracked screen, low battery and spam notifications** get worse with dumber phones.
- **Gain side:** a "Do Not Disturb" mode and a "phone-free day" badge.

## More free buildings for the Lose side (fixes the empty west half)
- 🫧 Slime Shop (make the slimiest slime)
- 🤸 Trampoline Park (bounce = brain cells fly out)
- 🌀 Fidget Store
- 🌈 Brainrot Café (rainbow mystery drinks)
- 🎭 Prank Shop
- 🎥 Influencer Studio (record dumb videos for "views")
- 🔮 Fortune Teller, with exact odds shown
- 🍔 Drive-thru
- 🕹 Claw Machine Arcade (in-game coins only, with exact odds)

## Build order
1. Phone Shop + case maker + scam stall (free).
2. 2–3 new Lose-side buildings (free), placed in the empty west half.
3. Life Pack: the pass (ID in Config, 0 until the user creates it), life stages and aging, the Crossroads Ceremony.
4. DLC buildings (owner-only appearance), Party Center rules, the preview tour.
5. Friends meter, family and pets.
Each step: text in Content.lua, numbers in Config.lua, tested in Studio (phone size), with a What's new entry.

**The user must create:** a 100-Robux game pass named "Life Pack" on the Roblox website, then give its ID.
