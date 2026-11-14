// دخول الإدارة — نفس حسابات وكلمات مرور لوحة الويب (core/users):
//  - كلمات المرور بصيغة pbkdf2$salt$digest (PBKDF2-SHA256، 120000 تكرار) مثل نسخة الويب تماماً
//  - دعم البصمة القديمة (FNV) وترقيتها تلقائياً عند أول دخول
//  - قفل 5 دقائق بعد 5 محاولات خاطئة، وجلسة مدتها ساعتان

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

import '../store.dart';
import '../utils.dart';

const String kDefaultAdminPass = 'Admin@2026';
const String _sessionKey = 'kp_admin_session';
const String _guardKey = 'kp_login_guard';
const int _pbkdf2Iterations = 120000;

final Random _secure = Random.secure();

String randomHex(int bytes) {
  final b = StringBuffer();
  for (var i = 0; i < bytes; i++) {
    b.write(_secure.nextInt(256).toRadixString(16).padLeft(2, '0'));
  }
  return b.toString();
}

/// البصمة القديمة في نسخة الويب: FNV-1a على وحدات UTF-16
String legacyHash(String s) {
  var h = 0x811c9dc5;
  for (final c in s.codeUnits) {
    h = (h ^ c) & 0xFFFFFFFF;
    h = (h * 0x01000193) & 0xFFFFFFFF;
  }
  return h.toRadixString(16);
}

String _hex(List<int> b) => b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();

/// PBKDF2-HMAC-SHA256 بطول 32 بايت (كتلة واحدة) — يطابق crypto.subtle.deriveBits في المتصفح
List<int> _pbkdf2Sha256(List<int> password, List<int> salt, int iterations) {
  final hmac = Hmac(sha256, password);
  final block = Uint8List(salt.length + 4)..setAll(0, salt);
  block[salt.length + 3] = 1;
  List<int> u = hmac.convert(block).bytes;
  final t = Uint8List.fromList(u);
  for (var i = 1; i < iterations; i++) {
    u = hmac.convert(u).bytes;
    for (var j = 0; j < t.length; j++) {
      t[j] ^= u[j];
    }
  }
  return t;
}

String _strongPasswordSync(List<String> a) =>
    _hex(_pbkdf2Sha256(utf8.encode(a[0]), utf8.encode(a[1]), _pbkdf2Iterations));

/// الحساب في خيط منفصل حتى لا تتجمّد الواجهة
Future<String> strongPassword(String password, String salt) =>
    compute(_strongPasswordSync, <String>[password, salt]);

Future<String> makePasswordRecord(String password) async {
  final salt = randomHex(16);
  final digest = await strongPassword(password, salt);
  return 'pbkdf2\$$salt\$$digest';
}

Future<bool> verifyPassword(String password, String record) async {
  if (record.startsWith('pbkdf2\$')) {
    final p = record.split('\$');
    if (p.length != 3) return false;
    try {
      return await strongPassword(password, p[1]) == p[2];
    } catch (_) {
      return false;
    }
  }
  return record == legacyHash(password);
}

/// نفس شرط نسخة الويب: 10 أحرف على الأقل وتحتوي حروفاً وأرقاماً
bool validPassword(String p) =>
    p.length >= 10 &&
    p.length <= 128 &&
    RegExp(r'[A-Za-z]').hasMatch(p) &&
    RegExp(r'[0-9]').hasMatch(p);

class AdminSession {
  static String? get user {
    final raw = Store.getJson(_sessionKey, null);
    if (raw is! Map) return null;
    final u = str(raw['u']);
    if (u.isEmpty || intOf(raw['exp']) <= DateTime.now().millisecondsSinceEpoch) {
      unawaited(Store.remove(_sessionKey));
      return null;
    }
    return u;
  }

  static Future<void> start(String u) => Store.setJson(_sessionKey, {
        'u': clip(u, 50),
        'exp': DateTime.now().millisecondsSinceEpoch + 2 * 3600 * 1000,
        'nonce': randomHex(16),
      });

  static Future<void> end() => Store.remove(_sessionKey);
}

class LoginGuard {
  static Map<String, dynamic> get _g {
    final v = Store.getJson(_guardKey, null);
    return v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{'fails': 0, 'until': 0};
  }

  /// عدد الدقائق المتبقية على القفل (0 = غير مقفل)
  static int get lockedMinutes {
    final until = intOf(_g['until']);
    final now = DateTime.now().millisecondsSinceEpoch;
    return until > now ? ((until - now) / 60000).ceil() : 0;
  }

  static Future<void> fail() async {
    final g = _g;
    var fails = intOf(g['fails']) + 1;
    var until = intOf(g['until']);
    if (fails >= 5) {
      until = DateTime.now().millisecondsSinceEpoch + 5 * 60 * 1000;
      fails = 0;
    }
    await Store.setJson(_guardKey, {'fails': fails, 'until': until});
  }

  static Future<void> clear() => Store.remove(_guardKey);
}
