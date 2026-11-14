// أدوات الطالب: الجدول الأسبوعي (مع تذكير)، حاسبة المعدل، العدّ التنازلي، الملاحظات
// كل بياناتها محفوظة على الجهاز فقط.

import 'dart:async';

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../local_data.dart';
import '../ui.dart';
import '../utils.dart';
import '../widgets/common.dart';
import 'detail_screen.dart';

/// أسماء الأيام بترتيب نسخة الويب: 0 = الأحد ... 6 = السبت
const List<String> kJsDays = ['الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت'];

/// ترتيب العرض: يبدأ الأسبوع الدراسي بالسبت
const List<int> kDayOrder = [6, 0, 1, 2, 3, 4, 5];

class ToolsScreen extends StatelessWidget {
  final bool standalone;
  final int initialTab;
  final String? pendingCountdownTitle;
  const ToolsScreen({
    super.key,
    this.standalone = false,
    this.initialTab = 0,
    this.pendingCountdownTitle,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      initialIndex: initialTab,
      child: Scaffold(
        appBar: brandAppBar(
          context,
          'أدوات الطالب',
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Color(0xFFF3D98A),
            labelStyle: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
            tabs: [
              Tab(text: 'الجدول الأسبوعي'),
              Tab(text: 'حاسبة المعدل'),
              Tab(text: 'العدّ التنازلي'),
              Tab(text: 'ملاحظاتي'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            const _ScheduleTab(),
            const _GpaTab(),
            _CountdownTab(pendingTitle: pendingCountdownTitle),
            const _NotesTab(),
          ],
        ),
      ),
    );
  }
}

Widget _box(BuildContext context, {required Widget child, EdgeInsets? padding}) {
  final p = Pal.of(context);
  return Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: padding ?? const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: p.card,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: p.border),
    ),
    child: child,
  );
}

Widget _lead(BuildContext context, int value, ValueChanged<int> onChanged, Map<int, String> options) {
  return DropdownButtonFormField<int>(
    value: value,
    isExpanded: true,
    decoration: fieldDeco(context, 'التذكير'),
    items: [
      for (final e in options.entries) DropdownMenuItem(value: e.key, child: Text(e.value)),
    ],
    onChanged: (v) => onChanged(v ?? value),
  );
}

// ======================= الجدول الأسبوعي =======================

class _ScheduleTab extends StatefulWidget {
  const _ScheduleTab();

  @override
  State<_ScheduleTab> createState() => _ScheduleTabState();
}

class _ScheduleTabState extends State<_ScheduleTab> {
  final TextEditingController _subject = TextEditingController();
  final TextEditingController _place = TextEditingController();
  int _day = 6;
  TimeOfDay _time = const TimeOfDay(hour: 16, minute: 0);
  int _leadMin = 15;

  @override
  void dispose() {
    _subject.dispose();
    _place.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final subject = clip(_subject.text, 80);
    if (subject.isEmpty) {
      toast('أدخل اسم المادة أو الدرس', ToastType.warn);
      return;
    }
    final list = LocalData.schedule();
    if (list.length >= 80) {
      toast('بلغت الحد الأقصى لعدد الدروس', ToastType.warn);
      return;
    }
    final id = uid();
    final place = clip(_place.text, 80);
    list.add({
      'id': id,
      'day': _day,
      'time': '${two(_time.hour)}:${two(_time.minute)}',
      'subject': subject,
      'place': place,
      'lead': _leadMin,
    });
    await LocalData.saveSchedule(list);
    if (_leadMin >= 0) {
      await AppState.I.remAdd({
        'id': 's$id',
        'title': 'درس: $subject',
        'body': place.isEmpty ? '${kJsDays[_day]} · ${arTime(DateTime(2020, 1, 1, _time.hour, _time.minute))}' : place,
        'weekly': {'wd': _day, 'h': _time.hour, 'm': _time.minute},
        'lead': _leadMin,
      });
    }
    _subject.clear();
    _place.clear();
    toast('أُضيف الدرس إلى جدولك');
    AppState.I.refreshUi();
    if (mounted) setState(() {});
  }

  Future<void> _delete(String id) async {
    final list = LocalData.schedule().where((x) => str(x['id']) != id).toList();
    await LocalData.saveSchedule(list);
    await AppState.I.remDel('s$id');
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    final list = LocalData.schedule();
    final byDay = <int, List<Map<String, dynamic>>>{};
    for (final x in list) {
      byDay.putIfAbsent(intOf(x['day']) % 7, () => []).add(x);
    }
    for (final v in byDay.values) {
      v.sort((a, b) => str(a['time']).compareTo(str(b['time'])));
    }
    final today = DateTime.now().weekday % 7;

    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 90),
      children: [
        _box(
          context,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('إضافة درس', style: TextStyle(fontWeight: FontWeight.w800, color: p.text)),
              const SizedBox(height: 10),
              TextField(
                controller: _subject,
                maxLength: 80,
                decoration: fieldDeco(context, 'المادة / الدرس', hint: 'مثال: رياضيات — أ. أحمد'),
              ),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _day,
                      isExpanded: true,
                      decoration: fieldDeco(context, 'اليوم'),
                      items: [
                        for (final d in kDayOrder) DropdownMenuItem(value: d, child: Text(kJsDays[d])),
                      ],
                      onChanged: (v) => setState(() => _day = v ?? _day),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final t = await showTimePicker(context: context, initialTime: _time);
                        if (t != null) setState(() => _time = t);
                      },
                      child: InputDecorator(
                        decoration: fieldDeco(context, 'الوقت'),
                        child: Text(arTime(DateTime(2020, 1, 1, _time.hour, _time.minute))),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _place,
                maxLength: 80,
                decoration: fieldDeco(context, 'المكان (اختياري)'),
              ),
              _lead(context, _leadMin, (v) => setState(() => _leadMin = v), const {
                -1: 'بدون تذكير',
                0: 'عند الموعد',
                10: 'قبل 10 دقائق',
                15: 'قبل 15 دقيقة',
                30: 'قبل 30 دقيقة',
                60: 'قبل ساعة',
              }),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: PrimaryButton('إضافة إلى الجدول', icon: Icons.add, onPressed: _add),
              ),
            ],
          ),
        ),
        if (list.isEmpty)
          const EmptyBox('جدولك فارغ. أضف دروسك ليذكّرك التطبيق بها أسبوعياً.', icon: Icons.calendar_month)
        else
          for (final d in kDayOrder)
            if (byDay[d] != null)
              _box(
                context,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          kJsDays[d],
                          style: TextStyle(fontWeight: FontWeight.w800, color: p.brandOn, fontSize: 15),
                        ),
                        if (d == today) ...[
                          const SizedBox(width: 8),
                          Tag('اليوم', bg: p.gold, fg: Colors.white),
                        ],
                      ],
                    ),
                    for (final x in byDay[d]!)
                      Row(
                        children: [
                          SizedBox(
                            width: 74,
                            child: Text(
                              _fmtTime(str(x['time'])),
                              style: TextStyle(color: p.muted, fontSize: 12.5, fontWeight: FontWeight.w700),
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  str(x['subject']),
                                  style: TextStyle(fontWeight: FontWeight.w700, color: p.text),
                                ),
                                if (str(x['place']).isNotEmpty)
                                  Text(
                                    str(x['place']),
                                    style: TextStyle(color: p.muted, fontSize: 12),
                                  ),
                              ],
                            ),
                          ),
                          if (intOf(x['lead']) >= 0)
                            Icon(Icons.notifications_active_outlined, size: 16, color: p.muted),
                          IconButton(
                            tooltip: 'حذف',
                            icon: const Icon(Icons.delete_outline, size: 20),
                            onPressed: () => _delete(str(x['id'])),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
      ],
    );
  }

  String _fmtTime(String hhmm) {
    final parts = hhmm.split(':');
    if (parts.length != 2) return hhmm;
    return arTime(DateTime(2020, 1, 1, int.tryParse(parts[0]) ?? 0, int.tryParse(parts[1]) ?? 0));
  }
}

// ======================= حاسبة المعدل =======================

class _GpaTab extends StatefulWidget {
  const _GpaTab();

  @override
  State<_GpaTab> createState() => _GpaTabState();
}

class _GpaTabState extends State<_GpaTab> {
  late List<Map<String, dynamic>> _rows;
  late String _target;
  int _gen = 0; // يتغيّر عند إضافة/حذف صف لإعادة بناء الحقول

  @override
  void initState() {
    super.initState();
    final g = LocalData.gpa();
    _rows = List<Map<String, dynamic>>.from(g['rows'] as List);
    _target = str(g['target']);
  }

  void _save() {
    LocalData.saveGpa({'rows': _rows, 'target': _target});
  }

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    var sum = 0.0;
    var max = 0.0;
    var counted = 0;
    for (final r in _rows) {
      final ms = str(r['m']).trim();
      if (ms.isEmpty) continue;
      final m = numOf(ms);
      var mx = numOf(r['max']);
      if (mx <= 0) mx = 100;
      sum += m.clamp(0, mx).toDouble();
      max += mx;
      counted++;
    }
    final avg = max > 0 ? sum / max * 100 : 0.0;
    final target = numOf(_target);
    String grade(double a) {
      if (a >= 90) return 'امتياز';
      if (a >= 80) return 'جيد جداً';
      if (a >= 70) return 'جيد';
      if (a >= 60) return 'متوسط';
      if (a >= 50) return 'مقبول';
      return 'دون النجاح';
    }

    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 90),
      children: [
        _box(
          context,
          child: Column(
            children: [
              Text(
                counted == 0 ? '—' : '${avg.toStringAsFixed(2)}%',
                style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: p.brandOn),
              ),
              Text(
                counted == 0
                    ? 'أدخل درجاتك لحساب المعدل'
                    : '${grade(avg)} · المجموع ${_trim(sum)} من ${_trim(max)} · $counted مادة',
                textAlign: TextAlign.center,
                style: TextStyle(color: p.muted),
              ),
              if (counted > 0 && target > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    avg >= target
                        ? 'حققت هدفك (${_trim(target)}%) بفارق ${(avg - target).toStringAsFixed(2)}'
                        : 'ينقصك ${(target - avg).toStringAsFixed(2)} للوصول إلى هدفك (${_trim(target)}%)',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: avg >= target ? const Color(0xFF0B8A4F) : const Color(0xFFB54708),
                    ),
                  ),
                ),
            ],
          ),
        ),
        for (var i = 0; i < _rows.length; i++)
          Padding(
            key: ValueKey('gpa-$_gen-$i'),
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: TextFormField(
                    initialValue: str(_rows[i]['n']),
                    maxLength: 40,
                    decoration: fieldDeco(context, 'المادة').copyWith(counterText: ''),
                    onChanged: (v) {
                      _rows[i]['n'] = v;
                      _save();
                    },
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    initialValue: str(_rows[i]['m']),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: fieldDeco(context, 'الدرجة'),
                    onChanged: (v) {
                      setState(() => _rows[i]['m'] = v);
                      _save();
                    },
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    initialValue: str(_rows[i]['max']),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: fieldDeco(context, 'من'),
                    onChanged: (v) {
                      setState(() => _rows[i]['max'] = v);
                      _save();
                    },
                  ),
                ),
                IconButton(
                  tooltip: 'حذف',
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: _rows.length <= 1
                      ? null
                      : () {
                          setState(() {
                            _rows.removeAt(i);
                            _gen++;
                          });
                          _save();
                        },
                ),
              ],
            ),
          ),
        Row(
          children: [
            Expanded(
              child: SoftButton(
                'إضافة مادة',
                icon: Icons.add,
                onPressed: _rows.length >= 40
                    ? null
                    : () {
                        setState(() => _rows.add({'n': '', 'm': '', 'max': 100}));
                        _save();
                      },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                key: ValueKey('gpa-target-$_gen'),
                initialValue: _target,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: fieldDeco(context, 'هدفي %'),
                onChanged: (v) {
                  setState(() => _target = v);
                  _save();
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'الحاسبة للمساعدة فقط، والمعتمد هو النتائج والتعليمات الرسمية.',
          style: TextStyle(color: p.muted, fontSize: 12),
        ),
      ],
    );
  }

  String _trim(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
}

// ======================= العدّ التنازلي =======================

class _CountdownTab extends StatefulWidget {
  final String? pendingTitle;
  const _CountdownTab({this.pendingTitle});

  @override
  State<_CountdownTab> createState() => _CountdownTabState();
}

class _CountdownTabState extends State<_CountdownTab> {
  final TextEditingController _title = TextEditingController();
  DateTime? _date;
  TimeOfDay _time = const TimeOfDay(hour: 8, minute: 0);
  int _leadMin = 1440;
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _title.text = widget.pendingTitle ?? '';
    _tick = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    _title.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final title = clip(_title.text, 100);
    final d = _date;
    if (title.isEmpty) {
      toast('أدخل عنوان الموعد', ToastType.warn);
      return;
    }
    if (d == null) {
      toast('اختر التاريخ', ToastType.warn);
      return;
    }
    final at = DateTime(d.year, d.month, d.day, _time.hour, _time.minute);
    if (!at.isAfter(DateTime.now())) {
      toast('اختر موعداً في المستقبل', ToastType.warn);
      return;
    }
    final list = LocalData.countdowns();
    if (list.length >= 40) {
      toast('بلغت الحد الأقصى لعدد المواعيد', ToastType.warn);
      return;
    }
    final id = uid();
    list.add({'id': id, 'title': title, 'at': at.millisecondsSinceEpoch});
    await LocalData.saveCountdowns(list);
    if (_leadMin >= 0) {
      await AppState.I.remAdd({
        'id': 'c$id',
        'title': title,
        'body': _leadMin == 0 ? 'حان الموعد' : 'الموعد: ${arDateTime(at.millisecondsSinceEpoch)}',
        'at': at.millisecondsSinceEpoch,
        'lead': _leadMin,
      });
    }
    _title.clear();
    toast('أُضيف الموعد');
    AppState.I.refreshUi();
    if (mounted) setState(() => _date = null);
  }

  Future<void> _delete(String id) async {
    await LocalData.saveCountdowns(LocalData.countdowns().where((x) => str(x['id']) != id).toList());
    await AppState.I.remDel('c$id');
    if (mounted) setState(() {});
  }

  String _remaining(int at) {
    final diff = at - DateTime.now().millisecondsSinceEpoch;
    if (diff <= 0) return 'انتهى الموعد';
    final days = diff ~/ 86400000;
    final hours = (diff % 86400000) ~/ 3600000;
    final mins = (diff % 3600000) ~/ 60000;
    if (days > 0) return 'باقٍ $days يوم و$hours ساعة';
    if (hours > 0) return 'باقٍ $hours ساعة و$mins دقيقة';
    return 'باقٍ $mins دقيقة';
  }

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    final list = LocalData.countdowns();
    final d = _date;
    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 90),
      children: [
        _box(
          context,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('موعد جديد', style: TextStyle(fontWeight: FontWeight.w800, color: p.text)),
              const SizedBox(height: 10),
              TextField(
                controller: _title,
                maxLength: 100,
                decoration: fieldDeco(context, 'العنوان', hint: 'مثال: امتحان الفيزياء الوزاري'),
              ),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final now = DateTime.now();
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: d ?? now,
                          firstDate: DateTime(now.year, now.month, now.day),
                          lastDate: DateTime(now.year + 3, 12, 31),
                        );
                        if (picked != null) setState(() => _date = picked);
                      },
                      child: InputDecorator(
                        decoration: fieldDeco(context, 'التاريخ'),
                        child: Text(d == null ? 'اختر' : '${d.day} ${kArMonths[d.month - 1]} ${d.year}'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final t = await showTimePicker(context: context, initialTime: _time);
                        if (t != null) setState(() => _time = t);
                      },
                      child: InputDecorator(
                        decoration: fieldDeco(context, 'الوقت'),
                        child: Text(arTime(DateTime(2020, 1, 1, _time.hour, _time.minute))),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _lead(context, _leadMin, (v) => setState(() => _leadMin = v), const {
                -1: 'بدون تذكير',
                0: 'عند الموعد',
                60: 'قبل ساعة',
                1440: 'قبل يوم',
                4320: 'قبل 3 أيام',
              }),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: PrimaryButton('إضافة الموعد', icon: Icons.add_alarm, onPressed: _add),
              ),
            ],
          ),
        ),
        if (list.isEmpty)
          const EmptyBox('لا توجد مواعيد. أضف امتحاناتك ومواعيد التسجيل لتتابع الوقت المتبقي.', icon: Icons.hourglass_empty)
        else
          for (final x in list)
            _box(
              context,
              padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
              child: Row(
                children: [
                  Icon(Icons.hourglass_bottom, color: p.brandOn),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          str(x['title']),
                          style: TextStyle(fontWeight: FontWeight.w800, color: p.text),
                        ),
                        Text(
                          _remaining(intOf(x['at'])),
                          style: TextStyle(color: p.brandOn, fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                        Text(
                          arDateTime(intOf(x['at'])),
                          style: TextStyle(color: p.muted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'حذف',
                    icon: const Icon(Icons.delete_outline, size: 20),
                    onPressed: () => _delete(str(x['id'])),
                  ),
                ],
              ),
            ),
      ],
    );
  }
}

// ======================= الملاحظات =======================

class _NotesTab extends StatefulWidget {
  const _NotesTab();

  @override
  State<_NotesTab> createState() => _NotesTabState();
}

class _NotesTabState extends State<_NotesTab> {
  Future<void> _edit({Map<String, dynamic>? note}) async {
    final title = TextEditingController(text: note == null ? '' : str(note['title']));
    final text = TextEditingController(text: note == null ? '' : str(note['text']));
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Pal.of(context).card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(18, 18, 18, 18 + MediaQuery.viewInsetsOf(ctx).bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: title,
              maxLength: 80,
              decoration: fieldDeco(ctx, 'العنوان (اختياري)'),
            ),
            TextField(
              controller: text,
              autofocus: true,
              maxLength: 1500,
              minLines: 4,
              maxLines: 8,
              decoration: fieldDeco(ctx, 'الملاحظة'),
            ),
            SizedBox(
              width: double.infinity,
              child: PrimaryButton(
                'حفظ',
                icon: Icons.save_outlined,
                onPressed: () => Navigator.of(ctx).pop(true),
              ),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    final body = clip(text.text, 1500);
    if (body.isEmpty) {
      toast('الملاحظة فارغة', ToastType.warn);
      return;
    }
    final saved = await LocalData.saveGeneralNote(
      id: note == null ? null : str(note['id']),
      title: clip(title.text, 80),
      text: body,
    );
    toast(saved ? 'حُفظت الملاحظة' : 'بلغت الحد الأقصى لعدد الملاحظات', saved ? ToastType.ok : ToastType.warn);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    final s = AppState.I;
    final general = LocalData.generalNotes();
    final cardNotes = LocalData.allCardNotes();
    final cardIds = cardNotes.keys.where((id) => s.cardById(id) != null).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 90),
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: PrimaryButton('ملاحظة جديدة', icon: Icons.note_add_outlined, onPressed: () => _edit()),
        ),
        const SizedBox(height: 6),
        Text(
          'ملاحظاتك خاصة ومحفوظة على جهازك فقط.',
          style: TextStyle(color: p.muted, fontSize: 12),
        ),
        const SizedBox(height: 12),
        if (general.isEmpty && cardIds.isEmpty)
          const EmptyBox('لا توجد ملاحظات بعد.', icon: Icons.sticky_note_2_outlined),
        for (final n in general)
          _box(
            context,
            padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _edit(note: n),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (str(n['title']).isNotEmpty)
                          Text(
                            str(n['title']),
                            style: TextStyle(fontWeight: FontWeight.w800, color: p.text),
                          ),
                        Text(
                          str(n['text']),
                          maxLines: 6,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: p.text, height: 1.7),
                        ),
                        Text(
                          arDateTime(intOf(n['at'])),
                          style: TextStyle(color: p.muted, fontSize: 11.5),
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'حذف',
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: () async {
                    final ok = await confirmDialog(context, 'حذف هذه الملاحظة؟', ok: 'حذف', danger: true);
                    if (!ok) return;
                    await LocalData.deleteGeneralNote(str(n['id']));
                    if (mounted) setState(() {});
                  },
                ),
              ],
            ),
          ),
        if (cardIds.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 8),
            child: Text(
              'ملاحظاتي عن عناصر الدليل',
              style: TextStyle(fontWeight: FontWeight.w800, color: p.brandOn),
            ),
          ),
          for (final id in cardIds)
            _box(
              context,
              child: InkWell(
                onTap: () => openDetail(context, id),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.cardById(id)!.name,
                      style: TextStyle(fontWeight: FontWeight.w800, color: p.text),
                    ),
                    Text(
                      cardNotes[id]!.text,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: p.text, height: 1.7),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ],
    );
  }
}
