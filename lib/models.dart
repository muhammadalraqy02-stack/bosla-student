// نماذج البيانات + دوال التطبيع (normalize) المطابقة لنسخة الويب

import 'package:flutter/material.dart';

import 'config.dart';
import 'utils.dart';

const List<String> kAssetKeys = [
  'teachers',
  'universities',
  'institutes',
  'schools',
  'academy',
  'future',
  'leadership',
  'hero',
];

/// صور قديمة (Unsplash) تُستبدل بالنسخة المضمّنة داخل التطبيق
const Map<String, String> kOfflinePhotoIds = {
  '1544717305-2782549b5136': 'asset:teachers',
  '1562774053-701939374585': 'asset:universities',
  '1498243691581-b145c3f54a5a': 'asset:institutes',
  '1509062522246-3755977927d7': 'asset:schools',
  '1524178232363-1fb2b075b655': 'asset:academy',
  '1541339907198-e08756dedf3f': 'asset:future',
  '1580582932707-520aed937b7b': 'asset:leadership',
};

final RegExp _reAsset = RegExp(r'^asset:[A-Za-z0-9_-]{1,40}$');
final RegExp _reMedia = RegExp(r'^media:[A-Za-z0-9_-]{1,100}$');
final RegExp _reHttps = RegExp(r'^https://[A-Za-z0-9.-]+(?::\d+)?(?:[/?#]\S*)?$', caseSensitive: false);
final RegExp _reData = RegExp(r'^data:image/(?:png|jpeg|jpg|webp|gif);base64,', caseSensitive: false);

/// مرجع صورة آمن: asset:xxx أو media:id أو رابط https أو data:image — وإلا نص فارغ
String safeImageRef(dynamic v) {
  final s = str(v).trim();
  if (s.isEmpty) return '';
  for (final id in kOfflinePhotoIds.keys) {
    if (s.contains(id)) return kOfflinePhotoIds[id]!;
  }
  if (s.contains('placehold.co')) return '';
  if (_reAsset.hasMatch(s)) return kAssetKeys.contains(s.substring(6)) ? s : '';
  if (_reMedia.hasMatch(s)) return s;
  if (s.length <= 2048 && _reHttps.hasMatch(s)) return s;
  if (s.length <= 4000000 && _reData.hasMatch(s)) return s;
  return '';
}

List<String> safeImageList(dynamic v, dynamic fallback) {
  final out = <String>[];
  void add(dynamic x) {
    final r = safeImageRef(x);
    if (r.isNotEmpty && !out.contains(r)) out.add(r);
  }

  add(fallback);
  if (v is List) {
    for (final x in v) {
      add(x);
    }
  } else if (v is Map) {
    final keys = v.keys.map((e) => e.toString()).toList()..sort();
    for (final k in keys) {
      add(v[k]);
    }
  }
  return out.length > 20 ? out.sublist(0, 20) : out;
}

/// بيانات فايربيس قد تكون مصفوفة أو خريطة بمفتاح المعرّف — نعيدها دائماً كقائمة خرائط
List<Map<String, dynamic>> pickList(dynamic v) {
  final out = <Map<String, dynamic>>[];
  if (v is List) {
    for (final x in v) {
      if (x is Map) out.add(Map<String, dynamic>.from(x));
    }
  } else if (v is Map) {
    final keys = v.keys.map((e) => e.toString()).toList()..sort();
    for (final k in keys) {
      final x = v[k];
      if (x is Map) out.add(Map<String, dynamic>.from(x));
    }
  }
  return out;
}

String _safeUrl(dynamic v, int max) {
  final s = str(v).trim();
  return isHttp(s) ? clip(s, max) : '';
}

String _safeId(dynamic v, String prefix) {
  final s = safeKey(v);
  if (s.isNotEmpty) return s.length > 80 ? s.substring(0, 80) : s;
  return '$prefix${uid()}';
}

class AppSettings {
  String siteName = 'بوصلة الطالب';
  String siteSub = 'دليلك لأفضل الخيارات التعليمية';
  String heroKicker = 'منصة متكاملة';
  String heroTitleA = 'للكوادر';
  String heroTitleB = 'والمؤسسات التعليمية';
  String heroText =
      'اكتشف أفضل المدرسين، الجامعات، المعاهد والمدارس في مكان واحد، واختر ما يناسب طموحاتك التعليمية.';
  String heroImg = 'asset:hero';
  String footer = '© 2026 بوصلة الطالب';
  String catsTitle = 'اختر القسم الذي يهمك';
  String catsSub = 'تصفح الدليل التعليمي واختر الفئة المناسبة';
  String listTitle = 'أبرز الخيارات التعليمية';
  String listSub = 'ابحث وفلتر حسب القسم الذي يناسبك';
  String theme = 'light';
  String logoImg = '';
  String brandColor = '#10275e';
  String accentColor = '#7C3AED';
  String whatsapp = '';
  bool welcomeOn = true;
  String welcomeTitle = 'اهلا بكم في بوصلة الطالب';
  bool adsOn = true;
  int adsDelay = 5;
  String aboutApp = 'سيتم إضافة معلومات التطبيق قريباً.';
  String developerCompany = 'سيتم إضافة معلومات الشركة المطوّرة قريباً.';
  String supaUrl = Cfg.supaUrlDefault;
  String supaBucket = Cfg.supaBucketDefault;

  AppSettings();

  factory AppSettings.fromJson(dynamic raw) {
    final s = AppSettings();
    if (raw is! Map) return s;
    final Map<dynamic, dynamic> m = raw;
    String pick(String k, String def, int max) {
      final v = clip(m[k], max);
      return v.isEmpty ? def : v;
    }

    s.siteName = pick('siteName', s.siteName, 180);
    if (s.siteName == 'منصة المعرفة') s.siteName = 'بوصلة الطالب';
    s.siteSub = pick('siteSub', s.siteSub, 180);
    s.heroKicker = pick('heroKicker', s.heroKicker, 180);
    s.heroTitleA = pick('heroTitleA', s.heroTitleA, 180);
    s.heroTitleB = pick('heroTitleB', s.heroTitleB, 180);
    s.heroText = pick('heroText', s.heroText, 1000);
    s.footer = pick('footer', s.footer, 180);
    if (s.footer == '© 2026 منصة المعرفة') s.footer = '© 2026 بوصلة الطالب';
    s.catsTitle = pick('catsTitle', s.catsTitle, 180);
    s.catsSub = clip(m['catsSub'] ?? s.catsSub, 180);
    s.listTitle = pick('listTitle', s.listTitle, 180);
    s.listSub = clip(m['listSub'] ?? s.listSub, 180);
    s.theme = str(m['theme']) == 'dark' ? 'dark' : 'light';
    final hero = safeImageRef(m['heroImg']);
    s.heroImg = (hero.isEmpty || hero.contains('photo-1523240795612')) ? 'asset:hero' : hero;
    s.logoImg = safeImageRef(m['logoImg']);
    s.brandColor = RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(str(m['brandColor']))
        ? str(m['brandColor'])
        : '#10275e';
    s.accentColor = RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(str(m['accentColor']))
        ? str(m['accentColor'])
        : '#7C3AED';
    final wa = digitsOnly(str(m['whatsapp']));
    s.whatsapp = wa.length > 15 ? wa.substring(0, 15) : wa;
    s.welcomeOn = m['welcomeOn'] != false;
    s.welcomeTitle = pick('welcomeTitle', s.welcomeTitle, 180);
    s.adsOn = m['adsOn'] != false;
    final delay = intOf(m['adsDelay']);
    s.adsDelay = delay <= 0 ? 5 : delay.clamp(2, 60).toInt();
    s.aboutApp = pick('aboutApp', s.aboutApp, 3000);
    s.developerCompany = pick('developerCompany', s.developerCompany, 3000);
    final su = str(m['supaUrl']).trim().replaceFirst(RegExp(r'/+$'), '');
    s.supaUrl = RegExp(r'^https://[A-Za-z0-9.-]+\.supabase\.(co|in)$', caseSensitive: false)
            .hasMatch(su)
        ? su
        : Cfg.supaUrlDefault;
    final sb = str(m['supaBucket']).trim();
    s.supaBucket = RegExp(r'^[A-Za-z0-9_-]{1,60}$').hasMatch(sb) ? sb : Cfg.supaBucketDefault;
    return s;
  }

  Map<String, dynamic> toJson() => {
        'siteName': siteName,
        'siteSub': siteSub,
        'heroKicker': heroKicker,
        'heroTitleA': heroTitleA,
        'heroTitleB': heroTitleB,
        'heroText': heroText,
        'heroImg': heroImg,
        'footer': footer,
        'catsTitle': catsTitle,
        'catsSub': catsSub,
        'listTitle': listTitle,
        'listSub': listSub,
        'theme': theme,
        'logoImg': logoImg,
        'brandColor': brandColor,
        'accentColor': accentColor,
        'whatsapp': whatsapp,
        'welcomeOn': welcomeOn,
        'welcomeTitle': welcomeTitle,
        'adsOn': adsOn,
        'adsDelay': adsDelay,
        'aboutApp': aboutApp,
        'developerCompany': developerCompany,
        'supaUrl': supaUrl,
        'supaBucket': supaBucket,
      };

  Color get brand => colorFromHex(brandColor, const Color(0xFF10275E));
  Color get accent => colorFromHex(accentColor, const Color(0xFF7C3AED));
}

const Map<String, List<String>> kCatTint = {
  'مدرسين': ['#F2ECFF', '#7C3AED'],
  'جامعات': ['#E9F1FE', '#2F6FE4'],
  'معاهد': ['#FEF5E4', '#F0A31B'],
  'مدارس': ['#E7F7F1', '#0F9D6E'],
};

const List<List<String>> kCatPalette = [
  ['#F2ECFF', '#7C3AED'],
  ['#E9F1FE', '#2F6FE4'],
  ['#FEF5E4', '#F0A31B'],
  ['#E7F7F1', '#0F9D6E'],
  ['#FEEDE3', '#F2711C'],
  ['#FEECEF', '#EF4444'],
  ['#EEF1FE', '#5B5BD6'],
  ['#E3F8ED', '#12A05F'],
  ['#E8F4FF', '#0EA5E9'],
  ['#FFF1F7', '#DB2777'],
];

const Map<String, String> kCatOne = {
  'مدرسين': 'مدرس',
  'جامعات': 'جامعة',
  'معاهد': 'معهد',
  'مدارس': 'مدرسة',
  'رياض الأطفال': 'روضة',
  'المكاتب': 'مكتب',
};

const Map<String, String> kCatIconFa = {
  'مدرسين': 'fa-solid fa-chalkboard-user',
  'جامعات': 'fa-solid fa-graduation-cap',
  'معاهد': 'fa-solid fa-building-columns',
  'مدارس': 'fa-solid fa-school',
  'رياض الأطفال': 'fa-solid fa-children',
  'المكاتب': 'fa-solid fa-briefcase',
};

class AppCategory {
  final String id;
  final String name;
  final String key;
  final String one;
  final String icon; // اسم Font Awesome كما في قاعدة البيانات
  final String tintSoft;
  final String tintAccent;
  final bool hier;
  final String desc;
  final String img;

  const AppCategory({
    required this.id,
    required this.name,
    required this.key,
    required this.one,
    required this.icon,
    required this.tintSoft,
    required this.tintAccent,
    required this.hier,
    required this.desc,
    required this.img,
  });

  IconData get iconData => iconFromFa(icon);
  Color get soft => colorFromHex(tintSoft, const Color(0xFFEEF2F8));
  Color get accent => colorFromHex(tintAccent, const Color(0xFF64748B));

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'key': key,
        'one': one,
        'icon': icon,
        'tint': [tintSoft, tintAccent],
        'hier': hier,
        'desc': desc,
        'img': img,
      };
}

List<AppCategory> defaultCategories() => const [
      AppCategory(id: 'c1', name: 'المدرسين', key: 'مدرسين', one: 'مدرس', icon: 'fa-solid fa-chalkboard-user', tintSoft: '#F2ECFF', tintAccent: '#7C3AED', hier: false, desc: 'تواصل مع أفضل المدرسين في مختلف التخصصات', img: 'asset:teachers'),
      AppCategory(id: 'c2', name: 'الجامعات', key: 'جامعات', one: 'جامعة', icon: 'fa-solid fa-graduation-cap', tintSoft: '#E9F1FE', tintAccent: '#2F6FE4', hier: false, desc: 'اكتشف أفضل الجامعات المحلية والعالمية', img: 'asset:universities'),
      AppCategory(id: 'c3', name: 'المعاهد', key: 'معاهد', one: 'معهد', icon: 'fa-solid fa-building-columns', tintSoft: '#FEF5E4', tintAccent: '#F0A31B', hier: true, desc: 'اكتشف المعاهد المتخصصة والدورات المهنية', img: 'asset:institutes'),
      AppCategory(id: 'c4', name: 'المدارس', key: 'مدارس', one: 'مدرسة', icon: 'fa-solid fa-school', tintSoft: '#E7F7F1', tintAccent: '#0F9D6E', hier: false, desc: 'ابحث عن أفضل المدارس لمختلف المراحل', img: 'asset:schools'),
      AppCategory(id: 'c5', name: 'رياض الأطفال', key: 'رياض الأطفال', one: 'روضة', icon: 'fa-solid fa-children', tintSoft: '#FFF0F6', tintAccent: '#DB2777', hier: false, desc: 'استعرض رياض الأطفال في مناطق ميسان', img: 'asset:schools'),
      AppCategory(id: 'c6', name: 'المكاتب', key: 'المكاتب', one: 'مكتب', icon: 'fa-solid fa-briefcase', tintSoft: '#EEF2FF', tintAccent: '#4F46E5', hier: false, desc: 'استعرض المكاتب والخدمات التعليمية', img: 'asset:institutes'),
    ];

List<AppCategory> normalizeCategories(dynamic raw, bool emptyFlag) {
  final list = pickList(raw);
  if (list.isEmpty) return emptyFlag ? <AppCategory>[] : defaultCategories();
  final seen = <String>{};
  final out = <AppCategory>[];
  final hex = RegExp(r'^#[0-9a-fA-F]{6}$');
  final faRe = RegExp(r'^fa-[A-Za-z0-9 _-]{1,100}$');
  for (var i = 0; i < list.length; i++) {
    final c = list[i];
    var key = clip(c['key'] ?? c['name'] ?? 'قسم${i + 1}', 80);
    if (key.isEmpty) key = 'قسم${i + 1}';
    while (seen.contains(key)) {
      key = '$key ${i + 1}';
    }
    seen.add(key);
    List<String> tint = kCatTint[key] ?? kCatPalette[i % kCatPalette.length];
    final rt = c['tint'];
    if (rt is List && rt.length == 2) tint = [str(rt[0]), str(rt[1])];
    final name = clip(c['name'] ?? key, 100);
    final one = clip(c['one'] ?? kCatOne[key] ?? c['name'] ?? key, 60);
    out.add(AppCategory(
      id: _safeId(c['id'], 'c'),
      name: name.isEmpty ? key : name,
      key: key,
      one: one.isEmpty ? key : one,
      icon: faRe.hasMatch(str(c['icon'])) ? str(c['icon']) : (kCatIconFa[key] ?? 'fa-regular fa-folder-open'),
      tintSoft: hex.hasMatch(tint[0]) ? tint[0] : '#EEF2F8',
      tintAccent: hex.hasMatch(tint[1]) ? tint[1] : '#64748B',
      hier: c['hier'] == null ? key == 'معاهد' : c['hier'] == true,
      desc: clip(c['desc'], 800),
      img: safeImageRef(c['img']),
    ));
  }
  return out;
}

class CardItem {
  final String id;
  final String name;
  String key;
  final String desc;
  final String img;
  final List<String> images;
  final String city;
  final String phone;
  final String specialty;
  final Map<String, String> extra;
  final double rating;
  final bool featured;
  String gov;
  String dist;
  final String status;
  final String created;

  CardItem({
    required this.id,
    required this.name,
    required this.key,
    required this.desc,
    required this.img,
    required this.images,
    required this.city,
    required this.phone,
    required this.specialty,
    required this.extra,
    required this.rating,
    required this.featured,
    required this.gov,
    required this.dist,
    required this.status,
    required this.created,
  });

  bool get published => status == 'منشور';
  bool get isTeacher => key.contains('مدرس');

  String get geoLabel {
    if (gov.isNotEmpty && dist.isNotEmpty) return '$gov / $dist';
    if (gov.isNotEmpty) return gov;
    if (dist.isNotEmpty) return dist;
    return city;
  }

  String get extraText => extra.values.join(' ');

  GeoPoint? get geo => parseGeo(extra['loc'] ?? '');

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'key': key,
        'desc': desc,
        'img': img,
        'images': images,
        'city': city,
        'phone': phone,
        'specialty': specialty,
        'extra': extra,
        'rating': rating,
        'featured': featured,
        'gov': gov,
        'dist': dist,
        'status': status,
        'created': created,
      };
}

Map<String, String> _cleanExtra(dynamic v) {
  final out = <String, String>{};
  if (v is! Map) return out;
  final re = RegExp(r'^[A-Za-z0-9_]{1,30}$');
  var n = 0;
  for (final e in v.entries) {
    if (n++ >= 30) break;
    final k = e.key.toString();
    if (!re.hasMatch(k)) continue;
    final s = clip(e.value, 200);
    if (s.isNotEmpty) out[k] = s;
  }
  return out;
}

List<CardItem> normalizeCards(dynamic raw, {String? forceKey, String defaultKey = 'عام'}) {
  final out = <CardItem>[];
  final areaSet = Cfg.maysanAreas.toSet();
  for (final c in pickList(raw)) {
    final images = safeImageList(c['images'], c['img']);
    final main = images.isNotEmpty ? images.first : '';
    var key = clip(c['key'], 80);
    if (key.isEmpty) key = defaultKey;
    var gov = clip(c['gov'], 100);
    var dist = clip(c['dist'], 100);
    final city = clip(c['city'], 150);
    // ترحيل بيانات العمارة والمناطق القديمة إلى محافظة ميسان
    if (gov == 'العمارة' || areaSet.contains(dist)) gov = Cfg.maysanGov;
    if (gov.isEmpty && city == Cfg.maysanGov) gov = city;
    if (dist.isEmpty && areaSet.contains(city)) {
      dist = city;
      if (gov.isEmpty) gov = Cfg.maysanGov;
    }
    final name = clip(c['name'], 150);
    final created = clip(c['created'], 20);
    out.add(CardItem(
      id: _safeId(c['id'], 'k'),
      name: name.isEmpty ? 'بدون اسم' : name,
      key: forceKey ?? key,
      desc: clip(c['desc'], 2000),
      img: main,
      images: images.isNotEmpty ? images : (main.isEmpty ? <String>[] : [main]),
      city: city,
      phone: clip(c['phone'], 40),
      specialty: clip(c['specialty'], 150),
      extra: _cleanExtra(c['extra']),
      rating: numOf(c['rating']).clamp(0, 5).toDouble(),
      featured: c['featured'] == true,
      gov: gov,
      dist: dist,
      status: str(c['status']) == 'مسودة' ? 'مسودة' : 'منشور',
      created: created.isEmpty ? todayIso() : created,
    ));
  }
  return out;
}

class AdItem {
  final String id;
  final String title;
  final String img;
  final String link;
  final String loc;
  final String map;
  final String desc;
  final String hours;
  final String phone;
  final Map<String, String> social; // wa, tg, fb, ig, tt
  final bool active;
  final String at;
  final int version;
  final int width;
  final int height;

  const AdItem({
    required this.id,
    required this.title,
    required this.img,
    required this.link,
    required this.loc,
    required this.map,
    required this.desc,
    required this.hours,
    required this.phone,
    required this.social,
    required this.active,
    required this.at,
    required this.version,
    required this.width,
    required this.height,
  });

  bool get hasInfo =>
      loc.isNotEmpty ||
      map.isNotEmpty ||
      desc.isNotEmpty ||
      hours.isNotEmpty ||
      phone.isNotEmpty ||
      social.values.any((v) => v.isNotEmpty);

  double get aspect {
    if (width > 0 && height > 0) return (width / height).clamp(0.5, 3.4).toDouble();
    return 16 / 9;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'img': img,
        'link': link,
        'loc': loc,
        'map': map,
        'desc': desc,
        'hours': hours,
        'phone': phone,
        ...social,
        'active': active,
        'at': at,
        'version': version,
        'width': width,
        'height': height,
      };
}

List<AdItem> normalizeAds(dynamic raw) {
  final out = <AdItem>[];
  for (final x in pickList(raw)) {
    final img = safeImageRef(x['img']);
    if (img.isEmpty) continue;
    final at = clip(x['at'] ?? nowIso(), 40);
    final upd = clip(x['updatedAt'] ?? at, 40);
    var ver = intOf(x['version']);
    if (ver <= 0) ver = parseIso(upd)?.millisecondsSinceEpoch ?? 0;
    out.add(AdItem(
      id: _safeId(x['id'], 'ad'),
      title: clip(x['title'], 150),
      img: img,
      link: _safeUrl(x['link'], 600),
      loc: clip(x['loc'], 300),
      map: _safeUrl(x['map'], 600),
      desc: clip(x['desc'], 2000),
      hours: clip(x['hours'], 300),
      phone: clip(x['phone'], 60),
      social: {
        'wa': clip(x['wa'], 120),
        'tg': clip(x['tg'], 120),
        'fb': clip(x['fb'], 200),
        'ig': clip(x['ig'], 200),
        'tt': clip(x['tt'], 200),
      },
      active: x['active'] != false,
      at: at,
      version: ver,
      width: intOf(x['width']).clamp(0, 10000).toInt(),
      height: intOf(x['height']).clamp(0, 10000).toInt(),
    ));
    if (out.length >= 60) break;
  }
  return out;
}

class NotifItem {
  final String id;
  final String title;
  final String text;
  final String at;
  final bool active;
  const NotifItem(this.id, this.title, this.text, this.at, this.active);

  Map<String, dynamic> toJson() =>
      {'id': id, 'title': title, 'text': text, 'at': at, 'active': active};
}

List<NotifItem> normalizeNotifs(dynamic raw) {
  final out = <NotifItem>[];
  for (final n in pickList(raw)) {
    final title = clip(n['title'], 150);
    out.add(NotifItem(
      _safeId(n['id'], 'n'),
      title.isEmpty ? 'إشعار' : title,
      clip(n['text'], 1500),
      clip(n['at'] ?? nowIso(), 40),
      n['active'] != false,
    ));
  }
  out.sort((a, b) => b.at.compareTo(a.at));
  return out.length > 300 ? out.sublist(0, 300) : out;
}

class RequestItem {
  final String id;
  final String type;
  final String about;
  final String from;
  final String msg;
  final String at;
  final bool read;
  final bool photo;
  final bool priv;
  final String status;
  final String cardId;

  const RequestItem({
    required this.id,
    required this.type,
    required this.about,
    required this.from,
    required this.msg,
    required this.at,
    this.read = false,
    this.photo = false,
    this.priv = false,
    this.status = '',
    this.cardId = '',
  });

  /// الصيغة المرسلة إلى فايربيس (نفس حقول نسخة الويب)
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'about': about,
        'from': from,
        'msg': msg,
        'at': at,
        'read': read,
        'photo': photo,
        'priv': priv,
        'status': status,
        'cardId': cardId,
      };
}

List<RequestItem> normalizeRequests(dynamic raw) {
  final out = <RequestItem>[];
  for (final r in pickList(raw)) {
    out.add(RequestItem(
      id: _safeId(r['id'], 'r'),
      type: clip(r['type'], 60),
      about: clip(r['about'], 160),
      from: clip(r['from'], 180),
      msg: clip(r['msg'], 2000),
      at: clip(r['at'] ?? nowIso(), 40),
      read: r['read'] == true,
      photo: r['photo'] == true,
      priv: r['priv'] == true,
      status: clip(r['status'], 30),
      cardId: clip(r['cardId'], 60),
    ));
  }
  return out;
}

/// بيانات عقدة core بعد التطبيع
class AppData {
  AppSettings settings = AppSettings();
  List<AppCategory> categories = defaultCategories();
  List<CardItem> cards = [];
  List<AdItem> ads = [];
  List<NotifItem> notifications = [];

  /// طلبات هذا الجهاز فقط — لا نحتفظ بطلبات بقية المستخدمين ولا بحسابات المدراء
  List<RequestItem> myRequests = [];

  AppData();

  factory AppData.fromCore(dynamic raw, Set<String> myIds) {
    final d = AppData();
    if (raw is! Map) return d;
    final emp = raw['_empty'] is Map ? raw['_empty'] as Map : const {};
    d.settings = AppSettings.fromJson(raw['settings']);
    d.categories = normalizeCategories(raw['categories'], emp['categories'] == true);
    final defKey = d.categories.isNotEmpty ? d.categories.first.key : 'عام';
    d.cards = normalizeCards(raw['cards'], defaultKey: defKey);
    d.ads = normalizeAds(raw['ads']);
    d.notifications = normalizeNotifs(raw['notifications']);
    d.myRequests =
        normalizeRequests(raw['requests']).where((r) => myIds.contains(r.id)).toList();
    return d;
  }

  /// نسخة الجهاز المؤقتة (للعمل دون إنترنت)
  Map<String, dynamic> toCache() => {
        'settings': settings.toJson(),
        'categories': categories.map((c) => c.toJson()).toList(),
        'cards': cards.map((c) => c.toJson()).toList(),
        'ads': ads.map((c) => c.toJson()).toList(),
        'notifications': notifications.map((c) => c.toJson()).toList(),
        'requests': myRequests.map((c) => c.toJson()).toList(),
        '_empty': {'categories': categories.isEmpty},
      };
}
