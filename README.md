# Paleo movement sandbox

Open `project.godot` in Godot 4.7.2 and run the project (F6 runs only the current scene; use F5 for this sandbox).

| Input | Join | Move |
| --- | --- | --- |
| Keyboard left | F | WASD (E reserved for interact) |
| Keyboard right | Enter | Arrow keys (. reserved for interact) |
| Controller | Start | Left stick (A reserved for interact) |

Up to four players can join in any combination, with at most two keyboard players. Players collide with walls and each other. When a controller disconnects, its player stays still and enters the released-player queue. The next unassigned keyboard layout or controller takes over that player. Movement is confined to a flat plane with no gravity.

## Code boundaries

- `PlayerManager` owns joining, slots, device assignments, and temporary InputMap actions. It copies the selected binding profile into each player's local action set; controller copies are assigned to a specific device. Released player slots are source-agnostic, so any valid unassigned source can claim one. It trusts the level to provide a safe marker for every player slot.
- Every source key includes a device ID. Both keyboard layouts use Godot's reserved keyboard ID, `16`; controllers use their assigned device ID.
- `InputSource` owns the canonical player action list and always reads from a player's local action prefix. It currently exposes movement and an interaction-press query, with no InputMap registration side effects.
- `Player` coordinates input, movement, and animation in one physics callback.
- `PlayerMovement` is the sole owner of velocity, body movement, and facing. Speed, acceleration, deceleration, and turn speed can be tuned on the Movement node in `scenes/player.tscn`.
- `PlayerAnimation` receives actual movement velocity and currently exposes only planar speed; the visible character is a placeholder.

The shared camera belongs to the level. Local `-Z` is forward on the Facing pivot, where the future interaction ray and carry anchor will attach. Dash should be implemented through PlayerMovement, not by adding another script that independently moves the body.

Pickup, interaction components, inventory, and world generation are not implemented yet.

## Checks

With the Godot console executable on PATH:

```sh
godot --headless --path . --editor --import --quit
godot --headless --path . --script res://tests/movement_test.gd
```

On Windows the installed executable may be named `Godot_v4.7.2-stable_win64_console.exe` rather than `godot`.

The test harness injects keyboard and controller events and checks input isolation, analog speed, joining, source-agnostic reclaim, focus handling, movement, collisions, and scene cleanup. It exits nonzero on a failed check. Real controller mapping, keyboard rollover, rendering, and movement feel still require a manual playtest.
