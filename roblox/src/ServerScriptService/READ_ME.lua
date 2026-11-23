--[[
	LOSE A BRAIN CELL / GAIN A BRAIN CELL  -  updates 1.0 - 1.6

	WHERE THINGS ARE
	- ReplicatedStorage > Shared > Config     : all settings, IDs (group, sounds, passes), admin commands
	- ReplicatedStorage > Shared > Content    : all text (headlines, questions, jobs, glasses)
	- ReplicatedStorage > Shared > Badges     : the one combined badge list
	- ReplicatedStorage > Shared > Narration  : everything Dr. Wrinkles says
	- ServerScriptService > Main + Services   : the server (saving, brain cells, admin, activities)
	- StarterPlayer > StarterPlayerScripts    : the player's screen (HUD, menus, styles, admin panel)

	THE MAP IS BUILT BY CODE when you press Play (it appears in Workspace > Map).

	BEFORE PUBLISHING
	1. Home > Game Settings > Security > turn ON "Enable Studio Access to API Services" (so saving works).
	2. Paste your IDs into Config (sounds, music, game passes) and Badges (badge IDs). 0 = not set up yet.

	ADMIN
	- Ranks come from your community (group) ranks, in Studio too once the game is published under it:
	  255 = Owner, 100+ = Head Moderator, 50+ = Moderator, 10+ = Tester.
	- Open the staff panel with the 🛠 button, P on keyboard, or the Select button on a controller.
	- 1.4: SpaceService (Astronaut, Moon, World's Smartest), CastleService (the secret Endless Castle),
	  Client > Tutorial (the guided tutorial with the notes).
	- 1.5: Rooms (furniture, people, seats and exit doors inside buildings that have a use; houses stay
	  closed), ConversationService + Client > Conversation (the cinematic conversation scenes),
	  and the 🆘 Unstuck button (handled in Main).
	  Room furniture is in Workspace > Rooms when you press Play.
	- 1.6: careers (GainService + Content.Careers), SchoolService (Lose-path school bell + truant officer),
	  AnimalForms (blocky animal bodies) + AnimalService (animal powers).
	- Chat commands also work, starting with ;  for example:  ;kick name reason   ;setcells me 1000
]]

return {}
