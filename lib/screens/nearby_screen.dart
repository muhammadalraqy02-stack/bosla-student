// الأقرب إليّ — يُحسب البعد على الجهاز فقط، ولا يُرسل الموقع إلى أي خادم

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models.dart';
import '../ui.dart';
import '../utils.dart';
import '../widgets/common.dart';

class NearbyScreen extends StatefulWidget {
  const NearbyScreen({super.key});

  @override
  State<NearbyScreen> createState() => _NearbyScreenState();
}

class _NearbyScreenState extends State<NearbyScreen> {
  bool _locating = false;
  String _error = '';
  String _cat = '';

  @override
  void initState() {
    super.initState();
    // نحمّل الأقسام العامة حتى تدخل المدارس والمعاهد في النتائج
    AppState.I.loadPublicSection('مدارس');
    AppState.I.loadPublicSection('معاهد');
  }

  Future<void> _locate() async {
    setState(() {
      _locating = true;
      _error = '';
    });
    final err = await AppState.I.locate();
    if (!mounted) return;
    setState(() {
      _locating = false;
      _error = err ?? '';
    });
    if (err != null) toast(err, ToastType.warn);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.I,
      builder: (context, _) {
        final s = AppState.I;
        final p = Pal.of(context);
        final pos = s.userPos;

        Widget body;
        if (pos == null) {
          body = ListView(
            padding: const EdgeInsets.fromLTRB(20, 30, 20, 40),
            children: [
              Icon(Icons.my_location, size: 54, color: p.brandOn),
              const SizedBox(height: 14),
              Text(
                'اعرض المدارس والمعاهد والمدرسين الأقرب إلى موقعك',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: p.text),
              ),
              const SizedBox(height: 8),
              Text(
                'يُستخدم موقعك على جهازك فقط لحساب المسافات، ولا يُرسل أو يُحفظ على أي خادم. يُطلب الإذن عند ضغطك الزر أدناه.',
                textAlign: TextAlign.center,
                style: TextStyle(color: p.muted, height: 1.8),
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                'تحديد موقعي',
                icon: Icons.near_me,
                busy: _locating,
                onPressed: _locate,
              ),
              if (_error.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: Text(
                    _error,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Color(0xFFB54708)),
                  ),
                ),
            ],
          );
        } else {
          final withGeo = <CardItem>[];
          final dist = <String, double>{};
          for (final c in s.publicCards) {
            final g = c.geo;
            if (g == null) continue;
            withGeo.add(c);
            dist[c.id] = distanceKm(pos, g);
          }
          final cats = s.data.categories.where((c) => withGeo.any((x) => x.key == c.key)).toList();
          if (_cat.isNotEmpty && !cats.any((c) => c.key == _cat)) _cat = '';
          final list = withGeo.where((c) => _cat.isEmpty || c.key == _cat).toList()
            ..sort((a, b) => dist[a.id]!.compareTo(dist[b.id]!));
          final shown = list.take(40).toList();
          final trailing = {for (final c in shown) c.id: distanceText(dist[c.id]!)};

          body = CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'مرتّبة من الأقرب إلى الأبعد. تظهر هنا العناصر التي أُضيف لها موقع على الخريطة فقط.',
                        style: TextStyle(color: p.muted, fontSize: 12.5, height: 1.7),
                      ),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _chip('الكل', _cat.isEmpty, () => setState(() => _cat = '')),
                            for (final c in cats)
                              _chip(c.name, _cat == c.key, () => setState(() => _cat = c.key)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // قائمة أفقية دائماً لإظهار المسافة بجانب كل عنصر
              if (shown.isEmpty)
                const SliverToBoxAdapter(
                  child: EmptyBox(
                    'لا توجد عناصر بموقع محدد في هذا القسم بعد.',
                    icon: Icons.location_off_outlined,
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 60),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) => ItemCard(shown[i], trailingText: trailing[shown[i].id]),
                      childCount: shown.length,
                    ),
                  ),
                ),
            ],
          );
        }

        return Scaffold(
          appBar: brandAppBar(
            context,
            'الأقرب إليّ',
            actions: [
              if (pos != null)
                IconButton(
                  tooltip: 'تحديث موقعي',
                  icon: const Icon(Icons.refresh),
                  onPressed: _locating ? null : _locate,
                ),
            ],
          ),
          body: body,
        );
      },
    );
  }

  Widget _chip(String label, bool on, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: on,
        onSelected: (_) => onTap(),
      ),
    );
  }
}
