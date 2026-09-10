# Cybertron Mission Acorn Electron runtime source reconstruction

This repository contains a complete, byte-exact BeebAsm reconstruction of the
relocated Acorn Electron `CYBRUN` gameplay runtime from *Cybertron Mission*.
Executable code, data tables, text, room layouts, and graphics are declared in
the maintained source file:

- `source_acorn_electron/cyber1.asm`

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
project, so validation requires no copyrighted original media.

## Layout and provenance

`CYBRUN` is the relocated runtime view used by the game logic. It loads at
`$0D80`, enters at `$0E02`, and ends at `$3000`. The source preserves original
addresses, memory aliases, self-modifying operands, Acorn screen-memory layout,
and 6502 behavior.

Names and comments distinguish proved behavior from unresolved data. Labels
such as `byte_decoded_*`, `unclassified_*`, and numeric graphic records remain
conservative where the available evidence does not justify a stronger meaning.

This is reconstructed source, not the original author's source. The original
game and its assets remain the property of their respective copyright holders.
No original title program or release media is included here.
