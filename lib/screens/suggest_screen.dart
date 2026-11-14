// اقترح إضافة إلى الدليل (مع صورة اختيارية من الكاميرا أو الصور)
// لا يُطلب إذن الكاميرا/الصور إلا عند ضغط أحد الزرين.

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../app_state.dart';
import '../config.dart';
import '../ui.dart';
import '../utils.dart';
import '../widgets/common.dart';
import 'legal_screen.dart';

class SuggestScreen extends StatefulWidget {
  const SuggestScreen({super.key});

  @override
  State<SuggestScreen> createState() => _SuggestScreenState();
}

class _SuggestScreenState extends State<SuggestScreen> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _contact = TextEditingController();
  final TextEditingController _note = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  String _cat = '';
  String _area = '';
  Uint8List? _photo;
  bool _age = false;
  bool _busy = false;
  bool _picking = false;

  @override
  void initState() {
    super.initState();
    final cats = AppState.I.data.categories;
    _cat = cats.isNotEmpty ? cats.first.name : 'أخرى';
  }

  @override
  void dispose() {
    _name.dispose();
    _contact.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pick(bool camera) async {
    if (_picking) return;
    setState(() => _picking = true);
    try {
      final x = await _picker.pickImage(
        source: camera ? ImageSource.camera : ImageSource.gallery,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 72,
      );
      if (x != null) {
        final bytes = await x.readAsBytes();
        if (bytes.length > 900 * 1024) {
          toast('الصورة كبيرة جداً — اختر صورة أخرى', ToastType.warn);
        } else if (mounted) {
          setState(() => _photo = bytes);
        }
      }
    } catch (_) {
      toast(
        camera
            ? 'تعذّر فتح الكاميرا — تحقق من الإذن في إعدادات الجهاز'
            : 'تعذّر قراءة الصورة — تحقق من الإذن في إعدادات الجهاز',
        ToastType.err,
      );
    }
    if (mounted) setState(() => _picking = false);
  }

  Future<void> _submit() async {
    final name = clip(_name.text, 120);
    if (name.length < 2) {
      toast('أدخل الاسم', ToastType.warn);
      return;
    }
    if (!_age) {
      toast('يرجى تأكيد العمر أو موافقة ولي الأمر', ToastType.warn);
      return;
    }
    setState(() => _busy = true);
    final err = await AppState.I.submitSuggestion(
      name: name,
      cat: _cat,
      area: _area,
      contact: clip(_contact.text, 120),
      note: clip(_note.text, 800),
      photoJpeg: _photo,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (err != null) {
      toast(err, ToastType.err);
      return;
    }
    toast('شكراً لك! وصل اقتراحك وسيُراجع قبل النشر');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    final cats = [...AppState.I.data.categories.map((c) => c.name), 'أخرى'];
    if (!cats.contains(_cat)) _cat = cats.first;
    final areas = ['', ...Cfg.maysanAreas, 'أخرى'];
    final photo = _photo;

    return Scaffold(
      appBar: brandAppBar(context, 'اقترح إضافة إلى الدليل'),
      body: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: [
          Text(
            'هل تعرف مدرسة أو معهداً أو جامعة أو مدرساً غير موجود في الدليل؟ صوّر واجهة المكان أو لوحته وأرسله لنا، وسيراجعه فريق التطبيق قبل إضافته.',
            style: TextStyle(color: p.muted, height: 1.8, fontSize: 13),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _cat,
            isExpanded: true,
            decoration: fieldDeco(context, 'القسم'),
            items: [for (final c in cats) DropdownMenuItem(value: c, child: Text(c))],
            onChanged: (v) => setState(() => _cat = v ?? _cat),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _name,
            maxLength: 120,
            textInputAction: TextInputAction.next,
            decoration: fieldDeco(context, 'الاسم', hint: 'مثال: معهد النور الأهلي'),
          ),
          DropdownButtonFormField<String>(
            value: _area,
            isExpanded: true,
            decoration: fieldDeco(context, 'المنطقة'),
            items: [
              for (final a in areas)
                DropdownMenuItem(value: a, child: Text(a.isEmpty ? 'اختر المنطقة' : a)),
            ],
            onChanged: (v) => setState(() => _area = v ?? ''),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _contact,
            maxLength: 120,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            decoration: fieldDeco(
              context,
              'وسيلة تواصل معك (اختياري)',
              hint: 'رقم هاتف — لنسألك عند الحاجة فقط',
            ),
          ),
          TextField(
            controller: _note,
            maxLength: 800,
            minLines: 3,
            maxLines: 6,
            decoration: fieldDeco(
              context,
              'ملاحظات (اختياري)',
              hint: 'العنوان التفصيلي، التخصص، أوقات الدوام...',
            ),
          ),
          Text('صورة (اختياري)', style: TextStyle(fontWeight: FontWeight.w800, color: p.text)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              SoftButton('التقاط بالكاميرا', icon: Icons.photo_camera_outlined, onPressed: () => _pick(true)),
              SoftButton('اختيار من الصور', icon: Icons.photo_library_outlined, onPressed: () => _pick(false)),
              if (photo != null)
                SoftButton(
                  'إزالة',
                  icon: Icons.delete_outline,
                  color: const Color(0xFFB42318),
                  onPressed: () => setState(() => _photo = null),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            height: 190,
            decoration: BoxDecoration(
              color: p.soft,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: p.border),
            ),
            clipBehavior: Clip.antiAlias,
            alignment: Alignment.center,
            child: photo != null
                ? Image.memory(photo, fit: BoxFit.contain, gaplessPlayback: true)
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.image_outlined, size: 32, color: p.muted),
                      const SizedBox(height: 6),
                      Text(
                        _picking ? 'جاري تجهيز الصورة...' : 'لم تُضف صورة',
                        style: TextStyle(color: p.muted),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 8),
          Text(
            'لا يصل التطبيق إلى الكاميرا أو الصور إلا عند ضغطك أحد الزرين. تُصغَّر الصورة على جهازك قبل الإرسال، ولا تُنشر للعامة.',
            style: TextStyle(color: p.muted, fontSize: 12, height: 1.7),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(value: _age, onChanged: (v) => setState(() => _age = v == true)),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'عمري 13 سنة أو أكثر، أو أرسل بموافقة ولي أمري، وقرأت سياسة الخصوصية وسياسة الأطفال.',
                        style: TextStyle(color: p.text, fontSize: 12.5, height: 1.7),
                      ),
                      Wrap(
                        spacing: 4,
                        children: [
                          TextButton(
                            onPressed: () => openLegal(context, 'privacy'),
                            child: const Text('سياسة الخصوصية'),
                          ),
                          TextButton(
                            onPressed: () => openLegal(context, 'children'),
                            child: const Text('سياسة الأطفال'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          PrimaryButton('إرسال الاقتراح', icon: Icons.send, busy: _busy, onPressed: _submit),
        ],
      ),
    );
  }
}
