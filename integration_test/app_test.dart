// جولة فحص تلقائية لنسخة الآيفون/الآيباد على محاكي أبل (تعمل من GitHub Actions ← Test iOS):
// تشغيل التطبيق، تحميل البيانات من فايربيس، كل التبويبات، قسم وعنصر وتفاصيله، القسم الهرمي،
// البحث، الوضع الليلي، صفحات المزيد، وشاشة دخول المدير — مع صورة لكل شاشة وتقرير بالنتائج.
// ignore_for_file: avoid_print

import 'package:bosla_student/admin/admin_entry.dart';
import 'package:bosla_student/app_state.dart';
import 'package:bosla_student/config.dart';
import 'package:bosla_student/main.dart' as app;
import 'package:bosla_student/models.dart';
import 'package:bosla_student/screens/detail_screen.dart';
import 'package:bosla_student/ui.dart';
import 'package:bosla_student/widgets/common.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

// حساب تجريبي اختياري (من أسرار المستودع DEMO_USER و DEMO_PASS) لفحص وضع «عرض فقط»
const String _demoUser = String.fromEnvironment('DEMO_USER');
const String _demoPass = String.fromEnvironment('DEMO_PASS');

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final passed = <String>[];
  final problems = <String>[];
  final errors = <String>[];
  var shotNo = 0;

  void check(bool ok, String what) {
    (ok ? passed : problems).add(what);
    print('IOS-CHECK ${ok ? 'OK  ' : 'FAIL'} $what');
  }

  Future<void> wait(WidgetTester t, [int ms = 1500]) async {
    final end = DateTime.now().add(Duration(milliseconds: ms));
    while (DateTime.now().isBefore(end)) {
      await t.pump(const Duration(milliseconds: 100));
    }
  }

  Future<bool> waitFor(WidgetTester t, Finder f, {int seconds = 25}) async {
    final end = DateTime.now().add(Duration(seconds: seconds));
    while (DateTime.now().isBefore(end)) {
      await t.pump(const Duration(milliseconds: 200));
      if (f.evaluate().isNotEmpty) return true;
    }
    return false;
  }

  Future<void> shot(WidgetTester t, String name) async {
    shotNo++;
    final id = '${shotNo.toString().padLeft(2, '0')}-$name';
    await wait(t, 600);
    try {
      await binding.takeScreenshot(id);
    } catch (e) {
      print('IOS-CHECK WARN screenshot $id: $e');
    }
  }

  Future<void> back(WidgetTester t) async {
    await navigatorKey.currentState?.maybePop();
    await wait(t, 1200);
  }

  Future<bool> tapIn(WidgetTester t, Finder f) async {
    if (f.evaluate().isEmpty) return false;
    try {
      await t.ensureVisible(f.first);
    } catch (_) {}
    await t.tap(f.first, warnIfMissed: false);
    await wait(t, 1500);
    return true;
  }

  Future<bool> scrollTo(WidgetTester t, Finder f) async {
    if (f.evaluate().isNotEmpty) return true;
    final scrollables = find.byType(Scrollable);
    if (scrollables.evaluate().isEmpty) return false;
    try {
      await t.scrollUntilVisible(f, 250, scrollable: scrollables.first, maxScrolls: 40);
    } catch (_) {}
    return f.evaluate().isNotEmpty;
  }

  Finder navTab(String label) =>
      find.descendant(of: find.byType(NavigationBar), matching: find.text(label));

  testWidgets('جولة كاملة في التطبيق على محاكي أبل', (t) async {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (d) {
      final msg = d.exceptionAsString().split('\n').first;
      errors.add(msg);
      print('IOS-CHECK ERROR $msg');
    };
    try {
      check(defaultTargetPlatform == TargetPlatform.iOS, 'التطبيق يعمل كنسخة iOS');

      // ---------- التشغيل ----------
      app.main();
      final started = await waitFor(t, find.byType(NavigationBar), seconds: 60);
      check(started, 'التطبيق اشتغل وظهرت الواجهة الرئيسية');
      if (!started) return;
      await wait(t, 6000);
      check(AppState.I.cloudUp, 'الاتصال بقاعدة البيانات (فايربيس) يعمل');
      final cats = AppState.I.data.categories;
      check(cats.isNotEmpty, 'الأقسام ظهرت (${cats.length} قسم)');
      check(AppState.I.publicCards.isNotEmpty, 'بيانات العناصر تحمّلت (${AppState.I.publicCards.length} عنصر)');
      await shot(t, 'home');
      try {
        await t.drag(find.byType(Scrollable).first, const Offset(0, -700));
      } catch (_) {}
      await shot(t, 'home-scrolled');
      try {
        await t.drag(find.byType(Scrollable).first, const Offset(0, 3000));
      } catch (_) {}
      await wait(t, 800);

      // ---------- قسم عادي وعنصر وتفاصيله ----------
      AppCategory? pick;
      for (final c in cats) {
        if (!Cfg.publicSections.containsKey(c.key) && AppState.I.catCount(c.key) > 0) {
          pick = c;
          break;
        }
      }
      if (pick != null) {
        final opened = await scrollTo(t, find.text(pick.name)) && await tapIn(t, find.text(pick.name));
        check(opened, 'فتح قسم «${pick.name}»');
        if (opened) {
          await wait(t, 2500);
          await shot(t, 'category');
          final hasCards = await waitFor(t, find.byType(ItemCard), seconds: 15);
          check(hasCards, 'عناصر قسم «${pick.name}» ظهرت');
          if (hasCards && await tapIn(t, find.byType(ItemCard))) {
            await wait(t, 2500);
            await shot(t, 'detail');
            check(find.byType(DetailScreen).evaluate().isNotEmpty, 'صفحة تفاصيل العنصر فتحت');
            await back(t);
          }
          await back(t);
        }
      } else {
        problems.add('لا يوجد قسم عادي فيه عناصر للفحص');
      }

      // ---------- قسم هرمي (المدارس / المعاهد) ----------
      String? hierName;
      for (final c in cats) {
        if (Cfg.publicSections.containsKey(c.key)) {
          hierName = c.name;
          break;
        }
      }
      if (hierName != null) {
        final opened = await scrollTo(t, find.text(hierName)) && await tapIn(t, find.text(hierName));
        check(opened, 'فتح قسم «$hierName» (تصفّح حسب المحافظة والمنطقة)');
        if (opened) {
          await wait(t, 4000);
          await shot(t, 'hier-gov');
          if (await tapIn(t, find.text(Cfg.maysanGov))) {
            await wait(t, 2500);
            await shot(t, 'hier-areas');
            await back(t);
          }
          await back(t);
        }
      }

      // ---------- البحث ----------
      if (await tapIn(t, find.byTooltip('بحث'))) {
        final field = find.byType(TextField);
        if (field.evaluate().isNotEmpty) {
          final sample = AppState.I.publicCards.isNotEmpty ? AppState.I.publicCards.first.name : 'مدرس';
          final q = sample.length > 4 ? sample.substring(0, 4) : sample;
          await t.enterText(field.first, q);
          await wait(t, 2500);
          check(find.byType(ItemCard).evaluate().isNotEmpty, 'البحث يعطي نتائج («$q»)');
          await shot(t, 'search');
        } else {
          problems.add('حقل البحث غير موجود');
        }
        FocusManager.instance.primaryFocus?.unfocus();
        await back(t);
      } else {
        problems.add('زر البحث غير موجود');
      }

      // ---------- التبويبات ----------
      for (final tab in ['المفضلة', 'طلباتي', 'أدواتي', 'المزيد']) {
        final ok = await tapIn(t, navTab(tab));
        check(ok, 'تبويب «$tab» يفتح');
        await wait(t, 1200);
        await shot(t, 'tab-$tab');
      }

      // ---------- المزيد ----------
      check(find.text('عن الشركة المطوّرة').evaluate().isEmpty &&
              !await scrollTo(t, find.text('عن الشركة المطوّرة')),
          '«عن الشركة المطوّرة» مخفية في الآيفون');
      await t.drag(find.byType(Scrollable).first, const Offset(0, 4000));
      await wait(t, 600);

      if (await scrollTo(t, find.text('الوضع الليلي'))) {
        await tapIn(t, find.text('الوضع الليلي'));
        await wait(t, 1200);
        await shot(t, 'dark-mode');
        await tapIn(t, find.text('الوضع الليلي'));
      }

      if (await scrollTo(t, find.text('سياسة الخصوصية')) && await tapIn(t, find.text('سياسة الخصوصية'))) {
        await wait(t, 1500);
        await shot(t, 'privacy');
        check(navigatorKey.currentState!.canPop(), 'صفحة سياسة الخصوصية تفتح');
        await back(t);
      }

      if (await scrollTo(t, find.text('عن التطبيق')) && await tapIn(t, find.text('عن التطبيق'))) {
        await wait(t, 1500);
        await shot(t, 'about-app');
        await back(t);
      }

      // ---------- دخول المدير ----------
      final adminBtn = find.text('دخول المدير');
      final adminVisible = await scrollTo(t, adminBtn);
      check(adminVisible, 'زر «دخول المدير» ظاهر في المزيد');
      if (adminVisible && await tapIn(t, adminBtn)) {
        await wait(t, 1500);
        final fields = find.byType(TextField);
        check(fields.evaluate().length >= 2, 'شاشة دخول المدير تفتح');
        await shot(t, 'admin-login');
        if (fields.evaluate().length >= 2) {
          await t.enterText(fields.at(0), 'ios_probe_user');
          await t.enterText(fields.at(1), 'WrongPass2026');
          FocusManager.instance.primaryFocus?.unfocus();
          await wait(t, 500);
          await tapIn(t, find.text('دخول'));
          final rejected = await waitFor(t, find.textContaining('غير صحيحة'), seconds: 40);
          check(rejected, 'رفض بيانات دخول خاطئة (والتحقق من فايربيس يعمل)');
          await shot(t, 'admin-wrong-pass');

          if (_demoUser.isNotEmpty && _demoPass.isNotEmpty) {
            await wait(t, 4000);
            await t.enterText(fields.at(0), _demoUser);
            await t.enterText(fields.at(1), _demoPass);
            FocusManager.instance.primaryFocus?.unfocus();
            await tapIn(t, find.text('دخول'));
            final inPanel = await waitFor(t, find.byType(AdminHomeScreen), seconds: 40);
            check(inPanel, 'الحساب التجريبي يدخل لوحة الإدارة');
            await wait(t, 3000);
            check(find.textContaining('حساب تجريبي للعرض فقط').evaluate().isNotEmpty,
                'لوحة الحساب التجريبي تعرض «عرض فقط»');
            await shot(t, 'admin-demo-home');
            await t.drag(find.byType(Scrollable).first, const Offset(0, -900));
            await shot(t, 'admin-demo-sections');
          }
        }
        await back(t);
      }
    } finally {
      FlutterError.onError = originalOnError;
      binding.reportData = <String, dynamic>{
        'passed': passed,
        'problems': problems,
        'flutterErrors': errors,
      };
      print('IOS-CHECK SUMMARY passed=${passed.length} problems=${problems.length} errors=${errors.length}');
    }
    expect(problems, isEmpty, reason: problems.join(' | '));
  });
}
