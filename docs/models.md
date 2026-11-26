# Real 3D models in the town

The town builder (`Props.lua` → `custom()`) uses a real model whenever `ServerStorage > Props` has one with the
right name, and falls back to the code-built blocks when it doesn't. Models are scaled to fit, anchored, and
**every script is removed** (on insert and again at runtime). ServerStorage is not synced by Rojo, so the
models live in the place file: save the place after changing them (dev copy saved again with the houses and shops, Nov 26).

| Name in ServerStorage > Props | Used for | Creator Store asset | Creator |
|---|---|---|---|
| Car | parked cars (repainted per car) | 14215126016 | Roblox Resources |
| Tree1 | round leafy trees (mixed with Tree2) | 580221169 | SheriffTaco |
| Tree2 | tall trees | 6020696518 | Adrijan0830 |
| StreetLamp | street lights and the street-dressing lamps | 14212653287 | 9bsts |
| House1 | filler houses, Gain side (most often) | 3110593690 | bearduckmonkey |
| House2 | filler houses, Gain side | 125443645311849 | DisBuilder |
| Shop1 | filler shops, Lose side | 4911112831 | Squistic |
| Bench | benches | 97070047122816 | Embeshad5804 (its hidden "ScreenBuilder" script was removed) |

All are free Creator Store models. To add or swap one: insert it in Studio, delete its scripts, name it as above
(other names that already work: Microwave, Desk, ArcadeMachine, Newsstand, PhoneDisplay, ShopCounter, Bookshelf,
TicketBooth, BulletinBoard, CafeCounter, LabBench, HospitalBed, VendingMachine), put it in ServerStorage > Props,
and save the place. Custom models from Blender go the same way (export FBX → import in Studio → Props).
