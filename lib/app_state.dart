// حالة التطبيق + محرك المزامنة مع Firebase (نفس منطق نسخة الويب للزائر):
//  1) نعرض نسخة الجهاز فوراً
//  2) نقرأ رقم النسخة core/_rev فقط (بايتات قليلة) ولا ننزّل القاعدة إلا إذا تغيّر
//  3) المدارس والمعاهد في عقدة public مستقلة برقم نسخة publicVersion
//  4) فحص خفيف كل 90 ثانية وعند العودة إلى التطبيق

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import 'api.dart';
import 'config.dart';
import 'models.dart';
import 'notifs.dart';
import 'store.dart';
import 'ui.dart';
import 'utils.dart';

class PublicSectionState {
  final String cat;
  bool loaded = false;
  bool remoteReady = false;
  int version = 0;
  int? count;
  int lastCheck = 0;
  Future<void>? loading;
  PublicSectionState(this.cat);
}

class Review {
  final String id;
  final int stars;
  final String nick;
  final String text;
  final String at;
  const Review(this.id, this.stars, this.nick, this.text, this.at);
}

class AppState extends ChangeNotifier {
  AppState._();
  static final AppState I = AppState._();

  AppData data = AppData();
  bool booted = false;
  bool cloudUp = true;
  bool _haveCache = false;
  int lastRev = 0;
  final String _clientId = clientId();
  Timer? _pollTimer;
  Timer? _remTimer;
  Timer? _retryTimer;
  int _lastWake = 0;
  bool _foreground = true;

  final Map<String, PublicSectionState> pub = {
    'schools': PublicSectionState('مدارس'),
    'institutes': PublicSectionState('معاهد'),
  };

  /// صور base64 القديمة (media:id) — تُجلب عند الحاجة فقط
  final Map<String, Uint8List> mediaBytes = {};
  final Set<String> _mediaWanted = {};

  GeoPoint? userPos;

  // ======================= الإقلاع =======================
  Future<void> init() async {
    final cached = await Store.readCache('core');
    if (cached is Map) {
      data = AppData.fromCore(cached, myIds());
      _haveCache = true;
    }
    for (final code in pub.keys) {
      final st = pub[code]!;
      final c = await Store.readCache('public_$code');
      if (c is Map && c['items'] is List) {
        final items = normalizeCards(c['items'], forceKey: st.cat);
        _replaceSection(st.cat, items);
        st.loaded = true;
        st.version = intOf(c['version']);
        st.count = items.length;
      }
    }
    notifyListeners();
    _remTimer?.cancel();
    _remTimer = Timer.periodic(const Duration(seconds: 30), (_) => remTick());
    unawaited(_bootAndMetrics());
  }

  Future<void> _bootAndMetrics() async {
    await cloudBoot();
    if (cloudUp) {
      await _loadMetrics();
      bumpMetric('visits');
    }
  }

  Future<void> cloudBoot() async {
    try {
      var rev = 0;
      try {
        rev = intOf(await Api.fbGet('${Cfg.fbCore}/_rev'));
      } catch (_) {
        rev = 0;
      }
      final cachedRev = Store.getInt(K.rev);
      if (rev != 0 && _haveCache && rev == cachedRev) {
        lastRev = rev;
      } else {
        final core = await Api.fbGet(Cfg.fbCore);
        if (core is Map) _applyCore(core, fromNetwork: true);
      }
      cloudUp = true;
      await Future.wait([loadPublicSection('مدارس'), loadPublicSection('معاهد')]);
      _startPoll();
    } catch (_) {
      cloudUp = false;
      _retryTimer?.cancel();
      _retryTimer = Timer(const Duration(seconds: 12), () {
        if (!cloudUp) unawaited(_bootAndMetrics());
      });
    }
    booted = true;
    notifyListeners();
  }

  PublicSectionState? _pubOf(String cat) {
    final code = Cfg.publicSections[cat];
    return code == null ? null : pub[code];
  }

  bool _fromPublicNode(String cat) {
    final st = _pubOf(cat);
    return st != null && st.loaded && (st.remoteReady || st.version > 0);
  }

  void _applyCore(Map core, {required bool fromNetwork}) {
    final preserved = data.cards.where((c) => _fromPublicNode(c.key)).toList();
    final next = AppData.fromCore(core, myIds());
    next.cards.removeWhere((c) => _fromPublicNode(c.key));
    next.cards.addAll(preserved);
    data = next;
    final rev = intOf(core['_rev']);
    if (rev > 0) lastRev = rev;
    if (fromNetwork) {
      _haveCache = true;
      unawaited(_saveCache());
      _checkNewNotifications();
      _checkBookingStatus();
    }
    notifyListeners();
  }

  Future<void> _saveCache() async {
    final m = data.toCache();
    m['cards'] =
        data.cards.where((c) => !_fromPublicNode(c.key)).map((c) => c.toJson()).toList();
    await Store.writeCache('core', m);
    await Store.setInt(K.rev, lastRev);
  }

  void _replaceSection(String cat, List<CardItem> items) {
    data.cards = data.cards.where((c) => c.key != cat).toList()..addAll(items);
  }

  /// يعرض المخبأ فوراً ثم يقرأ publicVersion الصغير فقط؛ لا يُنزَّل القسم إلا إذا تغيّر رقم نسخته
  Future<void> loadPublicSection(String cat, {bool force = false}) async {
    final st = _pubOf(cat);
    final code = Cfg.publicSections[cat];
    if (st == null || code == null) return;
    final running = st.loading;
    if (running != null) return running;
    final f = _loadPublic(cat, code, st, force);
    st.loading = f;
    try {
      await f;
    } finally {
      st.loading = null;
    }
  }

  Future<void> _loadPublic(String cat, String code, PublicSectionState st, bool force) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (!force && st.lastCheck != 0 && now - st.lastCheck < Cfg.publicVersionCheckMs) return;
    try {
      final metaRaw = await Api.fbGet('${Cfg.fbPublicVersion}/$code');
      st.lastCheck = now;
      var version = 0;
      int? count;
      if (metaRaw is Map) {
        version = intOf(metaRaw['version'] ?? metaRaw['lastUpdated']);
        if (metaRaw['count'] != null) count = intOf(metaRaw['count']);
      } else {
        version = intOf(metaRaw);
      }
      if (version == 0) {
        // القسم ما زال داخل core — نستخدم ما وصل منه
        st.loaded = true;
        st.remoteReady = false;
        return;
      }
      st.remoteReady = true;
      if (count != null) st.count = count;
      if (st.loaded && st.version == version) return;
      final remote = await Api.fbGet('${Cfg.fbPublic}/$code');
      final items = normalizeCards(remote, forceKey: cat);
      _replaceSection(cat, items);
      st.loaded = true;
      st.version = version;
      st.count = items.length;
      await Store.writeCache('public_$code', {
        'version': version,
        'items': items.map((c) => c.toJson()).toList(),
      });
      unawaited(_saveCache());
      notifyListeners();
    } catch (_) {
      st.loaded = true;
    }
  }

  // ======================= المزامنة الدورية =======================
  void _startPoll() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 90), (_) {
      if (_foreground) unawaited(checkRemote());
    });
  }

  /// فحص رقم النسخة فقط، وتنزيل القاعدة إن تغيّرت. يعيد true عند نجاح الاتصال.
  Future<bool> checkRemote() async {
    try {
      final rev = intOf(await Api.fbGet('${Cfg.fbCore}/_rev'));
      if (rev > lastRev) {
        final core = await Api.fbGet(Cfg.fbCore);
        if (core is Map) _applyCore(core, fromNetwork: true);
      }
      if (!cloudUp) {
        cloudUp = true;
        notifyListeners();
      }
      return true;
    } catch (_) {
      if (cloudUp) {
        cloudUp = false;
        notifyListeners();
      }
      return false;
    }
  }

  /// سحب للتحديث: فحص النسخة + إعادة فحص الأقسام العامة
  Future<void> refreshAll() async {
    final ok = await checkRemote();
    if (ok) {
      await Future.wait([
        loadPublicSection('مدارس', force: true),
        loadPublicSection('معاهد', force: true),
      ]);
      if (!booted) {
        booted = true;
        _startPoll();
      }
      notifyListeners();
    } else {
      toast('تعذّر الاتصال — تُعرض آخر نسخة محفوظة', ToastType.warn);
    }
  }

  void onResume() {
    _foreground = true;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastWake < 20000) return;
    _lastWake = now;
    unawaited(checkRemote());
    remTick();
  }

  void onPause() {
    _foreground = false;
    unawaited(flushMetrics());
  }

  // ======================= العدادات (زيارات / بحث) =======================
  Map<String, int> _metrics = {'visits': 0, 'newUsers': 0, 'searches': 0};
  bool _metricsLoaded = false;
  bool _metricsDirty = false;
  Timer? _metricsTimer;
  Timer? _searchTimer;

  Future<void> _loadMetrics() async {
    try {
      final m = await Api.fbGet(Cfg.fbMetrics);
      if (m is Map) {
        _metrics = {
          'visits': intOf(m['visits']),
          'newUsers': intOf(m['newUsers']),
          'searches': intOf(m['searches']),
        };
        _metricsLoaded = true;
      }
    } catch (_) {}
  }

  void bumpMetric(String k) {
    if (!_metricsLoaded) return;
    _metrics[k] = (_metrics[k] ?? 0) + 1;
    _metricsDirty = true;
    _metricsTimer?.cancel();
    _metricsTimer = Timer(const Duration(seconds: 15), () => unawaited(flushMetrics()));
  }

  void countSearch() {
    _searchTimer?.cancel();
    _searchTimer = Timer(const Duration(milliseconds: 900), () => bumpMetric('searches'));
  }

  Future<void> flushMetrics() async {
    if (!_metricsDirty || !_metricsLoaded) return;
    _metricsDirty = false;
    _metricsTimer?.cancel();
    try {
      await Api.fbPatch(Cfg.fbMetrics, Map<String, dynamic>.from(_metrics));
    } catch (_) {
      _metricsDirty = true;
    }
  }

  // ======================= استعلامات العرض =======================
  AppSettings get settings => data.settings;

  List<CardItem> get publicCards => data.cards.where((c) => c.published).toList();

  CardItem? cardById(String id) {
    for (final c in data.cards) {
      if (c.id == id) return c;
    }
    return null;
  }

  AppCategory? catByKey(String key) {
    for (final c in data.categories) {
      if (c.key == key) return c;
    }
    return null;
  }

  String catName(String key) => catByKey(key)?.name ?? (key.isEmpty ? 'غير مصنّف' : key);

  String catOne(String key) => catByKey(key)?.one ?? kCatOne[key] ?? key;

  int catCount(String key) {
    final st = _pubOf(key);
    if (st != null && !st.loaded && st.count != null) return st.count!;
    var n = 0;
    for (final c in data.cards) {
      if (c.published && c.key == key) n++;
    }
    return n;
  }

  List<AdItem> get activeAds =>
      settings.adsOn ? data.ads.where((a) => a.active).toList() : <AdItem>[];

  List<String> teacherSpecialtyChoices() {
    final list = List<String>.from(Cfg.teacherSpecialties);
    for (final c in data.cards) {
      if (!c.published || c.key != 'مدرسين') continue;
      final sp = teacherSpecialtyKey(c.specialty);
      if (sp.isNotEmpty && !list.contains(sp)) list.add(sp);
    }
    return list;
  }

  List<String> specialtyList(String cat) {
    final seen = <String>{};
    for (final c in data.cards) {
      if (!c.published) continue;
      if (cat.isNotEmpty && c.key != cat) continue;
      final v = c.specialty.trim();
      if (v.isNotEmpty) seen.add(v);
    }
    return seen.toList()..sort();
  }

  /// البحث والفلترة المتقدمة (مطابق لـ proFilter في نسخة الويب)
  List<CardItem> search({
    String q = '',
    String cat = '',
    String dist = '',
    String specialty = '',
    String sort = 'new',
  }) {
    final query = q.trim().toLowerCase();
    final list = data.cards.where((c) {
      if (!c.published) return false;
      if (cat.isNotEmpty && c.key != cat) return false;
      if (dist.isNotEmpty && c.dist != dist) return false;
      if (specialty.isNotEmpty && c.specialty != specialty) return false;
      if (query.isEmpty) return true;
      final hay =
          '${c.name} ${c.desc} ${c.key} ${catName(c.key)} ${c.city} ${c.gov} ${c.dist} ${c.phone} ${c.specialty} ${c.extraText}'
              .toLowerCase();
      return hay.contains(query);
    }).toList();
    sortCards(list, sort);
    return list;
  }

  void sortCards(List<CardItem> list, String sort) {
    int base(CardItem a, CardItem b) {
      if (sort == 'name') return a.name.compareTo(b.name);
      if (sort == 'rating') return b.rating.compareTo(a.rating);
      return b.created.compareTo(a.created);
    }

    list.sort((a, b) {
      final f = (b.featured ? 1 : 0) - (a.featured ? 1 : 0);
      return f != 0 ? f : base(a, b);
    });
  }

  // ======================= الصور القديمة media:id =======================
  Uint8List? mediaFor(String id) {
    final b = mediaBytes[id];
    if (b != null) return b;
    if (_mediaWanted.add(id)) unawaited(_fetchMedia(id));
    return null;
  }

  Future<void> _fetchMedia(String id) async {
    try {
      final v = await Api.fbGet('${Cfg.fbMedia}/${safeKey(id)}');
      final bytes = decodeDataUrl(str(v));
      if (bytes != null) {
        mediaBytes[id] = bytes;
        notifyListeners();
      }
    } catch (_) {
      _mediaWanted.remove(id);
    }
  }

  static Uint8List? decodeDataUrl(String s) {
    if (!s.startsWith('data:image/')) return null;
    final i = s.indexOf(',');
    if (i < 0) return null;
    try {
      return base64Decode(s.substring(i + 1).replaceAll(RegExp(r'\s'), ''));
    } catch (_) {
      return null;
    }
  }

  // ======================= الوضع الليلي =======================
  String get themePref {
    final v = Store.getString(K.themePref) ?? '';
    return (v == 'dark' || v == 'light') ? v : '';
  }

  bool get isDark => (themePref.isNotEmpty ? themePref : settings.theme) == 'dark';

  Future<void> toggleTheme() async {
    final next = isDark ? 'light' : 'dark';
    await Store.setString(K.themePref, next);
    notifyListeners();
    toast(next == 'dark' ? 'تم تفعيل الوضع الليلي' : 'تم تفعيل الوضع النهاري');
  }

  // ======================= المفضلة =======================
  List<String> get favoriteIds => Store.getStringList(K.fav);

  bool isFavorite(String id) => favoriteIds.contains(id);

  int get favoriteCount => favoriteIds.where((id) => cardById(id) != null).length;

  Future<void> toggleFavorite(String id) async {
    final a = favoriteIds;
    if (a.remove(id)) {
      toast('تمت الإزالة من المفضلة');
    } else {
      a.insert(0, id);
      toast('تمت الإضافة إلى المفضلة');
    }
    await Store.setJson(K.fav, a.take(500).toList());
    notifyListeners();
  }

  List<CardItem> get favoriteCards {
    final ids = favoriteIds;
    final out = <CardItem>[];
    for (final id in ids) {
      final c = cardById(id);
      if (c != null && c.published) out.add(c);
    }
    return out;
  }

  // ======================= المقارنة =======================
  List<String> get compareIds =>
      Store.getStringList(K.compare).where((id) => cardById(id) != null).toList();

  bool inCompare(String id) => compareIds.contains(id);

  Future<void> toggleCompare(String id) async {
    final a = compareIds;
    if (a.remove(id)) {
      toast('أُزيل من المقارنة');
    } else {
      if (a.length >= 3) {
        toast('يمكن مقارنة 3 عناصر كحد أقصى', ToastType.warn);
        return;
      }
      a.add(id);
      toast(a.length < 2 ? 'أُضيف — اختر عنصراً آخر للمقارنة' : 'أُضيف إلى المقارنة');
    }
    await Store.setJson(K.compare, a);
    notifyListeners();
  }

  Future<void> clearCompare() async {
    await Store.remove(K.compare);
    notifyListeners();
  }

  // ======================= الإشعارات العامة =======================
  List<NotifItem> get publishedNotifications =>
      data.notifications.where((n) => n.active).toList();

  int get unreadNotifications {
    final read = Store.getStringList(K.notifRead).toSet();
    return publishedNotifications.where((n) => !read.contains(n.id)).length;
  }

  Future<void> markNotificationsRead() async {
    await Store.setJson(
        K.notifRead, publishedNotifications.map((n) => n.id).take(300).toList());
    notifyListeners();
  }

  void _checkNewNotifications() {
    final list = publishedNotifications;
    final knownRaw = Store.getJson(K.notifAnnounced, null);
    final ids = list.map((n) => n.id).take(300).toList();
    if (knownRaw is! List) {
      // أول تشغيل: لا نعلن عن الإشعارات القديمة
      unawaited(Store.setJson(K.notifAnnounced, ids));
      return;
    }
    final known = knownRaw.map((e) => e.toString()).toSet();
    final now = DateTime.now();
    final fresh = list.where((n) {
      if (known.contains(n.id)) return false;
      final t = parseIso(n.at);
      return t == null || now.difference(t).inDays < 3;
    }).toList();
    if (fresh.isNotEmpty) {
      showBanner(fresh.first.title, fresh.first.text);
      for (final n in fresh.take(3)) {
        unawaited(Notifs.show('notif_${n.id}', n.title, n.text));
      }
    }
    final merged = <String>{...ids, ...known}.take(300).toList();
    unawaited(Store.setJson(K.notifAnnounced, merged));
  }

  // ======================= طلبات هذا الجهاز =======================
  Set<String> myIds() => {...Store.getStringList(K.mine), ...Store.getMap(K.bookings).keys};

  List<String> get mySuggestionIds => Store.getStringList(K.mine);

  Map<String, dynamic> get bookings => Store.getMap(K.bookings);

  int get unseenBookings {
    var n = 0;
    for (final v in bookings.values) {
      if (v is Map && v['seen'] == false) n++;
    }
    return n;
  }

  Future<void> markBookingsSeen() async {
    final b = bookings;
    var changed = false;
    for (final k in b.keys) {
      final v = b[k];
      if (v is Map && v['seen'] == false) {
        v['seen'] = true;
        changed = true;
      }
    }
    if (changed) {
      await Store.setJson(K.bookings, b);
      notifyListeners();
    }
  }

  RequestItem? myRequest(String id) {
    for (final r in data.myRequests) {
      if (r.id == id) return r;
    }
    return null;
  }

  /// حد الإرسال: 5 طلبات كل 10 دقائق من الجهاز الواحد
  Future<bool> allowPublicRequest() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final raw = Store.getJson(K.requestTimes, const []);
    final times = <int>[];
    if (raw is List) {
      for (final x in raw) {
        final t = intOf(x);
        if (now - t < 10 * 60 * 1000) times.add(t);
      }
    }
    if (times.length >= 5) return false;
    times.add(now);
    await Store.setJson(K.requestTimes, times);
    return true;
  }

  /// الاشتراك في النشرة البريدية — نفس subscribe في نسخة الويب (طلب من نوع «اشتراك» يظهر في لوحة المدير)
  Future<String?> subscribeNewsletter(String email) async {
    if (!await allowPublicRequest()) return 'يرجى الانتظار قليلاً قبل المحاولة مجدداً';
    final mail = clip(email, 180).toLowerCase();
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$').hasMatch(mail)) return 'أدخل بريداً إلكترونياً صحيحاً';
    final done = Store.getJson('kp_public_request_subs', const []);
    final list = done is List ? done.map((e) => e.toString()).toList() : <String>[];
    if (list.contains(mail)) return 'هذا البريد مشترك مسبقاً';
    final id = uid();
    try {
      await Api.fbPatch(Cfg.fbCore, {
        'requests/${safeKey(id)}': {
          'id': id,
          'type': 'اشتراك',
          'about': 'النشرة البريدية',
          'from': mail,
          'msg': 'طلب اشتراك في النشرة',
          'at': nowIso(),
          'read': false,
        },
        '_empty/requests': false,
        '_by': _clientId,
        '_rev': DateTime.now().millisecondsSinceEpoch,
      });
      await Store.setJson('kp_public_request_subs', [...list, mail]);
      return null;
    } catch (_) {
      return 'تعذّر الإرسال — تحقق من الاتصال';
    }
  }

  /// يكتب الطلب داخل core/requests بتحديث جزئي (نفس صيغة نسخة الويب) ليظهر في لوحة المدير
  Future<void> _pushRequest(RequestItem r) async {
    await Api.fbPatch(Cfg.fbCore, {
      'requests/${r.id}': r.toJson(),
      '_by': _clientId,
      '_rev': DateTime.now().millisecondsSinceEpoch,
    });
    data.myRequests = [r, ...data.myRequests.where((x) => x.id != r.id)];
    unawaited(_saveCache());
  }

  Future<void> _removeRequests(List<String> ids) async {
    if (ids.isEmpty) return;
    final body = <String, dynamic>{
      '_by': _clientId,
      '_rev': DateTime.now().millisecondsSinceEpoch,
    };
    for (final id in ids) {
      body['requests/${safeKey(id)}'] = null;
    }
    await Api.fbPatch(Cfg.fbCore, body);
    data.myRequests = data.myRequests.where((x) => !ids.contains(x.id)).toList();
    unawaited(_saveCache());
  }

  /// طلب تسجيل / حجز مقعد. يعيد null عند النجاح أو رسالة الخطأ.
  Future<String?> submitBooking({
    required CardItem card,
    required String name,
    required String phone,
    required String stage,
    required String time,
    required String subject,
    required String note,
  }) async {
    if (!await allowPublicRequest()) return 'يرجى الانتظار قليلاً قبل إرسال طلب جديد';
    final id = uid();
    final at = nowIso();
    try {
      await Api.fbPut('${Cfg.fbRequestsPrivate}/$id', {
        'name': name,
        'phone': phone,
        'stage': stage,
        'time': time,
        'subject': subject,
        'note': note,
        'cardId': card.id,
        'at': at,
      });
      // نسجّل المعرّف محلياً قبل الكتابة حتى يُعتبر الطلب «من هذا الجهاز»
      final b = bookings;
      b[id] = {
        'cardId': card.id,
        'name': card.name,
        'at': DateTime.now().millisecondsSinceEpoch,
        'status': 'قيد المراجعة',
      };
      await Store.setJson(K.bookings, b);
      await _pushRequest(RequestItem(
        id: id,
        type: 'طلب تسجيل',
        about: card.name,
        from: '🔒 بيانات خاصة',
        msg: 'المرحلة: $stage — الوقت: $time${subject.isEmpty ? '' : ' — $subject'}',
        at: at,
        status: 'قيد المراجعة',
        cardId: card.id,
        priv: true,
      ));
    } catch (_) {
      final b = bookings;
      if (b.remove(id) != null) await Store.setJson(K.bookings, b);
      unawaited(Api.fbDelete('${Cfg.fbRequestsPrivate}/$id').catchError((_) {}));
      return 'تعذّر الإرسال — تحقق من الاتصال وحاول مجدداً';
    }
    notifyListeners();
    return null;
  }

  Future<void> cancelBooking(String id) async {
    unawaited(Api.fbDelete('${Cfg.fbRequestsPrivate}/${safeKey(id)}').catchError((_) {}));
    try {
      await _removeRequests([id]);
    } catch (_) {}
    final b = bookings;
    b.remove(id);
    await Store.setJson(K.bookings, b);
    notifyListeners();
    toast('تم إلغاء الطلب');
  }

  /// متابعة تغيّر حالة الطلبات القادمة من الإدارة
  void _checkBookingStatus() {
    final b = bookings;
    var changed = false;
    for (final id in b.keys) {
      final v = b[id];
      if (v is! Map) continue;
      final r = myRequest(id);
      final st = r == null ? 'مغلق' : (r.status.isEmpty ? 'قيد المراجعة' : r.status);
      final old = str(v['status']);
      if (st != old) {
        if (old.isNotEmpty && st != 'مغلق') {
          final text = '«${str(v['name'])}»: $st';
          showBanner('تحديث على طلبك', text);
          unawaited(Notifs.show('$id$st', 'تحديث على طلبك', text));
        }
        v['status'] = st;
        v['seen'] = false;
        changed = true;
      }
    }
    if (changed) unawaited(Store.setJson(K.bookings, b));
  }

  /// اقتراح إضافة (مع صورة اختيارية). يعيد null عند النجاح أو رسالة الخطأ.
  Future<String?> submitSuggestion({
    required String name,
    required String cat,
    required String area,
    required String contact,
    required String note,
    Uint8List? photoJpeg,
  }) async {
    if (!await allowPublicRequest()) return 'يرجى الانتظار قليلاً قبل إرسال اقتراح جديد';
    final id = uid();
    final at = nowIso();
    var hasPhoto = false;
    if (photoJpeg != null) {
      try {
        await Api.fbPut('${Cfg.fbRequestMedia}/$id', {
          'img': 'data:image/jpeg;base64,${base64Encode(photoJpeg)}',
          'at': at,
        });
        hasPhoto = true;
      } catch (_) {
        toast('تعذّر رفع الصورة — سيُرسل الاقتراح بدونها', ToastType.warn);
      }
    }
    var priv = false;
    try {
      await Api.fbPut('${Cfg.fbRequestsPrivate}/$id', {
        'contact': contact,
        'cat': cat,
        'area': area,
        'note': note,
        'at': at,
      });
      priv = true;
    } catch (_) {}
    final parts = <String>[
      'القسم: $cat',
      if (area.isNotEmpty) 'المنطقة: $area',
      if (hasPhoto) '📷 مرفق صورة',
    ];
    try {
      final mine = mySuggestionIds..insert(0, id);
      await Store.setJson(K.mine, mine.take(50).toList());
      await _pushRequest(RequestItem(
        id: id,
        type: 'اقتراح إضافة',
        about: name,
        from: priv ? '🔒 بيانات خاصة' : '—',
        msg: parts.join(' — '),
        at: at,
        photo: hasPhoto,
        priv: priv,
      ));
    } catch (_) {
      final mine = mySuggestionIds..remove(id);
      await Store.setJson(K.mine, mine);
      if (hasPhoto) unawaited(Api.fbDelete('${Cfg.fbRequestMedia}/$id').catchError((_) {}));
      if (priv) unawaited(Api.fbDelete('${Cfg.fbRequestsPrivate}/$id').catchError((_) {}));
      return 'تعذّر الإرسال — تحقق من الاتصال وحاول مجدداً';
    }
    notifyListeners();
    return null;
  }

  int get myServerItemsCount => myIds().where((id) => myRequest(id) != null).length;

  /// حذف طلبات واقتراحات هذا الجهاز من الخادم (مع صورها وبياناتها الخاصة)
  Future<int> deleteMine() async {
    final ids = myIds().toList();
    final list = data.myRequests.where((r) => ids.contains(r.id)).toList();
    for (final id in ids) {
      unawaited(Api.fbDelete('${Cfg.fbRequestMedia}/${safeKey(id)}').catchError((_) {}));
      unawaited(Api.fbDelete('${Cfg.fbRequestsPrivate}/${safeKey(id)}').catchError((_) {}));
    }
    await _removeRequests(ids);
    await Store.setJson(K.mine, <String>[]);
    await Store.setJson(K.bookings, <String, dynamic>{});
    notifyListeners();
    return list.length;
  }

  Future<void> wipeLocal() async {
    // نلغي التذكيرات المجدولة قبل مسح قائمتها
    for (final r in reminders) {
      await Notifs.cancel(str(r['id']));
    }
    await Store.wipeUserKeys({K.mine, K.bookings});
    notifyListeners();
  }

  // ======================= التقييمات =======================
  final Map<String, List<Review>> _revCache = {};
  final Map<String, int> _revAt = {};

  List<String> get hiddenReviews => Store.getStringList(K.hiddenReviews);

  bool reviewedBefore(String cardId) => Store.getStringList(K.reviewed).contains(cardId);

  Future<List<Review>> loadReviews(String cardId, {bool force = false}) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final cached = _revCache[cardId];
    if (!force && cached != null && now - (_revAt[cardId] ?? 0) < 15000) return cached;
    final hidden = hiddenReviews.toSet();
    final out = <Review>[];
    try {
      final d = await Api.fbGet('${Cfg.fbReviews}/${safeKey(cardId)}');
      if (d is Map) {
        for (final e in d.entries) {
          final r = e.value;
          if (r is! Map) continue;
          final id = str(r['id']).isEmpty ? e.key.toString() : str(r['id']);
          if (str(r['status']) != 'approved' || hidden.contains(id)) continue;
          out.add(Review(
            id,
            intOf(r['stars']).clamp(0, 5).toInt(),
            clip(r['nick'], 30),
            clip(r['text'], 300),
            str(r['at']),
          ));
        }
      }
    } catch (_) {}
    out.sort((a, b) => b.at.compareTo(a.at));
    _revCache[cardId] = out;
    _revAt[cardId] = now;
    return out;
  }

  Future<String?> sendReview(String cardId, int stars, String nick, String text) async {
    if (stars < 1) return 'اختر عدد النجوم';
    if (hasContactInfo('$text $nick')) return 'يُمنع إضافة روابط أو أرقام هواتف أو معرّفات';
    if (hasBadWords(text) || hasBadWords(nick)) return 'يحتوي النص على كلمات غير مناسبة';
    if (!await allowPublicRequest()) return 'يرجى الانتظار قليلاً';
    final id = uid();
    try {
      await Api.fbPut('${Cfg.fbReviews}/${safeKey(cardId)}/$id', {
        'id': id,
        'cardId': cardId,
        'stars': stars,
        'nick': nick,
        'text': text,
        'at': nowIso(),
        'status': 'pending',
      });
    } catch (_) {
      return 'تعذّر الإرسال — حاول لاحقاً';
    }
    final d = Store.getStringList(K.reviewed)..add(cardId);
    await Store.setJson(K.reviewed, d.length > 300 ? d.sublist(d.length - 300) : d);
    return null;
  }

  Future<void> hideReview(String cardId, String reviewId) async {
    final h = hiddenReviews..add(reviewId);
    await Store.setJson(K.hiddenReviews, h.length > 500 ? h.sublist(h.length - 500) : h);
    _revCache.remove(cardId);
  }

  Future<void> reportReview(String cardId, String reviewId) async {
    try {
      await Api.fbPut('${Cfg.fbReviewReports}/${safeKey(reviewId)}/${uid()}', {
        'cardId': cardId,
        'at': nowIso(),
      });
    } catch (_) {}
    await hideReview(cardId, reviewId);
  }

  // ======================= التذكيرات =======================
  List<Map<String, dynamic>> get reminders => Store.getMapList(K.reminders);

  Future<bool> ensureNotifPermission() async {
    if (Notifs.enabled) return true;
    if (Notifs.pref == 'off') return false;
    return Notifs.requestPermission();
  }

  Future<void> remAdd(Map<String, dynamic> r) async {
    final id = str(r['id']);
    final a = reminders.where((x) => str(x['id']) != id).toList()..add(r);
    await Store.setJson(K.reminders, a);
    final ok = await ensureNotifPermission();
    if (!ok) return;
    final lead = intOf(r['lead']);
    final w = r['weekly'];
    if (w is Map) {
      await Notifs.scheduleWeekly(
        id,
        str(r['title']),
        str(r['body']),
        jsWeekday: intOf(w['wd']),
        hour: intOf(w['h']),
        minute: intOf(w['m']),
        leadMinutes: lead,
      );
    } else {
      final at = intOf(r['at']) - lead * 60000;
      await Notifs.scheduleAt(
        id,
        str(r['title']),
        str(r['body']),
        DateTime.fromMillisecondsSinceEpoch(at),
      );
    }
  }

  Future<void> remDel(String id) async {
    await Store.setJson(K.reminders, reminders.where((x) => str(x['id']) != id).toList());
    await Notifs.cancel(id);
    notifyListeners();
  }

  /// تذكير داخل التطبيق أثناء استخدامه (إشعار النظام يتكفّل بالباقي عندما يكون التطبيق مغلقاً)
  void remTick() {
    if (!_foreground) return;
    final a = reminders;
    if (a.isEmpty) return;
    final nowDt = DateTime.now();
    final now = nowDt.millisecondsSinceEpoch;
    var changed = false;
    for (final r in a) {
      final lead = intOf(r['lead']);
      final w = r['weekly'];
      if (w is Map) {
        final jsToday = nowDt.weekday % 7;
        if (jsToday != intOf(w['wd'])) continue;
        final ft = DateTime(nowDt.year, nowDt.month, nowDt.day, intOf(w['h']), intOf(w['m']))
                .millisecondsSinceEpoch -
            lead * 60000;
        final key = '${nowDt.year}-${nowDt.month}-${nowDt.day}';
        if (now >= ft && now - ft < 15 * 60000 && str(r['last']) != key) {
          r['last'] = key;
          changed = true;
          showBanner(str(r['title']), str(r['body']));
        }
      } else {
        final f = intOf(r['at']) - lead * 60000;
        if (r['fired'] != true && now >= f && now - f < 12 * 3600000) {
          r['fired'] = true;
          changed = true;
          showBanner(str(r['title']), str(r['body']));
        }
      }
    }
    if (changed) unawaited(Store.setJson(K.reminders, a));
  }

  // ======================= الموقع =======================
  /// يحدّد موقع المستخدم على جهازه فقط. يعيد null عند النجاح أو رسالة الخطأ.
  Future<String?> locate() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return 'خدمة الموقع متوقفة على هذا الجهاز';
      }
      var p = await Geolocator.checkPermission();
      if (p == LocationPermission.denied) p = await Geolocator.requestPermission();
      if (p == LocationPermission.denied || p == LocationPermission.deniedForever) {
        return 'لم يُسمح بالوصول للموقع — فعّله من إعدادات الجهاز';
      }
      final pos = await Geolocator.getCurrentPosition().timeout(const Duration(seconds: 20));
      userPos = GeoPoint(pos.latitude, pos.longitude);
      notifyListeners();
      return null;
    } catch (_) {
      return 'تعذّر تحديد موقعك';
    }
  }

  void refreshUi() => notifyListeners();
}
