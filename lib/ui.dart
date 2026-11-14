// أدوات واجهة مشتركة: التنبيهات السريعة (toast)، البانر، فتح الروابط، المشاركة، مربعات التأكيد

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

final GlobalKey<ScaffoldMessengerState> messengerKey = GlobalKey<ScaffoldMessengerState>();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// التبويب الحالي في الشريط السفلي (0 الرئيسية · 1 المفضلة · 2 طلباتي · 3 أدواتي · 4 المزيد)
final ValueNotifier<int> rootTab = ValueNotifier<int>(0);

enum ToastType { ok, warn, err }

void toast(String msg, [ToastType type = ToastType.ok]) {
  final m = messengerKey.currentState;
  if (m == null) return;
  final Color bg;
  final IconData icon;
  switch (type) {
    case ToastType.err:
      bg = const Color(0xFFB42318);
      icon = Icons.error_outline;
      break;
    case ToastType.warn:
      bg = const Color(0xFFB54708);
      icon = Icons.warning_amber_rounded;
      break;
    case ToastType.ok:
      bg = const Color(0xFF0B6B47);
      icon = Icons.check_circle_outline;
      break;
  }
  m.hideCurrentSnackBar();
  m.showSnackBar(SnackBar(
    behavior: SnackBarBehavior.floating,
    backgroundColor: bg,
    duration: const Duration(milliseconds: 2600),
    content: Row(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(msg, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        ),
      ],
    ),
  ));
}

/// بانر داخل التطبيق (إشعار جديد، تحديث حالة طلب، تذكير)
void showBanner(String title, String text) {
  final m = messengerKey.currentState;
  if (m == null) return;
  m.hideCurrentSnackBar();
  m.showSnackBar(SnackBar(
    behavior: SnackBarBehavior.floating,
    backgroundColor: const Color(0xFF10275E),
    duration: const Duration(seconds: 6),
    content: Row(
      children: [
        const Icon(Icons.notifications_active, color: Color(0xFFF3D98A)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
              if (text.isNotEmpty)
                Text(
                  text,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
            ],
          ),
        ),
      ],
    ),
  ));
}

Future<bool> openUrl(String url) async {
  if (url.isEmpty) return false;
  try {
    final uri = Uri.parse(url);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) toast('تعذّر فتح الرابط', ToastType.warn);
    return ok;
  } catch (_) {
    toast('تعذّر فتح الرابط', ToastType.warn);
    return false;
  }
}

Future<void> callPhone(String phone) async {
  final n = phone.replaceAll(RegExp(r'[^\d+]'), '');
  if (n.isEmpty) return;
  await openUrl('tel:$n');
}

/// المشاركة عبر ورقة النظام. على iPad يجب تحديد موضع النافذة المنبثقة وإلا يتعطل التطبيق.
Future<void> shareText(BuildContext context, String text, {String? subject}) async {
  Rect? origin;
  try {
    final box = context.findRenderObject();
    if (box is RenderBox && box.hasSize) {
      origin = box.localToGlobal(Offset.zero) & box.size;
    }
  } catch (_) {}
  origin ??= const Rect.fromLTWH(0, 0, 100, 100);
  try {
    await Share.share(text, subject: subject, sharePositionOrigin: origin);
  } catch (_) {
    toast('تعذّرت المشاركة', ToastType.warn);
  }
}

Future<bool> confirmDialog(
  BuildContext context,
  String message, {
  String ok = 'تأكيد',
  String cancel = 'إلغاء',
  bool danger = false,
}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      content: Text(message, style: const TextStyle(height: 1.7)),
      actions: [
        TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(cancel)),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(
            ok,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: danger ? const Color(0xFFB42318) : null,
            ),
          ),
        ),
      ],
    ),
  );
  return r == true;
}

/// زخرفة موحّدة لحقول الإدخال
InputDecoration fieldDeco(BuildContext context, String label, {String? hint, IconData? icon}) {
  final dark = Theme.of(context).brightness == Brightness.dark;
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: dark ? const Color(0xFF2A3A58) : const Color(0xFFDCE1EA)),
  );
  return InputDecoration(
    labelText: label,
    hintText: hint,
    prefixIcon: icon == null ? null : Icon(icon, size: 20),
    filled: true,
    fillColor: dark ? const Color(0xFF17233B) : const Color(0xFFF8FAFD),
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: border,
    enabledBorder: border,
    focusedBorder: border.copyWith(
      borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.6),
    ),
  );
}
