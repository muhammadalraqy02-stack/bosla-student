// الإشعارات الفورية من الخادم (Firebase Cloud Messaging) — نفس pushRegister في نسخة الويب:
// يُسجَّل رمز الجهاز في <root>/pushTokens/<الرمز> = {at, os}، ويُعرض الإشعار الوارد أثناء فتح التطبيق.
//
// تتفعّل تلقائياً بعد إضافة الملف android/app/google-services.json من Firebase Console
// (تطبيق Android بالمعرّف com.bosla2026.app). بدون الملف يعمل التطبيق طبيعياً ويتجاوز هذه الخطوة.

import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'api.dart';
import 'app_state.dart';
import 'config.dart';
import 'notifs.dart';
import 'utils.dart';

class Push {
  static bool ready = false;
  static bool _bound = false;

  static Future<void> init() async {
    try {
      await Firebase.initializeApp();
    } catch (_) {
      return; // لم يُضف google-services.json بعد
    }
    try {
      final m = FirebaseMessaging.instance;
      final st = await m.requestPermission();
      if (st.authorizationStatus == AuthorizationStatus.denied) return;
      final t = await m.getToken();
      if (t != null) await _save(t);
      if (!_bound) {
        _bound = true;
        m.onTokenRefresh.listen((t) => unawaited(_save(t)));
        FirebaseMessaging.onMessage.listen((msg) {
          final n = msg.notification;
          if (n == null) return;
          final title = (n.title ?? '').isEmpty ? AppState.I.settings.siteName : n.title!;
          unawaited(Notifs.show('push_${msg.messageId ?? DateTime.now().millisecondsSinceEpoch}', title, n.body ?? ''));
        });
      }
      ready = true;
    } catch (_) {}
  }

  static Future<void> _save(String token) async {
    final k = safeKey(token);
    if (k.isEmpty) return;
    try {
      await Api.fbPut('${Cfg.fbRoot}/pushTokens/$k', {'at': nowIso(), 'os': 'android'});
    } catch (_) {}
  }
}
