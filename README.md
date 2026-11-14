# بوصلة الطالب — تطبيق Flutter

تحويل كامل لنسخة الويب (`index.html` داخل WebView) إلى تطبيق Flutter/Dart أصلي.
يعمل على **نفس قاعدة البيانات ونفس حاوية الصور** دون أي ترحيل، ولوحة الإدارة تبقى على نسخة الويب.

> **حالة المشروع:** كُتب دون توفر Flutter SDK ولا اتصال بالإنترنت في بيئة الكتابة، فلم يُبنَ بعد.
> روجع الكود يدوياً وفُحصت الأقواس والاستيرادات وملفات XML وYAML آلياً. أول بناء هو الاختبار الحقيقي —
> إن فشل، أرسل سجل الخطأ ويُصحَّح.

## بناء APK

### الطريقة 1: GitHub Actions (دون تثبيت أي شيء)
1. أنشئ مستودعاً على GitHub (يُفضّل خاصاً Private) وارفع محتويات هذا المجلد إليه.
2. يبدأ البناء تلقائياً (أو من Actions ← Build Android APK ← Run workflow).
3. بعد 10–15 دقيقة: افتح التشغيل ← Artifacts ← `bosla-student-apk` ← نزّل وفك الضغط.
4. ثبّت `app-release.apk` (أصغر وأسرع) أو `app-debug.apk` على الهاتف.

الإعداد في `.github/workflows/build-apk.yml` — Flutter `3.35.x` مثبّت ليطابق إصدارات Gradle.

### الطريقة 2: على جهازك (Flutter + Android Studio)
```bash
flutter pub get
flutter analyze
flutter build apk --debug      # build/app/outputs/flutter-apk/app-debug.apk
flutter build apk --release    # build/app/outputs/flutter-apk/app-release.apk
```
أو افتح المجلد في Android Studio (مع إضافة Flutter) واضغط Run على محاكٍ أو هاتف.
ضع المشروع في مسار إنكليزي بلا مسافات (مثل `C:\dev\bosla_student`).

### إعدادات Android الموجودة في `android/`
| البند | القيمة |
|---|---|
| المعرّف | `com.bosla2026.app` |
| الاسم | «بوصلة الطالب» |
| Gradle / AGP / Kotlin | 8.12 / 8.9.1 / 2.1.0 (مطابقة لقالب Flutter) |
| Java | 17 + Core Library Desugaring (`desugar_jdk_libs 2.1.4`) |
| compile/min/target SDK | من Flutter (`flutter.compileSdkVersion` …) |
| الصلاحيات | الإنترنت، الموقع، الإشعارات، إعادة جدولة التذكيرات بعد إعادة التشغيل |
| الأيقونة | من `assets/images/app_icon.png` (عادية + Adaptive)، وأيقونة إشعار بيضاء `ic_stat_bosla` |

**التوقيع:** إصدار release موقّع حالياً بمفتاح debug — صالح للتثبيت والتجربة، **غير صالح للنشر على Google Play**.
للنشر أنشئ مفتاحاً بـ `keytool` واربطه في `android/app/build.gradle.kts` (لا ترفع ملف المفتاح إلى GitHub).

## iOS (على Mac فيه Flutter و Xcode و CocoaPods)

```bash
bash tool/setup_ios.sh            # ينشئ مجلد ios ويضبط المعرّف والأذونات والأيقونات
flutter run                       # تجربة
flutter build ipa                 # ملف الرفع إلى App Store Connect
```

لمعرّف آخر غير `com.bosla2026.app`:  `bash tool/setup_ios.sh com.your.bundle`

## الخوادم (لم يتغيّر شيء)

| الغرض | المسار |
|---|---|
| بيانات الدليل | `bosla-e2164-default-rtdb.firebaseio.com/knowledge/core` (REST) |
| المدارس والمعاهد | `knowledge/public/{schools,institutes}` + `knowledge/publicVersion` |
| الطلبات والاقتراحات | `core/requests` + `requestsPrivate` + `requestMedia` |
| التقييمات والبلاغات | `knowledge/reviews` + `knowledge/reviewReports` |
| العدادات | `knowledge/metrics` |
| الصور | Supabase Storage — الحاوية `media` |

كل العناوين والمفاتيح في `lib/config.dart`. لا حاجة إلى `GoogleService-Info.plist` لأن الاتصال عبر REST.

## ما الذي نُقل

الرئيسية والأقسام (اختصاصات المدرسين، مناطق المعاهد) · البحث والفلترة · صفحة التفاصيل ومعرض الصور ·
المفضلة · المقارنة · الأقرب إليّ · طلب التسجيل/الحجز ومتابعة حالته · اقترح إضافة بصورة · التقييمات مع الإبلاغ والإخفاء ·
الإشعارات واللوحات الإعلانية · أدوات الطالب (جدول، معدل، عدّ تنازلي، ملاحظات، تذكيرات) · الوضع الليلي ·
السياسات وحذف البيانات · العمل دون إنترنت من النسخة المحفوظة · المزامنة برقم النسخة `_rev`.

## الفروقات عن نسخة الويب

- **لوحة الإدارة غير موجودة في التطبيق** (تبقى على نسخة الويب)، ولا يحتفظ التطبيق بحسابات المدراء ولا بطلبات بقية المستخدمين.
- **البحث يعرض نتائجه** في شاشة مستقلة (في نسخة الويب الحالية عنصر النتائج `#cards` غير موجود في الصفحة الرئيسية).
- **الإشعارات محلية** على الجهاز (تذكيرات، تحديث حالة الطلب، إعلان جديد عند فتح التطبيق). لا يوجد Push من الخادم — كما في نسخة الويب.
- **المشاركة** ترسل نصاً فقط. لإضافة رابط العنصر ضع رابط نسخة الويب في `Cfg.webBaseUrl`.
- **الأيقونات** Material بدل Font Awesome (جدول التحويل في `config.dart`)، وخط Cairo يُحمَّل عبر `google_fonts` عند أول تشغيل.
- البيانات التجريبية الافتراضية (بطاقات وهمية) حُذفت حتى لا تظهر لمراجع Apple.

## بنية الكود

```
lib/
  main.dart          التهيئة، السمة، الشريط السفلي
  config.dart        الخوادم والثوابت واستمارات الأقسام
  models.dart        النماذج ودوال التطبيع
  api.dart           Firebase REST + Supabase
  app_state.dart     الحالة والمزامنة والطلبات والتقييمات
  store.dart         التخزين المحلي      local_data.dart  بيانات أدوات الطالب
  notifs.dart        الإشعارات المحلية   ui.dart / utils.dart  أدوات مساعدة
  widgets/           الصور والبطاقات والعناصر المشتركة
  screens/           الشاشات
```
