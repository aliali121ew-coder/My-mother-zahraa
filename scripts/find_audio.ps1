$ids = @('KhaqaniLatmiyat','basim-karbalaei-nawha','BasimKarbalaei','latmiyat-hussainiya','nawha-hussain-2024','salam-hussaini-nawha','MohammadBaqirKhaqani','latmiyat-arabic','hussaini-nawha-arabic','BasimAlKarbalaei2023','islamicaudio-nawha')
foreach ($id in $ids) {
    try {
        $url = "https://archive.org/metadata/$id"
        $r = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 8 -ErrorAction Stop
        $j = $r.Content | ConvertFrom-Json
        if ($j.files) {
            $mp3s = @($j.files | Where-Object { $_.name -like "*.mp3" } | Select-Object -First 3)
            if ($mp3s.Count -gt 0) {
                Write-Host "FOUND: $id"
                $mp3s | ForEach-Object { Write-Host "  FILE: $($_.name)" }
            }
        }
    } catch {
        Write-Host "SKIP: $id"
    }
}
Write-Host "Search complete."
