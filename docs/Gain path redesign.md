# Gain path redesign (user idea, Nov 25)

What the user asked for:
- A simple, clear progress path.
- Real, varied minigames instead of math problems.
- A choice of what kind of genius you become.
- Random story events, so no two runs are the same.

## 1. A clear progress path
One always-visible "path" strip (top left, under the counter): **Job → Shift → Promotion → Next job**.
- It shows the current step and a progress bar ("Shift 2/3 · Promotion at 3 ✅"), with one tap-to-go button that points the guide arrow at the right place.
- Stress has its own small bar. When it's high, the path strip suggests "☕ Take a break" (coffee, nap or pigeons) as the next step.
- **Steps:** pick a job → work shifts (minigames) → get promoted → unlock the next job. At the top of a ladder, pick your genius branch (section 3).
- **Remove from the job loop:** math and trivia questions. They stay only in the optional ⚡ Quick Play.

## 2. Job minigames (different for every job, ~30–60 s, phone-friendly, server-checked score)
| Job | Minigame |
|---|---|
| Cashier | **Scan & bag**: items slide in on a belt; tap to scan, then drag them into the right bag (fragile on top). |
| Doctor | **X-ray spot**: find what's wrong in the X-ray (a swallowed toy, a broken bone) before the timer ends. |
| Teacher | **Grade papers**: swipe left or right on silly answers, like a sorting game. |
| Scientist | **Mix colours**: hit the target colour by pouring red, yellow and blue. |
| Engineer | **Pipe puzzle**: rotate pipe pieces so water reaches the town. |
| Office | **File sorting**: drag files into folders by colour or label, faster each round. |
| Chef | **Order up**: build the burger shown on the ticket, in the right order. |
| Courier | **Hoppr dash**: a short top-down drive picking up and dropping off parcels. |

- Each minigame uses the same small framework: start screen, timer, score, then a pay and XP result.
- The server checks timing and score limits.
- Harder tiers just make it faster or add more items. Never maths.

## 3. Choose your genius (a big branch)
When you reach the top of your first career (or a set IQ), the **Genius Crossroads** event asks which genius you want to be:

| Genius | Jobs it unlocks | Signature minigame | Storyline taste |
|---|---|---|---|
| 🔢 Math genius | Codebreaker, Bank analyst | Number-pattern flow puzzle (no sums) | crack the town vault code |
| ⚛️ Physics genius | Rocket engineer, Inventor | Launch angle & power (Angry-Birds-like) | build the Moon rocket |
| 💻 Coding genius | Game dev, Robot builder | Drag code blocks to move a robot | fix the town's buggy AI |
| 💼 Business genius | Shop owner, CEO | Run a lemonade stand (price, stock, weather) | turn a closed shop into a chain |
| ♟️ Chess genius | Chess coach, Strategist | Mate-in-1 / mate-in-2 puzzles | the Grand Brain Tournament |

- Each branch has its own job ladder, its own short storyline (3–5 chapters, told through conversations and small cutscenes) and a badge at the end.
- Saved as `data.genius = "math" | …` (new field, nil for old saves). You can change branch later at the Crossroads (keeping your cells).

## 4. Big life events (both paths), user update Nov 25: "big things that happen in real life, like a friend's wedding"
These aren't tiny pop-ups. Each is a real life moment and a mini-story (2–5 minutes):
- a short intro cutscene
- a special place or decor set up in town
- 2–3 choices or minigames
- a lasting result (a photo in your phone gallery, a badge, friends, money, stress, a new place)

A run gets a few of them, drawn from a shuffle bag so no two runs are the same. Kid-safe: weddings are a FRIEND's or relative's party; the player never dates or marries.

| Event | What happens | Choices / minigames |
|---|---|---|
| 💒 A friend's wedding | The park turns into a wedding party | Pick a gift (card shop), give a speech (pick funny or kind lines), the dance-floor rhythm minigame, catch the bouquet (a silly physics catch) |
| 🎂 Grandma's 80th birthday | The family house is decorated | Bake the cake (Chef minigame), choose a present, family photo pose |
| 🎓 Graduation day | A ceremony at the school or university | Walk the stage, throw the cap, give your speech; the Lose path skips it to go viral |
| 🏠 Moving house | You pack and move to a new house in another district | Packing Tetris minigame, a moving-truck drive, decorate your new room |
| 👶 A new baby cousin | A visit to the hospital | Help choose a name, rock-the-baby rhythm game, "your first babysitting shift" |
| 🐶 Your pet runs away | Posters around town | Follow clues and smell trails around the map, then a reunion cutscene |
| 🏆 The big school or sports final | The stadium fills up | A penalty-kick or relay minigame; the crowd cheers your name |
| ✈️ Family holiday | A short trip to the beach town (a separate small area) | Sandcastle contest, souvenir shop, sunburn joke |
| 💼 Big job interview in the city | A downtown tower | Dress-up, pick answers, a handshake timing game; can unlock a better job |
| 🌩 City-wide blackout | The whole town goes dark at night | Bring torches and help neighbours (good choices = brain cells); the Lose path gets scared of shadows |
| 🎤 Talent show | A stage in the plaza | Pick an act (magic, comedy, piano rhythm game), and the crowd votes |
| 🏥 A friend breaks their leg | A hospital visit | Bring a get-well gift, sign the cast with a drawing (stickers), cheer them up |

- **Genius branches** add their own big events: a chess world championship, a startup pitch to investors, the rocket launch day, a hackathon, a math olympiad.
- **Lose path** versions are silly twists of the same life moments (you turn up to the wedding in pyjamas, you live-stream the graduation and fall off the stage).
- **Frequency:** the first event after about 10 minutes of play, then one every 15–25 minutes. You get an invite in your phone ("You're invited! 💌") and can accept now or later; nothing is forced mid-task.
- **Saved:** `data.eventsDone` (a list of ids, nil for old saves) and the event's results (gallery photos, badges).

## Build order
1. The progress path strip, plus removing maths from jobs.
2. The minigame framework, plus 3 minigames (cashier, scientist colours, pipe puzzle).
3. The other 5 job minigames.
4. The random event system, plus 8 events.
5. The Genius Crossroads and the 5 branches, one branch at a time (jobs, minigame, storyline).
