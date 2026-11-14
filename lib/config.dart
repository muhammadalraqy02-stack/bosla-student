// إعدادات الخوادم والثوابت — مطابقة لنسخة الويب (index.html)
// نفس قاعدة البيانات ونفس حاوية الصور، حتى يعمل التطبيق الجديد على البيانات الحالية دون أي ترحيل.

import 'package:flutter/material.dart';

class Cfg {
  static const String appVersion = '3.12-flutter';

  /// رابط نسخة الويب العامة — يُستخدم فقط في زر «مشاركة» لإنشاء رابط العنصر (#item=ID).
  /// اتركه فارغاً لمشاركة نص فقط.
  static const String webBaseUrl = '';

  // ===== Firebase Realtime Database (REST) =====
  static const String fbBase = 'https://bosla-e2164-default-rtdb.firebaseio.com';
  static const String fbNs = 'knowledge';
  static const String fbRoot = '$fbBase/$fbNs';
  static const String fbCore = '$fbRoot/core';
  static const String fbMedia = '$fbRoot/media'; // قديم: صور base64
  static const String fbMetrics = '$fbRoot/metrics';
  static const String fbPublic = '$fbRoot/public';
  static const String fbPublicVersion = '$fbRoot/publicVersion';
  static const String fbRequestMedia = '$fbRoot/requestMedia';
  static const String fbRequestsPrivate = '$fbRoot/requestsPrivate';
  static const String fbReviews = '$fbRoot/reviews';
  static const String fbReviewReports = '$fbRoot/reviewReports';

  /// الأقسام المفصولة في عقدة public (اسم القسم ← رمز العقدة)
  static const Map<String, String> publicSections = {
    'مدارس': 'schools',
    'معاهد': 'institutes',
  };
  static const int publicVersionCheckMs = 30 * 60 * 1000;
  static const int adCheckIntervalMs = 15 * 60 * 1000;

  // ===== Supabase Storage (الصور فقط) =====
  static const String supaUrlDefault = 'https://ayicfcqfdafjheftcedk.supabase.co';
  static const String supaKey = 'sb_publishable_wzwm3lPKhD-UOKekXOGFmQ_I4b6SDmm';
  static const String supaBucketDefault = 'media';

  // ===== دليل ميسان =====
  static const String maysanGov = 'ميسان';
  static const List<String> maysanAreas = [
    'عواشة',
    'القطاع',
    'حي المعلمين الجديد',
    'مغربة',
    'حي الجامعي',
    'حي المعلمين القديم',
    'حي الحسين الجديد',
    'ابو رمانة',
    'الجمعيات',
    'الماجدية',
    'حي الرسالة',
    'حي النداء',
    'حي الخليج',
  ];

  static const List<String> teacherSpecialties = [
    'رياضيات',
    'اللغة الإنكليزية',
    'اللغة العربية',
    'فيزياء',
    'كيمياء',
    'أحياء',
    'حاسوب',
    'اجتماعيات',
    'تربية إسلامية',
    'اللغة الفرنسية',
  ];

  static const String legalUpdated = '15 تشرين الأول 2026';
  static const String noArea = 'غير محدد';
}

class SpecialtyMeta {
  final IconData icon;
  final Color soft;
  final Color accent;
  const SpecialtyMeta(this.icon, this.soft, this.accent);
}

const Map<String, SpecialtyMeta> kSpecialtyMeta = {
  'رياضيات': SpecialtyMeta(Icons.calculate, Color(0xFFE9F1FE), Color(0xFF2F6FE4)),
  'اللغة الإنكليزية': SpecialtyMeta(Icons.translate, Color(0xFFF2ECFF), Color(0xFF7C3AED)),
  'اللغة العربية': SpecialtyMeta(Icons.menu_book, Color(0xFFFEF5E4), Color(0xFFE88A10)),
  'فيزياء': SpecialtyMeta(Icons.bolt, Color(0xFFE8F4FF), Color(0xFF0EA5E9)),
  'كيمياء': SpecialtyMeta(Icons.science, Color(0xFFE3F8ED), Color(0xFF12A05F)),
  'أحياء': SpecialtyMeta(Icons.biotech, Color(0xFFE7F7F1), Color(0xFF0F9D6E)),
  'حاسوب': SpecialtyMeta(Icons.computer, Color(0xFFEEF1FE), Color(0xFF5B5BD6)),
  'اجتماعيات': SpecialtyMeta(Icons.public, Color(0xFFFEEDE3), Color(0xFFF2711C)),
  'تربية إسلامية': SpecialtyMeta(Icons.mosque, Color(0xFFE3F8ED), Color(0xFF16865A)),
  'اللغة الفرنسية': SpecialtyMeta(Icons.spellcheck, Color(0xFFFFF1F7), Color(0xFFDB2777)),
};

const SpecialtyMeta kSpecialtyDefault =
    SpecialtyMeta(Icons.menu_book, Color(0xFFF2ECFF), Color(0xFF7C3AED));

/// حقل في استمارة القسم
class FormFieldDef {
  final String id;
  final String label;
  final IconData icon;
  final String link; // '' أو map/wa/tg/fb/ig/tt/yt
  final Color? color;
  const FormFieldDef(this.id, this.label, this.icon, {this.link = '', this.color});
}

class CatForm {
  final String specLabel;
  final List<FormFieldDef> fields;
  const CatForm(this.specLabel, this.fields);
}

const FormFieldDef _locField =
    FormFieldDef('loc', 'الموقع على الخريطة', Icons.my_location, link: 'map');

const Map<String, CatForm> kCatForms = {
  'مدرسين': CatForm('المادة / التخصص', [
    _locField,
    FormFieldDef('stage', 'المرحلة الدراسية', Icons.layers),
    FormFieldDef('exp', 'سنوات الخبرة', Icons.hourglass_bottom),
    FormFieldDef('mode', 'نمط التدريس', Icons.laptop),
    FormFieldDef('gtype', 'نوع الدرس', Icons.group),
    FormFieldDef('gender', 'جنس الطلبة المقبولين', Icons.wc),
    FormFieldDef('times', 'أوقات الدوام', Icons.schedule),
  ]),
  'جامعات': CatForm('أبرز الكليات / التخصصات', [
    _locField,
    FormFieldDef('utype', 'نوع الجامعة', Icons.account_balance),
    FormFieldDef('founded', 'سنة التأسيس', Icons.calendar_today),
    FormFieldDef('colleges', 'عدد الكليات', Icons.account_tree),
    FormFieldDef('study', 'نظام الدراسة', Icons.wb_sunny_outlined),
    FormFieldDef('degrees', 'الشهادات الممنوحة', Icons.school),
    FormFieldDef('site', 'الموقع الإلكتروني', Icons.public),
  ]),
  'معاهد': CatForm('الأقسام / التخصصات', [
    _locField,
    FormFieldDef('itype', 'نوع المعهد', Icons.business),
    FormFieldDef('duration', 'مدة الدراسة', Icons.hourglass_bottom),
    FormFieldDef('study', 'نظام الدراسة', Icons.wb_sunny_outlined),
    FormFieldDef('cert', 'نوع الشهادة', Icons.workspace_premium),
    FormFieldDef('site', 'الموقع الإلكتروني', Icons.public),
  ]),
  'مدارس': CatForm('التوجه / التميّز', [
    _locField,
    FormFieldDef('stype', 'نوع المدرسة', Icons.school),
    FormFieldDef('stage', 'المرحلة', Icons.layers),
    FormFieldDef('gender', 'جنس الطلبة', Icons.wc),
    FormFieldDef('curriculum', 'المنهج', Icons.book),
    FormFieldDef('lang', 'لغة الدراسة', Icons.translate),
    FormFieldDef('buses', 'خدمة النقل (الباصات)', Icons.directions_bus),
  ]),
};

const CatForm kDefaultForm = CatForm('التخصص', [
  _locField,
  FormFieldDef('gtype2', 'النوع', Icons.sell),
  FormFieldDef('site', 'الموقع الإلكتروني', Icons.public),
]);

/// حقول التواصل — مشتركة بين جميع الأقسام
const List<FormFieldDef> kCommonFields = [
  FormFieldDef('wa', 'واتساب', Icons.whatsapp, link: 'wa', color: Color(0xFF25D366)),
  FormFieldDef('tg', 'تيليغرام', Icons.telegram, link: 'tg', color: Color(0xFF29A9EB)),
  FormFieldDef('fb', 'فيسبوك', Icons.facebook, link: 'fb', color: Color(0xFF1877F2)),
  FormFieldDef('ig', 'إنستغرام', Icons.camera_alt, link: 'ig', color: Color(0xFFE1306C)),
  FormFieldDef('tt', 'تيك توك', Icons.tiktok, link: 'tt', color: Color(0xFF111827)),
  FormFieldDef('yt', 'يوتيوب', Icons.smart_display, link: 'yt', color: Color(0xFFFF0000)),
];

CatForm formOf(String key) => kCatForms[key] ?? kDefaultForm;

List<FormFieldDef> formFields(String key) => [...formOf(key).fields, ...kCommonFields];

/// تحويل أسماء أيقونات Font Awesome المخزّنة في قاعدة البيانات إلى أيقونات Material
const Map<String, IconData> kFaIcons = {
  'fa-chalkboard-user': Icons.co_present,
  'fa-graduation-cap': Icons.school,
  'fa-building-columns': Icons.account_balance,
  'fa-school': Icons.location_city,
  'fa-users-rectangle': Icons.groups,
  'fa-book': Icons.book,
  'fa-book-open-reader': Icons.menu_book,
  'fa-book-open': Icons.menu_book,
  'fa-laptop-code': Icons.computer,
  'fa-language': Icons.translate,
  'fa-flask': Icons.science,
  'fa-microscope': Icons.biotech,
  'fa-calculator': Icons.calculate,
  'fa-palette': Icons.palette,
  'fa-music': Icons.music_note,
  'fa-futbol': Icons.sports_soccer,
  'fa-stethoscope': Icons.medical_services,
  'fa-scale-balanced': Icons.balance,
  'fa-helmet-safety': Icons.engineering,
  'fa-mosque': Icons.mosque,
  'fa-pen-ruler': Icons.architecture,
  'fa-user-tie': Icons.person,
  'fa-certificate': Icons.workspace_premium,
  'fa-briefcase': Icons.work,
  'fa-globe': Icons.public,
  'fa-folder-open': Icons.folder_open,
  'fa-children': Icons.child_care,
  'fa-atom': Icons.bolt,
  'fa-earth-asia': Icons.public,
  'fa-spell-check': Icons.spellcheck,
  'fa-building': Icons.business,
  'fa-star': Icons.star,
  'fa-bullhorn': Icons.campaign,
};

IconData iconFromFa(String? fa) {
  final s = (fa ?? '').trim();
  for (final part in s.split(RegExp(r'\s+'))) {
    final ic = kFaIcons[part];
    if (ic != null) return ic;
  }
  return Icons.folder_open;
}
