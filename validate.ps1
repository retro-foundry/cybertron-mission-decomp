param(
    [string]$BeebAsm
)

$ErrorActionPreference = 'Stop'
$repoRoot = $PSScriptRoot
$source = Join-Path $repoRoot 'source_acorn_electron\cyber1.asm'
$memoryMap = Join-Path $repoRoot 'source_acorn_electron\memory_map.inc'
$payload = Join-Path $repoRoot 'build\reconstruction\CYBRUN'
$expectedLength = 0x2280
$expectedSha256 = '29D4BED6A2BF6A3F93302F01B05FE43EC930528EAF702E679B73D2FD2476BEEF'

$requiredFiles = @(
    'README.md'
    'build.ps1'
    'validate.ps1'
    'source_acorn_electron/cyber1.asm'
    'source_acorn_electron/memory_map.inc'
)
foreach ($relativePath in $requiredFiles) {
    $requiredPath = Join-Path $repoRoot $relativePath
    if (-not (Test-Path -LiteralPath $requiredPath -PathType Leaf)) {
        throw "Standalone source dependency is missing: $relativePath"
    }
}

$maintainedFiles = @(
    (Join-Path $repoRoot 'README.md')
    (Join-Path $repoRoot 'build.ps1')
    (Join-Path $repoRoot 'validate.ps1')
    $source
    $memoryMap
)
foreach ($maintainedFile in $maintainedFiles) {
    $nonAsciiByte = [System.IO.File]::ReadAllBytes($maintainedFile) |
        Where-Object { $_ -gt 0x7F } |
        Select-Object -First 1
    if ($null -ne $nonAsciiByte) {
        throw "Standalone maintained file is not ASCII-only: $maintainedFile"
    }
}

$assemblyText = Get-Content -LiteralPath $source -Raw
$memoryMapText = Get-Content -LiteralPath $memoryMap -Raw
if ($assemblyText -match '(?im)^\s*INCBIN\b') {
    throw 'cyber1.asm must remain source-owned and may not include binary fragments.'
}
if ($assemblyText -notmatch '(?im)^\s*INCLUDE\s+"source_acorn_electron/memory_map\.inc"\s*$') {
    throw 'cyber1.asm must include the maintained source_acorn_electron/memory_map.inc memory map.'
}
if ($memoryMapText -notmatch '(?im)^\s*runtime_start\s*=\s*&0D80\s*$') {
    throw 'memory_map.inc no longer declares the expected runtime load address $0D80.'
}
if ($memoryMapText -notmatch '(?im)^\s*runtime_entry\s*=\s*&0E02\s*$') {
    throw 'memory_map.inc no longer declares the expected runtime entry address $0E02.'
}
if ($assemblyText -notmatch '(?im)^\s*SAVE\s+"build/reconstruction/CYBRUN",\s*runtime_start,\s*runtime_end,\s*runtime_entry\s*$') {
    throw 'cyber1.asm no longer saves the expected CYBRUN runtime payload.'
}

$rawAbsoluteOperandPattern = '(?im)^\s*(?:ADC|AND|BIT|CMP|CPX|CPY|DEC|EOR|INC|JMP|JSR|LDA|LDX|LDY|ORA|SBC|STA|STX|STY)\s+(?:&|\$)[0-9A-F]+(?:\s*,\s*[XY])?\s*(?:;.*)?$'
$rawAbsoluteOperands = [regex]::Matches($assemblyText, $rawAbsoluteOperandPattern)
if ($rawAbsoluteOperands.Count -ne 0) {
    throw "Raw absolute operand in cyber1.asm; use a memory-map symbol: $($rawAbsoluteOperands[0].Value.Trim())"
}

if ($assemblyText -match '(?im)^\s*\.addr_[0-9A-F]+\s*$') {
    throw 'Generic address-only labels are not permitted in cyber1.asm; name the control-flow purpose.'
}
if ($assemblyText -match '(?im)^\s*\.(?:byte_decoded|unclassified)_[A-Za-z0-9_]+\s*$') {
    throw 'Generic decoded/unclassified labels are not permitted in cyber1.asm; document the proven source role.'
}

& (Join-Path $repoRoot 'build.ps1') -BeebAsm $BeebAsm

$actualLength = (Get-Item -LiteralPath $payload).Length
if ($actualLength -ne $expectedLength) {
    throw ('CYBRUN has length ${0:X}, expected ${1:X}.' -f $actualLength, $expectedLength)
}

$actualSha256 = (Get-FileHash -LiteralPath $payload -Algorithm SHA256).Hash
if ($actualSha256 -ne $expectedSha256) {
    throw "CYBRUN SHA-256 is $actualSha256, expected $expectedSha256."
}

Write-Output ('Validated CYBRUN: {0} bytes, SHA-256 {1}' -f $actualLength, $actualSha256)
