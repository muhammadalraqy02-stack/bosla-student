plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// نسخة Google Play: تُبنى باسم حزمة التطبيق المنشور على المتجر (BOSLA_PLAY_ID=apli4165806.uog)
// وبدون توقيع، ثم تُوقَّع بمفتاح التحميل (upload key) خارج GitHub. بدونه: نسخة APK التجريبية كالمعتاد.
val playAppId: String? = System.getenv("BOSLA_PLAY_ID")?.takeIf { it.isNotBlank() }
val appId: String = playAppId ?: "com.bosla2026.app"

android {
    namespace = "com.bosla2026.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // مطلوب لمكتبة flutter_local_notifications (الإشعارات المجدولة)
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = appId
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        // مفتاح تجريبي ثابت (android/app/bosla-test.jks) حتى تتحدّث كل نسخة فوق السابقة.
        // للتجربة فقط — قبل النشر على Google Play أنشئ مفتاح توقيع خاصاً (راجع README).
        create("test") {
            storeFile = file("bosla-test.jks")
            storePassword = "bosla2026"
            keyAlias = "bosla"
            keyPassword = "bosla2026"
            enableV1Signing = true
            enableV2Signing = true
            enableV3Signing = true
        }
    }

    buildTypes {
        release {
            signingConfig = if (playAppId != null) null else signingConfigs.getByName("test")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

// الإشعارات الفورية (FCM): تُفعَّل تلقائياً عند إضافة android/app/google-services.json من Firebase Console.
// بدون الملف يُبنى التطبيق طبيعياً وتُتجاوز الإشعارات الفورية.
// يُطبَّق فقط إذا كان الملف يحتوي تطبيقاً بنفس اسم الحزمة (وإلا يفشل البناء)
val googleServices = file("google-services.json")
if (googleServices.exists() && googleServices.readText().contains("\"$appId\"")) {
    apply(plugin = "com.google.gms.google-services")
}
