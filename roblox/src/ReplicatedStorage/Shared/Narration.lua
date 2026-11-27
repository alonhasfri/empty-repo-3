-- Narration: everything Dr. Wrinkles says, by mood.
-- Moods: host (average), librarian (smart), brainrot (dumb), caveman (too dumb)

local Narration = {}

Narration.Name = "Dr. Wrinkles"

Narration.Lines = {
	host = {
		welcomeBack = { "Welcome BACK, contestant! The show must go on!" }, -- 1.9.3: returning players already picked a door
		welcome = { "WELCOME, contestant! Behind door number one: glory! Behind door number two: drool!", "It's SHOWTIME! Pick a door, any door!" },
		choseLose = { "Ooh, the BIG door! Let's see how fast you can lose it ALL!", "A bold choice! Your brain is now officially on a countdown!" },
		choseGain = { "The quiet door! A scholar! Let's see if you've got what it takes!", "Brains on the line, folks! Let's climb!" },
		lost = { "And there goes another batch!", "Ding ding ding! Brain cells: going, going…" },
		gained = { "Brain cells UP! The crowd goes mild!", "Look at that brain GROW!" },
		gatePass = { "CORRECT! Ladies and gentlemen, we have a thinker!" },
		gateFail = { "Ooh, so close! The buzzer says… NO!" },
		stage = { "A brand new you! Give it up for the contestant!" },
	},
	librarian = {
		welcomeBack = { "Ah, you have returned. Your bookmark is where you left it." },
		welcome = { "Ah, welcome. Do keep your voice down; the books are thinking." },
		choseGain = { "A fine choice. Do mind the footnotes." },
		choseLose = { "…I see. I shall shelve your brain under 'Fiction'." },
		lost = { "A regrettable loss of grey matter." },
		gained = { "Splendid. Your neurons approve.", "Knowledge, accumulated. Most satisfactory." },
		gatePass = { "Impeccable reasoning. You may proceed." },
		gateFail = { "Incorrect. Revisit chapter one, perhaps." },
		stage = { "Your surroundings have… improved. As have you." },
		stressed = { "You appear frazzled. A routine might help. Beethoven counted his coffee beans." },
	},
	brainrot = {
		welcomeBack = { "yo ur back 👋 W" },
		welcome = { "yo wsg 👋 pick a door bro" },
		choseLose = { "W choice no cap 🔥" },
		choseGain = { "bro wants to be smart 💀 aight" },
		lost = { "bro just lost like a billion brain cells 💀", "ong that was so dumb 😭 W", "no thoughts head empty fr" },
		gained = { "nah why did u read that 😭", "bro gained brain cells?? L" },
		embarrassed = { "bro walked into a wall 💀 no cap that's crazy", "chat is he fr 😭" },
		hiding = { "bro is HIDING 💀 behind a bush 😭" },
		viral = { "YOU WENT VIRAL 😭😭 BigReactz is reacting to ur comment" },
		stage = { "yo ur turning into smth 💀" },
		meterBroken = { "bro is too dumb to be embarrassed now 🗿" },
	},
	caveman = {
		welcomeBack = { "OOGA! *waves*" },
		welcome = { "OOGA." },
		lost = { "OOGA.", "Hrrng.", "*bonk*", "UGH." },
		gained = { "…hm?", "OOG??" },
		embarrassed = { "HRRNG." },
		hiding = { "*hides*" },
		viral = { "OOGA BOOGA??" },
		stage = { "OOGA OOGA." },
		meterBroken = { "wut" },
		death = { "*bonk*" },
	},
}

local FALLBACK = {
	host = "Let's keep the show going!",
	librarian = "Indeed.",
	brainrot = "bruh",
	caveman = "OOGA.",
}

function Narration.line(mood: string, event: string): string
	local set = Narration.Lines[mood]
	if set and set[event] then
		local list = set[event]
		return list[math.random(1, #list)]
	end
	return FALLBACK[mood] or "…"
end

return Narration
