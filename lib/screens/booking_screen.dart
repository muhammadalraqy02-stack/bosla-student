// طلب تسجيل / حجز مقعد — تُحفظ بيانات الطالب في عقدة خاصة (requestsPrivate) منفصلة عن الدليل العام

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../ui.dart';
import '../utils.dart';
import '../widgets/common.dart';
import 'legal_screen.dart';

class BookingScreen extends StatefulWidget {
  final String cardId;
  const BookingScreen({super.key, required this.cardId});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _subject = TextEditingController();
  final TextEditingController _note = TextEditingController();
  String _stage = 'إعدادي';
  String _time = 'أي وقت';
  bool _age = false;
  bool _busy = false;
  bool _done = false;

  static const List<String> _stages = ['ابتدائي', 'متوسط', 'إعدادي', 'جامعي', 'أخرى'];
  static const List<String> _times = ['أي وقت', 'صباحاً', 'عصراً', 'مساءً'];

  @override
  void initState() {
    super.initState();
    _subject.text = AppState.I.cardById(widget.cardId)?.specialty ?? '';
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _subject.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final c = AppState.I.cardById(widget.cardId);
    if (c == null) return;
    final name = clip(_name.text, 80);
    final phone = telClean(clip(_phone.text, 20));
    if (name.length < 2) {
      toast('أدخل اسم الطالب', ToastType.warn);
      return;
    }
    if (phone.length < 7) {
      toast('أدخل رقم هاتف صحيح', ToastType.warn);
      return;
    }
    if (!_age) {
      toast('يرجى تأكيد العمر أو موافقة ولي الأمر', ToastType.warn);
      return;
    }
    setState(() => _busy = true);
    final err = await AppState.I.submitBooking(
      card: c,
      name: name,
      phone: phone,
      stage: _stage,
      time: _time,
      subject: clip(_subject.text, 80),
      note: clip(_note.text, 400),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (err != null) {
      toast(err, ToastType.err);
      return;
    }
    setState(() => _done = true);
    // نطلب إذن الإشعارات هنا لإبلاغ المستخدم عند تغيّر حالة طلبه
    AppState.I.ensureNotifPermission();
  }

  Widget _select(String label, String value, List<String> items, ValueChanged<String> onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      decoration: fieldDeco(context, label),
      items: [for (final it in items) DropdownMenuItem(value: it, child: Text(it))],
      onChanged: (v) => onChanged(v ?? value),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppState.I;
    final p = Pal.of(context);
    final c = s.cardById(widget.cardId);
    if (c == null) {
      return Scaffold(
        appBar: brandAppBar(context, 'طلب تسجيل'),
        body: const Center(child: EmptyBox('هذا العنصر لم يعد متوفراً')),
      );
    }
    final teacher = c.isTeacher;

    if (_done) {
      return Scaffold(
        appBar: brandAppBar(context, 'تم إرسال طلبك'),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, size: 64, color: Color(0xFF16A34A)),
                const SizedBox(height: 14),
                Text(
                  'وصل طلبك إلى «${c.name}»',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: p.text),
                ),
                const SizedBox(height: 8),
                Text(
                  'سنبلغك عند تغيّر حالة الطلب. يمكنك متابعته من «طلباتي».',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: p.muted, height: 1.8),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: PrimaryButton(
                        'عرض طلباتي',
                        icon: Icons.assignment_outlined,
                        onPressed: () {
                          rootTab.value = 2;
                          AppState.I.markBookingsSeen();
                          Navigator.of(context).popUntil((r) => r.isFirst);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    SoftButton('إغلاق', onPressed: () => Navigator.of(context).pop()),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: brandAppBar(context, teacher ? 'احجز مقعداً' : 'طلب تسجيل'),
      body: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: [
          Text(
            (teacher ? 'احجز مقعداً عند ' : 'طلب تسجيل في ') + c.name,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: p.text),
          ),
          const SizedBox(height: 6),
          Text(
            'املأ النموذج وسيتواصل معك فريق التطبيق بالتنسيق مع ${s.catOne(c.key)} لتأكيد التسجيل. تابع حالة طلبك من «طلباتي».',
            style: TextStyle(color: p.muted, height: 1.8, fontSize: 13),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _name,
            maxLength: 80,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.name],
            decoration: fieldDeco(context, 'اسم الطالب', icon: Icons.person_outline),
          ),
          TextField(
            controller: _phone,
            maxLength: 20,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.telephoneNumber],
            decoration: fieldDeco(
              context,
              'رقم الهاتف للتواصل (الطالب أو ولي الأمر)',
              hint: '07XXXXXXXXX',
              icon: Icons.phone_outlined,
            ),
          ),
          Row(
            children: [
              Expanded(child: _select('المرحلة', _stage, _stages, (v) => setState(() => _stage = v))),
              const SizedBox(width: 10),
              Expanded(
                child: _select('الوقت المفضل', _time, _times, (v) => setState(() => _time = v)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _subject,
            maxLength: 80,
            textInputAction: TextInputAction.next,
            decoration: fieldDeco(context, teacher ? 'المادة' : 'القسم / التخصص المطلوب'),
          ),
          TextField(
            controller: _note,
            maxLength: 400,
            minLines: 3,
            maxLines: 5,
            decoration: fieldDeco(
              context,
              'ملاحظات (اختياري)',
              hint: 'مثال: أفضّل دروساً جماعية، أو أحتاج دورة تقوية',
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(value: _age, onChanged: (v) => setState(() => _age = v == true)),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: InkWell(
                    onTap: () => openLegal(context, 'privacy'),
                    child: Text(
                      'عمري 13 سنة أو أكثر، أو أقدّم الطلب بموافقة ولي أمري، وأوافق على سياسة الخصوصية. (اضغط لقراءتها)',
                      style: TextStyle(color: p.text, fontSize: 12.5, height: 1.7),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          PrimaryButton('إرسال الطلب', icon: Icons.send, busy: _busy, onPressed: _submit),
        ],
      ),
    );
  }
}
