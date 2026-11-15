// سياسة الخصوصية، سياسة الأطفال، شروط الاستخدام، حذف بياناتي، الدعم والتواصل
// + نافذتا «عن التطبيق» و«عن الشركة المطوّرة» (نصهما من لوحة الإدارة)

import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform;
import 'package:flutter/material.dart';

import '../app_state.dart';
import '../config.dart';
import '../ui.dart';
import '../widgets/common.dart';

const List<List<String>> kLegalTabs = [
  ['privacy', 'سياسة الخصوصية'],
  ['children', 'سياسة الأطفال'],
  ['terms', 'شروط الاستخدام'],
  ['delete', 'حذف بياناتي'],
  ['support', 'الدعم والتواصل'],
];

void openLegal(BuildContext context, String tab) {
  Navigator.of(context).push(MaterialPageRoute(builder: (_) => LegalScreen(initial: tab)));
}

void openAdminWhatsApp() {
  final n = AppState.I.settings.whatsapp;
  if (n.isEmpty) {
    toast('لم تضف الإدارة رقم واتساب بعد', ToastType.warn);
    return;
  }
  openUrl('https://wa.me/$n');
}

void showInfoPage(BuildContext context, {required bool app}) {
  final st = AppState.I.settings;
  showDialog<void>(
    context: context,
    builder: (ctx) {
      final p = Pal.of(ctx);
      return AlertDialog(
        icon: Icon(app ? Icons.info_outline : Icons.business, size: 34, color: p.brandOn),
        title: Text(
          app ? 'عن التطبيق' : 'عن الشركة المطوّرة',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        content: SingleChildScrollView(
          child: Text(
            app ? st.aboutApp : st.developerCompany,
            style: const TextStyle(height: 1.9),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('إغلاق')),
        ],
      );
    },
  );
}

// نوع السطر: h عنوان · p فقرة · li بند · m ملاحظة باهتة
List<List<String>> _privacy(String s) => [
      ['h', 'سياسة الخصوصية — $s'],
      ['m', 'آخر تحديث: ${Cfg.legalUpdated}'],
      ['p', 'تطبيق «$s» دليل تعليمي يعرض المدارس والجامعات والمعاهد والمدرسين. نحترم خصوصيتك ونجمع أقل قدر ممكن من البيانات. توضح هذه السياسة ما نجمعه ولماذا وكيف تتحكم به.'],
      ['h', '1. لا حسابات ولا تسجيل دخول'],
      ['p', 'يمكنك استخدام التطبيق كاملاً دون إنشاء حساب أو تقديم اسمك أو رقمك.'],
      ['h', '2. بيانات تبقى على جهازك فقط'],
      ['li', 'قائمة المفضلة.'],
      ['li', 'الإشعارات التي قرأتها.'],
      ['li', 'اختيار الوضع الليلي أو النهاري.'],
      ['li', 'نسخة مؤقتة من محتوى الدليل لتسريع الفتح والعمل عند ضعف الإنترنت.'],
      ['li', 'أدوات الطالب: جدولك الأسبوعي، ودرجاتك في حاسبة المعدل، والعدّ التنازلي، والتذكيرات، وملاحظاتك الشخصية.'],
      ['li', 'قائمة المقارنة، والتقييمات التي أخفيتها.'],
      ['p', 'هذه البيانات لا تُرسل إلينا، ويمكنك مسحها من قسم «حذف بياناتي».'],
      ['h', '3. بيانات ترسلها أنت باختيارك'],
      ['p', 'عند استخدام ميزة «اقترح إضافة» نستلم: القسم، الاسم المقترح، المنطقة، الملاحظات، ووسيلة تواصل إن أدخلتها (اختيارية)، والصورة إن أرفقتها. نستخدمها فقط لمراجعة الاقتراح وإضافته إلى الدليل والتواصل معك بشأنه عند الحاجة. لا تُعرض وسيلة تواصلك ولا صورتك للعامة.'],
      ['p', 'طلب التسجيل / حجز مقعد: نستلم اسم الطالب، ورقم الهاتف، والمرحلة، والوقت المفضل، والمادة أو القسم، والملاحظات. تُحفظ هذه البيانات منفصلة عن محتوى الدليل العام، ويطّلع عليها فريق التطبيق فقط لتنسيق التسجيل مع الجهة التي اخترتها والتواصل معك. وتظهر لك حالة الطلب في «طلباتي».'],
      ['p', 'التقييمات: نستلم عدد النجوم والنص والاسم الظاهر الذي تختاره (اختياري). يُنشر التقييم للعامة بعد موافقة الإدارة، لذا لا تكتب فيه أي بيانات شخصية. البلاغات عن التقييمات تُرسل دون أي بيانات عنك.'],
      ['h', '4. الكاميرا والصور'],
      ['p', 'يطلب التطبيق إذن الكاميرا أو الصور فقط عند ضغطك زر «التقاط بالكاميرا» أو «اختيار من الصور» داخل نموذج الاقتراح. تُصغَّر الصورة على جهازك قبل إرسالها، ولا يصل التطبيق إلى أي صورة أخرى. يمكنك سحب الإذن في أي وقت من إعدادات الجهاز.'],
      ['h', '5. الإشعارات والتذكيرات'],
      ['p', 'الإشعارات اختيارية، ونطلب إذنها فقط عند ضغطك «تفعيل» أو عند إضافة تذكير أو إرسال طلب تسجيل. محتواها إعلانات الدليل وتحديثات حالة طلبك وتذكيراتك التي أضفتها بنفسك، وتُنشأ على جهازك نفسه. يمكنك إيقافها من إعدادات الجهاز.'],
      ['h', '5-أ. الموقع الجغرافي'],
      ['p', 'يُطلب إذن الموقع فقط عند ضغطك «الأقرب إليّ». يُستخدم موقعك على جهازك لحساب المسافات إلى المؤسسات، ولا يُرسل أو يُحفظ على أي خادم.'],
      ['h', '6. إحصاءات مجمّعة دون هوية'],
      ['p', 'نحتفظ بأعداد إجمالية فقط، مثل عدد الزيارات وعدد عمليات البحث، لتحسين الدليل. يستخدم التطبيق معرّفاً تقنياً عشوائياً يتغيّر مع كل تشغيل لتنظيم مزامنة البيانات، ولا يرتبط باسمك أو برقم هاتفك. لا نتتبعك عبر التطبيقات أو المواقع الأخرى، ولا نستخدم أدوات تتبع أو تحليلات إعلانية من أطراف ثالثة.'],
      ['h', '7. الإعلانات'],
      ['p', 'اللوحات الإعلانية داخل التطبيق إعلانات مباشرة لمؤسسات تعليمية يديرها فريق التطبيق. لا نستخدم شبكات إعلانية، ولا نعرض إعلانات مخصصة حسب سلوكك.'],
      ['h', '8. مزوّدو الخدمة'],
      ['p', 'نستخدم Google Firebase لقاعدة البيانات وSupabase لتخزين الصور، وقد تكون خوادمهما خارج العراق. يعالج هذان المزوّدان البيانات نيابة عنا ولغرض تشغيل التطبيق فقط.'],
      ['h', '9. لا بيع ولا مشاركة'],
      ['p', 'لا نبيع بياناتك ولا نشاركها مع أي جهة لأغراض تسويقية. قد نكشف عن معلومات إذا ألزمنا القانون بذلك.'],
      ['h', '10. روابط خارجية'],
      ['p', 'قد تفتح روابط مثل واتساب أو الاتصال الهاتفي أو مواقع المؤسسات، وتخضع هذه لسياسات أصحابها.'],
      ['h', '11. الاحتفاظ والحذف'],
      ['p', 'نحتفظ بالاقتراحات حتى انتهاء مراجعتها وانتهاء الغرض منها ثم نحذفها. يمكنك حذف اقتراحاتك بنفسك فوراً من «حذف بياناتي»، أو طلب الحذف عبر الدعم.'],
      ['h', '12. الأمان'],
      ['p', 'نتّبع إجراءات معقولة لحماية البيانات، منها الاتصال المشفّر (HTTPS) وتقليل البيانات المجموعة. لكن لا يوجد نظام آمن بنسبة 100%.'],
      ['h', '13. الأطفال'],
      ['p', 'راجع تبويب «سياسة الأطفال».'],
      ['h', '14. التعديلات والتواصل'],
      ['p', 'قد نحدّث هذه السياسة، وسيظهر تاريخ آخر تحديث أعلاها. للاستفسار راجع قسم «الدعم والتواصل».'],
    ];

List<List<String>> _children(String s) => [
      ['h', 'سياسة الأطفال وأولياء الأمور'],
      ['m', 'آخر تحديث: ${Cfg.legalUpdated}'],
      ['p', '«$s» دليل تعليمي موجّه للطلاب وأولياء الأمور والعموم، وليس تطبيقاً مخصصاً لفئة الأطفال.'],
      ['li', 'لا نجمع عن قصد أي بيانات شخصية من الأطفال دون 13 سنة.'],
      ['li', 'تصفّح الدليل لا يتطلب أي بيانات شخصية ولا حساباً.'],
      ['li', 'ميزتا «سجّل الآن» و«اقترح إضافة» هما ما يرسل بيانات تواصل، وتتطلبان تأكيد أن المستخدم بعمر 13 سنة أو أكثر أو يرسل بموافقة ولي أمره. ونقترح أن يُدخل ولي الأمر رقم هاتفه في طلبات التسجيل للأطفال.'],
      ['li', 'لا توجد محادثات بين المستخدمين ولا ملفات شخصية عامة. المحتوى الوحيد الذي ينشره المستخدمون هو التقييمات، وتُراجعها الإدارة قبل نشرها، ويمنع النظام الروابط وأرقام الهواتف والكلمات المسيئة، ويستطيع أي مستخدم الإبلاغ عن تقييم أو إخفاءه.'],
      ['li', 'بيانات أدوات الطالب (الجدول، الدرجات، التذكيرات، الملاحظات) تبقى على الجهاز ولا تُرسل إلينا، والموقع الجغرافي لا يُرسل أبداً.'],
      ['li', 'لا إعلانات مخصصة حسب السلوك، ولا تتبع، ولا مشتريات داخل التطبيق.'],
      ['li', 'جميع المحتوى المنشور مناسب لجميع الأعمار.'],
      ['li', 'قد تفتح بعض الأزرار تطبيقات خارجية مثل واتساب أو الهاتف، وننصح أولياء الأمور بمتابعة استخدام الأطفال لها.'],
      ['h', 'لأولياء الأمور'],
      ['p', 'إذا علمت أن طفلك دون 13 سنة أرسل بيانات من خلال التطبيق دون موافقتك، تواصل معنا من قسم «الدعم والتواصل» وسنحذفها فوراً. ويمكنك أيضاً حذفها مباشرة من جهازه عبر «حذف بياناتي».'],
    ];

List<List<String>> _terms() => [
      ['h', 'شروط الاستخدام'],
      ['m', 'آخر تحديث: ${Cfg.legalUpdated}'],
      ['li', 'يُقدَّم الدليل للمعلومة العامة. نسعى لدقة البيانات وتحديثها، لكن يُنصح بالتحقق مباشرة من المؤسسة قبل اتخاذ أي قرار.'],
      ['li', 'المؤسسات والمدرسون المعروضون مسؤولون عن خدماتهم، والتطبيق ليس طرفاً في أي اتفاق بينك وبينهم.'],
      ['li', 'عند إرسال اقتراح تتعهد بأن المعلومات صحيحة، وأن الصورة التقطتها أو يحق لك مشاركتها، وألا تتضمن وجوه أشخاص دون إذنهم أو أي محتوى مسيء.'],
      ['li', 'يحق لفريق التطبيق رفض أي اقتراح أو تقييم أو تعديله أو حذفه.'],
      ['li', 'لا تسامح مطلقاً مع المحتوى المسيء أو المهين أو الكاذب أو المتضمن بيانات شخصية في التقييمات؛ يُحذف فوراً، ويُمنع ناشره من النشر. يمكنك الإبلاغ عن أي تقييم بزر «إبلاغ» أو إخفاؤه عنك، ونراجع البلاغات خلال 24 ساعة.'],
      ['li', 'إرسال طلب تسجيل لا يعني القبول النهائي؛ يتأكد القبول والرسوم بعد تواصل الجهة معك مباشرة.'],
      ['li', 'أدوات الطالب (حاسبة المعدل وغيرها) للمساعدة فقط، والمعتمد هو النتائج والتعليمات الرسمية.'],
      ['li', 'يُمنع إساءة استخدام التطبيق أو محاولة الوصول غير المصرّح به إلى بياناته.'],
      ['li', 'تُطبّق أيضاً شروط ترخيص المستخدم النهائي القياسية من Apple (Standard EULA).'],
    ];

class LegalScreen extends StatefulWidget {
  final String initial;
  const LegalScreen({super.key, this.initial = 'privacy'});

  @override
  State<LegalScreen> createState() => _LegalScreenState();
}

class _LegalScreenState extends State<LegalScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    var i = kLegalTabs.indexWhere((t) => t[0] == widget.initial);
    if (i < 0) i = 0;
    _tabs = TabController(length: kLegalTabs.length, vsync: this, initialIndex: i);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Widget _blocks(BuildContext context, List<List<String>> blocks, {List<Widget> extra = const []}) {
    final p = Pal.of(context);
    final children = <Widget>[];
    for (final b in blocks) {
      final t = b[1];
      switch (b[0]) {
        case 'h':
          children.add(Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 4),
            child: Text(
              t,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: p.brandOn),
            ),
          ));
          break;
        case 'm':
          children.add(Text(t, style: TextStyle(color: p.muted, fontSize: 12.5)));
          break;
        case 'li':
          children.add(Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 9, left: 8),
                  child: Icon(Icons.circle, size: 6, color: p.muted),
                ),
                Expanded(child: Text(t, style: TextStyle(color: p.text, height: 1.85))),
              ],
            ),
          ));
          break;
        default:
          children.add(Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(t, style: TextStyle(color: p.text, height: 1.85)),
          ));
      }
    }
    children.addAll(extra);
    return ListView(padding: const EdgeInsets.fromLTRB(18, 6, 18, 40), children: children);
  }

  Widget _deleteTab(BuildContext context) {
    final p = Pal.of(context);
    final s = AppState.I;
    final n = s.myServerItemsCount;
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 40),
      children: [
        Text(
          'حذف بياناتي',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: p.brandOn),
        ),
        const SizedBox(height: 6),
        Text('لا توجد حسابات في التطبيق، وبياناتك نوعان:', style: TextStyle(color: p.text, height: 1.8)),
        NoteBox(
          child: Text(
            '1. البيانات المحفوظة على هذا الجهاز\nالمفضلة، الإشعارات المقروءة، تفضيلات العرض، أدوات الطالب والملاحظات والتذكيرات.',
            style: TextStyle(color: p.text, height: 1.8),
          ),
        ),
        SoftButton(
          'مسح بيانات هذا الجهاز',
          icon: Icons.cleaning_services_outlined,
          color: const Color(0xFFB42318),
          onPressed: () async {
            final ok = await confirmDialog(
              context,
              'مسح المفضلة والتفضيلات وأدوات الطالب من هذا الجهاز؟',
              ok: 'مسح',
              danger: true,
            );
            if (!ok) return;
            await s.wipeLocal();
            toast('تم مسح بيانات الجهاز');
          },
        ),
        const SizedBox(height: 10),
        NoteBox(
          child: Text(
            '2. طلبات التسجيل والاقتراحات التي أرسلتها من هذا الجهاز\n${n > 0 ? 'لديك $n طلب/اقتراح مرسل من هذا الجهاز.' : 'لا توجد طلبات أو اقتراحات مرسلة من هذا الجهاز.'}',
            style: TextStyle(color: p.text, height: 1.8),
          ),
        ),
        SoftButton(
          'حذف طلباتي واقتراحاتي من الخادم',
          icon: Icons.delete_outline,
          color: const Color(0xFFB42318),
          onPressed: () async {
            if (s.myIds().isEmpty) {
              toast('لا توجد طلبات أو اقتراحات مرسلة من هذا الجهاز', ToastType.warn);
              return;
            }
            final ok = await confirmDialog(
              context,
              'حذف طلباتك واقتراحاتك وصورها نهائياً من الخادم؟',
              ok: 'حذف',
              danger: true,
            );
            if (!ok) return;
            try {
              await s.deleteMine();
              toast('تم حذف طلباتك واقتراحاتك');
            } catch (_) {
              toast('تعذّر الحذف — تحقق من الاتصال وحاول مجدداً', ToastType.err);
            }
            if (mounted) setState(() {});
          },
        ),
        const SizedBox(height: 14),
        Text(
          'إذا أرسلت اقتراحاً من جهاز آخر أو حذفت التطبيق، تواصل معنا من «الدعم والتواصل» واذكر الاسم الذي اقترحته أو طلبت التسجيل فيه، وسنحذفه خلال 30 يوماً كحد أقصى. ولحذف تقييم كتبته تواصل معنا بنفس الطريقة.',
          style: TextStyle(color: p.muted, fontSize: 12.5, height: 1.8),
        ),
      ],
    );
  }

  Widget _supportTab(BuildContext context) {
    final s = AppState.I.settings.siteName;
    return _blocks(
      context,
      [
        ['h', 'الدعم والتواصل'],
        ['p', 'لأي سؤال أو مشكلة أو طلب حذف بيانات أو تصحيح معلومة في الدليل:'],
      ],
      extra: [
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            PrimaryButton(
              'تواصل عبر واتساب',
              icon: Icons.chat,
              color: const Color(0xFF128C4B),
              onPressed: openAdminWhatsApp,
            ),
            SoftButton(
              'عن التطبيق',
              icon: Icons.info_outline,
              onPressed: () => showInfoPage(context, app: true),
            ),
            // «الجهة المطوّرة» لا تظهر في نسخة الآيفون
            if (defaultTargetPlatform != TargetPlatform.iOS)
              SoftButton(
                'الجهة المطوّرة',
                icon: Icons.business,
                onPressed: () => showInfoPage(context, app: false),
              ),
          ],
        ),
        ..._faq(context, [
          ['كيف أسجّل عند مدرّس أو معهد؟', 'افتح صفحته واضغط «سجّل الآن» أو «احجز مقعداً»، وتابع حالة الطلب من «طلباتي».'],
          ['كيف أقيّم مدرّساً؟', 'من صفحته، قسم «تقييمات الطلاب» ثم «اكتب تقييمك». يظهر بعد مراجعة الإدارة.'],
          ['كيف أُضيف مؤسستي أو اسمي كمدرس؟', 'من تبويب «المزيد» اختر «اقترح إضافة»، ثم صوّر اللوحة أو الواجهة وأرسل الاقتراح.'],
          ['كيف أوقف الإشعارات؟', 'من إعدادات الجهاز ثم $s ثم الإشعارات.'],
          ['هل التطبيق مجاني؟', 'نعم، دون مشتريات داخل التطبيق.'],
        ]),
      ],
    );
  }

  List<Widget> _faq(BuildContext context, List<List<String>> items) {
    final p = Pal.of(context);
    return [
      Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 4),
        child: Text(
          'أسئلة شائعة',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: p.brandOn),
        ),
      ),
      for (final it in items)
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(it[0], style: TextStyle(fontWeight: FontWeight.w800, color: p.text)),
              Text(it[1], style: TextStyle(color: p.text, height: 1.8)),
            ],
          ),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final name = AppState.I.settings.siteName;
    return Scaffold(
      appBar: brandAppBar(
        context,
        'الخصوصية والسياسات',
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: const Color(0xFFF3D98A),
          labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
          tabs: [for (final t in kLegalTabs) Tab(text: t[1])],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _blocks(context, _privacy(name)),
          _blocks(context, _children(name)),
          _blocks(context, _terms()),
          _deleteTab(context),
          _supportTab(context),
        ],
      ),
    );
  }
}
