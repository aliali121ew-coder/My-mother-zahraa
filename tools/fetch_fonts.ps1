# Fetch fonts script for Windows PowerShell
$ErrorActionPreference = 'Stop'
$base = 'https://raw.githubusercontent.com/google/fonts/main/ofl/amiri'
$dir  = Join-Path $PSScriptRoot '..\assets\fonts'
if (-not (Test-Path $dir)) {
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
}

# Cairo Variable Font
$cairo = Join-Path $dir 'Cairo-Variable.ttf'
if (-not (Test-Path $cairo) -or ((Get-Item $cairo).Length -lt 100000)) {
    Write-Host "Downloading Cairo-Variable.ttf..."
    Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/google/fonts/main/ofl/cairo/Cairo%5Bslnt%2Cwght%5D.ttf' -OutFile $cairo
}

# Amiri Regular and Bold
foreach ($w in @('Regular','Bold')) {
    $out = Join-Path $dir "Amiri-$w.ttf"
    if ((Test-Path $out) -and ((Get-Item $out).Length -gt 100000)) {
        Write-Host "Already exists: Amiri-$w.ttf"
        continue
    }
    Write-Host "Downloading Amiri-$w.ttf..."
    Invoke-WebRequest -Uri "$base/Amiri-$w.ttf" -OutFile $out
    $len = (Get-Item $out).Length
    $kb = [math]::Round($len / 1024)
    if ($kb -lt 100) {
        throw "Failed to download Amiri-$w.ttf (size $kb KB)"
    }
    Write-Host "Done: Amiri-$w.ttf ($kb KB)"
}

Write-Host "Font verification:"
$bad = $false
Get-ChildItem "$dir\*.ttf" | ForEach-Object {
    $bytes = [System.IO.File]::ReadAllBytes($_.FullName)[0..3]
    $hex = ($bytes | ForEach-Object { $_.ToString('x2') }) -join ''
    if ($hex -in @('00010000','74727565','4f54544f')) {
        Write-Host "  OK: $($_.Name)"
    } else {
        Write-Host "  FAILED: $($_.Name) (header $hex)"
        $bad = $true
    }
}

if ($bad) {
    throw "Corrupted fonts detected"
}

Write-Host "Ready. Run: flutter pub get"
