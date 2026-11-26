-- Content: all the text in the game (headlines, questions, jobs, glasses...).
-- Add more entries anytime; the game picks from these lists.

local Content = {}

---------------------------------------------------------------------
-- LOSE PATH: reading popups (skip them fast!)
---------------------------------------------------------------------
Content.ReadingTexts = {
	"Welcome to the shop. Please read these instructions carefully before you continue, because they explain how everything works.",
	"Did you know that reading is good for your brain? Studies show that people who read every day remember more and focus better.",
	"The secret exit code is hidden at the end of this message. Keep reading to find out what it is. It is almost here...",
	"Important update: the shop will be closed for maintenance. We apologize for any inconvenience this may cause to you.",
	"Fun fact: honey never spoils. Archaeologists have found pots of honey in ancient tombs that are thousands of years old.",
	"DON'T READ THIS. Seriously. If you are still reading, you are getting smarter, and that is the opposite of the goal.",
	"Paragraph 1 of 3: You won't believe what happens in paragraph 3. Paragraph 2 is just here to build suspense for paragraph 3.",
	"Please remember to stay hydrated. Water helps your brain work properly, which you probably don't want right now.",
	"Notice: a new update has arrived. Changes include new things, fixed things, and things that were moved to other places.",
	"Tip: if you read every message carefully, you will understand the game better. We recommend reading everything twice.",
}

Content.TermsOfService = [[TERMS OF SERVICE (please read all of it)

1. By playing, you agree that brains are optional.
2. You agree not to read things you are told not to read, unless you are reading this, which you are.
3. Dr. Wrinkles is not responsible for any brain cells lost, found, borrowed or microwaved.
4. Bananas may not be used as legal defense in court. (They will be anyway.)
5. If you have read this far, you are officially the most patient person on this server.
6. Section 6 intentionally left blank.
7. See section 6.
8. Congratulations. Keep this window open for a full minute to receive a reward that is not a brain cell.]]

---------------------------------------------------------------------
-- LOSE PATH: clickbait cards
-- tier 1 = subtle (high brain cells) ... tier 4 = near zero
---------------------------------------------------------------------
Content.Headlines = {
	-- tier 1: subtle, mixed with real-looking news
	{ tier = 1, bait = false, text = "Scientists Report New Findings on Sleep and Memory", article = "A study found that people who slept well remembered word lists better the next day." },
	{ tier = 1, bait = false, text = "Study Suggests Sleep May Affect Memory More Than Expected", article = "Researchers say sleep helps the brain store memories. More research is planned." },
	{ tier = 1, bait = true, text = "Doctors Don't Want You to Know This One Sleep Trick", article = "The trick is: go to sleep. That's it. That's the article." },
	{ tier = 1, bait = false, text = "City Council Approves New Bike Lanes Downtown", article = "The council voted to add 12 km of protected bike lanes next year." },
	{ tier = 1, bait = true, text = "This Common Breakfast Food Could Be Ruining Your Day", article = "It's cereal. Probably. We didn't actually check." },
	{ tier = 1, bait = false, text = "Local Library Extends Weekend Opening Hours", article = "The library will now stay open until 8 PM on Saturdays." },
	-- tier 2: tempting
	{ tier = 2, bait = true, text = "You Won't BELIEVE What This Kid Found in His Backyard 😱", article = "A rock. He found a rock." },
	{ tier = 2, bait = true, text = "Free Robux Glitch (NOT CLICKBAIT) 2026", article = "There is no glitch. Never trust a free Robux headline." },
	{ tier = 2, bait = false, text = "New Study Shows Dogs Can Understand Some Words", article = "Dogs in the study reacted to familiar words even when strangers said them." },
	{ tier = 2, bait = true, text = "He Pressed This Button… What Happened Next Will SHOCK You", article = "Nothing happened. It was a doorbell." },
	{ tier = 2, bait = false, text = "Weather Service Expects Rain This Weekend", article = "Bring an umbrella on Saturday afternoon." },
	{ tier = 2, bait = true, text = "Scientists HATE Him for This One Weird Brain Trick", article = "Scientists do not hate him. They have never heard of him." },
	-- tier 3: obvious
	{ tier = 3, bait = true, text = "🚨🚨 BONKADOO FOUND IN REAL LIFE 🚨🚨", article = "It was a guy in a costume." },
	{ tier = 3, bait = true, text = "CLICK HERE 4 FREE BRAIN", article = "no brain here srry" },
	{ tier = 3, bait = true, text = "TOP 10 REASONS 2 CLICK THIS (NUMBER 7 IS CRAZY)", article = "there r no reasons" },
	{ tier = 3, bait = false, text = "water is wet (real)", article = "yes" },
	-- tier 4: barely words
	{ tier = 4, bait = true, text = "🤯 CLIK", article = "👀" },
	{ tier = 4, bait = true, text = "👀👀👀", article = "🗿" },
	{ tier = 4, bait = true, text = "PRES", article = "🍌" },
}

---------------------------------------------------------------------
-- LOSE PATH: Steal A / Fix A / Make A
---------------------------------------------------------------------
Content.StealWords = {
	"Toaster", "Grandma", "Spoon", "Cloud", "Banana", "Fridge", "Sock", "Volcano", "Pigeon", "Bathtub",
	"Traffic Cone", "Couch", "Moon", "Sandwich", "Lamp", "Duck", "Brain", "Rock", "Microwave", "Hat",
}

-- Tricky options at high brain cells (the dumb one is hidden)
Content.StealTricky = {
	{ steal = "Steal A Brain (Remastered Deluxe Edition)", fix = "Fix A Broken Economy", make = "Make A Sustainable Farm" },
	{ steal = "Steal A Toaster: Ultimate Collector's Pack", fix = "Fix A Leaky Pipe", make = "Make A Community Garden" },
	{ steal = "Steal A Grandma 2: The Return", fix = "Fix A Bicycle Chain", make = "Make A Science Fair Volcano" },
}

---------------------------------------------------------------------
-- LOSE PATH: dumb internet comments (preset words only)
-- dumb = how dumb the word is (more dumb = more cells lost, higher viral chance)
---------------------------------------------------------------------
Content.CommentWords = {
	{ text = "first!!", dumb = 3 },
	{ text = "who's watching in 2009", dumb = 4 },
	{ text = "is this real?", dumb = 2 },
	{ text = "I didn't watch but", dumb = 4 },
	{ text = "I disagree", dumb = 2 },
	{ text = "same", dumb = 3 },
	{ text = "lol", dumb = 1 },
	{ text = "bruh", dumb = 2 },
	{ text = "no cap", dumb = 2 },
	{ text = "fake", dumb = 2 },
	{ text = "bonkadoo", dumb = 4 },
	{ text = "me", dumb = 1 },
	{ text = "🗿", dumb = 3 },
	{ text = "nice video", dumb = 0 },
	{ text = "thanks for sharing", dumb = 0 },
	{ text = "can someone explain", dumb = 1 },
	{ text = "ratio", dumb = 3 },
	{ text = "who asked", dumb = 3 },
}

Content.Posts = {
	{ author = "LostDogHelp", text = "Has anyone seen my dog Biscuit? He's brown and very friendly." },
	{ author = "ScienceDaily_NPC", text = "Our new video explains how volcanoes form. (12 minutes)" },
	{ author = "CookingWithGran", text = "Grandma's famous pancake recipe, step by step!" },
	{ author = "TotallyRealNews", text = "Man claims he saw a sandwich fly. Watch the full video." },
	{ author = "MathIsFun_NPC", text = "Why does 0.999... equal 1? A simple explanation." },
	{ author = "WeatherBot_NPC", text = "Sunny tomorrow with a light breeze." },
}

Content.ReactionYoutuber = "BigReactz (parody NPC)"

---------------------------------------------------------------------
-- GAIN PATH: library passages (read 10 seconds, then answer)
---------------------------------------------------------------------
Content.Library = {
	{ text = "Octopuses have three hearts and blue blood. Two hearts pump blood to the gills, and one pumps it to the rest of the body.", q = "How many hearts does an octopus have?", options = { "One", "Two", "Three", "Eight" }, answer = 3 },
	{ text = "Light from the Sun takes about 8 minutes and 20 seconds to reach Earth, traveling roughly 150 million kilometers.", q = "About how long does sunlight take to reach Earth?", options = { "8 seconds", "8 minutes", "8 hours", "8 days" }, answer = 2 },
	{ text = "Bananas are botanically berries, while strawberries are not, because strawberries form from a flower with many ovaries.", q = "Which of these is botanically a berry?", options = { "Strawberry", "Banana", "Raspberry", "Cherry" }, answer = 2 },
	{ text = "The human brain has about 86 billion neurons. Connections between them matter more for intelligence than the raw number.", q = "About how many neurons does a human brain have?", options = { "86 million", "860 million", "86 billion", "86 trillion" }, answer = 3 },
	{ text = "Water expands when it freezes, which is why ice floats. This keeps lakes from freezing solid from the bottom up.", q = "Why does ice float?", options = { "It is hollow", "Water expands when it freezes", "It is colder", "It contains air bubbles only" }, answer = 2 },
	{ text = "Honeybees communicate the location of flowers with a 'waggle dance'. The angle of the dance shows the direction.", q = "What do bees use to show where flowers are?", options = { "Buzzing", "The waggle dance", "Colors", "Smell only" }, answer = 2 },
	{ text = "Einstein's brain was slightly smaller than average. Scientists think how neurons are connected matters more than size.", q = "Was Einstein's brain bigger than average?", options = { "Much bigger", "Slightly bigger", "Slightly smaller", "Twice as big" }, answer = 3 },
	{ text = "Sound travels about 343 meters per second in air, but more than four times faster in water.", q = "Where does sound travel faster?", options = { "Air", "Water", "Space", "Same everywhere" }, answer = 2 },
}

---------------------------------------------------------------------
-- GAIN PATH: Jack B Movies fun facts (parody channel)
---------------------------------------------------------------------
Content.Theater = {
	{ text = "Fun fact: a group of flamingos is called a 'flamboyance'!", q = "What is a group of flamingos called?", options = { "A flock", "A flamboyance", "A pinkening", "A parade" }, answer = 2 },
	{ text = "Fun fact: wombat poop is cube-shaped!", q = "What shape is wombat poop?", options = { "Round", "Cube", "Star", "Triangle" }, answer = 2 },
	{ text = "Fun fact: the Eiffel Tower can grow about 15 cm taller in summer because metal expands in heat!", q = "Why does the Eiffel Tower grow in summer?", options = { "It's repainted", "Metal expands in heat", "Wind pushes it", "It doesn't" }, answer = 2 },
	{ text = "Fun fact: a day on Venus is longer than a year on Venus!", q = "On Venus, which is longer?", options = { "A year", "A day", "They're equal", "Neither exists" }, answer = 2 },
	{ text = "Fun fact: J is the only letter that doesn't appear on the periodic table!", q = "Which letter is missing from the periodic table?", options = { "Q", "J", "X", "Z" }, answer = 2 },
	{ text = "Fun fact: sharks existed before trees!", q = "What came first?", options = { "Trees", "Sharks", "Dinosaurs", "Grass" }, answer = 2 },
}

---------------------------------------------------------------------
-- GAIN PATH: Skill Gate questions (tier 1 easy ... tier 4 hard)
---------------------------------------------------------------------
-- 1.8.9: FUN-FACT GATES (user: "Skill Gates must be VERY easy, basically fun facts").
-- Read the fact, then answer an easy question about it. The answer is always in the fact.
-- tier 1 = body and brain, 2 = space and coding, 3 = animals and inventions, 4 = myths and wonders
Content.GateFacts = {
	{ tier = 1, icon = "🧠", fact = "Your brain uses about 20% of your body's energy, even though it's small!", q = "How much of your energy does your brain use?", options = { "About 20%", "Almost none" }, answer = 1 },
	{ tier = 1, icon = "💤", fact = "When you sleep, your brain sorts out what you learned that day.", q = "What does your brain do while you sleep?", options = { "Sorts what you learned", "Turns off completely" }, answer = 1 },
	{ tier = 1, icon = "🦴", fact = "Babies have about 300 bones, but grown-ups have 206, because some bones join together.", q = "Who has MORE bones?", options = { "Babies", "Grown-ups" }, answer = 1 },
	{ tier = 1, icon = "👃", fact = "Your nose can remember about 50,000 different smells!", q = "How many smells can your nose remember?", options = { "About 50,000", "Only 3" }, answer = 1 },
	{ tier = 1, icon = "❤️", fact = "Your heart beats about 100,000 times every day.", q = "How often does your heart beat in a day?", options = { "About 100,000 times", "Once" }, answer = 1 },
	{ tier = 1, icon = "😁", fact = "Tooth enamel is the hardest thing in your whole body.", q = "What is the hardest thing in your body?", options = { "Tooth enamel", "Your hair", "Your ears" }, answer = 1 },
	{ tier = 1, icon = "👀", fact = "You blink around 15 to 20 times every minute to keep your eyes wet.", q = "Why do you blink?", options = { "To keep your eyes wet", "To say hello" }, answer = 1 },
	{ tier = 1, icon = "🧠", fact = "Learning something new makes new connections between your brain cells.", q = "What happens when you learn something new?", options = { "New brain connections", "Your brain shrinks" }, answer = 1 },
	{ tier = 1, icon = "💧", fact = "Drinking water helps your brain think more clearly.", q = "What helps your brain think clearly?", options = { "Drinking water", "Eating sand" }, answer = 1 },
	{ tier = 1, icon = "🤧", fact = "A sneeze can shoot out of your nose faster than a car on a city street!", q = "How fast can a sneeze be?", options = { "Faster than a city car", "Slower than a snail" }, answer = 1 },

	{ tier = 2, icon = "🌙", fact = "The Moon has no wind, so astronauts' footprints can stay there for millions of years.", q = "Why do footprints stay on the Moon?", options = { "There's no wind", "Robots guard them" }, answer = 1 },
	{ tier = 2, icon = "☀️", fact = "The Sun is a star, and it's so big that about a million Earths could fit inside it.", q = "What is the Sun?", options = { "A star", "A planet", "A big lamp" }, answer = 1 },
	{ tier = 2, icon = "🪐", fact = "Saturn is so light for its size that it could float in a giant bathtub!", q = "What could Saturn do in a giant bathtub?", options = { "Float", "Sink like a rock" }, answer = 1 },
	{ tier = 2, icon = "🔴", fact = "Mars looks red because its ground is full of rusty dust.", q = "Why does Mars look red?", options = { "Rusty dust", "It's embarrassed" }, answer = 1 },
	{ tier = 2, icon = "🌍", fact = "Earth is the only planet we know of with liquid water oceans on its surface.", q = "What does Earth have on its surface?", options = { "Liquid water oceans", "Chocolate rivers" }, answer = 1 },
	{ tier = 2, icon = "💻", fact = "Computers only understand two numbers: 0 and 1. Everything is built from them!", q = "Which two numbers do computers use?", options = { "0 and 1", "7 and 9" }, answer = 1 },
	{ tier = 2, icon = "🐛", fact = "A mistake in code is called a 'bug'. Once, a real moth got stuck in an old computer!", q = "What is a mistake in code called?", options = { "A bug", "A sandwich" }, answer = 1 },
	{ tier = 2, icon = "🔁", fact = "A 'loop' in code repeats the same steps again and again, so you don't have to write them many times.", q = "What does a loop do?", options = { "Repeats steps", "Deletes the game" }, answer = 1 },
	{ tier = 2, icon = "🛰", fact = "Satellites fly around Earth and help phones find where you are on a map.", q = "What helps your phone's map find you?", options = { "Satellites", "Pigeons" }, answer = 1 },
	{ tier = 2, icon = "🚀", fact = "Rockets push hot gas down so they can go up, like a balloon letting air out.", q = "How do rockets go up?", options = { "They push gas down", "They flap wings" }, answer = 1 },

	{ tier = 3, icon = "🐙", fact = "An octopus has three hearts and blue blood!", q = "How many hearts does an octopus have?", options = { "Three", "One" }, answer = 1 },
	{ tier = 3, icon = "🐘", fact = "Elephants can recognise themselves in a mirror, which is a sign of a clever brain.", q = "What can elephants recognise in a mirror?", options = { "Themselves", "Nothing at all" }, answer = 1 },
	{ tier = 3, icon = "🐝", fact = "Bees dance to tell other bees where to find flowers.", q = "How do bees share where flowers are?", options = { "They dance", "They send emails" }, answer = 1 },
	{ tier = 3, icon = "🦒", fact = "A giraffe's tongue is so long it can clean its own ears!", q = "What can a giraffe clean with its tongue?", options = { "Its ears", "The car" }, answer = 1 },
	{ tier = 3, icon = "🐧", fact = "Penguins can't fly in the air, but they 'fly' through water by swimming super fast.", q = "Where do penguins 'fly'?", options = { "Through water", "Over mountains" }, answer = 1 },
	{ tier = 3, icon = "💡", fact = "Light bulbs were improved by many inventors who kept trying after lots of failures.", q = "What did the light bulb inventors do after failing?", options = { "Kept trying", "Gave up forever" }, answer = 1 },
	{ tier = 3, icon = "🖨", fact = "The printing press let people copy books quickly, so many more people could read.", q = "What did the printing press help copy?", options = { "Books", "Cats" }, answer = 1 },
	{ tier = 3, icon = "🚲", fact = "Bicycles are one of the most energy-saving ways for a person to travel.", q = "What is a very energy-saving way to travel?", options = { "A bicycle", "A rocket to the shop" }, answer = 1 },
	{ tier = 3, icon = "🧲", fact = "A compass works because its needle is a magnet that points north.", q = "Why does a compass point north?", options = { "Its needle is a magnet", "It's scared of the south" }, answer = 1 },
	{ tier = 3, icon = "📞", fact = "The first phones had no screens at all. You could only talk!", q = "What did the first phones NOT have?", options = { "Screens", "A way to talk" }, answer = 1 },

	{ tier = 4, icon = "🐠", fact = "Myth: goldfish remember only 3 seconds. Truth: they can remember things for months!", q = "How long can goldfish really remember?", options = { "Months", "3 seconds" }, answer = 1 },
	{ tier = 4, icon = "⚡", fact = "Myth: lightning never strikes the same place twice. Truth: tall towers get hit many times a year!", q = "Can lightning strike the same place twice?", options = { "Yes", "Never" }, answer = 1 },
	{ tier = 4, icon = "🦇", fact = "Myth: bats are blind. Truth: bats can see, and many also use echoes to find their way.", q = "Are bats really blind?", options = { "No, they can see", "Yes, totally blind" }, answer = 1 },
	{ tier = 4, icon = "🧠", fact = "Myth: we only use 10% of our brain. Truth: we use all of it, just different parts for different jobs.", q = "How much of your brain do you use?", options = { "All of it", "Only 10%" }, answer = 1 },
	{ tier = 4, icon = "🐂", fact = "Myth: red makes bulls angry. Truth: bulls can't see red well; it's the waving cape that gets their attention.", q = "What gets a bull's attention?", options = { "The waving cape", "The colour red" }, answer = 1 },
	{ tier = 4, icon = "🌊", fact = "More than half of all the oxygen we breathe comes from tiny plants in the ocean.", q = "Where does much of our oxygen come from?", options = { "Tiny ocean plants", "Video games" }, answer = 1 },
	{ tier = 4, icon = "🏔", fact = "Mount Everest grows a tiny bit taller every year as the ground pushes it up.", q = "What happens to Mount Everest each year?", options = { "It grows a tiny bit", "It melts away" }, answer = 1 },
	{ tier = 4, icon = "🍯", fact = "Honey never goes bad. People have found honey thousands of years old that was still fine!", q = "What is special about honey?", options = { "It never goes bad", "It turns into juice" }, answer = 1 },
	{ tier = 4, icon = "🌈", fact = "A rainbow happens when sunlight shines through raindrops and splits into colours.", q = "What makes a rainbow?", options = { "Sunlight through raindrops", "Paint in the sky" }, answer = 1 },
	{ tier = 4, icon = "🐌", fact = "Some snails can sleep for up to three years when the weather is too dry!", q = "How long can some snails sleep?", options = { "Up to three years", "One second" }, answer = 1 },
}

Content.GateQuestions = {
	-- tier 1: math and facts
	{ tier = 1, q = "What is 12 × 12?", options = { "124", "144", "132", "122" }, answer = 2 },
	{ tier = 1, q = "Which planet is closest to the Sun?", options = { "Venus", "Mars", "Mercury", "Earth" }, answer = 3 },
	{ tier = 1, q = "What is 15% of 200?", options = { "15", "20", "30", "35" }, answer = 3 },
	{ tier = 1, q = "How many legs does a spider have?", options = { "6", "8", "10", "12" }, answer = 2 },
	{ tier = 1, q = "What is 7 + 8 × 2?", options = { "30", "23", "22", "17" }, answer = 2 },
	{ tier = 1, q = "Which is a mammal?", options = { "Shark", "Dolphin", "Salmon", "Octopus" }, answer = 2 },
	-- tier 2: coding (Luau) and logic
	{ tier = 2, q = "Luau: what does print(2 ^ 3) print?", options = { "6", "8", "9", "5" }, answer = 2 },
	{ tier = 2, q = "Luau: local t = {5, 10, 15}  print(#t)", options = { "3", "15", "30", "1" }, answer = 1 },
	{ tier = 2, q = "Luau: print(\"brain\" .. 2)", options = { "brain2", "brain 2", "error", "2brain" }, answer = 1 },
	{ tier = 2, q = "Luau: for i = 1, 3 do x = i end -- what is x after?", options = { "1", "2", "3", "4" }, answer = 3 },
	{ tier = 2, q = "Fallacy: 'Everyone plays this game, so it must be good.' Which fallacy?", options = { "Strawman", "Bandwagon", "Slippery slope", "Circular reasoning" }, answer = 2 },
	{ tier = 2, q = "Myth check: 'We only use 10% of our brain.' Is it true?", options = { "True", "False" }, answer = 2 },
	-- tier 3: harder coding, math, logic
	{ tier = 3, q = "Python: print(len(\"hello\"[1:4]))", options = { "3", "4", "5", "2" }, answer = 1 },
	{ tier = 3, q = "JavaScript: console.log(typeof [])", options = { "array", "object", "list", "undefined" }, answer = 2 },
	{ tier = 3, q = "Solve for x: 3x + 7 = 22", options = { "3", "5", "7", "15" }, answer = 2 },
	{ tier = 3, q = "A coin is flipped twice. Chance of two heads?", options = { "1/2", "1/3", "1/4", "1/8" }, answer = 3 },
	{ tier = 3, q = "Fallacy: 'If we allow homework on Fridays, soon there'll be homework every second of life.'", options = { "Slippery slope", "Ad hominem", "Bandwagon", "False dilemma" }, answer = 1 },
	{ tier = 3, q = "Myth check: 'Goldfish have a 3-second memory.'", options = { "True", "False" }, answer = 2 },
	-- tier 4: genius
	{ tier = 4, q = "C: int x = 7 / 2; printf(\"%d\", x);", options = { "3.5", "3", "4", "error" }, answer = 2 },
	{ tier = 4, q = "SQL: which clause filters rows after GROUP BY?", options = { "WHERE", "HAVING", "ORDER BY", "LIMIT" }, answer = 2 },
	{ tier = 4, q = "Derivative of x³?", options = { "3x²", "x²", "3x", "x⁴/4" }, answer = 1 },
	{ tier = 4, q = "Time complexity of binary search?", options = { "O(n)", "O(log n)", "O(n²)", "O(1)" }, answer = 2 },
	{ tier = 4, q = "Fermi: about how many seconds are in a year?", options = { "≈ 3 million", "≈ 30 million", "≈ 300 million", "≈ 3 billion" }, answer = 2 },
	{ tier = 4, q = "Myth check: 'The Great Wall of China is easily visible from space.'", options = { "True", "False" }, answer = 2 },
}

---------------------------------------------------------------------
-- GAIN PATH: glasses (flashy names = LOW brain)
---------------------------------------------------------------------
Content.Glasses = {
	{ minIQ = -999, name = "Galaxy Glasses", desc = "✨🔥 MAKES YOU 1000x SMARTER 🔥✨", boost = 1.02, color = Color3.fromRGB(170, 60, 255) },
	{ minIQ = 85, name = "GODLY Shades", desc = "🔥 LITERALLY GODLY 🔥 (not really)", boost = 1.04, color = Color3.fromRGB(255, 215, 0) },
	{ minIQ = 92, name = "Gamer Glasses", desc = "RGB lenses. +5 FPS in real life.", boost = 1.06, color = Color3.fromRGB(0, 255, 180) },
	{ minIQ = 100, name = "Reading Glasses", desc = "Simple glasses for reading.", boost = 1.08, color = Color3.fromRGB(60, 40, 30) },
	{ minIQ = 110, name = "Wire-Frame Glasses", desc = "Thin metal frames. Practical.", boost = 1.1, color = Color3.fromRGB(180, 180, 190) },
	{ minIQ = 120, name = "Jeweler's Loupe", desc = "10x magnification for fine detail.", boost = 1.12, color = Color3.fromRGB(40, 40, 40) },
	{ minIQ = 135, name = "Lab Spectacles", desc = "Impact-rated polycarbonate, side shields.", boost = 1.14, color = Color3.fromRGB(220, 230, 240) },
	{ minIQ = 145, name = "−2.25 SPH Progressive Lens", desc = "Anti-Reflective Polycarbonate, 1.67 Index.", boost = 1.16, color = Color3.fromRGB(200, 210, 220) },
}

---------------------------------------------------------------------
-- GAIN PATH: jobs (based on IQ)
---------------------------------------------------------------------
-- Jobs are done at real places in town ("place" = workplace key in WorldService).
-- You can take any job your IQ reaches.
Content.Jobs = {
	{ id = "janitor", name = "Janitor", place = "school", placeName = "the School", minIQ = -999, coinsPerMinute = 2, task = "janitor", comebackOnly = true },
	{ id = "sweeper", name = "Street Sweeper", place = "street", placeName = "Main Street", minIQ = -999, coinsPerMinute = 3, task = "janitor", comebackOnly = true },
	{ id = "cashier", name = "Cashier", place = "supermarket", placeName = "the Supermarket", minIQ = 75, coinsPerMinute = 4, task = "cashier" },
	{ id = "office", name = "Office Worker", place = "office", placeName = "the Office Tower", minIQ = 90, coinsPerMinute = 6, task = "office" },
	{ id = "teacher", name = "Teacher", place = "school", placeName = "the School", minIQ = 105, coinsPerMinute = 9, task = "teacher" },
	{ id = "professor", name = "Professor", place = "university", placeName = "the University", minIQ = 115, coinsPerMinute = 12, task = "teacher" },
	{ id = "doctor", name = "Doctor", place = "hospital", placeName = "the Hospital", minIQ = 120, coinsPerMinute = 14, task = "doctor" },
	{ id = "lawyer", name = "Lawyer", place = "courthouse", placeName = "the Courthouse", minIQ = 125, coinsPerMinute = 15, task = "lawyer" },
	{ id = "scientist", name = "Scientist", place = "lab", placeName = "the Science Lab", minIQ = 135, coinsPerMinute = 20, task = "scientist" },
	-- 1.9 Gain path redesign: new jobs with their own minigames
	{ id = "courier", name = "Courier", place = "street", placeName = "Main Street", minIQ = 80, coinsPerMinute = 5, task = "courier" },
	{ id = "chef", name = "Chef", place = "cafe", placeName = "Beethoven's Café", minIQ = 95, coinsPerMinute = 8, task = "chef" },
	{ id = "engineer", name = "Engineer", place = "office", placeName = "the Office Tower", minIQ = 118, coinsPerMinute = 13, task = "engineer" },
	-- 1.9.1 restaurants: works at ANY restaurant (Pizza Palace, Burger Barn, Sushi Spot, Taco Town)
	{ id = "server", name = "Restaurant Worker", place = "restaurant", placeName = "a restaurant", minIQ = 85, coinsPerMinute = 6, task = "server" },
}

-- 1.6: ANIMAL FORMS. When your brain shrinks enough you physically become the animal.
Content.Animals = {
	Transform = "You are now: %s %s",
	Forms = {
		dog = { sub = "\"bro is a dog now 💀\"", tip = "🐶 Power: BARK (button bottom-right). Pigeons fly away, people jump." },
		fly = { sub = "\"bro is a fruit fly now 💀\"", tip = "🦟 Power: BUZZ UP (button bottom-right) to fly over things." },
		bee = { sub = "\"bro is a bee now 💀\"", tip = "🐝 Power: BUZZ UP (button bottom-right) to fly over things." },
		mouse = { sub = "\"bro is a mouse now 💀\"", tip = "🐭 You're tiny. Squeak." },
		worm = { sub = "\"bro is a worm now 💀\"", tip = "🐛 Worms can't jump. Power: DIG a tunnel to another building." },
		dead = { sub = "You are a rock. Rocks don't do much.", tip = "🗿 Rocks can't move. You won the Lose path!" },
	},
	Powers = { bark = "🐶 Bark", buzz = "🦟 Buzz up", dig = "🐛 Dig" },
	Woof = "🐶 WOOF!",
	BarkedAt = "🐶 A dog barked at you! (it's %s)",
	Dug = "🐛 You dug a tunnel to %s!",
	NoSit = "🐾 Animals can't sit on chairs.",
	Wait = "⏳ Your power needs a moment.",
}

-- 1.6: SCHOOL for the Lose path (the bell, the truant officer, class)
Content.School = {
	Bell = "🔔 SCHOOL BELL! Get to the 🏫 School in %d seconds or the truant officer comes for you.",
	GoObjective = "🏫 Go to school! (%ds)",
	InClass = "✅ You made it to class. Now act dumb: sleep, throw paper, fail the quiz.",
	ClassObjective = "😴 In class. Act dumb: sleep, throw paper, take the pop quiz.",
	ClassOver = "🔔 Class is over. Freedom!",
	Officer = "👮 TRUANT OFFICER",
	Chase = "👮 The truant officer is coming! Run (or just go to school)!",
	ChaseObjective = "👮 Run! (or go to school)",
	Caught = "👮 CAUGHT! The officer walks you to class. Embarrassment +%d",
	CaughtMoment = "Got walked to class by the truant officer",
	Escaped = "😮‍💨 You escaped the truant officer. Legend.",
	NoAnimals = "🚫 No animals in school. You're officially too dumb for school now.",
}
-- 1.6: careers. Every job is a ladder: you start at the bottom and get promoted by working.
Content.Careers = {
	Ladders = {
		cashier = { "Bagger", "Cashier", "Shift Lead", "Store Manager" },
		office = { "Intern", "Office Worker", "Manager", "CEO" },
		teacher = { "Teacher's Assistant", "Substitute Teacher", "Teacher", "Head Teacher" },
		professor = { "Tutor", "Lecturer", "Professor", "Dean" },
		doctor = { "Hospital Volunteer", "Nurse", "Doctor", "Chief of Medicine" },
		lawyer = { "Court Clerk", "Paralegal", "Lawyer", "Judge" },
		scientist = { "Lab Assistant", "Researcher", "Scientist", "Lead Scientist" },
		janitor = { "Janitor", "Head Janitor", "Facilities Boss", "Janitor Legend" },
		sweeper = { "Street Sweeper", "Senior Sweeper", "Road Boss", "Street Legend" },
		courier = { "Bike Courier", "Courier", "Route Boss", "Delivery Legend" }, -- 1.9
		chef = { "Dishwasher", "Line Cook", "Chef", "Head Chef" },
		engineer = { "Apprentice", "Engineer", "Senior Engineer", "Chief Engineer" },
		server = { "Dishwasher", "Server", "Head Waiter", "Restaurant Owner" }, -- 1.9.1
	},
	Taken = "💼 You're now a %s! Go to %s and clock in (📱 Shifts) to get paid. 🚕",
	EarnedWait = "📈 You've earned a promotion! Reach IQ %d to get it.",
	Promoted = "📈 PROMOTED!",
	PromotedSub = "New uniform unlocked. Pay +%d%%.",
	Boss = "💬 Your boss: \"Congrats on becoming %s! 🎉\"",
	BackToWork = "Back to work",
	TaskDone = "✅ Task done! +%d coins",
	TaskFail = "❌ Your boss sighs.",
	ReportTitle = "📋 Shift report card",
	ReportRows = { "Job", "Accuracy", "Speed", "Coworker vibes" },
	ReportProgress = "Promotion progress: <b>%s XP</b>",
	Max = "MAX",
	Accuracy = { [0] = "F", [1] = "C", [2] = "B", [3] = "A" }, -- tasks right in the last shift
	Speed = { "A", "B", "B+", "A−" },
	Vibes = { "A", "A−", "B+", "B" },
	Ladder = "Your career: %s",
	Now = "Now: <b>%s</b>  •  XP %d",
	Next = "  •  next promotion at %d XP and IQ %d",
	Top = "  •  top of the ladder!",
	Pick = "<b>Careers</b>: you start at the bottom and get promoted by working. Pay goes up with every promotion.",
	JobButton = "%s → … → %s  •  💰 %d/min on shift  •  📍 %s%s",
	Yours = "  ✅ YOURS",
	Locked = "  🔒 IQ %d+",
}

Content.Diagnoses = {
	{ symptoms = "Sneezing, itchy eyes, only in spring.", options = { "Allergies", "Broken leg", "Sunburn", "Hiccups" }, answer = 1 },
	{ symptoms = "Arm hurts after falling off a skateboard; it's swollen and bent.", options = { "A cold", "Possible fracture", "Allergies", "Too much coffee" }, answer = 2 },
	{ symptoms = "Red, painful skin after a whole day at the beach.", options = { "Sunburn", "Flu", "Food poisoning", "Fracture" }, answer = 1 },
	{ symptoms = "Fever, sore throat, tired, many classmates have it too.", options = { "Broken arm", "Flu or a cold", "Sunburn", "Allergic to homework" }, answer = 2 },
}

Content.LabExperiments = {
	{ q = "You mix baking soda and vinegar. What gas makes the bubbles?", options = { "Oxygen", "Carbon dioxide", "Helium", "Hydrogen" }, answer = 2 },
	{ q = "Which is the control in an experiment?", options = { "The group you change", "The group you don't change", "The result", "The hypothesis" }, answer = 2 },
	{ q = "Water boils at 100°C at sea level. On a high mountain it boils at…", options = { "A higher temperature", "A lower temperature", "Exactly 100°C", "It can't boil" }, answer = 2 },
	{ q = "What does DNA stand for?", options = { "Deoxyribonucleic acid", "Dynamic nerve atom", "Dual nucleus array", "Dense neutron acid" }, answer = 1 },
}

---------------------------------------------------------------------
-- SECRET INVENTIONS (unlocked in the Eureka cutscene by working jobs)
---------------------------------------------------------------------
Content.Inventions = {
	{ key = "duck", icon = "🦆", name = "Rubber Duck 3000", desc = "Explain your problem to it. Gives +1 Skill Gate hint (max 3).", cooldown = 120 },
	{ key = "coffee", icon = "☕", name = "Infinite Coffee Machine", desc = "Erdős mode: instantly lowers stress a lot.", cooldown = 120 },
	{ key = "pigeons", icon = "🐦", name = "Pigeon Launcher", desc = "Launches a flock of Tesla's pigeons. Pointless. Beautiful.", cooldown = 30 },
	{ key = "rain", icon = "🧠", name = "Brain Rain Machine", desc = "Makes it rain brains around you.", cooldown = 180 },
	{ key = "boots", icon = "🥾", name = "Anti-Gravity Boots", desc = "Low gravity for you for 30 seconds.", cooldown = 60 },
	{ key = "remote", icon = "📡", name = "Teleport Remote", desc = "Teleport to any place in town, instantly.", cooldown = 20 },
	{ key = "goggles", icon = "🥽", name = "Focus Goggles", desc = "Your next 3 library or cinema answers give 1.5× brain cells.", cooldown = 300 },
	{ key = "rewind", icon = "⏪", name = "Pocket Time Machine", desc = "Rewinds you to where you were 5 seconds ago.", cooldown = 45 },
	{ key = "robot", icon = "🤖", name = "Robot Helper", desc = "Does a job task for you (+coins).", cooldown = 180 },
}

---------------------------------------------------------------------
-- LOSE PATH: short videos for the scroller (animated scenes)
---------------------------------------------------------------------
Content.Videos = {
	{ key = "cat", title = "cat vs table (gone wrong) 😭", creator = "@catclips", likes = "1.2M" },
	{ key = "noodles", title = "guy eats 40 noodles in 1 bite", creator = "@noodlelord", likes = "880K" },
	{ key = "dance", title = "dance #4,812 (everyone is doing it)", creator = "@trendzz", likes = "3.4M" },
	{ key = "wall", title = "man vs wall (wall wins)", creator = "@wallfan", likes = "560K" },
	{ key = "duck", title = "duck in a hat for 10 hours", creator = "@hatduck", likes = "2.1M" },
	{ key = "waitforit", title = "WAIT FOR IT… 😱", creator = "@waitforit", likes = "4.0M" },
	{ key = "rocket", title = "my rocket (it did not go up)", creator = "@spacekid", likes = "720K" },
}

-- 1.9 BrainTalks: the smart scroll for Gain players. Spot the smart talks, skip the brainrot.
Content.BrainTalks = {
	Title = "🎓 BrainTalks",
	Intro = "Skip the brainrot ⏭, watch the smart talks 👀. Smart talks calm you down fast and build a 🔥 focus streak. Watching brainrot costs a little brain power (you get one warning first).",
	Skip = "⏭ Skip",
	Watch = "👀 Watch",
	Watching = "Watching… %d",
	Streak = "🔥 Focus streak: %d   (best %d)",
	Loading = "Loading…",
	GainOnly = "BrainTalks is for the Gain path. (Lose players have BrainTok.)",
	NoAnimals = "🐾 Animals can't follow a talk. Paws are not for scrolling.",
	Off = "BrainTalks is turned off right now.",
	Stale = "That clip already scrolled away.",
	TooFast = "Watch it a bit longer first!",
	Missed = "😅 That was a smart talk! Focus streak reset.",
	Dodged = "⏭ Brainrot dodged! Streak +1",
	Learned = "🧠 You learned something! Stress down, brain cells up.",
	Warning = "⚠️ That was brainrot! This time is free. Next time it costs a little brain power and adds stress.",
	Rotted = "🫠 Brainrot watched. A little brain power lost, stress up. Streak reset.",
	Smart = {
		{ icon = "🐙", title = "Why octopuses have nine brains (kind of)", creator = "Dr. Inkwell" },
		{ icon = "🌋", title = "How volcanoes build new islands", creator = "Prof. Magma" },
		{ icon = "🐝", title = "How bees vote on a new home", creator = "Hive Mind Talks" },
		{ icon = "🌙", title = "Why we always see the same side of the Moon", creator = "Albert Zweistein" },
		{ icon = "🧊", title = "Why ice floats (and why fish are glad)", creator = "Cool Science" },
		{ icon = "🦴", title = "Your skeleton replaces itself every 10 years", creator = "Dr. Bones" },
		{ icon = "🌈", title = "Where rainbows really come from", creator = "Light Lab" },
		{ icon = "🧮", title = "The trick to multiply by 11 in your head", creator = "Math Minute" },
		{ icon = "🐋", title = "How whales sing across whole oceans", creator = "Deep Blue Talks" },
		{ icon = "🌳", title = "Trees share food through underground fungi", creator = "Forest Talks" },
		{ icon = "⚡", title = "How lightning is hotter than the Sun's surface", creator = "Storm Science" },
		{ icon = "🧠", title = "Sleep is when your brain files its memories", creator = "Noble Prize Club" },
		{ icon = "🐜", title = "Ants build bridges out of themselves", creator = "Tiny Engineers" },
		{ icon = "🪐", title = "A day on Venus is longer than its year", creator = "Space Facts" },
		{ icon = "🦎", title = "How geckos walk on ceilings", creator = "Sticky Science" },
		{ icon = "📖", title = "Why reading before bed helps you remember", creator = "Library Live" },
	},
	Rot = {
		{ icon = "💀", title = "skibidi sandwich part 47 💀💀", creator = "@rotlord" },
		{ icon = "🤑", title = "FREE BRAIN CELLS GLITCH (not clickbait) (clickbait)", creator = "@totallyreal" },
		{ icon = "🗿", title = "staring at a wall for 3 hours #relatable", creator = "@wallwatcher" },
		{ icon = "🥴", title = "guy says 'bruh' 900 times", creator = "@bruhmoment" },
		{ icon = "📦", title = "unboxing an empty box (EMOTIONAL)", creator = "@boxguy" },
		{ icon = "🐸", title = "frog but it's slowed + reverb 10 hours", creator = "@slowfrog" },
		{ icon = "😱", title = "you WON'T believe #7 (it's a spoon)", creator = "@topten" },
		{ icon = "🍝", title = "eating spaghetti with a fork… WRONG", creator = "@foodfails" },
		{ icon = "🔁", title = "this video loops forever (watch till the end)", creator = "@loopz" },
		{ icon = "🧃", title = "rating every juice box by how loud the straw is", creator = "@sipsip" },
		{ icon = "🪑", title = "chair falls over (part 2)", creator = "@chairfan" },
		{ icon = "🎤", title = "screaming the alphabet but backwards wrong", creator = "@loudkid" },
	},
}

Content.HomeworkMistakes = {
	{ lines = { "2 + 2 = 4", "3 × 3 = 9", "10 − 4 = 5", "8 ÷ 2 = 4" }, wrong = 3 },
	{ lines = { "The Sun is a star", "Spiders have 8 legs", "Water boils at 50°C at sea level", "Earth orbits the Sun" }, wrong = 3 },
	{ lines = { "5 × 6 = 30", "9 + 9 = 19", "7 − 7 = 0", "100 ÷ 10 = 10" }, wrong = 2 },
	{ lines = { "Bats are mammals", "Penguins can fly", "Frogs are amphibians", "Whales breathe air" }, wrong = 2 },
}

Content.Testimony = {
	{ lines = { "I was home all evening.", "I watched TV until 9.", "I was at the park at 8.", "Then I went to bed." }, wrong = 3 },
	{ lines = { "I don't own a bike.", "I rode my bike to work.", "Work starts at 9.", "I was on time." }, wrong = 2 },
}

---------------------------------------------------------------------
-- Cash-grab start (Gain path joke shop)
---------------------------------------------------------------------
Content.CashGrabButtons = {
	{ key = "iq", label = "BUY 1,000,000 IQ!!", result = "You received: 1 dunce cap. Thank you for your purchase of nothing." },
	{ key = "mega", label = "MEGA DEAL 🔥 99% OFF", result = "99% off of nothing is still nothing. 📉" },
	{ key = "vip", label = "ULTRA VIP (FREE)", result = "You are now ULTRA VIP. Benefits: none. Status: ultra." },
}

---------------------------------------------------------------------
-- UPDATE 1.3: MAJOR PROJECTS (scientists invent things for the whole world)
-- qs = research questions based on the real science (simplified)
---------------------------------------------------------------------
Content.Projects = {
	{ key = "teleport", icon = "🌀", name = "Teleportation", unlock = "Teleport pads appear around town (free, instant travel).",
		qs = {
			{ q = "Real 'quantum teleportation' sends…", options = { "Objects", "Information about a quantum state", "People", "Sound" }, answer = 2 },
			{ q = "Two particles linked so measuring one tells you about the other are…", options = { "Magnetized", "Entangled", "Frozen", "Charged" }, answer = 2 },
		} },
	{ key = "space", icon = "🚀", name = "Space Travel", unlock = "A rocket lands in the plaza and the Astronaut job unlocks for EVERYONE at IQ 160.",
		qs = {
			{ q = "A rocket pushes gas down so it goes up. That's Newton's…", options = { "1st law", "2nd law", "3rd law", "Law of gravity" }, answer = 3 },
			{ q = "Why do rockets drop empty fuel tanks (stages)?", options = { "To look cool", "Less weight = less fuel needed", "For fun", "To make noise" }, answer = 2 },
		} },
	{ key = "fusion", icon = "☀️", name = "Fusion Energy", unlock = "Unlimited power: every street light glows brighter.",
		qs = {
			{ q = "Fusion is how the Sun makes energy by…", options = { "Burning coal", "Joining light atoms together", "Splitting heavy atoms", "Spinning" }, answer = 2 },
			{ q = "The Sun mostly fuses which element?", options = { "Hydrogen", "Iron", "Gold", "Oxygen" }, answer = 1 },
		} },
	{ key = "hunger", icon = "🌾", name = "Solve World Hunger", unlock = "Free food stands in the plaza (stress relief).",
		qs = {
			{ q = "Growing crops in stacked indoor layers is called…", options = { "Vertical farming", "Fishing", "Mining", "Paving" }, answer = 1 },
			{ q = "Plants make food from sunlight by…", options = { "Respiration", "Photosynthesis", "Digestion", "Fermentation" }, answer = 2 },
		} },
	{ key = "water", icon = "💧", name = "Clean Water for Everyone", unlock = "The fountain sparkles with clean water.",
		qs = {
			{ q = "Removing salt from seawater is called…", options = { "Evaporation only", "Desalination", "Condensation", "Erosion" }, answer = 2 },
			{ q = "About how much of Earth's water is fresh water?", options = { "3%", "30%", "50%", "97%" }, answer = 1 },
		} },
	{ key = "cure", icon = "🧬", name = "A Cure for Cancer", unlock = "The hospital celebrates. Everyone's stress drops.",
		qs = {
			{ q = "Cancer is when cells…", options = { "Stop growing", "Grow out of control", "Turn into bones", "Become viruses" }, answer = 2 },
			{ q = "Which body system fights disease?", options = { "Digestive", "Immune", "Skeletal", "Muscular" }, answer = 2 },
		} },
	{ key = "translator", icon = "🗣", name = "Universal Translator", unlock = "Everyone in town understands each other (NPCs speak every language).",
		qs = {
			{ q = "Which language has the most native speakers?", options = { "English", "Mandarin Chinese", "Spanish", "Hindi" }, answer = 2 },
			{ q = "Translators find patterns. 'Uno, dos, tres' is…", options = { "French", "Spanish", "German", "Italian" }, answer = 2 },
		} },
	{ key = "superconductor", icon = "🧲", name = "Room-Temperature Superconductor", unlock = "Maglev streets: everyone walks faster.",
		qs = {
			{ q = "A superconductor carries electricity with…", options = { "Zero resistance", "Lots of heat", "Only at noon", "Sound" }, answer = 1 },
			{ q = "Maglev trains float using…", options = { "Wings", "Magnets", "Balloons", "Rockets" }, answer = 2 },
		} },
	{ key = "battery", icon = "🔋", name = "Forever Battery", unlock = "Gadgets recharge twice as fast.",
		qs = {
			{ q = "Most phone batteries today are…", options = { "Lithium-ion", "Lead-acid", "Potato", "Steam" }, answer = 1 },
			{ q = "A battery stores energy as…", options = { "Chemical energy", "Sound", "Light only", "Heat only" }, answer = 1 },
		} },
	{ key = "climate", icon = "🌍", name = "Fix the Climate", unlock = "Perfect sunny weather above everyone.",
		qs = {
			{ q = "Which gas traps the most extra heat from burning fuel?", options = { "Oxygen", "Carbon dioxide", "Helium", "Neon" }, answer = 2 },
			{ q = "Pulling CO₂ out of the air is called…", options = { "Carbon capture", "Cloud seeding", "Recycling", "Erosion" }, answer = 1 },
		} },
	{ key = "robots", icon = "🤖", name = "Robot Helpers", unlock = "Friendly robots walk around the plaza.",
		qs = {
			{ q = "Luau: what does `for i = 1, 3 do print(i) end` print last?", options = { "1", "2", "3", "4" }, answer = 3 },
			{ q = "A robot 'senses' distance with…", options = { "A sensor", "A battery", "A wheel", "A sticker" }, answer = 1 },
		} },
	{ key = "labfood", icon = "🍔", name = "Lab-Grown Food", unlock = "Free snack stands (stress relief).",
		qs = {
			{ q = "Lab-grown meat is grown from…", options = { "Plastic", "Animal cells", "Sand", "Plants only" }, answer = 2 },
			{ q = "Cells grow in a lab inside a…", options = { "Bioreactor", "Microwave", "Freezer", "Toaster" }, answer = 1 },
		} },
}

-- The secret joke project: always fails (badge after 10 tries)
Content.TimeMachineFails = {
	"You traveled 5 seconds into the past. Then 5 seconds passed. You're back.",
	"You met yourself. You argued about who's the original. Nobody won.",
	"The time machine turned into a toaster. The toast is from 1987.",
	"It worked! …in a parallel universe where it didn't.",
	"You went back in time and told yourself not to build the time machine. You didn't listen.",
	"Error 404: Time not found.",
	"You arrived in the future. It's Tuesday.",
	"The pigeons stole a part. Tesla would understand.",
	"You went back to the dinosaurs. A dinosaur pressed the button. You're home.",
	"Everything exploded, then un-exploded. Net result: nothing.",
}

Content.GrantArguments = {
	{ text = "This will help millions of people, and here's the data.", strength = 3 },
	{ text = "It's cool, trust me.", strength = 1 },
	{ text = "Other labs did smaller versions, so it's possible.", strength = 2 },
	{ text = "My cousin said it would work.", strength = 1 },
	{ text = "We have a clear plan, budget and timeline.", strength = 3 },
	{ text = "Pigeons approve.", strength = 1 },
}

Content.PeerReview = {
	{ lines = { "We tested it 100 times.", "It worked every time.", "So it must work forever, no matter what." }, wrong = 3 },
	{ lines = { "We measured the results carefully.", "One sample was enough to be sure.", "We shared our data." }, wrong = 2 },
	{ lines = { "Our control group didn't get the change.", "Our test group did.", "The control group proves the test group wrong because it's bigger." }, wrong = 3 },
}

---------------------------------------------------------------------
-- UPDATE 1.4: SPACE AND SECRETS
---------------------------------------------------------------------
-- Space projects (only Astronauts, only at the Space Lab on the Moon)
Content.SpaceProjects = {
	{ key = "spacefarm", icon = "🥬", name = "Space Farming", space = true, unlock = "Moon lettuce grows in the Space Lab garden.",
		qs = {
			{ q = "Plants grown without soil, roots in nutrient water, is called…", options = { "Hydroponics", "Photosynthesis", "Composting", "Irrigation" }, answer = 1 },
			{ q = "Plants on the ISS can't tell up from down by gravity. What do roots and shoots follow instead?", options = { "Sound", "Light and water", "Magnets", "Nothing, they die" }, answer = 2 },
		} },
	{ key = "asteroid", icon = "☄️", name = "Asteroid Mining", space = true, unlock = "A shiny asteroid parks next to the Moon base.",
		qs = {
			{ q = "Many asteroids are rich in which metal?", options = { "Gold only", "Iron and nickel", "Aluminium foil", "Lead" }, answer = 2 },
			{ q = "Where is the main asteroid belt?", options = { "Between Earth and the Moon", "Between Mars and Jupiter", "Past Pluto", "Inside the Sun" }, answer = 2 },
		} },
	{ key = "marshab", icon = "🔴", name = "Mars Habitat", space = true, unlock = "A Mars dome appears on the horizon of the Moon.",
		qs = {
			{ q = "Mars' air is mostly…", options = { "Oxygen", "Carbon dioxide", "Nitrogen", "Helium" }, answer = 2 },
			{ q = "A habitat on Mars needs thick walls or soil on top mainly to block…", options = { "Wind", "Radiation", "Noise", "Rain" }, answer = 2 },
		} },
}

-- Space Lab gates (orbital mechanics + physics)
Content.SpaceGates = {
	{ q = "Astronauts on the ISS float because…", options = { "There's no gravity in space", "They're falling around Earth all the time (free fall)", "Magnets", "The ISS is too high for gravity" }, answer = 2 },
	{ q = "To catch up with something AHEAD of you in the same orbit, you first…", options = { "Speed up", "Slow down (drop to a lower, faster orbit)", "Stop", "Turn around" }, answer = 2 },
	{ q = "Gravity on the Moon is about…", options = { "The same as Earth", "1/6 of Earth's", "Twice Earth's", "Zero" }, answer = 2 },
	{ q = "The ISS goes around Earth about every…", options = { "90 minutes", "24 hours", "1 week", "1 year" }, answer = 1 },
	{ q = "Why is there no sound in space?", options = { "It's too cold", "Sound needs air (or something) to travel through", "Space is too big", "Aliens absorb it" }, answer = 2 },
	{ q = "A higher orbit is…", options = { "Faster", "Slower", "The same speed", "Impossible" }, answer = 2 },
	{ q = "Light from the Sun reaches Earth in about…", options = { "8 seconds", "8 minutes", "8 hours", "8 days" }, answer = 2 },
	{ q = "Escape velocity from Earth is about…", options = { "11 km per second", "11 km per hour", "1,100 km per second", "11 m per second" }, answer = 1 },
}

-- Astronaut training (real minigames, not quizzes)
Content.AstroTraining = {
	{ key = "dock", icon = "🛰", name = "Docking", desc = "Tap DOCK when the capsule lines up with the port. Too early or late = bonk." },
	{ key = "oxygen", icon = "💦", name = "Oxygen", desc = "Keep the oxygen needle in the green zone for 15 seconds. Tap to breathe in." },
	{ key = "zerog", icon = "🧑‍🚀", name = "Zero-G", desc = "Push off in the right direction to grab each handle. Space has no brakes." },
}

-- World's Smartest cutscene (200 IQ)
Content.SmartestHeadlines = {
	"THE WORLD'S SMARTEST PERSON",
	"THE WORLD'S MOST INFLUENTIAL PERSON",
	"SCIENTISTS: \"WE HAVE QUESTIONS\"",
	"LOCAL GENIUS CORRECTS THE ENCYCLOPEDIA, ENCYCLOPEDIA SAYS THANK YOU",
}

-- Retired genius: NPCs ask you random questions
Content.RetiredQuestions = {
	{ who = "🧒 Kid", q = "Why is the sky blue?", options = { "Blue light scatters more in air", "It reflects the ocean", "Paint" }, answer = 1 },
	{ who = "👵 Grandma", q = "Is it true we only use 10% of our brain?", options = { "Yes", "No, we use all of it", "Only on Mondays" }, answer = 2 },
	{ who = "🧑‍🍳 Chef", q = "Does salt make water boil faster?", options = { "A lot faster", "Barely, it actually raises the boiling point a tiny bit", "It freezes it" }, answer = 2 },
	{ who = "🐦 A pigeon", q = "Coo?", options = { "Coo.", "Coo coo.", "Absolutely not." }, answer = 2 },
	{ who = "🧑‍🎓 Student", q = "Which is bigger, 0.5 or 0.45?", options = { "0.45", "0.5", "Same" }, answer = 2 },
	{ who = "🧔 Guy at the bus stop", q = "Do goldfish really have a 3 second memory?", options = { "Yes", "No, they remember for months", "Goldfish? Where?" }, answer = 2 },
	{ who = "👮 Officer", q = "Can lightning strike the same place twice?", options = { "Never", "Yes, tall things get hit a lot", "Only in movies" }, answer = 2 },
}

-- The Endless Castle: our own rhyme (one line per turn)
Content.CastleLeft = {
	"The candles drip and shadows creep, go LEFT where the old ghosts sleep.",
	"Count the stones and count again, the LEFT hall remembers when.",
	"A painting winks with one wet eye: go LEFT, and don't ask why.",
	"Hear the hum of the rusty knight? He says LEFT. (He's usually right.)",
}
Content.CastleRight = {
	"The armor creaks, the floorboards bite, the way ahead is to the RIGHT.",
	"Follow the drip of the leaky pipe, go RIGHT, believe the hype.",
	"The carpet's red, the curtains white, the brave ones always turn RIGHT.",
	"A chicken clucks with all its might: \"BAWK!\" (that means RIGHT).",
}
Content.CastleEnd = "And when you're lost and feeling small, knock on the old brick wall."
Content.CastleNoPath = "🗝 The chest hums… but it waits for someone who has picked a door. Come back after you choose: Lose or Gain!"
Content.CastleWrong = {
	"This hallway looks… familiar.",
	"You've been here before. Haven't you?",
	"The candles are laughing at you.",
	"Wrong turn. The castle resets. The castle always resets.",
}

---------------------------------------------------------------------
-- UPDATE 1.5: REAL PLACES (furniture, people and things to do inside buildings)
---------------------------------------------------------------------
Content.Rooms = {
	Closed = "🔒 Closed: nobody home",
	ClosedToast = "🔒 This building is closed. Nothing to do in there.",
	SmartOnly = "🧠 This is a smart place. Not for the Lose path.",
	DumbOnly = "🥴 This is a dumb place. Not for the Gain path.",
	PickPath = "Pick a path first: Lose or Gain.",
	Sit = "Sit",
	Talk = "Talk",
	Seat = "🪑 Seat",
	Couch = "🛋 Couch",
	Busy = "Wait a second…",
	-- signs inside rooms
	Signs = {
		arcade = "🕹 ARCADE ZONE",
		plushie = "🧸 PLUSHIE DISPLAY",
		classroom = "✏️ CLASSROOM",
		lecture = "🎓 LECTURE HALL",
		debate = "🎤 THE DEBATE SHOW",
		snacks = "🍿 SNACKS",
		therapy = "🛋 DR. CALM: THERAPY",
		checkup = "🩺 CHECK-UPS",
		patient = "🛹 PATIENT",
		newsroom = "📰 THE BRAINVILLE TIMES",
		counselor = "📋 JOB COUNSELOR",
		court = "⚖️ COURTROOM",
		election = "🗳 ELECTION PODIUM",
		maze = "🐭 MOUSE MAZE",
	},
	-- people who live in rooms (name tags)
	People = {
		host = "Ms. Mic (host)",
		editor = "Editor (Brainville Times)",
		teacher = "Teacher",
		student = "Student",
		doctor = "Dr. Wrinkle-Free",
		patient = "Skater kid (patient)",
		therapist = "Dr. Calm (therapist)",
		judge = "Judge Gavel",
		voter = "Voters of Brainville",
		counselor = "Job Counselor",
		barista = "Barista",
		assistant = "Lab assistant",
	},
	ArcadeTitles = { "BONKADOO", "BRAIN.EXE", "JUMP!!", "CLICK ME" },
	-- small things you can do (lose = Lose path only, gain = Gain path only)
	Actions = {
		arcade = { action = "Play the arcade", object = "🕹 Arcade", toast = "🕹️ 47 flashing lights later…" },
		plushie = { action = "Hug the display plushie (free)", object = "🧸 Bonkadoo Plushie", toast = "🧸 You hug it. It does not hug back." },
		cereal = { action = "Shake the cereal box", object = "🥣 Cereal", toast = "🥣 *shake shake* There is no prize." },
		sleep = { action = "Sleep in class", object = "😴 Your desk", toast = "😴 Zzz… you drooled on the desk." },
		paper = { action = "Throw a paper airplane", object = "✈️ Paper", toast = "✈️ It hit the teacher. Detention vibes." },
	},
	Fridge = { open = "Open", close = "Close", object = "🧊 Fridge", toast = "🧊 The fridge only has microwave meals. Of course." },
	Board = { action = "Write on the board", object = "🧑‍🏫 Whiteboard", toast = "🧑‍🏫 You wrote: %s" },
	BoardStart = {
		school = { Lose = "2 + 2 = fish", Gain = "Today: fractions" },
		university = "E = mc²   a² + b² = c²",
	},
	BoardLines = {
		Lose = { "2 + 2 = fish", "the sun is a big lamp", "bonkadoo = science", "cats are just loud bread" },
		Gain = { "¾ = 0.75", "H₂O = water", "√144 = 12", "E = mc²" },
	},
	Counselor = { action = "Find a job", object = "📋 Job Counselor" },
	Exit = { sign = "🚪 EXIT", action = "Leave", object = "🚪 Exit door" },
}

---------------------------------------------------------------------
-- UPDATE 1.5: CONVERSATION SCENES
-- Two people, the camera cuts to whoever talks, you pick what to say (bottom-left).
-- The numbers for every choice (meter and brain cells) are in Config.Conversations,
-- in the same order as the choices here.
---------------------------------------------------------------------
-- A way out if you get stuck (1.5)
-- The Perfectly Average guy (secret). Each visit he says the next line; kid-safe creepy, never scary.
Content.AverageGuy = {
	"\"I have exactly 86,000,000,000 brain cells. Not one more. Not one less.\"",
	"\"You came back. Most people only visit once. That's… above average.\"",
	"\"Have you noticed nobody else in town has exactly 86 billion? Just me. I counted.\"",
	"\"Sometimes at night the numbers on the Brain Tower stop. Then they start again. Perfectly normal.\"",
	"\"I'm not watching you. I'm watching the average. You just keep standing in it.\"",
	"…he just smiles. Perfectly average smile. 🙂",
}

Content.Unstuck = {
	Button = "🆘",
	Done = "🆘 Unstuck! You're back outside.",
	Wait = "🆘 Wait %d seconds before using Unstuck again.",
}

Content.ConvUI = {
	You = "You",
	Leave = "Leave",
	Again = "💬 You already talked about this. (Tiny brain change, no coins. Try another chat!)",
	Done = "Leave",
	Objection = "OBJECTION!",
	Fast = "⏩ Tap the text to skip",
	Busy = "You're already talking to someone.",
	TooFar = "Walk up to them first.",
	EmbarrassMoment = "Lost a conversation in front of everyone",
}

-- Animals can't talk. They still get three choices (same effects, in order).
Content.AnimalTalk = {
	worm = { "*wiggles politely*", "*wiggles rudely*", "*wiggles away*" },
	fly = { "*bzzz (agreeing)*", "*lands on their nose*", "*bzzzzzzz*" },
	bee = { "*happy buzz*", "*angry buzz*", "*waggle dance*" },
	mouse = { "*squeak (yes)*", "*squeak (no)*", "*eats the paperwork*" },
	octopus = { "*waves one arm*", "*squirts ink*", "*changes color*" },
	dog = { "*sits like a good dog*", "*barks at nothing*", "*chases own tail*" },
	microbe = { "*divides in half*", "*floats*", "*…*" },
	tardigrade = { "*survives*", "*survives harder*", "*naps for 30 years*" },
	default = { "*ook ook*", "*grunts*", "*points at a pigeon*" },
}

Content.Conversations = {
	therapist = {
		who = "Dr. Calm",
		meter = "🤗 Trust",
		action = "Talk to the therapist",
		nodes = {
			a = { say = "Welcome. Take a seat. So… how's your brain lately?", opts = {
				{ t = "Honestly? A bit stressed. Gates, jobs, everything.", n = "b" },
				{ t = "bro my brain is just loading 🔄", n = "b" },
				{ t = "I'd rather not talk about it.", n = "b" },
			} },
			b = { say = "Hm. When you feel overwhelmed, what do you usually do?", opts = {
				{ t = "Take a break. Coffee, a nap, a walk.", n = "c" },
				{ t = "Scroll BrainTok for 6 hours.", n = "c" },
				{ t = "Panic, mostly.", n = "c" },
			} },
			c = { say = "Here's a trick: name one thing you did well today.", opts = {
				{ t = "I learned something new." },
				{ t = "I didn't walk into the wall. Today." },
				{ t = "I clicked every clickbait 😎" },
			} },
		},
		ends = {
			good = { line = "You leave feeling lighter.", result = "😌 Stress −45, embarrassment −30" },
			mid = { line = "That was a good start.", result = "😌 Stress −15" },
			bad = { line = "Dr. Calm writes something in a notebook. Very long.", result = "📝 \"Patient is… a lot.\"" },
		},
	},
	doctorG = {
		who = "Skater kid (patient)",
		meter = "🩺 Patient trust",
		action = "See a patient",
		nodes = {
			a = { say = "Doc, I fell off my skateboard. My arm is swollen and bent. 😭", opts = {
				{ t = "Let's get an X-ray. It might be a fracture.", n = "b" },
				{ t = "Just walk it off.", n = "b" },
				{ t = "Have you tried turning it off and on again?", n = "b" },
			} },
			b = { say = "The X-ray shows a crack in the bone. What now?", opts = {
				{ t = "A cast for about 6 weeks, then a check-up.", n = "c" },
				{ t = "A plaster. Like a cartoon.", n = "c" },
				{ t = "Ice cream. For morale.", n = "c" },
			} },
			c = { say = "Will I be able to skate again?", opts = {
				{ t = "Yes! Once it heals. Wear a helmet and pads." },
				{ t = "Never. Become a librarian." },
				{ t = "Only backwards." },
			} },
		},
		ends = {
			good = { line = "The patient gives you a thumbs up with the good arm.", result = "💰 +30 coins, the hospital is impressed" },
			mid = { line = "The patient is OK. You could've been clearer.", result = "💰 +10 coins" },
			bad = { line = "The patient asks for a second opinion. From a pigeon.", result = "😰 Stress +10" },
		},
	},
	doctorL = {
		who = "Dr. Wrinkle-Free",
		meter = "🩺 Doctor patience",
		action = "Get checked",
		nodes = {
			a = { say = "So. What brings you in today?", opts = {
				{ t = "My brain feels… quieter. It's great.", n = "b" },
				{ t = "I think I'm getting smarter. Make it stop.", n = "b" },
				{ t = "I read a book by accident.", n = "b" },
			} },
			b = { say = "Hmm. Follow my finger with your eyes. Left… right…", opts = {
				{ t = "*follows a pigeon instead*", n = "c" },
				{ t = "*follows perfectly*", n = "c" },
				{ t = "Which finger? You have ten.", n = "c" },
			} },
			c = { say = "My diagnosis: acute brainrot. I prescribe one (1) book a day.", opts = {
				{ t = "Can I get that as a 15-second video?" },
				{ t = "Fine. One book." },
				{ t = "Is brainrot contagious? Asking for my friends." },
			} },
		},
		ends = {
			good = { line = "The doctor is relieved. You are not (it's bad for your run).", result = "📚 The doctor believes in you. Ew." },
			mid = { line = "You leave with a sticker.", result = "🩹 You got a sticker." },
			bad = { line = "The doctor sighs so hard the X-ray machine turns on.", result = "🥴 Extra brainrot for the road" },
		},
	},
	courtL = {
		who = "Judge Gavel",
		meter = "⚖️ Judge patience",
		action = "Answer the lawsuit",
		nodes = {
			a = { say = "Order! The Brainville Times is suing you for spreading a fake headline. How do you plead?", opts = {
				{ t = "Guilty. I shared it without reading it.", n = "b" },
				{ t = "Not guilty. The headline had 🔥 emojis, so it's true.", n = "b" },
				{ t = "What's a headline?", n = "b" },
			} },
			b = { say = "Did you check any other source before sharing it?", opts = {
				{ t = "No, and I should have.", n = "c" },
				{ t = "I checked the comments. They said 'real'.", n = "c" },
				{ t = "OBJECTION! …wait, I'm the one being sued.", n = "c", slam = true },
			} },
			c = { say = "Any final words before I decide?", opts = {
				{ t = "I'll read before I share." },
				{ t = "Like and subscribe." },
				{ t = "Can I get my sentence as a meme?" },
			} },
		},
		ends = {
			good = { line = "Case dismissed. The judge tells you to read more. (Ugh.)", result = "⚖️ Case dismissed" },
			mid = { line = "Small fine: you must read one (1) terms of service.", result = "📜 Community reading service" },
			bad = { line = "GUILTY. You must hold a sign in the plaza: 'I BELIEVED A FAKE HEADLINE'.", result = "📋 Embarrassment +35" },
		},
	},
	courtG = {
		who = "Judge Gavel",
		meter = "⚖️ Jury",
		action = "Take the case",
		nodes = {
			a = { say = "Counselor, the witness says: 'I was home all evening. I watched TV until 9. I was at the park at 8.'", opts = {
				{ t = "OBJECTION! They can't be home AND at the park at 8.", n = "b", slam = true },
				{ t = "Sounds fine to me.", n = "b" },
				{ t = "Can the witness do a backflip?", n = "b" },
			} },
			b = { say = "The other lawyer says your client 'looks guilty'. Your response?", opts = {
				{ t = "Looking guilty isn't evidence. Show proof.", n = "c" },
				{ t = "Fair point, they do.", n = "c" },
				{ t = "YOU look guilty.", n = "c" },
			} },
			c = { say = "Closing statement, counselor.", opts = {
				{ t = "The story doesn't add up. The jury must find my client not guilty." },
				{ t = "Uhh… thank you for coming to my TED talk." },
				{ t = "*slams table* NO FURTHER QUESTIONS", slam = true },
			} },
		},
		ends = {
			good = { line = "NOT GUILTY! Your client hugs you. The judge nods.", result = "💰 +40 coins, 🧠 brain cells" },
			mid = { line = "Hung jury. Try again another day.", result = "💰 +10" },
			bad = { line = "You lost the case. Your client is very confused.", result = "😰 Stress +15" },
		},
	},
	debate = {
		who = "Ms. Mic (host)",
		meter = "📊 Audience",
		action = "Join the Debate Show",
		nodes = {
			a = { say = "Welcome to THE DEBATE SHOW! Topic: should kids read more? Opening statement!", opts = {
				{ t = "Yes. Reading grows your vocabulary and focus.", n = "b" },
				{ t = "No. Videos are just books that move.", n = "b" },
				{ t = "*airhorn noises*", n = "b" },
			} },
			b = { say = "Your opponent says 'books are boring'. Rebuttal?", opts = {
				{ t = "Boring to start, but they let you imagine anything.", n = "c" },
				{ t = "Agreed. Next topic.", n = "c" },
				{ t = "Your FACE is boring.", n = "c" },
			} },
			c = { say = "Final 10 seconds! Make them count!", opts = {
				{ t = "Read 20 minutes a day. Your future self will thank you." },
				{ t = "Follow me on BrainTok." },
				{ t = "*dabs*" },
			} },
		},
		ends = {
			good = { line = "The audience gives you a standing ovation! 👏", result = "🏆 You won the Debate Show" },
			mid = { line = "A draw. The host is disappointed in both of you.", result = "🤝 Draw" },
			bad = { line = "The audience throws (foam) tomatoes. 🍅", result = "🍅 SPLAT" },
		},
	},
	journalistL = {
		who = "Editor (Brainville Times)",
		meter = "📰 Clicks",
		action = "Write a headline",
		nodes = {
			a = { say = "We need a headline about the new park. Make people click!", opts = {
				{ t = "'You WON'T BELIEVE what's in the PARK 😱😱'", n = "b" },
				{ t = "'New park opens on Main Street'", n = "b" },
				{ t = "'PARK? MORE LIKE BARK 🐶'", n = "b" },
			} },
			b = { say = "Good. Now the article. Facts or vibes?", opts = {
				{ t = "Vibes. Only vibes.", n = "c" },
				{ t = "Facts, with quotes from real people.", n = "c" },
				{ t = "Just the word 'park' 400 times.", n = "c" },
			} },
			c = { say = "Last thing: a thumbnail.", opts = {
				{ t = "Me pointing at a pigeon with a red arrow and a shocked face" },
				{ t = "A nice photo of the park" },
				{ t = "Just a red circle. On nothing." },
			} },
		},
		ends = {
			good = { line = "Your article goes MEGA viral. Dumb players everywhere read it.", result = "🔥 2 million clicks. Zero facts." },
			mid = { line = "It's… fine. Some clicks.", result = "📰 Published" },
			bad = { line = "Your article is accurate. Nobody clicks. Tragic.", result = "📉 4 clicks (one was your mom)" },
		},
	},
	journalistG = {
		who = "Editor (Brainville Times)",
		meter = "🔎 Accuracy",
		action = "Fact-check the news",
		nodes = {
			a = { say = "Fact-check this headline: 'Great Wall of China easily visible from space!'", opts = {
				{ t = "False. Astronauts say you can't see it with the naked eye.", n = "b" },
				{ t = "True, it's huge.", n = "b" },
				{ t = "Let me ask BrainTok.", n = "b" },
			} },
			b = { say = "Next: 'Study shows chocolate makes you a genius.' Your note?", opts = {
				{ t = "Check who paid for the study and how many people were in it.", n = "c" },
				{ t = "Publish it, I love chocolate.", n = "c" },
				{ t = "Only dark chocolate.", n = "c" },
			} },
			c = { say = "Last one. A quote with no source. Run it?", opts = {
				{ t = "No. Find the original source first." },
				{ t = "Yes, it sounds smart." },
				{ t = "Attribute it to Albert Zweistein." },
			} },
		},
		ends = {
			good = { line = "The Brainville Times prints a correction, thanks to you.", result = "💰 +30, 🧠 brain cells" },
			mid = { line = "Mostly right. Good work.", result = "💰 +10" },
			bad = { line = "The fake news got printed. Oops.", result = "😰 Stress +10" },
		},
	},
	election = {
		who = "Voters of Brainville",
		meter = "🗳 Votes",
		action = "Give an election speech",
		nodes = {
			a = { say = "Citizens gather at the podium. 'Why should we vote for you?'", opts = {
				{ t = { Lose = "FREE BRAINTOK FOR EVERYONE", Gain = "More libraries and free tutoring." }, n = "b" },
				{ t = "Because I said so.", n = "b" },
				{ t = "I promise a pigeon in every home.", n = "b" },
			} },
			b = { say = "A voter asks: 'What will you do about the potholes?'", opts = {
				{ t = "Fix the worst ones first and publish a plan.", n = "c" },
				{ t = "Turn them into tiny swimming pools.", n = "c" },
				{ t = "What's a pothole?", n = "c" },
			} },
			c = { say = "Final words before the vote!", opts = {
				{ t = "Vote for me. I'll listen to you." },
				{ t = "VOTE OR ELSE (please)" },
				{ t = "*throws confetti at the crowd*" },
			} },
		},
		ends = {
			good = { line = "YOU WON THE ELECTION! Your path gets a boost.", result = "🏛 Mayor of Brainville (temporary)" },
			mid = { line = "You lost, but it was close!", result = "🗳 Close race" },
			bad = { line = "You got 3 votes. One was a pigeon.", result = "🐦 3 votes" },
		},
	},
	classroomL = {
		who = "Teacher",
		meter = "😤 Teacher patience",
		action = "Take the pop quiz",
		nodes = {
			a = { say = "Pop quiz! What is the capital of France?", opts = {
				{ t = "F.", n = "b" },
				{ t = "Paris.", n = "b" },
				{ t = "France is a fake country.", n = "b" },
			} },
			b = { say = "…OK. How many legs does a spider have?", opts = {
				{ t = "Spiders are just ants that gave up.", n = "c" },
				{ t = "Eight.", n = "c" },
				{ t = "*throws paper airplane*", n = "c" },
			} },
			c = { say = "Last question. What is 7 × 8?", opts = {
				{ t = "78" },
				{ t = "56" },
				{ t = "*falls asleep*" },
			} },
		},
		ends = {
			good = { line = "The teacher is proud. You feel… smarter. Gross.", result = "📝 A+. Oh no." },
			mid = { line = "C−. Perfectly average.", result = "📝 C−" },
			bad = { line = "The teacher gives up and puts on a movie.", result = "📺 Movie day. Brain off." },
		},
	},
	classroomG = {
		who = "The class",
		meter = "🙋 Class attention",
		action = "Teach the class",
		nodes = {
			a = { say = "Students: 'Why do we need fractions?!'", opts = {
				{ t = "Pizza. If you share a pizza with 4 friends, that's quarters.", n = "b" },
				{ t = "Because the test says so.", n = "b" },
				{ t = "You don't. Class dismissed.", n = "b" },
			} },
			b = { say = "A student says: 'Is ½ bigger than ⅓?'", opts = {
				{ t = "Yes. Cut a pizza in 2 vs 3: halves are bigger slices.", n = "c" },
				{ t = "No, 3 is bigger than 2.", n = "c" },
				{ t = "Ask your parents.", n = "c" },
			} },
			c = { say = "Students: 'Can we have a fun fact?'", opts = {
				{ t = "Octopuses have three hearts!" },
				{ t = "Homework is a fun fact." },
				{ t = "Wombat poop is cube-shaped." },
			} },
		},
		ends = {
			good = { line = "The whole class claps. One kid says you're the best teacher ever.", result = "💰 +35, 💡 idea +1" },
			mid = { line = "Half the class was listening. Not bad.", result = "💰 +15" },
			bad = { line = "A paper airplane hits you in the head.", result = "✈️ Stress +12" },
		},
	},
	experiment = {
		who = "Lab assistant",
		meter = "🐭 Mouse progress",
		action = "Mouse maze experiment",
		nodes = {
			a = { say = "The mouse needs to learn the maze. How should we start?", opts = {
				{ t = "Put a treat at the end and let it explore.", n = "b" },
				{ t = "Yell directions at it.", n = "b" },
				{ t = "Show it a BrainTok tutorial.", n = "b" },
			} },
			b = { say = "Should we change the maze every time?", opts = {
				{ t = "No. Keep it the same so we can measure learning.", n = "c" },
				{ t = "Yes! Chaos!", n = "c" },
				{ t = "Let the mouse design it.", n = "c" },
			} },
			c = { say = "How do we know it learned?", opts = {
				{ t = "Time it every run. If it gets faster, it learned." },
				{ t = "Ask the mouse." },
				{ t = "Vibes." },
			} },
		},
		ends = {
			good = { line = "The mouse runs the maze in 9 seconds! Science! 🎉", result = "🐭 Experiment success, 💡 idea +1" },
			mid = { line = "The mouse found the treat. Eventually.", result = "🐭 Partial success" },
			bad = { line = "The mouse is now in charge of the lab.", result = "🐭 New lab director" },
		},
	},
}

---------------------------------------------------------------------
-- Settings -> "What's new": one entry per update, newest first.
-- Add a new entry at the TOP each update (and bump Config.Version).
---------------------------------------------------------------------
Content.Updates = {
	{ v = "1.9", name = "Real Life Update", lines = { "📱 Your phone is now the main menu, with an 🎒 Items app for all your gadgets.", "🎮 Every job has its own minigame: scan groceries, sort files, read X-rays, mix colours and more. No maths!", "💌 Big life moments: a friend's wedding, Grandma's 80th, a runaway pet… Check your Invites.", "🌟 Reach the top of a job ladder (or IQ 140) to choose your genius: math, physics, coding, business or chess.", "⚙️ Settings has tabs and volume sliders, and a 💬 Send feedback button." } },
	{ v = "1.8.9", name = "Calm New Look", lines = { "🎨 A calmer, cleaner look: dark panels, matching buttons, no more rainbow gradients.", "🚧 Skill Gates are now fun-fact gates: read a fun fact, answer an easy question about it.", "⚠️ New: Settings → Reset my progress (hold to confirm, once a day).", "💥 When your brain runs out it now swells, wobbles… and goes POOF!" } },
	{ v = "1.8.8", name = "Bigger Town + Unstuck", lines = { "🦶 Fixed: sometimes you got stuck and couldn't move. Stress now only slows you for a few seconds.", "🚧 Skill Gates no longer stress you out, and you can retry right away.", "🏙 The whole town is bigger: wider roads, bigger buildings, and parked cars no longer crash into each other." } },
	{ v = "1.8.7", name = "Phone Fixes", lines = { "🛠 Fixed: Skill Gates marked right answers wrong.", "📱 The in-game phone fits sideways phones: wider, more apps per row, BrainTalks buttons always visible.", "🔔 Little notes now pop up at the top, not in the middle." } },
	{ v = "1.8.6", name = "New Staff Panel", lines = { "🛠 Staff get a brand-new BrainAdmin panel: tabs, search, player cards with rank badges, and an \"Are you sure?\" step before kicks and bans." } },
	{ v = "1.8.5", name = "Cleaner Screen + Quick Play", lines = { "⚡ New Quick Play button next to your Phone: 3 fast questions, points for right answers (on the Lose path the dumbest answer wins!).", "🪟 Pop-ups are smaller, and you can tap outside one to close it.", "🛒 SHOP and 🗺 MAP are small round buttons now; the floating job tag is gone." } },
	{ v = "1.8.4", name = "Warm Genius Town", lines = { "🏙 Smart players (IQ 135+) now see a warm brick and sandstone town with terracotta roofs, not grey boxes.", "✨ At IQ 200+ the cyan future touches stay on top." } },
{ v = "1.8.3", name = "Tidier screen", lines = { "🔢 Huge brain counts are short now (1.2T, 9.9Qa …) instead of 25 squeezed digits.", "🔤 One clean font everywhere, even at genius level.", "📌 Goals sit in a slim line at the top instead of a big banner in the middle.", "➕ The More button has its icon back.", } },
	{ v = "1.8.2", name = "Busy Streets", lines = {
		"🏘 Every street is busier: globe lamps, planters, benches and trees along the sidewalks, and bunting over Main Street.",
		"🏠 Houses got pitched roofs and flower boxes; shops got striped awnings.",
		"🌆 A bigger city behind the town: tall towers with lit windows at night, hills and a highway.",
		"🎨 The town changes its art style with your brain level.",
		"🥔 Slow phone? Low graphics now switches on by itself (you can turn it off in Settings).",
	} },
	{ v = "1.8", name = "Life Pack & Phone Shop", lines = {
		"📱 New free Phone Shop: parody phones, a case maker with a 🧠 Brainrot meter, and a very suspicious scam stall.",
		"🫧 Slime Shop, 🤸 Trampoline Park and 🔮 Fortune Teller (exact odds shown) on the west side, free for everyone.",
		"👶 Optional Life Pack: grow up from baby to grandparent, pick your path at the 🌟 Crossroads Ceremony, hidden places, pets.",
		"🖐 High-five other players to become Friends → Good friends → Best friends. (The base game stays free and complete.)",
	} },
	{ v = "1.7.4", name = "No Pushing, No Falling", lines = {
		"👻 Players walk through each other now: nobody can push you or block a doorway.",
		"🧱 The edge of town has an invisible wall, so you can't walk off into the void.",
		"🏰 Endless Castle: the treasure waits for you if you haven't picked a door yet (it doesn't get used up).",
	} },
	{ v = "1.7.3", name = "Everyone's Ideas", lines = {
		"🧭 A \"What do I do now?\" arrow, 🥔 Low graphics, ⏱ a speedrun timer and 🏅 a badge checklist (all in Settings).",
		"🏆 Plaza boards: top earners this week and fastest to IQ 200. 🚗 Ride Hoppr with up to 3 friends. 🎭 Vs Mode lobby sign.",
		"💥 A big brain moment right after you pick a door. ☀️ Brighter town, greener grass, warm lamps indoors.",
		"📄 Something about the Perfectly Average guy isn't right. Look for beige notes… (Settings → 😐 Horror)",
	} },
	{ v = "1.7.2", name = "Bigger Buttons, Safer Bank", lines = {
		"📱 Every HUD button and label stays thumb-sized and readable, even on the smallest phones.",
		"🏦 Fixed a bank trick that could break your coins (broken saves are repaired automatically).",
		"💬 Chat scenes pay coins once every 10 minutes, so working is still the best way to earn.",
		"🙂 Someone plain and grey in the plaza has more to say if you keep visiting…",
	} },
	{ v = "1.7.1", name = "Fair Play Fixes", lines = {
		"💼 You get paid for real work: wages only while you're clocked in at work, and the on-time bonus needs a task.",
		"🚌 The free map ride is now a slow Brain Bus. Hoppr is the fast way. Rides never pull you out of a chat or a seat.",
		"🏦 Brain Bank pays a fair 0.5% on your lowest savings. 📱 Bigger buttons and text on phones.",
		"🐾 Animals: a new 🛍 button sniffs the way to the Mall stands. Effects slider now calms wobble and scrambled text too.",
	} },
	{ v = "1.7", name = "Your Brain Runs the Game", lines = {
		"📱 Your phone changes with your brain: a chunky toy phone, a cozy phone, or (IQ 120+) a real phone you swipe through.",
		"🚖 Hoppr rides: see the price and time before you pay. 🏦 Brain Bank savings. ⏰ Shifts with payslips.",
		"🥴 Lose path: scrambled app names, brain lag and silly joke ads (turn them down in Settings → Effects).",
		"🐾 Animals get a no-words menu and follow a smell trail. 🧠 New Brain Tower, district gates and lookouts.",
	} },
	{ v = "1.6", name = "Careers, School & Animals", lines = {
		"📈 Jobs are career ladders now: work, get promoted, earn more (Bagger → Store Manager, Tutor → Dean…).",
		"🏫 Lose path: the school bell rings. Get to class or the truant officer comes for you.",
		"🐶 Turn into a real animal: dog, fly, bee, mouse, worm, rock. Each one moves differently.",
		"🐾 Animal powers: Bark, Buzz up, Dig (button bottom right, or F).",
	} },
	{ v = "1.5", name = "Real Places", lines = {
		"🏫 Walk into buildings that have a use: furniture, people and seats inside.",
		"🎬 Conversation scenes: the camera moves in, pick your answer bottom-left (or press 1/2/3).",
		"🚪 EXIT doors in every building, and a 🆘 Unstuck button (top right).",
		"⏭ The tutorial is faster and has a Skip button.",
	} },
	{ v = "1.4", name = "Space & Castle", lines = {
		"🚀 Space projects and the Moon for the smartest players.",
		"🏰 The Castle for the dumbest players.",
		"📖 A new guided tutorial for each path.",
		"🏡 New cozy town look on the Gain path.",
	} },
	{ v = "1.3", name = "Projects", lines = { "🔬 Inventions, statues and big projects." } },
	{ v = "1.2", name = "Smart vs Dumb", lines = { "🤝 Activities where smart and dumb players play together." } },
	{ v = "1.1", name = "More to do", lines = { "📱 More phone apps, jobs and Skill Gates." } },
	{ v = "1.0", name = "Launch", lines = { "🧠 Pick a door: Lose a Brain Cell or Gain a Brain Cell." } },
}

---------------------------------------------------------------------
-- 1.7: real-life phone apps (original parody names only: never real brands)
---------------------------------------------------------------------
Content.Life = {
	Apps = {
		hoppr = { icon = "🚖", name = "Hoppr" },
		bank = { icon = "🏦", name = "Brain Bank" },
		shifts = { icon = "⏰", name = "Shifts" },
	},
	Ride = {
		Title = "🚖 Hoppr",
		WhereTo = "Where to?",
		Work = "Work",
		Fare = "Fare: 💰 %d",
		Eta = "Car arrives in %d s",
		Busy = "⚠️ Busy hours: prices are ×1.5 right now (shown before you pay).",
		Confirm = "Confirm ride • 💰 %d",
		Cancel = "Back",
		Coming = "Your car is coming!",
		PlateCard = "%s %s\nPlate: %s\nDriver: %s",
		Riding = "🚗 On the way to %s…",
		Receipt = "🧾 Receipt: %s • 💰 %d • plate %s. Thanks for riding Hoppr!",
		TooPoor = "You need 💰 %d for this ride. Walk, take the free 🚌 Brain Bus from the map, or earn coins at work.",
		Refunded = "🚗 Your driver waited, but you were busy talking. Fare refunded: 💰 %d.",
		Invite = "🚗 %s booked Hoppr to %s.\nJoin the ride? You pay 💰 %d.",
		Join = "✅ Join (💰 %d)",
		NoThanks = "No thanks",
		Joined = "🚗 You're in! Riding to %s (💰 %d).",
		GroupGone = "That ride already left.",
		GroupFull = "That car is full.",
		GroupFar = "Stand next to your friend to join.",
		Animal = "🐾 Animals can't hold a phone. Follow your nose instead!",
		Unknown = "Hoppr can't find that place.",
		Expired = "That price ran out. Check the fare again.",
		Already = "You're already in a car!",
		Wait = "Hoppr is finding the next car…",
		Free = "Walking is free. The free 🚌 Brain Bus (🗺 Maps) is slow. Hoppr is door to door, fast.",
		Drivers = { "Dana ⭐4.9", "Omar ⭐4.8", "Kim ⭐5.0", "Leo ⭐4.7", "Maya ⭐4.9" },
		CarColors = { "🔴 red", "🔵 blue", "⚪ white", "⚫ black", "🟢 green", "🟡 yellow" },
		CarModels = { "Brainmobile Mini", "Hoppr Comfort", "Thinkr Hatchback", "Noodle Sedan" },
	},
	Shift = {
		Title = "⏰ Shifts",
		NextIn = "Next shift starts in %d:%02d",
		StartedAgo = "This shift started %d s ago. Clock in within %d s to be on time.",
		Late = "⏰ Clocked in, but you're late. No on-time bonus this shift.",
		OnTime = "✅ Clocked in on time! Do at least one task for a +💰 %d bonus.",
		ClockIn = "🟢 Clock in",
		ClockOut = "🔴 Clock out (get payslip)",
		GainOnly = "Shifts are for the Gain path.",
		NoJob = "Get a job first (📱 Jobs).",
		NotThere = "Go to %s to clock in. Hoppr or the 🚌 bus can take you.",
		Already = "You're already clocked in.",
		NotOn = "You're not clocked in.",
		TooShort = "Work a little longer first (%d s).",
		OnShiftFor = "🟢 On shift: %d min %d s",
		Payslip = "🧾 PAYSLIP\nJob: %s\nTime: %s min • Tasks done: %d\nWages: 💰 %d\nOn-time bonus: 💰 %d\nTOTAL: 💰 %d\n💳 Paid into your Brain Bank checking.",
		Tip = "Tip: shifts start every 5 minutes. Walking is free, but it can make you late.",
		BonusInfo = "On-time bonus: 💰 %d if you clock in within %d s of the start and do at least one task. Wages are only paid while youre clocked in at work.",
	},
	Bank = {
		Title = "🏦 Brain Bank",
		Checking = "Checking (your coins): 💰 %d",
		Savings = "Savings: 💰 %d",
		Rate = "Savings grow +%s%% every %d minutes you play (fixed, never random), paid on your lowest balance since the last time.",
		NextIn = "Next interest in %d:%02d",
		Save = "Save 💰 %d",
		Take = "Take out 💰 %d",
		Amount = "Pick an amount.",
		NotEnough = "Not enough coins for that.",
		Interest = "🏦 Brain Bank: +💰 %d interest on your savings!",
		BillPaid = "🧾 Bills paid: 💰 %d (harder life is ON in Settings).",
		BillSkipped = "🧾 Bills skipped: you're broke, and there's no debt here.",
		HardLife = "Harder life (bills): %s",
		HardLifeInfo = "With harder life ON, a small bill of 💰 %d is paid every interest time. It never goes below 0: no debt, ever.",
		Note = "Paychecks go straight into checking. No loans, no gambling.",
	},
	Animal = {
		Title = "🐾",
		Sniff = "👃",
		Home = "🏠",
		Power = "⚡",
		Stands = "🛍", -- the four Lose stands in the Brainrot Mall (sniff trail, no reading needed)
		StandIcons = { clickbait = "📰", steal = "🎮", comments = "💬", scroller = "📱" },
		StandOrder = { "clickbait", "steal", "comments", "scroller" },
	},
	LoseFX = {
		Warn = { "uh oh…", "wait… 🥴", "brain buffering…", "hmm?" },
		Ads = {
			{ title = "🎉 YOU WON!!!", text = "a FREE nothing! tap X to claim (nothing)" },
			{ title = "🔥 HOT SINGLES", text = "hot single SOCKS near you 🧦🧦" },
			{ title = "💎 1 WEIRD TRICK", text = "doctors HATE this banana 🍌" },
			{ title = "📢 BRAIN SALE", text = "buy 0 brain cells, get 0 FREE" },
			{ title = "🎰 SPIN!!!", text = "(just kidding, there's no wheel) 🙃" },
		},
		AdNote = "joke ad • not real • nothing to buy",
		Shortcut = "🕳 Dumb shortcut! (only dumb brains fit)",
	},
}

-- Settings text for 1.7
Content.Settings17 = {
	Effects = "✨ Effects intensity",
	EffectsInfo = "Shake, glitches, scrambled words and joke ads. 0% turns them off.",
	ClassicHud = "🧩 Simple phone (same for every brain)",
	Guide = "🧭 \"What do I do now?\" arrow",
	LowGraphics = "🥔 Low graphics (for slow phones)",
	LowGraphicsInfo = "Turns off street lights, sparkles, extra decorations and shadows so the game runs smoother.",
	LowGraphicsAuto = "🥔 Your device seemed slow, so Low graphics is on. You can switch it off in Settings.",
	SpeedrunTimer = "⏱ Speedrun timer",
	AlwaysDay = "☀️ Always day (no night)",
	FewerToasts = "🔕 Fewer notifications",
	EdgeOfTown = "🚧 This is the edge of Brainville! The city goes on, but your adventure is back that way. 👈",
}

-- 1.7.3: badge checklist (Settings → 🏅). Kid-friendly hints for locked SECRET badges (they never say exactly how).
Content.BadgeUI = {
	Button = "🏅 Badges (%d/%d)",
	Title = "🏅 Badge checklist",
	Got = "✅",
	Locked = "🔒",
	Secret = "Secret badge",
	Hints = {
		ReadTOS = "Some people never read the small print. Be different.",
		ClickedEverything = "Curiosity clicked the cat… many, many times.",
		WhereAmI = "How small can a brain get before you stop being an animal?",
		PerfectlyAverage = "Someone plain and grey in the plaza wants to chat.",
		AllInventions = "Keep working until every idea goes ding.",
		Coffee60 = "A famous composer was very picky about his coffee.",
		CompleteMakeover = "Hit the very bottom… then climb all the way back.",
		RefusedPrize = "Not every prize has to be accepted.",
		MaybeNextTime = "Some machines need a LOT of tries.",
		WorldsSmartest = "Keep getting smarter. Like, really smart.",
		TooMuchBrain = "Is there such a thing as too smart?",
		LostAndFound = "A strange little house at the end of a road. Look closer.",
	},
}

-- 1.7.3: the first big moment of a new run
Content.FirstWow = {
	Lose = "💥 BRAIN DROP! A meme just deleted a chunk of your brain!",
	Gain = "✨ BRAIN BOOST! Your first big idea!",
}

-- 1.7.3: Vs Mode lobby sign (near spawn)
Content.VsLobby = {
	Title = "🎭 VS MODE LOBBY (tap 🎭 Vs Mode)",
	Waiting = "%d waiting: %s as %s. Needs a %s!",
	Nobody = "Nobody waiting yet. Be the first!",
}

-- 1.7.3: "The Average Files", part 1 (ported from the browser game's notes). Slow, kid-safe dread. No gore.
Content.Horror = {
	ReadNote = "Read",
	NoteObject = "📄 A beige note",
	NoteTitle = "📄 The Average Files (%d/%d)",
	AnimalNote = "📄 The paper smells… perfectly average. You can't read it, but your fur stands up a little. 🐾",
	StageToast = {
		[1] = "😐 You feel like someone perfectly ordinary is watching. Probably nothing.",
		[2] = "😐 The town feels a little more… average today.",
		[3] = "😐 Someone counted your steps. Exactly average. Again.",
	},
	Setting = "😐 Horror: %s",
	SettingNames = { off = "Off", spooky = "Spooky (no jump scares)", full = "Full" },
	Notes = {
		"Day 1. A new man stands in the plaza. Height: average. Smile: average. He said 'perfectly average day' 41 times today. I counted. It's not a big number. It's not a small number.",
		"Nobody remembers when he arrived. Everyone says 'he's always been there.' The town records say he arrived every single year.",
		"I measured him. IQ: 100. Exactly. Not 99.9. Not 100.1. Nothing in nature is that exact. Nothing.",
		"When I'm not looking, he's closer. When I look, he's just standing there. Averagely.",
		"He told me: 'Add up everyone in Brainville. Divide by everyone. That's me. Everyone becomes me, eventually.'",
		"The Mean is a place. Beige hallways. Every door opens into the same room. The clock always says 3:00.",
		"Outliers scare him. Things that are one of a kind. If he takes you to The Mean, find three of them. Don't let him make you average.",
		"He isn't evil. He's lonely. Nobody is actually average. So nobody is like him. Nobody.",
	},
}

-- 1.8: pets and the friends meter (friends and family only, never dating)
Content.PetsFriends = {
	PetNames = { dog = "🐶", cat = "🐱", fish = "🐟" },
	PetHeader = "🐾 Adopt a pet (Life Pack, free to adopt)",
	PetButtons = { dog = "🐶 Adopt a dog", cat = "🐱 Adopt a cat", fish = "🐟 Adopt a goldfish", none = "🏠 Pet stays home" },
	Adopted = "%s is your new best buddy!",
	PetHome = "🏠 Your pet is napping at home.",
	NeedPass = "Pets are part of the Life Pack (optional).",
	HighFive = "High-five",
	NoOne = "Nobody to high-five.",
	TooFar = "Get a bit closer first.",
	Wait = "Your hand needs a rest. 🖐",
	GaveFive = "🖐 High-five with %s! (%s)",
	GotFive = "🖐 %s high-fived you! (%s)",
	Levels = { "Friend", "Good friend", "Best friend 🤝" },
}

-- 1.8: Life Pack places hidden in plain houses + the honest pass card
Content.LifePackPlaces = {
	DoorTitle = "🏠 A house",
	DoorDesc = "Knock knock?",
	CardTitle = "🎟 Life Pack (optional)",
	CardText = "This house is a Life Pack place. The Life Pack costs R$ %d and gives you:\n• Grow up from baby to grandparent, with birthdays\n• The Crossroads Ceremony: pick your path at age 8–20\n• 5 places: 🧸 Kindergarten, 🍼 Daycare, 👴 Retirement Home, 🎉 Party Center, 🧸 Toy Store\nThe base game is fully playable without it.",
	Preview = "👀 Free 2-minute preview",
	PreviewOn = "👀 Preview on! You can use all 5 Life Pack places for 2 minutes.",
	PreviewUsed = "You already used your free preview.",
	SeePass = "🎟 See the pass",
}

-- 1.8: Life Pack life stages (kid-safe: friends and family only, never dating)
Content.LifeStages = {
	StageNames = { baby = "Baby", kinder = "Kindergarten kid", kid = "Kid", teen = "Teen", adult = "Adult", grandparent = "Grandparent" },
	NeedPass = "👶 Growing up from baby is part of the Life Pack (optional). The base game is fully playable without it.",
	Born = "👶 Waaah! A new life begins. Grow up, and pick your path at the 🌟 fountain from age 8.",
	BornAgain = "👶 Generation %d! Your new baby inherits 💰 %d from grandma/grandpa.",
	Birthday = "🎂 Happy birthday! You're %d!",
	NewStage = "%s You're a %s now!",
	TooYoung = "🚪 Too little for the big doors! Pick your path at the 🌟 Crossroads Ceremony (fountain) from age %d. (You're %d.)",
	CrossroadsOpen = "🌟 You're 8! The Crossroads Ceremony at the fountain is open: pick Lose or Gain whenever you're ready (until 20).",
	CrossroadsLast = "🌟 Time to choose! Visit the Crossroads Ceremony at the fountain.",
	AlreadyChose = "You already picked your path.",
	ChoseGain = "🌟 You chose to GAIN brain cells. The smart life begins!",
	ChoseLose = "🌟 You chose to LOSE brain cells. The silly life begins!",
	Legacy = "🌅 What a life! You can retire now: Settings → 👶 Start a new life. Your next baby inherits 💰 %d.",
	CeremonyAction = "Crossroads",
	CeremonyObject = "🌟 Crossroads Ceremony",
	CeremonyNotYou = "🌟 This ceremony is for Life Pack kids picking their path.",
	CeremonyTitle = "🌟 The Crossroads Ceremony",
	CeremonyText = "You're %d. Which way will your life go?",
	CeremonyWait = "You're %d. Come back at age %d!",
	PickGain = "🧠 GAIN: get smarter",
	PickLose = "🥴 LOSE: get sillier",
	NotNow = "Not yet",
	StartLife = "👶 Start a new life (Life Pack)",
	StartLifeConfirm = "Start over as a baby? Your path and brain cells reset (badges, coins and passes stay).",
	StartLifeYes = "👶 Yes, start a new life",
	Pause = "⏸ Pause aging",
	AgeChip = "%s Age %d",
}

-- 1.8: free new places on the west side (Slime Shop, Trampoline Park, Fortune Teller)
-- 1.8.6: the redesigned staff panel (docs/admin_panel_mockup.png)
Content.AdminUI = {
	Brand = "🧠 Brain",
	BrandAccent = "Admin",
	Tabs = { Players = "👥 Players", Server = "🖥 Server", Game = "🎮 Game", Fun = "🎉 Fun", Testing = "🧪 Testing", Logs = "📜 Logs", Settings = "⚙️ Settings" },
	Search = "🔎 Search players or commands…",
	QuickActions = "%s · QUICK ACTIONS",
	PickPlayer = "Tap a player on the left",
	Nobody = "Nobody",
	Value = "Value (number, reason, text…)",
	You = "You",
	PlayersHere = "%d players here",
	ConfirmTitle = "%s %s?",
	ConfirmBody = "Are you sure? This affects real players.",
	Cancel = "Cancel",
	Confirm = "Yes, do it",
	NoLogs = "No staff actions yet.",
	LogsLocked = "Head Moderator or Owner only.",
	Version = "Game version %s",
	StaffOnly = "Staff only.",
	Empty = "Nothing here for your rank.",
}

-- 1.8.5: ⚡ Quick Play quiz
-- 1.8.8: the stress freeze always ends by itself now
-- 1.8.9: Settings → Reset my progress
Content.ResetProgress = {
	Button = "⚠️ Reset my progress",
	Title = "⚠️ Reset my progress",
	Warning = "This resets your brain cells, path, coins, job and items, and you start fresh. Your Roblox badges and anything bought with Robux stay. You can do this once a day.",
	Hold = "Hold for %d s to reset",
	Holding = "Keep holding… %d",
	Kick = "Your progress was reset. Rejoin to start fresh! 🧠",
	Cooldown = "You can reset once a day. Try again tomorrow.",
	Failed = "Reset failed (save problem). Nothing was changed.",
}

Content.StressFreeze = {
	Frozen = "😵 Too stressed! You're slowed down for %d s. A habit (coffee, nap, pigeons) calms you faster.",
	Calm = "😌 You feel calm again.",
}
-- 1.8.8: the movement watchdog (frees you if something left you stuck)
Content.Watchdog = {
	Freed = "🦶 You looked stuck, so we freed you!",
}

Content.QuickPlay = {
	Button = "Quick Play",
	Title = "⚡ Quick Play",
	IntroGain = "Answer %d quick questions. Every right answer = more brain cells! 🧠",
	IntroLose = "Answer %d quick questions. Pick the DUMBEST answer to lose brain cells! 🤪",
	Progress = "Question %d of %d",
	Win = "✅ Nice!",
	Miss = "❌ Not that one.",
	TimeUp = "⏰ Too slow!",
	Done = "🎉 %d of %d! Brain cells changed.",
	DoneZero = "😅 0 of %d this time. Try again soon!",
	Again = "⚡ Play again",
	PickDoor = "Pick a door first! 🚪",
	Animal = "🐾 Animals can't read questions… yet.",
	Cooldown = "⏳ Next Quick Play in %d s.",
	TooFast = "Read the question first! 👀",
}

Content.Fun = {
	PickPath = "Pick a door first: Lose or Gain.",
	GoThere = "Walk up to the counter first.",
	Wait = "Give it %d s.",
	OddsTitle = "🎲 Exact odds (free, nothing to buy):",
	Odds = { silly = "🤪 Silly fortune: %d%%", wise = "🦉 Wise fortune: %d%%", weird = "🌀 Weird fortune: %d%%" },
	OddsEffect = "Lose path: silly fortunes cost a few cells. Gain path: wise ones give a few.",
	slime = {
		Title = "🫧 Slime Shop",
		Sign = "🫧 SLIME SHOP",
		Desc = "Make the slimiest slime",
		Lose = "🫧 Make the SLIMIEST slime",
		Gain = "🔬 Learn the science of slime",
		LoseDone = { "🫧 SPLORCH. Your slime is perfect. Your brain is sticky.", "🫧 You mixed glitter, glue and… cereal? Brain cells slide away.", "🫧 It's so slimy it ate a brain cell." },
		GainDone = { "🔬 Slime is a polymer: long sticky chains. Neat! Brain cells up.", "🔬 More glue = stretchier. You made a graph about it. Brain cells up." },
	},
	trampoline = {
		Title = "🤸 Trampoline Park",
		Sign = "🤸 TRAMPOLINE PARK",
		Desc = "Bounce!",
		Lose = "🤸 BOUNCE as high as you can",
		Gain = "🏃 Do a proper workout",
		LoseDone = { "🤸 BOING! Brain cells fly out of your ears!", "🤸 Triple flip! (Your brain stayed on the ground.)", "🤸 You bounced so hard you forgot your name for a second." },
		GainDone = { "🏃 Good workout! Your head feels clear. Stress down.", "🏃 Jumping jacks done right. Stress down." },
	},
	-- 1.8 Life Pack places (kids' party hall, not a club: cake, balloons, bouncy castle)
	party = {
		Title = "🎉 Party Center",
		Lose = "🎂 Face-plant into the birthday cake",
		Gain = "🎈 Play party games and chill",
		LoseDone = { "🎂 SPLAT! Cake everywhere. Brain cells too.", "🕺 You won the silly dance-off. Your brain lost.", "🎈 You stuck a balloon to your head. It's stuck. So are you." },
		GainDone = { "🎈 Party games with friends! Stress melts away.", "🍰 Cake, music and laughs. You feel great. Stress way down." },
	},
	kindergarten = {
		Title = "🧸 Kindergarten",
		Lose = "🖍 Eat a crayon (the red one)",
		Gain = "🧱 Build the tallest block tower",
		LoseDone = { "🖍 Tastes like… red. Brain cells drop.", "🎨 You finger-painted your own face." },
		GainDone = { "🧱 Your tower is 12 blocks tall! Balance and planning. Brain cells up.", "📖 Show-and-tell: you explained how magnets work!" },
	},
	daycare = {
		Title = "🍼 Daycare",
		Lose = "🍼 Drool on the toys",
		Gain = "😴 Take a cosy nap",
		LoseDone = { "🍼 Blubblub. That's all you can say now.", "🧦 You tried to eat a sock." },
		GainDone = { "😴 Best nap ever. Stress down.", "🧸 Cuddled the big teddy. So calm. Stress down." },
	},
	retirement = {
		Title = "👴 Retirement Home",
		Lose = "👓 Look for your glasses (they're on your head)",
		Gain = "🧩 Grandpa's wisdom quiz and bingo",
		LoseDone = { "👓 \"Where are my glasses?\" (on your head). Brain cells wander off.", "🧶 You knitted a sock… for a snake." },
		GainDone = { "🧩 Bingo AND you knew every capital city. Brain cells up!", "📚 Grandma's long story had a great lesson in it. Brain cells up." },
	},
	toystore = {
		Title = "🧸 Toy Store",
		Lose = "🔊 Squeeze every squeaky toy",
		Gain = "🧩 Solve the puzzle cube",
		LoseDone = { "🔊 SQUEAK SQUEAK SQUEAK. Brain cells squeaked out.", "🪀 The yo-yo won. You lost." },
		GainDone = { "🧩 Puzzle cube solved! Brain cells up.", "♟ You beat the toy chess robot. Brain cells up." },
	},
	fortune = {
		Title = "🔮 Fortune Teller",
		Sign = "🔮 FORTUNE TELLER",
		Desc = "Free fortunes (exact odds shown)",
		Button = "🔮 Tell my fortune (free)",
		silly = { "🔮 \"You will step on a LEGO. Twice.\"", "🔮 \"Your next sandwich will be… a sandwich.\"", "🔮 \"A pigeon will judge you today.\"" },
		wise = { "🔮 \"Read one page a day and you'll read a book a year.\"", "🔮 \"Asking questions is how smart people got smart.\"", "🔮 \"Sleep is brain food.\"" },
		weird = { "🔮 \"…the crystal ball just shows a perfectly average man.\"", "🔮 \"The ball is buffering. 🌀\"" },
	},
}

-- 1.8 (Life Pack plan step 1): the free Phone Shop. Parody phones only (original names, no real brands or logos).
Content.PhoneShop = {
	Title = "📱 Phone Shop",
	Sign = "📱 PHONE SHOP",
	StationTitle = "📱 Phone Shop",
	StationDesc = "Phones and the case maker",
	ScamTitle = "👍 Totally Real Phones",
	ScamDesc = "100% real. Trust.",
	Phones = {
		{ key = "brick", name = "📟 BrickFone 1", price = 0, desc = "Free. It can call. That's it." },
		{ key = "flip", name = "📞 FlipFlop Z", price = 40, desc = "Flips open. Makes a satisfying clack." },
		{ key = "noodle", name = "🍜 Noodle 5", price = 120, desc = "Bendy screen. Please don't bend it." },
		{ key = "brainphone", name = "🧠 BrainPhone Mini", price = 250, desc = "Small, smart and calm." },
		{ key = "ibrainz", name = "🌀 iBrainz 99 Ultra Pro Max Fold", price = 600, desc = "Folds three times. Nobody knows why." },
	},
	Colors = {
		{ key = "grey", name = "⬜ Plain grey", rot = 0 },
		{ key = "blue", name = "🟦 Calm blue", rot = 0 },
		{ key = "green", name = "🟩 Leafy green", rot = 0 },
		{ key = "pink", name = "🩷 Hot pink", rot = 1 },
		{ key = "neon", name = "🌈 Flashing neon", rot = 3 },
	},
	Stickers = {
		{ key = "duck", name = "🦆 Rubber duck", rot = 1 },
		{ key = "eyes", name = "👀 Googly eyes", rot = 2 },
		{ key = "skull", name = "🌈💀 Rainbow skull", rot = 2 },
		{ key = "sixseven", name = "6️⃣7️⃣ \"67\" sticker", rot = 3 },
		{ key = "cat", name = "✨🐱 Sparkle cat", rot = 2 },
		{ key = "leaf", name = "🍃 One small leaf", rot = 0 },
	},
	Using = "✅ Using",
	BuyFor = "Buy • 💰 %d",
	Free = "Use (free)",
	Use = "Use this one",
	CaseHeader = "🎨 Case maker (free)",
	ColorHeader = "Colour:",
	StickerHeader = "Stickers (up to %d):",
	Meter = "🧠 Brainrot meter: %d / %d",
	MeterInfo = "Louder, brighter, dumber case = more brain cells lost when you show it off (Lose path). A calm case lowers stress (Gain path).",
	Show = "📸 Show off my case",
	Bought = "📱 Now using: %s",
	TooPoor = "You need 💰 %d for that.",
	Unknown = "That phone doesn't exist.",
	PickPath = "Pick a door first: Lose or Gain.",
	Cooldown = "Wait a moment first.",
	ShowBoring = "😐 Nobody looks. It's a very normal case.",
	ShowLose = "📸 EVERYONE LOOKS. Your case screams (Brainrot meter %d). Brain cells fly out!",
	ShowCalm = "😌 A calm, simple case. You feel relaxed. Stress down!",
	ShowTooLoud = "😵 Your case is way too loud to be relaxing. (Try a calm one.)",
	ScamPitch = "\"iBrainz 99 MEGA. Brand new. Totally real. No box, no charger, no questions!!! 👍👍\"",
	ScamPrice = "Price: 💰 %d",
	ScamEffect = "What it does: the seller won't say.",
	ScamBuy = "Buy it • 💰 %d",
	ScamUse = "📱 Use my iBrainz 99 MEGA",
	ScamBought = "📦 You got… a calculator with a sticker on it. 🤡",
	ScamAlready = "You already own one. (Sadly.)",
	ScamNone = "You don't have that phone.",
	ScamUsed = {
		"🔔🔔🔔 47 notifications: \"YOU WON A FREE BRAIN!\" (you didn't)",
		"📱 The 'camera app' is a drawing of a camera.",
		"🔢 You try to call someone. It says 58008.",
		"📶 No signal. Ever. It's a calculator.",
	},
	ScamGainNo = "🧠 You notice the red flags. You don't buy it.",
	RedFlagsTitle = "🚩 Red flags you spotted:",
	RedFlags = {
		"🚩 The logo is spelled \"iBrianz\".",
		"🚩 \"No refunds!!!\" in three colours.",
		"🚩 The price is way too good to be true.",
		"🚩 The seller is wearing sunglasses at night.",
	},
	Report = "🚓 Report the scammer",
	Reported = "🚓 The police thank you! Spotting scams is smart. Brain cells up!",
	ReportAlready = "You already reported them. The police are on it.",
	ReportGainOnly = "Only smart players spot this scam.",
}

-- 1.8.1 UI review: the "More" button that holds the extra activities
-- 1.9: the phone is the main menu (Items app, Help app, chips under the counter, Settings tabs)
Content.Phone19 = {
	Apps = {
		items = { icon = "🎒", name = "Items" },
		badges = { icon = "🏅", name = "Badges" },
		help = { icon = "❓", name = "Help" },
		gate = { icon = "🚧", name = "Gate" },
		coffee = { icon = "☕", name = "Coffee" },
		nap = { icon = "😴", name = "Nap" },
		pigeons = { icon = "🐦", name = "Pigeons" },
		events = { icon = "💌", name = "Invites" },
		genius = { icon = "🌟", name = "Genius" },
		home = { icon = "🏠", name = "Home" }, -- 1.9.1
		town = { icon = "🏙", name = "Town" }, -- 1.9.1 town board
	},
	ItemsTitle = "🎒 Items",
	ItemsGadgets = "Gadgets & secret inventions",
	ItemsStuff = "Your stuff",
	ItemsLocked = "Still to invent",
	ItemsEmpty = "Nothing here yet! Gadgets and secret inventions you get will show up here.",
	ItemsLose = "Your pockets: 1 sticky sweet, 0 thoughts. (Gadgets are for the Gain path.)",
	ItemsPhone = "📱 Phone: %s",
	ItemsCoins = "💰 Coins: %d",
	ItemsPerk = "⭐ %s",
	HelpTitle = "❓ Help",
	HelpLines = {
		"📱 The phone is your main menu: every app lives here.",
		"⚡ Quick Play gives fast points any time.",
		"🆘 Stuck? Tap the SOS button on the screen.",
		"🧠 The top-left card shows your brain cells, IQ and job.",
	},
	HelpTutorial = "📖 Replay the tutorial",
	HelpWhatsNew = "📋 What's new",
	ChipComeback = "💀➡️🧠 Comeback",
	ChipNoSave = "⚠️ Not saving",
	ChipJob = "💼 %s",
	ChipStress = "😰 Stressed!",
}

Content.SettingsTabs = {
	Title = "⚙️ Settings",
	Names = {
		sound = "🔊 Sound",
		graphics = "🎨 Graphics",
		controls = "🎮 Controls & Screen",
		notifications = "🔔 Notifications",
		gameplay = "🧩 Gameplay",
		info = "ℹ️ Info",
		help = "❓ Help",
		danger = "⚠️ Danger zone",
	},
	Music = "🎵 Music volume",
	Sfx = "🔊 Sound effects",
	DangerInfo = "Careful: these can't be undone easily.",
	ControlsInfo = "Controller: Y menu, Select = staff panel, B close, X use prompts. Keyboard: M menu, P staff panel, E use prompts.",
	Feedback = "💬 Send feedback",
	FeedbackThanks = "💬 Thanks! Your feedback window is open.",
	FeedbackFallback = "💬 Feedback isn't available here right now. Tell us in the group page instead. Thank you!",
}

-- 1.9 Gain path redesign: job minigames (no maths, phone-friendly)
Content.Minigames = {
	Start = "START",
	Time = "⏱ %ds",
	Score = "⭐ %d",
	Goal = "Goal: %d",
	ResultGood = "✅ Great shift! ⭐ %d",
	ResultMeh = "😅 Not quite. ⭐ %d (goal %d)",
	Pay = "💰 +%d coins",
	Again = "🔁 Another shift",
	Break = "Take a break",
	TooFast = "⛔ That shift didn't count (timing looked off).",
	Games = {
		scan = { title = "🛒 Scan & bag", how = "Tap the item to scan it, then pick the right bag. Fragile things go in the soft bag!" },
		colors = { title = "🔬 Mix the colour", how = "Pour red, yellow and blue to match the target colour, then tap DONE." },
		pipes = { title = "🔧 Pipe puzzle", how = "Tap pipes to turn them so the water reaches the town on the right." },
		files = { title = "🗂 File sorting", how = "Put each file in the folder with the same colour. Quick!" },
		grade = { title = "📝 Grade papers", how = "Is the answer right or silly? Tap ✅ or ❌ (or swipe)." },
		xray = { title = "🩻 X-ray spot", how = "Find the thing that shouldn't be in the X-ray!" },
		order = { title = "🍔 Order up", how = "Build the burger on the ticket, from the bottom up." },
		dash = { title = "🚐 Hoppr dash", how = "Drive to the parcel, pick it up, then drop it at the house." },
		dishes = { title = "🍽 Dish duty", how = "Tap a dirty plate a few times to scrub it until it sparkles. Clean plates go on the rack by themselves." },
		serve = { title = "🧾 Serve the tables", how = "A table shows what it ordered. Tap that dish on the tray, then tap the table. Quick service = happy customers!" },
	},
	-- 1.9.1 restaurant: dish duty and serving
	ScrubHint = "Tap the dirty plates to scrub them!",
	Dirty = { "🍝 Saucy plate", "🍳 Eggy pan", "🥣 Sticky bowl", "🍽 Crumby plate" },
	Scrubbing = "🧽 Scrub!",
	Clean = "✨ Clean!",
	Rack = "Rack:",
	DefaultMenu = { "🍕", "🍔", "🥗", "🥤" },
	Holding = "On your tray: %s",
	TableN = "Table %d",
	Served = "😋 Thanks!",
	-- scan & bag
	Fragile = { "🥚", "🍞", "🍓", "🍌", "🧁" },
	Heavy = { "🥫", "🍉", "🥛", "🥔", "🧃" },
	SoftBag = "🧺 Soft bag",
	StrongBag = "🛍 Strong bag",
	TapToScan = "Tap to scan!",
	-- colours
	Red = "🔴 Red",
	Yellow = "🟡 Yellow",
	Blue = "🔵 Blue",
	Done = "✅ DONE",
	Empty = "🗑 Empty",
	Target = "Target",
	YourMix = "Your mix",
	-- files
	FileColors = { "Red", "Blue", "Green", "Yellow" },
	FileNames = { "Invoices", "Lunch menu", "Cat photos", "Memos", "Reports", "Plans", "Receipts", "Letters" },
	-- grade (right or silly? kid-safe, no maths)
	GradeRight = {
		"Fish live in water.", "The sun is very hot.", "Cats say meow.", "Ice is frozen water.", "Bees make honey.",
		"A week has seven days.", "Plants need light.", "Snow is cold.", "Birds have feathers.", "The Moon goes around the Earth.",
		"Frogs can jump.", "Rain falls from clouds.",
	},
	GradeSilly = {
		"Fish climb trees for fun.", "The Moon is made of cheese.", "Cows say quack.", "Snow is hot.", "Penguins live in the desert.",
		"Bananas grow on cars.", "Spiders have two legs.", "The sun comes out at midnight.", "Clouds are made of cotton candy.", "Dogs lay eggs.",
		"Trees walk at night.", "Rain falls upwards.",
	},
	Right = "✅ Right",
	Silly = "❌ Silly",
	-- x-ray
	Bone = "🦴",
	Odd = { "🧸", "🔑", "🧩", "🎲", "⚽", "🖍" },
	-- order up
	Ingredients = { "🍞", "🥩", "🧀", "🥬", "🍅" },
	Ticket = "Ticket:",
	Plate = "Plate:",
	-- dash
	Van = "🚐",
	Parcel = "📦",
	House = "🏠",
	Up = "⬆️",
	Down = "⬇️",
	Left = "⬅️",
	Right2 = "➡️",
}

-- 1.9 Big life events. Kid-safe: weddings are a FRIEND's party; the player never dates or marries.
-- Each choice has smart = true/false: smart choices help on the Gain path, silly ones on the Lose path.
Content.LifeEvents = {
	Invite = "💌 You're invited: %s! Open 📱 Invites when you're ready.",
	AppTitle = "💌 Invites",
	NoInvite = "No invites right now. Big life moments arrive every so often!",
	Album = "📸 Photo album",
	AlbumEmpty = "No photos yet.",
	Accept = "✅ Go now",
	Later = "Later",
	Step = "Part %d of %d",
	Done = "📸 %s: a photo was added to your album! +%d coins",
	Continue = "▶ Continue",
	Events = {
		wedding = {
			name = "a friend's wedding", icon = "💒",
			intro = { Gain = "Your friend Sam is getting married in the park! There are flowers everywhere. 💐", Lose = "Your friend Sam's wedding is today. You put on pyjamas. On purpose. 🩳" },
			steps = {
				{ text = "Pick a gift for Sam:", options = { { "📚 A book of jokes", true }, { "🍳 A shiny toaster", true }, { "🦆 A rubber duck in a tiny suit", false } } },
				{ text = "Time for your speech!", options = { { "💛 \"Sam is the kindest person I know.\"", true }, { "😂 \"Sam once ate soup with a fork. Legend.\"", false } } },
				{ text = "Here comes the bouquet!", options = { { "🙌 Jump and catch it", true }, { "🤸 Do a cartwheel instead", false } } },
			},
			outro = { Gain = "What a lovely day. Sam hugs you: \"Best speech ever!\" 🥹", Lose = "Everyone is still talking about your pyjamas. Iconic. 🩳" },
		},
		grandma = {
			name = "Grandma's 80th birthday", icon = "🎂",
			intro = { Gain = "Grandma turns 80! The family house is full of balloons. 🎈", Lose = "Grandma turns 80! You brought a balloon. It's a fish. 🐟" },
			steps = {
				{ text = "Help build the birthday treat, just like the ticket!", game = "order" },
				{ text = "Choose a present:", options = { { "🧣 A cozy scarf you picked yourself", true }, { "🖼 A frame with a family photo", true }, { "📱 A phone with 400 apps", false } } },
				{ text = "Family photo! Strike a pose:", options = { { "😊 Big smile", true }, { "🤪 Silly face", false } } },
			},
			outro = { Gain = "Grandma: \"Best birthday in 80 years!\" 🎂", Lose = "Grandma laughed so hard at your face she snorted. Win. 🤪" },
		},
		graduation = {
			name = "Graduation day", icon = "🎓",
			intro = { Gain = "Graduation day! Your name is on the list. 🎓", Lose = "Graduation day! You plan to live-stream the whole thing. 📱" },
			steps = {
				{ text = "Your name is called. Walk the stage:", options = { { "🚶 Walk proudly and shake hands", true }, { "📱 Film yourself walking (and trip)", false } } },
				{ text = "Caps in the air!", options = { { "🎓 Throw it high!", true }, { "🧢 Throw it at the stage lights", false } } },
				{ text = "Say a few words:", options = { { "🌟 \"Never stop learning!\"", true }, { "💤 \"Uhh… thanks for the snacks.\"", false } } },
			},
			outro = { Gain = "You did it! The crowd cheers your name. 🎉", Lose = "Your stream got 3 views. One was Grandma. 📱" },
		},
		moving = {
			name = "moving house", icon = "🏠",
			intro = { Gain = "You're moving to a new house! Boxes everywhere. 📦", Lose = "You're moving! You packed the fridge. Still plugged in. 🔌" },
			steps = {
				{ text = "Pack the boxes: match the colours!", game = "files" },
				{ text = "The moving truck is ready:", options = { { "🚚 Drive carefully", true }, { "🏎 Race it down the hill", false } } },
				{ text = "Decorate your new room:", options = { { "🪴 Plants and a bookshelf", true }, { "🍕 Pizza boxes as furniture", false } } },
			},
			outro = { Gain = "Your new room looks amazing. Home sweet home. 🏠", Lose = "Your room is 90% pizza boxes. You love it. 🍕" },
		},
		pet = {
			name = "a runaway pet", icon = "🐶",
			intro = { Gain = "Oh no! Your pet ran away! Posters are up all over town. 🐾", Lose = "Your pet ran away. Honestly? Fair. Let's find it anyway. 🐾" },
			steps = {
				{ text = "Follow the clues around town!", game = "dash", title = "🐾 Find your pet", how = "Follow the paw prints to the clue, grab it, then run to the spot where your pet was seen." },
				{ text = "You hear barking behind the bakery:", options = { { "🦴 Shake the treat bag", true }, { "📢 Yell \"COME BACK, POTATO!\"", false } } },
				{ text = "Found them!", options = { { "🤗 Big hug", true }, { "🤳 Selfie first, hug later", false } } },
			},
			outro = { Gain = "Your pet wags all the way home. 🐶💛", Lose = "Your pet is home. It still judges you. 🐶" },
		},
		blackout = {
			name = "a city-wide blackout", icon = "🌩",
			intro = { Gain = "The whole town went dark! Neighbours need help. 🔦", Lose = "The whole town went dark! Your phone is at 2%. 😱" },
			steps = {
				{ text = "What do you do first?", options = { { "🔦 Bring torches to the neighbours", true }, { "🛋 Hide under a blanket", false } } },
				{ text = "Help fix the power lines!", game = "pipes" },
				{ text = "Waiting for the lights:", options = { { "🕯 Tell stories by candlelight", true }, { "👻 Get scared of your own shadow", false } } },
			},
			outro = { Gain = "The lights come back on and the street cheers for you! 💡", Lose = "The lights are back. The shadow was a coat. 👻" },
		},
		-- 1.9.1 more big life events (big ideas #7)
		talent = {
			name = "the school talent show", icon = "🎤",
			intro = { Gain = "The talent show is tonight! The hall is packed. 🎭", Lose = "The talent show is tonight! Your act is \"standing very still\". 🗿" },
			steps = {
				{ text = "Pick your act:", options = { { "🎹 Play a song you practised", true }, { "🪄 A magic trick you learned", true }, { "🥄 Balance 9 spoons on your face", false } } },
				{ text = "Your act! Hit the notes on time.", game = "pattern", title = "🎤 Showtime!", how = "Watch the pattern of notes, then pick what comes next. Keep the rhythm!" },
				{ text = "The crowd is clapping:", options = { { "🙇 Take a bow and thank them", true }, { "🎤 Drop the mic. It breaks.", false } } },
			},
			outro = { Gain = "Standing ovation! Even the judges cheered. 🌟", Lose = "Nobody knew what they watched. They loved it anyway. 🗿" },
		},
		sciencefair = {
			name = "the town science fair", icon = "🧪",
			intro = { Gain = "The science fair! Your volcano is ready. Probably. 🌋", Lose = "The science fair! You brought a potato. With googly eyes. 🥔" },
			steps = {
				{ text = "Build it before the judges arrive!", game = "colors", title = "🧪 Mix the lava", how = "Mix the colours to match the lava colour the judges want, then tap DONE." },
				{ text = "A judge asks how it works:", options = { { "🔬 Explain it step by step", true }, { "🥔 \"The potato knows.\"", false } } },
				{ text = "Your volcano starts to rumble:", options = { { "🥽 Goggles on, step back!", true }, { "😮 Lean in closer", false } } },
			},
			outro = { Gain = "🥇 First prize! Your volcano is on the front page. 🌋", Lose = "The potato won \"Most Mysterious\". It is a real prize now. 🥔" },
		},
		festival = {
			name = "the town festival", icon = "🎡",
			intro = { Gain = "The town festival! Rides, lights and the smell of candy floss. 🎡", Lose = "The town festival! You ate candy floss for dinner. Twice. 🍭" },
			steps = {
				{ text = "First stop:", options = { { "🎡 The big wheel, see the whole town", true }, { "🎪 The mirror maze (you get lost)", false } } },
				{ text = "Help at the lemonade stand!", game = "lemonade", title = "🍋 Festival stand", how = "Pick the right price and amount so the festival crowd buys your lemonade!" },
				{ text = "Fireworks time!", options = { { "🎆 Watch from the hill with friends", true }, { "🙈 Cover your ears and shout", false } } },
			},
			outro = { Gain = "The best night of the year. The whole town sparkles. 🎆", Lose = "You won a goldfish and named it Brain. It is smarter than you. 🐠" },
		},
		kitten = {
			name = "a kitten stuck in a tree", icon = "🐱",
			intro = { Gain = "Mew! A kitten is stuck high up in the park tree. 🌳", Lose = "Mew! A kitten is stuck in a tree. You also climb up. Now there are two. 🌳" },
			steps = {
				{ text = "How do you help?", options = { { "🚒 Call the fire brigade", true }, { "🪜 Borrow a ladder from a neighbour", true }, { "🐦 Meow at it until it learns to fly", false } } },
				{ text = "Guide the ladder truck through town!", game = "dash", title = "🚒 To the park!", how = "Drive to the ladder, pick it up, then race to the park tree." },
				{ text = "The kitten is safe! Now:", options = { { "🥛 Find its owner with the collar tag", true }, { "👑 Make it mayor of the park", false } } },
			},
			outro = { Gain = "The owner hugs the kitten and thanks you. Hero! 🐱💛", Lose = "The kitten is mayor now. It has already done better than you. 🐱👑" },
		},
		firstday = {
			name = "your first day at a new job", icon = "💼",
			intro = { Gain = "First day at the new job! Your hands are a little sweaty. Deep breath. 😅", Lose = "First day at… wait, you got a job? Nobody is more surprised than you. 😅" },
			steps = {
				{ text = "You walk in. Everyone looks up:", options = { { "👋 Smile and say hi to everyone", true }, { "🫣 Hide behind a pot plant", false } } },
				{ text = "Your boss shows you the ropes. Try it!", game = "files", title = "💼 Learning the ropes", how = "Sort the files into the folder with the same colour. Your boss is watching… kindly!" },
				{ text = "Lunch break! The new coworkers wave you over:", options = { { "🥪 Sit with them and ask about their day", true }, { "🍜 Eat noodles in the supply cupboard", false } } },
			},
			outro = { Gain = "Your boss: \"Great first day!\" You're going to like it here. 💼", Lose = "You survived the first day. The pot plant is your best friend now. 🪴" },
		},
	},
}

-- 1.9 Genius Crossroads: five genius branches, each with jobs, a signature minigame and a 3-chapter story
Content.Genius = {
	Title = "🌟 Genius Crossroads",
	Intro = "You've reached the top! Now choose what kind of genius you want to become. (You can switch later and keep your brain cells.)",
	Locked = "🔒 The Crossroads opens at the top of a career ladder, or at IQ %d.",
	Pick = "Become a %s",
	Picked = "🌟 You are now a %s! Open 🌟 Genius in your phone.",
	Switch = "🔀 Switch genius branch",
	Jobs = "💼 Genius jobs",
	Work = "Work as %s",
	Story = "📖 Story",
	Chapter = "Chapter %d of %d",
	Play = "▶ Play this chapter",
	ChapterDone = "📖 Chapter done! +brain cells",
	StoryDone = "🏆 You finished the %s story! +%d coins",
	AllDone = "🏆 Story complete! You can still work your genius jobs.",
	NotGain = "Genius branches are for the Gain path.",
	Branches = {
		math = {
			icon = "🔢", name = "Math genius", jobs = { "Codebreaker", "Bank analyst" },
			blurb = "Patterns everywhere. Crack the town vault!",
			story = {
				"The town vault is stuck, and the code is hidden in a pattern on the door. Can you spot it?",
				"The vault has a second lock: a moving pattern of lights. Keep your eyes sharp!",
				"The last lock! Crack it and the town's lost treasure (a giant golden calculator) is free.",
			},
		},
		physics = {
			icon = "⚛️", name = "Physics genius", jobs = { "Rocket engineer", "Inventor" },
			blurb = "Angles, power, liftoff. Build the Moon rocket!",
			story = {
				"Test launch! Hit the targets to prove your rocket math is right.",
				"Windy day at the launch pad. Find the perfect angle and power.",
				"Launch day! Land the rocket's practice capsule on the target and the Moon trip is GO.",
			},
		},
		coding = {
			icon = "💻", name = "Coding genius", jobs = { "Game dev", "Robot builder" },
			blurb = "Code blocks and robots. Fix the town's buggy AI!",
			story = {
				"The town's helper robot got a bug and keeps walking into walls. Guide it home!",
				"The bug spread to the delivery bots. Write their routes, block by block.",
				"The main AI is confused. Fix its last robot and the whole town runs smoothly again.",
			},
		},
		business = {
			icon = "💼", name = "Business genius", jobs = { "Shop owner", "CEO" },
			blurb = "Price, stock and weather. Turn a lemonade stand into a chain!",
			story = {
				"Your first lemonade stand! Watch the weather and price it right.",
				"A second stand opens across town. Can you keep both busy?",
				"Investors are watching. Have a great week and your stand becomes a chain!",
			},
		},
		chess = {
			icon = "♟️", name = "Chess genius", jobs = { "Chess coach", "Strategist" },
			blurb = "Mate in one! Win the Grand Brain Tournament.",
			story = {
				"Round 1 of the Grand Brain Tournament. Find the winning move!",
				"The semi-final. Your opponent is sneaky, but checkmate is checkmate.",
				"THE FINAL. The whole town is watching. One move to become champion!",
			},
		},
	},
	-- chess puzzles (mate in 1, white to move). Squares are "a1".."h8".
	-- pieces: K Q R B N P = white, k q r b n p = black. solution = { from, to }.
	ChessPuzzles = {
		{ pieces = { g1 = "K", a1 = "R", g8 = "k", f7 = "p", g7 = "p", h7 = "p" }, solution = { "a1", "a8" } },
		{ pieces = { g1 = "K", d1 = "Q", h8 = "k", g7 = "p", h7 = "p" }, solution = { "d1", "d8" } },
		{ pieces = { e1 = "K", h1 = "R", e8 = "k", d7 = "p", e7 = "p", f7 = "p" }, solution = { "h1", "h8" } },
		{ pieces = { e1 = "K", c1 = "R", a8 = "k", a7 = "p", b7 = "p" }, solution = { "c1", "c8" } },
		{ pieces = { g1 = "K", e5 = "N", h8 = "k", g8 = "r", g7 = "p", h7 = "p" }, solution = { "e5", "f7" } },
		{ pieces = { g1 = "K", e4 = "Q", h8 = "k", g7 = "p", h7 = "p" }, solution = { "e4", "e8" } },
	},
	PieceNames = { K = "K", Q = "Q", R = "R", B = "B", N = "N", P = "P" },
	ChessHint = "White to move. Tap a white piece, then the square for checkmate!",
	-- math patterns (shapes, no sums)
	Shapes = { "🔴", "🔵", "🟢", "🟡", "🟣", "⭐" },
	WhatNext = "What comes next?",
	-- physics launch
	Angle = "📐 Angle: %d°",
	Power = "💪 Power: %d",
	Launch = "🚀 LAUNCH",
	TargetAt = "🎯 Target",
	Landed = "Landed here",
	-- coding robot
	Run = "▶ RUN",
	Clear = "🗑 Clear",
	Robot = "🤖",
	Flag = "🏁",
	Wall = "🧱",
	-- lemonade
	Weather = { "☀️ Sunny", "⛅ Cloudy", "🌧 Rainy" },
	Prices = { "Cheap", "Fair", "Fancy" },
	Cups = { 10, 20, 30 },
	CupsLabel = "%d cups",
	OpenStand = "🍋 Open the stand",
	DayResult = "Sold %d cups, profit %d",
}
Content.Minigames.Games.pattern = { title = "🔢 Pattern lock", how = "Look at the pattern and tap what comes next. No sums, just eyes!" }
Content.Minigames.Games.launch = { title = "🚀 Launch!", how = "Pick an angle and power, then launch. Land on the target!" }
Content.Minigames.Games.robot = { title = "🤖 Code the robot", how = "Tap arrow blocks to build a program, then RUN it. Reach the flag, avoid the walls!" }
Content.Minigames.Games.lemonade = { title = "🍋 Lemonade stand", how = "Check the weather, pick a price and how many cups to make. Have a good day!" }
Content.Minigames.Games.mate = { title = "♟️ Mate in one", how = "White to move: find the checkmate!" }

-- 1.9 Cutscenes
Content.Cutscenes = {
	Skip = "Skip ⏭",
	Intro = {
		"Welcome to Brainville… 🧠",
		"A town that changes with your brain.",
		"Two doors. One choice. Get smarter… or get dumber?",
	},
}

-- 1.9: the progress path strip under the counter (Gain path)
Content.PathStrip = {
	Steps = { "Job", "Shift", "Promotion", "Next job" },
	PickJob = "💼 Pick a job",
	Work = "🛠 Work a shift",
	Promo = "⭐ %d/%d XP to promotion",
	PromoIQ = "🧠 Reach IQ %d to get promoted",
	Top = "🏆 Top of the ladder!",
	Break = "☕ Take a break first",
	Genius = "🌟 Choose your genius",
	Go = "GO",
}

Content.HudMore = {
	Button = "More",
	Title = "☰ All activities",
}

-- 1.7.3: speedrun timer
Content.Speedrun = {
	Timer = "⏱ %s",
}

-- 1.7.2: plaza leaderboards (display names only)
Content.Boards = {
	WeeklyPayTitle = "💼 TOP EARNERS THIS WEEK\n(coins from real work)",
	SpeedrunTitle = "⏱ FASTEST TO IQ 200",
	Coins = "💰 %d",
	Empty = "Nobody yet. Be the first!",
	Resting = "📴 The board is resting. Back soon!",
}

-- 1.7.2: "What do I do now?" (a goal line + an arrow to the next useful place). Short, picture-first lines.
Content.Guide = {
	PickDoor = "🚪 Pick a door: get dumber or get smarter!",
	LifeGrow = "%s Age %d: play and grow up! Your path opens at age 8 (🌟 fountain).",
	LifeCrossroads = "🌟 Go to the Crossroads Ceremony at the fountain and pick your path!",
	Animal = "🐾 Sniff your way to the 🛍 Mall stands!",
	LoseStands = "📰 Go to the 🛍 Brainrot Mall and click some bait!",
	LoseSchool = "🏫 The bell! Get to school!",
	GainLibrary = "📚 Read at the School Library to get smarter!",
	GainJob = "💼 Get a job at the Job Center!",
	GainWork = "⏰ Go to work and clock in (📱 Shifts)!",
	GainTask = "🛠 You're on shift: do a task!",
	GainGate = "🚧 A Skill Gate! Go to the Exam Hall at the University.",
	Near = "You're here! 👇",
	Meters = "%d m",
}

-- 1.7 audit (R3): text that used to live in the services
Content.SocialText = {
	TrickQuestions = {
	{ q = "Pick the WRONG answer: 2 + 2 = ?", options = { "4", "5" }, correct = 2 },
	{ q = "Which is NOT not a fruit?", options = { "Apple", "Chair" }, correct = 1 },
	{ q = "True or false: \"false\" is not true.", options = { "True", "False" }, correct = 1 },
	{ q = "Do NOT pick the answer that isn't 7. What is 3 + 4?", options = { "7", "8" }, correct = 1 },
	{ q = "This time the dumb answer is correct: what color is the sky?", options = { "Blue", "Banana" }, correct = 2 },
	{ q = "Which is the SMALLEST: 0.5, 1/3 or 0.4?", options = { "0.5", "1/3", "0.4" }, correct = 2 },
	{ q = "Pick the answer that is NOT wrong: 10 − 3 = ?", options = { "7", "13" }, correct = 1 },
	{ q = "Reverse question: pick the LONGEST word.", options = { "Cat", "Hippopotamus" }, correct = 2 },
	},
	Speeches = {
	Gain = { "I will build more libraries.", "I promise free tutoring for everyone.", "Science funding for all!" },
	Lose = { "Free microwaves for everyone!!", "I will ban reading. Forever.", "Every day is Bonkadoo Day." },
	},
}

-- 1.7 fix: the free map ride is a slow bus
Content.Bus = {
	Coming = "🚌 The free Brain Bus picks you up in %d s. Stay put! (Hoppr is faster.)",
	Waiting = "🚌 Your bus is on its way… %d s",
	Arrived = "🚌 Ding ding! Bus stop: %s.",
	Missed = "🚌 The bus left: you were busy. Call it again from the map.",
	ToWork = "🚌 Bus to work",
	MapButtonSub = "free bus",
	MapHint = "💗 Lose places  •  💙 Gain places  •  💛 everyone  •  ⚪ you. Tap a pin to call the free 🚌 bus (it takes %d s).",
	Cooldown = "🚌 The next bus comes in %d s.",
}

-- 1.7: map signs and guides
Content.Map = {
	Tower = "🧠 THE BRAIN TOWER",
	Talk = "Talk",
	Gates = {
		{ x = -85, name = "🥴 BRAINROT DISTRICT", guide = "Gate Guide Gus", color = Color3.fromRGB(255, 90, 180), tip = "🥴 This way: Brainrot Mall, Microwave Diner, Wall Alley. Lose-path fun!" },
		{ x = 85, name = "🎓 SMARTY DISTRICT", guide = "Gate Guide Greta", color = Color3.fromRGB(70, 140, 255), tip = "🎓 This way: School, University, Cinema, Café, Hospital, Office, Job Center, Courthouse, Lab." },
	},
	Ends = {
		{ x = -430, z = 0, name = "🌅 West Lookout" },
		{ x = 430, z = 60, name = "🌄 East Lookout" }, -- 1.7.2: beside the road end, off the rocket pad
		{ x = -60, z = -430, name = "🏔 North Lookout" }, -- 1.7.2: beside the odd house, not on top of it
		{ x = 0, z = 430, name = "🌊 South Lookout" },
	},
	Hole = "🕳 dumb shortcut",
	HoleYes = "🕳 Squeeeeze! Only dumb brains fit. Welcome to the Brainrot Mall!",
	HoleNo = "🧠 You're too smart to fit in that hole. (Take Hoppr or the bus.)",
}

-- 1.9.1 room guide: what to do when you walk into a building
Content.RoomGuide = {
	Title = "📍 %s",
	What = "What to do here:",
	Pill = "📍 Where to go",
	Nothing = "Nothing for you here right now. Have a look around!",
	Arrived = "📍 You're here! Press the button to use it.",
	Close = "✕",
	Intros = {
		lose = "Arcade games, shiny shelves and a giant plushie. Click the bait!",
		diner = "Microwave food and a very old fridge. Grab a snack!",
		supermarket = "Aisles of food. Work the till or shake the cereal.",
		gain = "A real classroom. Find your desk and talk to the teacher.",
		university = "The lecture hall and the Skill Gate. Pass it to go further!",
		cinema = "Movies, snacks, and the Debate Show on the stage.",
		cafe = "Coffee, a cozy couch and a quiet place to think.",
		hospital = "Check-ups, patients, and Dr. Calm's corner for stress.",
		office = "Desks, files and the Brainville Times newsroom.",
		jobcenter = "Talk to the counselor to pick a job.",
		courthouse = "The judge, the court tables and the election podium.",
		lab = "Experiments! Help with the mouse maze.",
		pizza = "Pizza, pasta and gelato. Eat here, or work in the kitchen as a Restaurant Worker.",
		burger = "Burgers and shakes. Eat here, or work the grill as a Restaurant Worker.",
		sushi = "Sushi and noodles. Eat here, or work the bar as a Restaurant Worker.",
		taco = "Tacos and burritos. Eat here, or work the counter as a Restaurant Worker.",
		rotcafe = "Rainbow mystery drinks. Nobody knows what is in them. Not even the café.",
	},
}

-- 1.9.1 restaurants (big ideas #2). Parody names only.
Content.Restaurants = {
	Places = {
		pizza = { name = "🍕 Pizza Palace", sign = "🍕 PIZZA PALACE", work = "Pizza Kitchen", menu = { "🍕", "🍝", "🥗", "🥤", "🍨" }, board = "🍕 MENU\nPizza · Pasta · Salad\nLemonade · Gelato" },
		burger = { name = "🍔 Burger Barn", sign = "🍔 BURGER BARN", work = "Burger Grill", menu = { "🍔", "🍟", "🌭", "🥤", "🍦" }, board = "🍔 MENU\nBurger · Fries · Hot dog\nShake · Cone" },
		sushi = { name = "🍣 Sushi Spot", sign = "🍣 SUSHI SPOT", work = "Sushi Bar", menu = { "🍣", "🍙", "🍜", "🍵", "🍡" }, board = "🍣 MENU\nSushi · Rice ball · Noodles\nTea · Sweet dumplings" },
		taco = { name = "🌮 Taco Town", sign = "🌮 TACO TOWN", work = "Taco Counter", menu = { "🌮", "🌯", "🥙", "🧃", "🍮" }, board = "🌮 MENU\nTaco · Burrito · Wrap\nJuice · Flan" },
		rotcafe = { name = "🌈 Brainrot Café", sign = "🌈 BRAINROT CAFÉ", work = "", menu = { "🧃", "🍭", "🌈", "🫧" }, board = "🌈 MYSTERY DRINKS\nColour: yes\nFlavour: ???" },
	},
	Eat = { action = "Eat here", object = "🍽 Meal (%d coins)", done = "🍽 Yum! Stress -%d (-%d coins)", coma = "🍽 Food coma! Your brain takes a little nap. (-%d coins)", poor = "🪙 A meal costs %d coins. Work a shift first!", animal = "🐾 Animals can't order. Try begging for scraps!" },
	Scraps = { action = "Beg", object = "🐾 Scraps (free)", done = "🐾 Someone drops you a snack. Good pet! Stress -%d", human = "🐾 Only animals beg for scraps." },
	Mystery = {
		action = "Drink",
		object = "🌈 Mystery drink (free)",
		lines = { "🌈 It tasted like the colour purple.", "🫧 Your burp was a bubble. Science!", "🍭 Sugar and bad decisions. Delicious.", "🧃 You now speak fluent juice box.", "🌀 Your eyes did a little spin." },
		gain = "🤔 You read the label. It just says \"???\". You put it down.",
	},
	Customer = "🙂 Customer",
	Influencer = "🤳 Influencer",
	Wants = "wants %s",
}

-- 1.9.1 group shifts
Content.GroupShift = {
	Crew = "🤝 Group shift with %s! Teamwork bonus +%d%%",
	Role = "Your role: %s",
	Roles = { order = "🧑‍🍳 Cook", serve = "🧾 Server", dishes = "🧽 Dishwasher" },
	Bonus = "🤝 Teamwork bonus! +%d coins",
}

-- 1.9.1 homes (HomeService + the 🏠 Home app)
Content.Homes = {
	Title = "🏠 Home",
	GoHome = "🏠 Go home",
	YourHome = "Your home: %s",
	Grow = "Your home changes as your brain changes!",
	Shop = "🛋 Furniture",
	Buy = "Buy · %d 🪙",
	OwnedTag = "✅ In your home",
	Visit = "👀 Visit",
	VisitTitle = "Visit a home",
	NoOthers = "Nobody else is in this server yet.",
	ClosedTag = "🔒",
	DoorOpen = "🚪 Visitors welcome (tap to close)",
	DoorClosed = "🔒 Closed to visitors (tap to open)",
	Leave = "Leave",
	Door = "🚪 Back to town",
	NameSign = "🏠 %s's %s",
	Trophies = "🏆 TROPHY WALL\n🏅 Badges: %d\n💡 Inventions: %d\n📸 Photos: %d",
	PickPath = "Pick a door first!",
	WrongPath = "That one isn't for your path.",
	Owned = "You already have that.",
	Poor = "🪙 That costs %d coins. Work a shift or play to earn more!",
	Bought = "%s %s is in your home now! (-%d coins)",
	Gone = "That player isn't here any more.",
	Closed = "🔒 %s's door is closed to visitors right now.",
	Visiting = "👀 %s is visiting your home!",
	Welcome = "👋 Welcome to %s's home! Look, don't touch. 😄",
	Tiers = { flat = "Little Flat", house = "House", penthouse = "Penthouse", box = "Cardboard Box", messy = "Messy Room", palace = "Pizza-Box Palace", kennel = "Kennel" },
	Furniture = {
		rug = { icon = "🟥", name = "Rug" },
		plant = { icon = "🪴", name = "Plant" },
		lamp = { icon = "💡", name = "Lamp" },
		bed = { icon = "🛏", name = "Bed" },
		sofa = { icon = "🛋", name = "Sofa" },
		tv = { icon = "📺", name = "TV" },
		fishtank = { icon = "🐠", name = "Fish tank" },
		bookshelf = { icon = "📚", name = "Bookshelf" },
		desk = { icon = "💻", name = "Desk + computer" },
		piano = { icon = "🎹", name = "Piano" },
		gamingchair = { icon = "🎮", name = "RGB gaming chair" },
		pizzatower = { icon = "🍕", name = "Tower of pizza boxes" },
		beanbag = { icon = "🟡", name = "Beanbag" },
	},
}

-- 1.9.1 town board
Content.TownBoard = {
	Title = "🏙 TODAY IN TOWN",
	Footer = "📱 Open the Town app to visit their homes!",
	Nobody = "nobody yet",
	IQ = "IQ %d",
	Rows = { smartest = "🧠 Smartest:", dumbest = "🥴 Dumbest:", inventor = "💡 Top inventor:", team = "🤝 Best teamworker:", genius = "🌟 Geniuses:" },
	AppTitle = "🏙 Town",
	Visit = "👀 Visit",
}

return Content
