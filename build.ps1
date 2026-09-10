param(
    [string]$BeebAsm
)

$ErrorActionPreference = 'Stop'
$repoRoot = $PSScriptRoot
$outputDirectory = Join-Path $repoRoot 'build\reconstruction'
$source = Join-Path $repoRoot 'source_acorn_electron\cyber1.asm'
$payload = Join-Path $outputDirectory 'CYBRUN'
$labels = Join-Path $outputDirectory 'cyber1.labels'

if (-not $BeebAsm) {
    $beebAsmCommand = Get-Command beebasm -ErrorAction SilentlyContinue
    if (-not $beebAsmCommand) {
        throw 'BeebAsm is required. Put beebasm on PATH or pass -BeebAsm <path>.'
    }
    $BeebAsm = $beebAsmCommand.Source
}

$BeebAsm = [System.IO.Path]::GetFullPath($BeebAsm)
if (-not (Test-Path -LiteralPath $BeebAsm -PathType Leaf)) {
    throw "BeebAsm executable does not exist: $BeebAsm"
}
if (-not (Test-Path -LiteralPath $source -PathType Leaf)) {
    throw "Maintained assembly source does not exist: $source"
}

New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
Remove-Item -LiteralPath $payload, $labels -Force -ErrorAction SilentlyContinue

Push-Location $outputDirectory
try {
    & $BeebAsm -i $source -d -labels $labels
    if ($LASTEXITCODE -ne 0) {
        throw "BeebAsm failed with exit code $LASTEXITCODE"
    }
}
finally {
    Pop-Location
}

if (-not (Test-Path -LiteralPath $payload -PathType Leaf)) {
    throw "BeebAsm completed without producing the expected payload: $payload"
}

Write-Output "Rebuilt runtime: $payload"
Write-Output "Labels:          $labels"
