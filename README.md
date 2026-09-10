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

The decoded 24-byte artwork can be reviewed in the
[composed sprite and graphic sheet](analysis/reconstruction/composed_sprite_sheet.png).

This is reconstructed source, not the original author's source. The original
game and its assets remain the property of their respective copyright holders.
No original title program or release media is included here.
