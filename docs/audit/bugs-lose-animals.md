# Bug hunt: Lose path, animals, school, fun places

Read-only audit (no game code changed, Studio not used). Paths are under `roblox/src/`.
Ranked by severity. Nothing here was run; each item was found by reading the code.

## High

1. **Octopus (a main Lose stage) has no animal body or form entry.**
   `ServerScriptService/Services/AnimalForms.lua:19-76` has shapes for dog/fly/bee/mouse/worm/dead only. `Content.lua:263-270` (`Content.Animals.Forms`) has the same list. `Brain.lua:158-168` has octopus (50M to 500M cells), plus secret microbe and tardigrade.
   What goes wrong: an octopus player is a tiny human avatar. There is no "You are now..." transform screen (`BrainService.lua:421`, only a toast). `Rooms.isAnimal` still treats them as an animal (`Rooms.lua:167-174`), so they are locked out of conversations and jobs. `SocialService.isAnimalP` (`SocialService.lua:979-981`) says "not an animal", so scientists cannot experiment on them even though `EXPERIMENTS.octopus` exists.
   Fix: add octopus (and microbe, tardigrade) to `SHAPES`, `Content.Animals.Forms` and `Config.Animals.BodyScale`. Make `isAnimalP` use `Rooms.isAnimal`.

2. **Death or other server teleports during a conversation or Vs cutscene leave the client in a half-locked state.**
   `Conversation.lua:437-494` and `vsStart` hide `UI.gui`, anchor the root and set a scripted camera, all client-side. Nothing on the server or in `ClientMain` closes the conversation on `death`. `BrainService.blocked` (`BrainService.lua:752-765`) does not know about conversations. Because of that, these all run while a conversation is open:
   - `animal_power` dig (`AnimalService.lua:60-72`)
   - school "caught" teleport (`SchoolService.lua:182-194`)
   - the school bell
   - the reading popup
   - the death effect and death screen (`Stations.deathScreen` lives in `UI.gui`, which is hidden)

   What goes wrong: the player is teleported while anchored with a frozen camera. The POOF and death modal are invisible until they find the small "Leave" button. `Watchdog.isLocked` deliberately ignores a conversation (`ClientMain.client.lua:44`), so it never rescues them. Phone players have the thumbstick hidden too.
   Fix: in `ClientMain`'s `death` handler call `Conversation.close()` first. Add an `inConversation` runtime flag set by `ConversationService` and `SocialService` (cleared on close) and have `BrainService.blocked` return it. Make `SchoolService.ring/step` and `animal_power` respect `blocked`.

3. **Vs Mode sessions can be duplicated through `sued_accept`.**
   `SocialService.lua:738-756`: `sued_accept` never checks that the player was actually sued. It also does not check `inSession[player]` or `BrainService.blocked`.
   What goes wrong: any Lose player can call it at any time, even from inside another session. They are queued again and `startSession` overwrites `inSession[p]`. Two sessions then run for one player, and when the first ends it clears `inSession` for the second. The `sued` remote is also a free, unlimited courtroom queue.
   Fix: remember a `pendingSue[player]` token in `maybeSue` (expire it after about 30 s). Reject `sued_accept` without a token, when `inSession[player]`, or when `blocked`.

4. **A broken session setup leaves players permanently "already in an activity".**
   `SocialService.lua:570-572`: `act.setup(sess)` is not wrapped in `pcall`. `runSession` is the only place that clears `inSession` (`:608-614`). One error in a setup function or in `sendTo` strands both players. Every later `social_join` returns "You're already in an activity" until they rejoin.
   Fix: wrap the whole `runSession` body in `pcall` and always clear `inSession` and `sessions` in a final block.

5. **The election can wedge forever.**
   `SocialService.lua:796-850`: `election` is set at `:813` and cleared at `:845`. `runElection` is called through `pcall` (`:960`), but an error between those lines (for example `WorldService.setBanner` at `:841`) leaves `election` non-nil. All later elections return false silently. Votes stay open, and the 10-minute boost is never reset.
   Also, `task.delay(600)` at `:846` resets the boosts even if a newer election has started.
   Fix: do the work inside `pcall`, always set `election = nil` in a finally step, and store a boost expiry time instead of using `task.delay`.

6. **The school bell is a pure nuisance with no payoff.**
   `SchoolService.lua:115-120`: `startClass` does nothing but set an objective ("act dumb: sleep, throw paper...") for 60 s. There is no brain loss, reward or class interaction. Escaping the officer (speed 13 vs your 16) costs nothing. Skipping school is strictly better than going.
   Fix: make class give a small `BrainService.lose` plus coins, or trigger the classroom conversation. Give "caught" a real cost (the embarrass is already there) and "escaped" a small coin reward.

## Medium

7. **`switch_path` skips every guard.**
   `LoseService.lua:453-462`: it does not check `data.dead`, the Life Pack `doorGuard` (little kids cannot pick a door), or conversations. A client can call it with any path at any time. Fix: route it through `WorldService.enterDoor` rules, or require a pending `confirmSwitch`.

8. **`life_start` does not reset a run properly.**
   `LifeStageService.lua:91-121`: it sets path, dead and cells by hand instead of `BrainService.startPath`. Stale fields survive: `comeback`, `embarrass`, `stress`, `runStart`, `gatesPassed`, `astroNotified`, `worldsSmartest` (so the 200 IQ board can never fire again), plus runtime `frozen` and `hidingUntil`. It is also allowed mid-minigame or conversation. Fix: call a shared reset (`startPath` with path nil support) and respect `blocked`.

9. **`applyBody` fights `applyCharacter` over scale and speed.**
   `LifeStageService.lua:58-75` vs `BrainService.lua:300-307`. Baby or grandparent scale is overridden when the animal stage changes, and never restored when the player is human again until the next birthday. Baby walk speed is reset by any later `applyCharacter`. Fix: apply life-stage scale as a multiplier inside `applyCharacter`.

10. **Pending reading popups give brain cells to Lose players.**
    `LoseService.lua:92-108` and `:484-489`. If the client closes the popup without answering (`Conversation.open` calls `UI.closeModal`, and the popup is hidden while a conversation is open), the server waits 120 s and then calls `BrainService.gain` (wrong direction for Lose). The popup also fires for animals and during conversations or cutscenes. Fix: skip sending while blocked or animal, and on timeout apply the "skipped" penalty or nothing.

11. **`clickbait_ignore` is an infinite brain-cell faucet.**
    `LoseService.lua:247-254`: there is no check for an open card set and no cooldown. It gives `gain(0.3)` per call at up to 25 calls per second. On the Lose path `gain` is multiplicative (`cells * 0.022 * 0.3`), so the cell count grows exponentially. This lets cheaters avoid the ending. Fix: require `sess.clickbait` and clear it, as the other clickbait handlers do.

12. **Duplicate comment word ids are accepted.**
    `LoseService.lua:345-354`: the same id can be sent five times and the tier filter from `comments_get` is not applied. Cheaters get 5x score and viral odds. Fix: de-duplicate ids and re-apply the tier filter.

13. **Delayed kill can hit a fresh run.**
    `LoseService.lua:416-422`: after 5 s `hum.Health = 0` runs without checking that the player is still `dead`. A quick "Do It Again" or a respawn cuts the new run short (the character dies on spawn). Fix: re-check `DataService.get(player).dead` in the delay.

14. **Dead-end `AnimalService` dig.**
    `AnimalService.lua:63-70`: `choices` can be empty, so `choices[math.random(1,0)]` errors. The 6 s cooldown was already consumed at `:47`. Also, `Net` swallows the error as "Something went wrong". Fix: guard for empty and set the cooldown only after success. Dig also ignores the Life Pack, skill-style gates and the school rules; add the same checks as the doors.

15. **`exp_answer` pays coins even when no experiment starts, and skips eligibility.**
    `SocialService.lua:1016-1047`: `Config.LabExperiments.Coins` (10 each) is awarded after `startSession`. There is no cap and no Gain/Lose check. The animal does not need to be on the Lose path, which the experiment role requires. Two friends can farm coins every 20 s (`AskCooldown`). Fix: add a per-pair cooldown or a daily cap, and reuse `eligible(...)`.

16. **`fun_do` does not check `BrainService.blocked`.**
    `FunService.lua:36-84`: frozen or hiding players can still use the stands. Also `workspace:FindFirstChild("Station_"..key, true)` then `.Position` errors (caught by `Net`) if the station is a Model. Fix: check `blocked`, and use `GetPivot()`.

## Low

17. **Kid-safety wording: "HOT SINGLES" joke ad.**
    `Content.lua:1247` (`"🔥 HOT SINGLES"`, "hot single SOCKS near you"). Even as a sock joke, this is a dating/adult-ad trope in a kids' game. Replace it with "HOT SOCKS" or "SPICY TOAST".

18. **Real brand in a headline.**
    `Content.lua:47`: "Free Robux Glitch (NOT CLICKBAIT) 2026". It breaks the "parodies, never real brands" rule. Change it to a fake currency ("Free Bonkabucks").

19. **"Eat a crayon" as a joke button.**
    `Content.lua` Fun `kindergarten.Lose`. Kids may copy it. Swap for "Draw on the wall (with washable crayon)".

20. **Horror default is Spooky, not opt-in.**
    `HorrorService.lua:34-40`: new players get far-away sightings and "someone is watching you" toasts by default, with no jump scares. That matches the rule, but it is still creepy on the default setting. Consider defaulting to Off for new accounts and offering Spooky in the tutorial. Also `Horror.lua:108-115` runs sightings during conversations and cutscenes and in interiors (the raycast hits roofs); check `LoseFX.isBusy`-style busy state.

21. **`AnimalUI.sniffPicker` falls back to the first word.**
    `AnimalUI.lua:123`: `string.match(p.name, "^(%S+)")` shows a text word for places whose name does not start with an emoji, which animals cannot read. Also `standPicker` (`:139-146`) shows an empty modal when stations have not streamed in.

22. **`LoseJobService` pays coins to dead players for a round started before death.**
    `LoseJobService.lua:60-64`. Also unlimited rounds back to back (no cooldown).

23. **`death()` awards "Speedrun" and best-run to admin-set zero cells.**
    `LoseService.lua:395-415`: no `data.adminTouched` check (the 200 IQ board has one, `BrainService.lua:507`).

24. **`AnimalForms.apply` can build with a NaN look vector.**
    `AnimalForms.lua:132`: if the root looks straight up or down, X and Z are 0, so `CFrame.lookAt(p, p)` is invalid. Guard with a fallback direction.

25. **`LoseFX.beforeOpen` queues extra opens.**
    `LoseFX.lua:87`: tapping an app several times during the 0.25 s lag opens it several times.

26. **Sued flow has no cooldown after a dumb action.**
    `SocialService.lua:731-736`: a 6% chance per dumb action, with no minimum gap. Several `sued` popups can stack. Add a 2-minute gap.
