// بيانات لوحة الإدارة وعمليات الكتابة — بنفس صيغة نسخة الويب تماماً:
//  - core بصيغة map2: كل قسم خريطة بمفتاح المعرّف، والتحديث جزئي (PATCH) مع _by و _rev
//  - المدارس والمعاهد في public/<code> مع رقم نسخة في publicVersion/<code>
//  - الصور تُرفع إلى Supabase ويُحفظ رابطها فقط
// اللوحة تعمل على البيانات الخام كما هي في فايربيس حتى لا يضيع أي حقل لا يعرفه التطبيق.

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../api.dart';
import '../app_state.dart';
import '../config.dart';
import '../utils.dart';
import 'admin_auth.dart';

/// صورة العنصر الافتراضية عند عدم إضافة صورة — نفس قيمة نسخة الويب
const String kNoImage = 'data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSI4MDAiIGhlaWdodD0iNDAwIiB2aWV3Qm94PSIwIDAgODAwIDQwMCI+PGRlZnM+PGxpbmVhckdyYWRpZW50IGlkPSJnIiB4MT0iMCIgeTE9IjAiIHgyPSIxIiB5Mj0iMSI+PHN0b3Agc3RvcC1jb2xvcj0iI2VlZjNmYSIvPjxzdG9wIG9mZnNldD0iMSIgc3RvcC1jb2xvcj0iI2RjZTdmNSIvPjwvbGluZWFyR3JhZGllbnQ+PC9kZWZzPjxyZWN0IHdpZHRoPSI4MDAiIGhlaWdodD0iNDAwIiBmaWxsPSJ1cmwoI2cpIi8+PGcgZmlsbD0ibm9uZSIgc3Ryb2tlPSIjNzE4NWEzIiBzdHJva2Utd2lkdGg9IjE4IiBzdHJva2UtbGluZWNhcD0icm91bmQiIHN0cm9rZS1saW5lam9pbj0icm91bmQiPjxyZWN0IHg9IjI1MiIgeT0iOTIiIHdpZHRoPSIyOTYiIGhlaWdodD0iMjE2IiByeD0iMjQiLz48Y2lyY2xlIGN4PSIzNDAiIGN5PSIxNjUiIHI9IjMwIi8+PHBhdGggZD0iTTI4NSAyNzBsODgtODAgNjggNTkgMzgtMzQgMzYgNTUiLz48L2c+PC9zdmc+';

const List<String> kRequestStatuses = ['قيد المراجعة', 'تم التواصل', 'مقبول', 'مرفوض'];

/// رمز يعيده login عندما تكون كلمة المرور افتراضية ويجب تغييرها
const String kNeedNewPassword = '__CHANGE__';

typedef Json = Map<String, dynamic>;

Map<String, Json> _asMap(dynamic v) {
  final out = <String, Json>{};
  if (v is Map) {
    v.forEach((k, x) {
      if (x is Map) out[k.toString()] = Map<String, dynamic>.from(x);
    });
  } else if (v is List) {
    for (var i = 0; i < v.length; i++) {
      final x = v[i];
      if (x is Map) {
        final m = Map<String, dynamic>.from(x);
        final k = safeKey(m['id']);
        out[k.isEmpty ? 'i$i' : k] = m;
      }
    }
  }
  return out;
}

int _byAtDesc(Json a, Json b) => str(b['at']).compareTo(str(a['at']));

class AdminStore extends ChangeNotifier {
  AdminStore._();
  static final AdminStore I = AdminStore._();

  final String _client = clientId();
  bool loading = false;
  bool loaded = false;
  String error = '';

  /// بيانات بصيغة قديمة (قبل map2) — الكتابة متوقفة حتى تُفتح لوحة الويب مرة لترحيلها
  bool legacyFormat = false;

  Json settings = {};
  Map<String, Json> users = {};
  Map<String, Json> coreCards = {};
  Map<String, Json> requests = {};
  Map<String, Json> notifications = {};
  Map<String, Json> activity = {};
  final Map<String, Map<String, Json>> pubCards = {};
  final Map<String, bool> pubReady = {};

  String? get currentUser => AdminSession.user;

  static const String _legacyMsg =
      'بيانات فايربيس بصيغة قديمة — افتح لوحة الإدارة في نسخة الويب مرة واحدة لترحيلها ثم أعد المحاولة';
  static const String _netMsg = 'تعذّر الحفظ — تحقق من الاتصال وحاول مجدداً';

  // ======================= التحميل =======================
  Future<bool> load() async {
    if (loading) return loaded;
    loading = true;
    error = '';
    notifyListeners();
    try {
      final core = await Api.fbGet(Cfg.fbCore);
      final m = core is Map ? Map<String, dynamic>.from(core) : <String, dynamic>{};
      legacyFormat = m.isNotEmpty && str(m['_fmt']) != 'map2';
      settings = m['settings'] is Map ? Map<String, dynamic>.from(m['settings'] as Map) : <String, dynamic>{};
      users = _asMap(m['users']);
      if (users.isEmpty) {
        // نفس الحساب الافتراضي في نسخة الويب عند عدم وجود مستخدمين
        users = {
          'u1': {
            'id': 'u1',
            'user': 'admin',
            'pass': legacyHash(kDefaultAdminPass),
            'role': 'مدير عام',
            'created': todayIso(),
          },
        };
      }
      coreCards = _asMap(m['cards']);
      requests = _asMap(m['requests']);
      notifications = _asMap(m['notifications']);
      activity = _asMap(m['activity']);
      for (final code in Cfg.publicSections.values) {
        final meta = await Api.fbGet('${Cfg.fbPublicVersion}/$code');
        final ver = meta is Map ? intOf(meta['version'] ?? meta['lastUpdated']) : intOf(meta);
        pubReady[code] = ver > 0;
        pubCards[code] = ver > 0 ? _asMap(await Api.fbGet('${Cfg.fbPublic}/$code')) : <String, Json>{};
      }
      loaded = true;
    } catch (_) {
      error = 'تعذّر تحميل البيانات — تحقق من الاتصال';
    }
    loading = false;
    notifyListeners();
    return loaded;
  }

  // ======================= الدخول =======================
  MapEntry<String, Json>? _userEntry(String name) {
    for (final e in users.entries) {
      if (str(e.value['user']) == name) return e;
    }
    return null;
  }

  /// يعيد null عند النجاح، أو kNeedNewPassword عند كلمة المرور الافتراضية، أو رسالة الخطأ
  Future<String?> login(String user, String pass, {String? newPass}) async {
    final mins = LoginGuard.lockedMinutes;
    if (mins > 0) return 'محاولات كثيرة. انتظر $mins دقيقة';
    if (!loaded && !await load()) return error;
    final name = clip(user, 50);
    final entry = _userEntry(name);
    if (entry == null || !await verifyPassword(pass, str(entry.value['pass']))) {
      await LoginGuard.fail();
      return 'بيانات الدخول غير صحيحة';
    }
    final u = Map<String, dynamic>.from(entry.value);
    var changed = false;
    if (pass == kDefaultAdminPass) {
      if (newPass == null) return kNeedNewPassword;
      if (!validPassword(newPass)) {
        return 'كلمة المرور يجب أن تكون 10 أحرف على الأقل وتحتوي حروفاً وأرقاماً';
      }
      u['pass'] = await makePasswordRecord(newPass);
      changed = true;
    } else if (!str(u['pass']).startsWith('pbkdf2\$')) {
      u['pass'] = await makePasswordRecord(pass);
      changed = true;
    }
    await LoginGuard.clear();
    await AdminSession.start(name);
    try {
      final body = <String, dynamic>{};
      if (changed) {
        users[entry.key] = u;
        body['users/${entry.key}'] = u;
      }
      await _patchCore(body, log: 'تسجيل دخول للوحة التحكم (التطبيق)', icon: 'fa-solid fa-right-to-bracket');
    } catch (_) {
      if (changed) {
        await AdminSession.end();
        return 'تعذّر حفظ كلمة المرور الجديدة — تحقق من الاتصال';
      }
    }
    notifyListeners();
    return null;
  }

  /// للتأكد أن صاحب الجلسة ما زال ضمن المستخدمين
  bool get sessionValid {
    final u = currentUser;
    return u != null && _userEntry(u) != null;
  }

  Future<void> logout() async {
    await AdminSession.end();
    notifyListeners();
  }

  Future<String?> changePassword(String newPass) async {
    if (legacyFormat) return _legacyMsg;
    final me = currentUser;
    final entry = me == null ? null : _userEntry(me);
    if (entry == null) return 'انتهت الجلسة — سجّل الدخول من جديد';
    if (!validPassword(newPass)) {
      return 'كلمة المرور يجب أن تكون 10 أحرف على الأقل وتحتوي حروفاً وأرقاماً';
    }
    final u = Map<String, dynamic>.from(entry.value);
    u['pass'] = await makePasswordRecord(newPass);
    try {
      await _patchCore({'users/${entry.key}': u},
          log: 'تغيير كلمة مرور: ${str(u['user'])}', icon: 'fa-solid fa-key');
      users[entry.key] = u;
      notifyListeners();
      return null;
    } catch (_) {
      return _netMsg;
    }
  }

  // ======================= الكتابة في core =======================
  Future<void> _patchCore(Map<String, dynamic> body, {String log = '', String icon = 'fa-solid fa-pen'}) async {
    final b = Map<String, dynamic>.from(body);
    if (log.isNotEmpty) {
      final aid = uid();
      final a = <String, dynamic>{
        'id': aid,
        'text': clip(log, 500),
        'icon': icon,
        'at': nowIso(),
        'by': currentUser ?? 'النظام',
      };
      activity[aid] = a;
      b['activity/$aid'] = a;
      b['_empty/activity'] = false;
      // نفس حد نسخة الويب: آخر 120 نشاطاً
      if (activity.length > 150) {
        final ids = activity.keys.toList()..sort((x, y) => _byAtDesc(activity[x]!, activity[y]!));
        final drop = ids.skip(120).where((id) => id != aid).toList();
        for (final id in drop) {
          b['activity/$id'] = null;
          activity.remove(id);
        }
      }
    }
    if (b.isEmpty) return;
    b['_by'] = _client;
    b['_rev'] = DateTime.now().millisecondsSinceEpoch;
    await Api.fbPatch(Cfg.fbCore, b);
    // تحديث واجهة الزائر في هذا الجهاز فوراً
    unawaited(AppState.I.checkRemote());
  }

  // ======================= البطاقات =======================
  String? pubCode(String cat) => Cfg.publicSections[cat];

  bool isPublicCat(String cat) {
    final c = pubCode(cat);
    return c != null && (pubReady[c] ?? false);
  }

  List<Json> cardsOf(String cat) {
    final out = <Json>[];
    if (isPublicCat(cat)) {
      out.addAll(pubCards[pubCode(cat)]?.values ?? const <Json>[]);
    } else {
      for (final v in coreCards.values) {
        if (str(v['key']) == cat) out.add(v);
      }
    }
    out.sort((a, b) => str(b['created']).compareTo(str(a['created'])));
    return out;
  }

  int countOf(String cat) => cardsOf(cat).length;

  Future<void> _bumpPublic(String code) async {
    final ver = DateTime.now().millisecondsSinceEpoch;
    await Api.fbPut('${Cfg.fbPublicVersion}/$code', {
      'version': ver,
      'lastUpdated': DateTime.fromMillisecondsSinceEpoch(ver).toUtc().toIso8601String(),
      'count': pubCards[code]?.length ?? 0,
    });
  }

  void _refreshVisitor(String cat) {
    if (pubCode(cat) != null) unawaited(AppState.I.loadPublicSection(cat, force: true));
  }

  Future<void> _removeCardFrom(String cat, String id) async {
    if (isPublicCat(cat)) {
      final code = pubCode(cat)!;
      await Api.fbPatch('${Cfg.fbPublic}/$code', <String, dynamic>{id: null});
      pubCards[code]?.remove(id);
      await _bumpPublic(code);
    } else {
      coreCards.remove(id);
      await _patchCore({'cards/$id': null, '_empty/cards': coreCards.isEmpty});
    }
  }

  /// حفظ عنصر جديد أو معدّل. oldKey = قسمه السابق عند التعديل.
  Future<String?> saveCard(Json card, {String oldKey = '', bool isNew = false}) async {
    if (legacyFormat) return _legacyMsg;
    final id = safeKey(card['id']);
    final key = str(card['key']);
    final name = str(card['name']);
    if (id.isEmpty) return 'معرّف العنصر غير صالح';
    try {
      if (oldKey.isNotEmpty && oldKey != key) await _removeCardFrom(oldKey, id);
      final logText = isNew ? 'إضافة ${AppState.I.catOne(key)}: $name' : 'تعديل عنصر: $name';
      final icon = isNew ? 'fa-solid fa-plus' : 'fa-solid fa-pen';
      if (isPublicCat(key)) {
        final code = pubCode(key)!;
        await Api.fbPatch('${Cfg.fbPublic}/$code', <String, dynamic>{id: card});
        pubCards[code]![id] = card;
        await _bumpPublic(code);
        await _patchCore({}, log: logText, icon: icon);
      } else {
        coreCards[id] = card;
        await _patchCore({'cards/$id': card, '_empty/cards': false}, log: logText, icon: icon);
      }
      _refreshVisitor(key);
      if (oldKey.isNotEmpty && oldKey != key) _refreshVisitor(oldKey);
      notifyListeners();
      return null;
    } catch (_) {
      notifyListeners();
      return _netMsg;
    }
  }

  Future<String?> deleteCard(Json card) async {
    if (legacyFormat) return _legacyMsg;
    final id = safeKey(card['id']);
    final key = str(card['key']);
    try {
      await _removeCardFrom(key, id);
      await _patchCore({}, log: 'حذف عنصر: ${str(card['name'])}', icon: 'fa-regular fa-trash-can');
      _refreshVisitor(key);
      notifyListeners();
      return null;
    } catch (_) {
      notifyListeners();
      return _netMsg;
    }
  }

  // ======================= الطلبات =======================
  List<Json> get requestList => requests.values.toList()..sort(_byAtDesc);

  int get unreadRequests => requests.values.where((r) => r['read'] != true).length;

  String? _reqKey(String id) {
    if (requests.containsKey(id)) return id;
    for (final e in requests.entries) {
      if (str(e.value['id']) == id) return e.key;
    }
    return null;
  }

  Future<String?> _updateRequest(String id, void Function(Json r) change, {String log = ''}) async {
    if (legacyFormat) return _legacyMsg;
    final k = _reqKey(id);
    if (k == null) return 'الطلب غير موجود';
    final r = Map<String, dynamic>.from(requests[k]!);
    change(r);
    try {
      await _patchCore({'requests/$k': r}, log: log, icon: 'fa-regular fa-envelope-open');
      requests[k] = r;
      notifyListeners();
      return null;
    } catch (_) {
      return _netMsg;
    }
  }

  Future<String?> setRequestStatus(String id, String status) => _updateRequest(id, (r) {
        r['status'] = status;
        r['read'] = true;
      }, log: 'تحديث حالة طلب: $status');

  Future<String?> toggleRequestRead(String id) =>
      _updateRequest(id, (r) => r['read'] = r['read'] != true);

  Future<String?> markAllRead() async {
    if (legacyFormat) return _legacyMsg;
    final body = <String, dynamic>{};
    requests.forEach((k, r) {
      if (r['read'] != true) body['requests/$k/read'] = true;
    });
    if (body.isEmpty) return null;
    try {
      await _patchCore(body);
      for (final r in requests.values) {
        r['read'] = true;
      }
      notifyListeners();
      return null;
    } catch (_) {
      return _netMsg;
    }
  }

  Future<String?> deleteRequest(String id) async {
    if (legacyFormat) return _legacyMsg;
    final k = _reqKey(id);
    if (k == null) return null;
    final r = requests[k]!;
    try {
      final rest = Map<String, Json>.from(requests)..remove(k);
      await _patchCore({'requests/$k': null, '_empty/requests': rest.isEmpty},
          log: 'حذف طلب: ${str(r['type'])} · ${str(r['about'])}', icon: 'fa-regular fa-trash-can');
      requests.remove(k);
      unawaited(Api.fbDelete('${Cfg.fbRequestsPrivate}/${safeKey(id)}').catchError((_) {}));
      if (r['photo'] == true) {
        unawaited(Api.fbDelete('${Cfg.fbRequestMedia}/${safeKey(id)}').catchError((_) {}));
      }
      notifyListeners();
      return null;
    } catch (_) {
      return _netMsg;
    }
  }

  /// البيانات الخاصة للطلب (الاسم والهاتف...) والصورة المرفقة إن وُجدت
  Future<(Json?, Uint8List?)> requestDetails(Json r) async {
    final id = safeKey(r['id']);
    Json? priv;
    Uint8List? img;
    try {
      final p = await Api.fbGet('${Cfg.fbRequestsPrivate}/$id');
      if (p is Map) priv = Map<String, dynamic>.from(p);
    } catch (_) {}
    if (r['photo'] == true) {
      try {
        final m = await Api.fbGet('${Cfg.fbRequestMedia}/$id');
        if (m is Map) img = AppState.decodeDataUrl(str(m['img']));
      } catch (_) {}
    }
    return (priv, img);
  }

  // ======================= الإشعارات =======================
  List<Json> get notificationList => notifications.values.toList()..sort(_byAtDesc);

  Future<String?> saveNotification({String? id, required String title, required String text}) async {
    if (legacyFormat) return _legacyMsg;
    final t = clip(title, 150);
    final x = clip(text, 1500);
    if (t.isEmpty || x.isEmpty) return 'العنوان والنص مطلوبان';
    final isNew = id == null;
    final String key = isNew ? 'n${randomHex(8)}' : id!;
    final n = isNew
        ? <String, dynamic>{'id': key, 'title': t, 'text': x, 'at': nowIso(), 'active': true}
        : (Map<String, dynamic>.from(notifications[key] ?? {'id': key, 'at': nowIso(), 'active': true})
          ..['title'] = t
          ..['text'] = x);
    try {
      await _patchCore({'notifications/$key': n, '_empty/notifications': false},
          log: isNew ? 'إضافة إشعار: $t' : 'تعديل إشعار: $t',
          icon: isNew ? 'fa-regular fa-bell' : 'fa-solid fa-pen');
      notifications[key] = n;
      notifyListeners();
      return null;
    } catch (_) {
      return _netMsg;
    }
  }

  Future<String?> toggleNotification(String id) async {
    if (legacyFormat) return _legacyMsg;
    final cur = notifications[id];
    if (cur == null) return null;
    final n = Map<String, dynamic>.from(cur)..['active'] = cur['active'] == false;
    try {
      await _patchCore({'notifications/$id': n}, log: 'تغيير حالة إشعار', icon: 'fa-regular fa-bell');
      notifications[id] = n;
      notifyListeners();
      return null;
    } catch (_) {
      return _netMsg;
    }
  }

  Future<String?> deleteNotification(String id) async {
    if (legacyFormat) return _legacyMsg;
    final cur = notifications[id];
    if (cur == null) return null;
    final rest = Map<String, Json>.from(notifications)..remove(id);
    try {
      await _patchCore({'notifications/$id': null, '_empty/notifications': rest.isEmpty},
          log: 'حذف إشعار: ${str(cur['title'])}', icon: 'fa-regular fa-trash-can');
      notifications.remove(id);
      notifyListeners();
      return null;
    } catch (_) {
      return _netMsg;
    }
  }

  // ======================= الإعدادات =======================
  String setting(String k) => str(settings[k]);

  Future<String?> saveSettings(Map<String, dynamic> changes, {String log = 'تعديل إعدادات الموقع'}) async {
    if (legacyFormat) return _legacyMsg;
    final body = <String, dynamic>{};
    changes.forEach((k, v) => body['settings/$k'] = v);
    if (body.isEmpty) return null;
    try {
      await _patchCore(body, log: log, icon: 'fa-solid fa-gear');
      settings.addAll(changes);
      notifyListeners();
      return null;
    } catch (_) {
      return _netMsg;
    }
  }

  List<Json> get activityList => activity.values.toList()..sort(_byAtDesc);

  // ======================= رفع الصور إلى Supabase =======================
  static String _imgType(Uint8List b) {
    if (b.length > 4 && b[0] == 0x89 && b[1] == 0x50 && b[2] == 0x4E && b[3] == 0x47) return 'png';
    if (b.length > 12 && b[0] == 0x52 && b[1] == 0x49 && b[2] == 0x46 && b[3] == 0x46 && b[8] == 0x57) {
      return 'webp';
    }
    return 'jpeg';
  }

  /// يرفع الصورة ويعيد رابطها العام (نفس مسارات نسخة الويب: img/<السنة>/<الاسم>-<عشوائي>.<الامتداد>)
  Future<String> uploadImage(Uint8List bytes, String fileName) async {
    final s = AppState.I.settings;
    final base = s.supaUrl;
    final bucket = s.supaBucket;
    final type = _imgType(bytes);
    final ext = type == 'jpeg' ? 'jpg' : type;
    final id = 'm${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}${randomHex(2)}';
    final path = 'img/${DateTime.now().year}/$id-${randomHex(4)}.$ext';
    final r = await http
        .post(
          Uri.parse('$base/storage/v1/object/$bucket/$path'),
          headers: {
            'apikey': Cfg.supaKey,
            'Authorization': 'Bearer ${Cfg.supaKey}',
            'Content-Type': 'image/$type',
            'x-upsert': 'false',
            'cache-control': '31536000',
          },
          body: bytes,
        )
        .timeout(const Duration(seconds: 90));
    if (r.statusCode < 200 || r.statusCode >= 300) {
      throw Exception('supabase ${r.statusCode}');
    }
    final url = '$base/storage/v1/object/public/$bucket/$path';
    final kb = (bytes.length / 1024).round();
    try {
      await Api.fbPut('${Cfg.fbRoot}/mediaIndex/$id', {
        'u': url,
        'p': path,
        'kb': kb,
        'at': nowIso(),
        'n': clip(fileName, 80),
      });
    } catch (_) {}
    return url;
  }
}
