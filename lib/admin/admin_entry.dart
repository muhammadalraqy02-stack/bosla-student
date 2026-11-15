// مدخل لوحة الإدارة: 5 ضغطات متتالية على الشعار (مثل نسخة الويب)، شاشة الدخول، والصفحة الرئيسية للوحة

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config.dart';
import '../ui.dart';
import '../utils.dart';
import '../widgets/common.dart';
import 'admin_auth.dart';
import 'admin_cards.dart';
import 'admin_misc.dart';
import 'admin_sections_a.dart';
import 'admin_sections_b.dart';
import 'admin_store.dart';
import 'admin_ui.dart';

int _taps = 0;
Timer? _tapTimer;

/// تُستدعى عند الضغط على الشعار — 5 ضغطات خلال ثانية ونصف بين كل ضغطة وأخرى تفتح الإدارة
void adminSecretTap(BuildContext context) {
  // نسخة iOS: دخول المدير مخفي تماماً — مثل نسخة الويب داخل تطبيق iOS (متطلبات أبل، البند 2.3.1).
  // الإدارة متاحة من تطبيق الأندرويد ولوحة الويب.
  if (defaultTargetPlatform == TargetPlatform.iOS) return;
  _taps++;
  _tapTimer?.cancel();
  _tapTimer = Timer(const Duration(milliseconds: 1500), () => _taps = 0);
  if (_taps >= 5) {
    _taps = 0;
    _tapTimer?.cancel();
    HapticFeedback.mediumImpact();
    openAdmin(context);
  }
}

void openAdmin(BuildContext context) {
  final Widget page =
      AdminSession.user != null ? const AdminHomeScreen() : const AdminLoginScreen();
  Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
}

// ======================= شاشة الدخول =======================
class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _user = TextEditingController();
  final _pass = TextEditingController();
  bool _busy = false;
  bool _hide = true;

  @override
  void dispose() {
    _user.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _submit({String? newPass}) async {
    final u = _user.text.trim();
    final p = _pass.text;
    if (u.isEmpty || p.isEmpty) {
      toast('أدخل اسم المستخدم وكلمة المرور', ToastType.warn);
      return;
    }
    setState(() => _busy = true);
    final r = await AdminStore.I.login(u, p, newPass: newPass);
    if (!mounted) return;
    setState(() => _busy = false);
    if (r == null) {
      _pass.clear();
      toast('أهلاً $u');
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AdminHomeScreen()),
      );
      return;
    }
    if (r == kNeedNewPassword) {
      final np = await askNewPassword(
        context,
        title: 'كلمة المرور الافتراضية غير آمنة',
        note: 'أدخل كلمة مرور جديدة من 10 أحرف على الأقل وتحتوي حروفاً وأرقاماً.',
      );
      if (np != null) await _submit(newPass: np);
      return;
    }
    toast(r, ToastType.err);
  }

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('دخول المدير')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 30, 20, 30),
        children: [
          Center(
            child: Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(color: p.soft, borderRadius: BorderRadius.circular(22)),
              child: Icon(Icons.lock_outline, size: 38, color: p.brandOn),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'الدخول إلى لوحة الإدارة مخصص للمدير فقط.',
            textAlign: TextAlign.center,
            style: TextStyle(color: p.muted, height: 1.6),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _user,
            textInputAction: TextInputAction.next,
            autocorrect: false,
            enableSuggestions: false,
            textDirection: TextDirection.ltr,
            decoration: fieldDeco(context, 'اسم المستخدم', icon: Icons.person_outline),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _pass,
            obscureText: _hide,
            autocorrect: false,
            enableSuggestions: false,
            textDirection: TextDirection.ltr,
            onSubmitted: (_) => _submit(),
            decoration: fieldDeco(context, 'كلمة المرور', icon: Icons.key_outlined).copyWith(
              suffixIcon: IconButton(
                icon: Icon(_hide ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                onPressed: () => setState(() => _hide = !_hide),
              ),
            ),
          ),
          const SizedBox(height: 20),
          PrimaryButton('دخول', icon: Icons.login, busy: _busy, onPressed: () => _submit()),
          if (_busy) ...[
            const SizedBox(height: 12),
            Text('جاري التحقق...', textAlign: TextAlign.center, style: TextStyle(color: p.muted)),
          ],
        ],
      ),
    );
  }
}

/// نافذة إدخال كلمة مرور جديدة مع التأكيد
Future<String?> askNewPassword(BuildContext context, {required String title, String note = ''}) async {
  final a = TextEditingController();
  final b = TextEditingController();
  final r = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title, style: const TextStyle(fontSize: 17)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (note.isNotEmpty) Text(note, style: const TextStyle(height: 1.6, fontSize: 13)),
            const SizedBox(height: 12),
            TextField(
              controller: a,
              obscureText: true,
              textDirection: TextDirection.ltr,
              decoration: fieldDeco(ctx, 'كلمة المرور الجديدة'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: b,
              obscureText: true,
              textDirection: TextDirection.ltr,
              decoration: fieldDeco(ctx, 'تأكيد كلمة المرور'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('إلغاء')),
        TextButton(
          onPressed: () {
            if (a.text != b.text) {
              toast('كلمتا المرور غير متطابقتين', ToastType.warn);
              return;
            }
            if (!validPassword(a.text)) {
              toast('10 أحرف على الأقل وتحتوي حروفاً وأرقاماً', ToastType.warn);
              return;
            }
            Navigator.of(ctx).pop(a.text);
          },
          child: const Text('حفظ', style: TextStyle(fontWeight: FontWeight.w800)),
        ),
      ],
    ),
  );
  a.dispose();
  b.dispose();
  return r;
}

void _go(BuildContext context, Widget page) {
  Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
}

// ======================= الصفحة الرئيسية للوحة =======================
class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  @override
  void initState() {
    super.initState();
    final s = AdminStore.I;
    if (!s.loaded) unawaited(s.load());
  }

  Future<void> _logout() async {
    await AdminStore.I.logout();
    if (!mounted) return;
    Navigator.of(context).pop();
    toast('تم تسجيل الخروج');
  }

  Future<void> _changePass() async {
    final np = await askNewPassword(context, title: 'تغيير كلمة المرور');
    if (np == null) return;
    final r = await AdminStore.I.changePassword(np);
    toast(r ?? 'تم تغيير كلمة المرور', r == null ? ToastType.ok : ToastType.err);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AdminStore.I,
      builder: (context, _) {
        final s = AdminStore.I;
        final p = Pal.of(context);
        final me = s.currentUser;
        if (me == null || (s.loaded && !s.sessionValid)) {
          return Scaffold(
            appBar: AppBar(title: const Text('لوحة الإدارة')),
            body: EmptyBox(
              'انتهت الجلسة — سجّل الدخول من جديد',
              icon: Icons.lock_clock_outlined,
              action: PrimaryButton('تسجيل الدخول', icon: Icons.login, onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
                );
              }),
            ),
          );
        }
        return Scaffold(
          appBar: AppBar(
            title: const Text('لوحة الإدارة'),
            actions: [
              IconButton(
                tooltip: 'تحديث',
                icon: const Icon(Icons.refresh),
                onPressed: s.loading ? null : () => s.load(),
              ),
              PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'pass') _changePass();
                  if (v == 'out') _logout();
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'pass', child: Text('تغيير كلمة المرور')),
                  PopupMenuItem(value: 'out', child: Text('تسجيل الخروج')),
                ],
              ),
            ],
          ),
          body: !s.loaded
              ? (s.loading
                  ? const Center(child: CircularProgressIndicator())
                  : EmptyBox(
                      s.error.isEmpty ? 'جاري التحميل...' : s.error,
                      icon: Icons.cloud_off,
                      action: PrimaryButton('إعادة المحاولة', icon: Icons.refresh, onPressed: () => s.load()),
                    ))
              : RefreshIndicator(
                  onRefresh: () => s.load(),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 30),
                    children: [
                      Text('أهلاً $me', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: p.text)),
                      const SizedBox(height: 4),
                      Text(
                        'التعديلات تُحفظ في قاعدة البيانات نفسها وتظهر للزوار وفي لوحة الويب.',
                        style: TextStyle(fontSize: 12, color: p.muted, height: 1.5),
                      ),
                      if (s.legacyFormat) ...[
                        const SizedBox(height: 12),
                        NoteBox(
                          child: Text(
                            'بيانات فايربيس بصيغة قديمة — افتح لوحة الإدارة في نسخة الويب مرة واحدة لترحيلها، ثم اسحب للتحديث هنا.',
                            style: TextStyle(color: p.text, height: 1.6, fontSize: 12.5),
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),
                      _sectionTitle(context, 'لوحة المعلومات'),
                      const SizedBox(height: 8),
                      const AdminDashboardWidgets(),
                      const SizedBox(height: 6),
                      _sectionTitle(context, 'المحتوى'),
                      const SizedBox(height: 8),
                      _tile(
                        context,
                        icon: Icons.table_rows_outlined,
                        color: const Color(0xFF10275E),
                        title: 'كل المحتوى',
                        sub: '${fmtNum(s.allCards.length)} عنصر — بحث وفلترة حسب القسم والحالة',
                        onTap: () => _go(context, const AdminContentScreen()),
                      ),
                      for (final c in s.categoryList)
                        _tile(
                          context,
                          icon: iconFromFa(str(c['icon'])),
                          color: hexColor(s.tintOf(c)[1]),
                          title: str(c['name']),
                          sub: '${fmtNum(s.countOf(str(c['key'])))} عنصر',
                          onTap: () => _go(context, AdminCardsScreen(catKey: str(c['key']))),
                        ),
                      _tile(
                        context,
                        icon: Icons.category_outlined,
                        color: const Color(0xFF334155),
                        title: 'إدارة الأقسام',
                        sub: '${fmtNum(s.categories.length)} قسم — الاسم والأيقونة واللون والصورة والترتيب',
                        onTap: () => _go(context, const AdminCategoriesScreen()),
                      ),
                      _tile(
                        context,
                        icon: Icons.map_outlined,
                        color: const Color(0xFF0F9D6E),
                        title: 'المحافظات والمراكز',
                        sub: '${fmtNum(s.geo.length)} محافظة',
                        onTap: () => _go(context, const AdminGeoScreen()),
                      ),
                      const SizedBox(height: 14),
                      _sectionTitle(context, 'المتابعة والتواصل'),
                      const SizedBox(height: 8),
                      _tile(
                        context,
                        icon: Icons.mark_email_unread_outlined,
                        color: const Color(0xFF2F6FE4),
                        title: 'الطلبات والاستفسارات',
                        sub: '${fmtNum(s.requests.length)} طلب — غير المقروءة: ${fmtNum(s.unreadRequests)}',
                        badge: s.unreadRequests,
                        onTap: () => _go(context, const AdminRequestsScreen()),
                      ),
                      _tile(
                        context,
                        icon: Icons.notifications_active_outlined,
                        color: const Color(0xFFF0A31B),
                        title: 'الإشعارات',
                        sub: '${fmtNum(s.notifications.length)} إشعار',
                        onTap: () => _go(context, const AdminNotificationsScreen()),
                      ),
                      _tile(
                        context,
                        icon: Icons.campaign_outlined,
                        color: const Color(0xFFDB2777),
                        title: 'اللوحات الإعلانية',
                        sub: '${fmtNum(s.ads.length)} لوحة — ورسالة الترحيب',
                        onTap: () => _go(context, const AdminAdsScreen()),
                      ),
                      _tile(
                        context,
                        icon: Icons.insights_outlined,
                        color: const Color(0xFF8B5CF6),
                        title: 'الإحصائيات',
                        sub: 'أرقام الواجهة وتوزيع المحتوى والعدادات',
                        onTap: () => _go(context, const AdminStatsScreen()),
                      ),
                      const SizedBox(height: 14),
                      _sectionTitle(context, 'النظام'),
                      const SizedBox(height: 8),
                      _tile(
                        context,
                        icon: Icons.storage_outlined,
                        color: const Color(0xFFF2711C),
                        title: 'قواعد البيانات',
                        sub: 'Firebase و Supabase والنسخ الاحتياطي',
                        onTap: () => _go(context, const AdminDatabaseScreen()),
                      ),
                      _tile(
                        context,
                        icon: Icons.settings_outlined,
                        color: const Color(0xFF64748B),
                        title: 'الإعدادات',
                        sub: 'هوية المنصة، التواصل، الخلفيات والمظهر',
                        onTap: () => _go(context, const AdminSettingsScreen()),
                      ),
                      _tile(
                        context,
                        icon: Icons.manage_accounts_outlined,
                        color: const Color(0xFF5B5BD6),
                        title: 'المستخدمون',
                        sub: '${fmtNum(s.users.length)} حساب إداري',
                        onTap: () => _go(context, const AdminUsersScreen()),
                      ),
                      _tile(
                        context,
                        icon: Icons.photo_library_outlined,
                        color: const Color(0xFF0EA5E9),
                        title: 'مكتبة الوسائط',
                        sub: 'الصور المرفوعة إلى Supabase',
                        onTap: () => _go(context, const AdminMediaScreen()),
                      ),
                      _tile(
                        context,
                        icon: Icons.history,
                        color: const Color(0xFF94A3B8),
                        title: 'سجل النشاطات',
                        sub: '${fmtNum(s.activity.length)} نشاط',
                        onTap: () => _go(context, const AdminActivityScreen()),
                      ),
                      const SizedBox(height: 14),
                      _sectionTitle(context, 'آخر النشاطات'),
                      const SizedBox(height: 6),
                      if (s.activityList.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text('السجل فارغ.', style: TextStyle(color: p.muted)),
                        ),
                      for (final a in s.activityList.take(4))
                        ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.history, color: p.muted, size: 20),
                          title: Text(str(a['text']), style: TextStyle(fontSize: 13, color: p.text)),
                          subtitle: Text(
                            '${str(a['by'])} · ${timeAgo(str(a['at']))}',
                            style: TextStyle(fontSize: 11, color: p.muted),
                          ),
                        ),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _sectionTitle(BuildContext context, String t) {
    final p = Pal.of(context);
    return Text(t, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: p.brandOn));
  }

  Widget _tile(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String sub,
    required VoidCallback onTap,
    int badge = 0,
  }) {
    final p = Pal.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: p.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: p.border),
        ),
        child: ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          onTap: onTap,
          leading: CircleAvatar(
            backgroundColor: p.soft,
            child: Icon(icon, color: color, size: 22),
          ),
          title: Text(title, style: TextStyle(fontWeight: FontWeight.w800, color: p.text)),
          subtitle: Text(sub, style: TextStyle(fontSize: 12, color: p.muted)),
          trailing: badge > 0
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFB42318),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$badge',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12),
                  ),
                )
              : Icon(Icons.chevron_left, color: p.muted),
        ),
      ),
    );
  }
}
