// تبويب «المزيد» — يقابل القائمة الجانبية في نسخة الويب

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../ui.dart';
import '../widgets/common.dart';
import 'category_screen.dart';
import 'compare_screen.dart';
import 'legal_screen.dart';
import 'nearby_screen.dart';
import 'notifications_screen.dart';
import 'search_screen.dart';
import 'suggest_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  void _push(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.I,
      builder: (context, _) {
        final s = AppState.I;
        final p = Pal.of(context);
        final st = s.settings;

        Widget tile(IconData icon, String label, VoidCallback onTap, {Widget? trailing, Color? color}) {
          return ListTile(
            dense: true,
            leading: Icon(icon, color: color ?? p.brandOn),
            title: Text(
              label,
              style: TextStyle(fontWeight: FontWeight.w700, color: p.text, fontSize: 14.5),
            ),
            trailing: trailing ?? Icon(Icons.chevron_left, color: p.muted, size: 20),
            onTap: onTap,
          );
        }

        Widget group(String title, List<Widget> children) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 6, right: 4),
                  child: Text(
                    title,
                    style: TextStyle(color: p.muted, fontSize: 12.5, fontWeight: FontWeight.w800),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: p.card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: p.border),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Material(
                    color: Colors.transparent,
                    child: Column(children: children),
                  ),
                ),
              ],
            ),
          );
        }

        Widget count(int n) => n > 0
            ? Tag('$n', bg: p.soft, fg: p.brandOn)
            : Icon(Icons.chevron_left, color: p.muted, size: 20);

        return Scaffold(
          appBar: brandAppBar(context, 'المزيد'),
          body: ListView(
            padding: const EdgeInsets.only(bottom: 90),
            children: [
              Container(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [p.brand, const Color(0xFF174B91)],
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.explore, color: Color(0xFFF3D98A), size: 40),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            st.siteName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            st.siteSub,
                            style: const TextStyle(color: Colors.white70, fontSize: 12.5),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              group('الأقسام', [
                for (final c in s.data.categories)
                  tile(
                    c.iconData,
                    c.name,
                    () => _push(context, CategoryScreen(catKey: c.key)),
                    trailing: count(s.catCount(c.key)),
                  ),
              ]),
              group('خدمات التطبيق', [
                tile(Icons.search, 'البحث والفلترة المتقدمة', () => _push(context, const SearchScreen())),
                tile(Icons.my_location, 'الأقرب إليّ', () => _push(context, const NearbyScreen())),
                tile(
                  Icons.balance,
                  'المقارنة',
                  () => _push(context, const CompareScreen()),
                  trailing: count(s.compareIds.length),
                ),
                tile(
                  Icons.favorite,
                  'المفضلة',
                  () => rootTab.value = 1,
                  trailing: count(s.favoriteCount),
                  color: const Color(0xFFEF4444),
                ),
                tile(Icons.assignment_outlined, 'طلباتي', () {
                  rootTab.value = 2;
                  s.markBookingsSeen();
                }),
                tile(Icons.home_repair_service_outlined, 'أدوات الطالب', () => rootTab.value = 3),
                tile(
                  Icons.notifications_outlined,
                  'الإشعارات',
                  () => _push(context, const NotificationsScreen()),
                  trailing: count(s.unreadNotifications),
                ),
                tile(
                  Icons.add_a_photo_outlined,
                  'اقترح إضافة',
                  () => _push(context, const SuggestScreen()),
                ),
              ]),
              group('العرض', [
                SwitchListTile(
                  dense: true,
                  secondary: Icon(s.isDark ? Icons.dark_mode : Icons.light_mode, color: p.brandOn),
                  title: Text(
                    'الوضع الليلي',
                    style: TextStyle(fontWeight: FontWeight.w700, color: p.text, fontSize: 14.5),
                  ),
                  value: s.isDark,
                  onChanged: (_) => s.toggleTheme(),
                ),
              ]),
              group('التواصل والمعلومات', [
                tile(
                  Icons.chat,
                  'تواصل معنا عبر واتساب',
                  openAdminWhatsApp,
                  color: const Color(0xFF25D366),
                ),
                tile(Icons.info_outline, 'عن التطبيق', () => showInfoPage(context, app: true)),
                tile(Icons.business, 'عن الشركة المطوّرة', () => showInfoPage(context, app: false)),
                tile(Icons.headset_mic_outlined, 'الدعم والمساعدة', () => openLegal(context, 'support')),
              ]),
              group('الخصوصية والسياسات', [
                tile(Icons.privacy_tip_outlined, 'سياسة الخصوصية', () => openLegal(context, 'privacy')),
                tile(Icons.child_care, 'سياسة الأطفال', () => openLegal(context, 'children')),
                tile(Icons.description_outlined, 'شروط الاستخدام', () => openLegal(context, 'terms')),
                tile(
                  Icons.cleaning_services_outlined,
                  'حذف بياناتي',
                  () => openLegal(context, 'delete'),
                  color: const Color(0xFFB42318),
                ),
              ]),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  st.footer,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: p.muted, fontSize: 12),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
