# جلب خطوط Amiri النسخية — شغّله مرة واحدة بعد استنساخ المستودع.
#
# لماذا لا تُودَع الخطوط في المستودع مباشرة؟ لأن أداة الرفع الآلية لدى
# الوكيل ترمّز الملفات الثنائية مرتين فتُفسدها. جلبها بسكربت أضمن، ويبقي
# المستودع أخفّ. خطوط IBM Plex موجودة أصلاً لأنها رُفعت بـ git مباشرة.
#
#   powershell -ExecutionPolicy Bypass -File tools\fetch_fonts.ps1

$ErrorActionPreference = 'Stop'
$base = 'https://raw.githubusercontent.com/google/fonts/main/ofl/amiri'
$dir  = Join-Path $PSScriptRoot '..\assets\fonts'
New-Item -ItemType Directory -Force -Path $dir | Out-Null

# كايرو المتغيّر
$cairo = Join-Path $dir 'Cairo-Variable.ttf'
if (-not (Test-Path $cairo) -or (Get-Item $cairo).Length -lt 100000) {
    Write-Host "  تنزيل Cairo-Variable.ttf ..."
    Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/google/fonts/main/ofl/cairo/Cairo%5Bslnt%2Cwght%5D.ttf' -OutFile $cairo
}

foreach ($w in @('Regular','Bold')) {
    $out = Join-Path $dir "Amiri-$w.ttf"
    if ((Test-Path $out) -and ((Get-Item $out).Length -gt 100000)) {
        Write-Host "  موجود مسبقاً: Amiri-$w.ttf"
        continue
    }
    Write-Host "  تنزيل Amiri-$w.ttf ..."
    Invoke-WebRequest -Uri "$base/Amiri-$w.ttf" -OutFile $out
    $kb = [math]::Round((Get-Item $out).Length / 1KB)
    if ($kb -lt 100) { throw "فشل التنزيل: Amiri-$w.ttf حجمه $kb KB فقط" }
    Write-Host "  تم: Amiri-$w.ttf ($kb KB)"
}

# التحقّق من البصمة السحرية — ملف خط سليم يبدأ بـ 00 01 00 00
Write-Host "`nالتحقّق من سلامة الخطوط:"
$bad = $false
Get-ChildItem "$dir\*.ttf" | ForEach-Object {
    $b = [System.IO.File]::ReadAllBytes($_.FullName)[0..3]
    $m = ($b | ForEach-Object { $_.ToString('x2') }) -join ''
    if ($m -in @('00010000','74727565','4f54544f')) { Write-Host "  ✓ $($_.Name)" }
    else { Write-Host "  ✗ $($_.Name) تالف (بصمة $m)"; $bad = $true }
}
if ($bad) { throw 'خطوط تالفة — احذفها وأعد التشغيل' }

Write-Host "`nجاهز. شغّل الآن: flutter pub get"
