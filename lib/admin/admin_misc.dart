// شاشات الإدارة الأخرى: الطلبات والاستفسارات، الإشعارات، الإعدادات

import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../ui.dart';
import '../utils.dart';
import '../widgets/common.dart';
import 'admin_store.dart';

// ======================= الطلبات =======================
class AdminRequestsScreen extends StatelessWidget {
  const AdminRequestsScreen({super.key});

  static const Map<String, String> _labels = {
    'name': 'الاسم',
    'phone': 'الهاتف',
    'stage': 'المرحلة',
    'time': 'الوقت المفضل',
    'subject': 'المادة / القسم',
    'note': 'ملاحظات',
    'contact': 'وسيلة التواصل',
    'cat': 'القسم',
    'area': 'المنطقة',
  };

  IconData _icon(String type) {
    if (type == 'اشتراك') return Icons.mail_outline;
    if (type == 'اقتراح إضافة') return Icons.photo_camera_outlined;
    if (type == 'طلب تسجيل') return Icons.event_available_outlined;
    return Icons.forum_outlined;
  }

  Color _statusColor(String s) {
    if (s == 'مقبول') return const Color(0xFF0B6B47);
    if (s == 'مرفوض') return const Color(0xFFB42318);
    if (s == 'تم التواصل') return const Color(0xFF2F6FE4);
    return const Color(0xFFB54708);
  }

  Future<void> _details(BuildContext context, Json r) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${str(r['type'])} · ${str(r['about'])}', style: const TextStyle(fontSize: 16)),
        content: FutureBuilder<(Json?, Uint8List?)>(
          future: AdminStore.I.requestDetails(r),
          builder: (ctx, snap) {
            if (!snap.hasData) {
              return const SizedBox(height: 80, child: Center(child: CircularProgressIndicator()));
            }
            final (priv, img) = snap.data!;
            final rows = <Widget>[];
            if (priv == null || priv.isEmpty) {
              rows.add(const Text('لا توجد بيانات خاصة.'));
            } else {
              _labels.forEach((k, label) {
                final v = str(priv[k]);
                if (v.isEmpty) return;
                rows.add(Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text.rich(TextSpan(children: [
                    TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.w800)),
                    TextSpan(text: v),
                  ])),
                ));
                if (k == 'phone') {
                  rows.add(Wrap(spacing: 8, children: [
                    OutlinedButton.icon(
                      onPressed: () => callPhone(v),
                      icon: const Icon(Icons.call, size: 18),
                      label: const Text('اتصال'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => openUrl('https://wa.me/${normWa(v)}'),
                      icon: const Icon(Icons.chat, size: 18),
                      label: const Text('واتساب'),
                    ),
                  ]));
                }
              });
            }
            if (img != null) {
              rows.add(Padding(
                padding: const EdgeInsets.only(top: 10),
                child: ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.memory(img)),
              ));
            }
            return SingleChildScrollView(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: rows),
            );
          },
        ),
        actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('إغلاق'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AdminStore.I,
      builder: (context, _) {
        final s = AdminStore.I;
        final p = Pal.of(context);
        final list = s.requestList;
        return Scaffold(
          appBar: AppBar(
            title: Text('الطلبات (${fmtNum(list.length)})'),
            actions: [
              IconButton(
                tooltip: 'تعليم الكل كمقروء',
                icon: const Icon(Icons.done_all),
                onPressed: s.unreadRequests == 0
                    ? null
                    : () async {
                        final r = await s.markAllRead();
                        toast(r ?? 'تم التعليم', r == null ? ToastType.ok : ToastType.err);
                      },
              ),
            ],
          ),
          body: list.isEmpty
              ? const EmptyBox('لا توجد طلبات بعد.', icon: Icons.inbox_outlined)
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 30),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final r = list[i];
                    final id = str(r['id']);
                    final type = str(r['type']);
                    final status = str(r['status']);
                    final unread = r['read'] != true;
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: unread ? p.soft : p.card,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: unread ? p.brandOn : p.border, width: unread ? 1.3 : 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(_icon(type), color: p.brandOn, size: 22),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '$type · ${str(r['about'])}',
                                  style: TextStyle(fontWeight: FontWeight.w800, color: p.text),
                                ),
                              ),
                              if (status.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _statusColor(status),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(status,
                                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                                ),
                            ],
                          ),
                          if (str(r['msg']).isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(str(r['msg']), style: TextStyle(color: p.text, height: 1.6, fontSize: 13)),
                          ],
                          const SizedBox(height: 4),
                          Text('${str(r['from'])} · ${timeAgo(str(r['at']))}',
                              style: TextStyle(fontSize: 11, color: p.muted)),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              if (type == 'طلب تسجيل')
                                DropdownButton<String>(
                                  value: kRequestStatuses.contains(status) ? status : kRequestStatuses.first,
                                  underline: const SizedBox.shrink(),
                                  items: [
                                    for (final x in kRequestStatuses) DropdownMenuItem(value: x, child: Text(x)),
                                  ],
                                  onChanged: (v) async {
                                    if (v == null) return;
                                    final e = await s.setRequestStatus(id, v);
                                    toast(e ?? 'حُدّثت حالة الطلب: $v', e == null ? ToastType.ok : ToastType.err);
                                  },
                                ),
                              if (r['photo'] == true || r['priv'] == true)
                                IconButton(
                                  tooltip: 'التفاصيل الخاصة والصورة',
                                  icon: const Icon(Icons.badge_outlined),
                                  onPressed: () => _details(context, r),
                                ),
                              IconButton(
                                tooltip: unread ? 'تعليم كمقروء' : 'تعليم كغير مقروء',
                                icon: Icon(unread ? Icons.drafts_outlined : Icons.mark_email_unread_outlined),
                                onPressed: () async {
                                  final e = await s.toggleRequestRead(id);
                                  if (e != null) toast(e, ToastType.err);
                                },
                              ),
                              IconButton(
                                tooltip: 'حذف',
                                icon: const Icon(Icons.delete_outline, color: Color(0xFFB42318)),
                                onPressed: () async {
                                  final ok = await confirmDialog(context, 'حذف هذا الطلب؟', ok: 'حذف', danger: true);
                                  if (!ok) return;
                                  final e = await s.deleteRequest(id);
                                  toast(e ?? 'تم الحذف', e == null ? ToastType.ok : ToastType.err);
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}

// ======================= الإشعارات =======================
class AdminNotificationsScreen extends StatelessWidget {
  const AdminNotificationsScreen({super.key});

  Future<void> _edit(BuildContext context, [Json? n]) async {
    final t = TextEditingController(text: n == null ? '' : str(n['title']));
    final x = TextEditingController(text: n == null ? '' : str(n['text']));
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(n == null ? 'إشعار جديد' : 'تعديل الإشعار', style: const TextStyle(fontSize: 17)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: t, decoration: fieldDeco(ctx, 'عنوان الإشعار')),
              const SizedBox(height: 10),
              TextField(controller: x, minLines: 3, maxLines: 8, decoration: fieldDeco(ctx, 'نص الإشعار')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('إلغاء')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(n == null ? 'نشر' : 'حفظ', style: const TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
    final title = t.text;
    final text = x.text;
    t.dispose();
    x.dispose();
    if (ok != true) return;
    final r = await AdminStore.I.saveNotification(id: n == null ? null : str(n['id']), title: title, text: text);
    toast(r ?? (n == null ? 'تم نشر الإشعار' : 'تم تعديل الإشعار'), r == null ? ToastType.ok : ToastType.err);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AdminStore.I,
      builder: (context, _) {
        final s = AdminStore.I;
        final p = Pal.of(context);
        final list = s.notificationList;
        return Scaffold(
          appBar: AppBar(title: Text('الإشعارات (${fmtNum(list.length)})')),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _edit(context),
            icon: const Icon(Icons.add),
            label: const Text('إضافة إشعار'),
          ),
          body: list.isEmpty
              ? const EmptyBox('لا توجد إشعارات بعد.', icon: Icons.notifications_none)
              : ListView(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 90),
                  children: [
                    Text(
                      'الإشعارات المنشورة تظهر للزوار في جرس الإشعارات، ويصلهم تنبيه عند فتح التطبيق.',
                      style: TextStyle(fontSize: 12, color: p.muted, height: 1.5),
                    ),
                    const SizedBox(height: 10),
                    for (final n in list)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Material(
                          color: p.card,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(color: p.border),
                          ),
                          child: ListTile(
                            leading: Icon(
                              n['active'] == false ? Icons.notifications_off_outlined : Icons.notifications_outlined,
                              color: n['active'] == false ? p.muted : p.brandOn,
                            ),
                            title: Text(str(n['title']), style: TextStyle(fontWeight: FontWeight.w800, color: p.text)),
                            subtitle: Text(
                              '${str(n['text'])}\n${timeAgo(str(n['at']))} · ${n['active'] == false ? 'مخفي' : 'منشور'}',
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 12, color: p.muted, height: 1.5),
                            ),
                            isThreeLine: true,
                            trailing: PopupMenuButton<String>(
                              onSelected: (v) async {
                                final id = str(n['id']);
                                String? e;
                                if (v == 'edit') {
                                  await _edit(context, n);
                                  return;
                                }
                                if (v == 'toggle') e = await s.toggleNotification(id);
                                if (v == 'del') {
                                  final ok = await confirmDialog(context, 'حذف الإشعار "${str(n['title'])}"؟',
                                      ok: 'حذف', danger: true);
                                  if (!ok) return;
                                  e = await s.deleteNotification(id);
                                }
                                toast(e ?? 'تم', e == null ? ToastType.ok : ToastType.err);
                              },
                              itemBuilder: (_) => [
                                const PopupMenuItem(value: 'edit', child: Text('تعديل')),
                                PopupMenuItem(value: 'toggle', child: Text(n['active'] == false ? 'نشر' : 'إخفاء')),
                                const PopupMenuItem(
                                  value: 'del',
                                  child: Text('حذف', style: TextStyle(color: Color(0xFFB42318))),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
        );
      },
    );
  }
}

// ======================= الإعدادات =======================
class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  static const List<List<String>> _identity = [
    ['siteName', 'اسم المنصة'],
    ['siteSub', 'الوصف الجانبي'],
    ['heroKicker', 'العنوان التمهيدي'],
    ['heroTitleA', 'العنوان (جزء 1)'],
    ['heroTitleB', 'العنوان (جزء 2 - ملون)'],
    ['heroText', 'النص التعريفي'],
    ['footer', 'نص التذييل'],
    ['catsTitle', 'عنوان قسم الأقسام'],
    ['catsSub', 'وصف قسم الأقسام'],
    ['listTitle', 'عنوان قسم النتائج'],
    ['listSub', 'وصف قسم النتائج'],
    ['welcomeTitle', 'عنوان لوحة الترحيب'],
  ];

  final Map<String, TextEditingController> _c = {};
  final _wa = TextEditingController();
  final _about = TextEditingController();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final s = AdminStore.I;
    for (final f in _identity) {
      _c[f[0]] = TextEditingController(text: s.setting(f[0]));
    }
    _wa.text = s.setting('whatsapp');
    _about.text = s.setting('aboutApp');
  }

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    _wa.dispose();
    _about.dispose();
    super.dispose();
  }

  Future<void> _saveIdentity() async {
    final changes = <String, dynamic>{};
    for (final f in _identity) {
      final v = clip(_c[f[0]]!.text, f[0] == 'heroText' ? 1000 : 180);
      if (v != AdminStore.I.setting(f[0])) changes[f[0]] = v;
    }
    if (changes.isEmpty) {
      toast('لا توجد تغييرات');
      return;
    }
    setState(() => _busy = true);
    final r = await AdminStore.I.saveSettings(changes);
    if (mounted) setState(() => _busy = false);
    toast(r ?? 'تم حفظ الإعدادات', r == null ? ToastType.ok : ToastType.err);
  }

  Future<void> _saveDrawer() async {
    final w = digitsOnly(_wa.text);
    if (w.isNotEmpty && (w.length < 10 || w.length > 15)) {
      toast('أدخل رقم واتساب صحيحاً مع رمز الدولة وبدون +', ToastType.warn);
      return;
    }
    setState(() => _busy = true);
    final r = await AdminStore.I.saveSettings(
      {'whatsapp': w, 'aboutApp': clip(_about.text, 3000)},
      log: 'تعديل التواصل والتعريف',
    );
    if (mounted) setState(() => _busy = false);
    toast(r ?? 'تم حفظ بيانات القائمة', r == null ? ToastType.ok : ToastType.err);
  }

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    Widget head(String t) => Padding(
          padding: const EdgeInsets.only(top: 6, bottom: 10),
          child: Text(t, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: p.brandOn)),
        );
    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
        children: [
          head('هوية المنصة'),
          for (final f in _identity)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TextField(
                controller: _c[f[0]],
                minLines: f[0] == 'heroText' ? 3 : 1,
                maxLines: f[0] == 'heroText' ? 8 : 1,
                decoration: fieldDeco(context, f[1]),
              ),
            ),
          PrimaryButton('حفظ الإعدادات', icon: Icons.save_outlined, busy: _busy, onPressed: _saveIdentity),
          const SizedBox(height: 22),
          head('القائمة الجانبية والتواصل'),
          TextField(
            controller: _wa,
            keyboardType: TextInputType.phone,
            textDirection: TextDirection.ltr,
            decoration: fieldDeco(context, 'رقم واتساب الإدارة مع رمز الدولة', hint: 'مثال: 9647XXXXXXXXX'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _about,
            minLines: 4,
            maxLines: 10,
            decoration: fieldDeco(context, 'عن التطبيق'),
          ),
          const SizedBox(height: 12),
          PrimaryButton('حفظ بيانات القائمة', icon: Icons.save_outlined, busy: _busy, onPressed: _saveDrawer),
        ],
      ),
    );
  }
}
