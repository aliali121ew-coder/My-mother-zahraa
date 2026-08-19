# محاولة تحميل ملفات صوتية حقيقية من archive.org
$destDir = "assets\audio"

# قائمة archive.org مع identifiers معروفة
$tracks = @(
    @{ id="BasimKarbalaei"; file="????????.mp3"; dest="basim_01.mp3" },
    @{ id="nawha_hussain_arabic_2023"; file=""; dest="" }
)

# الرابط المباشر لباسم الكربلائي من archive.org
$basimUrl = "https://archive.org/download/BasimKarbalaei/"

try {
    $r = Invoke-WebRequest -Uri $basimUrl -UseBasicParsing -TimeoutSec 15
    $links = $r.Links | Where-Object { $_.href -like "*.mp3" } | Select-Object -First 10
    Write-Host "MP3 links found: $($links.Count)"
    $links | ForEach-Object { Write-Host $_.href }
} catch {
    Write-Host "ERROR: $_"
}
