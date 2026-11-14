// البحث والفلترة المتقدمة: نص + قسم + منطقة + تخصص (للمدرسين) + ترتيب

import 'dart:async';

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../config.dart';
import '../ui.dart';
import '../widgets/common.dart';

class SearchScreen extends StatefulWidget {
  final String initialCat;
  const SearchScreen({super.key, this.initialCat = ''});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _q = TextEditingController();
  Timer? _debounce;
  String _query = '';
  String _cat = '';
  String _dist = '';
  String _spec = '';
  String _sort = 'new';
  bool _filtersOpen = false;

  @override
  void initState() {
    super.initState();
    _cat = widget.initialCat;
    if (_cat.isNotEmpty) AppState.I.loadPublicSection(_cat);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _q.dispose();
    super.dispose();
  }

  void _onText(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 280), () {
      if (!mounted) return;
      setState(() => _query = v.trim());
      if (_query.isNotEmpty) AppState.I.countSearch();
    });
  }

  void _clear() {
    setState(() {
      _dist = '';
      _spec = '';
    });
    toast('تم مسح الفلاتر');
  }

  Widget _dropdown({
    required String label,
    required String value,
    required List<String> items,
    required String allLabel,
    required ValueChanged<String> onChanged,
    Map<String, String>? names,
  }) {
    final safe = items.contains(value) ? value : '';
    return DropdownButtonFormField<String>(
      value: safe,
      isExpanded: true,
      decoration: fieldDeco(context, label),
      items: [
        DropdownMenuItem(value: '', child: Text(allLabel, overflow: TextOverflow.ellipsis)),
        for (final it in items)
          DropdownMenuItem(
            value: it,
            child: Text(names?[it] ?? it, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: (v) => onChanged(v ?? ''),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.I,
      builder: (context, _) {
        final s = AppState.I;
        final p = Pal.of(context);
        final cats = s.data.categories;
        final catNames = {for (final c in cats) c.key: c.name};
        final teacher = _cat == 'مدرسين';
        final specs = s.specialtyList('مدرسين');
        final list = s.search(
          q: _query,
          cat: _cat,
          dist: _dist,
          specialty: teacher ? _spec : '',
          sort: _sort,
        );
        final activeFilters = (_dist.isNotEmpty ? 1 : 0) + (teacher && _spec.isNotEmpty ? 1 : 0);

        return Scaffold(
          appBar: brandAppBar(context, 'البحث في الدليل'),
          body: CustomScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
                  child: Column(
                    children: [
                      TextField(
                        controller: _q,
                        autofocus: widget.initialCat.isEmpty,
                        textInputAction: TextInputAction.search,
                        onChanged: _onText,
                        decoration: fieldDeco(
                          context,
                          'ابحث عن اسم مدرسة، جامعة، معهد، مدرس أو منطقة',
                          icon: Icons.search,
                        ).copyWith(
                          suffixIcon: _q.text.isEmpty
                              ? null
                              : IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () {
                                    _q.clear();
                                    setState(() => _query = '');
                                  },
                                ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _dropdown(
                              label: 'القسم',
                              value: _cat,
                              items: [for (final c in cats) c.key],
                              names: catNames,
                              allLabel: 'كل الأقسام',
                              onChanged: (v) {
                                setState(() {
                                  _cat = v;
                                  if (v != 'مدرسين') _spec = '';
                                });
                                if (v.isNotEmpty) s.loadPublicSection(v);
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _dropdown(
                              label: 'الترتيب',
                              value: _sort,
                              items: const ['name', 'rating'],
                              names: const {'name': 'الاسم', 'rating': 'الأعلى تقييماً'},
                              allLabel: 'الأحدث',
                              onChanged: (v) => setState(() => _sort = v.isEmpty ? 'new' : v),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: p.card,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: p.border),
                        ),
                        child: Column(
                          children: [
                            InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () => setState(() => _filtersOpen = !_filtersOpen),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                child: Row(
                                  children: [
                                    Icon(Icons.tune, size: 20, color: p.brandOn),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        activeFilters > 0
                                            ? 'بحث وفلترة متقدمة ($activeFilters)'
                                            : 'بحث وفلترة متقدمة',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          color: p.text,
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      _filtersOpen ? Icons.expand_less : Icons.expand_more,
                                      color: p.muted,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (_filtersOpen)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                                child: Column(
                                  children: [
                                    InputDecorator(
                                      decoration: fieldDeco(context, 'المحافظة'),
                                      child: Text(Cfg.maysanGov),
                                    ),
                                    const SizedBox(height: 10),
                                    _dropdown(
                                      label: 'المنطقة',
                                      value: _dist,
                                      items: Cfg.maysanAreas,
                                      allLabel: 'كل المناطق',
                                      onChanged: (v) => setState(() => _dist = v),
                                    ),
                                    if (teacher) ...[
                                      const SizedBox(height: 10),
                                      _dropdown(
                                        label: 'التخصص',
                                        value: _spec,
                                        items: specs,
                                        allLabel: 'كل التخصصات',
                                        onChanged: (v) => setState(() => _spec = v),
                                      ),
                                    ],
                                    Align(
                                      alignment: AlignmentDirectional.centerEnd,
                                      child: TextButton.icon(
                                        onPressed: _clear,
                                        icon: const Icon(Icons.restart_alt, size: 18),
                                        label: const Text('مسح الفلاتر'),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 12, bottom: 2),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _cat.isEmpty ? s.settings.listTitle : s.catName(_cat),
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  color: p.text,
                                ),
                              ),
                            ),
                            Text(
                              '${list.length} نتيجة',
                              style: TextStyle(color: p.muted, fontSize: 12.5),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              CardsSliver(list),
              const SliverToBoxAdapter(child: SizedBox(height: 60)),
            ],
          ),
        );
      },
    );
  }
}
