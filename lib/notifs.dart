// الإشعارات المحلية (تذكيرات الجدول والعدّ التنازلي، تحديثات الطلبات، إعلانات الدليل الجديدة)
// لا يُطلب الإذن إلا عند ضغط المستخدم «تفعيل» أو عند إضافة تذكير.

import 'dart:ui' show Color;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'store.dart';
import 'utils.dart';

class Notifs {
  static final FlutterLocalNotificationsPlugin _fln = FlutterLocalNotificationsPlugin();
  static bool _ready = false;
  static const String _prefKey = 'bosla_notif_pref_v1';

  static const NotificationDetails _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'bosla_main',
      'بوصلة الطالب',
      channelDescription: 'إعلانات الدليل وتحديثات الطلبات والتذكيرات',
      importance: Importance.high,
      priority: Priority.high,
      // أيقونة شريط الحالة (بيضاء أحادية اللون) — الملف android/app/src/main/res/drawable/ic_stat_bosla.xml
      icon: 'ic_stat_bosla',
      color: Color(0xFF10275E),
    ),
    iOS: DarwinNotificationDetails(),
  );

  static Future<void> init() async {
    try {
      tzdata.initializeTimeZones();
      _setLocalZone();
      await _fln.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('ic_stat_bosla'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
      );
      _ready = true;
    } catch (_) {
      _ready = false;
    }
  }

  /// نختار منطقة زمنية مطابقة لفرق توقيت الجهاز (مع تفضيل بغداد) دون حزمة إضافية
  static void _setLocalZone() {
    try {
      final offset = DateTime.now().timeZoneOffset.inMilliseconds;
      final baghdad = tz.getLocation('Asia/Baghdad');
      if (baghdad.currentTimeZone.offset == offset) {
        tz.setLocalLocation(baghdad);
        return;
      }
      for (final loc in tz.timeZoneDatabase.locations.values) {
        if (loc.currentTimeZone.offset == offset) {
          tz.setLocalLocation(loc);
          return;
        }
      }
    } catch (_) {}
  }

  /// 'on' بعد منح الإذن، 'off' بعد الرفض، '' إن لم يُسأل المستخدم بعد
  static String get pref => Store.getString(_prefKey) ?? '';

  static bool get enabled => pref == 'on';

  /// يعرض طلب الإذن من النظام (مرة واحدة) ويعيد النتيجة
  static Future<bool> requestPermission() async {
    if (!_ready) return false;
    bool ok = false;
    try {
      final ios =
          _fln.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      if (ios != null) {
        ok = await ios.requestPermissions(alert: true, badge: true, sound: true) ?? false;
      } else {
        final android = _fln
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        if (android != null) {
          ok = await android.requestNotificationsPermission() ?? false;
        }
      }
    } catch (_) {
      ok = false;
    }
    await Store.setString(_prefKey, ok ? 'on' : 'off');
    return ok;
  }

  static Future<void> show(String key, String title, String body) async {
    if (!_ready || !enabled) return;
    try {
      await _fln.show(numId(key), title, body, _details);
    } catch (_) {}
  }

  static Future<void> cancel(String key) async {
    if (!_ready) return;
    try {
      await _fln.cancel(numId(key));
    } catch (_) {}
  }

  /// تذكير لمرة واحدة عند وقت محدد
  static Future<void> scheduleAt(String key, String title, String body, DateTime when) async {
    if (!_ready || !enabled) return;
    if (!when.isAfter(DateTime.now())) return;
    try {
      await _fln.zonedSchedule(
        numId(key),
        title,
        body,
        tz.TZDateTime.from(when, tz.local),
        _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (_) {}
  }

  /// تذكير أسبوعي متكرر. [jsWeekday] بصيغة الويب: 0 = الأحد ... 6 = السبت
  static Future<void> scheduleWeekly(
    String key,
    String title,
    String body, {
    required int jsWeekday,
    required int hour,
    required int minute,
    int leadMinutes = 0,
  }) async {
    if (!_ready || !enabled) return;
    try {
      var total = hour * 60 + minute - leadMinutes;
      var wd = jsWeekday;
      while (total < 0) {
        total += 1440;
        wd = (wd + 6) % 7;
      }
      final dartWd = wd == 0 ? 7 : wd;
      final now = tz.TZDateTime.now(tz.local);
      var next = tz.TZDateTime(tz.local, now.year, now.month, now.day, total ~/ 60, total % 60);
      var guard = 0;
      while ((next.weekday != dartWd || !next.isAfter(now)) && guard < 8) {
        next = next.add(const Duration(days: 1));
        guard++;
      }
      await _fln.zonedSchedule(
        numId(key),
        title,
        body,
        next,
        _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    } catch (_) {}
  }
}
