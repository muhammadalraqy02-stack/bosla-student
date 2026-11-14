// الإحصائيات ولوحة المعلومات، المستخدمون، مكتبة الوسائط، سجل النشاطات، قواعد البيانات، جدول المحتوى

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config.dart';
import '../ui.dart';
import '../utils.dart';
import '../widgets/app_image.dart';
import '../widgets/common.dart';
import 'admin_cards.dart';
import 'admin_charts.dart';
import 'admin_store.dart';
import 'admin_ui.dart';

// ======================= عناصر لوحة المعلومات =======================
class AdminDashboardWidgets extends StatefulWidget {
  const AdminDashboardWidgets({super.key});

  @override
  State<AdminDashboardWidgets> createState() => _AdminDashboardWidgetsState();
}

class _AdminDashboardWidgetsState extends State<AdminDashboardWidgets> {
  int _months = 6;
  bool _requests = false;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(listenable: AdminStore.I, builder: (context, _) => _build(context));
  }

  Widget _build(BuildContext context) {
    final s = AdminStore.I;
    final p = Pal.of(context);
    final n = s.dashNumbers();
    final cats = s.categoryList;
    final (labels, vals) = s.chartSeries(_months, _requests);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // أرقام الأقسام (KPIs)
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 2.1,
          children: [
            for (final c in cats)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: p.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: p.border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: hexColor(s.tintOf(c)[0]),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(iconFromFa(str(c['icon'])), color: hexColor(s.tintOf(c)[1]), size: 20),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(fmtNum(n[str(c['key'])] ?? 0),
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: p.text)),
                          Text('إجمالي ${str(c['name'])}',
                              maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10.5, color: p.muted)),
                          Text('${s.countAll(str(c['key']))} عنصر مسجّل',
                              style: const TextStyle(fontSize: 10, color: Color(0xFF12A05F))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        AdminPanel(
          title: 'إضافة سريعة',
          children: [
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final c in cats)
                  ActionChip(
                    backgroundColor: hexColor(s.tintOf(c)[0]),
                    label: Text('+ إضافة ${str(c['one'])} جديد',
                        style: TextStyle(color: hexColor(s.tintOf(c)[1]), fontWeight: FontWeight.w700, fontSize: 12)),
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => AdminCardEditor(catKey: str(c['key'])),
                    )),
                  ),
              ],
            ),
          ],
        ),
        AdminPanel(
          title: 'توزيع المحتوى',
          children: [
            DonutChart(parts: [
              for (final c in cats)
                DonutPart(str(c['name']), n[str(c['key'])] ?? 0, hexColor(s.tintOf(c)[1])),
            ]),
          ],
        ),
        AdminPanel(
          title: 'إحصائيات ${_requests ? 'الطلبات' : 'العناصر'}',
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<bool>(
                value: _requests,
                underline: const SizedBox.shrink(),
                items: const [
                  DropdownMenuItem(value: false, child: Text('العناصر', style: TextStyle(fontSize: 12))),
                  DropdownMenuItem(value: true, child: Text('الطلبات', style: TextStyle(fontSize: 12))),
                ],
                onChanged: (v) => setState(() => _requests = v ?? false),
              ),
              const SizedBox(width: 6),
              DropdownButton<int>(
                value: _months,
                underline: const SizedBox.shrink(),
                items: const [
                  DropdownMenuItem(value: 3, child: Text('3 أشهر', style: TextStyle(fontSize: 12))),
                  DropdownMenuItem(value: 6, child: Text('6 أشهر', style: TextStyle(fontSize: 12))),
                  DropdownMenuItem(value: 12, child: Text('12 شهراً', style: TextStyle(fontSize: 12))),
                ],
                onChanged: (v) => setState(() => _months = v ?? 6),
              ),
            ],
          ),
          children: [
            LineChart(labels: labels, values: vals, metricLabel: _requests ? 'الطلبات' : 'العناصر'),
          ],
        ),
        AdminPanel(
          title: 'نظرة عامة',
          children: [
            for (final (label, v) in s.overview())
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(child: Text(label, style: TextStyle(color: p.text, fontSize: 13))),
                    Text(fmtNum(v), style: TextStyle(fontWeight: FontWeight.w800, color: p.text)),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}

// ======================= الإحصائيات =======================
class AdminStatsScreen extends StatefulWidget {
  const AdminStatsScreen({super.key});

  @override
  State<AdminStatsScreen> createState() => _AdminStatsScreenState();
}

class _AdminStatsScreenState extends State<AdminStatsScreen> {
  final Map<String, TextEditingController> _c = {};

  TextEditingController _ctrl(String k) =>
      _c.putIfAbsent(k, () => TextEditingController(text: str(AdminStore.I.stats[k] ?? '0')));

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AdminStore.I,
      builder: (context, _) {
        final s = AdminStore.I;
        final p = Pal.of(context);
        final comp = s.computedStats();
        final cats = s.categoryList;
        final total = comp.values.fold<int>(0, (a, b) => a + b);
        return Scaffold(
          appBar: AppBar(title: const Text('الإحصائيات')),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 30),
            children: [
              AdminPanel(
                title: 'أرقام الواجهة الرئيسية',
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('حساب الأرقام تلقائياً من المحتوى المنشور'),
                    value: s.autoStats,
                    onChanged: (v) async => showResult(await s.setAutoStats(v), 'تم التحديث'),
                  ),
                  for (final c in cats)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: s.autoStats
                          ? InputDecorator(
                              decoration: fieldDeco(context, str(c['name'])),
                              child: Text(fmtNum(comp[str(c['key'])] ?? 0)),
                            )
                          : TextField(
                              controller: _ctrl(str(c['key'])),
                              decoration: fieldDeco(context, str(c['name']), hint: 'مثال: 120 أو 1.5k'),
                            ),
                    ),
                  if (!s.autoStats)
                    PrimaryButton('حفظ الأرقام', icon: Icons.save_outlined, onPressed: () async {
                      showResult(
                        await s.saveStats({for (final c in cats) str(c['key']): _ctrl(str(c['key'])).text.trim()}),
                        'تم حفظ الأرقام',
                      );
                    }),
                ],
              ),
              AdminPanel(
                title: 'توزيع المحتوى الفعلي',
                children: [
                  for (final c in cats)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(
                        children: [
                          SizedBox(width: 90, child: Text(str(c['name']), style: TextStyle(fontSize: 12, color: p.text))),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                minHeight: 10,
                                value: total == 0 ? 0.0 : (comp[str(c['key'])] ?? 0) / total,
                                backgroundColor: p.soft,
                                color: hexColor(s.tintOf(c)[1]),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('${comp[str(c['key'])] ?? 0}', style: TextStyle(fontWeight: FontWeight.w800, color: p.text)),
                        ],
                      ),
                    ),
                ],
              ),
              AdminPanel(
                title: 'عدادات الزيارات',
                children: [
                  for (final (label, v) in s.overview())
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        children: [
                          Expanded(child: Text(label, style: TextStyle(color: p.text))),
                          Text(fmtNum(v), style: TextStyle(fontWeight: FontWeight.w800, color: p.text)),
                        ],
                      ),
                    ),
                  const SizedBox(height: 8),
                  MiniAction(Icons.speed, 'تصفير عدادات الزيارات', () async {
                    final ok = await confirmDialog(context, 'تصفير عدادات الزيارات والبحث والمستخدمين الجدد؟',
                        ok: 'تصفير', danger: true);
                    if (!ok) return;
                    showResult(await s.resetCounters(), 'تم التصفير');
                  }, danger: true),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// ======================= المستخدمون =======================
class AdminUsersScreen extends StatelessWidget {
  const AdminUsersScreen({super.key});

  Future<void> _add(BuildContext context) async {
    final u = await promptText(context, 'اسم المستخدم الجديد', ltr: true);
    if (u == null || u.trim().isEmpty || !context.mounted) return;
    final pw = await promptText(context, 'كلمة المرور', hint: '10 أحرف على الأقل مع حروف وأرقام', ltr: true);
    if (pw == null || pw.isEmpty || !context.mounted) return;
    final role = await promptText(context, 'الدور', initial: 'مشرف');
    showResult(await AdminStore.I.addUser(u, pw, role ?? 'مشرف'), 'تمت الإضافة');
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AdminStore.I,
      builder: (context, _) {
        final s = AdminStore.I;
        final p = Pal.of(context);
        final keys = s.users.keys.toList()..sort();
        return Scaffold(
          appBar: AppBar(title: Text('حسابات الإدارة: ${keys.length}')),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _add(context),
            icon: const Icon(Icons.person_add_alt),
            label: const Text('إضافة مستخدم'),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 90),
            children: [
              for (final k in keys)
                Card(
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(
                      '${str(s.users[k]!['user'])}${str(s.users[k]!['user']) == s.currentUser ? ' (أنت)' : ''}',
                      style: TextStyle(fontWeight: FontWeight.w800, color: p.text),
                    ),
                    subtitle: Text('${str(s.users[k]!['role'])} · ${str(s.users[k]!['created'])}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'تغيير كلمة المرور',
                          icon: const Icon(Icons.key),
                          onPressed: () async {
                            final pw = await promptText(context, 'كلمة المرور الجديدة لـ ${str(s.users[k]!['user'])}',
                                ltr: true);
                            if (pw == null || pw.isEmpty) return;
                            showResult(await s.changeUserPassword(k, pw), 'تم تغيير كلمة المرور');
                          },
                        ),
                        IconButton(
                          tooltip: 'حذف',
                          icon: const Icon(Icons.delete_outline, color: Color(0xFFB42318)),
                          onPressed: () async {
                            final ok = await confirmDialog(context, 'حذف المستخدم ${str(s.users[k]!['user'])}؟',
                                ok: 'حذف', danger: true);
                            if (!ok) return;
                            showResult(await s.deleteUser(k), 'تم الحذف');
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                'تنبيه: هذا تحقّق من جهة التطبيق فقط وليس حماية حقيقية. للحماية الفعلية يلزم ربط Firebase Authentication.',
                style: TextStyle(fontSize: 11, color: p.muted),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ======================= مكتبة الوسائط =======================
class AdminMediaScreen extends StatefulWidget {
  const AdminMediaScreen({super.key});

  @override
  State<AdminMediaScreen> createState() => _AdminMediaScreenState();
}

class _AdminMediaScreenState extends State<AdminMediaScreen> {
  int _legacy = 0;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    AdminStore.I.loadMediaIndex(force: true);
    AdminStore.I.legacyMediaCount().then((v) {
      if (mounted) setState(() => _legacy = v);
    });
  }

  Future<void> _upload() async {
    final x = await pickImageFile(context);
    if (x == null) return;
    setState(() => _busy = true);
    try {
      await AdminStore.I.uploadImage(await x.readAsBytes(), x.name);
      AdminStore.I.changed();
      toast('تم رفع الصورة');
    } catch (_) {
      toast('تعذّر رفع الصورة — تحقق من الاتصال وإعدادات Supabase', ToastType.err);
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _asBg(String ref) async {
    final key = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final b in kBgKeys)
              ListTile(title: Text(b[1]), onTap: () => Navigator.of(ctx).pop(b[0])),
          ],
        ),
      ),
    );
    if (key == null) return;
    showResult(await AdminStore.I.setSettingImage(key, ref), 'تم التعيين وحفظ الرابط في فايربيس');
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AdminStore.I,
      builder: (context, _) {
        final s = AdminStore.I;
        final p = Pal.of(context);
        final list = s.mediaList;
        final kb = list.fold<num>(0, (a, e) => a + numOf(e.value['kb']));
        return Scaffold(
          appBar: AppBar(title: Text('مكتبة الوسائط: ${list.length}')),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _busy ? null : _upload,
            icon: _busy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.add),
            label: const Text('رفع صورة جديدة'),
          ),
          body: s.mediaIndex == null
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 90),
                  children: [
                    Text(
                      '${list.length} صورة · ${(kb / 1024).toStringAsFixed(2)} ميغابايت في Supabase — الحاوية ${s.supaBucket}. '
                      'لا يُحفظ في فايربيس سوى رابط الصورة فقط.',
                      style: TextStyle(fontSize: 12, color: p.muted, height: 1.6),
                    ),
                    if (_legacy > 0)
                      NoteBox(
                        child: Text(
                          'صور قديمة مخزّنة داخل فايربيس: $_legacy — انقلها إلى Supabase من زر الترحيل في «قواعد البيانات».',
                          style: TextStyle(fontSize: 12, color: p.text),
                        ),
                      ),
                    const SizedBox(height: 10),
                    if (list.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(30),
                        child: Text('المكتبة فارغة — ارفع أول صورة.', textAlign: TextAlign.center, style: TextStyle(color: p.muted)),
                      ),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 0.78,
                      children: [
                        for (final e in list) _item(context, e.key, e.value),
                      ],
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _item(BuildContext context, String id, Json it) {
    final s = AdminStore.I;
    final p = Pal.of(context);
    final ref = str(it['u']);
    final used = s.mediaUsed(ref);
    return Container(
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: AppImage(ref)),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
            child: Text(str(it['n']).isEmpty ? id : str(it['n']),
                maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: p.text)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              '${numOf(it['kb']).round()} كيلوبايت · ${used ? 'مستخدمة' : 'غير مستخدمة'}',
              style: TextStyle(fontSize: 10.5, color: used ? const Color(0xFF12A05F) : p.muted),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                tooltip: 'نسخ الرابط',
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.copy, size: 18),
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: ref));
                  toast('تم نسخ الرابط');
                },
              ),
              IconButton(
                tooltip: 'تعيين كخلفية',
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.wallpaper, size: 18),
                onPressed: () => _asBg(ref),
              ),
              IconButton(
                tooltip: 'حذف',
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFB42318)),
                onPressed: () async {
                  final ok = await confirmDialog(
                    context,
                    used ? 'هذه الصورة مستخدمة حالياً. حذفها على أي حال؟' : 'حذف الصورة نهائياً؟',
                    ok: 'حذف',
                    danger: true,
                  );
                  if (!ok) return;
                  showResult(await s.deleteMedia(id), 'تم حذف الصورة');
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ======================= سجل النشاطات =======================
class AdminActivityScreen extends StatelessWidget {
  const AdminActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AdminStore.I,
      builder: (context, _) {
        final s = AdminStore.I;
        final p = Pal.of(context);
        final list = s.activityList;
        return Scaffold(
          appBar: AppBar(
            title: Text('سجل النشاطات: ${list.length}'),
            actions: [
              IconButton(
                tooltip: 'مسح السجل',
                icon: const Icon(Icons.delete_sweep_outlined),
                onPressed: list.isEmpty
                    ? null
                    : () async {
                        final ok = await confirmDialog(context, 'مسح سجل النشاطات؟', ok: 'مسح', danger: true);
                        if (!ok) return;
                        showResult(await s.clearLog(), 'تم المسح');
                      },
              ),
            ],
          ),
          body: list.isEmpty
              ? const EmptyBox('السجل فارغ.', icon: Icons.history)
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 30),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => Divider(height: 1, color: p.border),
                  itemBuilder: (context, i) {
                    final a = list[i];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: p.soft,
                        child: Icon(iconFromFa(str(a['icon'])), size: 18, color: p.brandOn),
                      ),
                      title: Text(str(a['text']), style: TextStyle(fontSize: 13, color: p.text)),
                      subtitle: Text('${str(a['by'])} · ${timeAgo(str(a['at']))}', style: TextStyle(fontSize: 11, color: p.muted)),
                    );
                  },
                ),
        );
      },
    );
  }
}

// ======================= قواعد البيانات =======================
class AdminDatabaseScreen extends StatefulWidget {
  const AdminDatabaseScreen({super.key});

  @override
  State<AdminDatabaseScreen> createState() => _AdminDatabaseScreenState();
}

class _AdminDatabaseScreenState extends State<AdminDatabaseScreen> {
  final _url = TextEditingController();
  final _bucket = TextEditingController();
  String _cloud = 'ok';
  int _legacy = 0;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _url.text = AdminStore.I.setting('supaUrl');
    _bucket.text = AdminStore.I.setting('supaBucket').isEmpty ? Cfg.supaBucketDefault : AdminStore.I.setting('supaBucket');
    AdminStore.I.legacyMediaCount().then((v) {
      if (mounted) setState(() => _legacy = v);
    });
  }

  @override
  void dispose() {
    _url.dispose();
    _bucket.dispose();
    super.dispose();
  }

  Future<void> _do(Future<void> Function() fn) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await fn();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AdminStore.I,
      builder: (context, _) {
        final s = AdminStore.I;
        final p = Pal.of(context);
        final status = _cloud == 'ok'
            ? 'متصل بقاعدة البيانات'
            : (_cloud == 'off' ? 'تعذّر الاتصال بقاعدة البيانات' : 'جاري المزامنة...');
        return Scaffold(
          appBar: AppBar(title: const Text('إدارة قواعد البيانات')),
          body: AbsorbPointer(
            absorbing: _busy,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 30),
              children: [
                if (_busy) const LinearProgressIndicator(),
                AdminPanel(
                  title: 'Firebase Realtime Database — البيانات فقط',
                  note: 'النصوص والمعلومات وكل ما يُضاف من لوحة المدير',
                  children: [
                    Row(
                      children: [
                        Icon(_cloud == 'ok' ? Icons.cloud_done : (_cloud == 'off' ? Icons.cloud_off : Icons.sync),
                            color: _cloud == 'ok' ? const Color(0xFF12A05F) : const Color(0xFFB42318)),
                        const SizedBox(width: 8),
                        Text(status, style: TextStyle(fontWeight: FontWeight.w700, color: p.text)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SelectableText(
                      'قاعدة البيانات: ${Cfg.fbBase}\n'
                      'بيانات المنصة: /${Cfg.fbNs}/core · المدارس: /${Cfg.fbNs}/public/schools · المعاهد: /${Cfg.fbNs}/public/institutes\n'
                      'أرقام النسخ الصغيرة: /${Cfg.fbNs}/publicVersion · فهرس الصور: /${Cfg.fbNs}/mediaIndex\n'
                      'العناصر: ${s.allCards.length} · الأقسام: ${s.categories.length} · المحافظات: ${s.geo.length} · المستخدمون: ${s.users.length}\n'
                      'رقم النسخة الحالي: ${s.lastRev} · صيغة التخزين: ${s.legacyFormat ? 'قديمة — اضغط «رفع كامل الآن» للترحيل' : 'محدّثة (كتابة جزئية)'}',
                      style: TextStyle(fontSize: 11.5, color: p.muted, height: 1.8),
                      textDirection: TextDirection.rtl,
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        MiniAction(Icons.cloud_upload_outlined, 'رفع كامل الآن', () => _do(() async {
                              setState(() => _cloud = 'sync');
                              final r = await s.fullPush();
                              setState(() => _cloud = r == null ? 'ok' : 'off');
                              showResult(r, 'تم رفع البيانات كاملة');
                            })),
                        MiniAction(Icons.cloud_download_outlined, 'سحب أحدث بيانات', () => _do(() async {
                              setState(() => _cloud = 'sync');
                              final ok = await s.load();
                              setState(() => _cloud = ok ? 'ok' : 'off');
                              showResult(ok ? null : s.error, 'تم سحب أحدث البيانات');
                            })),
                        MiniAction(Icons.power_outlined, 'اختبار الاتصال', () => _do(() async {
                              setState(() => _cloud = 'sync');
                              final ok = await s.testFirebase();
                              setState(() => _cloud = ok ? 'ok' : 'off');
                              showResult(ok ? null : 'تعذّر الاتصال بـ Firebase', 'Firebase متصل ويعمل بنجاح');
                            })),
                        MiniAction(Icons.delete_forever_outlined, 'مسح البيانات السحابية', () async {
                          final ok = await confirmTyped(
                              context, 'سيتم حذف كل البيانات والصور القديمة من فايربيس نهائياً. متأكد؟', 'حذف فايربيس');
                          if (!ok) return;
                          await _do(() async => showResult(await s.wipeCloud(), 'تم مسح البيانات السحابية وإعادة الضبط'));
                        }, danger: true),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'الحفظ جزئي: عند تعديل عنصر واحد يُرسل ذلك العنصر فقط إلى فايربيس بدل رفع القاعدة كاملة.',
                      style: TextStyle(fontSize: 11, color: p.muted, height: 1.7),
                    ),
                  ],
                ),
                AdminPanel(
                  title: 'Supabase Storage — الصور والوسائط فقط',
                  note: 'لا تُخزَّن أي بيانات نصية هنا',
                  children: [
                    NoteBox(
                      child: Text(
                        'الصور الجديدة تُرفع إلى الحاوية ${s.supaBucket} في ${s.supaBase} ويُحفظ رابطها فقط داخل فايربيس.',
                        style: TextStyle(fontSize: 12, color: p.text, height: 1.6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _url,
                      textDirection: TextDirection.ltr,
                      decoration: fieldDeco(context, 'رابط مشروع Supabase', hint: 'https://xxxxxxxx.supabase.co'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _bucket,
                      textDirection: TextDirection.ltr,
                      decoration: fieldDeco(context, 'اسم الحاوية (Bucket)', hint: 'media'),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        MiniAction(Icons.save_outlined, 'حفظ إعدادات Supabase', () => _do(() async {
                              showResult(await s.saveSupaSettings(_url.text, _bucket.text), 'تم حفظ إعدادات Supabase');
                            })),
                        MiniAction(Icons.power_outlined, 'اختبار الرفع', () => _do(() async {
                              toast('جاري اختبار الرفع...');
                              final r = await s.testSupabase();
                              showResult(r == 'OK' ? null : r, 'Supabase يعمل — رفع الصورة وعرضها للعامة والحذف ناجح');
                            })),
                        MiniAction(Icons.swap_horiz, 'ترحيل الصور القديمة ($_legacy)', () async {
                          final ok = await confirmDialog(
                            context,
                            'سيتم نقل كل الصور المخزّنة داخل فايربيس إلى Supabase، ثم استبدال المراجع بالروابط وحذفها من فايربيس. متابعة؟',
                            ok: 'متابعة',
                          );
                          if (!ok) return;
                          await _do(() async {
                            final (done, fail) = await s.migrateLegacyMedia();
                            final left = await s.legacyMediaCount();
                            if (mounted) setState(() => _legacy = left);
                            toast(
                              done == 0 && fail == 0
                                  ? 'لا توجد صور قديمة للترحيل'
                                  : 'انتهى الترحيل: $done صورة${fail > 0 ? ' · تعذّر $fail' : ''}',
                              fail > 0 ? ToastType.warn : ToastType.ok,
                            );
                          });
                        }),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'خطوات التهيئة في لوحة Supabase: أنشئ حاوية واجعلها Public، ثم أضف سياستين على storage.objects للدور anon: واحدة للقراءة (SELECT) وأخرى للرفع (INSERT) على نفس الحاوية.',
                      style: TextStyle(fontSize: 11, color: p.muted, height: 1.7),
                    ),
                  ],
                ),
                const AdminBackupPanel(),
                AdminPanel(
                  title: 'توزيع التخزين',
                  children: [
                    Text(
                      'Firebase: كل البيانات النصية (العناصر والأقسام والمحافظات والطلبات والمستخدمون والإعدادات والسجل).\n'
                      'Supabase: صور العناصر والأقسام والخلفيات والشعار والإعلانات — ملفات فقط.\n'
                      'الجهاز: نسخة محلية للعرض الفوري، تُحدَّث عند تغيّر رقم النسخة.',
                      style: TextStyle(fontSize: 11.5, color: p.muted, height: 1.8),
                    ),
                    const SizedBox(height: 8),
                    NoteBox(
                      child: Text(
                        'تنبيه أمني مهم: القراءة والكتابة في قاعدة البيانات ما زالت مفتوحة. الحماية الفعلية تتطلب Firebase Authentication وقواعد صلاحيات، وسياسات RLS في Supabase.',
                        style: TextStyle(fontSize: 11.5, color: p.text, height: 1.6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// النسخ الاحتياطي: تصدير/استيراد JSON، تصدير CSV، تصفير العدادات، إعادة ضبط المصنع
class AdminBackupPanel extends StatelessWidget {
  const AdminBackupPanel({super.key});

  Future<void> _import(BuildContext context) async {
    final s = AdminStore.I;
    String? text;
    try {
      text = await s.pickImportFile();
    } on AdminError catch (e) {
      toast(e.message, ToastType.err);
      return;
    } catch (_) {
      toast('تعذّر قراءة الملف', ToastType.err);
      return;
    }
    if (text == null || !context.mounted) return;
    final ok = await confirmDialog(context, 'سيتم استبدال جميع البيانات الحالية. متابعة؟', ok: 'استيراد', danger: true);
    if (!ok) return;
    toast('جاري الاستيراد...');
    showResult(await s.importJson(text), 'تم الاستيراد بنجاح');
  }

  @override
  Widget build(BuildContext context) {
    final s = AdminStore.I;
    return AdminPanel(
      title: 'النسخ الاحتياطي',
      note: 'البيانات محفوظة سحابياً في فايربيس ومتزامنة على كل الأجهزة. التصدير يبقى مفيد كنسخة احتياطية خارجية.',
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            MiniAction(Icons.download_outlined, 'تصدير JSON', () async {
              final r = await s.exportJson();
              if (r != null) toast(r, ToastType.err);
            }),
            MiniAction(Icons.upload_outlined, 'استيراد JSON', () => _import(context)),
            MiniAction(Icons.table_view_outlined, 'تصدير CSV', () async {
              final r = await s.exportCsv();
              if (r != null) toast(r, ToastType.err);
            }),
            MiniAction(Icons.speed, 'تصفير عدادات الزيارات', () async {
              final ok = await confirmDialog(context, 'تصفير عدادات الزيارات والبحث والمستخدمين الجدد؟',
                  ok: 'تصفير', danger: true);
              if (!ok) return;
              showResult(await s.resetCounters(), 'تم التصفير');
            }, danger: true),
            MiniAction(Icons.restart_alt, 'إعادة ضبط المصنع', () async {
              final ok = await confirmTyped(
                  context, 'سيتم مسح كل البيانات في فايربيس والعودة للوضع الافتراضي. متأكد؟', 'إعادة ضبط');
              if (!ok) return;
              showResult(await s.wipeCloud(keepMedia: true), 'تمت إعادة الضبط');
            }, danger: true),
          ],
        ),
      ],
    );
  }
}

// ======================= جدول المحتوى (كل العناصر) =======================
String _one(AdminStore s, String key) {
  for (final x in s.categories.values) {
    if (str(x['key']) == key) return str(x['one']);
  }
  return key;
}

class AdminContentScreen extends StatefulWidget {
  const AdminContentScreen({super.key});

  @override
  State<AdminContentScreen> createState() => _AdminContentScreenState();
}

class _AdminContentScreenState extends State<AdminContentScreen> {
  static const int _perPage = 20;
  final _q = TextEditingController();
  String _cat = '';
  String _status = '';
  int _page = 1;

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AdminStore.I,
      builder: (context, _) {
        final s = AdminStore.I;
        final p = Pal.of(context);
        final q = _q.text.trim().toLowerCase();
        final list = s.allCards.where((c) {
          if (_cat.isNotEmpty && str(c['key']) != _cat) return false;
          if (_status.isNotEmpty && str(c['status']) != _status) return false;
          if (q.isEmpty) return true;
          final ex = c['extra'] is Map ? (c['extra'] as Map).values.join(' ') : '';
          return '${str(c['name'])} ${str(c['desc'])} ${str(c['key'])} ${str(c['city'])} ${str(c['gov'])} ${str(c['dist'])} ${str(c['specialty'])} $ex'
              .toLowerCase()
              .contains(q);
        }).toList()
          ..sort((a, b) => str(b['created']).compareTo(str(a['created'])));
        final pages = list.isEmpty ? 1 : (list.length / _perPage).ceil();
        if (_page > pages) _page = pages;
        final slice = list.skip((_page - 1) * _perPage).take(_perPage).toList();
        return Scaffold(
          appBar: AppBar(title: Text('إجمالي العناصر: ${list.length}')),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
                child: TextField(
                  controller: _q,
                  onChanged: (_) => setState(() => _page = 1),
                  decoration: fieldDeco(context, 'بحث في المحتوى', icon: Icons.search),
                ),
              ),
              SizedBox(
                height: 46,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  children: [
                    Padding(
                      padding: const EdgeInsetsDirectional.only(end: 6),
                      child: ChoiceChip(
                        label: const Text('الكل'),
                        selected: _cat.isEmpty,
                        onSelected: (_) => setState(() {
                          _cat = '';
                          _page = 1;
                        }),
                      ),
                    ),
                    for (final c in s.categoryList)
                      Padding(
                        padding: const EdgeInsetsDirectional.only(end: 6),
                        child: ChoiceChip(
                          label: Text(str(c['name'])),
                          selected: _cat == str(c['key']),
                          onSelected: (_) => setState(() {
                            _cat = str(c['key']);
                            _page = 1;
                          }),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    Text('الحالة:', style: TextStyle(color: p.muted, fontSize: 12)),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: _status,
                      underline: const SizedBox.shrink(),
                      items: const [
                        DropdownMenuItem(value: '', child: Text('كل الحالات')),
                        DropdownMenuItem(value: 'منشور', child: Text('منشور')),
                        DropdownMenuItem(value: 'مسودة', child: Text('مسودة')),
                      ],
                      onChanged: (v) => setState(() {
                        _status = v ?? '';
                        _page = 1;
                      }),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: slice.isEmpty
                    ? const EmptyBox('لا توجد عناصر مطابقة.')
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(14, 4, 14, 10),
                        itemCount: slice.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 6),
                        itemBuilder: (context, i) {
                          final c = slice[i];
                          final draft = str(c['status']) == 'مسودة';
                          return Material(
                            color: p.card,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: p.border),
                            ),
                            child: ListTile(
                              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) => AdminCardEditor(catKey: str(c['key']), card: c),
                              )),
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: AppImage(str(c['img']), width: 44, height: 44),
                              ),
                              title: Text(str(c['name']),
                                  maxLines: 1, overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontWeight: FontWeight.w800, color: p.text)),
                              subtitle: Text(
                                '${_one(s, str(c['key']))}'
                                ' · ${str(c['created'])} · ${draft ? 'مسودة' : 'منشور'}',
                                style: TextStyle(fontSize: 11.5, color: draft ? const Color(0xFFB54708) : p.muted),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              if (pages > 1)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: _page > 1 ? () => setState(() => _page--) : null,
                      ),
                      Text('$_page / $pages'),
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: _page < pages ? () => setState(() => _page++) : null,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
