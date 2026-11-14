// بقية عمليات لوحة الإدارة — مطابقة لوظائف نسخة الويب:
// الأقسام، المحافظات والمراكز، اللوحات الإعلانية ورسالة الترحيب، الإحصائيات، المستخدمون،
// مكتبة الوسائط، سجل النشاطات، أدوات قواعد البيانات، النسخ الاحتياطي.

part of 'admin_store.dart';

/// خطأ تحقق برسالة عربية تُعرض للمدير
class AdminError implements Exception {
  final String message;
  const AdminError(this.message);
  @override
  String toString() => message;
}

/// أيقونات الأقسام المتاحة — نفس ICON_CHOICES في نسخة الويب
const List<String> kIconChoices = [
  'fa-solid fa-chalkboard-user', 'fa-solid fa-graduation-cap', 'fa-solid fa-building-columns',
  'fa-solid fa-school', 'fa-solid fa-users-rectangle', 'fa-solid fa-book', 'fa-solid fa-book-open-reader',
  'fa-solid fa-laptop-code', 'fa-solid fa-language', 'fa-solid fa-flask', 'fa-solid fa-microscope',
  'fa-solid fa-calculator', 'fa-solid fa-palette', 'fa-solid fa-music', 'fa-solid fa-futbol',
  'fa-solid fa-stethoscope', 'fa-solid fa-scale-balanced', 'fa-solid fa-helmet-safety', 'fa-solid fa-mosque',
  'fa-solid fa-pen-ruler', 'fa-solid fa-user-tie', 'fa-solid fa-certificate', 'fa-solid fa-briefcase',
  'fa-solid fa-globe', 'fa-regular fa-folder-open',
];

/// ألوان الأقسام الافتراضية [الخلفية، الأيقونة] — نفس CAT_PALETTE
const List<List<String>> kCatPalette = [
  ['#F2ECFF', '#7C3AED'], ['#E9F1FE', '#2F6FE4'], ['#FEF5E4', '#F0A31B'], ['#E7F7F1', '#0F9D6E'],
  ['#FEEDE3', '#F2711C'], ['#FEECEF', '#EF4444'], ['#EEF1FE', '#5B5BD6'], ['#E3F8ED', '#12A05F'],
  ['#E8F4FF', '#0EA5E9'], ['#FFF1F7', '#DB2777'],
];

/// الحقول ذات الخيارات المحددة في استمارات الأقسام — نفس CAT_FORMS
const Map<String, Map<String, List<String>>> kSelectOpts = {
  'مدرسين': {
    'stage': ['ابتدائي', 'متوسط', 'إعدادي', 'جامعي', 'جميع المراحل'],
    'mode': ['حضوري', 'أونلاين', 'حضوري وأونلاين'],
    'gtype': ['فردي (خصوصي)', 'جماعي (كروب)', 'فردي وجماعي'],
    'gender': ['بنين', 'بنات', 'بنين وبنات'],
  },
  'جامعات': {
    'utype': ['حكومية', 'أهلية', 'أجنبية / دولية'],
    'study': ['صباحي', 'مسائي', 'صباحي ومسائي'],
    'degrees': ['بكالوريوس', 'بكالوريوس + ماجستير', 'بكالوريوس + ماجستير + دكتوراه'],
  },
  'معاهد': {
    'itype': ['حكومي', 'أهلي', 'مركز تدريب'],
    'study': ['صباحي', 'مسائي', 'صباحي ومسائي'],
    'cert': ['دبلوم تقني', 'بكالوريوس تقني', 'شهادة دورة'],
  },
  'مدارس': {
    'stype': ['حكومية', 'أهلية', 'دولية'],
    'stage': ['رياض أطفال', 'ابتدائية', 'متوسطة', 'إعدادية', 'ثانوية', 'متعددة المراحل'],
    'gender': ['بنين', 'بنات', 'مختلط'],
    'curriculum': ['عراقي', 'دولي', 'عراقي ودولي'],
    'lang': ['عربي', 'إنكليزي', 'ثنائي اللغة'],
    'buses': ['متوفرة', 'غير متوفرة'],
  },
};

/// صور الخلفيات والشعار في الإعدادات
const List<List<String>> kBgKeys = [
  ['heroImg', 'خلفية الواجهة الرئيسية', 'الصورة الكبيرة خلف العنوان في أعلى الموقع'],
  ['pageBg', 'خلفية الموقع العامة', 'تظهر خلف كل صفحات الموقع'],
  ['adminBg', 'خلفية لوحة التحكم', 'خلفية شاشة الإدارة'],
  ['loginBg', 'خلفية نافذة تسجيل الدخول', 'الخلفية خلف نافذة الدخول'],
  ['logoImg', 'شعار المنصة', 'يظهر بجانب اسم المنصة وفي لوحة التحكم'],
];

const String kNoGov = 'غير محدد';
const List<String> kArMonths = [
  'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
  'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
];
const List<String> _emptyFlagKeys = [
  'cards', 'categories', 'geo', 'requests', 'notifications', 'activity', 'ads',
];

/// صورة GIF بحجم 1×1 لاختبار الرفع — نفس testSupabase
final Uint8List _testGif = Uint8List.fromList(const [
  71, 73, 70, 56, 57, 97, 1, 0, 1, 0, 128, 0, 0, 0, 0, 0, 255, 255, 255, 33, 249, 4, 1, 0, 0, 0, 0,
  44, 0, 0, 0, 0, 1, 0, 1, 0, 0, 2, 2, 68, 1, 0, 59,
]);

List<String> _sortedKeys(Map<String, Json> m) => m.keys.toList()..sort();

bool _validKey(String k) => !RegExp(r'[.$#\[\]/]').hasMatch(k);

List<String> cardImages(Json c) {
  final out = <String>[];
  void add(dynamic x) {
    final s = str(x).trim();
    if (s.isNotEmpty && !out.contains(s)) out.add(s);
  }

  add(c['img']);
  final imgs = c['images'];
  if (imgs is List) {
    for (final x in imgs) {
      add(x);
    }
  }
  return out;
}

extension AdminOps on AdminStore {
  // ======================= مساعدات عامة =======================
  List<Json> get allCards => [
        ...coreCards.values,
        for (final m in pubCards.values) ...m.values,
      ];

  List<Json> ordered(Map<String, Json> m) => [for (final k in _sortedKeys(m)) m[k]!];

  Future<String?> _run(Future<void> Function() fn) async {
    if (legacyFormat) return AdminStore._legacyMsg;
    try {
      await fn();
      changed();
      return null;
    } on AdminError catch (e) {
      changed();
      return e.message;
    } catch (_) {
      changed();
      return AdminStore._netMsg;
    }
  }

  /// يعدّل كل العناصر المطابقة في core و public، ويعيد جسم التحديث الخاص بـ core
  Future<Json> _rewriteCards(bool Function(Json c) match, void Function(Json c) change) async {
    final body = <String, dynamic>{};
    for (final k in coreCards.keys.toList()) {
      final c = coreCards[k]!;
      if (!match(c)) continue;
      final n = Map<String, dynamic>.from(c);
      change(n);
      coreCards[k] = n;
      body['cards/$k'] = n;
    }
    for (final e in pubCards.entries) {
      final pb = <String, dynamic>{};
      for (final k in e.value.keys.toList()) {
        final c = e.value[k]!;
        if (!match(c)) continue;
        final n = Map<String, dynamic>.from(c);
        change(n);
        e.value[k] = n;
        pb[k] = n;
      }
      if (pb.isNotEmpty) {
        await Api.fbPatch('${Cfg.fbPublic}/${e.key}', pb);
        await _bumpPublic(e.key);
      }
    }
    return body;
  }

  Json _seedBody(String section, Map<String, Json> m, bool seeded) {
    if (!seeded) return {};
    return {
      for (final e in m.entries) '$section/${e.key}': e.value,
      '_empty/$section': m.isEmpty,
    };
  }

  // ======================= الأقسام =======================
  List<Json> get categoryList => ordered(categories);
  List<String> get categoryKeys => _sortedKeys(categories);

  List<String> tintOf(Json c) {
    final t = c['tint'];
    if (t is List && t.length == 2) return [str(t[0]), str(t[1])];
    final cat = AppState.I.catByKey(str(c['key']));
    if (cat != null) return [cat.tintSoft, cat.tintAccent];
    return const ['#EEF2F8', '#64748B'];
  }

  int countAll(String key) => allCards.where((c) => str(c['key']) == key).length;

  Future<String?> addCategory(String name, String key, String one) => _run(() async {
        final n = clip(name, 80);
        final k = clip(key.trim().isEmpty ? n : key.trim(), 80);
        if (n.isEmpty) throw const AdminError('الاسم مطلوب');
        if (!_validKey(k)) throw const AdminError('المفتاح يجب ألا يحتوي الرموز . \$ # [ ] /');
        if (categories.values.any((c) => str(c['key']) == k)) throw const AdminError('المفتاح مستخدم مسبقاً');
        final i = categories.length;
        final id = 'c${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}${randomHex(2)}';
        final c = <String, dynamic>{
          'id': id,
          'name': n,
          'key': k,
          'one': clip(one.trim().isEmpty ? n : one.trim(), 80),
          'icon': kIconChoices[i % kIconChoices.length],
          'tint': List<String>.from(kCatPalette[i % kCatPalette.length]),
          'desc': '',
          'img': kCatNoImage,
          'hier': false,
        };
        await _patchCore({
          ..._seedBody('categories', categories, catsSeeded),
          'categories/$id': c,
          '_empty/categories': false,
          'stats/$k': '0',
        }, log: 'إضافة قسم: $n', icon: 'fa-solid fa-plus');
        catsSeeded = false;
        categories[id] = c;
        stats[k] = '0';
      });

  Future<String?> updateCategory(String id, Json changes, {String? log, String icon = 'fa-solid fa-layer-group'}) =>
      _run(() async {
        final cur = categories[id];
        if (cur == null) throw const AdminError('القسم غير موجود');
        final c = Map<String, dynamic>.from(cur)..addAll(changes);
        await _patchCore({
          ..._seedBody('categories', categories, catsSeeded),
          'categories/$id': c,
        }, log: log ?? 'تعديل قسم: ${str(c['name'])}', icon: icon);
        catsSeeded = false;
        categories[id] = c;
      });

  Future<String?> updateCategoryTint(String id, int idx, String color) {
    final cur = categories[id];
    if (cur == null) return Future.value('القسم غير موجود');
    final t = List<String>.from(tintOf(cur));
    t[idx] = color;
    return updateCategory(id, {'tint': t}, log: 'تعديل ألوان قسم: ${str(cur['name'])}');
  }

  Future<String?> renameCategoryKey(String id, String newKey) => _run(() async {
        final c0 = categories[id];
        if (c0 == null) throw const AdminError('القسم غير موجود');
        final old = str(c0['key']);
        final nk = clip(newKey.trim(), 80);
        if (nk.isEmpty) throw const AdminError('المفتاح مطلوب');
        if (old == nk) return;
        if (!_validKey(nk)) throw const AdminError('المفتاح يجب ألا يحتوي الرموز . \$ # [ ] /');
        if (categories.entries.any((e) => e.key != id && str(e.value['key']) == nk)) {
          throw const AdminError('هذا المفتاح مستخدم في قسم آخر');
        }
        if (Cfg.publicSections.containsKey(old) || Cfg.publicSections.containsKey(nk)) {
          throw const AdminError('لا يمكن تغيير مفتاح المدارس أو المعاهد لأنه مرتبط بقسم بيانات مستقل');
        }
        final c = Map<String, dynamic>.from(c0)..['key'] = nk;
        final body = await _rewriteCards((x) => str(x['key']) == old, (x) => x['key'] = nk);
        body.addAll(_seedBody('categories', categories, catsSeeded));
        body['categories/$id'] = c;
        final hadStat = stats.containsKey(old);
        if (hadStat) {
          body['stats/$old'] = null;
          body['stats/$nk'] = stats[old];
        }
        await _patchCore(body, log: 'تغيير مفتاح قسم: $old ← $nk', icon: 'fa-solid fa-layer-group');
        catsSeeded = false;
        categories[id] = c;
        if (hadStat) stats[nk] = stats.remove(old);
      });

  Future<String?> deleteCategory(String id) => _run(() async {
        if (categories.length <= 1) throw const AdminError('لا يمكن حذف آخر قسم');
        final c = categories[id];
        if (c == null) return;
        final key = str(c['key']);
        final body = <String, dynamic>{..._seedBody('categories', categories, catsSeeded)};
        for (final k in coreCards.keys.toList()) {
          if (str(coreCards[k]!['key']) == key) {
            body['cards/$k'] = null;
            coreCards.remove(k);
          }
        }
        final code = pubCode(key);
        if (code != null && (pubReady[code] ?? false) && (pubCards[code]?.isNotEmpty ?? false)) {
          await Api.fbDelete('${Cfg.fbPublic}/$code');
          pubCards[code]!.clear();
          await _bumpPublic(code);
        }
        body['categories/$id'] = null;
        body['stats/$key'] = null;
        body['_empty/cards'] = coreCards.isEmpty;
        await _patchCore(body, log: 'حذف قسم: ${str(c['name'])}', icon: 'fa-regular fa-trash-can');
        catsSeeded = false;
        categories.remove(id);
        stats.remove(key);
        _refreshVisitor(key);
      });

  /// تبديل محتوى عنصرين مع إبقاء المعرّفات في مكانها — فيثبت الترتيب في الويب والتطبيق (كلاهما يرتّب بالمعرّف)
  Future<void> _swap(String section, Map<String, Json> m, String k1, String k2, Json seed,
      {required String log, required String icon, void Function(Json a)? touch, Json extra = const {}}) async {
    final a = m[k1]!;
    final b = m[k2]!;
    final na = Map<String, dynamic>.from(b)..['id'] = a['id'];
    final nb = Map<String, dynamic>.from(a)..['id'] = b['id'];
    touch?.call(na);
    touch?.call(nb);
    await _patchCore({...seed, ...extra, '$section/$k1': na, '$section/$k2': nb}, log: log, icon: icon);
    m[k1] = na;
    m[k2] = nb;
  }

  Future<String?> moveCategory(int i, int dir) => _run(() async {
        final keys = categoryKeys;
        final j = i + dir;
        if (j < 0 || j >= keys.length) return;
        await _swap('categories', categories, keys[i], keys[j], _seedBody('categories', categories, catsSeeded),
            log: 'إعادة ترتيب الأقسام', icon: 'fa-solid fa-layer-group');
        catsSeeded = false;
      });

  // ======================= المحافظات والمراكز =======================
  List<Json> get geoList => ordered(geo);
  List<String> get geoKeys => _sortedKeys(geo);

  List<Json> districtsOf(Json g) => [
        for (final d in (g['districts'] is List ? g['districts'] as List : const []))
          if (d is Map) Map<String, dynamic>.from(d),
      ];

  Json? govByName(String n) {
    for (final g in geo.values) {
      if (str(g['name']) == n) return g;
    }
    return null;
  }

  int govCardCount(String name) => allCards.where((c) => str(c['gov']) == name).length;

  int distCardCount(String gov, String d) =>
      allCards.where((c) => str(c['gov']) == gov && str(c['dist']) == d).length;

  Future<void> _saveGov(String id, Json? g, {required String log, String icon = 'fa-solid fa-pen', Json extra = const {}}) async {
    final rest = Map<String, Json>.from(geo);
    if (g == null) {
      rest.remove(id);
    } else {
      rest[id] = g;
    }
    await _patchCore({
      ..._seedBody('geo', geo, geoSeeded),
      ...extra,
      'geo/$id': g,
      '_empty/geo': rest.isEmpty,
    }, log: log, icon: icon);
    geoSeeded = false;
    if (g == null) {
      geo.remove(id);
    } else {
      geo[id] = g;
    }
  }

  Future<String?> addGov(String name) => _run(() async {
        final n = clip(name.trim(), 100);
        if (n.isEmpty) throw const AdminError('الاسم مطلوب');
        if (govByName(n) != null) throw const AdminError('المحافظة موجودة مسبقاً');
        final id = 'g${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}';
        await _saveGov(id, {'id': id, 'name': n, 'districts': <Json>[]},
            log: 'إضافة محافظة: $n', icon: 'fa-solid fa-plus');
      });

  Future<String?> renameGov(String id, String name) => _run(() async {
        final g = geo[id];
        if (g == null) return;
        final n = clip(name.trim(), 100);
        if (n.isEmpty) throw const AdminError('الاسم مطلوب');
        final old = str(g['name']);
        if (n == old) return;
        if (govByName(n) != null) throw const AdminError('الاسم مستخدم');
        final extra = await _rewriteCards((c) => str(c['gov']) == old, (c) => c['gov'] = n);
        await _saveGov(id, Map<String, dynamic>.from(g)..['name'] = n,
            log: 'تعديل محافظة: $old ← $n', extra: extra);
      });

  Future<String?> deleteGov(String id) => _run(() async {
        final g = geo[id];
        if (g == null) return;
        await _saveGov(id, null, log: 'حذف محافظة: ${str(g['name'])}', icon: 'fa-regular fa-trash-can');
      });

  Future<String?> _setDists(String id, List<Json> dists, {required String log, String icon = 'fa-solid fa-pen', Json extra = const {}}) =>
      _run(() async {
        final g = geo[id];
        if (g == null) return;
        await _saveGov(id, Map<String, dynamic>.from(g)..['districts'] = dists, log: log, icon: icon, extra: extra);
      });

  Future<String?> addDist(String id, String name) {
    final g = geo[id];
    if (g == null) return Future.value(null);
    final n = clip(name.trim(), 100);
    if (n.isEmpty) return Future.value('الاسم مطلوب');
    final ds = districtsOf(g);
    if (ds.any((d) => str(d['name']) == n)) return Future.value('المركز موجود مسبقاً');
    ds.add({'id': 'd${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}', 'name': n});
    return _setDists(id, ds, log: 'إضافة مركز: $n / ${str(g['name'])}', icon: 'fa-solid fa-plus');
  }

  /// إضافة دفعة مراكز (سطر أو فاصلة لكل مركز). يعيد (الخطأ، عدد المضاف، عدد المكرر)
  Future<(String?, int, int)> addDistBulk(String id, String raw) async {
    final g = geo[id];
    if (g == null) return (null, 0, 0);
    final names = raw.split(RegExp(r'[\n\r,،;؛|]+')).map((x) => x.trim()).where((x) => x.isNotEmpty).toList();
    if (names.isEmpty) return ('لم تُدخل أي اسم', 0, 0);
    final ds = districtsOf(g);
    final seen = {for (final d in ds) str(d['name'])};
    var added = 0, dup = 0;
    for (final name in names) {
      final nm = clip(name, 100);
      if (nm.isEmpty) continue;
      if (seen.contains(nm)) {
        dup++;
        continue;
      }
      seen.add(nm);
      ds.add({'id': 'd${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}${randomHex(2)}', 'name': nm});
      added++;
    }
    if (added == 0) return ('كل الأسماء موجودة مسبقاً', 0, dup);
    final e = await _setDists(id, ds, log: 'إضافة $added مركز إلى ${str(g['name'])}', icon: 'fa-solid fa-plus');
    return (e, added, dup);
  }

  Future<String?> renameDist(String id, int j, String name) async {
    final g = geo[id];
    if (g == null) return null;
    final ds = districtsOf(g);
    if (j < 0 || j >= ds.length) return null;
    final n = clip(name.trim(), 100);
    if (n.isEmpty) return 'الاسم مطلوب';
    final old = str(ds[j]['name']);
    if (n == old) return null;
    if (ds.any((d) => str(d['name']) == n)) return 'الاسم مستخدم';
    ds[j] = Map<String, dynamic>.from(ds[j])..['name'] = n;
    final gName = str(g['name']);
    if (legacyFormat) return AdminStore._legacyMsg;
    Json extra;
    try {
      extra = await _rewriteCards(
          (c) => str(c['gov']) == gName && str(c['dist']) == old, (c) => c['dist'] = n);
    } catch (_) {
      return AdminStore._netMsg;
    }
    return _setDists(id, ds, log: 'تعديل مركز: $old ← $n', extra: extra);
  }

  Future<String?> deleteDist(String id, int j) {
    final g = geo[id];
    if (g == null) return Future.value(null);
    final ds = districtsOf(g);
    if (j < 0 || j >= ds.length) return Future.value(null);
    final d = ds.removeAt(j);
    return _setDists(id, ds, log: 'حذف مركز: ${str(d['name'])}', icon: 'fa-regular fa-trash-can');
  }

  Future<String?> moveDist(String id, int j, int dir) {
    final g = geo[id];
    if (g == null) return Future.value(null);
    final ds = districtsOf(g);
    final k = j + dir;
    if (j < 0 || k < 0 || j >= ds.length || k >= ds.length) return Future.value(null);
    final t = ds[j];
    ds[j] = ds[k];
    ds[k] = t;
    return _setDists(id, ds, log: 'ترتيب مراكز: ${str(g['name'])}', icon: 'fa-solid fa-arrows-up-down');
  }

  Future<String?> sortDists(String id) {
    final g = geo[id];
    if (g == null) return Future.value(null);
    final ds = districtsOf(g)..sort((a, b) => str(a['name']).compareTo(str(b['name'])));
    return _setDists(id, ds, log: 'ترتيب مراكز: ${str(g['name'])}', icon: 'fa-solid fa-arrow-down-a-z');
  }

  Future<String?> clearDists(String id) {
    final g = geo[id];
    if (g == null) return Future.value(null);
    final n = districtsOf(g).length;
    return _setDists(id, <Json>[], log: 'حذف $n مركز من ${str(g['name'])}', icon: 'fa-regular fa-trash-can');
  }

  // ======================= اللوحات الإعلانية ورسالة الترحيب =======================
  List<Json> get adList => ordered(ads);
  List<String> get adKeys => _sortedKeys(ads);

  bool adHasInfo(Json a) =>
      const ['loc', 'map', 'desc', 'hours', 'phone', 'wa', 'tg', 'fb', 'ig', 'tt'].any((k) => str(a[k]).trim().isNotEmpty);

  void _touchAd(Json a, int now) {
    a['version'] = now;
    a['updatedAt'] = DateTime.fromMillisecondsSinceEpoch(now).toUtc().toIso8601String();
  }

  Future<(int, int)> _imageSize(Uint8List b) async {
    try {
      final codec = await ui.instantiateImageCodec(b);
      final f = await codec.getNextFrame();
      final r = (f.image.width, f.image.height);
      f.image.dispose();
      codec.dispose();
      return r;
    } catch (_) {
      return (0, 0);
    }
  }

  /// يرفع صورة الإعلان (مع إعادة استخدام نفس الصورة إن رُفعت سابقاً) — نفس pickAdImage
  Future<(String, Json)> _uploadAdImage(Uint8List bytes, String fileName) async {
    if (bytes.length > 1300 * 1024) throw const AdminError('الصورة كبيرة بعد الضغط — اختر صورة أصغر');
    final (w, h) = await _imageSize(bytes);
    final hash = sha256.convert(bytes).toString();
    final kb = (bytes.length / 1024).round();
    final meta = <String, dynamic>{'width': w, 'height': h, 'kb': kb, 'hash': hash};
    final idx = await loadMediaIndex(force: true);
    for (final e in idx.entries) {
      if (str(e.value['h']) == hash && str(e.value['u']).isNotEmpty) return (str(e.value['u']), meta);
    }
    final id = 'adimg${hash.substring(0, 16)}';
    final (url, path) = await supaUpload(bytes, id, folder: 'ads', suffix: hash.substring(0, 24));
    if (!await supaPublicReady(url)) {
      await supaDeletePath(path);
      throw const AdminError('الصورة مرفوعة لكن الحاوية ليست عامة');
    }
    final rec = <String, dynamic>{
      'u': url, 'p': path, 'kb': kb, 'at': nowIso(), 'n': clip(fileName, 80),
      'h': hash, 'w': w, 'ht': h, 'kind': 'ad',
    };
    await Api.fbPut('${Cfg.fbRoot}/mediaIndex/$id', rec);
    mediaIndex?[id] = rec;
    return (url, meta);
  }

  /// إضافة لوحة إعلانية. يعيد (الخطأ، معرّف اللوحة الجديدة)
  Future<(String?, String)> addAd(Uint8List bytes, String fileName) async {
    if (legacyFormat) return (AdminStore._legacyMsg, '');
    try {
      final (url, meta) = await _uploadAdImage(bytes, fileName);
      final now = DateTime.now().millisecondsSinceEpoch;
      final id = 'ad${randomHex(8)}';
      final ad = <String, dynamic>{
        'id': id, 'title': '', 'img': url, 'link': '', 'loc': '', 'map': '', 'desc': '', 'hours': '',
        'phone': '', 'wa': '', 'tg': '', 'fb': '', 'ig': '', 'tt': '', 'active': true, 'at': nowIso(),
        ...meta,
      };
      _touchAd(ad, now);
      await _patchCore({'ads/$id': ad, '_empty/ads': false, 'settings/adsVersion': now},
          log: 'إضافة لوحة إعلانية', icon: 'fa-solid fa-rectangle-ad');
      ads[id] = ad;
      settings['adsVersion'] = now;
      changed();
      return (null, id);
    } on AdminError catch (e) {
      return (e.message, '');
    } catch (_) {
      return ('تعذّر تجهيز صورة الإعلان', '');
    }
  }

  Future<String?> _saveAd(String id, Json? ad, {required String log, String icon = 'fa-solid fa-rectangle-ad'}) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (ad != null) _touchAd(ad, now);
    final rest = Map<String, Json>.from(ads);
    if (ad == null) {
      rest.remove(id);
    } else {
      rest[id] = ad;
    }
    await _patchCore({'ads/$id': ad, '_empty/ads': rest.isEmpty, 'settings/adsVersion': now}, log: log, icon: icon);
    if (ad == null) {
      ads.remove(id);
    } else {
      ads[id] = ad;
    }
    settings['adsVersion'] = now;
    return null;
  }

  Future<String?> toggleAd(String id) => _run(() async {
        final a = ads[id];
        if (a == null) return;
        await _saveAd(id, Map<String, dynamic>.from(a)..['active'] = a['active'] == false,
            log: 'تغيير حالة لوحة إعلانية');
      });

  Future<String?> deleteAd(String id) => _run(() async {
        final a = ads[id];
        if (a == null) return;
        final old = str(a['img']);
        await _saveAd(id, null, log: 'حذف لوحة إعلانية', icon: 'fa-regular fa-trash-can');
        unawaited(cleanupUnusedMediaRef(old));
      });

  Future<String?> moveAd(int i, int dir) => _run(() async {
        final keys = _sortedKeys(ads);
        final j = i + dir;
        if (j < 0 || j >= keys.length) return;
        final now = DateTime.now().millisecondsSinceEpoch;
        await _swap('ads', ads, keys[i], keys[j], {},
            log: 'ترتيب اللوحات الإعلانية',
            icon: 'fa-solid fa-arrows-up-down',
            touch: (a) => _touchAd(a, now),
            extra: {'settings/adsVersion': now});
        settings['adsVersion'] = now;
      });

  Future<String?> saveAdInfo(String id, Map<String, String> f) => _run(() async {
        final a = ads[id];
        if (a == null) return;
        final link = (f['link'] ?? '').trim();
        final map = (f['map'] ?? '').trim();
        final https = RegExp(r'^https?://', caseSensitive: false);
        if (link.isNotEmpty && !https.hasMatch(link)) throw const AdminError('الرابط يجب أن يبدأ بـ https://');
        if (map.isNotEmpty && !https.hasMatch(map)) throw const AdminError('رابط الموقع يجب أن يبدأ بـ https://');
        String v(String k, int n) => clip(f[k] ?? '', n);
        final n = Map<String, dynamic>.from(a)
          ..['title'] = v('title', 150)
          ..['loc'] = v('loc', 300)
          ..['map'] = clip(map, 600)
          ..['desc'] = v('desc', 2000)
          ..['hours'] = v('hours', 300)
          ..['phone'] = v('phone', 60)
          ..['wa'] = v('wa', 120)
          ..['tg'] = v('tg', 120)
          ..['fb'] = v('fb', 200)
          ..['ig'] = v('ig', 200)
          ..['tt'] = v('tt', 200)
          ..['link'] = clip(link, 600);
        await _saveAd(id, n, log: 'تعديل معلومات لوحة إعلانية');
      });

  Future<String?> replaceAdImage(String id, Uint8List bytes, String fileName) => _run(() async {
        final a = ads[id];
        if (a == null) return;
        final old = str(a['img']);
        final (url, meta) = await _uploadAdImage(bytes, fileName);
        final n = Map<String, dynamic>.from(a)
          ..['img'] = url
          ..addAll(meta);
        await _saveAd(id, n, log: 'تغيير صورة لوحة إعلانية', icon: 'fa-regular fa-image');
        if (old.isNotEmpty && old != url) unawaited(cleanupUnusedMediaRef(old));
      });

  Future<String?> setAdsOn(bool on) => _run(() async {
        final now = DateTime.now().millisecondsSinceEpoch;
        await _patchCore({'settings/adsOn': on, 'settings/adsVersion': now},
            log: 'تغيير حالة اللوحات الإعلانية', icon: 'fa-solid fa-rectangle-ad');
        settings['adsOn'] = on;
        settings['adsVersion'] = now;
      });

  Future<String?> setAdsDelay(int v) => _run(() async {
        final d = v.clamp(2, 60);
        await _patchCore({'settings/adsDelay': d}, log: 'تعديل مدة عرض اللوحات', icon: 'fa-regular fa-clock');
        settings['adsDelay'] = d;
      });

  Future<String?> saveWelcome(bool on, String title) => _run(() async {
        final t = clip(title, 180);
        await _patchCore({'settings/welcomeOn': on, 'settings/welcomeTitle': t},
            log: 'تعديل رسالة الترحيب', icon: 'fa-solid fa-hand-sparkles');
        settings['welcomeOn'] = on;
        settings['welcomeTitle'] = t;
      });

  // ======================= الإحصائيات ولوحة المعلومات =======================
  bool get autoStats => settings['autoStats'] == true;

  /// عدد العناصر المنشورة في كل قسم — نفس computedStats
  Map<String, int> computedStats() {
    final o = <String, int>{};
    final pub = allCards.where((c) => str(c['status']) != 'مسودة').toList();
    for (final c in categoryList) {
      final k = str(c['key']);
      o[k] = pub.where((x) => str(x['key']) == k).length;
    }
    return o;
  }

  /// أرقام الواجهة: تلقائية أو يدوية (مع دعم k/m) — نفس dashNumbers
  Map<String, num> dashNumbers() {
    final c = computedStats();
    if (autoStats) return c;
    final o = <String, num>{};
    for (final cat in categoryList) {
      final k = str(cat['key']);
      final raw = str(stats[k] ?? 0).trim().replaceAll(',', '');
      final n = double.tryParse(raw.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
      o[k] = RegExp(r'k', caseSensitive: false).hasMatch(raw)
          ? n * 1000
          : (RegExp(r'm', caseSensitive: false).hasMatch(raw) ? n * 1e6 : n);
    }
    return o;
  }

  Future<String?> setAutoStats(bool on) => _run(() async {
        await _patchCore({'settings/autoStats': on});
        settings['autoStats'] = on;
      });

  Future<String?> saveStats(Map<String, String> values) => _run(() async {
        final body = <String, dynamic>{};
        values.forEach((k, v) {
          if (_validKey(k)) body['stats/$k'] = clip(v, 30);
        });
        await _patchCore(body, log: 'تعديل أرقام الواجهة', icon: 'fa-solid fa-chart-line');
        values.forEach((k, v) => stats[k] = clip(v, 30));
      });

  Future<String?> resetCounters() => _run(() async {
        await Api.fbPatch(Cfg.fbMetrics, {'visits': 0, 'newUsers': 0, 'searches': 0});
        metrics = {'visits': 0, 'newUsers': 0, 'searches': 0};
        await _patchCore({}, log: 'تصفير العدادات', icon: 'fa-solid fa-gauge');
      });

  /// بيانات المخطط الشهري — نفس chartSeries (العناصر أو الطلبات)
  (List<String>, List<int>) chartSeries(int months, bool requestsMetric) {
    final now = DateTime.now();
    final labels = <String>[];
    final vals = <int>[];
    for (var m = months - 1; m >= 0; m--) {
      final d = DateTime(now.year, now.month - m, 1);
      final key = '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}';
      labels.add(kArMonths[d.month - 1]);
      vals.add(requestsMetric
          ? requests.values.where((r) => str(r['at']).startsWith(key)).length
          : allCards.where((c) => str(c['created']).startsWith(key)).length);
    }
    return (labels, vals);
  }

  /// أرقام النظرة العامة — نفس renderOverview
  List<(String, num)> overview() => [
        ('الزيارات', intOf(metrics['visits'])),
        (
          'المستخدمون الجدد',
          requests.values.where((r) => str(r['type']) == 'اشتراك').length + intOf(metrics['newUsers'])
        ),
        ('عمليات البحث', intOf(metrics['searches'])),
        ('التواصلات', requests.length),
      ];

  // ======================= المستخدمون =======================
  List<Json> get userList => ordered(users);

  Future<String?> addUser(String name, String pass, String role) => _run(() async {
        final n = clip(name.trim(), 50);
        if (!RegExp(r'^[\p{L}\p{N}_.-]{3,50}$', unicode: true).hasMatch(n)) {
          throw const AdminError('اسم المستخدم يجب أن يكون 3–50 حرفاً بدون مسافات أو رموز غريبة');
        }
        if (users.values.any((u) => str(u['user']).toLowerCase() == n.toLowerCase())) {
          throw const AdminError('الاسم مستخدم مسبقاً');
        }
        if (!validPassword(pass)) {
          throw const AdminError('كلمة المرور يجب أن تكون 10 أحرف على الأقل وتحتوي حروفاً وأرقاماً');
        }
        final id = uid();
        final key = safeKey(id).isEmpty ? 'u${randomHex(4)}' : safeKey(id);
        final rec = <String, dynamic>{
          'id': id,
          'user': n,
          'pass': await makePasswordRecord(pass),
          'role': clip(role.trim().isEmpty ? 'مشرف' : role.trim(), 50),
          'created': todayIso(),
        };
        await _patchCore({..._seedBody('users', users, usersSeeded), 'users/$key': rec},
            log: 'إضافة مستخدم: $n', icon: 'fa-solid fa-user-plus');
        usersSeeded = false;
        users[key] = rec;
      });

  Future<String?> deleteUser(String key) => _run(() async {
        final u = users[key];
        if (u == null) return;
        if (users.length == 1) throw const AdminError('لا يمكن حذف آخر حساب إداري');
        if (str(u['user']) == currentUser) throw const AdminError('لا يمكنك حذف حسابك الحالي');
        await _patchCore({..._seedBody('users', users, usersSeeded), 'users/$key': null},
            log: 'حذف مستخدم: ${str(u['user'])}', icon: 'fa-solid fa-user-minus');
        usersSeeded = false;
        users.remove(key);
      });

  Future<String?> changeUserPassword(String key, String pass) => _run(() async {
        final u = users[key];
        if (u == null) return;
        if (!validPassword(pass)) {
          throw const AdminError('كلمة المرور يجب أن تكون 10 أحرف على الأقل وتحتوي حروفاً وأرقاماً');
        }
        final n = Map<String, dynamic>.from(u)..['pass'] = await makePasswordRecord(pass);
        await _patchCore({..._seedBody('users', users, usersSeeded), 'users/$key': n},
            log: 'تغيير كلمة مرور: ${str(u['user'])}', icon: 'fa-solid fa-key');
        usersSeeded = false;
        users[key] = n;
      });

  // ======================= سجل النشاطات والطلبات =======================
  Future<String?> clearLog() => _run(() async {
        await _patchCore({'activity': null, '_empty/activity': true});
        activity.clear();
      });

  Future<String?> clearRequests() => _run(() async {
        await _patchCore({'requests': null, '_empty/requests': true});
        requests.clear();
      });

  // ======================= مكتبة الوسائط =======================
  Future<Map<String, Json>> loadMediaIndex({bool force = false}) async {
    if (mediaIndex != null && !force) return mediaIndex!;
    try {
      mediaIndex = _asMap(await Api.fbGet('${Cfg.fbRoot}/mediaIndex'));
    } catch (_) {
      mediaIndex ??= <String, Json>{};
    }
    changed();
    return mediaIndex!;
  }

  List<MapEntry<String, Json>> get mediaList {
    final l = (mediaIndex ?? const <String, Json>{}).entries.toList();
    l.sort((a, b) => str(b.value['at']).compareTo(str(a.value['at'])));
    return l;
  }

  /// عدد الصور القديمة المخزّنة داخل فايربيس (base64)
  Future<int> legacyMediaCount() async {
    try {
      final r = await http
          .get(Uri.parse('${Cfg.fbMedia}.json?shallow=true'))
          .timeout(const Duration(seconds: 20));
      final v = jsonDecode(r.body);
      return v is Map ? v.length : 0;
    } catch (_) {
      return 0;
    }
  }

  bool mediaUsed(String ref) {
    if (ref.isEmpty) return false;
    for (final k in kBgKeys) {
      if (str(settings[k[0]]) == ref) return true;
    }
    if (allCards.any((c) => cardImages(c).contains(ref))) return true;
    if (categories.values.any((c) => str(c['img']) == ref)) return true;
    return ads.values.any((a) => str(a['img']) == ref);
  }

  Future<bool> cleanupUnusedMediaRef(String ref) async {
    if (ref.isEmpty || mediaUsed(ref)) return false;
    final idx = await loadMediaIndex();
    MapEntry<String, Json>? rec;
    for (final e in idx.entries) {
      if (str(e.value['u']) == ref) rec = e;
    }
    try {
      final path = rec != null
          ? (str(rec.value['p']).isNotEmpty ? str(rec.value['p']) : supaPathFromUrl(str(rec.value['u'])))
          : supaPathFromUrl(ref);
      if (path.isEmpty) return false;
      await supaDeletePath(path);
      if (rec != null) {
        await Api.fbDelete('${Cfg.fbRoot}/mediaIndex/${rec.key}');
        mediaIndex?.remove(rec.key);
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<String?> deleteMedia(String id) async {
    final it = mediaIndex?[id];
    if (it == null) return null;
    try {
      final p = str(it['p']).isNotEmpty ? str(it['p']) : supaPathFromUrl(str(it['u']));
      await supaDeletePath(p);
      await Api.fbDelete('${Cfg.fbRoot}/mediaIndex/$id');
      mediaIndex?.remove(id);
      changed();
      return null;
    } catch (_) {
      return 'تعذّر حذف الصورة';
    }
  }

  /// تعيين صورة كخلفية أو شعار — نفس useAsBg / uploadTo
  Future<String?> setSettingImage(String key, String ref) => saveSettings({key: ref}, log: '');

  // ======================= قواعد البيانات =======================
  Future<bool> testFirebase() async {
    try {
      await Api.fbGet('${Cfg.fbCore}/_rev');
      return true;
    } catch (_) {
      return false;
    }
  }

  Json _coreSnapshot() {
    final snap = <String, dynamic>{
      'version': rawVersion['version'],
      '_fmt': 'map2',
      'settings': settings,
      'stats': stats,
      'cards': coreCards,
      'categories': categories,
      'geo': geo,
      'users': users,
      'requests': requests,
      'notifications': notifications,
      'activity': activity,
      'ads': ads,
    };
    snap['_empty'] = {for (final k in _emptyFlagKeys) k: (snap[k] as Map).isEmpty};
    snap['_by'] = _client;
    snap['_rev'] = DateTime.now().millisecondsSinceEpoch;
    return snap;
  }

  /// رفع كامل لبيانات core الحالية (يرحّل الصيغة القديمة إلى map2) — نفس forcePush
  Future<String?> fullPush() async {
    try {
      final snap = _coreSnapshot();
      await Api.fbPut(Cfg.fbCore, snap);
      legacyFormat = false;
      catsSeeded = false;
      geoSeeded = false;
      usersSeeded = false;
      lastRev = intOf(snap['_rev']);
      unawaited(AppState.I.checkRemote());
      changed();
      return null;
    } catch (_) {
      return AdminStore._netMsg;
    }
  }

  /// مسح البيانات السحابية (core و public و publicVersion والصور القديمة) — نفس wipeCloud
  Future<String?> wipeCloud({bool keepMedia = false}) async {
    try {
      await Api.fbDelete(Cfg.fbCore);
      await Api.fbDelete(Cfg.fbPublic);
      await Api.fbDelete(Cfg.fbPublicVersion);
      if (!keepMedia) await Api.fbDelete(Cfg.fbMedia);
      await load();
      unawaited(AppState.I.checkRemote());
      return null;
    } catch (_) {
      return 'تعذّر المسح';
    }
  }

  Future<String?> saveSupaSettings(String url, String bucket) {
    final u = url.trim();
    if (u.isNotEmpty && !RegExp(r'^https://[A-Za-z0-9.-]+\.supabase\.(co|in)/?$', caseSensitive: false).hasMatch(u)) {
      return Future.value('الرابط غير صحيح — يجب أن ينتهي بـ supabase.co');
    }
    final b = bucket.trim().isEmpty ? Cfg.supaBucketDefault : bucket.trim();
    return saveSettings(
      {'supaUrl': u.replaceFirst(RegExp(r'/+$'), ''), 'supaBucket': b},
      log: 'تعديل إعدادات التخزين',
    );
  }

  /// اختبار الرفع والقراءة العامة والحذف — نفس testSupabase
  Future<String> testSupabase() async {
    try {
      final (url, path) = await supaUpload(_testGif, 'healthcheck', contentType: 'image/gif');
      if (!await supaPublicReady(url)) {
        await supaDeletePath(path);
        return 'الحاوية $supaBucket ليست Public — فعّل Public لظهور الصور للزوار';
      }
      await supaDeletePath(path);
      return 'OK';
    } catch (_) {
      return 'فشل الاختبار: تحقّق من اسم الحاوية وسياسات RLS';
    }
  }

  /// استبدال مرجع صورة في كل مكان (الإعدادات، العناصر، الأقسام، الإعلانات)
  Future<void> _replaceRef(String oldRef, String newRef) async {
    final body = await _rewriteCards((c) => cardImages(c).contains(oldRef), (c) {
      final imgs = cardImages(c).map((r) => r == oldRef ? newRef : r).toList();
      c['images'] = imgs;
      if (imgs.isNotEmpty) c['img'] = imgs.first;
    });
    for (final k in kBgKeys) {
      if (str(settings[k[0]]) == oldRef) {
        settings[k[0]] = newRef;
        body['settings/${k[0]}'] = newRef;
      }
    }
    for (final e in categories.entries) {
      if (str(e.value['img']) == oldRef) {
        e.value['img'] = newRef;
        body['categories/${e.key}'] = e.value;
      }
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    for (final e in ads.entries) {
      if (str(e.value['img']) == oldRef) {
        e.value['img'] = newRef;
        _touchAd(e.value, now);
        body['ads/${e.key}'] = e.value;
        body['settings/adsVersion'] = now;
      }
    }
    if (body.isNotEmpty) await _patchCore(body);
  }

  /// ترحيل صور base64 القديمة من فايربيس إلى Supabase — نفس migrateMediaToSupabase. يعيد (المنجز، المتعذّر)
  Future<(int, int)> migrateLegacyMedia() async {
    var done = 0, fail = 0;
    Map<String, dynamic> all = {};
    final v = await Api.fbGet(Cfg.fbMedia);
    if (v is Map) all = Map<String, dynamic>.from(v);
    await loadMediaIndex();
    Future<String?> up(String val, String id) async {
      final bytes = AppState.decodeDataUrl(val);
      if (bytes == null) return null;
      final (url, path) = await supaUpload(bytes, id);
      final rec = <String, dynamic>{
        'u': url, 'p': path, 'kb': (val.length * 0.75 / 1024).round(), 'at': nowIso(), 'n': id,
      };
      await Api.fbPut('${Cfg.fbRoot}/mediaIndex/$id', rec);
      mediaIndex?[id] = rec;
      return url;
    }

    for (final e in all.entries) {
      final val = str(e.value);
      if (!val.startsWith('data:image/')) {
        fail++;
        continue;
      }
      try {
        final url = await up(val, e.key);
        if (url == null) {
          fail++;
          continue;
        }
        await _replaceRef('media:${e.key}', url);
        await Api.fbDelete('${Cfg.fbMedia}/${e.key}');
        done++;
      } catch (_) {
        fail++;
      }
    }
    // صور مضمّنة مباشرة داخل الحقول بصيغة base64
    final inline = <String>{};
    for (final k in kBgKeys) {
      if (str(settings[k[0]]).startsWith('data:image/')) inline.add(str(settings[k[0]]));
    }
    for (final c in allCards) {
      for (final r in cardImages(c)) {
        if (r.startsWith('data:image/')) inline.add(r);
      }
    }
    for (final c in [...categories.values, ...ads.values]) {
      if (str(c['img']).startsWith('data:image/')) inline.add(str(c['img']));
    }
    for (final val in inline) {
      try {
        final id = 'm${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}${randomHex(2)}';
        final url = await up(val, id);
        if (url == null) {
          fail++;
          continue;
        }
        await _replaceRef(val, url);
        done++;
      } catch (_) {
        fail++;
      }
    }
    changed();
    return (done, fail);
  }

  // ======================= النسخ الاحتياطي =======================
  Json exportObject() => {
        'settings': settings,
        'stats': stats,
        'cards': allCards,
        'categories': categoryList,
        'geo': geoList,
        'users': userList,
        'requests': requestList,
        'notifications': notificationList,
        'activity': activityList,
        'ads': adList,
        'metrics': metrics,
      };

  Future<void> _shareFile(String name, String content, String mime) async {
    final dir = await getTemporaryDirectory();
    final f = File('${dir.path}/$name');
    await f.writeAsString(content, flush: true);
    await Share.shareXFiles([XFile(f.path, mimeType: mime, name: name)], subject: name);
  }

  Future<String?> exportJson() async {
    try {
      await _shareFile('knowledge-platform-${todayIso()}.json',
          const JsonEncoder.withIndent('  ').convert(exportObject()), 'application/json');
      return null;
    } catch (_) {
      return 'تعذّر تصدير النسخة الاحتياطية';
    }
  }

  /// تصدير العناصر بصيغة CSV — نفس exportCSV
  Future<String?> exportCsv() async {
    String safe(dynamic v) {
      var s = v == null ? '' : v.toString();
      if (RegExp(r'^[=+\-@]').hasMatch(s)) s = "'$s";
      return '"${s.replaceAll('"', '""')}"';
    }

    final rows = <List<dynamic>>[
      ['الاسم', 'الفئة', 'المدينة', 'الهاتف', 'التقييم', 'الحالة', 'التاريخ', 'الوصف'],
      for (final c in allCards)
        [c['name'], c['key'], c['city'], c['phone'], c['rating'], c['status'], c['created'], c['desc']],
    ];
    final csv = '﻿${rows.map((r) => r.map(safe).join(',')).join('\n')}';
    try {
      await _shareFile('content-${todayIso()}.csv', csv, 'text/csv');
      return null;
    } catch (_) {
      return 'تعذّر تصدير CSV';
    }
  }

  /// اختيار ملف JSON للاستيراد (حتى 5MB)
  Future<String?> pickImportFile() async {
    final f = await fs.openFile();
    if (f == null) return null;
    if (await f.length() > 5 * 1024 * 1024) throw const AdminError('ملف الاستيراد أكبر من الحد المسموح (5MB)');
    return f.readAsString();
  }

  /// استيراد نسخة احتياطية واستبدال البيانات — نفس importData
  Future<String?> importJson(String text) async {
    if (legacyFormat) return AdminStore._legacyMsg;
    dynamic d;
    try {
      d = jsonDecode(text);
    } catch (_) {
      return 'ملف غير صالح';
    }
    if (d is! Map) return 'بنية الملف غير صالحة';
    try {
      Map<String, Json> sec(String k) => _asMap(d[k]);
      final pub = <String, Map<String, Json>>{for (final code in Cfg.publicSections.values) code: {}};
      final coreC = <String, Json>{};
      sec('cards').forEach((k, c) {
        final code = Cfg.publicSections[str(c['key'])];
        if (code != null && (pubReady[code] ?? false)) {
          pub[code]![k] = c;
        } else {
          coreC[k] = c;
        }
      });
      final core = <String, dynamic>{
        'version': rawVersion['version'],
        '_fmt': 'map2',
        'settings': d['settings'] is Map ? Map<String, dynamic>.from(d['settings'] as Map) : settings,
        'stats': d['stats'] is Map ? Map<String, dynamic>.from(d['stats'] as Map) : stats,
        'cards': coreC,
        for (final k in const ['categories', 'geo', 'requests', 'notifications', 'activity', 'ads']) k: sec(k),
        'users': sec('users').isEmpty ? users : sec('users'),
      };
      core['_empty'] = {for (final k in _emptyFlagKeys) k: (core[k] as Map).isEmpty};
      core['_by'] = _client;
      core['_rev'] = DateTime.now().millisecondsSinceEpoch;
      await Api.fbPut(Cfg.fbCore, core);
      for (final code in pub.keys) {
        if (!(pubReady[code] ?? false)) continue;
        await Api.fbPut('${Cfg.fbPublic}/$code', pub[code]);
        pubCards[code] = pub[code]!;
        await _bumpPublic(code);
      }
      await load();
      await _patchCore({}, log: 'استيراد نسخة احتياطية', icon: 'fa-solid fa-upload');
      for (final cat in Cfg.publicSections.keys) {
        _refreshVisitor(cat);
      }
      changed();
      return null;
    } catch (_) {
      return AdminStore._netMsg;
    }
  }
}
