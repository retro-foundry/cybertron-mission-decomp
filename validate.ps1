param(
    [string]$BeebAsm
)

$ErrorActionPreference = 'Stop'
$repoRoot = $PSScriptRoot
$source = Join-Path $repoRoot 'source_acorn_electron\cyber1.asm'
$payload = Join-Path $repoRoot 'build\reconstruction\CYBRUN'
$expectedLength = 0x2280
$expectedSha256 = '29D4BED6A2BF6A3F93302F01B05FE43EC930528EAF702E679B73D2FD2476BEEF'

$requiredFiles = @(
    'README.md'
    'build.ps1'
    'validate.ps1'
    'source_acorn_electron/cyber1.asm'
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
if ($assemblyText -match '(?im)^\s*(?:INCBIN|INCLUDE)\b') {
    throw 'cyber1.asm must remain standalone and may not include source or binary fragments.'
}
if ($assemblyText -notmatch '(?im)^\s*runtime_start\s*=\s*&0D80\s*$') {
    throw 'cyber1.asm no longer declares the expected runtime load address $0D80.'
}
if ($assemblyText -notmatch '(?im)^\s*runtime_entry\s*=\s*&0E02\s*$') {
    throw 'cyber1.asm no longer declares the expected runtime entry address $0E02.'
}
if ($assemblyText -notmatch '(?im)^\s*SAVE\s+"CYBRUN",\s*runtime_start,\s*runtime_end,\s*runtime_entry\s*$') {
    throw 'cyber1.asm no longer saves the expected CYBRUN runtime payload.'
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
