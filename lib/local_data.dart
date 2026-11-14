// بيانات أدوات الطالب المحفوظة على الجهاز فقط (لا تُرسل إلى أي خادم):
// الملاحظات، الجدول الأسبوعي، حاسبة المعدل، العدّ التنازلي — بنفس مفاتيح وصيغ نسخة الويب

import 'store.dart';
import 'utils.dart';

class CardNote {
  final String text;
  final int at;
  const CardNote(this.text, this.at);
}

class LocalData {
  // ---------- الملاحظات ----------
  static Map<String, dynamic> _notes() {
    final n = Store.getMap(K.notes);
    if (n['cards'] is! Map) n['cards'] = <String, dynamic>{};
    if (n['general'] is! List) n['general'] = <dynamic>[];
    return n;
  }

  static CardNote? cardNote(String id) {
    final c = (_notes()['cards'] as Map)[id];
    if (c is Map && str(c['text']).isNotEmpty) return CardNote(str(c['text']), intOf(c['at']));
    return null;
  }

  static Map<String, CardNote> allCardNotes() {
    final out = <String, CardNote>{};
    final m = _notes()['cards'] as Map;
    for (final e in m.entries) {
      final c = e.value;
      if (c is Map && str(c['text']).isNotEmpty) {
        out[e.key.toString()] = CardNote(str(c['text']), intOf(c['at']));
      }
    }
    return out;
  }

  static Future<void> setCardNote(String id, String text) async {
    final n = _notes();
    final cards = Map<String, dynamic>.from(n['cards'] as Map);
    if (text.isEmpty) {
      cards.remove(id);
    } else {
      cards[id] = {'text': text, 'at': DateTime.now().millisecondsSinceEpoch};
    }
    n['cards'] = cards;
    await Store.setJson(K.notes, n);
  }

  static List<Map<String, dynamic>> generalNotes() {
    final g = _notes()['general'] as List;
    final out = g.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    out.sort((a, b) => intOf(b['at']).compareTo(intOf(a['at'])));
    return out;
  }

  /// يحفظ ملاحظة عامة (جديدة أو تعديل). يعيد false عند بلوغ الحد الأقصى.
  static Future<bool> saveGeneralNote({String? id, required String title, required String text}) async {
    final n = _notes();
    final g = (n['general'] as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    final now = DateTime.now().millisecondsSinceEpoch;
    if (id != null) {
      for (final x in g) {
        if (str(x['id']) == id) {
          x['title'] = title;
          x['text'] = text;
          x['at'] = now;
        }
      }
    } else {
      if (g.length >= 300) return false;
      g.add({'id': uid(), 'title': title, 'text': text, 'at': now});
    }
    n['general'] = g;
    await Store.setJson(K.notes, n);
    return true;
  }

  static Future<void> deleteGeneralNote(String id) async {
    final n = _notes();
    n['general'] = (n['general'] as List)
        .whereType<Map>()
        .where((x) => str(x['id']) != id)
        .toList();
    await Store.setJson(K.notes, n);
  }

  // ---------- الجدول الأسبوعي ----------
  // العنصر: {id, day (0 = الأحد ... 6 = السبت), time "HH:MM", subject, place, lead}
  static List<Map<String, dynamic>> schedule() => Store.getMapList(K.schedule);

  static Future<void> saveSchedule(List<Map<String, dynamic>> s) => Store.setJson(K.schedule, s);

  // ---------- العدّ التنازلي ----------
  // العنصر: {id, title, at (ms)}
  static List<Map<String, dynamic>> countdowns() {
    final a = Store.getMapList(K.countdowns);
    a.sort((x, y) => intOf(x['at']).compareTo(intOf(y['at'])));
    return a;
  }

  static Future<void> saveCountdowns(List<Map<String, dynamic>> s) =>
      Store.setJson(K.countdowns, s);

  // ---------- حاسبة المعدل ----------
  // {rows: [{n, m, max}], target}
  static Map<String, dynamic> gpa() {
    final g = Store.getMap(K.gpa);
    final rows = g['rows'] is List
        ? (g['rows'] as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
        : <Map<String, dynamic>>[];
    if (rows.isEmpty) rows.add({'n': '', 'm': '', 'max': 100});
    return {'rows': rows, 'target': str(g['target'])};
  }

  static Future<void> saveGpa(Map<String, dynamic> g) => Store.setJson(K.gpa, g);
}
