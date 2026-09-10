# Cybertron Mission semantic completion audit

## Result

Semantic annotation of the source-owned `CYBRUN` payload is complete under the
same acceptance distinction used by Quest: every byte has an evidence-backed
source role, active code has behavioral or reusable port contracts, and inert
bytes have explicit bounded no-consumer or unreachable-entry contracts. This
does not claim that every possible gameplay state has been observed or that a
future port has passed full-frame parity.

## Authority and scope

This audit covers the relocated Acorn Electron `CYBRUN` gameplay runtime at
`$0D80-$2FFF`, entered at `$0E02`. The expected source-built payload is 8,832
bytes with SHA-256
`29d4bed6a2bf6a3f93302f01b05fe43ec930528eaf702e679b73d2fd2476beef`.
The title program, bootstrap, and release-media container are outside this
repository's declared scope.

The source-built payload and the contracts enforced by `validate.ps1` are the
authority for this standalone repository. Visual appearance alone is not
accepted as evidence for gameplay identity.

## Current evidence

| Requirement | Current evidence | Result |
| --- | --- | --- |
| Complete source ownership | `cyber1.asm` emits the full `$2280` bytes without `INCBIN`; `reconstruction.json` covers `$0D80-$3000` without gaps | Proved |
| Exact reconstruction | A clean BeebAsm build is checked for length and SHA-256 by `validate.ps1` | Proved |
| Named executable operands | Validation rejects raw numeric instruction operands and raw symbol-relative offsets | Proved |
| Named emitted data | Validation rejects any `EQUB`, `EQUW`, or `EQUS` without an active owner label | Proved |
| Inert source bytes | `runtime_inert_source_contract.txt` gives every retained unused entry, gap, padding block, and bitmap-shaped record an exact unreachable-entry or bounded no-consumer contract | Behavioral, complete negative contract |
| Contextual shared workspace | The source and memory map contain no generic `scratch` identifiers; shared addresses use bounded contextual aliases | Proved |
| Graphic bank structure | 64 consecutive 24-byte Mode 2 records, IDs `$00-$3F`, selected through the `$2F40/$2F80` pointer tables | Proved |
| Graphic bank meaning | Every record has a semantic source label and `graphic_usage` annotation; `$16E1` proves eight player direction families and three selected lower animation frames | Behavioral |
| Room data | Sixteen 18-byte packed room records are bounded by the room selector and tile renderer | Behavioral |
| Static gameplay semantics | Input, player movement, collision, projectile, object, status, score, sound, room, and screen-flow code is source-owned and behaviorally named | Behavioral, static |
| Port address preflight | `validate_port_contracts.py` checks 64 graphic pointers, 32 player animation selections, four player starts, 32 shot projections, and 32 movement projections against the source-built runtime | Port-contract |
| Projectile movement replay | The actual source-built `$1B87` routine is CPU-replayed for all eight directions from four representative even/odd-Y positions; current/previous pointers and X/Y fields are checked | Port-contract |
| Projectile pointer replay | The actual source-built `$1BFC` routine and nested pointer helpers are CPU-replayed for all 32 player-start/direction shot positions | Port-contract |
| Player-shot spawn replay | The actual source-built `$1C4D` allocator is CPU-replayed through 128 admitted start/direction/free-slot combinations and both refusal edges | Port-contract |
| Hazard spawn replay | The actual source-built `$2235` allocator is CPU-replayed for all eight movement directions in every eligible first-free slot 4-7, the Electron escape-condition pulse path, and all five rejection gates; source selection, offsets, pointer calculation, slot writes, counter ownership, and sound dispatch are checked | Port-contract |
| Input replay and projection | The actual source-built `$1609` scanner is CPU-replayed for all 16 keyboard masks, `$1287` for 72 joystick X/Y/fire edge combinations, and `$2207` for all eight non-idle direction vectors; four fire-latch transitions are also checked | Port-contract |
| Room-render parity | `validate_port_contracts.py` independently reconstructs `$14B9/$1516/$0EFE/$1EC8/$1F19` and matches all 256 original-output `$3000-$7FFF` digests, draw/fill counts, and nonzero-byte totals | Port-contract |
| Status-render parity | `validate_port_contracts.py` independently reconstructs `$1CAB/$1D3C/$2319/$2345` and matches all 640 original-output room/level composite digests; the bundled oracle also records life and target-slot placement | Port-contract |
| Sprite-render parity | `validate_port_contracts.py` independently reconstructs the even and split odd-Y `$1426-$1464` destination walks and matches all four original-output `$1735` player-start XOR-layer digests | Port-contract |
| Setup-frame parity | Seven deterministic scenarios reproduce target-code generation, enemy/target placement with rejection, RNG end state, setup-screen digest, and the immediate `$1849-$1863` player-entry digest | Port-contract |
| Object/projectile lifecycle projection | All six enemy-count rows, 41 overlapping render-slot roles, six hit-animation states, and 256 masked projectile-expiry bytes are checked against bundled contracts | Port-contract |
| Hit lifecycle replay | The actual source-built `$1812` erase/retire and `$1876` draw/advance passes are CPU-replayed for all six lifecycle states with renderer calls captured | Port-contract, exhaustive |
| Enemy scheduler replay | The complete source-built `$198C` scheduler is CPU-replayed for all 12 active-object slots, all 16 frame phases, and all three enemy graphics, plus inactive and unrecognized-graphic rejection cases; cadence and erase/move/redraw dispatch order are checked in 600 cases | Port-contract, exhaustive |
| Enemy decision primitives | The source-built `$20B3` random-delta generator is CPU-replayed for all 16 low-bit inputs and `$23A3` chase-vector resolution for all nine relative axis outcomes, including its adjusted player-Y comparison | Port-contract, exhaustive |
| Enemy movement policies | Actual-code CPU replays cover SPINNER diagonal/X/Y retries and total failure, CLONE stored/random success and failure, and CYBERDROID initialization, persistence, both alignment retargets, and blocked-delta reset; `$205D` is used as a controlled collision oracle | Port-contract |
| Enemy movement validation | The source-built `$205D` validator runs with the real `$16BE` incremental mover, pointer-save/update logic, and `$1FBD` bounds test for clear movement, renderer collision, and all four playfield boundaries; only the bitmap renderer is a controlled collision oracle | Port-contract |
| Player collision priority | The source-built `$18DF-$1929` phase-3 pipeline is CPU-replayed for clear, pretest, spook, target, scalar-hit, fatal-accumulator, and combined-signal cases; draw modes, input gating, early `$1972` routing, and target-before-hit-before-fatal priority are checked | Port-contract |
| Player hit and room-exit edges | `$1964` is CPU-replayed for all four phase-modulo outcomes, proving saved-redraw versus direct-clear routing into life loss; `$1AAC/$172A` is replayed for inside and all four exits, proving signed room changes and restart without damage | Port-contract, exhaustive |
| Hazard recycle replay | The actual source-built `$22D0` path is CPU-replayed for every first-free logical item slot 0-11 and the slot-12 refusal boundary; graphic transfer, active state, saved slot, placement tail, and bounded ownership are checked | Port-contract, exhaustive |
| Projectile expiry replay | The actual source-built `$1B41` routine is CPU-replayed for all 256 screen-byte values in both player-shot and hazard slots, including counter ownership and the `$A0` spook-pause class | Port-contract, exhaustive |
| Target outcome replay | The actual source-built `$0FD6-$1069` handler is CPU-replayed for required slots 1-5, the bonus target, the incomplete completion gate, and level advance with and without decimal carry; matching, status consumption, movement reversal/cancellation, score/sound dispatch, lives, level digits, and room-bank rotation are checked | Port-contract |
| Life-loss replay | The complete source-built `$1A59-$1AAA` reset is CPU-replayed across four saved-pointer cases spanning low-byte borrow/carry boundaries; life count, status/sound calls, both restored pointers and Y fields, death graphics, draw order, render mode, and transition delay are checked | Port-contract |
| Score CPU replay | The actual source-built `$22E6` routine is executed for all 10,000 valid four-character score states and compared with an independent carry/extra-life model | Port-contract, exhaustive |
| Active-frame edge replay | The actual `$17BF-$195B` frame spine is CPU-replayed for normal, terminal-delay, active-delay, and spook-pause-consumption cases with leaf-call order and state effects checked | Port-contract |
| Sound dispatch replay | The actual source-built `$21EA` dispatcher is CPU-replayed for all 22 sound IDs with sound enabled and disabled; OSWORD 7 register arguments and gating are checked | Port-contract, exhaustive |
| Screen/text replay | The actual `$110E` VDU streamer is CPU-replayed for all three source streams and `$111B` for all fourteen compact strings; screen order and required-target order are bundled without stale Mode-5 artwork claims | Port-contract, exhaustive |
| Menu/intro flow replay | Actual-code CPU replays enforce the 20-byte text clear, help-before-legend menu order, and all seven level-intro count/cap cases including glyph, sound, and wait ordering | Port-contract |
| Full active-frame parity | No deterministic full-frame replay oracle is bundled in this standalone repository | Not proved |

## Source quality metrics

These counts describe the current source and are checked where practical by
`validate.ps1`:

- 8,832 of 8,832 runtime bytes are source-owned.
- 2,726 decoded 6502 instructions assemble byte-exactly.
- 64 of 64 renderer graphics have consecutive numeric ID annotations,
  semantic labels, and bounded usage annotations.
- Zero generic address-only, decoded-island, unclassified, numeric graphic,
  or scratch labels remain.
- Thirteen `unused_*` labels remain intentionally. Each denotes retained
  original bytes or an entry/loop with a proved bounded no-consumer or
  unreachable-entry contract; these are not omitted from the build.

## Additional port-validation work

Quest-level semantic source completion does not require every possible dynamic
state or a whole-frame emulator comparison. A stronger future port-acceptance
ladder can still add an active-loop/full-frame comparison recording complete
RAM and display effects for fixed initial state and input sequences, and can
replace active-frame leaf probes with integrated subsystem execution. Until
then, this audit does not describe the runtime as fully scenario-validated or
claim that any port is frame-perfect.
