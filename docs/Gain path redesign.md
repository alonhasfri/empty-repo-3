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

## 4. Random story events (both paths)
- Every few minutes there's a small chance of a short event, drawn from a shuffle bag so a run never repeats one.
- **Gain examples:** a pigeon steals your homework, a surprise inspection at work, a science fair, a power cut (light candles in a minigame), a famous scientist visits, the library flood.
- **Lose examples:** a brainrot trend storm, a fake giveaway, a meme contest, the "touch grass" challenge.
- Each event has a choice with a reward or a cost, and a clear banner (not mid-screen) that you can ignore.
- Branch-specific events appear only for that genius (e.g. a chess challenger in the park).

## Build order
1. The progress path strip, plus removing maths from jobs.
2. The minigame framework, plus 3 minigames (cashier, scientist colours, pipe puzzle).
3. The other 5 job minigames.
4. The random event system, plus 8 events.
5. The Genius Crossroads and the 5 branches, one branch at a time (jobs, minigame, storyline).
