# تُضاف تلقائياً من Flutter Gradle Plugin عند بناء release
# flutter_local_notifications يحفظ الإشعارات المجدولة بـ Gson
-keep class com.dexterous.** { *; }
-keepattributes Signature
-keepattributes *Annotation*
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken
