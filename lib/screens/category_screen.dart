// صفحة القسم:
//  - المدرسين: اختيار الاختصاص أولاً ثم عرض المدرسين
//  - المعاهد: اختيار المنطقة أولاً ثم عرض المعاهد
//  - بقية الأقسام: قائمة مباشرة مع بحث داخل القسم

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../config.dart';
import '../models.dart';
import '../utils.dart';
import '../widgets/common.dart';
import 'search_screen.dart';

class CategoryScreen extends StatefulWidget {
  final String catKey;
  const CategoryScreen({super.key, required this.catKey});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final TextEditingController _q = TextEditingController();
  String _query = '';
  String _area = '';
  String _specialty = '';
  bool _loading = false;

  bool get _isTeachers => widget.catKey == 'مدرسين';
  bool get _isInstitutes => widget.catKey == 'معاهد';

  @override
  void initState() {
    super.initState();
    if (Cfg.publicSections.containsKey(widget.catKey)) {
      _loading = true;
      AppState.I.loadPublicSection(widget.catKey).whenComplete(() {
        if (mounted) setState(() => _loading = false);
      });
    }
  }

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  void _resetSearch() {
    _q.clear();
    _query = '';
  }

  bool _handleBack() {
    if (_specialty.isNotEmpty || _area.isNotEmpty) {
      setState(() {
        _specialty = '';
        _area = '';
        _resetSearch();
      });
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.I,
      builder: (context, _) {
        final s = AppState.I;
        final p = Pal.of(context);
        final cat = s.catByKey(widget.catKey);
        final all = s.publicCards.where((c) => c.key == widget.catKey).toList();
        s.sortCards(all, 'new');

        final chooseSpecialty = _isTeachers && _specialty.isEmpty;
        final chooseArea = _isInstitutes && _area.isEmpty;
        final showTiles = chooseSpecialty || chooseArea;

        var base = all;
        if (_isInstitutes && _area.isNotEmpty) {
          base = base.where((c) => (c.dist.isEmpty ? Cfg.noArea : c.dist) == _area).toList();
        }
        if (_isTeachers && _specialty.isNotEmpty) {
          base = base.where((c) {
            final sp = teacherSpecialtyKey(c.specialty);
            return (sp.isEmpty ? Cfg.noArea : sp) == _specialty;
          }).toList();
        }
        final q = _query.toLowerCase();
        final list = q.isEmpty
            ? base
            : base.where((c) {
                final hay = '${c.name} ${c.specialty} ${c.desc} ${c.geoLabel} ${c.extraText}'
                    .toLowerCase();
                return hay.contains(q);
              }).toList();

        return PopScope(
          canPop: _specialty.isEmpty && _area.isEmpty,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _handleBack();
          },
          child: Scaffold(
            appBar: brandAppBar(
              context,
              cat?.name ?? widget.catKey,
              actions: [
                IconButton(
                  tooltip: 'بحث وفلترة متقدمة',
                  icon: const Icon(Icons.tune),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => SearchScreen(initialCat: widget.catKey)),
                  ),
                ),
              ],
            ),
            body: RefreshIndicator(
              onRefresh: () => s.loadPublicSection(widget.catKey, force: true),
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                slivers: [
                  if (cat != null && cat.desc.isNotEmpty && showTiles)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                        child: Text(
                          cat.desc,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: p.muted, height: 1.7),
                        ),
                      ),
                    ),
                  if (_isTeachers || _isInstitutes)
                    SliverToBoxAdapter(child: _crumb(p)),
                  if (!showTiles)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                        child: TextField(
                          controller: _q,
                          textInputAction: TextInputAction.search,
                          onChanged: (v) => setState(() => _query = v.trim()),
                          decoration: fieldDecoSearch(context),
                        ),
                      ),
                    ),
                  if (_loading && all.isEmpty)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    )
                  else if (chooseSpecialty)
                    _specialtyTiles(s, all)
                  else if (chooseArea)
                    _areaTiles(all, cat)
                  else
                    CardsSliver(list),
                  const SliverToBoxAdapter(child: SizedBox(height: 70)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  InputDecoration fieldDecoSearch(BuildContext context) {
    final p = Pal.of(context);
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: p.border),
    );
    return InputDecoration(
      hintText: 'ابحث داخل هذا القسم...',
      prefixIcon: const Icon(Icons.search, size: 20),
      filled: true,
      fillColor: p.soft,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      border: border,
      enabledBorder: border,
      focusedBorder: border,
    );
  }

  Widget _crumb(Pal p) {
    final picked = _isTeachers ? _specialty : _area;
    final rootLabel = _isTeachers ? 'اختصاصات المدرسين' : 'مناطق العمارة';
    final hint = _isTeachers
        ? 'اختر الاختصاص لعرض المدرسين المسجّلين فيه.'
        : 'اختر المنطقة لعرض المعاهد المتواجدة فيها.';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6,
            runSpacing: 6,
            children: [
              ActionChip(
                avatar: Icon(
                  picked.isEmpty
                      ? (_isTeachers ? Icons.menu_book : Icons.map_outlined)
                      : Icons.arrow_forward,
                  size: 16,
                ),
                label: Text(picked.isEmpty ? rootLabel : (_isTeachers ? 'كل الاختصاصات' : 'كل المناطق')),
                onPressed: picked.isEmpty ? null : _handleBack,
              ),
              if (picked.isNotEmpty) ...[
                Icon(Icons.chevron_left, size: 18, color: p.muted),
                Chip(
                  label: Text(
                    _isTeachers ? picked : 'منطقة $picked',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ],
          ),
          if (picked.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(hint, style: TextStyle(color: p.muted, fontSize: 13)),
            ),
        ],
      ),
    );
  }

  SliverGridDelegate _tileDelegate(BuildContext context, {double extra = 0}) {
    final w = MediaQuery.sizeOf(context).width;
    final cols = w >= 900 ? 5 : (w >= 600 ? 4 : 2);
    final scale = MediaQuery.textScalerOf(context).scale(1.0);
    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: cols,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      mainAxisExtent: 58 + 56 * scale + extra,
    );
  }

  Widget _specialtyTiles(AppState s, List<CardItem> all) {
    final counts = <String, int>{};
    for (final c in all) {
      final sp = teacherSpecialtyKey(c.specialty);
      final k = sp.isEmpty ? Cfg.noArea : sp;
      counts[k] = (counts[k] ?? 0) + 1;
    }
    final choices = s.teacherSpecialtyChoices();
    if ((counts[Cfg.noArea] ?? 0) > 0) choices.add(Cfg.noArea);
    final p = Pal.of(context);
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      sliver: SliverGrid(
        gridDelegate: _tileDelegate(context),
        delegate: SliverChildBuilderDelegate(
          (ctx, i) {
            final sp = choices[i];
            final m = kSpecialtyMeta[sp] ?? kSpecialtyDefault;
            return _Tile(
              icon: m.icon,
              soft: p.dark ? p.soft : m.soft,
              accent: p.dark ? p.brandOn : m.accent,
              title: sp,
              sub: '${counts[sp] ?? 0} مدرس',
              onTap: () => setState(() {
                _specialty = sp;
                _resetSearch();
              }),
            );
          },
          childCount: choices.length,
        ),
      ),
    );
  }

  Widget _areaTiles(List<CardItem> all, AppCategory? cat) {
    final counts = <String, int>{};
    for (final c in all) {
      final a = c.dist.isEmpty ? Cfg.noArea : c.dist;
      counts[a] = (counts[a] ?? 0) + 1;
    }
    final areas = <String>[...Cfg.maysanAreas];
    for (final k in counts.keys) {
      if (!areas.contains(k)) areas.add(k);
    }
    final p = Pal.of(context);
    final one = cat?.one ?? 'معهد';
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      sliver: SliverGrid(
        gridDelegate: _tileDelegate(context),
        delegate: SliverChildBuilderDelegate(
          (ctx, i) {
            final a = areas[i];
            return _Tile(
              icon: a == Cfg.noArea ? Icons.help_outline : Icons.place,
              soft: p.soft,
              accent: p.brandOn,
              title: a,
              sub: '${counts[a] ?? 0} $one',
              onTap: () => setState(() {
                _area = a;
                _resetSearch();
              }),
            );
          },
          childCount: areas.length,
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final Color soft;
  final Color accent;
  final String title;
  final String sub;
  final VoidCallback onTap;
  const _Tile({
    required this.icon,
    required this.soft,
    required this.accent,
    required this.title,
    required this.sub,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    return Material(
      color: p.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: p.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(color: soft, borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: accent, size: 22),
              ),
              const SizedBox(height: 6),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: p.text),
              ),
              Text(
                sub,
                maxLines: 1,
                style: TextStyle(fontSize: 11.5, color: p.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
