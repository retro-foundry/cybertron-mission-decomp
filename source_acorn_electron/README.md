# Cybertron Mission Acorn Electron source

This directory contains the standalone, byte-exact BeebAsm reconstruction of
the relocated Acorn Electron `CYBRUN` gameplay runtime.

## Source files

- `cyber1.asm` contains every instruction, table, text byte, room record,
  graphic record, initial state byte, and original unused byte in the runtime.
- `memory_map.inc` names the MOS entry points, runtime state, arrays,
  self-modifying operands, screen locations, and build addresses.
- `reconstruction.json` records the source-owned ranges and the evidence used
  to classify them.

The build has no `INCBIN`, generated layout include, extracted binary slice,
or dependency on an original executable. The byte authority is represented by
the expected length and SHA-256 in `validate.ps1`.

## Source conventions

- Preserve NMOS 6502 behavior and the original `$0D80-$2FFF` byte layout.
- Use named addresses from `memory_map.inc` in executable code.
- Describe behavior only where control flow, dataflow, bounded consumers, or
  decoded artwork supports it.
- Mark retained no-caller code and no-consumer data explicitly as unused.
- Keep numeric graphic record names where artwork identity is not proven.
- Keep source and comments ASCII-only.

Build and validate from the repository root with `./build.ps1` and
`./validate.ps1`. Generated output is written below ignored
`build/reconstruction/`.
