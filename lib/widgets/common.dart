// عناصر واجهة مشتركة: الألوان، العناوين، النجوم، بطاقات العناصر، شبكة النتائج

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models.dart';
import '../screens/detail_screen.dart';
import '../ui.dart';
import '../config.dart';
import 'app_image.dart';

/// لوحة الألوان (كحلي/ذهبي) بحسب الوضع النهاري أو الليلي
class Pal {
  final bool dark;
  final Color brand;
  final Color accent;
  const Pal(this.dark, this.brand, this.accent);

  static Pal of(BuildContext context) {
    final s = AppState.I.settings;
    return Pal(Theme.of(context).brightness == Brightness.dark, s.brand, s.accent);
  }

  Color get bg => dark ? const Color(0xFF0D1425) : Colors.white;
  Color get card => dark ? const Color(0xFF111A2E) : Colors.white;
  Color get border => dark ? const Color(0xFF263550) : const Color(0xFFDCE1EA);
  Color get text => dark ? const Color(0xFFE6EBF5) : const Color(0xFF15213F);
  Color get muted => dark ? const Color(0xFF9AA7BD) : const Color(0xFF68758B);
  Color get soft => dark ? const Color(0xFF17233B) : const Color(0xFFF4F7FC);
  Color get gold => const Color(0xFFF0A31B);

  /// لون العلامة بصيغة مقروءة على الخلفية الحالية
  Color get brandOn => dark ? const Color(0xFFF3D98A) : brand;
}

class SectionTitle extends StatelessWidget {
  final String title;
  final String sub;
  const SectionTitle(this.title, {super.key, this.sub = ''});

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 12),
      child: Column(
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: p.text),
          ),
          const SizedBox(height: 8),
          Container(
            width: 56,
            height: 4,
            decoration: BoxDecoration(color: p.gold, borderRadius: BorderRadius.circular(4)),
          ),
          if (sub.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(sub, textAlign: TextAlign.center, style: TextStyle(color: p.muted, fontSize: 13)),
          ],
        ],
      ),
    );
  }
}

class Stars extends StatelessWidget {
  final double rating;
  final double size;
  final bool showValue;
  const Stars(this.rating, {super.key, this.size = 15, this.showValue = true});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Icon(
            rating >= i - 0.25 ? Icons.star_rounded : Icons.star_outline_rounded,
            size: size,
            color: const Color(0xFFF59E0B),
          ),
        if (showValue) ...[
          const SizedBox(width: 4),
          Text(
            rating.toStringAsFixed(1),
            style: TextStyle(fontSize: size - 3, fontWeight: FontWeight.w800),
          ),
        ],
      ],
    );
  }
}

class EmptyBox extends StatelessWidget {
  final IconData icon;
  final String text;
  final Widget? action;
  const EmptyBox(this.text, {super.key, this.icon = Icons.sentiment_dissatisfied, this.action});

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 44),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 44, color: p.muted),
          const SizedBox(height: 12),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(color: p.muted, height: 1.8, fontSize: 14),
          ),
          if (action != null) ...[const SizedBox(height: 14), action!],
        ],
      ),
    );
  }
}

/// شارة صغيرة (اسم القسم، حالة الطلب ...)
class Tag extends StatelessWidget {
  final String text;
  final Color bg;
  final Color fg;
  final IconData? icon;
  const Tag(this.text, {super.key, required this.bg, required this.fg, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 12, color: fg), const SizedBox(width: 4)],
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

Widget statusTag(String status) {
  switch (status) {
    case 'مقبول':
      return const Tag('مقبول', bg: Color(0xFFE3F8ED), fg: Color(0xFF0B6B47));
    case 'مرفوض':
      return const Tag('مرفوض', bg: Color(0xFFFEECEF), fg: Color(0xFFB42318));
    case 'تم التواصل':
      return const Tag('تم التواصل', bg: Color(0xFFE9F1FE), fg: Color(0xFF2F6FE4));
    case 'تم الاطلاع':
      return const Tag('تم الاطلاع', bg: Color(0xFFE9F1FE), fg: Color(0xFF2F6FE4));
    case 'مغلق':
      return const Tag('أُغلق الطلب', bg: Color(0xFFEEF2F8), fg: Color(0xFF64748B));
  }
  return Tag(
    status.isEmpty ? 'قيد المراجعة' : status,
    bg: const Color(0xFFFEF5E4),
    fg: const Color(0xFFB54708),
  );
}

/// شريط «غير متصل»
class OfflineBar extends StatelessWidget {
  const OfflineBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFB54708),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off, color: Colors.white, size: 16),
          SizedBox(width: 8),
          Flexible(
            child: Text(
              'غير متصل — تُعرض آخر نسخة محفوظة',
              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

/// نص مشاركة عنصر من الدليل
String shareTextFor(CardItem c) {
  final s = AppState.I;
  final b = StringBuffer('شاهد ${c.name} على ${s.settings.siteName}');
  if (c.specialty.isNotEmpty) b.write('\n${c.specialty}');
  if (c.geoLabel.isNotEmpty) b.write('\n${c.geoLabel}');
  if (c.phone.isNotEmpty) b.write('\n${c.phone}');
  if (Cfg.webBaseUrl.isNotEmpty) {
    b.write('\n${Cfg.webBaseUrl.split('#').first}#item=${Uri.encodeComponent(c.id)}');
  }
  return b.toString();
}

/// بطاقة عنصر أفقية (مدرسة، جامعة، معهد ...)
class ItemCard extends StatelessWidget {
  final CardItem card;
  final String? trailingText;
  const ItemCard(this.card, {super.key, this.trailingText});

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    final s = AppState.I;
    final c = card;
    final fav = s.isFavorite(c.id);
    final cat = s.catByKey(c.key);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => openDetail(context, c.id),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 116,
                height: 132,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    AppImage(c.img),
                    if (c.featured)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Tag('مميّز', bg: p.gold, fg: Colors.white, icon: Icons.star),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 12, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Tag(
                              cat?.one ?? c.key,
                              bg: p.dark ? p.soft : (cat?.soft ?? p.soft),
                              fg: p.dark ? p.brandOn : (cat?.accent ?? p.brand),
                            ),
                          ),
                          const Spacer(),
                          _MiniIcon(
                            icon: fav ? Icons.favorite : Icons.favorite_border,
                            color: fav ? const Color(0xFFEF4444) : p.muted,
                            tooltip: fav ? 'إزالة من المفضلة' : 'إضافة إلى المفضلة',
                            onTap: () => s.toggleFavorite(c.id),
                          ),
                          Builder(
                            builder: (ctx) => _MiniIcon(
                              icon: Icons.share_outlined,
                              color: p.muted,
                              tooltip: 'مشاركة',
                              onTap: () => shareText(ctx, shareTextFor(c), subject: c.name),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        c.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: p.text,
                          height: 1.4,
                        ),
                      ),
                      if (c.specialty.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Row(
                            children: [
                              Icon(Icons.menu_book, size: 13, color: p.muted),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  c.specialty,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 12, color: p.muted),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (c.geoLabel.isNotEmpty) ...[
                            Icon(Icons.location_on, size: 13, color: p.muted),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                c.geoLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 12, color: p.muted),
                              ),
                            ),
                          ] else
                            const Spacer(),
                          if (trailingText != null)
                            Text(
                              trailingText!,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: p.brandOn,
                              ),
                            )
                          else if (c.rating > 0)
                            Stars(c.rating, size: 13),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;
  const _MiniIcon({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkResponse(
        onTap: onTap,
        radius: 22,
        child: Padding(
          padding: const EdgeInsets.all(7),
          child: Icon(icon, size: 21, color: color),
        ),
      ),
    );
  }
}

/// بطاقة مدرّس مدمجة (شبكة بثلاثة أعمدة كما في نسخة الويب)
class TeacherTile extends StatelessWidget {
  final CardItem card;
  const TeacherTile(this.card, {super.key});

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    final c = card;
    final fav = AppState.I.isFavorite(c.id);
    return Container(
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => openDetail(context, c.id),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    AppImage(c.img),
                    if (fav)
                      const Positioned(
                        top: 6,
                        left: 6,
                        child: Icon(Icons.favorite, size: 16, color: Color(0xFFEF4444)),
                      ),
                    if (c.featured)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Icon(Icons.star, size: 16, color: p.gold),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        c.name,
                        maxLines: 2,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: p.text,
                          height: 1.35,
                        ),
                      ),
                      if (c.specialty.isNotEmpty)
                        Text(
                          c.specialty,
                          maxLines: 1,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 10, color: p.muted),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// قائمة/شبكة النتائج داخل CustomScrollView
class CardsSliver extends StatelessWidget {
  final List<CardItem> list;
  final String emptyText;
  final Map<String, String>? trailing; // نص إضافي لكل عنصر (مثل المسافة)
  const CardsSliver(
    this.list, {
    super.key,
    this.emptyText = 'لا توجد نتائج مطابقة.',
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    if (list.isEmpty) {
      return SliverToBoxAdapter(child: EmptyBox(emptyText));
    }
    final w = MediaQuery.sizeOf(context).width;
    final teacherGrid = list.every((c) => c.isTeacher);
    if (teacherGrid) {
      final cols = w >= 900 ? 6 : (w >= 600 ? 4 : 3);
      final tileW = (w - 32 - (cols - 1) * 8) / cols;
      final scale = MediaQuery.textScalerOf(context).scale(1.0);
      return SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        sliver: SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            mainAxisExtent: tileW + 62 * scale,
          ),
          delegate: SliverChildBuilderDelegate(
            (ctx, i) => TeacherTile(list[i]),
            childCount: list.length,
          ),
        ),
      );
    }
    final cols = w >= 760 ? 2 : 1;
    final rows = (list.length / cols).ceil();
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (ctx, r) {
            if (cols == 1) {
              final c = list[r];
              return ItemCard(c, trailingText: trailing?[c.id]);
            }
            final a = list[r * 2];
            final b = r * 2 + 1 < list.length ? list[r * 2 + 1] : null;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: ItemCard(a, trailingText: trailing?[a.id])),
                const SizedBox(width: 12),
                Expanded(
                  child: b == null
                      ? const SizedBox.shrink()
                      : ItemCard(b, trailingText: trailing?[b.id]),
                ),
              ],
            );
          },
          childCount: rows,
        ),
      ),
    );
  }
}

/// زر أساسي بلون العلامة
class PrimaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool busy;
  final Color? color;
  const PrimaryButton(
    this.label, {
    super.key,
    this.icon,
    this.onPressed,
    this.busy = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    return ElevatedButton(
      onPressed: busy ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color ?? p.brand,
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
      ),
      child: busy
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 8)],
                Flexible(child: Text(label, textAlign: TextAlign.center)),
              ],
            ),
    );
  }
}

/// زر ثانوي بإطار
class SoftButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final Color? color;
  const SoftButton(this.label, {super.key, this.icon, this.onPressed, this.color});

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    final fg = color ?? p.brandOn;
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: fg,
        backgroundColor: p.soft,
        side: BorderSide(color: p.border),
        minimumSize: const Size(0, 46),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 7)],
          Flexible(child: Text(label, textAlign: TextAlign.center)),
        ],
      ),
    );
  }
}

/// صندوق ملاحظة ملوّن
class NoteBox extends StatelessWidget {
  final Widget child;
  const NoteBox({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: p.dark ? const Color(0xFF17233B) : const Color(0xFFF1F6FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: p.dark ? const Color(0xFF2A3A58) : const Color(0xFFD6E3FF)),
      ),
      child: child,
    );
  }
}

/// شريط علوي موحّد بلون العلامة للصفحات الفرعية
PreferredSizeWidget brandAppBar(BuildContext context, String title, {List<Widget>? actions, PreferredSizeWidget? bottom}) {
  final p = Pal.of(context);
  return AppBar(
    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
    centerTitle: true,
    backgroundColor: p.dark ? const Color(0xFF111A2E) : p.brand,
    foregroundColor: Colors.white,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    actions: actions,
    bottom: bottom,
  );
}
