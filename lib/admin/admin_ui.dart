// أدوات واجهة مشتركة لشاشات الإدارة

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../ui.dart';
import '../widgets/common.dart';
import 'admin_store.dart';

/// للحساب التجريبي: يعرض تنبيهاً ويعيد true لإيقاف أي إجراء يغيّر البيانات
bool demoBlocked() {
  if (!AdminStore.I.isDemo) return false;
  toast(AdminStore.demoMsg, ToastType.warn);
  return true;
}

Color hexColor(String h, [Color fallback = const Color(0xFF64748B)]) {
  var s = h.trim().replaceFirst('#', '');
  if (s.length == 3) s = s.split('').map((c) => '$c$c').join();
  if (s.length != 6) return fallback;
  final v = int.tryParse(s, radix: 16);
  return v == null ? fallback : Color(0xFF000000 | v);
}

String colorHex(Color c) {
  final v = c.toARGB32() & 0xFFFFFF;
  return '#${v.toRadixString(16).padLeft(6, '0').toUpperCase()}';
}

/// نافذة إدخال نص (بديل prompt في نسخة الويب)
Future<String?> promptText(
  BuildContext context,
  String title, {
  String initial = '',
  String hint = '',
  int lines = 1,
  TextInputType? type,
  bool ltr = false,
}) async {
  final c = TextEditingController(text: initial);
  final r = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title, style: const TextStyle(fontSize: 16)),
      content: TextField(
        controller: c,
        autofocus: true,
        minLines: lines,
        maxLines: lines == 1 ? 1 : lines + 6,
        keyboardType: type,
        textDirection: ltr ? TextDirection.ltr : null,
        decoration: fieldDeco(ctx, hint.isEmpty ? title : hint),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('إلغاء')),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(c.text),
          child: const Text('حفظ', style: TextStyle(fontWeight: FontWeight.w800)),
        ),
      ],
    ),
  );
  c.dispose();
  return r;
}

/// تأكيد بكتابة عبارة محددة (للعمليات الخطرة)
Future<bool> confirmTyped(BuildContext context, String message, String phrase) async {
  if (demoBlocked()) return false;
  final ok = await confirmDialog(context, message, ok: 'متابعة', danger: true);
  if (!ok || !context.mounted) return false;
  final t = await promptText(context, 'للتأكيد اكتب: $phrase');
  if (t == null) return false;
  if (t.trim() != phrase) {
    toast('تم الإلغاء', ToastType.warn);
    return false;
  }
  return true;
}

void showResult(String? err, String okMsg) {
  toast(err ?? okMsg, err == null ? ToastType.ok : ToastType.err);
}

const List<String> _swatches = [
  '#10275E', '#7C3AED', '#2F6FE4', '#0EA5E9', '#0F9D6E', '#12A05F', '#F0A31B', '#F2711C',
  '#EF4444', '#DB2777', '#5B5BD6', '#64748B', '#F2ECFF', '#E9F1FE', '#FEF5E4', '#E7F7F1',
  '#FEEDE3', '#FEECEF', '#EEF1FE', '#E3F8ED', '#E8F4FF', '#FFF1F7', '#EEF2F8', '#FFFFFF',
];

/// اختيار لون (بديل input type=color)
Future<String?> pickColor(BuildContext context, String current, {String title = 'اختر اللون'}) async {
  final hex = TextEditingController(text: current);
  final r = await showDialog<String>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSt) => AlertDialog(
        title: Text(title, style: const TextStyle(fontSize: 16)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final s in _swatches)
                    InkWell(
                      onTap: () => setSt(() => hex.text = s),
                      customBorder: const CircleBorder(),
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: hexColor(s),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: hex.text.toUpperCase() == s ? Colors.black : const Color(0x33000000),
                            width: hex.text.toUpperCase() == s ? 3 : 1,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: hexColor(hex.text, Colors.transparent),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0x33000000)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: hex,
                      textDirection: TextDirection.ltr,
                      onChanged: (_) => setSt(() {}),
                      decoration: fieldDeco(ctx, 'رمز اللون', hint: '#RRGGBB'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('إلغاء')),
          TextButton(
            onPressed: () {
              final v = hex.text.trim();
              if (!RegExp(r'^#?[0-9A-Fa-f]{6}$').hasMatch(v)) {
                toast('أدخل لوناً بصيغة #RRGGBB', ToastType.warn);
                return;
              }
              Navigator.of(ctx).pop(v.startsWith('#') ? v.toUpperCase() : '#${v.toUpperCase()}');
            },
            child: const Text('اختيار', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    ),
  );
  hex.dispose();
  return r;
}

/// اختيار صورة من المعرض أو الكاميرا
Future<XFile?> pickImageFile(BuildContext context, {double maxW = 1600, double maxH = 1600, int quality = 72}) async {
  if (demoBlocked()) return null;
  final src = await showModalBottomSheet<ImageSource>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('من المعرض'),
            onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
          ),
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: const Text('من الكاميرا'),
            onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
          ),
        ],
      ),
    ),
  );
  if (src == null) return null;
  return ImagePicker().pickImage(source: src, maxWidth: maxW, maxHeight: maxH, imageQuality: quality);
}

/// لوحة بإطار — مثل content-panel في نسخة الويب
class AdminPanel extends StatelessWidget {
  final String title;
  final String note;
  final Widget? trailing;
  final List<Widget> children;
  const AdminPanel({super.key, required this.title, this.note = '', this.trailing, required this.children});

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: p.text)),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          if (note.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(note, style: TextStyle(fontSize: 11.5, color: p.muted, height: 1.6)),
          ],
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

/// زر صغير بأيقونة ونص
class MiniAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool danger;
  const MiniAction(this.icon, this.label, this.onTap, {super.key, this.danger = false});

  @override
  Widget build(BuildContext context) {
    final color = danger ? const Color(0xFFB42318) : Pal.of(context).brandOn;
    return OutlinedButton.icon(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        visualDensity: VisualDensity.compact,
        side: BorderSide(color: color.withValues(alpha: 0.4)),
      ),
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }
}
