// إدارة الأقسام، المحافظات والمراكز، اللوحات الإعلانية ورسالة الترحيب

import 'package:flutter/material.dart';

import '../config.dart';
import '../ui.dart';
import '../utils.dart';
import '../widgets/app_image.dart';
import '../widgets/common.dart';
import 'admin_cards.dart';
import 'admin_store.dart';
import 'admin_ui.dart';

// ======================= إدارة الأقسام =======================
class AdminCategoriesScreen extends StatelessWidget {
  const AdminCategoriesScreen({super.key});

  Future<void> _add(BuildContext context) async {
    final name = await promptText(context, 'اسم القسم الجديد (بصيغة الجمع)', initial: 'قسم جديد');
    if (name == null || !context.mounted) return;
    if (name.trim().isEmpty) {
      toast('الاسم مطلوب', ToastType.warn);
      return;
    }
    final key = await promptText(context, 'مفتاح القسم (كلمة مختصرة للتصنيف)', initial: name.trim());
    if (key == null || !context.mounted) return;
    final one = await promptText(context, 'اسم العنصر الواحد (مفرد)', initial: name.trim());
    final r = await AdminStore.I.addCategory(name, key, one ?? '');
    showResult(r, 'تمت إضافة القسم');
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AdminStore.I,
      builder: (context, _) {
        final s = AdminStore.I;
        final keys = s.categoryKeys;
        return Scaffold(
          appBar: AppBar(title: Text('إدارة الأقسام (${keys.length})')),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _add(context),
            icon: const Icon(Icons.add),
            label: const Text('إضافة قسم جديد'),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 90),
            children: [
              Text(
                'تقدر تضيف أي عدد من الأقسام وتغيّر الاسم والصورة والأيقونة واللون والوصف — وكل شي ينحفظ في فايربيس ويظهر فوراً للمستخدمين.',
                style: TextStyle(fontSize: 12, color: Pal.of(context).muted, height: 1.6),
              ),
              const SizedBox(height: 10),
              for (var i = 0; i < keys.length; i++) _CategoryCard(id: keys[i], index: i, total: keys.length),
            ],
          ),
        );
      },
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String id;
  final int index;
  final int total;
  const _CategoryCard({required this.id, required this.index, required this.total});

  Future<void> _edit(BuildContext context, String field, String label, {int lines = 1}) async {
    final c = AdminStore.I.categories[id];
    if (c == null) return;
    final v = await promptText(context, label, initial: str(c[field]), lines: lines);
    if (v == null) return;
    showResult(await AdminStore.I.updateCategory(id, {field: lines > 1 ? clip(v, 1000) : clip(v, 200)}), 'تم حفظ التعديل');
  }

  Future<void> _key(BuildContext context) async {
    final c = AdminStore.I.categories[id];
    if (c == null) return;
    final v = await promptText(context, 'المفتاح (يُستخدم للتصنيف)', initial: str(c['key']));
    if (v == null) return;
    showResult(await AdminStore.I.renameCategoryKey(id, v), 'تم تحديث المفتاح ونقل العناصر');
  }

  Future<void> _icon(BuildContext context) async {
    final c = AdminStore.I.categories[id];
    if (c == null) return;
    final cur = str(c['icon']);
    final picked = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('الأيقونة', style: TextStyle(fontSize: 16)),
        content: SizedBox(
          width: double.maxFinite,
          child: GridView.count(
            crossAxisCount: 5,
            shrinkWrap: true,
            children: [
              for (final ic in [...kIconChoices, if (!kIconChoices.contains(cur) && cur.isNotEmpty) cur])
                IconButton(
                  tooltip: ic.replaceAll('fa-solid fa-', '').replaceAll('fa-regular fa-', ''),
                  isSelected: ic == cur,
                  icon: Icon(iconFromFa(ic)),
                  onPressed: () => Navigator.of(ctx).pop(ic),
                ),
            ],
          ),
        ),
      ),
    );
    if (picked == null || picked == cur) return;
    showResult(await AdminStore.I.updateCategory(id, {'icon': picked}), 'تم حفظ التعديل');
  }

  Future<void> _color(BuildContext context, int idx) async {
    final c = AdminStore.I.categories[id];
    if (c == null) return;
    final t = AdminStore.I.tintOf(c);
    final v = await pickColor(context, t[idx], title: idx == 0 ? 'لون الخلفية' : 'لون الأيقونة');
    if (v == null) return;
    showResult(await AdminStore.I.updateCategoryTint(id, idx, v), 'تم تغيير اللون');
  }

  Future<void> _image(BuildContext context) async {
    final c = AdminStore.I.categories[id];
    if (c == null) return;
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.cloud_upload_outlined),
              title: const Text('رفع صورة'),
              onTap: () => Navigator.of(ctx).pop('up'),
            ),
            ListTile(
              leading: const Icon(Icons.link),
              title: const Text('رابط صورة'),
              onTap: () => Navigator.of(ctx).pop('url'),
            ),
          ],
        ),
      ),
    );
    if (choice == null || !context.mounted) return;
    if (choice == 'url') {
      final v = await promptText(context, 'صورة القسم', initial: str(c['img']), hint: 'https://... رابط الصورة', ltr: true);
      if (v == null) return;
      showResult(await AdminStore.I.updateCategory(id, {'img': v.trim()}), 'تم حفظ التعديل');
      return;
    }
    final x = await pickImageFile(context);
    if (x == null) return;
    try {
      toast('جاري ضغط ورفع الصورة...');
      final url = await AdminStore.I.uploadImage(await x.readAsBytes(), x.name);
      showResult(
        await AdminStore.I.updateCategory(id, {'img': url},
            log: 'تغيير صورة قسم: ${str(c['name'])}', icon: 'fa-regular fa-image'),
        'تم تحديث صورة القسم',
      );
    } catch (_) {
      toast('تعذّر رفع الصورة — تحقق من الاتصال وإعدادات Supabase', ToastType.err);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AdminStore.I;
    final c = s.categories[id];
    if (c == null) return const SizedBox.shrink();
    final p = Pal.of(context);
    final t = s.tintOf(c);
    final key = str(c['key']);
    final n = s.countAll(key);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            children: [
              SizedBox(height: 110, width: double.infinity, child: AppImage(str(c['img']), height: 110)),
              PositionedDirectional(
                top: 6,
                end: 6,
                child: Row(
                  children: [
                    _round(Icons.arrow_upward, index == 0 ? null : () async {
                      showResult(await s.moveCategory(index, -1), 'تم تغيير الترتيب');
                    }),
                    _round(Icons.arrow_downward, index == total - 1 ? null : () async {
                      showResult(await s.moveCategory(index, 1), 'تم تغيير الترتيب');
                    }),
                    _round(Icons.delete_outline, () async {
                      final ok = await confirmDialog(
                        context,
                        'حذف القسم "${str(c['name'])}"${n > 0 ? ' مع $n عنصر تابع له' : ''}؟',
                        ok: 'حذف',
                        danger: true,
                      );
                      if (!ok) return;
                      showResult(await s.deleteCategory(id), 'تم حذف القسم');
                    }, danger: true),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    InkWell(
                      onTap: () => _icon(context),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(color: hexColor(t[0]), borderRadius: BorderRadius.circular(12)),
                        child: Icon(iconFromFa(str(c['icon'])), color: hexColor(t[1])),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(str(c['name']), style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: p.text)),
                          Text('المفرد: ${str(c['one'])} · المفتاح: $key',
                              style: TextStyle(fontSize: 11.5, color: p.muted)),
                        ],
                      ),
                    ),
                  ],
                ),
                if (str(c['desc']).isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(str(c['desc']), style: TextStyle(fontSize: 12.5, color: p.text, height: 1.6)),
                ],
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    MiniAction(Icons.edit, 'الاسم', () => _edit(context, 'name', 'اسم القسم (جمع)')),
                    MiniAction(Icons.edit_note, 'المفرد', () => _edit(context, 'one', 'المفرد')),
                    MiniAction(Icons.key, 'المفتاح', () => _key(context)),
                    MiniAction(Icons.notes, 'الوصف', () => _edit(context, 'desc', 'الوصف', lines: 3)),
                    MiniAction(Icons.emoji_symbols, 'الأيقونة', () => _icon(context)),
                    MiniAction(Icons.format_color_fill, 'لون الخلفية', () => _color(context, 0)),
                    MiniAction(Icons.color_lens_outlined, 'لون الأيقونة', () => _color(context, 1)),
                    MiniAction(Icons.image_outlined, 'صورة القسم', () => _image(context)),
                    MiniAction(Icons.list, 'عناصر القسم ($n)', () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => AdminCardsScreen(catKey: key)));
                    }),
                  ],
                ),
                const SizedBox(height: 6),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: const Text('تصنيف هرمي: محافظة ← مركز ← العناصر', style: TextStyle(fontSize: 12.5)),
                  value: c['hier'] == true,
                  onChanged: (v) async => showResult(await s.updateCategory(id, {'hier': v}), 'تم حفظ التعديل'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _round(IconData icon, VoidCallback? onTap, {bool danger = false}) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 4),
      child: Material(
        color: onTap == null ? const Color(0x55000000) : const Color(0xAA000000),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(icon, size: 18, color: danger ? const Color(0xFFFF8A80) : Colors.white),
          ),
        ),
      ),
    );
  }
}

// ======================= المحافظات والمراكز =======================
class AdminGeoScreen extends StatelessWidget {
  const AdminGeoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AdminStore.I,
      builder: (context, _) {
        final s = AdminStore.I;
        final p = Pal.of(context);
        final gs = s.geoList;
        final distCount = gs.fold<int>(0, (a, g) => a + s.districtsOf(g).length);
        final hierCats = s.categoryList.where((c) => c['hier'] == true).map((c) => str(c['name'])).join('، ');
        return Scaffold(
          appBar: AppBar(title: Text('المحافظات: ${gs.length} — المراكز: $distCount')),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () async {
              final n = await promptText(context, 'اسم المحافظة الجديدة');
              if (n == null) return;
              showResult(await s.addGov(n), 'تمت إضافة المحافظة');
            },
            icon: const Icon(Icons.add),
            label: const Text('إضافة محافظة'),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 90),
            children: [
              Text(
                'الأقسام التي تعتمد التصنيف الهرمي (محافظة ← مركز): ${hierCats.isEmpty ? 'لا يوجد' : hierCats}. '
                'تقدر تفعّل أو تلغي التصنيف الهرمي لأي قسم من «إدارة الأقسام». تعديل اسم محافظة أو مركز ينقل العناصر المرتبطة تلقائياً.',
                style: TextStyle(fontSize: 12, color: p.muted, height: 1.6),
              ),
              const SizedBox(height: 6),
              NoteBox(
                child: Text(
                  'ملاحظة: الإصدار الحالي (دليل ميسان) يعرض للزوار مناطق ميسان المعتمدة في الويب والتطبيق، لذلك تُحفظ تعديلات هذا القسم في قاعدة البيانات دون أن تغيّر قائمة المناطق الظاهرة.',
                  style: TextStyle(fontSize: 11.5, color: p.text, height: 1.6),
                ),
              ),
              const SizedBox(height: 8),
              for (final k in s.geoKeys) _GovCard(gid: k),
            ],
          ),
        );
      },
    );
  }
}

class _GovCard extends StatelessWidget {
  final String gid;
  const _GovCard({required this.gid});

  @override
  Widget build(BuildContext context) {
    final s = AdminStore.I;
    final p = Pal.of(context);
    final g = s.geo[gid];
    if (g == null) return const SizedBox.shrink();
    final name = str(g['name']);
    final ds = s.districtsOf(g);
    return AdminPanel(
      title: '$name (${ds.length} مركز · ${s.govCardCount(name)} عنصر)',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'تعديل الاسم',
            icon: const Icon(Icons.edit, size: 20),
            onPressed: () async {
              final n = await promptText(context, 'اسم المحافظة', initial: name);
              if (n == null) return;
              showResult(await s.renameGov(gid, n), 'تم تعديل اسم المحافظة');
            },
          ),
          IconButton(
            tooltip: 'حذف',
            icon: const Icon(Icons.delete_outline, size: 20, color: Color(0xFFB42318)),
            onPressed: () async {
              final n = s.govCardCount(name);
              final ok = await confirmDialog(
                context,
                'حذف محافظة $name وأقضيتها؟${n > 0 ? ' يوجد $n عنصر مرتبط بها (لن تُحذف عناصره، لكن ستبقى بدون محافظة مسجّلة).' : ''}',
                ok: 'حذف',
                danger: true,
              );
              if (!ok) return;
              showResult(await s.deleteGov(gid), 'تم حذف المحافظة');
            },
          ),
        ],
      ),
      children: [
        if (ds.isEmpty) Text('لا توجد مراكز بعد.', style: TextStyle(fontSize: 12, color: p.muted)),
        for (var j = 0; j < ds.length; j++)
          Row(
            children: [
              Icon(Icons.place, size: 14, color: p.muted),
              const SizedBox(width: 4),
              Expanded(
                child: Text('مركز ${str(ds[j]['name'])}', style: TextStyle(fontSize: 13, color: p.text)),
              ),
              Text('${s.distCardCount(name, str(ds[j]['name']))}', style: TextStyle(fontSize: 12, color: p.muted)),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.arrow_upward, size: 18),
                onPressed: j == 0 ? null : () async => showResult(await s.moveDist(gid, j, -1), 'تم الترتيب'),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.arrow_downward, size: 18),
                onPressed: j == ds.length - 1 ? null : () async => showResult(await s.moveDist(gid, j, 1), 'تم الترتيب'),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.edit, size: 18),
                onPressed: () async {
                  final n = await promptText(context, 'اسم المركز', initial: str(ds[j]['name']));
                  if (n == null) return;
                  showResult(await s.renameDist(gid, j, n), 'تم تعديل اسم المركز');
                },
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFB42318)),
                onPressed: () async {
                  final dn = str(ds[j]['name']);
                  final n = s.distCardCount(name, dn);
                  final ok = await confirmDialog(context, 'حذف مركز $dn؟${n > 0 ? ' يوجد $n عنصر مرتبط به.' : ''}',
                      ok: 'حذف', danger: true);
                  if (!ok) return;
                  showResult(await s.deleteDist(gid, j), 'تم حذف المركز');
                },
              ),
            ],
          ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            MiniAction(Icons.add, 'إضافة مركز', () async {
              final n = await promptText(context, 'اسم المركز الجديد في محافظة $name');
              if (n == null) return;
              showResult(await s.addDist(gid, n), 'تمت إضافة المركز');
            }),
            MiniAction(Icons.playlist_add, 'إضافة دفعة', () async {
              final raw = await promptText(
                context,
                'أضف عدة مراكز دفعة واحدة في $name',
                hint: 'اكتب كل مركز في سطر، أو افصلها بفاصلة',
                lines: 5,
              );
              if (raw == null) return;
              final (e, added, dup) = await s.addDistBulk(gid, raw);
              if (e != null) {
                toast(e, ToastType.warn);
              } else {
                toast('تمت إضافة $added مركز${dup > 0 ? ' — تم تجاهل $dup مكرر' : ''}');
              }
            }),
            if (ds.length > 1)
              MiniAction(Icons.sort_by_alpha, 'ترتيب أبجدي', () async {
                showResult(await s.sortDists(gid), 'تم الترتيب أبجدياً');
              }),
            if (ds.isNotEmpty)
              MiniAction(Icons.delete_sweep_outlined, 'حذف الكل', () async {
                final linked = s.allCards.where((c) => str(c['gov']) == name && str(c['dist']).isNotEmpty).length;
                final ok = await confirmDialog(
                  context,
                  'حذف كل المراكز (${ds.length}) من $name؟${linked > 0 ? ' يوجد $linked عنصر مرتبط بمراكز (لن تُحذف عناصره).' : ''}',
                  ok: 'حذف',
                  danger: true,
                );
                if (!ok) return;
                showResult(await s.clearDists(gid), 'تم حذف كل المراكز');
              }, danger: true),
          ],
        ),
      ],
    );
  }
}

// ======================= اللوحات الإعلانية ورسالة الترحيب =======================
class AdminAdsScreen extends StatefulWidget {
  const AdminAdsScreen({super.key});

  @override
  State<AdminAdsScreen> createState() => _AdminAdsScreenState();
}

class _AdminAdsScreenState extends State<AdminAdsScreen> {
  final _welcome = TextEditingController();
  final _delay = TextEditingController();
  late bool _wOn;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final s = AdminStore.I;
    _welcome.text = s.setting('welcomeTitle');
    _wOn = s.settings['welcomeOn'] != false;
    final d = intOf(s.settings['adsDelay']);
    _delay.text = '${d == 0 ? 5 : d}';
  }

  @override
  void dispose() {
    _welcome.dispose();
    _delay.dispose();
    super.dispose();
  }

  Future<void> _addAd() async {
    final x = await pickImageFile(context, maxW: 1920, maxH: 1200, quality: 88);
    if (x == null) return;
    setState(() => _busy = true);
    toast('جاري تجهيز صورة الإعلان...');
    final (e, id) = await AdminStore.I.addAd(await x.readAsBytes(), x.name);
    if (!mounted) return;
    setState(() => _busy = false);
    if (e != null) {
      toast(e, ToastType.err);
      return;
    }
    toast('تمت إضافة اللوحة الإعلانية');
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => AdEditorScreen(id: id)));
  }

  Future<void> _replace(String id) async {
    final x = await pickImageFile(context, maxW: 1920, maxH: 1200, quality: 88);
    if (x == null) return;
    setState(() => _busy = true);
    final e = await AdminStore.I.replaceAdImage(id, await x.readAsBytes(), x.name);
    if (mounted) setState(() => _busy = false);
    showResult(e, 'تم تغيير صورة اللوحة');
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AdminStore.I,
      builder: (context, _) {
        final s = AdminStore.I;
        final p = Pal.of(context);
        final list = s.adList;
        final keys = s.adKeys;
        final shown = list.where((a) => a['active'] != false).length;
        return Scaffold(
          appBar: AppBar(title: const Text('اللوحات الإعلانية')),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 30),
            children: [
              AdminPanel(
                title: 'رسالة الترحيب',
                note: 'النص الذي يظهر أعلى الواجهة الرئيسية فوق اللوحة الإعلانية مباشرة.',
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('إظهار رسالة الترحيب في الواجهة'),
                    value: _wOn,
                    onChanged: (v) => setState(() => _wOn = v),
                  ),
                  TextField(
                    controller: _welcome,
                    decoration: fieldDeco(context, 'نص الترحيب', hint: 'اهلا بكم في بوصلة الطالب'),
                  ),
                  const SizedBox(height: 10),
                  PrimaryButton('حفظ رسالة الترحيب', icon: Icons.save_outlined, onPressed: () async {
                    showResult(await s.saveWelcome(_wOn, _welcome.text), 'تم حفظ رسالة الترحيب');
                  }),
                ],
              ),
              AdminPanel(
                title: 'اللوحات الإعلانية: ${list.length} — المعروضة: $shown',
                note: 'اللوحات المفعّلة تظهر للمستخدمين في الواجهة الرئيسية. إذا كان هناك أكثر من لوحة تتبدّل تلقائياً، ويمكن للزائر التنقل بينها.',
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('تفعيل عرض اللوحات الإعلانية في الواجهة'),
                    value: s.settings['adsOn'] != false,
                    onChanged: (v) async => showResult(
                        await s.setAdsOn(v), v ? 'تم تفعيل اللوحات الإعلانية' : 'تم إيقاف اللوحات الإعلانية'),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _delay,
                          keyboardType: TextInputType.number,
                          decoration: fieldDeco(context, 'مدة عرض كل لوحة (بالثواني)', hint: '2 - 60'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SoftButton('حفظ', icon: Icons.timer_outlined, onPressed: () async {
                        showResult(await s.setAdsDelay(int.tryParse(_delay.text.trim()) ?? 5), 'تم حفظ مدة العرض');
                      }),
                    ],
                  ),
                  const SizedBox(height: 10),
                  PrimaryButton('إضافة لوحة إعلانية', icon: Icons.add_photo_alternate_outlined, busy: _busy, onPressed: _addAd),
                ],
              ),
              if (list.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(30),
                  child: Text('لا توجد لوحات إعلانية بعد — اضغط «إضافة لوحة إعلانية» لرفع أول صورة.',
                      textAlign: TextAlign.center, style: TextStyle(color: p.muted)),
                ),
              for (var i = 0; i < keys.length; i++) _adCard(context, keys, i),
            ],
          ),
        );
      },
    );
  }

  Widget _adCard(BuildContext context, List<String> keys, int i) {
    final s = AdminStore.I;
    final p = Pal.of(context);
    final id = keys[i];
    final a = s.ads[id];
    if (a == null) return const SizedBox.shrink();
    final active = a['active'] != false;
    final w = intOf(a['width']), h = intOf(a['height']);
    final hasInfo = s.adHasInfo(a);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: (w > 0 && h > 0) ? (w / h).clamp(0.5, 3.4).toDouble() : 2.0,
            child: AppImage(str(a['img'])),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(str(a['title']).isEmpty ? 'بدون عنوان' : str(a['title']),
                          style: TextStyle(fontWeight: FontWeight.w800, color: p.text)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: active ? const Color(0xFF0B6B47) : const Color(0xFF94A3B8),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(active ? 'معروضة' : 'مخفية',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${w > 0 && h > 0 ? '$w×$h' : 'صورة قديمة'}${intOf(a['kb']) > 0 ? ' · ${intOf(a['kb'])}KB' : ''}',
                  style: TextStyle(fontSize: 11.5, color: p.muted),
                ),
                Text(str(a['link']).isEmpty ? 'بدون رابط' : str(a['link']),
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11.5, color: p.muted)),
                Text(
                  hasInfo
                      ? 'معلومات الإعلان مضافة — تظهر للمستخدم عند الضغط على الصورة'
                      : 'لا توجد معلومات — اضغط «المعلومات» لإضافة الموقع والوصف وأوقات العمل والتواصل',
                  style: TextStyle(fontSize: 11.5, color: hasInfo ? const Color(0xFF189A92) : const Color(0xFFC0863A)),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    MiniAction(Icons.arrow_upward, 'تقديم', i == 0 ? null : () async {
                      showResult(await s.moveAd(i, -1), 'تم تغيير الترتيب');
                    }),
                    MiniAction(Icons.arrow_downward, 'تأخير', i == keys.length - 1 ? null : () async {
                      showResult(await s.moveAd(i, 1), 'تم تغيير الترتيب');
                    }),
                    MiniAction(Icons.edit_note, 'المعلومات', () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => AdEditorScreen(id: id)));
                    }),
                    MiniAction(Icons.image_outlined, 'الصورة', _busy ? null : () => _replace(id)),
                    MiniAction(active ? Icons.visibility_off_outlined : Icons.visibility_outlined, active ? 'إخفاء' : 'عرض',
                        () async {
                      showResult(await s.toggleAd(id), active ? 'تم إخفاء اللوحة' : 'تم عرض اللوحة');
                    }),
                    MiniAction(Icons.delete_outline, 'حذف', () async {
                      final ok = await confirmDialog(
                        context,
                        'حذف هذه اللوحة الإعلانية${str(a['title']).isNotEmpty ? ' "${str(a['title'])}"' : ''}؟',
                        ok: 'حذف',
                        danger: true,
                      );
                      if (!ok) return;
                      showResult(await s.deleteAd(id), 'تم حذف اللوحة الإعلانية');
                    }, danger: true),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// معلومات الإعلان — نفس openAdEditor
class AdEditorScreen extends StatefulWidget {
  final String id;
  const AdEditorScreen({super.key, required this.id});

  @override
  State<AdEditorScreen> createState() => _AdEditorScreenState();
}

class _AdEditorScreenState extends State<AdEditorScreen> {
  static const List<List<String>> _fields = [
    ['title', 'اسم الإعلان / العنوان', 'مثال: الحداد ابو مؤمل'],
    ['loc', 'نص الموقع', 'مثال: حداد متجول بكل العمارة وميسان'],
    ['map', 'رابط الموقع على الخرائط (اختياري)', 'https://maps.google.com/...'],
    ['desc', 'وصف الخدمات', 'اكتب كل سطر في سطر منفصل...'],
    ['hours', 'أوقات العمل', 'مثال: 06:00 صباحاً - 12:00 مساءً'],
    ['phone', 'رقم الهاتف', '07XXXXXXXXX'],
    ['wa', 'واتساب', '07XXXXXXXXX'],
    ['tg', 'تيليغرام', '@المعرف أو الرابط'],
    ['fb', 'فيسبوك', 'اسم الصفحة أو الرابط'],
    ['ig', 'إنستغرام', '@المعرف أو الرابط'],
    ['tt', 'تيك توك', '@المعرف أو الرابط'],
    ['link', 'رابط إضافي عند الضغط على زر «زيارة الرابط» (اختياري)', 'https://...'],
  ];
  final Map<String, TextEditingController> _c = {};
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final a = AdminStore.I.ads[widget.id] ?? const <String, dynamic>{};
    for (final f in _fields) {
      _c[f[0]] = TextEditingController(text: str(a[f[0]]));
    }
  }

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final a = AdminStore.I.ads[widget.id];
    return Scaffold(
      appBar: AppBar(title: const Text('معلومات الإعلان')),
      body: a == null
          ? const EmptyBox('اللوحة غير موجودة')
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AspectRatio(aspectRatio: 2, child: AppImage(str(a['img']))),
                ),
                const SizedBox(height: 12),
                for (final f in _fields)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TextField(
                      controller: _c[f[0]],
                      minLines: f[0] == 'desc' ? 4 : 1,
                      maxLines: f[0] == 'desc' ? 10 : 1,
                      textDirection: const ['map', 'link', 'phone', 'wa'].contains(f[0]) ? TextDirection.ltr : null,
                      decoration: fieldDeco(context, f[1], hint: f[2]),
                    ),
                  ),
                PrimaryButton('حفظ المعلومات', icon: Icons.save_outlined, busy: _busy, onPressed: () async {
                  setState(() => _busy = true);
                  final r = await AdminStore.I.saveAdInfo(widget.id, {for (final e in _c.entries) e.key: e.value.text});
                  if (!mounted) return;
                  setState(() => _busy = false);
                  showResult(r, 'تم حفظ معلومات الإعلان');
                  if (r == null) Navigator.of(context).pop();
                }),
              ],
            ),
    );
  }
}
