// إشعارات الدليل المنشورة من لوحة الإدارة + تفعيل إشعارات الجهاز

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../notifs.dart';
import '../ui.dart';
import '../utils.dart';
import '../widgets/common.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => AppState.I.markNotificationsRead());
  }

  Future<void> _enable() async {
    final ok = await Notifs.requestPermission();
    if (ok) {
      toast('تم تفعيل الإشعارات');
    } else {
      toast(
        'الإشعارات مرفوضة — يمكنك تفعيلها من إعدادات الجهاز ‹ ${AppState.I.settings.siteName}',
        ToastType.warn,
      );
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.I,
      builder: (context, _) {
        final s = AppState.I;
        final p = Pal.of(context);
        final list = s.publishedNotifications;
        final pref = Notifs.pref;

        Widget bar;
        if (pref == 'on') {
          bar = Row(
            children: [
              const Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text('إشعارات الجهاز مفعّلة', style: TextStyle(color: p.text))),
            ],
          );
        } else if (pref == 'off') {
          bar = Row(
            children: [
              Icon(Icons.notifications_off_outlined, color: p.muted, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'الإشعارات متوقفة — فعّلها من إعدادات الجهاز',
                  style: TextStyle(color: p.text),
                ),
              ),
              TextButton(onPressed: _enable, child: const Text('إعادة المحاولة')),
            ],
          );
        } else {
          bar = Row(
            children: [
              Expanded(
                child: Text(
                  'استلم إشعاراً عند نشر إعلان أو تحديث جديد',
                  style: TextStyle(color: p.text),
                ),
              ),
              const SizedBox(width: 8),
              PrimaryButton('تفعيل', onPressed: _enable),
            ],
          );
        }

        return Scaffold(
          appBar: brandAppBar(context, 'الإشعارات'),
          body: RefreshIndicator(
            onRefresh: s.refreshAll,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
              children: [
                NoteBox(child: bar),
                if (list.isEmpty)
                  const EmptyBox(
                    'لا توجد إشعارات حالياً.',
                    icon: Icons.notifications_off_outlined,
                  )
                else
                  for (final n in list)
                    Container(
                      margin: const EdgeInsets.only(top: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: p.card,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: p.border),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: p.soft,
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: Icon(Icons.campaign, color: p.brandOn, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  n.title,
                                  style: TextStyle(fontWeight: FontWeight.w800, color: p.text),
                                ),
                                if (n.text.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 3),
                                    child: Text(
                                      n.text,
                                      style: TextStyle(color: p.text.withAlpha(215), height: 1.7),
                                    ),
                                  ),
                                const SizedBox(height: 4),
                                Text(
                                  timeAgo(n.at),
                                  style: TextStyle(color: p.muted, fontSize: 11.5),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
              ],
            ),
          ),
        );
      },
    );
  }
}
