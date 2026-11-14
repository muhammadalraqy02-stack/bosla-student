// المقارنة بين حتى 3 خيارات

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../config.dart';
import '../models.dart';
import '../ui.dart';
import '../utils.dart';
import '../widgets/app_image.dart';
import '../widgets/common.dart';
import 'detail_screen.dart';

class CompareScreen extends StatelessWidget {
  const CompareScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.I,
      builder: (context, _) {
        final s = AppState.I;
        final p = Pal.of(context);
        final items = <CardItem>[];
        for (final id in s.compareIds) {
          final c = s.cardById(id);
          if (c != null) items.add(c);
        }

        if (items.isEmpty) {
          return Scaffold(
            appBar: brandAppBar(context, 'المقارنة'),
            body: const Center(
              child: EmptyBox(
                'أضف عناصر للمقارنة من زر «قارن» داخل صفحة أي مدرسة أو معهد أو مدرّس.',
                icon: Icons.balance,
              ),
            ),
          );
        }

        var best = 0.0;
        for (final c in items) {
          if (c.rating > best) best = c.rating;
        }
        final userPos = s.userPos;

        Widget cell(Widget child) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
              child: child,
            );
        Widget txt(String t, {bool bold = false, Color? color}) => Text(
              t.isEmpty ? '—' : t,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color ?? p.text,
                fontSize: 12.5,
                fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
                height: 1.5,
              ),
            );
        Widget head(String t) => cell(Text(
              t,
              style: TextStyle(color: p.muted, fontSize: 12, fontWeight: FontWeight.w800),
            ));

        final rows = <TableRow>[];
        void add(String label, Widget Function(CardItem c) build) {
          rows.add(TableRow(
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: p.border))),
            children: [head(label), for (final c in items) cell(build(c))],
          ));
        }

        add('الصورة', (c) => ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: AspectRatio(aspectRatio: 4 / 3, child: AppImage(c.img)),
            ));
        add('الاسم', (c) => txt(c.name, bold: true));
        add('القسم', (c) => txt(s.catOne(c.key)));
        add('التقييم', (c) {
          if (c.rating <= 0) return txt('');
          final top = items.length > 1 && c.rating == best;
          return txt(
            '★ ${c.rating.toStringAsFixed(1)}',
            bold: top,
            color: top ? const Color(0xFF0B8A4F) : null,
          );
        });
        add('المنطقة', (c) {
          final parts = [c.gov, c.dist].where((x) => x.isNotEmpty).join(' / ');
          return txt(parts.isEmpty ? c.city : parts);
        });
        add('التخصص', (c) => txt(c.specialty));
        add('الهاتف', (c) {
          if (c.phone.isEmpty) return txt('');
          return InkWell(
            onTap: () => callPhone(c.phone),
            child: txt(c.phone, bold: true, color: p.brandOn),
          );
        });

        // الحقول الخاصة بكل قسم — يظهر الصف إذا كان معبّأً عند عنصر واحد على الأقل
        final seen = <String>{};
        for (final c in items) {
          for (final f in formFields(c.key)) {
            if (f.link.isNotEmpty || seen.contains(f.label)) continue;
            final any = items.any((x) => _extraByLabel(x, f.label).isNotEmpty);
            if (!any) continue;
            seen.add(f.label);
            add(f.label, (x) => txt(_extraByLabel(x, f.label)));
          }
        }

        if (userPos != null) {
          add('المسافة', (c) {
            final g = c.geo;
            return txt(g == null ? '' : distanceText(distanceKm(userPos, g)));
          });
        }

        rows.add(TableRow(
          children: [
            head(''),
            for (final c in items)
              cell(Column(
                children: [
                  PrimaryButton('التفاصيل', onPressed: () => openDetail(context, c.id)),
                  TextButton(
                    onPressed: () => s.toggleCompare(c.id),
                    child: const Text('إزالة'),
                  ),
                ],
              )),
          ],
        ));

        final minWidth = 86.0 + items.length * 132.0;
        return Scaffold(
          appBar: brandAppBar(context, 'المقارنة'),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(12, 14, 12, 40),
            children: [
              LayoutBuilder(
                builder: (ctx, box) {
                  final width = box.maxWidth < minWidth ? minWidth : box.maxWidth;
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: width,
                      child: Container(
                        decoration: BoxDecoration(
                          color: p.card,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: p.border),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Table(
                          columnWidths: const {0: FixedColumnWidth(86)},
                          defaultColumnWidth: const FlexColumnWidth(),
                          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                          children: rows,
                        ),
                      ),
                    ),
                  );
                },
              ),
              if (items.length < 3)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    'يمكنك إضافة ${3 - items.length} عنصر آخر.',
                    style: TextStyle(color: p.muted),
                  ),
                ),
              const SizedBox(height: 12),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: SoftButton(
                  'مسح المقارنة',
                  icon: Icons.cleaning_services_outlined,
                  onPressed: s.clearCompare,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static String _extraByLabel(CardItem c, String label) {
    for (final f in formFields(c.key)) {
      if (f.label == label) return c.extra[f.id] ?? '';
    }
    return '';
  }
}
