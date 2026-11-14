// التخزين المحلي:
//  - القيم الصغيرة (المفضلة، التفضيلات، التذكيرات...) في SharedPreferences بنفس مفاتيح نسخة الويب (bosla_*)
//  - النسخ المؤقتة الكبيرة (بيانات الدليل) في ملفات JSON داخل مجلد دعم التطبيق

import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class K {
  static const fav = 'bosla_favorites_v1';
  static const notifRead = 'bosla_notifications_read_v1';
  static const notifAnnounced = 'bosla_notif_announced_v1';
  static const themePref = 'bosla_theme_pref';
  static const mine = 'bosla_my_requests_v1';
  static const bookings = 'bosla_bookings_v1';
  static const compare = 'bosla_compare_v1';
  static const schedule = 'bosla_schedule_v1';
  static const gpa = 'bosla_gpa_v1';
  static const countdowns = 'bosla_countdowns_v1';
  static const reminders = 'bosla_reminders_v1';
  static const reviewed = 'bosla_reviewed_v1';
  static const hiddenReviews = 'bosla_hidden_reviews_v1';
  static const notes = 'bosla_notes_v1';
  static const requestTimes = 'kp_public_request_times';
  // مفاتيح داخلية للمزامنة (لا تُمسح مع «مسح بيانات الجهاز»)
  static const rev = 'sync_cloud_rev';
  static const publicMeta = 'sync_public_meta';
}

class Store {
  static late SharedPreferences _p;
  static Directory? _dir;

  static Future<void> init() async {
    _p = await SharedPreferences.getInstance();
    try {
      _dir = await getApplicationSupportDirectory();
    } catch (_) {
      _dir = null;
    }
  }

  // ---------- قيم صغيرة ----------
  static String? getString(String k) => _p.getString(k);

  static Future<void> setString(String k, String v) async {
    await _p.setString(k, v);
  }

  static Future<void> remove(String k) async {
    await _p.remove(k);
  }

  static dynamic getJson(String k, dynamic def) {
    try {
      final s = _p.getString(k);
      if (s == null || s.isEmpty) return def;
      final v = jsonDecode(s);
      return v ?? def;
    } catch (_) {
      return def;
    }
  }

  static Future<void> setJson(String k, dynamic v) async {
    await _p.setString(k, jsonEncode(v));
  }

  static List<String> getStringList(String k) {
    final v = getJson(k, const []);
    if (v is! List) return <String>[];
    return v.whereType<String>().toList();
  }

  static List<Map<String, dynamic>> getMapList(String k) {
    final v = getJson(k, const []);
    if (v is! List) return <Map<String, dynamic>>[];
    return v.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  static Map<String, dynamic> getMap(String k) {
    final v = getJson(k, const {});
    if (v is! Map) return <String, dynamic>{};
    return Map<String, dynamic>.from(v);
  }

  static int getInt(String k) => int.tryParse(_p.getString(k) ?? '') ?? 0;

  static Future<void> setInt(String k, int v) => setString(k, '$v');

  /// مسح بيانات المستخدم على الجهاز مع الإبقاء على مفاتيح محددة
  static Future<void> wipeUserKeys(Set<String> keep) async {
    final keys = _p.getKeys().toList();
    for (final k in keys) {
      if (keep.contains(k)) continue;
      if (k.startsWith('bosla_') || k.startsWith('kp_public_request')) {
        await _p.remove(k);
      }
    }
  }

  // ---------- ملفات النسخ المؤقتة ----------
  static File? _file(String name) {
    final d = _dir;
    if (d == null) return null;
    return File('${d.path}/$name.json');
  }

  static Future<dynamic> readCache(String name) async {
    try {
      final f = _file(name);
      if (f == null || !await f.exists()) return null;
      return jsonDecode(await f.readAsString());
    } catch (_) {
      return null;
    }
  }

  static Future<void> writeCache(String name, dynamic value) async {
    try {
      final f = _file(name);
      if (f == null) return;
      await f.writeAsString(jsonEncode(value), flush: true);
    } catch (_) {}
  }
}
