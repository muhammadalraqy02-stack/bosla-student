// المفضلة — العناصر التي حفظها المستخدم على هذا الجهاز

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../ui.dart';
import '../widgets/common.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.I,
      builder: (context, _) {
        final list = AppState.I.favoriteCards;
        return Scaffold(
          appBar: brandAppBar(context, 'المفضلة'),
          body: list.isEmpty
              ? Center(
                  child: EmptyBox(
                    'لم تحفظ أي عنصر بعد.\nاضغط على القلب في أي مدرسة أو معهد أو مدرّس ليظهر هنا.',
                    icon: Icons.favorite_border,
                    action: SoftButton(
                      'تصفّح الدليل',
                      icon: Icons.home_outlined,
                      onPressed: () => rootTab.value = 0,
                    ),
                  ),
                )
              : CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                        child: Text(
                          'العناصر التي حفظتها على هذا الجهاز (${list.length})',
                          style: TextStyle(color: Pal.of(context).muted, fontSize: 13),
                        ),
                      ),
                    ),
                    // في المفضلة نعرض البطاقات الأفقية دائماً ليظهر زر القلب للإزالة
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (ctx, i) => ItemCard(list[i]),
                          childCount: list.length,
                        ),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}
