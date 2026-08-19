$json = Invoke-WebRequest -Uri "https://archive.org/metadata/BasimKarbalaei" -UseBasicParsing -TimeoutSec 15 | Select-Object -ExpandProperty Content | ConvertFrom-Json
$mp3s = @($json.files | Where-Object { $_.name -like "*.mp3" })
Write-Host "Total MP3 files: $($mp3s.Count)"
$mp3s | Select-Object -First 20 | ForEach-Object { Write-Host "  $($_.name)" }
