// جولة فحص تلقائية لنسخة الآيفون/الآيباد على محاكي أبل (تعمل من GitHub Actions ← Test iOS):
// تشغيل التطبيق، تحميل البيانات من فايربيس، كل التبويبات، قسم وعنصر وتفاصيله، القسم الهرمي،
// البحث، الوضع الليلي، صفحات المزيد، وشاشة دخول المدير — مع صورة لكل شاشة وتقرير بالنتائج.
// ignore_for_file: avoid_print

import 'package:bosla_student/admin/admin_entry.dart';
import 'package:bosla_student/app_state.dart';
import 'package:bosla_student/config.dart';
import 'package:bosla_student/main.dart' as app;
import 'package:bosla_student/models.dart';
import 'package:bosla_student/screens/category_screen.dart';
import 'package:bosla_student/screens/detail_screen.dart';
import 'package:bosla_student/screens/home_screen.dart';
import 'package:bosla_student/screens/more_screen.dart';
import 'package:bosla_student/screens/search_screen.dart';
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

  // التبويبات محفوظة في IndexedStack (المخفية منها تبقى في الشجرة)، لذلك كل بحث وتمرير محصور
  // داخل الشاشة الظاهرة حالياً
  Finder vScroll(Finder inside) => find.descendant(
        of: inside,
        matching: find.byWidgetPredicate(
            (w) => w is Scrollable && axisDirectionToAxis(w.axisDirection) == Axis.vertical),
      );

  Finder inScreen(Finder screen, Finder f) => find.descendant(of: screen, matching: f);

  // بطاقة عنصر: ItemCard للأقسام العادية و TeacherTile لشبكة المدرسين
  Finder cardFinder() => find.byWidgetPredicate((w) => w is ItemCard || w is TeacherTile);

  Future<bool> scrollTo(WidgetTester t, Finder screen, Finder f) async {
    if (f.evaluate().isNotEmpty) return true;
    final sc = vScroll(screen);
    if (sc.evaluate().isEmpty) return false;
    try {
      await t.scrollUntilVisible(f, 250, scrollable: sc.first, maxScrolls: 40);
    } catch (_) {}
    return f.evaluate().isNotEmpty;
  }

  Future<void> toTop(WidgetTester t, Finder screen) async {
    final sc = vScroll(screen);
    if (sc.evaluate().isEmpty) return;
    try {
      await t.drag(sc.first, const Offset(0, 6000));
    } catch (_) {}
    await wait(t, 600);
  }

  Finder navTab(String label) =>
      find.descendant(of: find.byType(NavigationBar), matching: find.text(label));

  Finder resultsCount() => find.byWidgetPredicate(
      (w) => w is Text && RegExp(r'^[1-9][0-9]* نتيجة$').hasMatch(w.data ?? ''));

  /// يفتح قسماً من الرئيسية ويعيد true إن فُتحت شاشته
  Future<bool> openCategory(WidgetTester t, String name) async {
    final home = find.byType(HomeScreen);
    await toTop(t, home);
    final f = inScreen(home, find.text(name));
    if (!await scrollTo(t, home, f)) return false;
    await tapIn(t, f);
    return waitFor(t, find.byType(CategoryScreen), seconds: 10);
  }

  /// ينتظر ظهور عناصر في شاشة القسم ويفتح أول عنصر
  Future<void> openFirstCard(WidgetTester t, String label) async {
    final cat = find.byType(CategoryScreen);
    final card = inScreen(cat, cardFinder());
    final shown = await waitFor(t, card, seconds: 15) || await scrollTo(t, cat, card);
    check(shown, 'عناصر $label ظهرت');
    if (!shown) return;
    await tapIn(t, card);
    final opened = await waitFor(t, find.byType(DetailScreen), seconds: 10);
    check(opened, 'صفحة تفاصيل عنصر من $label فتحت');
    if (opened) {
      await wait(t, 2000);
      await shot(t, 'detail-$label');
      try {
        await t.drag(vScroll(find.byType(DetailScreen)).first, const Offset(0, -900));
        await shot(t, 'detail-$label-more');
      } catch (_) {}
      await back(t);
    }
  }

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
        await t.drag(vScroll(find.byType(HomeScreen)).first, const Offset(0, -700));
      } catch (_) {}
      await shot(t, 'home-scrolled');
      await toTop(t, find.byType(HomeScreen));

      // ---------- المدرسون: الاختصاصات ثم العناصر ثم التفاصيل ----------
      final teachers = AppState.I.catByKey('مدرسين');
      if (teachers != null) {
        final opened = await openCategory(t, teachers.name);
        check(opened, 'فتح قسم «${teachers.name}»');
        if (opened) {
          await wait(t, 2500);
          await shot(t, 'teachers-specialties');
          final cat = find.byType(CategoryScreen);
          var tapped = false;
          for (final sp in AppState.I.specialtyList('مدرسين')) {
            final f = inScreen(cat, find.text(sp));
            if (f.evaluate().isNotEmpty) {
              await tapIn(t, f);
              tapped = true;
              await shot(t, 'teachers-list');
              break;
            }
          }
          check(tapped, 'اختيار اختصاص في قسم المدرسين');
          if (tapped) await openFirstCard(t, 'المدرسين');
          // الرجوع من قائمة الاختصاص ثم من القسم إلى الرئيسية
          while (navigatorKey.currentState?.canPop() ?? false) {
            await back(t);
          }
        }
      }

      // ---------- قسم عادي فيه عناصر ----------
      AppCategory? plain;
      for (final c in cats) {
        if (c.key != 'مدرسين' &&
            !c.hier &&
            !Cfg.publicSections.containsKey(c.key) &&
            AppState.I.catCount(c.key) > 0) {
          plain = c;
          break;
        }
      }
      if (plain != null) {
        final opened = await openCategory(t, plain.name);
        check(opened, 'فتح قسم «${plain.name}»');
        if (opened) {
          await wait(t, 2500);
          await shot(t, 'category-${plain.key}');
          await openFirstCard(t, plain.name);
          while (navigatorKey.currentState?.canPop() ?? false) {
            await back(t);
          }
        }
      }

      // ---------- المعاهد والمدارس (حسب المنطقة / المحافظة) ----------
      for (final c in cats.where((c) => Cfg.publicSections.containsKey(c.key))) {
        final opened = await openCategory(t, c.name);
        check(opened, 'فتح قسم «${c.name}»');
        if (!opened) continue;
        await wait(t, 4000);
        await shot(t, 'cat-${c.key}');
        final cat = find.byType(CategoryScreen);
        // المدارس: المحافظة أولاً
        final gov = inScreen(cat, find.text(Cfg.maysanGov));
        if (gov.evaluate().isNotEmpty) {
          await tapIn(t, gov);
          await wait(t, 2000);
          await shot(t, 'cat-${c.key}-gov');
        }
        var area = false;
        for (final a in Cfg.maysanAreas) {
          final f = inScreen(cat, find.text(a));
          if (f.evaluate().isNotEmpty) {
            await tapIn(t, f);
            area = true;
            break;
          }
        }
        check(area, 'اختيار منطقة في قسم «${c.name}»');
        if (area) {
          await wait(t, 3000);
          await shot(t, 'cat-${c.key}-area');
          final card = inScreen(cat, cardFinder());
          final empty = find.textContaining('لا ').evaluate().isNotEmpty;
          check(await waitFor(t, card, seconds: 12) || empty, 'عناصر «${c.name}» في المنطقة تظهر');
        }
        // الرجوع إلى الرئيسية
        while (navigatorKey.currentState?.canPop() ?? false) {
          await back(t);
        }
      }

      // ---------- البحث ----------
      if (await tapIn(t, find.byTooltip('بحث'))) {
        final search = find.byType(SearchScreen);
        final field = inScreen(search, find.byType(TextField));
        if (field.evaluate().isNotEmpty) {
          final sample = AppState.I.publicCards.isNotEmpty ? AppState.I.publicCards.first.name : 'مدرس';
          final q = sample.length > 4 ? sample.substring(0, 4) : sample;
          await t.enterText(field.first, q);
          await wait(t, 2500);
          FocusManager.instance.primaryFocus?.unfocus();
          await wait(t, 800);
          check(await waitFor(t, inScreen(search, resultsCount()), seconds: 8), 'البحث يعطي نتائج («$q»)');
          await shot(t, 'search');
        } else {
          problems.add('حقل البحث غير موجود');
        }
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
      final more = find.byType(MoreScreen);
      check(inScreen(more, find.text('عن الشركة المطوّرة')).evaluate().isEmpty &&
              !await scrollTo(t, more, inScreen(more, find.text('عن الشركة المطوّرة'))),
          '«عن الشركة المطوّرة» مخفية في الآيفون');
      await shot(t, 'more-bottom');
      await toTop(t, more);

      final darkTile = inScreen(more, find.text('الوضع الليلي'));
      if (await scrollTo(t, more, darkTile)) {
        await tapIn(t, darkTile);
        await wait(t, 1200);
        await shot(t, 'dark-mode');
        check(AppState.I.isDark, 'الوضع الليلي يعمل');
        await tapIn(t, darkTile);
      }

      final privacy = inScreen(more, find.text('سياسة الخصوصية'));
      if (await scrollTo(t, more, privacy) && await tapIn(t, privacy)) {
        await wait(t, 1500);
        await shot(t, 'privacy');
        check(navigatorKey.currentState!.canPop(), 'صفحة سياسة الخصوصية تفتح');
        await back(t);
      } else {
        problems.add('سياسة الخصوصية غير موجودة في المزيد');
      }

      final about = inScreen(more, find.text('عن التطبيق'));
      if (await scrollTo(t, more, about) && await tapIn(t, about)) {
        await wait(t, 1500);
        await shot(t, 'about-app');
        await back(t);
      }

      // ---------- دخول المدير ----------
      final adminBtn = inScreen(more, find.text('دخول المدير'));
      final adminVisible = await scrollTo(t, more, adminBtn);
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
            try {
              await t.drag(vScroll(find.byType(AdminHomeScreen)).first, const Offset(0, -900));
              await shot(t, 'admin-demo-sections');
            } catch (_) {}
          }
        }
        await back(t);
      }
    } finally {
      FlutterError.onError = originalOnError;
      // لا تحذف صور الشاشات المحفوظة في reportData
      binding.reportData = <String, dynamic>{
        ...?binding.reportData,
        'passed': passed,
        'problems': problems,
        'flutterErrors': errors,
      };
      print('IOS-CHECK SUMMARY passed=${passed.length} problems=${problems.length} errors=${errors.length}');
    }
    expect(problems, isEmpty, reason: problems.join(' | '));
  });
}
