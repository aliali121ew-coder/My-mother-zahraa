import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass.dart';

/// صفحة المنشورات بنمط إنستغرام — قيد البناء في هذه المرحلة.
///
/// المتطلبات المسجّلة لهذه الشاشة:
///  • شريط ستوريز في الأعلى مقسّم إلى أقسام يديرها المدير
///  • منشورات بعدة صور بتمرير أفقي (carousel)
///  • إعجاب متاح **للزائر بلا تسجيل**، وتعليق **يتطلب حساباً**
///  • مشاركة وحفظ المنشور، ملفات شخصية ومتابعة
///  • قسم السنوات: أرشيف بألبوم مستقل لكل سنة
class PostsPage extends ConsumerWidget {
  const PostsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('المنشورات')),
      body: const _UnderConstruction(
        icon: Icons.dynamic_feed_rounded,
        title: 'المنشورات قيد البناء',
        points: [
          'شريط ستوريز بأقسام يديرها المدير',
          'منشورات بعدة صور بتمرير أفقي',
          'إعجاب للزائر وتعليق للمسجلين',
          'مشاركة وحفظ ومتابعة',
          'أرشيف السنوات بألبوم لكل سنة',
        ],
      ),
    );
  }
}

/// شاشة مؤقتة تُبيّن ما سيُبنى في هذه الصفحة بدقة — أوضح من صفحة فارغة.
class _UnderConstruction extends StatelessWidget {
  const _UnderConstruction({
    required this.icon,
    required this.title,
    required this.points,
  });

  final IconData icon;
  final String title;
  final List<String> points;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
      children: [
        GlassCard(
          blur: true,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: AppColors.gold, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(title, style: theme.textTheme.titleLarge),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text('ما سيحتويه هذا القسم:', style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              for (final p in points)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 6),
                        child: Icon(Icons.circle,
                            size: 5, color: AppColors.gold),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(p, style: theme.textTheme.bodyLarge),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
