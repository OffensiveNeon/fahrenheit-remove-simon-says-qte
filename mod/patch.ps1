<#
Remove Simon Says QTE (Auto-Pass) - patcher for Fahrenheit: Indigo Prophecy Remastered.
PowerShell port of patch_qte.py + patch_text.py (same sites, same checks).

  patch.ps1 -Action Install   apply all patches (skips ones already applied)
  patch.ps1 -Action Uninstall restore FahrenheitSub.exe from its backup, put captions back
  patch.ps1 -Action Status    show the state of every patch site

Nothing is written unless every site holds the expected original (or patched) bytes.
#>
param([ValidateSet('Install', 'Uninstall', 'Status')][string]$Action = 'Install')

$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath $PSScriptRoot

$Exe = 'FahrenheitSub.exe'
$Backup = 'FahrenheitSub.exe.backup'
$Data = 'BigFile_PC.d02'

function Hex([string]$h) {
    $b = New-Object byte[] ($h.Length / 2)
    for ($i = 0; $i -lt $b.Length; $i++) { $b[$i] = [Convert]::ToByte($h.Substring($i * 2, 2), 16) }
    return , $b
}

function Site([int]$off, [string]$orig, [string]$new, [string]$desc) {
    [pscustomobject]@{ Off = $off; Orig = (Hex $orig); New = (Hex $new); Desc = $desc }
}

# Exe patches: (raw offset, original hex, patched hex). See patch_qte.py for the reasoning.
$ExeSites = @(
    (Site 0x0028F46C '20' '10' 'CHOOSE_ACTION fail -> won')
    (Site 0x003056F3 '20' '10' 'MULTI_CHOOSE fail #1 -> won')
    (Site 0x0030572B '20' '10' 'MULTI_CHOOSE fail #2 -> won')
    (Site 0x00308CA4 '20' '10' 'MULTI_CHOOSE post-loop fail -> won')
    (Site 0x0028F610 'f8' 'c0' 'CHOOSE outcome, transition path always wins')
    (Site 0x0028F641 'f8' 'c0' 'CHOOSE outcome, final path always wins')
    (Site 0x00282B48 '0b' '00' 'stick-input miss count always 0')
    (Site 0x0028DC5E 'e8adefedff' '83c4089090' 'hide QTE HUD: STICK_INPUT_FX')
    (Site 0x0032B237 'e8d419e4ff' '83c4089090' 'hide QTE HUD: STICK_INPUT_BACKGRND_FX #1')
    (Site 0x0032B245 'e8c619e4ff' '83c4089090' 'hide QTE HUD: STICK_INPUT_BACKGRND_FX #2')
    (Site 0x00305CA2 'e8696fe6ff' '83c4089090' 'hide QTE HUD: MULTI_CHOOSE_ACTION vt8')
    (Site 0x00305E1E 'e8ed6de6ff' '83c4089090' 'hide QTE HUD: MULTI_CHOOSE_ACTION 0x705CE0')
    (Site 0x0028EA83 '75' 'eb' 'hide Simon circles')
    (Site 0x0028F388 '44' '4c' 'hide Simon prompt display')
)

# QTE captions in the English text table (two copies), blanked with same-length spaces.
$TextSites = foreach ($t in @(
        @(0x375A72F0, 'GET READY!'), @(0x375A7320, 'GREAT!'), @(0x375A7340, 'LUCKY!'), @(0x375A7360, 'FAILED!'),
        @(0x375DE6F0, 'GET READY!'), @(0x375DE720, 'GREAT!'), @(0x375DE740, 'LUCKY!'), @(0x375DE760, 'FAILED!'))) {
    [pscustomobject]@{
        Off  = [long]$t[0]
        Orig = [Text.Encoding]::Unicode.GetBytes($t[1])
        New  = [Text.Encoding]::Unicode.GetBytes(' ' * $t[1].Length)
        Desc = $t[1]
    }
}

function Same([byte[]]$a, [byte[]]$b) {
    if ($a.Length -ne $b.Length) { return $false }
    for ($i = 0; $i -lt $a.Length; $i++) { if ($a[$i] -ne $b[$i]) { return $false } }
    return $true
}

function Slice([byte[]]$buf, [long]$off, [int]$n) {
    $out = New-Object byte[] $n
    if ($off + $n -le $buf.Length) { [Array]::Copy($buf, $off, $out, 0, $n) }
    return , $out
}

function ReadAt([IO.FileStream]$fs, [long]$off, [int]$n) {
    $out = New-Object byte[] $n
    $fs.Position = $off
    [void]$fs.Read($out, 0, $n)
    return , $out
}

function StateOf($site, [byte[]]$cur) {
    if (Same $cur $site.New) { 'PATCHED' } elseif (Same $cur $site.Orig) { 'original' } else { 'UNKNOWN' }
}

function Need([string]$f) {
    if (-not (Test-Path -LiteralPath $f)) { throw "$f not found in $PSScriptRoot" }
}

function Install-Exe {
    Need $Exe
    if (-not (Test-Path -LiteralPath $Backup)) {
        Write-Host "creating $Backup"
        Copy-Item -LiteralPath $Exe -Destination $Backup
    }
    $path = Join-Path $PSScriptRoot $Exe
    $buf = [IO.File]::ReadAllBytes($path)
    $applied = 0; $already = 0; $bad = @()
    foreach ($s in $ExeSites) {
        $state = StateOf $s (Slice $buf $s.Off $s.Orig.Length)
        if ($state -eq 'PATCHED') { $already++ }
        elseif ($state -eq 'original') { [Array]::Copy($s.New, 0, $buf, $s.Off, $s.New.Length); $applied++ }
        else { $bad += $s }
    }
    if ($bad.Count) {
        foreach ($s in $bad) { Write-Host ('  unexpected bytes at 0x{0:X8} -- {1}' -f $s.Off, $s.Desc) }
        throw "$Exe doesn't match the expected version. Nothing was written."
    }
    if ($applied) { [IO.File]::WriteAllBytes($path, $buf) }
    Write-Host "exe: applied $applied, already patched $already, total $($ExeSites.Count)"
}

function Set-Text([bool]$blank) {
    Need $Data
    $fs = [IO.File]::Open((Join-Path $PSScriptRoot $Data), 'Open', 'ReadWrite')
    try {
        foreach ($s in $TextSites) {
            if ((StateOf $s (ReadAt $fs $s.Off $s.Orig.Length)) -eq 'UNKNOWN') {
                throw ('{0} has unexpected bytes at 0x{1:X8} ({2}). Nothing was written.' -f $Data, $s.Off, $s.Desc)
            }
        }
        $changed = 0
        foreach ($s in $TextSites) {
            $want = if ($blank) { $s.New } else { $s.Orig }
            if (-not (Same (ReadAt $fs $s.Off $want.Length) $want)) {
                $fs.Position = $s.Off
                $fs.Write($want, 0, $want.Length)
                $changed++
            }
        }
    } finally { $fs.Close() }
    Write-Host "captions: $(if ($blank) { 'blanked' } else { 'restored' }) $changed, total $($TextSites.Count)"
}

function Show-Status {
    Need $Exe
    $buf = [IO.File]::ReadAllBytes((Join-Path $PSScriptRoot $Exe))
    foreach ($s in $ExeSites) {
        Write-Host ('  0x{0:X8}  {1,-9} {2}' -f $s.Off, (StateOf $s (Slice $buf $s.Off $s.Orig.Length)), $s.Desc)
    }
    Need $Data
    $fs = [IO.File]::OpenRead((Join-Path $PSScriptRoot $Data))
    try {
        foreach ($s in $TextSites) {
            Write-Host ('  0x{0:X8}  {1,-9} caption "{2}"' -f $s.Off, (StateOf $s (ReadAt $fs $s.Off $s.Orig.Length)), $s.Desc)
        }
    } finally { $fs.Close() }
}

try {
    switch ($Action) {
        'Install' { Install-Exe; Set-Text $true }
        'Uninstall' {
            Need $Backup
            Copy-Item -LiteralPath $Backup -Destination $Exe -Force
            Write-Host "exe: restored $Exe from $Backup"
            Set-Text $false
        }
        'Status' { Show-Status }
    }
} catch {
    Write-Host "ERROR: $($_.Exception.Message)"
    exit 1
}
exit 0
