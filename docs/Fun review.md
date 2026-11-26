# Fun review (Nov 26): why testers quit after ~10 minutes

Two independent reviews (a minute-by-minute new-player walkthrough of both doors, and a game-designer core-loop
review) read the code and config. Both agree: the map is fine, the **first 10 minutes are the problem**.

## Why players quit
1. **The game is silent.** Every `Config.Sounds` / `Config.Music` ID is 0, so `UI.sound` does nothing: no ding, no
   whoosh, no music, no level-up sound.
2. **The Gain start feels like homework.** 16 tutorial steps (9 full-screen text cards, 4 with quizzes), forced 10 s
   reads, only 8 library texts (each repeats 3-6 times), stress for wrong answers. First gate (IQ 100) after 6+ min.
3. **The fun part pays least.** Job minigames (the real skill play) give 0.5 brain points per 40 s shift, a book gives
   2 per 10 s.
4. **Lose = spam one button.** BrainTok swipes (0.25 points, 0.25 s floor) beat every clever Lose activity. No coins
   on the Lose path, no progress bar, first animal (Dog) at 5-10 min, a 7-minute fly-to-worm dead zone.
5. **Big moments come too late.** First life event 600 s (exactly when the tester quit), school bell 240 s,
   Dog 5-10 min, FirstWow is just a toast.
6. **Progress makes the game harder to play** (Lose: lag, scrambling, ads, slower walking early on; Gain: stress freezes).
7. **The number feels dead.** 11-digit counter, only the last digits move; IQ creeps up by ~1.
8. **Best content is hidden** (inventions, genius, homes, adopt, social scenes, horror, weather) inside phone menus
   or behind 20+ minutes. Nothing broadcasts showing-off moments.

## Fixes, best value for effort first
1. **Sounds and music** (free Creator Store audio): reward ding, swipe whoosh, level-up, bonk, ambient music.
2. **Pacing numbers:** job minigame = 2 + bonus/2 points; library 10 s → 4 s, stress off; Gain start IQ 70 → ~85;
   LoseRate up so the Dog comes at ~3 min; Events.FirstAfter 600 → 90-150 and gaps 300-480 s; School bell later (600 s)
   so it doesn't interrupt the first minutes; Quick Play cooldown 20 → 5 with a streak bonus.
3. **Cut the Gain tutorial to ~5 steps;** the rest become one-line tips later.
4. **A progress bar for Lose** ("🐶 Dog: 70%") like the Gain path strip, plus a milestone reward per animal and a
   server-wide toast ("Sam is now a Dog!").
5. **Big first transformation** (POOF + "NEW FORM UNLOCKED" + an animal collection book with ??? slots).
6. **Make the number feel alive:** "+0.6 IQ" / "−1.4%" pops by the counter, short numbers (86.2B).
7. **Skill instead of mashing on Lose:** a "Brainrot Rush" minigame (tap the dumbest clip, combos), swipes worth less.
8. **More content:** 60+ library/theater/Quick Play facts with shuffle bags.
9. **Earlier surprises:** a free golden-brain pickup in town every 60-90 s; stage titles over heads others can see;
   coins + silly cosmetics on the Lose path.
10. **Replay:** Lose leaderboard ("Fastest to Rock"), New Game+ prestige stars; open Genius / Space earlier.

## Proposed first 3 minutes
0-15 s flyover + music, pick a door, loud sting; 15-30 s one obvious action with a sound and a number pop every tap;
30-45 s FirstWow screen moment; 45-60 s goal bar appears + 50-coin gift; 60-120 s first unlock banner (Jobs / big drop);
120-150 s first job minigame or first animal transformation; 150-180 s first life-event invite + next goal shown.
