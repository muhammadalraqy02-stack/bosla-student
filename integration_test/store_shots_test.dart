// صور ومقطع المتجر (App Store): يتنقّل في واجهة الزائر ويطبع علامات يلتقط عندها سكربت
// الـ workflow صوراً حقيقية من شاشة المحاكي (مع شريط الحالة) ويسجّل فيديو المعاينة.
// يعمل من GitHub Actions ← Store assets (iOS).
// ignore_for_file: avoid_print

import 'package:bosla_student/app_state.dart';
import 'package:bosla_student/config.dart';
import 'package:bosla_student/main.dart' as app;
import 'package:bosla_student/screens/category_screen.dart';
import 'package:bosla_student/screens/detail_screen.dart';
import 'package:bosla_student/screens/home_screen.dart';
import 'package:bosla_student/screens/search_screen.dart';
import 'package:bosla_student/ui.dart';
import 'package:bosla_student/widgets/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> wait(WidgetTester t, [int ms = 1500]) async {
    final end = DateTime.now().add(Duration(milliseconds: ms));
    while (DateTime.now().isBefore(end)) {
      await t.pump(const Duration(milliseconds: 33));
    }
  }

  Future<bool> waitFor(WidgetTester t, Finder f, {int seconds = 20}) async {
    final end = DateTime.now().add(Duration(seconds: seconds));
    while (DateTime.now().isBefore(end)) {
      await t.pump(const Duration(milliseconds: 100));
      if (f.evaluate().isNotEmpty) return true;
    }
    return false;
  }

  Finder vScroll(Finder inside) => find.descendant(
        of: inside,
        matching: find.byWidgetPredicate(
            (w) => w is Scrollable && axisDirectionToAxis(w.axisDirection) == Axis.vertical),
      );

  Finder inScreen(Finder screen, Finder f) => find.descendant(of: screen, matching: f);

  // يطبع علامة الصورة ثم ينتظر حتى يلتقطها السكربت من شاشة المحاكي
  Future<void> shot(WidgetTester t, String name) async {
    FocusManager.instance.primaryFocus?.unfocus();
    await wait(t, 2500);
    print('STORESHOT:$name');
    await wait(t, 4000);
  }

  Future<void> smooth(WidgetTester t, Finder screen, double dy, {int ms = 1600}) async {
    final sc = vScroll(screen);
    if (sc.evaluate().isEmpty) return;
    try {
      await t.timedDrag(sc.first, Offset(0, dy), Duration(milliseconds: ms));
    } catch (_) {}
    await wait(t, 700);
  }

  Future<void> tap(WidgetTester t, Finder f, [int after = 1800]) async {
    if (f.evaluate().isEmpty) return;
    try {
      await t.ensureVisible(f.first);
    } catch (_) {}
    await t.tap(f.first, warnIfMissed: false);
    await wait(t, after);
  }

  Future<void> back(WidgetTester t) async {
    await navigatorKey.currentState?.maybePop();
    await wait(t, 1200);
  }

  Future<bool> openCat(WidgetTester t, String key) async {
    final c = AppState.I.catByKey(key);
    if (c == null) return false;
    final home = find.byType(HomeScreen);
    final f = inScreen(home, find.text(c.name));
    if (f.evaluate().isEmpty) {
      try {
        await t.scrollUntilVisible(f, 250, scrollable: vScroll(home).first, maxScrolls: 30);
      } catch (_) {}
    }
    await tap(t, f);
    return waitFor(t, find.byType(CategoryScreen), seconds: 8);
  }

  Future<bool> pickSpecialty(WidgetTester t) async {
    final cat = find.byType(CategoryScreen);
    for (final sp in AppState.I.specialtyList('مدرسين')) {
      final f = inScreen(cat, find.text(sp));
      if (f.evaluate().isNotEmpty) {
        await tap(t, f, 2500);
        return true;
      }
    }
    return false;
  }

  testWidgets('صور ومقطع المتجر', (t) async {
    app.main();
    await waitFor(t, find.byType(NavigationBar), seconds: 60);
    await wait(t, 9000);
    final home = find.byType(HomeScreen);

    // ================= الصور =================
    await shot(t, '01-home');
    await smooth(t, home, -1250);
    await shot(t, '02-categories');
    await smooth(t, home, 6000, ms: 600);

    if (await openCat(t, 'مدرسين')) {
      await wait(t, 2000);
      await shot(t, '03-teachers-specialties');
      if (await pickSpecialty(t)) {
        await shot(t, '04-teachers-list');
        final card = inScreen(find.byType(CategoryScreen), find.byType(ItemCard));
        if (await waitFor(t, card, seconds: 10)) {
          await tap(t, card, 2500);
          if (await waitFor(t, find.byType(DetailScreen), seconds: 8)) {
            await shot(t, '05-teacher-detail');
            await back(t);
          }
        }
        await back(t);
      }
      await back(t);
    }

    if (await openCat(t, 'معاهد')) {
      await wait(t, 4000);
      await shot(t, '06-institutes-areas');
      await back(t);
    }

    await tap(t, find.byTooltip('بحث'));
    final search = find.byType(SearchScreen);
    final field = inScreen(search, find.byType(TextField));
    if (field.evaluate().isNotEmpty) {
      await t.enterText(field.first, 'رياضيات');
      await wait(t, 2000);
      await shot(t, '07-search');
    }
    await back(t);

    await tap(t, find.descendant(of: find.byType(NavigationBar), matching: find.text('أدواتي')));
    await shot(t, '08-tools');
    await tap(t, find.descendant(of: find.byType(NavigationBar), matching: find.text('الرئيسية')));

    await AppState.I.toggleTheme();
    await wait(t, 1500);
    await shot(t, '09-dark-home');
    await AppState.I.toggleTheme();
    await wait(t, 1500);

    // ================= مقطع المعاينة (حوالي 25 ثانية) =================
    await smooth(t, home, 6000, ms: 500);
    await wait(t, 1500);
    print('STOREVIDEO:start');
    await wait(t, 2500);
    await smooth(t, home, -700, ms: 2200);
    await smooth(t, home, -700, ms: 2200);
    await smooth(t, home, 2000, ms: 900);
    if (await openCat(t, 'مدرسين')) {
      await wait(t, 1500);
      if (await pickSpecialty(t)) {
        final card = inScreen(find.byType(CategoryScreen), find.byType(ItemCard));
        if (await waitFor(t, card, seconds: 6)) {
          await tap(t, card, 2500);
          await smooth(t, find.byType(DetailScreen), -600, ms: 2000);
          await wait(t, 1200);
          await back(t);
        }
        await back(t);
      }
      await back(t);
    }
    if (await openCat(t, 'معاهد')) {
      await wait(t, 2500);
      final cat = find.byType(CategoryScreen);
      for (final a in Cfg.maysanAreas) {
        final f = inScreen(cat, find.text(a));
        if (f.evaluate().isNotEmpty) {
          await tap(t, f, 3000);
          break;
        }
      }
      await back(t);
      await back(t);
    }
    await wait(t, 1000);
    print('STOREVIDEO:stop');
    await wait(t, 3000);
    print('STOREDONE');
  });
}
