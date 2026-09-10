# Cybertron Mission Acorn Electron runtime source reconstruction

This repository contains a complete, byte-exact BeebAsm reconstruction of the
relocated Acorn Electron `CYBRUN` gameplay runtime from *Cybertron Mission*.
Executable code, data tables, text, room layouts, and graphics are declared in
the two maintained source files:

- `source_acorn_electron/cyber1.asm`
- `source_acorn_electron/memory_map.inc`
- `source_acorn_electron/reconstruction.json`

The assembly contains no binary fragments and requires no original executable
or authority binary to build.

This repository covers the runtime loaded at `$0D80-$2FFF`, with entry point
`$0E02`. The original title program, bootstrap, cassette/disc structure, and
other release media are outside this source reconstruction.

Original image: https://bbcmicro.co.uk/game.php?id=58

## Community

Join the project discussion on [Discord](https://discord.gg/QjARJ67V9U).

## Requirements

- PowerShell 7 or Windows PowerShell 5.1
- [BeebAsm](https://github.com/stardot/beebasm), either on `PATH` or supplied
  with `-BeebAsm`
- Python 3 for validation of the bundled analysis tool
- Pillow to regenerate the optional labelled graphic sheet

## Build

From the repository root:

```powershell
./build.ps1
```

Or specify the assembler explicitly:

```powershell
./build.ps1 -BeebAsm C:\path\to\beebasm.exe
```

The build writes `build/reconstruction/CYBRUN` and
`build/reconstruction/cyber1.labels`.

## Validate

```powershell
./validate.ps1
```

Validation performs a clean source assembly and requires the resulting runtime
to be exactly `$2280` bytes with SHA-256
`29d4bed6a2bf6a3f93302f01b05fe43ec930528eaf702e679b73d2fd2476beef`.
That digest is the byte-exact authority established by the reverse-engineering
project, so validation requires no copyrighted original media. It also runs
standalone port preflight contracts for graphic pointers, player animation
selection, player starts, projectile address updates, all 256 clean room
render variants, all 640 room/level status-panel composites, both sprite
destination walks, and all four isolated player-start layers.
Seven seeded setup scenarios additionally validate target-code generation,
enemy/target placement, collision rejection, and the composed entry frame.
The input preflight exhausts all 16 keyboard movement masks, joystick threshold
edges, and every previous/current fire-latch transition. Each keyboard mask is
also replayed through the actual assembled scanner with a bounded INKEY stub;
72 X/Y/fire edge combinations replay the assembled joystick scanner, and all
eight non-idle deltas replay the assembled direction resolver.
All 32 representative direction/parity projectile movements also execute the
assembled `$1B87` pointer-update routine and compare every mutated slot field.
The 32 player-start/direction shot positions execute `$1BFC` and its real
nested pointer helpers to verify the computed bitmap address.
The assembled `$1C4D` allocator is replayed through 128 admitted combinations
and both refusal edges, checking slot choice, counters, offsets, visibility,
pointer calculation, fire consumption, and sound dispatch.
The capacity-rejection case deliberately checks the original ordering in which
the fire edge is consumed before the four-shot limit returns.
Object validation covers every setup-count row, all 41 render slots in the
overlapping lifecycle windows, all six hit-animation states, and all 256
projectile expiry input bytes.
The assembled `$1B41` expiry routine is also replayed for all 256 pixel bytes
in both a player-shot and a spawned-hazard slot, checking separate counters,
deactivation, and the special spook-pause flag.
The assembled phase-zero `$1812` erase/retire and `$1876` draw/advance passes
are replayed for every lifecycle state, preserving their two-pass ordering.
The actual assembled score routine is CPU-replayed across all 10,000 valid
four-character score states, including every carry and extra-life boundary.
Further original-code replays cover all 22 sound dispatch IDs, all runtime text
streams, menu and level-intro ordering, target/bonus/level outcomes, life-loss
reset, hazard allocation/rejection/recycling, enemy scheduling and movement
policies, and player collision/room-exit priority. `validate.ps1` prints the
exact replay count for every category and fails on the first divergence.

## Layout and provenance

`CYBRUN` is the relocated runtime view used by the game logic. It loads at
`$0D80`, enters at `$0E02`, and ends at `$3000`. The source preserves original
addresses, memory aliases, self-modifying operands, Acorn screen-memory layout,
and 6502 behavior.

Names and comments distinguish proved behavior from structural classification.
Unreferenced original bytes are retained as explicitly named unused code,
padding, or graphic-shaped records rather than hidden in binary fragments.
See [`source_acorn_electron/README.md`](source_acorn_electron/README.md) for the
source conventions and range manifest. The
[semantic completion audit](analysis/reconstruction/semantic_completion_audit.md)
records what is proved and the remaining Quest-level runtime validation gaps.
The original-output [room renderer oracle](analysis/reconstruction/runtime_room_render_reference.txt)
provides 256 clean-screen digests covering all 64 rooms and four fill-pattern
variants.
The [status-panel oracle](analysis/reconstruction/runtime_status_panel_reference.txt)
adds every room with every displayed level digit, plus explicit life and target
slot placement references.
The [sprite renderer oracle](analysis/reconstruction/runtime_sprite_renderer_reference.txt)
records the distinct even/odd-Y write sequences and exact player-start layer
digests.
The [setup-frame oracle](analysis/reconstruction/runtime_setup_frame_reference.txt)
records the seeded RNG state, placed objects, setup-screen digest, and immediate
player-entry digest for each scenario.
The [control-flow reference](analysis/reconstruction/runtime_control_input_reference.txt)
and [movement reference](analysis/reconstruction/runtime_player_movement.txt)
document key codes, input selection, pause/menu behavior, direction mapping,
room exits, and projectile movement tables.
The [enemy movement contract](analysis/reconstruction/runtime_enemy_movement_contract.txt)
and [player collision contract](analysis/reconstruction/runtime_player_collision_contract.txt)
record the distinct scheduler, retry, collision-priority, damage, and room-exit
rules now enforced by executable replays.
The [object-slot contract](analysis/reconstruction/runtime_object_slot_contract.txt),
[object lifecycle reference](analysis/reconstruction/runtime_object_lifecycle_reference.txt),
and [projectile lifecycle reference](analysis/reconstruction/runtime_projectile_lifecycle.txt)
preserve the deliberately different scheduler, collision, animation, target,
and shot/hazard ownership windows.
The [score/status contract](analysis/reconstruction/runtime_score_status_contract.txt)
documents the original character-counter, target outcomes, lives, and level
completion behavior. A strict bounded 6502 replay core executes the source-built
routine rather than replacing it with the port model under test.
The [active-frame edge contract](analysis/reconstruction/runtime_active_frame_edge_contract.txt)
is enforced by bounded CPU replays of normal, terminal-delay, active-delay,
and spook-pause-consumption frame spines, including exact leaf-call order.
The [sound dispatch audit](analysis/reconstruction/runtime_sound_dispatch_audit.txt)
and [sound port semantics](analysis/reconstruction/runtime_sound_port_semantics.txt)
preserve all 22 loader-owned sound rows and their BBC channel/envelope meaning.
The assembled `$21EA` dispatcher is replayed for every ID with sound both on
and off, checking gating and the exact OSWORD 7 block pointer.
The [screen-flow contract](analysis/reconstruction/runtime_screen_flow_contract.txt)
records the original help, legend, and level-intro order without the archived
report's incorrect Mode-5 previews. Actual `$110E` and `$111B` CPU replays
verify all three VDU streams and all fourteen compact text streams.
Additional CPU replays enforce the text-buffer clear, help-before-legend menu
order, and every level-intro target-count/glyph/sound/wait sequence.
They also guard the original distinction between the five-glyph intro cap and
the inclusive highest-required-target slot used during gameplay.
The [inert-source contract](analysis/reconstruction/runtime_inert_source_contract.txt)
gives every retained unused entry and data block a bounded unreachable or
no-consumer role, matching the semantic-completion standard used for Quest.

The decoded 24-byte artwork can be reviewed in the
[composed sprite and graphic sheet](analysis/reconstruction/composed_sprite_sheet.png).

This is reconstructed source, not the original author's source. The original
game and its assets remain the property of their respective copyright holders.
No original title program or release media is included here.
