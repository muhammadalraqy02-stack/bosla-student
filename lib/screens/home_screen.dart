// الصفحة الرئيسية: الترويسة، التاريخ والوقت، الواجهة (Hero) مع البحث، الأقسام،
// الاختصارات السريعة، لوحة الترحيب والإعلانات، ومزايا الدليل

import 'dart:async';

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../config.dart';
import '../models.dart';
import '../ui.dart';
import '../utils.dart';
import '../widgets/app_image.dart';
import '../widgets/common.dart';
import 'category_screen.dart';
import 'compare_screen.dart';
import 'nearby_screen.dart';
import 'notifications_screen.dart';
import 'search_screen.dart';
import 'suggest_screen.dart';

void _push(BuildContext context, Widget page) {
  Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Timer? _clock;

  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.I,
      builder: (context, _) {
        final s = AppState.I;
        final p = Pal.of(context);
        final st = s.settings;
        final unread = s.unreadNotifications;
        final w = MediaQuery.sizeOf(context).width;
        final cols = w >= 900 ? 4 : (w >= 600 ? 3 : 2);
        final tileW = (w - 32 - (cols - 1) * 12) / cols;
        final scale = MediaQuery.textScalerOf(context).scale(1.0);
        final ads = s.activeAds;
        final showWelcome = st.welcomeOn && st.welcomeTitle.trim().isNotEmpty;

        return Scaffold(
          appBar: AppBar(
            backgroundColor: p.card,
            foregroundColor: p.text,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            titleSpacing: 14,
            title: Row(
              children: [
                _Logo(size: 42),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        st.siteName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: p.brandOn,
                          height: 1.2,
                        ),
                      ),
                      Text(
                        st.siteSub,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 10.5, color: p.muted, height: 1.3),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'بحث',
                icon: const Icon(Icons.search),
                onPressed: () => _push(context, const SearchScreen()),
              ),
              IconButton(
                tooltip: s.isDark ? 'التبديل إلى الوضع النهاري' : 'التبديل إلى الوضع الليلي',
                icon: Icon(s.isDark ? Icons.light_mode : Icons.dark_mode_outlined),
                onPressed: s.toggleTheme,
              ),
              IconButton(
                tooltip: 'الإشعارات',
                icon: Badge(
                  isLabelVisible: unread > 0,
                  label: Text(unread > 99 ? '99+' : '$unread'),
                  child: const Icon(Icons.notifications_outlined),
                ),
                onPressed: () => _push(context, const NotificationsScreen()),
              ),
              const SizedBox(width: 4),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: s.refreshAll,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _DateBar()),
                SliverToBoxAdapter(child: _Hero()),
                SliverToBoxAdapter(child: SectionTitle(st.catsTitle, sub: st.catsSub)),
                if (s.data.categories.isEmpty)
                  const SliverToBoxAdapter(
                    child: EmptyBox('لا توجد أقسام بعد.', icon: Icons.folder_open),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: cols,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        mainAxisExtent: tileW * 0.62 + 54 * scale,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) => _CategoryTile(s.data.categories[i]),
                        childCount: s.data.categories.length,
                      ),
                    ),
                  ),
                SliverToBoxAdapter(child: SectionTitle(st.listTitle, sub: st.listSub)),
                SliverToBoxAdapter(child: _QuickActions()),
                if (showWelcome || ads.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 22, 16, 4),
                      child: Column(
                        children: [
                          if (showWelcome)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Text(
                                st.welcomeTitle,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w800,
                                  color: p.brandOn,
                                ),
                              ),
                            ),
                          if (ads.isNotEmpty) AdsCarousel(ads: ads, delaySeconds: st.adsDelay),
                        ],
                      ),
                    ),
                  ),
                SliverToBoxAdapter(child: _Trust()),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 28),
                    child: Text(
                      '${st.footer}\nدليل تعليمي لمحافظة ${Cfg.maysanGov}',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: p.muted, fontSize: 12, height: 1.8),
                    ),
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

class _Logo extends StatelessWidget {
  final double size;
  const _Logo({required this.size});

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    final logo = AppState.I.settings.logoImg;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: size,
        height: size,
        child: logo.isNotEmpty
            ? AppImage(logo)
            : Container(
                color: p.brand,
                alignment: Alignment.center,
                child: Icon(Icons.explore, color: const Color(0xFFF3D98A), size: size * 0.62),
              ),
      ),
    );
  }
}

class _DateBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    final now = baghdadNow();
    return Container(
      decoration: BoxDecoration(
        color: p.card,
        border: Border(
          top: BorderSide(color: p.border),
          bottom: BorderSide(color: p.border),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      child: Row(
        children: [
          Icon(Icons.calendar_month, size: 20, color: p.brandOn),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              arDate(now),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: p.text),
            ),
          ),
          Text(arTime(now), style: TextStyle(fontSize: 13, color: p.muted)),
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    final st = AppState.I.settings;
    final veil = p.dark ? const Color(0xFF0D1425) : Colors.white;
    return Stack(
      children: [
        Positioned.fill(child: AppImage(st.heroImg)),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerRight,
                end: Alignment.centerLeft,
                colors: [veil.withAlpha(245), veil.withAlpha(215), veil.withAlpha(120)],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 26, 18, 26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                st.heroKicker,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: p.text),
              ),
              const SizedBox(height: 2),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: '${st.heroTitleA} '),
                    TextSpan(
                      text: st.heroTitleB,
                      style: TextStyle(
                        color: p.dark ? const Color(0xFFF3D98A) : const Color(0xFF2C5FB5),
                      ),
                    ),
                  ],
                ),
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  height: 1.4,
                  color: p.text,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                st.heroText,
                style: TextStyle(fontSize: 14, height: 1.9, color: p.text.withAlpha(215)),
              ),
              const SizedBox(height: 16),
              Material(
                color: p.card,
                elevation: 3,
                shadowColor: Colors.black26,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => _push(context, const SearchScreen()),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
                    child: Row(
                      children: [
                        Icon(Icons.search, color: p.muted),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'ابحث عن اسم مدرسة، جامعة، معهد، مدرس...',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: p.muted, fontSize: 13.5),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                          decoration: BoxDecoration(
                            color: p.brand,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'بحث',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final AppCategory cat;
  const _CategoryTile(this.cat);

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    final count = AppState.I.catCount(cat.key);
    return Container(
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: p.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _push(context, CategoryScreen(catKey: cat.key)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    AppImage(cat.img),
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: cat.soft,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Icon(cat.iconData, size: 19, color: cat.accent),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        cat.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: p.text,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: p.dark ? p.soft : cat.soft,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: p.dark ? p.brandOn : cat.accent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Widget item(String label, IconData icon, VoidCallback onTap) {
      return SizedBox(
        width: (MediaQuery.sizeOf(context).width - 32 - 10) / 2,
        child: SoftButton(label, icon: icon, onPressed: onTap),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          item('بحث وفلترة متقدمة', Icons.tune, () => _push(context, const SearchScreen())),
          item('الأقرب إليّ', Icons.my_location, () => _push(context, const NearbyScreen())),
          item('المقارنة', Icons.balance, () => _push(context, const CompareScreen())),
          item('اقترح إضافة', Icons.add_a_photo_outlined, () => _push(context, const SuggestScreen())),
        ],
      ),
    );
  }
}

class _Trust extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    const items = [
      [Icons.sync, 'تحديث مستمر', 'نضيف يومياً أحدث المعلومات'],
      [Icons.travel_explore, 'سهولة البحث', 'ابحث بسرعة عمّا تحتاجه'],
      [Icons.forum_outlined, 'تواصل مباشر', 'تواصل مباشرة مع المؤسسات'],
      [Icons.verified_user_outlined, 'معلومات موثوقة', 'بيانات موثقة ومحدّثة'],
    ];
    final w = (MediaQuery.sizeOf(context).width - 32 - 10) / 2;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          for (final it in items)
            Container(
              width: w,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
              decoration: BoxDecoration(
                color: p.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: p.border),
              ),
              child: Column(
                children: [
                  Icon(it[0] as IconData, color: p.brandOn, size: 26),
                  const SizedBox(height: 6),
                  Text(
                    it[1] as String,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.w800, color: p.text, fontSize: 13.5),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    it[2] as String,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: p.muted, fontSize: 11.5),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ======================= اللوحات الإعلانية =======================

class AdsCarousel extends StatefulWidget {
  final List<AdItem> ads;
  final int delaySeconds;
  const AdsCarousel({super.key, required this.ads, required this.delaySeconds});

  @override
  State<AdsCarousel> createState() => _AdsCarouselState();
}

class _AdsCarouselState extends State<AdsCarousel> {
  final PageController _pc = PageController();
  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void didUpdateWidget(covariant AdsCarousel old) {
    super.didUpdateWidget(old);
    if (old.ads.length != widget.ads.length || old.delaySeconds != widget.delaySeconds) {
      if (_index >= widget.ads.length) _index = 0;
      _start();
    }
  }

  void _start() {
    _timer?.cancel();
    if (widget.ads.length < 2) return;
    _timer = Timer.periodic(Duration(seconds: widget.delaySeconds.clamp(2, 60).toInt()), (_) {
      if (!mounted || !_pc.hasClients || widget.ads.isEmpty) return;
      final next = (_index + 1) % widget.ads.length;
      _pc.animateToPage(
        next,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pc.dispose();
    super.dispose();
  }

  void _open(AdItem a) {
    if (a.hasInfo) {
      showAdDetail(context, a);
    } else if (a.link.isNotEmpty) {
      openUrl(a.link);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    final ads = widget.ads;
    final size = MediaQuery.sizeOf(context);
    final width = size.width - 32;
    // نختار نسبة تُظهر أطول إعلان كاملاً دون أن تتجاوز اللوحة 60% من ارتفاع الشاشة
    var aspect = 3.4;
    for (final a in ads) {
      if (a.aspect < aspect) aspect = a.aspect;
    }
    final minAspect = width / (size.height * 0.6);
    if (aspect < minAspect) aspect = minAspect;

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AspectRatio(
            aspectRatio: aspect,
            child: Container(
              color: p.soft,
              child: PageView.builder(
                controller: _pc,
                itemCount: ads.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (ctx, i) {
                  final a = ads[i];
                  return GestureDetector(
                    onTap: () => _open(a),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        AppImage(a.img, fit: BoxFit.contain, cacheVersion: '${a.version}'),
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'إعلان',
                              style: TextStyle(color: Colors.white, fontSize: 10.5),
                            ),
                          ),
                        ),
                        if (a.title.isNotEmpty)
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: Container(
                              padding: const EdgeInsets.fromLTRB(12, 18, 12, 10),
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [Colors.black87, Colors.transparent],
                                ),
                              ),
                              child: Text(
                                a.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        if (ads.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < ads.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _index ? 18 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: i == _index ? p.brandOn : p.border,
                      borderRadius: BorderRadius.circular(7),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

void showAdDetail(BuildContext context, AdItem a) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Pal.of(context).card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      final p = Pal.of(ctx);
      Widget block(IconData icon, String label, List<Widget> children) {
        return Padding(
          padding: const EdgeInsets.only(top: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(color: p.soft, borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, size: 19, color: p.brandOn),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: TextStyle(fontWeight: FontWeight.w800, color: p.text)),
                    const SizedBox(height: 2),
                    ...children,
                  ],
                ),
              ),
            ],
          ),
        );
      }

      final social = <Widget>[];
      for (final f in kCommonFields) {
        final href = socialHref(f.link, a.social[f.id] ?? '');
        if (href.isEmpty) continue;
        social.add(SocialChip(label: f.label, icon: f.icon, color: f.color, url: href));
      }

      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(color: p.border, borderRadius: BorderRadius.circular(4)),
              ),
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: AspectRatio(
                aspectRatio: a.aspect < 0.8 ? 0.8 : a.aspect,
                child: Container(
                  color: p.soft,
                  child: AppImage(a.img, fit: BoxFit.contain, cacheVersion: '${a.version}'),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (a.title.isNotEmpty)
              Text(
                a.title,
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: p.text),
              ),
            const SizedBox(height: 6),
            Tag('إعلان', bg: p.soft, fg: p.muted),
            if (a.loc.isNotEmpty || a.map.isNotEmpty)
              block(Icons.location_on, 'الموقع', [
                if (a.loc.isNotEmpty)
                  Text(a.loc, style: TextStyle(color: p.muted, height: 1.7)),
                if (a.map.isNotEmpty)
                  InkWell(
                    onTap: () => openUrl(a.map),
                    child: Text(
                      'فتح الموقع على الخريطة',
                      style: TextStyle(
                        color: p.brandOn,
                        fontWeight: FontWeight.w800,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
              ]),
            if (a.desc.isNotEmpty)
              block(Icons.description_outlined, 'الوصف', [
                Text(a.desc, style: TextStyle(color: p.muted, height: 1.8)),
              ]),
            if (a.hours.isNotEmpty)
              block(Icons.schedule, 'أوقات العمل', [
                Text(a.hours, style: TextStyle(color: p.muted, height: 1.7)),
              ]),
            if (a.phone.isNotEmpty || social.isNotEmpty)
              block(Icons.phone, 'تواصل معنا', [
                if (a.phone.isNotEmpty)
                  InkWell(
                    onTap: () => callPhone(a.phone),
                    child: Text(
                      'رقم الهاتف: ${a.phone}',
                      style: TextStyle(color: p.brandOn, fontWeight: FontWeight.w800),
                    ),
                  ),
                if (social.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Wrap(spacing: 8, runSpacing: 8, children: social),
                  ),
              ]),
            if (a.link.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 18),
                child: SizedBox(
                  width: double.infinity,
                  child: PrimaryButton(
                    'زيارة الرابط',
                    icon: Icons.open_in_new,
                    onPressed: () => openUrl(a.link),
                  ),
                ),
              ),
          ],
        ),
      );
    },
  );
}

/// زر وسيلة تواصل (واتساب، تيليغرام ...)
class SocialChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color? color;
  final String url;
  const SocialChip({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.url,
  });

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    var c = color ?? const Color(0xFF64748B);
    if (p.dark && c.computeLuminance() < 0.08) c = Colors.white;
    return Material(
      color: c.withAlpha(28),
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => openUrl(url),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: c),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(color: c, fontWeight: FontWeight.w800, fontSize: 12.5)),
            ],
          ),
        ),
      ),
    );
  }
}
