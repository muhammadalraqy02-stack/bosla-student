// إدارة عناصر الدليل: قائمة عناصر القسم + نافذة الإضافة والتعديل (نفس حقول محرّر نسخة الويب)

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../app_state.dart';
import '../config.dart';
import '../ui.dart';
import '../utils.dart';
import '../widgets/app_image.dart';
import '../widgets/common.dart';
import 'admin_store.dart';
import 'admin_ui.dart';

const String _published = 'منشور';
const String _draft = 'مسودة';

// ======================= قائمة عناصر القسم =======================
class AdminCardsScreen extends StatefulWidget {
  final String catKey;
  const AdminCardsScreen({super.key, required this.catKey});

  @override
  State<AdminCardsScreen> createState() => _AdminCardsScreenState();
}

class _AdminCardsScreenState extends State<AdminCardsScreen> {
  final _q = TextEditingController();
  String _area = '';

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  bool _match(Json c, String q) {
    if (_area.isNotEmpty && str(c['dist']) != _area) return false;
    if (q.isEmpty) return true;
    final extra = c['extra'] is Map ? (c['extra'] as Map).values.join(' ') : '';
    final hay = '${str(c['name'])} ${str(c['desc'])} ${str(c['city'])} ${str(c['gov'])} '
            '${str(c['dist'])} ${str(c['specialty'])} ${str(c['phone'])} $extra'
        .toLowerCase();
    return hay.contains(q);
  }

  void _edit([Json? card]) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => AdminCardEditor(catKey: widget.catKey, card: card, presetArea: _area),
    ));
  }

  Future<void> _toggleStatus(Json c) async {
    final n = Map<String, dynamic>.from(c)
      ..['status'] = str(c['status']) == _draft ? _published : _draft;
    final r = await AdminStore.I.saveCard(n, oldKey: str(c['key']));
    toast(r ?? (n['status'] == _published ? 'تم النشر' : 'تم الإخفاء (مسودة)'),
        r == null ? ToastType.ok : ToastType.err);
  }

  Future<void> _toggleFeatured(Json c) async {
    final n = Map<String, dynamic>.from(c)..['featured'] = c['featured'] != true;
    final r = await AdminStore.I.saveCard(n, oldKey: str(c['key']));
    toast(r ?? (n['featured'] == true ? 'تم التمييز' : 'أُلغي التمييز'),
        r == null ? ToastType.ok : ToastType.err);
  }

  Future<void> _delete(Json c) async {
    if (demoBlocked()) return;
    final ok = await confirmDialog(context, 'حذف "${str(c['name'])}" نهائياً؟', ok: 'حذف', danger: true);
    if (!ok) return;
    final r = await AdminStore.I.deleteCard(c);
    toast(r ?? 'تم الحذف', r == null ? ToastType.ok : ToastType.err);
  }

  @override
  Widget build(BuildContext context) {
    final title = AppState.I.catName(widget.catKey);
    final one = AppState.I.catOne(widget.catKey);
    final isInstitutes = widget.catKey == 'معاهد';
    return ListenableBuilder(
      listenable: AdminStore.I,
      builder: (context, _) {
        final p = Pal.of(context);
        final q = _q.text.trim().toLowerCase();
        final all = AdminStore.I.cardsOf(widget.catKey);
        final list = all.where((c) => _match(c, q)).toList();
        return Scaffold(
          appBar: AppBar(title: Text('$title (${fmtNum(all.length)})')),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _edit(),
            icon: const Icon(Icons.add),
            label: Text('إضافة $one'),
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
                child: TextField(
                  controller: _q,
                  onChanged: (_) => setState(() {}),
                  decoration: fieldDeco(context, 'بحث بالاسم أو المنطقة أو الهاتف', icon: Icons.search),
                ),
              ),
              if (isInstitutes)
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 4, 14, 6),
                  child: DropdownButtonFormField<String>(
                    value: _area,
                    isExpanded: true,
                    decoration: fieldDeco(context, 'المنطقة', icon: Icons.place_outlined),
                    items: [
                      const DropdownMenuItem(value: '', child: Text('كل مناطق العمارة')),
                      for (final a in Cfg.maysanAreas) DropdownMenuItem(value: a, child: Text(a)),
                    ],
                    onChanged: (v) => setState(() => _area = v ?? ''),
                  ),
                ),
              Expanded(
                child: list.isEmpty
                    ? ListView(children: [EmptyBox(all.isEmpty ? 'لا توجد عناصر بعد.' : 'لا توجد نتائج.')])
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(14, 6, 14, 90),
                        itemCount: list.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final c = list[i];
                          final draft = str(c['status']) == _draft;
                          final featured = c['featured'] == true;
                          final geo = [str(c['gov']), str(c['dist'])].where((x) => x.isNotEmpty).join(' / ');
                          final sub = [
                            if (str(c['specialty']).isNotEmpty) str(c['specialty']),
                            if (geo.isNotEmpty) geo,
                            str(c['created']),
                          ].join(' · ');
                          return Material(
                            color: p.card,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: BorderSide(color: p.border),
                            ),
                            child: ListTile(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              onTap: () => _edit(c),
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: AppImage(str(c['img']), width: 52, height: 52),
                              ),
                              title: Row(
                                children: [
                                  if (featured)
                                    Padding(
                                      padding: const EdgeInsetsDirectional.only(end: 4),
                                      child: Icon(Icons.star, size: 16, color: p.gold),
                                    ),
                                  Expanded(
                                    child: Text(
                                      str(c['name']),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontWeight: FontWeight.w800, color: p.text),
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Text(
                                draft ? 'مسودة (مخفي) · $sub' : sub,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: draft ? const Color(0xFFB54708) : p.muted,
                                ),
                              ),
                              trailing: PopupMenuButton<String>(
                                onSelected: (v) {
                                  if (v == 'edit') _edit(c);
                                  if (v == 'status') _toggleStatus(c);
                                  if (v == 'feat') _toggleFeatured(c);
                                  if (v == 'del') _delete(c);
                                },
                                itemBuilder: (_) => [
                                  const PopupMenuItem(value: 'edit', child: Text('تعديل')),
                                  PopupMenuItem(value: 'status', child: Text(draft ? 'نشر' : 'إخفاء (مسودة)')),
                                  PopupMenuItem(value: 'feat', child: Text(featured ? 'إلغاء التمييز' : 'تمييز')),
                                  const PopupMenuItem(
                                    value: 'del',
                                    child: Text('حذف', style: TextStyle(color: Color(0xFFB42318))),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ======================= محرّر العنصر =======================
class AdminCardEditor extends StatefulWidget {
  final String catKey;
  final Json? card;
  final String presetArea;
  const AdminCardEditor({super.key, required this.catKey, this.card, this.presetArea = ''});

  @override
  State<AdminCardEditor> createState() => _AdminCardEditorState();
}

class _AdminCardEditorState extends State<AdminCardEditor> {
  late String _key;
  late String _status;
  late bool _featured;
  late String _dist;
  final List<String> _images = [];
  final _name = TextEditingController();
  final _specialty = TextEditingController();
  final _gov = TextEditingController();
  final _distText = TextEditingController();
  final _city = TextEditingController();
  final _phone = TextEditingController();
  final _desc = TextEditingController();
  final Map<String, TextEditingController> _extra = {};
  final ImagePicker _picker = ImagePicker();
  bool _busy = false;
  bool _uploading = false;

  bool get _isNew => widget.card == null;

  @override
  void initState() {
    super.initState();
    final c = widget.card ?? const <String, dynamic>{};
    _key = str(c['key']).isEmpty ? widget.catKey : str(c['key']);
    _status = str(c['status']) == _draft ? _draft : _published;
    _featured = c['featured'] == true;
    _name.text = str(c['name']);
    _specialty.text = str(c['specialty']);
    _city.text = str(c['city']);
    _phone.text = str(c['phone']);
    _desc.text = str(c['desc']);
    final dist = _isNew && _key == 'معاهد' ? widget.presetArea : str(c['dist']);
    _dist = Cfg.maysanAreas.contains(dist) ? dist : '';
    _distText.text = dist;
    _gov.text = _isNew && _key == 'معاهد' ? Cfg.maysanGov : str(c['gov']);
    final imgs = c['images'];
    final first = str(c['img']);
    void add(dynamic x) {
      final s = str(x).trim();
      if (s.isNotEmpty && s != kNoImage && !_images.contains(s)) _images.add(s);
    }

    add(first);
    if (imgs is List) {
      for (final x in imgs) {
        add(x);
      }
    }
    final ex = c['extra'];
    if (ex is Map) {
      ex.forEach((k, v) => _ctrl(k.toString()).text = str(v));
    }
  }

  TextEditingController _ctrl(String id) => _extra.putIfAbsent(id, () => TextEditingController());

  @override
  void dispose() {
    for (final c in [_name, _specialty, _gov, _distText, _city, _phone, _desc, ..._extra.values]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _addImage(ImageSource src) async {
    if (_uploading || demoBlocked()) return;
    try {
      final x = await _picker.pickImage(source: src, maxWidth: 1600, maxHeight: 1600, imageQuality: 72);
      if (x == null) return;
      final bytes = await x.readAsBytes();
      if (bytes.length > 2500 * 1024) {
        toast('الصورة كبيرة جداً — اختر صورة أصغر', ToastType.err);
        return;
      }
      setState(() => _uploading = true);
      toast('جاري رفع الصورة...');
      final url = await AdminStore.I.uploadImage(bytes, x.name);
      if (!mounted) return;
      setState(() {
        _images.add(url);
        _uploading = false;
      });
      toast('تم رفع الصورة (${(bytes.length / 1024).round()}KB)');
    } catch (_) {
      if (mounted) setState(() => _uploading = false);
      toast('تعذّر رفع الصورة — تحقق من الاتصال', ToastType.err);
    }
  }

  void _pickSource() {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('من المعرض'),
              onTap: () {
                Navigator.of(ctx).pop();
                _addImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('من الكاميرا'),
              onTap: () {
                Navigator.of(ctx).pop();
                _addImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.link),
              title: const Text('إضافة برابط'),
              onTap: () {
                Navigator.of(ctx).pop();
                _addImageUrl();
              },
            ),
          ],
        ),
      ),
    );
  }

  /// إضافة صورة برابط — نفس editorAddImageUrl
  Future<void> _addImageUrl() async {
    if (_images.length >= 20) {
      toast('الحد الأعلى 20 صورة', ToastType.warn);
      return;
    }
    final v = await promptText(context, 'الصق رابط الصورة', hint: 'https://...', ltr: true);
    if (v == null) return;
    final ref = v.trim();
    if (!RegExp(r'^https://', caseSensitive: false).hasMatch(ref) &&
        !RegExp(r'^data:image/(png|jpe?g|webp|gif);base64,', caseSensitive: false).hasMatch(ref)) {
      toast('رابط الصورة غير صالح', ToastType.warn);
      return;
    }
    if (_images.contains(ref)) {
      toast('هذه الصورة مضافة مسبقاً', ToastType.warn);
      return;
    }
    setState(() => _images.add(ref));
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      toast('الاسم مطلوب', ToastType.warn);
      return;
    }
    if (_key == 'مدرسين' && _specialty.text.trim().isEmpty) {
      toast('اختصاص المدرس مطلوب', ToastType.warn);
      return;
    }
    final isInst = _key == 'معاهد';
    final dist = isInst ? _dist : _distText.text.trim();
    if (isInst && dist.isEmpty) {
      toast('اختر منطقة المعهد', ToastType.warn);
      return;
    }
    // لا نحفظ إلا حقول القسم المختار — مثل نسخة الويب
    final ex = <String, String>{};
    for (final f in formFields(_key)) {
      final v = _ctrl(f.id).text.trim();
      if (v.isNotEmpty) ex[f.id] = v.length > 200 ? v.substring(0, 200) : v;
    }
    final old = widget.card;
    final obj = old == null
        ? <String, dynamic>{'id': uid(), 'created': todayIso()}
        : Map<String, dynamic>.from(old);
    final img = _images.isNotEmpty ? _images.first : kNoImage;
    obj.addAll({
      'name': clip(name, 150),
      'key': _key,
      'city': _city.text.trim(),
      'gov': isInst ? Cfg.maysanGov : _gov.text.trim(),
      'dist': dist,
      'phone': _phone.text.trim(),
      'specialty': _specialty.text.trim(),
      'rating': old == null ? 0 : numOf(old['rating']),
      'status': _status,
      'desc': clip(_desc.text, 2000),
      'img': img,
      'extra': ex,
      'featured': _featured,
      'images': _images.isNotEmpty ? List<String>.from(_images) : <String>[img],
    });
    setState(() => _busy = true);
    final r = await AdminStore.I.saveCard(obj, oldKey: old == null ? '' : str(old['key']), isNew: old == null);
    if (!mounted) return;
    setState(() => _busy = false);
    if (r != null) {
      toast(r, ToastType.err);
      return;
    }
    toast(old == null ? 'تمت الإضافة' : 'تم حفظ التعديلات');
    Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final c = widget.card;
    if (c == null) return;
    if (demoBlocked()) return;
    final ok = await confirmDialog(context, 'حذف "${str(c['name'])}" نهائياً؟', ok: 'حذف', danger: true);
    if (!ok) return;
    setState(() => _busy = true);
    final r = await AdminStore.I.deleteCard(c);
    if (!mounted) return;
    setState(() => _busy = false);
    toast(r ?? 'تم الحذف', r == null ? ToastType.ok : ToastType.err);
    if (r == null) Navigator.of(context).pop();
  }

  Widget _field(TextEditingController c, String label,
      {IconData? icon, int lines = 1, TextInputType? type, String? hint}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        minLines: lines,
        maxLines: lines == 1 ? 1 : lines + 4,
        keyboardType: type,
        decoration: fieldDeco(context, label, icon: icon, hint: hint),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    final cats = AppState.I.data.categories;
    final form = formOf(_key);
    final isInst = _key == 'معاهد';
    final isTeacher = _key == 'مدرسين';
    final catTitle = AppState.I.catName(_key);
    return Scaffold(
      appBar: AppBar(
        title: Text('${_isNew ? 'إضافة عنصر' : 'تعديل عنصر'} — $catTitle'),
        actions: [
          if (!_isNew)
            IconButton(
              tooltip: 'حذف',
              icon: const Icon(Icons.delete_outline),
              onPressed: _busy ? null : _delete,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 30),
        children: [
          _field(_name, 'الاسم *', icon: Icons.badge_outlined),
          if (!_isNew && cats.length > 1)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: DropdownButtonFormField<String>(
                value: cats.any((c) => c.key == _key) ? _key : null,
                isExpanded: true,
                decoration: fieldDeco(context, 'القسم', icon: Icons.category_outlined),
                items: [for (final c in cats) DropdownMenuItem(value: c.key, child: Text(c.name))],
                onChanged: (v) {
                  if (v == null) return;
                  setState(() {
                    _key = v;
                    if (_key == 'معاهد') _gov.text = Cfg.maysanGov;
                  });
                },
              ),
            ),
          _field(_specialty, '${form.specLabel}${isTeacher ? ' *' : ''}', icon: Icons.menu_book_outlined),
          if (isTeacher)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final sp in Cfg.teacherSpecialties)
                    ChoiceChip(
                      label: Text(sp),
                      selected: _specialty.text.trim() == sp,
                      onSelected: (_) => setState(() => _specialty.text = sp),
                    ),
                ],
              ),
            ),
          if (isInst)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: DropdownButtonFormField<String>(
                value: _dist.isEmpty ? null : _dist,
                isExpanded: true,
                decoration: fieldDeco(context, 'المنطقة (${Cfg.maysanGov}) *', icon: Icons.place_outlined),
                items: [for (final a in Cfg.maysanAreas) DropdownMenuItem(value: a, child: Text(a))],
                onChanged: (v) => setState(() => _dist = v ?? ''),
              ),
            )
          else ...[
            _geoSelect(
              label: 'المحافظة',
              icon: Icons.map_outlined,
              value: _gov.text.trim(),
              options: const [Cfg.maysanGov],
              empty: '— اختر المحافظة —',
              onChanged: (v) => setState(() {
                _gov.text = v;
                _distText.text = '';
              }),
            ),
            _geoSelect(
              label: 'المركز',
              icon: Icons.place_outlined,
              value: _distText.text.trim(),
              options: _gov.text.trim() == Cfg.maysanGov ? Cfg.maysanAreas : const <String>[],
              empty: '— اختر المركز —',
              onChanged: (v) => setState(() => _distText.text = v),
            ),
          ],
          _field(_city, 'العنوان / المدينة', icon: Icons.location_city_outlined),
          _field(_phone, 'الهاتف', icon: Icons.phone_outlined, type: TextInputType.phone),
          _field(_desc, 'الوصف', icon: Icons.notes, lines: 3),
          const SizedBox(height: 4),
          Text('الصور', style: TextStyle(fontWeight: FontWeight.w800, color: p.text)),
          const SizedBox(height: 4),
          Text('الصورة الأولى هي الصورة الرئيسية. تُرفع الصور إلى Supabase.',
              style: TextStyle(fontSize: 11.5, color: p.muted)),
          const SizedBox(height: 8),
          SizedBox(
            height: 96,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (var i = 0; i < _images.length; i++)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 8),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: AppImage(_images[i], width: 96, height: 96),
                        ),
                        PositionedDirectional(
                          top: 2,
                          end: 2,
                          child: _miniBtn(Icons.close, () => setState(() => _images.removeAt(i))),
                        ),
                        if (i > 0)
                          PositionedDirectional(
                            bottom: 2,
                            end: 2,
                            child: _miniBtn(Icons.star_outline, () {
                              setState(() {
                                final x = _images.removeAt(i);
                                _images.insert(0, x);
                              });
                            }),
                          )
                        else
                          PositionedDirectional(
                            bottom: 4,
                            start: 4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xCC10275E),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text('رئيسية',
                                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                            ),
                          ),
                      ],
                    ),
                  ),
                InkWell(
                  onTap: _uploading ? null : _pickSource,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: p.soft,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: p.border),
                    ),
                    child: _uploading
                        ? const Center(child: CircularProgressIndicator())
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate_outlined, color: p.brandOn),
                              const SizedBox(height: 4),
                              Text('إضافة صورة', style: TextStyle(fontSize: 11, color: p.muted)),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('معلومات إضافية', style: TextStyle(fontWeight: FontWeight.w800, color: p.text)),
          const SizedBox(height: 8),
          for (final f in formFields(_key))
            if (kSelectOpts[_key]?[f.id] != null)
              _geoSelect(
                label: f.label,
                icon: f.icon,
                value: _ctrl(f.id).text.trim(),
                options: kSelectOpts[_key]![f.id]!,
                empty: '— اختر —',
                onChanged: (v) => setState(() => _ctrl(f.id).text = v),
              )
            else
              _field(
                _ctrl(f.id),
                f.label,
                icon: f.icon,
                hint: f.link == 'map'
                    ? 'رابط خرائط Google أو إحداثيات مثل 31.83,47.14'
                    : (f.link.isNotEmpty ? 'رابط أو معرّف أو رقم' : null),
              ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('منشور (يظهر للزوار)'),
            value: _status == _published,
            onChanged: (v) => setState(() => _status = v ? _published : _draft),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('عنصر مميّز'),
            value: _featured,
            onChanged: (v) => setState(() => _featured = v),
          ),
          const SizedBox(height: 10),
          PrimaryButton(
            _isNew ? 'إضافة' : 'حفظ التعديلات',
            icon: Icons.save_outlined,
            busy: _busy || _uploading,
            onPressed: _save,
          ),
        ],
      ),
    );
  }

  /// قائمة اختيار مع الإبقاء على القيمة الحالية حتى لو لم تكن ضمن الخيارات (مثل نسخة الويب)
  Widget _geoSelect({
    required String label,
    required IconData icon,
    required String value,
    required List<String> options,
    required String empty,
    required ValueChanged<String> onChanged,
  }) {
    final items = <String>['', ...options];
    if (value.isNotEmpty && !items.contains(value)) items.add(value);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: value,
        isExpanded: true,
        decoration: fieldDeco(context, label, icon: icon),
        items: [
          for (final o in items)
            DropdownMenuItem(
              value: o,
              child: Text(o.isEmpty ? empty : (options.contains(o) ? o : '$o (غير مسجّلة)')),
            ),
        ],
        onChanged: (v) => onChanged(v ?? ''),
      ),
    );
  }

  Widget _miniBtn(IconData icon, VoidCallback onTap) {
    return Material(
      color: const Color(0xAA000000),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(icon, size: 16, color: Colors.white),
        ),
      ),
    );
  }
}
