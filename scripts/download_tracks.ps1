$destDir = "assets\audio"

# باسم الكربلائي - archive.org
$basimFile = "%D8%A3%D9%82%D9%88%D9%84%20%D8%A7%D8%B3%D9%85%D9%83%20-%D8%A8%D8%A7%D8%B3%D9%85%20%D8%A7%D9%84%D9%83%D8%B1%D8%A8%D9%84%D8%A7%D8%A6%D9%8A.mp3"
$basimUrl = "https://archive.org/download/BasimKarbalaei/$basimFile"

Write-Host "Downloading Basim track..."
Invoke-WebRequest -Uri $basimUrl -OutFile "$destDir\basim_aqool_asmak.mp3" -UseBasicParsing -TimeoutSec 60
Write-Host "Downloaded: basim_aqool_asmak.mp3 - Size: $((Get-Item "$destDir\basim_aqool_asmak.mp3").Length / 1MB) MB"

# البحث عن مصادر أخرى محمد باقر الخاقاني وسيد سلام الحسيني وسيد فاقد
$otherIds = @(
    "khaqani_nawha_2023",
    "MuhammadBaqirKhaqani", 
    "SalamHussaini",
    "FaqidNawha",
    "SayedFaqid",
    "islamicnasheed2024"
)

foreach ($id in $otherIds) {
    try {
        $r = Invoke-WebRequest -Uri "https://archive.org/metadata/$id" -UseBasicParsing -TimeoutSec 8 -ErrorAction Stop
        $j = $r.Content | ConvertFrom-Json
        if ($j.files) {
            $mp3 = @($j.files | Where-Object { $_.name -like "*.mp3" }) | Select-Object -First 1
            if ($mp3) {
                Write-Host "FOUND: $id - $($mp3[0].name)"
            }
        }
    } catch { }
}

Write-Host "Done."
