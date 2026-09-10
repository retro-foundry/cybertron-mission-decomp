# Cybertron Mission semantic completion audit

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
| Contextual shared workspace | The source and memory map contain no generic `scratch` identifiers; shared addresses use bounded contextual aliases | Proved |
| Graphic bank structure | 64 consecutive 24-byte Mode 2 records, IDs `$00-$3F`, selected through the `$2F40/$2F80` pointer tables | Proved |
| Graphic bank meaning | Every record has a semantic source label and `graphic_usage` annotation; `$16E1` proves eight player direction families and three selected lower animation frames | Behavioral |
| Room data | Sixteen 18-byte packed room records are bounded by the room selector and tile renderer | Behavioral |
| Static gameplay semantics | Input, player movement, collision, projectile, object, status, score, sound, room, and screen-flow code is source-owned and behaviorally named | Behavioral, static |
| Port address preflight | `validate_port_contracts.py` checks 64 graphic pointers, 32 player animation selections, four player starts, 32 shot projections, and 32 movement projections against the source-built runtime | Port-contract |
| Projectile movement replay | The actual source-built `$1B87` routine is CPU-replayed for all eight directions from four representative even/odd-Y positions; current/previous pointers and X/Y fields are checked | Port-contract |
| Projectile pointer replay | The actual source-built `$1BFC` routine and nested pointer helpers are CPU-replayed for all 32 player-start/direction shot positions | Port-contract |
| Player-shot spawn replay | The actual source-built `$1C4D` allocator is CPU-replayed through 128 admitted start/direction/free-slot combinations and both refusal edges | Port-contract |
| Input replay and projection | The actual source-built `$1609` scanner is CPU-replayed for all 16 keyboard masks, `$1287` for 72 joystick X/Y/fire edge combinations, and `$2207` for all eight non-idle direction vectors; four fire-latch transitions are also checked | Port-contract |
| Room-render parity | `validate_port_contracts.py` independently reconstructs `$14B9/$1516/$0EFE/$1EC8/$1F19` and matches all 256 original-output `$3000-$7FFF` digests, draw/fill counts, and nonzero-byte totals | Port-contract |
| Status-render parity | `validate_port_contracts.py` independently reconstructs `$1CAB/$1D3C/$2319/$2345` and matches all 640 original-output room/level composite digests; the bundled oracle also records life and target-slot placement | Port-contract |
| Sprite-render parity | `validate_port_contracts.py` independently reconstructs the even and split odd-Y `$1426-$1464` destination walks and matches all four original-output `$1735` player-start XOR-layer digests | Port-contract |
| Setup-frame parity | Seven deterministic scenarios reproduce target-code generation, enemy/target placement with rejection, RNG end state, setup-screen digest, and the immediate `$1849-$1863` player-entry digest | Port-contract |
| Object/projectile lifecycle projection | All six enemy-count rows, 41 overlapping render-slot roles, six hit-animation states, and 256 masked projectile-expiry bytes are checked against bundled contracts | Port-contract |
| Hit lifecycle replay | The actual source-built `$1812` erase/retire and `$1876` draw/advance passes are CPU-replayed for all six lifecycle states with renderer calls captured | Port-contract, exhaustive |
| Projectile expiry replay | The actual source-built `$1B41` routine is CPU-replayed for all 256 screen-byte values in both player-shot and hazard slots, including counter ownership and the `$A0` spook-pause class | Port-contract, exhaustive |
| Score CPU replay | The actual source-built `$22E6` routine is executed for all 10,000 valid four-character score states and compared with an independent carry/extra-life model | Port-contract, exhaustive |
| Active-frame edge replay | The actual `$17BF-$195B` frame spine is CPU-replayed for normal, terminal-delay, active-delay, and spook-pause-consumption cases with leaf-call order and state effects checked | Port-contract |
| Sound dispatch replay | The actual source-built `$21EA` dispatcher is CPU-replayed for all 22 sound IDs with sound enabled and disabled; OSWORD 7 register arguments and gating are checked | Port-contract, exhaustive |
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
  original bytes or an entry/loop with no proved reachable caller or consumer;
  these are not omitted from the build.

## Remaining work to reach Quest-level evidence

The source reconstruction itself is complete and byte-exact, but the dynamic
validation depth is not yet equivalent to the Quest repository. Completion of
that broader standard requires:

1. Add replay-backed input, movement, collision, projectile, object lifecycle,
   score, sound, and screen-flow contracts.
2. Add an active-loop/full-frame comparison that records RAM and display
   effects for fixed initial state and input sequences.
3. Promote routines from static behavioral meaning to `port-contract` only
   when those fixtures or replays provide exact accept/reject evidence.

Until those gates exist and pass, this audit must not describe the runtime as
fully scenario-validated or port-contract complete.
