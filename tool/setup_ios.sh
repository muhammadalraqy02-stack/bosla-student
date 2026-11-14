#!/bin/bash
# تجهيز مشروع iOS لتطبيق «بوصلة الطالب» — يُشغَّل مرة واحدة على جهاز Mac فيه Flutter و Xcode و CocoaPods
#   bash tool/setup_ios.sh                      (المعرّف الافتراضي com.bosla2026.app)
#   bash tool/setup_ios.sh com.example.myapp    (معرّف Bundle ID آخر)
set -euo pipefail
cd "$(dirname "$0")/.."

BUNDLE_ID="${1:-com.bosla2026.app}"
APP_NAME="بوصلة الطالب"
PLIST="ios/Runner/Info.plist"
PB="/usr/libexec/PlistBuddy"

echo "==> إنشاء مجلد ios (لا يستبدل ملفات lib أو pubspec)"
flutter create --platforms=ios --org com.bosla2026 --project-name bosla_student .

echo "==> ضبط Bundle ID: $BUNDLE_ID"
perl -pi -e 's/PRODUCT_BUNDLE_IDENTIFIER = [^;]*?(\.RunnerTests)?;/PRODUCT_BUNDLE_IDENTIFIER = '"$BUNDLE_ID"'$1;/g' ios/Runner.xcodeproj/project.pbxproj

setkey() { # المفتاح، النوع، القيمة
  $PB -c "Delete :$1" "$PLIST" >/dev/null 2>&1 || true
  $PB -c "Add :$1 $2 $3" "$PLIST"
}
echo "==> ضبط Info.plist (الاسم، اللغة، نصوص الأذونات)"
setkey CFBundleDisplayName string "$APP_NAME"
setkey CFBundleDevelopmentRegion string ar
$PB -c "Delete :CFBundleLocalizations" "$PLIST" >/dev/null 2>&1 || true
$PB -c "Add :CFBundleLocalizations array" "$PLIST"
$PB -c "Add :CFBundleLocalizations:0 string ar" "$PLIST"
setkey ITSAppUsesNonExemptEncryption bool false
setkey NSCameraUsageDescription string "تُستخدم الكاميرا فقط عند اختيارك التقاط صورة لمؤسسة تعليمية تقترح إضافتها إلى الدليل."
setkey NSPhotoLibraryUsageDescription string "يُستخدم الوصول إلى الصور فقط عند اختيارك صورة ترفقها باقتراح إضافة إلى الدليل."
setkey NSLocationWhenInUseUsageDescription string "يُستخدم موقعك على جهازك فقط لعرض المدارس والمعاهد والمدرسين الأقرب إليك، ولا يُرسل إلى أي خادم."

echo "==> توليد أيقونات التطبيق من assets/images/app_icon.png"
ICONSET="ios/Runner/Assets.xcassets/AppIcon.appiconset"
gen() { sips -z "$2" "$2" assets/images/app_icon.png --out "$ICONSET/$1" >/dev/null; }
gen Icon-App-20x20@1x.png 20;   gen Icon-App-20x20@2x.png 40;   gen Icon-App-20x20@3x.png 60
gen Icon-App-29x29@1x.png 29;   gen Icon-App-29x29@2x.png 58;   gen Icon-App-29x29@3x.png 87
gen Icon-App-40x40@1x.png 40;   gen Icon-App-40x40@2x.png 80;   gen Icon-App-40x40@3x.png 120
gen Icon-App-60x60@2x.png 120;  gen Icon-App-60x60@3x.png 180
gen Icon-App-76x76@1x.png 76;   gen Icon-App-76x76@2x.png 152
gen Icon-App-83.5x83.5@2x.png 167
gen Icon-App-1024x1024@1x.png 1024

echo "==> تنزيل الحزم"
flutter pub get
(cd ios && pod install)

echo
echo "تم. الخطوات التالية:"
echo "  1) open ios/Runner.xcworkspace  ثم اختر فريقك في Signing & Capabilities"
echo "  2) flutter run                   للتجربة على جهاز أو محاكي"
echo "  3) flutter build ipa             ثم ارفع الملف عبر Transporter أو Xcode Organizer"
