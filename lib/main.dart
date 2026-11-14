// بوصلة الطالب — تطبيق Flutter أصلي
// نقطة البداية: التهيئة، السمة (كحلي/ذهبي، خط Cairo، RTL)، والهيكل الرئيسي بشريط التنقل السفلي

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_state.dart';
import 'notifs.dart';
import 'screens/compare_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/home_screen.dart';
import 'screens/more_screen.dart';
import 'screens/my_requests_screen.dart';
import 'screens/tools_screen.dart';
import 'store.dart';
import 'ui.dart';
import 'widgets/common.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Store.init();
  await Notifs.init();
  await AppState.I.init();
  runApp(const BoslaApp());
}

final Map<String, ThemeData> _themeCache = {};

ThemeData buildTheme(bool dark, Color brand) {
  final key = '$dark-${brand.value}';
  final hit = _themeCache[key];
  if (hit != null) return hit;
  final brightness = dark ? Brightness.dark : Brightness.light;
  final scheme = ColorScheme.fromSeed(seedColor: brand, brightness: brightness);
  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: dark ? scheme.copyWith(primary: const Color(0xFFF3D98A)) : scheme.copyWith(primary: brand),
    scaffoldBackgroundColor: dark ? const Color(0xFF0D1425) : const Color(0xFFFAFBFD),
    fontFamily: GoogleFonts.cairo().fontFamily,
    splashFactory: InkRipple.splashFactory,
  );
  final t = base.copyWith(
    textTheme: GoogleFonts.cairoTextTheme(base.textTheme),
    primaryTextTheme: GoogleFonts.cairoTextTheme(base.primaryTextTheme),
  );
  _themeCache[key] = t;
  return t;
}

class BoslaApp extends StatelessWidget {
  const BoslaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.I,
      builder: (context, _) {
        final s = AppState.I;
        final brand = s.settings.brand;
        return MaterialApp(
          title: s.settings.siteName,
          debugShowCheckedModeBanner: false,
          navigatorKey: navigatorKey,
          scaffoldMessengerKey: messengerKey,
          locale: const Locale('ar'),
          supportedLocales: const [Locale('ar')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: buildTheme(false, brand),
          darkTheme: buildTheme(true, brand),
          themeMode: s.isDark ? ThemeMode.dark : ThemeMode.light,
          home: const RootShell(),
        );
      },
    );
  }
}

/// الهيكل الرئيسي: خمسة تبويبات سفلية كما في نسخة التطبيق على الويب
class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      AppState.I.onResume();
    } else if (state == AppLifecycleState.paused) {
      AppState.I.onPause();
    }
  }

  void _select(int i) {
    rootTab.value = i;
    if (i == 2) AppState.I.markBookingsSeen();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([AppState.I, rootTab]),
      builder: (context, _) {
        final s = AppState.I;
        final p = Pal.of(context);
        final i = rootTab.value;
        final cmp = s.compareIds.length;
        final unseen = s.unseenBookings;
        return Scaffold(
          body: Column(
            children: [
              Expanded(
                child: IndexedStack(
                  index: i,
                  children: const [
                    HomeScreen(),
                    FavoritesScreen(),
                    MyRequestsScreen(),
                    ToolsScreen(),
                    MoreScreen(),
                  ],
                ),
              ),
              if (!s.cloudUp) const OfflineBar(),
            ],
          ),
          floatingActionButton: cmp > 0 && i != 3
              ? FloatingActionButton.extended(
                  heroTag: 'cmpTray',
                  backgroundColor: p.brand,
                  foregroundColor: Colors.white,
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CompareScreen()),
                  ),
                  icon: const Icon(Icons.balance),
                  label: Text('قارن ($cmp)', style: const TextStyle(fontWeight: FontWeight.w800)),
                )
              : null,
          bottomNavigationBar: NavigationBar(
            selectedIndex: i,
            onDestinationSelected: _select,
            height: 66,
            backgroundColor: p.card,
            indicatorColor: p.dark ? const Color(0xFF2A3A58) : const Color(0xFFE4ECFB),
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'الرئيسية',
              ),
              const NavigationDestination(
                icon: Icon(Icons.favorite_border),
                selectedIcon: Icon(Icons.favorite),
                label: 'المفضلة',
              ),
              NavigationDestination(
                icon: Badge(
                  isLabelVisible: unseen > 0,
                  label: Text('$unseen'),
                  child: const Icon(Icons.assignment_outlined),
                ),
                selectedIcon: const Icon(Icons.assignment),
                label: 'طلباتي',
              ),
              const NavigationDestination(
                icon: Icon(Icons.home_repair_service_outlined),
                selectedIcon: Icon(Icons.home_repair_service),
                label: 'أدواتي',
              ),
              const NavigationDestination(
                icon: Icon(Icons.menu),
                selectedIcon: Icon(Icons.menu_open),
                label: 'المزيد',
              ),
            ],
          ),
        );
      },
    );
  }
}
