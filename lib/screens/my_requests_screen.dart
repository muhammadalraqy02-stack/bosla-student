// طلباتي: طلبات التسجيل (مع متابعة الحالة)، اقتراحاتي، تذكيراتي

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../local_data.dart';
import '../ui.dart';
import '../utils.dart';
import '../widgets/common.dart';
import 'detail_screen.dart';
import 'suggest_screen.dart';

class MyRequestsScreen extends StatelessWidget {
  const MyRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: ListenableBuilder(
        listenable: AppState.I,
        builder: (context, _) {
          return Scaffold(
            appBar: brandAppBar(
              context,
              'طلباتي',
              bottom: const TabBar(
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                indicatorColor: Color(0xFFF3D98A),
                labelStyle: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                tabs: [
                  Tab(text: 'طلبات التسجيل'),
                  Tab(text: 'اقتراحاتي'),
                  Tab(text: 'تذكيراتي'),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                _bookings(context),
                _suggestions(context),
                _reminders(context),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _item(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String sub,
    Widget? tag,
    List<Widget> actions = const [],
    VoidCallback? onTap,
  }) {
    final p = Pal.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 6, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: p.soft, borderRadius: BorderRadius.circular(11)),
                  child: Icon(icon, color: p.brandOn, size: 21),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: TextStyle(fontWeight: FontWeight.w800, color: p.text)),
                      if (sub.isNotEmpty)
                        Text(sub, style: TextStyle(color: p.muted, fontSize: 12)),
                      if (tag != null) Padding(padding: const EdgeInsets.only(top: 6), child: tag),
                    ],
                  ),
                ),
                ...actions,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _bookings(BuildContext context) {
    final s = AppState.I;
    final b = s.bookings;
    final ids = b.keys.where((k) => b[k] is Map).toList()
      ..sort((x, y) => intOf((b[y] as Map)['at']).compareTo(intOf((b[x] as Map)['at'])));
    if (ids.isEmpty) {
      return const Center(
        child: EmptyBox(
          'لا توجد طلبات تسجيل بعد.\nافتح أي مدرّس أو معهد واضغط «سجّل الآن».',
          icon: Icons.event_available,
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 90),
      children: [
        for (final id in ids)
          Builder(builder: (ctx) {
            final x = b[id] as Map;
            final cardId = str(x['cardId']);
            final exists = s.cardById(cardId) != null;
            return _item(
              ctx,
              icon: Icons.event_available,
              title: str(x['name']),
              sub: arDateTime(intOf(x['at'])),
              tag: statusTag(str(x['status'])),
              onTap: exists ? () => openDetail(ctx, cardId) : null,
              actions: [
                IconButton(
                  tooltip: 'إلغاء الطلب',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    final ok = await confirmDialog(
                      ctx,
                      'إلغاء هذا الطلب وحذف بياناته؟',
                      ok: 'إلغاء الطلب',
                      cancel: 'تراجع',
                      danger: true,
                    );
                    if (ok) await s.cancelBooking(id);
                  },
                ),
              ],
            );
          }),
      ],
    );
  }

  Widget _suggestions(BuildContext context) {
    final s = AppState.I;
    final mine = s.mySuggestionIds;
    final list = s.data.myRequests.where((r) => mine.contains(r.id)).toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 90),
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: PrimaryButton(
            'اقتراح جديد',
            icon: Icons.add_a_photo_outlined,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SuggestScreen()),
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (list.isEmpty)
          const EmptyBox('لم ترسل اقتراحات من هذا الجهاز.', icon: Icons.lightbulb_outline)
        else
          for (final r in list)
            _item(
              context,
              icon: Icons.photo_camera_outlined,
              title: r.about,
              sub: timeAgo(r.at),
              tag: statusTag(r.read ? 'تم الاطلاع' : 'قيد المراجعة'),
            ),
      ],
    );
  }

  Widget _reminders(BuildContext context) {
    final s = AppState.I;
    final now = DateTime.now().millisecondsSinceEpoch;
    final a = s.reminders
        .where((r) => r['weekly'] is Map || intOf(r['at']) > now - 86400000)
        .toList()
      ..sort((x, y) => intOf(x['at']).compareTo(intOf(y['at'])));
    if (a.isEmpty) {
      return Center(
        child: EmptyBox(
          'لا توجد تذكيرات. أضفها من «أدواتي».',
          icon: Icons.notifications_none,
          action: SoftButton(
            'فتح أدواتي',
            icon: Icons.home_repair_service_outlined,
            onPressed: () => rootTab.value = 3,
          ),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 90),
      children: [
        for (final r in a)
          _item(
            context,
            icon: Icons.notifications_none,
            title: str(r['title']),
            sub: r['weekly'] is Map ? 'أسبوعياً' : arDateTime(intOf(r['at'])),
            actions: [
              IconButton(
                tooltip: 'حذف',
                icon: const Icon(Icons.delete_outline),
                onPressed: () async {
                  final id = str(r['id']);
                  await s.remDel(id);
                  // حذف التذكير يحذف مصدره (درس في الجدول أو عدّ تنازلي) كما في نسخة الويب
                  final sch = LocalData.schedule().where((x) => 's${str(x['id'])}' != id).toList();
                  await LocalData.saveSchedule(sch);
                  final cds = LocalData.countdowns().where((x) => 'c${str(x['id'])}' != id).toList();
                  await LocalData.saveCountdowns(cds);
                  s.refreshUi();
                },
              ),
            ],
          ),
      ],
    );
  }
}
