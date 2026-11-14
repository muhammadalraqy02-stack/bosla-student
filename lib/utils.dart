// أدوات مساعدة عامة — مطابقة لدوال نسخة الويب (clip, uid, timeAgo, normWa, socialHref ...)

import 'dart:math';

import 'package:flutter/material.dart';

final Random _rnd = Random();

String uid() {
  final t = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
  final r = _rnd.nextInt(60466176).toRadixString(36).padLeft(5, '0');
  return 'k$t$r';
}

String clientId() => 'c${_rnd.nextInt(2000000000).toRadixString(36)}';

String str(dynamic v) => v == null ? '' : v.toString();

double numOf(dynamic v) {
  if (v is num) return v.toDouble();
  return double.tryParse(str(v)) ?? 0;
}

int intOf(dynamic v) => numOf(v).round();

final RegExp _ctrl = RegExp(r'[\u0000-\u0008\u000B\u000C\u000E-\u001F\u007F]');

String clip(dynamic v, [int max = 500]) {
  final s = str(v).replaceAll(_ctrl, '').trim();
  return s.length > max ? s.substring(0, max) : s;
}

String safeKey(dynamic v) {
  final s = str(v).replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '');
  return s.length > 120 ? s.substring(0, 120) : s;
}

String digitsOnly(String v) => v.replaceAll(RegExp(r'\D'), '');

String telClean(String v) => v.replaceAll(RegExp(r'[^\d+]'), '');

Color colorFromHex(dynamic v, Color fallback) {
  final s = str(v);
  if (!RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(s)) return fallback;
  return Color(int.parse('FF${s.substring(1)}', radix: 16));
}

String fmtNum(num v) {
  final s = v.round().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return b.toString();
}

String todayIso() => DateTime.now().toIso8601String().substring(0, 10);

String nowIso() => DateTime.now().toUtc().toIso8601String();

DateTime? parseIso(String s) => DateTime.tryParse(s);

String timeAgo(String iso) {
  final t = parseIso(iso);
  if (t == null) return '';
  final d = DateTime.now().difference(t).inSeconds;
  if (d < 60) return 'قبل لحظات';
  String ar(int n, String one, String two, String many) {
    if (n == 1) return one;
    if (n == 2) return two;
    if (n < 11) return 'منذ $n $many';
    return 'منذ $n ${one.replaceFirst('منذ ', '')}';
  }

  if (d < 3600) return ar(d ~/ 60, 'منذ دقيقة', 'منذ دقيقتين', 'دقائق');
  if (d < 86400) return ar(d ~/ 3600, 'منذ ساعة', 'منذ ساعتين', 'ساعات');
  if (d < 2592000) return ar(d ~/ 86400, 'منذ يوم', 'منذ يومين', 'أيام');
  final l = t.toLocal();
  return '${l.day}/${l.month}/${l.year}';
}

// ---------- التاريخ العربي (بتسميات الأشهر المستخدمة في العراق) ----------
const List<String> kArMonths = [
  'كانون الثاني',
  'شباط',
  'آذار',
  'نيسان',
  'أيار',
  'حزيران',
  'تموز',
  'آب',
  'أيلول',
  'تشرين الأول',
  'تشرين الثاني',
  'كانون الأول',
];

/// مفهرسة بـ DateTime.weekday (1 = الاثنين ... 7 = الأحد)
const List<String> kArWeekdays = [
  'الاثنين',
  'الثلاثاء',
  'الأربعاء',
  'الخميس',
  'الجمعة',
  'السبت',
  'الأحد',
];

String two(int n) => n < 10 ? '0$n' : '$n';

String arTime(DateTime d) {
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  return '$h:${two(d.minute)} ${d.hour < 12 ? 'ص' : 'م'}';
}

String arDate(DateTime d, {bool year = true}) {
  final base = '${kArWeekdays[d.weekday - 1]} ${d.day} ${kArMonths[d.month - 1]}';
  return year ? '$base ${d.year}' : base;
}

String arDateTime(int ms) {
  final d = DateTime.fromMillisecondsSinceEpoch(ms);
  return '${arDate(d, year: false)} · ${arTime(d)}';
}

/// الوقت الحالي بتوقيت بغداد (UTC+3 بلا توقيت صيفي)
DateTime baghdadNow() => DateTime.now().toUtc().add(const Duration(hours: 3));

// ---------- روابط التواصل ----------
String normWa(String v) {
  var n = digitsOnly(v);
  if (n.isEmpty) return '';
  n = n.replaceFirst(RegExp(r'^00'), '');
  if (n.startsWith('964')) return n;
  if (n.startsWith('0')) return '964${n.replaceFirst(RegExp(r'^0+'), '')}';
  if (n.startsWith('7') && n.length <= 10) return '964$n';
  return n;
}

bool isHttp(String v) => RegExp(r'^https?://', caseSensitive: false).hasMatch(v.trim());

String socialHref(String link, String value) {
  final v = value.trim();
  if (v.isEmpty || link.isEmpty) return '';
  if (link == 'wa') {
    final n = normWa(v);
    return n.isEmpty ? '' : 'https://wa.me/$n';
  }
  if (isHttp(v)) return v;
  final u = v.replaceFirst(RegExp(r'^@+'), '').replaceFirst(RegExp(r'^/+'), '');
  if (u.isEmpty) return '';
  switch (link) {
    case 'fb':
      return 'https://facebook.com/$u';
    case 'ig':
      return 'https://instagram.com/$u';
    case 'tg':
      return 'https://t.me/$u';
    case 'tt':
      return 'https://tiktok.com/@$u';
    case 'yt':
      return 'https://youtube.com/@$u';
  }
  return 'https://$u';
}

// ---------- الموقع الجغرافي ----------
class GeoPoint {
  final double lat;
  final double lng;
  const GeoPoint(this.lat, this.lng);
}

GeoPoint? parseGeo(String v) {
  if (v.isEmpty) return null;
  RegExpMatch? m = RegExp(r'!3d(-?\d+\.\d+)!4d(-?\d+\.\d+)').firstMatch(v);
  m ??= RegExp(r'(-?\d{1,2}\.\d{3,})\s*,\s*(-?\d{1,3}\.\d{3,})').firstMatch(v);
  if (m == null) return null;
  final la = double.tryParse(m.group(1)!);
  final lo = double.tryParse(m.group(2)!);
  if (la == null || lo == null) return null;
  if (la.abs() > 90 || lo.abs() > 180) return null;
  return GeoPoint(la, lo);
}

double distanceKm(GeoPoint a, GeoPoint b) {
  const r = pi / 180;
  final dl = (b.lat - a.lat) * r;
  final dn = (b.lng - a.lng) * r;
  final x = sin(dl / 2) * sin(dl / 2) +
      cos(a.lat * r) * cos(b.lat * r) * sin(dn / 2) * sin(dn / 2);
  return 6371 * 2 * atan2(sqrt(x), sqrt(1 - x));
}

String distanceText(double d) {
  if (d < 1) return '${(d * 1000).round()} م';
  return '${d.toStringAsFixed(d < 10 ? 1 : 0)} كم';
}

/// معرّف رقمي ثابت للإشعارات المحلية (نفس خوارزمية نسخة الويب)
int numId(String s) {
  var h = 0;
  for (var i = 0; i < s.length; i++) {
    h = (h * 31 + s.codeUnitAt(i)) & 0xFFFFFFFF;
    if (h >= 0x80000000) h -= 0x100000000;
  }
  return h.abs() % 2000000000 + 1;
}

/// توحيد اسم تخصص المدرس (انكليزي ← اللغة الإنكليزية ...)
String teacherSpecialtyKey(String value) {
  final raw = value.trim();
  final s = raw
      .replaceAll(RegExp('[أإآ]'), 'ا')
      .replaceAll('ة', 'ه')
      .toLowerCase();
  if (['انكليزي', 'انجليزي', 'اللغه الانكليزيه', 'اللغه الانجليزيه'].contains(s)) {
    return 'اللغة الإنكليزية';
  }
  if (['عربي', 'اللغه العربيه'].contains(s)) return 'اللغة العربية';
  if (['اسلاميه', 'تربيه اسلاميه', 'التربيه الاسلاميه'].contains(s)) return 'تربية إسلامية';
  if (['فرنسي', 'اللغه الفرنسيه'].contains(s)) return 'اللغة الفرنسية';
  return raw;
}

// ---------- فلتر الكلمات غير اللائقة في التقييمات ----------
const List<String> _bad = [
  'كلب', 'حمار', 'حيوان', 'زبالة', 'تافه', 'غبي', 'لعنة', 'قذر', 'حقير', 'وسخ',
  'خرا', 'منيوك', 'كس', 'عير', 'قحب', 'شرموط', 'fuck', 'shit', 'bitch',
];

bool hasBadWords(String input) {
  final s = input.toLowerCase().replaceAll(RegExp('[ً-ْـ]'), '');
  for (final w in _bad) {
    final re = RegExp('(^|[^\\u0600-\\u06FFa-z])$w(\$|[^\\u0600-\\u06FFa-z])');
    if (re.hasMatch(s)) return true;
  }
  return false;
}

bool hasContactInfo(String s) =>
    RegExp(r'(https?:|www\.|\.com|\.net|@\w|\d{7,})', caseSensitive: false).hasMatch(s);
