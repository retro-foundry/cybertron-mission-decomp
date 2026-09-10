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
    'source_acorn_electron/README.md'
    'source_acorn_electron/reconstruction.json'
    'analysis/reconstruction/semantic_completion_audit.md'
    'analysis/reconstruction/runtime_room_render_reference.txt'
    'analysis/reconstruction/room_render_fixture.json'
    'analysis/reconstruction/runtime_status_panel_reference.txt'
    'analysis/reconstruction/runtime_sprite_renderer_reference.txt'
    'analysis/reconstruction/runtime_setup_frame_reference.txt'
    'analysis/reconstruction/runtime_control_input_reference.txt'
    'analysis/reconstruction/runtime_player_movement.txt'
    'analysis/reconstruction/runtime_enemy_movement_contract.txt'
    'analysis/reconstruction/runtime_player_collision_contract.txt'
    'analysis/reconstruction/runtime_inert_source_contract.txt'
    'analysis/reconstruction/runtime_object_lifecycle_reference.txt'
    'analysis/reconstruction/runtime_object_slot_contract.txt'
    'analysis/reconstruction/runtime_projectile_lifecycle.txt'
    'analysis/reconstruction/runtime_score_status_contract.txt'
    'analysis/reconstruction/runtime_active_frame_edge_contract.txt'
    'analysis/reconstruction/runtime_sound_dispatch_audit.txt'
    'analysis/reconstruction/runtime_sound_port_semantics.txt'
    'analysis/reconstruction/runtime_screen_flow_contract.txt'
    'tools/reconstruction/replay_6502.py'
    'tools/reconstruction/render_graphic_sheet.py'
    'tools/reconstruction/validate_port_contracts.py'
    'analysis/reconstruction/composed_sprite_sheet.png'
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
    (Join-Path $repoRoot 'source_acorn_electron\README.md')
    (Join-Path $repoRoot 'source_acorn_electron\reconstruction.json')
    (Join-Path $repoRoot 'analysis\reconstruction\semantic_completion_audit.md')
    (Join-Path $repoRoot 'analysis\reconstruction\runtime_room_render_reference.txt')
    (Join-Path $repoRoot 'analysis\reconstruction\room_render_fixture.json')
    (Join-Path $repoRoot 'analysis\reconstruction\runtime_status_panel_reference.txt')
    (Join-Path $repoRoot 'analysis\reconstruction\runtime_sprite_renderer_reference.txt')
    (Join-Path $repoRoot 'analysis\reconstruction\runtime_setup_frame_reference.txt')
    (Join-Path $repoRoot 'analysis\reconstruction\runtime_control_input_reference.txt')
    (Join-Path $repoRoot 'analysis\reconstruction\runtime_player_movement.txt')
    (Join-Path $repoRoot 'analysis\reconstruction\runtime_enemy_movement_contract.txt')
    (Join-Path $repoRoot 'analysis\reconstruction\runtime_player_collision_contract.txt')
    (Join-Path $repoRoot 'analysis\reconstruction\runtime_inert_source_contract.txt')
    (Join-Path $repoRoot 'analysis\reconstruction\runtime_object_lifecycle_reference.txt')
    (Join-Path $repoRoot 'analysis\reconstruction\runtime_object_slot_contract.txt')
    (Join-Path $repoRoot 'analysis\reconstruction\runtime_projectile_lifecycle.txt')
    (Join-Path $repoRoot 'analysis\reconstruction\runtime_score_status_contract.txt')
    (Join-Path $repoRoot 'analysis\reconstruction\runtime_active_frame_edge_contract.txt')
    (Join-Path $repoRoot 'analysis\reconstruction\runtime_sound_dispatch_audit.txt')
    (Join-Path $repoRoot 'analysis\reconstruction\runtime_sound_port_semantics.txt')
    (Join-Path $repoRoot 'analysis\reconstruction\runtime_screen_flow_contract.txt')
    (Join-Path $repoRoot 'tools\reconstruction\replay_6502.py')
    (Join-Path $repoRoot 'tools\reconstruction\render_graphic_sheet.py')
    (Join-Path $repoRoot 'tools\reconstruction\validate_port_contracts.py')
)
foreach ($maintainedFile in $maintainedFiles) {
    $nonAsciiByte = [System.IO.File]::ReadAllBytes($maintainedFile) |
        Where-Object { $_ -gt 0x7F } |
        Select-Object -First 1
    if ($null -ne $nonAsciiByte) {
        throw "Standalone maintained file is not ASCII-only: $maintainedFile"
    }
}

$rendererScript = Join-Path $repoRoot 'tools\reconstruction\render_graphic_sheet.py'
$replayScript = Join-Path $repoRoot 'tools\reconstruction\replay_6502.py'
$pythonCommand = Get-Command python -ErrorAction SilentlyContinue
if ($null -eq $pythonCommand) {
    throw 'Python 3 is required to syntax-check the bundled reconstruction tool.'
}
& $pythonCommand.Source -c 'import ast, pathlib, sys; ast.parse(pathlib.Path(sys.argv[1]).read_bytes())' $rendererScript
if ($LASTEXITCODE -ne 0) {
    throw 'The bundled graphic-sheet renderer does not parse as Python.'
}
& $pythonCommand.Source -c 'import ast, pathlib, sys; ast.parse(pathlib.Path(sys.argv[1]).read_bytes())' $replayScript
if ($LASTEXITCODE -ne 0) {
    throw 'The bundled 6502 replay core does not parse as Python.'
}

$assemblyText = Get-Content -LiteralPath $source -Raw
$memoryMapText = Get-Content -LiteralPath $memoryMap -Raw
$manifestPath = Join-Path $repoRoot 'source_acorn_electron\reconstruction.json'
$manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
if ($manifest.authority.load_address -ne 0x0D80 -or
    $manifest.authority.execution_address -ne 0x0E02 -or
    $manifest.authority.end_exclusive -ne 0x3000 -or
    $manifest.source_owned_payload_bytes -ne $expectedLength -or
    $manifest.authority.sha256.ToUpperInvariant() -ne $expectedSha256) {
    throw 'reconstruction.json does not match the validated CYBRUN authority contract.'
}
if ($manifest.semantic_annotation_completion.status -ne 'complete' -or
    $manifest.semantic_annotation_completion.unresolved_active_code_or_data_ranges -ne 0 -or
    $manifest.semantic_annotation_completion.audit -ne 'analysis/reconstruction/semantic_completion_audit.md' -or
    $manifest.semantic_annotation_completion.inert_contract -ne 'analysis/reconstruction/runtime_inert_source_contract.txt') {
    throw 'reconstruction.json no longer declares the validated semantic completion contract.'
}
$nextManifestAddress = $manifest.authority.load_address
foreach ($range in $manifest.data_ranges) {
    if ($range.runtime_start -ne $nextManifestAddress -or
        $range.runtime_end_exclusive -le $range.runtime_start) {
        throw "reconstruction.json has a gap, overlap, or empty range at $($range.name)."
    }
    $nextManifestAddress = $range.runtime_end_exclusive
}
if ($nextManifestAddress -ne $manifest.authority.end_exclusive) {
    throw 'reconstruction.json ranges do not cover the complete CYBRUN payload.'
}
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
$numericInstructionPattern = '(?im)^\s*(?:ADC|AND|ASL|BIT|CMP|CPX|CPY|DEC|EOR|INC|JMP|JSR|LDA|LDX|LDY|LSR|ORA|ROL|ROR|SBC|STA|STX|STY)\s+#?(?:&[0-9A-F]+|\$[0-9A-F]+|%[01]+|[0-9]+)(?:\s*,\s*[XY])?\s*(?:;.*)?$'
$numericInstructions = [regex]::Matches($assemblyText, $numericInstructionPattern)
if ($numericInstructions.Count -ne 0) {
    throw "Raw numeric operand in cyber1.asm; use a named constant or label: $($numericInstructions[0].Value.Trim())"
}
$relativeNumericOperandPattern = '(?im)^\s*(?:ADC|AND|ASL|BIT|CMP|CPX|CPY|DEC|EOR|INC|JMP|JSR|LDA|LDX|LDY|LSR|ORA|ROL|ROR|SBC|STA|STX|STY)\s+.*[A-Z_][A-Z0-9_]*[+-][0-9]+(?:\s*,\s*[XY])?\s*(?:;.*)?$'
$relativeNumericOperands = [regex]::Matches($assemblyText, $relativeNumericOperandPattern)
if ($relativeNumericOperands.Count -ne 0) {
    throw "Raw symbol-relative operand in cyber1.asm; use a named offset or alias: $($relativeNumericOperands[0].Value.Trim())"
}

if ($assemblyText -match '(?im)^\s*\.addr_[0-9A-F]+\s*$') {
    throw 'Generic address-only labels are not permitted in cyber1.asm; name the control-flow purpose.'
}
if ($assemblyText -match '(?im)^\s*\.(?:byte_decoded|unclassified)_[A-Za-z0-9_]+\s*$') {
    throw 'Generic decoded/unclassified labels are not permitted in cyber1.asm; document the proven source role.'
}
if ($assemblyText -match '(?im)^\s*\.(?:unknown|orphan|unreferenced|FUN_[0-9A-F]+|enter_[0-9A-F]+)[A-Za-z0-9_]*\s*$') {
    throw 'Uncertain or raw address-derived source labels are not permitted in cyber1.asm.'
}
if ($assemblyText -match '(?im)^\s*\.graphic_record_[0-9A-F]+\s*$') {
    throw 'Numeric graphic-record labels are not permitted; name the proved artwork or runtime role.'
}
$graphicIdMatches = [regex]::Matches($assemblyText, '(?im)^\s*; graphic_id \$(?<id>[0-9A-F]{2})\s*$')
if ($graphicIdMatches.Count -ne 64) {
    throw "cyber1.asm must annotate exactly 64 graphic records with consecutive graphic_id comments; found $($graphicIdMatches.Count)."
}
for ($graphicIdIndex = 0; $graphicIdIndex -lt 64; $graphicIdIndex++) {
    $actualGraphicId = [Convert]::ToInt32($graphicIdMatches[$graphicIdIndex].Groups['id'].Value, 16)
    if ($actualGraphicId -ne $graphicIdIndex) {
        throw ('Graphic ID annotation {0} is ${1:X2}; expected ${0:X2}.' -f $graphicIdIndex, $actualGraphicId)
    }
}
$graphicUsageCount = [regex]::Matches($assemblyText, '(?im)^\s*; graphic_usage status=').Count
if ($graphicUsageCount -ne 64) {
    throw "Every graphic record must carry a graphic_usage evidence annotation; found $graphicUsageCount of 64."
}
if (($assemblyText + "`n" + $memoryMapText) -match '(?i)\b(?:zp_)?scratch[A-Za-z0-9_]*\b') {
    throw 'Generic scratch names are not permitted; use a contextual alias for each bounded lifetime.'
}

$assemblyLines = Get-Content -LiteralPath $source
$activeDataOwner = $null
$instructionPattern = '^\s*(?:ADC|AND|ASL|BCC|BCS|BEQ|BIT|BMI|BNE|BPL|BRK|BVC|BVS|CLC|CLD|CLI|CLV|CMP|CPX|CPY|DEC|DEX|DEY|EOR|INC|INX|INY|JMP|JSR|LDA|LDX|LDY|LSR|NOP|ORA|PHA|PHP|PLA|PLP|ROL|ROR|RTI|RTS|SBC|SEC|SED|SEI|STA|STX|STY|TAX|TAY|TSX|TXA|TXS|TYA)(?:\s|$)'
for ($assemblyLineIndex = 0; $assemblyLineIndex -lt $assemblyLines.Count; $assemblyLineIndex++) {
    $assemblyLine = $assemblyLines[$assemblyLineIndex]
    if ($assemblyLine -match '^\s*ORG\s') {
        $activeDataOwner = $null
    }
    elseif ($assemblyLine -match '^\s*\.([A-Za-z_][A-Za-z0-9_]*)\s*$') {
        $activeDataOwner = $Matches[1]
    }
    elseif ($assemblyLine -match $instructionPattern) {
        $activeDataOwner = $null
    }
    elseif ($assemblyLine -match '^\s*(?:EQUB|EQUW|EQUS)(?:\s|$)' -and $null -eq $activeDataOwner) {
        throw "Unlabelled emitted data in cyber1.asm at line $($assemblyLineIndex + 1): $($assemblyLine.Trim())"
    }
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

$portContractScript = Join-Path $repoRoot 'tools\reconstruction\validate_port_contracts.py'
& $pythonCommand.Source $portContractScript $payload
if ($LASTEXITCODE -ne 0) {
    throw 'CYBRUN failed the standalone port preflight contracts.'
}

Write-Output ('Validated CYBRUN: {0} bytes, SHA-256 {1}' -f $actualLength, $actualSha256)
