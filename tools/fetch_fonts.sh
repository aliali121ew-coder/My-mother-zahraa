#!/usr/bin/env bash
# جلب خطوط المشروع — يُشغَّل بعد الاستنساخ وفي CI قبل البناء.
#
# الخطوط لا تُودَع في المستودع لسببين:
#  ١) أدوات الرفع الآلية ترمّز الملفات الثنائية base64 مرتين فتُفسدها
#  ٢) حدث فعلاً: أُودعت أربعة ملفات باسم Cairo-*.ttf وكانت صفحات HTML
#     (تبدأ بـ <!DOCTYPE html>)، فكان Flutter يرتدّ صامتاً للخط الافتراضي
#     وخط كايرو لم يُطبَّق يوماً رغم أن الـcommit يقول إنه طُبِّق.
# السكربت يتحقّق من البصمة السحرية لكل ملف فلا يتكرر ذلك.
set -euo pipefail

BASE="https://raw.githubusercontent.com/google/fonts/main/ofl/amiri"
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/assets/fonts"
mkdir -p "$DIR"

# كايرو: النسخة المتغيّرة — لا توجد أوزان ثابتة في مستودع Google Fonts
CAIRO_URL="https://raw.githubusercontent.com/google/fonts/main/ofl/cairo/Cairo%5Bslnt%2Cwght%5D.ttf"
cairo="$DIR/Cairo-Variable.ttf"
if [ ! -f "$cairo" ] || [ "$(stat -c%s "$cairo" 2>/dev/null || stat -f%z "$cairo")" -lt 100000 ]; then
  echo "  تنزيل Cairo-Variable.ttf ..."
  curl -sSL --max-time 120 -o "$cairo" "$CAIRO_URL"
fi

for w in Regular Bold; do
  out="$DIR/Amiri-$w.ttf"
  if [ -f "$out" ] && [ "$(stat -c%s "$out" 2>/dev/null || stat -f%z "$out")" -gt 100000 ]; then
    echo "  موجود مسبقاً: Amiri-$w.ttf"
    continue
  fi
  echo "  تنزيل Amiri-$w.ttf ..."
  curl -sSL --max-time 90 -o "$out" "$BASE/Amiri-$w.ttf"
  sz=$(stat -c%s "$out" 2>/dev/null || stat -f%z "$out")
  if [ "$sz" -lt 100000 ]; then
    echo "  فشل التنزيل: الحجم $sz بايت فقط" >&2
    rm -f "$out"; exit 1
  fi
  echo "  تم: Amiri-$w.ttf ($((sz/1024)) KB)"
done

# التحقّق من البصمة السحرية: ملف الخط السليم يبدأ بـ 00 01 00 00
echo
echo "التحقّق من سلامة الخطوط:"
bad=0
for f in "$DIR"/*.ttf; do
  magic=$(head -c 4 "$f" | od -An -tx1 | tr -d ' \n')
  case "$magic" in
    00010000|74727565|4f54544f) echo "  ✓ $(basename "$f")" ;;
    *) echo "  ✗ $(basename "$f") تالف (بصمة $magic)"; bad=1 ;;
  esac
done
[ "$bad" = "1" ] && { echo "خطوط تالفة — احذفها وأعد التشغيل" >&2; exit 1; }

echo
echo "جاهز. شغّل الآن: flutter pub get"
