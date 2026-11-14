// صفحة تفاصيل العنصر: معرض الصور، المعلومات، وسائل التواصل، الحجز، المقارنة،
// التذكير، الملاحظة الخاصة، الاتجاهات، وتقييمات الطلاب (مع الإبلاغ والإخفاء)

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../config.dart';
import '../local_data.dart';
import '../models.dart';
import '../ui.dart';
import '../utils.dart';
import '../widgets/app_image.dart';
import '../widgets/common.dart';
import 'booking_screen.dart';
import 'home_screen.dart' show SocialChip;
import 'legal_screen.dart';
import 'tools_screen.dart';

void openDetail(BuildContext context, String id) {
  if (AppState.I.cardById(id) == null) {
    toast('هذا العنصر لم يعد متوفراً', ToastType.warn);
    return;
  }
  Navigator.of(context).push(MaterialPageRoute(builder: (_) => DetailScreen(cardId: id)));
}

/// فتح الاتجاهات إلى موقع العنصر (خرائط Apple على iOS)
void openDirections(BuildContext context, CardItem c) {
  final g = c.geo;
  final loc = c.extra['loc'] ?? '';
  final ios = Theme.of(context).platform == TargetPlatform.iOS;
  var url = '';
  if (g != null) {
    url = ios
        ? 'https://maps.apple.com/?daddr=${g.lat},${g.lng}'
        : 'https://www.google.com/maps/dir/?api=1&destination=${g.lat},${g.lng}';
  } else if (isHttp(loc)) {
    url = loc;
  }
  if (url.isNotEmpty) openUrl(url);
}

class DetailScreen extends StatefulWidget {
  final String cardId;
  const DetailScreen({super.key, required this.cardId});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  int _img = 0;
  List<Review>? _reviews;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews({bool force = false}) async {
    final list = await AppState.I.loadReviews(widget.cardId, force: force);
    if (mounted) setState(() => _reviews = list);
  }

  Future<void> _editNote(CardItem c) async {
    final cur = LocalData.cardNote(c.id);
    final ctl = TextEditingController(text: cur?.text ?? '');
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Pal.of(context).card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final p = Pal.of(ctx);
        return Padding(
          padding: EdgeInsets.fromLTRB(18, 18, 18, 18 + MediaQuery.viewInsetsOf(ctx).bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ملاحظتي عن «${c.name}»',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: p.text),
              ),
              const SizedBox(height: 6),
              Text(
                'ملاحظة خاصة بك لا يراها أحد غيرك، وتُحفظ على جهازك فقط. مثال: الأسعار، أوقات الدوام، انطباعك بعد الزيارة.',
                style: TextStyle(color: p.muted, fontSize: 12.5, height: 1.7),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ctl,
                autofocus: true,
                maxLength: 1500,
                minLines: 5,
                maxLines: 9,
                decoration: fieldDeco(ctx, 'اكتب ملاحظتك...'),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: PrimaryButton(
                      'حفظ',
                      icon: Icons.save_outlined,
                      onPressed: () => Navigator.of(ctx).pop(clip(ctl.text, 1500)),
                    ),
                  ),
                  if (cur != null) ...[
                    const SizedBox(width: 10),
                    SoftButton(
                      'حذف',
                      icon: Icons.delete_outline,
                      color: const Color(0xFFB42318),
                      onPressed: () => Navigator.of(ctx).pop(''),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
    if (result == null) return;
    await LocalData.setCardNote(c.id, result);
    toast(result.isEmpty ? 'حُذفت الملاحظة' : 'حُفظت ملاحظتك');
    if (mounted) setState(() {});
  }

  Future<void> _writeReview(CardItem c) async {
    final sent = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Pal.of(context).card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _ReviewForm(card: c),
    );
    if (sent == true) {
      toast('شكراً! سيظهر تقييمك بعد مراجعة الإدارة');
      if (mounted) setState(() {});
    }
  }

  Future<void> _report(Review r) async {
    final ok = await confirmDialog(
      context,
      'الإبلاغ عن هذا التقييم كمحتوى غير مناسب؟ سيُخفى عنك وتراجعه الإدارة.',
      ok: 'إبلاغ',
      danger: true,
    );
    if (!ok) return;
    await AppState.I.reportReview(widget.cardId, r.id);
    toast('تم الإبلاغ، شكراً لك');
    await _loadReviews(force: true);
  }

  Future<void> _hide(Review r) async {
    await AppState.I.hideReview(widget.cardId, r.id);
    toast('أُخفي التقييم');
    await _loadReviews(force: true);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.I,
      builder: (context, _) {
        final s = AppState.I;
        final p = Pal.of(context);
        final c = s.cardById(widget.cardId);
        if (c == null) {
          return Scaffold(
            appBar: brandAppBar(context, 'التفاصيل'),
            body: const Center(child: EmptyBox('هذا العنصر لم يعد متوفراً')),
          );
        }
        final cat = s.catByKey(c.key);
        final fav = s.isFavorite(c.id);
        final inCmp = s.inCompare(c.id);
        final images = c.images.isNotEmpty ? c.images : <String>[c.img];
        if (_img >= images.length) _img = 0;
        final form = formOf(c.key);
        final note = LocalData.cardNote(c.id);
        final g = c.geo;
        final hasLoc = g != null || isHttp(c.extra['loc'] ?? '');
        final userPos = s.userPos;

        final rows = <Widget>[];
        void row(IconData icon, String text, {VoidCallback? onTap}) {
          rows.add(_InfoRow(icon: icon, text: text, onTap: onTap));
        }

        if (c.specialty.isNotEmpty) row(Icons.menu_book, '${form.specLabel}: ${c.specialty}');
        for (final f in formFields(c.key)) {
          final v = c.extra[f.id] ?? '';
          if (v.isEmpty || f.link.isNotEmpty) continue;
          row(f.icon, '${f.label}: $v', onTap: isHttp(v) ? () => openUrl(v) : null);
        }
        if (c.gov.isNotEmpty) {
          final d = c.dist.isEmpty ? '' : (c.key == 'معاهد' ? ' / منطقة ' : ' / مركز ') + c.dist;
          row(Icons.map_outlined, 'محافظة ${c.gov}$d');
        }
        if (c.city.isNotEmpty) row(Icons.location_on_outlined, c.city);
        if (c.phone.isNotEmpty) row(Icons.phone, c.phone, onTap: () => callPhone(c.phone));
        row(Icons.calendar_today_outlined, 'أُضيف بتاريخ ${c.created}');

        final social = <Widget>[];
        for (final f in kCommonFields) {
          final href = socialHref(f.link, c.extra[f.id] ?? '');
          if (href.isEmpty) continue;
          social.add(SocialChip(label: f.label, icon: f.icon, color: f.color, url: href));
        }

        return Scaffold(
          appBar: brandAppBar(
            context,
            cat?.one ?? c.key,
            actions: [
              Builder(
                builder: (ctx) => IconButton(
                  tooltip: 'مشاركة',
                  icon: const Icon(Icons.share_outlined),
                  onPressed: () => shareText(ctx, shareTextFor(c), subject: c.name),
                ),
              ),
              IconButton(
                tooltip: fav ? 'إزالة من المفضلة' : 'إضافة إلى المفضلة',
                icon: Icon(fav ? Icons.favorite : Icons.favorite_border),
                onPressed: () => s.toggleFavorite(c.id),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.only(bottom: 90),
            children: [
              // ---------- معرض الصور ----------
              GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => _ImageViewer(images: images, initial: _img),
                  ),
                ),
                child: AspectRatio(aspectRatio: 16 / 10, child: AppImage(images[_img])),
              ),
              if (images.length > 1)
                SizedBox(
                  height: 70,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                    itemCount: images.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (ctx, i) => GestureDetector(
                      onTap: () => setState(() => _img = i),
                      child: Container(
                        width: 76,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: i == _img ? p.brandOn : p.border,
                            width: i == _img ? 2.2 : 1,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: AppImage(images[i]),
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        Tag(
                          c.key,
                          bg: p.dark ? p.soft : (cat?.soft ?? p.soft),
                          fg: p.dark ? p.brandOn : (cat?.accent ?? p.brand),
                        ),
                        if (c.featured) Tag('مميّز', bg: p.gold, fg: Colors.white, icon: Icons.star),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      c.name,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: p.text,
                        height: 1.4,
                      ),
                    ),
                    if (c.rating > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Stars(c.rating, size: 18),
                      ),
                    if (c.desc.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(
                          c.desc,
                          style: TextStyle(color: p.text.withAlpha(220), height: 1.9, fontSize: 14.5),
                        ),
                      ),
                    const SizedBox(height: 14),
                    Container(
                      decoration: BoxDecoration(
                        color: p.card,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: p.border),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: Column(children: rows),
                    ),
                    if (social.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 14),
                        child: Wrap(spacing: 8, runSpacing: 8, children: social),
                      ),
                    const SizedBox(height: 16),

                    // ---------- الإجراءات ----------
                    SizedBox(
                      width: double.infinity,
                      child: PrimaryButton(
                        c.isTeacher ? 'احجز مقعداً' : 'سجّل الآن',
                        icon: Icons.event_available,
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => BookingScreen(cardId: c.id)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: SoftButton(
                            inCmp ? 'في المقارنة ✓' : 'قارن',
                            icon: Icons.balance,
                            onPressed: () => s.toggleCompare(c.id),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: SoftButton(
                            'ذكّرني',
                            icon: Icons.notifications_none,
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ToolsScreen(
                                  standalone: true,
                                  initialTab: 2,
                                  pendingCountdownTitle: 'موعد التسجيل — ${c.name}',
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: SoftButton(
                        note == null ? 'أضف ملاحظة خاصة' : 'تعديل ملاحظتي',
                        icon: Icons.sticky_note_2_outlined,
                        onPressed: () => _editNote(c),
                      ),
                    ),
                    if (hasLoc) ...[
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: SoftButton(
                          g != null && userPos != null
                              ? 'الاتجاهات · ${distanceText(distanceKm(userPos, g))}'
                              : 'الاتجاهات',
                          icon: Icons.directions,
                          onPressed: () => openDirections(context, c),
                        ),
                      ),
                    ],
                    if (note != null)
                      InkWell(
                        onTap: () => _editNote(c),
                        child: NoteBox(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.sticky_note_2_outlined, size: 17, color: p.brandOn),
                                  const SizedBox(width: 6),
                                  Text(
                                    'ملاحظتي الخاصة',
                                    style: TextStyle(fontWeight: FontWeight.w800, color: p.text),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(note.text, style: TextStyle(color: p.text, height: 1.7)),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 22),

                    // ---------- التقييمات ----------
                    _reviewsSection(context, c),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _reviewsSection(BuildContext context, CardItem c) {
    final p = Pal.of(context);
    final s = AppState.I;
    final list = _reviews;
    final done = s.reviewedBefore(c.id);
    final avg = (list == null || list.isEmpty)
        ? 0.0
        : list.fold<int>(0, (a, r) => a + r.stars) / list.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.star_rounded, color: Color(0xFFF59E0B)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'تقييمات الطلاب',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: p.text),
              ),
            ),
            if (list != null && list.isNotEmpty)
              Tag(
                '${avg.toStringAsFixed(1)} من 5 · ${list.length}',
                bg: p.soft,
                fg: p.brandOn,
              ),
          ],
        ),
        const SizedBox(height: 10),
        if (done)
          Text('شكراً، أرسلت تقييمك لهذا العنصر.', style: TextStyle(color: p.muted))
        else
          SoftButton('اكتب تقييمك', icon: Icons.rate_review_outlined, onPressed: () => _writeReview(c)),
        const SizedBox(height: 8),
        if (list == null)
          Padding(
            padding: const EdgeInsets.all(14),
            child: Text('جاري تحميل التقييمات...', style: TextStyle(color: p.muted)),
          )
        else if (list.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'لا توجد تقييمات بعد — كن أول من يقيّم.',
              style: TextStyle(color: p.muted),
            ),
          )
        else
          for (final r in list.take(20))
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: p.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: p.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Stars(r.stars.toDouble(), size: 15, showValue: false),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${r.nick.isEmpty ? 'طالب' : r.nick} · ${timeAgo(r.at)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: p.muted, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  if (r.text.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(r.text, style: TextStyle(color: p.text, height: 1.7)),
                    ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () => _report(r),
                        icon: const Icon(Icons.flag_outlined, size: 16),
                        label: const Text('إبلاغ'),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFB42318),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => _hide(r),
                        icon: const Icon(Icons.visibility_off_outlined, size: 16),
                        label: const Text('إخفاء'),
                        style: TextButton.styleFrom(
                          foregroundColor: p.muted,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback? onTap;
  const _InfoRow({required this.icon, required this.text, this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    final child = Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Icon(icon, size: 18, color: p.brandOn),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: onTap == null ? p.text : p.brandOn,
                fontWeight: onTap == null ? FontWeight.w500 : FontWeight.w800,
                height: 1.6,
              ),
            ),
          ),
          if (onTap != null) Icon(Icons.chevron_left, size: 18, color: p.muted),
        ],
      ),
    );
    return onTap == null ? child : InkWell(onTap: onTap, child: child);
  }
}

class _ImageViewer extends StatelessWidget {
  final List<String> images;
  final int initial;
  const _ImageViewer({required this.images, required this.initial});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: PageView.builder(
        controller: PageController(initialPage: initial),
        itemCount: images.length,
        itemBuilder: (ctx, i) => InteractiveViewer(
          maxScale: 4,
          child: Center(
            child: SizedBox.expand(child: AppImage(images[i], fit: BoxFit.contain)),
          ),
        ),
      ),
    );
  }
}

/// نموذج كتابة تقييم (يُراجع من الإدارة قبل النشر)
class _ReviewForm extends StatefulWidget {
  final CardItem card;
  const _ReviewForm({required this.card});

  @override
  State<_ReviewForm> createState() => _ReviewFormState();
}

class _ReviewFormState extends State<_ReviewForm> {
  final TextEditingController _nick = TextEditingController();
  final TextEditingController _text = TextEditingController();
  int _stars = 0;
  bool _agree = false;
  bool _busy = false;

  @override
  void dispose() {
    _nick.dispose();
    _text.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_stars == 0) {
      toast('اختر عدد النجوم', ToastType.warn);
      return;
    }
    if (!_agree) {
      toast('يرجى الموافقة على شروط الاستخدام', ToastType.warn);
      return;
    }
    setState(() => _busy = true);
    final err = await AppState.I.sendReview(
      widget.card.id,
      _stars,
      clip(_nick.text, 30),
      clip(_text.text, 300),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (err != null) {
      toast(err, ToastType.warn);
      return;
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(18, 18, 18, 18 + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'قيّم «${widget.card.name}»',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: p.text),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 1; i <= 5; i++)
                IconButton(
                  iconSize: 38,
                  tooltip: '$i',
                  onPressed: () => setState(() => _stars = i),
                  icon: Icon(
                    i <= _stars ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: const Color(0xFFF59E0B),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _nick,
            maxLength: 30,
            decoration: fieldDeco(context, 'الاسم الظاهر (اختياري)', hint: 'مثال: طالب سادس علمي'),
          ),
          TextField(
            controller: _text,
            maxLength: 300,
            minLines: 3,
            maxLines: 5,
            decoration: fieldDeco(
              context,
              'رأيك (اختياري)',
              hint: 'تحدّث عن تجربتك: الشرح، الالتزام، البيئة الدراسية...',
            ),
          ),
          Text(
            'يُراجع التقييم من الإدارة قبل نشره. يُمنع المحتوى المسيء أو الشخصي أو الروابط، وأي إساءة تُحذف فوراً.',
            style: TextStyle(color: p.muted, fontSize: 12, height: 1.7),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(value: _agree, onChanged: (v) => setState(() => _agree = v == true)),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: InkWell(
                    onTap: () => openLegal(context, 'terms'),
                    child: Text(
                      'أوافق على شروط الاستخدام ولا أنشر بيانات شخصية لأحد. (اضغط لقراءة الشروط)',
                      style: TextStyle(color: p.text, fontSize: 12.5, height: 1.6),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: PrimaryButton('إرسال التقييم', icon: Icons.send, busy: _busy, onPressed: _send),
          ),
        ],
      ),
    );
  }
}
