// طبقة الاتصال بالخوادم:
//  - Firebase Realtime Database عبر REST (نفس أسلوب نسخة الويب، دون SDK)
//  - Supabase Storage لقراءة الصور

import 'dart:convert';

import 'package:http/http.dart' as http;

import 'config.dart';

class Api {
  static const Duration _timeout = Duration(seconds: 25);
  static const Map<String, String> _json = {'Content-Type': 'application/json'};

  static Future<dynamic> fbGet(String path) async {
    final r = await http.get(Uri.parse('$path.json')).timeout(_timeout);
    if (r.statusCode < 200 || r.statusCode >= 300) {
      throw Exception('HTTP ${r.statusCode}');
    }
    if (r.bodyBytes.isEmpty) return null;
    return jsonDecode(utf8.decode(r.bodyBytes));
  }

  static Future<void> fbPut(String path, dynamic body) async {
    final r = await http
        .put(Uri.parse('$path.json?print=silent'), headers: _json, body: jsonEncode(body))
        .timeout(_timeout);
    if (r.statusCode < 200 || r.statusCode >= 300) {
      throw Exception('HTTP ${r.statusCode}');
    }
  }

  /// تحديث جزئي: يكتب المسارات المتغيّرة فقط
  static Future<void> fbPatch(String path, Map<String, dynamic> body) async {
    final r = await http
        .patch(Uri.parse('$path.json?print=silent'), headers: _json, body: jsonEncode(body))
        .timeout(_timeout);
    if (r.statusCode < 200 || r.statusCode >= 300) {
      throw Exception('HTTP ${r.statusCode}');
    }
  }

  static Future<void> fbDelete(String path) async {
    final r = await http.delete(Uri.parse('$path.json?print=silent')).timeout(_timeout);
    if (r.statusCode < 200 || r.statusCode >= 300) {
      throw Exception('HTTP ${r.statusCode}');
    }
  }

  // ---------- Supabase ----------
  static Map<String, String> get supaHeaders =>
      {'apikey': Cfg.supaKey, 'Authorization': 'Bearer ${Cfg.supaKey}'};

  /// مسار الملف داخل الحاوية إن كان الرابط رابطاً عاماً من Supabase، وإلا نص فارغ
  static String supaPathFromUrl(String url, String supaUrl, String bucket) {
    final pre = '$supaUrl/storage/v1/object/public/$bucket/';
    return url.startsWith(pre) ? url.substring(pre.length) : '';
  }

  /// بعض الحاويات القديمة خاصة: عند فشل الرابط العام نقرأ الملف بهوية anon
  static String supaAuthenticatedUrl(String path, String supaUrl, String bucket) =>
      '$supaUrl/storage/v1/object/authenticated/$bucket/$path';
}
