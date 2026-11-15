# بوصلة الطالب — تعليمات نسخة iOS للمطوّر

تطبيق **Flutter 3.35 (stable) / Dart 3.9** أصلي بالكامل. مجلد `ios/` جاهز للتوقيع والرفع إلى App Store.

| الإعداد | القيمة |
|---|---|
| Bundle ID | `com.bosla2026.app` (يمكن تغييره حسب حسابك) |
| اسم التطبيق | بوصلة الطالب |
| أقل إصدار iOS | 13.0 |
| الإصدار | من `pubspec.yaml` ← `version: 1.0.0+1` (ارفع رقم البناء `+N` مع كل رفع) |
| الأذونات المضافة في Info.plist | الموقع (أثناء الاستخدام)، الكاميرا، مكتبة الصور — بنصوص عربية |
| التشفير | `ITSAppUsesNonExemptEncryption = false` (HTTPS فقط) |

## الطريقة الموصى بها: البناء من المصدر على Mac

```bash
git clone <repo>
cd bosla-student
flutter pub get
cd ios && pod install && cd ..
open ios/Runner.xcworkspace
```

في Xcode ← Runner ← **Signing & Capabilities**:
1. اختر **Team** الخاص بك، وتأكد من الـ Bundle ID.
2. (للإشعارات الفورية فقط) أضف Capability: **Push Notifications** و **Background Modes ← Remote notifications**.

ثم:
```bash
flutter build ipa --release
```
وارفع الملف الناتج من `build/ios/ipa/` عبر تطبيق **Transporter** أو من Xcode ← Organizer.

## البديل: الأرشيف غير الموقّع من GitHub
في صفحة **Releases** توجد نسخ باسم `ios-N` تحتوي `bosla-student-ios-unsigned.xcarchive.zip` مبنية تلقائياً على GitHub Actions (macOS).
يمكن فتح الأرشيف في Xcode Organizer وتوقيعه عند التصدير، لكن **البناء من المصدر أضمن**.

## الإشعارات الفورية (اختياري)
الإشعارات الفورية تعمل حالياً على الأندرويد. لتفعيلها على iOS:
1. في Firebase Console (المشروع `bosla-e2164`) أضف تطبيق **iOS** بنفس الـ Bundle ID ونزّل `GoogleService-Info.plist`.
2. ضع الملف في `ios/Runner/` وأضفه إلى target **Runner** في Xcode.
3. ارفع **APNs Authentication Key (.p8)** من حساب Apple Developer إلى Firebase ← Project settings ← Cloud Messaging.
4. فعّل Capability: Push Notifications.

بدون هذا الملف يعمل التطبيق طبيعياً على iOS لكن بدون إشعارات فورية (التذكيرات المحلية تعمل).

## ملاحظات لمراجعة Apple
- نسخة iOS مطابقة تماماً لنسخة الأندرويد (نفس ملفات Dart في `lib/`).
- دخول المدير **ظاهر** في تبويب «المزيد ← الإدارة ← دخول المدير» (لا توجد ميزات مخفية — البند 2.3.1).
- أبل تطلب حساباً تجريبياً لأي ميزة خلف تسجيل دخول (البند 2.1): أنشئ حساب مدير خاص بالمراجعة من لوحة الإدارة ← المستخدمون، واكتب بياناته في App Review Information عند الرفع.
- التطبيق لا يتطلب تسجيل حساب، ولا يجمع بيانات شخصية؛ الموقع يُستخدم محلياً فقط لترتيب النتائج حسب القرب.
- صفحات سياسة الخصوصية والشروط وحذف البيانات والدعم موجودة داخل التطبيق: تبويب «المزيد».
